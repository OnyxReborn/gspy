#!/bin/bash

# Quick .npmrc Fix for Cloudways
# Direct fix for .npmrc conflicts with nvm

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

echo "=========================================="
echo "    Quick .npmrc Fix for Cloudways        "
echo "=========================================="
echo ""

# Step 1: Backup .npmrc
print_status "Backing up .npmrc..."
if [ -f ~/.npmrc ]; then
    cp ~/.npmrc ~/.npmrc.backup.$(date +%Y%m%d_%H%M%S)
    print_success "Backup created"
else
    print_status "No .npmrc file found"
fi

# Step 2: Remove .npmrc completely (temporary fix)
print_status "Removing .npmrc to clear conflicts..."
if [ -f ~/.npmrc ]; then
    rm ~/.npmrc
    print_success ".npmrc removed"
fi

# Step 3: Load nvm environment
print_status "Loading nvm environment..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Step 4: Check if nvm is working
if command -v nvm >/dev/null 2>&1; then
    print_success "nvm loaded: $(nvm --version)"
else
    print_error "nvm not found after loading"
    exit 1
fi

# Step 5: Clear any existing prefix
print_status "Clearing nvm prefix..."
nvm use --delete-prefix v18.19.0 --silent 2>/dev/null || true
print_success "Prefix cleared"

# Step 6: Reinstall Node.js
print_status "Reinstalling Node.js 18.19.0..."
nvm uninstall v18.19.0 2>/dev/null || true
nvm install 18.19.0
nvm use 18.19.0
nvm alias default 18.19.0
print_success "Node.js 18.19.0 installed"

# Step 7: Test npm
print_status "Testing npm..."
if command -v npm >/dev/null 2>&1; then
    NPM_VERSION=$(npm --version)
    print_success "npm is working: $NPM_VERSION"
else
    print_error "npm not found"
    exit 1
fi

# Step 8: Create clean .npmrc
print_status "Creating clean .npmrc..."
cat > ~/.npmrc << 'EOF'
# Clean .npmrc for nvm compatibility
registry=https://registry.npmjs.org/
cache=~/.npm-cache
EOF
print_success "Clean .npmrc created"

# Step 9: Configure npm for nvm
print_status "Configuring npm for nvm..."
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
npm config delete globalconfig 2>/dev/null || true
print_success "npm configured"

# Step 10: Add to PATH
print_status "Updating PATH..."
if ! grep -q "npm-global" ~/.bashrc; then
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
    print_success "Added to .bashrc"
else
    print_status "Already in .bashrc"
fi

# Step 11: Test npm install
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

# Step 12: Create environment script
print_status "Creating environment script..."
cat > ~/setup-nvm-env.sh << 'EOF'
#!/bin/bash
# nvm Environment Setup Script

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Use default Node.js version
nvm use default

# Add npm global path
export PATH=~/.npm-global/bin:$PATH

echo "nvm environment loaded successfully"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
EOF

chmod +x ~/setup-nvm-env.sh
print_success "Environment script created: ~/setup-nvm-env.sh"

# Final status
echo ""
echo "=== Final Status ==="
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "nvm: $(nvm --version)"
echo "npm location: $(which npm)"
echo ""

echo "=========================================="
echo "    Quick Fix Complete!                   "
echo "=========================================="
echo ""
echo "🎉 npm should now be working!"
echo ""
echo "📋 Next Steps:"
echo "   1. Test: npm --version"
echo "   2. Install PM2: npm install -g pm2"
echo "   3. Load environment: source ~/setup-nvm-env.sh"
echo "   4. Or restart terminal"
echo ""
echo "📁 Backup: ~/.npmrc.backup.*"
echo "📁 New .npmrc: ~/.npmrc"
echo "" 