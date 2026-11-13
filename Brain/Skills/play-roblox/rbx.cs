// rbx.exe - drive the Roblox player (RobloxPlayerBeta) from Claude Code on Windows.
// Real input the way games read it: SendInput with SCAN CODES, separate key down / up, holds, several keys at once,
// RELATIVE mouse moves (Roblox's camera turns with right-button drag), focus by process, screenshots of the game only.
// Commands can be chained in one call with ';' (one process start for many actions):
//   rbx "focus; key w 1500; shot C:\path\a.png"
// Coordinates for click / move are in the LAST SCREENSHOT's pixels (the tool maps them back to the screen).
// Build: csc /out:rbx.exe /r:System.Drawing.dll rbx.cs   (the .NET Framework compiler that ships with Windows)
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;

static class Rbx
{
    // ------------------------------------------------------------------ Win32
    [StructLayout(LayoutKind.Sequential)] struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] struct POINT { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] struct KEYBDINPUT { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Explicit)] struct InputUnion { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
    [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public InputUnion u; }

    [DllImport("user32.dll")] static extern uint SendInput(uint n, INPUT[] inputs, int size);
    [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);
    [DllImport("user32.dll")] static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out POINT p);
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] static extern bool AttachThreadInput(uint a, uint b, bool attach);
    [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();

    const uint INPUT_MOUSE = 0, INPUT_KEYBOARD = 1;
    const uint KEYEVENTF_EXTENDEDKEY = 0x1, KEYEVENTF_KEYUP = 0x2, KEYEVENTF_SCANCODE = 0x8;
    const uint MOUSEEVENTF_MOVE = 0x1, LEFTDOWN = 0x2, LEFTUP = 0x4, RIGHTDOWN = 0x8, RIGHTUP = 0x10, MIDDLEDOWN = 0x20, MIDDLEUP = 0x40, WHEEL = 0x800;

    static string GeomFile { get { return Path.Combine(Path.GetTempPath(), "rbx_geom.txt"); } }

    // ------------------------------------------------------------------ window
    static IntPtr FindRoblox()
    {
        foreach (var p in Process.GetProcessesByName("RobloxPlayerBeta"))
            if (p.MainWindowHandle != IntPtr.Zero) return p.MainWindowHandle;
        return IntPtr.Zero;
    }

    static IntPtr Focus()
    {
        IntPtr h = FindRoblox();
        if (h == IntPtr.Zero) throw new Exception("Roblox player window not found (is the game open?)");
        if (IsIconic(h)) ShowWindow(h, 9); // SW_RESTORE
        if (GetForegroundWindow() != h)
        {
            // Windows only lets the foreground app hand over focus: an Alt tap + thread attach is the usual way round it
            keybd_event(0x12, 0, 0, IntPtr.Zero);
            keybd_event(0x12, 0, KEYEVENTF_KEYUP, IntPtr.Zero);
            uint pid;
            uint fg = GetWindowThreadProcessId(GetForegroundWindow(), out pid);
            uint me = GetCurrentThreadId();
            AttachThreadInput(me, fg, true);
            BringWindowToTop(h);
            SetForegroundWindow(h);
            AttachThreadInput(me, fg, false);
            Thread.Sleep(150);
        }
        return h;
    }

    static Rectangle ClientScreenRect(IntPtr h)
    {
        RECT r; GetClientRect(h, out r);
        POINT p = new POINT { X = 0, Y = 0 }; ClientToScreen(h, ref p);
        return new Rectangle(p.X, p.Y, r.Right - r.Left, r.Bottom - r.Top);
    }

    // ------------------------------------------------------------------ screenshot (the game's client area only)
    static void Shot(string path, int maxWidth)
    {
        IntPtr h = Focus();
        Thread.Sleep(80);
        Rectangle rc = ClientScreenRect(h);
        if (rc.Width <= 0 || rc.Height <= 0) throw new Exception("Roblox window has no size (minimised?)");
        using (var full = new Bitmap(rc.Width, rc.Height))
        {
            using (var g = Graphics.FromImage(full)) g.CopyFromScreen(rc.Left, rc.Top, 0, 0, rc.Size);
            double scale = Math.Min(1.0, (double)maxWidth / rc.Width);
            int w = (int)Math.Round(rc.Width * scale), hh = (int)Math.Round(rc.Height * scale);
            using (var small = new Bitmap(w, hh))
            {
                using (var g = Graphics.FromImage(small))
                {
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.DrawImage(full, 0, 0, w, hh);
                }
                Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
                if (path.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase))
                {
                    var enc = Array.Find(ImageCodecInfo.GetImageEncoders(), c => c.MimeType == "image/jpeg");
                    var ps = new EncoderParameters(1); ps.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 85L);
                    small.Save(path, enc, ps);
                }
                else small.Save(path, ImageFormat.Png);
            }
            File.WriteAllText(GeomFile, string.Format(CultureInfo.InvariantCulture, "{0} {1} {2} {3} {4}", rc.Left, rc.Top, rc.Width, rc.Height, scale));
            Console.WriteLine(string.Format(CultureInfo.InvariantCulture, "shot {0} game={1}x{2} image={3}x{4} scale={5:0.###}", path, rc.Width, rc.Height, (int)Math.Round(rc.Width * scale), (int)Math.Round(rc.Height * scale), scale));
        }
    }

    // image pixel (from the last shot) -> screen pixel
    static Point ToScreen(double x, double y)
    {
        IntPtr h = FindRoblox();
        double scale = 1;
        Rectangle rc;
        if (File.Exists(GeomFile))
        {
            var p = File.ReadAllText(GeomFile).Split(' ');
            scale = double.Parse(p[4], CultureInfo.InvariantCulture);
        }
        rc = ClientScreenRect(h); // (the live window: it may have moved since the shot)
        return new Point(rc.Left + (int)Math.Round(x / scale), rc.Top + (int)Math.Round(y / scale));
    }

    // ------------------------------------------------------------------ input
    static void Send(params INPUT[] inputs) { SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT))); }

    static INPUT Mouse(uint flags, int dx = 0, int dy = 0, uint data = 0)
    {
        var i = new INPUT { type = INPUT_MOUSE };
        i.u.mi = new MOUSEINPUT { dx = dx, dy = dy, mouseData = data, dwFlags = flags };
        return i;
    }

    static readonly Dictionary<string, ushort> VK = new Dictionary<string, ushort>(StringComparer.OrdinalIgnoreCase)
    {
        {"space",0x20},{"enter",0x0D},{"return",0x0D},{"esc",0x1B},{"escape",0x1B},{"tab",0x09},{"backspace",0x08},
        {"shift",0x10},{"lshift",0xA0},{"ctrl",0x11},{"control",0x11},{"alt",0x12},
        {"left",0x25},{"up",0x26},{"right",0x27},{"down",0x28},{"pageup",0x21},{"pagedown",0x22},{"home",0x24},{"end",0x23},
        {"insert",0x2D},{"delete",0x2E},{"minus",0xBD},{"equals",0xBB},{"comma",0xBC},{"period",0xBE},{"slash",0xBF},
        {"backquote",0xC0},{"semicolon",0xBA},{"quote",0xDE},{"lbracket",0xDB},{"rbracket",0xDD},{"backslash",0xDC},
    };
    static readonly HashSet<ushort> Extended = new HashSet<ushort> { 0x25, 0x26, 0x27, 0x28, 0x21, 0x22, 0x24, 0x23, 0x2D, 0x2E };

    static ushort VkOf(string name)
    {
        ushort v;
        if (VK.TryGetValue(name, out v)) return v;
        if (name.Length == 1)
        {
            char c = char.ToUpperInvariant(name[0]);
            if ((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) return (ushort)c;
        }
        if (name.Length >= 2 && (name[0] == 'f' || name[0] == 'F'))
        {
            int n; if (int.TryParse(name.Substring(1), out n) && n >= 1 && n <= 12) return (ushort)(0x70 + n - 1);
        }
        throw new Exception("unknown key: " + name);
    }

    static INPUT Key(string name, bool up)
    {
        ushort vk = VkOf(name);
        ushort scan = (ushort)MapVirtualKey(vk, 0); // MAPVK_VK_TO_VSC
        uint flags = KEYEVENTF_SCANCODE | (up ? KEYEVENTF_KEYUP : 0) | (Extended.Contains(vk) ? KEYEVENTF_EXTENDEDKEY : 0);
        var i = new INPUT { type = INPUT_KEYBOARD };
        i.u.ki = new KEYBDINPUT { wVk = 0, wScan = scan, dwFlags = flags };
        return i;
    }

    static void KeysDown(string[] names) { foreach (var n in names) { Send(Key(n, false)); Thread.Sleep(15); } }
    static void KeysUp(string[] names) { for (int i = names.Length - 1; i >= 0; i--) { Send(Key(names[i], true)); Thread.Sleep(15); } }

    static uint DownFlag(string b) { return b == "right" ? RIGHTDOWN : b == "middle" ? MIDDLEDOWN : LEFTDOWN; }
    static uint UpFlag(string b) { return b == "right" ? RIGHTUP : b == "middle" ? MIDDLEUP : LEFTUP; }

    static void MoveTo(Point p)
    {
        SetCursorPos(p.X, p.Y);
        Thread.Sleep(20);
        // a tiny relative wiggle: Roblox UI registers hover from real mouse-move input, not only the cursor position
        Send(Mouse(MOUSEEVENTF_MOVE, 1, 0)); Thread.Sleep(15); Send(Mouse(MOUSEEVENTF_MOVE, -1, 0)); Thread.Sleep(25);
    }

    // relative move in small steps (games read the deltas)
    static void Rel(int dx, int dy, int ms)
    {
        int steps = Math.Max(1, ms / 10);
        int sx = 0, sy = 0;
        for (int i = 1; i <= steps; i++)
        {
            int tx = (int)Math.Round((double)dx * i / steps), ty = (int)Math.Round((double)dy * i / steps);
            Send(Mouse(MOUSEEVENTF_MOVE, tx - sx, ty - sy));
            sx = tx; sy = ty;
            Thread.Sleep(10);
        }
    }

    // ------------------------------------------------------------------ commands
    static int I(string s) { return int.Parse(s, CultureInfo.InvariantCulture); }
    static double D(string s) { return double.Parse(s, CultureInfo.InvariantCulture); }

    static void Run(string[] a)
    {
        string c = a[0].ToLowerInvariant();
        switch (c)
        {
            case "focus":
            {
                IntPtr h = Focus();
                Rectangle rc = ClientScreenRect(h);
                Console.WriteLine(string.Format("focus ok client={0},{1} {2}x{3} foreground={4}", rc.Left, rc.Top, rc.Width, rc.Height, GetForegroundWindow() == h));
                break;
            }
            case "shot": Shot(a.Length > 1 ? a[1] : Path.Combine(Path.GetTempPath(), "rbx.png"), a.Length > 2 ? I(a[2]) : 1280); break;
            case "zoom": // zoom X Y W H [path]: that part of the LAST shot at full detail (read small labels), up to 2x
            {
                Focus();
                Point tl = ToScreen(D(a[1]), D(a[2]));
                Point br = ToScreen(D(a[1]) + D(a[3]), D(a[2]) + D(a[4]));
                int w = Math.Max(8, br.X - tl.X), hh = Math.Max(8, br.Y - tl.Y);
                string path = a.Length > 5 ? a[5] : Path.Combine(Path.GetTempPath(), "rbx_zoom.png");
                using (var img = new Bitmap(w, hh))
                {
                    using (var g = Graphics.FromImage(img)) g.CopyFromScreen(tl.X, tl.Y, 0, 0, new Size(w, hh));
                    double up = Math.Min(2.0, Math.Max(1.0, 900.0 / w));
                    using (var big = new Bitmap((int)(w * up), (int)(hh * up)))
                    {
                        using (var g = Graphics.FromImage(big)) { g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.DrawImage(img, 0, 0, big.Width, big.Height); }
                        big.Save(path, ImageFormat.Png);
                    }
                }
                Console.WriteLine("zoom " + path + " (" + w + "x" + hh + " screen px)");
                break;
            }
            case "wait": Thread.Sleep(I(a[1])); break;
            case "key": // key <name[+name...]> [holdMs]   (tap, or hold; '+' = together, e.g. w+space)
            {
                Focus();
                var names = a[1].Split('+');
                int hold = a.Length > 2 ? I(a[2]) : 60;
                KeysDown(names); Thread.Sleep(hold); KeysUp(names);
                Console.WriteLine("key " + a[1] + " " + hold + "ms");
                break;
            }
            case "down": Focus(); KeysDown(a[1].Split('+')); Console.WriteLine("down " + a[1]); break;
            case "up": KeysUp(a[1].Split('+')); Console.WriteLine("up " + a[1]); break;
            case "type": // type <text>  (letters, digits and spaces only, sent as key taps)
            {
                Focus();
                string text = string.Join(" ", a, 1, a.Length - 1);
                foreach (char ch in text)
                {
                    string n = ch == ' ' ? "space" : ch.ToString();
                    KeysDown(new[] { n }); Thread.Sleep(30); KeysUp(new[] { n }); Thread.Sleep(30);
                }
                Console.WriteLine("typed " + text.Length + " chars");
                break;
            }
            case "move": Focus(); MoveTo(ToScreen(D(a[1]), D(a[2]))); Console.WriteLine("move ok"); break;
            case "click": // click X Y [left|right|middle] [holdMs]   (X, Y in last-shot pixels)
            {
                Focus();
                Point p = ToScreen(D(a[1]), D(a[2]));
                string b = a.Length > 3 ? a[3].ToLowerInvariant() : "left";
                int hold = a.Length > 4 ? I(a[4]) : 70;
                MoveTo(p);
                Send(Mouse(DownFlag(b))); Thread.Sleep(hold); Send(Mouse(UpFlag(b)));
                Console.WriteLine(string.Format("click {0} at screen {1},{2}", b, p.X, p.Y));
                break;
            }
            case "mdown": Focus(); Send(Mouse(DownFlag(a.Length > 1 ? a[1] : "left"))); Console.WriteLine("mdown"); break;
            case "mup": Send(Mouse(UpFlag(a.Length > 1 ? a[1] : "left"))); Console.WriteLine("mup"); break;
            case "rel": Focus(); Rel(I(a[1]), I(a[2]), a.Length > 3 ? I(a[3]) : 200); Console.WriteLine("rel ok"); break;
            case "turn": // turn dx [dy] [ms]: hold the right button and drag (Roblox camera); dx > 0 turns right
            {
                Focus();
                Send(Mouse(RIGHTDOWN)); Thread.Sleep(40);
                Rel(I(a[1]), a.Length > 2 ? I(a[2]) : 0, a.Length > 3 ? I(a[3]) : 300);
                Thread.Sleep(40); Send(Mouse(RIGHTUP));
                Console.WriteLine("turn ok");
                break;
            }
            case "scroll": // scroll n  (n > 0 = wheel up = zoom in in Roblox)
            {
                Focus();
                int n = I(a[1]);
                for (int i = 0; i < Math.Abs(n); i++) { Send(Mouse(WHEEL, 0, 0, (uint)(n > 0 ? 120 : -120))); Thread.Sleep(40); }
                Console.WriteLine("scroll " + n);
                break;
            }
            case "release": // let go of everything (safety)
            {
                foreach (var n in new[] { "w", "a", "s", "d", "space", "shift", "ctrl", "e", "q" }) Send(Key(n, true));
                Send(Mouse(LEFTUP)); Send(Mouse(RIGHTUP));
                Console.WriteLine("released");
                break;
            }
            default: throw new Exception("unknown command: " + c);
        }
    }

    static int Main(string[] args)
    {
        SetProcessDPIAware(); // physical pixels everywhere (Windows display scaling)
        string all = string.Join(" ", args);
        int code = 0;
        foreach (var part in all.Split(';'))
        {
            var cmd = part.Trim();
            if (cmd.Length == 0) continue;
            try { Run(cmd.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries)); }
            catch (Exception e) { Console.WriteLine("ERROR in '" + cmd + "': " + e.Message); code = 1; break; }
        }
        return code;
    }
}
