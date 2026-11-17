$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$engine = Join-Path $here 'ServiceBackup.ps1'
$dataDir = Join-Path $here 'Backups'

$admin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', ('"{0}"' -f $PSCommandPath)
    exit
}
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, Microsoft.VisualBasic

try {

# Dark "soft UI" look: rounded cards and pills with a purple neon outline.
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

public static class Neon {
    public static readonly Color Outer = Color.FromArgb(30, 29, 34);
    public static readonly Color Fill = Color.FromArgb(42, 41, 48);
    public static readonly Color Accent = Color.FromArgb(168, 85, 247);

    public static GraphicsPath Round(Rectangle r, int radius) {
        int d = Math.Max(2, Math.Min(radius * 2, Math.Min(r.Width, r.Height)));
        GraphicsPath p = new GraphicsPath();
        p.AddArc(r.X, r.Y, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }

    public static void Draw(Graphics g, Rectangle r, int radius, Color fill, bool glow, float line) {
        g.SmoothingMode = SmoothingMode.AntiAlias;
        using (GraphicsPath p = Round(r, radius)) {
            using (SolidBrush b = new SolidBrush(fill)) g.FillPath(b, p);
            if (!glow) return;
            for (int i = 3; i >= 1; i--)
                using (Pen halo = new Pen(Color.FromArgb(22, Accent), 1 + i * 3)) g.DrawPath(halo, p);
            using (Pen pen = new Pen(Accent, line)) g.DrawPath(pen, p);
        }
    }
}

public class NeonPanel : Panel {
    public int Radius = 18;      // 0 = full pill
    public bool Glowing = true;
    public Color FillColor = Neon.Fill;
    public Color Surround = Neon.Outer;   // colour behind the rounded corners
    public NeonPanel() {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        BackColor = Neon.Fill;
    }
    protected override void OnPaint(PaintEventArgs e) {
        e.Graphics.Clear(Surround);
        Rectangle r = new Rectangle(5, 5, Width - 11, Height - 11);
        Neon.Draw(e.Graphics, r, Radius > 0 ? Radius : r.Height / 2, FillColor, Glowing, 1.6f);
    }
}

public class PillButton : Button {
    public bool Primary;
    bool hot;
    public PillButton() {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        Cursor = Cursors.Hand;
    }
    protected override void OnMouseEnter(EventArgs e) { hot = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { hot = false; Invalidate(); base.OnMouseLeave(e); }
    protected override void OnPaint(PaintEventArgs e) {
        e.Graphics.Clear(Neon.Outer);
        Rectangle r = new Rectangle(4, 4, Width - 9, Height - 9);
        Color fill = Primary ? Color.FromArgb(78, 48, 120) : (hot ? Color.FromArgb(52, 51, 60) : Neon.Fill);
        Neon.Draw(e.Graphics, r, r.Height / 2, fill, Primary || hot, 1.4f);
        TextRenderer.DrawText(e.Graphics, Text, Font, r, Color.FromArgb(236, 235, 240),
            TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.SingleLine);
    }
}
'@

$cOuter = [Neon]::Outer
$cFill = [Neon]::Fill
$cAccent = [Neon]::Accent
$cText = [Drawing.Color]::FromArgb(236, 235, 240)
$cMuted = [Drawing.Color]::FromArgb(154, 152, 166)
$cLine = [Drawing.Color]::FromArgb(58, 57, 66)
$cInner = [Drawing.Color]::FromArgb(34, 33, 39)
$fRegular = New-Object Drawing.Font('Segoe UI', 9)
$fBold = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
$brFill = New-Object Drawing.SolidBrush($cFill)
$brSel = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(70, 168, 85, 247))
$brText = New-Object Drawing.SolidBrush($cText)
$brMuted = New-Object Drawing.SolidBrush($cMuted)
$sfEllipsis = New-Object Drawing.StringFormat
$sfEllipsis.Trimming = 'EllipsisCharacter'; $sfEllipsis.FormatFlags = 'NoWrap'

$script:rows = @()
$script:loading = $false
$script:baseText = ''
$script:meta = @{}

function Show-State([string]$s) {
    if ($s -eq 'missing') { return 'Missing (removed)' }
    if ($s -notmatch '^Start=(\d)') { return $s }
    $label = @('Boot', 'System', 'Automatic', 'Manual', 'Disabled')[[int]$Matches[1]]
    $extra = (($s -replace '^Start=\d;?', '') -replace 'Delayed=-;?', '' -replace 'Override=$', '').TrimEnd(';')
    if ($extra) { return "$label ($extra)" }
    return $label
}

function Show-Error($e) { [void][Windows.Forms.MessageBox]::Show($e.Exception.Message, 'Error', 'OK', 'Error') }

function New-Button([string]$text, [bool]$primary = $false) {
    $b = New-Object PillButton
    $b.Text = $text; $b.Font = $fRegular; $b.Primary = $primary
    $b.Size = [Drawing.Size]::new([Windows.Forms.TextRenderer]::MeasureText($text, $fRegular).Width + 44, 38)
    $b.Margin = [Windows.Forms.Padding]::new(2, 0, 2, 0)
    return $b
}

function New-Label([string]$text, [Drawing.Color]$color, [Drawing.Color]$bg, [float]$size = 9, [bool]$bold = $false) {
    $l = New-Object Windows.Forms.Label
    $style = if ($bold) { [Drawing.FontStyle]::Bold } else { [Drawing.FontStyle]::Regular }
    $l.Text = $text; $l.ForeColor = $color; $l.BackColor = $bg
    $l.Font = New-Object Drawing.Font('Segoe UI', $size, $style)
    $l.AutoSize = $false; $l.Dock = 'Fill'; $l.TextAlign = 'MiddleCenter'; $l.AutoEllipsis = $true
    return $l
}

function New-Card([int]$radius = 18, [bool]$glow = $true) {
    $p = New-Object NeonPanel
    $p.Radius = $radius; $p.Glowing = $glow; $p.Dock = 'Fill'
    $p.Margin = [Windows.Forms.Padding]::new(0)
    return $p
}

function New-Table([int]$cols, [int]$rows) {
    $t = New-Object Windows.Forms.TableLayoutPanel
    $t.Dock = 'Fill'; $t.ColumnCount = $cols; $t.RowCount = $rows; $t.BackColor = [Drawing.Color]::Transparent
    return $t
}

function Add-Row($t, [string]$kind, [float]$size) { [void]$t.RowStyles.Add((New-Object Windows.Forms.RowStyle($kind, $size))) }
function Add-Col($t, [string]$kind, [float]$size) { [void]$t.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle($kind, $size))) }

$form = New-Object Windows.Forms.Form
$form.Text = 'TheKOS - Service Backup'
$form.Font = $fRegular; $form.BackColor = $cOuter; $form.ForeColor = $cText
$form.Size = [Drawing.Size]::new(1120, 720)
$form.MinimumSize = [Drawing.Size]::new(900, 520)
$form.StartPosition = 'CenterScreen'

# ---- Left card: selected backup
$cardLeft = New-Card
$cardLeft.Padding = [Windows.Forms.Padding]::new(16)
$avatar = New-Card 38 $false
$avatar.FillColor = $cInner; $avatar.Surround = $cFill; $avatar.Padding = [Windows.Forms.Padding]::new(14)
$avatar.Dock = 'None'; $avatar.Size = [Drawing.Size]::new(80, 80); $avatar.Anchor = 'None'
$glyph = New-Label ([string][char]0x2699) $cAccent $cInner 26
$glyph.Font = New-Object Drawing.Font('Segoe UI Symbol', 26)
$avatar.Controls.Add($glyph)
$lblName = New-Label '' $cText $cFill 11 $true
$lblDate = New-Label '' $cAccent $cFill 9
$lblPc = New-Label '' $cMuted $cFill 8.5
$statSvc = New-Label '-' $cText $cInner 13 $true
$statDiff = New-Label '-' $cText $cInner 13 $true
$statSel = New-Label '0' $cText $cInner 13 $true

function New-StatCell([string]$caption, $valueLabel) {
    $t = New-Table 1 2
    $t.BackColor = $cInner
    Add-Col $t 'Percent' 100; Add-Row $t 'Percent' 58; Add-Row $t 'Percent' 42
    $t.Controls.Add($valueLabel, 0, 0)
    $t.Controls.Add((New-Label $caption $cMuted $cInner 8), 0, 1)
    return $t
}
$stats = New-Card 12 $false
$stats.FillColor = $cInner; $stats.Surround = $cFill; $stats.Dock = 'Fill'; $stats.Margin = [Windows.Forms.Padding]::new(0, 6, 0, 6)
$statsTable = New-Table 3 1
$statsTable.BackColor = $cInner
foreach ($i in 1..3) { Add-Col $statsTable 'Percent' 33.3 }
Add-Row $statsTable 'Percent' 100
$statsTable.Controls.Add((New-StatCell 'Services' $statSvc), 0, 0)
$statsTable.Controls.Add((New-StatCell 'Differ' $statDiff), 1, 0)
$statsTable.Controls.Add((New-StatCell 'Checked' $statSel), 2, 0)
$stats.Padding = [Windows.Forms.Padding]::new(8, 6, 8, 6)
$stats.Controls.Add($statsTable)

$leftTable = New-Table 1 6
$leftTable.BackColor = $cFill
Add-Col $leftTable 'Percent' 100
Add-Row $leftTable 'Absolute' 96; Add-Row $leftTable 'Absolute' 32; Add-Row $leftTable 'Absolute' 24
Add-Row $leftTable 'Absolute' 24; Add-Row $leftTable 'Absolute' 76; Add-Row $leftTable 'Percent' 100
$leftTable.Controls.Add($avatar, 0, 0)
$leftTable.Controls.Add($lblName, 0, 1)
$leftTable.Controls.Add($lblDate, 0, 2)
$leftTable.Controls.Add($lblPc, 0, 3)
$leftTable.Controls.Add($stats, 0, 4)
$cardLeft.Controls.Add($leftTable)

# ---- Center card: comparison grid
$cardCenter = New-Card
$cardCenter.Padding = [Windows.Forms.Padding]::new(18, 14, 18, 16)
$gridTitle = New-Label 'Comparison with the current state' $cText $cFill 11
$gridTitle.Dock = 'Top'; $gridTitle.Height = 30; $gridTitle.TextAlign = 'MiddleLeft'
$grid = New-Object Windows.Forms.DataGridView
$grid.Dock = 'Fill'; $grid.BackgroundColor = $cFill; $grid.BorderStyle = 'None'
$grid.AllowUserToAddRows = $false; $grid.AllowUserToDeleteRows = $false; $grid.AllowUserToResizeRows = $false
$grid.RowHeadersVisible = $false; $grid.SelectionMode = 'FullRowSelect'; $grid.AutoSizeColumnsMode = 'Fill'
$grid.EnableHeadersVisualStyles = $false; $grid.CellBorderStyle = 'SingleHorizontal'; $grid.GridColor = $cLine
$grid.ColumnHeadersBorderStyle = 'None'; $grid.ColumnHeadersHeightSizeMode = 'DisableResizing'; $grid.ColumnHeadersHeight = 32
$grid.RowTemplate.Height = 28
$grid.DefaultCellStyle.BackColor = $cFill; $grid.DefaultCellStyle.ForeColor = $cText
$grid.DefaultCellStyle.SelectionBackColor = [Drawing.Color]::FromArgb(75, 58, 115); $grid.DefaultCellStyle.SelectionForeColor = [Drawing.Color]::White
$grid.DefaultCellStyle.Padding = [Windows.Forms.Padding]::new(6, 0, 0, 0)
$grid.AlternatingRowsDefaultCellStyle.BackColor = [Drawing.Color]::FromArgb(46, 45, 53)
$grid.ColumnHeadersDefaultCellStyle.BackColor = [Drawing.Color]::FromArgb(36, 35, 41)
$grid.ColumnHeadersDefaultCellStyle.ForeColor = $cMuted
$grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = [Drawing.Color]::FromArgb(36, 35, 41)
$grid.ColumnHeadersDefaultCellStyle.Padding = [Windows.Forms.Padding]::new(6, 0, 0, 0)
$colCheck = New-Object Windows.Forms.DataGridViewCheckBoxColumn
$colCheck.HeaderText = 'Restore'; $colCheck.FillWeight = 11
[void]$grid.Columns.Add($colCheck)
foreach ($c in @(@('Service', 33), @('In backup', 28), @('Current', 28))) {
    $col = New-Object Windows.Forms.DataGridViewTextBoxColumn
    $col.HeaderText = $c[0]; $col.FillWeight = $c[1]; $col.ReadOnly = $true
    [void]$grid.Columns.Add($col)
}
$cardCenter.Controls.AddRange(@($grid, $gridTitle))

# ---- Right card: backups list
$cardRight = New-Card
$cardRight.Padding = [Windows.Forms.Padding]::new(16, 14, 16, 16)
$listTitle = New-Label 'Backups' $cText $cFill 11
$listTitle.Dock = 'Top'; $listTitle.Height = 30; $listTitle.TextAlign = 'MiddleLeft'
$list = New-Object Windows.Forms.ListBox
$list.Dock = 'Fill'; $list.BorderStyle = 'None'; $list.BackColor = $cFill; $list.ForeColor = $cText
$list.DrawMode = 'OwnerDrawFixed'; $list.ItemHeight = 46; $list.IntegralHeight = $false
$cardRight.Controls.AddRange(@($list, $listTitle))

# ---- Top pill: actions + filter
$pill = New-Card 0 $true
$pill.Padding = [Windows.Forms.Padding]::new(12, 7, 12, 7)
$btnNew = New-Button 'New backup...'
$btnCompare = New-Button 'Refresh comparison'
$flowL = New-Object Windows.Forms.FlowLayoutPanel
$flowL.Dock = 'Left'; $flowL.AutoSize = $true; $flowL.WrapContents = $false; $flowL.BackColor = $cFill
$flowL.Controls.AddRange(@($btnNew, $btnCompare))
$filter = New-Object Windows.Forms.TextBox
$filter.Width = 220; $filter.BorderStyle = 'FixedSingle'; $filter.BackColor = [Drawing.Color]::FromArgb(54, 53, 62); $filter.ForeColor = $cText
$lblFilter = New-Label 'Filter service:' $cMuted $cFill 9
$lblFilter.AutoSize = $true; $lblFilter.Dock = 'None'; $lblFilter.Margin = [Windows.Forms.Padding]::new(0, 7, 6, 0)
$filter.Margin = [Windows.Forms.Padding]::new(0, 6, 0, 0)
$flowR = New-Object Windows.Forms.FlowLayoutPanel
$flowR.Dock = 'Right'; $flowR.AutoSize = $true; $flowR.WrapContents = $false; $flowR.BackColor = $cFill
$flowR.Controls.AddRange(@($lblFilter, $filter))
$pill.Controls.AddRange(@($flowR, $flowL))

# ---- Bottom row: status + actions
$status = New-Label '' $cMuted $cOuter 9
$status.TextAlign = 'MiddleLeft'; $status.Padding = [Windows.Forms.Padding]::new(8, 0, 0, 0)
$btnAll = New-Button 'Check all'
$btnNone = New-Button 'Uncheck all'
$btnCsv = New-Button 'Export CSV'
$btnFolder = New-Button 'Open folder'
$btnRestore = New-Button 'Restore checked' $true
$flowB = New-Object Windows.Forms.FlowLayoutPanel
$flowB.Dock = 'Right'; $flowB.AutoSize = $true; $flowB.WrapContents = $false; $flowB.BackColor = $cOuter
$flowB.Controls.AddRange(@($btnAll, $btnNone, $btnCsv, $btnFolder, $btnRestore))
$bottom = New-Object Windows.Forms.Panel
$bottom.Dock = 'Fill'; $bottom.BackColor = $cOuter
$bottom.Controls.AddRange(@($status, $flowB))

# ---- Assemble
$title = New-Label 'SERVICES' $cText $cOuter 13
$main = New-Table 3 1
$main.BackColor = $cOuter
Add-Col $main 'Absolute' 250; Add-Col $main 'Percent' 100; Add-Col $main 'Absolute' 270; Add-Row $main 'Percent' 100
$main.Controls.Add($cardLeft, 0, 0); $main.Controls.Add($cardCenter, 1, 0); $main.Controls.Add($cardRight, 2, 0)

$root = New-Table 1 4
$root.BackColor = $cOuter; $root.Padding = [Windows.Forms.Padding]::new(14)
Add-Col $root 'Percent' 100
Add-Row $root 'Absolute' 38; Add-Row $root 'Absolute' 56; Add-Row $root 'Percent' 100; Add-Row $root 'Absolute' 56
$root.Controls.Add($title, 0, 0); $root.Controls.Add($pill, 0, 1); $root.Controls.Add($main, 0, 2); $root.Controls.Add($bottom, 0, 3)
$form.Controls.Add($root)

# ---- Behavior
function Update-Status {
    $n = @($grid.Rows | Where-Object { $_.Cells[0].Value -eq $true }).Count
    $statSel.Text = "$n"
    $status.Text = $script:baseText
}

function Update-Info {
    $lblName.Text = ''; $lblDate.Text = ''; $lblPc.Text = ''; $statSvc.Text = '-'
    if (-not $list.SelectedItem) { return }
    try {
        $d = Get-Content -LiteralPath (Join-Path $dataDir ($list.SelectedItem + '.json')) -Raw -Encoding UTF8 | ConvertFrom-Json
        $lblName.Text = [string]$list.SelectedItem
        $lblDate.Text = 'created ' + ([datetime]$d.CapturedAt).ToString('yyyy-MM-dd HH:mm')
        $lblPc.Text = [string]$d.Computer
        $statSvc.Text = [string]$d.ServiceCount
    } catch { $lblName.Text = 'Unreadable backup' }
}

function Import-Snapshots([string]$select) {
    $list.Items.Clear(); $script:meta = @{}
    Get-ChildItem -LiteralPath $dataDir -Filter '*.json' | Where-Object { $_.Extension -eq '.json' } |
        Sort-Object LastWriteTime -Descending | ForEach-Object {
            $script:meta[$_.BaseName] = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            [void]$list.Items.Add($_.BaseName)
        }
    $i = $list.Items.IndexOf($select)
    if ($i -lt 0 -and $list.Items.Count) { $i = 0 }
    $list.SelectedIndex = $i
}

function Set-GridFilter {
    $t = $filter.Text.Trim()
    $grid.CurrentCell = $null
    foreach ($row in $grid.Rows) {
        $row.Visible = (-not $t) -or (([string]$row.Cells[1].Value).IndexOf($t, [StringComparison]::OrdinalIgnoreCase) -ge 0)
    }
}

function Set-AllChecked([bool]$value) {
    $script:loading = $true
    foreach ($row in $grid.Rows) { if ($row.Visible -and -not $row.Cells[0].ReadOnly) { $row.Cells[0].Value = $value } }
    $script:loading = $false
    Update-Status
}

function Update-Grid {
    $snap = $list.SelectedItem
    $script:loading = $true
    $grid.Rows.Clear()
    $statDiff.Text = '-'
    if (-not $snap) { $script:loading = $false; $script:baseText = 'No backups found. Use "New backup...".'; Update-Status; return }
    $form.Cursor = [Windows.Forms.Cursors]::WaitCursor
    try {
        $script:rows = @(& $engine -Mode Compare -From $snap -To Current -PassThru)
        foreach ($r in $script:rows) {
            $i = $grid.Rows.Add($false, $r.Name, (Show-State $r.Before), (Show-State $r.After))
            if ($r.Before -eq 'missing' -or $r.After -eq 'missing') {
                # Not restorable: absent from the backup, or the service was deleted.
                $grid.Rows[$i].Cells[0].ReadOnly = $true
                $grid.Rows[$i].DefaultCellStyle.ForeColor = [Drawing.Color]::FromArgb(110, 108, 120)
            }
        }
        $statDiff.Text = [string]$script:rows.Count
        $script:baseText = "Compared with '$snap'. Greyed-out rows = not restorable (removed, or absent from the backup)."
        Set-GridFilter
    } catch { Show-Error $_ } finally { $script:loading = $false; $form.Cursor = [Windows.Forms.Cursors]::Default }
    Update-Status
}

$list.Add_DrawItem({
    param($s, $e)
    if ($e.Index -lt 0) { return }
    $name = [string]$list.Items[$e.Index]
    $e.Graphics.FillRectangle($brFill, $e.Bounds)
    if (($e.State -band [Windows.Forms.DrawItemState]::Selected) -ne 0) {
        $e.Graphics.FillRectangle($brSel, [Drawing.Rectangle]::new($e.Bounds.X, $e.Bounds.Y + 2, $e.Bounds.Width, $e.Bounds.Height - 4))
    }
    $w = $e.Bounds.Width - 20
    $e.Graphics.DrawString($name, $fBold, $brText, [Drawing.RectangleF]::new($e.Bounds.X + 10, $e.Bounds.Y + 6, $w, 18), $sfEllipsis)
    $e.Graphics.DrawString([string]$script:meta[$name], $fRegular, $brMuted, [Drawing.RectangleF]::new($e.Bounds.X + 10, $e.Bounds.Y + 25, $w, 18), $sfEllipsis)
})

$grid.Add_CurrentCellDirtyStateChanged({ if ($grid.IsCurrentCellDirty) { $grid.CommitEdit('CurrentCellChange') } })
$grid.Add_CellValueChanged({ if (-not $script:loading) { Update-Status } })
$list.Add_SelectedIndexChanged({ Update-Info; Update-Grid })
$btnCompare.Add_Click({ Update-Grid })
$filter.Add_TextChanged({ Set-GridFilter })
$btnFolder.Add_Click({ Start-Process explorer.exe -ArgumentList ('"{0}"' -f $dataDir) })
$btnAll.Add_Click({ Set-AllChecked $true })
$btnNone.Add_Click({ Set-AllChecked $false })

$btnCsv.Add_Click({
    if ($script:rows.Count -eq 0) { return }
    $dlg = New-Object Windows.Forms.SaveFileDialog
    $dlg.Filter = 'CSV|*.csv'; $dlg.FileName = 'Services.Diff.csv'
    if ($dlg.ShowDialog() -eq 'OK') { $script:rows | Export-Csv -LiteralPath $dlg.FileName -NoTypeInformation -Encoding UTF8 }
})

$btnNew.Add_Click({
    $name = [Microsoft.VisualBasic.Interaction]::InputBox('Backup name (letters, numbers, . _ -):', 'New backup', 'Custom.' + (Get-Date -Format 'yyyyMMdd-HHmm'))
    if (-not $name) { return }
    if ($name -notmatch '^[A-Za-z0-9_.-]+$') { [void][Windows.Forms.MessageBox]::Show('Invalid name.', 'Error', 'OK', 'Warning'); return }
    $args2 = @{ Mode = 'Capture'; Snapshot = $name }
    if (Test-Path -LiteralPath (Join-Path $dataDir ($name + '.json'))) {
        $q = if ($name -eq 'Windows.Default.Services') { 'This is the backup of the ORIGINAL Windows state. Replace it anyway?' } else { "'$name' already exists (the previous version is kept as .previous). Replace it?" }
        if ([Windows.Forms.MessageBox]::Show($q, 'Confirm', 'YesNo', 'Warning') -ne 'Yes') { return }
        $args2.Force = $true
    }
    if ([Windows.Forms.MessageBox]::Show('Include a full export of the services registry key (.full.reg)? It lets you recover removed services, but the file is large.', 'Full backup', 'YesNo', 'Question') -eq 'Yes') { $args2.Full = $true }
    $form.Cursor = [Windows.Forms.Cursors]::WaitCursor
    try {
        $out = (& $engine @args2 *>&1 | Out-String).Trim()
        Import-Snapshots $name
        $script:baseText = $out
        Update-Status
    } catch { Show-Error $_ } finally { $form.Cursor = [Windows.Forms.Cursors]::Default }
})

$btnRestore.Add_Click({
    $snap = $list.SelectedItem
    $names = @($grid.Rows | Where-Object { $_.Cells[0].Value -eq $true } | ForEach-Object { $_.Cells[1].Value })
    if (-not $snap -or $names.Count -eq 0) { [void][Windows.Forms.MessageBox]::Show('Check at least one service.', 'Restore', 'OK', 'Information'); return }
    $msg = "Restore the startup type of $($names.Count) service(s) to the state in '$snap'?`n`nAn automatic backup of the current state (PreRestore.*) will be created first. The change takes effect after a restart."
    if ([Windows.Forms.MessageBox]::Show($msg, 'Confirm restore', 'YesNo', 'Warning') -ne 'Yes') { return }
    $form.Cursor = [Windows.Forms.Cursors]::WaitCursor
    try {
        $out = (& $engine -Mode Restore -Snapshot $snap -Services ($names -join ',') *>&1 | Out-String).Trim()
        Import-Snapshots $snap
        [void][Windows.Forms.MessageBox]::Show($out, 'Result', 'OK', 'Information')
    } catch { Show-Error $_ } finally { $form.Cursor = [Windows.Forms.Cursors]::Default }
})

& $engine -Mode Organize
Import-Snapshots 'Windows.Default.Services'
[void]$form.ShowDialog()
} catch {
    # The launcher hides the console, so surface startup errors in a dialog and a log file.
    $msg = ($_ | Out-String)
    try { Set-Content -LiteralPath (Join-Path $env:TEMP 'ServiceBackupUI.log') -Value $msg -Encoding UTF8 } catch { }
    [void][Windows.Forms.MessageBox]::Show($msg, 'TheKOS - error opening the interface', 'OK', 'Error')
}
