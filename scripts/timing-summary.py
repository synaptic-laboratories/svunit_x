#!/usr/bin/env python3
"""Extract per-test timing data from a pytest JUnit XML file.

Usage:
    timing-summary.py <junit.xml> <simulator> <hostname> <run_id> <output.json>

Writes a timing-summary.json document with:
    - simulator, hostname, run_id, wall_time_s, tests_total
    - tests: array of {name, base_name, classname, duration_s, status}
      sorted by duration descending.

base_name strips any "[parameter]" suffix from the test name so results
from multiple simulators can be correlated for the same underlying test.
"""

from __future__ import annotations

import json
import sys
import xml.etree.ElementTree as ET


def _status(tc: ET.Element) -> str:
    if tc.find("skipped") is not None:
        return "SKIPPED"
    if tc.find("failure") is not None:
        return "FAILED"
    if tc.find("error") is not None:
        return "ERROR"
    return "PASSED"


def main(argv: list[str]) -> int:
    if len(argv) != 6:
        print(
            "Usage: timing-summary.py <junit.xml> <simulator> <hostname> "
            "<run_id> <output.json>",
            file=sys.stderr,
        )
        return 2

    xml_path, simulator, hostname, run_id, output_path = argv[1:]

    tree = ET.parse(xml_path)
    root = tree.getroot()
    testsuite = root.find(".//testsuite")
    # `testsuite or root` is a DeprecationWarning in Python 3.12+ — the truth
    # value of an Element with no children is False, which shadows the
    # element-not-found case.  Compare against None explicitly.
    wall_src = testsuite if testsuite is not None else root
    wall = float(wall_src.get("time", "0"))

    tests = []
    for tc in root.iter("testcase"):
        name = tc.get("name", "")
        base = name.rsplit("[", 1)[0] if "[" in name else name
        tests.append(
            {
                "name": name,
                "base_name": base,
                "classname": tc.get("classname", ""),
                "duration_s": round(float(tc.get("time", "0")), 3),
                "status": _status(tc),
            }
        )
    tests.sort(key=lambda t: -t["duration_s"])

    doc = {
        "simulator": simulator,
        "hostname": hostname,
        "run_id": run_id,
        "wall_time_s": round(wall, 3),
        "tests_total": len(tests),
        "tests": tests,
    }
    with open(output_path, "w") as f:
        json.dump(doc, f, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
