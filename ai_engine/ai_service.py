"""Local FaceLandmarker challenge and ArcFace vector service for Laravel.

Run on the same computer as Laravel. Its existing embedding API stays intact.
"""

import json
import os
import urllib.request
import tempfile
from pathlib import Path
from typing import Any

import cv2
import mediapipe as mp
import numpy as np
from deepface import DeepFace
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse


BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = Path(os.environ.get("AI_MODEL_DIR", BASE_DIR / "model"))
FACE_CONFIG_PATH = MODEL_DIR / "face_recognition_config.json"
FACE_CONFIG: dict[str, Any] = {}
if FACE_CONFIG_PATH.is_file():
    FACE_CONFIG = json.loads(FACE_CONFIG_PATH.read_text(encoding="utf-8"))

MAX_UPLOAD_BYTES = 25 * 1024 * 1024
MAX_VIDEO_SECONDS = 8
CALIBRATION_FRAMES = 8
HOLD_FRAMES = 3
SAMPLED_FRAMES = 24
LEFT_DELTA = -0.10
RIGHT_DELTA = 0.10
ARCFACE_MODEL = FACE_CONFIG.get("model_name", "ArcFace")
DETECTOR_BACKEND = FACE_CONFIG.get("detector_backend", "ssd")
FACE_MATCH_THRESHOLD = float(os.environ.get("FACE_MATCH_THRESHOLD", "0.8"))

app = FastAPI(title="Presensi AI Engine", version="2.0.0")

LANDMARK_MODEL_PATH = MODEL_DIR / "face_landmarker.task"
LANDMARK_MODEL_URL = "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/latest/face_landmarker.task"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
if not LANDMARK_MODEL_PATH.is_file():
    urllib.request.urlretrieve(LANDMARK_MODEL_URL, LANDMARK_MODEL_PATH)
_landmarker_options = mp.tasks.vision.FaceLandmarkerOptions(
    base_options=mp.tasks.BaseOptions(model_asset_path=str(LANDMARK_MODEL_PATH)),
    running_mode=mp.tasks.vision.RunningMode.VIDEO,
    num_faces=1,
    min_face_detection_confidence=0.5,
    min_face_presence_confidence=0.5,
    min_tracking_confidence=0.5,
)
_landmarker = mp.tasks.vision.FaceLandmarker.create_from_options(_landmarker_options)


@app.get("/")
def health() -> dict[str, str]:
    return {"status": "running", "service": "face-landmarker-and-arcface"}


@app.get("/health/models")
def model_health() -> dict[str, Any]:
    return {
        "status": "ready",
        "face_landmarker": "ready",
        "face_match_threshold": FACE_MATCH_THRESHOLD,
        "arcface_model": ARCFACE_MODEL,
    }


async def read_upload(upload: UploadFile) -> bytes:
    content = await upload.read(MAX_UPLOAD_BYTES + 1)
    if len(content) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="File maksimal 25 MB.")
    return content


def normalize(vector: Any) -> np.ndarray:
    values = np.asarray(vector, dtype=np.float32).reshape(-1)
    norm = float(np.linalg.norm(values))
    if not np.isfinite(norm) or norm <= 1e-12:
        raise ValueError("invalid_embedding")
    return values / norm


def image_from_bytes(content: bytes) -> np.ndarray:
    image = cv2.imdecode(np.frombuffer(content, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError("invalid_image")
    return image


def represent_one(image: np.ndarray) -> np.ndarray:
    try:
        representations = DeepFace.represent(
            img_path=image,
            model_name=ARCFACE_MODEL,
            detector_backend=DETECTOR_BACKEND,
            enforce_detection=True,
            align=True,
            normalization="ArcFace",
            l2_normalize=True,
            max_faces=1,
        )
    except ValueError as error:
        if "face" in str(error).lower() and "detect" in str(error).lower():
            raise ValueError("face_not_detected") from error
        raise
    if not representations:
        raise ValueError("face_not_detected")
    return normalize(representations[0]["embedding"])


def arcface_embedding(image: np.ndarray) -> np.ndarray:
    # Use the captured frame once. A missed second detection on a mirrored copy
    # previously rejected an otherwise valid face photo with HTTP 400.
    return represent_one(image)


def check_face_turns(video_path: str, sequence: list[str]) -> dict[str, Any]:
    capture = cv2.VideoCapture(video_path)
    if not capture.isOpened():
        raise ValueError("video_decode_failed")
    try:
        frame_count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
        fps = float(capture.get(cv2.CAP_PROP_FPS) or 0)
        if frame_count < 2:
            raise ValueError("video_too_short_or_invalid")
        duration = frame_count / fps if fps > 0 else 0
        if duration > MAX_VIDEO_SECONDS:
            raise ValueError("video_too_long")
        positions = np.linspace(0, frame_count - 1, num=min(SAMPLED_FRAMES, frame_count), dtype=int)
        yaw_values: list[float | None] = []
        for position in positions:
            capture.set(cv2.CAP_PROP_POS_FRAMES, int(position))
            ok, frame = capture.read()
            if not ok or frame is None:
                yaw_values.append(None)
                continue
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            result = _landmarker.detect_for_video(mp_image, int(position * 1000 / max(fps, 1)))
            if not result.face_landmarks:
                yaw_values.append(None)
                continue
            landmarks = result.face_landmarks[0]
            left_eye = np.array([landmarks[33].x, landmarks[33].y], dtype=np.float32)
            right_eye = np.array([landmarks[263].x, landmarks[263].y], dtype=np.float32)
            nose = np.array([landmarks[1].x, landmarks[1].y], dtype=np.float32)
            eye_distance = float(np.linalg.norm(right_eye - left_eye))
            yaw_values.append(None if eye_distance < 1e-6 else float((nose[0] - (left_eye[0] + right_eye[0]) / 2) / eye_distance))
        valid = [value for value in yaw_values if value is not None]
        if len(valid) < CALIBRATION_FRAMES + 2 * HOLD_FRAMES:
            raise ValueError("video_decode_failed")
        baseline = float(np.median(valid[:CALIBRATION_FRAMES]))
        deltas = [None if value is None else value - baseline for value in yaw_values]
        active = deltas[CALIBRATION_FRAMES:]
        detected: list[str] = []
        for start in range(max(0, len(active) - HOLD_FRAMES + 1)):
            window = active[start:start + HOLD_FRAMES]
            if any(value is None for value in window):
                continue
            target = sequence[len(detected)] if len(detected) < len(sequence) else None
            if target == "LEFT" and all(value <= LEFT_DELTA for value in window):
                detected.append("LEFT")
            elif target == "RIGHT" and all(value >= RIGHT_DELTA for value in window):
                detected.append("RIGHT")
            if len(detected) == len(sequence):
                break
        found_left = "LEFT" in detected
        found_right = "RIGHT" in detected
        return {"passed": found_left and found_right, "left_detected": found_left,
                "right_detected": found_right, "sequence_detected": detected,
                "valid_frames": len(valid)}
    finally:
        capture.release()


@app.post("/check-face-landmarker")
async def check_face_landmarker(
    file: UploadFile = File(...), challenge: str = Form(...)
) -> dict[str, Any]:
    sequence = [step.strip().upper() for step in challenge.split(",")]
    if sequence not in (["LEFT", "RIGHT"], ["RIGHT", "LEFT"]):
        raise HTTPException(status_code=400, detail="Challenge tidak valid.")
    content = await read_upload(file)
    suffix = Path(file.filename or "clip.mp4").suffix or ".mp4"
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as temporary:
            temporary.write(content)
            temporary_path = temporary.name
        result = check_face_turns(temporary_path, sequence)
        return {
            "status": "success",
            "passed": result["passed"],
            "left_detected": result["left_detected"],
            "right_detected": result["right_detected"],
            "sequence_detected": result["sequence_detected"],
            "frames_checked": result["valid_frames"],
        }
    except ValueError as error:
        return JSONResponse(
            status_code=422,
            content={"status": "error", "passed": False, "reason": str(error)},
        )
    except Exception as error:  # Do not send internal details to clients.
        print("face landmarker inference error:", repr(error))
        return JSONResponse(
            status_code=500,
            content={"status": "error", "passed": False, "reason": "inference_error"},
        )
    finally:
        if temporary_path and os.path.exists(temporary_path):
            os.remove(temporary_path)


@app.post("/extract-embedding")
async def extract_embedding(file: UploadFile = File(...)) -> dict[str, Any]:
    """Compatible with the existing Laravel UserController enrollment call."""
    try:
        image = image_from_bytes(await read_upload(file))
        embedding = arcface_embedding(image)
        return {
            "status": "success",
            "message": "Vektor wajah berhasil diekstrak",
            "vector_length": int(embedding.size),
            "embedding": embedding.tolist(),
        }
    except ValueError as error:
        print(f"[EXTRACT ERROR] ValueError: {error}")
        return JSONResponse(
            status_code=400,
            content={"status": "error", "message": "Wajah tidak terdeteksi atau gambar tidak valid.", "reason": str(error)},
        )
    except Exception as error:
        print("embedding extraction error:", repr(error))
        return JSONResponse(status_code=500, content={"status": "error", "message": "Gagal mengekstrak embedding."})


@app.post("/compare-embedding")
async def compare_embedding(
    file: UploadFile = File(...), registered_embedding: str = Form(...)
) -> dict[str, Any]:
    """Compatible with the existing Laravel KehadiranController request format."""
    try:
        parsed = json.loads(registered_embedding)
        if isinstance(parsed, str):
            parsed = json.loads(parsed)
        registered = normalize(parsed)
        image = image_from_bytes(await read_upload(file))
        current = arcface_embedding(image)
        if registered.size != current.size:
            return JSONResponse(
                status_code=422,
                content={"status": "error", "reason": "embedding_dimension_mismatch", "message": "Embedding lama harus didaftarkan ulang dengan model ArcFace baru."},
            )
        similarity = float(np.clip(np.dot(registered, current), -1.0, 1.0))
        is_match = similarity >= FACE_MATCH_THRESHOLD
        return {
            "status": "success",
            "is_match": bool(is_match),
            "similarity_score": round(similarity * 100, 2),
            "distance": round(1.0 - similarity, 4),
        }
    except (ValueError, json.JSONDecodeError) as error:
        return JSONResponse(status_code=400, content={"status": "error", "message": "Embedding atau foto tidak valid.", "reason": str(error)})
    except Exception as error:
        print("embedding comparison error:", repr(error))
        return JSONResponse(status_code=500, content={"status": "error", "message": "Gagal membandingkan embedding."})


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "ai_service:app",
        host=os.environ.get("AI_ENGINE_HOST", "127.0.0.1"),
        port=int(os.environ.get("AI_ENGINE_PORT", "8001")),
        reload=False,
    )
