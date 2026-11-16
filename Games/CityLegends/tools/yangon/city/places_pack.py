"""places_pack.py <tag> (2026-11-16): one holding .rbxmx for Studio after places_1to1 + buildings_1to1:
Folder PlacesHold_<tag>
  Data_<tag>   (buildings_<tag>/ygnkit_<tag>.rbxmx: the kit detail, client-streamed)
  Data_<tag>P  (places_<tag>/ygnplaces_<tag>.rbxmx: the places detail, client-streamed, LOAD 900)
  Shell_<n>    StringValues (YangonKitPlace.shells lines)
  YangonKitData  ModuleScript (src/shared/YangonKitData.lua: the place colour codes)
PATCH it as a new version of Model asset 133014134133489 (content type model/x-rbxm), InsertService:LoadAsset in Studio.
    YANGON_SCALE=1to1 python places_pack.py P1
"""
import glob
import os
import re
import sys
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
TAG = sys.argv[1] if len(sys.argv) > 1 else "P1"
B1 = os.path.join(ROOT, "build", "city_1to1")


def inner_folder(path):
    """the <Item class="Folder" ...>...</Item> of a one-folder rbxmx, referents renamed to stay unique"""
    x = open(path, encoding="utf-8").read()
    a = x.index('<Item class="Folder"')
    b = x.rindex("</roblox>")
    body = x[a:b]
    pre = os.path.basename(path).split(".")[0]
    return re.sub(r'referent="R(\d+)"', lambda m: 'referent="%s_%s"' % (pre, m.group(1)), body)


def main():
    parts = []
    bdir = os.path.join(B1, "buildings_%s" % TAG)
    parts.append(inner_folder(os.path.join(ROOT, "imports", "sync", "ygn1to1_%s" % TAG.lower(), "ygnkit_%s.rbxmx" % TAG.lower())))
    parts.append(inner_folder(os.path.join(B1, "places_%s" % TAG, "ygnplaces_%s.rbxmx" % TAG.lower())))
    k = 0
    for p in sorted(glob.glob(os.path.join(bdir, "Shell_*.txt")), key=lambda s: int(re.findall(r"\d+", os.path.basename(s))[0])):
        v = open(p, encoding="utf-8").read().replace("\r\n", "\n")
        assert len(v) < 199000
        k += 1
        parts.append('<Item class="StringValue" referent="S%d"><Properties><string name="Name">%s</string>'
                     '<string name="Value">%s</string></Properties></Item>' % (k, os.path.splitext(os.path.basename(p))[0], escape(v)))
    # the run being replaced (its exact positions: PlacesApply.unshells removes only those parts)
    old = os.path.join(B1, "buildings_%s_before_places" % TAG)
    for p in sorted(glob.glob(os.path.join(old, "Shell_*.txt")), key=lambda s: int(re.findall(r"\d+", os.path.basename(s))[0])):
        v = open(p, encoding="utf-8").read().replace("\r\n", "\n")
        k += 1
        parts.append('<Item class="StringValue" referent="S%d"><Properties><string name="Name">Old%s</string>'
                     '<string name="Value">%s</string></Properties></Item>' % (k, os.path.splitext(os.path.basename(p))[0], escape(v)))
    # the green layer run again with the places keep-out (its own holding folder, nested)
    gp = os.path.join(ROOT, "imports", "sync", "ygn1to1_green", "green_%s.rbxmx" % TAG.lower())
    if os.path.exists(gp):
        parts.append(inner_folder(gp))
    for i, name in enumerate(("PlacesApply", "YangonShellFacades", "YangonKitPlace", "YangonGreen1to1")):
        code = open(os.path.join(ROOT, "tools", "yangon", name + ".luau"), encoding="utf-8").read().replace("\r\n", "\n")
        parts.append('<Item class="ModuleScript" referent="M%d"><Properties><string name="Name">%s</string>'
                     '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString></Properties></Item>' % (i + 2, name, code))
    # shell facade sets (city/shell_facades.py map P1 P2 P3 P4): YangonShellFacades.apply pages
    for st in ("walkup", "shop", "none"):
        v = open(os.path.join(ROOT, "build", "shell_facades", "packed_%s.txt" % st)).read()
        parts.append('<Item class="StringValue" referent="F_%s"><Properties><string name="Name">Fac_%s</string>'
                     '<string name="Value">%s</string></Properties></Item>' % (st, st, v))
    src = open(os.path.join(ROOT, "src", "shared", "YangonKitData.lua"), encoding="utf-8").read().replace("\r\n", "\n")
    assert "]]>" not in src
    parts.append('<Item class="ModuleScript" referent="M1"><Properties><string name="Name">YangonKitData</string>'
                 '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString></Properties></Item>' % src)
    x = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
         'version="4"><Item class="Folder" referent="H1"><Properties><string name="Name">PlacesHold_%s</string></Properties>%s'
         '</Item></roblox>' % (TAG, "".join(parts)))
    out = os.path.join(ROOT, "imports", "sync", "places_%s.rbxmx" % TAG.lower())
    open(out, "w", encoding="utf-8", newline="\n").write(x)
    import xml.dom.minidom
    xml.dom.minidom.parseString(x.encode("utf-8"))
    h = 0
    for ch in src.encode("utf-8"):
        h = (h * 31 + ch) % 2147483647
    print("wrote %s  %d bytes, %d shell pages, YangonKitData %d chars checksum %d" % (out, len(x.encode("utf-8")), k, len(src), h))




def places_only():
    """the places layer alone (Data_<tag>P + Grade pages + PlacesApply): after the buildings / green swap is in"""
    parts = [inner_folder(os.path.join(B1, "places_%s" % TAG, "ygnplaces_%s.rbxmx" % TAG.lower()))]
    for p in sorted(glob.glob(os.path.join(B1, "places_%s" % TAG, "Grade_*.txt"))):
        parts.append('<Item class="StringValue" referent="G%s"><Properties><string name="Name">%s</string>'
                     '<string name="Value">%s</string></Properties></Item>' % (
                         os.path.basename(p)[6:-4], os.path.splitext(os.path.basename(p))[0], escape(open(p).read())))
    code = open(os.path.join(ROOT, "tools", "yangon", "PlacesApply.luau"), encoding="utf-8").read().replace("\r\n", "\n")
    parts.append('<Item class="ModuleScript" referent="M2"><Properties><string name="Name">PlacesApply</string>'
                 '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString></Properties></Item>' % code)
    x = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
         'version="4"><Item class="Folder" referent="H1"><Properties><string name="Name">PlacesOnly_%s</string></Properties>%s'
         '</Item></roblox>' % (TAG, "".join(parts)))
    out = os.path.join(ROOT, "imports", "sync", "places_only_%s.rbxmx" % TAG.lower())
    open(out, "w", encoding="utf-8", newline="\n").write(x)
    import xml.dom.minidom
    xml.dom.minidom.parseString(x.encode("utf-8"))
    print("wrote %s  %d bytes" % (out, len(x.encode("utf-8"))))


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[2] == "places":
        places_only()
    else:
        main()
