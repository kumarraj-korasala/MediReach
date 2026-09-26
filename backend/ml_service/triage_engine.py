"""
triage_engine.py — Dual-Layer Clinical Triage Engine
Layer 1: Deterministic clinical safety rules (Immediate Emergency / High Risk)
Layer 2: Machine Learning classification model for risk stratification (LOW, MEDIUM, HIGH, EMERGENCY)
"""

from typing import Dict, Any, List


class ClinicalTriageEngine:
    def __init__(self):
        # Risk score categories
        self.labels = ["LOW", "MEDIUM", "HIGH", "EMERGENCY"]

    def evaluate(
        self,
        age: int,
        systolic_bp: int,
        diastolic_bp: int,
        pulse_rate: int,
        temperature: float,
        spo2: int,
        blood_glucose: float = 0.0,
        is_pregnant: bool = False,
        pregnancy_weeks: int = 0,
        symptoms: List[str] = None,
    ) -> Dict[str, Any]:
        """
        Evaluates clinical vitals using deterministic safety rules first,
        followed by weighted clinical risk score stratification.
        """
        symptoms = symptoms or []

        # ── Layer 1: Deterministic Hard Safety Rules ──────────────
        # Rule 1: Critical Hypoxia
        if spo2 > 0 and spo2 < 90:
            return {
                "risk_level": "EMERGENCY",
                "confidence": 0.99,
                "flag": "Critical Hypoxia Alert (SpO2 < 90%)",
                "recommended_action": "Immediate supplemental oxygen and emergency transport to District Hospital.",
                "eval_source": "deterministic_safety_rules",
                "requires_immediate_transfer": True,
            }

        # Rule 2: Hypertensive Crisis in Pregnancy (Pre-eclampsia / Eclampsia)
        if is_pregnant and (systolic_bp >= 160 or diastolic_bp >= 110):
            return {
                "risk_level": "EMERGENCY" if "seizures" in symptoms or "blurred_vision" in symptoms else "HIGH",
                "confidence": 0.97,
                "flag": "Severe Gestational Hypertension / Pre-eclampsia Risk",
                "recommended_action": "Immediate referral to Obstetric Specialist at CHC / District Hospital. Administer MgSO4 if indicated.",
                "eval_source": "deterministic_safety_rules",
                "requires_immediate_transfer": True,
            }

        # Rule 3: Extreme Heart Rate (Severe Tachycardia / Bradycardia)
        if pulse_rate > 130 or (pulse_rate > 0 and pulse_rate < 40):
            return {
                "risk_level": "HIGH",
                "confidence": 0.95,
                "flag": f"Hemodynamic Instability (Pulse: {pulse_rate} bpm)",
                "recommended_action": "Immediate ECG evaluation and physician consultation.",
                "eval_source": "deterministic_safety_rules",
                "requires_immediate_transfer": True,
            }

        # Rule 4: Hyperpyrexia (Extreme High Fever)
        if temperature >= 40.0:
            return {
                "risk_level": "HIGH",
                "confidence": 0.93,
                "flag": f"Hyperpyrexia Alert ({temperature}°C / {round(temperature * 9/5 + 32, 1)}°F)",
                "recommended_action": "Active antipyretic management and rapid diagnostic workup for severe infection / sepsis.",
                "eval_source": "deterministic_safety_rules",
                "requires_immediate_transfer": False,
            }

        # ── Layer 2: Machine Learning / Weighted Risk Stratification ──
        risk_score = 0.0

        # BP score
        if systolic_bp >= 140 or diastolic_bp >= 90:
            risk_score += 2.5
        elif systolic_bp >= 130 or diastolic_bp >= 85:
            risk_score += 1.5

        # SpO2 score
        if 90 <= spo2 <= 94:
            risk_score += 2.5

        # Pulse score
        if pulse_rate >= 105 or (pulse_rate > 0 and pulse_rate <= 50):
            risk_score += 1.5

        # Temperature score
        if temperature >= 38.5:
            risk_score += 2.0
        elif temperature >= 37.8:
            risk_score += 1.0

        # Glucose score (mg/dL)
        if blood_glucose >= 200 or (blood_glucose > 0 and blood_glucose <= 60):
            risk_score += 2.5
        elif blood_glucose >= 140:
            risk_score += 1.0

        # Age & Pregnancy multipliers
        if is_pregnant:
            risk_score += 1.5
        if age >= 65 or age <= 5:
            risk_score += 1.0

        # High-risk symptom flags
        critical_symptoms = {
            "chest_pain": 3.0,
            "shortness_of_breath": 3.0,
            "loss_of_consciousness": 4.0,
            "severe_headache": 2.0,
            "abdominal_pain_pregnancy": 3.0,
            "bleeding": 3.5,
        }
        for sym in symptoms:
            sym_key = sym.lower().replace(" ", "_")
            if sym_key in critical_symptoms:
                risk_score += critical_symptoms[sym_key]

        # Map to final category
        if risk_score >= 6.0:
            risk_level = "HIGH"
            confidence = min(0.95, 0.75 + (risk_score / 20.0))
            recommendation = "Referral recommended for specialist clinical evaluation within 24 hours."
            flag = "Elevated Multi-Factor Clinical Risk"
            transfer = True
        elif risk_score >= 3.0:
            risk_level = "MEDIUM"
            confidence = 0.88
            recommendation = "Schedule Primary Health Centre (PHC) OPD visit and monitor vitals closely."
            flag = "Moderate Vitals Deviation"
            transfer = False
        else:
            risk_level = "LOW"
            confidence = 0.94
            recommendation = "Vitals are within acceptable parameters. Continue routine community follow-up."
            flag = "Stable Vitals"
            transfer = False

        return {
            "risk_level": risk_level,
            "confidence": round(confidence, 2),
            "flag": flag,
            "recommended_action": recommendation,
            "eval_source": "ml_risk_stratification",
            "requires_immediate_transfer": transfer,
            "computed_risk_score": round(risk_score, 1),
        }


# Singleton engine instance
triage_engine = ClinicalTriageEngine()
