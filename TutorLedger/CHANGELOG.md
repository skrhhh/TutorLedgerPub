# 课酬记 · 版本记录

> 状态以 App Store Connect 为准。日期为提交日。

---

## 1.0.2 — 2026-09-20（待提审）

### App Store · What’s New

**简体中文**

```
本次更新：
• 账单可一键复制文字，方便发家长微信核对
• 首页提醒备份，避免换机或重装丢失课酬记录
• 快速添加「先付课包」学生时需填写节数，避免记下课后才发现课包为 0
• 新建课包学生会写入购课流水，剩余课时可追溯
• 设置页显示正确版本号
• 提升稳定性
```

**English**

```
This update:
• Copy a bill as text to share with parents in chat
• Home screen backup reminder so records are not lost when changing phones
• Quick-add prepaid students now require package hours
• New prepaid students get an opening package record
• Settings now shows the real app version
• Stability improvements
```

### 本版改动

- 账单详情支持复制微信可用的文字摘要
- 首页在有课时且超过 30 天未备份时提醒导出
- 记课时快速添加先付学生必须填写课包节数
- 新建 / 改为先付课包时写入「建档购课」流水
- 设置页版本号改为读取实际 MARKETING_VERSION
- 接入 6 个业务埋点：add_student / log_lesson / package_purchase / generate_bill / mark_paid / export_csv（含 billing_mode、is_demo）
- Crashlytics 写入版本号；记课 5 次或生成账单后请求一次评分

---

## 1.0.1 — 2026-08-26（已提审）

### App Store · What’s New

**简体中文**

```
本次更新：
• 作废课时可在「课时流水」和「学生详情」中查看，并显示作废原因
• 修复系统深色模式下界面错乱，现已固定浅色显示
• 优化作废课时流程，填写原因后操作更可靠
• 提升稳定性
```

**English**

```
This update:
• View voided lessons in Lesson History and student details, including the void reason
• Fixed Dark Mode layout issues; the app now stays in Light appearance
• More reliable void-lesson flow
• Stability improvements
```

### App Store · Promotional Text

**简体中文**

```
个人辅导老师的口袋账本：10 秒记一笔课时，课包自动扣减，月底一键生成账单分享家长。数据存本机，完全离线，无需登录。
```

**English**

```
Your pocket ledger for tutoring pay: log a lesson in 10 seconds, auto-deduct packages, generate bills to share with parents. Fully offline—data stays on your device.
```

### 本版改动

- 接入 Firebase Analytics、Crashlytics（CocoaPods）；App 启动时 `FirebaseApp.configure()`
- 作废课时可在课时流水（有效 / 已作废 / 全部）与学生详情「课时」中查看
- 固定浅色界面，不再跟随系统深浅色
- 修复作废课时无反馈、已出账仍显示作废、作废后未返回上一页
- 首页今日 / 本周 / 本月统计改为闭区间；试讲金额按时长 × 0.5 计算
- App Store 隐私标签已按 Analytics + Crashlytics 重新申报（追踪：否）

---

## 1.0.0 — 首发

### App Store · What’s New

**简体中文**

```
欢迎使用课酬记！
• 添加学生，支持先付课包 / 课后结算 / 按次现结
• 课后 10 秒记一笔，单价快照与自动扣包 / 挂账
• 待出账汇总、生成账单、标记已发送 / 已收款
• 课包购课与扣减流水
• 首页概览与月度统计
• CSV 导出备份，数据存本机、无需登录
```

**English**

```
Welcome to TutorLedger!
• Add students with prepaid, pay-after-class, or per-session billing
• Log a lesson in seconds with rate snapshots and auto package deduction
• Pending billing, generate bills, mark sent / paid
• Package purchase & deduction history
• Home overview and monthly stats
• CSV export—data stays on device, no account required
```

### 本版范围

学生 CRUD、记课时、课时流水、账单、课包流水、首页与月度统计、CSV 导出。数据存本机，无需登录。
