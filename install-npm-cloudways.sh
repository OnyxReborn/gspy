#!/bin/bash

# npm Installation Script for Cloudways
# This script installs npm on Cloudways without requiring sudo privileges

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check current Node.js and npm status
check_current_status() {
    print_status "Checking current Node.js and npm status..."
    
    echo "=== Current Status ==="
    echo "Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
    echo "npm: $(npm --version 2>/dev/null || echo 'Not installed')"
    echo "nvm: $(nvm --version 2>/dev/null || echo 'Not installed')"
    echo ""
}

# Function to install nvm
install_nvm() {
    print_status "Installing nvm (Node Version Manager)..."
    
    if command_exists nvm; then
        print_success "nvm is already installed: $(nvm --version)"
        return 0
    fi
    
    # Download and install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Export nvm environment
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Verify nvm installation
    if command_exists nvm; then
        print_success "nvm installed successfully: $(nvm --version)"
    else
        print_error "nvm installation failed"
        return 1
    fi
}

# Function to install Node.js with npm using nvm
install_nodejs_npm() {
    print_status "Installing Node.js with npm using nvm..."
    
    # Export nvm environment
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Check current Node.js version
    CURRENT_NODE_VERSION=$(node --version 2>/dev/null || echo "none")
    TARGET_VERSION="18.19.0"
    
    if [ "$CURRENT_NODE_VERSION" = "v$TARGET_VERSION" ]; then
        print_success "Node.js $TARGET_VERSION is already installed"
    else
        print_status "Installing Node.js $TARGET_VERSION..."
        nvm install $TARGET_VERSION
        nvm use $TARGET_VERSION
        nvm alias default $TARGET_VERSION
        print_success "Node.js $TARGET_VERSION installed successfully"
    fi
    
    # Verify npm installation
    if command_exists npm; then
        print_success "npm installed successfully: $(npm --version)"
    else
        print_error "npm installation failed"
        return 1
    fi
}

# Function to configure npm
configure_npm() {
    print_status "Configuring npm..."
    
    # Create npm global directory
    mkdir -p ~/.npm-global
    
    # Configure npm
    npm config set prefix '~/.npm-global'
    npm config set registry https://registry.npmjs.org/
    npm config set cache ~/.npm-cache
    
    # Add to PATH
    if ! grep -q "npm-global" ~/.bashrc; then
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
        print_success "Added npm global path to .bashrc"
    else
        print_status "npm global path already in .bashrc"
    fi
    
    # Reload shell configuration
    source ~/.bashrc
    
    print_success "npm configured successfully"
}

# Function to install PM2 globally
install_pm2() {
    print_status "Installing PM2 globally..."
    
    if command_exists pm2; then
        print_success "PM2 is already installed: $(pm2 --version)"
        return 0
    fi
    
    # Install PM2
    npm install -g pm2
    
    if command_exists pm2; then
        print_success "PM2 installed successfully: $(pm2 --version)"
    else
        print_warning "PM2 installation failed, but continuing..."
    fi
}

# Function to test installation
test_installation() {
    print_status "Testing installation..."
    
    echo "=== Installation Test ==="
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "nvm: $(nvm --version)"
    echo "PM2: $(pm2 --version 2>/dev/null || echo 'Not installed')"
    echo "npm prefix: $(npm config get prefix)"
    echo "npm cache: $(npm config get cache)"
    echo "npm registry: $(npm config get registry)"
    echo ""
    
    # Test npm functionality
    print_status "Testing npm functionality..."
    npm --version >/dev/null 2>&1 && print_success "npm is working correctly" || print_error "npm is not working"
}

# Function to create environment setup script
create_setup_script() {
    print_status "Creating environment setup script..."
    
    cat > ~/setup-nvm.sh << 'EOF'
#!/bin/bash
# nvm Environment Setup Script
# Run this script to set up nvm environment in new shell sessions

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Add npm global path
export PATH=~/.npm-global/bin:$PATH

echo "nvm environment loaded successfully"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
EOF
    
    chmod +x ~/setup-nvm.sh
    print_success "Environment setup script created: ~/setup-nvm.sh"
}

# Function to display usage instructions
display_instructions() {
    echo ""
    echo "=========================================="
    echo "    npm Installation Complete!            "
    echo "=========================================="
    echo ""
    echo "🎉 npm has been successfully installed on your Cloudways server!"
    echo ""
    echo "📋 Installation Summary:"
    echo "   Node.js: $(node --version)"
    echo "   npm: $(npm --version)"
    echo "   nvm: $(nvm --version)"
    echo "   PM2: $(pm2 --version 2>/dev/null || echo 'Not installed')"
    echo ""
    echo "🔧 Next Steps:"
    echo "   1. Restart your terminal or run: source ~/.bashrc"
    echo "   2. Test npm: npm --version"
    echo "   3. Install global packages: npm install -g package-name"
    echo "   4. Use the setup script: source ~/setup-nvm.sh"
    echo ""
    echo "📁 Important Files:"
    echo "   nvm installation: ~/.nvm"
    echo "   npm global packages: ~/.npm-global"
    echo "   npm cache: ~/.npm-cache"
    echo "   setup script: ~/setup-nvm.sh"
    echo ""
    echo "🛠️  Useful Commands:"
    echo "   nvm list                    # List installed Node.js versions"
    echo "   nvm install 16.20.0        # Install specific Node.js version"
    echo "   nvm use 16.20.0            # Switch to specific version"
    echo "   npm install -g pm2         # Install PM2 globally"
    echo "   npm list -g --depth=0      # List global packages"
    echo ""
    echo "⚠️  Important Notes:"
    echo "   - Always run 'source ~/.bashrc' in new terminal sessions"
    echo "   - Use 'source ~/setup-nvm.sh' to quickly set up environment"
    echo "   - npm global packages are installed in ~/.npm-global"
    echo ""
}

# Function to check system requirements
check_system_requirements() {
    print_status "Checking system requirements..."
    
    # Check if we're on a Linux system
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_warning "This script is designed for Linux systems"
    fi
    
    # Check available disk space
    DISK_SPACE=$(df ~ | awk 'NR==2 {print $4}')
    DISK_SPACE_MB=$((DISK_SPACE / 1024))
    
    if [ $DISK_SPACE_MB -lt 500 ]; then
        print_warning "Low disk space: ${DISK_SPACE_MB}MB available (500MB recommended)"
    else
        print_success "Disk space: ${DISK_SPACE_MB}MB available"
    fi
    
    # Check internet connectivity
    if curl -s --connect-timeout 5 https://registry.npmjs.org/ >/dev/null; then
        print_success "Internet connectivity: OK"
    else
        print_error "No internet connectivity. Please check your connection."
        exit 1
    fi
    
    echo ""
}

# Main installation function
main() {
    echo "=========================================="
    echo "    npm Installation for Cloudways        "
    echo "=========================================="
    echo ""
    echo "This script will install npm on your Cloudways server"
    echo "without requiring sudo privileges."
    echo ""
    
    # Check system requirements
    check_system_requirements
    
    # Check current status
    check_current_status
    
    # Ask for confirmation
    read -p "Continue with installation? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled."
        exit 1
    fi
    
    echo ""
    
    # Install nvm
    install_nvm
    
    # Install Node.js with npm
    install_nodejs_npm
    
    # Configure npm
    configure_npm
    
    # Install PM2
    install_pm2
    
    # Test installation
    test_installation
    
    # Create setup script
    create_setup_script
    
    # Display instructions
    display_instructions
    
    print_success "npm installation completed successfully!"
}

# Error handling
cleanup_on_error() {
    print_error "Installation failed. Cleaning up..."
    print_error "Please check the error messages above."
    exit 1
}

# Set trap for error handling
trap cleanup_on_error ERR

# Check if script is run with arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "npm Installation Script for Cloudways"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --test         Test current installation"
    echo "  --setup        Create environment setup script only"
    echo ""
    echo "This script installs npm on Cloudways without sudo privileges."
    exit 0
elif [ "$1" = "--test" ]; then
    check_current_status
    test_installation
    exit 0
elif [ "$1" = "--setup" ]; then
    create_setup_script
    display_instructions
    exit 0
fi

# Run main function
main "$@" 