"""Public module tests: synthetic input, source metadata and no standard copies."""
import json
import sys
import tempfile
import unittest
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import review_drawing


class NormativeReleaseTests(unittest.TestCase):
    def test_registry_sources_and_no_local_evidence(self):
        text = (ROOT / 'standards/registry.json').read_text(encoding='utf-8')
        data = json.loads(text)
        self.assertEqual(len(data['entries']), 20)
        self.assertEqual(len(data['supersessions']), 8)
        for entry in data['entries']:
            self.assertEqual(urlparse(entry['url']).hostname, 'knowledge.bsigroup.com')
            self.assertIs(entry['full_text_read'], False)
        for forbidden in ('local_file', 'sha256', 'references\\', 'pdf-preview'):
            self.assertNotIn(forbidden, text)
        self.assertEqual({p.name for p in (ROOT / 'standards').iterdir()}, {'registry.json'})

    def test_example_clearly_synthetic(self):
        data = review_drawing.load_json(ROOT / 'examples/drawing-review.synthetic.json')
        self.assertIs(data['synthetic_example'], True)
        self.assertIn('invented hash', data['notice'])

    def test_cli_never_releases(self):
        with tempfile.TemporaryDirectory() as td:
            output = Path(td) / 'review.json'
            code = review_drawing.main([str(ROOT / 'examples/drawing-review.synthetic.json'), str(output)])
            data = json.loads(output.read_text(encoding='utf-8'))
            self.assertEqual(code, 0)
            self.assertEqual(data['release'], 'NOT_AUTHORIZED')
            self.assertIsNone(data['iso_compliant'])

    def test_cli_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as td:
            output = Path(td) / 'review.json'
            output.write_text('preserve', encoding='utf-8')
            with self.assertRaises(FileExistsError):
                review_drawing.main([str(ROOT / 'examples/drawing-review.synthetic.json'), str(output)])
            self.assertEqual(output.read_text(), 'preserve')

    def test_cli_invalid_inputs_fail_closed(self):
        for text in ('[]', '{"sheets":null}', '{"value":NaN}', '{"a":1,"a":2}',
                     '{"sheets":[{"views":[{"id":"v","type":"section","parent_view":[]}]}]}'):
            with self.subTest(text=text), tempfile.TemporaryDirectory() as td:
                source = Path(td) / 'source.json'
                output = Path(td) / 'result.json'
                source.write_text(text, encoding='utf-8')
                self.assertEqual(review_drawing.main([str(source), str(output)]), 2)
                self.assertEqual(json.loads(output.read_text())['release'], 'BLOCKED')
                self.assertEqual(source.read_text(), text)

    def test_cli_large_input_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            source = Path(td) / 'large.json'
            source.write_text(' ' * 2_000_001)
            with self.assertRaises(ValueError):
                review_drawing.load_json(source)

    def test_documentation_discloses_limits(self):
        text = (ROOT / 'docs/NORMAS-2D.md').read_text(encoding='utf-8')
        for phrase in ('Nenhuma norma foi lida integralmente', 'NOT_AUTHORIZED',
                       'nem mede geometria', 'não substitui a ISO 2768-1'):
            self.assertIn(phrase, text)
        agents = (ROOT / 'AGENTS.md').read_text(encoding='utf-8')
        self.assertIn('docs/NORMAS-2D.md', agents)
        self.assertIn('normas', (ROOT / 'THIRD_PARTY_NOTICES.md').read_text(encoding='utf-8'))


if __name__ == '__main__':
    unittest.main()
