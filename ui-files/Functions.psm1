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
    $reg_data_root = ".\regularization_images\$dataset"
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

function Find-ControlByName {
    param(
        [System.Windows.Forms.Control]$ParentControl,
        [string]$ControlName
    )

    foreach ($control in $ParentControl.Controls) {
        if ($control.Name -eq $ControlName) {
            return $control
        }
        elseif ($control.HasChildren) {
            $result = Find-ControlByName -ParentControl $control -ControlName $ControlName
            if ($null -ne $result) {
                return $result
            }
        }
    }
    return $null
}
function Convert-PathToPython {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Replace backslashes with forward slashes
    $path = $Path.Replace('\', '/')

    # Add 'r' prefix to make the string a raw string
    <#     $path = 'r"' + $path + '"' #>

    return $path
}
Function Start-Training {
    param (
        $settings
    )
    Remove-Item -Recurse -Force "$($settings.training_images)\.ipynb_checkpoints" -ErrorAction SilentlyContinue
    $regularization_images = Set-RegImages $settings.class_word
    logger.pop "Training starts now"
    logger.info "Training project with the following parameters`nBase Model: $($settings.training_model) Project Name: $($settings.project_name) '$($settings.token) $($settings.class_word)'`nUsing images from $($settings.training_images)"
    
    if ($regularization_images) {
        logger.info "Regularisation images from $regularization_images"
        <#     python "main.py" `
            --base "configs/stable-diffusion/v1-finetune_unfrozen.yaml" `
            -t `
            --actual_resume $(Convert-PathToPython($settings.model_path)) `
            --regularization_images $(Convert-PathToPython($regularization_images)) `
            -n $($settings.projectName) `
            --gpus 1 `
            --data_root "$(Convert-PathToPython($settings.data_root))" `
            --max_training_steps $($settings.max_training_steps) `
            --class_word $($settings.class_word) `
            --token $($settings.token) `
            --no-test `
            --flip_p 0.5 `
            --save_every_x_steps $($settings.save_every_x_steps) #>
            
        python "main.py" `
            --project_name "Leo" `
            --debug False `
            --max_training_steps 1500 `
            --token "matthewdelnegro" `
            --training_model "G:\AI\Training\Dreambooth\1.5-NewVAE.ckpt" `
            --training_images "G:\AI\Training\Datasets\Mozoloa\training_images" `
            --regularization_images "E:\Professional\Empire Media Science\Projects\AI\Easy-Dreambooth-Windows\regularization_images\man_euler" `
            --class_word "man" `
            --flip_p 0.5 `
            --save_every_x_steps 0
        
    }
    else {
        logger.info "No regularisation images"
        python "main.py" `
            --base "configs/stable-diffusion/v1-finetune_unfrozen.yaml" `
            -t `
            --actual_resume $(Convert-PathToPython($settings.model_path)) `
            -n $($settings.projectName) `
            --gpus 1 `
            --data_root "$(Convert-PathToPython($settings.data_root))" `
            --max_training_steps $($settings.max_training_steps) `
            --class_word $($settings.class_word) `
            --token $($settings.token) `
            --no-test `
            --flip_p 0.5 `
            --save_every_x_steps $($settings.save_every_x_steps)
    }
}

