"""Offline release checks; no VBA execution or SOLIDWORKS automation."""
import hashlib
import re
import sys
from urllib.parse import unquote
import unittest
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import build_guide
import scan_release


class ReleaseTests(unittest.TestCase):
    def test_inventory_privacy(self):
        self.assertEqual(scan_release.scan(scan_release.inventory()), [])

    def test_scanner_positive_and_negative(self):
        self.assertTrue(scan_release.scan_text('C:' + chr(92) + 'Users' + chr(92) + 'Synthetic' + chr(92) + 'demo', 'fixture'))
        self.assertTrue(scan_release.scan_text('gh' + 'p_' + 'A' * 30, 'fixture'))
        self.assertFalse(scan_release.scan_text('H=30 mm, volume=608.683576633022 mm3', 'fixture'))

    def test_relative_markdown_links(self):
        for path in ROOT.rglob('*.md'):
            if '.git' in path.parts:
                continue
            text = re.sub(r'```.*?```', '', path.read_text(encoding='utf-8'), flags=re.S)
            for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)', text):
                if target.startswith(('https://', 'http://', '#', 'mailto:')):
                    continue
                target, _, fragment = target.partition('#')
                destination = path.parent / unquote(target)
                self.assertTrue(destination.exists(), f'{path.name}: {target}')
                if fragment and destination.suffix == '.md':
                    headings = re.findall(r'^#+\s+(.+)$', destination.read_text(encoding='utf-8'), re.M)
                    slugs = {re.sub(r'[^\w\- ]', '', h.lower()).replace(' ', '-') for h in headings}
                    self.assertIn(unquote(fragment), slugs, f'{path.name}: invalid anchor {fragment}')

    def test_docx_matches_source_in_order(self):
        source = build_guide.SOURCE.read_text(encoding='utf-8')
        namespace = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
        with zipfile.ZipFile(build_guide.OUTPUT) as archive:
            root = ET.fromstring(archive.read('word/document.xml'))
            actual = []
            for paragraph in root.findall('.//w:body//w:p', namespace):
                content = []
                for item in paragraph.iter():
                    if item.tag.endswith('}t'):
                        content.append(item.text or '')
                    elif item.tag.endswith('}br'):
                        content.append('\n')
                    elif item.tag.endswith('}tab'):
                        content.append('\t')
                actual.append(''.join(content))
            expected = build_guide.expected_text(source)
            self.assertEqual(actual, expected)
            core = archive.read('docProps/core.xml').decode('utf-8')
            self.assertIn(hashlib.sha256(build_guide.SOURCE.read_bytes()).hexdigest(), core)
            self.assertIn('solidworks-ai-starter contributors', core)
        self.assertGreater(len(expected), 100)

    def test_word_has_no_embeds_or_external_relationships(self):
        self.assertGreater(len(list(scan_release.docx_texts(build_guide.OUTPUT))), 3)

    def test_parser_preserves_code_and_tables(self):
        source = '# Heading\n\n```ps1\n$var = 1\nprint\n```\n|A|B|\n|---|---|\n|1|2|\n'
        self.assertEqual(build_guide.expected_text(source), ['Heading', '$var = 1\nprint', 'A', 'B', '1', '2'])
        self.assertEqual(build_guide.expected_text('A wrapped\nparagraph.\n\n- A list\n  continuation.'),
                         ['A wrapped paragraph.', 'A list continuation.'])
        self.assertEqual(build_guide.expected_text('  ```\nline\n  ```'), ['line'])
        with self.assertRaises(ValueError):
            list(build_guide.blocks('```\nmissing close'))

    def test_connection_static_safety(self):
        text = (ROOT / 'tools/connect-solidworks.ps1').read_text(encoding='utf-8')
        self.assertIn('[ValidateRange(1,20)]', text)
        self.assertIn('WaitForExit(12000)', text)
        self.assertIn('Get-ConnectionDecision', text)
        self.assertIn('$client.Kill()', text)
        for forbidden in ['Stop-Process', 'ExitApp(', 'CloseDoc(', 'ExecutionPolicy Bypass']:
            self.assertNotIn(forbidden, text)
        probe = (ROOT / 'tools/SwConnection.cs').read_text(encoding='utf-8')
        for forbidden in ['NewDocument(', 'CloseDoc(', 'ExitApp(', 'SaveAs(']:
            self.assertNotIn(forbidden, probe)


if __name__ == '__main__':
    unittest.main()
