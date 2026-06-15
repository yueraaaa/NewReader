#!/bin/bash
# NewReader 服务端部署脚本
#
# 前置条件（运行前必须 export 以下环境变量）：
#
#   必需：
#     export SUPABASE_ACCESS_TOKEN=sbp_...
#     export SUPABASE_PROJECT_REF=YOUR_PROJECT_REF
#     export DEEPSEEK_API_KEY=sk-...
#     export CLOUDFLARE_TURNSTILE_SITEKEY=0x4AAAAA...
#     export CLOUDFLARE_TURNSTILE_SECRET=0x4AAAAA...
#     export BILLING_NOTIFY_EMAIL=you@example.com
#
#   可选（不设则跳过邮件发送，billing-watchdog 仍能检测）：
#     export RESEND_API_KEY=re_...
#     export RESEND_FROM="NewReader <onboarding@resend.dev>"
#
#   准备：
#     supabase link --project-ref $SUPABASE_PROJECT_REF
#
# 用法：
#   bash scripts/deploy-server.sh
#
# 全部命令失败会立即退出（set -e）。任何一步想手动重跑，把对应段取消注释即可。

set -e

# ============ 检查环境 ============
echo "=== 检查环境 ==="

MISSING=0
check_required() {
    local name=$1
    if [ -z "${!name}" ]; then
        echo "❌ $name 未设置。请先: export $name=..."
        MISSING=1
    else
        if [[ "$name" == *"KEY"* ]] || [[ "$name" == *"TOKEN"* ]] || [[ "$name" == *"SECRET"* ]]; then
            echo "✅ $name 已设 (len=${#!name})"
        else
            echo "✅ $name = ${!name}"
        fi
    fi
}

check_required SUPABASE_ACCESS_TOKEN
check_required SUPABASE_PROJECT_REF
check_required DEEPSEEK_API_KEY
check_required CLOUDFLARE_TURNSTILE_SITEKEY
check_required CLOUDFLARE_TURNSTILE_SECRET
check_required BILLING_NOTIFY_EMAIL

if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo "💡 提示：将以上变量写入 ~/.newreader-deploy-env 后 source 即可："
    echo "   source ~/.newreader-deploy-env && bash scripts/deploy-server.sh"
    exit 1
fi

echo "✅ supabase CLI: $(supabase --version 2>&1 | head -1)"

# ============ 1. Edge Function secrets ============
echo ""
echo "=== 1. 设置 Edge Function secrets ==="
supabase secrets set DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY" 2>&1 | tail -2
supabase secrets set DEEPSEEK_BASE_URL="https://api.deepseek.com/v1" 2>&1 | tail -2
supabase secrets set DAILY_LIMIT=50 2>&1 | tail -2
supabase secrets set DEVICE_DAILY_LIMIT=5 2>&1 | tail -2
supabase secrets set CLOUDFLARE_TURNSTILE_SECRET="$CLOUDFLARE_TURNSTILE_SECRET" 2>&1 | tail -2
supabase secrets set SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" 2>&1 | tail -2
supabase secrets set SUPABASE_PROJECT_REF="$SUPABASE_PROJECT_REF" 2>&1 | tail -2
supabase secrets set BILLING_NOTIFY_EMAIL="$BILLING_NOTIFY_EMAIL" 2>&1 | tail -2
supabase secrets set RESEND_FROM="$RESEND_FROM" 2>&1 | tail -2
supabase secrets set FREE_PLAN_WARN_PCT=80 2>&1 | tail -2
supabase secrets set FREE_PLAN_HARD_STOP_PCT=95 2>&1 | tail -2
if [ -n "$RESEND_API_KEY" ]; then
    supabase secrets set RESEND_API_KEY="$RESEND_API_KEY" 2>&1 | tail -2
else
    echo "⚠️  RESEND_API_KEY 为空，跳过（billing-watchdog 不会发邮件，但检测仍工作）"
fi

echo ""
echo "--- 当前 secrets 列表 ---"
supabase secrets list 2>&1 | head -30

# ============ 2. SQL 迁移提示 ============
echo ""
echo "=== 2. SQL 迁移 ==="
echo "⚠️  SQL 迁移需要在 Supabase SQL Editor 手动跑（CLI 跑不了 DDL + RLS）。"
echo "    1. 打开 https://supabase.com/dashboard/project/$SUPABASE_PROJECT_REF/sql/new"
echo "    2. 复制并执行 supabase/migrations/003_device_quota.sql"
echo "    3. 复制并执行 supabase/migrations/004_billing_alerts.sql"
echo "    4. 验证 Table Editor 看到 device_quota / billing_alerts / service_flags 三张表"
read -p "    三张表都建好了？[y/N] " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "❌ 请先在 Dashboard 跑完 SQL 迁移，再重跑本脚本"
    exit 1
fi
echo "✅ SQL 迁移完成"

# ============ 3. 部署 Edge Functions ============
echo ""
echo "=== 3. 部署 Edge Functions ==="
# ai-proxy: 默认 JWT 验证（客户端带用户 JWT 调用，平台自动验）
supabase functions deploy ai-proxy 2>&1 | tail -5
# billing-watchdog: --no-verify-jwt，因为这是运维端点，
# 用 SUPABASE_ACCESS_TOKEN (Management API token) 调，不是用户 JWT
supabase functions deploy billing-watchdog --no-verify-jwt 2>&1 | tail -5

echo ""
echo "--- 已部署 ---"
supabase functions list 2>&1 | head -20

# ============ 4. 手动测一次 billing-watchdog ============
echo ""
echo "=== 4. 手动测试 billing-watchdog ==="
RESP=$(curl -sS -X POST \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  "https://$SUPABASE_PROJECT_REF.supabase.co/functions/v1/billing-watchdog")
echo "响应: $RESP"

# ============ 5. 客户端 Secrets.plist + 打包 ============
echo ""
echo "=== 5. 更新 Secrets.plist + 重新打包 ==="
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SECRETS="$PROJECT_DIR/Sources/NewReaderMac/Secrets.plist"

if [ ! -f "$SECRETS" ]; then
    echo "❌ $SECRETS 不存在"
    exit 1
fi

# 检查是否已经有 CloudflareTurnstileSitekey
if plutil -extract CloudflareTurnstileSitekey raw "$SECRETS" 2>/dev/null; then
    echo "✅ Secrets.plist 已有 CloudflareTurnstileSitekey，跳过"
else
    plutil -insert CloudflareTurnstileSitekey -string "$CLOUDFLARE_TURNSTILE_SITEKEY" "$SECRETS"
    echo "✅ 已加 CloudflareTurnstileSitekey 到 Secrets.plist"
fi

echo ""
echo "--- Secrets.plist 当前内容 ---"
plutil -p "$SECRETS"

echo ""
echo "=== 6. 重新打包 .app + .dmg ==="
bash "$SCRIPT_DIR/package-macos.sh" 2>&1 | tail -10

# ============ 7. 验证 sitekey 进了 .app ============
echo ""
echo "=== 7. 验证 sitekey 已嵌入 .app ==="
SITEKEY_IN_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :CloudflareTurnstileSitekey" "$PROJECT_DIR/NewReader.app/Contents/Info.plist" 2>&1)
if [ "$SITEKEY_IN_BUNDLE" = "$CLOUDFLARE_TURNSTILE_SITEKEY" ]; then
    echo "✅ .app Info.plist 包含正确的 Turnstile sitekey"
else
    echo "⚠️  .app Info.plist 的 sitekey = $SITEKEY_IN_BUNDLE"
    echo "    预期: $CLOUDFLARE_TURNSTILE_SITEKEY"
fi

echo ""
echo "=== 8. 最终产物 ==="
ls -lh "$PROJECT_DIR/NewReader.app" "$PROJECT_DIR/NewReader.dmg" 2>&1 | head -5

echo ""
echo "=== 9. 提示：下一步 ==="
echo "⚠️  还有一步需要在 Supabase Dashboard 手动完成："
echo "    调度 billing-watchdog (每 6 小时)。两条路："
echo "    a) pg_cron (SQL Editor 跑 SECURITY_SETUP.md §4.5 方案 A 的 SQL)"
echo "    b) 外部 cron: 0 */6 * * * curl -X POST -H 'Authorization: Bearer ...' https://$SUPABASE_PROJECT_REF.supabase.co/functions/v1/billing-watchdog"
echo ""
echo "🎉 服务端部署完成！"
