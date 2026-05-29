Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$IniFile = Join-Path $PSScriptRoot "iperf_profiles.ini"


# Win32 API for textbox placeholder text
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, string lParam);
    public const int EM_SETCUEBANNER = 0x1501;
}
"@ -Language CSharp

function Set-Placeholder {
    param([System.Windows.Forms.TextBox]$tb, [string]$hint)
    [WinAPI]::SendMessage($tb.Handle, [WinAPI]::EM_SETCUEBANNER, [IntPtr]::Zero, $hint) | Out-Null
}

# All known parameter keys - always written to INI
$AllKeys = @("host","port","protocol","direction","bitrate","duration","interval","buflen","streams","window","extra")

$C = @{
    Bg        = [System.Drawing.Color]::FromArgb(22,  22,  32)
    Panel     = [System.Drawing.Color]::FromArgb(30,  30,  44)
    Card      = [System.Drawing.Color]::FromArgb(38,  38,  54)
    Border    = [System.Drawing.Color]::FromArgb(60,  60,  85)
    Text      = [System.Drawing.Color]::FromArgb(210, 210, 225)
    TextDim   = [System.Drawing.Color]::FromArgb(110, 110, 140)
    TextDark  = [System.Drawing.Color]::FromArgb(20,  20,  30)
    Input     = [System.Drawing.Color]::FromArgb(18,  18,  28)
    Accent    = [System.Drawing.Color]::FromArgb(100, 149, 237)   # CornflowerBlue
    AccentHov = [System.Drawing.Color]::FromArgb(140, 185, 255)   # lighter blue for hover
    BtnRun    = [System.Drawing.Color]::FromArgb(120, 200, 120)   # lawn green muted
    BtnRunHov = [System.Drawing.Color]::FromArgb(150, 225, 150)
    BtnNew    = [System.Drawing.Color]::FromArgb(119, 158, 203)   # SteelBlue-ish
    BtnNewHov = [System.Drawing.Color]::FromArgb(145, 185, 225)
    BtnDel    = [System.Drawing.Color]::FromArgb(188, 143, 143)   # RosyBrown / LightPink-dark
    BtnDelHov = [System.Drawing.Color]::FromArgb(210, 170, 170)
    BtnSave   = [System.Drawing.Color]::FromArgb(148, 167, 215)   # Lavender-blue
    BtnSaveHov= [System.Drawing.Color]::FromArgb(175, 192, 235)
    BtnAll    = [System.Drawing.Color]::FromArgb(130, 180, 160)   # Muted green
    BtnAllHov = [System.Drawing.Color]::FromArgb(158, 205, 185)
    BtnRel    = [System.Drawing.Color]::FromArgb(80,  80, 110)    # DarkGray-blue
    BtnRelHov = [System.Drawing.Color]::FromArgb(100, 100, 135)
    Preview   = [System.Drawing.Color]::FromArgb(130, 175, 220)
}

$F = @{
    Main   = New-Object System.Drawing.Font("Consolas", 9)
    Label  = New-Object System.Drawing.Font("Consolas", 8.5)
    Title  = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    Small  = New-Object System.Drawing.Font("Consolas", 8)
    Button = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
}

# INI Helpers
function Read-IniFile {
    param([string]$Path)
    $result = [System.Collections.Specialized.OrderedDictionary]::new()
    if (-not (Test-Path $Path)) { return $result }
    $curName   = $null
    $curData   = $null
    $curActive = $false
    foreach ($line in (Get-Content $Path -Encoding UTF8)) {
        if ($line -match '^\[([^;][^\]]*)\]$') {
            if ($curName) { $result[$curName] = @{ Active=$curActive; Data=$curData } }
            $curName   = $Matches[1].Trim()
            $curData   = @{}
            $curActive = $true
        } elseif ($line -match '^\[;([^\]]+)\]$') {
            if ($curName) { $result[$curName] = @{ Active=$curActive; Data=$curData } }
            $curName   = $Matches[1].Trim()
            $curData   = @{}
            $curActive = $false
        } elseif ($curName -and $line -match '^([^=;]+)=(.*)$') {
            $curData[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    if ($curName) { $result[$curName] = @{ Active=$curActive; Data=$curData } }
    return $result
}

function Write-IniFile {
    param([string]$Path, [System.Collections.Specialized.OrderedDictionary]$Profiles)
    $lines = @()
    $first = $true
    foreach ($name in $Profiles.Keys) {
        if (-not $first) { $lines += "; ---" }
        $first = $false
        $p = $Profiles[$name]
        if ($p.Active) { $lines += "[$name]" } else { $lines += "[;$name]" }
        foreach ($key in $AllKeys) {
            $val = if ($p.Data.Contains($key)) { $p.Data[$key] } else { "" }
            $lines += "$key=$val"
        }
    }
    Set-Content -Path $Path -Value $lines -Encoding UTF8
}

# UI Helpers
function New-FlatButton {
    param([string]$Text, [int]$X, [int]$Y, [int]$W=120, [int]$H=28,
          [System.Drawing.Color]$Bg=$C.BtnSave,
          [System.Drawing.Color]$Fg=$C.TextDark,
          [System.Drawing.Color]$Hov=$C.BtnSaveHov,
          [System.Drawing.Font]$Font=$null)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = $Text
    $btn.Location  = New-Object System.Drawing.Point($X, $Y)
    $btn.Size      = New-Object System.Drawing.Size($W, $H)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize         = 0
    $btn.FlatAppearance.MouseOverBackColor = $Hov
    $btn.BackColor = $Bg
    $btn.ForeColor = $Fg
    $btn.Font      = if ($Font) { $Font } else { $F.Button }
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    return $btn
}

function New-Label {
    param([string]$Text, [int]$X, [int]$Y, [int]$W=140, [int]$H=20,
          [System.Drawing.Color]$Color=$C.TextDim)
    $lbl           = New-Object System.Windows.Forms.Label
    $lbl.Text      = $Text
    $lbl.Location  = New-Object System.Drawing.Point($X, $Y)
    $lbl.Size      = New-Object System.Drawing.Size($W, $H)
    $lbl.ForeColor = $Color
    $lbl.Font      = $F.Label
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    return $lbl
}

function New-TextBox {
    param([int]$X, [int]$Y, [int]$W=80, [string]$Default="", [bool]$Enabled=$true, [string]$Placeholder="")
    $tb             = New-Object System.Windows.Forms.TextBox
    $tb.Location    = New-Object System.Drawing.Point($X, $Y)
    $tb.Size        = New-Object System.Drawing.Size($W, 22)
    $tb.BackColor   = $C.Input
    $tb.ForeColor   = $C.Text
    $tb.Font        = $F.Main
    $tb.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tb.Text        = $Default
    $tb.Enabled     = $Enabled
    return $tb
}

function New-CheckBox {
    param([string]$Text, [int]$X, [int]$Y, [bool]$Checked=$false, [int]$W=80)
    $cb             = New-Object System.Windows.Forms.CheckBox
    $cb.Text        = $Text
    $cb.Location    = New-Object System.Drawing.Point($X, $Y)
    $cb.Size        = New-Object System.Drawing.Size($W, 22)
    $cb.Checked     = $Checked
    $cb.Font        = $F.Small
    $cb.Appearance  = [System.Windows.Forms.Appearance]::Button
    $cb.FlatStyle   = [System.Windows.Forms.FlatStyle]::Flat
    $cb.FlatAppearance.BorderSize         = 1
    $cb.FlatAppearance.BorderColor        = $C.Border
    $cb.FlatAppearance.CheckedBackColor   = $C.Accent
    $cb.FlatAppearance.MouseOverBackColor = $C.Border
    $cb.BackColor   = $C.Card
    $cb.ForeColor   = $C.TextDim
    $cb.TextAlign   = [System.Drawing.ContentAlignment]::MiddleCenter
    $cb.Cursor      = [System.Windows.Forms.Cursors]::Hand
    $cb.Add_CheckedChanged({
        if ($this.Checked) {
            $this.ForeColor = $C.TextDark
            $this.FlatAppearance.MouseOverBackColor = $C.AccentHov
        } else {
            $this.ForeColor = $C.TextDim
            $this.FlatAppearance.MouseOverBackColor = $C.Border
        }
    })
    return $cb
}

function New-ComboBox {
    param([int]$X, [int]$Y, [int]$W=140, [string[]]$Items, [string]$Selected="")
    $cb               = New-Object System.Windows.Forms.ComboBox
    $cb.Location      = New-Object System.Drawing.Point($X, $Y)
    $cb.Size          = New-Object System.Drawing.Size($W, 22)
    $cb.BackColor     = $C.Input
    $cb.ForeColor     = $C.Text
    $cb.Font          = $F.Main
    $cb.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cb.FlatStyle     = [System.Windows.Forms.FlatStyle]::Flat
    $cb.DrawMode      = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
    $cb.ItemHeight    = 16

    $cb.Add_DrawItem({
        param($s, $e)
        if ($e.Index -lt 0) { return }
        # Background
        $bgColor = if ($e.State -band [System.Windows.Forms.DrawItemState]::Selected) { $C.ListSel } else { $C.Input }
        $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush($bgColor)), $e.Bounds)
        # Text
        $txt = $s.Items[$e.Index].ToString()
        $e.Graphics.DrawString($txt, $e.Font, (New-Object System.Drawing.SolidBrush($C.Text)),
            ($e.Bounds.X + 4), ($e.Bounds.Y + 2))
        # Draw dropdown arrow area background (covers white native button)
        $arrowRect = New-Object System.Drawing.Rectangle(($e.Bounds.Right - 18), $e.Bounds.Y, 18, $e.Bounds.Height)
    })

    # Paint event to redraw the button area of collapsed combobox
    $cb.Add_Paint({
        param($s, $e)
        # Cover the native white dropdown arrow with our own
        $w  = $s.Width
        $h  = $s.Height
        $aw = 18
        $arrowRect = New-Object System.Drawing.Rectangle(($w - $aw - 1), 1, ($aw), ($h - 2))
        $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush($C.Card)), $arrowRect)
        # Draw a simple down-arrow in accent color
        $ax = $w - $aw/2 - 1
        $ay = $h/2
        $pts = @(
            (New-Object System.Drawing.Point(($ax - 4), ($ay - 2))),
            (New-Object System.Drawing.Point(($ax + 4), ($ay - 2))),
            (New-Object System.Drawing.Point(($ax),     ($ay + 3)))
        )
        $e.Graphics.FillPolygon((New-Object System.Drawing.SolidBrush($C.TextDim)), $pts)
        # Border around whole control
        $e.Graphics.DrawRectangle(
            (New-Object System.Drawing.Pen($C.Border)),
            0, 0, ($w - 1), ($h - 1))
    })

    foreach ($i in $Items) { [void]$cb.Items.Add($i) }
    if ($Selected -and $cb.Items.Contains($Selected)) { $cb.SelectedItem = $Selected }
    elseif ($cb.Items.Count -gt 0) { $cb.SelectedIndex = 0 }
    return $cb
}

# ListSel color for combobox dropdown highlight
$C["ListSel"] = [System.Drawing.Color]::FromArgb(42, 62, 90)

function New-Sep {
    param([int]$X, [int]$Y, [int]$W)
    $p           = New-Object System.Windows.Forms.Panel
    $p.Location  = New-Object System.Drawing.Point($X, $Y)
    $p.Size      = New-Object System.Drawing.Size($W, 1)
    $p.BackColor = $C.Border
    return $p
}

# Main Form
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "iperf3 Profile Configurator"
$form.ClientSize      = New-Object System.Drawing.Size(800, 606)
$form.MinimumSize     = New-Object System.Drawing.Size(800, 606)
$form.BackColor       = $C.Bg
$form.ForeColor       = $C.Text
$form.Font            = $F.Main
$form.StartPosition   = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox     = $false

# Title
$titleLbl           = New-Object System.Windows.Forms.Label
$titleLbl.Text      = "  iperf3 Profile Configurator"
$titleLbl.Location  = New-Object System.Drawing.Point(0, 0)
$titleLbl.Size      = New-Object System.Drawing.Size(800, 34)
$titleLbl.ForeColor = $C.Accent
$titleLbl.Font      = $F.Title
$titleLbl.BackColor = $C.Panel
$titleLbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$form.Controls.Add($titleLbl)

# Left panel
$leftPanel           = New-Object System.Windows.Forms.Panel
$leftPanel.Location  = New-Object System.Drawing.Point(0, 34)
$leftPanel.Size      = New-Object System.Drawing.Size(218, 548)
$leftPanel.BackColor = $C.Panel
$form.Controls.Add($leftPanel)

$leftPanel.Controls.Add((New-Label "PROFILES" 12 8 140 18 $C.TextDim))

$profileList              = New-Object System.Windows.Forms.CheckedListBox
$profileList.Location     = New-Object System.Drawing.Point(10, 28)
$profileList.Size         = New-Object System.Drawing.Size(198, 446)
$profileList.BackColor    = $C.Card
$profileList.ForeColor    = $C.Text
$profileList.Font         = $F.Main
$profileList.BorderStyle  = [System.Windows.Forms.BorderStyle]::None
$profileList.CheckOnClick = $false
$leftPanel.Controls.Add($profileList)

# Separator above buttons
$leftPanel.Controls.Add((New-Sep 10 478 198))

# Buttons same height as right panel buttons, aligned at y=530
$btnAdd    = New-FlatButton "New"      10  482  95 28 $C.BtnNew  $C.TextDark $C.BtnNewHov
$btnDelete = New-FlatButton "Delete"   113 482  95 28 $C.BtnDel  $C.TextDark $C.BtnDelHov
$leftPanel.Controls.Add($btnAdd)
$leftPanel.Controls.Add($btnDelete)

# Right panel
$rightPanel           = New-Object System.Windows.Forms.Panel
$rightPanel.Location  = New-Object System.Drawing.Point(218, 34)
$rightPanel.Size      = New-Object System.Drawing.Size(572, 548)
$rightPanel.BackColor = $C.Bg
$form.Controls.Add($rightPanel)

# Profile name row
$rightPanel.Controls.Add((New-Label "Profile name:" 16 12 110 20 $C.TextDim))
$txtName = New-TextBox 132 10 260
$txtName.Add_TextChanged({
    if (-not $script:suppressEvents) { $script:dirty = $true }
})
$rightPanel.Controls.Add($txtName)
$rightPanel.Controls.Add((New-Sep 10 38 542))

# Build parameter rows
$y    = 50
$rowH = 30
$LX   = 16    # label x
$LW   = 130   # label width
$TX   = 150   # textbox / combo x
$TW   = 85    # textbox width
$CX   = 244   # checkbox x

function Add-NumRow {
    param([string]$Lbl, [string]$Key, [string]$Hint, [ref]$YRef)
    $yv = $YRef.Value
    $rightPanel.Controls.Add((New-Label $Lbl $LX ($yv+4) $LW 18))
    $tb             = New-TextBox $TX $yv $TW "" $false
    $tb.Tag         = $Hint   # Tag stores hint for placeholder simulation
    $tb.ForeColor   = $C.TextDim
    $tb.Text        = $Hint
    $rightPanel.Controls.Add($tb)
    $chk        = New-CheckBox "manual" $CX $yv $false 80
    $chk.Tag    = $tb
    $chk.Add_CheckedChanged({
        $field = $this.Tag
        if ($this.Checked) {
            # Enabling: clear hint if showing
            if ($field.ForeColor -eq $C.TextDim) {
                $field.Text      = ""
                $field.ForeColor = $C.Text
            }
            $field.Enabled = $true
        } else {
            $field.Enabled = $false
            # Show hint if empty
            if ($field.Text.Trim() -eq "") {
                $field.ForeColor = $C.TextDim
                $field.Text      = $field.Tag
            }
        }
    })
    $rightPanel.Controls.Add($chk)
    $YRef.Value += $rowH
    return @{ tb=$tb; chk=$chk; key=$Key; hint=$Hint }
}

function Add-ComboRow {
    param([string]$Lbl, [string]$Key, [string[]]$Items, [ref]$YRef)
    $yv = $YRef.Value
    $rightPanel.Controls.Add((New-Label $Lbl $LX ($yv+4) $LW 18))
    $cb      = New-ComboBox $TX $yv 148 $Items
    $cb.Tag  = $Key
    $rightPanel.Controls.Add($cb)
    $YRef.Value += $rowH
    return @{ cb=$cb; key=$Key }
}

$yRef = [ref]$y

$rowProto    = Add-ComboRow "Protocol:"         "protocol"  @("TCP","UDP")        $yRef
$rowDir      = Add-ComboRow "Direction:"        "direction" @("Normal","Reverse")  $yRef
$rightPanel.Controls.Add((New-Sep 10 $yRef.Value 542))
$yRef.Value += 8

$rowHost     = Add-NumRow   "Host / IP:"        "host"     "192.168.1.1"        $yRef
$rowPort     = Add-NumRow   "Port:"             "port"     "5201"               $yRef
$rowBitrate  = Add-NumRow   "Bitrate (Mbps):"   "bitrate"  "100"                $yRef
$rowDuration = Add-NumRow   "Duration (sec):"   "duration" "10"                 $yRef
$rowInterval = Add-NumRow   "Interval (sec):"   "interval" "1"                  $yRef
$rowBufLen   = Add-NumRow   "Block size (bytes):" "buflen"   "131072"             $yRef
$rowStreams   = Add-NumRow   "Streams:"          "streams"  "1"                  $yRef
$rowWindow   = Add-NumRow   "Buflen (MB):"      "window"   "1"                  $yRef
$rightPanel.Controls.Add((New-Sep 10 $yRef.Value 542))
$yRef.Value += 8

# Extra params
$rightPanel.Controls.Add((New-Label "Extra params:" $LX ($yRef.Value+4) $LW 18))
$txtExtra = New-TextBox $TX $yRef.Value 382
$rightPanel.Controls.Add($txtExtra)
$yRef.Value += $rowH + 2

$rightPanel.Controls.Add((New-Sep 10 $yRef.Value 542))
$yRef.Value += 8

# Preview
$rightPanel.Controls.Add((New-Label "Command preview:" $LX $yRef.Value 150 18 $C.TextDim))
$yRef.Value += 20
$txtPreview             = New-Object System.Windows.Forms.TextBox
$txtPreview.Location    = New-Object System.Drawing.Point($LX, $yRef.Value)
$txtPreview.Size        = New-Object System.Drawing.Size(538, 38)
$txtPreview.BackColor   = $C.Card
$txtPreview.ForeColor   = $C.Preview
$txtPreview.Font        = $F.Small
$txtPreview.Multiline   = $true
$txtPreview.ReadOnly    = $true
$txtPreview.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$rightPanel.Controls.Add($txtPreview)
$yRef.Value += 46

$rightPanel.Controls.Add((New-Sep 10 $yRef.Value 542))
$yRef.Value += 8

# Bottom buttons — same row, same height as left panel buttons (y=530 in left = $yRef.Value here)
$btnSave    = New-FlatButton "Save Profile"  $LX         $yRef.Value  90 28 $C.BtnSave $C.TextDark $C.BtnSaveHov
$btnReload  = New-FlatButton "Reload INI"   ($LX+92)    $yRef.Value  90 28 $C.BtnRel  $C.Text     $C.BtnRelHov
$btnSaveAll = New-FlatButton "Save INI"     ($LX+184)   $yRef.Value  90 28 $C.BtnAll  $C.TextDark $C.BtnAllHov
$rightPanel.Controls.Add($btnSave)
$rightPanel.Controls.Add($btnReload)
$rightPanel.Controls.Add($btnSaveAll)

# Help button (square, right of Save All)
$btnRun     = New-FlatButton "Run"          ($LX+286)   $yRef.Value  85 28 $C.BtnRun  $C.TextDark $C.BtnRunHov
$btnRunLive = New-FlatButton "Run Live"     ($LX+373)   $yRef.Value  85 28 $C.BtnRun  $C.TextDark $C.BtnRunHov
$btnHelp = New-FlatButton "?" (526) $yRef.Value 28 28 $C.BtnRel $C.Text $C.BtnRelHov
$rightPanel.Controls.Add($btnRun)
$rightPanel.Controls.Add($btnRunLive)
$rightPanel.Controls.Add($btnHelp)

# Help dialog with RichTextBox for bold formatting
$FlagFile = Join-Path $PSScriptRoot "runtest.flag"

$btnRun.Add_Click({
    if ($script:dirty) {
        $res = [System.Windows.Forms.MessageBox]::Show(
            "You have unsaved changes not written to INI file." + [char]10 +
            "Save INI file before running tests?",
            "Unsaved Changes",
            [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
            Save-CurrentProfile
            Write-IniFile $IniFile $script:profiles
            $script:dirty = $false
        } elseif ($res -eq [System.Windows.Forms.DialogResult]::Cancel) {
            return
        }
    }
    Set-Content -Path $FlagFile -Value "1" -Encoding ASCII
    $statusLbl.Text      = "  Run flag created: $FlagFile"
    $statusLbl.ForeColor = $C.BtnRun
    $form.Close()
})

$btnRunLive.Add_Click({
    if ($script:dirty) {
        $res = [System.Windows.Forms.MessageBox]::Show(
            "You have unsaved changes not written to INI file." + [char]10 +
            "Save INI file before running live test?",
            "Unsaved Changes",
            [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
            Save-CurrentProfile
            Write-IniFile $IniFile $script:profiles
            $script:dirty = $false
        } elseif ($res -eq [System.Windows.Forms.DialogResult]::Cancel) {
            return
        }
    }
    $liveFlagFile = Join-Path $PSScriptRoot "runlive.flag"
    Set-Content -Path $liveFlagFile -Value "1" -Encoding ASCII
    $statusLbl.Text      = "  Live flag created: $liveFlagFile"
    $statusLbl.ForeColor = $C.BtnRun
    $form.Close()
})

$btnHelp.Add_Click({
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text            = "iperf3 Configurator - Help"
    $dlg.Size            = New-Object System.Drawing.Size(560, 620)
    $dlg.MinimizeBox     = $false
    $dlg.MaximizeBox     = $false
    $dlg.StartPosition   = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dlg.BackColor       = $C.Card
    $dlg.ForeColor       = $C.Text
    $dlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

    $rtb = New-Object System.Windows.Forms.RichTextBox
    $rtb.Location        = New-Object System.Drawing.Point(12, 12)
    $rtb.Size            = New-Object System.Drawing.Size(518, 554)
    $rtb.BackColor       = $C.Card
    $rtb.ForeColor       = $C.Text
    $rtb.ReadOnly        = $true
    $rtb.BorderStyle     = [System.Windows.Forms.BorderStyle]::None
    $rtb.ScrollBars      = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $rtb.Font            = New-Object System.Drawing.Font("Segoe UI", 9)
    $dlg.Controls.Add($rtb)

    function RTB-Add {
        param([string]$Text, [bool]$Bold=$false, [bool]$Newline=$true)
        $start = $rtb.TextLength
        $rtb.AppendText($Text)
        $rtb.Select($start, $Text.Length)
        $style = if ($Bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
        $rtb.SelectionFont  = New-Object System.Drawing.Font("Segoe UI", 9, $style)
        $rtb.SelectionColor = if ($Bold) { $C.Accent } else { $C.Text }
        if ($Newline) { $rtb.AppendText("`n") }
    }

    RTB-Add "PROFILES LIST" $true
    RTB-Add "  The list on the left shows all profiles from the INI file."
    RTB-Add "  Checkbox next to each name controls active/inactive state:"
    RTB-Add "  Checked   " $true $false; RTB-Add "= written as [ProfileName] in INI, parsed by CMD script." $false
    RTB-Add "  Unchecked " $true $false; RTB-Add "= written as [;ProfileName], skipped by CMD script." $false
    RTB-Add "  Click a profile name to load it into the editor on the right."
    RTB-Add ""
    RTB-Add "CREATING A PROFILE" $true
    RTB-Add "  Option A: Click " $false $false; RTB-Add "New" $true $false; RTB-Add ", edit the name and parameters, click " $false $false; RTB-Add "Save Profile" $true $false; RTB-Add "." $false
    RTB-Add "  Option B: Type a name in " $false $false; RTB-Add "Profile name:" $true $false; RTB-Add " at the top, set parameters, click " $false $false; RTB-Add "Save Profile" $true $false; RTB-Add "." $false
    RTB-Add "           A new profile is created automatically."
    RTB-Add "  To rename: load the profile, edit the name field, click " $false $false; RTB-Add "Save Profile" $true $false; RTB-Add "." $false
    RTB-Add ""
    RTB-Add "PARAMETERS" $true
    RTB-Add "  Each numeric field has a " $false $false; RTB-Add "manual" $true $false; RTB-Add " toggle button." $false
    RTB-Add "  Gray  " $true $false; RTB-Add "= default mode. Key written empty in INI (e.g. bitrate=), iperf3 uses its default." $false
    RTB-Add "  Blue  " $true $false; RTB-Add "= manual mode. Value is saved and passed to iperf3 command." $false
    RTB-Add "  Gray numbers shown in empty fields are hints only, not saved values."
    RTB-Add "  Protocol and Direction are always saved (dropdowns, no manual toggle needed)."
    RTB-Add ""
    RTB-Add "  Protocol   " $true $false; RTB-Add "       TCP or UDP." $false
    RTB-Add "  Direction  " $true $false; RTB-Add "       Normal = client sends. Reverse (-R) = server sends." $false
    RTB-Add "  Host / IP  " $true $false; RTB-Add "(-c)  Server address. Required for iperf3 client mode." $false
    RTB-Add "  Port       " $true $false; RTB-Add "(-p)  Server port. Default: 5201." $false
    RTB-Add "  Bitrate    " $true $false; RTB-Add "(-b)  Target bitrate in Mbps. UDP default: 1M, TCP: unlimited." $false
    RTB-Add "  Duration   " $true $false; RTB-Add "(-t)  Test duration in seconds. Default: 10." $false
    RTB-Add "  Interval   " $true $false; RTB-Add "(-i)  Stats report interval in seconds. Default: 1." $false
    RTB-Add "  Block size " $true $false; RTB-Add "(-l)  Read/write block size in bytes. TCP default: 131072, UDP default: 1460." $false
    RTB-Add "  Streams    " $true $false; RTB-Add "(-P)  Number of parallel streams. Default: 1." $false
    RTB-Add "  Buflen     " $true $false; RTB-Add "(-w)  Socket buffer size in MB. Default: 1." $false
    RTB-Add "  Extra      " $true $false; RTB-Add "      Any extra flags, appended verbatim to the command." $false
    RTB-Add ""
    RTB-Add "BUTTONS" $true
    RTB-Add "  Save Profile  " $true $false; RTB-Add "Saves current editor state to memory (not to disk yet)." $false
    RTB-Add "  Reload File   " $true $false; RTB-Add "Reloads all profiles from INI file. Discards unsaved changes." $false
    RTB-Add "  Save All INI  " $true $false; RTB-Add "Calls Save Profile, then writes all profiles to disk." $false
    RTB-Add "  Save Profile  " $true $false; RTB-Add "Saves current profile to memory only (not to disk)." $false
    RTB-Add "  Reload INI    " $true $false; RTB-Add "Reloads all profiles from INI. Discards unsaved changes." $false
    RTB-Add "  Save INI      " $true $false; RTB-Add "Saves all profiles to INI file on disk." $false
    RTB-Add "  Run           " $true $false; RTB-Add "Saves INI (prompts if unsaved), signals CMD to run queued tests." $false
    RTB-Add "  Run Live      " $true $false; RTB-Add "Like Run, but signals CMD to run a live/immediate test." $false
    RTB-Add "  On close: if there are unsaved changes, you will be prompted to save." $false
    RTB-Add ""
    RTB-Add "FLAG FILES" $true
    RTB-Add "  Run        " $true $false; RTB-Add "creates runtest.flag in the script folder." $false
    RTB-Add "  Run Live   " $true $false; RTB-Add "creates runlive.flag in the script folder." $false
    RTB-Add "  Simply closing the window creates no flag files." $false
    RTB-Add ""
    RTB-Add "  Check flags in your CMD script:" $false
    RTB-Add "  " $false $false; RTB-Add "if exist runtest.flag  del runtest.flag  & call :_iPerfTest" $true $false; RTB-Add "" $false
    RTB-Add "  " $false $false; RTB-Add "if exist runlive.flag  del runlive.flag  & call :_iPerfLive" $true $false; RTB-Add "" $false
    RTB-Add ""
    RTB-Add "  Launch the configurator from CMD:" $false
    RTB-Add "  " $false $false; RTB-Add "powershell -ExecutionPolicy Bypass -File configurator.ps1" $true $false; RTB-Add "" $false
    RTB-Add ""
    RTB-Add "INI FILE FORMAT" $true
    RTB-Add "  [ProfileName]   " $true $false; RTB-Add "Active profile section." $false
    RTB-Add "  [;ProfileName]  " $true $false; RTB-Add "Inactive (skipped) profile section." $false
    RTB-Add "  ; ---           " $true $false; RTB-Add "Separator between profiles." $false
    RTB-Add "  key=value       " $true $false; RTB-Add "Parameter. Empty value = iperf3 uses its default." $false
    RTB-Add ""
    RTB-Add "  Use " $false $false; RTB-Add "iperf_parse.cmd" $true $false; RTB-Add " to iterate all active profiles and run tests:" $false
    RTB-Add "  iperf_parse.cmd" $false
    RTB-Add "  Edit the " $false $false; RTB-Add ":RunTest" $true $false; RTB-Add " section in that script with your launch command." $false
    RTB-Add ""
    RTB-Add "INI file is saved in the same folder as the script." $false

    $rtb.SelectionStart = 0
    [void]$dlg.ShowDialog()
})


# Status bar
$statusLbl           = New-Object System.Windows.Forms.Label
$statusLbl.Location  = New-Object System.Drawing.Point(0, 582)
$statusLbl.Size      = New-Object System.Drawing.Size(800, 24)
$statusLbl.BackColor = $C.Panel
$statusLbl.ForeColor = $C.TextDim
$statusLbl.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5)
$statusLbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$statusLbl.Text      = "  Ready  |  $IniFile"
$form.Controls.Add($statusLbl)

# State
$script:profiles       = Read-IniFile $IniFile
$script:currentProfile = $null
$script:suppressEvents = $false
$script:dirty          = $false   # tracks unsaved changes

# Helpers
function Refresh-ProfileList {
    param([string]$SelectName = "")
    $script:suppressEvents = $true
    $profileList.Items.Clear()
    foreach ($name in $script:profiles.Keys) {
        $idx = $profileList.Items.Add($name)
        $profileList.SetItemChecked($idx, [bool]$script:profiles[$name].Active)
    }
    $target = if ($SelectName) { $SelectName } else { $script:currentProfile }
    if ($target) {
        for ($i = 0; $i -lt $profileList.Items.Count; $i++) {
            if ($profileList.Items[$i].ToString() -eq $target) {
                $profileList.SelectedIndex = $i; break
            }
        }
    }
    $script:suppressEvents = $false
}

function Update-Preview {
    $parts = @("iperf3")
    $h = $rowHost.tb.Text.Trim()
    if ($rowHost.chk.Checked -and $h) { $parts += ("-c " + $h) }
    $pt = $rowPort.tb.Text.Trim()
    if ($rowPort.chk.Checked -and $pt) { $parts += ("-p " + $pt) }
    if ($rowProto.cb.SelectedItem -eq "UDP")    { $parts += "-u" }
    if ($rowDir.cb.SelectedItem  -eq "Reverse") { $parts += "-R" }
    if ($rowBitrate.chk.Checked  -and $rowBitrate.tb.Text.Trim())  { $parts += ("-b " + $rowBitrate.tb.Text.Trim()  + "M") }
    if ($rowDuration.chk.Checked -and $rowDuration.tb.Text.Trim()) { $parts += ("-t " + $rowDuration.tb.Text.Trim()) }
    if ($rowInterval.chk.Checked -and $rowInterval.tb.Text.Trim()) { $parts += ("-i " + $rowInterval.tb.Text.Trim()) }
    if ($rowBufLen.chk.Checked   -and $rowBufLen.tb.Text.Trim())   { $parts += ("-l " + $rowBufLen.tb.Text.Trim()) }
    if ($rowStreams.chk.Checked   -and $rowStreams.tb.Text.Trim())  { $parts += ("-P " + $rowStreams.tb.Text.Trim()) }
    if ($rowWindow.chk.Checked   -and $rowWindow.tb.Text.Trim())   { $parts += ("-w " + $rowWindow.tb.Text.Trim()   + "M") }
    $ex = $txtExtra.Text.Trim()
    if ($ex) { $parts += $ex }
    $txtPreview.Text = ($parts -join " ")
}

function Load-Profile {
    param([string]$Name)
    $script:currentProfile = $Name
    $p = $script:profiles[$Name].Data
    $script:suppressEvents = $true
    $txtName.Text = $Name

    # Numeric rows with manual checkbox
    foreach ($row in @($rowHost,$rowPort,$rowBitrate,$rowDuration,$rowInterval,$rowBufLen,$rowStreams,$rowWindow)) {
        $key  = $row.key
        $val  = if ($p.Contains($key)) { $p[$key] } else { "" }
        $hint = $row.hint
        if ($val -ne "") {
            $row.tb.ForeColor = $C.Text
            $row.tb.Text      = $val
            $row.chk.Checked  = $true
            $row.tb.Enabled   = $true
        } else {
            $row.chk.Checked  = $false
            $row.tb.Enabled   = $false
            $row.tb.ForeColor = $C.TextDim
            $row.tb.Text      = $hint
        }
    }

    $proto = if ($p.Contains("protocol") -and $p["protocol"] -ne "") { $p["protocol"] } else { "TCP" }
    $dir   = if ($p.Contains("direction") -and $p["direction"] -ne "") { $p["direction"] } else { "Normal" }
    $rowProto.cb.SelectedItem = $proto
    $rowDir.cb.SelectedItem   = $dir
    # Update Block size hint to match loaded protocol
    if (-not $rowBufLen.chk.Checked) {
        $hint = if ($proto -eq "UDP") { "1460" } else { "131072" }
        $rowBufLen.tb.ForeColor = $C.TextDim
        $rowBufLen.tb.Text      = $hint
        $rowBufLen.tb.Tag       = $hint
    }
    $txtExtra.Text = if ($p.Contains("extra") -and $p["extra"] -ne "") { $p["extra"] } else { "" }

    $script:suppressEvents = $false
    Update-Preview
}

function Save-CurrentProfile {
    # Recover from list selection if needed
    if (-not $script:currentProfile) {
        $idx = $profileList.SelectedIndex
        if ($idx -ge 0) { $script:currentProfile = $profileList.Items[$idx].ToString() }
    }
    # Manual entry: create new profile from name field
    if (-not $script:currentProfile) {
        $typedName = $txtName.Text.Trim()
        if (-not $typedName) {
            $statusLbl.Text      = "  Enter a profile name first."
            $statusLbl.ForeColor = $C.BtnDel
            return
        }
        $script:profiles[$typedName] = @{ Active=$true; Data=@{} }
        $script:currentProfile = $typedName
        Refresh-ProfileList $typedName
    }

    $oldName = $script:currentProfile
    $newName = $txtName.Text.Trim()
    if (-not $newName) {
        [System.Windows.Forms.MessageBox]::Show("Profile name cannot be empty.", "Validation")
        return
    }

    # Collect data — always write all keys, empty = default
    $data = @{}
    foreach ($row in @($rowHost,$rowPort,$rowBitrate,$rowDuration,$rowInterval,$rowBufLen,$rowStreams,$rowWindow)) {
        if ($row.chk.Checked) {
            $val = $row.tb.Text.Trim()
            $data[$row.key] = $val
        } else {
            $data[$row.key] = ""
        }
    }
    $data["protocol"]  = $rowProto.cb.SelectedItem.ToString()
    $data["direction"] = $rowDir.cb.SelectedItem.ToString()
    $data["extra"]     = $txtExtra.Text.Trim()

    # Read active state from list
    $isActive = $true
    for ($i = 0; $i -lt $profileList.Items.Count; $i++) {
        if ($profileList.Items[$i].ToString() -eq $oldName) {
            $isActive = $profileList.GetItemChecked($i); break
        }
    }

    if ($oldName -ne $newName) {
        $newProfiles = [System.Collections.Specialized.OrderedDictionary]::new()
        foreach ($k in $script:profiles.Keys) {
            if ($k -eq $oldName) { $newProfiles[$newName] = @{ Active=$isActive; Data=$data } }
            else                  { $newProfiles[$k]       = $script:profiles[$k] }
        }
        $script:profiles       = $newProfiles
        $script:currentProfile = $newName
    } else {
        $script:profiles[$newName] = @{ Active=$isActive; Data=$data }
    }

    $script:dirty        = $true
    Refresh-ProfileList $newName
    Update-Preview
    $statusLbl.Text      = "  Profile [" + $newName + "] saved in memory. Use Save All INI to write to disk."
    $statusLbl.ForeColor = $C.BtnSave
}

# Events
$profileList.Add_SelectedIndexChanged({
    if ($script:suppressEvents) { return }
    $idx = $profileList.SelectedIndex
    if ($idx -lt 0) { return }
    Load-Profile $profileList.Items[$idx].ToString()
})

$profileList.Add_ItemCheck({
    param($s, $e)
    if ($script:suppressEvents) { return }
    $name = $profileList.Items[$e.Index].ToString()
    if ($script:profiles.Contains($name)) {
        $script:profiles[$name].Active = ($e.NewValue -eq [System.Windows.Forms.CheckState]::Checked)
        $script:dirty = $true
    }
})

$btnAdd.Add_Click({
    $newName = "Profile_" + [datetime]::Now.ToString("HHmmss")
    $script:profiles[$newName] = @{ Active=$true; Data=@{} }
    Refresh-ProfileList $newName
    Load-Profile $newName
    $txtName.Focus(); $txtName.SelectAll()
})

$btnDelete.Add_Click({
    if (-not $script:currentProfile) { return }
    $msg = "Delete profile: " + $script:currentProfile + "?"
    $res = [System.Windows.Forms.MessageBox]::Show($msg, "Confirm Delete",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
        $script:profiles.Remove($script:currentProfile)
        $script:currentProfile = $null
        $script:dirty = $true
        Refresh-ProfileList
        $statusLbl.Text      = "  Profile deleted."
        $statusLbl.ForeColor = $C.BtnDel
    }
})

$btnSave.Add_Click({ Save-CurrentProfile })

$btnReload.Add_Click({
    $script:profiles       = Read-IniFile $IniFile
    $script:currentProfile = $null
    $script:dirty          = $false
    Refresh-ProfileList
    $statusLbl.Text      = "  Profiles reloaded from disk."
    $statusLbl.ForeColor = $C.Accent
})

$btnSaveAll.Add_Click({
    Save-CurrentProfile
    Write-IniFile $IniFile $script:profiles
    $script:dirty        = $false
    $statusLbl.Text      = "  INI file saved: " + $IniFile
    $statusLbl.ForeColor = $C.BtnAll
})

# Live preview wiring + dirty tracking
foreach ($ctl in @($rowHost.tb,$rowPort.tb,$rowBitrate.tb,$rowDuration.tb,$rowInterval.tb,$rowBufLen.tb,$rowStreams.tb,$rowWindow.tb,$txtExtra)) {
    $ctl.Add_TextChanged({
        if (-not $script:suppressEvents) { $script:dirty = $true }
        Update-Preview
    })
}
foreach ($chk in @($rowHost.chk,$rowPort.chk,$rowBitrate.chk,$rowDuration.chk,$rowInterval.chk,$rowBufLen.chk,$rowStreams.chk,$rowWindow.chk)) {
    $chk.Add_CheckedChanged({
        if (-not $script:suppressEvents) { $script:dirty = $true }
        Update-Preview
    })
}
$rowProto.cb.Add_SelectedIndexChanged({
    if (-not $script:suppressEvents) { $script:dirty = $true }
    # Update Block size hint based on selected protocol
    if (-not $rowBufLen.chk.Checked) {
        $hint = if ($rowProto.cb.SelectedItem -eq "UDP") { "1460" } else { "131072" }
        $rowBufLen.tb.ForeColor = $C.TextDim
        $rowBufLen.tb.Text      = $hint
        $rowBufLen.tb.Tag       = $hint
    }
    Update-Preview
})
$rowDir.cb.Add_SelectedIndexChanged({
    if (-not $script:suppressEvents) { $script:dirty = $true }
    Update-Preview
})


# Set placeholder texts after handles are created
$form.Add_Shown({
    Set-Placeholder $txtName  "Enter profile name"
    Set-Placeholder $txtExtra "--get-server-output --logfile out.txt ..."
})

# Initial load
Refresh-ProfileList
if ($profileList.Items.Count -gt 0) {
    $profileList.SelectedIndex = 0
    Load-Profile $profileList.Items[0].ToString()
}

$form.Add_FormClosing({
    param($s, $e)
    if ($script:dirty) {
        $res = [System.Windows.Forms.MessageBox]::Show(
            "You have unsaved changes. Save INI file before closing?",
            "Unsaved Changes",
            [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
            Save-CurrentProfile
            Write-IniFile $IniFile $script:profiles
            $script:dirty = $false
        } elseif ($res -eq [System.Windows.Forms.DialogResult]::Cancel) {
            $e.Cancel = $true
        }
    }
})

[void]$form.ShowDialog()