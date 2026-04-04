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
From the repository root or from this service directory:

### 1. Enter the service folder
```powershell
cd C:\eidonic_core\services\signal-gateway

2. Create a virtual environment with Python 3.12
py -V:3.12 -m venv .venv
3. Activate the virtual environment
.venv\Scripts\Activate.ps1
4. Install dependencies
python -m pip install -r requirements.txt
5. Run the service
python -m uvicorn app.main:app --reload
6. Test health endpoint

Open:
http://127.0.0.1:8000/health

7. Optional API docs

Open:
http://127.0.0.1:8000/docs

Use this commit message:

```text
Document local run steps for signal-gateway
