#!/usr/bin/env python3
"""
BanglaWriter Test Suite
Tests the transliteration engine for correctness.
"""

import sys
import os

# Add engine directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'engine'))

from transliteration import TransliterationEngine, transliterate


def test_basic_transliteration():
    """Test basic word transliteration."""
    print("Testing basic transliteration...")
    
    test_cases = [
        ("ami", "আমি"),
        ("vhalo", "ভালো"),
        ("bhalo", "ভালো"),
        ("bangla", "বাংলা"),
        ("desh", "দেশ"),
        ("rastra", "রাষ্ট্র"),
        ("rastro", "রাষ্ট্র"),
        ("muktir", "মুক্তির"),
        ("shadin", "স্বাধীন"),
        ("phon", "ফোন"),
        ("bidesh", "বিদেশ"),
        ("bhasha", "ভাষা"),
        ("chele", "ছেলে"),
        ("meye", "মেয়ে"),
        ("ghor", "ঘর"),
        ("bagh", "বাঘ"),
        ("nasta", "নাস্তা"),
        ("khana", "খানা"),
        ("pani", "পানি"),
        ("path", "পাথ"),
    ]
    
    engine = TransliterationEngine()
    passed = 0
    failed = 0
    
    for roman, expected in test_cases:
        engine.reset()
        for char in roman:
            engine.process_key(char)
        result = engine.get_preedit_text()
        
        if result == expected:
            print(f"  ✓ '{roman}' → '{result}'")
            passed += 1
        else:
            print(f"  ✗ '{roman}' → '{result}' (expected: '{expected}')")
            failed += 1
    
    print(f"\nBasic transliteration: {passed}/{passed+failed} passed")
    return failed == 0


def test_conjuncts():
    """Test conjunct consonant transliteration."""
    print("\nTesting conjuncts...")
    
    test_cases = [
        ("kshatriya", "ক্ষত্রিয়"),
        ("gyn", "গ্যান"),
        ("jn", "জ্ঞান"),
        ("krom", "ক্রম"),
        ("spr", "স্প্র"),
    ]
    
    engine = TransliterationEngine()
    passed = 0
    failed = 0
    
    for roman, expected in test_cases:
        engine.reset()
        for char in roman:
            engine.process_key(char)
        result = engine.get_preedit_text()
        
        # Check if expected string is contained in result
        if expected in result:
            print(f"  ✓ '{roman}' → '{result}'")
            passed += 1
        else:
            print(f"  ✗ '{roman}' → '{result}' (expected to contain: '{expected}')")
            failed += 1
    
    print(f"\nConjuncts: {passed}/{passed+failed} passed")
    return failed == 0


def test_sentences():
    """Test sentence transliteration."""
    print("\nTesting sentences...")
    
    test_cases = [
        ("ami banglay gan gacchi", "আমি বাংলায় গান গাচ্ছি"),
        ("amra bangla bhashai kotha boli", "আমরা বাংলা ভাষায় কথা বলি"),
    ]
    
    engine = TransliterationEngine()
    passed = 0
    failed = 0
    
    for roman, expected in test_cases:
        result = transliterate(roman)
        
        if expected in result:
            print(f"  ✓ '{roman}'")
            print(f"    → '{result}'")
            passed += 1
        else:
            print(f"  ✗ '{roman}'")
            print(f"    → '{result}' (expected to contain: '{expected}')")
            failed += 1
    
    print(f"\nSentences: {passed}/{passed+failed} passed")
    return failed == 0


def test_suggestions():
    """Test word suggestion functionality."""
    print("\nTesting suggestions...")
    
    engine = TransliterationEngine()
    
    # Test common prefix
    engine.reset()
    for char in "bang":
        engine.process_key(char)
    suggestions = engine.get_suggestions()
    
    print(f"  Suggestions for 'bang': {suggestions[:5]}")
    
    if suggestions:
        print(f"  ✓ Got {len(suggestions)} suggestions")
        return True
    else:
        print(f"  ✗ No suggestions returned")
        return False


def test_mode_switching():
    """Test mode switching between Bangla and ASCII."""
    print("\nTesting mode switching...")
    
    from transliteration import Mode
    engine = TransliterationEngine()
    
    # Test Bangla mode
    engine.set_mode(Mode.BANGLA)
    for char in "test":
        engine.process_key(char)
    bangla_result = engine.get_preedit_text()
    print(f"  Bangla mode 'test' → '{bangla_result}'")
    
    # Test ASCII mode
    engine.set_mode(Mode.ASCII)
    for char in "test":
        engine.process_key(char)
    ascii_result = engine.get_preedit_text()
    print(f"  ASCII mode 'test' → '{ascii_result}'")
    
    if bangla_result != ascii_result:
        print(f"  ✓ Mode switching works correctly")
        return True
    else:
        print(f"  ✗ Mode switching not working")
        return False


def main():
    """Run all tests."""
    print("=" * 60)
    print("BanglaWriter Transliteration Engine Test Suite")
    print("=" * 60)
    
    results = []
    results.append(("Basic Transliteration", test_basic_transliteration()))
    results.append(("Conjuncts", test_conjuncts()))
    results.append(("Sentences", test_sentences()))
    results.append(("Suggestions", test_suggestions()))
    results.append(("Mode Switching", test_mode_switching()))
    
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    
    all_passed = True
    for name, passed in results:
        status = "✓ PASSED" if passed else "✗ FAILED"
        print(f"  {status}: {name}")
        if not passed:
            all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("All tests passed! ✓")
        print("=" * 60)
        return 0
    else:
        print("Some tests failed! ✗")
        print("=" * 60)
        return 1


if __name__ == "__main__":
    sys.exit(main())
