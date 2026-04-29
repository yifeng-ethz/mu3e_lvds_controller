#!/usr/bin/env python3
"""Run ordered LVDS isolated coverage and emit machine-readable deltas."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass


UVM_ROOT = pathlib.Path(__file__).resolve().parents[1]
TB_ROOT = UVM_ROOT.parent
VCOVER = pathlib.Path("/data1/questaone_sim/questasim/linux_x86_64/vcover")
DU_NAME = "work.mu3e_lvds_controller"

METRIC_NAMES = {
    "Branches": "branch",
    "Conditions": "cond",
    "Expressions": "expr",
    "Statements": "stmt",
    "Toggles": "toggle",
}


@dataclass(frozen=True)
class Metrics:
    values: dict[str, float]
    total: float

    def delta(self, previous: "Metrics | None") -> dict[str, float]:
        if previous is None:
            return {**self.values, "total": self.total}
        delta = {name: self.values.get(name, 0.0) - previous.values.get(name, 0.0) for name in METRIC_NAMES.values()}
        delta["total"] = self.total - previous.total
        return delta


def run(cmd: list[str], cwd: pathlib.Path = UVM_ROOT, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("+", " ".join(cmd), flush=True)
    return subprocess.run(cmd, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=check)


def parse_metrics(ucdb: pathlib.Path) -> Metrics:
    result = run(
        [
            str(VCOVER),
            "report",
            f"-du={DU_NAME}",
            "-codeAll",
            str(ucdb),
        ]
    )
    values: dict[str, float] = {}
    for line in result.stdout.splitlines():
        match = re.match(r"\s*(Branches|Conditions|Expressions|Statements|Toggles)\s+\d+\s+\d+\s+\d+\s+([0-9.]+)%", line)
        if match:
            values[METRIC_NAMES[match.group(1)]] = float(match.group(2))
            continue
        total_match = re.match(r"Total Coverage By Design Unit .*:\s+([0-9.]+)%", line)
        if total_match:
            total = float(total_match.group(1))
    if "total" not in locals():
        raise RuntimeError(f"failed to parse total coverage from {ucdb}")
    for name in METRIC_NAMES.values():
        values.setdefault(name, 0.0)
    return Metrics(values=values, total=total)


def merge_ucdb(output: pathlib.Path, inputs: list[pathlib.Path]) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    if len(inputs) == 1:
        shutil.copy2(inputs[0], output)
        return
    run([str(VCOVER), "merge", "-quiet", str(output), *[str(path) for path in inputs]])


def read_cases(selected: str | None) -> list[str]:
    if selected:
        return [case.strip().upper() for case in selected.split(",") if case.strip()]
    return [
        line.strip()
        for line in (UVM_ROOT / "regression_cases.list").read_text(encoding="ascii").splitlines()
        if line.strip()
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build", default="cov_primary")
    parser.add_argument("--symbol-cap", type=int, default=256)
    parser.add_argument("--cases")
    parser.add_argument("--no-compile", action="store_true")
    parser.add_argument("--reuse-existing", action="store_true")
    args = parser.parse_args()

    cases = read_cases(args.cases)
    cov_root = UVM_ROOT / "cov" / args.build
    report_root = TB_ROOT / "REPORT" / "coverage"
    isolated_root = cov_root / "isolated"
    merged_root = cov_root / "merged"
    report_root.mkdir(parents=True, exist_ok=True)

    if not args.no_compile:
        run(["make", f"BUILD={args.build}", "COVER=1", "compile"])

    rows: list[dict[str, object]] = []
    previous_metrics: Metrics | None = None
    previous_merged: pathlib.Path | None = None

    for index, case_id in enumerate(cases, start=1):
        ucdb = isolated_root / f"{case_id}.ucdb"
        if not (args.reuse_existing and ucdb.exists()):
            run(
                [
                    "make",
                    f"BUILD={args.build}",
                    "COVER=1",
                    f"CASE_ID={case_id}",
                    "coverage_case",
                    f"SYMBOL_CAP={args.symbol_cap}",
                ]
            )

        isolated_metrics = parse_metrics(ucdb)
        merged_ucdb = merged_root / f"{index:03d}_{case_id}.ucdb"
        merge_inputs = [ucdb] if previous_merged is None else [previous_merged, ucdb]
        merge_ucdb(merged_ucdb, merge_inputs)
        merged_metrics = parse_metrics(merged_ucdb)
        delta = merged_metrics.delta(previous_metrics)

        rows.append(
            {
                "index": index,
                "case_id": case_id,
                "ucdb": str(ucdb.relative_to(UVM_ROOT)),
                "merged_ucdb": str(merged_ucdb.relative_to(UVM_ROOT)),
                "isolated": {**isolated_metrics.values, "total": isolated_metrics.total},
                "merged": {**merged_metrics.values, "total": merged_metrics.total},
                "delta": delta,
                "zero_increment": all(abs(value) < 0.005 for value in delta.values()),
            }
        )
        previous_metrics = merged_metrics
        previous_merged = merged_ucdb
        print(
            f"{case_id}: merged total {merged_metrics.total:.2f}% "
            f"delta {delta['total']:+.2f}% zero={rows[-1]['zero_increment']}",
            flush=True,
        )

    output = report_root / f"{args.build}_coverage.json"
    output.write_text(json.dumps({"build": args.build, "du": DU_NAME, "cases": rows}, indent=2) + "\n", encoding="ascii")
    print(f"wrote {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
