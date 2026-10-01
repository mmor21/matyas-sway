#!/usr/bin/env python3
"""Rewrite the calendar span colors in waybar/modules.

Called from theme.sh. Validates JSONC before and after transformation.
If validation fails, the file is left untouched.

Usage:
    waybar-calendar.py [--dry-run] <path> <fg> <weeks> <weekdays> <today_bg> <today_fg>

Exit codes: 0 = ok / no change, 1 = not written (invalid input/output), 2 = usage.
"""

import json
import os
import re
import sys
import tempfile

HEX = re.compile(r"^#[0-9a-fA-F]{6}$")


def jsonc_to_json(text):
    """Remove // and /* */ comments and trailing commas, string-aware.

    A plain regex would also cut "https://..." inside strings. Waybar's
    parser (jsoncpp) accepts comments and trailing commas, so both must
    be handled before json.loads() can validate the file.
    """
    out, i, n = [], 0, len(text)
    in_str = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
        elif c == '"':
            in_str = True
            out.append(c)
            i += 1
        elif text.startswith("//", i):
            j = text.find("\n", i)
            i = n if j == -1 else j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            i = n if j == -1 else j + 2
        else:
            out.append(c)
            i += 1
    no_comments = "".join(out)
    # Second string-aware pass: drop commas directly before } or ].
    res, in_str, k = [], False, 0
    s = no_comments
    while k < len(s):
        ch = s[k]
        if in_str:
            res.append(ch)
            if ch == "\\" and k + 1 < len(s):
                res.append(s[k + 1])
                k += 2
                continue
            if ch == '"':
                in_str = False
        elif ch == '"':
            in_str = True
            res.append(ch)
        elif ch == ",":
            m = re.match(r",\s*([}\]])", s[k:])
            if not m:
                res.append(ch)
        else:
            res.append(ch)
        k += 1
    return "".join(res)


def is_valid_jsonc(text):
    try:
        json.loads(jsonc_to_json(text))
        return True, None
    except ValueError as e:
        return False, str(e)


def transform(original, fg, weeks, weekdays, today_bg, today_fg):
    q = r"""['"]#[0-9a-fA-F]{6}['"]"""
    subs = [
        ("months",   r'("months":\s*"<span color=)' + q,   lambda m: f"{m[1]}'{fg}'"),
        ("days",     r'("days":\s*"<span color=)' + q,     lambda m: f"{m[1]}'{fg}'"),
        ("weeks",    r'("weeks":\s*"<span color=)' + q,    lambda m: f"{m[1]}'{weeks}'"),
        ("weekdays", r'("weekdays":\s*"<span color=)' + q, lambda m: f"{m[1]}'{weekdays}'"),
        ("today",    r'("today":\s*"<span background=)' + q + r"(\s+color=)" + q,
                     lambda m: f"{m[1]}'{today_bg}'{m[2]}'{today_fg}'"),
    ]
    result, missing = original, []
    for key, pat, repl in subs:
        result, count = re.subn(pat, repl, result)
        if count == 0:
            missing.append(key)
    return result, missing


def atomic_write(path, data):
    """Write next to the real file (follows symlinks), keep permissions."""
    real = os.path.realpath(path)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(real), prefix=".modules.")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(data)
        os.chmod(tmp, os.stat(real).st_mode & 0o7777)
        os.replace(tmp, real)
    except BaseException:
        os.unlink(tmp)
        raise


def main():
    args = sys.argv[1:]
    dry_run = bool(args) and args[0] == "--dry-run"
    if dry_run:
        args = args[1:]

    if len(args) != 6:
        print(__doc__.strip().splitlines()[-3], file=sys.stderr)
        sys.exit(2)

    path, *colors = args
    bad = [c for c in colors if not HEX.match(c)]
    if bad:
        print(f"waybar/modules: not #rrggbb colors: {' '.join(bad)}", file=sys.stderr)
        sys.exit(1)

    with open(path, encoding="utf-8") as f:
        original = f.read()

    ok, err = is_valid_jsonc(original)
    if not ok:
        print(f"waybar/modules: original invalid JSONC, aborting: {err}", file=sys.stderr)
        sys.exit(1)

    transformed, missing = transform(original, *colors)
    if missing:
        print(f"waybar/modules: warning, no match for: {', '.join(missing)}", file=sys.stderr)

    ok, err = is_valid_jsonc(transformed)
    if not ok:
        print(f"waybar/modules: transformed invalid JSONC, NOT writing: {err}", file=sys.stderr)
        sys.exit(1)

    if dry_run:
        print(transformed)
    elif transformed != original:
        atomic_write(path, transformed)
        print("waybar/modules: updated")
    else:
        print("waybar/modules: no change needed")


if __name__ == "__main__":
    main()
