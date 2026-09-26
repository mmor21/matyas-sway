#!/usr/bin/env python3
"""Rewrite the calendar span colors in waybar/modules.

Called from theme.sh. Validates JSONC before and after transformation.
If validation fails, the file is left untouched.

Usage:
    waybar-calendar.py <path> <fg> <weeks> <weekdays> <today_bg> <today_fg>
    waybar-calendar.py --dry-run <path> <fg> <weeks> <weekdays> <today_bg> <today_fg>
"""

import json
import re
import sys


def strip_comments(text):
    """Strip // line comments for JSONC validation."""
    return re.sub(r'//[^\n]*', '', text)


def is_valid_jsonc(text):
    try:
        json.loads(strip_comments(text))
        return True, None
    except Exception as e:
        return False, str(e)


def transform(original, fg, weeks, weekdays, today_bg, today_fg):
    subs = [
        (r'("months":\s*"<span color=)[\'"]#[0-9a-fA-F]{6}[\'"]',
         r"\g<1>'" + fg + "'"),
        (r'("days":\s*"<span color=)[\'"]#[0-9a-fA-F]{6}[\'"]',
         r"\g<1>'" + fg + "'"),
        (r'("weeks":\s*"<span color=)[\'"]#[0-9a-fA-F]{6}[\'"]',
         r"\g<1>'" + weeks + "'"),
        (r'("weekdays":\s*"<span color=)[\'"]#[0-9a-fA-F]{6}[\'"]',
         r"\g<1>'" + weekdays + "'"),
        (r'("today":\s*"<span background=)[\'"]#[0-9a-fA-F]{6}[\'"] (color=)[\'"]#[0-9a-fA-F]{6}[\'"]',
         r"\g<1>'" + today_bg + r"' \g<2>'" + today_fg + "'"),
    ]
    result = original
    for pat, repl in subs:
        result = re.sub(pat, repl, result)
    return result


def main():
    args = sys.argv[1:]

    dry_run = False
    if args and args[0] == "--dry-run":
        dry_run = True
        args = args[1:]

    if len(args) != 6:
        print("usage: waybar-calendar.py [--dry-run] <path> <fg> <weeks> <weekdays> <today_bg> <today_fg>",
              file=sys.stderr)
        sys.exit(2)

    path, fg, weeks, weekdays, today_bg, today_fg = args

    with open(path, "r", encoding="utf-8") as f:
        original = f.read()

    ok, err = is_valid_jsonc(original)
    if not ok:
        print(f"waybar/modules: original invalid JSONC, aborting: {err}", file=sys.stderr)
        sys.exit(0)

    transformed = transform(original, fg, weeks, weekdays, today_bg, today_fg)

    ok, err = is_valid_jsonc(transformed)
    if not ok:
        print(f"waybar/modules: transformed invalid JSONC, NOT writing: {err}", file=sys.stderr)
        sys.exit(1)

    if dry_run:
        print(transformed)
        sys.exit(0)

    if transformed != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(transformed)
        print("waybar/modules: updated")
    else:
        print("waybar/modules: no change needed")


if __name__ == "__main__":
    main()
