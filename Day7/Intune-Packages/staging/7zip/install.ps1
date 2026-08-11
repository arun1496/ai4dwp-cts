Start-Process -FilePath "msiexec.exe" -ArgumentList '/i "7z2602-x64.msi" /qn /norestart' -Wait -NoNewWindow
if ( -ne 0) { exit  }
exit 0
