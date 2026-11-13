"""Join pages of Studio output saved by the MCP into one text file (each page starts with "@P<n>@" and may end with "@END@";
the MCP saves an execute_luau result over ~90k characters as a file, sometimes as JSON [{"text": ...}]).

  python join_pages.py out.txt page1.txt page2.txt ...
"""
import json, sys


def text_of(path):
    s = open(path, encoding='utf-8').read()
    if s[:1] in '[{':
        try:
            d = json.loads(s)
            s = d[0]['text'] if isinstance(d, list) else d.get('text', s)
        except Exception:
            pass
    return s


def main():
    out, pages = sys.argv[1], sys.argv[2:]
    rows = []
    for i, p in enumerate(pages):
        s = text_of(p)
        tag = f'@P{i + 1}@'
        s = s[s.index(tag) + len(tag):]
        if '@END@' in s:
            s = s[:s.index('@END@')]
        rows += [r for r in s.split(chr(10)) if r.strip()]
    open(out, 'w', encoding='utf-8', newline=chr(10)).write(chr(10).join(rows) + chr(10))
    print(len(rows), 'rows ->', out)


if __name__ == '__main__':
    main()
