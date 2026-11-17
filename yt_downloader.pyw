# YouTube downloader: a small window around yt-dlp (already installed via winget, with ffmpeg).
import subprocess, threading, tkinter as tk
from pathlib import Path
from tkinter import filedialog, scrolledtext

def build_cmd(url, folder, audio_only):
    # --no-playlist: a watch link from a mix/playlist gets just that video; a playlist?list= link still gets all
    cmd = ["yt-dlp", "--newline", "--no-playlist", "-P", folder, "-o", "%(title)s.%(ext)s"]
    cmd += ["-x", "--audio-format", "mp3"] if audio_only else ["-f", "bv*+ba/b", "--merge-output-format", "mp4"]
    return cmd + ["--", url]  # "--" so a URL can never be read as an option

def download():
    url = url_var.get().strip()
    if not url:
        return log("Paste a link first.\n")
    btn.config(state="disabled")
    def run():
        p = subprocess.Popen(build_cmd(url, folder_var.get(), audio_var.get()), stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, text=True, creationflags=subprocess.CREATE_NO_WINDOW)
        for line in p.stdout:
            root.after(0, log, line)
        root.after(0, log, "Done.\n" if p.wait() == 0 else "Failed (see above).\n")
        root.after(0, lambda: btn.config(state="normal"))
    threading.Thread(target=run, daemon=True).start()

def log(text):
    out.insert("end", text); out.see("end")

if __name__ == "__main__":
    assert build_cmd("u", "d", True)[-3:] == ["mp3", "--", "u"]
    assert build_cmd("-x", "d", False)[-2:] == ["--", "-x"]

    root = tk.Tk(); root.title("YouTube Downloader")
    url_var = tk.StringVar(); folder_var = tk.StringVar(value=str(Path.home() / "Downloads")); audio_var = tk.BooleanVar()
    tk.Label(root, text="Link:").grid(row=0, column=0, sticky="w", padx=6, pady=4)
    tk.Entry(root, textvariable=url_var, width=60).grid(row=0, column=1, columnspan=2, sticky="we", padx=6)
    tk.Label(root, text="Save to:").grid(row=1, column=0, sticky="w", padx=6)
    tk.Entry(root, textvariable=folder_var, width=50).grid(row=1, column=1, sticky="we", padx=6)
    tk.Button(root, text="Browse", command=lambda: folder_var.set(filedialog.askdirectory() or folder_var.get())).grid(row=1, column=2, padx=6)
    tk.Checkbutton(root, text="Audio only (mp3)", variable=audio_var).grid(row=2, column=1, sticky="w", padx=6)
    btn = tk.Button(root, text="Download", command=download); btn.grid(row=2, column=2, padx=6, pady=4)
    out = scrolledtext.ScrolledText(root, height=15, width=80); out.grid(row=3, column=0, columnspan=3, padx=6, pady=6)
    root.mainloop()
