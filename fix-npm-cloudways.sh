#!/bin/bash

# Quick Fix Script for npm on Cloudways
# This script fixes npm issues when nvm is installed but npm is not working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to load nvm environment
load_nvm() {
    print_status "Loading nvm environment..."
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    
    if command_exists nvm; then
        print_success "nvm loaded successfully: $(nvm --version)"
    else
        print_error "Failed to load nvm"
        return 1
    fi
}

# Function to check and fix Node.js installation
fix_nodejs() {
    print_status "Checking Node.js installation..."
    
    # Load nvm first
    load_nvm
    
    # Check current Node.js version
    CURRENT_NODE_VERSION=$(node --version 2>/dev/null || echo "none")
    TARGET_VERSION="18.19.0"
    
    if [ "$CURRENT_NODE_VERSION" = "v$TARGET_VERSION" ]; then
        print_success "Node.js $TARGET_VERSION is installed"
        
        # Check if npm is available in the current Node.js installation
        if [ -f "$NVM_DIR/versions/node/v$TARGET_VERSION/bin/npm" ]; then
            print_success "npm found in Node.js installation"
            # Add npm to PATH
            export PATH="$NVM_DIR/versions/node/v$TARGET_VERSION/bin:$PATH"
            print_success "npm added to PATH"
        else
            print_warning "npm not found in Node.js installation, reinstalling Node.js..."
            nvm uninstall $TARGET_VERSION
            nvm install $TARGET_VERSION
            nvm use $TARGET_VERSION
            nvm alias default $TARGET_VERSION
        fi
    else
        print_status "Installing Node.js $TARGET_VERSION..."
        nvm install $TARGET_VERSION
        nvm use $TARGET_VERSION
        nvm alias default $TARGET_VERSION
    fi
}

# Function to verify npm installation
verify_npm() {
    print_status "Verifying npm installation..."
    
    # Load nvm environment
    load_nvm
    
    # Check if npm is available
    if command_exists npm; then
        print_success "npm is working: $(npm --version)"
        return 0
    else
        print_error "npm is still not available"
        return 1
    fi
}

# Function to create npm symlink
create_npm_symlink() {
    print_status "Creating npm symlink..."
    
    # Find npm in nvm directory
    NPM_PATH=$(find ~/.nvm -name "npm" -type f 2>/dev/null | head -1)
    
    if [ -n "$NPM_PATH" ]; then
        print_success "Found npm at: $NPM_PATH"
        
        # Create symlink in ~/bin
        mkdir -p ~/bin
        ln -sf "$NPM_PATH" ~/bin/npm
        
        # Add ~/bin to PATH
        if ! grep -q "~/bin" ~/.bashrc; then
            echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
            print_success "Added ~/bin to PATH"
        fi
        
        # Update current session
        export PATH=~/bin:$PATH
        
        print_success "npm symlink created"
    else
        print_error "Could not find npm in nvm directory"
        return 1
    fi
}

# Function to test npm functionality
test_npm() {
    print_status "Testing npm functionality..."
    
    if command_exists npm; then
        echo "=== npm Test ==="
        echo "npm version: $(npm --version)"
        echo "npm location: $(which npm)"
        echo "npm help: $(npm help 2>/dev/null | head -1 || echo 'npm help working')"
        
        # Test npm install
        print_status "Testing npm install..."
        mkdir -p /tmp/npm-test
        cd /tmp/npm-test
        npm init -y >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_success "npm install test passed"
        else
            print_warning "npm install test failed"
        fi
        cd - >/dev/null
        rm -rf /tmp/npm-test
        
        return 0
    else
        print_error "npm is not available"
        return 1
    fi
}

# Function to configure npm
configure_npm() {
    print_status "Configuring npm..."
    
    if ! command_exists npm; then
        print_error "npm is not available for configuration"
        return 1
    fi
    
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
    
    # Update current session
    export PATH=~/.npm-global/bin:$PATH
    
    print_success "npm configured successfully"
}

# Function to create environment script
create_env_script() {
    print_status "Creating environment setup script..."
    
    cat > ~/setup-npm-env.sh << 'EOF'
#!/bin/bash
# npm Environment Setup Script for Cloudways

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Add npm to PATH
export PATH=~/bin:$PATH
export PATH=~/.npm-global/bin:$PATH

# Use default Node.js version
nvm use default

echo "npm environment loaded successfully"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "npm location: $(which npm)"
EOF
    
    chmod +x ~/setup-npm-env.sh
    print_success "Environment script created: ~/setup-npm-env.sh"
}

# Function to display current status
show_status() {
    echo ""
    echo "=== Current Status ==="
    echo "Node.js: $(node --version 2>/dev/null || echo 'Not available')"
    echo "npm: $(npm --version 2>/dev/null || echo 'Not available')"
    echo "nvm: $(nvm --version 2>/dev/null || echo 'Not available')"
    echo "npm location: $(which npm 2>/dev/null || echo 'Not found')"
    echo ""
}

# Main function
main() {
    echo "=========================================="
    echo "    npm Fix Script for Cloudways          "
    echo "=========================================="
    echo ""
    
    # Show initial status
    show_status
    
    # Load nvm environment
    load_nvm
    
    # Fix Node.js installation
    fix_nodejs
    
    # Try to verify npm
    if verify_npm; then
        print_success "npm is working correctly!"
    else
        print_warning "npm not found, creating symlink..."
        create_npm_symlink
        verify_npm
    fi
    
    # Configure npm
    configure_npm
    
    # Test npm functionality
    test_npm
    
    # Create environment script
    create_env_script
    
    # Show final status
    show_status
    
    echo "=========================================="
    echo "    npm Fix Complete!                     "
    echo "=========================================="
    echo ""
    echo "🎉 npm should now be working!"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Test npm: npm --version"
    echo "   2. Install global packages: npm install -g pm2"
    echo "   3. Use environment script: source ~/setup-npm-env.sh"
    echo "   4. Restart terminal or run: source ~/.bashrc"
    echo ""
    echo "🛠️  If npm still doesn't work:"
    echo "   - Run: source ~/setup-npm-env.sh"
    echo "   - Check: which npm"
    echo "   - Test: npm --version"
    echo ""
}

# Error handling
cleanup_on_error() {
    print_error "Fix failed. Please check the error messages above."
    exit 1
}

# Set trap for error handling
trap cleanup_on_error ERR

# Run main function
main "$@" 