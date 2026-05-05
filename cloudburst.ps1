# Cloudburst ML Prediction Runner
# Usage: .\cloudburst.ps1 -lat 31.5173 -lon 74.3411 -start 2026-04-20 -end 2026-05-04

param(
    [Parameter(Mandatory=$false)]
    [double]$lat = 31.5173,
    
    [Parameter(Mandatory=$false)]
    [double]$lon = 74.3411,
    
    [Parameter(Mandatory=$false)]
    [string]$start = "2026-04-20",
    
    [Parameter(Mandatory=$false)]
    [string]$end = "2026-05-04"
)

# Navigate to cloudburst folder
$cloudburst_path = Join-Path $PSScriptRoot "cloudburst"
Set-Location $cloudburst_path

# Activate venv
& "$cloudburst_path\venv\Scripts\Activate.ps1"

# Run prediction
python src/predict_openmeteo.py --latitude $lat --longitude $lon --start-date $start --end-date $end
