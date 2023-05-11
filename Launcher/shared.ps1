Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName Microsoft.VisualBasic
Set-StrictMode -Version 2
Import-Module .\logger.psm1 -Force -Global -Prefix "logger."
. ".\EmpireUI\EmpireUI.ps1"

# General Variables
$InstallPath = (get-item $PSScriptRoot ).parent.FullName
$dreamboothFolder = "$InstallPath\Dreambooth-Stable-Diffusion"
$launcherFolder = "$InstallPath\launcher"
$settingsPath = "$launcherFolder\settings.json"
$tempFolder = (Get-Item -Path env:\temp).Value
$PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$gitLocation = "$dreamboothFolder\regularization_gits"
$trainedModelsDir = "$dreamboothFolder\trained_models"
$train = $false

$classes = @("none", "woman", "man", "person")

# Ui general variables
$backgroundColor = [System.Drawing.ColorTranslator]::FromHtml("#000000")
$accentColor = [System.Drawing.ColorTranslator]::FromHtml("#ff9e36")
$primaryColor = [System.Drawing.ColorTranslator]::FromHtml("#1c0f01")
$secondaryColor = [System.Drawing.ColorTranslator]::FromHtml("#999999")
$buttonColor = [System.Drawing.ColorTranslator]::FromHtml("#111111")
$style = [System.Windows.Forms.FlatStyle]::Flat

