# Signal Gateway

The Signal Gateway is the first ingress service for Eidonic Core.

## Responsibility
- receive incoming signals
- normalize them into SignalEvent objects
- reject malformed ingress
- pass valid signals to thresholding and session logic

## Current phase
Phase 1 scaffold only

## Current endpoints
- `GET /health`
- `POST /signals/ingest`

## Notes
This service currently accepts and echoes valid signal input.
Thresholding, session binding, persistence, and routing are not implemented yet.

## Local run

### 1. Enter the service folder
```powershell
cd C:\eidonic_core\services\signal-gateway
```

### 2. Create a virtual environment with Python 3.12
```powershell
py -V:3.12 -m venv .venv
```

### 3. Activate the virtual environment
```powershell
.venv\Scripts\Activate.ps1
```

### 4. Install dependencies
```powershell
python -m pip install -r requirements.txt
```

### 5. Run the service
```powershell
python -m uvicorn app.main:app --reload
```

### 6. Test the health endpoint
Open this in your browser:

`http://127.0.0.1:8000/health`

### 7. Optional API docs
Open this in your browser:

`http://127.0.0.1:8000/docs`

## Manual ingest test

You can test `POST /signals/ingest` in two ways.

### Option 1: FastAPI docs in the browser
1. Run the service:
   ```powershell
   python -m uvicorn app.main:app --reload
   ```
2. Open:
   `http://127.0.0.1:8000/docs`
3. Expand `POST /signals/ingest`
4. Click **Try it out**
5. Open `examples/sample_signal_event.json`
6. Copy its full contents
7. Paste that JSON into the request body box
8. Click **Execute**

### Option 2: PowerShell in the terminal
Run this from `services/signal-gateway` while the service is running:

```powershell
$body = Get-Content .\examples\sample_signal_event.json -Raw
Invoke-RestMethod -Uri "http://127.0.0.1:8000/signals/ingest" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

### Expected response
You should receive a JSON response showing:
- `status` as `accepted`
- `service` as `signal-gateway`
- `received_signal_id` matching the sample payload
