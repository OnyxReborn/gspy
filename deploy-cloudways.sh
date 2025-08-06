#!/bin/bash

# gSpy Cloudways Deployment Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration variables
APP_NAME=""
DOMAIN_NAME=""
EMAIL=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
DB_NAME=""
DB_USER=""
DB_PASS=""

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

get_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ${default:+[$default]}: " input
    echo "${input:-$default}"
}

check_requirements() {
    print_status "Checking system requirements..."
    
    if ! command -v node >/dev/null 2>&1; then
        print_error "Node.js is not available."
        exit 1
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm is not available."
        exit 1
    fi
    
    if ! command -v pm2 >/dev/null 2>&1; then
        print_status "Installing PM2..."
        npm install -g pm2
    fi
    
    print_success "System requirements check completed."
}

get_configuration() {
    echo "=========================================="
    echo "      gSpy Cloudways Configuration        "
    echo "=========================================="
    
    APP_NAME=$(get_input "Enter your Cloudways app name" "gspy-app")
    DOMAIN_NAME=$(get_input "Enter your domain name" "")
    EMAIL=$(get_input "Enter your email address" "")
    ADMIN_EMAIL=$(get_input "Enter admin email" "$EMAIL")
    ADMIN_PASSWORD=$(get_input "Enter admin password (empty to generate)" "")
    DB_NAME=$(get_input "Enter database name" "gspy_db")
    DB_USER=$(get_input "Enter database username" "gspy_user")
    DB_PASS=$(get_input "Enter database password (empty to generate)" "")
    
    if [ -z "$ADMIN_PASSWORD" ]; then
        ADMIN_PASSWORD=$(generate_password)
        print_status "Generated admin password: $ADMIN_PASSWORD"
    fi
    
    if [ -z "$DB_PASS" ]; then
        DB_PASS=$(generate_password)
        print_status "Generated database password: $DB_PASS"
    fi
    
    echo ""
    echo "Configuration Summary:"
    echo "App Name: $APP_NAME"
    echo "Domain: $DOMAIN_NAME"
    echo "Admin Email: $ADMIN_EMAIL"
    echo "Database: $DB_NAME"
    echo ""
    
    read -p "Continue? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled."
        exit 1
    fi
}

create_deployment_directory() {
    print_status "Creating deployment directory..."
    DEPLOY_DIR="/home/master/applications/$APP_NAME/public_html"
    mkdir -p "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
    print_success "Deployment directory: $DEPLOY_DIR"
}

setup_gspy() {
    print_status "Setting up gSpy application..."
    
    mkdir -p backend frontend mobile logs uploads backups
    
    # Setup backend
    cd backend
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "gspy-backend-cloudways",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "pm2:start": "pm2 start ecosystem.config.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^8.0.3",
    "redis": "^4.6.10",
    "socket.io": "^4.7.4",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "express-rate-limit": "^7.1.5",
    "multer": "^1.4.5-lts.1",
    "nodemailer": "^6.9.7",
    "winston": "^3.11.0",
    "dotenv": "^16.3.1",
    "express-validator": "^7.0.1",
    "uuid": "^9.0.1",
    "moment": "^2.29.4",
    "lodash": "^4.17.21",
    "axios": "^1.6.2"
  },
  "engines": { "node": ">=16.0.0" }
}
EOF
    
    # Create PM2 ecosystem config
    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'gspy-backend',
    script: 'server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: '../logs/err.log',
    out_file: '../logs/out.log',
    log_file: '../logs/combined.log',
    time: true,
    max_memory_restart: '1G'
  }]
};
EOF
    
    # Create server.js
    cat > server.js << 'EOF'
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
require('dotenv').config();

const app = express();

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000
});

// Middleware
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));
app.use(cors({
  origin: process.env.FRONTEND_URL || "*",
  credentials: true
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(limiter);

// Database connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/gspy', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('Connected to MongoDB'))
.catch((error) => console.error('MongoDB connection error:', error));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    uptime: process.uptime()
  });
});

// Basic routes
app.get('/api/auth/test', (req, res) => {
  res.json({ message: 'Auth endpoint working' });
});

// Serve static files
app.use(express.static(path.join(__dirname, '../frontend/build')));

// Catch all route for SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/build/index.html'));
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`gSpy server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
EOF
    
    # Create environment file
    cat > .env << EOF
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
MONGODB_URI=mongodb://$DB_USER:$DB_PASS@localhost:27017/$DB_NAME?authSource=admin
REDIS_URL=redis://localhost:6379
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/")
JWT_EXPIRES_IN=7d
FRONTEND_URL=https://$DOMAIN_NAME
EMAIL_SERVICE=gmail
EMAIL_USER=noreply@$DOMAIN_NAME
EMAIL_PASS=your-email-password
EMAIL_FROM=gSpy <noreply@$DOMAIN_NAME>
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=1000
CORS_ORIGIN=https://$DOMAIN_NAME
LOG_LEVEL=info
LOG_FILE_PATH=../logs
ENABLE_REQUEST_LOGGING=true
ENABLE_KEYLOGGER=true
ENABLE_SCREEN_RECORDER=true
ENABLE_CALL_RECORDING=true
ENABLE_LIVE_SCREEN=true
ENABLE_SOCIAL_MEDIA_MONITORING=true
ENABLE_APP_MONITORING=true
ENABLE_BROWSER_HISTORY=true
ENABLE_EMAIL_MONITORING=true
ENABLE_CALENDAR_MONITORING=true
ENABLE_GEOFENCING=true
ENABLE_KEYWORD_ALERTS=true
ENABLE_APP_BLOCKING=true
MONITORING_INTERVAL=300000
LOCATION_UPDATE_INTERVAL=60000
SYNC_INTERVAL=300000
HEARTBEAT_INTERVAL=30000
BACKUP_ENABLED=true
BACKUP_INTERVAL=86400000
BACKUP_RETENTION_DAYS=30
BACKUP_PATH=../backups
ANALYTICS_ENABLED=true
ANALYTICS_RETENTION_DAYS=90
ANALYTICS_BATCH_SIZE=1000
ENCRYPTION_KEY=$(openssl rand -base64 32)
ENCRYPTION_ALGORITHM=aes-256-gcm
EOF
    
    npm install --production
    cd ..
    
    # Setup frontend
    cd frontend
    
    cat > package.json << 'EOF'
{
  "name": "gspy-frontend-cloudways",
  "version": "1.0.0",
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "@mui/material": "^5.14.20",
    "@mui/icons-material": "^5.14.19",
    "@emotion/react": "^11.11.1",
    "@emotion/styled": "^11.11.0",
    "axios": "^1.6.2",
    "react-router-dom": "^6.20.1",
    "react-hot-toast": "^2.4.1"
  },
  "browserslist": {
    "production": [">0.2%", "not dead", "not op_mini all"],
    "development": ["last 1 chrome version", "last 1 firefox version", "last 1 safari version"]
  }
}
EOF
    
    cat > .env << EOF
REACT_APP_API_URL=https://$DOMAIN_NAME/api
REACT_APP_SOCKET_URL=https://$DOMAIN_NAME
REACT_APP_ENVIRONMENT=production
REACT_APP_DOMAIN=$DOMAIN_NAME
EOF
    
    mkdir -p public src
    
    cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="gSpy Monitoring Dashboard" />
    <title>gSpy Dashboard</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF
    
    cat > src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF
    
    cat > src/App.js << 'EOF'
import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Card,
  CardContent,
  Button,
  Alert,
  CircularProgress
} from '@mui/material';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: { main: '#2196f3' },
    secondary: { main: '#f50057' },
    background: { default: '#0a0a0a', paper: '#1a1a1a' },
  },
});

function App() {
  const [isLoading, setIsLoading] = useState(true);
  const [isHealthy, setIsHealthy] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    checkHealth();
  }, []);

  const checkHealth = async () => {
    try {
      const response = await fetch('/api/health');
      if (response.ok) {
        setIsHealthy(true);
      } else {
        setError('Server is not responding properly');
      }
    } catch (err) {
      setError('Cannot connect to server');
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="100vh">
          <CircularProgress />
        </Box>
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Container maxWidth="md" sx={{ py: 4 }}>
        <Typography variant="h3" component="h1" gutterBottom align="center">
          gSpy Dashboard
        </Typography>
        
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="h5" gutterBottom>Server Status</Typography>
            
            {isHealthy ? (
              <Alert severity="success" sx={{ mb: 2 }}>
                Server is running and healthy
              </Alert>
            ) : (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error || 'Server is not responding'}
              </Alert>
            )}
            
            <Button variant="contained" onClick={checkHealth} disabled={isLoading}>
              Check Status
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardContent>
            <Typography variant="h5" gutterBottom>Quick Setup</Typography>
            <Typography variant="body1" paragraph>
              Your gSpy monitoring dashboard is now deployed on Cloudways.
              Full features are available with this hosting platform.
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Admin Email: ADMIN_EMAIL_PLACEHOLDER<br/>
              Admin Password: ADMIN_PASSWORD_PLACEHOLDER
            </Typography>
          </CardContent>
        </Card>
      </Container>
    </ThemeProvider>
  );
}

export default App;
EOF
    
    npm install
    npm run build
    cd ..
    
    print_success "gSpy application setup completed."
}

setup_database() {
    print_status "Setting up database..."
    mysql -u root -p -e "
    CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
    GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
    FLUSH PRIVILEGES;
    "
    print_success "Database setup completed."
}

create_pm2_config() {
    print_status "Creating PM2 configuration..."
    cd backend
    pm2 start ecosystem.config.js --env production
    pm2 save
    pm2 startup
    cd ..
    print_success "PM2 configuration completed."
}

create_management_scripts() {
    print_status "Creating management scripts..."
    
    cat > start.sh << 'EOF'
#!/bin/bash
echo "Starting gSpy on Cloudways..."
cd backend
pm2 start ecosystem.config.js --env production
pm2 save
echo "gSpy started successfully!"
EOF
    
    cat > monitor.sh << 'EOF'
#!/bin/bash
echo "=== gSpy Cloudways Status ==="
echo "Date: $(date)"
echo ""
echo "=== PM2 Status ==="
pm2 status
echo ""
echo "=== System Resources ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
echo "Memory Usage:"
free -h | grep Mem
echo "Disk Usage:"
df -h | grep -E '^/dev/'
echo ""
echo "=== Application Health ==="
curl -s https://$DOMAIN_NAME/api/health | jq . 2>/dev/null || echo "❌ Application not responding"
EOF
    
    cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

echo "Creating database backup..."
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR/db_backup_$DATE.sql

echo "Creating application backup..."
tar -czf $BACKUP_DIR/app_backup_$DATE.tar.gz --exclude=node_modules --exclude=logs --exclude=backups .

echo "Backup completed:"
echo "- Database: db_backup_$DATE.sql"
echo "- Application: app_backup_$DATE.tar.gz"
du -h $BACKUP_DIR/*$DATE*
EOF
    
    chmod +x start.sh monitor.sh backup.sh
    print_success "Management scripts created."
}

display_final_info() {
    echo ""
    echo "=========================================="
    echo "    gSpy Cloudways Setup Complete!       "
    echo "=========================================="
    echo ""
    echo "🎉 gSpy has been set up on your Cloudways server!"
    echo ""
    echo "📋 Setup Information:"
    echo "   App Name: $APP_NAME"
    echo "   Domain: https://$DOMAIN_NAME"
    echo "   Admin Email: $ADMIN_EMAIL"
    echo "   Admin Password: $ADMIN_PASSWORD"
    echo "   Database: $DB_NAME"
    echo "   Database User: $DB_USER"
    echo "   Database Password: $DB_PASS"
    echo ""
    echo "🔧 Management Commands:"
    echo "   Start app: ./start.sh"
    echo "   Monitor: ./monitor.sh"
    echo "   Backup: ./backup.sh"
    echo "   PM2 status: pm2 status"
    echo "   PM2 logs: pm2 logs"
    echo ""
    echo "🌐 Next Steps:"
    echo "   1. Configure SSL certificate in Cloudways panel"
    echo "   2. Set up custom domain in Cloudways panel"
    echo "   3. Configure email settings in backend/.env"
    echo "   4. Access your dashboard at https://$DOMAIN_NAME"
    echo ""
    echo "⚠️  Legal Compliance:"
    echo "   - Ensure compliance with local laws"
    echo "   - Obtain proper consent for monitoring"
    echo "   - Follow data protection regulations"
    echo ""
}

main() {
    echo "=========================================="
    echo "      gSpy Cloudways Deployment          "
    echo "=========================================="
    echo ""
    
    check_requirements
    get_configuration
    create_deployment_directory
    setup_gspy
    setup_database
    create_pm2_config
    create_management_scripts
    display_final_info
}

main "$@" 