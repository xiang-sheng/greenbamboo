#!/usr/bin/env python3
"""
GreenBamboo 文件下载服务器
- 仅支持文件查看和下载
- 带账号密码认证
- 安全隔离（只能访问指定文件夹）
- 不支持启动，仅配置文件
"""

import http.server
import socketserver
import base64
import os
import io
import hashlib
import secrets
from datetime import datetime

# ============ 配置区域 ============
PORT = 8082
USERNAME = "admin"
# 随机生成密码（首次运行时生成）
PASSWORD_FILE = os.path.expanduser("~/documents/.fileserver_password")
DIRECTORY = os.path.expanduser("~/documents/office-files")
# =================================

def get_or_create_password():
    """获取或创建随机密码"""
    if os.path.exists(PASSWORD_FILE):
        with open(PASSWORD_FILE, 'r') as f:
            return f.read().strip()
    else:
        # 生成随机密码
        password = secrets.token_urlsafe(12)
        os.makedirs(os.path.dirname(PASSWORD_FILE), exist_ok=True)
        with open(PASSWORD_FILE, 'w') as f:
            f.write(password)
        return password

PASSWORD = get_or_create_password()

class FileDownloadHandler(http.server.SimpleHTTPRequestHandler):
    """文件下载服务器处理器"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def do_GET(self):
        # 检查认证
        auth = self.headers.get("Authorization")
        if not self._check_auth(auth):
            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Basic realm="GreenBamboo Files"')
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h1>401 Unauthorized</h1><p>Please login to access files.</p>")
            return
        
        # 安全路径检查
        if not self._is_safe_path(self.path):
            self.send_error(403, "Access denied")
            return
        
        # 处理请求
        super().do_GET()
    
    def do_HEAD(self):
        auth = self.headers.get("Authorization")
        if not self._check_auth(auth):
            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Basic realm="GreenBamboo Files"')
            self.end_headers()
            return
        super().do_HEAD()
    
    def _check_auth(self, auth):
        """验证账号密码"""
        if auth is None:
            return False
        try:
            decoded = base64.b64decode(auth.split()[1]).decode("utf-8")
            username, password = decoded.split(":", 1)
            return username == USERNAME and password == PASSWORD
        except Exception:
            return False
    
    def _is_safe_path(self, path):
        """安全检查路径，防止目录穿越"""
        # 解码 URL
        from urllib.parse import unquote
        decoded_path = unquote(path)
        
        # 检查是否有目录穿越尝试
        if ".." in decoded_path or decoded_path.startswith("/"):
            decoded_path = decoded_path.lstrip("/")
        
        # 构建完整路径
        full_path = os.path.normpath(os.path.join(DIRECTORY, decoded_path))
        
        # 确保路径在允许目录内
        return full_path.startswith(os.path.normpath(DIRECTORY))
    
    def list_directory(self, path):
        """生成美观的目录列表页面"""
        try:
            entries = os.listdir(path)
        except OSError:
            self.send_error(404, "Cannot list directory")
            return None
        
        entries.sort(key=lambda x: (not os.path.isdir(os.path.join(path, x)), x.lower()))
        
        # 生成 HTML
        html = []
        html.append("<!DOCTYPE html>")
        html.append("<html lang='zh-CN'>")
        html.append("<head>")
        html.append("<meta charset='UTF-8'>")
        html.append("<meta name='viewport' content='width=device-width, initial-scale=1.0'>")
        html.append("<title>📁 GreenBamboo 文件下载</title>")
        html.append("<style>")
        html.append("* { margin: 0; padding: 0; box-sizing: border-box; }")
        html.append("body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }")
        html.append(".container { max-width: 1000px; margin: 0 auto; }")
        html.append("h1 { color: white; text-align: center; margin-bottom: 10px; font-size: 28px; }")
        html.append(".subtitle { color: rgba(255,255,255,0.8); text-align: center; margin-bottom: 30px; font-size: 14px; }")
        html.append(".file-list { background: white; border-radius: 16px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); overflow: hidden; }")
        html.append(".file-item { display: flex; align-items: center; padding: 16px 20px; border-bottom: 1px solid #f0f0f0; transition: background 0.2s; }")
        html.append(".file-item:hover { background: #f8f9ff; }")
        html.append(".file-item:last-child { border-bottom: none; }")
        html.append(".icon { font-size: 24px; margin-right: 16px; width: 32px; text-align: center; }")
        html.append(".name { flex: 1; color: #333; text-decoration: none; font-weight: 500; }")
        html.append(".name:hover { color: #667eea; }")
        html.append(".size { color: #999; font-size: 13px; margin-left: 20px; }")
        html.append(".download-btn { background: #667eea; color: white; padding: 8px 16px; border-radius: 8px; text-decoration: none; font-size: 13px; margin-left: 20px; transition: background 0.2s; }")
        html.append(".download-btn:hover { background: #5a6fd6; }")
        html.append(".empty { text-align: center; padding: 60px 20px; color: #999; }")
        html.append(".empty-icon { font-size: 64px; margin-bottom: 20px; }")
        html.append(".breadcrumb { background: rgba(255,255,255,0.1); padding: 12px 20px; border-radius: 12px 12px 0 0; color: white; }")
        html.append(".breadcrumb a { color: white; text-decoration: none; }")
        html.append(".breadcrumb a:hover { text-decoration: underline; }")
        html.append(".footer { text-align: center; color: rgba(255,255,255,0.6); margin-top: 30px; font-size: 12px; }")
        html.append(".folder { background: #fff8e6; }")
        html.append("</style>")
        html.append("</head>")
        html.append("<body>")
        html.append("<div class='container'>")
        html.append("<h1>🎋 GreenBamboo 文件下载</h1>")
        html.append("<p class='subtitle'>安全 · 简洁 · 高效</p>")
        
        # 面包屑导航
        rel_path = os.path.relpath(path, DIRECTORY)
        if rel_path == ".":
            html.append("<div class='breadcrumb'>📁 根目录</div>")
        else:
            parts = ["<a href='/'>🏠 首页</a>"]
            current = ""
            for part in rel_path.split(os.sep):
                current = os.path.join(current, part)
                full_path = os.path.join(DIRECTORY, current)
                if os.path.isdir(full_path):
                    parts.append(f"<a href='/{current}/'>{part}</a>")
                else:
                    parts.append(f"<span>{part}</span>")
            html.append(f"<div class='breadcrumb'>{' / '.join(parts)}</div>")
        
        html.append("<div class='file-list'>")
        
        # 返回上级目录
        if path != DIRECTORY:
            parent = os.path.dirname(path)
            html.append(f"<div class='file-item folder'><span class='icon'>📁</span><a class='name' href='../'>..</a><span class='size'>返回上级</span></div>")
        
        # 文件列表
        if not entries:
            html.append("<div class='empty'>")
            html.append("<div class='empty-icon'>📭</div>")
            html.append("<p>此目录为空</p>")
            html.append("<p style='margin-top: 10px; font-size: 13px;'>将文件放入 ~/documents/office-files/ 即可在此查看</p>")
            html.append("</div>")
        else:
            for name in entries:
                full_path = os.path.join(path, name)
                rel = os.path.relpath(full_path, DIRECTORY)
                url_path = "/" + rel.replace(os.sep, "/")
                
                if os.path.isdir(full_path):
                    html.append(f"<div class='file-item folder'><span class='icon'>📁</span><a class='name' href='{url_path}/'>{name}</a><span class='size'>文件夹</span></div>")
                else:
                    size = os.path.getsize(full_path)
                    size_str = self._format_size(size)
                    icon = self._get_icon(name)
                    html.append(f"<div class='file-item'><span class='icon'>{icon}</span><a class='name' href='{url_path}'>{name}</a><span class='size'>{size_str}</span><a class='download-btn' href='{url_path}' download>⬇ 下载</a></div>")
        
        html.append("</div>")
        html.append("<p class='footer'>🎋 GreenBamboo File Server | 登录用户：admin</p>")
        html.append("</div>")
        html.append("</body>")
        html.append("</html>")
        
        encoded = "\n".join(html).encode("utf-8")
        return io.BytesIO(encoded)
    
    def _format_size(self, size):
        """格式化文件大小"""
        for unit in ["B", "KB", "MB", "GB"]:
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} TB"
    
    def _get_icon(self, filename):
        """根据文件类型返回图标"""
        ext = os.path.splitext(filename)[1].lower()
        icons = {
            # 文档
            ".pdf": "📕", ".doc": "📘", ".docx": "📘", ".odt": "📘",
            ".txt": "📄", ".md": "📝", ".rtf": "📄",
            # 表格
            ".xls": "📊", ".xlsx": "📊", ".csv": "📊", ".ods": "📊",
            # 演示
            ".ppt": "📽️", ".pptx": "📽️", ".odp": "📽️", ".key": "📽️",
            # 图片
            ".jpg": "🖼️", ".jpeg": "🖼️", ".png": "🖼️", ".gif": "🖼️",
            ".svg": "🖼️", ".webp": "🖼️", ".bmp": "🖼️",
            # 压缩
            ".zip": "📦", ".rar": "📦", ".7z": "📦", ".tar": "📦",
            ".gz": "📦", ".bz2": "📦",
            # 代码
            ".py": "🐍", ".js": "📜", ".html": "🌐", ".css": "🎨",
            ".json": "📋", ".xml": "📋", ".yaml": "⚙️", ".yml": "⚙️",
            ".go": "🔷", ".dart": "🎯", ".sh": "💻",
            # 其他
            ".mp3": "🎵", ".mp4": "🎬", ".avi": "🎬", ".mkv": "🎬",
        }
        return icons.get(ext, "📄")
    
    def log_message(self, format, *args):
        """自定义日志格式"""
        pass  # 静默模式


def main():
    """主函数 - 仅显示配置信息，不启动服务"""
    print("")
    print("=" * 50)
    print("🎋 GreenBamboo 文件下载服务器 - 配置完成")
    print("=" * 50)
    print("")
    print("📁 服务目录：")
    print(f"   {DIRECTORY}")
    print("")
    print("🌐 端口：")
    print(f"   {PORT}")
    print("")
    print("👤 用户名：")
    print(f"   {USERNAME}")
    print("")
    print("🔑 密码：")
    print(f"   {PASSWORD}")
    print("")
    print("📝 使用说明：")
    print("   1. 将文件放入 ~/documents/office-files/")
    print("   2. 启动服务：python3 ~/documents/file-server.py")
    print("   3. 浏览器访问：http://服务器 IP:8082/")
    print("")
    print("🔒 安全特性：")
    print("   • 账号密码认证")
    print("   • 目录隔离（只能访问指定文件夹）")
    print("   • 防止目录穿越攻击")
    print("   • 支持子文件夹")
    print("")
    print("⚠️  服务当前未启动，需要时手动运行启动命令")
    print("")
    print("=" * 50)
    print("")


if __name__ == "__main__":
    main()
