#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = REPO_ROOT / "docs" / "grafana-dashboards" / "manifest.json"
DASHBOARD_DIR = REPO_ROOT / "docs" / "grafana-dashboards"
ENVIRONMENTS = ("rc", "prod")


def fail(message: str) -> None:
    print(f"policy check failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        fail(f"missing required file: {path.relative_to(REPO_ROOT)}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path.relative_to(REPO_ROOT)}: {exc}")
    raise AssertionError("unreachable")


def assert_contains(path: Path, needle: str, description: str) -> None:
    text = path.read_text(encoding="utf-8")
    if needle not in text:
        fail(f"{path.relative_to(REPO_ROOT)} is missing {description}")


def main() -> None:
    manifest = load_json(MANIFEST_PATH)
    dashboards = manifest.get("dashboards")
    if not isinstance(dashboards, list) or not dashboards:
        fail("Grafana dashboard manifest must declare at least one dashboard entry")

    manifest_files: list[str] = []
    for entry in dashboards:
        if not isinstance(entry, dict):
            fail("Grafana dashboard manifest entries must be objects")
        file_name = entry.get("file")
        if not isinstance(file_name, str) or not file_name:
            fail("Grafana dashboard manifest entries must include a file path")
        manifest_files.append(file_name)

        dashboard_path = REPO_ROOT / file_name
        if not dashboard_path.is_file():
            fail(f"Grafana dashboard file not found: {file_name}")

    expected_files = sorted(
        path.relative_to(REPO_ROOT).as_posix()
        for path in DASHBOARD_DIR.glob("*.json")
        if path.name != "manifest.json"
    )
    if sorted(manifest_files) != expected_files:
        fail(
            "Grafana dashboard manifest entries must match the tracked dashboard JSON assets"
        )

    for env in ENVIRONMENTS:
        main_tf = REPO_ROOT / "environments" / env / "main.tf"
        outputs_tf = REPO_ROOT / "environments" / env / "outputs.tf"
        assert_contains(main_tf, 'module "grafana_dashboards"', "Grafana dashboard module wiring")
        assert_contains(
            main_tf,
            "grafana_dashboard_manifest_path",
            "Grafana dashboard manifest path wiring",
        )
        assert_contains(
            main_tf,
            "grafana_dashboard_source_root",
            "Grafana dashboard source root wiring",
        )
        assert_contains(
            outputs_tf,
            "grafana_dashboard_provisioning",
            "Grafana dashboard provisioning output contract",
        )
        assert_contains(
            outputs_tf,
            "module.grafana_dashboards.dashboards",
            "Grafana dashboard output wiring",
        )

    module_main = REPO_ROOT / "modules" / "grafana_dashboards" / "main.tf"
    assert_contains(
        module_main,
        "jsondecode(file(var.dashboard_manifest_path))",
        "manifest-driven dashboard loading",
    )
    assert_contains(
        module_main,
        "file(each.value.source_path)",
        "source-controlled dashboard file loading",
    )

    for tf_file in REPO_ROOT.rglob("*.tf"):
        if ".terraform" in tf_file.parts:
            continue
        if "terraform.workspace" in tf_file.read_text(encoding="utf-8"):
            fail(
                f"Terraform workspaces are not allowed: {tf_file.relative_to(REPO_ROOT)}"
            )

    print("Terraform policy checks passed")


if __name__ == "__main__":
    main()
