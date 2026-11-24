#!/usr/bin/env python3
"""Read-only, local structure inspection of exported Apple Watch face archives."""
import argparse
import json
import pathlib
import plistlib
import zipfile

MAX_MEMBER = 2 * 1024 * 1024
MAX_TOTAL = 12 * 1024 * 1024
MAX_ENTRIES = 512
MAX_DEPTH = 20
MAX_NODES = 2000


def schema(value):
    remaining = MAX_NODES

    def walk(node, depth):
        nonlocal remaining
        remaining -= 1
        if remaining < 0 or depth >= MAX_DEPTH:
            return "<limit>"
        if isinstance(node, dict):
            return {str(key): walk(item, depth + 1)
                    for key, item in sorted(node.items(), key=lambda pair: str(pair[0]))}
        if isinstance(node, (list, tuple)):
            shapes = {}
            for item in node:
                shape = walk(item, depth + 1)
                shapes[json.dumps(shape, sort_keys=True)] = shape
                if remaining <= 0:
                    break
            return list(shapes.values())
        return type(node).__name__

    return walk(value, 0)


def inspect(path):
    result = {"archive": path.name, "members": [], "schemas": {}}
    with zipfile.ZipFile(path) as archive:
        entries = archive.infolist()
        if len(entries) > MAX_ENTRIES:
            raise ValueError("Too many archive members")
        budget = MAX_TOTAL
        for entry in entries:
            name = entry.filename
            result["members"].append({"path": name, "bytes": entry.file_size})
            suffix = pathlib.PurePosixPath(name).suffix.lower()
            if entry.is_dir() or suffix not in {".json", ".plist"}:
                continue
            if entry.file_size > MAX_MEMBER or entry.file_size > budget:
                result["schemas"][name] = "<size limit>"
                continue
            if name in result["schemas"]:
                raise ValueError("Duplicate configuration member: " + name)
            with archive.open(entry) as stream:
                data = stream.read(MAX_MEMBER + 1)
            if len(data) > MAX_MEMBER or len(data) > budget:
                result["schemas"][name] = "<size limit>"
                continue
            budget -= len(data)
            try:
                obj = json.loads(data) if suffix == ".json" else plistlib.loads(data)
                result["schemas"][name] = schema(obj)
            except (ValueError, TypeError, OverflowError, RecursionError, plistlib.InvalidFileException) as error:
                result["schemas"][name] = "<unreadable: " + type(error).__name__ + ">"
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("faces", nargs="+", type=pathlib.Path)
    args = parser.parse_args()
    for path in args.faces:
        try:
            print(json.dumps(inspect(path), indent=2, ensure_ascii=True, sort_keys=True))
        except (OSError, ValueError, RuntimeError, zipfile.BadZipFile) as error:
            parser.exit(1, f"{path.name}: {type(error).__name__}: {error}\n")


if __name__ == "__main__":
    main()
