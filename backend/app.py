# Project: HyperV Manager
# Author: Pablo
from flask import Flask, request, jsonify, send_from_directory, Response, stream_with_context
from flask_cors import CORS
import subprocess
import json
import os
import base64
import threading
import time

# Try to import flask_socketio, fallback if not available
try:
    from flask_socketio import SocketIO, emit
    SOCKETIO_AVAILABLE = True
except ImportError:
    SOCKETIO_AVAILABLE = False
    print("Warning: flask-socketio not installed. WebSocket features will be disabled.")
    print("Install with: pip install flask-socketio python-socketio eventlet")

app = Flask(__name__, static_folder='../frontend', static_url_path='')
CORS(app)  # Enable CORS for frontend

# Initialize SocketIO only if available
if SOCKETIO_AVAILABLE:
    socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')
else:
    socketio = None

# Get the directory where PowerShell scripts are located
POWERSHELL_DIR = os.path.join(os.path.dirname(__file__), 'powershell')
# Get the directory where ISO files are located
ISO_DIR = os.path.join(os.path.dirname(__file__), '..', 'iso')

def run_powershell_script(script_name, *args):
    """Execute a PowerShell script and return the result."""
    script_path = os.path.join(POWERSHELL_DIR, script_name)
    
    # Build PowerShell command
    # Use -ExecutionPolicy Bypass to avoid execution policy issues
    # Use -File to execute the script file
    # Pass arguments as parameters
    cmd = [
        'powershell.exe',
        '-ExecutionPolicy', 'Bypass',
        '-File', script_path
    ] + list(args)
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode != 0:
            return {
                'success': False,
                'error': result.stderr or 'Unknown error occurred'
            }
        
        # Try to parse JSON output if available
        output = result.stdout.strip()
        if output:
            try:
                return {
                    'success': True,
                    'data': json.loads(output)
                }
            except json.JSONDecodeError:
                return {
                    'success': True,
                    'data': output
                }
        else:
            return {
                'success': True,
                'data': None
            }
            
    except subprocess.TimeoutExpired:
        return {
            'success': False,
            'error': 'Script execution timeout'
        }
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }

@app.route('/isos', methods=['GET'])
def get_isos():
    """Get list of available ISO files."""
    try:
        iso_files = []
        if os.path.exists(ISO_DIR):
            for file in os.listdir(ISO_DIR):
                if file.lower().endswith('.iso'):
                    iso_path = os.path.join(ISO_DIR, file)
                    iso_files.append({
                        'name': file,
                        'path': iso_path
                    })
        
        return jsonify({
            'success': True,
            'data': {'isos': iso_files}
        }), 200
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/create_vm', methods=['POST'])
def create_vm():
    """Create a new virtual machine."""
    data = request.json
    
    # Validate required fields
    required_fields = ['name', 'memoryMB', 'cpuCount', 'diskGB', 'switchName']
    for field in required_fields:
        if field not in data:
            return jsonify({
                'success': False,
                'error': f'Missing required field: {field}'
            }), 400
    
    # Build PowerShell command with named parameters
    script_path = os.path.join(POWERSHELL_DIR, 'create_vm.ps1')
    
    # Escape paths and values for PowerShell (use single quotes for paths)
    def escape_ps_value(value):
        if isinstance(value, str):
            # Escape single quotes by doubling them and wrap in single quotes
            escaped = value.replace("'", "''")
            return f"'{escaped}'"
        return str(value)
    
    # Build PowerShell command with named parameters
    ps_params = [
        f"-Name {escape_ps_value(data['name'])}",
        f"-MemoryMB {data['memoryMB']}",
        f"-CPUCount {data['cpuCount']}",
        f"-DiskGB {data['diskGB']}",
        f"-SwitchName {escape_ps_value(data['switchName'])}"
    ]
    
    # Add ISO path if provided
    if 'isoPath' in data and data['isoPath']:
        # Validate ISO path exists
        if os.path.exists(data['isoPath']):
            ps_params.append(f"-IsoPath {escape_ps_value(data['isoPath'])}")
        else:
            return jsonify({
                'success': False,
                'error': f'ISO file not found: {data["isoPath"]}'
            }), 400
    
    # Build the PowerShell command - use absolute path with proper escaping
    script_path_escaped = script_path.replace("'", "''")
    ps_command = f"& '{script_path_escaped}' " + " ".join(ps_params)
    
    cmd = [
        'powershell.exe',
        '-ExecutionPolicy', 'Bypass',
        '-Command', ps_command
    ]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode != 0:
            # Include both stderr and stdout for debugging
            error_msg = result.stderr.strip() if result.stderr.strip() else result.stdout.strip()
            result_data = {
                'success': False,
                'error': error_msg or 'Unknown error occurred',
                'stdout': result.stdout.strip(),
                'stderr': result.stderr.strip()
            }
        else:
            # Try to parse JSON output if available
            output = result.stdout.strip()
            if output:
                try:
                    result_data = {
                        'success': True,
                        'data': json.loads(output)
                    }
                except json.JSONDecodeError:
                    result_data = {
                        'success': True,
                        'data': output
                    }
            else:
                result_data = {
                    'success': True,
                    'data': None
                }
        
        if result_data['success']:
            return jsonify(result_data), 200
        else:
            return jsonify(result_data), 500
            
    except subprocess.TimeoutExpired:
        return jsonify({
            'success': False,
            'error': 'Script execution timeout'
        }), 500
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@app.route('/vms', methods=['GET'])
def get_vms():
    """Get list of all virtual machines."""
    result = run_powershell_script('get_vms.ps1')
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@app.route('/start_vm', methods=['POST'])
def start_vm():
    """Start a virtual machine."""
    data = request.json
    
    if 'name' not in data:
        return jsonify({
            'success': False,
            'error': 'Missing required field: name'
        }), 400
    
    result = run_powershell_script('start_vm.ps1', data['name'])
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@app.route('/stop_vm', methods=['POST'])
def stop_vm():
    """Stop a virtual machine."""
    data = request.json
    
    if 'name' not in data:
        return jsonify({
            'success': False,
            'error': 'Missing required field: name'
        }), 400
    
    result = run_powershell_script('stop_vm.ps1', data['name'])
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@app.route('/remove_vm', methods=['POST'])
def remove_vm():
    """Remove a virtual machine."""
    data = request.json
    
    if 'name' not in data:
        return jsonify({
            'success': False,
            'error': 'Missing required field: name'
        }), 400
    
    result = run_powershell_script('remove_vm.ps1', data['name'])
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@app.route('/connect_vm', methods=['POST'])
def connect_vm():
    """Launch VMConnect for a virtual machine."""
    data = request.json
    
    if 'name' not in data:
        return jsonify({
            'success': False,
            'error': 'Missing required field: name'
        }), 400
    
    result = run_powershell_script('connect_vm.ps1', data['name'])
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@app.route('/vm_ip/<vm_name>', methods=['GET'])
def get_vm_ip(vm_name):
    """Get IP address(es) of a virtual machine."""
    result = run_powershell_script('get_vm_ip.ps1', vm_name)
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@app.route('/vm_console/<vm_name>', methods=['GET'])
def get_vm_console(vm_name):
    """Get VM console information using Hyper-V APIs."""
    result = run_powershell_script('get_vm_console.ps1', vm_name)
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@app.route('/vm_screen/<vm_name>', methods=['GET'])
def get_vm_screen(vm_name):
    """Get VM screen capture using Hyper-V APIs."""
    result = run_powershell_script('capture_vm_screen.ps1', vm_name, '1024', '768')
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@app.route('/vm_stream/<vm_name>', methods=['GET'])
def stream_vm_screen(vm_name):
    """Stream VM screen using Server-Sent Events."""
    def generate():
        while True:
            try:
                # Get VM screen info via PowerShell
                result = run_powershell_script('stream_vm_screen.ps1', vm_name)
                
                if result['success']:
                    data = result.get('data', {})
                    # Send JSON data via SSE
                    yield f"data: {json.dumps(data)}\n\n"
                else:
                    yield f"data: {json.dumps({'error': result.get('error', 'Unknown error')})}\n\n"
                
                time.sleep(1)  # Update every second
            except Exception as e:
                yield f"data: {json.dumps({'error': str(e)})}\n\n"
                break
    
    return Response(stream_with_context(generate()), mimetype='text/event-stream')

if SOCKETIO_AVAILABLE:
    @socketio.on('connect_vm_stream')
    def handle_vm_stream(data):
        """Handle WebSocket connection for VM screen streaming."""
        vm_name = data.get('vmName')
        if not vm_name:
            emit('error', {'message': 'VM name required'})
            return
        
        # Start streaming thread
        def stream_thread():
            while True:
                try:
                    result = run_powershell_script('stream_vm_screen.ps1', vm_name)
                    socketio.emit('vm_frame', result.get('data', {}))
                    time.sleep(0.5)  # 2 FPS
                except Exception as e:
                    socketio.emit('error', {'message': str(e)})
                    break
        
        thread = threading.Thread(target=stream_thread)
        thread.daemon = True
        thread.start()

@app.route('/vm_viewer/<vm_name>', methods=['GET'])
def vm_viewer(vm_name):
    """Serve VM viewer page using Hyper-V native APIs."""
    # Get VM console info using Hyper-V APIs
    console_result = run_powershell_script('get_vm_console.ps1', vm_name)
    console_info = {}
    if console_result['success'] and console_result.get('data'):
        console_info = console_result['data']
    
    # Get VM state and info
    vm_state = console_info.get('state', 'Unknown')
    vm_id = console_info.get('vmId', '')
    can_connect = console_info.get('canConnect', False)
    
    # Return viewer HTML page using Hyper-V native connection with WebSocket streaming
    viewer_html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>VM Viewer - {vm_name}</title>
        <meta charset="UTF-8">
        {'<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>' if SOCKETIO_AVAILABLE else '<!-- WebSocket disabled: flask-socketio not installed -->'}
        <style>
            body {{
                margin: 0;
                padding: 0;
                background: #000;
                font-family: Arial, sans-serif;
                color: white;
            }}
            .viewer-container {{
                width: 100vw;
                height: 100vh;
                display: flex;
                flex-direction: column;
            }}
            .viewer-header {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 15px 20px;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }}
            .viewer-header h2 {{
                margin: 0;
            }}
            .viewer-content {{
                flex: 1;
                display: flex;
                justify-content: center;
                align-items: center;
                background: #1a1a1a;
                overflow: auto;
            }}
            .viewer-info {{
                text-align: center;
                padding: 40px;
                max-width: 800px;
            }}
            .vm-status {{
                padding: 15px;
                margin: 20px 0;
                border-radius: 8px;
                background: {'#28a745' if can_connect else '#dc3545'};
            }}
            .btn {{
                padding: 12px 24px;
                margin: 10px;
                background: #667eea;
                color: white;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                text-decoration: none;
                display: inline-block;
                font-size: 14px;
                transition: background 0.3s;
            }}
            .btn:hover {{
                background: #764ba2;
            }}
            .btn-primary {{
                background: #667eea;
            }}
            .btn-success {{
                background: #28a745;
            }}
            .vm-details {{
                background: #2a2a2a;
                padding: 20px;
                border-radius: 8px;
                margin: 20px 0;
                text-align: left;
            }}
            .vm-details code {{
                background: #1a1a1a;
                padding: 2px 6px;
                border-radius: 3px;
                color: #667eea;
            }}
        </style>
    </head>
    <body>
        <div class="viewer-container">
            <div class="viewer-header">
                <h2>{vm_name}</h2>
                <button class="btn" onclick="window.close()">Fermer</button>
            </div>
            <div class="viewer-content">
                {f'''<div style="width: 100%; height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center;">
                    <canvas id="vmCanvas" style="border: 2px solid #667eea; background: #000; max-width: 100%; max-height: 80vh; cursor: crosshair;"></canvas>
                    <div style="margin-top: 20px; text-align: center;">
                        <button class="btn btn-success" onclick="launchVMConnect()">Ouvrir VMConnect</button>
                        <button class="btn btn-primary" onclick="window.location.href='/'">Retour</button>
                    </div>
                    <div style="margin-top: 10px; color: #888; font-size: 12px;">
                        <p>Streaming via Hyper-V Enhanced Session Mode</p>
                        <p>VM ID: <code>{vm_id}</code> | État: {vm_state}</p>
                    </div>
                </div>''' if can_connect else f'''<div class="viewer-info">
                    <h3>Interface graphique via Hyper-V</h3>
                    <div class="vm-status">
                        <strong>État de la VM:</strong> {vm_state}
                    </div>
                    <div class="vm-details">
                        <p><strong>VM ID:</strong> <code>{vm_id}</code></p>
                        <p><strong>Connexion possible:</strong> Non (la VM doit être démarrée)</p>
                    </div>
                    <p>Veuillez démarrer la VM pour accéder à l'interface graphique.</p>
                    <div style="margin-top: 30px;">
                        <button class="btn btn-primary" onclick="window.location.href='/'">Retour à l'interface principale</button>
                    </div>
                </div>'''}
            </div>
        </div>
        <script>
            const vmName = '{vm_name}';
            {'const socket = io();' if SOCKETIO_AVAILABLE else '// WebSocket disabled'}
            let canvas, ctx;
            
            function initCanvas() {{
                canvas = document.getElementById('vmCanvas');
                if (canvas) {{
                    ctx = canvas.getContext('2d');
                    canvas.width = 1024;
                    canvas.height = 768;
                    // Fill with black background
                    ctx.fillStyle = '#000';
                    ctx.fillRect(0, 0, canvas.width, canvas.height);
                    // Draw waiting message
                    ctx.fillStyle = '#fff';
                    ctx.font = '20px Arial';
                    ctx.textAlign = 'center';
                    ctx.fillText('Connexion à la VM via Hyper-V...', canvas.width / 2, canvas.height / 2);
                }}
            }}
            
            {'''socket.on('connect', () => {
                console.log('WebSocket connecté');
                socket.emit('connect_vm_stream', { vmName: vmName });
            });
            
            socket.on('vm_frame', (data) => {
                // Handle VM frame data
                console.log('Frame reçue:', data);
                updateCanvas(data);
            });
            
            socket.on('error', (error) => {
                console.error('Erreur:', error);
                if (ctx) {
                    ctx.fillStyle = '#f00';
                    ctx.font = '16px Arial';
                    ctx.textAlign = 'center';
                    ctx.fillText('Erreur: ' + (error.message || 'Erreur inconnue'), canvas.width / 2, canvas.height / 2 + 30);
                }
            });''' if SOCKETIO_AVAILABLE else '// WebSocket features disabled - install flask-socketio to enable'}
            
            function updateCanvas(data) {{
                if (!ctx) return;
                
                // If we receive image data (base64), display it
                if (data.imageData) {{
                    const img = new Image();
                    img.onload = function() {{
                        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                    }};
                    img.src = 'data:image/png;base64,' + data.imageData;
                }} else {{
                    // Draw status info
                    ctx.fillStyle = '#000';
                    ctx.fillRect(0, 0, canvas.width, canvas.height);
                    ctx.fillStyle = '#0f0';
                    ctx.font = '16px Arial';
                    ctx.textAlign = 'center';
                    ctx.fillText('VM: ' + (data.vmName || vmName), canvas.width / 2, canvas.height / 2 - 20);
                    ctx.fillText('État: ' + (data.state || 'Running'), canvas.width / 2, canvas.height / 2);
                    ctx.fillText('Connexion Hyper-V active', canvas.width / 2, canvas.height / 2 + 20);
                }}
            }}
            
            function launchVMConnect() {{
                fetch('/connect_vm', {{
                    method: 'POST',
                    headers: {{ 'Content-Type': 'application/json' }},
                    body: JSON.stringify({{ name: vmName }})
                }})
                .then(response => response.json())
                .then(data => {{
                    if (data.success) {{
                        alert('VMConnect lancé avec succès!');
                    }} else {{
                        alert('Erreur: ' + (data.error || 'Erreur inconnue'));
                    }}
                }})
                .catch(error => {{
                    alert('Erreur: ' + error.message);
                }});
            }}
            
            window.onload = function() {{
                initCanvas();
            }};
        </script>
    </body>
    </html>
    """
    return viewer_html

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({'status': 'ok'}), 200

@app.route('/')
def index():
    """Serve the frontend index.html."""
    return send_from_directory('../frontend', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    """Serve static files from frontend directory."""
    return send_from_directory('../frontend', path)

if __name__ == '__main__':
    if SOCKETIO_AVAILABLE:
        socketio.run(app, debug=True, host='0.0.0.0', port=5000, allow_unsafe_werkzeug=True, use_reloader=False)
    else:
        app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)

