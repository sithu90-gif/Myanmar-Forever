"""Verify Git's staged source blobs against an extracted release folder."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path)
    args = parser.parse_args()
    tracked = {}
    for record in subprocess.check_output(["git", "ls-files", "--stage", "-z"]).split(bytes([0])):
        if record:
            metadata, path = record.split(b"\t", 1)
            tracked[path.decode("utf-8")] = metadata.split()[1].decode("ascii")
    prefix = "Myanmar_Forever_NorthshireTest/"
    expected = {prefix + path.relative_to(args.reference).as_posix(): path
                for path in args.reference.rglob("*") if path.is_file()}
    if {path for path in tracked if path.startswith(prefix)} != set(expected):
        raise SystemExit("Tracked source paths differ from the release snapshot")
    for name, path in expected.items():
        data = path.read_bytes()
        digest = hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + bytes([0]) + data).hexdigest()
        if digest != tracked[name]:
            raise SystemExit(f"Staged source differs from released bytes: {name}")
    manifest = json.loads(Path("docs/validation/released-source-manifest.json").read_text(encoding="utf-8"))
    if manifest["fileCount"] != len(expected):
        raise SystemExit("Manifest file count differs")
    print(f"Verified {len(expected)} staged source files against released bytes")


if __name__ == "__main__":
    main()
