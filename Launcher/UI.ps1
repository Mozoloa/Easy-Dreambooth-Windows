Write-Output $PSScriptRoot
Import-Module .\Functions.psm1 -Force
. ".\shared.ps1"

# Env Setup
Install-Miniconda
Enable-Conda
Import-DBGitHub

$settings = @{
    project_name          = ""
    training_model        = ""
    training_images       = ""
    max_training_steps    = 1500
    regularization_images = ""
    token                 = ""
    class_word            = ""
    save_every_x_steps    = 0
}

function Update-Settings {
    param (
        $form
    )
    
    #Project Name
    $project_name = (Find-Control $form "project_name").text
    $settings.project_name = if ($project_name) {
        (Find-Control $form "project_name").Text.Replace(' ', '_').ToLower()
    }
    else {
        'UntitledProject'
    }

    #Token
    $token = (Find-Control $form "token").text
    $settings.token = if ($token) {
    (Find-Control $form "token").Text
    }
    else {
        "sks"
    }

    #Class
    $class_word = (Find-Control $form "class_word").SelectedIndex
    $settings.class_word = $classes[$class_word]

    #Regu
    <#     $use_reg_images = (Find-Control $form "use_reg_images").Checked
    $settings.use_reg_images = $use_reg_images #>

    #max_training_steps
    $max_training_steps = (Find-Control $form "max_training_steps").text
    $settings.max_training_steps = if ($max_training_steps) {
        $max_training_steps
    }
    else {
        1500
    }
    logger.info "Settings :`n$($settings | ConvertTo-Json -Depth 4)"
}

# General Options
$ValidateScript = {
    Update-Settings $MainForm
    $Global:train = $true
    $MainForm.Dispose()
}

$MainForm = New-MainForm `
    -Header `
    -HeaderImage ".\media\Title.png" `
    -TopBar `
    -Validate "Train" `
    -ValidateScript $ValidateScript

$projectNameInputBox = New-MainInputBox `
    -text "Project Name" `
    -type "Input" `
    -name "project_name" `
    -help { Open-Link -link "https://github.com/Mozoloa/Easy-Dreambooth-Windows#-project-name" } `

$tokenInputBox = New-MainInputBox `
    -text "Celebrity Doppleganger (token)" `
    -type "Input" `
    -name "token" `
    -help { Open-Link -link "https://github.com/Mozoloa/Easy-Dreambooth-Windows#-celebrity-doppleganger" } `

$TraininStepsBox = New-MainInputBox `
    -text "Training Steps" `
    -type "Int" `
    -name "max_training_steps" `
    -default 1500 `
    -help { Open-Link -link "https://github.com/Mozoloa/Easy-Dreambooth-Windows#-training-steps" } `

$classCombo = New-MainInputBox `
    -text "Class" `
    -name "class_word" `
    -type "Combo" `
    -list $classes `
    -help { Open-Link -link "https://github.com/Mozoloa/Easy-Dreambooth-Windows#-class" } 

$reguCheckbox = New-InlineCheckbox `
    -text "Use Regularization images" `
    -name "use_reg_images" `
    -list $classes `
    -help { Open-Link -link "https://github.com/Mozoloa/Easy-Dreambooth-Windows#-class" } `

$ModelBrowse = New-MainBrowse `
    -text "Base Model" `
    -name "modelBrowse" `
    -browseAction {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Checkpoint files (*.ckpt)|*.ckpt"
    $openFileDialog.Title = "Select a checkpoint file"
    if ($openFileDialog.ShowDialog() -eq 'OK') {
        $Global:settings.training_model = $openFileDialog.FileName
        $browseText = Find-Control $MainForm "modelBrowseText"
        $browseText.Text = Get-ShortenedPath $Global:settings.training_model 40
        $browseText.Refresh()
    } } `

$TrainingImagesBrowse = New-MainBrowse `
    -text "Training Images" `
    -name "trainingImagesBrowse" `
    -browseAction {
    $openFolderDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFolderDialog.Title = "Select a folder"
    $openFolderDialog.ValidateNames = $false
    $openFolderDialog.CheckFileExists = $false
    $openFolderDialog.CheckPathExists = $true
    $openFolderDialog.Filter = "Folder Selection|*.folder"
    $openFolderDialog.FileName = "Select Folder"
        
    if ($openFolderDialog.ShowDialog() -eq 'OK') {
        $selectedFolder = [System.IO.Path]::GetDirectoryName($openFolderDialog.FileName)
        $Global:settings.training_images = $selectedFolder
        $browseText = Find-Control $MainForm "trainingImagesBrowseText"
        $browseText.Text = Get-ShortenedPath $Global:settings.training_images 40
        $browseText.Refresh()
    } } `
    -path $settings.training_model `
    -help { Open-Link -link "https://github.com/Mozoloa/Easy-Dreambooth-Windows#-the-training-images" }


$MainForm.Controls["main"].Controls.Add($TraininStepsBox)
$MainForm.Controls["main"].Controls.Add($ModelBrowse)
<# $MainForm.Controls["main"].Controls.Add($reguCheckbox) #>
$MainForm.Controls["main"].Controls.Add($classCombo)
$MainForm.Controls["main"].Controls.Add($tokenInputBox)
$MainForm.Controls["main"].Controls.Add($TrainingImagesBrowse)
$MainForm.Controls["main"].Controls.Add($projectNameInputBox)

logger.pop "UI Starting"
$MainForm.ShowDialog()

if ($Global:train -eq $true) {
    Start-Training $settings
    Read-Host "Press any key to continue..."
    if (Test-Path $trainedModelsDir) {
        Invoke-Item $trainedModelsDir
    }
}