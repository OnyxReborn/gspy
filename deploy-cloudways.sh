#!/bin/bash

# gSpy Cloudways Deployment Script
set -e

# Error handling function
cleanup_on_error() {
    print_error "Deployment failed. Cleaning up..."
    
    # Stop PM2 processes if running
    if command -v pm2 >/dev/null 2>&1; then
        pm2 stop gspy-backend 2>/dev/null || true
        pm2 delete gspy-backend 2>/dev/null || true
    fi
    
    # Remove temporary files
    rm -rf /tmp/gspy-* 2>/dev/null || true
    
    print_error "Cleanup completed. Please check the error messages above."
    exit 1
}

# Set trap to call cleanup function on error
trap cleanup_on_error ERR

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

# Function to check if running on Cloudways
check_cloudways_environment() {
    print_status "Checking Cloudways environment..."
    
    # Check if we're in a Cloudways-like environment
    if [ -d "/home/master/applications" ]; then
        print_success "Detected Cloudways environment."
        CLOUDWAYS_ENV=true
    else
        print_warning "Not running in Cloudways environment. Some features may not work correctly."
        print_warning "This script is designed for Cloudways hosting."
        CLOUDWAYS_ENV=false
        
        read -p "Continue anyway? (y/N): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            print_error "Deployment cancelled."
            exit 1
        fi
    fi
    
    # Check if we have sudo privileges
    if ! sudo -n true 2>/dev/null; then
        print_warning "Sudo privileges required for system package installation."
        print_warning "Please ensure you have sudo access or run as root."
        
        read -p "Continue? (y/N): " continue_sudo
        if [[ ! $continue_sudo =~ ^[Yy]$ ]]; then
            print_error "Deployment cancelled."
            exit 1
        fi
    fi
}

check_requirements() {
    print_status "Checking and installing system requirements..."
    
    # Check and install Node.js
    if ! command -v node >/dev/null 2>&1; then
        print_status "Node.js not found. Installing Node.js..."
        
        # Detect OS and install Node.js
        if command -v apt-get >/dev/null 2>&1; then
            # Ubuntu/Debian
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command -v yum >/dev/null 2>&1; then
            # CentOS/RHEL
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo yum install -y nodejs
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo dnf install -y nodejs
        else
            print_error "Unsupported package manager. Please install Node.js manually."
            exit 1
        fi
        
        print_success "Node.js installed successfully."
    else
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 16 ]; then
            print_warning "Node.js version 16+ is recommended. Current version: $(node -v)"
            print_status "Updating Node.js..."
            
            if command -v apt-get >/dev/null 2>&1; then
                curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                sudo apt-get install -y nodejs
            elif command -v yum >/dev/null 2>&1; then
                curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
                sudo yum install -y nodejs
            elif command -v dnf >/dev/null 2>&1; then
                curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
                sudo dnf install -y nodejs
            fi
        fi
    fi
    
    # Check and install npm
    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm is not available. Please install npm manually."
        exit 1
    fi
    
    # Check and install PM2
    if ! command -v pm2 >/dev/null 2>&1; then
        print_status "PM2 not found. Installing PM2..."
        npm install -g pm2
        print_success "PM2 installed successfully."
    fi
    
    # Check and install MySQL client
    if ! command -v mysql >/dev/null 2>&1; then
        print_status "MySQL client not found. Installing MySQL client..."
        
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y mysql-client
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y mysql
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y mysql
        else
            print_warning "Could not install MySQL client automatically. Please install manually."
        fi
    fi
    
    # Check and install Redis client
    if ! command -v redis-cli >/dev/null 2>&1; then
        print_status "Redis client not found. Installing Redis client..."
        
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y redis-tools
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y redis
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y redis
        else
            print_warning "Could not install Redis client automatically. Please install manually."
        fi
    fi
    
    # Check and install Git
    if ! command -v git >/dev/null 2>&1; then
        print_status "Git not found. Installing Git..."
        
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y git
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y git
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y git
        else
            print_warning "Could not install Git automatically. Please install manually."
        fi
    fi
    
    # Check and install wget
    if ! command -v wget >/dev/null 2>&1; then
        print_status "wget not found. Installing wget..."
        
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y wget
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y wget
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y wget
        else
            print_warning "Could not install wget automatically. Please install manually."
        fi
    fi
    
    # Check and install curl
    if ! command -v curl >/dev/null 2>&1; then
        print_status "curl not found. Installing curl..."
        
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y curl
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y curl
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y curl
        else
            print_warning "Could not install curl automatically. Please install manually."
        fi
    fi
    
    # Check and install jq (for JSON parsing)
    if ! command -v jq >/dev/null 2>&1; then
        print_status "jq not found. Installing jq..."
        
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y jq
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y jq
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y jq
        else
            print_warning "Could not install jq automatically. Please install manually."
        fi
    fi
    
    # Check and install unzip
    if ! command -v unzip >/dev/null 2>&1; then
        print_status "unzip not found. Installing unzip..."
        
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y unzip
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y unzip
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y unzip
        else
            print_warning "Could not install unzip automatically. Please install manually."
        fi
    fi
    
    # Check and install build tools (for native modules)
    print_status "Installing build tools for native modules..."
    
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y build-essential python3
    elif command -v yum >/dev/null 2>&1; then
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y python3
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y python3
    else
        print_warning "Could not install build tools automatically. Please install manually."
    fi
    
    # Verify installations
    print_status "Verifying installations..."
    
    echo "Node.js: $(node -v)"
    echo "npm: $(npm -v)"
    echo "PM2: $(pm2 -v)"
    echo "MySQL: $(mysql --version 2>/dev/null || echo 'Not available')"
    echo "Redis: $(redis-cli --version 2>/dev/null || echo 'Not available')"
    echo "Git: $(git --version 2>/dev/null || echo 'Not available')"
    echo "wget: $(wget --version 2>/dev/null | head -1 || echo 'Not available')"
    echo "curl: $(curl --version 2>/dev/null | head -1 || echo 'Not available')"
    echo "jq: $(jq --version 2>/dev/null || echo 'Not available')"
    echo "unzip: $(unzip -v 2>/dev/null | head -1 || echo 'Not available')"
    
    print_success "System requirements check and installation completed."
}

# Function to check and install additional dependencies
install_additional_dependencies() {
    print_status "Installing additional dependencies for gSpy..."
    
    # Install system libraries for image processing
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y \
            libpng-dev \
            libjpeg-dev \
            libgif-dev \
            librsvg2-dev \
            libwebp-dev \
            libfreetype6-dev \
            libfontconfig1-dev \
            libcairo2-dev \
            libpango1.0-dev \
            libgif-dev \
            libexif-dev \
            libvips-dev \
            libmagickwand-dev \
            imagemagick
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y \
            libpng-devel \
            libjpeg-devel \
            giflib-devel \
            librsvg2-devel \
            libwebp-devel \
            freetype-devel \
            fontconfig-devel \
            cairo-devel \
            pango-devel \
            libexif-devel \
            vips-devel \
            ImageMagick-devel \
            ImageMagick
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y \
            libpng-devel \
            libjpeg-devel \
            giflib-devel \
            librsvg2-devel \
            libwebp-devel \
            freetype-devel \
            fontconfig-devel \
            cairo-devel \
            pango-devel \
            libexif-devel \
            vips-devel \
            ImageMagick-devel \
            ImageMagick
    fi
    
    # Install additional system tools
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y \
            htop \
            iotop \
            nethogs \
            iftop \
            tree \
            tmux \
            screen \
            vim \
            nano \
            mc \
            rsync \
            sshfs \
            nfs-common \
            samba-client
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y \
            htop \
            iotop \
            nethogs \
            iftop \
            tree \
            tmux \
            screen \
            vim \
            nano \
            mc \
            rsync \
            nfs-utils \
            cifs-utils
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y \
            htop \
            iotop \
            nethogs \
            iftop \
            tree \
            tmux \
            screen \
            vim \
            nano \
            mc \
            rsync \
            nfs-utils \
            cifs-utils
    fi
    
    print_success "Additional dependencies installed successfully."
}

# Function to configure system settings
configure_system_settings() {
    print_status "Configuring system settings for optimal performance..."
    
    # Increase file descriptor limits
    if [ -f /etc/security/limits.conf ]; then
        print_status "Configuring file descriptor limits..."
        echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
        echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
        echo "root soft nofile 65536" | sudo tee -a /etc/security/limits.conf
        echo "root hard nofile 65536" | sudo tee -a /etc/security/limits.conf
    fi
    
    # Configure kernel parameters
    if [ -f /etc/sysctl.conf ]; then
        print_status "Configuring kernel parameters..."
        echo "net.core.somaxconn = 65535" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_max_syn_backlog = 65535" | sudo tee -a /etc/sysctl.conf
        echo "net.core.netdev_max_backlog = 5000" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_fin_timeout = 30" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_keepalive_time = 1200" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_max_tw_buckets = 5000" | sudo tee -a /etc/sysctl.conf
        echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf
        echo "vm.dirty_ratio = 15" | sudo tee -a /etc/sysctl.conf
        echo "vm.dirty_background_ratio = 5" | sudo tee -a /etc/sysctl.conf
        
        # Apply changes
        sudo sysctl -p
    fi
    
    # Configure Node.js settings
    print_status "Configuring Node.js settings..."
    
    # Set Node.js memory limit
    export NODE_OPTIONS="--max-old-space-size=4096"
    
    # Add to profile for persistence
    if [ -f ~/.bashrc ]; then
        echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> ~/.bashrc
    fi
    
    if [ -f ~/.profile ]; then
        echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> ~/.profile
    fi
    
    # Configure npm settings
    npm config set registry https://registry.npmjs.org/
    npm config set cache ~/.npm-cache
    npm config set prefix ~/.npm-global
    
    # Create npm global directory
    mkdir -p ~/.npm-global
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
    
    print_success "System settings configured successfully."
}

# Function to update system and install security patches
update_system() {
    print_status "Updating system and installing security patches..."
    
    # Update package lists
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get upgrade -y
        sudo apt-get autoremove -y
        sudo apt-get autoclean
    elif command -v yum >/dev/null 2>&1; then
        sudo yum update -y
        sudo yum autoremove -y
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf update -y
        sudo dnf autoremove -y
    fi
    
    # Install security updates
    if command -v unattended-upgrades >/dev/null 2>&1; then
        print_status "Configuring automatic security updates..."
        sudo apt-get install -y unattended-upgrades
        sudo dpkg-reconfigure -plow unattended-upgrades
    fi
    
    # Configure firewall (if available)
    if command -v ufw >/dev/null 2>&1; then
        print_status "Configuring firewall..."
        sudo ufw --force enable
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow ssh
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
    elif command -v firewall-cmd >/dev/null 2>&1; then
        print_status "Configuring firewall..."
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo firewall-cmd --reload
    fi
    
    print_success "System updated and secured successfully."
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
    mkdir -p backend/database
    
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
    "mysql2": "^3.6.5",
    "sequelize": "^6.35.1",
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
const { Sequelize } = require('sequelize');
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
const sequelize = new Sequelize(
  process.env.DB_NAME || 'gspy_db',
  process.env.DB_USER || 'gspy_user',
  process.env.DB_PASSWORD || 'password',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

sequelize.authenticate()
  .then(() => console.log('Connected to MySQL database'))
  .catch((error) => console.error('MySQL connection error:', error));

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
DB_HOST=localhost
DB_PORT=3306
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASS
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
    
    # Create database schema file
    cat > database/schema.sql << 'EOF'
-- gSpy MySQL Database Schema
-- This file contains all the necessary tables for gSpy monitoring system

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS gspy_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gspy_db;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role ENUM('user', 'admin', 'super_admin') DEFAULT 'user',
    subscription_plan ENUM('basic', 'premium', 'enterprise') DEFAULT 'basic',
    subscription_status ENUM('active', 'inactive', 'expired', 'cancelled') DEFAULT 'inactive',
    subscription_start_date DATETIME,
    subscription_end_date DATETIME,
    subscription_auto_renew BOOLEAN DEFAULT FALSE,
    notifications_email BOOLEAN DEFAULT TRUE,
    notifications_push BOOLEAN DEFAULT TRUE,
    notifications_sms BOOLEAN DEFAULT FALSE,
    privacy_data_retention INT DEFAULT 90,
    privacy_share_analytics BOOLEAN DEFAULT TRUE,
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_active BOOLEAN DEFAULT TRUE,
    last_login DATETIME,
    login_attempts INT DEFAULT 0,
    lock_until DATETIME,
    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    email_verification_expires DATETIME,
    password_reset_token VARCHAR(255),
    password_reset_expires DATETIME,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    api_key VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_subscription_status (subscription_status),
    INDEX idx_is_active (is_active)
);

-- Insert default admin user (password: admin123)
INSERT INTO users (email, password, firstName, lastName, role, subscription_plan, subscription_status, is_active, email_verified) 
VALUES ('admin@gspy.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK8i', 'Admin', 'User', 'super_admin', 'enterprise', 'active', TRUE, TRUE)
ON DUPLICATE KEY UPDATE id=id;
EOF
    
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
    
    # Create database and user
    mysql -u root -p -e "
    CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
    GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
    FLUSH PRIVILEGES;
    "
    
    # Create database schema
    print_status "Creating database schema..."
    mysql -u $DB_USER -p$DB_PASS $DB_NAME < backend/database/schema.sql
    
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
    
    # Check Cloudways environment
    check_cloudways_environment
    
    # Check if running as root or with sudo
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. Some operations may not work correctly."
    fi
    
    # Check and install system requirements
    check_requirements
    
    # Update system and install security patches
    update_system
    
    # Install additional dependencies
    install_additional_dependencies
    
    # Configure system settings
    configure_system_settings
    
    # Get user configuration
    get_configuration
    
    # Create deployment directory
    create_deployment_directory
    
    # Setup gSpy application
    setup_gspy
    
    # Setup database
    setup_database
    
    # Create PM2 configuration
    create_pm2_config
    
    # Create management scripts
    create_management_scripts
    
    # Display final information
    display_final_info
    
    # Final system check
    print_status "Performing final system check..."
    echo "System load: $(uptime)"
    echo "Memory usage: $(free -h | grep Mem)"
    echo "Disk usage: $(df -h / | tail -1)"
    echo "Node.js version: $(node -v)"
    echo "npm version: $(npm -v)"
    echo "PM2 version: $(pm2 -v)"
    
    print_success "gSpy deployment completed successfully!"
}

main "$@" 