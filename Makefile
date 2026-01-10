# BanglaWriter Makefile
# Build and installation script for BanglaWriter input method
#
# Supports system-wide and user-only installation

# Installation paths
PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
SHAREDIR ?= $(PREFIX)/share
LIBDIR ?= $(PREFIX)/lib
IBUSDIR ?= $(SHAREDIR)/ibus
FONTSDIR ?= $(SHAREDIR)/fonts/truetype/banglawriter
M17NDIR ?= $(SHAREDIR)/m17n
ICONDIR ?= $(SHAREDIR)/m17n/icons

# Directories
ENGINE_DIR = engine
UI_DIR = ui
BIN_DIR = bin
ICONS_DIR = icons
DATA_DIR = data
DOCS_DIR = docs
FONTS_DIR = fonts

# User installation directories
USER_FONTS_DIR ?= $(HOME)/.local/share/fonts/banglawriter
USER_M17N_DIR ?= $(HOME)/.m17n.d
USER_ICONS_DIR ?= $(HOME)/.m17n.d/icons

# Installation directories
INSTALL_ENGINE_DIR = $(DESTDIR)$(LIBDIR)/banglawriter
INSTALL_UI_DIR = $(DESTDIR)$(LIBDIR)/banglawriter/ui
INSTALL_BIN_DIR = $(DESTDIR)$(BINDIR)
INSTALL_ICONS_DIR = $(DESTDIR)$(ICONDIR)
INSTALL_FONTS_DIR = $(DESTDIR)$(FONTSDIR)
INSTALL_DATA_DIR = $(DESTDIR)$(M17NDIR)
INSTALL_IBUS_DIR = $(DESTDIR)$(IBUSDIR)
INSTALL_DOCS_DIR = $(DESTDIR)$(SHAREDIR)/doc/banglawriter

# Python files
ENGINE_FILES = $(wildcard $(ENGINE_DIR)/*.py)
UI_FILES = $(wildcard $(UI_DIR)/*.py)

# Bin files
BIN_FILES = $(wildcard $(BIN_DIR)/*)

# Icon files
ICON_FILES = $(wildcard $(ICONS_DIR)/*)

# Data files
DATA_FILES = $(wildcard $(DATA_DIR)/*)

# Font files
FONT_FILES = $(wildcard $(FONTS_DIR)/*.*)

# Documentation files
DOCS_FILES = $(wildcard $(DOCS_DIR)/*)

.PHONY: all install uninstall user-install check test clean help full-install

# Default target
all: help

# Help target
help:
	@echo ""
	@echo "BanglaWriter - Phonetic Bangla Typing for Linux"
	@echo "=============================================="
	@echo ""
	@echo "Usage: make [command] [options]"
	@echo ""
	@echo "Commands:"
	@echo "  install       Install BanglaWriter system-wide (requires root)"
	@echo "  user-install  Install BanglaWriter to user directory (no root)"
	@echo "  uninstall     Remove BanglaWriter from system"
	@echo "  full-install  Install engine, binaries, fonts, and IBUS setup"
	@echo "  check         Check system requirements"
	@echo "  test          Run transliteration engine tests"
	@echo "  clean         Clean build artifacts"
	@echo "  help          Show this help message"
	@echo ""
	@echo "Options:"
	@echo "  PREFIX=<path>  Installation prefix (default: /usr)"
	@echo ""
	@echo "Quick Start:"
	@echo "  sudo make install        # System-wide installation"
	@echo "  make user-install        # User-only installation"
	@echo "  make test                # Test the engine"
	@echo "  ./install.sh             # Interactive installer"
	@echo ""

# Check dependencies
check:
	@echo ""
	@echo "Checking system requirements..."
	@echo ""
	
	@echo "Required commands:"
	@which git >/dev/null 2>&1 && echo "  [OK] git" || echo "  [!!] git (optional)"
	@which make >/dev/null 2>&1 && echo "  [OK] make" || echo "  [!!] make (required)"
	@which fc-cache >/dev/null 2>&1 && echo "  [OK] fontconfig" || echo "  [!!] fontconfig (required)"
	
	@echo ""
	@echo "IBUS components:"
	@which ibus >/dev/null 2>&1 && echo "  [OK] ibus" || echo "  [!!] ibus (NOT INSTALLED)"
	@which ibus-daemon >/dev/null 2>&1 && echo "  [OK] ibus-daemon" || echo "  [!!] ibus-daemon"
	
	@echo ""
	@echo "m17n components:"
	@which m17n-db >/dev/null 2>&1 && echo "  [OK] m17n-db" || echo "  [!!] m17n-db (NOT INSTALLED)"
	@test -d /usr/share/m17n && echo "  [OK] m17n directory" || echo "  [!!] m17n directory"
	
	@echo ""
	@echo "Python:"
	@python3 --version 2>/dev/null | head -1 && echo "  [OK] python3" || echo "  [!!] python3 (required)"
	
	@echo ""
	@echo "=============================================="
	@echo "For installation, run: sudo make install"
	@echo "=============================================="
	@echo ""

# System-wide installation
install: check
	@echo ""
	@echo "Installing BanglaWriter system-wide..."
	@echo ""
	
	@echo "[1/7] Creating directories..."
	@sudo mkdir -p $(INSTALL_ENGINE_DIR)
	@sudo mkdir -p $(INSTALL_UI_DIR)
	@sudo mkdir -p $(INSTALL_BIN_DIR)
	@sudo mkdir -p $(INSTALL_ICONS_DIR)
	@sudo mkdir -p $(INSTALL_FONTS_DIR)
	@sudo mkdir -p $(INSTALL_DATA_DIR)
	@sudo mkdir -p $(INSTALL_IBUS_DIR)
	@sudo mkdir -p $(INSTALL_DOCS_DIR)
	
	@echo "[2/7] Installing engine files..."
	@sudo cp $(ENGINE_FILES) $(INSTALL_ENGINE_DIR)/
	
	@echo "[3/7] Installing UI files..."
	@sudo cp $(UI_FILES) $(INSTALL_UI_DIR)/
	
	@echo "[4/7] Installing binaries..."
	@sudo cp $(BIN_FILES) $(INSTALL_BIN_DIR)/
	@sudo chmod +x $(INSTALL_BIN_DIR)/banglawriter-engine
	@sudo chmod +x $(INSTALL_BIN_DIR)/banglawriter-setup
	
	@echo "[5/7] Installing fonts..."
	@sudo cp -r $(FONTS_DIR)/* $(INSTALL_FONTS_DIR)/ 2>/dev/null || echo "  (No fonts to install)"
	
	@echo "[6/7] Installing input method and data..."
	@sudo cp $(DATA_FILES) $(INSTALL_DATA_DIR)/
	@sudo chmod 644 $(INSTALL_DATA_DIR)/*.mim 2>/dev/null || true
	@sudo cp $(ICON_FILES) $(INSTALL_ICONS_DIR)/ 2>/dev/null || echo "  (No icons to install)"
	@sudo cp $(DATA_DIR)/banglawriter.xml $(INSTALL_IBUS_DIR)/
	
	@echo "[7/7] Updating databases..."
	@sudo fc-cache -fv 2>/dev/null || true
	
	@echo ""
	@echo "=============================================="
	@echo "System-wide Installation Complete!"
	@echo "=============================================="
	@echo ""
	@echo "Next Steps:"
	@echo "  1. Log out and log back in"
	@echo "  2. Add 'Bangla (BanglaWriter)' in your keyboard settings"
	@echo "  3. Use Super+Space to switch to Bangla"
	@echo ""
	@echo "Test: make test"
	@echo ""

# User-only installation (no root required)
user-install: check
	@echo ""
	@echo "Installing BanglaWriter to user directory..."
	@echo ""
	
	@echo "[1/4] Creating directories..."
	@mkdir -p $(USER_FONTS_DIR)
	@mkdir -p $(USER_M17N_DIR)
	@mkdir -p $(USER_ICONS_DIR)
	
	@echo "[2/4] Installing fonts..."
	@cp -r $(FONTS_DIR)/* $(USER_FONTS_DIR)/ 2>/dev/null || echo "  (No fonts to install)"
	
	@echo "[3/4] Installing input method..."
	@cp $(DATA_FILES) $(USER_M17N_DIR)/
	@chmod 644 $(USER_M17N_DIR)/*.mim 2>/dev/null || true
	@cp $(ICON_FILES) $(USER_ICONS_DIR)/ 2>/dev/null || echo "  (No icons to install)"
	
	@echo "[4/4] Updating databases..."
	@fc-cache -fv 2>/dev/null || true
	
	@echo ""
	@echo "=============================================="
	@echo "User Installation Complete!"
	@echo "=============================================="
	@echo ""
	@echo "Important: Add to ~/.bashrc:"
	@echo ""
	@echo "  export GTK_IM_MODULE=ibus"
	@echo "  export QT_IM_MODULE=ibus"
	@echo "  export XMODIFIERS=@im=ibus"
	@echo ""
	@echo "Then restart IBUS: ibus-daemon -drx"
	@echo ""

# Full installation (engine + bin + fonts + IBUS)
full-install: install
	@echo ""
	@echo "=============================================="
	@echo "Full Installation Includes:"
	@echo "  - Transliteration engine"
	@echo "  - Setup UI application"
	@echo "  - IBUS integration"
	@echo "  - Bangla fonts"
	@echo "=============================================="
	@echo ""

# Uninstall target
uninstall:
	@echo ""
	@echo "Uninstalling BanglaWriter..."
	@echo ""
	
	@echo "[1/6] Removing engine files..."
	@sudo rm -f $(INSTALL_ENGINE_DIR)/*.py
	@sudo rmdir $(INSTALL_ENGINE_DIR) 2>/dev/null || true
	
	@echo "[2/6] Removing UI files..."
	@sudo rm -f $(INSTALL_UI_DIR)/*.py
	@sudo rmdir $(INSTALL_UI_DIR) 2>/dev/null || true
	
	@echo "[3/6] Removing binaries..."
	@sudo rm -f $(INSTALL_BIN_DIR)/banglawriter-engine
	@sudo rm -f $(INSTALL_BIN_DIR)/banglawriter-setup
	
	@echo "[4/6] Removing fonts..."
	@sudo rm -rf $(INSTALL_FONTS_DIR) 2>/dev/null || true
	
	@echo "[5/6] Removing input method and data..."
	@sudo rm -f $(INSTALL_DATA_DIR)/*.mim
	@sudo rm -f $(INSTALL_DATA_DIR)/*.xml
	@sudo rmdir $(INSTALL_DATA_DIR) 2>/dev/null || true
	@sudo rm -f $(INSTALL_IBUS_DIR)/banglawriter.xml
	@sudo rmdir $(INSTALL_IBUS_DIR) 2>/dev/null || true
	
	@echo "[6/6] Updating databases..."
	@sudo fc-cache -fv 2>/dev/null || true
	
	@echo ""
	@echo "=============================================="
	@echo "Uninstallation Complete!"
	@echo "=============================================="
	@echo ""
	@echo "Please log out and log back in for changes to take effect."
	@echo ""

# Test target
test:
	@echo ""
	@echo "Running BanglaWriter transliteration tests..."
	@echo ""
	
	@if [ -f test_engine.py ]; then \
		python3 test_engine.py; \
	else \
		echo "Test file not found. Running inline tests..."; \
		python3 -c "
from engine.transliteration import TransliterationEngine, transliterate

engine = TransliterationEngine()

# Test cases
tests = [
    ('ami', 'আমি'),
    ('vhalo', 'ভালো'),
    ('bhalo', 'ভালো'),
    ('bangla', 'বাংলা'),
    ('desh', 'দেশ'),
]

passed = 0
failed = 0

for roman, expected in tests:
    engine.reset()
    for c in roman:
        engine.process_key(c)
    result = engine.get_preedit_text()
    if result == expected:
        print(f'  OK: {roman} -> {result}')
        passed += 1
    else:
        print(f'  FAIL: {roman} -> {result} (expected: {expected})')
        failed += 1

print(f'')
print(f'Results: {passed} passed, {failed} failed')
"
	fi
	
	@echo ""

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -f *.pyc
	@rm -f **/*.pyc 2>/dev/null || true
	@rm -rf __pycache__ 2>/dev/null || true
	@rm -rf engine/__pycache__ 2>/dev/null || true
	@rm -rf ui/__pycache__ 2>/dev/null || true
	@echo "Clean complete!"
