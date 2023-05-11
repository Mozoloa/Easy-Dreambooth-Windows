. "$PSScriptRoot\shared.ps1"

# Conda
function Install-Miniconda {
    $miniconda_installed = (Get-Command -ErrorAction SilentlyContinue conda) -ne $null

    if (!$miniconda_installed) {
        logger.action "Installing Miniconda"
        $url = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
        $output = "Miniconda3-latest-Windows-x86_64.exe"
        $install_path = "C:\Miniconda3"

        # Download the installer
        Invoke-WebRequest -Uri $url -OutFile $output

        # Install Miniconda silently
        Start-Process -FilePath ".\$output" -ArgumentList "/InstallationType=JustMe", "/AddToPath=1", "/RegisterPython=0", "/S", "/D=$install_path" -Wait -NoNewWindow

        # Remove the installer
        Remove-Item $output

        # Add Miniconda to the PATH environment variable
        $env:Path += ";$install_path"
        $env:Path += ";$install_path\Scripts"
        $env:Path += ";$install_path\Library\bin"
        [System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::User)
        return
    }
    $condaV = conda --version
    logger.info "Conda version : $condaV"
}
function Test-CondaInitialized {
    return $Env:CONDA_DEFAULT_ENV
}

function Test-EnvironmentExists ($envName) {
    $condaEnvs = conda env list
    return $condaEnvs -match $envName
}
function Get-EnvironmentHash ($filePath) {
    $hash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
    return $hash
}

function Save-EnvironmentHash ($filePath, $hash) {
    $hash | Out-File -FilePath $filePath -Force
}

function Enable-Conda {
    $envName = "easydreambooth"
    $envFile = "$dreamboothFolder\environment.yaml"
    $envHashFile = ".envhash"

    if (-not (Test-CondaInitialized)) {
        logger.action "Initiating Powershell"
        conda init powershell
    }
    else {
        logger.info "Powershell is in conda mode"
    }

    if (-not (Test-EnvironmentExists $envName)) {
        logger.action "Creating Conda environment '$envName', this can take a while..."
        conda env create --name $envName -f $envFile
        logger.success "Conda environment '$envName' created successfully."
    }

    $currentHash = Get-EnvironmentHash $envFile
    $savedHash = ""
    if (Test-Path $envHashFile) {
        $savedHash = Get-Content $envHashFile
    }

    if ($currentHash -ne $savedHash) {
        logger.action "Updating Conda environment '$envName', this can take a while..."
        conda env update --name $envName -f $envFile
        logger.success "Conda environment '$envName' updated successfully."
        Save-EnvironmentHash $envHashFile $currentHash
    }
    else {
        logger.info "The Conda environment '$envName' is up to date."
    }

    logger.action "Activating environment '$envName'"
    conda activate $envName
    if (-Not (conda list git -n $envName | Select-String 'git')) {
        conda install git -y
    }
}

function Import-DBGitHub {
    if (!(test-path $dreamboothFolder)) {
        Set-Location $InstallPath
        git clone https://github.com/JoePenna/Dreambooth-Stable-Diffusion
        Set-Location $launcherFolder
    }
}

function Update-DBGithub {
    if (!(test-path $dreamboothFolder)) {
        Import-DBGitHub
        return
    }
    Set-Location $InstallPath
    git pull https://github.com/JoePenna/Dreambooth-Stable-Diffusion 
    Set-Location $launcherFolder
}
# Setup Reg Images
Function Set-RegImages {
    param($class_word)
    $dataset = ""
    switch ($class_word) {
        "woman" { $dataset = "woman_ddim" }
        "man" { $dataset = "man_euler" }
        "person" { $dataset = "person_ddim" }
    }
    $reg_data_root = "$dreamboothFolder\regularization_images\$dataset"
    $gitRepoName = "Stable-Diffusion-Regularization-Images-$dataset"
    if (!(Test-Path $reg_data_root)) {
        if (!(Test-Path $gitLocation)) {
            New-Item -ItemType Directory -Path $gitLocation | Out-Null
        }
        Set-Location $gitLocation 
        logger.action "Downloading regularization images"
        git clone "https://github.com/djbielejeski/$gitRepoName.git"
        cd..
        logger.action "Creating regularization images folder and moving them"
        mkdir -p $reg_data_root
        Move-Item "$gitLocation/$gitRepoName/$dataset/*.*" $reg_data_root
        logger.action "Deleting images git"
        Remove-Item -Recurse -Force "$gitLocation/$gitRepoName"
    }
    else {
        logger.info "'$dataset' dataset already present on disk. No need for redownload"
    }
    return $reg_data_root
}
function Convert-PathToPython {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Path
    )

    # Replace backslashes with forward slashes
    $path = $Path.Replace('\', '/')

    # Add 'r' prefix to make the string a raw string
    <#     $path = 'r"' + $path + '"' #>

    return $path
}

Function Start-Training {
    param ($settings)

    # Remove checkpoints
    $leftover_training_files = @("$dreamboothFolder/training_images/.ipynb_checkpoints", "$dreamboothFolder/regularization_images/.ipynb_checkpoints")
    foreach ($file in $leftover_training_files) {
        Remove-Item -Recurse -Force $file -ErrorAction SilentlyContinue
    }

    # Build Python arguments
    $pythonArgs = @{
        'project_name'       = $settings.project_name
        'debug'              = $false
        'max_training_steps' = $settings.max_training_steps
        'token'              = $settings.token
        'training_model'     = $settings.training_model
        'training_images'    = $settings.training_images
        'flip_p'             = 0.5
        'save_every_x_steps' = $settings.save_every_x_steps
    }
    # Add regularization images to Python arguments if selected
    if ($settings.class_word -eq "none") {
        $reguMsg = "No regularization images"
        $settings.regularization_images = ""
    }
    else {
        $settings.regularization_images = Set-RegImages $settings.class_word
        $pythonArgs['regularization_images'] = $settings.regularization_images
        $pythonArgs['class_word'] = $settings.class_word
        $reguMsg = "Regularization of `"$($settings.class_word)`" with images from $($settings.regularization_images)"
    }
    # Log training start
    logger.pop "Training starts now"
    logger.info "Training project with the following parameters`nBase Model: $($settings.training_model) Project Name: $($settings.project_name) '$($settings.token) $($settings.class_word)'`nUsing images from $($settings.training_images)"
    logger.info $reguMsg
    
    # Build Python command
    $pythonCommand = 'python "main.py" '
    foreach ($arg in $pythonArgs.GetEnumerator()) {
        $value = $arg.Value
        if ($value -is [string]) {
            $value = "`"$value`""  # add quotemarks around the string value
        }
        $pythonCommand += "--$($arg.Key) $value "
    }

    # Print Python command
    logger.action "Launching python with:`n $pythonCommand"

    # Launch Python script
    Invoke-Expression $pythonCommand
}