# Local AI engine

This service runs on the same Windows machine as Laravel, so Laravel can call `127.0.0.1:8001` and no ngrok token or public tunnel is needed for local development.

## Model files

The FaceLandmarker task file is downloaded from the official MediaPipe model bundle on first startup into `ai_engine/model/face_landmarker.task`. ArcFace weights are downloaded by DeepFace on first use. The supplied development notebooks are kept in `ai_engine/notebooks/`.

## Start on Windows

From PowerShell in this directory:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python ai_service.py
```

Open `http://127.0.0.1:8001/health/models`. The first ArcFace request may download model weights from DeepFace.

Face turning is measured from the nose and eye landmarks relative to the neutral-face baseline. The initial thresholds follow the supplied notebook and should be calibrated on the target phone camera and lighting before production.

Endpoints:

- `POST /check-face-landmarker`, multipart field `file` containing a video with neutral, left-turn, and right-turn segments.
- `POST /extract-embedding`, multipart field `file` containing an image. Kept compatible with Laravel employee enrollment.
- `POST /compare-embedding`, multipart fields `file` (image) and `registered_embedding` (JSON vector). Kept compatible with Laravel attendance comparison.

`AI_ENGINE_HOST` defaults to `127.0.0.1`. Keep it local for Laravel on the same machine. If Laravel runs on another host, deploy the service on an authenticated HTTPS host and set `AI_ENGINE_HOST=0.0.0.0` only behind a firewall/reverse proxy.

Existing employee face embeddings created with InsightFace buffalo or a different ArcFace checkpoint are not interchangeable with this model. Re-register employee face images through the existing enrollment flow before enabling comparisons.
