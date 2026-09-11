"""Documentation contract checks only; these do not execute or validate CAD."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class DrawingDocumentationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.module = (ROOT / 'docs/DESENHOS-2D.md').read_text(encoding='utf-8')
        cls.guide = (ROOT / 'docs/GUIA-COMPLETO.md').read_text(encoding='utf-8')

    def test_native_workflow_is_documented(self):
        for contract in ('CreateDrawViewFromModelView3', 'SelectEntity',
                         'CreateSectionViewAt5', 'CreateDetailViewAt4',
                         'SetSheets', 'IsDangling', 'GetOverride'):
            with self.subTest(contract=contract):
                self.assertIn(contract, self.module)
                self.assertIn(contract, self.guide)

    def test_limits_are_not_hidden(self):
        for text in ('não são uma macro completa', 'portabilidade não validada',
                     '3D Interconnect', 'não foi validado ponta a ponta',
                     'demonstração recriada', 'Lixeira'):
            with self.subTest(text=text):
                self.assertIn(text.casefold(), self.module.casefold())

    def test_word_source_contains_standalone_steps(self):
        for step in ('Etapa A', 'Etapa B', 'Etapa C', 'Etapa D', 'Etapa E', 'Etapa F'):
            self.assertIn(step, self.guide)
        self.assertIn('## 24.', self.guide)

    def test_public_access_and_both_accounts(self):
        readme = (ROOT / 'README.md').read_text(encoding='utf-8')
        for account in ('eludvic-gif', 'ericludvic-79'):
            self.assertIn(f'https://github.com/{account}/solidworks-ai-starter', readme)
        self.assertNotIn('Este é um repositório privado', readme)
        self.assertNotIn('O repo é privado:', self.guide)

    def test_prompt_requires_preservation_and_validation(self):
        prompt = (ROOT / 'docs/prompts/05-desenho-2d.md').read_text(encoding='utf-8')
        for text in ('SLDDRW', 'BREP', 'Interconnect', 'dangling', 'override',
                     'NÃO LIBERADO', 'temporários', 'originais'):
            self.assertIn(text, prompt)


if __name__ == '__main__':
    unittest.main()
