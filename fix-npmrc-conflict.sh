#!/bin/bash

# Fix .npmrc Conflict Script for Cloudways
# This script fixes .npmrc conflicts that prevent nvm from working

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

# Function to backup .npmrc
backup_npmrc() {
    print_status "Backing up .npmrc file..."
    
    if [ -f ~/.npmrc ]; then
        cp ~/.npmrc ~/.npmrc.backup.$(date +%Y%m%d_%H%M%S)
        print_success "Backup created: ~/.npmrc.backup.$(date +%Y%m%d_%H%M%S)"
    else
        print_status "No .npmrc file found"
    fi
}

# Function to fix .npmrc conflicts
fix_npmrc() {
    print_status "Fixing .npmrc conflicts..."
    
    # Export nvm environment
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Remove conflicting settings from .npmrc
    if [ -f ~/.npmrc ]; then
        print_status "Removing conflicting settings from .npmrc..."
        
        # Create a clean .npmrc without globalconfig and prefix
        grep -v -E "^(globalconfig|prefix)=" ~/.npmrc > ~/.npmrc.tmp 2>/dev/null || true
        
        # If the temp file is empty or doesn't exist, create a minimal .npmrc
        if [ ! -s ~/.npmrc.tmp ]; then
            echo "# Clean .npmrc for nvm compatibility" > ~/.npmrc.tmp
        fi
        
        # Replace the original .npmrc
        mv ~/.npmrc.tmp ~/.npmrc
        print_success "Cleaned .npmrc file"
    else
        print_status "Creating clean .npmrc file..."
        echo "# Clean .npmrc for nvm compatibility" > ~/.npmrc
    fi
    
    # Run nvm command to clear prefix
    print_status "Clearing nvm prefix..."
    nvm use --delete-prefix v18.19.0 --silent 2>/dev/null || true
    print_success "nvm prefix cleared"
}

# Function to load nvm properly
load_nvm() {
    print_status "Loading nvm environment..."
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    if command_exists nvm; then
        print_success "nvm loaded successfully: $(nvm --version)"
    else
        print_error "Failed to load nvm"
        return 1
    fi
}

# Function to reinstall Node.js with npm
reinstall_nodejs() {
    print_status "Reinstalling Node.js with npm..."
    
    # Load nvm
    load_nvm
    
    # Uninstall current Node.js version
    print_status "Uninstalling current Node.js version..."
    nvm uninstall v18.19.0 2>/dev/null || true
    
    # Install fresh Node.js version
    print_status "Installing fresh Node.js 18.19.0..."
    nvm install 18.19.0
    nvm use 18.19.0
    nvm alias default 18.19.0
    
    print_success "Node.js 18.19.0 reinstalled successfully"
}

# Function to verify npm installation
verify_npm() {
    print_status "Verifying npm installation..."
    
    # Load nvm
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

# Function to configure npm properly
configure_npm() {
    print_status "Configuring npm for nvm..."
    
    # Load nvm
    load_nvm
    
    if ! command_exists npm; then
        print_error "npm is not available for configuration"
        return 1
    fi
    
    # Create npm global directory
    mkdir -p ~/.npm-global
    
    # Configure npm without conflicting settings
    npm config set prefix '~/.npm-global'
    npm config set registry https://registry.npmjs.org/
    npm config set cache ~/.npm-cache
    
    # Remove any globalconfig setting that might conflict
    npm config delete globalconfig 2>/dev/null || true
    
    # Add to PATH
    if ! grep -q "npm-global" ~/.bashrc; then
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
        print_success "Added npm global path to .bashrc"
    else
        print_status "npm global path already in .bashrc"
    fi
    
    # Update current session
    export PATH=~/.npm-global/bin:$PATH
    
    print_success "npm configured successfully for nvm"
}

# Function to test npm functionality
test_npm() {
    print_status "Testing npm functionality..."
    
    # Load nvm
    load_nvm
    
    if command_exists npm; then
        echo "=== npm Test ==="
        echo "npm version: $(npm --version)"
        echo "npm location: $(which npm)"
        echo "npm config prefix: $(npm config get prefix)"
        echo "npm config registry: $(npm config get registry)"
        
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

# Function to create environment script
create_env_script() {
    print_status "Creating environment setup script..."
    
    cat > ~/setup-nvm-clean.sh << 'EOF'
#!/bin/bash
# Clean nvm Environment Setup Script for Cloudways

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Use default Node.js version
nvm use default

# Add npm global path
export PATH=~/.npm-global/bin:$PATH

echo "Clean nvm environment loaded successfully"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "npm location: $(which npm)"
echo "npm prefix: $(npm config get prefix)"
EOF
    
    chmod +x ~/setup-nvm-clean.sh
    print_success "Environment script created: ~/setup-nvm-clean.sh"
}

# Function to display current status
show_status() {
    echo ""
    echo "=== Current Status ==="
    echo "Node.js: $(node --version 2>/dev/null || echo 'Not available')"
    echo "npm: $(npm --version 2>/dev/null || echo 'Not available')"
    echo "nvm: $(nvm --version 2>/dev/null || echo 'Not available')"
    echo "npm location: $(which npm 2>/dev/null || echo 'Not found')"
    echo ".npmrc exists: $([ -f ~/.npmrc ] && echo 'Yes' || echo 'No')"
    if [ -f ~/.npmrc ]; then
        echo ".npmrc content:"
        cat ~/.npmrc | head -5
    fi
    echo ""
}

# Main function
main() {
    echo "=========================================="
    echo "    .npmrc Conflict Fix for Cloudways     "
    echo "=========================================="
    echo ""
    echo "This script fixes .npmrc conflicts that prevent nvm from working."
    echo ""
    
    # Show initial status
    show_status
    
    # Ask for confirmation
    read -p "Continue with fixing .npmrc conflicts? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_error "Fix cancelled."
        exit 1
    fi
    
    echo ""
    
    # Backup .npmrc
    backup_npmrc
    
    # Fix .npmrc conflicts
    fix_npmrc
    
    # Load nvm
    load_nvm
    
    # Reinstall Node.js
    reinstall_nodejs
    
    # Verify npm
    verify_npm
    
    # Configure npm
    configure_npm
    
    # Test npm
    test_npm
    
    # Create environment script
    create_env_script
    
    # Show final status
    show_status
    
    echo "=========================================="
    echo "    .npmrc Conflict Fix Complete!         "
    echo "=========================================="
    echo ""
    echo "🎉 .npmrc conflicts have been resolved!"
    echo ""
    echo "📋 What was fixed:"
    echo "   - Removed conflicting globalconfig and prefix settings"
    echo "   - Cleaned .npmrc file for nvm compatibility"
    echo "   - Reinstalled Node.js with npm"
    echo "   - Configured npm properly for nvm"
    echo ""
    echo "🔧 Next Steps:"
    echo "   1. Test npm: npm --version"
    echo "   2. Install global packages: npm install -g pm2"
    echo "   3. Use environment script: source ~/setup-nvm-clean.sh"
    echo "   4. Restart terminal or run: source ~/.bashrc"
    echo ""
    echo "📁 Backup created:"
    echo "   Original .npmrc: ~/.npmrc.backup.*"
    echo "   New .npmrc: ~/.npmrc"
    echo ""
    echo "⚠️  If you need to restore original settings:"
    echo "   cp ~/.npmrc.backup.* ~/.npmrc"
    echo ""
}

# Error handling
cleanup_on_error() {
    print_error "Fix failed. Please check the error messages above."
    print_error "You can restore your original .npmrc from the backup."
    exit 1
}

# Set trap for error handling
trap cleanup_on_error ERR

# Run main function
main "$@" 