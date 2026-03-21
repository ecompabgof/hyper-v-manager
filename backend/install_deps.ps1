Write-Host "Installation des dépendances..." -ForegroundColor Green

# Try with python
Write-Host "Tentative avec python..." -ForegroundColor Yellow
python -m pip install flask-socketio python-socketio eventlet 2>&1 | Write-Host

# Try with py
Write-Host "Tentative avec py..." -ForegroundColor Yellow
py -m pip install flask-socketio python-socketio eventlet 2>&1 | Write-Host

# Verify installation
Write-Host "`nVérification de l'installation..." -ForegroundColor Green
python -c "import flask_socketio; print('✅ flask-socketio installé')" 2>&1
py -c "import flask_socketio; print('✅ flask-socketio installé')" 2>&1

Write-Host "`nInstallation terminée!" -ForegroundColor Green

