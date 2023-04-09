. "$PSScriptRoot\shared.ps1"

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