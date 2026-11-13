"""Pack changed game scripts (and Studio tools) into one .rbxmx for Open Cloud -> Studio (Yangon step 9, 2026-11-14).

  python tools/yangon/pack_sync.py out.rbxmx src/shared/Config.lua src/server/Main.server.lua ... tools/yangon/X.luau
src/<side>/... files go into CLSync/<side> (Script / LocalScript / ModuleScript by name, for ClaudeTools.SyncScripts);
tools/... files go into Tools (ModuleScripts for ClaudeTools). Prints each one's byte length and checksum (LF line ends).
"""
import os, sys, xml.dom.minidom


def ck(b):
    h = 0
    for x in b:
        h = (h * 31 + x) % 2147483647
    return h


out, files = sys.argv[1], sys.argv[2:]
ref = [1]
groups = {}
for path in files:
    raw = open(path, 'rb').read().replace(b'\r\n', b'\n')
    src = raw.decode('utf-8')
    base = os.path.basename(path)
    parts = path.replace(chr(92), '/').split('/')
    if parts[0] == 'src':
        side = parts[1]
        if base.endswith('.server.lua'):
            cls, name = 'Script', base[:-11]
        elif base.endswith('.client.lua'):
            cls, name = 'LocalScript', base[:-11]
        else:
            cls, name = 'ModuleScript', os.path.splitext(base)[0]
        key = ('CLSync', side)
    else:
        cls, name, key = 'ModuleScript', os.path.splitext(base)[0], ('Tools', None)
    assert ']]>' not in src and len(raw) < 199000, (name, len(raw))
    ref[0] += 1
    groups.setdefault(key, []).append('<Item class="%s" referent="R%d"><Properties><string name="Name">%s</string><ProtectedString name="Source"><![CDATA[%s]]></ProtectedString></Properties></Item>' % (cls, ref[0], name, src))
    print('%-14s %-12s %7d %d' % (name, cls, len(raw), ck(raw)))


def folder(name, inner):
    ref[0] += 1
    return '<Item class="Folder" referent="R%d"><Properties><string name="Name">%s</string></Properties>%s</Item>' % (ref[0], name, inner)


cl = ''.join(folder(side, ''.join(v)) for (top, side), v in groups.items() if top == 'CLSync')
body = (folder('CLSync', cl) if cl else '') + (folder('Tools', ''.join(groups[('Tools', None)])) if ('Tools', None) in groups else '')
x = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="4"><Item class="Folder" referent="R1"><Properties><string name="Name">YangonToolsIn</string></Properties>%s</Item></roblox>' % body
xml.dom.minidom.parseString(x.encode('utf-8'))
open(out, 'w', encoding='utf-8', newline='\n').write(x)
print(len(x.encode('utf-8')), 'bytes ->', out)
