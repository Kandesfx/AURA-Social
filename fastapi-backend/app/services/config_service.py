"""
AURA Social – Firestore Dynamic Configuration Service
Loads and caches keywords/rules dynamically from Firestore collections.
"""
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, List
from app.utils.firebase_client import get_firestore

class FirestoreConfigService:
    """
    Manages dynamic application parameters stored in Firestore under the 'configs' collection.
    Caches items locally for 10 minutes to minimize read costs.
    """

    def __init__(self):
        self._cached_moderation = None
        self._cached_self_care = None
        self._last_fetched_moderation = None
        self._last_fetched_self_care = None
        self.cache_duration = timedelta(minutes=10)

    def _should_fetch(self, last_fetched: datetime) -> bool:
        if not last_fetched:
            return True
        return datetime.now(timezone.utc) - last_fetched > self.cache_duration

    def get_moderation_config(self) -> Dict[str, List[str]]:
        """
        Retrieve profanity, self-harm, and hate speech keywords dynamically.
        """
        # Fallback defaults in case Firestore is empty/unavailable
        default_config = {
            "profanities": [
                "đm", "đcm", "dcm", "vcl", "clm", "đéo", "chó đẻ", "khốn nạn",
                "bú cu", "đút đít", "lồn", "cặc", "phịch", "nứng", "địt", "đệt",
                "ngu lồn", "ngu cặc", "chó má", "mẹ kiếp", "fuck", "bitch", "shit",
                "cút đi", "cút xéo", "đồ ngu", "ngu ngốc", "đần độn", "óc chó", "đồ tồi"
            ],
            "self_harm": [
                "tự tử", "tự sát", "muốn chết", "kết liễu cuộc đời", "kết liễu",
                "rạch tay", "uống thuốc ngủ", "nhảy lầu", "treo cổ", "cắt cổ tay"
            ],
            "hate_speech": [
                "hồi mọi", "bọn mọi", "mọi rợ", "bê đê", "xúc vật", "súc vật",
                "đồ rác rưởi", "bọn cặn bã", "tẩy chay", "cút về nước"
            ]
        }

        if not self._should_fetch(self._last_fetched_moderation) and self._cached_moderation:
            return self._cached_moderation

        try:
            db = get_firestore()
            doc_ref = db.collection('configs').document('moderation').get()
            if doc_ref.exists:
                data = doc_ref.to_dict()
                # Ensure all lists exist
                config = {
                    "profanities": data.get("profanities") or default_config["profanities"],
                    "self_harm": data.get("self_harm") or default_config["self_harm"],
                    "hate_speech": data.get("hate_speech") or default_config["hate_speech"]
                }
                self._cached_moderation = config
                self._last_fetched_moderation = datetime.now(timezone.utc)
                print("⚙️ Dynamic Config: Successfully loaded moderation keywords from Firestore.")
                return self._cached_moderation
        except Exception as e:
            print(f"⚠️ Dynamic Config: Failed to load moderation config from Firestore, using defaults: {e}")

        # If fetch fails, return defaults or previously cached
        return self._cached_moderation or default_config

    def get_self_care_config(self) -> Dict[str, Any]:
        """
        Retrieve self-care recommendation configs.
        """
        # Fallback defaults in case Firestore is empty/unavailable
        default_config = {
            "sadness": {
                "activities": [
                    "Thực hành viết nhật ký cảm xúc 10 phút trước khi ngủ để trút bỏ muộn phiền.",
                    "Đi bộ nhẹ nhàng ở nơi có nhiều cây xanh hoặc hồ nước để làm dịu tâm trí.",
                    "Thực hành bài thiền tự ôm lấy bản thân (self-compassion) 5 phút."
                ],
                "music_vibe": "Nhạc Acoustic mộc mạc, Lofi ấm áp hoặc tiếng mưa rơi tự nhiên.",
                "social_tip": "Hãy gửi tin nhắn trò chuyện với một người bạn thân thiết trong mục 'Soul Connect' để nhận được sự đồng cảm."
            },
            "anger": {
                "activities": [
                    "Thực hành kỹ thuật thở hộp (Box Breathing) 4-4-4-4 khi cảm thấy nóng giận dâng trào.",
                    "Tập thể dục cường độ cao (chạy bộ, cardio) để giải phóng hormone cortisol dư thừa.",
                    "Viết những điều bức bối ra giấy rồi xé bỏ để giải tỏa tâm lý."
                ],
                "music_vibe": "Nhạc không lời tiết tấu chậm, nhạc tần số Solfeggio 528Hz làm dịu thần kinh.",
                "social_tip": "Tạm ngắt kết nối mạng xã hội 1 giờ và tránh tranh luận trực tuyến lúc này."
            },
            "fear": {
                "activities": [
                    "Thực hành kỹ thuật tiếp đất 5-4-3-2-1 để giảm bớt cảm giác lo âu bồn chồn.",
                    "Uống một tách trà thảo mộc ấm (hoa cúc, hoa oải hương) và đọc một cuốn sách nhẹ nhàng.",
                    "Liệt kê những điều nằm trong tầm kiểm soát của bạn để tái định hình suy nghĩ."
                ],
                "music_vibe": "Nhạc tần số 432Hz xoa dịu lo âu hoặc nhạc thiền định nhẹ nhàng (Ambient).",
                "social_tip": "Trò chuyện với những người bạn có điểm số 'trust' cao để tìm cảm giác an toàn."
            },
            "joy": {
                "activities": [
                    "Lưu giữ khoảnh khắc đẹp này bằng cách viết ra 3 điều biết ơn hôm nay.",
                    "Thực hiện một hành động tử tế nhỏ cho người xung quanh (gửi lời khen, giúp đỡ đồng nghiệp).",
                    "Thực hiện một dự án sáng tạo (vẽ tranh, nấu món ăn mới, chụp ảnh)."
                ],
                "music_vibe": "Nhạc Indie Pop tươi vui, nhạc tiết tấu nhanh năng lượng (Upbeat).",
                "social_tip": "Chia sẻ niềm vui hoặc bài viết truyền cảm hứng lên bảng tin AURA để lan tỏa vibe tích cực."
            },
            "default": {
                "activities": [
                    "Duy trì thói quen ngủ đúng giờ và uống đủ nước mỗi ngày.",
                    "Dành 15 phút ngồi tĩnh tâm ngắm cảnh xung quanh mà không bấm điện thoại.",
                    "Thử giãn cơ nhẹ nhàng giữa giờ làm việc."
                ],
                "music_vibe": "Nhạc Chillhop, Jazz nhẹ nhàng hoặc không lời nhẹ nhàng.",
                "social_tip": "Tương tác nhẹ nhàng với bạn bè bằng các reaction thấu cảm trên AURA."
            }
        }

        if not self._should_fetch(self._last_fetched_self_care) and self._cached_self_care:
            return self._cached_self_care

        try:
            db = get_firestore()
            doc_ref = db.collection('configs').document('self_care').get()
            if doc_ref.exists:
                self._cached_self_care = doc_ref.to_dict()
                self._last_fetched_self_care = datetime.now(timezone.utc)
                print("⚙️ Dynamic Config: Successfully loaded self-care config from Firestore.")
                return self._cached_self_care
        except Exception as e:
            print(f"⚠️ Dynamic Config: Failed to load self-care config from Firestore: {e}")

        return self._cached_self_care or default_config

# Singleton instance
config_service = FirestoreConfigService()
