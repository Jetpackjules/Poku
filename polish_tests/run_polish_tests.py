#!/usr/bin/env python3
"""Fast Godot-4-only checks for Poku's polished-jank invariants."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GODOT = Path(os.environ.get("GODOT4", "/usr/local/bin/godot"))
SCENES = (
    "res://polish_tests/classic_physics_contract_test.tscn",
    "res://polish_tests/pause_options_test.tscn",
    "res://polish_tests/presentation_flow_test.tscn",
    "res://polish_tests/experimental_features_test.tscn",
    "res://polish_tests/test_lab_test.tscn",
    "res://polish_tests/spaceship_coal_test.tscn",
    "res://polish_tests/mode_rules_test.tscn",
    "res://polish_tests/planes_interaction_test.tscn",
    "res://polish_tests/controller_input_test.tscn",
    "res://polish_tests/map_smoke_test.tscn",
    "res://polish_tests/ostritch_route_test.tscn",
)


def main() -> int:
    if not GODOT.exists():
        print(f"Godot 4 executable not found: {GODOT}", file=sys.stderr)
        return 2

    environment = os.environ.copy()
    environment["POKU_POLISH_TEST"] = "1"
    failed = False

    for scene in SCENES:
        completed = subprocess.run(
            [str(GODOT), "--headless", "--path", str(ROOT), scene],
            cwd=ROOT,
            env=environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=45,
        )
        print(completed.stdout, end="")
        runtime_error = "SCRIPT ERROR:" in completed.stdout or "\nERROR:" in completed.stdout
        if completed.returncode != 0 or '"passed":true' not in completed.stdout or runtime_error:
            failed = True

    print("POLISH SUITE PASS" if not failed else "POLISH SUITE FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
