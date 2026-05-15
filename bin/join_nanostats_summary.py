#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Join NanoPlot NanoStats tables across samples.")
    parser.add_argument("--pattern", required=True, help="Glob pattern for NanoStats input files.")
    parser.add_argument("--output", required=True, help="Output TSV file.")
    args = parser.parse_args()

    files = sorted(Path('.').glob(args.pattern))
    if not files:
        raise SystemExit(f"No files matched pattern: {args.pattern}")

    header_names = []
    all_metrics = []
    data = {}

    for fp in files:
        sample = fp.name
        sample = sample.replace('.prefilter_nanostats.txt', '')
        sample = sample.replace('.postfilter_nanostats.txt', '')
        header_names.append(sample)

        rows = {}
        with fp.open() as handle:
            reader = csv.reader(handle, delimiter='\t')
            for row in reader:
                if not row or len(row) < 2:
                    continue
                key = row[0].strip()
                val = row[1].strip()
                if key.lower() in {'metrics', 'metric', 'statistics', 'statistic'}:
                    continue
                rows[key] = val
                if key not in all_metrics:
                    all_metrics.append(key)
        data[sample] = rows

    with open(args.output, 'w', newline='') as out:
        writer = csv.writer(out, delimiter='\t')
        writer.writerow(['Metric'] + header_names)
        for metric in all_metrics:
            writer.writerow([metric] + [data[s].get(metric, 'NA') for s in header_names])


if __name__ == '__main__':
    main()
