#!/usr/bin/env python3
"""PokéVault All-in-One Data Pipeline Runner.

Executes all database generation and scraping scripts in the required sequence:
1. update_data.py                    (Downloads web assets & updates git submodules)
2. build_database.py                 (Builds core assets/db/pokedex.sqlite)
3. update_evolutions_db.py           (Enriches evolution trees)
4. update_cap_locks_and_trades.py    (Injects special locks & trades)
5. optimize_databases.py             (Covering indexes, ANALYZE, VACUUM)
"""

import argparse
import os
import sys
import subprocess
import time
from pathlib import Path

# Ensure UTF-8 output on Windows consoles to prevent UnicodeEncodeError
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
if hasattr(sys.stderr, "reconfigure"):
    try:
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent


def run_step(step_num: int, total_steps: int, title: str, script_path: Path, args: list = None) -> bool:
    """Executes a single pipeline step and reports progress and execution time."""
    print(f"\n{'=' * 60}")
    print(f"[{step_num}/{total_steps}] {title}")
    print(f"Skript: {script_path.relative_to(REPO_ROOT)}")
    print(f"{'=' * 60}")

    if not script_path.exists():
        print(f"[!] FEHLER: Skriptdatei nicht gefunden: {script_path}")
        return False

    cmd = [sys.executable, str(script_path)] + (args or [])
    start_time = time.time()

    try:
        result = subprocess.run(cmd, cwd=str(REPO_ROOT))
        elapsed = time.time() - start_time
        if result.returncode != 0:
            print(f"\n[X] Schritt {step_num} fehlgeschlagen (Exit-Code {result.returncode}) nach {elapsed:.1f}s.")
            return False
        print(f"\n[+] Schritt {step_num} erfolgreich abgeschlossen in {elapsed:.1f}s.")
        return True
    except Exception as e:
        print(f"\n[!] Fehler bei der Ausführung von Schritt {step_num}: {e}")
        return False


def main():
    """Main entrypoint for running the end-to-end PokéVault data pipeline."""
    parser = argparse.ArgumentParser(
        description="PokéVault - Führt die gesamte Offline-Datenbank-Pipeline mit einem einzigen Befehl aus."
    )
    parser.add_argument(
        "--skip-download",
        action="store_true",
        help="Überspringt das Herunterladen von Webseiten und Git-Submodul-Updates (update_data.py).",
    )
    args = parser.parse_args()

    steps = []
    if not args.skip_download:
        steps.append((
            "Externe Rohdaten & Git-Submodule aktualisieren",
            REPO_ROOT / "update_data.py",
            [],
        ))

    steps.extend([
        (
            "SQLite-Hauptdatenbank bauen (pokedex.sqlite)",
            BASE_DIR / "build_database.py",
            [],
        ),
        (
            "Evolutionsbäume anreichern",
            BASE_DIR / "update_evolutions_db.py",
            [],
        ),
        (
            "Kappen-, Cosplay- & Tausch-Locks einpflegen",
            BASE_DIR / "update_cap_locks_and_trades.py",
            [],
        ),
        (
            "Covering-Indizes erstellen, optimieren & VACUUM",
            BASE_DIR / "optimize_databases.py",
            [],
        ),
    ])

    total_steps = len(steps)
    overall_start = time.time()

    print("\n" + "#" * 60)
    print("  PokéVault Data Pipeline Runner gestartet")
    print(f"  Geplante Schritte: {total_steps}")
    print("#" * 60)

    for i, (title, script_path, script_args) in enumerate(steps, start=1):
        success = run_step(i, total_steps, title, script_path, script_args)
        if not success:
            print("\n" + "!" * 60)
            print("(!) Pipeline wurde wegen eines Fehlers abgebrochen.")
            print("!" * 60)
            sys.exit(1)

    overall_elapsed = time.time() - overall_start
    print("\n" + "=" * 60)
    print(f"[+] Alle {total_steps} Pipeline-Schritte erfolgreich in {overall_elapsed:.1f}s ausgeführt!")
    print("assets/db/pokedex.sqlite ist nun vollständig und optimiert.")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
