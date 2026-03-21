# HyperV Manager

Une interface web complète pour gérer vos machines virtuelles Hyper-V via PowerShell et Flask.

## 📋 Prérequis

- Windows 10/11 ou Windows Server avec Hyper-V activé
- Python 3.8 ou supérieur
- PowerShell 5.1 ou supérieur
- Accès administrateur pour exécuter les scripts PowerShell

## 🚀 Installation

### 1. Installer les dépendances Python

Ouvrez PowerShell ou CMD dans le dossier `backend` et exécutez:

```powershell
cd backend
pip install -r requirements.txt
```

### 2. Configurer la politique d'exécution PowerShell

Pour permettre l'exécution des scripts PowerShell, vous devez configurer la politique d'exécution. Ouvrez PowerShell **en tant qu'administrateur** et exécutez:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Ou pour une configuration plus restrictive (recommandé):

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

**Note:** La configuration `Bypass` dans le scope `Process` s'applique uniquement à la session PowerShell actuelle et est plus sécurisée.

### 3. Vérifier les switches virtuels Hyper-V

Avant de créer une VM, assurez-vous qu'un switch virtuel existe. Pour lister les switches disponibles:

```powershell
Get-VMSwitch
```

Notez le nom du switch que vous souhaitez utiliser (par exemple: "Default Switch" ou "External Switch").

## 🏃 Exécution

### Démarrer le serveur Flask

Dans le dossier `backend`, exécutez:

```powershell
python app.py
```

Le serveur Flask démarrera sur `http://localhost:5000`.

### Accéder à l'interface web

1. Ouvrez votre navigateur web
2. Naviguez vers `http://localhost:5000` (si vous avez configuré un serveur web pour servir les fichiers frontend)
   
   **OU**
   
   Ouvrez directement le fichier `frontend/index.html` dans votre navigateur.

**Note:** Si vous ouvrez directement `index.html`, assurez-vous que le serveur Flask est bien démarré car le JavaScript fait des appels API vers `http://localhost:5000`.

### Alternative: Servir le frontend avec Flask

Pour une meilleure expérience, vous pouvez modifier `app.py` pour servir également les fichiers statiques du frontend. Ajoutez cette route:

```python
@app.route('/')
def index():
    return send_from_directory('../frontend', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory('../frontend', path)
```

Puis accédez à `http://localhost:5000` directement.

## 📖 Utilisation

### Créer une VM

1. Remplissez le formulaire avec:
   - **Nom de la VM**: Un nom unique pour votre machine virtuelle
   - **Mémoire (MB)**: Minimum 512 MB
   - **Nombre de CPU**: Minimum 1
   - **Taille du disque (GB)**: Minimum 1 GB
   - **Nom du switch virtuel**: Le nom exact d'un switch Hyper-V existant

2. Cliquez sur "Créer la VM"

### Gérer les VMs

- **Actualiser**: Cliquez sur le bouton "Actualiser" pour mettre à jour la liste des VMs
- **Démarrer**: Cliquez sur "Démarrer" pour démarrer une VM arrêtée
- **Arrêter**: Cliquez sur "Arrêter" pour arrêter une VM en cours d'exécution
- **Supprimer**: Cliquez sur "Supprimer" pour supprimer définitivement une VM (avec confirmation)

## 🏗️ Architecture

```
hyperv-manager/
│
├── backend/
│   ├── app.py                 # Serveur Flask avec routes API
│   ├── requirements.txt       # Dépendances Python
│   └── powershell/
│       ├── create_vm.ps1      # Script de création de VM
│       ├── get_vms.ps1        # Script de récupération des VMs
│       ├── start_vm.ps1       # Script de démarrage de VM
│       ├── stop_vm.ps1        # Script d'arrêt de VM
│       └── remove_vm.ps1      # Script de suppression de VM
│
├── frontend/
│   ├── index.html            # Interface utilisateur principale
│   ├── css/
│   │   └── style.css         # Styles CSS modernes
│   └── js/
│       └── main.js           # Logique JavaScript et appels API
│
└── README.md                 # Ce fichier
```

## 🔌 API Endpoints

- `POST /create_vm` - Créer une nouvelle VM
- `GET /vms` - Récupérer la liste de toutes les VMs
- `POST /start_vm` - Démarrer une VM
- `POST /stop_vm` - Arrêter une VM
- `POST /remove_vm` - Supprimer une VM
- `GET /health` - Vérifier l'état du serveur

## ⚠️ Notes importantes

1. **Permissions**: Vous devez exécuter PowerShell et Flask avec des privilèges administrateur pour gérer Hyper-V.

2. **Sécurité**: Ce projet est conçu pour un usage local. Ne l'exposez pas sur Internet sans sécurisation appropriée.

3. **Validation**: Les scripts PowerShell valident les entrées et retournent des messages d'erreur clairs en cas de problème.

4. **Suppression de VM**: La suppression d'une VM est irréversible. Les disques virtuels associés peuvent être supprimés selon la configuration Hyper-V.

## 🐛 Dépannage

### Erreur: "Execution Policy"
Si vous obtenez une erreur de politique d'exécution, exécutez PowerShell en tant qu'administrateur et configurez la politique comme indiqué dans la section Installation.

### Erreur: "VM not found"
Vérifiez que le nom de la VM est correct et qu'elle existe dans Hyper-V.

### Erreur: "Switch not found"
Vérifiez que le nom du switch virtuel est correct en utilisant `Get-VMSwitch` dans PowerShell.

### Le serveur Flask ne démarre pas
Vérifiez que le port 5000 n'est pas déjà utilisé par une autre application.

## 📝 Licence

Ce projet est fourni tel quel, sans garantie.

