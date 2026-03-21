# Script pour initialiser le dépôt Git et configurer le remote
# Exécutez ce script depuis le dossier hyperv-manager

Write-Host "Initialisation du dépôt Git..." -ForegroundColor Green

# Initialiser git si ce n'est pas déjà fait
if (-not (Test-Path .git)) {
    git init
    Write-Host "Dépôt Git initialisé." -ForegroundColor Green
} else {
    Write-Host "Dépôt Git déjà initialisé." -ForegroundColor Yellow
}

# Ajouter tous les fichiers
Write-Host "Ajout des fichiers..." -ForegroundColor Green
git add .

# Vérifier si un commit existe déjà
$hasCommits = git rev-parse --verify HEAD 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Création du commit initial..." -ForegroundColor Green
    git commit -m "Initial commit: HyperV Manager - Interface web pour gérer les machines virtuelles Hyper-V"
} else {
    Write-Host "Des commits existent déjà. Vérifiez avec 'git log'." -ForegroundColor Yellow
}

# Configurer le remote
Write-Host "Configuration du remote GitHub..." -ForegroundColor Green
git remote remove origin 2>$null
git remote add origin git@github.com:pablogoffinet/hyper-v-manager.git

# Vérifier la configuration
Write-Host "`nConfiguration actuelle:" -ForegroundColor Cyan
git remote -v

# Déterminer la branche par défaut
$currentBranch = git branch --show-current 2>$null
if (-not $currentBranch) {
    # Si aucune branche n'existe, créer main
    git checkout -b main 2>$null
    if ($LASTEXITCODE -ne 0) {
        git checkout -b master 2>$null
        $currentBranch = "master"
    } else {
        $currentBranch = "main"
    }
}

Write-Host "`nBranche actuelle: $currentBranch" -ForegroundColor Cyan

# Pousser vers GitHub
Write-Host "`nPoussage vers GitHub..." -ForegroundColor Green
git push -u origin $currentBranch

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Push réussi vers GitHub!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Erreur lors du push. Vérifiez:" -ForegroundColor Red
    Write-Host "1. Votre connexion SSH à GitHub est configurée" -ForegroundColor Yellow
    Write-Host "2. Le dépôt existe sur GitHub: git@github.com:pablogoffinet/hyper-v-manager.git" -ForegroundColor Yellow
    Write-Host "3. Vous avez les permissions d'écriture" -ForegroundColor Yellow
}

