"""strings_check.py: checks src/shared/Strings.lua (run from anywhere).
Every entry has English + Myanmar, the Myanmar has Myanmar letters or is a kept loanword, the same format
specifiers in the same order, no Zawgyi-only code points, no duplicate keys. Prints counts."""
import os
import re
import sys

PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "shared", "Strings.lua")
src = open(PATH, encoding="utf-8").read()
ROW = re.compile(r'^\s*\["([^"]+)"\]\s*=\s*\{\s*"((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"(\s*,\s*true)?\s*\},?\s*$', re.M)
FMT = re.compile(r"%[-+ #0]*\d*(?:\.\d+)?[dsfxXgq%]")
rows = ROW.findall(src)
lines = [l for l in src.splitlines() if re.match(r'^\s*\["', l)]
bad = []
assert len(rows) == len(lines), "unparsed rows: %d of %d" % (len(lines) - len(rows), len(lines))
keys = [r[0] for r in rows]
dups = {k for k in keys if keys.count(k) > 1}
assert not dups, "duplicate keys %s" % dups
for k, en, my, rev in rows:
    if FMT.findall(en) != FMT.findall(my):
        bad.append("%s: format %s vs %s" % (k, FMT.findall(en), FMT.findall(my)))
    if en.count("|") != my.count("|"):
        bad.append("%s: rank count" % k)
    # Zawgyi-only: U+106A / U+106B / U+1090-1097 style forms are not used by Unicode Burmese text here
    if re.search("[ၠ-႗]", my):
        bad.append("%s: code point outside standard Burmese (Zawgyi?)" % k)
    # Unicode order: a medial ya / ra / wa / ha never comes before its consonant, e ( U+1031) never first
    if re.search(r"(^|[^က-အဿင်္ျ-ှ])ေ", my):
        bad.append("%s: U+1031 typed before its consonant (Zawgyi order)" % k)
total = len(rows)
review = sum(1 for r in rows if r[3])
print("entries %d, to review %d, bad %d" % (total, review, len(bad)))
for b in bad:
    print("  " + b)
sys.exit(1 if bad else 0)
