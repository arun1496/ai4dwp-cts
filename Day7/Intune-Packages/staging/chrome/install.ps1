Start-Process -FilePath "msiexec.exe" -ArgumentList '/i "googlechromestandaloneenterprise64.msi" /qn /norestart' -Wait -NoNewWindow
if ( -ne 0) { exit  }
exit 0
