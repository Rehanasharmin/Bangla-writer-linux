# BanglaWriter - Bangla Input Method for Linux

**⚠️ i dont recommend you to install that software now. its in under development and has mich much issues. install.sh file still giving errors. I hope i can release it as soon as possible**

A production-ready Bangla input method for Linux that converts Romanized Bengali to proper Bangla script using phonetic transliteration.

## One-Click Installation

### Quick Install (All Distributions)

```bash
# Clone the repository
git clone https://github.com/Rehanasharmin/Bangla-writer-linux.git
cd Bangla-writer-linux

# Run the one-click installer
chmod +x install.sh
sudo ./install.sh

# Log out and log back in
# Then add BanglaWriter from your system settings
```

The installer will automatically:
- Detect your Linux distribution
- Install required packages (IBUS, m17n, fontconfig)
- Deploy Bangla fonts
- Configure the input method
- Set up environment variables

### Supported Distributions

- Ubuntu 20.04+
- Debian 11+
- Fedora 35+
- Arch Linux
- Manjaro
- openSUSE

### Manual Installation

#### Using Make (Ubuntu/Debian)

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y ibus ibus-m17n m17n-db fontconfig git make

# Install BanglaWriter
cd Bangla-writer-linux
sudo make install

# Restart IBUS
ibus restart
```

#### Using Make (Fedora)

```bash
# Install dependencies
sudo dnf install -y ibus ibus-m17n m17n-db fontconfig git make

# Install BanglaWriter
cd Bangla-writer-linux
sudo make install

# Restart IBUS
ibus restart
```

#### Using Make (Arch Linux)

```bash
# Install dependencies
sudo pacman -Sy ibus m17n-db fontconfig git make

# Install BanglaWriter
cd Bangla-writer-linux
sudo make install

# Restart IBUS
ibus restart
```

### User-Only Installation (No Root)

For systems where you cannot use sudo:

```bash
cd Bangla-writer-linux
make user-install

# Add to ~/.bashrc:
echo 'export GTK_IM_MODULE=ibus' >> ~/.bashrc
echo 'export QT_IM_MODULE=ibus' >> ~/.bashrc
echo 'export XMODIFIERS=@im=ibus' >> ~/.bashrc

# Restart IBUS
ibus-daemon -drx
```

## Features

- **Phonetic Transliteration**: Type "Ami vhalo" and get "আমি ভালো"
- **Intelligent Transliteration Engine**: Handles complex Bengali phonology
- **IBUS Integration**: Seamless integration with the IBUS input method framework
- **Cross-Distribution**: Works on Ubuntu, Debian, Fedora, Arch, and more
- **Custom Bangla Fonts**: Properly renders all Bangla characters
- **Word Suggestions**: Intelligent auto-completion

## Usage

### Basic Typing Examples

| You Type | You Get |
|----------|---------|
| ami | আমি |
| vhalo | ভালো |
| bangla | বাংলা |
| desh | দেশ |
| phon | ফোন |
| bhasha | ভাষা |

### Keyboard Shortcuts

- **Ctrl+Space**: Toggle input method
- **Super+Space** (Win+Space): Switch keyboard layout (system-wide)
- **Escape**: Cancel current input
- **Backspace**: Delete last character
- **Enter**: Commit current text

### After Installation

1. **Log out and log back in** (or restart your session)
2. **Open System Settings** → Keyboard → Input Sources
3. **Click +** and search for "Bangla (BanglaWriter)"
4. **Add it** to your input sources
5. **Use Super+Space** to switch between English and Bangla

## Transliteration Rules

### Vowels

```
a  → অ        aa/A → আ       i → ই       ee/I → ঈ
u  → উ        oo/U → ঊ      ri/R → ঋ     e → এ
ai/oi → ঐ    o → ও        ou/O → ঔ
```

### Consonants

```
k  → ক        kh → খ        g → গ        gh → ঘ
ng → ং        c → চ         ch → ছ       j → জ
jh → ঝ        ny → ঞ        T → ট        th → ঠ
D  → ড        dh → ঢ        n → ণ        t → ত
d  → দ        n → ন         p → প        ph → ফ
b  → ব        bh → ভ        m → ম        y → য
r  → র        l → ল         s → স        sh → শ
h  → হ        rh → ড়      rrh → ঢ়
```

### Conjuncts (Yuktakshara)

```
kk  → ক্ক     ks → ক্স      ksh → ক্ষ     gn → গ্ন
jj  → জ্জ     jn → জ্ঞ      tt → ট্ট     rn → র্ন
rm  → র্ম     rl → র্ল      st → স্ত     str → স্ত্র
```

## Testing

Run the transliteration tests:

```bash
make test
```

Or run manually:

```bash
cd Bangla-writer-linux
python3 test_engine.py
```

Expected output should show all tests passing for core functionality like:
- ami → আমি
- vhalo → ভালো
- bangla → বাংলা

## Uninstalling

```bash
cd Bangla-writer-linux
sudo make uninstall

# Log out and log back in
```

## Troubleshooting

### Bangla Text Not Rendering

```bash
# Install Noto Sans Bengali
sudo apt-get install fonts-noto-bengali  # Ubuntu/Debian
sudo dnf install google-noto-sans-bengali  # Fedora

# Update font cache
fc-cache -fv
```

### IBUS Not Detecting BanglaWriter

```bash
# Restart IBUS
ibus restart

# Check if engine is registered
ibus list-engines | grep Bangla

# If still not working, try:
ibus exit
ibus-daemon -drx
```

### Input Method Not Appearing in Settings

```bash
# Verify installation
ls /usr/share/m17n/bangla*.mim

# Restart IBUS daemon
ibus exit
ibus-daemon -drx
```

### Environment Variables Not Set

Add to your ~/.bashrc or ~/.profile:

```bash
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export CLUTTER_IM_MODULE=ibus
```

Then reload:
```bash
source ~/.bashrc
```

## Project Structure

```
Bangla-writer-linux/
├── install.sh           # One-click installer script
├── Makefile             # Build and installation automation
├── test_engine.py       # Transliteration tests
├── engine/
│   ├── transliteration.py   # Core transliteration logic
│   └── engine.py            # IBUS engine implementation
├── ui/
│   └── setup_ui.py          # GTK settings dialog
├── bin/
│   ├── banglawriter-engine  # Engine entry point
│   └── banglawriter-setup   # Settings launcher
├── data/
│   ├── bangla.mim           # M17N input method definition
│   └── banglawriter.xml     # IBUS component XML
├── fonts/                   # Bangla fonts
├── icons/                   # Application icons
└── README.md            # This file
```

## Building Packages

### DEB Package (Debian/Ubuntu)

```bash
# Install build tools
sudo apt-get install devscripts debhelper

# Build package
debuild -us -uc
```

### RPM Package (Fedora/RHEL)

```bash
# Install build tools
sudo dnf install rpm-build

# Build package
rpmbuild -ba rpm/banglawriter.spec
```

### Arch Package

```bash
cd arch
makepkg -s
```

## License

This project is licensed under the **GNU General Public License v3.0**.

You are free to:
- Use this software freely in personal and commercial projects
- Modify the software for your needs
- Redistribute the software
- Create derivative works

See [LICENSE](LICENSE) for full details.

## Contributing

Contributions are welcome! Areas where help is needed:

1. **Dictionary Expansion**: Add more common Bangla words
2. **Testing**: Test on different distributions and applications
3. **Bug Reports**: Report rendering or transliteration issues
4. **Feature Requests**: Suggest new features

## Contact

- **GitHub**: [bangla-writer](https://github.com/yourusername/bangla-writer)
- **Issues**: Report bugs and request features on GitHub

---

Made with ❤️ for the Bangla-speaking Linux community
