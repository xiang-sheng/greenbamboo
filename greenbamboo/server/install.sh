#!/bin/bash

# GreenBamboo 一键安装脚本
# 🎋 青竹 - 健康如竹，节节高

set -e

echo "🎋 GreenBamboo 一键安装"
echo "━━━━━━━━━━━━━━━━━━━━━━"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ 未检测到 Docker"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✅ Docker 已安装"

# 检查 docker-compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ 未检测到 docker-compose"
    echo "请先安装 docker-compose"
    exit 1
fi

echo "✅ docker-compose 已安装"

# 创建安装目录
INSTALL_DIR="$HOME/greenbamboo"
echo ""
echo "📁 安装目录：$INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 下载配置文件
echo ""
echo "📥 下载配置文件..."

if [ -f "docker-compose.yml" ]; then
    echo "⚠️  docker-compose.yml 已存在，跳过下载"
else
    curl -sSL https://raw.githubusercontent.com/greenbamboo/server/main/docker-compose.yml -o docker-compose.yml
    echo "✅ docker-compose.yml 下载完成"
fi

if [ -f ".env" ]; then
    echo "⚠️  .env 已存在，跳过生成"
else
    curl -sSL https://raw.githubusercontent.com/greenbamboo/server/main/.env.example -o .env
    
    # 生成随机 JWT_SECRET
    JWT_SECRET=$(openssl rand -hex 32)
    sed -i "s/your-secret-key-here/$JWT_SECRET/" .env
    
    echo "✅ .env 生成完成"
fi

# 创建数据目录
mkdir -p data config

# 启动服务
echo ""
echo "🚀 启动 GreenBamboo 服务..."

if docker compose version &> /dev/null; then
    docker compose up -d
else
    docker-compose up -d
fi

# 等待服务启动
echo ""
echo "⏳ 等待服务启动..."
sleep 5

# 获取服务器 IP
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="localhost"
fi

# 显示安装结果
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 安装完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 服务器地址："
echo "   http://$SERVER_IP:3000"
echo "   http://localhost:3000"
echo ""
echo "🔑 初始设置："
echo "   请访问上述地址注册账号"
echo ""
echo "📊 服务状态："
if docker compose version &> /dev/null; then
    docker compose ps
else
    docker-compose ps
fi
echo ""
echo "📝 日志查看："
echo "   cd $INSTALL_DIR"
if docker compose version &> /dev/null; then
    echo "   docker compose logs -f"
else
    echo "   docker-compose logs -f"
fi
echo ""
echo "🛑 停止服务："
if docker compose version &> /dev/null; then
    echo "   docker compose down"
else
    echo "   docker-compose down"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo "🎋 健康如竹，节节高"
echo "━━━━━━━━━━━━━━━━━━━━━━"
