#!/usr/bin/env python3
"""Package the assessor-facing folder, excluding local tools, Git and caches."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import json

root = Path(__file__).resolve().parents[1]
output = root.parent / 'BreathingCity_Final_2026-10-01.zip'
exclude = {'.git', '__pycache__', 'build', '.DS_Store', 'screenshots'}
# Preserve the complete historical baseline locally, but do not submit its
# unfinished reflection/source/feedback templates. See archive/EXPORT-NOTES.md.
excluded_working_documents = {
    'docs/reflection-draft.md',
    'docs/反思工作稿.md',
    'docs/course-sources-needed.md',
    'docs/peer-feedback-form.md',
    'archive/baseline-2026-10-01/docs/reflection-draft.md',
    'archive/baseline-2026-10-01/docs/course-sources-needed.md',
    'archive/baseline-2026-10-01/docs/peer-feedback-form.md',
}
files = [p for p in root.rglob('*') if p.is_file()
         and not any(part in exclude for part in p.relative_to(root).parts)
         and p.suffix not in {'.class', '.pyc'}
         and p.relative_to(root).as_posix() not in excluded_working_documents
         and p.name != 'PACKAGE-MANIFEST.json']
manifest = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(files)}
manifest_path = root / 'PACKAGE-MANIFEST.json'
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
files.append(manifest_path)
with ZipFile(output, 'w', ZIP_DEFLATED, compresslevel=6) as z:
    for p in sorted(files):
        z.write(p, root.name + '/' + str(p.relative_to(root)))
with ZipFile(output) as z:
    assert z.testzip() is None
    for name, digest in manifest.items():
        assert hashlib.sha256(z.read(root.name + '/' + name)).hexdigest() == digest
print(f'Created and verified {output.name}: {len(files)} files, {output.stat().st_size} bytes')
