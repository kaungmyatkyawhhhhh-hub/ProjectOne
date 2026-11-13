"""Pack Studio tools (Luau ModuleScripts) into one .rbxmx for upload + insert_asset (13 Nov 2026).

Studio's execute_luau cannot fetch from the web here, so tool sources travel as a Model asset:
  python tools/yangon/pack_tools.py imports/sync/yangon_tools_1.rbxmx tools/riviera/Roads.luau tools/riviera/RoadLines.luau tools/yangon/YangonRoads.luau
then upload the file (open_cloud_invoke POST /assets/v1/assets, group 33151111), insert_asset into
ServerStorage, move the ModuleScripts into ServerStorage.ClaudeTools and delete the PackageLink.
It prints each module's length and checksum with line ends as LF: the Studio copy must give the same
(checksum = (h * 31 + byte) % 2147483647 over the Source).
"""
import os, sys


def checksum(text):
    h = 0
    for ch in text.encode('utf-8'):
        h = (h * 31 + ch) % 2147483647
    return h


def main():
    out, files = sys.argv[1], sys.argv[2:]
    items = []
    for n, path in enumerate(files):
        src = open(path, 'rb').read().decode('utf-8').replace('\r\n', '\n')
        name = os.path.splitext(os.path.basename(path))[0]
        assert ']]>' not in src and len(src) < 199000, (name, len(src))
        items.append('<Item class="ModuleScript" referent="R%d"><Properties><string name="Name">%s</string><ProtectedString name="Source"><![CDATA[%s]]></ProtectedString></Properties></Item>' % (n + 2, name, src))
        print('%s: %d chars, checksum %d' % (name, len(src), checksum(src)))
    x = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="4"><Item class="Folder" referent="R1"><Properties><string name="Name">YangonToolsIn</string></Properties>%s</Item></roblox>' % ''.join(items)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    open(out, 'w', encoding='utf-8', newline='\n').write(x)
    import xml.dom.minidom
    xml.dom.minidom.parseString(x.encode('utf-8'))
    print('wrote %s, %d bytes' % (out, len(x.encode('utf-8'))))


if __name__ == '__main__':
    main()
