# AURA Social – Ambient Emotional Intelligence Social Platform

> **"Your emotions shape your feed. Your feed heals your emotions."**

## 🚀 Overview

AURA Social là nền tảng mạng xã hội sử dụng **AI suy luận cảm xúc** từ hành vi người dùng, tạo ra trải nghiệm cá nhân hóa sâu mà không cần thao tác thủ công.

## 🏗️ Architecture: Hybrid (Firebase + FastAPI)

```
Flutter App ─── Firebase SDK ───► Firebase (data, auth, chat)
            └── dio HTTP ────────► FastAPI (AI, recommendation, soul connect)

Cloud Functions ── HTTP ─────────► FastAPI (content analysis triggers)
```

## 📁 Project Structure

```
AURA-Social/
├── docs/                         # Tài liệu hệ thống
│   ├── AURA-System-Design/       # 8 tài liệu thiết kế chi tiết
│   ├── team/                     # Phân công + khung xương
│   └── ui-mockups/               # Giao diện mẫu + wireframes
│
├── app/                          # Flutter mobile app
├── fastapi-backend/              # FastAPI AI server
└── firebase/                     # Cloud Functions + Rules
```

## 👥 Team

| Role | Phạm vi |
|---|---|
| 👑 Leader | Firebase + Cloud Functions + DevOps |
| 🤖 Person 2 | FastAPI AI Backend |
| 📱 Person 3 | Flutter Core (Auth, Feed, Post, Profile) |
| 💬 Person 4 | Flutter Social (Chat, Soul, Waves, Settings) |

## 🛠️ Tech Stack

- **Frontend:** Flutter 3.19+ / Dart / Riverpod / GoRouter / dio
- **AI Backend:** FastAPI / Python 3.12 / HuggingFace / PyTorch
- **Data:** Firebase Firestore + Realtime Database
- **Auth:** Firebase Auth (Google, Apple, Email)
- **Deploy:** Cloud Run (FastAPI) + Firebase Hosting
