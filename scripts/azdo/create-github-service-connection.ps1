<#
Create or locate a GitHub service connection in Azure DevOps and persist its id to .azdo_env
Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\azdo\create-github-service-connection.ps1 \
  -OrgUrl 'https://dev.azure.com/ORG/' -Project 'MyProject' -Name 'GitHub-Conn'
#>
Param(
  [Parameter(Mandatory=$true)][string]$OrgUrl,
  [Parameter(Mandatory=$true)][string]$Project,
  [string]$Name = "GitHub-Conn"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$azdoPatFile = Join-Path $scriptDir ".azdo_pat"
$githubPatFile = Join-Path $scriptDir ".github_pat"
$envFile = Join-Path $scriptDir ".azdo_env"

function Read-Pat($path, $key) {
  if (-not (Test-Path $path)) { return $null }
  foreach ($line in Get-Content $path) {
    if ($line -match "^\s*$key\s*=\s*(.+)\s*$") { return $matches[1].Trim() }
  }
  return $null
}

$AZDO_PAT = Read-Pat $azdoPatFile "AZDO_PAT"
$GITHUB_PAT = Read-Pat $githubPatFile "GITHUB_PAT"

if (-not $AZDO_PAT) { Write-Error "AZDO_PAT not found in $azdoPatFile"; exit 2 }
if (-not $GITHUB_PAT) { Write-Warning "GITHUB_PAT not found in $githubPatFile; creation may fail if token missing" }

$env:AZURE_DEVOPS_EXT_PAT = $AZDO_PAT

# Get project id
$projId = (& az devops project show --project $Project --org $OrgUrl --query id -o tsv) -replace "`r","" -replace "`n",""
if (-not $projId) { Write-Error "Unable to determine project id for $Project"; exit 3 }

Write-Host "Project id: $projId"

# Try to find existing GitHub endpoint scoped to project
$listJson = $null
try { $listJson = (& az devops service-endpoint list --project $Project --org $OrgUrl -o json) } catch { }
if (-not $listJson) {
  try { $listJson = (& az devops service-endpoint list --org $OrgUrl -o json) } catch { }
}
$scId = $null
if ($listJson) {
  try {
    $endpoints = $listJson | ConvertFrom-Json
    foreach ($e in $endpoints) {
      if ($e.type -eq "github") {
        $refs = $e.serviceEndpointProjectReferences
        if ($refs) {
          foreach ($r in $refs) {
            if ($r.projectReference -and $r.projectReference.id -eq $projId) {
              $scId = $e.id; break
            }
          }
        }
      }
      if ($scId) { break }
    }
  } catch { }
}

if ($scId) {
  Write-Host "Found existing GitHub service connection id: $scId"
} else {
  Write-Host "No existing GitHub service connection found; creating via REST..."
  $apiUrl = ($OrgUrl.TrimEnd("/") + "/_apis/serviceendpoint/endpoints?api-version=6.0-preview.4")
  $payload = @{
    name = $Name
    type = "github"
    url  = "https://github.com"
    authorization = @{
      scheme = "PersonalAccessToken"
      parameters = @{ accessToken = $GITHUB_PAT }
    }
    data = @{}
    serviceEndpointProjectReferences = @(@{ projectReference = @{ id = $projId }; name = $Project; isShared = $true })
  }
  $basic = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$AZDO_PAT"))
  try {
    $resp = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers @{ Authorization = "Basic $basic"; "Content-Type" = "application/json" } -Body (ConvertTo-Json $payload -Depth 10) -ErrorAction Stop
    $scId = $resp.id
    Write-Host "Created service connection id: $scId"
  } catch [System.Net.WebException] {
    $resp = $_.Exception.Response
    if ($resp -and ($resp.StatusCode.Value__ -eq 409)) {
      Write-Warning "Received 409 (already exists). Re-listing project endpoints to capture id..."
      try { $listJson = (& az devops service-endpoint list --project $Project --org $OrgUrl -o json) } catch { }
      if ($listJson) {
        try {
          $endpoints = $listJson | ConvertFrom-Json
          foreach ($e in $endpoints) {
            if ($e.type -eq "github") {
              $refs = $e.serviceEndpointProjectReferences
              if ($refs) {
                foreach ($r in $refs) { if ($r.projectReference -and $r.projectReference.id -eq $projId) { $scId = $e.id; break } }
              }
            }
            if ($scId) { break }
          }
        } catch { }
      }
    } else {
      $body = ""
      if ($resp) { $sr = New-Object System.IO.StreamReader($resp.GetResponseStream()); $body = $sr.ReadToEnd(); $sr.Close() }
      Write-Error "Failed creating service connection. HTTP: $($resp.StatusCode) Body: $body"
      exit 4
    }
  } catch {
    Write-Error "Unexpected error: $_"
    exit 5
  }
}

if (-not $scId) { Write-Error "Unable to determine service connection id."; exit 6 }

# enable-for-all (best-effort)
try { & az devops service-endpoint update --id $scId --enable-for-all true --org $OrgUrl --project $Project > $null 2>&1 } catch {}

# Persist to .azdo_env (atomic)
if (-not (Test-Path $envFile)) {
  "## Azure DevOps environment variables (local)" | Out-File -FilePath $envFile -Encoding UTF8
}
$lines = Get-Content $envFile | Where-Object { $_ -notmatch '^AZDO_GITHUB_SERVICE_CONNECTION_ID=' }
$lines += "AZDO_GITHUB_SERVICE_CONNECTION_ID=$scId"
$lines | Set-Content -Path $envFile -Encoding UTF8

Write-Host "Updated $envFile with AZDO_GITHUB_SERVICE_CONNECTION_ID=$scId"
