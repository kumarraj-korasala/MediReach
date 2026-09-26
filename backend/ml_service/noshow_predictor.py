"""
noshow_predictor.py — Follow-up Appointment No-Show & Adherence Predictor
Uses demographic, distance, and historical visit adherence features to prioritize high-risk follow-ups.
"""

from typing import Dict, Any


def predict_noshow_risk(
    age: int,
    distance_km: float,
    previous_no_shows: int = 0,
    is_high_risk_patient: bool = False,
    has_phone: bool = True,
    transport_available: bool = True,
) -> Dict[str, Any]:
    """
    Computes probability of follow-up appointment no-show.
    Returns risk probability and recommended intervention.
    """
    score = 0.15  # baseline probability

    # Distance factor
    if distance_km > 25.0:
        score += 0.35
    elif distance_km > 10.0:
        score += 0.20
    elif distance_km > 5.0:
        score += 0.10

    # Historical adherence
    if previous_no_shows > 0:
        score += min(0.30, previous_no_shows * 0.15)

    # Transport / Contactability
    if not transport_available:
        score += 0.20
    if not has_phone:
        score += 0.15

    # Age vulnerability
    if age > 70 or age < 5:
        score += 0.10

    # Protective factor: high risk condition usually encourages family escort
    if is_high_risk_patient:
        score = max(0.10, score - 0.10)

    probability = round(min(0.95, score), 2)

    if probability >= 0.60:
        tier = "HIGH_RISK"
        action = "Schedule home visit reminder by village ASHA worker and provide community transport support."
    elif probability >= 0.35:
        tier = "MEDIUM_RISK"
        action = "Send SMS/Voice automated IVR reminder 24 hours prior."
    else:
        tier = "LOW_RISK"
        action = "Standard appointment reminder."

    return {
        "noshow_probability": probability,
        "risk_tier": tier,
        "recommended_intervention": action,
        "factors": {
            "distance_km": distance_km,
            "previous_missed": previous_no_shows,
            "transport_barrier": not transport_available,
        },
    }
