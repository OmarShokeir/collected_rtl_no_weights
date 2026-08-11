#!/usr/bin/env python3

from pathlib import Path
import shutil

SCRIPT_DIR = Path(__file__).parent.resolve()

SOURCE_DIR = SCRIPT_DIR / "collected_rtl_2"
DEST_DIR = SCRIPT_DIR / "flattened"

DEST_DIR.mkdir(exist_ok=True)

renamed = []

for file in SOURCE_DIR.rglob("*"):
    if not file.is_file():
        continue

    destination = DEST_DIR / file.name

    if destination.exists():
        stem = destination.stem
        suffix = destination.suffix
        i = 1
        while True:
            new_destination = DEST_DIR / f"{stem}_{i}{suffix}"
            if not new_destination.exists():
                renamed.append((file.relative_to(SOURCE_DIR), new_destination.name))
                destination = new_destination
                break
            i += 1

    shutil.copy2(file, destination)

print(f"\nCopied {sum(1 for _ in DEST_DIR.iterdir())} files.")

if renamed:
    print("\nFiles renamed due to duplicate names:")
    print("-" * 60)
    for original, newname in renamed:
        print(f"{original}  -->  {newname}")
else:
    print("\nNo duplicate filenames found.")