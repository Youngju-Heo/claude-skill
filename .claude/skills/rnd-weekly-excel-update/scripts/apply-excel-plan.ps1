# Write a weekly plan (build-excel-plan.py output) into the running Excel app.
# Must run under Windows PowerShell 5.1 (powershell.exe): pwsh 7 has no
# Marshal.GetActiveObject.
#
# Usage:
#   powershell.exe -NoProfile -File apply-excel-plan.ps1 -PlanFile plan.json -OutFile result.json [-DryRun]
#   [-WorkbookIndex n]   pick the n-th workbook (1-based) when several contain the sheet
#
# Layout of the sheet (columns): B=LAB, C/H=category, D/I=owner, E/J=name,
# F/K=progress text (left: done, right: plan), G/L=ids.
param(
    [Parameter(Mandatory)][string]$PlanFile,
    [Parameter(Mandatory)][string]$OutFile,
    [int]$WorkbookIndex = 0,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

function Write-Json($obj, $path) {
    $json = $obj | ConvertTo-Json -Depth 10
    [IO.File]::WriteAllText($path, $json, (New-Object Text.UTF8Encoding $false))
}
function T($cell) { ([string]$cell.Value2).Trim() }
function Set-IdCell($cell, $item) {
    # Show the id text; link to the first id (one hyperlink per cell), keeping the cell font.
    $cell.Value2 = $item.ids
    if ($item.url) {
        $name = $cell.Font.Name; $size = $cell.Font.Size
        $ws.Hyperlinks.Add($cell, $item.url, '', $item.url, $item.ids) | Out-Null
        $cell.Font.Name = $name; $cell.Font.Size = $size
    }
}

$plan = Get-Content -Raw -Encoding UTF8 $PlanFile | ConvertFrom-Json

try { $xl = [Runtime.InteropServices.Marshal]::GetActiveObject('Excel.Application') }
catch { throw "Excel app is not running. Open the workbook in Excel first." }

$candidates = @()
foreach ($wb in $xl.Workbooks) {
    foreach ($s in $wb.Worksheets) { if ($s.Name -eq $plan.sheet) { $candidates += $wb } }
}
if ($candidates.Count -eq 0) { throw "No open workbook has the target sheet." }
if ($candidates.Count -gt 1 -and $WorkbookIndex -eq 0) {
    $names = ($candidates | ForEach-Object { $_.FullName }) -join "`n"
    throw "Several workbooks have the target sheet. Pass -WorkbookIndex:`n$names"
}
$wb = if ($WorkbookIndex -gt 0) { $candidates[$WorkbookIndex - 1] } else { $candidates[0] }
$ws = $wb.Worksheets.Item($plan.sheet)

# Locate the header row ("LAB" in column B) and block start rows.
$last = $ws.UsedRange.Row + $ws.UsedRange.Rows.Count - 1
$header = 0
for ($r = 1; $r -le $last; $r++) { if ((T $ws.Cells.Item($r, 2)) -eq 'LAB') { $header = $r; break } }
if ($header -eq 0) { throw "Header row with 'LAB' in column B not found." }
$starts = @()
for ($r = $header + 1; $r -le $last; $r++) { if ((T $ws.Cells.Item($r, 2)) -ne '') { $starts += $r } }

$layout = @()
foreach ($b in $plan.blocks) {
    $start = 0
    for ($i = 0; $i -lt $starts.Count; $i++) {
        if ((T $ws.Cells.Item($starts[$i], 2)) -eq $b.lab) {
            $start = $starts[$i]
            $end = if ($i + 1 -lt $starts.Count) { $starts[$i + 1] - 1 } else { $last }
        }
    }
    if ($start -eq 0) { throw "Block not found in column B: $($b.lab)" }
    $dataEnd = $end
    for ($r = $start; $r -le $end; $r++) {
        if ((T $ws.Cells.Item($r, 3)) -eq $plan.etc_label) { $dataEnd = $r - 1; break }
    }
    $owners = @{}
    for ($r = $start; $r -le $dataEnd; $r++) {
        $n = T $ws.Cells.Item($r, 5); $o = [string]$ws.Cells.Item($r, 4).Value2
        if ($n -ne '' -and $o.Trim() -ne '') { $owners[$n] = $o }
    }
    $need = 0
    foreach ($g in $b.groups) { $need += [Math]::Max([Math]::Max(@($g.done).Count, @($g.plan).Count), 1) }
    $layout += [pscustomobject]@{ block = $b; lab = $b.lab; start = $start; end = $end
        data_end = $dataEnd; current_rows = $dataEnd - $start + 1; needed_rows = $need; owners = $owners }
}

$summary = @($layout | ForEach-Object { [ordered]@{ lab = $_.lab; start = $_.start; data_end = $_.data_end
    block_end = $_.end; current_rows = $_.current_rows; needed_rows = $_.needed_rows } })
if ($DryRun) {
    Write-Json ([ordered]@{ workbook = $wb.FullName; dry_run = $true; blocks = $summary }) $OutFile
    Write-Output "Dry run written to $OutFile"
    return
}

$xl.DisplayAlerts = $false
try {
    # Bottom block first so row shifts do not move blocks still to be processed.
    foreach ($L in ($layout | Sort-Object start -Descending)) {
        $s = $L.start; $m = $L.current_rows; $n = $L.needed_rows
        $ws.Range("B${s}:B$($L.end)").UnMerge()
        $ws.Range("C${s}:L$($L.data_end)").UnMerge()
        if ($n -gt $m) { $ws.Range("A$($s + 1):A$($s + $n - $m)").EntireRow.Insert() | Out-Null }
        if ($n -lt $m) { $ws.Range("A$($s + $n):A$($s + $m - 1)").EntireRow.Delete() | Out-Null }
        $dataEnd = $s + $n - 1; $blockEnd = $L.end + ($n - $m)
        $ws.Range("C${s}:L$dataEnd").ClearHyperlinks()
        $ws.Range("C${s}:L$dataEnd").ClearContents() | Out-Null

        $r = $s; $catStart = $s; $prevCat = $null
        foreach ($g in $L.block.groups) {
            $done = @($g.done); $pl = @($g.plan)
            $rows = [Math]::Max([Math]::Max($done.Count, $pl.Count), 1)
            $owner = if ($L.owners.ContainsKey($g.name)) { $L.owners[$g.name] } else { $g.default_owner }
            if ($g.category -ne $prevCat) {
                if ($prevCat -ne $null -and $r - 1 -gt $catStart) {
                    $ws.Range("C${catStart}:C$($r - 1)").Merge(); $ws.Range("H${catStart}:H$($r - 1)").Merge()
                }
                $ws.Cells.Item($r, 3).Value2 = $g.category; $ws.Cells.Item($r, 8).Value2 = $g.category
                $catStart = $r; $prevCat = $g.category
            }
            $ws.Cells.Item($r, 4).Value2 = $owner; $ws.Cells.Item($r, 9).Value2 = $owner
            $ws.Cells.Item($r, 5).Value2 = $g.name; $ws.Cells.Item($r, 10).Value2 = $g.name
            for ($k = 0; $k -lt $done.Count; $k++) {
                $ws.Cells.Item($r + $k, 6).Value2 = $done[$k].text; Set-IdCell $ws.Cells.Item($r + $k, 7) $done[$k]
            }
            for ($k = 0; $k -lt $pl.Count; $k++) {
                $ws.Cells.Item($r + $k, 11).Value2 = $pl[$k].text; Set-IdCell $ws.Cells.Item($r + $k, 12) $pl[$k]
            }
            if ($rows -gt 1) {
                $ws.Range("D${r}:D$($r + $rows - 1)").Merge(); $ws.Range("I${r}:I$($r + $rows - 1)").Merge()
            }
            $r += $rows
        }
        if ($r - 1 -gt $catStart) { $ws.Range("C${catStart}:C$($r - 1)").Merge(); $ws.Range("H${catStart}:H$($r - 1)").Merge() }
        if ($blockEnd -gt $s) { $ws.Range("B${s}:B$blockEnd").Merge() }
    }
} finally { $xl.DisplayAlerts = $true }

# Read back what is now in the blocks for verification.
$check = @()
$starts2 = @()
$last = $ws.UsedRange.Row + $ws.UsedRange.Rows.Count - 1
for ($r = $header + 1; $r -le $last; $r++) { if ((T $ws.Cells.Item($r, 2)) -ne '') { $starts2 += $r } }
foreach ($b in $plan.blocks) {
    for ($i = 0; $i -lt $starts2.Count; $i++) {
        if ((T $ws.Cells.Item($starts2[$i], 2)) -ne $b.lab) { continue }
        $e = if ($i + 1 -lt $starts2.Count) { $starts2[$i + 1] - 1 } else { $last }
        for ($r = $starts2[$i]; $r -le $e; $r++) {
            $row = [ordered]@{ row = $r }
            foreach ($c in 3..12) { $row["c$c"] = [string]$ws.Cells.Item($r, $c).Value2 }
            foreach ($c in 7, 12) {
                $h = $ws.Cells.Item($r, $c).Hyperlinks
                $row["link$c"] = if ($h.Count -gt 0) { $h.Item(1).Address } else { '' }
            }
            $check += $row
        }
    }
}
Write-Json ([ordered]@{ workbook = $wb.FullName; dry_run = $false; blocks = $summary; rows = $check }) $OutFile
Write-Output "Applied. Read-back written to $OutFile"
