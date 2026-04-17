#!/usr/bin/env python3
"""Cross-simulator timing comparison report.

Usage:
    timing-report.py <artefacts_root>

Scans <artefacts_root>/*/timing-summary.json, keeps the latest run per
(hostname, simulator), and prints a markdown report to stdout with a
per-simulator summary table plus a per-test comparison when two or more
simulators exist for a given hostname.
"""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path


def _fmt_wall(seconds: float) -> str:
    mm, ss = divmod(seconds, 60)
    return f"{int(mm)}m{ss:.1f}s" if mm else f"{seconds:.1f}s"


def _collect(root: Path) -> list[dict]:
    summaries: list[dict] = []
    for p in sorted(root.glob("*/timing-summary.json")):
        try:
            with open(p) as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        data["_path"] = p.parent.name
        summaries.append(data)
    return summaries


def _latest_per_sim(summaries: list[dict]) -> dict[tuple[str, str], dict]:
    latest: dict[tuple[str, str], dict] = {}
    for s in summaries:
        key = (s.get("hostname", "unknown"), s.get("simulator", "unknown"))
        existing = latest.get(key)
        if existing is None or s.get("run_id", "") > existing.get("run_id", ""):
            latest[key] = s
    return latest


def _print_host_summary(host: str, sims: dict[str, dict]) -> None:
    print(f"# Timing Report — {host}")
    print()
    print("| Simulator | Run ID | Wall Time | Tests | Passed | Skipped |")
    print("|-----------|--------|-----------|-------|--------|---------|")
    for sim_name, data in sorted(sims.items()):
        wall = _fmt_wall(data.get("wall_time_s", 0))
        total = data.get("tests_total", 0)
        passed = sum(1 for t in data.get("tests", []) if t["status"] == "PASSED")
        skipped = sum(1 for t in data.get("tests", []) if t["status"] == "SKIPPED")
        run_id = data.get("run_id", "?")
        print(f"| {sim_name} | {run_id} | {wall} | {total} | {passed} | {skipped} |")
    print()


def _print_comparison(sims: dict[str, dict]) -> None:
    sim_names = sorted(sims.keys())
    if len(sim_names) < 2:
        return

    print(f"## Per-test comparison ({' vs '.join(sim_names)})")
    print()

    test_data: dict[str, dict[str, dict]] = defaultdict(dict)
    for sim_name, data in sims.items():
        for t in data.get("tests", []):
            base = t.get("base_name", t["name"])
            test_data[base][sim_name] = t

    cols = " | ".join(f"{s} (s)" for s in sim_names)
    header = f"| Test | {cols} | Ratio |"
    sep = "|" + "|".join(["---"] * (len(sim_names) + 2)) + "|"
    print(header)
    print(sep)

    rows: list[tuple[str, list[float | None]]] = []
    for base, by_sim in test_data.items():
        vals: list[float | None] = []
        for s in sim_names:
            if s in by_sim and by_sim[s]["status"] == "PASSED":
                vals.append(by_sim[s]["duration_s"])
            else:
                vals.append(None)
        rows.append((base, vals))
    rows.sort(key=lambda r: -(r[1][0] or 0))

    for base, vals in rows:
        val_strs = [f"{v:.3f}" if v is not None else "N/A" for v in vals]
        if len(vals) >= 2 and vals[0] and vals[-1] and vals[0] > 0:
            ratio = f"{vals[-1] / vals[0]:.1f}x"
        else:
            ratio = "N/A"
        print(f"| {base} | {' | '.join(val_strs)} | {ratio} |")
    print()

    for i, s in enumerate(sim_names):
        durations = [r[1][i] for r in rows if r[1][i] is not None]
        if durations:
            avg = sum(durations) / len(durations)
            total_d = sum(durations)
            print(
                f"**{s}**: {len(durations)} tests, total {total_d:.1f}s, "
                f"avg {avg:.2f}s/test"
            )

    common = [
        (r[1][0], r[1][-1])
        for r in rows
        if r[1][0] is not None and r[1][-1] is not None and r[1][0] > 0
    ]
    if common:
        ratios = [b / a for a, b in common]
        avg_ratio = sum(ratios) / len(ratios)
        print(
            f"**Mean ratio** ({sim_names[-1]}/{sim_names[0]}): "
            f"{avg_ratio:.2f}x across {len(common)} common tests"
        )


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Usage: timing-report.py <artefacts_root>", file=sys.stderr)
        return 2
    root = Path(argv[1])
    if not root.is_dir():
        print(f"ERROR: Artefacts directory not found: {root}", file=sys.stderr)
        return 2

    summaries = _collect(root)
    if not summaries:
        print(f"No timing-summary.json files found in {root}")
        return 0

    by_host: dict[str, dict[str, dict]] = defaultdict(dict)
    for (host, sim), data in sorted(_latest_per_sim(summaries).items()):
        by_host[host][sim] = data

    for host, sims in sorted(by_host.items()):
        _print_host_summary(host, sims)
        _print_comparison(sims)
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
