# BanglaWriter Fonts Directory

This directory is for storing Bangla fonts that will be installed with BanglaWriter.

## Automatic Font Installation

**Fonts are automatically downloaded during installation!** The installer will download:

- **Noto Sans Bangla** - Modern, versatile Bangla font by Google
- **Noto Serif Bangla** - Formal serif Bangla font by Google
- **Lohit Bengali** - Standard Bengali font (Fedora default)

## Adding Custom Fonts

To add a custom Bangla font:

1. Place your font file (.ttf or .otf format) in this directory
2. Supported formats: TTF, OTF, WOFF
3. Font file naming convention: Use lowercase with hyphens
   - Example: banglawriter-regular.ttf

## Font Installation

Fonts are installed to:
- System-wide: /usr/share/fonts/truetype/banglawriter/
- User-only: ~/.local/share/fonts/banglawriter/

## Font Configuration

After installing fonts, run:
```bash
fc-cache -fv
```

To verify font installation:
```bash
fc-list | grep BanglaWriter
```

## Recommended Font Sources

- Google Fonts Noto Bangla: https://fonts.google.com/noto
- Fedora Lohit Bengali: https://src.fedoraproject.org/rpms/lohit-bengali
- Ekushey Project: https://www.ekushey.org/

## License

Ensure all fonts in this directory have appropriate licenses for redistribution.
