# Script de démarrage pour HyperV Manager
Write-Host "=== HyperV Manager - Démarrage ===" -ForegroundColor Cyan
Write-Host ""

# Vérifier si Python est installé
$pythonCmd = $null

# Chercher dans le PATH d'abord
$pythonCommands = @('python', 'python3', 'py')
foreach ($cmd in $pythonCommands) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($found -and $found.Source -notlike "*WindowsApps*") {
        $pythonCmd = $cmd
        break
    }
}

# Si pas trouvé dans PATH, chercher dans les emplacements standards
if (-not $pythonCmd) {
    $pythonPaths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python*\python.exe",
        "$env:ProgramFiles\Python*\python.exe",
        "C:\Python*\python.exe"
    )
    
    foreach ($pathPattern in $pythonPaths) {
        $found = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $pythonCmd = $found.FullName
            Write-Host "Python trouvé: $pythonCmd" -ForegroundColor Green
            break
        }
    }
}

if (-not $pythonCmd) {
    Write-Host "ERREUR: Python n'est pas trouvé." -ForegroundColor Red
    Write-Host "Veuillez installer Python depuis https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "Assurez-vous de cocher 'Add Python to PATH' lors de l'installation." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

if ($pythonCmd -notlike "*\*") {
    Write-Host "Python trouvé: $pythonCmd" -ForegroundColor Green
}

# Aller dans le dossier backend
$backendPath = Join-Path $PSScriptRoot "backend"
if (-not (Test-Path $backendPath)) {
    Write-Host "ERREUR: Le dossier backend n'existe pas!" -ForegroundColor Red
    pause
    exit 1
}

Set-Location $backendPath

# Vérifier si les dépendances sont installées
Write-Host "Vérification des dépendances..." -ForegroundColor Yellow
try {
    $test = & $pythonCmd -c "import flask" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Installation des dépendances..." -ForegroundColor Yellow
        & $pythonCmd -m pip install -r requirements.txt
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERREUR: Impossible d'installer les dépendances." -ForegroundColor Red
            pause
            exit 1
        }
    } else {
        Write-Host "Dépendances OK" -ForegroundColor Green
    }
} catch {
    Write-Host "Installation des dépendances..." -ForegroundColor Yellow
    & $pythonCmd -m pip install -r requirements.txt
}

Write-Host ""
Write-Host "Démarrage du serveur Flask..." -ForegroundColor Cyan
Write-Host "Le serveur sera accessible sur: http://localhost:5000" -ForegroundColor Green
Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur" -ForegroundColor Yellow
Write-Host ""

# Démarrer Flask
& $pythonCmd app.py


