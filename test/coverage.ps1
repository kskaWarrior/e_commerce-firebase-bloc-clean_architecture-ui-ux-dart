# This file reads code coverage from lcov.info and summarizes by layer
# (domain, data, presentation, other). Execute it from project root with:
# powershell -NoProfile -ExecutionPolicy Bypass -File test/coverage.ps1

# Powershell command to show lowest-covered files per layer:
# powershell -NoProfile -ExecutionPolicy Bypass -File test/coverage_hotspots.ps1 -Top 5




$lcovFile = "coverage/lcov.info"

if (-not (Test-Path $lcovFile)) {
	Write-Host "File not found: $lcovFile"
	exit 1
}

$records = @()
$currentFile = $null
$currentLF = 0
$currentLH = 0

Get-Content $lcovFile | ForEach-Object {
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

			$records += [PSCustomObject]@{
				File  = $currentFile
				Layer = $layer
				LF    = $currentLF
				LH    = $currentLH
			}
		}

		$currentFile = $null
		$currentLF = 0
		$currentLH = 0
	}
}

$totalLF = ($records | Measure-Object -Property LF -Sum).Sum
$totalLH = ($records | Measure-Object -Property LH -Sum).Sum
$totalPct = if ($totalLF -gt 0) {
	[math]::Round(($totalLH / $totalLF) * 100, 2)
}
else {
	0
}

Write-Host ""
Write-Host "TOTAL: $totalPct% ($totalLH/$totalLF)"
Write-Host ""

$records |
	Group-Object Layer |
	ForEach-Object {
		$lf = ($_.Group | Measure-Object -Property LF -Sum).Sum
		$lh = ($_.Group | Measure-Object -Property LH -Sum).Sum
		$pct = if ($lf -gt 0) {
			[math]::Round(($lh / $lf) * 100, 2)
		}
		else {
			0
		}

		[PSCustomObject]@{
			Layer    = $_.Name
			Coverage = "$pct% ($lh/$lf)"
			Percent  = $pct
		}
	} |
	Sort-Object Percent -Descending |
	Format-Table -AutoSize