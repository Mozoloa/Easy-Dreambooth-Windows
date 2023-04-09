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
<# Init-Conda
 #>
$settings = @{
    project_name       = "LeoMozoloa"
    training_model     = "G:\AI\Training\Dreambooth\1.5-NewVAE.ckpt"
    training_images    = "G:\AI\Training\Datasets\Mozoloa\training_images"
    max_training_steps = 10
    token              = "matthewdelnegro"
    class_word         = "man"
    save_every_x_steps = 0
}

# General Options

$ValidateScript = { 
    Start-Training $settings
}

$MainForm = New-MainForm -Header -HeaderImage ".\ui-files\media\Title.png" -TopBar -Validate "Train" -ValidateScript $ValidateScript

$projectInputBox = New-MainInputBox -text "Project Name" -type "Input" -name "projectName"

$CelebrityInputBox = New-MainInputBox -text "Celebrity Doppleganger" -type "Input" -name "token"

$ModelBrowse = New-MainBrowseToFolder -text "Base Model" -name "modelBrowse" -help { Open-Link -link "https://google.com" } -browseAction { Open-Link -link "https://google.com" } -path $settings.training_model

<# $classCombo = New-MainInputBox -text "Regularization Images" -type "Combo" -list $datasets #>

<# $MainArea.Controls.Add($classCombo) #>

$MainForm.Controls["main"].Controls.Add($CelebrityInputBox)
$MainForm.Controls["main"].Controls.Add($ModelBrowse)
$MainForm.Controls["main"].Controls.Add($projectInputBox)

logger.pop "UI Starting"
$MainForm.ShowDialog()
$MainForm.Dispose()

