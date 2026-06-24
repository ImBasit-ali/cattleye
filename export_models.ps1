# PyTorch weights live in assets/models/*.pth and *.pt
# Start the Python backend instead of exporting to ONNX/TFLite:
#
#   pip install -r python_backend/requirements.txt
#   python -m uvicorn python_backend.main:app --host 0.0.0.0 --port 8000
#
Write-Host "PyTorch models in assets/models/" -ForegroundColor Green
Get-ChildItem (Join-Path $PSScriptRoot "assets\models") -File |
  Where-Object { $_.Extension -in '.pth', '.pt' } |
  Format-Table Name, @{N='MB';E={[math]::Round($_.Length/1MB,2)}}
