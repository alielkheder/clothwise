@echo off
echo Adding Windows Firewall rules for ngrok...
echo.

netsh advfirewall firewall add rule name="ngrok Inbound" dir=in action=allow program="C:\Users\yassi\Downloads\ngrok.exe" enable=yes

netsh advfirewall firewall add rule name="ngrok Outbound" dir=out action=allow program="C:\Users\yassi\Downloads\ngrok.exe" enable=yes

echo.
echo Firewall rules added successfully!
echo Press any key to close...
pause > nul
