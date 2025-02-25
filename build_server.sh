#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display section headers
section() {
    echo -e "\n${BLUE}========== $1 ==========${NC}"
}

# Function to display success messages
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to display info messages
info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Function to display error messages
error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

section "Setting up environment"

# Define paths
STEAM_DIR="$HOME/.steam"
STEAMCMD_DIR="$STEAM_DIR/steamcmd"
SDK_INSTALL_DIR="$STEAM_DIR/sdk2013"
PROJECT_DIR="$(pwd)"
LIB_DIR="$PROJECT_DIR/lib"

# Create directories
info "Creating directories..."
mkdir -p "$STEAMCMD_DIR"
mkdir -p "$SDK_INSTALL_DIR"
mkdir -p "$LIB_DIR/linux64"
success "Directories created"

# Install dependencies
section "Installing dependencies"
if command -v apt-get &> /dev/null; then
    info "Detected Debian/Ubuntu system"
    info "Installing required packages..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq lib32gcc-s1 lib32stdc++6 ca-certificates curl git git-lfs build-essential python3 python3-pip
    success "Required packages installed"
elif command -v yum &> /dev/null; then
    info "Detected Red Hat/CentOS/Fedora system"
    info "Installing required packages..."
    sudo yum install -y glibc.i686 libstdc++.i686 ca-certificates curl git git-lfs gcc gcc-c++ make python3 python3-pip
    success "Required packages installed"
else
    info "Unknown package manager. Skipping automatic dependency installation."
    info "Please ensure you have the required dependencies installed manually."
fi

# Initialize git-lfs if git is available
if command -v git &> /dev/null && command -v git-lfs &> /dev/null; then
    info "Initializing git-lfs..."
    git lfs install
    success "git-lfs initialized"
fi

# Install SteamCMD
section "Setting up SteamCMD"
if [ ! -f "$STEAMCMD_DIR/steamcmd.sh" ]; then
    info "Installing SteamCMD..."
    cd "$STEAMCMD_DIR"
    curl -O http://media.steampowered.com/installer/steamcmd_linux.tar.gz
    tar -xzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
    ./steamcmd.sh +quit
    success "SteamCMD installed successfully"
else
    success "SteamCMD is already installed"
fi

# Install Source SDK Base 2013 Dedicated Server
section "Installing Source SDK Base 2013"
info "Installing Source SDK Base 2013 Linux server (Depot 244313)..."

# Create a script file for SteamCMD
cat > "$STEAMCMD_DIR/install_sdk.txt" << EOL
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login anonymous
force_install_dir $SDK_INSTALL_DIR
app_update 244310 validate
quit
EOL

# Run SteamCMD to download the SDK
cd "$STEAMCMD_DIR"
./steamcmd.sh +runscript install_sdk.txt

# Copy necessary lib files to our project
info "Copying necessary library files to project..."
cp "$SDK_INSTALL_DIR/bin/libtier0_srv.so" "$LIB_DIR/"
cp "$SDK_INSTALL_DIR/bin/libvstdlib_srv.so" "$LIB_DIR/"
cp "$SDK_INSTALL_DIR/bin/linux64/libtier0_srv.so" "$LIB_DIR/linux64/"
cp "$SDK_INSTALL_DIR/bin/linux64/libvstdlib_srv.so" "$LIB_DIR/linux64/"
success "SDK libraries copied to project"

# Return to the project directory
cd "$PROJECT_DIR"

# Build the server
section "Building the server"
info "Building in release mode..."

# Always use release mode
export VPC_NINJA_BUILD_MODE="release"

# Source the SDK container script
info "Sourcing SDK container script..."
if [ -f "src/sdk_container" ]; then
    source src/sdk_container
    run_in_sniper
else
    error "sdk_container script not found in src directory! Make sure you're in the right directory."
fi

solution_out="src/_vpc_/ninja/sdk_server_$VPC_NINJA_BUILD_MODE"

if [[ ! -e "$solution_out.ninja" ]]; then
    info "Generating build files..."
    
    if [ ! -f "src/devtools/bin/vpc" ]; then
        error "VPC tool not found! Make sure your SDK is properly set up."
    fi
    
    src/devtools/bin/vpc /hl2mp /tf /linux64 /ninja /define:SOURCESDK +dedicated /mksln "$solution_out"
    
    # Generate compile commands
    info "Generating compile commands..."
    ninja -f "$solution_out.ninja" -t compdb > src/compile_commands.json
    
    # Remove some unsupported clang commands
    info "Adjusting compile commands..."
    sed -i 's/-fpredictive-commoning//g; s/-fvar-tracking-assignments//g' src/compile_commands.json
    sed -i 's|/my_mod/src|.|g' src/compile_commands.json
    
    # Adjust paths for server libraries
    info "Adjusting library paths..."
    sed -i 's|-D_DLL_EXT=\.so|-D_DLL_EXT=_srv.so|g' src/compile_commands.json
    sed -i 's|-D_EXTERNAL_DLL_EXT=\.so|-D_EXTERNAL_DLL_EXT=_srv.so|g' src/compile_commands.json
    sed -i 's|server\.so|server_srv.so|g' src/compile_commands.json
    sed -i 's|lvstdlib|lvstdlib_srv|g' src/compile_commands.json
    sed -i 's|ltier0|ltier0_srv|g' src/compile_commands.json
    
    sed -i 's|-D_DLL_EXT=\.so|-D_DLL_EXT=_srv.so|g' "$solution_out.ninja"
    sed -i 's|-D_EXTERNAL_DLL_EXT=\.so|-D_EXTERNAL_DLL_EXT=_srv.so|g' "$solution_out.ninja"
    sed -i 's|server\.so|server_srv.so|g' "$solution_out.ninja"
    sed -i 's|libtier0\.so|libtier0_srv.so|g' "$solution_out.ninja"
    sed -i 's|libvstdlib\.so|libvstdlib_srv.so|g' "$solution_out.ninja"
    sed -i 's|lvstdlib|lvstdlib_srv|g' "$solution_out.ninja"
    sed -i 's|ltier0|ltier0_srv|g' "$solution_out.ninja"
    
    success "Build files generated and adjusted"
fi

# Build using all available processors
info "Compiling the server..."
ninja -f "$solution_out.ninja" -j$(nproc)

section "Build completed"
success "Server build complete in release mode!"
info "You can run your server now"
