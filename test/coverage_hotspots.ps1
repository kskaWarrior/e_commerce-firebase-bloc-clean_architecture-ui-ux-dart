param(
  [int]$Top = 5,
  [string]$LcovFile = "coverage/lcov.info"
)

if (-not (Test-Path $LcovFile)) {
  Write-Host "File not found: $LcovFile"
  exit 1
}

$records = @()
$currentFile = $null
$currentLF = 0
$currentLH = 0

Get-Content $LcovFile | ForEach-Object {
  if ($_ -match '^SF:(.*)$') {
    $currentFile = $matches[1]
  }
  elseif ($_ -match '^LF:(\d+)$') {
    $currentLF = [int]$matches[1]
  }
  elseif ($_ -match '^LH:(\d+)$') {
    $currentLH = [int]$matches[1]
  }
  elseif ($_ -eq 'end_of_record') {
    if ($currentFile) {
      $layer = 'other'
      if ($currentFile -match '(^|[\\/])lib[\\/]domain([\\/]|$)') {
        $layer = 'domain'
      }
      elseif ($currentFile -match '(^|[\\/])lib[\\/]data([\\/]|$)') {
        $layer = 'data'
      }
      elseif ($currentFile -match '(^|[\\/])lib[\\/]presentation([\\/]|$)') {
        $layer = 'presentation'
      }

      $pct = if ($currentLF -gt 0) {
        [math]::Round(($currentLH / $currentLF) * 100, 2)
      }
      else {
        0
      }

      $records += [PSCustomObject]@{
        File    = $currentFile
        Layer   = $layer
        LF      = $currentLF
        LH      = $currentLH
        Percent = $pct
      }
    }

    $currentFile = $null
    $currentLF = 0
    $currentLH = 0
  }
}

$layers = @('domain', 'data', 'presentation')

foreach ($layer in $layers) {
  Write-Host ""
  Write-Host "=== $layer (lowest $Top files) ==="

  $rows = $records |
    Where-Object { $_.Layer -eq $layer } |
    Sort-Object Percent, File |
    Select-Object -First $Top

  if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "No files found for layer: $layer"
    continue
  }

  $rows |
    Select-Object @{Name='Coverage';Expression={"$($_.Percent)% ($($_.LH)/$($_.LF))"}}, File |
    Format-Table -AutoSize
}
