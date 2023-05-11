$ScriptPath = (Get-Item -Path "./UI.ps1" -Verbose).FullName
$ShortcutPath = (Join-Path -Path (Get-Location) -ChildPath "EasyDreamboothUI.lnk")
$IconPath = (Get-Item -Path "./media/ShortcutIcon.ico" -Verbose).FullName
$WScriptShell = New-Object -ComObject WScript.Shell

If (Test-Path $ShortcutPath) {
        Remove-Item $ShortcutPath
}

$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`""
$Shortcut.IconLocation = $IconPath
$Shortcut.WindowStyle = 1
$Shortcut.Description = "EasyDreamboothUI"
$Shortcut.WorkingDirectory = (Get-Location).Path
$Shortcut.Save()

$Shell = New-Object -ComObject Shell.Application
$Shell.Namespace(7).ParseName($ShortcutPath).InvokeVerb("taskbarpin")