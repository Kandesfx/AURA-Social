"""
AURA Social – Empathetic AI Prompt Engine
Generates conversational icebreakers and reply recommendations.
Integrates Google Gemini 1.5 Flash with fallback to local rule-based templates.
"""
import json
import re
from typing import List, Dict, Any, Optional
import google.generativeai as genai
from app.config import get_settings

ICEBREAKERS = {
    "default": [
        "Hôm nay của bạn thế nào? Có điều gì làm bạn cười không? 😊",
        "Nếu được chọn một bài hát để mô tả ngày hôm nay, bạn chọn bài gì? 🎶",
        "Hiện tại bạn đang làm gì đó? Có muốn cùng chia sẻ chút không? ✨"
    ],
    "stressed": [
        "Mình nghe nói hôm nay bạn hơi căng thẳng. Cứ thong thả nhé, muốn chia sẻ chút không? ☕",
        "Khi bị stress, bạn thường thích làm gì để xoa dịu tâm trí thế? 🍃",
        "Hãy cùng hít thở sâu một nhịp nhé. Có chuyện gì đang làm bạn bận lòng à? 🌊"
    ],
    "sad": [
        "Gửi tới bạn một cái ôm ấm áp. Nếu cần một người lắng nghe, mình luôn ở đây. 🫂",
        "Hôm nay là một ngày hơi xám xịt đúng không? Bạn có muốn trút bầu tâm sự không?",
        "Không sao cả khi cảm thấy buồn. Có điều gì nhỏ bé có thể làm bạn thấy dễ chịu hơn lúc này không? 🌸"
    ],
    "happy": [
        "Năng lượng tích cực quá! Có chuyện gì vui chia sẻ cho mình cười cùng với! 🤩",
        "Niềm vui nhân đôi khi được chia sẻ. Hôm nay có điều gì đặc biệt thế? 🎉",
        "Mong là niềm vui này sẽ lan tỏa suốt cả ngày của bạn! Bạn đang làm gì thế?"
    ],
    "lonely": [
        "Có những ngày ta cảm thấy hơi lạc lõng. Rất vui vì được kết nối với bạn ở đây! 💫",
        "Chúng ta cùng trò chuyện nhé, bạn có muốn chia sẻ về sở thích hay một bộ phim tâm đắc không?",
        "Bạn không cô đơn đâu. Hiện tại bạn đang chill hay đang bận bịu gì thế? ☕"
    ],
    "anxious": [
        "Mọi chuyện rồi sẽ ổn thôi, đừng lo lắng quá nhé. Mình cùng tán gẫu chuyện gì đó vui vẻ nha! 🌱",
        "Nếu cảm thấy ngột ngạt, hãy thử nhấp một ngụm nước ấm xem sao. Bạn muốn nói về chủ đề gì để giải tỏa nào?",
        "Chúng mình có thể trò chuyện nhẹ nhàng về những điều bình dị được không? 🌼"
    ]
}

RELATIONSHIP_PROMPTS = {
    "Twin Flame": [
        "Chúng ta có tần số cảm xúc cực kỳ giống nhau tuần này đấy! Có bao giờ bạn cảm thấy xúc động trước những điều rất nhỏ nhặt không?",
        "Sự đồng điệu này thật đặc biệt. Bạn có sở thích nào cực kỳ đam mê không? 🚀"
    ],
    "Vibe Partner": [
        "Chào người bạn cùng gu! Gu âm nhạc hay nghệ thuật của bạn dạo này thế nào? 🎵",
        "Thật tuyệt khi gặp người có năng lượng tương đồng. Ngày hôm nay của bạn có điều gì thú vị không?"
    ],
    "Complementary Vibe": [
        "Chúng ta là hai mảnh ghép khá thú vị đấy – một người tràn đầy năng lượng và một người rất điềm tĩnh. Bạn nghĩ sao về sự kết hợp này? ☯️",
        "Sự khác biệt làm nên điều kỳ diệu. Bạn thường làm gì khi muốn tìm lại sự cân bằng?"
    ],
    "Kindred Spirit": [
        "Chào tri kỷ! Chúng ta có thói quen thời gian hoạt động rất giống nhau. Bạn là người hướng về ban đêm hay ban ngày thế? 🌙"
    ]
}

class PromptEngine:
    """
    Generates tailored conversational guidelines and response recommendations.
    Uses Google Gemini API when available, otherwise falls back to local database.
    """

    def _get_gemini_model(self) -> Optional[genai.GenerativeModel]:
        """Initialize and return Gemini model if key is configured."""
        settings = get_settings()
        if not settings.gemini_api_key:
            return None
        try:
            genai.configure(api_key=settings.gemini_api_key)
            return genai.GenerativeModel('gemini-2.0-flash')
        except Exception as e:
            print(f"⚠️ PromptEngine: Failed to configure Gemini API client: {e}")
            return None

    def _parse_gemini_json_list(self, text: str) -> Optional[List[str]]:
        """Extract and parse list from Gemini text response."""
        try:
            # Extract JSON array using regex
            match = re.search(r'\[.*\]', text, re.DOTALL)
            if match:
                items = json.loads(match.group(0))
                if isinstance(items, list) and all(isinstance(i, str) for i in items):
                    return items
        except Exception as e:
            print(f"⚠️ PromptEngine: Failed to parse Gemini response as list: {e}. Raw: {text}")
        return None

    def generate_icebreakers(
        self,
        user_mood: str,
        partner_mood: str,
        connection_type: Optional[str] = None
    ) -> List[str]:
        """
        Generate 3 warm, emotional icebreakers.
        Tries Gemini API first, falls back to local rules.
        """
        model = self._get_gemini_model()
        if model:
            prompt = f"""
            Bạn là một trợ lý AI đồng cảm của mạng xã hội thấu cảm AURA.
            Hãy tạo 3 câu gợi mở trò chuyện (icebreakers) bằng Tiếng Việt thân thiện, tự nhiên, ấm áp để bắt đầu cuộc trò chuyện.
            Ngữ cảnh:
            - Người gửi (tôi) đang có tâm trạng: {user_mood}
            - Người nhận (bạn) đang có tâm trạng: {partner_mood}
            - Kiểu kết nối linh hồn giữa hai người: {connection_type or "bình thường"}
            
            Yêu cầu:
            - Trả về kết quả dưới dạng danh sách JSON chứa mảng gồm đúng 3 chuỗi câu thoại gợi mở, ví dụ: ["câu 1", "câu 2", "câu 3"].
            - Không thêm bất kỳ văn bản giải thích, ký tự đặc biệt hay ký tự markdown nào ngoài JSON.
            """
            try:
                response = model.generate_content(prompt)
                res_list = self._parse_gemini_json_list(response.text)
                if res_list and len(res_list) >= 3:
                    print("✨ PromptEngine: Generated icebreakers using Gemini.")
                    return res_list[:3]
            except Exception as e:
                print(f"⚠️ PromptEngine: Gemini generation failed, falling back to local: {e}")

        # FALLBACK: Local template-based rules
        prompts = []
        mood_key = partner_mood.lower() if partner_mood.lower() in ICEBREAKERS else "default"
        prompts.extend(ICEBREAKERS[mood_key])

        if connection_type and connection_type in RELATIONSHIP_PROMPTS:
            prompts.extend(RELATIONSHIP_PROMPTS[connection_type])

        seen = set()
        unique_prompts = []
        for p in prompts:
            if p not in seen:
                seen.add(p)
                unique_prompts.append(p)
                if len(unique_prompts) >= 3:
                    break

        if not unique_prompts:
            unique_prompts = ICEBREAKERS["default"][:3]

        return unique_prompts

    def suggest_replies(
        self,
        last_message: str,
        partner_mood: str,
        user_mood: str
    ) -> List[str]:
        """
        Suggest quick empathetic replies based on the last message received.
        Tries Gemini API first, falls back to local rules.
        """
        model = self._get_gemini_model()
        if model:
            prompt = f"""
            Bạn là một trợ lý AI đồng cảm của mạng xã hội AURA.
            Hãy gợi ý 3 câu trả lời ngắn gọn (Tiếng Việt, tối đa 15 từ mỗi câu) ấm áp và thấu cảm để người dùng gửi lại.
            Tin nhắn nhận được từ đối phương: "{last_message}"
            Tâm trạng đối phương: {partner_mood}
            Tâm trạng của tôi: {user_mood}
            
            Yêu cầu:
            - Trả về kết quả dưới dạng danh sách JSON chứa mảng gồm đúng 3 câu gợi ý phản hồi, ví dụ: ["phản hồi 1", "phản hồi 2", "phản hồi 3"].
            - Không thêm văn bản giải thích hay ký tự markdown nào khác ngoài JSON.
            """
            try:
                response = model.generate_content(prompt)
                res_list = self._parse_gemini_json_list(response.text)
                if res_list and len(res_list) >= 3:
                    print("✨ PromptEngine: Suggested replies using Gemini.")
                    return res_list[:3]
            except Exception as e:
                print(f"⚠️ PromptEngine: Gemini reply suggestion failed, falling back to local: {e}")

        # FALLBACK: Local keyword-based rules
        msg = last_message.lower()
        suggestions = []

        if any(w in msg for w in ["buồn", "tệ", "chán", "mệt", "khóc", "nản"]):
            suggestions = [
                "Mình hiểu mà, nghe thôi đã thấy mệt mỏi rồi. Bạn ôm một cái nhé! 🫂",
                "Đừng tự tạo áp lực cho mình quá nhé. Mình luôn ở đây lắng nghe bạn.",
                "Có điều gì mình có thể giúp bạn thấy đỡ hơn không?"
            ]
        elif any(w in msg for w in ["vui", "tuyệt", "khoe", "đạt được", "cười"]):
            suggestions = [
                "Chúc mừng bạn nhé! Siêu quá đi mất! 🎉",
                "Nghe thôi đã thấy vui lây rồi! Cảm ơn bạn đã chia sẻ năng lượng tích cực này nha!",
                "Thật tuyệt vời! Bạn đã kỷ niệm niềm vui này thế nào rồi?"
            ]
        elif any(w in msg for w in ["căng thẳng", "stress", "áp lực", "lo lắng", "sợ"]):
            suggestions = [
                "Hãy hít một hơi thật sâu nào. Mọi việc rồi sẽ ổn thôi, đừng lo quá nha. 🌱",
                "Nếu mệt quá, bạn hãy nghỉ tay một lát nhé. Sức khỏe tinh thần là quan trọng nhất.",
                "Mình cùng nói về chuyện gì đó vui vẻ để giải tỏa áp lực nhé?"
            ]
        else:
            if partner_mood == "stressed" or partner_mood == "sad":
                suggestions = [
                    "Bạn cứ nói đi, mình đang lắng nghe đây. ☕",
                    "Mong rằng cuộc trò chuyện của chúng ta sẽ giúp bạn nhẹ lòng hơn một chút.",
                    "Hôm nay bạn đã tự chăm sóc bản thân chưa?"
                ]
            else:
                suggestions = [
                    "Nghe thú vị thật đấy! Bạn kể thêm đi. 😄",
                    "Thật vui vì được kết nối và trò chuyện cùng bạn!",
                    "À, bạn có sở thích hay thói quen gì đặc biệt vào cuối tuần không?"
                ]

        return suggestions[:3]

# Singleton instance
prompt_engine = PromptEngine()
