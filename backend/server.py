"""
OFG Connects - Christian Media Streaming Backend
Python 3.11+ stdlib HTTP server with SQLite + Cloudflare R2
"""

from __future__ import annotations

import hashlib
import hmac
import json
import os
import re
import secrets
import sqlite3
import urllib.parse
import urllib.request
import hmac
import base64
import datetime
from datetime import datetime, timezone, timedelta
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Optional
import boto3
from botocore.config import Config
# ---------------------------------------------------------------------------
# .env loader (stdlib only)
# ---------------------------------------------------------------------------

def _load_env(path: str = ".env") -> None:
    env_path = Path(path)
    if not env_path.exists():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip().strip('"').strip("'")
        os.environ.setdefault(key, val)


_load_env()

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

R2_ENDPOINT          = os.environ.get("R2_ENDPOINT", "")
R2_ACCESS_KEY_ID     = os.environ.get("R2_ACCESS_KEY_ID", "")
R2_SECRET_ACCESS_KEY = os.environ.get("R2_SECRET_ACCESS_KEY", "")
# Main video bucket
R2_BUCKET_NAME       = os.environ.get("R2_BUCKET_NAME", "ofg-connects-storage")
R2_PUBLIC_URL        = os.environ.get("R2_PUBLIC_URL", "")
# Thumbnails bucket
R2_THUMBNAILS_BUCKET     = os.environ.get("R2_THUMBNAILS_BUCKET", "ofg-thumbnails")
R2_THUMBNAILS_PUBLIC_URL = os.environ.get("R2_THUMBNAILS_PUBLIC_URL", "")
# Shorts bucket
R2_SHORTS_BUCKET         = os.environ.get("R2_SHORTS_BUCKET", "ofg-shorts")
R2_SHORTS_PUBLIC_URL     = os.environ.get("R2_SHORTS_PUBLIC_URL", "")

OFG_HOST           = os.environ.get("OFG_HOST", "0.0.0.0")
OFG_PORT           = int(os.environ.get("PORT", os.environ.get("OFG_PORT", "8787")))
ADMIN_SECRET       = os.environ.get("ADMIN_SECRET", "ofg_admin_2024")
DB_PATH            = os.environ.get("DB_PATH", "ofg_connects.db")

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

DDL = """
PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    handle TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    salt TEXT NOT NULL,
    bio TEXT DEFAULT '',
    avatar_url TEXT DEFAULT '',
    subscription TEXT DEFAULT 'Free',
    is_verified INTEGER DEFAULT 0,
    is_admin INTEGER DEFAULT 0,
    is_banned INTEGER DEFAULT 0,
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
    token TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS videos (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    creator_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    creator_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'sermons',
    duration TEXT DEFAULT '0:00',
    views INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    watch_time_total REAL DEFAULT 0,
    thumbnail_url TEXT DEFAULT '',
    media_url TEXT DEFAULT '',
    is_live INTEGER DEFAULT 0,
    is_short INTEGER DEFAULT 0,
    is_featured INTEGER DEFAULT 0,
    is_removed INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    impressions INTEGER DEFAULT 0,
    avg_completion_rate REAL DEFAULT 0,
    recent_views INTEGER DEFAULT 0,
    recent_views_updated TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS likes (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    PRIMARY KEY(user_id, video_id)
);

CREATE TABLE IF NOT EXISTS saves (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    PRIMARY KEY(user_id, video_id)
);

CREATE TABLE IF NOT EXISTS follows (
    follower_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    creator_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    PRIMARY KEY(follower_id, creator_id)
);

CREATE TABLE IF NOT EXISTS history (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    progress REAL DEFAULT 0,
    watch_time REAL DEFAULT 0,
    completion_rate REAL DEFAULT 0,
    viewed_at TEXT NOT NULL,
    PRIMARY KEY(user_id, video_id)
);

CREATE TABLE IF NOT EXISTS comments (
    id TEXT PRIMARY KEY,
    video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_handle TEXT NOT NULL,
    content TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    from_user_id TEXT,
    from_user_name TEXT,
    video_id TEXT,
    message TEXT NOT NULL,
    is_read INTEGER DEFAULT 0,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS reports (
    id TEXT PRIMARY KEY,
    reporter_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS settings (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY(user_id, key)
);

CREATE TABLE IF NOT EXISTS video_skips (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    skip_rate REAL DEFAULT 1.0,
    skipped_at TEXT NOT NULL,
    PRIMARY KEY(user_id, video_id)
);

CREATE INDEX IF NOT EXISTS idx_videos_creator ON videos(creator_id);
CREATE INDEX IF NOT EXISTS idx_videos_category ON videos(category);
CREATE INDEX IF NOT EXISTS idx_history_user ON history(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_video ON comments(video_id);
CREATE INDEX IF NOT EXISTS idx_video_skips_user ON video_skips(user_id);

CREATE TABLE IF NOT EXISTS creator_wallets (
    creator_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    wallet_balance REAL DEFAULT 0,
    lifetime_donations REAL DEFAULT 0,
    lifetime_platform_fees REAL DEFAULT 0,
    total_supporters INTEGER DEFAULT 0,
    monthly_earnings REAL DEFAULT 0,
    pending_payout REAL DEFAULT 0,
    last_payout_date TEXT DEFAULT '',
    payout_account TEXT DEFAULT '',
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS donations (
    id TEXT PRIMARY KEY,
    donor_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    creator_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount REAL NOT NULL,
    platform_fee REAL NOT NULL,
    creator_amount REAL NOT NULL,
    message TEXT DEFAULT '',
    is_anonymous INTEGER DEFAULT 0,
    status TEXT DEFAULT 'completed',
    transaction_id TEXT DEFAULT '',
    payment_method TEXT DEFAULT 'simulated',
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS payouts (
    id TEXT PRIMARY KEY,
    creator_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount REAL NOT NULL,
    status TEXT DEFAULT 'pending',
    requested_at TEXT NOT NULL,
    approved_at TEXT DEFAULT '',
    paid_at TEXT DEFAULT '',
    rejection_reason TEXT DEFAULT '',
    admin_note TEXT DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_donations_creator ON donations(creator_id);
CREATE INDEX IF NOT EXISTS idx_donations_donor ON donations(donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_created ON donations(created_at);
CREATE INDEX IF NOT EXISTS idx_payouts_creator ON payouts(creator_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status);
"""


def get_db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys=ON")
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def init_db() -> None:
    conn = get_db()
    try:
        for stmt in DDL.split(";"):
            stmt = stmt.strip()
            if stmt:
                try:
                    conn.execute(stmt)
                except sqlite3.OperationalError:
                    pass
        conn.commit()
        _migrate_db(conn)
        _seed_users(conn)
    finally:
        conn.close()


def _migrate_db(conn: sqlite3.Connection) -> None:
    """Safely add new algorithm columns to existing databases."""
    migrations = [
        "ALTER TABLE videos ADD COLUMN impressions INTEGER DEFAULT 0",
        "ALTER TABLE videos ADD COLUMN avg_completion_rate REAL DEFAULT 0",
        "ALTER TABLE videos ADD COLUMN recent_views INTEGER DEFAULT 0",
        "ALTER TABLE videos ADD COLUMN recent_views_updated TEXT DEFAULT ''",
        """CREATE TABLE IF NOT EXISTS video_skips (
            user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
            skip_rate REAL DEFAULT 1.0,
            skipped_at TEXT NOT NULL,
            PRIMARY KEY(user_id, video_id)
        )""",
        "CREATE INDEX IF NOT EXISTS idx_video_skips_user ON video_skips(user_id)",
        # Donation system tables
        """CREATE TABLE IF NOT EXISTS creator_wallets (
            creator_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
            wallet_balance REAL DEFAULT 0,
            lifetime_donations REAL DEFAULT 0,
            lifetime_platform_fees REAL DEFAULT 0,
            total_supporters INTEGER DEFAULT 0,
            monthly_earnings REAL DEFAULT 0,
            pending_payout REAL DEFAULT 0,
            last_payout_date TEXT DEFAULT '',
            payout_account TEXT DEFAULT '',
            updated_at TEXT NOT NULL
        )""",
        """CREATE TABLE IF NOT EXISTS donations (
            id TEXT PRIMARY KEY,
            donor_id TEXT REFERENCES users(id) ON DELETE SET NULL,
            creator_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            amount REAL NOT NULL,
            platform_fee REAL NOT NULL,
            creator_amount REAL NOT NULL,
            message TEXT DEFAULT '',
            is_anonymous INTEGER DEFAULT 0,
            status TEXT DEFAULT 'completed',
            transaction_id TEXT DEFAULT '',
            payment_method TEXT DEFAULT 'simulated',
            created_at TEXT NOT NULL
        )""",
        """CREATE TABLE IF NOT EXISTS payouts (
            id TEXT PRIMARY KEY,
            creator_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            amount REAL NOT NULL,
            status TEXT DEFAULT 'pending',
            requested_at TEXT NOT NULL,
            approved_at TEXT DEFAULT '',
            paid_at TEXT DEFAULT '',
            rejection_reason TEXT DEFAULT '',
            admin_note TEXT DEFAULT ''
        )""",
        "CREATE INDEX IF NOT EXISTS idx_donations_creator ON donations(creator_id)",
        "CREATE INDEX IF NOT EXISTS idx_donations_donor ON donations(donor_id)",
        "CREATE INDEX IF NOT EXISTS idx_payouts_creator ON payouts(creator_id)",
        "CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status)",
    ]
    for m in migrations:
        try:
            conn.execute(m)
        except sqlite3.OperationalError:
            pass  # Column/table already exists — safe to ignore
    conn.commit()



def _seed_users(conn: sqlite3.Connection) -> None:
    count = conn.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    if count > 0:
        return

    now = utcnow()

    # Admin user
    admin_id = new_id()
    admin_salt = secrets.token_hex(16)
    admin_hash = hash_password("Admin@OFG2024!", admin_salt)
    conn.execute(
        """INSERT INTO users (id, name, email, handle, password_hash, salt,
           bio, avatar_url, subscription, is_verified, is_admin, is_banned,
           follower_count, following_count, created_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
        (
            admin_id, "OFG Admin", "admin@ofgconnects.com", "@ofgadmin",
            admin_hash, admin_salt,
            "Official OFG Connects administrator account.", "",
            "Premium", 1, 1, 0, 0, 0, now,
        ),
    )

    # Demo Pastor
    demo_id = new_id()
    demo_salt = secrets.token_hex(16)
    demo_hash = hash_password("password123", demo_salt)
    conn.execute(
        """INSERT INTO users (id, name, email, handle, password_hash, salt,
           bio, avatar_url, subscription, is_verified, is_admin, is_banned,
           follower_count, following_count, created_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
        (
            demo_id, "Demo Pastor", "demo@ofg.local", "@demopastor",
            demo_hash, demo_salt,
            "Demo pastor account for testing.", "",
            "Free", 1, 0, 0, 0, 0, now,
        ),
    )

    conn.commit()
    print(f"[OFG] Seeded admin ({admin_id}) and demo ({demo_id}) users.")


# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------

def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def new_id() -> str:
    return secrets.token_urlsafe(16)


def gen_token() -> str:
    return secrets.token_urlsafe(32)


def make_handle(name: str) -> str:
    base = re.sub(r"[^a-z0-9]", "", name.lower().replace(" ", ""))[:15]
    suffix = secrets.token_hex(3)
    return f"@{base}{suffix}"


def hash_password(password: str, salt: str) -> str:
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 260_000)
    return dk.hex()


def verify_password(password: str, salt: str, stored_hash: str) -> bool:
    return hmac.compare_digest(hash_password(password, salt), stored_hash)


def validate_email(email: str) -> bool:
    return bool(re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email))


def format_views(n: int) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)


# ---------------------------------------------------------------------------
# Algorithm v2 — YouTube-inspired multi-signal scoring
# ---------------------------------------------------------------------------

def _age_hours(created_at_iso: str) -> float:
    try:
        ts = created_at_iso.replace("Z", "+00:00")
        return (datetime.now(timezone.utc) - datetime.fromisoformat(ts)).total_seconds() / 3600
    except Exception:
        return 9999.0


def _recency_score(age_hours: float) -> float:
    """Smooth decay curve instead of step-function."""
    if age_hours < 6:    return 20.0
    if age_hours < 24:   return 16.0
    if age_hours < 72:   return 11.0
    if age_hours < 168:  return 7.0
    if age_hours < 720:  return 3.0
    if age_hours < 2160: return 1.0
    return 0.0


def _ctr_score(views: int, impressions: int) -> float:
    """Click-through rate signal — how often people click when shown this video."""
    if impressions < 10:
        return 5.0  # Not enough data — neutral prior
    ctr = min(views / impressions, 1.0)
    # YouTube target CTR is ~2-10%; we scale to 0-25 pts
    return min(ctr * 150, 25.0)


def _engagement_score(like_count: int, comment_count: int, share_count: int, views: int) -> float:
    """Weighted engagement rate — shares > comments > likes (cost of action)."""
    # Likes=1, Comments=3 (intent to discuss), Shares=5 (highest intent)
    weighted = like_count * 1 + comment_count * 3 + share_count * 5
    rate = weighted / max(views, 1)
    return min(rate * 50, 30.0)


def _completion_score(avg_completion: float) -> float:
    """Avg completion rate across ALL users for this video — signals content quality."""
    # 0-20 pts. A video watched to 80%+ avg is exceptional.
    return min(avg_completion * 25, 20.0)


def _velocity_score(recent_views: int, total_views: int, age_hours: float) -> float:
    """Trending signal — how fast is this video gaining traction right now?"""
    if total_views < 1:
        return 0.0
    # recent_views = views in last 24h
    velocity = recent_views / max(total_views, 1)
    # New videos naturally have high velocity — dampen slightly for very new content
    dampen = min(age_hours / 12, 1.0) if age_hours < 48 else 1.0
    return min(velocity * 40 * dampen, 20.0)


def score_video(
    row: dict,
    *,
    follow_boost: float = 0.0,
    watch_penalty: float = 0.0,
    category_score: float = 0.0,
    collab_boost: float = 0.0,
    save_boost: float = 0.0,
) -> float:
    """Main scoring function — combines all signals."""
    views = row.get("views") or 0
    impressions = row.get("impressions") or views  # fallback if column missing
    age_h = _age_hours(row.get("created_at", ""))
    recent_v = row.get("recent_views") or 0
    avg_comp = row.get("avg_completion_rate") or 0.0

    # Core signals
    s_ctr         = _ctr_score(views, impressions)                               # max 25
    s_engagement  = _engagement_score(
        row.get("like_count") or 0,
        row.get("comment_count") or 0,
        row.get("share_count") or 0,
        views,
    )                                                                             # max 30
    s_completion  = _completion_score(avg_comp)                                  # max 20
    s_velocity    = _velocity_score(recent_v, views, age_h)                     # max 20
    s_recency     = _recency_score(age_h)                                       # max 20

    # Personalization signals
    s_follow      = follow_boost      # +15 if user follows creator
    s_category    = category_score    # 0-20 based on user affinity
    s_collab      = collab_boost      # 0-10 collaborative filtering boost
    s_save        = save_boost        # +5 if user saved similar content

    # Penalty / suppression
    s_watch       = watch_penalty     # -3 to -20 depending on skip depth

    # Featured override
    s_featured    = 100.0 if (row.get("is_featured") or 0) else 0.0

    return (s_ctr + s_engagement + s_completion + s_velocity + s_recency
            + s_follow + s_category + s_collab + s_save + s_watch + s_featured)


def _update_recent_views(db, vid_id: str) -> None:
    """Recalculate recent_views (last 24h) for a video. Called on watch event."""
    threshold = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
    count = db.execute(
        """SELECT COUNT(*) FROM history
           WHERE video_id=? AND viewed_at > ?""",
        (vid_id, threshold),
    ).fetchone()[0]
    db.execute(
        "UPDATE videos SET recent_views=?, recent_views_updated=? WHERE id=?",
        (count, utcnow(), vid_id),
    )


# ---------------------------------------------------------------------------
# JSON serializers
# ---------------------------------------------------------------------------

def video_to_dict(row, liked=False, saved=False, following=False) -> dict:
    return {
        "id": row["id"],
        "title": row["title"],
        "description": row["description"] or "",
        "creator": row["creator_name"],
        "creatorId": row["creator_id"],
        "creatorAvatar": row["avatar_url"] if row["avatar_url"] else "",
        "creatorVerified": bool(row["is_verified"] if row["is_verified"] is not None else 0),
        "category": row["category"],
        "duration": row["duration"] or "0:00",
        "views": row["views"] or 0,
        "likes": row["like_count"] or 0,
        "comments": row["comment_count"] or 0,
        "shares": row["share_count"] or 0,
        "isShort": bool(row["is_short"]),
        "isLive": bool(row["is_live"]),
        "isFeatured": bool(row["is_featured"] if row["is_featured"] is not None else 0),
        "progress": row["progress"] if row["progress"] is not None else 0,
        "liked": liked,
        "saved": saved,
        "following": following,
        "mediaUrl": row["media_url"] or "",
        "thumbnailUrl": row["thumbnail_url"] or "",
        "createdAt": row["created_at"],
        "label": f"{row['category']} {'shorts' if row['is_short'] else 'video'}",
        "meta": f"{row['creator_name']} • {format_views(row['views'] or 0)} views",
    }


def user_to_dict(row) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "email": row["email"],
        "handle": row["handle"],
        "bio": row["bio"] or "",
        "avatarUrl": row["avatar_url"] or "",
        "subscription": row["subscription"] or "Free",
        "isVerified": bool(row["is_verified"]),
        "isAdmin": bool(row["is_admin"]),
    }


def comment_to_dict(row) -> dict:
    return {
        "id": row["id"],
        "videoId": row["video_id"],
        "userId": row["user_id"],
        "userName": row["user_name"],
        "userHandle": row["user_handle"],
        "content": row["content"],
        "likeCount": row["like_count"] or 0,
        "createdAt": row["created_at"],
    }


def notification_to_dict(row) -> dict:
    return {
        "id": row["id"],
        "userId": row["user_id"],
        "type": row["type"],
        "fromUserId": row["from_user_id"] or "",
        "fromUserName": row["from_user_name"] or "",
        "videoId": row["video_id"] or "",
        "message": row["message"],
        "isRead": bool(row["is_read"]),
        "createdAt": row["created_at"],
    }


def report_to_dict(row) -> dict:
    return {
        "id": row["id"],
        "reporterId": row["reporter_id"],
        "type": row["type"],
        "targetId": row["target_id"],
        "reason": row["reason"],
        "status": row["status"],
        "createdAt": row["created_at"],
    }


# ---------------------------------------------------------------------------
# Cloudflare R2 pre-signed URL (AWS Signature Version 4)
# ---------------------------------------------------------------------------

def _hmac_sha256(key: bytes, data: str) -> bytes:
    return hmac.new(key, data.encode("utf-8"), hashlib.sha256).digest()


def _r2_presign_put(key: str, content_type: str, expires: int = 3600,
                    bucket: str = None, public_url: str = None) -> str:
    """Generate a pre-signed PUT URL for R2 using boto3."""
    if not R2_ENDPOINT or not R2_ACCESS_KEY_ID or not R2_SECRET_ACCESS_KEY:
        return ""

    target_bucket = bucket or R2_BUCKET_NAME

    try:
        s3_client = boto3.client('s3',
            endpoint_url=R2_ENDPOINT,
            aws_access_key_id=R2_ACCESS_KEY_ID,
            aws_secret_access_key=R2_SECRET_ACCESS_KEY,
            config=Config(signature_version='s3v4'),
            region_name='auto'
        )

        params = {'Bucket': target_bucket, 'Key': key}
        # NOTE: Do NOT include ContentType in params — if we sign it, the client's
        # Content-Type header must match byte-perfectly or R2 returns 403.
        # Leaving it unsigned means the client can set any Content-Type freely.

        return s3_client.generate_presigned_url(
            ClientMethod='put_object',
            Params=params,
            ExpiresIn=expires
        )
    except Exception as e:
        print(f"[OFG ERROR] Presign URL failed: {e}")
        return ""


def r2_public_url(key: str, pub_url: str = None, bucket: str = None) -> str:
    base = (pub_url or R2_PUBLIC_URL).rstrip("/")
    if base:
        return f"{base}/{key}"
    target_bucket = bucket or R2_BUCKET_NAME
    if R2_ENDPOINT:
        return f"{R2_ENDPOINT.rstrip('/')}/{target_bucket}/{key}"
    return key


# ---------------------------------------------------------------------------
# Feed query helper
# ---------------------------------------------------------------------------

VIDEO_SELECT = """
    SELECT v.*,
           u.avatar_url,
           u.is_verified
    FROM videos v
    JOIN users u ON u.id = v.creator_id
    WHERE v.is_removed = 0
"""


def _build_feed(
    db: sqlite3.Connection,
    user=None,
    category: str = "",
    is_short: Optional[bool] = None,
    page: int = 0,
    limit: int = 20,
    search_q: str = "",
) -> tuple[list[dict], int]:
    """
    Algorithm v2 — YouTube-inspired multi-signal personalized feed.
    Signals: CTR, engagement quality, completion rate, velocity/trending,
             recency, follow boost, category affinity, collaborative filtering,
             adaptive watch penalty, creator diversity.
    """

    # ---- base query — fetch all candidates ----
    conditions = ["v.is_removed = 0"]
    params: list = []

    if category:
        conditions.append("v.category = ?")
        params.append(category)

    if is_short is not None:
        conditions.append("v.is_short = ?")
        params.append(1 if is_short else 0)

    if search_q:
        conditions.append("(v.title LIKE ? OR v.description LIKE ? OR v.creator_name LIKE ?)")
        like = f"%{search_q}%"
        params.extend([like, like, like])

    where = " AND ".join(conditions)

    sql = f"""
        SELECT v.*,
               u.avatar_url,
               u.is_verified
        FROM videos v
        JOIN users u ON u.id = v.creator_id
        WHERE {where}
    """

    rows = db.execute(sql, params).fetchall()

    if not rows:
        return [], 0

    # ---- Track impressions for CTR signal ----
    # Every video returned in /feed = 1 impression (server-side CTR)
    vid_ids_in_feed = [r["id"] for r in rows]
    if vid_ids_in_feed:
        placeholders = ",".join("?" * len(vid_ids_in_feed))
        db.execute(
            f"UPDATE videos SET impressions=impressions+1 WHERE id IN ({placeholders})",
            vid_ids_in_feed,
        )
        db.commit()

    # ---- Personalization context ----
    followed_ids: set[str] = set()
    watched_completion: dict[str, float] = {}   # video_id -> user's personal completion rate
    skip_ids: set[str] = set()                   # videos user skipped early
    top_categories: dict[str, float] = {}        # category -> affinity score
    liked_ids: set[str] = set()
    saved_ids: set[str] = set()
    collab_video_ids: set[str] = set()           # collaborative filtering candidates

    if user:
        uid = user["id"]

        # Follows
        foll = db.execute("SELECT creator_id FROM follows WHERE follower_id=?", (uid,)).fetchall()
        followed_ids = {r["creator_id"] for r in foll}

        # Watch history with completion rates
        hist = db.execute(
            "SELECT video_id, completion_rate FROM history WHERE user_id=?", (uid,)
        ).fetchall()
        for r in hist:
            watched_completion[r["video_id"]] = float(r["completion_rate"] or 0)

        # Skips (completion < 15%)
        try:
            skip_rows = db.execute(
                "SELECT video_id FROM video_skips WHERE user_id=?", (uid,)
            ).fetchall()
            skip_ids = {r["video_id"] for r in skip_rows}
        except Exception:
            pass  # Table may not exist on old DB — safe fallback

        # Category affinity — weighted by completion + recency
        cat_sql = """
            SELECT v.category,
                   SUM(h.completion_rate * CASE
                       WHEN h.viewed_at > datetime('now', '-7 days') THEN 2.0
                       WHEN h.viewed_at > datetime('now', '-30 days') THEN 1.0
                       ELSE 0.5 END) AS weighted_affinity,
                   COUNT(*) AS cnt
            FROM history h
            JOIN videos v ON v.id = h.video_id
            WHERE h.user_id = ?
            GROUP BY v.category
            ORDER BY weighted_affinity DESC
        """
        cat_rows = db.execute(cat_sql, (uid,)).fetchall()
        for cr in cat_rows:
            top_categories[cr["category"]] = float(cr["weighted_affinity"] or 0)

        # Normalize category affinity to 0-1
        max_affinity = max(top_categories.values(), default=1)
        top_categories = {k: v / max_affinity for k, v in top_categories.items()}

        # Likes / Saves
        lk = db.execute("SELECT video_id FROM likes WHERE user_id=?", (uid,)).fetchall()
        liked_ids = {r["video_id"] for r in lk}

        sv = db.execute("SELECT video_id FROM saves WHERE user_id=?", (uid,)).fetchall()
        saved_ids = {r["video_id"] for r in sv}

        # ---- Collaborative Filtering (lightweight co-watch) ----
        # Find users who watched the same top-3 videos as this user
        # Then recommend what they also watched (but this user hasn't seen)
        top_watched = list(watched_completion.keys())[:3]
        if top_watched:
            placeholders = ",".join("?" * len(top_watched))
            similar_users = db.execute(
                f"""SELECT DISTINCT h2.user_id FROM history h2
                    WHERE h2.video_id IN ({placeholders})
                    AND h2.user_id != ?
                    AND h2.completion_rate > 0.5
                    LIMIT 20""",
                top_watched + [uid],
            ).fetchall()
            similar_uids = [r["user_id"] for r in similar_users]
            if similar_uids:
                s_ph = ",".join("?" * len(similar_uids))
                collab_rows = db.execute(
                    f"""SELECT DISTINCT h.video_id FROM history h
                        WHERE h.user_id IN ({s_ph})
                        AND h.video_id NOT IN ({placeholders})
                        AND h.completion_rate > 0.6""",
                    similar_uids + top_watched,
                ).fetchall()
                collab_video_ids = {r["video_id"] for r in collab_rows}

    # ---- Score each video ----
    scored: list[tuple[float, sqlite3.Row]] = []

    for row in rows:
        vid_id  = row["id"]
        vid_cat = row["category"]
        creator_id = row["creator_id"]

        # --- Personalization signals ---
        follow_boost = 15.0 if creator_id in followed_ids else 0.0

        # Adaptive watch penalty based on how much user skipped
        if vid_id in skip_ids:
            watch_penalty = -20.0  # User actively skipped early — strong suppress
        elif vid_id in watched_completion:
            cr = watched_completion[vid_id]
            if cr >= 0.85:
                watch_penalty = -2.0   # Watched nearly all — mild penalty (may rewatch)
            elif cr >= 0.5:
                watch_penalty = -6.0   # Watched half
            elif cr >= 0.2:
                watch_penalty = -12.0  # Watched a little
            else:
                watch_penalty = -18.0  # Barely watched — suppress heavily
        else:
            watch_penalty = 0.0

        # Category affinity (0–20 pts)
        category_score = top_categories.get(vid_cat, 0) * 20

        # Collaborative filtering boost (0–10 pts)
        collab_boost = 8.0 if vid_id in collab_video_ids else 0.0

        # Save signal — user saved similar category content
        save_boost = 3.0 if vid_id in saved_ids else 0.0

        sc = score_video(
            dict(row),
            follow_boost=follow_boost,
            watch_penalty=watch_penalty,
            category_score=category_score,
            collab_boost=collab_boost,
            save_boost=save_boost,
        )

        scored.append((sc, row))

    scored.sort(key=lambda x: x[0], reverse=True)
    total = len(scored)

    # ---- Creator Diversity: max 3 videos per creator per page ----
    start = page * limit
    all_sorted = scored  # already sorted
    creator_count: dict[str, int] = {}
    paged: list[tuple[float, sqlite3.Row]] = []
    skipped = 0

    for score, row in all_sorted:
        if len(paged) >= limit + start:
            break
        cid = row["creator_id"]
        creator_count[cid] = creator_count.get(cid, 0) + 1
        if creator_count[cid] > 3:  # Max 3 per creator per feed request
            continue
        paged.append((score, row))

    paged = paged[start: start + limit]

    # ---- Build result items ----
    items = []
    for _, row in paged:
        vid_id    = row["id"]
        liked     = vid_id in liked_ids
        saved     = vid_id in saved_ids
        following = row["creator_id"] in followed_ids

        prog = 0.0
        if user and vid_id in watched_completion:
            hr = db.execute(
                "SELECT progress FROM history WHERE user_id=? AND video_id=?",
                (user["id"], vid_id),
            ).fetchone()
            if hr:
                prog = float(hr["progress"] or 0)

        d = video_to_dict(row, liked=liked, saved=saved, following=following)
        d["progress"] = prog
        # Surface algorithm confidence for debugging (remove in prod)
        # d["_score"] = round(score, 2)
        items.append(d)

    return items, total


# ---------------------------------------------------------------------------
# HTTP Handler
# ---------------------------------------------------------------------------

class Handler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):  # noqa: A002
        pass  # suppress default request logs

    # ------------------------------------------------------------------ CORS

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Admin-Secret")

    def _json(self, data: dict, status: int = 200):
        body = json.dumps(data, default=str).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self._cors()
        self.end_headers()
        self.wfile.write(body)

    def _error(self, msg: str, status: int = 400):
        self._json({"error": msg}, status)

    def _body(self) -> dict:
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return {}
        try:
            return json.loads(self.rfile.read(length))
        except Exception:
            return {}

    def _qs(self) -> dict:
        parsed = urllib.parse.urlparse(self.path)
        return {k: v[0] for k, v in urllib.parse.parse_qs(parsed.query).items()}

    def _path(self) -> str:
        return urllib.parse.urlparse(self.path).path.rstrip("/")

    def _token(self) -> Optional[str]:
        auth = self.headers.get("Authorization", "")
        if auth.startswith("Bearer "):
            return auth[7:].strip()
        return None

    def _user(self, db: sqlite3.Connection):
        token = self._token()
        if not token:
            return None
        sess = db.execute("SELECT * FROM sessions WHERE token=?", (token,)).fetchone()
        if not sess:
            return None
        return db.execute(
            "SELECT * FROM users WHERE id=? AND is_banned=0", (sess["user_id"],)
        ).fetchone()

    def _require_user(self, db: sqlite3.Connection):
        user = self._user(db)
        if not user:
            self._error("Unauthorized", 401)
            return None
        return user

    def _require_admin(self, db: sqlite3.Connection) -> bool:
        secret = self.headers.get("X-Admin-Secret", "")
        if secret == ADMIN_SECRET:
            return True
        user = self._user(db)
        if user and user["is_admin"]:
            return True
        self._error("Forbidden", 403)
        return False

    # ---------------------------------------------------------------- OPTIONS

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    # -------------------------------------------------------------------- GET

    def do_GET(self):
        db = get_db()
        try:
            self._route_get(db)
        except Exception as exc:
            print(f"[OFG ERROR] GET {self.path}: {exc}")
            self._error("Internal server error", 500)
        finally:
            db.close()

    def _route_get(self, db: sqlite3.Connection):
        path = self._path()
        qs   = self._qs()

        # /test-upload - Browser upload test
        if path == "/test-upload":
            html = """<!DOCTYPE html>
<html>
<head>
    <title>Upload Test</title>
    <style>body { font-family: sans-serif; padding: 20px; }</style>
</head>
<body>
    <h2>Upload Test Page</h2>
    <p>1. Login (automatic with test credentials)</p>
    <p>2. Select a video file below</p>
    <input type="file" id="filePicker" accept="video/*" />
    <br><br>
    <button onclick="doUpload()">Start Upload</button>
    <pre id="log" style="background:#eee; padding:10px; margin-top:20px; min-height:100px;"></pre>

    <script>
        function log(msg) {
            document.getElementById('log').innerText += msg + "\\n";
        }

        async function doUpload() {
            const file = document.getElementById('filePicker').files[0];
            if (!file) { alert("Select a file first"); return; }
            log("Logging in...");
            try {
                // 1. Login
                let res = await fetch("/auth/login", {
                    method: "POST",
                    headers: {"Content-Type": "application/json"},
                    body: JSON.stringify({email: "demo@ofg.local", password: "password123"})
                });
                let data = await res.json();
                if (!data.token) throw new Error("Login failed");
                let token = data.token;
                log("Login OK.");

                // 2. Init Upload
                log("Requesting upload URL...");
                res = await fetch("/upload/init", {
                    method: "POST",
                    headers: {"Content-Type": "application/json", "Authorization": "Bearer " + token},
                    body: JSON.stringify({filename: file.name, contentType: file.type, type: "video"})
                });
                data = await res.json();
                if (!data.uploadUrl) throw new Error("Init failed");
                log("Init OK. Uploading to R2...");

                // 3. PUT to R2
                res = await fetch(data.uploadUrl, {
                    method: "PUT",
                    headers: {"Content-Type": file.type},
                    body: file
                });
                if (!res.ok) {
                    const text = await res.text();
                    throw new Error(`R2 PUT Failed: ${res.status} ${text}`);
                }
                log("R2 PUT OK! Saving metadata...");

                // 4. Save metadata
                res = await fetch("/upload", {
                    method: "POST",
                    headers: {"Content-Type": "application/json", "Authorization": "Bearer " + token},
                    body: JSON.stringify({
                        title: "Web Test Upload",
                        description: "Uploaded from browser",
                        category: "sermons",
                        mediaUrl: data.mediaUrl,
                        thumbnailUrl: "",
                        duration: "0:00",
                        isShort: false
                    })
                });
                let finalData = await res.json();
                log("SUCCESS! Video ID: " + finalData.videoId);
            } catch (err) {
                log("ERROR: " + err.message);
            }
        }
    </script>
</body>
</html>"""
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(html.encode("utf-8"))
            return

        # /auth/me
        if path == "/auth/me":
            user = self._require_user(db)
            if not user:
                return
            self._json({"user": user_to_dict(user)})
            return

        # /feed or /videos (no ID)
        if path in ("/feed", "/videos"):
            self._handle_feed(db, qs)
            return

        # /videos/{id}
        m = re.fullmatch(r"/videos/([^/]+)", path)
        if m:
            self._handle_video_get(db, m.group(1))
            return

        # /videos/{id}/comments
        m = re.fullmatch(r"/videos/([^/]+)/comments", path)
        if m:
            self._handle_comments_get(db, m.group(1), qs)
            return

        # /shorts
        if path == "/shorts":
            self._handle_shorts(db, qs)
            return

        # /search
        if path == "/search":
            self._handle_search(db, qs)
            return

        # /users/{id}
        m = re.fullmatch(r"/users/([^/]+)", path)
        if m:
            self._handle_user_profile(db, m.group(1))
            return

        # /creator/stats
        if path == "/creator/stats":
            user = self._require_user(db)
            if not user:
                return
            self._handle_creator_stats(db, user)
            return

        # /creator/videos
        if path == "/creator/videos":
            user = self._require_user(db)
            if not user:
                return
            self._handle_creator_videos(db, user, qs)
            return

        # /library/history
        if path == "/library/history":
            user = self._require_user(db)
            if not user:
                return
            self._handle_history(db, user)
            return

        # /library/saved
        if path == "/library/saved":
            user = self._require_user(db)
            if not user:
                return
            self._handle_saved(db, user)
            return

        # /settings
        if path == "/settings":
            user = self._require_user(db)
            if not user:
                return
            self._handle_settings_get(db, user)
            return

        # /notifications
        if path == "/notifications":
            user = self._require_user(db)
            if not user:
                return
            self._handle_notifications_get(db, user)
            return

        # /admin/videos
        if path == "/admin/videos":
            if not self._require_admin(db):
                return
            self._handle_admin_videos(db, qs)
            return

        # /admin/reports
        if path == "/admin/reports":
            if not self._require_admin(db):
                return
            self._handle_admin_reports(db, qs)
            return

        # /admin/donations
        if path == "/admin/donations":
            if not self._require_admin(db):
                return
            self._handle_admin_donations(db, qs)
            return

        # /admin/payouts
        if path == "/admin/payouts":
            if not self._require_admin(db):
                return
            self._handle_admin_payouts(db, qs)
            return

        # /donations/history
        if path == "/donations/history":
            user = self._require_user(db)
            if not user:
                return
            self._handle_donation_history(db, user, qs)
            return

        # /creator/wallet
        if path == "/creator/wallet":
            user = self._require_user(db)
            if not user:
                return
            self._handle_creator_wallet_get(db, user)
            return

        # /creator/donations
        if path == "/creator/donations":
            user = self._require_user(db)
            if not user:
                return
            self._handle_creator_donations_list(db, user, qs)
            return

        # /creator/payouts
        if path == "/creator/payouts":
            user = self._require_user(db)
            if not user:
                return
            self._handle_creator_payouts_list(db, user, qs)
            return

        # /users/{id}/wallet (public wallet stats for creator profile)
        m = re.fullmatch(r"/users/([^/]+)/wallet", path)
        if m:
            self._handle_public_wallet(db, m.group(1))
            return

        self._error("Route not found", 404)

    # ------------------------------------------------------------------- POST

    def do_POST(self):
        db = get_db()
        try:
            self._route_post(db)
        except Exception as exc:
            print(f"[OFG ERROR] POST {self.path}: {exc}")
            self._error("Internal server error", 500)
        finally:
            db.close()

    def _route_post(self, db: sqlite3.Connection):
        path = self._path()

        if path == "/auth/register":
            self._handle_register(db)
            return

        if path == "/auth/login":
            self._handle_login(db)
            return

        if path == "/auth/logout":
            self._handle_logout(db)
            return

        # /videos/{id}/like
        m = re.fullmatch(r"/videos/([^/]+)/like", path)
        if m:
            self._handle_like(db, m.group(1))
            return

        # /videos/{id}/save
        m = re.fullmatch(r"/videos/([^/]+)/save", path)
        if m:
            self._handle_save(db, m.group(1))
            return

        # /videos/{id}/watch
        m = re.fullmatch(r"/videos/([^/]+)/watch", path)
        if m:
            self._handle_watch(db, m.group(1))
            return

        # /videos/{id}/comments
        m = re.fullmatch(r"/videos/([^/]+)/comments", path)
        if m:
            self._handle_comment_post(db, m.group(1))
            return

        # /follow/{user_id}
        m = re.fullmatch(r"/follow/([^/]+)", path)
        if m:
            self._handle_follow(db, m.group(1))
            return

        # /upload/init
        if path == "/upload/init":
            user = self._require_user(db)
            if not user:
                return
            self._handle_upload_init(db, user)
            return

        # /upload
        if path == "/upload":
            user = self._require_user(db)
            if not user:
                return
            self._handle_upload(db, user)
            return

        # /settings
        if path == "/settings":
            user = self._require_user(db)
            if not user:
                return
            self._handle_settings_post(db, user)
            return

        # /notifications/read-all
        if path == "/notifications/read-all":
            user = self._require_user(db)
            if not user:
                return
            db.execute(
                "UPDATE notifications SET is_read=1 WHERE user_id=?", (user["id"],)
            )
            db.commit()
            self._json({"ok": True})
            return

        # /reports
        if path == "/reports":
            user = self._require_user(db)
            if not user:
                return
            self._handle_report(db, user)
            return

        # /admin/videos/{id}/feature
        m = re.fullmatch(r"/admin/videos/([^/]+)/feature", path)
        if m:
            if not self._require_admin(db):
                return
            self._handle_admin_feature(db, m.group(1))
            return

        # /admin/users/{id}/ban
        m = re.fullmatch(r"/admin/users/([^/]+)/ban", path)
        if m:
            if not self._require_admin(db):
                return
            self._handle_admin_ban(db, m.group(1))
            return

        # /admin/reports/{id}/resolve
        m = re.fullmatch(r"/admin/reports/([^/]+)/resolve", path)
        if m:
            if not self._require_admin(db):
                return
            self._handle_admin_report_resolve(db, m.group(1))
            return

        # /donations (donate to creator)
        if path == "/donations":
            user = self._require_user(db)
            if not user:
                return
            self._handle_donate(db, user)
            return

        # /creator/payouts (request payout)
        if path == "/creator/payouts":
            user = self._require_user(db)
            if not user:
                return
            self._handle_creator_payout_request(db, user)
            return

        # /creator/wallet/payout-account
        if path == "/creator/wallet/payout-account":
            user = self._require_user(db)
            if not user:
                return
            self._handle_creator_payout_account(db, user)
            return

        # /admin/payouts/{id}/approve
        m = re.fullmatch(r"/admin/payouts/([^/]+)/approve", path)
        if m:
            if not self._require_admin(db):
                return
            self._handle_admin_payout_approve(db, m.group(1))
            return

        # /admin/payouts/{id}/reject
        m = re.fullmatch(r"/admin/payouts/([^/]+)/reject", path)
        if m:
            if not self._require_admin(db):
                return
            self._handle_admin_payout_reject(db, m.group(1))
            return

        self._error("Route not found", 404)

    # -------------------------------------------------------------------- PUT

    def do_PUT(self):
        db = get_db()
        try:
            path = self._path()
            if path == "/users/me":
                user = self._require_user(db)
                if not user:
                    return
                self._handle_user_update(db, user)
            else:
                self._error("Not found", 404)
        except Exception as exc:
            print(f"[OFG ERROR] PUT {self.path}: {exc}")
            self._error("Internal server error", 500)
        finally:
            db.close()

    # ----------------------------------------------------------------- DELETE

    def do_DELETE(self):
        db = get_db()
        try:
            path = self._path()
            if path == "/auth/logout":
                self._handle_logout(db)
            else:
                # /admin/videos/{id}
                m = re.fullmatch(r"/admin/videos/([^/]+)", path)
                if m:
                    if not self._require_admin(db):
                        return
                    vid_id = m.group(1)
                    db.execute("UPDATE videos SET is_removed=1 WHERE id=?", (vid_id,))
                    db.commit()
                    self._json({"ok": True})
                    return
                self._error("Not found", 404)
        except Exception as exc:
            print(f"[OFG ERROR] DELETE {self.path}: {exc}")
            self._error("Internal server error", 500)
        finally:
            db.close()

    # ================================================================= handlers

    # ---- Auth ----

    def _handle_register(self, db: sqlite3.Connection):
        body = self._body()
        name  = (body.get("name") or "").strip()
        email = (body.get("email") or "").strip().lower()
        password = body.get("password") or ""

        if not name or not email or not password:
            self._error("name, email, and password are required")
            return
        if not validate_email(email):
            self._error("Invalid email format")
            return
        if len(password) < 6:
            self._error("Password must be at least 6 characters")
            return

        existing = db.execute("SELECT id FROM users WHERE email=?", (email,)).fetchone()
        if existing:
            self._error("Email already registered", 409)
            return

        uid    = new_id()
        salt   = secrets.token_hex(16)
        phash  = hash_password(password, salt)
        handle = make_handle(name)
        now    = utcnow()

        db.execute(
            """INSERT INTO users (id, name, email, handle, password_hash, salt,
               bio, avatar_url, subscription, is_verified, is_admin, is_banned,
               follower_count, following_count, created_at)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (uid, name, email, handle, phash, salt, "", "", "Free", 0, 0, 0, 0, 0, now),
        )

        token = gen_token()
        db.execute(
            "INSERT INTO sessions (token, user_id, created_at) VALUES (?,?,?)",
            (token, uid, now),
        )
        db.commit()

        user_row = db.execute("SELECT * FROM users WHERE id=?", (uid,)).fetchone()
        self._json({"token": token, "user": user_to_dict(user_row)}, 201)

    def _handle_login(self, db: sqlite3.Connection):
        body  = self._body()
        email = (body.get("email") or "").strip().lower()
        password = body.get("password") or ""

        if not email or not password:
            self._error("email and password are required")
            return

        user = db.execute("SELECT * FROM users WHERE email=?", (email,)).fetchone()
        if not user:
            self._error("Invalid credentials", 401)
            return
        if user["is_banned"]:
            self._error("Account banned", 403)
            return
        if not verify_password(password, user["salt"], user["password_hash"]):
            self._error("Invalid credentials", 401)
            return

        token = gen_token()
        now = utcnow()
        db.execute(
            "INSERT OR REPLACE INTO sessions (token, user_id, created_at) VALUES (?,?,?)",
            (token, user["id"], now),
        )
        db.commit()
        self._json({"token": token, "user": user_to_dict(user)})

    def _handle_logout(self, db: sqlite3.Connection):
        token = self._token()
        if token:
            db.execute("DELETE FROM sessions WHERE token=?", (token,))
            db.commit()
        self._json({"ok": True})

    # ---- Feed ----

    def _handle_feed(self, db: sqlite3.Connection, qs: dict):
        category = qs.get("category", "")
        page  = int(qs.get("page", 0))
        limit = int(qs.get("limit", 20))
        limit = min(limit, 100)

        user = self._user(db)
        items, total = _build_feed(db, user=user, category=category, page=page, limit=limit)
        self._json({"items": items, "total": total, "page": page})

    def _handle_video_get(self, db: sqlite3.Connection, vid_id: str):
        row = db.execute(
            """SELECT v.*, u.avatar_url, u.is_verified
               FROM videos v JOIN users u ON u.id=v.creator_id
               WHERE v.id=? AND v.is_removed=0""",
            (vid_id,),
        ).fetchone()
        if not row:
            self._error("Video not found", 404)
            return

        user = self._user(db)
        liked = saved = following = False
        if user:
            uid = user["id"]
            liked   = bool(db.execute("SELECT 1 FROM likes WHERE user_id=? AND video_id=?", (uid, vid_id)).fetchone())
            saved   = bool(db.execute("SELECT 1 FROM saves WHERE user_id=? AND video_id=?", (uid, vid_id)).fetchone())
            following = bool(db.execute("SELECT 1 FROM follows WHERE follower_id=? AND creator_id=?", (uid, row["creator_id"])).fetchone())

        self._json({"video": video_to_dict(row, liked=liked, saved=saved, following=following)})

    def _handle_shorts(self, db: sqlite3.Connection, qs: dict):
        page  = int(qs.get("page", 0))
        limit = int(qs.get("limit", 20))
        limit = min(limit, 100)
        user  = self._user(db)
        items, total = _build_feed(db, user=user, is_short=True, page=page, limit=limit)
        self._json({"items": items, "total": total, "page": page})

    def _handle_search(self, db: sqlite3.Connection, qs: dict):
        q        = qs.get("q", "").strip()
        category = qs.get("category", "")
        page     = int(qs.get("page", 0))
        limit    = int(qs.get("limit", 20))
        limit    = min(limit, 100)

        user  = self._user(db)
        items, total = _build_feed(
            db, user=user, category=category, page=page, limit=limit, search_q=q
        )
        self._json({"items": items, "total": total, "page": page})

    # ---- Video Interactions ----

    def _handle_like(self, db: sqlite3.Connection, vid_id: str):
        user = self._require_user(db)
        if not user:
            return

        uid = user["id"]
        existing = db.execute(
            "SELECT 1 FROM likes WHERE user_id=? AND video_id=?", (uid, vid_id)
        ).fetchone()

        video = db.execute("SELECT * FROM videos WHERE id=? AND is_removed=0", (vid_id,)).fetchone()
        if not video:
            self._error("Video not found", 404)
            return

        if existing:
            db.execute("DELETE FROM likes WHERE user_id=? AND video_id=?", (uid, vid_id))
            db.execute("UPDATE videos SET like_count=MAX(0, like_count-1) WHERE id=?", (vid_id,))
            liked = False
        else:
            now = utcnow()
            db.execute(
                "INSERT INTO likes (user_id, video_id, created_at) VALUES (?,?,?)",
                (uid, vid_id, now),
            )
            db.execute("UPDATE videos SET like_count=like_count+1 WHERE id=?", (vid_id,))
            liked = True

            # notification for video creator (not self-like)
            if video["creator_id"] != uid:
                notif_id = new_id()
                msg = f"{user['name']} liked your video \"{video['title']}\""
                db.execute(
                    """INSERT INTO notifications
                       (id, user_id, type, from_user_id, from_user_name, video_id, message, is_read, created_at)
                       VALUES (?,?,?,?,?,?,?,?,?)""",
                    (notif_id, video["creator_id"], "like", uid, user["name"], vid_id, msg, 0, utcnow()),
                )

        db.commit()
        new_count = db.execute("SELECT like_count FROM videos WHERE id=?", (vid_id,)).fetchone()["like_count"]
        self._json({"liked": liked, "likeCount": new_count})

    def _handle_save(self, db: sqlite3.Connection, vid_id: str):
        user = self._require_user(db)
        if not user:
            return

        uid = user["id"]
        video = db.execute("SELECT id FROM videos WHERE id=? AND is_removed=0", (vid_id,)).fetchone()
        if not video:
            self._error("Video not found", 404)
            return

        existing = db.execute(
            "SELECT 1 FROM saves WHERE user_id=? AND video_id=?", (uid, vid_id)
        ).fetchone()

        if existing:
            db.execute("DELETE FROM saves WHERE user_id=? AND video_id=?", (uid, vid_id))
            saved = False
        else:
            now = utcnow()
            db.execute(
                "INSERT INTO saves (user_id, video_id, created_at) VALUES (?,?,?)",
                (uid, vid_id, now),
            )
            saved = True

        db.commit()
        self._json({"saved": saved})

    def _handle_watch(self, db: sqlite3.Connection, vid_id: str):
        body          = self._body()
        watch_time    = float(body.get("watchTime", 0))
        completion    = float(body.get("completionRate", 0))
        progress      = float(body.get("progress", 0))

        video = db.execute("SELECT * FROM videos WHERE id=? AND is_removed=0", (vid_id,)).fetchone()
        if not video:
            self._error("Video not found", 404)
            return

        user = self._user(db)
        if user:
            uid = user["id"]
            existing = db.execute(
                "SELECT 1 FROM history WHERE user_id=? AND video_id=?", (uid, vid_id)
            ).fetchone()

            now = utcnow()
            if existing:
                db.execute(
                    """UPDATE history SET progress=?, watch_time=?, completion_rate=?, viewed_at=?
                       WHERE user_id=? AND video_id=?""",
                    (progress, watch_time, completion, now, uid, vid_id),
                )
            else:
                # First watch → increment views
                db.execute(
                    """INSERT INTO history (user_id, video_id, progress, watch_time, completion_rate, viewed_at)
                       VALUES (?,?,?,?,?,?)""",
                    (uid, vid_id, progress, watch_time, completion, now),
                )
                db.execute("UPDATE videos SET views=views+1 WHERE id=?", (vid_id,))

            db.execute(
                "UPDATE videos SET watch_time_total=watch_time_total+? WHERE id=?",
                (watch_time, vid_id),
            )

            # ---- Update avg_completion_rate across all viewers ----
            avg_row = db.execute(
                "SELECT AVG(completion_rate) as ac FROM history WHERE video_id=?", (vid_id,)
            ).fetchone()
            db.execute(
                "UPDATE videos SET avg_completion_rate=? WHERE id=?",
                (float(avg_row["ac"] or 0), vid_id),
            )

            # ---- Update recent_views (last 24h) ----
            _update_recent_views(db, vid_id)

            # ---- Track skip signal ----
            try:
                if completion < 0.15:
                    # User skipped this video early — record it
                    db.execute(
                        """INSERT INTO video_skips (user_id, video_id, skip_rate, skipped_at)
                           VALUES (?,?,?,?)
                           ON CONFLICT(user_id, video_id) DO UPDATE SET
                               skip_rate=excluded.skip_rate, skipped_at=excluded.skipped_at""",
                        (uid, vid_id, completion, now),
                    )
                else:
                    # User watched enough — remove any prior skip record
                    db.execute(
                        "DELETE FROM video_skips WHERE user_id=? AND video_id=?",
                        (uid, vid_id),
                    )
            except Exception:
                pass  # Skip table may not exist on older DBs

        else:
            # Anonymous: just increment views every time
            db.execute("UPDATE videos SET views=views+1 WHERE id=?", (vid_id,))
            _update_recent_views(db, vid_id)

        db.commit()
        self._json({"ok": True})

    # ---- Comments ----

    def _handle_comments_get(self, db: sqlite3.Connection, vid_id: str, qs: dict):
        page  = int(qs.get("page", 0))
        limit = int(qs.get("limit", 20))
        limit = min(limit, 100)
        offset = page * limit

        total = db.execute(
            "SELECT COUNT(*) FROM comments WHERE video_id=?", (vid_id,)
        ).fetchone()[0]

        rows = db.execute(
            """SELECT * FROM comments WHERE video_id=?
               ORDER BY created_at DESC LIMIT ? OFFSET ?""",
            (vid_id, limit, offset),
        ).fetchall()

        self._json({"items": [comment_to_dict(r) for r in rows], "total": total})

    def _handle_comment_post(self, db: sqlite3.Connection, vid_id: str):
        user = self._require_user(db)
        if not user:
            return

        body    = self._body()
        content = (body.get("content") or "").strip()
        if not content:
            self._error("content is required")
            return
        if len(content) > 2000:
            self._error("Comment too long (max 2000 chars)")
            return

        video = db.execute("SELECT * FROM videos WHERE id=? AND is_removed=0", (vid_id,)).fetchone()
        if not video:
            self._error("Video not found", 404)
            return

        cid = new_id()
        now = utcnow()
        db.execute(
            """INSERT INTO comments (id, video_id, user_id, user_name, user_handle, content, like_count, created_at)
               VALUES (?,?,?,?,?,?,?,?)""",
            (cid, vid_id, user["id"], user["name"], user["handle"], content, 0, now),
        )
        db.execute("UPDATE videos SET comment_count=comment_count+1 WHERE id=?", (vid_id,))

        # notification for video creator (not self-comment)
        if video["creator_id"] != user["id"]:
            notif_id = new_id()
            msg = f"{user['name']} commented on your video \"{video['title']}\""
            db.execute(
                """INSERT INTO notifications
                   (id, user_id, type, from_user_id, from_user_name, video_id, message, is_read, created_at)
                   VALUES (?,?,?,?,?,?,?,?,?)""",
                (notif_id, video["creator_id"], "comment", user["id"], user["name"], vid_id, msg, 0, now),
            )

        db.commit()

        row = db.execute("SELECT * FROM comments WHERE id=?", (cid,)).fetchone()
        self._json({"comment": comment_to_dict(row)}, 201)

    # ---- Follows ----

    def _handle_follow(self, db: sqlite3.Connection, creator_id: str):
        user = self._require_user(db)
        if not user:
            return

        uid = user["id"]
        if uid == creator_id:
            self._error("Cannot follow yourself")
            return

        creator = db.execute("SELECT * FROM users WHERE id=? AND is_banned=0", (creator_id,)).fetchone()
        if not creator:
            self._error("User not found", 404)
            return

        existing = db.execute(
            "SELECT 1 FROM follows WHERE follower_id=? AND creator_id=?", (uid, creator_id)
        ).fetchone()

        if existing:
            db.execute(
                "DELETE FROM follows WHERE follower_id=? AND creator_id=?", (uid, creator_id)
            )
            db.execute(
                "UPDATE users SET follower_count=MAX(0, follower_count-1) WHERE id=?", (creator_id,)
            )
            db.execute(
                "UPDATE users SET following_count=MAX(0, following_count-1) WHERE id=?", (uid,)
            )
            following = False
        else:
            now = utcnow()
            db.execute(
                "INSERT INTO follows (follower_id, creator_id, created_at) VALUES (?,?,?)",
                (uid, creator_id, now),
            )
            db.execute("UPDATE users SET follower_count=follower_count+1 WHERE id=?", (creator_id,))
            db.execute("UPDATE users SET following_count=following_count+1 WHERE id=?", (uid,))
            following = True

            # notification
            notif_id = new_id()
            msg = f"{user['name']} started following you"
            db.execute(
                """INSERT INTO notifications
                   (id, user_id, type, from_user_id, from_user_name, video_id, message, is_read, created_at)
                   VALUES (?,?,?,?,?,?,?,?,?)""",
                (notif_id, creator_id, "follow", uid, user["name"], None, msg, 0, utcnow()),
            )

        db.commit()
        self._json({"following": following})

    # ---- User Profiles ----

    def _handle_user_profile(self, db: sqlite3.Connection, user_id: str):
        u = db.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
        if not u:
            self._error("User not found", 404)
            return

        videos = db.execute(
            """SELECT v.*, u2.avatar_url, u2.is_verified
               FROM videos v JOIN users u2 ON u2.id=v.creator_id
               WHERE v.creator_id=? AND v.is_removed=0
               ORDER BY v.created_at DESC LIMIT 50""",
            (user_id,),
        ).fetchall()

        video_count = db.execute(
            "SELECT COUNT(*) FROM videos WHERE creator_id=? AND is_removed=0", (user_id,)
        ).fetchone()[0]

        me = self._user(db)
        following = False
        if me:
            following = bool(
                db.execute(
                    "SELECT 1 FROM follows WHERE follower_id=? AND creator_id=?",
                    (me["id"], user_id),
                ).fetchone()
            )

        self._json({
            "user": user_to_dict(u),
            "videos": [video_to_dict(v, following=following) for v in videos],
            "followerCount": u["follower_count"] or 0,
            "followingCount": u["following_count"] or 0,
            "videoCount": video_count,
        })

    def _handle_user_update(self, db: sqlite3.Connection, user):
        body = self._body()
        uid  = user["id"]

        name       = (body.get("name") or user["name"]).strip()
        bio        = (body.get("bio") if body.get("bio") is not None else user["bio"] or "")
        handle_raw = (body.get("handle") or user["handle"]).strip()
        avatar_url = (body.get("avatarUrl") if body.get("avatarUrl") is not None else user["avatar_url"] or "")

        # Validate handle uniqueness
        if handle_raw != user["handle"]:
            clash = db.execute(
                "SELECT id FROM users WHERE handle=? AND id!=?", (handle_raw, uid)
            ).fetchone()
            if clash:
                self._error("Handle already taken", 409)
                return

        db.execute(
            """UPDATE users SET name=?, bio=?, handle=?, avatar_url=? WHERE id=?""",
            (name, bio, handle_raw, avatar_url, uid),
        )
        db.commit()
        updated = db.execute("SELECT * FROM users WHERE id=?", (uid,)).fetchone()
        self._json({"user": user_to_dict(updated)})

    # ---- Upload ----

    def _handle_upload_init(self, db: sqlite3.Connection, user):
        body         = self._body()
        filename     = (body.get("filename") or "").strip()
        content_type = (body.get("contentType") or "application/octet-stream").strip()
        # 'type' tells us which bucket: 'thumbnail', 'short', or 'video' (default)
        upload_type  = (body.get("type") or "video").strip().lower()

        if not filename:
            self._error("filename is required")
            return

        ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "bin"

        # Route to correct bucket and public URL based on upload type
        if upload_type == "thumbnail" or content_type.startswith("image/"):
            bucket     = R2_THUMBNAILS_BUCKET
            pub_url    = R2_THUMBNAILS_PUBLIC_URL
            key        = f"thumbnails/{new_id()}.{ext}"
        elif upload_type == "short":
            bucket     = R2_SHORTS_BUCKET
            pub_url    = R2_SHORTS_PUBLIC_URL
            key        = f"shorts/{new_id()}.{ext}"
        else:
            bucket     = R2_BUCKET_NAME
            pub_url    = R2_PUBLIC_URL
            key        = f"videos/{new_id()}.{ext}"

        upload_url = _r2_presign_put(key, content_type, bucket=bucket)
        media_url  = r2_public_url(key, pub_url=pub_url, bucket=bucket)

        self._json({"uploadUrl": upload_url, "mediaUrl": media_url, "key": key})

    def _handle_upload(self, db: sqlite3.Connection, user):
        body         = self._body()
        title        = (body.get("title") or "").strip()
        description  = (body.get("description") or "").strip()
        category     = (body.get("category") or "sermons").strip()
        media_url    = (body.get("mediaUrl") or "").strip()
        thumbnail_url = (body.get("thumbnailUrl") or "").strip()
        duration     = (body.get("duration") or "0:00").strip()
        is_short     = int(bool(body.get("isShort", False)))

        if not title:
            self._error("title is required")
            return
        if not media_url:
            self._error("mediaUrl is required")
            return

        vid_id = new_id()
        now    = utcnow()
        db.execute(
            """INSERT INTO videos
               (id, title, description, creator_id, creator_name, category, duration,
                views, like_count, comment_count, share_count, watch_time_total,
                thumbnail_url, media_url, is_live, is_short, is_featured, is_removed, created_at)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                vid_id, title, description, user["id"], user["name"],
                category, duration,
                0, 0, 0, 0, 0.0,
                thumbnail_url, media_url,
                0, is_short, 0, 0, now,
            ),
        )
        db.commit()
        self._json({"ok": True, "videoId": vid_id}, 201)

    # ---- Creator ----

    def _handle_creator_stats(self, db: sqlite3.Connection, user):
        uid = user["id"]
        stats = db.execute(
            """SELECT
                   COALESCE(SUM(views), 0) AS total_views,
                   COUNT(*) AS total_videos,
                   COALESCE(SUM(like_count), 0) AS total_likes
               FROM videos WHERE creator_id=? AND is_removed=0""",
            (uid,),
        ).fetchone()

        u = db.execute("SELECT follower_count, following_count FROM users WHERE id=?", (uid,)).fetchone()

        # Watch time + completion rate from history
        watch_stats = db.execute(
            """SELECT
                   COALESCE(SUM(h.watch_time), 0) AS total_watch_time,
                   COALESCE(AVG(h.completion_rate), 0) AS avg_completion
               FROM history h
               JOIN videos v ON v.id = h.video_id
               WHERE v.creator_id = ? AND v.is_removed = 0""",
            (uid,),
        ).fetchone()

        # Top category by watch time
        top_cat_row = db.execute(
            """SELECT v.category, COALESCE(SUM(h.watch_time), 0) AS wt
               FROM history h
               JOIN videos v ON v.id = h.video_id
               WHERE v.creator_id = ? AND v.is_removed = 0
               GROUP BY v.category
               ORDER BY wt DESC
               LIMIT 1""",
            (uid,),
        ).fetchone()

        top_category = top_cat_row["category"] if top_cat_row else ""

        self._json({
            "views": stats["total_views"] or 0,
            "videos": stats["total_videos"] or 0,
            "likes": stats["total_likes"] or 0,
            "followers": u["follower_count"] or 0,
            "following": u["following_count"] or 0,
            "totalWatchTime": float(watch_stats["total_watch_time"] or 0),
            "avgCompletionRate": float(watch_stats["avg_completion"] or 0),
            "topCategory": top_category,
        })

    def _handle_creator_videos(self, db: sqlite3.Connection, user, qs: dict):
        uid   = user["id"]
        page  = int(qs.get("page", 0))
        limit = int(qs.get("limit", 20))
        limit = min(limit, 100)
        offset = page * limit

        total = db.execute(
            "SELECT COUNT(*) FROM videos WHERE creator_id=? AND is_removed=0", (uid,)
        ).fetchone()[0]

        rows = db.execute(
            """SELECT v.*, u.avatar_url, u.is_verified
               FROM videos v JOIN users u ON u.id=v.creator_id
               WHERE v.creator_id=? AND v.is_removed=0
               ORDER BY v.created_at DESC LIMIT ? OFFSET ?""",
            (uid, limit, offset),
        ).fetchall()

        self._json({"items": [video_to_dict(r) for r in rows], "total": total, "page": page})

    # ---- Library ----

    def _handle_history(self, db: sqlite3.Connection, user):
        uid  = user["id"]
        rows = db.execute(
            """SELECT v.*, u.avatar_url, u.is_verified, h.progress
               FROM history h
               JOIN videos v ON v.id=h.video_id
               JOIN users u ON u.id=v.creator_id
               WHERE h.user_id=? AND v.is_removed=0
               ORDER BY h.viewed_at DESC LIMIT 100""",
            (uid,),
        ).fetchall()

        items = []
        for row in rows:
            d = video_to_dict(row)
            d["progress"] = row["progress"] or 0
            items.append(d)

        self._json({"items": items})

    def _handle_saved(self, db: sqlite3.Connection, user):
        uid  = user["id"]
        rows = db.execute(
            """SELECT v.*, u.avatar_url, u.is_verified
               FROM saves s
               JOIN videos v ON v.id=s.video_id
               JOIN users u ON u.id=v.creator_id
               WHERE s.user_id=? AND v.is_removed=0
               ORDER BY s.created_at DESC LIMIT 100""",
            (uid,),
        ).fetchall()

        self._json({"items": [video_to_dict(r, saved=True) for r in rows]})

    # ---- Settings ----

    def _handle_settings_get(self, db: sqlite3.Connection, user):
        uid  = user["id"]
        rows = db.execute("SELECT key, value FROM settings WHERE user_id=?", (uid,)).fetchall()
        self._json({"settings": {r["key"]: r["value"] for r in rows}})

    def _handle_settings_post(self, db: sqlite3.Connection, user):
        body  = self._body()
        key   = (body.get("key") or "").strip()
        value = body.get("value")

        if not key:
            self._error("key is required")
            return
        if value is None:
            self._error("value is required")
            return

        uid = user["id"]
        db.execute(
            "INSERT OR REPLACE INTO settings (user_id, key, value) VALUES (?,?,?)",
            (uid, key, str(value)),
        )
        db.commit()
        self._json({"ok": True})

    # ---- Notifications ----

    def _handle_notifications_get(self, db: sqlite3.Connection, user):
        uid  = user["id"]
        rows = db.execute(
            """SELECT * FROM notifications WHERE user_id=?
               ORDER BY created_at DESC LIMIT 100""",
            (uid,),
        ).fetchall()

        unread = db.execute(
            "SELECT COUNT(*) FROM notifications WHERE user_id=? AND is_read=0", (uid,)
        ).fetchone()[0]

        self._json({
            "items": [notification_to_dict(r) for r in rows],
            "unreadCount": unread,
        })

    # ---- Reports ----

    def _handle_report(self, db: sqlite3.Connection, user):
        body      = self._body()
        rtype     = (body.get("type") or "").strip()
        target_id = (body.get("targetId") or "").strip()
        reason    = (body.get("reason") or "").strip()

        if rtype not in ("video", "user"):
            self._error("type must be 'video' or 'user'")
            return
        if not target_id or not reason:
            self._error("targetId and reason are required")
            return

        rid = new_id()
        now = utcnow()
        db.execute(
            """INSERT INTO reports (id, reporter_id, type, target_id, reason, status, created_at)
               VALUES (?,?,?,?,?,?,?)""",
            (rid, user["id"], rtype, target_id, reason, "pending", now),
        )
        db.commit()
        self._json({"ok": True}, 201)

    # ---- Admin ----

    def _handle_admin_videos(self, db: sqlite3.Connection, qs: dict):
        status = qs.get("status", "all")
        page   = int(qs.get("page", 0))
        limit  = int(qs.get("limit", 50))
        limit  = min(limit, 200)
        offset = page * limit

        if status == "removed":
            where = "WHERE v.is_removed=1"
        elif status == "active":
            where = "WHERE v.is_removed=0"
        else:
            where = ""

        rows = db.execute(
            f"""SELECT v.*, u.avatar_url, u.is_verified
                FROM videos v JOIN users u ON u.id=v.creator_id
                {where}
                ORDER BY v.created_at DESC LIMIT ? OFFSET ?""",
            (limit, offset),
        ).fetchall()

        total = db.execute(
            f"SELECT COUNT(*) FROM videos v {where}"
        ).fetchone()[0]

        self._json({"items": [video_to_dict(r) for r in rows], "total": total, "page": page})

    def _handle_admin_feature(self, db: sqlite3.Connection, vid_id: str):
        video = db.execute("SELECT id, is_featured FROM videos WHERE id=?", (vid_id,)).fetchone()
        if not video:
            self._error("Video not found", 404)
            return
        new_val = 0 if video["is_featured"] else 1
        db.execute("UPDATE videos SET is_featured=? WHERE id=?", (new_val, vid_id))
        db.commit()
        self._json({"ok": True, "featured": bool(new_val)})

    def _handle_admin_ban(self, db: sqlite3.Connection, user_id: str):
        u = db.execute("SELECT id, is_banned FROM users WHERE id=?", (user_id,)).fetchone()
        if not u:
            self._error("User not found", 404)
            return
        new_val = 0 if u["is_banned"] else 1
        db.execute("UPDATE users SET is_banned=? WHERE id=?", (new_val, user_id))
        if new_val:
            db.execute("DELETE FROM sessions WHERE user_id=?", (user_id,))
        db.commit()
        self._json({"ok": True, "banned": bool(new_val)})

    def _handle_admin_reports(self, db: sqlite3.Connection, qs: dict):
        status = qs.get("status", "pending")
        page   = int(qs.get("page", 0))
        limit  = int(qs.get("limit", 50))
        limit  = min(limit, 200)
        offset = page * limit

        if status == "all":
            rows = db.execute(
                "SELECT * FROM reports ORDER BY created_at DESC LIMIT ? OFFSET ?",
                (limit, offset),
            ).fetchall()
        else:
            rows = db.execute(
                "SELECT * FROM reports WHERE status=? ORDER BY created_at DESC LIMIT ? OFFSET ?",
                (status, limit, offset),
            ).fetchall()

        self._json({"items": [report_to_dict(r) for r in rows]})

    def _handle_admin_report_resolve(self, db: sqlite3.Connection, report_id: str):
        body   = self._body()
        status = (body.get("status") or "").strip()
        if status not in ("resolved", "dismissed"):
            self._error("status must be 'resolved' or 'dismissed'")
            return

        rpt = db.execute("SELECT id FROM reports WHERE id=?", (report_id,)).fetchone()
        if not rpt:
            self._error("Report not found", 404)
            return

        db.execute("UPDATE reports SET status=? WHERE id=?", (status, report_id))
        db.commit()
        self._json({"ok": True})

    # ---- Donation System ----

    PLATFORM_FEE_RATE = 0.10  # 10% platform fee

    def _ensure_wallet(self, db: sqlite3.Connection, creator_id: str):
        """Create a wallet row for creator if one doesn't exist."""
        db.execute(
            """INSERT OR IGNORE INTO creator_wallets
               (creator_id, wallet_balance, lifetime_donations, lifetime_platform_fees,
                total_supporters, monthly_earnings, pending_payout, updated_at)
               VALUES (?,0,0,0,0,0,0,?)""",
            (creator_id, utcnow()),
        )

    def _handle_donate(self, db: sqlite3.Connection, user):
        body = self._body()
        creator_id  = body.get("creatorId", "").strip()
        amount      = float(body.get("amount", 0))
        message     = str(body.get("message", ""))[:250]
        is_anon     = 1 if body.get("isAnonymous") else 0

        # --- Validation ---
        if not creator_id:
            self._error("creatorId is required")
            return
        if amount < 10 or amount > 50000:
            self._error("Amount must be between ₹10 and ₹50,000")
            return
        if creator_id == user["id"]:
            self._error("You cannot donate to yourself")
            return

        creator = db.execute(
            "SELECT id, name FROM users WHERE id=? AND is_banned=0", (creator_id,)
        ).fetchone()
        if not creator:
            self._error("Creator not found", 404)
            return

        # --- Rate limiting: max 3 donations per hour per user ---
        one_hour_ago = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
        recent_count = db.execute(
            "SELECT COUNT(*) FROM donations WHERE donor_id=? AND created_at > ?",
            (user["id"], one_hour_ago),
        ).fetchone()[0]
        if recent_count >= 3:
            self._error("Too many donations. Please wait before donating again.")
            return

        # --- Duplicate detection: same donor+creator in last 10 seconds ---
        ten_sec_ago = (datetime.now(timezone.utc) - timedelta(seconds=10)).isoformat()
        dupe = db.execute(
            "SELECT id FROM donations WHERE donor_id=? AND creator_id=? AND created_at > ?",
            (user["id"], creator_id, ten_sec_ago),
        ).fetchone()
        if dupe:
            self._error("Duplicate donation detected. Please wait a moment.")
            return

        # --- Revenue split ---
        platform_fee    = round(amount * self.PLATFORM_FEE_RATE, 2)
        creator_amount  = round(amount - platform_fee, 2)

        # --- Simulate payment (Razorpay-ready placeholder) ---
        # In production: call Razorpay API here, capture payment, then proceed
        transaction_id = f"TXN_{secrets.token_hex(8).upper()}"

        # --- Record donation ---
        donation_id = f"DON_{secrets.token_hex(10).upper()}"
        now = utcnow()

        db.execute(
            """INSERT INTO donations
               (id, donor_id, creator_id, amount, platform_fee, creator_amount,
                message, is_anonymous, status, transaction_id, payment_method, created_at)
               VALUES (?,?,?,?,?,?,?,?,'completed',?,'simulated',?)""",
            (donation_id, user["id"], creator_id, amount, platform_fee,
             creator_amount, message, is_anon, transaction_id, now),
        )

        # --- Update creator wallet ---
        self._ensure_wallet(db, creator_id)

        # Check if this donor is new for this creator
        existing_donor = db.execute(
            "SELECT id FROM donations WHERE donor_id=? AND creator_id=? AND id!=?",
            (user["id"], creator_id, donation_id),
        ).fetchone()
        new_supporter = 1 if not existing_donor else 0

        db.execute(
            """UPDATE creator_wallets SET
                wallet_balance       = wallet_balance + ?,
                lifetime_donations   = lifetime_donations + ?,
                lifetime_platform_fees = lifetime_platform_fees + ?,
                total_supporters     = total_supporters + ?,
                monthly_earnings     = monthly_earnings + ?,
                updated_at           = ?
               WHERE creator_id = ?""",
            (creator_amount, amount, platform_fee, new_supporter, creator_amount, now, creator_id),
        )

        # --- Send notification to creator ---
        donor_label = "Anonymous Supporter" if is_anon else user["name"]
        notif_msg = f"{donor_label} donated ₹{int(amount)} to your ministry!"
        db.execute(
            """INSERT INTO notifications (id, user_id, type, from_user_id, from_user_name,
               video_id, message, is_read, created_at)
               VALUES (?,?,'donation',?,?,'',?,0,?)""",
            (secrets.token_hex(12), creator_id,
             user["id"] if not is_anon else "",
             donor_label, notif_msg, now),
        )

        db.commit()

        self._json({
            "ok": True,
            "donationId": donation_id,
            "transactionId": transaction_id,
            "amount": amount,
            "platformFee": platform_fee,
            "creatorAmount": creator_amount,
            "creatorName": creator["name"],
            "message": "Donation successful! God bless you 🙏",
        })

    def _handle_donation_history(self, db: sqlite3.Connection, user, qs: dict):
        page  = int(qs.get("page", 0))
        limit = min(int(qs.get("limit", 20)), 100)
        offset = page * limit

        total = db.execute(
            "SELECT COUNT(*) FROM donations WHERE donor_id=?", (user["id"],)
        ).fetchone()[0]

        rows = db.execute(
            """SELECT d.*, u.name as creator_name, u.avatar_url as creator_avatar
               FROM donations d
               JOIN users u ON u.id = d.creator_id
               WHERE d.donor_id = ?
               ORDER BY d.created_at DESC LIMIT ? OFFSET ?""",
            (user["id"], limit, offset),
        ).fetchall()

        items = [dict(r) for r in rows]
        self._json({"items": items, "total": total, "page": page})

    def _handle_creator_wallet_get(self, db: sqlite3.Connection, user):
        self._ensure_wallet(db, user["id"])
        db.commit()
        wallet = db.execute(
            "SELECT * FROM creator_wallets WHERE creator_id=?", (user["id"],)
        ).fetchone()
        self._json(dict(wallet))

    def _handle_public_wallet(self, db: sqlite3.Connection, creator_id: str):
        """Public-facing minimal wallet stats (for creator profile page)."""
        wallet = db.execute(
            """SELECT total_supporters, lifetime_donations, monthly_earnings
               FROM creator_wallets WHERE creator_id=?""",
            (creator_id,),
        ).fetchone()
        if wallet:
            self._json({
                "totalSupporters": wallet["total_supporters"],
                "lifetimeDonations": wallet["lifetime_donations"],
                "monthlyEarnings": wallet["monthly_earnings"],
            })
        else:
            self._json({"totalSupporters": 0, "lifetimeDonations": 0.0, "monthlyEarnings": 0.0})

    def _handle_creator_donations_list(self, db: sqlite3.Connection, user, qs: dict):
        page  = int(qs.get("page", 0))
        limit = min(int(qs.get("limit", 20)), 100)
        offset = page * limit

        total = db.execute(
            "SELECT COUNT(*) FROM donations WHERE creator_id=?", (user["id"],)
        ).fetchone()[0]

        rows = db.execute(
            """SELECT d.id, d.amount, d.platform_fee, d.creator_amount, d.message,
                      d.is_anonymous, d.status, d.transaction_id, d.created_at,
                      CASE WHEN d.is_anonymous=1 THEN 'Anonymous Supporter'
                           ELSE u.name END as donor_name,
                      CASE WHEN d.is_anonymous=1 THEN ''
                           ELSE u.avatar_url END as donor_avatar
               FROM donations d
               LEFT JOIN users u ON u.id = d.donor_id
               WHERE d.creator_id = ?
               ORDER BY d.created_at DESC LIMIT ? OFFSET ?""",
            (user["id"], limit, offset),
        ).fetchall()

        self._json({"items": [dict(r) for r in rows], "total": total, "page": page})

    def _handle_creator_payouts_list(self, db: sqlite3.Connection, user, qs: dict):
        page  = int(qs.get("page", 0))
        limit = min(int(qs.get("limit", 20)), 100)
        offset = page * limit

        total = db.execute(
            "SELECT COUNT(*) FROM payouts WHERE creator_id=?", (user["id"],)
        ).fetchone()[0]

        rows = db.execute(
            """SELECT * FROM payouts WHERE creator_id=?
               ORDER BY requested_at DESC LIMIT ? OFFSET ?""",
            (user["id"], limit, offset),
        ).fetchall()

        self._json({"items": [dict(r) for r in rows], "total": total, "page": page})

    def _handle_creator_payout_request(self, db: sqlite3.Connection, user):
        body = self._body()
        amount = float(body.get("amount", 0))

        MIN_PAYOUT = 500.0
        if amount < MIN_PAYOUT:
            self._error(f"Minimum payout is ₹{int(MIN_PAYOUT)}")
            return

        self._ensure_wallet(db, user["id"])
        db.commit()
        wallet = db.execute(
            "SELECT wallet_balance, payout_account FROM creator_wallets WHERE creator_id=?",
            (user["id"],),
        ).fetchone()

        if not wallet["payout_account"]:
            self._error("Please connect a payout account first")
            return
        if wallet["wallet_balance"] < amount:
            self._error(f"Insufficient balance. Available: ₹{wallet['wallet_balance']:.2f}")
            return

        # Check for pending payout already
        pending = db.execute(
            "SELECT id FROM payouts WHERE creator_id=? AND status='pending'", (user["id"],)
        ).fetchone()
        if pending:
            self._error("You already have a pending payout request")
            return

        payout_id = f"PAY_{secrets.token_hex(10).upper()}"
        now = utcnow()

        db.execute(
            """INSERT INTO payouts (id, creator_id, amount, status, requested_at)
               VALUES (?,?,?,'pending',?)""",
            (payout_id, user["id"], amount, now),
        )
        # Deduct from wallet balance into pending_payout
        db.execute(
            """UPDATE creator_wallets SET
                wallet_balance = wallet_balance - ?,
                pending_payout = pending_payout + ?,
                updated_at = ?
               WHERE creator_id = ?""",
            (amount, amount, now, user["id"]),
        )
        db.commit()
        self._json({"ok": True, "payoutId": payout_id, "status": "pending"})

    def _handle_creator_payout_account(self, db: sqlite3.Connection, user):
        body = self._body()
        account = str(body.get("payoutAccount", "")).strip()
        if not account:
            self._error("payoutAccount is required")
            return
        self._ensure_wallet(db, user["id"])
        db.execute(
            "UPDATE creator_wallets SET payout_account=?, updated_at=? WHERE creator_id=?",
            (account, utcnow(), user["id"]),
        )
        db.commit()
        self._json({"ok": True})

    # ---- Admin Donation Handlers ----

    def _handle_admin_donations(self, db: sqlite3.Connection, qs: dict):
        page  = int(qs.get("page", 0))
        limit = min(int(qs.get("limit", 30)), 100)
        offset = page * limit
        status = qs.get("status", "")

        cond = ""
        params: list = []
        if status:
            cond = "WHERE d.status=?"
            params.append(status)

        total = db.execute(f"SELECT COUNT(*) FROM donations d {cond}", params).fetchone()[0]

        rows = db.execute(
            f"""SELECT d.*, u.name as donor_name, c.name as creator_name
                FROM donations d
                LEFT JOIN users u ON u.id=d.donor_id
                JOIN users c ON c.id=d.creator_id
                {cond}
                ORDER BY d.created_at DESC LIMIT ? OFFSET ?""",
            params + [limit, offset],
        ).fetchall()

        # Platform summary
        summary = db.execute(
            """SELECT COALESCE(SUM(amount),0) as total_donations,
                      COALESCE(SUM(platform_fee),0) as total_revenue,
                      COUNT(*) as donation_count
               FROM donations WHERE status='completed'"""
        ).fetchone()

        self._json({
            "items": [dict(r) for r in rows],
            "total": total,
            "summary": dict(summary),
            "page": page,
        })

    def _handle_admin_payouts(self, db: sqlite3.Connection, qs: dict):
        page   = int(qs.get("page", 0))
        limit  = min(int(qs.get("limit", 30)), 100)
        offset = page * limit
        status = qs.get("status", "pending")

        total = db.execute(
            "SELECT COUNT(*) FROM payouts WHERE status=?", (status,)
        ).fetchone()[0]

        rows = db.execute(
            """SELECT p.*, u.name as creator_name, u.email as creator_email,
                      cw.payout_account
               FROM payouts p
               JOIN users u ON u.id=p.creator_id
               LEFT JOIN creator_wallets cw ON cw.creator_id=p.creator_id
               WHERE p.status=?
               ORDER BY p.requested_at DESC LIMIT ? OFFSET ?""",
            (status, limit, offset),
        ).fetchall()

        self._json({"items": [dict(r) for r in rows], "total": total, "page": page})

    def _handle_admin_payout_approve(self, db: sqlite3.Connection, payout_id: str):
        payout = db.execute(
            "SELECT * FROM payouts WHERE id=?", (payout_id,)
        ).fetchone()
        if not payout:
            self._error("Payout not found", 404)
            return
        if payout["status"] != "pending":
            self._error(f"Payout is already {payout['status']}")
            return

        now = utcnow()
        db.execute(
            "UPDATE payouts SET status='approved', approved_at=? WHERE id=?",
            (now, payout_id),
        )
        # In production, trigger actual bank transfer here (Razorpay Payouts API)
        db.execute(
            "UPDATE payouts SET status='paid', paid_at=? WHERE id=?",
            (now, payout_id),
        )
        # Clear pending_payout from wallet
        db.execute(
            """UPDATE creator_wallets SET
                pending_payout = pending_payout - ?,
                last_payout_date = ?,
                updated_at = ?
               WHERE creator_id = ?""",
            (payout["amount"], now, now, payout["creator_id"]),
        )
        # Notify creator
        db.execute(
            """INSERT INTO notifications (id, user_id, type, from_user_id, from_user_name,
               video_id, message, is_read, created_at)
               VALUES (?,?,'payout','','OFG Admin','',?,0,?)""",
            (secrets.token_hex(12), payout["creator_id"],
             f"Your payout of ₹{payout['amount']:.0f} has been approved and sent!",
             now),
        )
        db.commit()
        self._json({"ok": True, "status": "paid"})

    def _handle_admin_payout_reject(self, db: sqlite3.Connection, payout_id: str):
        body = self._body()
        reason = str(body.get("reason", "Rejected by admin")).strip()

        payout = db.execute(
            "SELECT * FROM payouts WHERE id=?", (payout_id,)
        ).fetchone()
        if not payout:
            self._error("Payout not found", 404)
            return
        if payout["status"] != "pending":
            self._error(f"Payout is already {payout['status']}")
            return

        now = utcnow()
        db.execute(
            "UPDATE payouts SET status='rejected', rejection_reason=? WHERE id=?",
            (reason, payout_id),
        )
        # Refund balance back to wallet
        db.execute(
            """UPDATE creator_wallets SET
                wallet_balance = wallet_balance + ?,
                pending_payout = pending_payout - ?,
                updated_at = ?
               WHERE creator_id = ?""",
            (payout["amount"], payout["amount"], now, payout["creator_id"]),
        )
        # Notify creator
        db.execute(
            """INSERT INTO notifications (id, user_id, type, from_user_id, from_user_name,
               video_id, message, is_read, created_at)
               VALUES (?,?,'payout','','OFG Admin','',?,0,?)""",
            (secrets.token_hex(12), payout["creator_id"],
             f"Your payout of ₹{payout['amount']:.0f} was rejected: {reason}",
             now),
        )
        db.commit()
        self._json({"ok": True, "status": "rejected"})


# ---------------------------------------------------------------------------
# Server entry point
# ---------------------------------------------------------------------------

def run():
    print("[OFG] Initializing database …")
    init_db()
    print(f"[OFG] OFG Connects server starting on http://{OFG_HOST}:{OFG_PORT}")
    server = ThreadingHTTPServer((OFG_HOST, OFG_PORT), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[OFG] Shutting down.")
        server.shutdown()


if __name__ == "__main__":
    run()