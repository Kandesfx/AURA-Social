# AURA Social – Giao Diện Mẫu (UI Mockups)

> Tài liệu này mô tả chi tiết giao diện cho từng màn hình, dùng làm reference khi code Flutter.

---

## 1. Design System

### 1.1 Color Palette

```
Dark Theme (Default):
━━━━━━━━━━━━━━━━━━━━━
Background:       #0A0A0F (gần đen, hơi xanh tím)
Surface:          #14141F (card background)
Surface Variant:  #1E1E2E (elevated cards)
Primary:          #8B5CF6 (purple – brand color)
Secondary:        #06B6D4 (cyan accent)
Tertiary:         #F472B6 (pink accent)
On Background:    #E2E8F0 (text chính)
On Surface:       #94A3B8 (text phụ)
Error:            #EF4444
Success:          #22C55E
```

### 1.2 Emotion → Color Mapping

| Emotion | Color | Hex | Gradient |
|---|---|---|---|
| Joy | Amber/Gold | `#F59E0B` | Gold → Orange |
| Trust | Green | `#22C55E` | Green → Teal |
| Anticipation | Orange | `#F97316` | Orange → Amber |
| Surprise | Cyan | `#06B6D4` | Cyan → Blue |
| Sadness | Blue | `#3B82F6` | Blue → Indigo |
| Fear | Purple | `#8B5CF6` | Purple → Violet |
| Anger | Red | `#EF4444` | Red → Rose |
| Disgust | Dark Green | `#84CC16` | Lime → Green |

### 1.3 Typography

```
Font Family: Inter (Google Fonts)

Heading 1:  28sp, Bold
Heading 2:  24sp, SemiBold
Heading 3:  20sp, SemiBold
Body 1:     16sp, Regular
Body 2:     14sp, Regular
Caption:    12sp, Regular
Button:     14sp, SemiBold, UPPERCASE tracking
```

### 1.4 Spacing & Radius

```
Spacing: 4, 8, 12, 16, 20, 24, 32, 48
Border Radius: 8 (small), 12 (medium), 16 (large), 24 (xl), 9999 (pill)
Card Elevation: 0 (flat) với border subtle
```

---

## 2. Screen Designs

### 🔑 2.1 Login Screen (Person 3)

```
┌─────────────────────────────┐
│                             │
│         [AURA Logo]         │  ← Gradient glow animation
│    "Your Emotional Space"   │
│                             │
│  ┌───────────────────────┐  │
│  │  📧 Email             │  │  ← TextField dark
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  🔒 Password          │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │      ĐĂNG NHẬP        │  │  ← Gradient button (purple → cyan)
│  └───────────────────────┘  │
│                             │
│     ─── hoặc tiếp tục ───  │
│                             │
│  ┌───────────────────────┐  │
│  │  G  Đăng nhập Google  │  │  ← White outline button
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  🍎 Đăng nhập Apple   │  │  ← White outline button
│  └───────────────────────┘  │
│                             │
│    Chưa có tài khoản?       │
│    [Đăng ký ngay]           │  ← Text link
│                             │
└─────────────────────────────┘
```

### 📰 2.2 For You Feed (Person 3)

```
┌─────────────────────────────┐
│  ┌─────────────────────────┐│
│  │ For You  │  Following   ││  ← Tab bar, underline indicator
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ ┌──┐                   ││
│  │ │🟣│ Nguyễn Hải   • 2h ││  ← Avatar with Aura Ring glow
│  │ └──┘                   ││
│  │                         ││
│  │ Hôm nay tôi cảm thấy   ││  ← Post content
│  │ thật tuyệt vời khi...   ││
│  │                         ││
│  │ ┌─────────────────────┐ ││
│  │ │    [Post Image]     │ ││  ← Optional media
│  │ └─────────────────────┘ ││
│  │                         ││
│  │ 😊 🤝 🎯 😮 😢 😰 😠 🤢 ││  ← 8 Emotion Reactions
│  │ 12  5   3  1   0  0  0  0││
│  │                         ││
│  │ 💬 23 comments  🔄 Share ││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ [Next Post Card...]     ││
│  └─────────────────────────┘│
│                             │
├─────────────────────────────┤
│ 🏠  🔮  [+]  💬  👤       │  ← Bottom Nav
└─────────────────────────────┘
```

### 🔮 2.3 Soul Connect (Person 4)

```
┌─────────────────────────────┐
│  ← Soul Connect             │
│                             │
│  ┌─────────────────────────┐│
│  │                         ││
│  │      ┌────────┐         ││
│  │      │ 🟣     │         ││  ← Large avatar + Aura Ring
│  │      │ Avatar │         ││
│  │      └────────┘         ││
│  │                         ││
│  │    "Trần Minh Anh"      ││  ← Name
│  │    📍 Hà Nội            ││
│  │                         ││
│  │  ┌─────────────────┐    ││
│  │  │ 🔮 Soul Score    │    ││
│  │  │     87%          │    ││  ← Animated number
│  │  └─────────────────┘    ││
│  │                         ││
│  │  Compatibility:         ││
│  │  ├── Emotional: 92%  ██ ││  ← Progress bars
│  │  ├── Content:  85%   █▓ ││
│  │  ├── Activity: 78%   █░ ││
│  │  └── Social:   88%   ██ ││
│  │                         ││
│  │   [❌ Bỏ qua]  [✅ Kết nối] │  ← Action buttons
│  │                         ││
│  └─────────────────────────┘│
│                             │
│  ← Swipe left / right →    │
│                             │
├─────────────────────────────┤
│ 🏠  🔮  [+]  💬  👤       │
└─────────────────────────────┘
```

### 💬 2.4 Chat Screen (Person 4)

```
┌─────────────────────────────┐
│  ← 🟣 Minh Anh      🟢 Online│
│─────────────────────────────│
│                             │
│        ┌──────────────────┐ │
│        │ Chào bạn! Mình   │ │  ← Other's message (dark surface)
│        │ thấy mình match  │ │
│        │ cao ghê 😄       │ │
│        └────────── 10:30  │ │
│                             │
│  ┌──────────────────┐       │
│  │ Oa thật á! Mình  │       │  ← My message (purple gradient)
│  │ cũng thấy vậy 🎉│       │
│  └──── 10:32        │       │
│                             │
│        ┌──────────────────┐ │
│        │ ...              │ │  ← Typing indicator (3 dots)
│        └──────────────────┘ │
│                             │
│─────────────────────────────│
│ [___Message input___] [📎] [➤]│  ← Input + send
└─────────────────────────────┘
```

### 👤 2.5 Profile Screen (Person 3)

```
┌─────────────────────────────┐
│  ← Profile            ⚙️   │  ← Settings gear icon
│                             │
│         ┌────────┐          │
│         │ 🟣🟢🔵 │          │  ← Large Aura Ring (gradient)
│         │ Avatar │          │
│         └────────┘          │
│                             │
│      "Nguyễn Hải"           │
│      @hai_nguyen             │
│                             │
│   ┌───────┬───────┬───────┐ │
│   │  42   │  128  │  89   │ │
│   │ Posts  │Followers│Following│
│   └───────┴───────┴───────┘ │
│                             │
│   "Dreamer. Coffee lover ☕" │
│                             │
│  ┌─────────────────────────┐│
│  │ 🧭 Emotional Compass   →││  ← Link to compass
│  │ Mood: Anticipation 🎯   ││
│  │ Confidence: 78%         ││
│  └─────────────────────────┘│
│                             │
│  ┌──┬──┬──┐                 │
│  │📷│📷│📷│                 │  ← Post grid (Instagram style)
│  ├──┼──┼──┤                 │
│  │📷│📷│📷│                 │
│  └──┴──┴──┘                 │
│                             │
├─────────────────────────────┤
│ 🏠  🔮  [+]  💬  👤       │
└─────────────────────────────┘
```

### 🌊 2.6 Emotional Waves (Person 4)

```
┌─────────────────────────────┐
│  ← Emotional Waves          │
│                             │
│  Đang hoạt động (3)         │
│                             │
│  ┌─────────────────────────┐│
│  │ 🌊 "Đêm Chill Cùng Nhau"││  ← Wave name (AI-generated)
│  │                         ││
│  │ Cảm xúc: 😌 Relaxed    ││
│  │ 👥 24 members           ││
│  │                         ││
│  │ Momentum: ████████░░ 80%││  ← Momentum bar
│  │                         ││
│  │ ⏰ Còn 2h 15m           ││  ← Time remaining
│  │                         ││
│  │      [Tham gia 🌊]      ││  ← Join button
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ 🌊 "Monday Motivation"  ││
│  │ 😊 Energetic • 👥 12    ││
│  │ Momentum: ███████░░░ 70%││
│  │      [Tham gia 🌊]      ││
│  └─────────────────────────┘│
│                             │
├─────────────────────────────┤
│ 🏠  🔮  [+]  💬  👤       │
└─────────────────────────────┘
```

### 🧭 2.7 Emotional Compass (Person 4)

```
┌─────────────────────────────┐
│  ← Emotional Compass        │
│                             │
│  ┌─────────────────────────┐│
│  │      Joy                ││
│  │       ╱╲                ││
│  │  Trust╱  ╲Anticipation  ││
│  │     ╱ ╲╱╲ ╲             ││  ← Radar chart (8 axes)
│  │  Disgust  Surprise      ││
│  │     ╲    ╱              ││
│  │  Anger╲╱Fear            ││
│  │      Sadness            ││
│  └─────────────────────────┘│
│                             │
│  Current Mode: 🎯 Explore   │
│  Confidence: 78%             │
│                             │
│  ┌─────────────────────────┐│
│  │ Tuần này:               ││
│  │ ████████████████████    ││  ← Emotion timeline
│  │ Mon Tue Wed Thu Fri Sat ││
│  │ 😊  😌  😊  🎯  😊  😌 ││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ 💡 AI Insight:          ││
│  │ "Bạn thường vui nhất    ││
│  │  vào buổi sáng cuối     ││
│  │  tuần 🌅"               ││
│  └─────────────────────────┘│
│                             │
├─────────────────────────────┤
│ 🏠  🔮  [+]  💬  👤       │
└─────────────────────────────┘
```

---

## 3. Aura Ring – Chi Tiết Component

```
Aura Ring là gradient glow quanh avatar, biểu diễn cảm xúc:

  ┌─────────────────────────────┐
  │                             │
  │   Dominant: Joy (amber)     │
  │   ┌─────────────┐          │
  │   │   ╭───╮     │          │
  │   │  ╱ 🟡✨ ╲    │  ← Amber glow (joy dominant)
  │   │ │ Avatar │   │
  │   │  ╲     ╱    │  ← Gradient: amber → orange
  │   │   ╰───╯     │
  │   └─────────────┘          │
  │                             │
  │   Dominant: Sadness (blue)  │
  │   ┌─────────────┐          │
  │   │   ╭───╮     │          │
  │   │  ╱ 🔵✨ ╲    │  ← Blue glow (sadness dominant)
  │   │ │ Avatar │   │
  │   │  ╲     ╱    │  ← Gradient: blue → indigo
  │   │   ╰───╯     │
  │   └─────────────┘          │
  │                             │
  │   Mixed emotions:           │
  │   ┌─────────────┐          │
  │   │   ╭───╮     │          │
  │   │  ╱ 🌈✨ ╲    │  ← Multi-color gradient
  │   │ │ Avatar │   │     (top 3 emotions blend)
  │   │  ╲     ╱    │
  │   │   ╰───╯     │
  │   └─────────────┘          │
  └─────────────────────────────┘

Animation:
- Idle: Subtle pulse (1.5s cycle)
- Update: Smooth color transition (0.8s ease)
- Ring width: 3px (small), 4px (medium), 6px (large)
- Glow blur: 8px (small), 12px (large)
```

---

## 4. Reference Images

### Main Screens (Login, Feed, Soul Connect, Chat, Profile)
![Main Screens Mockup](./01-main-screens.png)

### Secondary Screens (Waves, Create Post, Compass, Settings)
![Secondary Screens Mockup](./02-secondary-screens.png)
