# NewReader 安全部署指南

本指南面向 **项目维护者**，说明为了让客户端在生产环境安全运行需要配置的所有凭据、Supabase 设置、Cloudflare 设置和部署步骤。

普通用户下载 .dmg 即可使用，不需要读本文档。

---

## 1. 总览

```
┌──────────┐   HTTPS    ┌─────────────────┐
│ 用户设备 │ ────────── │ Supabase 项目    │
│ (macOS)  │            │ (ai-proxy Edge) │
└──────────┘            └─────────────────┘
                              │
                ┌─────────────┼──────────────┐
                │             │              │
                ▼             ▼              ▼
        Cloudflare       Resend       DeepSeek API
        Turnstile        (邮件)       (付费)
```

**威胁模型**：
- 任意人下载 .dmg，能注册 Supabase 账号
- 单个攻击者可以脚本批量注册 + 调 AI
- 单 DeepSeek 调用成本低（几分钱），但量大后超 Supabase 免费额度
- Crash report 上传是匿名 anon，已在 RLS 限制

**防御层**：
1. Cloudflare Turnstile（每次登录 + 每次 AI 调用）
2. Per-device UUID 限速（每设备每天 5 次 AI 调用）
3. Per-user UUID 限速（每用户每天 50 次）
4. billing-watchdog 监控月用量，硬停止时自动暂停 ai-proxy

---

## 2. 凭据清单

部署前需要配置：

### 2.1 Supabase Edge Function secrets

```bash
# 已有
supabase secrets set DEEPSEEK_API_KEY=sk-...
supabase secrets set DEEPSEEK_BASE_URL=https://api.deepseek.com/v1

# 新增
supabase secrets set CLOUDFLARE_TURNSTILE_SECRET=0x4AAA...   # 见 §3
supabase secrets set DAILY_LIMIT=50                           # 每用户/天
supabase secrets set DEVICE_DAILY_LIMIT=5                    # 每设备/天
```

### 2.2 Supabase Management API token

```bash
supabase secrets set SUPABASE_ACCESS_TOKEN=sbp_...           # 见 §4.1
supabase secrets set SUPABASE_PROJECT_REF=your-project-ref   # 见 §4.2
supabase secrets set BILLING_NOTIFY_EMAIL=you@example.com
supabase secrets set FREE_PLAN_WARN_PCT=80                   # 用了 80% 警告
supabase secrets set FREE_PLAN_HARD_STOP_PCT=95              # 用了 95% 硬停止
supabase secrets set RESEND_API_KEY=re_...
supabase secrets set RESEND_FROM="NewReader <onboarding@resend.dev>"
```

### 2.3 客户端 Secrets（macOS / iOS）

`Sources/NewReaderMac/Secrets.plist`（gitignored）或
`~/Library/Application Support/NewReader/secrets.plist`（推荐）：

```xml
<dict>
    <key>SupabaseURL</key>                 <string>https://xxx.supabase.co</string>
    <key>SupabasePublishableKey</key>      <string>sb_publishable_...</string>
    <key>FeedbackEmail</key>               <string>you@example.com</string>
    <key>CloudflareTurnstileSitekey</key>  <string>0x4AAA...</string>  <!-- 新增 -->
</dict>
```

模板文件：`Sources/NewReaderMac/Secrets.plist.template`

### 2.4 复用已有凭据

`RESEND_API_KEY` 和 Vault 里的 `crash_notify_email` 已在 crash-report 流程用过，
billing-watchdog 复用同一个 Resend 账号发邮件。`crash_notify_email` 在
billing-watchdog 里**不直接读**（PostgREST 拿不到 vault 表），需要再设一个
`BILLING_NOTIFY_EMAIL` env（可以和 crash 通知邮箱相同）。

---

## 3. Cloudflare Turnstile 配置

1. 登录 [dash.cloudflare.com](https://dash.cloudflare.com) → 左侧 **Turnstile**
2. **Add widget**：
   - Widget name: `NewReader`
   - Hostname: `newreader.netlify.app`（产品站点）+ `localhost`（开发）
   - Widget mode: **Invisible**（用户看不到，流量异常时才弹）
3. 创建后拿到：
   - **Sitekey**（公开）→ 写到客户端 `Secrets.plist` 的 `CloudflareTurnstileSitekey`
   - **Secret key**（私密）→ `supabase secrets set CLOUDFLARE_TURNSTILE_SECRET=...`

**本地开发跳过 Turnstile**：
不配置 `CLOUDFLARE_TURNSTILE_SECRET`（或设为 `dev`），ai-proxy 会 warn + 跳过验证。
客户端没有 sitekey 时，fallback 到 Cloudflare 官方 dev sitekey
`1x00000000000000000000AA`（永远返回通过 token）。这样新开发者 clone
项目后不需要注册 Cloudflare 就能跑。

---

## 4. Supabase 配置

### 4.1 生成 Management API token

1. https://supabase.com/dashboard/account/tokens
2. **Generate new token** → name `billing-watchdog` → scope `all`
3. 复制 token（以 `sbp_` 开头），立即 `supabase secrets set SUPABASE_ACCESS_TOKEN=...`

### 4.2 找项目 ref

`Supabase Dashboard → Project Settings → General → Reference ID`
（例如 `krqcjyqxcfupjeweyhuj`）

### 4.3 应用 SQL 迁移

在 Supabase Dashboard SQL Editor 里依次执行：

```bash
# 文件路径
supabase/migrations/003_device_quota.sql
supabase/migrations/004_billing_alerts.sql
```

或将整个 `supabase/migrations/` 目录接进 [Supabase CLI migrations](https://supabase.com/docs/guides/cli/local-development#database-migrations)。

### 4.4 部署 Edge Functions

```bash
supabase functions deploy ai-proxy
supabase functions deploy billing-watchdog
```

### 4.5 调度 billing-watchdog

**方案 A：pg_cron（推荐，单一项目）**

在 SQL Editor：

```sql
select cron.schedule(
    'billing-watchdog',
    '0 */6 * * *',  -- 每 6 小时整点
    $$
    select net.http_post(
        url := 'https://<project-ref>.supabase.co/functions/v1/billing-watchdog',
        headers := jsonb_build_object(
            'Authorization', 'Bearer ' || (
                select decrypted_secret from vault.decrypted_secrets
                where name = 'service_role_key'
            )
        )
    );
    $$
);
```

> ⚠️ 这一步需要在 Supabase Vault 里存 service_role_key，再由 pg_cron 拼装 header。
> 比手动 token 复杂但更安全（不写明文）。

**方案 B：外部 cron（最简单）**

任何能跑 curl 的机器（GitHub Actions、自己的 Mac 等等）：

```bash
# crontab -e
0 */6 * * * curl -X POST \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  https://<project-ref>.supabase.co/functions/v1/billing-watchdog
```

GitHub Actions 替代方案：加一个 workflow，每 6 小时 `workflow_dispatch` + `schedule` trigger。

---

## 5. 验证

部署后验证清单：

```bash
# 1. Edge Functions 部署成功
supabase functions list

# 2. SQL 表已建
# Dashboard → Table Editor → 应看到 device_quota, billing_alerts, service_flags

# 3. 凭据已设
supabase secrets list

# 4. 手动触发 billing-watchdog
curl -X POST https://<project-ref>.supabase.co/functions/v1/billing-watchdog \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# 预期输出: {"metrics":[{"name":"db_size","used":12,"limit":500,"pct":2.4,"level":"ok"}, ...], "highest_level":"ok", "paused":false}

# 5. 客户端登录 → 第一次 AI 摘要 → 触发 Turnstile
# Settings → 应看到"人机验证：已开启（Cloudflare Turnstile）"

# 6. 测试硬停止
# 在 SQL Editor: update service_flags set value='true' where key='ai_proxy_paused';
# 客户端 AI 调用应返回 "AI 服务暂时维护中，请稍后再试"
# 恢复: update service_flags set value='false' where key='ai_proxy_paused';
```

---

## 6. 限额调整

| 变量 | 默认 | 含义 |
|------|------|------|
| `DAILY_LIMIT` | 50 | 每登录用户每天 AI 调用次数 |
| `DEVICE_DAILY_LIMIT` | 5 | 每物理设备每天 AI 调用次数（不论登录用户） |
| `FREE_PLAN_WARN_PCT` | 80 | 任意 Supabase 免费额度指标达到 80% 发邮件警告 |
| `FREE_PLAN_HARD_STOP_PCT` | 95 | 任意指标达到 95% 自动暂停 ai-proxy |

**为什么用百分比不是美元**：Supabase Free plan 账单是 $0，金额告警在免费层没意义。
百分比才是 Free plan 上唯一有用的"接近上限"信号。

billing-watchdog 同时监控 4 项 Free plan 指标，**任意一项**达到阈值就触发：
- 数据库大小：500 MB
- Storage：1 GB
- 出站流量：5 GB
- Edge Function 调用：500,000 次 / 月

改限额：

```bash
supabase secrets set DEVICE_DAILY_LIMIT=10
supabase secrets set FREE_PLAN_HARD_STOP_PCT=90
```

设备限额是针对**未登录攻击者**的——单物理设备刷 5 个不同 Supabase 账号也只
能跑 5 次。真人普通用户 5 次/天可能不够（建议 10-20）。

---

## 7. 不在本文档范围

- 邮箱白名单注册（Supabase Auth 支持，需要在 Dashboard 配置 allowed emails）
- Crash 上传限速（Edge Function 已暴露 anon bucket，需要加 device-id 限速）
- App Store / TestFlight 发布
- Netlify 网站部署

见 `CODE_AUDIT_REPORT.md` 第 11、12 章的后续建议。
