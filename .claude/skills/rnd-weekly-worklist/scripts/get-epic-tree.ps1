# Collect all descendants of top work items and print them as JSON.
# Usage:
#   pwsh -File get-epic-tree.ps1 -Project prod -RootIds 184,57 -OutFile out.json [-Since 2026-11-02]
# -Since: drop finished items not changed since that date (open items are kept).
# Output: JSON array of { id, parent, type, state, title, assigned_to,
#   changed, state_changed, depth } ordered as a tree (depth-first).
param(
    [Parameter(Mandatory)][string]$Project,
    [Parameter(Mandatory)][string]$RootIds,   # comma-separated, e.g. "184,57"
    [Parameter(Mandatory)][string]$OutFile,
    [string]$Since
)
$ErrorActionPreference = 'Stop'
$roots = @($RootIds -split ',' | ForEach-Object { [int]$_.Trim() })
. "$HOME/.claude/skills/devops-workflow/scripts/ado.ps1"
if (-not $env:ADO_ORG) { $env:ADO_ORG = 'https://dev.azure.com/cberrydevops' }

$parentOf = @{}
$children = @{}
foreach ($root in $roots) {
    $wiql = "SELECT [System.Id] FROM WorkItemLinks WHERE [Source].[System.Id] = $root " +
            "AND [System.Links.LinkType] = 'System.LinkTypes.Hierarchy-Forward' MODE (Recursive)"
    $res = Invoke-Ado -Path "$Project/_apis/wit/wiql" -Method POST -Body @{ query = $wiql }
    foreach ($rel in $res.workItemRelations) {
        $t = [int]$rel.target.id
        if ($rel.source) {
            $s = [int]$rel.source.id
            $parentOf[$t] = $s
            if (-not $children.ContainsKey($s)) { $children[$s] = [System.Collections.Generic.List[int]]::new() }
            if (-not $children[$s].Contains($t)) { $children[$s].Add($t) }
        }
    }
}

$ids = @(@($roots) + @($parentOf.Keys) | Select-Object -Unique)
$fields = 'System.Id','System.WorkItemType','System.State','System.Title','System.AssignedTo',
          'System.ChangedDate','Microsoft.VSTS.Common.StateChangeDate'
$info = @{}
for ($i = 0; $i -lt $ids.Count; $i += 200) {
    $chunk = @($ids[$i..([Math]::Min($i + 199, $ids.Count - 1))])
    $batch = Invoke-Ado -Path "$Project/_apis/wit/workitemsbatch" -Method POST `
                        -Body @{ ids = @($chunk); fields = $fields }
    foreach ($w in $batch.value) { $info[[int]$w.id] = $w.fields }
}

$out = [System.Collections.Generic.List[object]]::new()
function Walk([int]$id, [int]$depth) {
    $f = $info[$id]
    $sc = $f.'Microsoft.VSTS.Common.StateChangeDate'
    $row = [ordered]@{
        id            = $id
        parent        = $parentOf[$id]
        type          = $f.'System.WorkItemType'
        state         = $f.'System.State'
        title         = $f.'System.Title'
        assigned_to   = $f.'System.AssignedTo'.displayName
        changed       = ([datetime]$f.'System.ChangedDate').ToString('yyyy-MM-dd')
        state_changed = if ($sc) { ([datetime]$sc).ToString('yyyy-MM-dd') } else { $null }
        depth         = $depth
    }
    if (-not $Since -or $depth -eq 0 -or $row.changed -ge $Since -or $row.state -notin 'Done','Closed','Removed','완료','제거됨') {
        $out.Add($row)
    }
    if ($children.ContainsKey($id)) { foreach ($c in $children[$id]) { Walk $c ($depth + 1) } }
}
foreach ($r in $roots) { Walk $r 0 }
ConvertTo-Json -InputObject @($out) -Depth 5 | Set-Content -Path $OutFile -Encoding utf8
Write-Output "Wrote $($out.Count) items to $OutFile"
