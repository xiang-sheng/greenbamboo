#!/usr/bin/env python3
"""
带认证的文件服务器 - 简化版
用户名: admin
密码: greenbamboo123
"""

import http.server
import socketserver
import base64
import os
import io

# 配置
PORT = 8080
USERNAME = "admin"
PASSWORD = "greenbamboo123"
DIRECTORY = os.path.expanduser("~/.openclaw/workspace")

class AuthHandler(http.server.SimpleHTTPRequestHandler):
    """带基本认证的 HTTP 请求处理器"""
    
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
            self.wfile.write(b"<h1>Authorization Required</h1><p>Please login to access files.</p>")
            return
        
        # 认证通过，处理请求
        super().do_GET()
    
    def _check_auth(self, auth):
        """验证账号密码"""
        if auth is None:
            return False
        
        try:
            # 解码 Basic Auth
            auth_decoded = base64.b64decode(auth.split()[1]).decode("utf-8")
            username, password = auth_decoded.split(":", 1)
            return username == USERNAME and password == PASSWORD
        except Exception:
            return False
    
    def list_directory(self, path):
        """生成目录列表 - 返回 BytesIO 对象"""
        try:
            entries = os.listdir(path)
        except OSError:
            self.send_error(404, "Cannot list directory")
            return None
        
        entries.sort(key=lambda x: x.lower())
        
        # 生成 HTML
        html = []
        html.append("<!DOCTYPE html>")
        html.append("<html>")
        html.append("<head>")
        html.append("<meta charset='utf-8'>")
        html.append("<meta name='viewport' content='width=device-width, initial-scale=1'>")
        html.append("<title>📁 GreenBamboo File Server</title>")
        html.append("<style>")
        html.append("body { font-family: -apple-system, sans-serif; max-width: 1000px; margin: 0 auto; padding: 20px; background: #f5f5f5; }")
        html.append("h1 { color: #4CAF50; }")
        html.append("ul { list-style: none; padding: 0; }")
        html.append("li { margin: 8px 0; padding: 12px; background: white; border-radius: 8px; }")
        html.append("a { text-decoration: none; color: #333; }")
        html.append("a:hover { color: #4CAF50; }")
        html.append(".folder { color: #FF9800; }")
        html.append(".file { color: #2196F3; }")
        html.append(".size { color: #999; float: right; }")
        html.append("</style>")
        html.append("</head>")
        html.append("<body>")
        html.append("<h1>📁 GreenBamboo File Server</h1>")
        html.append("<p>🎋 欢迎访问文件服务器，点击文件或文件夹查看内容</p>")
        html.append("<ul>")
        
        # 返回上级目录
        if path != DIRECTORY:
            html.append('<li><a href="../">📁 ..</a></li>')
        
        for name in entries:
            fullname = os.path.join(path, name)
            if os.path.isdir(fullname):
                html.append(f'<li><a href="{name}/"><span class="folder">📁</span> {name}/</a></li>')
            else:
                size = os.path.getsize(fullname)
                size_str = self._format_size(size)
                html.append(f'<li><a href="{name}"><span class="file">📄</span> {name}</a><span class="size">{size_str}</span></li>')
        
        html.append("</ul>")
        html.append("<hr>")
        html.append("<p style='color: #999; font-size: 12px;'>🎋 GreenBamboo | 登录用户: admin</p>")
        html.append("</body>")
        html.append("</html>")
        
        # 返回 BytesIO 对象（像文件一样）
        encoded = "\n".join(html).encode("utf-8")
        return io.BytesIO(encoded)
    
    def _format_size(self, size):
        """格式化文件大小"""
        for unit in ["B", "KB", "MB", "GB"]:
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} TB"


def main():
    print(f"")
    print(f"🌱 GreenBamboo 文件服务器")
    print(f"="* 40)
    print(f"📁 服务目录: {DIRECTORY}")
    print(f"🌐 监听端口: {PORT}")
    print(f"👤 用户名: {USERNAME}")
    print(f"🔑 密码: {PASSWORD}")
    print(f"")
    print(f"🔗 访问地址: http://你的服务器IP:{PORT}/")
    print(f"")
    print(f"按 Ctrl+C 停止服务器")
    print(f"")
    
    with socketserver.TCPServer(("", PORT), AuthHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 服务器已停止")


if __name__ == "__main__":
    main()
