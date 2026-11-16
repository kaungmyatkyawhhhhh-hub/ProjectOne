"""pack_strings.py out.rbxmx FolderName file1 [file2 ...] (2026-11-16): data pages (.txt) as StringValues and tool code
(.luau) as ModuleScripts in one .rbxmx Folder, for the Open Cloud PATCH of Model asset 133014134133489 (Open Cloud
refuses a NEW Model from an .rbxmx) and InsertService:LoadAsset in Studio. Each StringValue is named after its file
(without the extension) and printed with its length and checksum ((h * 31 + byte) % 2147483647, LF line ends).
"""
import os
import sys
from xml.sax.saxutils import escape


def checksum(text):
    h = 0
    for ch in text.encode("utf-8"):
        h = (h * 31 + ch) % 2147483647
    return h


def main():
    out, folder, files = sys.argv[1], sys.argv[2], sys.argv[3:]
    items = []
    for n, path in enumerate(files):
        src = open(path, "rb").read().decode("utf-8").replace("\r\n", "\n")
        name = os.path.splitext(os.path.basename(path))[0]
        assert len(src) < 199000, (name, len(src))
        if path.endswith(".luau") or path.endswith(".lua"):
            assert "]]>" not in src
            items.append('<Item class="ModuleScript" referent="R%d"><Properties><string name="Name">%s</string>'
                         '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString></Properties></Item>' % (n + 2, name, src))
        else:
            items.append('<Item class="StringValue" referent="R%d"><Properties><string name="Name">%s</string>'
                         '<string name="Value">%s</string></Properties></Item>' % (n + 2, name, escape(src)))
        print("%s: %d chars, checksum %d" % (name, len(src), checksum(src)))
    x = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
         'version="4"><Item class="Folder" referent="R1"><Properties><string name="Name">%s</string></Properties>%s</Item>'
         '</roblox>' % (folder, "".join(items)))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    open(out, "w", encoding="utf-8", newline="\n").write(x)
    import xml.dom.minidom
    xml.dom.minidom.parseString(x.encode("utf-8"))
    print("wrote %s, %d bytes" % (out, len(x.encode("utf-8"))))


if __name__ == "__main__":
    main()
