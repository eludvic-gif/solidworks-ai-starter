"""Generate the standalone Word guide from GUIA-COMPLETO.md only.
Requires python-docx. Refuses overwrites unless --replace is explicit.
Supported Markdown: headings, paragraphs, fenced code, lists, pipe tables,
inline bold/italic/code and links (printed as text plus target, usable offline).
"""
import argparse
import hashlib
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs' / 'GUIA-COMPLETO.md'
OUTPUT = SOURCE.with_suffix('.docx')


def plain(text):
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'\1 (\2)', text)
    return text.replace('**', '').replace('`', '').replace('__', '')


def blocks(text):
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or re.fullmatch(r'\s*---+\s*', line):
            i += 1; continue
        if line.lstrip().startswith('```'):
            content = []
            i += 1
            while i < len(lines) and not lines[i].lstrip().startswith('```'):
                content.append(lines[i]); i += 1
            if i == len(lines):
                raise ValueError('Unclosed code fence')
            yield 'code', '\n'.join(content)
            i += 1; continue
        if line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].startswith('|'):
                row = [plain(c.strip()) for c in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-+:?', c) for c in row):
                    rows.append(row)
                i += 1
            if len({len(row) for row in rows}) > 1:
                raise ValueError('Inconsistent table column count')
            yield 'table', rows
            continue
        # Markdown source wraps prose for readability; retain one Word paragraph
        # per logical paragraph/list item, not one paragraph per source line.
        if not line.startswith('#'):
            while i + 1 < len(lines):
                next_line = lines[i + 1]
                if not next_line.strip() or re.match(r'^\s*(?:#|```|\||[-*]\s|\d+\.\s|>\s)', next_line):
                    break
                line += ' ' + next_line.strip()
                i += 1
        heading = re.match(r'^(#{1,6})\s+(.+)', line)
        if heading:
            yield 'heading' + str(len(heading[1])), plain(heading[2])
        elif re.match(r'^\s*[-*]\s+', line):
            yield 'bullet', plain(re.sub(r'^\s*[-*]\s+', '', line))
        elif re.match(r'^\s*\d+\.\s+', line):
            # Keep explicit numbering: separate numbered procedures restart correctly.
            yield 'number', plain(line.strip())
        elif line.startswith('> '):
            yield 'quote', plain(line[2:])
        else:
            yield 'paragraph', plain(line)
        i += 1


def expected_text(text):
    result = []
    for kind, value in blocks(text):
        if kind == 'table':
            result.extend(cell for row in value for cell in row)
        else:
            result.append(value)
    return result


def build(replace=False):
    from docx import Document
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.oxml import OxmlElement
    from docx.shared import Cm, Pt, RGBColor
    if OUTPUT.exists() and not replace:
        raise FileExistsError('Guide already exists. Review it before using --replace.')
    source = SOURCE.read_text(encoding='utf-8')
    document = Document()
    # Remove python-docx template thumbnail, not authored by this project.
    for rid, rel in list(document.part.package.rels.items()):
        if rel.reltype.endswith('/metadata/thumbnail'):
            document.part.package.rels.pop(rid)
    section = document.sections[0]
    section.page_width, section.page_height = Cm(21), Cm(29.7)
    section.top_margin = section.bottom_margin = Cm(2)
    section.left_margin = section.right_margin = Cm(2)
    normal = document.styles['Normal']
    normal.font.name, normal.font.size = 'Calibri', Pt(10.5)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.12
    for level in range(1, 5):
        style = document.styles[f'Heading {level}']
        style.font.name = 'Calibri'
        style.font.color.rgb = RGBColor.from_string('194D66')
        style.paragraph_format.keep_with_next = True
    properties = document.core_properties
    properties.title = 'IA + SOLIDWORKS — Guia replicável'
    properties.subject = 'Configuração, demonstração, validação e instruções para agentes'
    properties.author = 'solidworks-ai-starter contributors'
    properties.last_modified_by = 'solidworks-ai-starter contributors'
    properties.keywords = 'CAD, IA, SOLIDWORKS, validação'
    properties.comments = 'Source SHA256: ' + hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    properties.created = datetime(2026, 9, 10, tzinfo=timezone.utc)
    properties.modified = datetime(2026, 9, 12, tzinfo=timezone.utc)
    properties.revision = 3
    header = section.header.paragraphs[0]
    header.text = 'SOLIDWORKS AI STARTER  /  GUIA DE REPLICAÇÃO'
    header.runs[0].font.size = Pt(8)
    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    footer.add_run('Guia técnico • validação local obrigatória  |  ')
    field = OxmlElement('w:fldSimple')
    from docx.oxml.ns import qn
    field.set(qn('w:instr'), 'PAGE')
    footer._p.append(field)
    for kind, value in blocks(source):
        if kind.startswith('heading'):
            document.add_heading(value, level=min(4, int(kind[-1])))
        elif kind == 'table':
            table = document.add_table(rows=0, cols=len(value[0]))
            table.style = 'Light Shading Accent 1'
            for index, cells in enumerate(value):
                row = table.add_row()
                for cell, text in zip(row.cells, cells):
                    cell.text = text
                if index == 0:
                    repeat = OxmlElement('w:tblHeader')
                    row._tr.get_or_add_trPr().append(repeat)
        else:
            style = {'bullet': 'List Bullet', 'quote': 'Intense Quote'}.get(kind)
            paragraph = document.add_paragraph(value, style=style)
            if kind == 'code':
                paragraph.paragraph_format.space_before = Pt(4)
                paragraph.paragraph_format.space_after = Pt(9)
                for run in paragraph.runs:
                    run.font.name, run.font.size = 'Consolas', Pt(8)
            elif kind == 'number':
                paragraph.paragraph_format.left_indent = Cm(0.3)
    document.save(OUTPUT)
    print('Generated:', OUTPUT.name)
    print('Source SHA256:', hashlib.sha256(SOURCE.read_bytes()).hexdigest())
    print('Content blocks:', len(list(blocks(source))))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--replace', action='store_true')
    build(parser.parse_args().replace)
