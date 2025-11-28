@echo off
echo Adding ngrok to Windows Defender exclusions...
echo.

powershell -Command "Add-MpPreference -ExclusionPath 'C:\Users\yassi\Downloads\ngrok.exe'"

echo.
echo ngrok added to Windows Defender exclusions!
echo.
echo Press any key to close...
pause > nul
