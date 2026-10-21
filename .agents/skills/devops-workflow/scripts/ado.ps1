# Azure DevOps REST 헬퍼 (PowerShell 7)
#
# 왜 필요한가: 이 PC의 az CLI 는 콘솔 코드페이지(cp949) 를 거치면서
#   - PR 제목/본문, Work Item 댓글에 넣은 한글을 통째로 버리고
#   - 응답에 cp949 로 표현 못 하는 문자(일본어 등)가 있으면 그것도 버린다.
# 인자로 넘기든 @파일로 넘기든 같다. 그래서 비ASCII 가 한 글자라도 들어가는
# 조작은 REST 로 처리한다. Invoke-RestMethod 는 요청·응답 모두 UTF-8 을
# 그대로 다루므로 이 문제가 발생하지 않는다.
#
# 인증: az 로그인 세션에서 파생된 토큰을 쓴다. 새 PAT 를 발급하지 않는다.
#
# 사용:
#   . "$HOME\.claude\skills\devops-workflow\scripts\ado.ps1"
#   Add-AdoWorkItemComment -Id 351 -Html "<b>완료</b><br>내용"

$script:AdoResourceId = '499b84ac-1321-427f-aa17-267ca6975798'  # Azure DevOps 고정 앱 ID

function Get-AdoOrganization {
    <#  기본 조직: az devops configure 에 설정된 값을 쓴다.  #>
    if ($env:ADO_ORG) { return $env:ADO_ORG }
    $line = (az devops configure --list 2>$null) | Where-Object { $_ -match '^\s*organization\s*=' }
    if (-not $line) { throw "조직을 찾을 수 없다. az devops configure --defaults organization=... 로 설정하거나 ADO_ORG 를 지정하라." }
    return ($line -split '=', 2)[1].Trim().TrimEnd('/')
}

function Get-AdoToken {
    $tok = az account get-access-token --resource $script:AdoResourceId --query accessToken -o tsv 2>$null
    if (-not $tok) { throw "az 로그인 토큰을 얻지 못했다. az login 을 먼저 수행하라." }
    return $tok
}

function Invoke-Ado {
    <#
    .SYNOPSIS  Azure DevOps REST 를 UTF-8 로 호출한다.
    .PARAMETER Path  조직 URL 뒤에 붙는 경로. 예: 'prod/_apis/wit/workitems/351'
    .PARAMETER Body  해시테이블/배열이면 JSON 으로 직렬화하고, 문자열이면 그대로 보낸다.
    .EXAMPLE  Invoke-Ado -Path 'prod/_apis/wit/workitems/351'
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Method = 'GET',
        $Body,
        [string]$ApiVersion = '7.1',
        [string]$ContentType = 'application/json; charset=utf-8',
        [string]$Organization
    )
    if (-not $Organization) { $Organization = Get-AdoOrganization }
    $sep = if ($Path -match '\?') { '&' } else { '?' }
    $uri = "$Organization/$($Path.TrimStart('/'))$sep" + "api-version=$ApiVersion"

    $params = @{
        Uri     = $uri
        Method  = $Method
        Headers = @{ Authorization = "Bearer $(Get-AdoToken)" }
    }
    if ($null -ne $Body) {
        $json = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 20 }
        # UTF-8 바이트로 직접 넘긴다. 문자열로 넘기면 인코딩이 흔들린다.
        $params.Body        = [System.Text.Encoding]::UTF8.GetBytes($json)
        $params.ContentType = $ContentType
    }
    Invoke-RestMethod @params
}

# ─── Work Item ────────────────────────────────────────────────────────────────

function Get-AdoWorkItem {
    param([Parameter(Mandatory)][int]$Id)
    Invoke-Ado -Path "_apis/wit/workitems/$Id"
}

function Add-AdoWorkItemComment {
    <#  본문은 HTML 이다. 줄바꿈은 <br>, 목록은 <ul><li>.  #>
    param(
        [Parameter(Mandatory)][int]$Id,
        [Parameter(Mandatory)][string]$Html,
        [Parameter(Mandatory=$false)][string]$Project
    )
    if (-not $Project) { $Project = $env:ADO_PROJECT }
    if (-not $Project) { throw "Project 를 지정하거나 ADO_PROJECT 를 설정하라." }
    Invoke-Ado -Path "$Project/_apis/wit/workItems/$Id/comments" -Method POST `
               -Body @{ text = $Html } -ApiVersion '7.1-preview.3'
}

function Set-AdoWorkItemField {
    <#  임의 필드 갱신. 상태 전환은 Set-AdoWorkItemState 를 쓰라.  #>
    param(
        [Parameter(Mandatory)][int]$Id,
        [Parameter(Mandatory)][hashtable]$Fields
    )
    $ops = @($Fields.GetEnumerator() | ForEach-Object {
        @{ op = 'add'; path = "/fields/$($_.Key)"; value = $_.Value }
    })
    # 단일 원소도 JSON 배열이어야 하므로 직접 직렬화한다.
    $json = ConvertTo-Json -InputObject @($ops) -Depth 10
    if ($ops.Count -eq 1 -and -not $json.TrimStart().StartsWith('[')) { $json = "[$json]" }
    Invoke-Ado -Path "_apis/wit/workitems/$Id" -Method PATCH -Body $json `
               -ContentType 'application/json-patch+json; charset=utf-8'
}

function Set-AdoWorkItemState {
    <#  상태명은 프로세스 템플릿을 따른다(이 조직은 할일/진행중/완료).  #>
    param(
        [Parameter(Mandatory)][int]$Id,
        [Parameter(Mandatory)][string]$State
    )
    Set-AdoWorkItemField -Id $Id -Fields @{ 'System.State' = $State }
}

# ─── Pull Request ─────────────────────────────────────────────────────────────

function New-AdoPullRequest {
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$SourceBranch,   # 브랜치명만. refs/heads/ 는 자동으로 붙는다
        [Parameter(Mandatory)][string]$TargetBranch,
        [Parameter(Mandatory)][string]$Title,
        [string]$Description = '',
        [int[]]$WorkItemIds = @()
    )
    $body = @{
        sourceRefName = "refs/heads/$($SourceBranch -replace '^refs/heads/','')"
        targetRefName = "refs/heads/$($TargetBranch -replace '^refs/heads/','')"
        title         = $Title
        description   = $Description
    }
    if ($WorkItemIds.Count -gt 0) {
        $body.workItemRefs = @($WorkItemIds | ForEach-Object { @{ id = "$_" } })
    }
    Invoke-Ado -Path "$Project/_apis/git/repositories/$Repository/pullrequests" -Method POST -Body $body
}

function Update-AdoPullRequest {
    <#  제목/본문 수정. az repos pr update 는 비ASCII 를 유실하므로 이걸 쓰라.  #>
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][int]$Id,
        [string]$Title,
        [string]$Description
    )
    $body = @{}
    if ($PSBoundParameters.ContainsKey('Title'))       { $body.title = $Title }
    if ($PSBoundParameters.ContainsKey('Description')) { $body.description = $Description }
    if ($body.Count -eq 0) { throw "Title 또는 Description 중 하나는 지정하라." }
    Invoke-Ado -Path "$Project/_apis/git/repositories/$Repository/pullrequests/$Id" -Method PATCH -Body $body
}

function Get-AdoPullRequest {
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][int]$Id
    )
    Invoke-Ado -Path "$Project/_apis/git/repositories/$Repository/pullrequests/$Id"
}

function Add-AdoPullRequestComment {
    <#  PR 에 새 댓글 스레드를 만든다. az repos pr 에는 댓글 명령이 없다.  #>
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][int]$Id,
        [Parameter(Mandatory)][string]$Text
    )
    $body = @{
        comments = @(@{ parentCommentId = 0; content = $Text; commentType = 1 })
        status   = 1
    }
    Invoke-Ado -Path "$Project/_apis/git/repositories/$Repository/pullrequests/$Id/threads" -Method POST -Body $body
}
