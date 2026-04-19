# AURA v3.0 – Frontend Flutter Chi Tiết

> **Tài liệu:** 05/07 – Frontend Design  
> **Phiên bản:** 3.0 (Behavioral AI Edition)

---

## 1. Tổng Quan Frontend Architecture

### Design Philosophy v3.0
- **Ambient & Alive**: UI phản ánh cảm xúc real-time thông qua Aura Ring, dynamic gradients
- **Discover-First**: For You feed là trung tâm, không phải Following
- **Emotion-Aware UI**: Màu sắc, typography, animations thay đổi subtle theo emotional mode
- **Privacy-Transparent**: Luôn hiển thị khi AI đang hoạt động

### State Management: Riverpod

```dart
// Core providers architecture
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = StreamProvider.family<UserProfile, String>((ref, uid) {
  return FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
      .map((doc) => UserProfile.fromFirestore(doc));
});

final emotionProfileProvider = StreamProvider.family<EmotionProfile, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users').doc(uid)
      .collection('emotion_profile').doc('current')
      .snapshots()
      .map((doc) => EmotionProfile.fromFirestore(doc));
});

final forYouFeedProvider = FutureProvider.autoDispose<FeedResult>((ref) async {
  final service = ref.read(feedServiceProvider);
  return service.getForYouFeed();
});

final soulSuggestionsProvider = FutureProvider.autoDispose<List<SoulSuggestion>>((ref) async {
  final service = ref.read(soulConnectServiceProvider);
  return service.getSuggestions();
});

final activeWavesProvider = StreamProvider<List<Wave>>((ref) {
  return FirebaseFirestore.instance
      .collection('waves')
      .where('status', isEqualTo: 'active')
      .orderBy('momentum', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Wave.fromFirestore(d)).toList());
});

// === API Services (FastAPI backend) ===
final apiServiceProvider = Provider<AuraApiService>((ref) {
  return AuraApiService();  // HTTP client → FastAPI
});

final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService(ref.read(apiServiceProvider));
});

final soulConnectServiceProvider = Provider<SoulConnectService>((ref) {
  return SoulConnectService(ref.read(apiServiceProvider));
});

final behavioralTrackerProvider = Provider<BehavioralTracker>((ref) {
  return BehavioralTracker(ref.read(apiServiceProvider));
});
```

---

## 2. Design System

### 2.1 Color System

```dart
class AuraColors {
  // === Brand Colors ===
  static const primary = Color(0xFF8B5CF6);      // Violet
  static const primaryLight = Color(0xFFA78BFA);
  static const primaryDark = Color(0xFF6D28D9);
  
  static const secondary = Color(0xFF06B6D4);     // Cyan
  static const secondaryLight = Color(0xFF22D3EE);
  
  static const accent = Color(0xFFF472B6);         // Pink
  
  // === Background (Dark Mode First) ===
  static const bgPrimary = Color(0xFF0F0F1A);      // Deep navy
  static const bgSecondary = Color(0xFF1A1A2E);     // Card background
  static const bgTertiary = Color(0xFF16213E);      // Elevated surfaces
  static const bgGlass = Color(0x1AFFFFFF);          // Glassmorphism
  
  // === Text ===
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF475569);
  
  // === Emotion Colors (Plutchik Wheel) ===
  static const emotionJoy = Color(0xFFFBBF24);        // Gold
  static const emotionTrust = Color(0xFF34D399);        // Emerald
  static const emotionAnticipation = Color(0xFFFB923C); // Orange
  static const emotionSurprise = Color(0xFF60A5FA);     // Blue
  static const emotionSadness = Color(0xFF818CF8);       // Indigo
  static const emotionFear = Color(0xFF9333EA);          // Purple
  static const emotionAnger = Color(0xFFEF4444);         // Red
  static const emotionDisgust = Color(0xFF65A30D);       // Lime
  
  // === Semantic ===
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  
  /// Map emotion name → color
  static Color getEmotionColor(String emotion) {
    return {
      'joy': emotionJoy, 'trust': emotionTrust,
      'anticipation': emotionAnticipation, 'surprise': emotionSurprise,
      'sadness': emotionSadness, 'fear': emotionFear,
      'anger': emotionAnger, 'disgust': emotionDisgust,
    }[emotion] ?? primary;
  }
  
  /// Generate gradient from emotion vector
  static List<Color> emotionGradient(Map<String, double> emotionVector) {
    final sorted = emotionVector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3);
    return top3.map((e) => getEmotionColor(e.key).withOpacity(
      0.4 + e.value * 0.6,
    )).toList();
  }
}
```

### 2.2 Typography

```dart
class AuraTypography {
  static const fontFamily = 'Inter';
  
  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28, fontWeight: FontWeight.w800,
    color: AuraColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AuraColors.textPrimary,
  );
  
  static const h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AuraColors.textPrimary,
  );
  
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AuraColors.textPrimary,
    height: 1.5,
  );
  
  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AuraColors.textSecondary,
    height: 1.5,
  );
  
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AuraColors.textMuted,
  );
  
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AuraColors.textMuted,
    letterSpacing: 0.5,
  );
  
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
```

### 2.3 Theme

```dart
ThemeData auraTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AuraColors.bgPrimary,
    
    colorScheme: const ColorScheme.dark(
      primary: AuraColors.primary,
      secondary: AuraColors.secondary,
      surface: AuraColors.bgSecondary,
      error: AuraColors.error,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AuraTypography.h3,
    ),
    
    cardTheme: CardTheme(
      color: AuraColors.bgSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AuraColors.bgPrimary,
      selectedItemColor: AuraColors.primary,
      unselectedItemColor: AuraColors.textMuted,
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AuraColors.bgTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AuraColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AuraTypography.button,
      ),
    ),
  );
}
```

---

## 3. Core UI Components

### 3.1 Aura Ring (Vòng Hào Quang Cảm Xúc)

```dart
class AuraRing extends StatelessWidget {
  final Map<String, double> emotionVector;
  final double size;
  final Widget child; // Usually CircleAvatar
  final double confidence;
  final double arousal;
  
  const AuraRing({
    super.key,
    required this.emotionVector,
    required this.child,
    this.size = 56,
    this.confidence = 0.5,
    this.arousal = 0.5,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = AuraColors.emotionGradient(emotionVector);
    final ringWidth = 2.0 + (confidence * 3.0); // 2-5px based on confidence
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      width: size + ringWidth * 2,
      height: size + ringWidth * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [...colors, colors.first], // Loop gradient
          startAngle: 0,
          endAngle: 2 * pi,
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(ringWidth),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AuraColors.bgPrimary,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(child: SizedBox(width: size, height: size, child: child)),
      ),
    );
  }
}
```

### 3.2 Emotion Reaction Wheel

```dart
class EmotionReactionWheel extends StatelessWidget {
  final Function(String emotion) onReaction;
  
  const EmotionReactionWheel({super.key, required this.onReaction});
  
  static const _reactions = [
    {'emotion': 'joy', 'emoji': '😊', 'label': 'Joy'},
    {'emotion': 'trust', 'emoji': '🤗', 'label': 'Trust'},
    {'emotion': 'anticipation', 'emoji': '🤩', 'label': 'Hype'},
    {'emotion': 'surprise', 'emoji': '😮', 'label': 'Wow'},
    {'emotion': 'sadness', 'emoji': '😢', 'label': 'Sad'},
    {'emotion': 'fear', 'emoji': '😰', 'label': 'Anxious'},
    {'emotion': 'anger', 'emoji': '😤', 'label': 'Angry'},
    {'emotion': 'disgust', 'emoji': '😒', 'label': 'Meh'},
  ];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraColors.bgSecondary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _reactions.map((r) => GestureDetector(
          onTap: () => onReaction(r['emotion'] as String),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r['emoji'] as String, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 2),
                Text(r['label'] as String, style: AuraTypography.caption),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}
```

### 3.3 Glassmorphism Card

```dart
class AuraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final List<Color>? borderGradient;
  
  const AuraCard({
    super.key,
    required this.child,
    this.padding,
    this.borderGradient,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: borderGradient != null
            ? LinearGradient(colors: borderGradient!)
            : null,
      ),
      padding: borderGradient != null ? const EdgeInsets.all(1) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuraColors.bgGlass,
              borderRadius: BorderRadius.circular(15),
              border: borderGradient == null
                  ? Border.all(color: Colors.white.withOpacity(0.1))
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

### 3.4 Wave Momentum Indicator

```dart
class WaveMomentumIndicator extends StatelessWidget {
  final double momentum; // 0.0 - 1.0
  final String emoji;
  
  const WaveMomentumIndicator({
    super.key,
    required this.momentum,
    required this.emoji,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = momentum > 0.6
        ? AuraColors.success
        : momentum > 0.3
            ? AuraColors.warning
            : AuraColors.error;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        SizedBox(
          width: 40, height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: momentum,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
```

### 3.5 Wellbeing Break Card

```dart
class WellbeingBreakCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String variant; // 'positive_inject' | 'session_break'
  final VoidCallback? onDismiss;
  
  const WellbeingBreakCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.variant,
    this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: variant == 'session_break'
              ? [const Color(0xFF1E3A5F), const Color(0xFF0D1B2A)]
              : [const Color(0xFF1A2F1A), const Color(0xFF0D1B0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: variant == 'session_break'
              ? AuraColors.secondary.withOpacity(0.3)
              : AuraColors.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AuraTypography.h3),
          const SizedBox(height: 8),
          Text(subtitle, style: AuraTypography.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              if (variant == 'session_break') ...[
                ElevatedButton(
                  onPressed: () { /* Navigate to Emotional Compass */ },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraColors.secondary.withOpacity(0.2),
                  ),
                  child: const Text('Xem Aura của tôi'),
                ),
                const SizedBox(width: 12),
              ],
              TextButton(
                onPressed: onDismiss,
                child: Text('Tiếp tục', 
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.textMuted,
                  )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 4. Screen Designs

### 4.1 Navigation Structure

```
BottomNavigationBar (5 tabs):
├── 🏠 Home (For You + Following feeds)
├── 🌊 Waves (Emotional Waves discovery)
├── ➕ Create (New post)
├── 💜 Connect (Soul Connect)
└── 👤 Profile (Emotional Compass, Settings)
```

### 4.2 Home Screen (For You Feed)

```
┌──────────────────────────────────────┐
│ ┌──────────────────────────────────┐ │
│ │ [AURA Logo]         [🔍] [🔔]  │ │  ← AppBar
│ └──────────────────────────────────┘ │
│                                      │
│  ┌──────────┐  ┌──────────┐         │
│  │ For You  │  │ Following│         │  ← Tab selector
│  │ ════════ │  │          │         │
│  └──────────┘  └──────────┘         │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 🤖 Đang hiểu bạn...  explore│   │  ← AI Status Bar (emotional mode)
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ ┌──────┐                     │   │
│  │ │AuraR.│ display_name   2m   │   │  ← Post Card
│  │ └──────┘                     │   │
│  │                              │   │
│  │ "Hôm nay mình cảm thấy rất  │   │
│  │  tốt sau khi chạy bộ..."    │   │
│  │                              │   │
│  │ [📷 Image]                   │   │
│  │                              │   │
│  │ 😊15 🤗5 🤩2  💬8   ↗3  📌5│   │  ← Emotion reactions
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ ✨ Góc tươi sáng             │   │  ← Wellbeing break card
│  │ Đây là lúc tốt để nhìn vào  │   │     (injected by Wellbeing Guard)
│  │ điều tích cực...             │   │
│  │    [Xem Aura] [Tiếp tục]    │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ Post Card 2...               │   │
│  └──────────────────────────────┘   │
│                                      │
│ ┌────┬────┬────┬────┬────┐          │
│ │ 🏠 │ 🌊 │ ➕ │ 💜 │ 👤 │          │  ← Bottom Nav
│ └────┴────┴────┴────┴────┘          │
└──────────────────────────────────────┘
```

### 4.3 Waves Discover Screen

```
┌──────────────────────────────────────┐
│ ┌──────────────────────────────────┐ │
│ │ Emotional Waves      [Info ℹ️]  │ │
│ └──────────────────────────────────┘ │
│                                      │
│  "28 người đang cùng vibe với bạn"   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 🌊 Đêm Không Ngủ            │   │
│  │ 32 người • ████████░░ 0.85  │   │  ← Momentum bar
│  │ "Dành cho những ai đang      │   │
│  │  thức khuya..."              │   │
│  │  ┌──┐┌──┐┌──┐┌──┐ +28      │   │  ← Stacked avatars with Aura Rings
│  │  └──┘└──┘└──┘└──┘           │   │
│  │       [Tham gia 🌊]          │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 🔥 Deadline Warriors         │   │
│  │ 45 người • ██████████ 0.95  │   │
│  │ ...                          │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 🌈 Friday Vibes              │   │
│  │ 28 người • ██████░░░░ 0.60  │   │
│  │ ...                          │   │
│  └──────────────────────────────┘   │
│                                      │
│ ┌────┬────┬────┬────┬────┐          │
│ │ 🏠 │ 🌊 │ ➕ │ 💜 │ 👤 │          │
│ └────┴────┴────┴────┴────┘          │
└──────────────────────────────────────┘
```

### 4.4 Soul Connect Screen

```
┌──────────────────────────────────────┐
│ ┌──────────────────────────────────┐ │
│ │ Soul Connect 💜                 │ │
│ └──────────────────────────────────┘ │
│                                      │
│  ┌──────────────────────────────┐   │
│  │                              │   │
│  │     ┌──────────────┐         │   │
│  │     │              │         │   │
│  │     │  ┌────────┐  │         │   │
│  │     │  │ Avatar │  │         │   │  ← Large Aura Ring
│  │     │  │  with  │  │         │   │
│  │     │  │ AuraR. │  │         │   │
│  │     │  └────────┘  │         │   │
│  │     │              │         │   │
│  │     └──────────────┘         │   │
│  │                              │   │
│  │     Minh Anh, 23             │   │
│  │     "Just vibing ✨"          │   │
│  │                              │   │
│  │  ┌──────────────────────┐    │   │
│  │  │ 💜 Kindred Spirit    │    │   │  ← Connection type badge
│  │  │ Soul Score: 85%      │    │   │
│  │  └──────────────────────┘    │   │
│  │                              │   │
│  │  ┌──────────────────────┐    │   │
│  │  │ Compatibility:       │    │   │
│  │  │ Emotion  ████████░░  │    │   │  ← Breakdown chart
│  │  │ Taste    ████████░░  │    │   │
│  │  │ Support  █████████░  │    │   │
│  │  │ Interest ███████░░░  │    │   │
│  │  │ Activity ████████░░  │    │   │
│  │  └──────────────────────┘    │   │
│  │                              │   │
│  │  [❌ Skip]    [💜 Connect]   │   │
│  │                              │   │
│  └──────────────────────────────┘   │
│                                      │
│ ┌────┬────┬────┬────┬────┐          │
│ │ 🏠 │ 🌊 │ ➕ │ 💜 │ 👤 │          │
│ └────┴────┴────┴────┴────┘          │
└──────────────────────────────────────┘
```

### 4.5 Profile + Emotional Compass Screen

```
┌──────────────────────────────────────┐
│ ┌──────────────────────────────────┐ │
│ │ [←]   My Profile     [⚙️]      │ │
│ └──────────────────────────────────┘ │
│                                      │
│        ┌────────────┐                │
│        │  Avatar    │                │  ← Large Aura Ring
│        │  AuraRing  │                │
│        └────────────┘                │
│        Minh Anh                      │
│        @minhanh_                     │
│        "Just vibing through life ✨" │
│                                      │
│  ──────── Stats ──────────           │
│  42 followers  58 following  15 posts│
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 🧭 Emotional Compass         │   │
│  │                              │   │
│  │     Joy ────┐                │   │
│  │   Disgust   │  Trust         │   │  ← 8-axis radar chart
│  │       \     │  /             │   │
│  │  Anger──────●──────Anticip.  │   │
│  │       /     │  \             │   │
│  │    Fear     │  Surprise      │   │
│  │     Sadness─┘                │   │
│  │                              │   │
│  │  Mood: explore 🔍            │   │
│  │  Valence: +0.65 (positive)   │   │
│  │  Confidence: 78%             │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 📈 Emotional Journey (7 days)│   │
│  │                              │   │
│  │  ┌─ valence over time ─────┐ │   │  ← Weekly trend chart
│  │  │      ╱╲    ╱╲           │ │   │
│  │  │ ────╱──╲──╱──╲────────  │ │   │
│  │  │    ╱    ╲╱    ╲         │ │   │
│  │  │  M  T  W  T  F  S  S   │ │   │
│  │  └─────────────────────────┘ │   │
│  │                              │   │
│  │ 💡 AI Insight:               │   │
│  │ "Bạn thường vui vào cuối    │   │
│  │  tuần và stressed vào T3-T4" │   │
│  │                              │   │
│  │ Wellbeing Score: 72/100 🌟   │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ My Posts                      │   │
│  │ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐   │   │  ← Grid of user's posts
│  │ └──┘ └──┘ └──┘ └──┘ └──┘   │   │
│  └──────────────────────────────┘   │
│                                      │
│ ┌────┬────┬────┬────┬────┐          │
│ │ 🏠 │ 🌊 │ ➕ │ 💜 │ 👤 │          │
│ └────┴────┴────┴────┴────┘          │
└──────────────────────────────────────┘
```

### 4.6 Chat Screen

```
┌──────────────────────────────────────┐
│ ┌──────────────────────────────────┐ │
│ │ [←] ┌──┐ Minh Anh   Online 🟢 │ │  ← Aura Ring avatar
│ │     └──┘ Kindred Spirit 💜     │ │
│ └──────────────────────────────────┘ │
│                                      │
│                                      │
│  ┌──────────────────┐               │
│  │ 💜 Soul Connect!  │               │  ← System message
│  │ Các bạn là        │               │
│  │ Kindred Spirit    │               │
│  └──────────────────┘               │
│                                      │
│             ┌──────────────────────┐ │
│             │ Hey! Nice to meet    │ │  ← Outgoing message
│             │ you 😊               │ │
│             └──────────────────────┘ │
│                                      │
│  ┌──────────────────────┐           │
│  │ Hi! Mình cũng vui    │           │  ← Incoming message
│  │ khi được connect!     │           │
│  └──────────────────────┘           │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 💡 AI gợi ý:                 │   │  ← AI Prompt Assistant
│  │ "Hỏi xem họ đang nghe       │   │
│  │  nhạc gì thế! 🎧"           │   │
│  └──────────────────────────────┘   │
│                                      │
│  ✍️ Minh Anh đang nhập...          │  ← Typing indicator
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ [😊] Nhập tin nhắn...    [➤]   │ │  ← Chat input
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

## 5. Routing (GoRouter)

```dart
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    
    if (user == null && !isAuthRoute) return '/auth/login';
    if (user != null && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    
    // Auth routes
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/auth/onboarding', builder: (_, __) => const OnboardingScreen()),
    
    // Main app (with bottom navigation)
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const ForYouFeedScreen(),
        ),
        GoRoute(
          path: '/waves',
          builder: (_, __) => const WavesDiscoverScreen(),
        ),
        GoRoute(
          path: '/create',
          builder: (_, __) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/connect',
          builder: (_, __) => const SoulConnectScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
        ),
      ],
    ),
    
    // Detail routes
    GoRoute(
      path: '/wave/:waveId',
      builder: (_, state) => WaveChatScreen(waveId: state.pathParameters['waveId']!),
    ),
    GoRoute(
      path: '/chat/:conversationId',
      builder: (_, state) => ChatScreen(conversationId: state.pathParameters['conversationId']!),
    ),
    GoRoute(
      path: '/user/:userId',
      builder: (_, state) => UserProfileScreen(userId: state.pathParameters['userId']!),
    ),
    GoRoute(
      path: '/compass',
      builder: (_, __) => const EmotionalCompassScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/ai',
      builder: (_, __) => const AISettingsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),
  ],
);
```

---

## 6. Animation & Micro-interactions

### 6.1 Aura Ring Transitions
- **Emotion change**: 800ms ease-in-out gradient color transition
- **Online→Offline**: 300ms opacity fade
- **Confidence change**: Ring width animates smoothly

### 6.2 Feed Interactions
- **Pull to refresh**: Lottie animation (aura ripple)
- **Like/Reaction**: Emoji scales up 1.2x → bounces → returns (200ms)
- **Post appear**: Slide up + fade in (300ms stagger 50ms)
- **Break card appear**: Slow fade in over 500ms (non-jarring)

### 6.3 Wave Interactions
- **Join wave**: Ripple effect from tap point
- **Momentum bar**: Smooth animated fill (300ms)
- **Wave card**: Subtle breathing glow animation on active waves

### 6.4 Soul Connect
- **Card reveal**: 3D flip animation (400ms)
- **Score reveal**: Count-up animation for soul score (800ms)
- **Connect success**: Dual Aura Rings merge animation + confetti burst

### 6.5 Navigation
- **Tab switch**: Cross-fade (200ms)
- **Push screen**: Slide from right (300ms) with MaterialPageRoute
- **Modal sheet**: Slide from bottom with drag-to-dismiss

---

## 7. Performance Optimization

| Strategy | Implementation |
|---|---|
| **Feed pagination** | Load 20 posts per page, infinite scroll |
| **Image optimization** | Compress client-side (max 500KB), CDN via Firebase Storage |
| **Lazy loading** | Images load on scroll with `cached_network_image` |
| **Behavioral batching** | Events buffered 30s before network write |
| **Firestore cache** | `getDocFromCache()` for frequently accessed data |
| **Feed cache** | Pre-computed feed served from `feed_cache` subcollection |
| **Widget rebuild** | `const` constructors, `.select()` on Riverpod providers |
| **List rendering** | `ListView.builder` with `itemExtent` for fixed-height items |

---

> **Tài liệu tiếp theo:** [06-BAO-MAT-QUYEN-RIENG-TU.md](./06-BAO-MAT-QUYEN-RIENG-TU.md)
