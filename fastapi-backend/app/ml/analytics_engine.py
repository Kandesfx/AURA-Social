"""
AURA Social – Weekly Emotional Analytics & Self-Care Engine
Aggregates 7-day user mood data, calculates stability metrics, and generates self-care plans.
Integrates Google Gemini 1.5 Flash for personalized letters with fallback to local templates.
"""
import json
import re
from typing import List, Dict, Any, Optional
import numpy as np
from datetime import datetime, timedelta, timezone
from app.config import get_settings
from app.ml.emotion_engine import EMOTIONS
from app.services.config_service import config_service

class WeeklyAnalyticsEngine:
    """
    Analyzes weekly mood check-ins and interaction logs to produce
    comprehensive emotional reports and wellness recommendations.
    Uses Google Gemini API for personalized letters and dynamic advice.
    """

    def _get_gemini_model(self) -> Optional[Any]:
        """Initialize and return Gemini model if key is configured (AI Studio) or via Vertex AI."""
        settings = get_settings()
        
        # 1. Try AI Studio if API key is provided
        if settings.gemini_api_key:
            try:
                import google.generativeai as genai
                genai.configure(api_key=settings.gemini_api_key)
                return genai.GenerativeModel('gemini-2.0-flash')
            except Exception as e:
                print(f"⚠️ AnalyticsEngine: Failed to configure AI Studio client: {e}")
                
        # 2. Otherwise, try Vertex AI (runs on Cloud Run with Service Account)
        try:
            import vertexai
            from vertexai.generative_models import GenerativeModel
            
            # Initialize Vertex AI. Location is set to asia-east1 (same as Cloud Run)
            vertexai.init(project="aura-social-vn", location="asia-east1")
            
            # Vertex AI Gemini model name
            return GenerativeModel("gemini-2.0-flash")
        except Exception as e:
            print(f"⚠️ AnalyticsEngine: Failed to configure Vertex AI client: {e}")
            return None

    def _generate_personalized_letter_gemini(
        self,
        user_id: str,
        dominant_emotion: str,
        stability_index: float,
        stability_label: str,
        trends: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """Call Gemini to write a personalized empathetic letter and customize self-care recommendations."""
        model = self._get_gemini_model()
        if not model:
            return None

        prompt = f"""
        Bạn là một chuyên gia tâm lý học thấu cảm và trị liệu tinh thần của mạng xã hội AURA.
        Hãy viết một lá thư phân tích ngắn gọn, ấm áp (Tiếng Việt, khoảng 120-150 từ, thân mật) gửi cho người dùng có ID là {user_id}.
        
        Số liệu phân tích tuần này của họ:
        - Cảm xúc chủ đạo tuần: {dominant_emotion}
        - Chỉ số ổn định tâm trạng: {stability_index}/1.0 ({stability_label})
        - Giờ tiêu cực nhất: {trends['peak_negative_hour']}h
        - Giờ tích cực nhất: {trends['peak_positive_hour']}h
        - Xu hướng tuần: {trends['weekend_vs_weekday']}
        
        Yêu cầu:
        1. Giọng văn thật chân thành, thấu hiểu, mang lại cảm giác bình yên và an ủi cho người đọc. Xưng hô "mình" và "bạn".
        2. Gợi ý 3 hoạt động tự chăm sóc bản thân (self-care) hành động được ngay tương thích với trạng thái này.
        3. Gợi ý 1 thể loại/vibe âm nhạc xoa dịu tâm hồn phù hợp.
        
        Hãy trả về kết quả dưới dạng cấu trúc JSON chính xác sau:
        {{
          "letter": "nội dung lá thư gửi người dùng",
          "activities": ["hoạt động 1", "hoạt động 2", "hoạt động 3"],
          "music_vibe": "gợi ý âm nhạc",
          "social_tip": "lời khuyên kết nối bạn bè phù hợp"
        }}
        
        Không viết thêm bất kỳ văn bản giới thiệu hay ký tự markdown nào ngoài JSON.
        """
        try:
            response = model.generate_content(prompt)
            # Parse JSON from response text
            match = re.search(r'\{.*\}', response.text, re.DOTALL)
            if match:
                data = json.loads(match.group(0))
                if all(k in data for k in ["letter", "activities", "music_vibe", "social_tip"]):
                    return data
        except Exception as e:
            print(f"⚠️ AnalyticsEngine: Failed to generate report with Gemini: {e}")
        return None

    def generate_weekly_report(
        self,
        user_id: str,
        checkins: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Generate a detailed 7-day emotional report and self-care plan.
        `checkins` is a list of check-in records containing:
            - 'timestamp': float or datetime
            - 'emotion_vector': Dict[str, float] or List[float]
            - 'dominant_emotion': str
        """
        if not checkins:
            return self._get_default_report(user_id)

        # 1. Parse and extract emotional vectors
        vectors = []
        dominant_counts = {}
        hourly_valences = {h: [] for h in range(24)}
        weekday_valences = {d: [] for d in range(7)}

        for c in checkins:
            ts = c.get('timestamp')
            if isinstance(ts, (int, float)):
                dt = datetime.fromtimestamp(ts, tz=timezone.utc)
            elif isinstance(ts, datetime):
                dt = ts
            else:
                dt = datetime.now(timezone.utc)

            raw_vec = c.get('emotion_vector', {})
            if isinstance(raw_vec, dict):
                vec = [raw_vec.get(e, 0.0) for e in EMOTIONS]
            elif isinstance(raw_vec, list) and len(raw_vec) == 8:
                vec = raw_vec
            else:
                vec = [0.125] * 8

            vectors.append(vec)

            dom = c.get('dominant_emotion')
            if not dom and isinstance(raw_vec, dict) and raw_vec:
                dom = max(raw_vec, key=raw_vec.get)
            dom = dom or 'trust'
            dominant_counts[dom] = dominant_counts.get(dom, 0) + 1

            # Calculate valence: (joy + trust + anticipation) - (sadness + fear + anger + disgust)
            valence = (vec[0] + vec[1] + vec[2]) - (vec[4] + vec[5] + vec[6] + vec[7])
            hourly_valences[dt.hour].append(valence)
            weekday_valences[dt.weekday()].append(valence)

        # 2. Mood Distribution
        avg_vector = np.mean(vectors, axis=0)
        distribution = {EMOTIONS[i]: float(avg_vector[i]) for i in range(8)}
        dominant_emotion = max(dominant_counts, key=dominant_counts.get) if dominant_counts else 'trust'

        # 3. Calculate Stability Index
        valences = []
        for vec in vectors:
            v = (vec[0] + vec[1] + vec[2]) - (vec[4] + vec[5] + vec[6] + vec[7])
            valences.append(v)

        val_std = np.std(valences) if len(valences) > 1 else 0.0
        stability_index = float(max(0.0, min(1.0, 1.0 - val_std)))

        if stability_index >= 0.85:
            stability_label = "Rất ổn định"
            stability_desc = "Tâm trạng của bạn rất vững vàng và cân bằng trong tuần qua."
        elif stability_index >= 0.65:
            stability_label = "Ổn định"
            stability_desc = "Tâm trạng của bạn dao động trong mức bình thường, dễ dàng tự điều chỉnh."
        elif stability_index >= 0.45:
            stability_label = "Biến động nhẹ"
            stability_desc = "Có sự lên xuống thất thường về cảm xúc. Bạn nên chú ý dành thời gian nghỉ ngơi."
        else:
            stability_label = "Biến động mạnh"
            stability_desc = "Tâm trạng thay đổi đột ngột hoặc chịu áp lực lớn. Hãy cân nhắc thực hành các bài tập giảm stress."

        # 4. Analyze Triggers & Trends
        peak_neg_hour = 22
        peak_pos_hour = 10

        avg_hourly_valence = {h: np.mean(vals) if vals else 0.0 for h, vals in hourly_valences.items()}
        if avg_hourly_valence:
            peak_neg_hour = min(avg_hourly_valence, key=avg_hourly_valence.get)
            peak_pos_hour = max(avg_hourly_valence, key=avg_hourly_valence.get)

        weekday_vals = []
        for d in range(5):
            weekday_vals.extend(weekday_valences[d])
        weekend_vals = []
        for d in [5, 6]:
            weekend_vals.extend(weekday_valences[d])

        avg_weekday = np.mean(weekday_vals) if weekday_vals else 0.0
        avg_weekend = np.mean(weekend_vals) if weekend_vals else 0.0

        if avg_weekend > avg_weekday + 0.15:
            trend_comparison = "Cuối tuần tích cực hơn rõ rệt so với ngày thường."
        elif avg_weekend < avg_weekday - 0.15:
            trend_comparison = "Ngày thường tích cực hơn cuối tuần (cuối tuần có thể cảm thấy buồn hoặc cô đơn hơn)."
        else:
            trend_comparison = "Cảm xúc cân bằng và ổn định đều giữa các ngày trong tuần."

        trends = {
            "peak_negative_hour": int(peak_neg_hour),
            "peak_positive_hour": int(peak_pos_hour),
            "weekend_vs_weekday": trend_comparison
        }

        # 5. Dynamic / Generative Self-Care plan and Letter
        self_care_plan = None
        personalized_letter = None

        # Try generating customized report using Gemini first
        gemini_data = self._generate_personalized_letter_gemini(
            user_id=user_id,
            dominant_emotion=dominant_emotion,
            stability_index=stability_index,
            stability_label=stability_label,
            trends=trends
        )

        if gemini_data:
            personalized_letter = gemini_data["letter"]
            self_care_plan = {
                "activities": gemini_data["activities"],
                "music_vibe": gemini_data["music_vibe"],
                "social_tip": gemini_data["social_tip"]
            }
        else:
            # Fallback to local config rules (which load dynamically from Firestore via config_service)
            print("ℹ️ WeeklyAnalyticsEngine: Gemini failed or not configured. Falling back to local rules.")
            self_care_plan = self._generate_care_plan_local(dominant_emotion, distribution)
            
            # Simple warm placeholder letter
            personalized_letter = (
                f"Chào bạn! Tuần qua, nhịp cảm xúc của bạn hướng nhiều về trạng thái {dominant_emotion}. "
                f"Tâm trạng của bạn đạt mức độ ổn định {stability_index:.2f} ({stability_label}). "
                f"Hãy tham khảo các gợi ý chăm sóc tinh thần bên dưới để giúp bản thân luôn tràn đầy năng lượng thấu cảm nhé! ❤️"
            )

        # Date range labels
        end_date = datetime.now(timezone.utc)
        start_date = end_date - timedelta(days=7)

        return {
            "user_id": user_id,
            "start_date": start_date.strftime("%Y-%m-%d"),
            "end_date": end_date.strftime("%Y-%m-%d"),
            "mood_distribution": {k: round(v, 3) for k, v in distribution.items()},
            "stability_index": round(stability_index, 3),
            "stability_label": stability_label,
            "stability_description": stability_desc,
            "dominant_emotion": dominant_emotion,
            "trends": trends,
            "personalized_letter": personalized_letter,
            "self_care_plan": self_care_plan
        }

    def _generate_care_plan_local(self, dominant_emotion: str, distribution: Dict[str, float]) -> Dict[str, Any]:
        """Fallback to dynamic self-care plans loaded from Firestore configs."""
        self_care_config = config_service.get_self_care_config()
        
        sadness = distribution.get("sadness", 0.0)
        anger = distribution.get("anger", 0.0)
        fear = distribution.get("fear", 0.0)
        joy = distribution.get("joy", 0.0)

        if sadness > 0.3 or dominant_emotion == "sadness":
            return self_care_config.get("sadness") or self_care_config["default"]
        elif anger > 0.25 or dominant_emotion == "anger":
            return self_care_config.get("anger") or self_care_config["default"]
        elif fear > 0.25 or dominant_emotion == "fear":
            return self_care_config.get("fear") or self_care_config["default"]
        elif joy > 0.3 or dominant_emotion in ["joy", "anticipation"]:
            return self_care_config.get("joy") or self_care_config["default"]
        
        return self_care_config["default"]

    def _get_default_report(self, user_id: str) -> Dict[str, Any]:
        """Fallback default report if no check-ins exist."""
        end_date = datetime.now(timezone.utc)
        start_date = end_date - timedelta(days=7)
        return {
            "user_id": user_id,
            "start_date": start_date.strftime("%Y-%m-%d"),
            "end_date": end_date.strftime("%Y-%m-%d"),
            "mood_distribution": {e: 0.125 for e in EMOTIONS},
            "stability_index": 1.0,
            "stability_label": "Ổn định",
            "stability_description": "Chưa có đủ dữ liệu kiểm tra tâm trạng tuần này. Hãy chăm chỉ check-in cảm xúc hàng ngày nhé!",
            "dominant_emotion": "trust",
            "trends": {
                "peak_negative_hour": 22,
                "peak_positive_hour": 10,
                "weekend_vs_weekday": "Chưa có đủ dữ liệu phân tích."
            },
            "personalized_letter": "Chào mừng bạn đến với AURA! Hãy thực hiện check-in cảm xúc hàng ngày để mở khóa báo cáo sức khỏe tinh thần hàng tuần của riêng bạn nhé! ✨",
            "self_care_plan": {
                "activities": [
                    "Check-in cảm xúc ít nhất 1 lần mỗi ngày trên ứng dụng AURA.",
                    "Dành 5 phút ghi lại nhật ký ngắn vào buổi tối."
                ],
                "music_vibe": "Nhạc hòa tấu nhẹ nhàng hoặc Lofi chill.",
                "social_tip": "Kết bạn mới trên Soul Connect để bắt đầu hành trình thấu cảm cùng nhau."
            }
        }

# Singleton instance
weekly_analytics_engine = WeeklyAnalyticsEngine()
