# 课酬记 · TutorLedger

帮助学科辅导老师记录课时费、算清课酬、快速对账的 **iOS** 工具。

| 项 | 说明 |
|---|---|
| 品牌名 | **课酬记** |
| 工程名 | TutorLedger |
| 平台 | **iOS 17+** |
| 技术栈 | SwiftUI · SwiftData |

## 打开项目

```bash
open TutorLedger/TutorLedger.xcworkspace
```

工程由 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成，Firebase 用 CocoaPods 接入。改过 `project.yml` 后按顺序执行：

```bash
cd TutorLedger && xcodegen generate && pod install
```

之后打开 `.xcworkspace`，不要直接开 `.xcodeproj`。

## v1.0 已实现功能

- [x] 学生 CRUD（先付课包 / 课后结算 / 按次现结）
- [x] 记课时（单价快照、自动扣包 / 挂账 / 现结标记已收）
- [x] 课时流水（查看、编辑、作废）
- [x] 待收款 + 生成账单 + 标记已收 / 已发送
- [x] 课包购课 / 扣减流水
- [x] 首页概览 + 月度统计
- [x] CSV 导出
- [x] 账单文字复制（v1.0.2）
- [x] 业务埋点（v1.0.2）

## 文档

- [REQUIREMENTS.md](./REQUIREMENTS.md) — 产品需求文档（v1.1）
- [CHANGELOG.md](./CHANGELOG.md) — 版本记录（含 App Store What’s New / 宣传文本）
- [APP_STORE_COPY.md](./APP_STORE_COPY.md) — App Store Connect 中英后台文案（可直接粘贴）
- [../TutorLedger_setting/](../TutorLedger_setting/) — 隐私政策 / 用户协议 / 支持页（App Store 用）

## 目录结构

```
TutorLedger/
├── REQUIREMENTS.md
├── README.md
└── TutorLedger/
    ├── project.yml
    ├── TutorLedger.xcodeproj
    └── TutorLedger/
        ├── Models/
        ├── Services/
        ├── Views/
        └── Common/
```
