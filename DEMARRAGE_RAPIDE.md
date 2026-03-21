# 🚀 Guide de Démarrage Rapide

## ⚠️ Prérequis

1. **Python 3.8+** doit être installé
   - Télécharger depuis: https://www.python.org/downloads/
   - ⚠️ IMPORTANT: Cochez "Add Python to PATH" lors de l'installation

2. **Hyper-V** doit être activé sur Windows

## 📦 Installation et Démarrage

### Méthode 1: Script automatique (Recommandé)

1. Ouvrez PowerShell **en tant qu'administrateur**
2. Naviguez vers le dossier du projet:
   ```powershell
   cd C:\Users\Pablo\Desktop\HyperV-Manager
   ```
3. Exécutez le script de démarrage:
   ```powershell
   .\start.ps1
   ```

### Méthode 2: Démarrage manuel

1. Ouvrez PowerShell **en tant qu'administrateur**

2. Installez les dépendances Python:
   ```powershell
   cd C:\Users\Pablo\Desktop\HyperV-Manager\backend
   python -m pip install -r requirements.txt
   ```
   
   Si `python` ne fonctionne pas, essayez:
   ```powershell
   py -m pip install -r requirements.txt
   ```
   ou
   ```powershell
   python3 -m pip install -r requirements.txt
   ```

3. Démarrez le serveur Flask:
   ```powershell
   python app.py
   ```
   
   Ou avec `py`:
   ```powershell
   py app.py
   ```

4. Ouvrez votre navigateur et allez sur:
   ```
   http://localhost:5000
   ```

## ✅ Vérification

Une fois le serveur démarré, vous devriez voir:
```
 * Running on http://0.0.0.0:5000
```

Et dans votre navigateur, l'interface HyperV Manager devrait s'afficher.

## 🔧 Configuration PowerShell (si nécessaire)

Si vous obtenez une erreur de politique d'exécution, exécutez dans PowerShell (admin):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🆘 Dépannage

### Python non trouvé
- Vérifiez que Python est installé: `python --version`
- Si non installé: https://www.python.org/downloads/
- Assurez-vous que Python est dans le PATH système

### Port 5000 déjà utilisé
- Arrêtez l'application qui utilise le port 5000
- Ou modifiez le port dans `backend/app.py` (ligne 170)

### Erreur de dépendances
- Vérifiez votre connexion Internet
- Essayez: `python -m pip install --upgrade pip`
- Puis réessayez: `python -m pip install -r requirements.txt`

