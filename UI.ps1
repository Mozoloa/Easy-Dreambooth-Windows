Set-Location $PSScriptRoot
Import-Module .\ui-files\Functions.psm1 -Force
. ".\ui-files\shared.ps1"

# Env Setup
function Init-Conda {
    if (!$Env:CONDA_DEFAULT_ENV) {
        logger.action "Initiating Powershell"
        conda init powershell
    }
    else {
        logger.info "Powershell is in conda mode"
    }
    $envName = "easydreambooth"
    $condaEnvs = conda env list
    if ($condaEnvs -match $envName) {
        logger.info "The Conda environment '$envName' already exists."
    }
    else {
        logger.action "Creating Conda environment '$envName', this can take a while..."
        conda env create --name $envName -f environment.yaml
        logger.success "Conda environment '$envName' created successfully."
    }
    logger.action "Activating environment '$envName'"
    conda activate $envName
}
Init-Conda

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
    (Find-Control $form "token").Text.Trim().ToLower().Replace(" ", "")
    }
    else {
        "sks"
    }

    #Class
    $class_word = (Find-Control $form "class_word").SelectedIndex
    $settings.class_word = $classes[$class_word]

    #max_training_steps
    $max_training_steps = (Find-Control $form "max_training_steps").text
    $settings.max_training_steps = if (!$max_training_steps) {
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
    <#  $MainForm.Dispose() #>
}

$MainForm = New-MainForm `
    -Header `
    -HeaderImage ".\ui-files\media\Title.png" `
    -TopBar `
    -Validate "Train" `
    -ValidateScript $ValidateScript

$projectNameInputBox = New-MainInputBox `
    -text "Project Name" `
    -type "Input" `
    -name "project_name"

$tokenInputBox = New-MainInputBox `
    -text "Celebrity Doppleganger (token)" `
    -type "Input" `
    -name "token"

$TraininStepsBox = New-MainInputBox `
    -text "Training Steps" `
    -type "Int" `
    -name "max_training_steps" `
    -default 1500

$classCombo = New-MainInputBox `
    -text "Regularization Images" `
    -name "class_word" `
    -type "Combo" `
    -list $classes


$ModelBrowse = New-MainBrowse `
    -text "Base Model" `
    -name "modelBrowse" `
    -help { Open-Link -link "https://google.com" } `
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
    -path $settings.training_model

$TrainingImagesBrowse = New-MainBrowse `
    -text "Training Images" `
    -name "trainingImagesBrowse" `
    -help { Open-Link -link "https://google.com" } `
    -browseAction {
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.Description = "Select a folder"
    if ($folderBrowserDialog.ShowDialog() -eq 'OK') {
        $Global:settings.training_images = $folderBrowserDialog.SelectedPath
        $browseText = Find-Control $MainForm "trainingImagesBrowseText"
        $browseText.Text = Get-ShortenedPath $Global:settings.training_images 40
        $browseText.Refresh()
    } } `
    -path $settings.training_model


$MainForm.Controls["main"].Controls.Add($TraininStepsBox)
$MainForm.Controls["main"].Controls.Add($TrainingImagesBrowse)
$MainForm.Controls["main"].Controls.Add($classCombo)
$MainForm.Controls["main"].Controls.Add($tokenInputBox)
$MainForm.Controls["main"].Controls.Add($ModelBrowse)
$MainForm.Controls["main"].Controls.Add($projectNameInputBox)

logger.pop "UI Starting"
$MainForm.ShowDialog()

<# if ($Global:train -eq $true) {
    Start-Training $settings
    if (Test-Path $trainedModelsDir) {
        Invoke-Item $trainedModelsDir
    }
} #>