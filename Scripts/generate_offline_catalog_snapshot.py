#!/usr/bin/env python3
"""Generate BrickScan/Resources/OfflineCatalogSnapshot.json from Rebrickable's public catalog dump.

Rebrickable publishes a daily, unauthenticated CSV dump of every set in its catalog at
https://cdn.rebrickable.com/media/downloads/sets.csv.gz (see https://rebrickable.com/downloads/ —
no API key needed for this static download, unlike the v3 API used elsewhere in this app). Its
columns are `set_num,name,year,theme_id,num_parts,img_url`, which line up directly with `LegoSet`'s
Codable keys in BrickScan/Core/Network/APIModels.swift (`set_img_url` here is renamed from the
dump's `img_url` to match).

This script is NOT run automatically as part of the build (see AGENTS.md "Build" — the generated
project deliberately has no build-time network step). Run it manually whenever the bundled
snapshot needs refreshing, and commit the resulting JSON:

    python3 Scripts/generate_offline_catalog_snapshot.py

NOTE: the file currently committed at BrickScan/Resources/OfflineCatalogSnapshot.json is a small,
hand-picked placeholder (a handful of well-known sets), NOT a real run of this script — the
network this was written in could not reach rebrickable.com to validate the dump's exact shape or
download the full ~25k-set catalog. Before shipping the offline-catalog feature for real, run this
script with real network access, review the output size (see the "Questions ouvertes" in the
originating issue about bundle size), and replace the placeholder file.
"""
import argparse
import csv
import gzip
import json
import sys
import urllib.request
from pathlib import Path

DUMP_URL = "https://cdn.rebrickable.com/media/downloads/sets.csv.gz"
DEFAULT_OUTPUT = Path(__file__).resolve().parent.parent / "BrickScan" / "Resources" / "OfflineCatalogSnapshot.json"


def fetch_rows(url: str):
    with urllib.request.urlopen(url) as response:
        with gzip.open(response, mode="rt", encoding="utf-8", newline="") as text_stream:
            yield from csv.DictReader(text_stream)


def to_lego_set(row: dict) -> dict:
    return {
        "set_num": row["set_num"],
        "name": row["name"],
        "year": int(row["year"]),
        "theme_id": int(row["theme_id"]),
        "num_parts": int(row["num_parts"]),
        "set_img_url": row["img_url"] or None,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=DUMP_URL, help="Override the sets.csv.gz dump URL.")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Output JSON path.")
    args = parser.parse_args()

    sets = [to_lego_set(row) for row in fetch_rows(args.url)]
    args.output.write_text(json.dumps(sets, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(sets)} sets to {args.output} ({args.output.stat().st_size / 1_000_000:.1f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
