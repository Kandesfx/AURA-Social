"""
AURA Social – Emotion Inference Engine
Processes 5-layer emotional signals and calculates Plutchik vectors.
"""
from typing import List, Dict, Any, Optional
import numpy as np
import torch
from app.ml.model_loader import model_loader

# Plutchik 8 primary emotions
EMOTIONS = ['joy', 'trust', 'anticipation', 'surprise', 'sadness', 'fear', 'anger', 'disgust']


class EmotionInferenceEngine:
    """
    Infers user emotion vectors from 5 layers of behavioral and content signals.
    """

    def __init__(self):
        pass

    # ── Layer 1: Behavioral Signals ──
    def analyze_behavioral(self, events: List[Any]) -> Dict[str, Any]:
        """
        Analyze scroll, dwell, and view patterns.
        - High scroll speed + short dwell time -> high arousal/restlessness or boredom.
        - Low scroll speed + long dwell time -> deep interest, trust, or contemplative sadness.
        - High interaction frequency -> excitement, social energy.
        """
        if not events:
            return {
                'vector': [0.125] * 8,
                'arousal': 0.5,
                'depth': 0.5,
                'social_energy': 0.5
            }

        scroll_speeds = []
        dwell_times = []
        interaction_count = 0
        total_events = len(events)

        for event in events:
            # Handle both dicts and Pydantic models
            e_type = event.event_type if hasattr(event, 'event_type') else event.get('event_type')
            duration = event.duration_ms if hasattr(event, 'duration_ms') else event.get('duration_ms')
            metadata = event.metadata if hasattr(event, 'metadata') else event.get('metadata', {})
            if metadata is None:
                metadata = {}

            if e_type == 'scroll':
                scroll_speed = metadata.get('scroll_speed', 1.0)
                scroll_speeds.append(scroll_speed)
            elif e_type == 'dwell' or e_type == 'view':
                if duration:
                    dwell_times.append(duration / 1000.0) # convert to seconds
            
            if e_type in ['react', 'comment', 'share', 'save']:
                interaction_count += 1

        avg_scroll = np.mean(scroll_speeds) if scroll_speeds else 1.5
        avg_dwell = np.mean(dwell_times) if dwell_times else 3.0
        interaction_rate = interaction_count / max(total_events, 1)

        vector = np.zeros(8)
        
        # Arousal (0.0 to 1.0) based on scroll speed (5.0 px/ms is high)
        arousal = float(min(1.0, avg_scroll / 5.0))
        # Depth (0.0 to 1.0) based on dwell time (10s is deep)
        depth = float(min(1.0, avg_dwell / 10.0))
        # Social Energy based on interaction rate (30% is high)
        social_energy = float(min(1.0, interaction_rate / 0.3))

        # Pattern mapping to Plutchik dimensions
        if arousal > 0.6 and social_energy > 0.5:
            # Fast + interactive -> excitement, anticipation, surprise
            vector[0] = 0.4  # joy
            vector[2] = 0.4  # anticipation
            vector[3] = 0.2  # surprise
        elif arousal < 0.3 and depth > 0.6:
            # Slow + deep reading -> trust, contemplative joy
            vector[1] = 0.6  # trust
            vector[0] = 0.4  # joy
        elif arousal > 0.6 and social_energy < 0.2:
            # Fast scrolling, not interacting -> boredom/restlessness -> slight anger/disgust or sadness
            vector[6] = 0.3  # anger/frustration
            vector[7] = 0.3  # disgust
            vector[4] = 0.4  # sadness (unmet expectation)
        elif arousal < 0.3 and social_energy < 0.2:
            # Slow and passive -> sadness, fear/anxiety
            vector[4] = 0.6  # sadness
            vector[5] = 0.4  # fear
        else:
            # Neutral / average
            vector = np.full(8, 0.125)

        # Normalize
        vector = vector / (vector.sum() + 1e-6)

        return {
            'vector': vector.tolist(),
            'arousal': arousal,
            'depth': depth,
            'social_energy': social_energy
        }

    # ── Layer 2: Content Interaction ──
    def analyze_interactions(self, interactions: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze reaction types and interaction scores.
        """
        vector = np.zeros(8)
        
        reaction_counts = interactions.get('reactions', {})
        total_reactions = sum(reaction_counts.values())
        
        if total_reactions > 0:
            for i, emotion in enumerate(EMOTIONS):
                vector[i] = reaction_counts.get(emotion, 0) / total_reactions
        
        # Save rate -> trust, anticipation
        save_rate = interactions.get('save_rate', 0.0)
        if save_rate > 0.1:
            vector[1] += 0.2  # trust
            vector[2] += 0.1  # anticipation

        # Share rate -> joy, trust
        share_rate = interactions.get('share_rate', 0.0)
        if share_rate > 0.05:
            vector[0] += 0.2  # joy
            vector[1] += 0.1  # trust

        # Normalize
        if vector.sum() > 0:
            vector = vector / vector.sum()
        else:
            vector = np.full(8, 0.125)

        return {'vector': vector.tolist()}

    # ── Layer 3: Text Sentiment Analysis ──
    def analyze_texts(self, texts: List[str]) -> Dict[str, Any]:
        """
        Perform NLP sentiment analysis on recent text logs using the HuggingFace model.
        Returns a mapping onto Plutchik dimensions.
        """
        vector = np.zeros(8)
        sentiment_pipeline = model_loader.get_emotion_model()

        if not texts or sentiment_pipeline is None:
            return {'vector': [0.125] * 8}

        valid_texts = [t for t in texts if t and len(t.strip()) >= 2]
        if not valid_texts:
            return {'vector': [0.125] * 8}

        for text in valid_texts[:10]:  # limit to 10 items
            try:
                # model outputs: '1 star', '2 stars', etc.
                result = sentiment_pipeline(text[:512])[0]
                label = result['label']
                score = result['score']
                
                # Parse stars (1 to 5)
                stars = int(label.split()[0])
                
                if stars >= 4:
                    # Positive sentiment -> joy, trust, anticipation
                    vector[0] += score * 0.5  # joy
                    vector[1] += score * 0.3  # trust
                    vector[2] += score * 0.2  # anticipation
                elif stars <= 2:
                    # Negative sentiment -> sadness, anger, fear, disgust
                    vector[4] += score * 0.4  # sadness
                    if "tệ" in text.lower() or "ghét" in text.lower() or "bực" in text.lower():
                        vector[6] += score * 0.4  # anger
                    else:
                        vector[5] += score * 0.3  # fear
                        vector[7] += score * 0.1  # disgust
                else:
                    # Neutral sentiment -> surprise, trust
                    vector[3] += score * 0.4  # surprise
                    vector[1] += score * 0.4  # trust
                    vector[2] += score * 0.2  # anticipation
            except Exception as e:
                print(f"⚠️ Error analyzing text sentiment: {e}")
                # Fallback to general neutral contribution
                vector += 0.125

        if vector.sum() > 0:
            vector = vector / vector.sum()
        else:
            vector = np.full(8, 0.125)

        return {'vector': vector.tolist()}

    # ── Layer 4: Temporal Context ──
    def analyze_temporal(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Circadian pattern mapping.
        - 22:00 to 04:00 (Late Night) -> Loneliness, Sadness, Trust (seeking connection).
        - 06:00 to 10:00 (Morning) -> Joy, Anticipation.
        - 14:00 to 17:00 (Afternoon) -> Fatigue, slight Boredom (Disgust/Sadness).
        """
        hour = context.get('hour', 12)
        day_of_week = context.get('day_of_week', 2) # 0=Mon, 6=Sun
        session_gap_hours = context.get('session_gap_hours', 2.0)

        vector = np.full(8, 0.125)

        # Late night vulnerabity
        if 22 <= hour or hour <= 4:
            vector[4] += 0.2  # sadness (reflectiveness)
            vector[1] += 0.15 # trust (desire to connect)
            vector[5] += 0.05 # fear/anxiety
        
        # Morning motivation
        elif 6 <= hour <= 10:
            vector[0] += 0.2  # joy
            vector[2] += 0.2  # anticipation
        
        # Weekend chill
        if day_of_week >= 5:
            vector[0] += 0.1  # joy
            vector[1] += 0.05 # trust
        
        # Rapid reopening -> high anticipation/anxiety
        if session_gap_hours < 0.5:
            vector[2] += 0.15 # anticipation
            vector[5] += 0.05 # fear/restlessness

        vector = vector / vector.sum()
        return {'vector': vector.tolist()}

    # ── Layer 5: Social Graph ──
    def analyze_social(self, social_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze social graph characteristics.
        - High reciprocity rate -> trust, joy.
        - Unrequited interactions -> sadness, anger.
        """
        vector = np.full(8, 0.125)
        reciprocity_rate = social_data.get('reciprocity_rate', 0.5)

        if reciprocity_rate > 0.7:
            vector[1] += 0.3  # trust
            vector[0] += 0.2  # joy
        elif reciprocity_rate < 0.3:
            vector[4] += 0.2  # sadness
            vector[6] += 0.1  # anger/frustration

        vector = vector / vector.sum()
        return {'vector': vector.tolist()}

    # ── Signal Fusion ──
    def fuse_signals(
        self,
        behavioral: Dict[str, Any],
        interaction: Dict[str, Any],
        text: Dict[str, Any],
        temporal: Dict[str, Any],
        social: Dict[str, Any],
        explicit_mood: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Combine all layers using a weighted fusion model.
        Returns final 8D vector and meta-dimensions (valence, arousal, dominance).
        """
        # Default Weights
        weights = {
            'behavioral': 0.30,
            'interaction': 0.25,
            'text': 0.25,
            'temporal': 0.10,
            'social': 0.10
        }

        # If explicit mood check-in is present, increase text/explicit weights
        if explicit_mood in EMOTIONS:
            # Let explicit mood shape 35% of the final vector directly, reduce other weights
            explicit_vector = np.zeros(8)
            explicit_vector[EMOTIONS.index(explicit_mood)] = 1.0
            explicit_weight = 0.35
            
            # Scale down others to sum up to 0.65
            scale = 0.65
        else:
            explicit_vector = np.zeros(8)
            explicit_weight = 0.0
            scale = 1.0

        fused = np.zeros(8)
        fused += np.array(behavioral['vector']) * weights['behavioral'] * scale
        fused += np.array(interaction['vector']) * weights['interaction'] * scale
        fused += np.array(text['vector']) * weights['text'] * scale
        fused += np.array(temporal['vector']) * weights['temporal'] * scale
        fused += np.array(social['vector']) * weights['social'] * scale
        
        fused += explicit_vector * explicit_weight
        
        # Re-normalize
        fused = fused / (fused.sum() + 1e-6)

        # ── Meta-Dimensions ──
        # Valence: positive emotions minus negative emotions
        # Positive: joy, trust, anticipation
        # Negative: sadness, fear, anger, disgust
        # Surprise is neutral/dependent
        valence = (fused[0] + fused[1] + fused[2]) - (fused[4] + fused[5] + fused[6] + fused[7])
        
        # Arousal: high energy states (joy, anticipation, surprise, anger)
        arousal = fused[0] + fused[2] + fused[3] + fused[6]
        
        # Dominance: level of assertiveness/control (joy, anger, trust vs fear, sadness)
        dominance = (fused[0] + fused[6] + fused[1]) - (fused[5] + fused[4])

        return {
            'emotion_vector': {EMOTIONS[i]: round(float(fused[i]), 4) for i in range(8)},
            'valence': round(float(valence), 4),
            'arousal': round(float(min(1.0, max(-1.0, arousal))), 4),
            'dominance': round(float(min(1.0, max(-1.0, dominance))), 4)
        }

    # ── Emotional Mode Detection ──
    def detect_emotional_mode(self, emotion_vector: Dict[str, Any], weekly_trend: Optional[Dict[str, Any]] = None) -> str:
        """
        Categorizes user state into an emotional mode to drive content delivery.
        - gentle_uplift: user is experiencing persistent sadness -> inject mild positive vibes.
        - empathetic_mirror: user has temporary sadness -> show comforting/mirroring content.
        - amplify: high energy positive -> amplify with excited content.
        - deep_chill: low energy state -> show calming, relaxing content.
        - explore: neutral/balanced state -> default discovery.
        """
        valence = emotion_vector.get('valence', 0.0)
        arousal = emotion_vector.get('arousal', 0.5)
        
        # Check weekly stability if present
        stability = 0.5
        if weekly_trend:
            stability = weekly_trend.get('stability_score', 0.5)

        if valence < -0.3:
            if stability < 0.4:
                return "gentle_uplift"      # Persistent low mood -> uplift gently
            else:
                return "empathetic_mirror"  # Acute/temporary low mood -> empathize/comfort
        elif valence > 0.4 and arousal > 0.5:
            return "amplify"                # Happy & active -> matching high energy
        elif arousal < 0.3:
            return "deep_chill"             # Low energy -> relaxation, calm content
        else:
            return "explore"                # Balanced -> explore new vibes

    # ── Confidence Score ──
    def calculate_confidence(self, signals_available: Dict[str, Any]) -> float:
        """
        Returns a confidence score based on the quantity and diversity of data signals.
        """
        confidence = 0.2 # Baseline

        if signals_available.get('behavioral_count', 0) > 15:
            confidence += 0.2
        if signals_available.get('interaction_count', 0) > 5:
            confidence += 0.2
        if signals_available.get('text_count', 0) > 0:
            confidence += 0.2
        if signals_available.get('has_explicit_mood', False):
            confidence += 0.2

        return min(1.0, confidence)


# Singleton instance
emotion_inference_engine = EmotionInferenceEngine()
