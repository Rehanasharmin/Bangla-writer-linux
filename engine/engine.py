#!/usr/bin/env python3
"""
BanglaWriter IBUS Engine
IBUS input method engine for Bangla transliteration.

This module implements the IBUS engine interface for the BanglaWriter
input method, handling key events, candidate windows, and text commit.
"""

import sys
import os
import signal
import threading
from typing import Tuple, Optional, List, Dict

try:
    import gi
    gi.require_version('IBus', '1.0')
    from gi.repository import IBus, GLib, GObject
except ImportError:
    print("Error: IBus Python bindings not found.")
    print("Please install: sudo apt-get install python3-gi gir1.2-ibus-1.0")
    sys.exit(1)

from transliteration import TransliterationEngine, Mode


# Component XML descriptor for IBUS registration
COMPONENT_XML = """<?xml version="1.0" encoding="utf-8"?>
<component>
    <version>1.0.0</version>
    <name>com.banglawriter</name>
    <description>BanglaWriter - Bangla Input Method for Linux</description>
    <author>MiniMax Agent</author>
    <license>SIL Open Font License 1.1</license>
    <host:exec>/usr/bin/banglawriter-engine</host:exec>
    <host:version>1.0</host:version>
</component>
"""


class BanglaWriterEngine(IBus.Engine):
    """
    Main IBUS engine for BanglaWriter input method.
    
    Handles:
    - Key event processing
    - Preedit text display
    - Candidate window management
    - Mode switching (Bangla/ASCII)
    """
    
    # Engine name and description
    ENGINE_NAME = "BanglaWriter"
    ENGINE_LONG_NAME = "BanglaWriter - Bangla Input Method"
    ENGINE_DESCRIPTION = "Phonetic Bangla transliteration input method"
    ENGINE_LANGUAGE = "bn"
    ENGINE_AUTHOR = "MiniMax Agent"
    ENGINE_ICON = "/usr/share/banglawriter/icons/banglawriter.svg"
    
    def __init__(self, bus: IBus.Bus):
        """Initialize the engine.
        
        Args:
            bus: IBus bus connection
        """
        super().__init__()
        self.bus = bus
        self.transliteration = TransliterationEngine()
        self.is_active = False
        self.current_mode = Mode.BANGLA
        
        # Preedit text tracking
        self.preedit_text = ""
        self.preedit_cursor = 0
        
        # Candidate window
        self.candidates = []
        self.candidate_index = 0
        self.candidate_showing = False
        
        # Key handling
        self.modifier_state = 0
        
        # Focus handling
        self.is_focused = False
        
        # Configuration
        self.config = self._load_config()
        
        # Setup signal handlers
        self._setup_signal_handlers()
    
    def _load_config(self) -> Dict:
        """Load engine configuration.
        
        Returns:
            Configuration dictionary
        """
        config = {
            'auto_commit': True,
            'show_suggestions': True,
            'suggestion_page_size': 10,
            'candidate_window_orientation': IBus.Orientation.VERTICAL,
        }
        
        # Try to load from IBUS config
        try:
            config_obj = self.bus.get_config()
            if config_obj:
                for key in config.keys():
                    value = config_obj.get_value("banglawriter", key)
                    if value is not None:
                        config[key] = value
        except Exception:
            pass
        
        return config
    
    def _setup_signal_handlers(self):
        """Setup signal handlers for cleanup."""
        pass
    
    def do_reset(self):
        """Reset the engine state."""
        self.transliteration.reset()
        self.preedit_text = ""
        self.preedit_cursor = 0
        self.candidates = []
        self.candidate_index = 0
        self.candidate_showing = False
        self._update_preedit()
        self._hide_candidate_window()
    
    def do_process_key_event(self, keyval: int, keycode: int, state: int) -> bool:
        """Process a key event.
        
        Args:
            keyval: Key symbol value
            keycode: Key code
            state: Modifier state
            
        Returns:
            True if key was handled, False otherwise
        """
        self.modifier_state = state
        
        # Get key character
        keychar = chr(IBus.keyval_to_unicode(keyval))
        
        # Handle mode switch (Shift+Alt or F12)
        if keyval == IBus.KEY_F12:
            self._toggle_mode()
            return True
        
        if keyval == IBus.KEY_Escape:
            if self.candidate_showing:
                self._hide_candidate_window()
                return True
            else:
                self.transliteration.reset()
                self._commit_preedit()
                return True
        
        if keyval == IBus.KEY_space:
            if self.preedit_text:
                committed = self.transliteration.commit_buffer()
                if committed:
                    self._commit_text(committed)
                    self._update_preedit()
                elif not self.candidate_showing:
                    # Space commits buffer as-is
                    committed = self.transliteration.get_preedit_text()
                    if committed:
                        self._commit_text(committed)
                        self.transliteration.reset()
                        self._update_preedit()
                return True
            return False
        
        if keyval == IBus.KEY_Return or keyval == IBus.KEY_KP_Enter:
            if self.preedit_text:
                if self.candidate_showing and self.candidates:
                    # Commit selected candidate
                    if 0 <= self.candidate_index < len(self.candidates):
                        selected = self.candidates[self.candidate_index]
                        self._commit_text(selected)
                    else:
                        self._commit_text(self.transliteration.commit_buffer())
                else:
                    self._commit_text(self.transliteration.commit_buffer())
                self._update_preedit()
                self._hide_candidate_window()
                return True
            return False
        
        if keyval == IBus.KEY_BackSpace:
            if self.transliteration.backspace():
                self._update_preedit()
                if self.config['show_suggestions']:
                    self.candidates = self.transliteration.get_suggestions()
                    if self.candidates:
                        self._show_candidate_window()
                else:
                    self._hide_candidate_window()
                return True
            return False
        
        if keyval == IBus.KEY_Delete or keyval == IBus.KEY_KP_Delete:
            # Delete key - clear buffer and commit
            if self.preedit_text:
                self._commit_text(self.transliteration.get_preedit_text())
                self.transliteration.reset()
                self._update_preedit()
                self._hide_candidate_window()
            return True
        
        # Navigation in candidate window
        if self.candidate_showing:
            if keyval == IBus.KEY_Down or keyval == IBus.KEY_KP_Down:
                self.candidate_index = min(self.candidate_index + 1, len(self.candidates) - 1)
                self._update_candidate_window()
                return True
            
            if keyval == IBus.KEY_Up or keyval == IBus.KEY_KP_Up:
                self.candidate_index = max(self.candidate_index - 1, 0)
                self._update_candidate_window()
                return True
            
            if keyval == IBus.KEY_Page_Down:
                self.candidate_index = min(self.candidate_index + self.config['suggestion_page_size'], 
                                           len(self.candidates) - 1)
                self._update_candidate_window()
                return True
            
            if keyval == IBus.KEY_Page_Up:
                self.candidate_index = max(self.candidate_index - self.config['suggestion_page_size'], 0)
                self._update_candidate_window()
                return True
            
            # Number keys to select candidate
            if keyval in (IBus.KEY_1, IBus.KEY_2, IBus.KEY_3, IBus.KEY_4, IBus.KEY_5,
                         IBus.KEY_6, IBus.KEY_7, IBus.KEY_8, IBus.KEY_9, IBus.KEY_0):
                index = (keyval - IBus.KEY_1) % 10
                if index < len(self.candidates):
                    self._commit_text(self.candidates[index])
                    self._hide_candidate_window()
                    return True
        
        # Handle alphanumeric keys
        if keychar.isalnum() or keychar in [' ', '-', '.', ',', "'"]:
            if state & IBus.ModifierType.CONTROL_MASK:
                # Ctrl key combinations pass through
                return False
            
            if state & IBus.ModifierType.ALT_MASK:
                # Alt key combinations pass through
                return False
            
            if state & IBus.ModifierType.SUPER_MASK:
                # Super key combinations pass through
                return False
            
            # Process the key
            committed, suggestions, is_complete = self.transliteration.process_key(keychar)
            
            if committed:
                self._commit_text(committed)
            
            # Update preedit
            self._update_preedit()
            
            # Show suggestions if available
            if self.config['show_suggestions'] and suggestions:
                self.candidates = suggestions
                self.candidate_index = 0
                self._show_candidate_window()
            else:
                self._hide_candidate_window()
            
            return True
        
        # Pass through other keys
        return False
    
    def do_focus_in(self):
        """Called when engine gains focus."""
        self.is_focused = True
        self._update_preedit()
        if self.candidates:
            self._show_candidate_window()
    
    def do_focus_out(self):
        """Called when engine loses focus."""
        self.is_focused = False
        # Commit any pending text
        if self.preedit_text:
            self._commit_text(self.transliteration.commit_buffer())
            self._update_preedit()
        self._hide_candidate_window()
    
    def do_set_capabilities(self, caps: int):
        """Set engine capabilities.
        
        Args:
            caps: Capability flags
        """
        pass
    
    def do_candidate_clicked(self, index: int, button: int, x: int, y: int):
        """Handle candidate click.
        
        Args:
            index: Candidate index
            button: Mouse button
            x: X coordinate
            y: Y coordinate
        """
        if 0 <= index < len(self.candidates):
            self._commit_text(self.candidates[index])
            self._hide_candidate_window()
    
    def _toggle_mode(self):
        """Toggle between Bangla and ASCII modes."""
        if self.current_mode == Mode.BANGLA:
            self.current_mode = Mode.ASCII
            self.transliteration.set_mode(Mode.ASCII)
        else:
            self.current_mode = Mode.BANGLA
            self.transliteration.set_mode(Mode.BANGLA)
        
        # Update UI
        self._update_preedit()
    
    def _update_preedit(self):
        """Update the preedit text display."""
        self.preedit_text = self.transliteration.get_preedit_text()
        self.preedit_cursor = len(self.preedit_text)
        
        # Update IBus preedit
        if self.preedit_text:
            attr_list = IBus.AttrList()
            # Underline the preedit text
            attr_list.append(IBus.Attribute.new(
                IBus.AttrType.UNDERLINE,
                IBus.AttrUnderline.SINGLE,
                0,
                len(self.preedit_text)
            ))
            
            self.update_preedit_text(
                IBus.Text.new_from_string(self.preedit_text),
                self.preedit_cursor,
                True
            )
        else:
            self.update_preedit_text(
                IBus.Text.new_from_string(""),
                0,
                False
            )
    
    def _show_candidate_window(self):
        """Show the candidate window."""
        if not self.candidates:
            return
        
        self.candidate_showing = True
        
        # Create candidate table
        candidate_table = IBus.CandidateList.new()
        candidate_table.set_orientation(self.config['candidate_window_orientation'])
        candidate_table.set_page_size(self.config['suggestion_page_size'])
        
        for candidate in self.candidates:
            text = IBus.Text.new_from_string(candidate)
            candidate_table.append(text)
        
        if self.candidate_index < len(self.candidates):
            candidate_table.set_cursor(self.candidate_index)
        
        self.update_candidate_window(candidate_table)
    
    def _update_candidate_window(self):
        """Update the candidate window with current selection."""
        if not self.candidates:
            return
        
        self.candidate_showing = True
        
        candidate_table = IBus.CandidateList.new()
        candidate_table.set_orientation(self.config['candidate_window_orientation'])
        candidate_table.set_page_size(self.config['suggestion_page_size'])
        
        for candidate in self.candidates:
            text = IBus.Text.new_from_string(candidate)
            candidate_table.append(text)
        
        if 0 <= self.candidate_index < len(self.candidates):
            candidate_table.set_cursor(self.candidate_index)
        
        self.update_candidate_window(candidate_table)
    
    def _hide_candidate_window(self):
        """Hide the candidate window."""
        self.candidate_showing = False
        self.candidates = []
        self.candidate_index = 0
        self.hide_candidate_window()
    
    def _commit_text(self, text: str):
        """Commit text to the application.
        
        Args:
            text: Text to commit
        """
        if text:
            self.commit_text(IBus.Text.new_from_string(text))
    
    def _commit_preedit(self):
        """Commit the current preedit text."""
        if self.preedit_text:
            self._commit_text(self.preedit_text)
            self.preedit_text = ""
            self.preedit_cursor = 0
    
    def get_name(self) -> str:
        """Get engine name."""
        return self.ENGINE_NAME


class BanglaWriterSetup:
    """Setup utility for BanglaWriter."""
    
    @staticmethod
    def install_files():
        """Install required files for IBUS."""
        # Create directories
        directories = [
            "/usr/share/ibus/component",
            "/usr/share/banglawriter",
            "/usr/share/banglawriter/icons",
            "/usr/share/banglawriter/data",
            "/usr/lib/ibus",
            "/usr/bin",
        ]
        
        for directory in directories:
            os.makedirs(directory, exist_ok=True)
        
        # Write component XML
        component_path = "/usr/share/ibus/component/banglawriter.xml"
        with open(component_path, 'w', encoding='utf-8') as f:
            f.write(COMPONENT_XML)
        
        print(f"Installed component XML to {component_path}")
    
    @staticmethod
    def uninstall_files():
        """Remove installed files."""
        import shutil
        
        files_and_dirs = [
            "/usr/share/ibus/component/banglawriter.xml",
            "/usr/share/banglawriter",
            "/usr/lib/ibus/banglawriter-engine",
            "/usr/bin/banglawriter-setup",
        ]
        
        for path in files_and_dirs:
            if os.path.exists(path):
                if os.path.isdir(path):
                    shutil.rmtree(path)
                else:
                    os.remove(path)
                print(f"Removed {path}")


def main():
    """Main entry point for the IBUS engine."""
    # Setup signal handlers
    def signal_handler(signum, frame):
        print("\nBanglaWriter engine shutting down...")
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Create engine factory
    engine_factory = type(
        "BanglaWriterEngineFactory",
        (IBus.Factory,),
        {
            'create_engine': lambda self, bus: BanglaWriterEngine(bus)
        }
    )
    
    # Get IBUS connection
    try:
        bus = IBus.Bus()
    except Exception as e:
        print(f"Error connecting to IBus: {e}")
        print("Make sure IBus is running.")
        sys.exit(1)
    
    # Create factory
    factory = engine_factory(bus, "/usr/share/ibus/component")
    
    # Connect to bus
    bus.request_name("com.banglawriter", 0)
    
    print("BanglaWriter IBUS engine started.")
    print("Press F12 to toggle between Bangla and ASCII modes.")
    
    # Run main loop
    try:
        GLib.MainLoop().run()
    except KeyboardInterrupt:
        print("\nShutting down BanglaWriter...")
        sys.exit(0)


if __name__ == "__main__":
    main()
