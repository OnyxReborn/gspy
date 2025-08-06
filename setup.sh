#!/bin/bash

# gSpy Setup Script
# This script sets up the complete gSpy monitoring solution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check Node.js
    if ! command_exists node; then
        print_error "Node.js is not installed. Please install Node.js 18+ first."
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
    
    # Check Docker
    if ! command_exists docker; then
        print_warning "Docker is not installed. Some features may not work."
    fi
    
    # Check Docker Compose
    if ! command_exists docker-compose; then
        print_warning "Docker Compose is not installed. Some features may not work."
    fi
    
    print_success "System requirements check completed."
}

# Function to create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    mkdir -p backend/logs
    mkdir -p backend/uploads
    mkdir -p frontend/build
    mkdir -p mobile/android
    mkdir -p mobile/ios
    mkdir -p docs
    mkdir -p docker/nginx
    mkdir -p docker/prometheus
    mkdir -p docker/grafana
    mkdir -p docker/traefik
    mkdir -p docker/mongo
    
    print_success "Directory structure created."
}

# Function to install backend dependencies
install_backend() {
    print_status "Installing backend dependencies..."
    
    cd backend
    
    # Install dependencies
    npm install
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        cp env.example .env
        print_warning "Backend .env file created. Please configure it with your settings."
    fi
    
    cd ..
    print_success "Backend dependencies installed."
}

# Function to install frontend dependencies
install_frontend() {
    print_status "Installing frontend dependencies..."
    
    cd frontend
    
    # Install dependencies
    npm install
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        cat > .env << EOF
REACT_APP_API_URL=http://localhost:5000/api
REACT_APP_SOCKET_URL=http://localhost:5000
REACT_APP_ENVIRONMENT=development
EOF
        print_warning "Frontend .env file created. Please configure it with your settings."
    fi
    
    cd ..
    print_success "Frontend dependencies installed."
}

# Function to install mobile dependencies
install_mobile() {
    print_status "Installing mobile dependencies..."
    
    cd mobile
    
    # Install dependencies
    npm install
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        cat > .env << EOF
EXPO_PUBLIC_API_URL=http://localhost:5000/api
EXPO_PUBLIC_SOCKET_URL=http://localhost:5000
EXPO_PUBLIC_ENVIRONMENT=development
EOF
        print_warning "Mobile .env file created. Please configure it with your settings."
    fi
    
    cd ..
    print_success "Mobile dependencies installed."
}

# Function to setup database
setup_database() {
    print_status "Setting up database..."
    
    # Check if MongoDB is running
    if command_exists docker && docker ps | grep -q mongodb; then
        print_status "MongoDB is already running in Docker."
    else
        print_warning "MongoDB is not running. Please start it manually or use Docker Compose."
    fi
    
    # Check if Redis is running
    if command_exists docker && docker ps | grep -q redis; then
        print_status "Redis is already running in Docker."
    else
        print_warning "Redis is not running. Please start it manually or use Docker Compose."
    fi
}

# Function to create Docker configuration files
create_docker_configs() {
    print_status "Creating Docker configuration files..."
    
    # Create backend Dockerfile
    cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Create necessary directories
RUN mkdir -p logs uploads

# Expose port
EXPOSE 5000

# Start the application
CMD ["npm", "start"]
EOF

    # Create frontend Dockerfile
    cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built files
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 3000

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

    # Create nginx configuration
    cat > frontend/nginx.conf << 'EOF'
server {
    listen 3000;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

    print_success "Docker configuration files created."
}

# Function to create startup scripts
create_startup_scripts() {
    print_status "Creating startup scripts..."
    
    # Create start script
    cat > start.sh << 'EOF'
#!/bin/bash

echo "Starting gSpy application..."

# Start backend
cd backend
npm run dev &
BACKEND_PID=$!

# Start frontend
cd ../frontend
npm start &
FRONTEND_PID=$!

# Wait for processes
wait $BACKEND_PID $FRONTEND_PID
EOF

    # Create stop script
    cat > stop.sh << 'EOF'
#!/bin/bash

echo "Stopping gSpy application..."

# Kill backend process
pkill -f "npm run dev"

# Kill frontend process
pkill -f "npm start"

echo "gSpy application stopped."
EOF

    # Create Docker start script
    cat > start-docker.sh << 'EOF'
#!/bin/bash

echo "Starting gSpy with Docker Compose..."

# Start all services
docker-compose up -d

echo "gSpy is starting up..."
echo "Dashboard: http://localhost:3000"
echo "API: http://localhost:5000"
echo "Database: http://localhost:8080"
echo "Redis: http://localhost:8081"
echo "Monitoring: http://localhost:3001"
EOF

    # Create Docker stop script
    cat > stop-docker.sh << 'EOF'
#!/bin/bash

echo "Stopping gSpy Docker services..."

# Stop all services
docker-compose down

echo "gSpy Docker services stopped."
EOF

    # Make scripts executable
    chmod +x start.sh stop.sh start-docker.sh stop-docker.sh
    
    print_success "Startup scripts created."
}

# Function to create documentation
create_documentation() {
    print_status "Creating documentation..."
    
    # Create API documentation
    cat > docs/API.md << 'EOF'
# gSpy API Documentation

## Authentication
All API endpoints require authentication using JWT tokens.

### Login
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password"
}

### Register
POST /api/auth/register
{
  "email": "user@example.com",
  "password": "password",
  "firstName": "John",
  "lastName": "Doe"
}

## Devices
GET /api/devices - Get all devices
POST /api/devices - Add new device
GET /api/devices/:id - Get device details
PUT /api/devices/:id - Update device
DELETE /api/devices/:id - Remove device

## Monitoring
GET /api/monitoring/keylogger/:deviceId - Get keylogger data
GET /api/monitoring/calls/:deviceId - Get call logs
GET /api/monitoring/messages/:deviceId - Get message logs
GET /api/monitoring/location/:deviceId - Get location data
GET /api/monitoring/social-media/:deviceId - Get social media data

## Analytics
GET /api/analytics/overview - Get analytics overview
GET /api/analytics/usage/:deviceId - Get device usage analytics
GET /api/analytics/reports - Get reports
EOF

    # Create deployment guide
    cat > docs/DEPLOYMENT.md << 'EOF'
# gSpy Deployment Guide

## Prerequisites
- Node.js 18+
- MongoDB 6+
- Redis 7+
- Docker (optional)

## Local Development Setup
1. Clone the repository
2. Run setup script: `./setup.sh`
3. Configure environment variables
4. Start services: `./start.sh`

## Docker Deployment
1. Run setup script: `./setup.sh`
2. Configure environment variables
3. Start with Docker: `./start-docker.sh`

## Production Deployment
1. Set NODE_ENV=production
2. Configure SSL certificates
3. Set up monitoring and logging
4. Configure backup strategies
5. Set up load balancing

## Security Considerations
- Use strong passwords
- Enable SSL/TLS
- Configure firewall rules
- Regular security updates
- Monitor access logs
EOF

    print_success "Documentation created."
}

# Function to create gitignore
create_gitignore() {
    print_status "Creating .gitignore files..."
    
    # Root .gitignore
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Build outputs
build/
dist/
*.tgz
*.tar.gz

# Logs
logs/
*.log

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/

# nyc test coverage
.nyc_output

# Dependency directories
jspm_packages/

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Docker
.dockerignore

# Temporary files
tmp/
temp/

# Uploads
uploads/

# Backups
backups/

# SSL certificates
*.pem
*.key
*.crt

# Database files
*.db
*.sqlite
*.sqlite3

# Mobile build files
mobile/android/app/build/
mobile/ios/build/
mobile/expo/
EOF

    print_success ".gitignore files created."
}

# Function to display final instructions
display_instructions() {
    echo ""
    echo "=========================================="
    echo "           gSpy Setup Complete!           "
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Configure environment variables:"
    echo "   - Backend: Edit backend/.env"
    echo "   - Frontend: Edit frontend/.env"
    echo "   - Mobile: Edit mobile/.env"
    echo ""
    echo "2. Start the application:"
    echo "   - Local development: ./start.sh"
    echo "   - Docker: ./start-docker.sh"
    echo ""
    echo "3. Access the application:"
    echo "   - Dashboard: http://localhost:3000"
    echo "   - API: http://localhost:5000"
    echo "   - Database: http://localhost:8080"
    echo "   - Redis: http://localhost:8081"
    echo "   - Monitoring: http://localhost:3001"
    echo ""
    echo "4. Documentation:"
    echo "   - API: docs/API.md"
    echo "   - Deployment: docs/DEPLOYMENT.md"
    echo ""
    echo "5. Security:"
    echo "   - Change default passwords"
    echo "   - Configure SSL certificates"
    echo "   - Set up firewall rules"
    echo ""
    echo "For support, visit: https://github.com/your-repo/gspy"
    echo ""
}

# Main setup function
main() {
    echo "=========================================="
    echo "           gSpy Setup Script              "
    echo "=========================================="
    echo ""
    
    # Check requirements
    check_requirements
    
    # Create directory structure
    create_directories
    
    # Install dependencies
    install_backend
    install_frontend
    install_mobile
    
    # Setup database
    setup_database
    
    # Create Docker configurations
    create_docker_configs
    
    # Create startup scripts
    create_startup_scripts
    
    # Create documentation
    create_documentation
    
    # Create gitignore
    create_gitignore
    
    # Display final instructions
    display_instructions
}

# Run main function
main "$@" 