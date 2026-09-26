"""
ml_server.py — Python FastAPI ML Microservice
Port: 8001
Internal microservice called by the Node.js API Gateway (:5000)
"""

from typing import List, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from triage_engine import triage_engine
from symptom_nlp import extract_symptoms_from_text
from noshow_predictor import predict_noshow_risk


app = FastAPI(
    title="MediReach Python ML Microservice",
    description="Internal Clinical Decision Support, Triage ML, Multilingual NLP, and Adherence Prediction.",
    version="1.0.0",
)

# Enable CORS for internal gateway requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request Models ────────────────────────────────────────────

class TriageRequest(BaseModel):
    age: int = Field(..., ge=0, le=125, example=32)
    systolic_bp: int = Field(..., ge=40, le=300, example=165)
    diastolic_bp: int = Field(..., ge=20, le=200, example=105)
    pulse_rate: int = Field(..., ge=20, le=250, example=98)
    temperature: float = Field(..., ge=30.0, le=45.0, example=37.2)
    spo2: int = Field(..., ge=40, le=100, example=96)
    blood_glucose: Optional[float] = Field(0.0, example=120.0)
    is_pregnant: Optional[bool] = Field(False, example=True)
    pregnancy_weeks: Optional[int] = Field(0, example=32)
    symptoms: Optional[List[str]] = Field(default=[], example=["severe_headache", "blurred_vision"])


class SymptomExtractRequest(BaseModel):
    text: str = Field(..., example="రోగికి తీవ్రమైన జ్వరం మరియు ఛాతీ నొప్పి ఉంది")
    language: Optional[str] = Field("auto", example="te")


class NoShowRequest(BaseModel):
    age: int = Field(..., example=55)
    distance_km: float = Field(..., example=18.5)
    previous_no_shows: Optional[int] = Field(0, example=1)
    is_high_risk_patient: Optional[bool] = Field(False, example=True)
    has_phone: Optional[bool] = Field(True, example=True)
    transport_available: Optional[bool] = Field(False, example=False)


# ── Endpoints ─────────────────────────────────────────────────

@app.get("/")
@app.get("/health")
def health_check():
    return {
        "status": "online",
        "service": "MediReach Python ML Microservice",
        "port": 8001,
        "models_loaded": ["ClinicalTriageEngine", "MultilingualSymptomNLP", "NoShowRiskPredictor"],
    }


@app.post("/triage")
def perform_triage(payload: TriageRequest):
    """
    Evaluates clinical vitals and returns triage risk level, confidence score, and clinical recommendation.
    """
    try:
        result = triage_engine.evaluate(
            age=payload.age,
            systolic_bp=payload.systolic_bp,
            diastolic_bp=payload.diastolic_bp,
            pulse_rate=payload.pulse_rate,
            temperature=payload.temperature,
            spo2=payload.spo2,
            blood_glucose=payload.blood_glucose or 0.0,
            is_pregnant=payload.is_pregnant or False,
            pregnancy_weeks=payload.pregnancy_weeks or 0,
            symptoms=payload.symptoms or [],
        )
        return {
            "success": True,
            "data": result,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Triage evaluation error: {str(e)}")


@app.post("/extract-symptoms")
def extract_symptoms(payload: SymptomExtractRequest):
    """
    Extracts structured clinical symptoms from multilingual free-text / voice transcript (Telugu, Hindi, English).
    """
    try:
        result = extract_symptoms_from_text(payload.text, language=payload.language)
        return {
            "success": True,
            "data": result,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"NLP extraction error: {str(e)}")


@app.post("/predict-noshow")
def predict_noshow(payload: NoShowRequest):
    """
    Computes probability of follow-up appointment no-show for ASHA task prioritization.
    """
    try:
        result = predict_noshow_risk(
            age=payload.age,
            distance_km=payload.distance_km,
            previous_no_shows=payload.previous_no_shows or 0,
            is_high_risk_patient=payload.is_high_risk_patient or False,
            has_phone=payload.has_phone if payload.has_phone is not None else True,
            transport_available=payload.transport_available if payload.transport_available is not None else True,
        )
        return {
            "success": True,
            "data": result,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"No-show prediction error: {str(e)}")


# Run command:
# uvicorn ml_server:app --host 0.0.0.0 --port 8001
