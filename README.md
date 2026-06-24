# OFG Connects

A production-grade Christian media streaming app (Flutter + Python backend + Cloudflare R2).

---

## Project Structure

```
ofg/
├── backend/
│   ├── server.py          ← Full production API (37 endpoints)
│   ├── requirements.txt   ← Python dependencies
│   ├── .env               ← Credentials (gitignored)
│   ├── .gitignore
│   └── start.bat          ← Dev launcher (auto-creates venv)
├── ofg_mobile/
│   ├── lib/               ← Flutter source code
│   │   ├── api/           ← ApiClient + OfgStorage
│   │   ├── logic/         ← Riverpod providers
│   │   ├── models/        ← Data models
│   │   └── presentation/  ← Pages + Widgets + Theme
│   ├── android/           ← Android build config
│   └── pubspec.yaml
├── README.md
└── .gitignore
```

---

## Backend Setup

### Local Development

```bat
cd backend
start.bat
```

Server runs on `http://0.0.0.0:8787`

| Target | URL |
|---|---|
| Browser | http://127.0.0.1:8787 |
| Android Emulator | http://10.0.2.2:8787 |
| Real Device | http://YOUR_LAN_IP:8787 |

### Demo Accounts

| Email | Password | Role |
|---|---|---|
| demo@ofg.local | password123 | User |
| admin@ofgconnects.com | Admin@OFG2024! | Admin |

### Environment Variables (backend/.env)

```env
R2_ENDPOINT=https://xxxx.r2.cloudflarestorage.com
R2_ACCESS_KEY_ID=your_key_id
R2_SECRET_ACCESS_KEY=your_secret_key
R2_BUCKET_NAME=ofg-connects-storage
R2_PUBLIC_URL=https://pub-xxx.r2.dev
OFG_HOST=0.0.0.0
OFG_PORT=8787
ADMIN_SECRET=ofg_admin_2024
```

---

## Flutter App Build

### Development

```bash
cd ofg_mobile
flutter pub get
flutter run
```

### Production APK

```bash
flutter build apk --release
```

### Play Store AAB

```bash
flutter build appbundle --release
```

### Play Store Signing Setup

1. Generate keystore (run once, keep forever):
   ```bash
   keytool -genkey -v -keystore android/ofg_connects_release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ofg_connects
   ```

2. Copy `android/key.properties.template` → `android/key.properties`

3. Fill in your keystore passwords in `android/key.properties`

4. Build: `flutter build appbundle --release`

---

## API Overview

The backend runs 37 endpoints covering:

- **Auth**: Register, Login, Logout, Me
- **Feed**: Personalized (YouTube-style engagement_rate algorithm), Shorts, Search
- **Videos**: CRUD, Like, Save, Watch tracking
- **Comments**: List + Post
- **Social**: Follow/Unfollow, User profiles
- **Creator**: Stats dashboard, Video management, Upload (Cloudflare R2)
- **Library**: Watch history, Saved videos
- **Notifications**: Real-time + Read-all
- **Reports**: Video/User reporting
- **Admin**: Feature/Remove videos, Ban users, Resolve reports

---

## Personalization Algorithm

Score = `engagement_rate × 40` + `recency_bonus` + `category_affinity` + `follow_boost` + `featured_boost` − `watch_penalty`

- `engagement_rate = (likes + comments×2 + shares×3) / max(views, 1)` — gives small creators a fair chance
- New videos (< 24h): +20 recency bonus
- Videos from followed creators: +15 boost
- Featured videos: +100 (admin-set)
- Already-watched videos: −5 penalty (encourages discovery)

---

## Play Store Checklist

- [x] Application ID: `com.ofgconnects.app`
- [x] Version: 1.0.0 (versionCode 1)
- [x] minSdk: 21 (Android 5.0+, ~99% coverage)
- [x] targetSdk: 34
- [x] R8 minification enabled
- [x] All permissions declared
- [x] Release signing configured
- [ ] Generate keystore → fill key.properties
- [ ] Upload AAB to Play Console
