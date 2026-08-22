# -*- coding: utf-8 -*-
"""
DSH 插件小卖部 · 后端服务
FastAPI + SQLite：注册登录（session cookie）、访问统计、插件数据、管理后台 API。
生产环境由 Caddy 反代 /dsh-plugin/api/* 到本服务；本地开发时本服务也直接托管静态文件。
"""
import hashlib
import json
import os
import re
import secrets
import sqlite3
import time
from contextlib import contextmanager
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, Request, Response, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

BASE_DIR = Path(__file__).resolve().parent          # dsh-plugin/api
PLUGIN_DIR = BASE_DIR.parent                        # dsh-plugin
PROJECT_ROOT = PLUGIN_DIR.parent                    # 项目根
DB_PATH = Path(os.environ.get("DSH_DB", str(BASE_DIR / "data.db")))
SEED_JSON = PLUGIN_DIR / "plugins.json"
SESSION_TTL = 60 * 60 * 24 * 30                     # 30 天
COOKIE_SECURE = os.environ.get("DSH_COOKIE_SECURE", "0") == "1"
ADMIN_USER = os.environ.get("DSH_ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("DSH_ADMIN_PASSWORD", "")

app = FastAPI(title="DSH Plugin Market API",
              docs_url="/dsh-plugin/api/docs",
              openapi_url="/dsh-plugin/api/openapi.json")

# ---------- 数据库 ----------

@contextmanager
def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()

def hash_password(pwd):
    salt = secrets.token_hex(16)
    h = hashlib.pbkdf2_hmac("sha256", pwd.encode(), salt.encode(), 100_000).hex()
    return salt + "$" + h

def verify_password(pwd, stored):
    try:
        salt, h = stored.split("$", 1)
    except ValueError:
        return False
    cand = hashlib.pbkdf2_hmac("sha256", pwd.encode(), salt.encode(), 100_000).hex()
    return secrets.compare_digest(cand, h)

def init_db():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with db() as conn:
        conn.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            is_admin INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            last_login_at INTEGER
        );
        CREATE TABLE IF NOT EXISTS sessions (
            token TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            expires_at INTEGER NOT NULL
        );
        CREATE TABLE IF NOT EXISTS page_views (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts INTEGER NOT NULL,
            path TEXT NOT NULL,
            vid TEXT,
            ip_hash TEXT,
            ua TEXT,
            ref TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_pv_ts ON page_views(ts);
        CREATE INDEX IF NOT EXISTS idx_pv_path ON page_views(path);
        CREATE TABLE IF NOT EXISTS plugins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            repo TEXT UNIQUE NOT NULL,
            desc TEXT NOT NULL DEFAULT '',
            cat TEXT NOT NULL DEFAULT '其他',
            stars INTEGER NOT NULL DEFAULT 0,
            tested INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'on',
            featured INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        );
        """)
        # 兼容旧库：给已有 plugins 表补 featured 列
        cols = [c[1] for c in conn.execute("PRAGMA table_info(plugins)").fetchall()]
        if "featured" not in cols:
            conn.execute("ALTER TABLE plugins ADD COLUMN featured INTEGER NOT NULL DEFAULT 0")
        # 兼容旧库：users 表补 is_admin 已存在；page_views 无需补
        cnt = conn.execute("SELECT COUNT(*) FROM plugins").fetchone()[0]
        if cnt == 0 and SEED_JSON.exists():
            rows = json.loads(SEED_JSON.read_text(encoding="utf-8"))
            now = int(time.time())
            conn.executemany(
                "INSERT OR IGNORE INTO plugins (name, repo, desc, cat, stars, tested, status, featured, created_at, updated_at)"
                " VALUES (?,?,?,?,?,0,'on',?,?,?)",
                [(p["n"], p["r"], p["d"], p["c"], p.get("s", 0), 1 if p.get("f") else 0, now, now) for p in rows])
            print("[init] 已导入插件种子数据:", len(rows), "条")
        ucnt = conn.execute("SELECT COUNT(*) FROM users").fetchone()[0]
        if ucnt == 0:
            pwd = ADMIN_PASSWORD or secrets.token_urlsafe(10)
            conn.execute(
                "INSERT INTO users (username, password_hash, is_admin, created_at) VALUES (?,?,1,?)",
                (ADMIN_USER, hash_password(pwd), int(time.time())))
            print("[init] 已创建管理员账号 %r，初始密码: %s （请尽快登录后修改）" % (ADMIN_USER, pwd))

# ---------- session ----------

def create_session(user_id):
    token = secrets.token_urlsafe(32)
    now = int(time.time())
    with db() as conn:
        conn.execute("INSERT INTO sessions (token, user_id, created_at, expires_at) VALUES (?,?,?,?)",
                     (token, user_id, now, now + SESSION_TTL))
    return token

def get_session_user(request):
    token = request.cookies.get("dsh_session")
    if not token:
        return None
    now = int(time.time())
    with db() as conn:
        row = conn.execute(
            "SELECT u.id, u.username, u.is_admin FROM sessions s JOIN users u ON u.id = s.user_id"
            " WHERE s.token = ? AND s.expires_at > ?", (token, now)).fetchone()
    return dict(row) if row else None

def require_admin(request):
    user = get_session_user(request)
    if not user or not user["is_admin"]:
        raise HTTPException(403, "需要管理员权限")
    return user

def set_session_cookie(resp, token):
    resp.set_cookie("dsh_session", token, max_age=SESSION_TTL, httponly=True,
                    samesite="lax", path="/dsh-plugin", secure=COOKIE_SECURE)

# ---------- 请求体 ----------

class AuthBody(BaseModel):
    username: str = Field(min_length=2, max_length=24)
    password: str = Field(min_length=6, max_length=72)

class TrackBody(BaseModel):
    path: str = Field(max_length=200)
    vid: str = Field(default="", max_length=64)
    ref: str = Field(default="", max_length=300)

class PluginPatch(BaseModel):
    name: Optional[str] = None
    desc: Optional[str] = None
    cat: Optional[str] = None
    stars: Optional[int] = None
    tested: Optional[bool] = None
    status: Optional[str] = None
    featured: Optional[bool] = None

class PluginCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    repo: str = Field(min_length=4, max_length=300)
    desc: str = Field(default="", max_length=500)
    cat: str = Field(default="其他", max_length=30)
    stars: int = 0
    tested: bool = False
    featured: bool = False

# ---------- 认证 API ----------

USERNAME_RE = re.compile(r"^[\w\u4e00-\u9fa5-]{2,24}$")

# 简单限流：每 IP 每分钟最多 10 次认证尝试（内存实现，重启清零，MVP 够用）
_auth_attempts = {}

def rate_limit_auth(request):
    ip = client_ip(request)
    now = time.time()
    bucket = [t for t in _auth_attempts.get(ip, []) if now - t < 60]
    if len(bucket) >= 10:
        raise HTTPException(429, "尝试太频繁了，歇一分钟再来")
    bucket.append(now)
    _auth_attempts[ip] = bucket

@app.post("/dsh-plugin/api/register")
def register(request: Request, body: AuthBody, response: Response):
    rate_limit_auth(request)
    if not USERNAME_RE.match(body.username):
        raise HTTPException(400, "用户名仅限中英文、数字、下划线，2~24 位")
    with db() as conn:
        exists = conn.execute("SELECT 1 FROM users WHERE username = ?", (body.username,)).fetchone()
        if exists:
            raise HTTPException(409, "用户名已被占用")
        now = int(time.time())
        uid = conn.execute(
            "INSERT INTO users (username, password_hash, is_admin, created_at, last_login_at) VALUES (?,?,0,?,?)",
            (body.username, hash_password(body.password), now, now)).lastrowid
    token = create_session(uid)
    set_session_cookie(response, token)
    return {"ok": True, "username": body.username, "is_admin": False}

@app.post("/dsh-plugin/api/login")
def login(request: Request, body: AuthBody, response: Response):
    rate_limit_auth(request)
    with db() as conn:
        row = conn.execute("SELECT * FROM users WHERE username = ?", (body.username,)).fetchone()
        if not row or not verify_password(body.password, row["password_hash"]):
            raise HTTPException(401, "用户名或密码不对")
        conn.execute("UPDATE users SET last_login_at = ? WHERE id = ?", (int(time.time()), row["id"]))
    token = create_session(row["id"])
    set_session_cookie(response, token)
    return {"ok": True, "username": row["username"], "is_admin": bool(row["is_admin"])}

@app.post("/dsh-plugin/api/logout")
def logout(request: Request, response: Response):
    token = request.cookies.get("dsh_session")
    if token:
        with db() as conn:
            conn.execute("DELETE FROM sessions WHERE token = ?", (token,))
    response.delete_cookie("dsh_session", path="/dsh-plugin")
    return {"ok": True}

@app.get("/dsh-plugin/api/me")
def me(request: Request):
    user = get_session_user(request)
    if not user:
        return {"logged_in": False}
    return {"logged_in": True, "username": user["username"], "is_admin": bool(user["is_admin"])}

# ---------- 访问统计 ----------

def client_ip(request):
    fwd = request.headers.get("x-forwarded-for")
    if fwd:
        return fwd.split(",")[0].strip()
    return request.client.host if request.client else ""

@app.post("/dsh-plugin/api/track")
def track(body: TrackBody, request: Request):
    ip = client_ip(request)
    ip_hash = hashlib.sha256(("dsh-salt:" + ip).encode()).hexdigest()[:16] if ip else ""
    ua = request.headers.get("user-agent", "")[:200]
    path = body.path if body.path.startswith("/") else "/" + body.path
    with db() as conn:
        conn.execute("INSERT INTO page_views (ts, path, vid, ip_hash, ua, ref) VALUES (?,?,?,?,?,?)",
                     (int(time.time()), path[:200], body.vid[:64], ip_hash, ua, body.ref[:300]))
    return {"ok": True}

# ---------- 插件 API ----------

def plugin_json(r):
    return {"id": r["id"], "n": r["name"], "r": r["repo"], "d": r["desc"],
            "c": r["cat"], "s": r["stars"], "t": bool(r["tested"]), "f": bool(r["featured"])}

@app.get("/dsh-plugin/api/plugins")
def list_plugins():
    with db() as conn:
        rows = conn.execute(
            "SELECT * FROM plugins WHERE status = 'on' ORDER BY stars DESC, name ASC").fetchall()
    return [plugin_json(r) for r in rows]

# ---------- 管理后台 API ----------

@app.get("/dsh-plugin/api/admin/stats")
def admin_stats(request: Request):
    require_admin(request)
    now = int(time.time())
    lt = time.localtime(now)
    day_start = int(time.mktime((lt.tm_year, lt.tm_mon, lt.tm_mday, 0, 0, 0, 0, 0, -1)))
    week_start = day_start - 6 * 86400
    month_start = day_start - 29 * 86400
    with db() as conn:
        def pv_uv_since(ts):
            row = conn.execute(
                "SELECT COUNT(*) pv, COUNT(DISTINCT COALESCE(NULLIF(vid,''), ip_hash)) uv"
                " FROM page_views WHERE ts >= ?", (ts,)).fetchone()
            return row["pv"], row["uv"]
        today_pv, today_uv = pv_uv_since(day_start)
        week_pv, week_uv = pv_uv_since(week_start)
        month_pv, month_uv = pv_uv_since(month_start)
        total_pv, _ = pv_uv_since(0)
        daily = []
        rows = conn.execute(
            "SELECT (ts - ?) / 86400 d, COUNT(*) pv, COUNT(DISTINCT COALESCE(NULLIF(vid,''), ip_hash)) uv"
            " FROM page_views WHERE ts >= ? GROUP BY d", (month_start, month_start)).fetchall()
        by_day = {r["d"]: (r["pv"], r["uv"]) for r in rows}
        for i in range(30):
            d = month_start + i * 86400
            pv, uv = by_day.get(i, (0, 0))
            daily.append({"date": time.strftime("%m-%d", time.localtime(d)), "pv": pv, "uv": uv})
        top_pages = [dict(r) for r in conn.execute(
            "SELECT path, COUNT(*) pv, COUNT(DISTINCT COALESCE(NULLIF(vid,''), ip_hash)) uv"
            " FROM page_views WHERE ts >= ? GROUP BY path ORDER BY pv DESC LIMIT 10",
            (month_start,)).fetchall()]
        total_users = conn.execute("SELECT COUNT(*) FROM users").fetchone()[0]
        pc = conn.execute("SELECT COUNT(*) total, COALESCE(SUM(status='on'),0) on_cnt FROM plugins").fetchone()
    return {
        "today": {"pv": today_pv, "uv": today_uv},
        "week": {"pv": week_pv, "uv": week_uv},
        "month": {"pv": month_pv, "uv": month_uv},
        "total_pv": total_pv,
        "daily": daily,
        "top_pages": top_pages,
        "total_users": total_users,
        "plugins": {"total": pc["total"], "on": pc["on_cnt"]},
    }

@app.get("/dsh-plugin/api/admin/users")
def admin_users(request: Request):
    require_admin(request)
    with db() as conn:
        rows = conn.execute(
            "SELECT id, username, is_admin, created_at, last_login_at FROM users ORDER BY id DESC LIMIT 500"
        ).fetchall()
    return [dict(r) for r in rows]

@app.get("/dsh-plugin/api/admin/plugins")
def admin_plugins(request: Request):
    require_admin(request)
    with db() as conn:
        rows = conn.execute("SELECT * FROM plugins ORDER BY stars DESC, name ASC").fetchall()
    return [dict(r) for r in rows]

@app.patch("/dsh-plugin/api/admin/plugins/{pid}")
def admin_patch_plugin(pid: int, body: PluginPatch, request: Request):
    require_admin(request)
    fields, vals = [], []
    for k in ("name", "desc", "cat", "stars"):
        v = getattr(body, k)
        if v is not None:
            fields.append(k + " = ?"); vals.append(v)
    if body.tested is not None:
        fields.append("tested = ?"); vals.append(1 if body.tested else 0)
    if body.featured is not None:
        fields.append("featured = ?"); vals.append(1 if body.featured else 0)
    if body.status is not None:
        if body.status not in ("on", "off"):
            raise HTTPException(400, "status 只能是 on / off")
        fields.append("status = ?"); vals.append(body.status)
    if not fields:
        raise HTTPException(400, "没有要修改的字段")
    fields.append("updated_at = ?"); vals.append(int(time.time()))
    vals.append(pid)
    with db() as conn:
        cur = conn.execute("UPDATE plugins SET " + ", ".join(fields) + " WHERE id = ?", vals)
        if cur.rowcount == 0:
            raise HTTPException(404, "插件不存在")
    return {"ok": True}

@app.post("/dsh-plugin/api/admin/plugins")
def admin_create_plugin(body: PluginCreate, request: Request):
    require_admin(request)
    now = int(time.time())
    with db() as conn:
        try:
            pid = conn.execute(
                "INSERT INTO plugins (name, repo, desc, cat, stars, tested, status, featured, created_at, updated_at)"
                " VALUES (?,?,?,?,?,?,'on',?,?,?)",
                (body.name, body.repo, body.desc, body.cat, body.stars,
                 1 if body.tested else 0, 1 if body.featured else 0, now, now)).lastrowid
        except sqlite3.IntegrityError:
            raise HTTPException(409, "这个仓库地址已存在")
    return {"ok": True, "id": pid}

@app.delete("/dsh-plugin/api/admin/plugins/{pid}")
def admin_delete_plugin(pid: int, request: Request):
    require_admin(request)
    with db() as conn:
        cur = conn.execute("DELETE FROM plugins WHERE id = ?", (pid,))
        if cur.rowcount == 0:
            raise HTTPException(404, "插件不存在")
    return {"ok": True}

def _friendly_validation_error(exc):
    """把 pydantic 校验错误转成人话"""
    for err in exc.errors():
        loc = err.get("loc", ())
        field = loc[-1] if loc else "参数"
        field_cn = {"username": "用户名", "password": "密码"}.get(field, field)
        etype = err.get("type", "")
        if etype == "string_too_short":
            limit = err.get("ctx", {}).get("min_length", 0)
            if field == "username":
                return f"用户名至少 {limit} 个字符"
            if field == "password":
                return f"密码至少 {limit} 位"
            return f"{field_cn}太短了"
        if etype == "string_too_long":
            return f"{field_cn}太长了"
        if etype == "missing":
            return f"请填写{field_cn}"
        if etype == "value_error":
            return err.get("msg", "参数有误").replace("Value error, ", "")
    return "用户名或密码格式不对"

@app.exception_handler(HTTPException)
def http_exc_handler(request, exc):
    return JSONResponse({"ok": False, "detail": exc.detail}, status_code=exc.status_code)

@app.exception_handler(RequestValidationError)
def validation_handler(request, exc):
    return JSONResponse(
        {"ok": False, "detail": _friendly_validation_error(exc)},
        status_code=400,
    )

# ---------- 静态文件（本地开发用；生产由 Caddy 直接发） ----------

app.mount("/", StaticFiles(directory=str(PROJECT_ROOT), html=True), name="static")

init_db()
