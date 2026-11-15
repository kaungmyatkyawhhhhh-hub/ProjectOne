@echo off
cd /d "%~dp0"
(
echo == pip install ==
python -m pip install --upgrade numpy pillow piper-tts faster-whisper
echo == import check ==
python -c "import numpy, PIL, piper, faster_whisper; print('OK python packages', numpy.__version__, PIL.__version__)"
echo == node ==
node -v
echo == studio ==
cd /d "%USERPROFILE%\what-if-studio" && call npm ls remotion
) > "%~dp0check-log.txt" 2>&1
echo Done. You can close this window.
pause
