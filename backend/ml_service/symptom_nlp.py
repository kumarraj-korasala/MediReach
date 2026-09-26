"""
symptom_nlp.py — Multilingual Clinical Symptom NLP Extractor
Maps free-form speech transcripts in Telugu, Hindi, and English to structured ICD/SNOMED symptom entities.
"""

from typing import List, Dict, Any
import re


# Multilingual clinical dictionary mapping vernacular terms to normalized symptom keys
CLINICAL_SYMPTOM_DICTIONARY = {
    "fever": {
        "te": ["జ్వరం", "వేడి", "ఒళ్లు కాలడం", "జ్వరం వచ్చింది"],
        "hi": ["बुखार", "ताप", "बदन गर्म", "हरारत"],
        "en": ["fever", "high temperature", "pyrexia", "hot body", "chills"],
        "severity": "MODERATE",
    },
    "chest_pain": {
        "te": ["ఛాతీ నొప్పి", "గుండె నొప్పి", "ఛాతీలో బరువు"],
        "hi": ["सीने में दर्द", "छाती में दर्द", "दिल में दर्द"],
        "en": ["chest pain", "angina", "tightness in chest", "chest ache"],
        "severity": "CRITICAL",
    },
    "shortness_of_breath": {
        "te": ["శ్వాస ఆడకపోవడం", "ఆయాసం", "దమ్ము"],
        "hi": ["सांस फूलना", "सांस लेने में तकलीफ", "दम घुटना"],
        "en": ["shortness of breath", "dyspnea", "breathlessness", "difficulty breathing", "wheezing"],
        "severity": "CRITICAL",
    },
    "headache": {
        "te": ["తలనొప్పి", "తల భారంగా ఉంది", "మండిపోవడం"],
        "hi": ["सिरदर्द", "सर दर्द", "सिर में भारीपन"],
        "en": ["headache", "head pain", "migraine", "severe headache"],
        "severity": "MILD",
    },
    "dizziness": {
        "te": ["కళ్ళు తిరగడం", "తల తిరుగుతోంది", "మత్తుగా ఉండడం"],
        "hi": ["चक्कर आना", "सिर घूमना"],
        "en": ["dizziness", "vertigo", "lightheadedness", "feeling faint"],
        "severity": "MODERATE",
    },
    "vomiting": {
        "te": ["వాంతులు", "వికారం", "కడుపు తిప్పడం"],
        "hi": ["उल्टी", "कै", "जी मिचलाना"],
        "en": ["vomiting", "nausea", "throwing up", "emesis"],
        "severity": "MODERATE",
    },
    "cough": {
        "te": ["దగ్గు", "పొడి దగ్గు", "కఫం"],
        "hi": ["खांसी", "कफ", "सूखी खांसी"],
        "en": ["cough", "dry cough", "phlegm", "cold and cough"],
        "severity": "MILD",
    },
    "blurred_vision": {
        "te": ["మసకబారిన చూపు", "కళ్ళు మసకలు", "చూపు కనిపించకపోవడం"],
        "hi": ["धुंधला दिखना", "आंखों में धुंधलापन"],
        "en": ["blurred vision", "double vision", "dim vision"],
        "severity": "HIGH",
    },
    "abdominal_pain": {
        "te": ["కడుపు నొప్పి", "పొట్ట నొప్పి", "తీవ్రమైన కడుపు నొప్పి"],
        "hi": ["पेट में दर्द", "पेट दर्द", "मरोड़"],
        "en": ["stomach pain", "abdominal pain", "cramps", "belly ache"],
        "severity": "MODERATE",
    },
}


def extract_symptoms_from_text(text: str, language: str = "auto") -> Dict[str, Any]:
    """
    Extracts structured clinical symptoms from multilingual free-text / voice transcript.
    """
    if not text:
        return {"symptoms": [], "critical_flags": [], "raw_text": text}

    normalized_text = text.lower().strip()
    detected_symptoms = []
    critical_flags = []

    for symptom_key, meta in CLINICAL_SYMPTOM_DICTIONARY.items():
        matched = False
        all_terms = meta["en"] + meta["hi"] + meta["te"]

        for term in all_terms:
            if term.lower() in normalized_text:
                matched = True
                break

        if matched:
            detected_symptoms.append({
                "symptom_key": symptom_key,
                "display_name": symptom_key.replace("_", " ").title(),
                "severity": meta["severity"],
            })
            if meta["severity"] in ["HIGH", "CRITICAL"]:
                critical_flags.append(symptom_key)

    return {
        "symptoms": detected_symptoms,
        "count": len(detected_symptoms),
        "critical_flags": critical_flags,
        "has_emergency_symptom": len(critical_flags) > 0,
        "raw_text": text,
    }
