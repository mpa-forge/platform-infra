#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ENVIRONMENTS = ("rc", "prod")


def fail(message: str) -> None:
    print(f"static analysis failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def assert_contains(path: Path, needle: str, description: str) -> None:
    text = path.read_text(encoding="utf-8")
    if needle not in text:
        fail(f"{path.relative_to(REPO_ROOT)} is missing {description}")


def main() -> None:
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

    print("Terraform static analysis passed")


if __name__ == "__main__":
    main()
