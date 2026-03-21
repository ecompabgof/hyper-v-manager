# Instructions pour pousser vers GitHub

## Prérequis

Git doit être installé sur votre système. Si ce n'est pas le cas :

1. **Installer Git pour Windows** :
   - Téléchargez depuis : https://git-scm.com/download/win
   - Ou installez via winget : `winget install Git.Git`
   - Ou installez via Chocolatey : `choco install git`

2. **Redémarrez PowerShell** après l'installation pour que Git soit ajouté au PATH

## Commandes pour pousser vers GitHub

Une fois Git installé, ouvrez PowerShell **dans le dossier `hyperv-manager`** et exécutez ces commandes :

### Option 1 : Utiliser le script automatique

```powershell
powershell -ExecutionPolicy Bypass -File .\git-setup.ps1
```

### Option 2 : Commandes manuelles

```powershell
# Initialiser le dépôt Git (si pas déjà fait)
git init

# Ajouter tous les fichiers
git add .

# Créer le commit initial
git commit -m "Initial commit: HyperV Manager - Interface web pour gérer les machines virtuelles Hyper-V"

# Configurer le remote GitHub
git remote add origin git@github.com:pablogoffinet/hyper-v-manager.git

# Vérifier la branche (créer main si nécessaire)
git branch -M main

# Pousser vers GitHub
git push -u origin main
```

## Configuration SSH (si nécessaire)

Si vous obtenez une erreur d'authentification SSH :

1. **Vérifier si vous avez une clé SSH** :
   ```powershell
   Test-Path ~\.ssh\id_rsa.pub
   ```

2. **Générer une clé SSH si nécessaire** :
   ```powershell
   ssh-keygen -t ed25519 -C "votre_email@example.com"
   ```

3. **Ajouter la clé SSH à GitHub** :
   - Copiez le contenu de `~\.ssh\id_rsa.pub`
   - Allez sur GitHub → Settings → SSH and GPG keys → New SSH key
   - Collez la clé et sauvegardez

4. **Tester la connexion** :
   ```powershell
   ssh -T git@github.com
   ```

## Alternative : Utiliser HTTPS au lieu de SSH

Si vous préférez utiliser HTTPS au lieu de SSH :

```powershell
git remote set-url origin https://github.com/pablogoffinet/hyper-v-manager.git
git push -u origin main
```

Vous devrez entrer votre nom d'utilisateur GitHub et un token d'accès personnel (pas votre mot de passe).

## Vérification

Après le push, vérifiez que tout s'est bien passé :

```powershell
git remote -v
git log --oneline
```

Votre dépôt devrait maintenant être visible sur GitHub à l'adresse :
https://github.com/pablogoffinet/hyper-v-manager

