#!/usr/bin/env python3
"""Register (or remove) the weekly headless W1 audit job.

Windows: a Task Scheduler job (schtasks). macOS/Linux: a crontab entry
(marker comment makes install/remove idempotent). On macOS, if cron can't
read ~/.claude, grant cron Full Disk Access in System Settings.

The job runs the full W1 audit headless via `claude -p`. W1 is read-only
(it never edits a skill, only writes reports under audits/), so the headless
run uses --dangerously-skip-permissions safely.

Usage:
    python -m scripts.install_schedule [--time 03:00] [--day SUN]
                                       [--remove] [--dry-run]
"""

from __future__ import annotations

import argparse
import platform
import re
import subprocess
import sys

TASK_NAME = "ClaudeSkillQA-WeeklyAudit"
CRON_DAYS = {"SUN": 0, "MON": 1, "TUE": 2, "WED": 3, "THU": 4, "FRI": 5, "SAT": 6}
TIME_RE = re.compile(r"^([01]?\d|2[0-3]):([0-5]\d)$")


def _audit_prompt(audits_dir: str) -> str:
    return (
        "Use the skill-qa-agent skill to run a W1 full audit. Read-only: do not edit "
        "any skill or rule. Write skill-index.json, candidate-pairs.json, summary.json, "
        f"and the three reports into a new timestamped folder under {audits_dir}"
    )


# --- Windows (schtasks) -----------------------------------------------------

def build_create_cmd(time_str: str, day: str) -> list[str]:
    log = "%USERPROFILE%\\.claude\\skill-qa\\audits\\last-cron.log"
    prompt = _audit_prompt("%USERPROFILE%\\.claude\\skill-qa\\audits\\.")
    inner = (
        f'claude -p "{prompt}" --dangerously-skip-permissions '
        f'> "{log}" 2>&1'
    )
    tr = f"cmd /c {inner}"
    return [
        "schtasks", "/Create", "/TN", TASK_NAME,
        "/SC", "WEEKLY", "/D", day, "/ST", time_str,
        "/TR", tr, "/F",
    ]


def build_remove_cmd() -> list[str]:
    return ["schtasks", "/Delete", "/TN", TASK_NAME, "/F"]


def _run_windows(cmd: list[str], dry_run: bool) -> int:
    printable = " ".join(cmd)
    if dry_run:
        print(printable)
        return 0
    print(printable, file=sys.stderr)
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True)
    except FileNotFoundError:
        print("ERROR: schtasks not found.", file=sys.stderr)
        return 2
    sys.stdout.write(proc.stdout)
    sys.stderr.write(proc.stderr)
    return proc.returncode


# --- macOS / Linux (crontab) ------------------------------------------------

def build_cron_line(time_str: str, day: str) -> str:
    hour, minute = time_str.split(":")
    prompt = _audit_prompt("~/.claude/skill-qa/audits/.")
    log = "$HOME/.claude/skill-qa/audits/last-cron.log"
    cmd = f'claude -p "{prompt}" --dangerously-skip-permissions > "{log}" 2>&1'
    return f"{int(minute)} {int(hour)} * * {CRON_DAYS[day]} {cmd}  # {TASK_NAME}"


def _current_crontab() -> str:
    try:
        proc = subprocess.run(["crontab", "-l"], capture_output=True, text=True)
    except FileNotFoundError:
        return ""
    return proc.stdout if proc.returncode == 0 else ""


def _run_posix(time_str: str, day: str, remove: bool, dry_run: bool) -> int:
    kept = [l for l in _current_crontab().splitlines() if TASK_NAME not in l]
    if not remove:
        kept.append(build_cron_line(time_str, day))
    new_tab = "\n".join(kept) + ("\n" if kept else "")
    if dry_run:
        sys.stdout.write(new_tab or "(empty crontab)\n")
        return 0
    proc = subprocess.run(["crontab", "-"], input=new_tab,
                          capture_output=True, text=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        return proc.returncode
    print(("removed" if remove else "installed") + f" {TASK_NAME} crontab entry")
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Register/remove the weekly W1 audit job.")
    parser.add_argument("--time", default="03:00", help="Start time HH:MM (24h)")
    parser.add_argument("--day", default="SUN", help="Weekday: MON..SUN")
    parser.add_argument("--remove", action="store_true", help="Delete the job")
    parser.add_argument("--dry-run", action="store_true", help="Print result only")
    args = parser.parse_args(argv)

    day = args.day.upper()
    if not TIME_RE.match(args.time):
        parser.error(f"--time '{args.time}' not HH:MM (24h)")
    if day not in CRON_DAYS:
        parser.error(f"--day '{args.day}' not one of {', '.join(CRON_DAYS)}")

    if platform.system() == "Windows":
        cmd = build_remove_cmd() if args.remove else build_create_cmd(args.time, day)
        return _run_windows(cmd, args.dry_run)
    return _run_posix(args.time, day, args.remove, args.dry_run)


if __name__ == "__main__":
    raise SystemExit(main())
