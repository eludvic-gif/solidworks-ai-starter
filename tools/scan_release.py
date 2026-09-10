"""Fail-closed release inventory and heuristic privacy checks; not a secrecy proof.
Default: scan non-local source tree. --tracked: scan EVERY Git-tracked file,
including files force-added despite .gitignore. No upload or file mutation.
"""
import argparse
import re
import subprocess
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ALLOWED_SUFFIXES = {'.md', '.py', '.ps1', '.cs', '.bas', '.json', '.txt', '.docx'}
ALLOWED_ROOT = {'.gitignore', '.gitattributes', 'LICENSE'}
LOCAL_DIRS = {'.git', '.venv', '__pycache__', 'local', 'output'}
PATTERNS = {
    'personal Windows path': re.compile(r'[A-Za-z]:[\\/]+Users[\\/]+[^\s<>"\']+', re.I),
    'API credential': re.compile(r'\b(?:sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})'),
    'private key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'credential assignment': re.compile(r'(?im)^\s*(?:api_key|access_token|password|secret)\s*[=:]\s*["\']?[^\s"\']{8,}'),
}


def scan_text(text, label):
    return [f'{label}: {name}' for name, pattern in PATTERNS.items() if pattern.search(text)]


def docx_texts(path):
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if any('embeddings/' in n or 'vbaProject' in n or 'comments' in n for n in names):
            raise ValueError('DOCX includes embedded content, macros or comments')
        for item in archive.infolist():
            if item.file_size > 8_000_000:
                raise ValueError('Oversized DOCX member')
            if not item.filename.endswith(('.xml', '.rels')):
                if item.filename.startswith('docProps/thumbnail.'):
                    raise ValueError('DOCX contains an unreviewed thumbnail')
                continue
            text = archive.read(item).decode('utf-8')
            node = ET.fromstring(text)
            if any(e.tag.rsplit('}', 1)[-1] in {'ins', 'del', 'altChunk', 'oleObject'} for e in node.iter()):
                raise ValueError('DOCX has revisions or embedded content')
            if item.filename.endswith('.rels'):
                for rel in node:
                    if rel.attrib.get('TargetMode') == 'External':
                        raise ValueError('External DOCX relationship requires manual review')
            yield item.filename, text


def inventory(tracked=False):
    if tracked:
        result = subprocess.run(['git', '-C', str(ROOT), 'ls-files', '-z'], check=True, capture_output=True)
        return [ROOT / name for name in result.stdout.decode('utf-8').split('\0') if name]
    return sorted(p for p in ROOT.rglob('*') if p.is_file()
                  and not LOCAL_DIRS.intersection(p.relative_to(ROOT).parts)
                  and p.name != 'config.local.json' and not p.name.startswith('~$'))


def scan(paths):
    errors = []
    for path in paths:
        name = path.relative_to(ROOT).as_posix()
        errors += scan_text(name, name)
        if path.is_symlink() or path.resolve().is_relative_to(ROOT.resolve()) is False:
            errors.append(f'{name}: symlink/outside root'); continue
        if path.name == 'config.local.json' or LOCAL_DIRS.intersection(path.relative_to(ROOT).parts):
            errors.append(f'{name}: local-only content tracked'); continue
        if path.suffix.lower() not in ALLOWED_SUFFIXES and name not in ALLOWED_ROOT:
            errors.append(f'{name}: unapproved file type'); continue
        if path.stat().st_size > 8_000_000:
            errors.append(f'{name}: oversized file'); continue
        try:
            chunks = docx_texts(path) if path.suffix.lower() == '.docx' else [('', path.read_text(encoding='utf-8-sig'))]
            for member, text in chunks:
                errors += scan_text(text, name + (':' + member if member else ''))
        except (ValueError, UnicodeError, zipfile.BadZipFile, ET.ParseError) as exc:
            errors.append(f'{name}: {exc}')
    return errors


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tracked', action='store_true')
    args = parser.parse_args()
    paths = inventory(args.tracked)
    errors = scan(paths)
    if not paths:
        errors.append('Empty inventory: nothing reviewed')
    for path in paths:
        print(path.relative_to(ROOT).as_posix())
    for error in errors:
        print('FAIL:', error)
    print(f'{"FAIL" if errors else "PASS"}: {len(paths)} files; manual content review still required.')
    raise SystemExit(bool(errors))
