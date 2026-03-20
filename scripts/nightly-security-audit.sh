#!/bin/bash
# OpenClaw Nightly Security Audit Script v2.8
# 部署日期：2026-03-20 | 来源：SlowMist 慢雾科技

set -uo pipefail

# 路径定义
OC="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
REPORT_DIR="$OC/security-reports"
KNOWN_ISSUES_FILE="$OC/.security-audit-known-issues.json"
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
REPORT_FILE="$REPORT_DIR/audit-$TIMESTAMP.txt"

# 计数器
CRITICAL_COUNT=0
WARN_COUNT=0
OK_COUNT=0

# 确保报告目录存在
mkdir -p "$REPORT_DIR"

# 已知问题排除函数
check_known_issue() {
    local check_name="$1"
    local message="$2"
    
    if [ -f "$KNOWN_ISSUES_FILE" ]; then
        # 简单匹配：如果消息包含已知问题的 pattern
        if grep -q "$check_name" "$KNOWN_ISSUES_FILE" 2>/dev/null; then
            echo "[已知问题 - 忽略] $message"
            return 0
        fi
    fi
    return 1
}

# 输出函数
output_result() {
    local level="$1"  # CRITICAL, WARN, OK
    local message="$2"
    
    case "$level" in
        CRITICAL)
            echo "🚨 [CRITICAL] $message"
            ((CRITICAL_COUNT++))
            ;;
        WARN)
            echo "⚠️  [WARN] $message"
            ((WARN_COUNT++))
            ;;
        OK)
            echo "✅ [OK] $message"
            ((OK_COUNT++))
            ;;
    esac
}

# 开始输出
echo "========================================"
echo "OpenClaw 夜间安全巡检报告"
echo "时间：$(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "========================================"
echo ""

# [1] OpenClaw 平台审计
echo "=== [1] OpenClaw 平台审计 ==="
if command -v openclaw &> /dev/null; then
    AUDIT_OUTPUT=$(openclaw security audit 2>&1 | head -n 100)
    if echo "$AUDIT_OUTPUT" | grep -qi "error\|fail\|critical"; then
        output_result "WARN" "OpenClaw 安全审计发现潜在问题"
        echo "$AUDIT_OUTPUT" | grep -i "error\|fail\|critical" | head -n 10
    else
        output_result "OK" "OpenClaw 安全审计通过"
    fi
else
    output_result "WARN" "openclaw 命令未找到"
fi
echo ""

# [2] 进程与网络审计
echo "=== [2] 进程与网络审计 ==="
LISTEN_PORTS=$(ss -tnlp 2>/dev/null | grep LISTEN | head -n 20)
if [ -n "$LISTEN_PORTS" ]; then
    output_result "OK" "监听端口检查完成"
    echo "$LISTEN_PORTS" | head -n 10
else
    output_result "OK" "未发现 TCP 监听端口"
fi
echo ""

# [3] 敏感目录变更
echo "=== [3] 敏感目录变更 (24h) ==="
RECENT_CHANGES=$(find "$OC" -type f -mtime -1 2>/dev/null | head -n 50)
if [ -n "$RECENT_CHANGES" ]; then
    CHANGE_COUNT=$(echo "$RECENT_CHANGES" | wc -l)
    output_result "OK" "过去 24 小时有 $CHANGE_COUNT 个文件变更"
    echo "$RECENT_CHANGES" | head -n 20
else
    output_result "OK" "过去 24 小时无文件变更"
fi
echo ""

# [4] 系统定时任务
echo "=== [4] 系统定时任务 ==="
CRON_JOBS=$(crontab -l 2>/dev/null | head -n 20)
if [ -n "$CRON_JOBS" ]; then
    output_result "OK" "用户 crontab 检查完成"
    echo "$CRON_JOBS" | head -n 10
else
    output_result "OK" "无用户 crontab"
fi
echo ""

# [5] OpenClaw Cron Jobs
echo "=== [5] OpenClaw Cron Jobs ==="
OC_CRONS=$(openclaw cron list 2>&1 | head -n 20)
if echo "$OC_CRONS" | grep -q "cron\|job\|ID"; then
    output_result "OK" "OpenClaw Cron 检查完成"
    echo "$OC_CRONS" | head -n 10
else
    output_result "WARN" "OpenClaw Cron 列表异常"
fi
echo ""

# [6] 登录与 SSH
echo "=== [6] 登录与 SSH ==="
if [ -f /var/log/auth.log ]; then
    SSH_FAILS=$(grep -i "failed\|invalid" /var/log/auth.log 2>/dev/null | tail -n 100 | wc -l)
    if [ "$SSH_FAILS" -gt 10 ]; then
        output_result "WARN" "SSH 失败尝试：$SSH_FAILS 次"
    else
        output_result "OK" "SSH 登录正常 ($SSH_FAILS 次失败)"
    fi
else
    output_result "OK" "无 auth.log 或无法访问"
fi
echo ""

# [7] 关键文件完整性
echo "=== [7] 关键文件完整性 ==="
if [ -f "$OC/.config-baseline.sha256" ]; then
    cd "$OC" && sha256sum -c .config-baseline.sha256 2>&1 | head -n 10
    if [ $? -eq 0 ]; then
        output_result "OK" "配置文件哈希校验通过"
    else
        output_result "CRITICAL" "配置文件哈希校验失败！"
    fi
else
    output_result "WARN" "配置文件基线不存在"
fi
echo ""

# [8] 黄线操作交叉验证
echo "=== [8] 黄线操作记录 ==="
MEMORY_FILE="$OC/workspace/memory/$(date +%Y-%m-%d).md"
if [ -f "$MEMORY_FILE" ]; then
    SUDO_COUNT=$(grep -c "sudo" "$MEMORY_FILE" 2>/dev/null || echo 0)
    output_result "OK" "今日 memory 中有 $SUDO_COUNT 条 sudo 记录"
else
    output_result "OK" "今日 memory 文件不存在或无 sudo 记录"
fi
echo ""

# [9] 磁盘使用
echo "=== [9] 磁盘使用 ==="
DISK_USAGE=$(df -h / 2>/dev/null | tail -n 1 | awk '{print $5}' | sed 's/%//')
if [ -n "$DISK_USAGE" ] && [ "$DISK_USAGE" -gt 85 ]; then
    output_result "WARN" "磁盘使用率：${DISK_USAGE}%"
else
    output_result "OK" "磁盘使用率：${DISK_USAGE:-未知}%"
fi
echo ""

# [10] Gateway 环境变量
echo "=== [10] Gateway 环境变量 ==="
GATEWAY_PID=$(pgrep -f "openclaw.*gateway" 2>/dev/null | head -n 1)
if [ -n "$GATEWAY_PID" ] && [ -d "/proc/$GATEWAY_PID" ]; then
    ENV_VARS=$(cat /proc/$GATEWAY_PID/environ 2>/dev/null | tr '\0' '\n' | grep -i "KEY\|TOKEN\|SECRET\|PASSWORD" | head -n 20)
    if [ -n "$ENV_VARS" ]; then
        output_result "OK" "Gateway 环境变量检查完成"
        echo "$ENV_VARS" | sed 's/=.*$/=***/' | head -n 10
    else
        output_result "OK" "未发现敏感环境变量"
    fi
else
    output_result "OK" "Gateway 进程未找到或无法检查"
fi
echo ""

# [11] 明文私钥/凭证泄露扫描 (DLP)
echo "=== [11] 明文凭证泄露扫描 ==="
DLP_RESULTS=$(grep -rE "(0x[a-fA-F0-9]{64}|[1-9][a-km-zA-HJ-NP-Z1-9]{51}|\\b[a-zA-Z0-9]{12}\\b.*\\b[a-zA-Z0-9]{12}\\b)" "$OC/workspace/memory" "$OC/workspace/logs" 2>/dev/null | head -n 20)
if [ -n "$DLP_RESULTS" ]; then
    if check_known_issue "dlp" "$DLP_RESULTS"; then
        output_result "OK" "DLP 扫描发现匹配项（已知问题）"
    else
        output_result "CRITICAL" "发现疑似明文凭证！"
        echo "$DLP_RESULTS" | head -n 5
    fi
else
    output_result "OK" "未发现明文凭证泄露"
fi
echo ""

# [12] Skill/MCP 完整性
echo "=== [12] Skill 完整性 ==="
if [ -f "$OC/.skill-baseline.sha256" ]; then
    CURRENT_HASH=$(find "$OC/workspace/skills" -type f -not -path '*/.git/*' -exec sha256sum {} \; 2>/dev/null | sort | sha256sum)
    BASELINE_HASH=$(cat "$OC/.skill-baseline.sha256" 2>/dev/null)
    if [ "$CURRENT_HASH" = "$BASELINE_HASH" ]; then
        output_result "OK" "Skill 文件完整性校验通过"
    else
        output_result "WARN" "Skill 文件发生变化"
    fi
else
    output_result "OK" "Skill 基线不存在（首次运行）"
fi
echo ""

# [13] 大脑灾备 Git 同步（可选）
echo "=== [13] 大脑灾备 Git 同步 ==="
if [ -d "$OC/.git" ]; then
    cd "$OC" && git status --porcelain 2>/dev/null | head -n 20
    if [ $? -eq 0 ]; then
        output_result "OK" "Git 仓库存在并可访问"
    else
        output_result "WARN" "Git 仓库状态异常"
    fi
else
    output_result "OK" "未配置 Git 灾备（可选功能）"
fi
echo ""

# 统计摘要
echo "========================================"
echo "统计摘要：$CRITICAL_COUNT critical · $WARN_COUNT warn · $OK_COUNT ok"
echo "========================================"

# 保存报告
echo "" >> "$REPORT_FILE"
echo "报告时间：$(date '+%Y-%m-%d %H:%M:%S %Z')" >> "$REPORT_FILE"
echo "统计摘要：$CRITICAL_COUNT critical · $WARN_COUNT warn · $OK_COUNT ok" >> "$REPORT_FILE"

# 清理旧报告（保留 30 天）
find "$REPORT_DIR" -type f -mtime +30 -delete 2>/dev/null

exit 0
