#!/bin/bash

# gSpy Hostinger Shared Hosting Deployment Script
# This script deploys gSpy to Hostinger shared hosting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
DOMAIN_NAME=""
EMAIL=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
DB_NAME=""
DB_USER=""
DB_PASS=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to get user input
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        echo "${input:-$default}"
    else
        read -p "$prompt: " input
        echo "$input"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check Node.js
    if ! command_exists node; then
        print_error "Node.js is not available on shared hosting."
        print_status "You'll need to use the web-based deployment method."
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        print_warning "Node.js version 16+ is recommended. Current version: $(node -v)"
    fi
    
    # Check npm
    if ! command_exists npm; then
        print_error "npm is not available on shared hosting."
        exit 1
    fi
    
    # Check git
    if ! command_exists git; then
        print_warning "Git is not available. You'll need to upload files manually."
    fi
    
    print_success "System requirements check completed."
}

# Function to get configuration from user
get_configuration() {
    echo ""
    echo "=========================================="
    echo "    gSpy Shared Hosting Configuration     "
    echo "=========================================="
    echo ""
    
    DOMAIN_NAME=$(get_input "Enter your domain name (e.g., yourdomain.com)" "")
    EMAIL=$(get_input "Enter your email address" "")
    ADMIN_EMAIL=$(get_input "Enter admin email for dashboard" "$EMAIL")
    ADMIN_PASSWORD=$(get_input "Enter admin password (leave empty to generate)" "")
    DB_NAME=$(get_input "Enter database name (from Hostinger panel)" "")
    DB_USER=$(get_input "Enter database username (from Hostinger panel)" "")
    DB_PASS=$(get_input "Enter database password (from Hostinger panel)" "")
    
    # Generate admin password if not provided
    if [ -z "$ADMIN_PASSWORD" ]; then
        ADMIN_PASSWORD=$(generate_password)
        print_status "Generated admin password: $ADMIN_PASSWORD"
    fi
    
    echo ""
    echo "Configuration Summary:"
    echo "Domain: $DOMAIN_NAME"
    echo "Email: $EMAIL"
    echo "Admin Email: $ADMIN_EMAIL"
    echo "Database: $DB_NAME"
    echo "Database User: $DB_USER"
    echo ""
    
    read -p "Continue with this configuration? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled."
        exit 1
    fi
}

# Function to create deployment directory
create_deployment_directory() {
    print_status "Creating deployment directory..."
    
    # Use public_html for shared hosting
    DEPLOY_DIR="$HOME/public_html/gspy"
    mkdir -p "$DEPLOY_DIR"
    
    cd "$DEPLOY_DIR"
    
    print_success "Deployment directory created: $DEPLOY_DIR"
}

# Function to download and setup gSpy
setup_gspy() {
    print_status "Setting up gSpy application..."
    
    # Create directory structure
    mkdir -p backend frontend mobile logs uploads backups
    
    # Download or create backend files
    cd backend
    
    # Create package.json for backend
    cat > package.json << 'EOF'
{
  "name": "gspy-backend-shared",
  "version": "1.0.0",
  "description": "gSpy Backend for Shared Hosting",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^8.0.3",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "express-rate-limit": "^7.1.5",
    "multer": "^1.4.5-lts.1",
    "crypto": "^1.0.1",
    "nodemailer": "^6.9.7",
    "winston": "^3.11.0",
    "joi": "^17.11.0",
    "compression": "^1.7.4",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "express-validator": "^7.0.1",
    "uuid": "^9.0.1",
    "moment": "^2.29.4",
    "lodash": "^4.17.21",
    "axios": "^1.6.2"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF
    
    # Create simplified server.js for shared hosting
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
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

// Middleware
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));
app.use(cors({
  origin: process.env.FRONTEND_URL || "*",
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(limiter);

// Database connection (using MongoDB Atlas for shared hosting)
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/gspy', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log('Connected to MongoDB');
})
.catch((error) => {
  console.error('MongoDB connection error:', error);
});

// Basic routes
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/api/auth/test', (req, res) => {
  res.json({ message: 'Auth endpoint working' });
});

// Serve static files
app.use(express.static(path.join(__dirname, '../frontend/build')));

// Catch all route for SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/build/index.html'));
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`gSpy server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
EOF
    
    # Create environment file
    cat > .env << EOF
# Server Configuration
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# Database Configuration (Use MongoDB Atlas for shared hosting)
MONGODB_URI=mongodb+srv://$DB_USER:$DB_PASS@cluster0.mongodb.net/$DB_NAME?retryWrites=true&w=majority

# JWT Configuration
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/")
JWT_EXPIRES_IN=7d

# Frontend URL
FRONTEND_URL=https://$DOMAIN_NAME

# Email Configuration
EMAIL_SERVICE=gmail
EMAIL_USER=noreply@$DOMAIN_NAME
EMAIL_PASS=your-email-password
EMAIL_FROM=gSpy <noreply@$DOMAIN_NAME>

# Security Configuration
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
CORS_ORIGIN=https://$DOMAIN_NAME

# Logging Configuration
LOG_LEVEL=info
LOG_FILE_PATH=./logs
ENABLE_REQUEST_LOGGING=true

# Feature Flags (Limited for shared hosting)
ENABLE_KEYLOGGER=false
ENABLE_SCREEN_RECORDER=false
ENABLE_CALL_RECORDING=false
ENABLE_LIVE_SCREEN=false
ENABLE_SOCIAL_MEDIA_MONITORING=true
ENABLE_APP_MONITORING=true
ENABLE_BROWSER_HISTORY=true
ENABLE_EMAIL_MONITORING=true
ENABLE_CALENDAR_MONITORING=true
ENABLE_GEOFENCING=true
ENABLE_KEYWORD_ALERTS=true
ENABLE_APP_BLOCKING=false

# Development Configuration
ENABLE_DEBUG_MODE=false
ENABLE_TEST_MODE=false
MOCK_DATA_ENABLED=false
EOF
    
    # Install dependencies
    npm install --production
    
    cd ..
    
    # Setup frontend
    cd frontend
    
    # Create package.json for frontend
    cat > package.json << 'EOF'
{
  "name": "gspy-frontend-shared",
  "version": "1.0.0",
  "description": "gSpy Frontend for Shared Hosting",
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
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
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
EOF
    
    # Create environment file
    cat > .env << EOF
REACT_APP_API_URL=https://$DOMAIN_NAME/api
REACT_APP_ENVIRONMENT=production
REACT_APP_DOMAIN=$DOMAIN_NAME
EOF
    
    # Create basic React app
    mkdir -p public src
    
    # Create public/index.html
    cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
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
    
    # Create src/index.js
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
    
    # Create src/App.js
    cat > src/App.js << 'EOF'
import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Card,
  CardContent,
  Button,
  TextField,
  Alert,
  CircularProgress
} from '@mui/material';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#0a0a0a',
      paper: '#1a1a1a',
    },
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
        <Box
          display="flex"
          justifyContent="center"
          alignItems="center"
          minHeight="100vh"
        >
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
            <Typography variant="h5" gutterBottom>
              Server Status
            </Typography>
            
            {isHealthy ? (
              <Alert severity="success" sx={{ mb: 2 }}>
                Server is running and healthy
              </Alert>
            ) : (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error || 'Server is not responding'}
              </Alert>
            )}
            
            <Button
              variant="contained"
              onClick={checkHealth}
              disabled={isLoading}
            >
              Check Status
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardContent>
            <Typography variant="h5" gutterBottom>
              Quick Setup
            </Typography>
            <Typography variant="body1" paragraph>
              Your gSpy monitoring dashboard is now deployed on shared hosting.
              Some advanced features may be limited due to hosting restrictions.
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
    
    # Install dependencies and build
    npm install
    npm run build
    
    cd ..
    
    print_success "gSpy application setup completed."
}

# Function to create .htaccess for shared hosting
create_htaccess() {
    print_status "Creating .htaccess for shared hosting..."
    
    cat > .htaccess << 'EOF'
RewriteEngine On

# Redirect all requests to the Node.js app
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ /gspy/backend/server.js [QSA,L]

# Security headers
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"

# Cache static assets
<FilesMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg)$">
    ExpiresActive On
    ExpiresDefault "access plus 1 year"
    Header set Cache-Control "public, immutable"
</FilesMatch>

# Compress files
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>
EOF
    
    print_success ".htaccess file created."
}

# Function to create database setup instructions
create_database_instructions() {
    print_status "Creating database setup instructions..."
    
    cat > DATABASE_SETUP.md << EOF
# Database Setup for Shared Hosting

Since shared hosting doesn't support MongoDB, you need to use MongoDB Atlas (free tier).

## Step 1: Create MongoDB Atlas Account

1. Go to https://www.mongodb.com/atlas
2. Sign up for a free account
3. Create a new cluster (free tier)
4. Create a database user
5. Get your connection string

## Step 2: Update Configuration

Edit the file: \`backend/.env\`

Update the MONGODB_URI line with your Atlas connection string:

\`\`\`env
MONGODB_URI=mongodb+srv://username:password@cluster0.mongodb.net/gspy?retryWrites=true&w=majority
\`\`\`

## Step 3: Create Database Collections

The application will automatically create the necessary collections when it starts.

## Step 4: Test Connection

Visit: https://$DOMAIN_NAME/api/health

You should see a JSON response indicating the server is healthy.

## Alternative: Use MySQL (if available)

If your shared hosting supports MySQL, you can modify the backend to use MySQL instead of MongoDB.

Contact your hosting provider for MySQL credentials.
EOF
    
    print_success "Database setup instructions created."
}

# Function to create startup script
create_startup_script() {
    print_status "Creating startup script..."
    
    cat > start.sh << 'EOF'
#!/bin/bash

echo "Starting gSpy on shared hosting..."

# Navigate to backend directory
cd backend

# Start the Node.js application
node server.js
EOF
    
    chmod +x start.sh
    
    print_success "Startup script created."
}

# Function to create monitoring script
create_monitoring_script() {
    print_status "Creating monitoring script..."
    
    cat > monitor.sh << 'EOF'
#!/bin/bash

echo "=== gSpy Shared Hosting Status ==="
echo "Date: $(date)"
echo "Directory: $(pwd)"
echo ""

# Check if Node.js is running
if pgrep -x "node" > /dev/null; then
    echo "✅ Node.js is running"
else
    echo "❌ Node.js is not running"
fi

# Check disk usage
echo ""
echo "=== Disk Usage ==="
df -h . | tail -1

# Check memory usage
echo ""
echo "=== Memory Usage ==="
free -h | grep Mem

# Check application logs
echo ""
echo "=== Recent Logs ==="
tail -5 logs/app.log 2>/dev/null || echo "No logs found"
EOF
    
    chmod +x monitor.sh
    
    print_success "Monitoring script created."
}

# Function to create backup script
create_backup_script() {
    print_status "Creating backup script..."
    
    cat > backup.sh << 'EOF'
#!/bin/bash

# Backup script for shared hosting
BACKUP_DIR="backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="gspy_backup_$DATE.tar.gz"

# Create backup directory
mkdir -p $BACKUP_DIR

# Create backup
tar -czf $BACKUP_DIR/$BACKUP_FILE \
    --exclude=node_modules \
    --exclude=logs \
    --exclude=uploads \
    --exclude=backups \
    .

# Keep only last 5 backups (due to space limitations)
find $BACKUP_DIR -name "gspy_backup_*.tar.gz" -mtime +5 -delete

echo "Backup completed: $BACKUP_FILE"
echo "Backup size: $(du -h $BACKUP_DIR/$BACKUP_FILE | cut -f1)"
EOF
    
    chmod +x backup.sh
    
    print_success "Backup script created."
}

# Function to display final information
display_final_info() {
    echo ""
    echo "=========================================="
    echo "    gSpy Shared Hosting Setup Complete!   "
    echo "=========================================="
    echo ""
    echo "🎉 gSpy has been set up on your Hostinger shared hosting!"
    echo ""
    echo "📋 Setup Information:"
    echo "   Domain: https://$DOMAIN_NAME"
    echo "   Admin Email: $ADMIN_EMAIL"
    echo "   Admin Password: $ADMIN_PASSWORD"
    echo "   Database: $DB_NAME (MongoDB Atlas required)"
    echo ""
    echo "📁 Important Files:"
    echo "   Application: $DEPLOY_DIR"
    echo "   Backend: $DEPLOY_DIR/backend"
    echo "   Frontend: $DEPLOY_DIR/frontend/build"
    echo "   Logs: $DEPLOY_DIR/logs"
    echo "   Backups: $DEPLOY_DIR/backups"
    echo ""
    echo "🔧 Management Commands:"
    echo "   Start app: cd $DEPLOY_DIR && ./start.sh"
    echo "   Monitor: cd $DEPLOY_DIR && ./monitor.sh"
    echo "   Backup: cd $DEPLOY_DIR && ./backup.sh"
    echo ""
    echo "⚠️  Important Notes for Shared Hosting:"
    echo "   - Some advanced features are limited"
    echo "   - Use MongoDB Atlas for database"
    echo "   - Monitor resource usage carefully"
    echo "   - Regular backups are essential"
    echo ""
    echo "📚 Next Steps:"
    echo "   1. Set up MongoDB Atlas database"
    echo "   2. Update backend/.env with database credentials"
    echo "   3. Start the application"
    echo "   4. Access your dashboard"
    echo ""
    echo "📖 Documentation:"
    echo "   - Database setup: DATABASE_SETUP.md"
    echo "   - Shared hosting limitations: README_SHARED.md"
    echo ""
    echo "⚠️  Legal Compliance:"
    echo "   - Ensure compliance with local laws"
    echo "   - Obtain proper consent for monitoring"
    echo "   - Follow data protection regulations"
    echo ""
}

# Main deployment function
main() {
    echo "=========================================="
    echo "    gSpy Shared Hosting Deployment       "
    echo "=========================================="
    echo ""
    
    # Check requirements
    check_requirements
    
    # Get configuration
    get_configuration
    
    # Create deployment directory
    create_deployment_directory
    
    # Setup gSpy
    setup_gspy
    
    # Create .htaccess
    create_htaccess
    
    # Create database instructions
    create_database_instructions
    
    # Create startup script
    create_startup_script
    
    # Create monitoring script
    create_monitoring_script
    
    # Create backup script
    create_backup_script
    
    # Display final information
    display_final_info
}

# Run main function
main "$@" 