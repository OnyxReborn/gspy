#!/bin/bash

# gSpy Hostinger Deployment Script
# This script deploys gSpy to a Hostinger hosting server

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
DB_NAME=""
DB_USER=""
DB_PASS=""
JWT_SECRET=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""

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

# Function to generate JWT secret
generate_jwt_secret() {
    openssl rand -base64 64 | tr -d "=+/"
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
    
    # Check if running on Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "This script is designed for Linux servers. Please run on your Hostinger server."
        exit 1
    fi
    
    # Check Node.js
    if ! command_exists node; then
        print_error "Node.js is not installed. Please install Node.js 18+ first."
        print_status "You can install Node.js using: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version 18+ is required. Current version: $(node -v)"
        exit 1
    fi
    
    # Check npm
    if ! command_exists npm; then
        print_error "npm is not installed."
        exit 1
    fi
    
    # Check git
    if ! command_exists git; then
        print_error "Git is not installed. Please install git first."
        exit 1
    fi
    
    # Check PM2
    if ! command_exists pm2; then
        print_warning "PM2 is not installed. Installing PM2..."
        npm install -g pm2
    fi
    
    # Check nginx
    if ! command_exists nginx; then
        print_warning "Nginx is not installed. Installing Nginx..."
        sudo apt-get update
        sudo apt-get install -y nginx
    fi
    
    # Check certbot
    if ! command_exists certbot; then
        print_warning "Certbot is not installed. Installing Certbot..."
        sudo apt-get install -y certbot python3-certbot-nginx
    fi
    
    print_success "System requirements check completed."
}

# Function to get configuration from user
get_configuration() {
    echo ""
    echo "=========================================="
    echo "        gSpy Configuration Setup          "
    echo "=========================================="
    echo ""
    
    DOMAIN_NAME=$(get_input "Enter your domain name (e.g., gspy.yourdomain.com)" "")
    EMAIL=$(get_input "Enter your email address" "")
    DB_NAME=$(get_input "Enter database name" "gspy_db")
    DB_USER=$(get_input "Enter database username" "gspy_user")
    DB_PASS=$(get_input "Enter database password (leave empty to generate)" "")
    ADMIN_EMAIL=$(get_input "Enter admin email for dashboard" "$EMAIL")
    ADMIN_PASSWORD=$(get_input "Enter admin password (leave empty to generate)" "")
    
    # Generate passwords if not provided
    if [ -z "$DB_PASS" ]; then
        DB_PASS=$(generate_password)
        print_status "Generated database password: $DB_PASS"
    fi
    
    if [ -z "$ADMIN_PASSWORD" ]; then
        ADMIN_PASSWORD=$(generate_password)
        print_status "Generated admin password: $ADMIN_PASSWORD"
    fi
    
    # Generate JWT secret
    JWT_SECRET=$(generate_jwt_secret)
    
    echo ""
    echo "Configuration Summary:"
    echo "Domain: $DOMAIN_NAME"
    echo "Email: $EMAIL"
    echo "Database: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Admin Email: $ADMIN_EMAIL"
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
    
    DEPLOY_DIR="/var/www/gspy"
    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown -R $USER:$USER "$DEPLOY_DIR"
    
    cd "$DEPLOY_DIR"
    
    print_success "Deployment directory created: $DEPLOY_DIR"
}

# Function to clone and setup gSpy
setup_gspy() {
    print_status "Setting up gSpy application..."
    
    # Clone the repository (replace with your actual repository URL)
    git clone https://github.com/your-username/gspy.git .
    
    # Install backend dependencies
    cd backend
    npm install --production
    
    # Create production environment file
    cat > .env << EOF
# Server Configuration
NODE_ENV=production
PORT=5000
HOST=0.0.0.0

# Database Configuration
MONGODB_URI=mongodb://$DB_USER:$DB_PASS@localhost:27017/$DB_NAME
MONGODB_USER=$DB_USER
MONGODB_PASS=$DB_PASS

# Redis Configuration (if available)
REDIS_URL=redis://localhost:6379

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d

# Session Configuration
SESSION_SECRET=$(generate_jwt_secret)
SESSION_MAX_AGE=86400000

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

# Monitoring Configuration
ENABLE_MONITORING=true
MONITORING_INTERVAL=300000
DATA_RETENTION_DAYS=90

# Logging Configuration
LOG_LEVEL=info
LOG_FILE_PATH=./logs
ENABLE_REQUEST_LOGGING=true

# Feature Flags
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

# API Configuration
API_VERSION=v1
API_PREFIX=/api
ENABLE_API_DOCUMENTATION=true
SWAGGER_UI_PATH=/api-docs

# WebSocket Configuration
SOCKET_CORS_ORIGIN=https://$DOMAIN_NAME
SOCKET_PING_TIMEOUT=60000
SOCKET_PING_INTERVAL=25000

# Background Jobs Configuration
ENABLE_BACKGROUND_JOBS=true
JOB_QUEUE_REDIS_URL=redis://localhost:6379/1
MAX_CONCURRENT_JOBS=5

# Backup Configuration
ENABLE_AUTO_BACKUP=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
BACKUP_STORAGE_PATH=./backups

# Analytics Configuration
ENABLE_ANALYTICS=true
ANALYTICS_PROVIDER=mixpanel
MIXPANEL_TOKEN=your-mixpanel-token
GOOGLE_ANALYTICS_ID=your-ga-id

# Payment Configuration
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
STRIPE_WEBHOOK_SECRET=your-stripe-webhook-secret
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-client-secret

# Notification Configuration
ENABLE_PUSH_NOTIFICATIONS=true
FIREBASE_SERVER_KEY=your-firebase-server-key
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-client-email

# Encryption Configuration
ENCRYPTION_KEY=$(generate_jwt_secret)
ENABLE_END_TO_END_ENCRYPTION=true

# Geolocation Configuration
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
GEOCODING_SERVICE=google
DEFAULT_COUNTRY=US

# Development Configuration
ENABLE_DEBUG_MODE=false
ENABLE_TEST_MODE=false
MOCK_DATA_ENABLED=false
EOF
    
    # Create logs directory
    mkdir -p logs uploads backups
    
    cd ..
    
    # Install frontend dependencies
    cd frontend
    npm install
    
    # Create production environment file
    cat > .env << EOF
REACT_APP_API_URL=https://$DOMAIN_NAME/api
REACT_APP_SOCKET_URL=https://$DOMAIN_NAME
REACT_APP_ENVIRONMENT=production
REACT_APP_DOMAIN=$DOMAIN_NAME
EOF
    
    # Build frontend for production
    npm run build
    
    cd ..
    
    print_success "gSpy application setup completed."
}

# Function to setup database
setup_database() {
    print_status "Setting up database..."
    
    # Check if MongoDB is installed
    if ! command_exists mongod; then
        print_warning "MongoDB is not installed. Installing MongoDB..."
        
        # Add MongoDB repository
        wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
        
        # Install MongoDB
        sudo apt-get update
        sudo apt-get install -y mongodb-org
        
        # Start and enable MongoDB
        sudo systemctl start mongod
        sudo systemctl enable mongod
    fi
    
    # Create database and user
    mongo --eval "
        use $DB_NAME;
        db.createUser({
            user: '$DB_USER',
            pwd: '$DB_PASS',
            roles: [
                { role: 'readWrite', db: '$DB_NAME' },
                { role: 'dbAdmin', db: '$DB_NAME' }
            ]
        });
    "
    
    print_success "Database setup completed."
}

# Function to setup Redis
setup_redis() {
    print_status "Setting up Redis..."
    
    # Check if Redis is installed
    if ! command_exists redis-server; then
        print_warning "Redis is not installed. Installing Redis..."
        sudo apt-get install -y redis-server
    fi
    
    # Start and enable Redis
    sudo systemctl start redis-server
    sudo systemctl enable redis-server
    
    print_success "Redis setup completed."
}

# Function to create PM2 ecosystem file
create_pm2_config() {
    print_status "Creating PM2 configuration..."
    
    cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'gspy-backend',
      script: './backend/src/server.js',
      cwd: '/var/www/gspy',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 5000
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',
      time: true,
      max_memory_restart: '1G',
      node_args: '--max-old-space-size=1024'
    }
  ]
};
EOF
    
    print_success "PM2 configuration created."
}

# Function to setup Nginx
setup_nginx() {
    print_status "Setting up Nginx..."
    
    # Create Nginx configuration
    sudo tee /etc/nginx/sites-available/gspy << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;
    
    # SSL Configuration (will be configured by Certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Frontend
    location / {
        root /var/www/gspy/frontend/build;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API Backend
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # WebSocket support
    location /socket.io {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:5000;
        access_log off;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;
}
EOF
    
    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/gspy /etc/nginx/sites-enabled/
    
    # Test Nginx configuration
    sudo nginx -t
    
    # Reload Nginx
    sudo systemctl reload nginx
    
    print_success "Nginx configuration completed."
}

# Function to setup SSL certificate
setup_ssl() {
    print_status "Setting up SSL certificate..."
    
    # Obtain SSL certificate
    sudo certbot --nginx -d $DOMAIN_NAME --email $EMAIL --agree-tos --non-interactive
    
    # Setup auto-renewal
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    print_success "SSL certificate setup completed."
}

# Function to create admin user
create_admin_user() {
    print_status "Creating admin user..."
    
    # Create admin user script
    cat > create_admin.js << EOF
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./backend/src/models/User');

async function createAdmin() {
    try {
        await mongoose.connect('mongodb://$DB_USER:$DB_PASS@localhost:27017/$DB_NAME');
        
        // Check if admin already exists
        const existingAdmin = await User.findOne({ email: '$ADMIN_EMAIL' });
        if (existingAdmin) {
            console.log('Admin user already exists');
            process.exit(0);
        }
        
        // Create admin user
        const hashedPassword = await bcrypt.hash('$ADMIN_PASSWORD', 12);
        const adminUser = new User({
            email: '$ADMIN_EMAIL',
            password: hashedPassword,
            firstName: 'Admin',
            lastName: 'User',
            role: 'super_admin',
            emailVerified: true,
            subscription: {
                plan: 'enterprise',
                status: 'active',
                startDate: new Date(),
                endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year
                autoRenew: true
            }
        });
        
        await adminUser.save();
        console.log('Admin user created successfully');
        console.log('Email: $ADMIN_EMAIL');
        console.log('Password: $ADMIN_PASSWORD');
        
    } catch (error) {
        console.error('Error creating admin user:', error);
    } finally {
        await mongoose.disconnect();
    }
}

createAdmin();
EOF
    
    # Run the script
    cd /var/www/gspy
    node create_admin.js
    
    print_success "Admin user created."
}

# Function to setup firewall
setup_firewall() {
    print_status "Setting up firewall..."
    
    # Allow SSH, HTTP, HTTPS
    sudo ufw allow ssh
    sudo ufw allow 80
    sudo ufw allow 443
    
    # Enable firewall
    echo "y" | sudo ufw enable
    
    print_success "Firewall configured."
}

# Function to setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Install monitoring tools
    sudo apt-get install -y htop iotop nethogs
    
    # Create monitoring script
    cat > /var/www/gspy/monitor.sh << 'EOF'
#!/bin/bash

# Simple monitoring script
echo "=== gSpy Server Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Memory: $(free -h | grep Mem)"
echo "Disk: $(df -h / | tail -1)"
echo "CPU Load: $(cat /proc/loadavg)"
echo ""

# Check if services are running
echo "=== Service Status ==="
echo "MongoDB: $(systemctl is-active mongod)"
echo "Redis: $(systemctl is-active redis-server)"
echo "Nginx: $(systemctl is-active nginx)"
echo "PM2: $(pm2 status | grep gspy-backend | awk '{print $10}')"
echo ""

# Check application logs
echo "=== Recent Errors ==="
tail -5 /var/www/gspy/logs/err.log 2>/dev/null || echo "No error logs found"
EOF
    
    chmod +x /var/www/gspy/monitor.sh
    
    print_success "Monitoring setup completed."
}

# Function to create backup script
create_backup_script() {
    print_status "Creating backup script..."
    
    cat > /var/www/gspy/backup.sh << EOF
#!/bin/bash

# Backup script for gSpy
BACKUP_DIR="/var/www/gspy/backups"
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="gspy_backup_\$DATE.tar.gz"

# Create backup directory
mkdir -p \$BACKUP_DIR

# Backup database
mongodump --uri="mongodb://$DB_USER:$DB_PASS@localhost:27017/$DB_NAME" --out=\$BACKUP_DIR/db_\$DATE

# Backup application files
tar -czf \$BACKUP_DIR/\$BACKUP_FILE \\
    --exclude=node_modules \\
    --exclude=logs \\
    --exclude=uploads \\
    --exclude=backups \\
    /var/www/gspy

# Keep only last 7 backups
find \$BACKUP_DIR -name "gspy_backup_*.tar.gz" -mtime +7 -delete
find \$BACKUP_DIR -name "db_*" -mtime +7 -exec rm -rf {} \;

echo "Backup completed: \$BACKUP_FILE"
EOF
    
    chmod +x /var/www/gspy/backup.sh
    
    # Add to crontab (daily backup at 2 AM)
    (crontab -l 2>/dev/null; echo "0 2 * * * /var/www/gspy/backup.sh") | crontab -
    
    print_success "Backup script created."
}

# Function to start services
start_services() {
    print_status "Starting services..."
    
    # Start PM2
    cd /var/www/gspy
    pm2 start ecosystem.config.js
    pm2 save
    pm2 startup
    
    # Ensure services are running
    sudo systemctl enable mongod
    sudo systemctl enable redis-server
    sudo systemctl enable nginx
    
    print_success "Services started successfully."
}

# Function to display final information
display_final_info() {
    echo ""
    echo "=========================================="
    echo "        gSpy Deployment Complete!         "
    echo "=========================================="
    echo ""
    echo "🎉 gSpy has been successfully deployed to your Hostinger server!"
    echo ""
    echo "📋 Deployment Information:"
    echo "   Domain: https://$DOMAIN_NAME"
    echo "   Admin Email: $ADMIN_EMAIL"
    echo "   Admin Password: $ADMIN_PASSWORD"
    echo "   Database: $DB_NAME"
    echo "   Database User: $DB_USER"
    echo "   Database Password: $DB_PASS"
    echo ""
    echo "🔧 Management Commands:"
    echo "   View logs: pm2 logs gspy-backend"
    echo "   Restart app: pm2 restart gspy-backend"
    echo "   Monitor server: /var/www/gspy/monitor.sh"
    echo "   Manual backup: /var/www/gspy/backup.sh"
    echo ""
    echo "📁 Important Files:"
    echo "   Application: /var/www/gspy"
    echo "   Logs: /var/www/gspy/logs"
    echo "   Backups: /var/www/gspy/backups"
    echo "   Nginx config: /etc/nginx/sites-available/gspy"
    echo ""
    echo "🔒 Security Notes:"
    echo "   - Change default passwords"
    echo "   - Update JWT secrets in production"
    echo "   - Configure email settings"
    echo "   - Set up monitoring alerts"
    echo ""
    echo "📞 Support:"
    echo "   - Check logs for errors"
    echo "   - Monitor server resources"
    echo "   - Regular backups are automated"
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
    echo "      gSpy Hostinger Deployment          "
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
    
    # Setup database
    setup_database
    
    # Setup Redis
    setup_redis
    
    # Create PM2 config
    create_pm2_config
    
    # Setup Nginx
    setup_nginx
    
    # Setup SSL
    setup_ssl
    
    # Create admin user
    create_admin_user
    
    # Setup firewall
    setup_firewall
    
    # Setup monitoring
    setup_monitoring
    
    # Create backup script
    create_backup_script
    
    # Start services
    start_services
    
    # Display final information
    display_final_info
}

# Run main function
main "$@" 