@echo off
rem Serves the SPEED ARC code folder so Studio can pull it (see README). Close this window when done.
cd /d "%~dp0"
python make_manifest.py
cd /d "%~dp0.."
python -m http.server 8765 --bind 127.0.0.1
