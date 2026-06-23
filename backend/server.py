#!/usr/bin/env python3
"""Local OFG Connects backend.

Runs a small HTTP API on the local PC with SQLite storage. No cloud services,
no Appwrite, and no third-party Python packages are required.
"""

from __future__ import annotations

import base64
import hashlib
import json
import mimetypes
import os
import re
import secrets
import sqlite3
import sys
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "ofg_local.db"
MEDIA_DIR = ROOT / "media"
HOST = os.environ.get("OFG_HOST", "0.0.0.0")
PORT = int(os.environ.get("OFG_PORT", "8787"))


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def open_db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def uid(prefix: str) -> str:
    return f"{prefix}_{uuid.uuid4().hex[:14]}"


def hash_password(password: str, salt: str | None = None) -> tuple[str, str]:
    salt = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt.encode("utf-8"), 120_000
    ).hex()
    return digest, salt


def verify_password(password: str, digest: str, salt: str) -> bool:
    actual, _ = hash_password(password, salt)
    return secrets.compare_digest(actual, digest)


def init_db() -> None:
    MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    with open_db() as db:
        db.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              handle TEXT NOT NULL,
              password_hash TEXT NOT NULL,
              salt TEXT NOT NULL,
              bio TEXT DEFAULT '',
              subscription TEXT DEFAULT 'Free',
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
              creator_id TEXT NOT NULL,
              creator_name TEXT NOT NULL,
              category TEXT NOT NULL,
              duration TEXT DEFAULT '12:04',
              views INTEGER DEFAULT 0,
              like_count INTEGER DEFAULT 0,
              comment_count INTEGER DEFAULT 0,
              thumbnail_label TEXT DEFAULT 'video 16:9',
              media_url TEXT DEFAULT '',
              is_live INTEGER DEFAULT 0,
              is_short INTEGER DEFAULT 0,
              progress REAL DEFAULT 0,
              created_at TEXT NOT NULL
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
              creator_id TEXT NOT NULL,
              created_at TEXT NOT NULL,
              PRIMARY KEY(follower_id, creator_id)
            );
            CREATE TABLE IF NOT EXISTS history (
              user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
              progress REAL DEFAULT 0,
              viewed_at TEXT NOT NULL,
              PRIMARY KEY(user_id, video_id)
            );
            CREATE TABLE IF NOT EXISTS comments (
              id TEXT PRIMARY KEY,
              video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
              user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              user_name TEXT NOT NULL,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS settings (
              user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              key TEXT NOT NULL,
              value TEXT NOT NULL,
              PRIMARY KEY(user_id, key)
            );
            """
        )
        seed(db)


def seed(db: sqlite3.Connection) -> None:
    count = db.execute("SELECT COUNT(*) AS c FROM users").fetchone()["c"]
    if count:
        return

    def add_user(user_id: str, name: str, email: str, password: str, handle: str) -> None:
        digest, salt = hash_password(password)
        db.execute(
            """
            INSERT INTO users(id, name, email, handle, password_hash, salt, bio, subscription, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
                name,
                email,
                handle,
                digest,
                salt,
                "Sharing faith, worship and teaching through OFG Connects.",
                "Pro" if email == "demo@ofg.local" else "Free",
                now_iso(),
            ),
        )

    creators = [
        ("u_demo", "Aria Kade", "demo@ofg.local", "password123", "@ariakade"),
        ("u_pastor", "Pastor David Cole", "pastor@ofg.local", "password123", "@pastorcole"),
        ("u_living", "Living Word", "living@ofg.local", "password123", "@livingword"),
        ("u_corner", "Cornerstone", "cornerstone@ofg.local", "password123", "@cornerstone"),
        ("u_grace", "Grace Chapel", "grace@ofg.local", "password123", "@gracechapel"),
        ("u_daily", "Daily Verse", "daily@ofg.local", "password123", "@dailyverse"),
    ]
    for item in creators:
        add_user(*item)

    videos = [
        ("v_grace", "Sunday Service - The Power of Grace", "A message on grace and walking in faith recorded live at Sunday service.", "u_pastor", "Pastor David Cole", "sermons", "58:10", 2100000, 24000, 842, "service still 16:9", 0, 0, 0.62),
        ("v_psalm23", "Morning Devotion: Psalm 23", "A quiet devotion for the start of the day.", "u_living", "Living Word", "worship", "14:08", 1100000, 14800, 420, "thumb", 0, 0, 0.70),
        ("v_hymns", "Worship Night - Hymns of Hope", "A full worship night with hymns and prayer.", "u_corner", "Cornerstone", "music", "1:12:00", 880000, 20200, 588, "worship still 16:9", 0, 0, 0.40),
        ("v_testimony", "Testimony: From Darkness to Light", "A story of hope, restoration and faith.", "u_grace", "Grace Chapel", "sermons", "24:44", 410000, 9800, 312, "thumb", 0, 0, 0.30),
        ("v_live", "Sunday Service - Live", "Live worship and sermon from Grace Chapel.", "u_grace", "Grace Chapel", "live", "LIVE", 12400, 2400, 151, "service live", 1, 0, 0),
        ("v_prayer", "24/7 Worship and Prayer", "Continuous worship and prayer stream.", "u_corner", "Cornerstone", "live", "LIVE", 8100, 1800, 92, "worship live", 1, 0, 0),
        ("v_bible", "Evening Bible Study", "Verse-by-verse study and discussion.", "u_living", "Living Word", "live", "LIVE", 5600, 900, 65, "study live", 1, 0, 0),
        ("v_kids", "Kids Bible Adventure", "A fun lesson for children and families.", "u_grace", "Grace Chapel", "kids", "18:20", 240000, 5200, 188, "video 16:9", 0, 0, 0),
        ("v_song", "Sunday Worship Playlist", "A set of songs for prayer and reflection.", "u_corner", "Cornerstone", "music", "18 songs", 320000, 7600, 84, "album art", 0, 0, 0),
        ("s_daily", "Daily Verse", "I can do all things through Christ - Philippians 4:13", "u_daily", "@dailyverse", "shorts", "0:42", 128000, 128000, 2400, "short 9:16", 0, 1, 0),
        ("s_faith", "Faith Fuel", "A 60-second reminder that God is with you today.", "u_living", "@faithfuel", "shorts", "0:58", 89000, 89000, 1100, "short 9:16", 0, 1, 0),
        ("s_worship", "Worship Moment", "Lift your voice - He is worthy of all our praise.", "u_corner", "@worshipmoments", "shorts", "0:47", 342000, 342000, 5800, "short 9:16", 0, 1, 0),
        ("s_grace", "Behind Sunday Worship", "Behind the scenes of Sunday worship.", "u_grace", "@gracechapel", "shorts", "0:36", 56000, 56000, 820, "short 9:16", 0, 1, 0),
    ]
    db.executemany(
        """
        INSERT INTO videos(id, title, description, creator_id, creator_name, category, duration, views,
          like_count, comment_count, thumbnail_label, is_live, is_short, progress, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        [(*v, now_iso()) for v in videos],
    )
    db.executemany(
        """
        INSERT INTO comments(id, video_id, user_id, user_name, content, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        [
            ("c_1", "v_grace", "u_demo", "Aria Kade", "This message was exactly what I needed today.", now_iso()),
            ("c_2", "v_grace", "u_corner", "Cornerstone", "Amen. Powerful word.", now_iso()),
        ],
    )
    db.commit()


def row_to_user(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "name": row["name"],
        "email": row["email"],
        "handle": row["handle"],
        "bio": row["bio"],
        "subscription": row["subscription"],
    }


def video_to_json(db: sqlite3.Connection, row: sqlite3.Row, user_id: str | None) -> dict[str, Any]:
    liked = saved = following = False
    if user_id:
        liked = (
            db.execute(
                "SELECT 1 FROM likes WHERE user_id = ? AND video_id = ?",
                (user_id, row["id"]),
            ).fetchone()
            is not None
        )
        saved = (
            db.execute(
                "SELECT 1 FROM saves WHERE user_id = ? AND video_id = ?",
                (user_id, row["id"]),
            ).fetchone()
            is not None
        )
        following = (
            db.execute(
                "SELECT 1 FROM follows WHERE follower_id = ? AND creator_id = ?",
                (user_id, row["creator_id"]),
            ).fetchone()
            is not None
        )
    meta = f"{format_count(row['views'])} views"
    return {
        "id": row["id"],
        "title": row["title"],
        "creator": row["creator_name"],
        "creatorId": row["creator_id"],
        "category": row["category"],
        "duration": row["duration"],
        "meta": meta,
        "description": row["description"],
        "label": row["thumbnail_label"],
        "views": row["views"],
        "likes": row["like_count"],
        "comments": row["comment_count"],
        "isLive": bool(row["is_live"]),
        "isShort": bool(row["is_short"]),
        "progress": row["progress"],
        "liked": liked,
        "saved": saved,
        "following": following,
        "mediaUrl": row["media_url"],
    }


def format_count(value: int) -> str:
    if value >= 1_000_000:
        return f"{value / 1_000_000:.1f}M"
    if value >= 1_000:
        return f"{value / 1_000:.1f}K"
    return str(value)


class Handler(BaseHTTPRequestHandler):
    server_version = "OFGLocal/1.0"

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._headers()
        self.end_headers()

    def do_GET(self) -> None:
        self._dispatch("GET")

    def do_POST(self) -> None:
        self._dispatch("POST")

    def log_message(self, fmt: str, *args: Any) -> None:
        sys.stdout.write("[%s] %s\n" % (self.log_date_time_string(), fmt % args))

    def _dispatch(self, method: str) -> None:
        try:
            parsed = urlparse(self.path)
            path = parsed.path.rstrip("/") or "/"
            query = parse_qs(parsed.query)
            body = self._json_body() if method == "POST" else {}
            with open_db() as db:
                user = self._current_user(db)
                if method == "GET" and path == "/health":
                    return self._json({"ok": True, "service": "ofg-local", "time": now_iso()})
                if method == "POST" and path == "/auth/register":
                    return self._register(db, body)
                if method == "POST" and path == "/auth/login":
                    return self._login(db, body)
                if method == "GET" and path == "/me":
                    return self._require_user(user, lambda: self._json({"user": row_to_user(user)}))
                if method == "GET" and path == "/videos":
                    return self._videos(db, user, query, shorts=False)
                if method == "GET" and path == "/shorts":
                    return self._videos(db, user, query, shorts=True)
                if method == "GET" and path == "/search":
                    return self._search(db, user, query)
                if method == "GET" and path == "/library":
                    return self._require_user(user, lambda: self._library(db, user["id"]))
                if method == "GET" and path == "/settings":
                    return self._require_user(user, lambda: self._settings_get(db, user["id"]))
                if method == "POST" and path == "/settings":
                    return self._require_user(user, lambda: self._settings_post(db, user["id"], body))
                if method == "GET" and path == "/creator/stats":
                    return self._require_user(user, lambda: self._creator_stats(db, user["id"]))
                if method == "POST" and path == "/upload":
                    return self._require_user(user, lambda: self._upload(db, user, body))
                if method == "GET" and path == "/comments":
                    return self._comments_get(db, query)
                if method == "POST" and path == "/comments":
                    return self._require_user(user, lambda: self._comments_post(db, user, body))
                if path.startswith("/media/") and method == "GET":
                    return self._serve_media(path)

                match = re.match(r"^/videos/([^/]+)$", path)
                if method == "GET" and match:
                    return self._video_detail(db, user, match.group(1))
                match = re.match(r"^/videos/([^/]+)/(like|save|follow|view)$", path)
                if method == "POST" and match:
                    return self._require_user(
                        user,
                        lambda: self._video_action(db, user["id"], match.group(1), match.group(2), body),
                    )
                return self._error(404, "Route not found")
        except ApiError as exc:
            return self._error(exc.status, exc.message)
        except Exception as exc:
            return self._error(500, f"Internal error: {exc}")

    def _headers(self, content_type: str = "application/json") -> None:
        self.send_header("Content-Type", content_type)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def _json(self, payload: Any, status: int = 200) -> None:
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self._headers()
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _error(self, status: int, message: str) -> None:
        self._json({"error": message}, status)

    def _json_body(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0") or 0)
        if not length:
            return {}
        raw = self.rfile.read(length).decode("utf-8")
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise ApiError(400, f"Invalid JSON: {exc}")
        if not isinstance(payload, dict):
            raise ApiError(400, "JSON body must be an object")
        return payload

    def _current_user(self, db: sqlite3.Connection) -> sqlite3.Row | None:
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return None
        token = auth.removeprefix("Bearer ").strip()
        return db.execute(
            """
            SELECT users.* FROM sessions
            JOIN users ON users.id = sessions.user_id
            WHERE sessions.token = ?
            """,
            (token,),
        ).fetchone()

    def _require_user(self, user: sqlite3.Row | None, callback: Any) -> None:
        if user is None:
            raise ApiError(401, "Sign in required")
        return callback()

    def _register(self, db: sqlite3.Connection, body: dict[str, Any]) -> None:
        name = str(body.get("name", "")).strip() or "OFG User"
        email = str(body.get("email", "")).strip().lower()
        password = str(body.get("password", ""))
        if not email or "@" not in email:
            raise ApiError(400, "Valid email required")
        if len(password) < 6:
            raise ApiError(400, "Password must be at least 6 characters")
        digest, salt = hash_password(password)
        user_id = uid("u")
        handle = "@" + re.sub(r"[^a-z0-9]+", "", email.split("@")[0].lower())[:20]
        try:
            db.execute(
                """
                INSERT INTO users(id, name, email, handle, password_hash, salt, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (user_id, name, email, handle, digest, salt, now_iso()),
            )
        except sqlite3.IntegrityError:
            raise ApiError(409, "Email is already registered")
        db.commit()
        user = db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        self._session_response(db, user)

    def _login(self, db: sqlite3.Connection, body: dict[str, Any]) -> None:
        email = str(body.get("email", "")).strip().lower()
        password = str(body.get("password", ""))
        user = db.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
        if not user or not verify_password(password, user["password_hash"], user["salt"]):
            raise ApiError(401, "Email or password is incorrect")
        self._session_response(db, user)

    def _session_response(self, db: sqlite3.Connection, user: sqlite3.Row) -> None:
        token = secrets.token_urlsafe(32)
        db.execute(
            "INSERT INTO sessions(token, user_id, created_at) VALUES (?, ?, ?)",
            (token, user["id"], now_iso()),
        )
        db.commit()
        self._json({"token": token, "user": row_to_user(user)})

    def _videos(self, db: sqlite3.Connection, user: sqlite3.Row | None, query: dict[str, list[str]], shorts: bool) -> None:
        category = (query.get("category") or [""])[0].lower()
        clauses = ["is_short = ?"]
        args: list[Any] = [1 if shorts else 0]
        if category:
            clauses.append("category = ?")
            args.append(category)
        rows = db.execute(
            f"SELECT * FROM videos WHERE {' AND '.join(clauses)} ORDER BY is_live DESC, created_at DESC",
            args,
        ).fetchall()
        self._json({"items": [video_to_json(db, row, user["id"] if user else None) for row in rows]})

    def _video_detail(self, db: sqlite3.Connection, user: sqlite3.Row | None, video_id: str) -> None:
        row = db.execute("SELECT * FROM videos WHERE id = ?", (video_id,)).fetchone()
        if not row:
            raise ApiError(404, "Video not found")
        self._json({"item": video_to_json(db, row, user["id"] if user else None)})

    def _search(self, db: sqlite3.Connection, user: sqlite3.Row | None, query: dict[str, list[str]]) -> None:
        q = (query.get("q") or [""])[0].strip().lower()
        if not q:
            return self._json({"items": []})
        rows = db.execute(
            """
            SELECT * FROM videos
            WHERE lower(title) LIKE ? OR lower(description) LIKE ? OR lower(creator_name) LIKE ? OR lower(category) LIKE ?
            ORDER BY views DESC LIMIT 30
            """,
            tuple([f"%{q}%"] * 4),
        ).fetchall()
        self._json({"items": [video_to_json(db, row, user["id"] if user else None) for row in rows]})

    def _video_action(self, db: sqlite3.Connection, user_id: str, video_id: str, action: str, body: dict[str, Any]) -> None:
        row = db.execute("SELECT * FROM videos WHERE id = ?", (video_id,)).fetchone()
        if not row:
            raise ApiError(404, "Video not found")
        if action == "like":
            existing = db.execute(
                "SELECT 1 FROM likes WHERE user_id = ? AND video_id = ?",
                (user_id, video_id),
            ).fetchone()
            if existing:
                db.execute("DELETE FROM likes WHERE user_id = ? AND video_id = ?", (user_id, video_id))
                db.execute("UPDATE videos SET like_count = MAX(like_count - 1, 0) WHERE id = ?", (video_id,))
            else:
                db.execute("INSERT INTO likes(user_id, video_id, created_at) VALUES (?, ?, ?)", (user_id, video_id, now_iso()))
                db.execute("UPDATE videos SET like_count = like_count + 1 WHERE id = ?", (video_id,))
        elif action == "save":
            existing = db.execute(
                "SELECT 1 FROM saves WHERE user_id = ? AND video_id = ?",
                (user_id, video_id),
            ).fetchone()
            if existing:
                db.execute("DELETE FROM saves WHERE user_id = ? AND video_id = ?", (user_id, video_id))
            else:
                db.execute("INSERT INTO saves(user_id, video_id, created_at) VALUES (?, ?, ?)", (user_id, video_id, now_iso()))
        elif action == "follow":
            creator_id = row["creator_id"]
            existing = db.execute(
                "SELECT 1 FROM follows WHERE follower_id = ? AND creator_id = ?",
                (user_id, creator_id),
            ).fetchone()
            if existing:
                db.execute("DELETE FROM follows WHERE follower_id = ? AND creator_id = ?", (user_id, creator_id))
            else:
                db.execute("INSERT INTO follows(follower_id, creator_id, created_at) VALUES (?, ?, ?)", (user_id, creator_id, now_iso()))
        elif action == "view":
            progress = float(body.get("progress", 0.1) or 0.1)
            db.execute("UPDATE videos SET views = views + 1 WHERE id = ?", (video_id,))
            db.execute(
                """
                INSERT INTO history(user_id, video_id, progress, viewed_at) VALUES (?, ?, ?, ?)
                ON CONFLICT(user_id, video_id) DO UPDATE SET progress = excluded.progress, viewed_at = excluded.viewed_at
                """,
                (user_id, video_id, progress, now_iso()),
            )
        db.commit()
        next_row = db.execute("SELECT * FROM videos WHERE id = ?", (video_id,)).fetchone()
        self._json({"item": video_to_json(db, next_row, user_id)})

    def _library(self, db: sqlite3.Connection, user_id: str) -> None:
        history = db.execute(
            """
            SELECT videos.*, history.progress AS h_progress FROM history
            JOIN videos ON videos.id = history.video_id
            WHERE history.user_id = ?
            ORDER BY history.viewed_at DESC
            """,
            (user_id,),
        ).fetchall()
        saved = db.execute(
            """
            SELECT videos.* FROM saves
            JOIN videos ON videos.id = saves.video_id
            WHERE saves.user_id = ?
            ORDER BY saves.created_at DESC
            """,
            (user_id,),
        ).fetchall()
        self._json(
            {
                "history": [video_to_json(db, row, user_id) for row in history],
                "saved": [video_to_json(db, row, user_id) for row in saved],
            }
        )

    def _comments_get(self, db: sqlite3.Connection, query: dict[str, list[str]]) -> None:
        video_id = (query.get("videoId") or [""])[0]
        rows = db.execute(
            "SELECT * FROM comments WHERE video_id = ? ORDER BY created_at DESC",
            (video_id,),
        ).fetchall()
        self._json(
            {
                "items": [
                    {
                        "id": row["id"],
                        "user": row["user_name"],
                        "content": row["content"],
                        "when": "local",
                    }
                    for row in rows
                ]
            }
        )

    def _comments_post(self, db: sqlite3.Connection, user: sqlite3.Row, body: dict[str, Any]) -> None:
        video_id = str(body.get("videoId", ""))
        content = str(body.get("content", "")).strip()
        if not video_id or not content:
            raise ApiError(400, "videoId and content are required")
        db.execute(
            "INSERT INTO comments(id, video_id, user_id, user_name, content, created_at) VALUES (?, ?, ?, ?, ?, ?)",
            (uid("c"), video_id, user["id"], user["name"], content, now_iso()),
        )
        db.execute("UPDATE videos SET comment_count = comment_count + 1 WHERE id = ?", (video_id,))
        db.commit()
        self._json({"ok": True})

    def _settings_get(self, db: sqlite3.Connection, user_id: str) -> None:
        rows = db.execute("SELECT key, value FROM settings WHERE user_id = ?", (user_id,)).fetchall()
        values = {row["key"]: row["value"] == "true" for row in rows}
        defaults = {"autoplay": True, "wifi": True, "push": True, "dark": True, "private": False}
        defaults.update(values)
        self._json(defaults)

    def _settings_post(self, db: sqlite3.Connection, user_id: str, body: dict[str, Any]) -> None:
        for key, value in body.items():
            if key not in {"autoplay", "wifi", "push", "dark", "private"}:
                continue
            db.execute(
                """
                INSERT INTO settings(user_id, key, value) VALUES (?, ?, ?)
                ON CONFLICT(user_id, key) DO UPDATE SET value = excluded.value
                """,
                (user_id, key, "true" if value else "false"),
            )
        db.commit()
        self._settings_get(db, user_id)

    def _creator_stats(self, db: sqlite3.Connection, user_id: str) -> None:
        row = db.execute(
            "SELECT COUNT(*) AS videos, COALESCE(SUM(views), 0) AS views, COALESCE(SUM(like_count), 0) AS likes FROM videos WHERE creator_id = ?",
            (user_id,),
        ).fetchone()
        self._json({"videos": row["videos"], "views": row["views"], "likes": row["likes"]})

    def _upload(self, db: sqlite3.Connection, user: sqlite3.Row, body: dict[str, Any]) -> None:
        title = str(body.get("title", "")).strip()
        if not title:
            raise ApiError(400, "Title is required")
        description = str(body.get("description", "")).strip()
        category = str(body.get("category", "sermons")).strip().lower()
        media_url = ""
        media_b64 = body.get("mediaBase64")
        filename = str(body.get("filename", "upload.bin"))
        if media_b64:
            safe = re.sub(r"[^a-zA-Z0-9_.-]", "_", filename)
            media_id = f"{uid('media')}_{safe}"
            (MEDIA_DIR / media_id).write_bytes(base64.b64decode(media_b64))
            media_url = f"/media/{media_id}"
        video_id = uid("v")
        is_short = 1 if category == "shorts" else 0
        db.execute(
            """
            INSERT INTO videos(id, title, description, creator_id, creator_name, category, duration, views,
              like_count, comment_count, thumbnail_label, media_url, is_live, is_short, progress, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, 0, ?, ?, 0, ?, 0, ?)
            """,
            (
                video_id,
                title,
                description or "Local upload saved on this PC.",
                user["id"],
                user["name"],
                category,
                "0:59" if is_short else "12:04",
                "short 9:16" if is_short else "video 16:9",
                media_url,
                is_short,
                now_iso(),
            ),
        )
        db.commit()
        row = db.execute("SELECT * FROM videos WHERE id = ?", (video_id,)).fetchone()
        self._json({"item": video_to_json(db, row, user["id"])}, 201)

    def _serve_media(self, path: str) -> None:
        name = Path(path).name
        target = MEDIA_DIR / name
        if not target.exists() or not target.is_file():
            raise ApiError(404, "Media not found")
        data = target.read_bytes()
        self.send_response(200)
        self._headers(mimetypes.guess_type(target.name)[0] or "application/octet-stream")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


class ApiError(Exception):
    def __init__(self, status: int, message: str) -> None:
        super().__init__(message)
        self.status = status
        self.message = message


def main() -> int:
    init_db()
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"OFG local backend running on http://{HOST}:{PORT}")
    print(f"SQLite database: {DB_PATH}")
    print("Demo login: demo@ofg.local / password123")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping OFG local backend")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
