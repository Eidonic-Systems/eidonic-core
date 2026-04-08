# Signal Gateway

The Signal Gateway is the first ingress service for Eidonic Core.

## Responsibility
- receive incoming signals
- normalize them into `SignalEvent` objects
- reject malformed ingress
- forward accepted signal data to `herald-service` for threshold review

## Current phase
Phase 2 first live chain step

## Current endpoints
- `GET /health`
- `POST /signals/ingest`

## Current behavior
`signal-gateway` now performs the first real downstream handoff in the system:
- accepts a valid `SignalEvent`
- forwards a threshold payload to `herald-service`
- returns both the ingest acceptance and Herald's response

Session binding and orchestration are still separate services and are not chained yet.

## Herald dependency
By default, `signal-gateway` calls:

`http://127.0.0.1:8001`

You can override this with the environment variable:

`HERALD_BASE_URL`

## Local run

### 1. Enter the service folder
```powershell
cd C:\eidonic_core\services\signal-gateway
```

### 2. Create a virtual environment with Python 3.12
```powershell
py -V:3.12 -m venv .venv
```

### 3. Install dependencies
```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

### 4. Make sure `herald-service` is running
Default Herald URL:
`http://127.0.0.1:8001`

### 5. Run the service
```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000
```

### 6. Test the health endpoint
Open this in your browser:

`http://127.0.0.1:8000/health`

## Manual chain test

### Option 1: FastAPI docs in the browser
1. Make sure `herald-service` is running on port `8001`
2. Run `signal-gateway` on port `8000`
3. Open:
   `http://127.0.0.1:8000/docs`
4. Expand `POST /signals/ingest`
5. Click **Try it out**
6. Open `examples/sample_signal_event.json`
7. Copy its full contents
8. Paste that JSON into the request body box
9. Click **Execute**

### Expected response
You should receive a JSON response showing:
- `status` as `accepted`
- `service` as `signal-gateway`
- `received_signal_id` matching the sample payload
- `herald_result.service` as `herald-service`
- `herald_result.threshold_result` as `pass`

### Option 2: PowerShell in the terminal
Run this from `services/signal-gateway` while both services are running:

```powershell
$body = Get-Content .\examples\sample_signal_event.json -Raw
Invoke-RestMethod -Uri "http://127.0.0.1:8000/signals/ingest" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```
