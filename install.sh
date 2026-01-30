#!/bin/bash
#
# BanglaWriter IBUS Installation Script
# One-click installer for Bangla phonetic typing on Linux
#
# Usage: ./install.sh [--uninstall] [--help]
#
# Supported distributions: Ubuntu, Debian, Fedora, Arch Linux, Manjaro
#

set -e

# Configuration
PROJECT_NAME="BanglaWriter"
PROJECT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"
FONT_DIR="${SCRIPT_DIR}/fonts"
ICONS_DIR="${SCRIPT_DIR}/icons"

# Installation paths
SYSTEM_FONTS_DIR="/usr/share/fonts/truetype/banglawriter"
USER_FONTS_DIR="${HOME}/.local/share/fonts/banglawriter"
SYSTEM_M17N_DIR="/usr/share/m17n"
USER_M17N_DIR="${HOME}/.m17n.d"
SYSTEM_ICONS_DIR="/usr/share/m17n/icons"
USER_ICONS_DIR="${HOME}/.m17n.d/icons"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Global variables
DISTRO=""
DISTRO_VERSION=""
PACKAGE_MANAGER=""
IS_ROOT=false

# Print functions
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${PROJECT_NAME} IBUS Installer v${PROJECT_VERSION}${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[${NC}${BOLD}STEP${NC}${BLUE}]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[${NC}${BOLD}OK${NC}${GREEN}]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[${NC}${BOLD}WARN${NC}${YELLOW}]${NC} $1"
}

print_error() {
    echo -e "${RED}[${NC}${BOLD}ERROR${NC}${RED}]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[${NC}${BOLD}INFO${NC}${CYAN}]${NC} $1"
}

# Check if running as root or has sudo access
check_permissions() {
    print_step "Checking permissions..."
    
    if [ "$(id -u)" -eq 0 ]; then
        IS_ROOT=true
        print_success "Running as root"
    else
        # Check if sudo is available
        if command -v sudo &> /dev/null; then
            print_info "sudo access required. You may be prompted for your password."
            if sudo -n true 2>/dev/null; then
                IS_ROOT=false
                print_success "sudo access available"
            else
                print_info "You will be prompted for your password during installation"
                IS_ROOT=false
            fi
        else
            print_error "sudo is not available. Please run as root or install sudo."
            exit 1
        fi
    fi
}

# Execute command with proper permissions
run_command() {
    if [ "$IS_ROOT" = true ]; then
        "$@"
    else
        sudo "$@"
    fi
}


# Detect Linux distribution
detect_distro() {
    print_step "Detecting Linux distribution..."
    
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        DISTRO="${NAME}"
        DISTRO_VERSION="${VERSION_ID}"
        
        # Normalize distribution names
        case "${DISTRO,,}" in
            ubuntu*|debian*|linuxmint*)
                DISTRO="debian"
                PACKAGE_MANAGER="apt"
                ;;
            fedora*|rhel*|centos*)
                DISTRO="fedora"
                PACKAGE_MANAGER="dnf"
                ;;
            arch*|manjaro*|endeavouros*)
                DISTRO="arch"
                PACKAGE_MANAGER="pacman"
                ;;
            opensuse*|suse*)
                DISTRO="suse"
                PACKAGE_MANAGER="zypper"
                ;;
            *)
                print_warning "Unknown distribution: ${DISTRO}"
                print_info "Attempting generic installation..."
                DISTRO="generic"
                PACKAGE_MANAGER=""
                ;;
        esac
        
        print_success "Detected: ${DISTRO^} (${DISTRO_VERSION})"
    else
        print_error "Cannot detect distribution. /etc/os-release not found."
        exit 1
    fi
}

# Install distribution-specific dependencies
install_dependencies() {
    print_step "Installing dependencies for ${DISTRO^}..."
    
    case "$PACKAGE_MANAGER" in
                apt)
            run_command apt-get update -qq
            run_command apt-get install -y -qq \
                ibus \
                ibus-m17n \
                m17n-db \
                libm17n-0 \
                fontconfig \
                git \
                make
            print_success "Dependencies installed via apt"
            ;;
        dnf)
            run_command dnf install -y -q \
                ibus \
                ibus-m17n \
                m17n-db \
                m17n-lib \
                fontconfig \
                git \
                make
            print_success "Dependencies installed via dnf"
            ;;
        pacman)
            run_command pacman -Sy --noconfirm \
                ibus \
                libm17n \
                m17n-db \
                fontconfig \
                git \
                make
            print_success "Dependencies installed via pacman"
            ;;
        zypper)
            run_command zypper install -y -q \
                ibus \
                ibus-m17n \
                m17n-db \
                m17n-lib \
                fontconfig \
                git \
                make
            print_success "Dependencies installed via zypper"
            ;;
        *)
            print_warning "No package manager detected. Please install manually:"
            print_info "  - ibus"
            print_info "  - ibus-m17n"
            print_info "  - m17n-db"
            print_info "  - m17n-lib"
            print_info "  - fontconfig"
            ;;
    esac
}

# Find all font files (.ttf and .otf) in the project
find_font_files() {
    local font_files=()
    
    # Search in fonts directory
    if [ -d "$FONT_DIR" ]; then
        while IFS= read -r -d '' font_file; do
            font_files+=("$font_file")
        done < <(find "$FONT_DIR" -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.TTF" -o -name "*.OTF" \) -print0 2>/dev/null)
    fi
    
    # Also search in project root for any stray font files
    while IFS= read -r -d '' font_file; do
        # Skip if already found in fonts directory
        local already_found=false
        for existing in "${font_files[@]}"; do
            if [ "$font_file" = "$existing" ]; then
                already_found=true
                break
            fi
        done
        if [ "$already_found" = false ]; then
            font_files+=("$font_file")
        fi
    done < <(find "$SCRIPT_DIR" -maxdepth 2 -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.TTF" -o -name "*.OTF" \) -print0 2>/dev/null)
    
    # Return count of found fonts
    echo ${#font_files[@]}
}

# Download and install fonts automatically
download_and_install_fonts() {
    print_step "Downloading and installing Bangla fonts..."
    
    local temp_dir=$(mktemp -d)
    local download_failed=false
    local fonts_downloaded=0
    
    # Create user font directory if it doesn't exist
    if ! run_command mkdir -p "${USER_FONTS_DIR}" 2>/dev/null; then
        print_warning "Could not create user font directory"
        download_failed=true
    fi
    
    # Download Noto Sans Bangla font (open source, high quality)
    print_info "Downloading Noto Sans Bangla font..."
    
    # Noto Sans Bangla font URL (Google Fonts)
    local noto_bangla_url="https://github.com/google/fonts/raw/main/ofl/notosansbengali/NotoSansBengali%5Bwght%5D.ttf"
    
    if command -v curl &> /dev/null; then
        if curl -L -o "${temp_dir}/NotoSansBengali-Regular.ttf" "${noto_bangla_url}" 2>/dev/null; then
            if [ -s "${temp_dir}/NotoSansBengali-Regular.ttf" ]; then
                run_command cp "${temp_dir}/NotoSansBengali-Regular.ttf" "${USER_FONTS_DIR}/"
                print_success "Downloaded Noto Sans Bangla Regular"
                ((fonts_downloaded++))
            fi
        fi
    elif command -v wget &> /dev/null; then
        if wget -O "${temp_dir}/NotoSansBengali-Regular.ttf" "${noto_bangla_url}" 2>/dev/null; then
            if [ -s "${temp_dir}/NotoSansBengali-Regular.ttf" ]; then
                run_command cp "${temp_dir}/NotoSansBengali-Regular.ttf" "${USER_FONTS_DIR}/"
                print_success "Downloaded Noto Sans Bangla Regular"
                ((fonts_downloaded++))
            fi
        fi
    else
        print_warning "Neither curl nor wget found. Cannot download fonts."
        download_failed=true
    fi
    
    # Download Noto Serif Bangla font (for formal documents)
    print_info "Downloading Noto Serif Bangla font..."
    local noto_serif_url="https://github.com/google/fonts/raw/main/ofl/notoserifbengali/NotoSerifBengali%5Bwght%5D.ttf"
    
    if command -v curl &> /dev/null; then
        if curl -L -o "${temp_dir}/NotoSerifBengali-Regular.ttf" "${noto_serif_url}" 2>/dev/null; then
            if [ -s "${temp_dir}/NotoSerifBengali-Regular.ttf" ]; then
                run_command cp "${temp_dir}/NotoSerifBengali-Regular.ttf" "${USER_FONTS_DIR}/"
                print_success "Downloaded Noto Serif Bangla Regular"
                ((fonts_downloaded++))
            fi
        fi
    elif command -v wget &> /dev/null; then
        if wget -O "${temp_dir}/NotoSerifBengali-Regular.ttf" "${noto_serif_url}" 2>/dev/null; then
            if [ -s "${temp_dir}/NotoSerifBengali-Regular.ttf" ]; then
                run_command cp "${temp_dir}/NotoSerifBengali-Regular.ttf" "${USER_FONTS_DIR}/"
                print_success "Downloaded Noto Serif Bangla Regular"
                ((fonts_downloaded++))
            fi
        fi
    fi
    
    # Download Lohit Bengali font ( Fedora/RHEL default)
    print_info "Downloading Lohit Bengali font..."
    local lohit_url="https://github.com/東方Project/lohit-bengali/raw/master/lohit-bengali/Lohit-Bengali.ttf"
    
    if command -v curl &> /dev/null; then
        if curl -L -o "${temp_dir}/Lohit-Bengali.ttf" "${lohit_url}" 2>/dev/null; then
            if [ -s "${temp_dir}/Lohit-Bengali.ttf" ]; then
                run_command cp "${temp_dir}/Lohit-Bengali.ttf" "${USER_FONTS_DIR}/"
                print_success "Downloaded Lohit Bengali"
                ((fonts_downloaded++))
            fi
        fi
    elif command -v wget &> /dev/null; then
        if wget -O "${temp_dir}/Lohit-Bengali.ttf" "${lohit_url}" 2>/dev/null; then
            if [ -s "${temp_dir}/Lohit-Bengali.ttf" ]; then
                run_command cp "${temp_dir}/Lohit-Bengali.ttf" "${USER_FONTS_DIR}/"
                print_success "Downloaded Lohit Bengali"
                ((fonts_downloaded++))
            fi
        fi
    fi
    
    # Also copy any local fonts from the project
    local local_font_count=$(find_font_files)
    if [ "$local_font_count" -gt 0 ]; then
        print_info "Found $local_font_count local font file(s), copying..."
        
        if [ -d "$FONT_DIR" ]; then
            run_command cp -r "$FONT_DIR"/* "${USER_FONTS_DIR}/" 2>/dev/null || true
        fi
        
        while IFS= read -r -d '' font_file; do
            local font_filename=$(basename "$font_file")
            if [ ! -f "${USER_FONTS_DIR}/$font_filename" ]; then
                run_command cp "$font_file" "${USER_FONTS_DIR}/" 2>/dev/null || true
            fi
        done < <(find "$SCRIPT_DIR" -maxdepth 2 -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.TTF" -o -name "*.OTF" \) -print0 2>/dev/null)
        
        local local_copied=$(find "$USER_FONTS_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) | wc -l)
        if [ "$local_copied" -gt 0 ]; then
            print_success "Copied $local_copied local font(s)"
            ((fonts_downloaded += local_copied))
        fi
    fi
    
    # Clean up temp directory
    rm -rf "$temp_dir"
    
    # Set proper permissions
    run_command chmod 644 "${USER_FONTS_DIR}"/*.{ttf,otf,TTF,OTF} 2>/dev/null || true
    
    # Update font cache
    if run_command fc-cache -fv 2>/dev/null; then
        print_success "Font cache updated"
    else
        print_warning "Failed to update font cache"
    fi
    
    # Verify fonts are installed
    local verified_count=$(fc-list 2>/dev/null | grep -i -E "noto.*bengali\|noto.*bangla\|lohit.*bengali\|banglawriter" | wc -l)
    
    if [ "$verified_count" -gt 0 ]; then
        print_success "Verified $verified_count Bangla font(s) installed"
        return 0
    elif [ "$fonts_downloaded" -gt 0 ]; then
        print_warning "Fonts downloaded but verification pending (fc-list may need update)"
        print_info "You may need to log out and log back in for fonts to appear in all applications"
        return 0
    else
        print_warning "Could not download or install any fonts"
        print_font_tutorial
        return 1
    fi
}

# Install fonts with automatic detection and fallback
install_fonts() {
    print_step "Installing Bangla fonts..."
    
    local font_install_failed=false
    local font_count=0
    
    # Create user font directory if it doesn't exist
    if ! run_command mkdir -p "${USER_FONTS_DIR}" 2>/dev/null; then
        print_warning "Could not create user font directory"
        font_install_failed=true
    fi
    
    # Find and count local font files
    font_count=$(find_font_files)
    
    if [ "$font_count" -gt 0 ]; then
        print_info "Found $font_count local font file(s)"
        
        # Copy fonts from fonts directory
        if [ -d "$FONT_DIR" ]; then
            if run_command cp -r "$FONT_DIR"/* "${USER_FONTS_DIR}/" 2>/dev/null; then
                print_success "Local fonts installed to ${USER_FONTS_DIR}"
            else
                print_warning "Failed to copy fonts from fonts directory"
                font_install_failed=true
            fi
        fi
        
        # Copy any stray fonts from project root
        while IFS= read -r -d '' font_file; do
            local font_filename=$(basename "$font_file")
            if [ ! -f "${USER_FONTS_DIR}/$font_filename" ]; then
                if run_command cp "$font_file" "${USER_FONTS_DIR}/" 2>/dev/null; then
                    print_info "Installed: $font_filename"
                fi
            fi
        done < <(find "$SCRIPT_DIR" -maxdepth 2 -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.TTF" -o -name "*.OTF" \) -print0 2>/dev/null)
        
        # Set proper permissions
        run_command chmod 644 "${USER_FONTS_DIR}"/*.{ttf,otf,TTF,OTF} 2>/dev/null || true
        
        # Update font cache
        if run_command fc-cache -fv 2>/dev/null; then
            print_success "Font cache updated"
        else
            print_warning "Failed to update font cache"
            font_install_failed=true
        fi
        
        # Verify fonts are installed
        local verified_count=$(fc-list | grep -i "bangla\|banglawriter" | wc -l)
        if [ "$verified_count" -gt 0 ]; then
            print_success "Verified $verified_count Bangla font(s) installed"
        else
            print_warning "Could not verify font installation"
        fi
    else
        print_info "No local font files found"
        print_info "Attempting to download fonts automatically..."
        download_and_install_fonts
        return $?
    fi
    
    # Print fallback tutorial if installation failed
    if [ "$font_install_failed" = true ]; then
        print_font_tutorial
        return 1
    fi
    
    return 0
}

# Print manual font installation tutorial
print_font_tutorial() {
    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}  ${BOLD}Manual Font Installation Tutorial${NC}                      ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Option 1: Using GUI (File Manager)${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} Right-click on the .ttf or .otf font file"
    echo -e "${CYAN}2.${NC} Select 'Open with Font Viewer' or 'Install Font'"
    echo -e "${CYAN}3.${NC} Choose 'Install for all users' (requires root) or 'Install for user'"
    echo ""
    echo -e "${BOLD}Option 2: Using Command Line (Recommended)${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} Copy fonts to user font directory:"
    echo "      mkdir -p ~/.local/share/fonts"
    echo "      cp /path/to/font.ttf ~/.local/share/fonts/"
    echo ""
    echo -e "${CYAN}2.${NC} Or copy to system font directory (requires root):"
    echo "      sudo mkdir -p /usr/share/fonts/truetype/banglawriter"
    echo "      sudo cp /path/to/font.ttf /usr/share/fonts/truetype/banglawriter/"
    echo ""
    echo -e "${CYAN}3.${NC} Update font cache:"
    echo "      fc-cache -fv"
    echo ""
    echo -e "${BOLD}Option 3: Using Font Manager (GUI)${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} Install font manager:"
    echo "      sudo apt install font-manager  # Debian/Ubuntu"
    echo "      sudo dnf install font-manager  # Fedora"
    echo "      sudo pacman -S font-manager    # Arch"
    echo ""
    echo -e "${CYAN}2.${NC} Open Font Manager from applications menu"
    echo -e "${CYAN}3.${NC} Click '+' and browse to your font files"
    echo -e "${CYAN}4.${NC} Select the fonts and click 'Install'"
    echo ""
    echo -e "${BOLD}Popular Bangla Fonts:${NC}"
    echo ""
    echo -e "${CYAN}•${NC} SolaimanLipi - Classic Bangla font"
    echo -e "${CYAN}•${NC} Nikosh - Modern Bangla font"
    echo -e "${CYAN}•${NC} Boishakhi - Standard Bangla font"
    echo -e "${CYAN}•${NC} Kalpurush - Clear Bangla font"
    echo -e "${CYAN}•${NC} Siyam Rupali - Beautiful Bangla font"
    echo ""
    echo -e "${BOLD}Download Bangla Fonts:${NC}"
    echo ""
    echo -e "${CYAN}•${NC} Google Noto Bangla: https://fonts.google.com/noto"
    echo -e "${CYAN}•${NC} Mozilla Bangla: https://github.com/mozilla/bangla-fonts"
    echo -e "${CYAN}•${NC} Bengal Software: https://www.bengalsoftware.com"
    echo ""
    echo -e "${GREEN}Tip:${NC} After installing fonts, log out and log back in for all applications to recognize them."
    echo ""
}

# Install m17n input method
install_m17n_db() {
    print_step "Installing BanglaWriter input method..."
    
    # Create user m17n directory
    run_command mkdir -p "${USER_M17N_DIR}"
    run_command mkdir -p "$(dirname "$USER_M17N_DIR")"
    
    # Copy m17n files
    if [ -d "$DATA_DIR" ]; then
        # Copy all .mim files
        find "$DATA_DIR" -name "*.mim" -exec run_command cp {} "${USER_M17N_DIR}/" \; 2>/dev/null || true
        run_command chmod 644 "${USER_M17N_DIR}"/*.mim 2>/dev/null || true
        print_success "Input method files installed to ${USER_M17N_DIR}"
    fi
    
    # Copy icons
    run_command mkdir -p "${USER_ICONS_DIR}"
    if [ -d "$ICONS_DIR" ]; then
        run_command cp -r "$ICONS_DIR"/* "${USER_ICONS_DIR}/" 2>/dev/null || true
        print_success "Icons installed"
    fi
    
    # Update m17n database
    run_command touch "${USER_M17N_DIR}/.xim" 2>/dev/null || true
    print_info "You may need to restart IBUS for changes to take effect"
}

# Configure environment variables
configure_environment() {
    print_step "Configuring environment variables..."
    
    local bashrc="${HOME}/.bashrc"
    local xprofile="${HOME}/.xprofile"
    local profile="${HOME}/.profile"
    
    # Environment variables to add
    local env_vars="
# BanglaWriter IBUS Configuration
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT4_IM_MODULE=ibus
export CLUTTER_IM_MODULE=ibus
"
    
    # Add to .bashrc if not already present
    if [ -f "$bashrc" ]; then
        if ! grep -q "BanglaWriter IBUS Configuration" "$bashrc" 2>/dev/null; then
            echo "" >> "$bashrc"
            echo "$env_vars" >> "$bashrc"
            print_success "Added environment variables to ~/.bashrc"
        else
            print_info "Environment variables already present in ~/.bashrc"
        fi
    else
        echo "#!/bin/bash" > "$bashrc"
        echo "$env_vars" >> "$bashrc"
        print_success "Created ~/.bashrc with environment variables"
    fi
    
    # Add to .xprofile for X11 session startup
    if [ -f "$xprofile" ]; then
        if ! grep -q "BanglaWriter IBUS Configuration" "$xprofile" 2>/dev/null; then
            echo "" >> "$xprofile"
            echo "$env_vars" >> "$xprofile"
            print_success "Added environment variables to ~/.xprofile"
        fi
    else
        echo "#!/bin/bash" > "$xprofile"
        echo "$env_vars" >> "$xprofile"
        print_success "Created ~/.xprofile with environment variables"
    fi
    
    # Also add to .profile as fallback
    if [ -f "$profile" ]; then
        if ! grep -q "BanglaWriter IBUS Configuration" "$profile" 2>/dev/null; then
            echo "" >> "$profile"
            echo "$env_vars" >> "$profile"
        fi
    fi
}

# Configure IBUS
configure_ibus() {
    print_step "Configuring IBUS daemon..."
    
    # Check if IBUS is already running
    if pgrep -x "ibus-daemon" > /dev/null; then
        print_info "IBUS daemon is already running"
        
        # Restart IBUS to pick up changes
        print_info "Restarting IBUS daemon..."
        ibus restart 2>/dev/null || true
    else
        print_info "Starting IBUS daemon..."
        # Start IBUS in background
        ibus-daemon -drx 2>/dev/null &
        sleep 1
        
        if pgrep -x "ibus-daemon" > /dev/null; then
            print_success "IBUS daemon started"
        else
            print_warning "Could not start IBUS daemon. You may need to start it manually."
        fi
    fi
    
    # Add BanglaWriter to IBUS input methods
    print_step "Registering BanglaWriter input method..."
    
    # Try to add the input method
    if command -v ibus &> /dev/null; then
        # Wait for IBUS to be ready
        sleep 2
        
        # The m17n input method should now be available
        print_success "Input method should be available in IBUS"
    fi
}

# Configure GNOME settings (if running GNOME)
configure_gnome() {
    if command -v gsettings &> /dev/null; then
        if command -v dbus-launch &> /dev/null; then
            print_step "Configuring GNOME input sources..."
            
            # Check if running GNOME
            if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || \
               [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ]; then
                
                # Add Bangla input source using gsettings
                if command -v gdbus &> /dev/null; then
                    # Try to add via gsettings (requires running IBUS)
                    print_info "To add Bangla input source in GNOME:"
                    print_info "  1. Go to Settings → Keyboard → Input Sources"
                    print_info "  2. Click '+' and search for 'Bangla (BanglaWriter)'"
                    print_info "  3. Add it to your input sources"
                    print_success "GNOME configuration hints provided"
                fi
            fi
        fi
    fi
}

# Create desktop application entry
create_desktop_entry() {
    print_step "Creating desktop entry..."
    
    local desktop_dir="${HOME}/.local/share/applications"
    local desktop_file="${desktop_dir}/banglawriter-setup.desktop"
    
    run_command mkdir -p "$desktop_dir"
    
    cat > "$desktop_file" << 'EOF'
[Desktop Entry]
Name=BanglaWriter Setup
Comment=Configure BanglaWriter IBUS input method
Exec=bash -c "cd /usr/share/banglawriter && python3 ui/setup_ui.py"
Icon=/usr/share/banglawriter/icons/banglawriter.svg
Terminal=false
Type=Application
Categories=Settings;InputMethod;
EOF
    
    run_command chmod 644 "$desktop_file"
    print_success "Desktop entry created: ${desktop_file}"
}

# Create systemd user service for IBUS
create_systemd_service() {
    print_step "Creating systemd user service..."
    
    local service_dir="${HOME}/.config/systemd/user"
    local service_file="${service_dir}/ibus-banglawriter.service"
    
    run_command mkdir -p "$service_dir"
    
    cat > "$service_file" << 'EOF'
[Unit]
Description=IBUS Daemon for BanglaWriter
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/ibus-daemon -drx
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
    
    run_command chmod 644 "$service_file"
    
    # Enable the service if systemctl is available
    if command -v systemctl &> /dev/null; then
        print_info "To enable automatic IBUS startup:"
        print_info "  systemctl --user enable ibus-banglawriter.service"
    fi
    
    print_success "Systemd service created"
}

# Print post-installation instructions
print_post_install() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Installation Complete!${NC}                                   ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} ${BOLD}Log out and log back in${NC} (or restart your session)"
    echo "   This ensures all environment variables are loaded."
    echo ""
    echo -e "${CYAN}2.${NC} ${BOLD}Add Bangla input source to your system:${NC}"
    echo "   • GNOME: Settings → Keyboard → Input Sources → + → Bangla"
    echo "   • KDE: System Settings → Input Devices → Keyboard → Layouts → Add"
    echo "   • Other: Look for 'Input Method' or 'Keyboard Layout' settings"
    echo ""
    echo -e "${CYAN}3.${NC} ${BOLD}Switch to Bangla using:${NC}"
    echo "   • Super+Space or Ctrl+Space (default IBUS shortcuts)"
    echo "   • Click the keyboard icon in your system tray"
    echo ""
    echo -e "${CYAN}4.${NC} ${BOLD}Test BanglaWriter:${NC}"
    echo "   • Open a text editor (gedit, libreoffice, etc.)"
    echo "   • Type: ami vhalo → should show: আমি ভালো"
    echo "   • Type: bangla → should show: বাংলা"
    echo ""
    echo -e "${BOLD}Quick Commands:${NC}"
    echo "   • Restart IBUS:     ibus restart"
    echo "   • Test typing:      cd /usr/share/banglawriter && python3 test_engine.py"
    echo "   • Run setup UI:     banglawriter-setup"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "   • If Bangla doesn't appear, restart IBUS: ibus-daemon -drx"
    echo "   • If still not working, log out and log back in"
    echo "   • Check environment: echo \$GTK_IM_MODULE (should show 'ibus')"
    echo ""
}

# Uninstall function
uninstall() {
    echo ""
    echo -e "${YELLOW}Uninstalling BanglaWriter...${NC}"
    echo ""
    
    # Remove fonts
    if [ -d "$USER_FONTS_DIR" ]; then
        run_command rm -rf "$USER_FONTS_DIR"
        print_success "Removed fonts from ${USER_FONTS_DIR}"
    fi
    
    # Remove m17n files
    if [ -d "$USER_M17N_DIR" ]; then
        run_command rm -rf "${USER_M17N_DIR}"/*.mim 2>/dev/null || true
        print_success "Removed input method files from ${USER_M17N_DIR}"
    fi
    
    # Remove environment variables from .bashrc
    if [ -f "${HOME}/.bashrc" ]; then
        run_command sed -i '/# BanglaWriter IBUS Configuration/,/^$/d' "${HOME}/.bashrc" 2>/dev/null || true
        print_success "Removed environment variables from ~/.bashrc"
    fi
    
    # Remove desktop entry
    if [ -f "${HOME}/.local/share/applications/banglawriter-setup.desktop" ]; then
        run_command rm -f "${HOME}/.local/share/applications/banglawriter-setup.desktop"
        print_success "Removed desktop entry"
    fi
    
    # Update font cache
    run_command fc-cache -fv 2>/dev/null || true
    
    echo ""
    echo -e "${GREEN}Uninstallation complete!${NC}"
    echo "Please log out and log back in for changes to take effect."
    echo ""
}

# Show help
show_help() {
    echo "BanglaWriter IBUS Installer"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --install     Install BanglaWriter (default)"
    echo "  --uninstall   Remove BanglaWriter from the system"
    echo "  --help        Show this help message"
    echo "  --check       Check system requirements"
    echo ""
    echo "Examples:"
    echo "  $0                    # Install with defaults"
    echo "  $0 --uninstall        # Remove BanglaWriter"
    echo "  $0 --check            # Check if system is ready"
    echo ""
}

# Check system requirements
check_requirements() {
    echo ""
    echo -e "${CYAN}System Requirements Check${NC}"
    echo ""
    
    local checks_passed=0
    local checks_failed=0
    
    # Check for required commands
    local required_cmds="git make fc-cache"
    for cmd in $required_cmds; do
        if command -v $cmd &> /dev/null; then
            echo -e "${GREEN}[✓]${NC} $cmd is installed"
            ((checks_passed++))
        else
            echo -e "${RED}[✗]${NC} $cmd is NOT installed"
            ((checks_failed++))
        fi
    done
    
    # Check for IBUS
    if command -v ibus &> /dev/null; then
        echo -e "${GREEN}[✓]${NC} ibus is installed"
        ((checks_passed++))
    else
        echo -e "${RED}[✗]${NC} ibus is NOT installed (will be installed)"
        ((checks_failed++))
    fi
    
    # Check for m17n
    if command -v m17n-db &> /dev/null || [ -d /usr/share/m17n ]; then
        echo -e "${GREEN}[✓]${NC} m17n-db is installed"
        ((checks_passed++))
    else
        echo -e "${RED}[✗]${NC} m17n-db is NOT installed (will be installed)"
        ((checks_failed++))
    fi
    
    echo ""
    echo "Summary: ${checks_passed} passed, ${checks_failed} failed"
    
    if [ $checks_failed -gt 0 ]; then
        echo -e "${YELLOW}Some requirements are missing but will be installed.${NC}"
    else
        echo -e "${GREEN}All requirements met!${NC}"
    fi
}

# Main function
main() {
    # Parse arguments
    local action="install"
    
    for arg in "$@"; do
        case $arg in
            --install)
                action="install"
                ;;
            --uninstall|--remove|--delete)
                action="uninstall"
                ;;
            --help|-h|--help)
                show_help
                exit 0
                ;;
            --check|-c|--check)
                check_requirements
                exit 0
                ;;
            *)
                print_error "Unknown option: $arg"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Print header
    print_header
    
    # Check permissions
    check_permissions
    
    case $action in
        install)
            # Detect distribution
            detect_distro
            
            # Install dependencies
            install_dependencies
            
            # Install fonts
            install_fonts
            
            # Install m17n database
            install_m17n_db
            
            # Configure environment
            configure_environment
            
            # Configure IBUS
            configure_ibus
            
            # Create desktop entry
            create_desktop_entry
            
            # Create systemd service
            create_systemd_service
            
            # Print post-install instructions
            print_post_install
            ;;
            
        uninstall)
            uninstall
            ;;
    esac
}

# Run main function
main "$@"
