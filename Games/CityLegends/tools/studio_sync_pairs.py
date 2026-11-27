"""Make one execute_luau script that copies changed src files into Studio as find/replace pairs (26 Nov 2026).
Each file's Studio Source must equal the git base (default HEAD); the script checks the length first and reports
"<name> base <len>" if not, "<name> MISS" if a pair is not found, else "<name> <new len>/<want>".
Usage (from Games/CityLegends): python tools/studio_sync_pairs.py [base [files...]] > out.luau (no files: every src file changed since base, new ones too)   (then paste into execute_luau, Edit)
Writes Source directly (27 Nov: ScriptEditorService:UpdateSourceAsync hung in Team Create; a plain Source write worked).
Line-based diff: fast on 140k-character files (a character diff took minutes)."""
import subprocess, difflib, sys

def inst_of(f):
    """repo path -> the Studio instance path (Rojo layout: client / server / shared; folder modules = init.lua)"""
    root = {'src/client/': 'game.StarterPlayer.StarterPlayerScripts.Client', 'src/server/': 'game.ServerScriptService.Server', 'src/shared/': 'game.ReplicatedStorage.Shared'}
    for k, v in root.items():
        if f.startswith(k):
            rest = f[len(k):]
            for ext in ('.client.lua', '.server.lua', '.lua'):
                if rest.endswith(ext):
                    rest = rest[:-len(ext)]
                    break
            parts = [x for x in rest.split('/') if x != 'init']
            return v + ''.join('[%s]' % lit(x) for x in parts)
    raise SystemExit('not a src file: ' + f)


BASE = sys.argv[1] if len(sys.argv) > 1 else 'HEAD'
NL = '\n'


def lit(s):
    """a plain-ASCII Luau string literal (non-ASCII as \\u{...}: terminals garble UTF-8 when the script is pasted)"""
    out = []
    for ch in s:
        o = ord(ch)
        if ch == '\\':
            out.append('\\\\')
        elif ch == '"':
            out.append('\\"')
        elif ch == '\n':
            out.append('\\n')
        elif ch == '\t':
            out.append('\\t')
        elif o < 32:
            out.append('\\%d' % o)
        elif o < 128:
            out.append(ch)
        else:
            out.append('\\u{%x}' % o)
    return '"' + ''.join(out) + '"'


def gen(old, new, inst):
    ol, nl = old.split(NL), new.split(NL)
    sm = difflib.SequenceMatcher(None, ol, nl, autojunk=False)
    out = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal':
            continue
        a, b = max(0, i1 - 2), min(len(ol), i2 + 2)
        while True:
            s = NL.join(ol[a:b])
            if old.count(s) == 1 and len(s) > 20:
                break
            a, b = max(0, a - 1), min(len(ol), b + 1)
        c, d = j1 - (i1 - a), j2 + (b - i2)
        if out and a < out[-1][3]:  # overlaps the previous region: grow that one instead
            pa = out[-1][2]
            pc = out[-1][4]
            s = NL.join(ol[pa:b])
            out[-1] = (s, NL.join(nl[pc:d]), pa, b, pc)
        else:
            out.append((s, NL.join(nl[c:d]), a, b, c))
    cur = old
    for s, n, *_ in reversed(out):
        assert cur.count(s) == 1, inst
        i = cur.find(s)
        cur = cur[:i] + n + cur[i + len(s):]
    assert cur == new, inst
    body = ','.join('{%s,%s}' % (lit(s), lit(n)) for s, n, *_ in reversed(out))
    return ('do local inst=%s local src=inst.Source:gsub("\\r","") if #src~=%d then table.insert(R,inst.Name.." base "..#src) '
            'else local ok=true for _,p in {%s} do local i,j=string.find(src,p[1],1,true) if not i then ok=false break end '
            'src=src:sub(1,i-1)..p[2]..src:sub(j+1) end if ok then inst.Source=src '
            'table.insert(R,inst.Name.." "..#inst.Source.."/%d") else table.insert(R,inst.Name.." MISS") end end end'
            % (inst, len(old.encode()), body, len(new.encode())))


def git(*a):
    return subprocess.run(['git', *a], capture_output=True, encoding='utf-8')


FILES = sys.argv[2:] or [f.replace('Games/CityLegends/', '') for f in git('diff', '--name-only', BASE, '--', 'src').stdout.split()]
if not sys.argv[2:]:  # (27 Nov) files given = only those: never create another job's new scripts
    FILES += [f for f in git('ls-files', '--others', '--exclude-standard', 'src').stdout.split() if f not in FILES]
print('local SES=game:GetService("ScriptEditorService") local R={}')
for f in FILES:
    inst = inst_of(f)
    r = git('show', f'{BASE}:Games/CityLegends/{f}')
    new = open(f, encoding='utf-8').read().replace('\r', '')
    if r.returncode != 0:  # a new file: make the ModuleScript under its parent and fill it
        parent, name = inst.rsplit('[', 1)
        name = name[:-1]
        print('do local p=%s local m=p:FindFirstChild(%s) or Instance.new("ModuleScript") m.Name=%s m.Parent=p '
              'm.Source=%s table.insert(R,m.Name.." new "..#m.Source.."/%d") end'
              % (parent, name, name, lit(new), len(new.encode())))
        continue
    old = r.stdout.replace('\r', '')
    if old != new:
        print(gen(old, new, inst))
print('return table.concat(R,"\\n")')
