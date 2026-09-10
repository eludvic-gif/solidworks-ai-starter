"""Static VBA guard regression checks. These do not compile or execute VBA."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class MacroGuardTests(unittest.TestCase):
    def test_sources_are_text_not_binaries(self):
        for name in ('ConeValidation.bas', 'ConeBore9.bas'):
            text = (ROOT / 'examples' / name).read_text(encoding='utf-8-sig')
            self.assertIn('Option Explicit', text)
            self.assertIn('InputBox', text)
            self.assertIn('NewDocument', text)
            self.assertIn('RequireActive', text)
            self.assertIn('GetSaveFlag()', text)
            self.assertIn('Test', text)
            self.assertNotIn('C:\\ProgramData', text)
            for forbidden in ('.CloseDoc', '.ExitApp', '.SaveAs', '.Save3', 'CreateObject('):
                self.assertNotIn(forbidden, text)
            self.assertNotRegex(text, r'Set\s+doc\s*=\s*app\.ActiveDoc')

    def test_cut_guard_precedes_document_creation(self):
        text = (ROOT / 'examples/ConeBore9.bas').read_text(encoding='utf-8-sig')
        self.assertLess(text.index('If wall <= WALL_TOL_MM'), text.index('app.NewDocument'))
        self.assertIn('Private Const BORE_DEPTH_MM As Double = 9#', text)
        self.assertIn('Private Const BORE_DEPTH_MM As Double = 15#',
                      (ROOT / 'examples/ConeValidation.bas').read_text(encoding='utf-8-sig'))

    def test_revolve_signatures_have_twenty_arguments(self):
        for path in (ROOT / 'examples').glob('*.bas'):
            text = path.read_text(encoding='utf-8-sig').replace('_\n', '')
            # Match the complete multiline statement, not the inner Atn(1#).
            calls = re.findall(r'Set \w+ = doc\.FeatureManager\.FeatureRevolve2\((.*?)\)\s*\n', text, re.S)
            self.assertEqual(len(calls), 1, path.name)
            self.assertEqual(len(calls[0].split(',')), 20, path.name)


if __name__ == '__main__':
    unittest.main()
