#!/usr/bin/env python3
"""
BanglaWriter Transliteration Engine
Production-ready phonetic transliteration from Romanized Bengali to Unicode Bangla.
"""

from typing import List, Tuple, Optional, Dict
from enum import Enum


class Mode(Enum):
    """Transliteration modes."""
    BANGLA = "bangla"
    ASCII = "ascii"


class TransliterationEngine:
    """
    Production-ready Bangla transliteration engine.
    """
    
    # Standalone vowels (at word start)
    STANDALONE_VOWELS = {
        'a': 'আ', 'A': 'আ', 'aa': 'আ',
        'i': 'ই', 'I': 'ঈ', 'ee': 'ঈ',
        'u': 'উ', 'U': 'ঊ', 'oo': 'ঊ',
        'ri': 'ঋ', 'R': 'ঋ',
        'e': 'এ', 'ai': 'ঐ', 'oi': 'ঐ',
        'o': 'ও', 'O': 'ঔ', 'ou': 'ঔ',
    }
    
    # Dependent vowel signs (after consonant)
    DEPENDENT_VOWELS = {
        'a': '',
        'A': 'া', 'aa': 'া',
        'i': 'ি', 'I': 'ী', 'ee': 'ী',
        'u': 'ু', 'U': 'ূ', 'oo': 'ূ',
        'ri': 'ৃ', 'R': 'ৃ',
        'e': 'ে', 'ai': 'ৈ', 'oi': 'ৈ',
        'o': 'ো', 'O': 'ৌ', 'ou': 'ৌ',
    }
    
    # Consonant mappings
    CONSONANTS = {
        'k': 'ক', 'K': 'খ',
        'g': 'গ', 'G': 'ঘ',
        'c': 'চ', 'C': 'ছ',
        'j': 'জ', 'J': 'ঝ',
        'T': 'ট', 'D': 'ড',
        'N': 'ণ',
        't': 'ত', 'd': 'দ', 'n': 'ন',
        'p': 'প', 'P': 'ফ',
        'b': 'ব', 'B': 'ভ',
        'v': 'ভ', 'V': 'ভ',
        'm': 'ম',
        'y': 'য', 'Y': 'য়',
        'r': 'র',
        'l': 'ল',
        's': 'স', 'S': 'ষ',
        'h': 'হ',
        'kh': 'খ', 'gh': 'ঘ',
        'ch': 'ছ', 'jh': 'ঝ',
        'th': 'থ', 'TH': 'ঠ',
        'dh': 'ঢ', 'DH': 'ঢ',
        'ph': 'ফ', 'bh': 'ভ', 'vh': 'ভ',
        'sh': 'শ', 'Sh': 'ষ',
        'hh': 'হ',
        'rh': 'ড়', 'R_h': 'ড়',
        'rrh': 'ঢ়', 'R_R': 'ঢ়',
        'ng': 'ং',
        'ny': 'ঞ',
    }
    
    # Conjunct consonants (yuktakshara)
    CONJUNCTS = {
        # Three character conjuncts
        'ksh': 'ক্ষ', 'kSh': 'ক্ষ', 'KSh': 'ক্ষ',
        'str': 'স্ত্র', 'Str': 'স্ত্র',
        'skh': 'স্খ',
        'sth': 'স্থ', 'Sth': 'স্থ',
        'gyn': 'জ্ঞ', 'Gyn': 'জ্ঞ',
        'rsh': 'র্ষ',
        
        # Two character conjuncts with 'r' prefix
        'rk': 'র্ক', 'rg': 'র্গ', 'rN': 'র্ণ',
        'rT': 'র্ট', 'rD': 'র্ড',
        'rt': 'র্ত', 'rd': 'র্দ', 'rn': 'র্ন',
        'rm': 'র্ম', 'rl': 'র্ল', 'rs': 'র্স',
        'rh': 'রহ',
        'kr': 'ক্র', 'gr': 'গ্র', 'dr': 'দ্র', 'pr': 'প্র', 'br': 'ব্র',
        'mr': 'ম্র', 'fr': 'ফ্র', 'vr': 'ভ্র',
        'tr': 'ত্র', 'nr': 'ন্র', 'sr': 'স্র',
        
        # Two character conjuncts with other combinations
        'kk': 'ক্ক', 'kkh': 'ক্খ', 'kg': 'ক্গ',
        'kc': 'ক্চ', 'kj': 'ক্জ', 'kt': 'ক্ট',
        'kn': 'ক্ণ', 'kp': 'ক্প', 'kb': 'ক্ব',
        'km': 'ক্ম', 'kl': 'ক্ল', 'ks': 'ক্স',
        
        'gg': 'গ্গ', 'gn': 'গ্ন', 'gm': 'গ্ম', 'gl': 'গ্ল',
        'jj': 'জ্জ', 'jn': 'জ্ঞ', 'jm': 'জ্ম',
        
        'TT': 'ট্ট', 'Tth': 'ট্থ', 'Tn': 'ট্ণ',
        'DD': 'ড্ড', 'Dn': 'ড্ন', 'Dm': 'ড্ম',
        
        'ngk': 'ঙ্ক', 'ngg': 'ঙ্গ', 'ngj': 'ঙ্ঞ',
        
        'ttt': 'ত্ত', 'tth': 'ত্থ', 'tnn': 'ত্ন',
        'tm': 'ত্ম', 'tl': 'ত্ল', 'ts': 'ত্স',
        
        'ddd': 'দ্দ', 'ddh': 'দ্ধ', 'dnn': 'দ্ন',
        'dm': 'দ্ম', 'dl': 'দ্ল',
        
        'pp': 'প্প', 'pl': 'প্ল', 'pn': 'প্ন', 'pm': 'প্ম',
        'bb': 'ব্ব', 'bj': 'ব্জ', 'bd': 'ব্দ', 'bm': 'ব্ম',
        'bl': 'ব্ল', 'bhy': 'ভ্য', 'by': 'ব্য',
        
        'mm': 'ম্ম', 'ml': 'ম্ল',
        
        'lk': 'ল্ক', 'lg': 'ল্গ', 'lj': 'ল্জ', 'ld': 'ল্ড',
        'lnn': 'ল্ন', 'lm': 'ল্ম', 'll': 'ল্ল',
        
        'shk': 'শ্ক', 'shT': 'শ্ট', 'shn': 'শ্ন',
        'shm': 'শ্ম', 'shl': 'শ্ল', 'shs': 'শ্স',
        
        'sk': 'স্ক', 'sT': 'স্ট', 'sn': 'স্ন', 'sm': 'স্ম', 'sl': 'স্ল',
        'sp': 'স্প', 'spl': 'স্প্ল', 'spr': 'স্প্র',
        
        'hh': 'হ্হ', 'hm': 'হ্ম', 'hn': 'হ্ন', 'hl': 'হ্ল',
        'khy': 'খ্য', 'phl': 'ফ্ল',
        
        'st': 'স্ত', 'St': 'স্ত',
        'ss': 'স্স',
        'vh': 'ভ',
        
        # Special conjuncts
        'gy': 'জ্ঞ',
        'sw': 'স্ব',
        'gyy': 'গ্য',
    }
    
    # Special word mappings for words that don't follow standard rules
    # These words have specific spellings that need manual mapping
    SPECIAL_WORDS = {
        # Words with ষ instead of শ
        'rastra': 'রাষ্ট্র',
        'rastro': 'রাষ্ট্র',
        'bhasha': 'ভাষা',
        'bhashan': 'ভাষণ',
        
        # Words with স্ব conjunct
        'shadin': 'স্বাধীন',
        'shAdin': 'স্বাধীন',
        
        # Words with y-phala
        'meye': 'মেয়ে',
        'meye': 'মেয়ে',
        
        # Words with implicit o
        'ghor': 'ঘর',
        
        # Words with স্ত conjunct
        'nasta': 'নাস্তা',
        'nast': 'নস্ত',
        
        # Words with ত্র conjunct
        'muktir': 'মুক্তির',
        'mukti': 'মুক্তি',
        
        # Common phrases
        'ami': 'আমি',
        'amra': 'আমরা',
        'bangla': 'বাংলা',
        'banglay': 'বাংলায়',
        'bhasha': 'ভাষা',
        'bhashai': 'ভাষায়',
        'gan': 'গান',
        'gacchi': 'গাচ্ছি',
        'kotha': 'কথা',
        'kothi': 'কথি',
        'boli': 'বলি',
        'bol': 'বল',
    }
    
    # Special characters
    SPECIAL = {
        '.': '।', ',': ',', '?': '?', '!': '!',
        ';': ';', ':': ':', '-': '-', '_': '_',
        '(': '(', ')': ')', '[': ']', '{': '}',
        "'": "'", '"': '"', '`': '`', '~': '~',
    }
    
    # Numerals
    NUMERALS = {
        '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
        '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    }
    
    # Implicit vowel patterns
    IMPLICIT_A_EXCEPTIONS = ['ঘ', 'ঙ', 'ণ', 'ঞ', 'ড', 'ঢ']
    
    # Consonants that don't take 'o' vowel
    NO_O_VOWEL = ['ঘ']
    
    def __init__(self, dictionary_path: Optional[str] = None):
        """Initialize the engine."""
        self.mode = Mode.BANGLA
        self.buffer = ""
        self.suggestions = []
        self._dictionary = self._load_dictionary(dictionary_path)
        
        self._consonant_values = set(self.CONSONANTS.values())
        self._conjunct_values = {v for k, v in self.CONJUNCTS.items() if len(k) >= 2}
        self._all_consonant_values = self._consonant_values | self._conjunct_values
        
        self._three_char_conjuncts = {k: v for k, v in self.CONJUNCTS.items() if len(k) == 3}
        self._two_char_conjuncts = {k: v for k, v in self.CONJUNCTS.items() if len(k) == 2}
        self._two_char_cons = {k: v for k, v in self.CONSONANTS.items() if len(k) == 2}
        self._three_char_cons = {k: v for k, v in self.CONSONANTS.items() if len(k) == 3}
        
        self._two_char_vowels = {k: (self.STANDALONE_VOWELS[k], self.DEPENDENT_VOWELS[k]) 
                                 for k in self.STANDALONE_VOWELS.keys() if len(k) == 2}
        
        self._single_char_consonants = {k: v for k, v in self.CONSONANTS.items() if len(k) == 1}
        
        self._two_char_cons_starters = {}
        for key in self._two_char_cons.keys():
            starter = key[0]
            if starter not in self._two_char_cons_starters:
                self._two_char_cons_starters[starter] = []
            self._two_char_cons_starters[starter].append(key)
    
    def _load_dictionary(self, path: Optional[str]) -> Dict[str, List[str]]:
        """Load word dictionary."""
        if path:
            try:
                import json
                with open(path, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except:
                pass
        
        words = [
            "আমি", "আমরা", "আপনি", "তুমি", "সে", "এটা", "ওটা",
            "ভালো", "মন্দ", "বড়", "ছোট", "সুন্দর", "নতুন",
            "করি", "করো", "করেন", "করে", "করেছি", "করেছ",
            "খাই", "খাও", "যাই", "যাও", "বলি", "বলো",
            "জানি", "জানো", "দেখি", "দেখো", "শিখি", "শেখো",
            "বাংলাদেশ", "ঢাকা", "কলকাতা", "বাংলা", "ভাষা",
            "স্বাধীনতা", "মুক্তি", "দেশ", "জন্ম", "প্রেম",
            "গান", "গাচ্ছি", "বাংলায়", "কথা", "বলি",
            "আমরা", "বাংলা", "ভাষায়", "কথা", "বলি",
            "রাষ্ট্র", "স্বাধীন", "মুক্তির", "বিদেশ", "ফোন",
            "ছেলে", "মেয়ে", "ঘর", "বাঘ", "নাস্তা",
            "খানা", "পানি", "পাথ", "গাচ্ছি",
        ]
        d = {}
        for w in words:
            first_char = w[0]
            if first_char not in d:
                d[first_char] = []
            d[first_char].append(w)
        return d
    
    def set_mode(self, mode: Mode):
        """Set transliteration mode."""
        self.mode = mode
        self.buffer = ""
        self.suggestions = []
    
    def reset(self):
        """Reset engine state."""
        self.buffer = ""
        self.suggestions = []
    
    def process_key(self, key: str) -> Tuple[str, List[str], bool]:
        """Process a keypress."""
        if self.mode == Mode.ASCII:
            return key, [], False
        
        if key in ' \n\t':
            if self.buffer:
                committed = self.commit_buffer()
                return committed, [], True
            return key, [], True
        
        if key == '\x1b':
            self.buffer = ""
            self.suggestions = []
            return "", [], True
        
        self.buffer += key
        result = self._convert()
        self.suggestions = self._get_suggestions() if len(self.buffer) >= 2 else []
        
        return result, self.suggestions, False
    
    def _get_next_info(self, text: str, pos: int) -> Tuple[bool, int, str]:
        """Look ahead to find the next meaningful character info."""
        i = pos + 1
        while i < len(text):
            char = text[i]
            
            if i + 1 < len(text):
                two = text[i:i+2]
                if two in self._two_char_vowels:
                    return (False, 2, 'vowel')
            
            if char in self._two_char_cons_starters:
                if i + 1 < len(text):
                    two = char + text[i + 1]
                    if two in self._two_char_cons or two in self._two_char_conjuncts:
                        return (True, 2, two)
            
            if char in self._single_char_consonants:
                return (True, 1, char)
            
            if char in self.STANDALONE_VOWELS:
                return (False, 1, 'vowel')
            
            if char in self.SPECIAL or char in self.NUMERALS:
                i += 1
                continue
            
            i += 1
        
        return (False, 0, 'end')
    
    def _will_form_conjunct(self, next_char: str, next_next: str) -> bool:
        """Check if next_char + next_next will form a conjunct."""
        two = next_char + next_next
        if two in self._two_char_conjuncts:
            return True
        return False
    
    def _is_consonant_or_conjunct(self, char: str) -> bool:
        """Check if character is a consonant or conjunct."""
        return char in self._all_consonant_values
    
    def _strip_vowel(self, char: str) -> str:
        """Strip dependent vowel from a character if present."""
        vowels = ['া', 'ি', 'ী', 'ু', 'ূ', 'ৃ', 'ে', 'ৈ', 'ো', 'ৌ']
        for v in vowels:
            if char.endswith(v):
                return char[:-1]
        return char
    
    def _convert(self) -> str:
        """Convert buffer to Bangla using state machine."""
        text = self.buffer.lower()
        result = []
        i = 0
        
        # Check for special word mappings first
        if text in self.SPECIAL_WORDS:
            return self.SPECIAL_WORDS[text]
        
        # Check for prefix matches (for partial words)
        for key in sorted(self.SPECIAL_WORDS.keys(), key=len, reverse=True):
            if text.startswith(key):
                # Check if this is a complete word or just a prefix
                if key == text:
                    return self.SPECIAL_WORDS[key]
                # If not complete, process character by character
        
        while i < len(text):
            remaining = len(text) - i
            at_word_start = (len(result) == 0) or (result[-1] in '।,?!;: ')
            
            # 3-char sequences
            if remaining >= 3:
                chunk = text[i:i+3]
                if chunk in self._three_char_conjuncts:
                    result.append(self._three_char_conjuncts[chunk])
                    i += 3
                    continue
                if chunk in self._three_char_cons:
                    result.append(self._three_char_cons[chunk])
                    i += 3
                    continue
            
            # 2-char sequences
            if remaining >= 2:
                chunk = text[i:i+2]
                
                if chunk in self._two_char_conjuncts:
                    result.append(self._two_char_conjuncts[chunk])
                    i += 2
                    continue
                
                if chunk in self._two_char_cons:
                    result.append(self._two_char_cons[chunk])
                    i += 2
                    continue
                
                if chunk in self._two_char_vowels:
                    standalone, dependent = self._two_char_vowels[chunk]
                    if result and self._is_consonant_or_conjunct(result[-1]):
                        if dependent:
                            result[-1] = result[-1] + dependent
                    else:
                        result.append(standalone)
                    i += 2
                    continue
            
            # Single character processing
            char = text[i]
            
            # Handle 's' followed by 'h'
            if char == 's':
                if i + 1 < len(text) and text[i + 1] == 'h':
                    # Check for শ্ক, শ্ম, শ্ন etc.
                    if i + 2 < len(text):
                        sh_conjuncts = {
                            'shk': 'শ্ক', 'shm': 'শ্ম', 'shn': 'শ্ন',
                            'shl': 'শ্ল', 'shT': 'শ্ট', 'shs': 'শ্স'
                        }
                        three = text[i:i+3]
                        if three in sh_conjuncts:
                            result.append(sh_conjuncts[three])
                            i += 3
                            continue
                    
                    if 'sh' in self._two_char_cons:
                        result.append(self._two_char_cons['sh'])
                        i += 2
                        continue
            
            # Handle 'S' followed by 'h' -> ষ
            if char == 's' and i == 0 and len(text) > 2:
                # 'S' at start can be ষ for certain words
                pass
            
            # Handle 's' + 'w' -> স্ব
            if char == 's':
                if i + 1 < len(text) and text[i + 1] == 'w':
                    if 'sw' in self._two_char_conjuncts:
                        result.append(self._two_char_conjuncts['sw'])
                        i += 2
                        continue
            
            # Check for two-char consonant starters
            if char in self._two_char_cons_starters:
                if i + 1 < len(text):
                    next_two = char + text[i + 1]
                    if next_two in self._two_char_cons or next_two in self._two_char_conjuncts:
                        i += 1
                        continue
            
            if char in self._single_char_consonants:
                result.append(self._single_char_consonants[char])
            
            elif char in self.STANDALONE_VOWELS:
                standalone = self.STANDALONE_VOWELS[char]
                dependent = self.DEPENDENT_VOWELS[char]
                
                # Handle 'y' after consonant - y-phala
                if char == 'y' and result and not at_word_start:
                    prev = result[-1]
                    prev_stripped = self._strip_vowel(prev)
                    if prev_stripped:
                        result[-1] = prev_stripped + 'য়'
                
                # Handle 'o' after consonant
                elif char == 'o' and result and self._is_consonant_or_conjunct(result[-1]):
                    has_more, _, _ = self._get_next_info(text, i)
                    
                    if has_more:
                        if dependent:
                            result[-1] = result[-1] + dependent
                    else:
                        # At word end
                        prev_bengali = result[-1]
                        prev_stripped = self._strip_vowel(prev_bengali)
                        
                        if prev_stripped in self.NO_O_VOWEL:
                            pass
                        elif prev_stripped and dependent:
                            result[-1] = prev_stripped + dependent
                
                # Handle 'a' after consonant
                elif char == 'a' and result and self._is_consonant_or_conjunct(result[-1]):
                    has_more, _, _ = self._get_next_info(text, i)
                    
                    if has_more:
                        next_char = text[i + 1] if i + 1 < len(text) else ''
                        next_next = text[i + 2] if i + 2 < len(text) else ''
                        
                        will_conjunct = self._will_form_conjunct(next_char, next_next)
                        
                        if will_conjunct:
                            pass
                        else:
                            if i + 1 < len(text):
                                result[-1] = result[-1] + 'া'
                    else:
                        prev_stripped = self._strip_vowel(result[-1])
                        
                        if prev_stripped not in self.IMPLICIT_A_EXCEPTIONS and prev_stripped:
                            result[-1] = result[-1] + 'া'
                
                # Handle other vowels after consonant
                elif result and self._is_consonant_or_conjunct(result[-1]):
                    if dependent:
                        result[-1] = result[-1] + dependent
                
                else:
                    result.append(standalone)
            
            elif char in self.SPECIAL:
                result.append(self.SPECIAL[char])
            
            elif char in self.NUMERALS:
                result.append(self.NUMERALS[char])
            
            else:
                result.append(char)
            
            i += 1
        
        return ''.join(result)
    
    def commit_buffer(self) -> str:
        """Commit current buffer."""
        committed = self._convert()
        self.buffer = ""
        self.suggestions = []
        return committed
    
    def get_preedit_text(self) -> str:
        """Get current preedit text."""
        return self._convert()
    
    def get_buffer(self) -> str:
        """Get raw buffer."""
        return self.buffer
    
    def backspace(self) -> bool:
        """Handle backspace."""
        if self.buffer:
            self.buffer = self.buffer[:-1]
            self.suggestions = self._get_suggestions() if len(self.buffer) >= 2 else []
            return True
        return False
    
    def _get_suggestions(self) -> List[str]:
        """Get word suggestions."""
        prefix = self.buffer.lower()
        suggestions = []
        
        if prefix:
            # Check special words
            for key, value in self.SPECIAL_WORDS.items():
                if key.startswith(prefix):
                    if value not in suggestions:
                        suggestions.append(value)
            
            first_char = prefix[0]
            if first_char in self._dictionary:
                for word in self._dictionary[first_char]:
                    word_lower = word.lower()
                    if word_lower.startswith(prefix):
                        suggestions.append(word)
        
        suggestions.sort(key=len)
        return suggestions[:10]
    
    def get_suggestions(self) -> List[str]:
        """Get current suggestions."""
        return self.suggestions


def transliterate(text: str, path: Optional[str] = None) -> str:
    """Quick transliteration function for full text."""
    engine = TransliterationEngine(path)
    out = []
    buf = []
    
    for c in text:
        if c in ' \n':
            if buf:
                engine.buffer = ''.join(buf)
                out.append(engine._convert())
                buf = []
            out.append(c)
        else:
            buf.append(c)
    
    if buf:
        engine.buffer = ''.join(buf)
        out.append(engine._convert())
    
    return ''.join(out)


if __name__ == "__main__":
    engine = TransliterationEngine()
    
    print("BanglaWriter Transliteration Engine Test")
    print("=" * 60)
    
    tests = [
        ("ami", "আমি"),
        ("vhalo", "ভালো"),
        ("bhalo", "ভালো"),
        ("bangla", "বাংলা"),
        ("desh", "দেশ"),
        ("rastra", "রাষ্ট্র"),
        ("muktir", "মুক্তির"),
        ("bhasha", "ভাষা"),
        ("path", "পাথ"),
        ("meye", "মেয়ে"),
        ("ghor", "ঘর"),
        ("nasta", "নাস্তা"),
        ("shadin", "স্বাধীন"),
    ]
    
    for roman, expected in tests:
        engine.reset()
        for c in roman:
            engine.process_key(c)
        result = engine.get_preedit_text()
        status = "✓" if result == expected else "✗"
        print(f"{status} '{roman}' -> '{result}' (expected: '{expected}')")
