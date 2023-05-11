# Init libraries

Add-Type -AssemblyName System.Windows.Forms

#Settings (later, put this in some json as a theme)

$Theme = [PSCustomObject]@{
    MainBGColor          = "#111111"
    SecondaryBGColor     = "#000000"
    MainAccentColor      = "#FFBB00"
    MainTextColor        = "#EEEEEE"
    SecondaryTextColor   = "#909090"
    MainButtonColor      = "#252525"
    MainHoverButtonColor = "#353535"
    MainDownButtonColor  = "#151515"
}

# Converting Theme Colors

foreach ($property in $Theme.PSObject.Properties) {
    $key = $property.Name
    $value = $property.Value
    if ($key -ilike "*Color") {
        $Theme.$key = [System.Drawing.ColorTranslator]::FromHtml($value)
    }
}

Function New-MainForm {
    param(
        $Size,
        [String]$Title,
        [switch]$Header,
        $HeaderImage,
        [switch]$TopBar,
        [switch]$Settings,
        [String]$Validate,
        [scriptblock]$ValidateScript,
        [switch]$Cancel
    )

    # Create a new form object
    $Form = New-Object System.Windows.Forms.Form
    $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    # Font
    $Form.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 10, [System.Drawing.FontStyle]::Regular)
    # Geo
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $form.StartPosition = "CenterScreen"
    $form.AutoSize = $True
    # Appearance
    $form.ControlBox = $false
    $form.AllowTransparency = $true
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    <#     $form.add_Load({ $form.Region = New-Object System.Drawing.Region(New-RoundedRectangle $form.size 40) })
 #>
    # Colors
    $form.BackColor = $Theme.MainBGColor
    $form.ForeColor = $Theme.MainAccentColor

    # Top Bar
    $topBarPanel = New-Object System.Windows.Forms.Panel
    $topBarPanel.Height = 20
    $topBarPanel.Dock = "Top"
    $topBarPanel.Name = "Topbar"
    $topBarPanel.Padding = 4

    # Title
    
    $TitleText = New-Object System.Windows.Forms.Label
    $TitleText.Text = $Title
    $TitleText.Location = "3,2"
    $TitleText.ForeColor = $Theme.SecondaryTextColor
    $TitleText.Height = "15"

    if ($Title) {
        $form.Controls.Add($TitleText)
    }
    #Exit X
    $exitBTNImg = Get-ImgFromFile "$PSScriptRoot\Media\Nav\Exit.png"
    $exitBTN = New-Object System.Windows.Forms.PictureBox
    $exitBTN.Image = $exitBTNImg
    $exitBTN.SizeMode = "Zoom"
    $exitBTN.Size = "15,11"
    $exitBTN.Dock = "Right"
    $exitBTN.add_click({ 
            param($sender)
            $sender.Parent.Parent.Close()
        })
    
    #Settings
    if ($Settings) {

        $settingsBTNImg = Get-ImgFromFile "$PSScriptRoot\Media\Nav\Settings.png"
        $settingsBTN = New-Object System.Windows.Forms.PictureBox
        $settingsBTN.Name = "settingsBTN"
        $settingsBTN.Image = $settingsBTNImg
        $settingsBTN.SizeMode = "Zoom"
        $settingsBTN.Size = "20,15"
        $settingsBTN.Dock = "Right"
    
        $topBarPanel.Controls.Add($settingsBTN)
    }

    $topBarPanel.Controls.Add($exitBTN)

    #Header
    if ($Header) {
        $headerSpace = New-Object System.Windows.Forms.Panel
        $headerSpace.dock = "Top"
        $headerSpace.size = "1000,100"

        if ($HeaderImage) {
            $HeaderImage = Get-ImgFromFile $HeaderImage
            $HeaderImg = new-object Windows.Forms.PictureBox
            $HeaderImg.Image = $HeaderImage
            $HeaderImg.Dock = "Fill"
            $HeaderImg.SizeMode = "Zoom"
            $headerSpace.Controls.add($HeaderImg)
            
        }
        $form.Controls.Add($headerSpace)
    }

    # Main Area
    $mainArea = New-Object System.Windows.Forms.Panel
    $mainArea.Name = "main"
    $mainArea.Padding = "20,10,20,30"
    $mainArea.Dock = "bottom"
    $mainArea.AutoSize = $True
    $mainArea.BackColor = $theme.SecondaryBGColor

    #Cancel Button
    if ($TopBar) {
        $form.Controls.Add($topBarPanel)
    }

    $form.Controls.Add($mainArea)

    if ($Validate) {
        # Validate Aera
        $ValidateArea = New-Object System.Windows.Forms.Panel
        $ValidateArea.Name = "ValidateArea"
        $ValidateArea.AutoSize = $true
        $ValidateArea.Dock = "Bottom"
        $ValidateArea.Padding = "20,10,20,20"

        #Validate Button

        $ValidateBTN = New-MainButton -Text $Validate -Main -OnButtonClick $ValidateScript -name "validate"
        $ValidateBTN.dock = "Top"
        $ValidateArea.Controls.Add($ValidateBTN)

        $form.Controls.Add($ValidateArea)

        if ($Cancel) {
            $cancelBTN = New-MainButton -Text "CANCEL" -Dock "Bottom"
            $cancelBTN.Controls["Button"].add_click({ param($sender)
                    $sender.Parent.Parent.Parent.Close() })
            $ValidateArea.Controls.Add($cancelBTN)
        }
    }
    
    # Return the form
    return $Form
}

Function New-MainButton {
    param(
        $Text,
        [switch]$Main,
        [scriptblock]$OnButtonClick,
        [string]$name
    )
    #Container
    $ButtonContainer = New-Object System.Windows.Forms.Panel
    $ButtonContainer.AutoSize = $true
    $ButtonContainer.Padding = 5
    #Button
    $Button = New-Object System.Windows.Forms.Button
    $Button.Name = $name
    # Geo
    $Button.Dock = "Top"
    $Button.AutoSize = $true
    # Appearance
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Button.FlatAppearance.BorderSize = 0
    # Text
    $Button.Text = $Text
    # Colors
    $Button.ForeColor = $Theme.SecondaryTextColor 
    if ($Main) { $Button.ForeColor = $Theme.MainAccentColor }
    $Button.BackColor = $Theme.MainButtonColor 
    #Hover behaviour
    $Button.Add_MouseEnter({ $this.BackColor = $Theme.MainHoverButtonColor })
    $Button.Add_MouseLeave({ $this.BackColor = $Theme.MainButtonColor })
    $Button.Add_MouseDown({ $this.BackColor = $Theme.MainDownButtonColor })
    $Button.Add_MouseUp({ $this.BackColor = $Theme.MainHoverButtonColor })
    $button.Add_Click($OnButtonClick)

    $ButtonContainer.Controls.Add($Button)
    return $ButtonContainer
}
Function New-ControlHeader {
    param(
        [String]$text,
        $help
    )
    $inputBoxField = New-Object System.Windows.Forms.Panel
    $inputBoxField.AutoSize = $true
    $inputBoxField.Dock = "Top"
    $inputBoxField.Padding = "0,10,0,0"

    $inputBoxText = New-Object System.Windows.Forms.Label
    $inputBoxText.Text = $text
    $inputBoxText.ForeColor = $Theme.MainAccentColor
    $inputBoxText.Dock = "Top"

    $helpBTN = New-Object System.Windows.Forms.Button
    $helpBTN.text = "?"
    $helpBTN.size = "20,10"
    $helpBTN.Dock = "Right"
    $helpBTN.BackColor = $Theme.MainBGColor
    $helpBTN.ForeColor = $Theme.SecondaryTextColor
    $helpBTN.Add_Click($help)

    $inputBoxField.Controls.Add($inputBoxText)
    $inputBoxField.Controls.Add($helpBTN)
    return $inputBoxField
}
Function New-MainInputBox {
    param(
        [String]$type,
        [String]$text,
        $list,
        [string]$name,
        $help,
        $default
    )
    $inputBoxField = New-ControlHeader $text $help

    switch ($type) {
        'Combo' {
            $InputBox = New-Object System.Windows.Forms.ComboBox
            $InputBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
            if ($list) {
                $InputBox.Items.AddRange($list)
                $InputBox.SelectedIndex = 0
            }
            break
        }
        'Input' {
            $InputBox = New-Object System.Windows.Forms.TextBox
            break
        }
        'Int' {
            $InputBox = New-Object System.Windows.Forms.NumericUpDown
            $InputBox.Maximum = 2147483647
            $InputBox.Minimum = 0
            break
        }
    }
    if ($default) {
        $inputBox.Text = $default
    }
    $InputBox.BackColor = $Theme.MainBGColor
    $InputBox.ForeColor = $Theme.MainTextColor
    $InputBox.Dock = "Bottom"
    $inputBox.Name = $name
    $inputBoxField.Controls.AddRange(@($InputBox))
    return $inputBoxField
}

function New-MainBrowseToFolder {
    param(
        [String]$type,
        [String]$text,
        $list,
        [string]$name,
        $help,
        [scriptblock]$browseAction,
        $path
    )
    $inputBoxField = New-ControlHeader $text $help

    $browseBox = New-Object System.Windows.Forms.Panel
    $browseBox.Dock = "Bottom"
    $browseBox.AutoSize = $true
    $browseBox.Name = ""

    $browseBTN = New-MainButton -Text "Browse" -name $name -OnButtonClick $browseAction
    $browseBTN.Anchor = "Right"
    $browseBTN.dock = "Top"
    $browseBTN.size = "70,10"
    $browseBTN.Padding = 0

    $browseText = New-Object System.Windows.Forms.Label
    $browseText.Anchor = "Left"
    $browseText.Name = $name + "Text"
    $browseText.Dock = "Top"
    $browseText.Text = "No model selected"
    if ($path) {
        $browseText.Text = Get-ShortenedPath $path 40
    }

    $browseText.ForeColor = $Theme.SecondaryTextColor

    $browseBox.Controls.Add($browseText)
    $browseBox.Controls.Add($browseBTN)
    $inputBoxField.Controls.Add($browseBox)
    return $inputBoxField

}

function New-InlineCheckbox {
    param(
        [String]$text,
        [Boolean]$checked,
        [String]$name
    )
    $inputBoxField = New-Object System.Windows.Forms.Panel
    $inputBoxField.AutoSize = $true
    $inputBoxField.Dock = "Top"
    $inputBoxField.Padding = "0,10,0,0"

    $inputBoxText = New-Object System.Windows.Forms.Label
    $inputBoxText.Text = $text
    $inputBoxText.ForeColor = $Theme.MainTextColor
    $inputBoxText.Dock = "Top"

    $CheckBox = New-Object System.Windows.Forms.CheckBox
    $CheckBox.size = "20,10"
    $CheckBox.Dock = "Right"
    $CheckBox.Name = $name
    $CheckBox.BackColor = $Theme.MainBGColor
    $CheckBox.ForeColor = $Theme.SecondaryTextColor

    $inputBoxField.Controls.Add($inputBoxText)
    $inputBoxField.Controls.Add($CheckBox)
    return $inputBoxField

}

function New-MainBrowse {
    param(
        [String]$type,
        [String]$text,
        $list,
        [string]$name,
        $help,
        [scriptblock]$browseAction,
        $path
    )
    $inputBoxField = New-ControlHeader $text $help

    $browseBox = New-Object System.Windows.Forms.Panel
    $browseBox.Dock = "Bottom"
    $browseBox.AutoSize = $true
    $browseBox.Name = ""

    $browseBTN = New-MainButton -Text "Browse" -name $name -OnButtonClick $browseAction
    $browseBTN.Anchor = "Right"
    $browseBTN.dock = "Top"
    $browseBTN.size = "70,10"
    $browseBTN.Padding = 0

    $browseText = New-Object System.Windows.Forms.Label
    $browseText.Anchor = "Left"
    $browseText.Name = $name + "Text"
    $browseText.Dock = "Top"
    $browseText.Text = "No model selected"
    if ($path) {
        $browseText.Text = Get-ShortenedPath $path 40
    }

    $browseText.ForeColor = $Theme.SecondaryTextColor

    $browseBox.Controls.Add($browseText)
    $browseBox.Controls.Add($browseBTN)
    $inputBoxField.Controls.Add($browseBox)
    return $inputBoxField

}

#Utils
Function New-RoundedRectangle ($size, $cornerRadius) {
    $rect = New-Object System.Drawing.Rectangle(0, 0, $size.Width, $size.Height)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($rect.X, $rect.Y, $cornerRadius, $cornerRadius, 180, 90)
    $path.AddArc($rect.X + $rect.Width - $cornerRadius, $rect.Y, $cornerRadius, $cornerRadius, 270, 90)
    $path.AddArc($rect.X + $rect.Width - $cornerRadius, $rect.Y + $rect.Height - $cornerRadius, $cornerRadius, $cornerRadius, 0, 90)
    $path.AddArc($rect.X, $rect.Y + $rect.Height - $cornerRadius, $cornerRadius, $cornerRadius, 90, 90)
    $path.CloseAllFigures()
    return $path
}

function Get-ImgFromFile ($path) {
    return [System.Drawing.Image]::Fromfile((get-item $path))
}
function Get-ShortenedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [int]$MaxLength
    )

    if ($Path.Length -le $MaxLength) {
        return $Path
    }

    $start = $Path.Substring(0, $MaxLength / 2 - 2)
    $end = $Path.Substring($Path.Length - $MaxLength / 2 + 2)
    return $start + "..." + $end
}
function Open-Link {
    param (
        [string]$link
    )
    Start-Process $link -Verb Open
}

function Find-Control($ParentControl, $ControlName) {
    foreach ($ChildControl in $ParentControl.Controls) {
        if ($ChildControl.Name -eq $ControlName) {
            return $ChildControl
        }
        elseif ($ChildControl.Controls.Count -gt 0) {
            $FoundControl = Find-Control -ParentControl $ChildControl -ControlName $ControlName
            if ($FoundControl) {
                return $FoundControl
            }
        }
    }
    return $null
}