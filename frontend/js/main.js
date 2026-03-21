/**
 * Project: HyperV Manager
 * Author: Pablo
 */
// API Base URL
const API_BASE_URL = 'http://localhost:5000';

// DOM Elements
const createVmForm = document.getElementById('createVmForm');
const refreshBtn = document.getElementById('refreshBtn');
const vmTableBody = document.getElementById('vmTableBody');
const messageDiv = document.getElementById('message');

// Initialize: Load VMs and ISOs on page load
document.addEventListener('DOMContentLoaded', () => {
    loadVMs();
    loadISOs();
});

// Load ISOs from API
async function loadISOs() {
    try {
        const response = await fetch(`${API_BASE_URL}/isos`);
        const result = await response.json();
        
        const isoSelect = document.getElementById('isoSelect');
        
        if (result.success && result.data && result.data.isos) {
            // Clear existing options except the first one
            isoSelect.innerHTML = '<option value="">Aucun ISO</option>';
            
            // Add ISO options
            result.data.isos.forEach(iso => {
                const option = document.createElement('option');
                option.value = iso.path;
                option.textContent = iso.name;
                isoSelect.appendChild(option);
            });
        } else {
            console.warn('Aucun ISO trouvé ou erreur lors du chargement');
        }
    } catch (error) {
        console.error('Erreur lors du chargement des ISO:', error);
    }
}

// Load VMs from API
async function loadVMs() {
    try {
        vmTableBody.innerHTML = '<tr><td colspan="6" class="loading">Chargement...</td></tr>';
        
        const response = await fetch(`${API_BASE_URL}/vms`);
        const result = await response.json();
        
        if (result.success && result.data && result.data.vms) {
            displayVMs(result.data.vms);
        } else {
            showMessage('Erreur lors du chargement des VMs: ' + (result.error || 'Erreur inconnue'), 'error');
            vmTableBody.innerHTML = '<tr><td colspan="6" class="loading">Aucune VM trouvée</td></tr>';
        }
    } catch (error) {
        showMessage('Erreur de connexion au serveur: ' + error.message, 'error');
        vmTableBody.innerHTML = '<tr><td colspan="6" class="loading">Erreur de connexion</td></tr>';
    }
}

// Display VMs in table
function displayVMs(vms) {
    if (vms.length === 0) {
        vmTableBody.innerHTML = '<tr><td colspan="6" class="loading">Aucune VM trouvée</td></tr>';
        return;
    }
    
    vmTableBody.innerHTML = '';
    
    vms.forEach(vm => {
        const row = document.createElement('tr');
        
        // State badge class
        const stateClass = getStateClass(vm.State);
        
        row.innerHTML = `
            <td><strong>${escapeHtml(vm.Name)}</strong></td>
            <td><span class="state-badge state-${stateClass}">${escapeHtml(vm.State)}</span></td>
            <td>${escapeHtml(vm.CPUUsage || 'N/A')}</td>
            <td>${escapeHtml(vm.MemoryAssigned || 'N/A')}</td>
            <td>${escapeHtml(vm.Uptime || 'N/A')}</td>
            <td class="actions">
                ${vm.State === 'Off' || vm.State === 'OffCritical' ? 
                    `<button class="btn btn-success" onclick="startVM('${escapeHtml(vm.Name)}')">Démarrer</button>` : 
                    `<button class="btn btn-warning" onclick="stopVM('${escapeHtml(vm.Name)}')">Arrêter</button>`
                }
                <button class="btn btn-info" onclick="connectVM('${escapeHtml(vm.Name)}')" title="Ouvrir VMConnect">Connecter</button>
                <button class="btn btn-primary" onclick="openVMViewer('${escapeHtml(vm.Name)}')" title="Ouvrir l'interface graphique dans le navigateur">Voir</button>
                <button class="btn btn-secondary" onclick="openRemoteDesktop('${escapeHtml(vm.Name)}')" title="Connexion Bureau à distance">RDP</button>
                <button class="btn btn-danger" onclick="removeVM('${escapeHtml(vm.Name)}')">Supprimer</button>
            </td>
        `;
        
        vmTableBody.appendChild(row);
    });
}

// Get state class for badge styling
function getStateClass(state) {
    const stateLower = (state || '').toLowerCase();
    if (stateLower.includes('running')) return 'running';
    if (stateLower.includes('off')) return 'off';
    if (stateLower.includes('paused')) return 'paused';
    return 'other';
}

// Create VM form handler
createVmForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const isoSelect = document.getElementById('isoSelect');
    const isoPath = isoSelect.value.trim();
    
    const formData = {
        name: document.getElementById('vmName').value.trim(),
        memoryMB: parseInt(document.getElementById('memoryMB').value),
        cpuCount: parseInt(document.getElementById('cpuCount').value),
        diskGB: parseInt(document.getElementById('diskGB').value),
        switchName: document.getElementById('switchName').value.trim()
    };
    
    // Add ISO path if selected
    if (isoPath) {
        formData.isoPath = isoPath;
    }
    
    // Validation
    if (!formData.name) {
        showMessage('Le nom de la VM est requis', 'error');
        return;
    }
    
    if (formData.memoryMB < 512) {
        showMessage('La mémoire doit être d\'au moins 512 MB', 'error');
        return;
    }
    
    try {
        showMessage('Création de la VM en cours...', 'info');
        
        const response = await fetch(`${API_BASE_URL}/create_vm`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage(result.data?.message || 'VM créée avec succès!', 'success');
            createVmForm.reset();
            // Reload VM list after a short delay
            setTimeout(() => {
                loadVMs();
            }, 1000);
        } else {
            showMessage('Erreur: ' + (result.error || 'Erreur inconnue'), 'error');
        }
    } catch (error) {
        showMessage('Erreur de connexion: ' + error.message, 'error');
    }
});

// Start VM
async function startVM(vmName) {
    if (!confirm(`Voulez-vous démarrer la VM "${vmName}"?`)) {
        return;
    }
    
    try {
        showMessage('Démarrage de la VM...', 'info');
        
        const response = await fetch(`${API_BASE_URL}/start_vm`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ name: vmName })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage(result.data?.message || 'VM démarrée avec succès!', 'success');
            setTimeout(() => {
                loadVMs();
            }, 1000);
        } else {
            showMessage('Erreur: ' + (result.error || 'Erreur inconnue'), 'error');
        }
    } catch (error) {
        showMessage('Erreur de connexion: ' + error.message, 'error');
    }
}

// Stop VM
async function stopVM(vmName) {
    if (!confirm(`Voulez-vous arrêter la VM "${vmName}"?`)) {
        return;
    }
    
    try {
        showMessage('Arrêt de la VM...', 'info');
        
        const response = await fetch(`${API_BASE_URL}/stop_vm`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ name: vmName })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage(result.data?.message || 'VM arrêtée avec succès!', 'success');
            setTimeout(() => {
                loadVMs();
            }, 1000);
        } else {
            showMessage('Erreur: ' + (result.error || 'Erreur inconnue'), 'error');
        }
    } catch (error) {
        showMessage('Erreur de connexion: ' + error.message, 'error');
    }
}

// Remove VM
async function removeVM(vmName) {
    if (!confirm(`ATTENTION: Voulez-vous vraiment supprimer la VM "${vmName}"?\nCette action est irréversible!`)) {
        return;
    }
    
    try {
        showMessage('Suppression de la VM...', 'info');
        
        const response = await fetch(`${API_BASE_URL}/remove_vm`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ name: vmName })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage(result.data?.message || 'VM supprimée avec succès!', 'success');
            setTimeout(() => {
                loadVMs();
            }, 1000);
        } else {
            showMessage('Erreur: ' + (result.error || 'Erreur inconnue'), 'error');
        }
    } catch (error) {
        showMessage('Erreur de connexion: ' + error.message, 'error');
    }
}

// Refresh button handler
refreshBtn.addEventListener('click', () => {
    loadVMs();
    showMessage('Liste des VMs actualisée', 'info');
});

// Show message helper
function showMessage(text, type) {
    messageDiv.textContent = text;
    messageDiv.className = `message ${type}`;
    
    // Auto-hide success/info messages after 5 seconds
    if (type === 'success' || type === 'info') {
        setTimeout(() => {
            messageDiv.className = 'message';
        }, 5000);
    }
}

// Open VM viewer in browser using Hyper-V native APIs
async function openVMViewer(vmName) {
    try {
        showMessage('Ouverture du viewer via Hyper-V...', 'info');
        
        // Get VM console info using Hyper-V APIs (no IP needed)
        const consoleResponse = await fetch(`${API_BASE_URL}/vm_console/${encodeURIComponent(vmName)}`);
        const consoleResult = await consoleResponse.json();
        
        if (consoleResult.success && consoleResult.data) {
            const consoleInfo = consoleResult.data;
            // Open viewer in new window/tab using Hyper-V native connection
            window.open(`${API_BASE_URL}/vm_viewer/${encodeURIComponent(vmName)}`, '_blank', 'width=1200,height=800');
        } else {
            showMessage('Erreur lors de la récupération des informations de la VM: ' + (consoleResult.error || 'Erreur inconnue'), 'error');
        }
    } catch (error) {
        showMessage('Erreur: ' + error.message, 'error');
    }
}

// Show VM viewer modal with embedded viewer using Hyper-V APIs
function showVMViewerModal(vmName) {
    // Remove existing modal if any
    const existingModal = document.getElementById('vmViewerModal');
    if (existingModal) {
        existingModal.remove();
    }
    
    const modal = document.createElement('div');
    modal.id = 'vmViewerModal';
    modal.className = 'modal vm-viewer-modal';
    
    const viewerContent = 
        `<div class="viewer-container">
            <div class="viewer-header">
                <h3>Interface graphique - ${escapeHtml(vmName)}</h3>
                <div class="viewer-controls">
                    <button class="btn btn-secondary btn-sm" onclick="refreshVMViewer('${escapeHtml(vmName)}')">Actualiser</button>
                    <span class="modal-close" onclick="closeVMViewerModal()">&times;</span>
                </div>
            </div>
            <div class="viewer-frame-container">
                <iframe id="vmViewerFrame" class="vm-viewer-frame" 
                    src="${API_BASE_URL}/vm_viewer/${encodeURIComponent(vmName)}"
                    allowfullscreen
                    frameborder="0">
                </iframe>
                <div class="viewer-loading">
                    <p>Chargement du viewer via Hyper-V...</p>
                    <p class="viewer-instructions">
                        Connexion via les APIs natives Hyper-V (sans IP requise)
                    </p>
                </div>
            </div>
        </div>`;
    
    modal.innerHTML = viewerContent;
    document.body.appendChild(modal);
    
    // Load viewer using Hyper-V APIs
    loadVMViewer(vmName);
}

function loadVMViewer(vmName) {
    const frame = document.getElementById('vmViewerFrame');
    if (frame) {
        // Load the viewer page using Hyper-V native APIs (no IP needed)
        frame.src = `${API_BASE_URL}/vm_viewer/${encodeURIComponent(vmName)}`;
        frame.style.display = 'block';
        
        // Hide loading message after frame loads
        frame.onload = () => {
            const loading = frame.parentElement.querySelector('.viewer-loading');
            if (loading) {
                loading.style.display = 'none';
            }
        };
        
        // Fallback: hide loading after timeout
        setTimeout(() => {
            const loading = frame.parentElement.querySelector('.viewer-loading');
            if (loading && frame.contentDocument) {
                loading.style.display = 'none';
            }
        }, 3000);
    }
}

function refreshVMViewer(vmName) {
    openVMViewer(vmName);
}

function openNoVNCViewer(ip) {
    if (!ip) {
        showMessage('Adresse IP non disponible', 'error');
        return;
    }
    
    // Note: This requires a VNC server running in the VM and a WebSocket proxy
    // For now, we'll show instructions
    showMessage('Pour utiliser noVNC, vous devez configurer un serveur VNC dans la VM et un proxy WebSocket sur le serveur.', 'info');
    
    // In a full implementation, you would:
    // 1. Load noVNC library
    // 2. Connect to ws://localhost:5000/vnc-proxy?vm=vmName
    // 3. The backend would proxy the WebSocket connection to the VNC server
}

function closeVMViewerModal() {
    const modal = document.getElementById('vmViewerModal');
    if (modal) {
        modal.remove();
    }
}

// Connect to VM using VMConnect
async function connectVM(vmName) {
    try {
        showMessage('Ouverture de VMConnect...', 'info');
        
        const response = await fetch(`${API_BASE_URL}/connect_vm`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ name: vmName })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('VMConnect lancé avec succès!', 'success');
        } else {
            showMessage('Erreur: ' + (result.error || 'Erreur inconnue'), 'error');
        }
    } catch (error) {
        showMessage('Erreur de connexion: ' + error.message, 'error');
    }
}

// Open Remote Desktop Connection
async function openRemoteDesktop(vmName) {
    try {
        showMessage('Récupération de l\'adresse IP de la VM...', 'info');
        
        const response = await fetch(`${API_BASE_URL}/vm_ip/${encodeURIComponent(vmName)}`);
        const result = await response.json();
        
        if (result.success && result.data) {
            const ipAddresses = result.data.ipAddresses || [];
            
            if (ipAddresses.length > 0) {
                // Use the first IP address
                const ip = ipAddresses[0];
                
                // Open RDP connection
                // Try to launch mstsc.exe with the IP
                showMessage(`Ouverture de la connexion RDP vers ${ip}...`, 'info');
                
                // Create a hidden iframe to trigger RDP protocol handler
                const rdpLink = document.createElement('a');
                rdpLink.href = `rdp://full%20address=s:${ip}`;
                rdpLink.style.display = 'none';
                document.body.appendChild(rdpLink);
                rdpLink.click();
                document.body.removeChild(rdpLink);
                
                // Also show a modal with connection options
                showRemoteDesktopModal(vmName, ipAddresses);
            } else {
                showMessage('Aucune adresse IP trouvée pour cette VM. Assurez-vous que la VM est démarrée et a une connexion réseau.', 'error');
                // Still show the modal with manual connection option
                showRemoteDesktopModal(vmName, []);
            }
        } else {
            showMessage('Erreur lors de la récupération de l\'IP: ' + (result.error || 'Erreur inconnue'), 'error');
        }
    } catch (error) {
        showMessage('Erreur de connexion: ' + error.message, 'error');
    }
}

// Show Remote Desktop connection modal
function showRemoteDesktopModal(vmName, ipAddresses) {
    // Create modal HTML
    const modal = document.createElement('div');
    modal.id = 'rdpModal';
    modal.className = 'modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3>Connexion Bureau à distance - ${escapeHtml(vmName)}</h3>
                <span class="modal-close" onclick="closeRemoteDesktopModal()">&times;</span>
            </div>
            <div class="modal-body">
                ${ipAddresses.length > 0 ? 
                    `<p><strong>Adresse(s) IP trouvée(s):</strong></p>
                    <ul>
                        ${ipAddresses.map(ip => `<li>${escapeHtml(ip)}</li>`).join('')}
                    </ul>
                    <p>Pour vous connecter:</p>
                    <ol>
                        <li>Ouvrez le Bureau à distance Windows (mstsc.exe)</li>
                        <li>Entrez l'adresse IP: <code>${escapeHtml(ipAddresses[0])}</code></li>
                        <li>Cliquez sur "Connexion"</li>
                    </ol>
                    <button class="btn btn-primary" onclick="launchRDP('${escapeHtml(ipAddresses[0])}')">Ouvrir RDP</button>` :
                    `<p>Aucune adresse IP trouvée. La VM doit être démarrée et avoir une connexion réseau active.</p>
                    <p>Vous pouvez toujours vous connecter manuellement:</p>
                    <ol>
                        <li>Ouvrez le Bureau à distance Windows (mstsc.exe)</li>
                        <li>Entrez le nom de la VM ou son adresse IP</li>
                        <li>Cliquez sur "Connexion"</li>
                    </ol>`
                }
                <p><strong>Alternative:</strong> Utilisez le bouton "Connecter" pour ouvrir VMConnect (interface graphique native Hyper-V)</p>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // Close on outside click
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            closeRemoteDesktopModal();
        }
    });
}

function closeRemoteDesktopModal() {
    const modal = document.getElementById('rdpModal');
    if (modal) {
        modal.remove();
    }
}

function launchRDP(ip) {
    // Try to launch mstsc.exe programmatically
    // Note: This may not work in all browsers due to security restrictions
    window.location.href = `rdp://full%20address=s:${ip}`;
    closeRemoteDesktopModal();
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

