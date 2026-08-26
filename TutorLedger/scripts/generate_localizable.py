#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate Localizable.xcstrings and InfoPlist.xcstrings for TutorLedger."""

from __future__ import annotations

import json
import os
import re
from typing import Dict, Set

from opencc import OpenCC

ROOT = os.path.join(os.path.dirname(__file__), "..", "TutorLedger", "TutorLedger")
cc = OpenCC("s2tw")

EN = {
    "课酬记": "TutorLedger",
    "记录课时，算清课酬": "Log lessons. Settle pay clearly.",
    "下课记一笔，对账不扯皮": "Log after class. Settle without disputes.",
    "课酬记导出.csv": "TutorLedger-Export.csv",
    "首页": "Home",
    "学生": "Students",
    "账单": "Bills",
    "统计": "Stats",
    "设置": "Settings",
    "完成": "Done",
    "合计": "Total",
    "取消": "Cancel",
    "保存": "Save",
    "好的": "OK",
    "可选": "Optional",
    "编辑": "Edit",
    "筛选": "Filter",
    "自定义": "Custom",
    "全部": "All",
    "其他": "Other",
    "备注": "Notes",
    "备注（可选）": "Notes (optional)",
    "状态": "Status",
    "类型": "Type",
    "日期": "Date",
    "时长": "Duration",
    "小时": "hours",
    "科目": "Subject",
    "单价": "Rate",
    "金额": "Amount",
    "续费": "Renew",
    "详情": "Details",
    "开始": "Start",
    "结束": "End",
    "今天": "Today",
    "明天": "Tomorrow",
    "已收": "Received",
    "未知学生": "Unknown student",
    "未知错误": "Unknown error",
    "操作失败": "Operation failed",
    "无法保存": "Unable to save",
    "分享失败": "Share failed",
    "导出失败": "Export failed",
    "数学": "Math",
    "先付课包": "Prepaid package",
    "课后结算": "Pay after class",
    "按次现结": "Pay per session",
    "在读": "Active",
    "停课": "Paused",
    "结课": "Archived",
    "小学": "Primary",
    "初中": "Junior high",
    "高中": "Senior high",
    "周结": "Weekly",
    "月结": "Monthly",
    "正常": "Regular",
    "试讲": "Trial",
    "补课": "Makeup",
    "赠课": "Complimentary",
    "已扣课": "Deducted",
    "待结算": "Pending",
    "已出账": "Billed",
    "已收款": "Paid",
    "已作废": "Voided",
    "待发送": "Draft",
    "已发送": "Sent",
    "微信": "WeChat",
    "支付宝": "Alipay",
    "现金": "Cash",
    "购课": "Purchase",
    "扣课": "Deduction",
    "调整": "Adjustment",
    "确认收款": "Confirm payment",
    "收款信息": "Payment details",
    "收款方式": "Payment method",
    "收款日期": "Payment date",
    "收款": "Payment",
    "当场已收款": "Paid on the spot",
    "标记已收款": "Mark as paid",
    "标记为已发送": "Mark as sent",
    "数据仅保存在内存中，重启后将丢失": "Data is in memory only and will be lost after restart.",
    "应用启动失败": "App failed to launch",
    "添加学生": "Add student",
    "录入姓名、计费方式和默认单价，支持先付课包、课后结算、按次现结": (
        "Enter name, billing mode, and default rate. Supports prepaid packages, "
        "pay-after-class, and per-session pay."
    ),
    "记课时": "Log lesson",
    "下课后 10 秒记一笔，可当场添加新学生，单价自动带出": (
        "Log a lesson in 10 seconds after class. Add a new student on the spot; "
        "rate fills in automatically."
    ),
    "对账收款": "Reconcile & collect",
    "在账单页汇总待收、生成账单分享 CSV，记得定期备份": (
        "On Bills, total pending amounts, generate bills, share CSV, and back up regularly."
    ),
    "账单状态": "Bill status",
    "待发送：已生成未发给家长 · 已发送：已发给家长待收款 · 已收款：钱已到账": (
        "Draft: created but not sent · Sent: waiting for payment · Paid: received"
    ),
    "下一步": "Next",
    "跳过": "Skip",
    "开始使用": "Get started",
    "10 秒完成记录": "Done in 10 seconds",
    "今日课时": "Today",
    "本周课时": "This week",
    "本月已收": "Received this month",
    "本月待收": "Pending this month",
    "课包不足": "Low package balance",
    "即将上课": "Upcoming",
    "最近课时": "Recent lessons",
    "还没有课时记录，点击上方按钮记第一笔": "No lessons yet. Tap above to log the first one.",
    "查看全部课时": "See all lessons",
    "记一笔": "Log",
    "还没有学生": "No students yet",
    "添加第一个学生，开始记录课时与课酬": "Add your first student to start tracking lessons and pay.",
    "搜索姓名或科目": "Search name or subject",
    "暂无学生": "No students",
    "未找到匹配的学生": "No matching students",
    "编辑学生": "Edit student",
    "基本信息": "Basic info",
    "姓名/昵称": "Name / nickname",
    "小明": "Alex",
    "小明-初二数学": "Alex – Grade 8 Math",
    "年级": "Grade",
    "科目（顿号分隔）": "Subjects (separated by 、)",
    "科目（可选）": "Subject (optional)",
    "数学、英语": "Math, English",
    "计费": "Billing",
    "计费设置": "Billing settings",
    "计费模式": "Billing mode",
    "课包节数": "Package sessions",
    "结算周期": "Settlement cycle",
    "默认时长": "Default duration",
    "设置下次上课时间": "Set next lesson time",
    "请填写姓名": "Please enter a name",
    "请填写默认单价": "Please enter a default rate",
    "请填写课包节数": "Please enter package sessions",
    "请设置默认时长": "Please set a default duration",
    "科目未填写": "Subject not filled in",
    "未填写科目不影响保存，但记课时时需要手动输入科目。是否直接保存？": (
        "You can save without a subject, but you’ll need to enter it when logging lessons. Save anyway?"
    ),
    "直接保存": "Save anyway",
    "返回填写": "Go back",
    "快速添加后可立即记课时，详细资料可在学生页补充。": (
        "After a quick add you can log lessons right away. Fill in details later on the student page."
    ),
    "概览": "Overview",
    "课时": "Lessons",
    "剩余课时": "Remaining",
    "待收金额": "Pending amount",
    "累计课时": "Total lessons",
    "下次上课": "Next lesson",
    "最近上课": "Recent lessons",
    "购课 / 续费": "Buy / renew",
    "课包流水": "Package history",
    "仅显示最近 10 条": "Showing latest 10 only",
    "暂无课时": "No lessons",
    "暂无账单": "No bills",
    "点击右上角「记一笔」开始记录": "Tap “Log” at the top right to start.",
    "在「账单」页为待结算课时生成账单": "Generate bills for pending lessons on the Bills tab.",
    "编辑学生信息": "Edit student",
    "删除学生": "Delete student",
    "删除学生？": "Delete student?",
    "删除全部数据": "Delete all data",
    "将永久删除该学生及其所有课时、账单和课包记录，此操作不可恢复。": (
        "This permanently deletes the student and all lessons, bills, and package records. This cannot be undone."
    ),
    "购课后剩余课时": "Remaining after purchase",
    "购课信息": "Purchase details",
    "购买节数": "Sessions to buy",
    "实收金额（可选）": "Amount received (optional)",
    "请输入有效节数": "Enter a valid session count",
    "未设置": "Not set",
    "全部学生": "All students",
    "课时流水": "Lesson history",
    "搜索学生、科目或备注": "Search student, subject, or notes",
    "按月份筛选": "Filter by month",
    "调整筛选条件试试": "Try adjusting filters",
    "未找到匹配的课时记录": "No matching lessons",
    "请选择学生": "Please select a student",
    "请设置上课时长": "Please set lesson duration",
    "课包剩余课时不足": "Not enough remaining package sessions",
    "上课信息": "Lesson details",
    "日期时间": "Date & time",
    "课时类型": "Lesson type",
    "预计结果": "Preview",
    "计费方式": "Billing mode",
    "扣课后剩余": "Remaining after deduction",
    "选择学生": "Select student",
    "还没有在读学生，点「新学生」快速添加": "No active students yet. Tap “New student” to add one.",
    "请选择一位学生": "Please select a student",
    "新学生": "New student",
    "未填写科目，是否仍要保存？": "No subject entered. Save anyway?",
    "课时详情": "Lesson details",
    "作废此课时": "Void this lesson",
    "作废课时": "Void lesson",
    "作废原因": "Void reason",
    "确认作废": "Confirm void",
    "待出账": "To bill",
    "已出账单": "Issued bills",
    "课后课时，尚未生成账单": "Postpaid lessons not yet billed",
    "已按学生汇总，可分享对账": "Grouped by student — ready to share",
    "本月": "This month",
    "全部时间": "All time",
    "全部状态": "All statuses",
    "待收款": "Unpaid",
    "时间范围": "Time range",
    "暂无待出账课时": "No lessons to bill",
    "账单按学生汇总多节课时，不是每节课一张账单": (
        "A bill groups multiple lessons for one student — not one bill per lesson."
    ),
    "开始日期": "Start date",
    "结束日期": "End date",
    "分享当前筛选 CSV": "Share filtered CSV",
    "课后结算的课时会出现在这里，选中学生后可生成账单": (
        "Pay-after-class lessons appear here. Select a student to generate a bill."
    ),
    "待出账合计": "Total to bill",
    "生成账单": "Generate bill",
    "在「待出账」中为学生勾选课时，生成第一张账单": (
        "In To bill, select lessons for a student to create the first bill."
    ),
    "当前筛选条件下没有账单，试试调整筛选": "No bills match the current filters. Try adjusting them.",
    "账单合计": "Bill total",
    "账期": "Billing period",
    "选择课时": "Select lessons",
    "无法生成": "Unable to generate",
    "账单详情": "Bill details",
    "包含课时": "Lessons included",
    "课时明细": "Lesson breakdown",
    "分享 CSV": "Share CSV",
    "撤销账单": "Cancel bill",
    "撤销账单？": "Cancel bill?",
    "撤销并退回待收": "Cancel and return to pending",
    "账单将被删除，所含课时恢复为「待结算」状态。": (
        "The bill will be deleted and its lessons will return to Pending."
    ),
    "选择日期": "Pick a date",
    "本月课时": "Lessons this month",
    "本月时长": "Hours this month",
    "收入分布": "Income breakdown",
    "学生贡献": "By student",
    "本月暂无已收款记录": "No paid records this month",
    "上课最多": "Most lessons",
    "本月暂无课时记录": "No lessons this month",
    "这一天没有课时记录": "No lessons on this day",
    "日": "S",
    "一": "M",
    "二": "T",
    "三": "W",
    "四": "T",
    "五": "F",
    "六": "S",
    "建议备份数据": "Back up your data",
    "数据仅保存在本机，换机前请导出 CSV 备份。建议每月至少备份一次。": (
        "Data stays on this device. Export a CSV backup before switching phones. Back up at least monthly."
    ),
    "默认设置": "Defaults",
    "默认课时时长": "Default lesson duration",
    "时长快捷选项": "Duration shortcuts",
    "逗号分隔，记课时可快速选择": "Comma-separated; quick picks when logging lessons",
    "货币符号": "Currency symbol",
    "输入符号，如 ₱": "Enter a symbol, e.g. ₱",
    "数据": "Data",
    "上次导出": "Last export",
    "导出 / 分享 CSV": "Export / share CSV",
    "重新查看引导": "Replay onboarding",
    "数据保存在本机，无需登录 · 暂无 iCloud 同步": "Stored on device · No login · No iCloud sync yet",
    "尚未导出": "Never exported",
    "如 1.25": "e.g. 1.25",
    "该课时已出账或已收款，无法编辑": "This lesson is billed or paid and can’t be edited",
    "该课时已作废": "This lesson is voided",
    "该课时已关联账单，请先处理账单": "This lesson is linked to a bill. Handle the bill first.",
    "当前状态不允许此操作": "This action isn’t allowed in the current status",
    "仅先付课包学生可购课": "Only prepaid-package students can purchase sessions",
    "没有可出账的待结算课时": "No pending lessons to bill",
    "账单已收款，无法撤销": "Paid bills can’t be cancelled",
    "无法访问应用数据目录": "Can’t access the app data directory",
    "上课扣课": "Lesson deduction",
    "=== 学生 ===": "=== Students ===",
    "姓名,年级,科目,计费模式,默认单价,剩余课时,状态,备注": (
        "Name,Grade,Subjects,Billing mode,Default rate,Remaining,Status,Notes"
    ),
    "=== 课时记录 ===": "=== Lessons ===",
    "日期,学生,科目,时长,单价,金额,类型,状态,收款方式,收款日期,备注": (
        "Date,Student,Subject,Duration,Rate,Amount,Type,Status,Payment method,Payment date,Notes"
    ),
    "=== 账单 ===": "=== Bills ===",
    "账期开始,账期结束,学生,合计,状态,收款方式,收款日期,备注": (
        "Period start,Period end,Student,Total,Status,Payment method,Payment date,Notes"
    ),
    "=== 课包流水 ===": "=== Package history ===",
    "日期,学生,类型,节数,实收金额,备注": "Date,Student,Type,Sessions,Amount received,Notes",
    "=== 账单摘要 ===": "=== Bill summary ===",
    "学生,账期开始,账期结束,合计,状态,收款方式,收款日期,备注": (
        "Student,Period start,Period end,Total,Status,Payment method,Payment date,Notes"
    ),
    "日期,科目,时长,单价,金额,备注": "Date,Subject,Duration,Rate,Amount,Notes",
    "=== 待出账汇总 ===": "=== Pending billing summary ===",
    "学生数,课时数,合计": "Students,Lessons,Total",
    "学生,课时数,合计": "Student,Lessons,Total",
    "学生,日期,科目,时长,单价,金额,备注": "Student,Date,Subject,Duration,Rate,Amount,Notes",
    "=== 账单汇总 ===": "=== Bills summary ===",
    "学生数,账单数,合计": "Students,Bills,Total",
    "学生,账单数,合计": "Student,Bills,Total",
    "=== 账单列表 ===": "=== Bill list ===",
    "学生,账期开始,账期结束,合计,状态,课时数,收款方式,收款日期,备注": (
        "Student,Period start,Period end,Total,Status,Lessons,Payment method,Payment date,Notes"
    ),
    "=== 各账单课时明细 ===": "=== Lessons per bill ===",
    "学生,账期,日期,科目,时长,单价,金额,备注": "Student,Period,Date,Subject,Duration,Rate,Amount,Notes",
    "=== 课时明细 ===": "=== Lesson breakdown ===",
    "=== 各学生汇总 ===": "=== Per-student summary ===",
    "=== 导出范围 ===": "=== Export scope ===",
    "字段,值": "Field,Value",
    "单学生": "Single student",
    "导出说明": "Export note",
    "导出范围": "Export scope",
    "类型": "Type",
    "学生": "Student",
    "_账单": "_Bill",
    "%.0f 小时": "%.0f hours",
    "%.1f 小时": "%.1f hours",
}

ZH_HANT_OVERRIDE = {
    "课酬记": "課酬記",
    "课酬记导出.csv": "課酬記匯出.csv",
    "账单": "帳單",
    "账单状态": "帳單狀態",
    "账单合计": "帳單合計",
    "账单详情": "帳單詳情",
    "已出账单": "已出帳單",
    "生成账单": "產生帳單",
    "撤销账单": "撤銷帳單",
    "撤销账单？": "撤銷帳單？",
    "暂无账单": "暫無帳單",
    "_账单": "_帳單",
    "=== 账单 ===": "=== 帳單 ===",
    "=== 账单摘要 ===": "=== 帳單摘要 ===",
    "=== 账单汇总 ===": "=== 帳單彙總 ===",
    "=== 账单列表 ===": "=== 帳單列表 ===",
    "=== 各账单课时明细 ===": "=== 各帳單課時明細 ===",
}

FORMAT_ENTRIES = {
    "%lld 节": {"en": "%lld sessions", "zh-Hant": "%lld 節"},
    "%lld 节课": {"en": "%lld lessons", "zh-Hant": "%lld 節課"},
    "%lld 条记录": {"en": "%lld records", "zh-Hant": "%lld 條記錄"},
    "%lld 位在读": {"en": "%lld active", "zh-Hant": "%lld 位在讀"},
    "%lld 位学生": {"en": "%lld students", "zh-Hant": "%lld 位學生"},
    "%lld 张账单": {"en": "%lld bills", "zh-Hant": "%lld 張帳單"},
    "%lld 待收": {"en": "%lld unpaid", "zh-Hant": "%lld 待收"},
    "%lld 节课待出账": {"en": "%lld lessons to bill", "zh-Hant": "%lld 節課待出帳"},
    "还有 %lld 节课…": {"en": "%lld more lessons…", "zh-Hant": "還有 %lld 節課…"},
    "剩 %lld 节": {"en": "%lld left", "zh-Hant": "剩 %lld 節"},
    "+%lld 节": {"en": "+%lld sessions", "zh-Hant": "+%lld 節"},
    "-%lld 节": {"en": "-%lld sessions", "zh-Hant": "-%lld 節"},
    "%.0f 小时": {"en": "%.0f hours", "zh-Hant": "%.0f 小時"},
    "%.1f 小时": {"en": "%.1f hours", "zh-Hant": "%.1f 小時"},
    "%@/小时": {"en": "%@/hour", "zh-Hant": "%@/小時"},
    "预览：%@": {"en": "Preview: %@", "zh-Hant": "預覽：%@"},
    "默认单价（%@）": {"en": "Default rate (%@)", "zh-Hant": "預設單價（%@）"},
    "本次单价（%@）": {"en": "Rate for this lesson (%@)", "zh-Hant": "本次單價（%@）"},
    "待收 %@ · %lld 位学生": {
        "en": "Pending %@ · %lld students",
        "zh-Hant": "待收 %@ · %lld 位學生",
    },
    "%lld 张账单 · %lld 位学生": {
        "en": "%lld bills · %lld students",
        "zh-Hant": "%lld 張帳單 · %lld 位學生",
    },
    "%lld 张账单 · 合计 %@": {
        "en": "%lld bills · total %@",
        "zh-Hant": "%lld 張帳單 · 合計 %@",
    },
    "%@没有待出账课时，试试调整筛选": {
        "en": "No lessons to bill for %@. Try adjusting filters.",
        "zh-Hant": "%@沒有待出帳課時，試試調整篩選",
    },
    "将为 %@ 生成一张账单，汇总所选课时。家长收到的是一张总账，不是每节课单独一张。": {
        "en": (
            "A bill will be created for %@ with the selected lessons. "
            "Parents get one total bill, not one per lesson."
        ),
        "zh-Hant": "將為 %@ 產生一張帳單，彙總所選課時。家長收到的是一張總帳，不是每節課單獨一張。",
    },
    "未填写本科目，保存后将使用「%@」。是否直接保存？": {
        "en": "No subject entered. After saving, “%@” will be used. Save anyway?",
        "zh-Hant": "未填寫本科目，儲存後將使用「%@」。是否直接儲存？",
    },
    "导出说明,课酬记 · %@ · %@": {
        "en": "Export note,TutorLedger · %@ · %@",
        "zh-Hant": "匯出說明,課酬記 · %@ · %@",
    },
    "导出说明,课酬记 · %@ · 待出账": {
        "en": "Export note,TutorLedger · %@ · To bill",
        "zh-Hant": "匯出說明,課酬記 · %@ · 待出帳",
    },
    "导出说明,课酬记 · %@ · 已出账单": {
        "en": "Export note,TutorLedger · %@ · Issued bills",
        "zh-Hant": "匯出說明,課酬記 · %@ · 已出帳單",
    },
    "作废课时返还：%@": {
        "en": "Voided lesson refund: %@",
        "zh-Hant": "作廢課時返還：%@",
    },
    "购课 %lld 节": {
        "en": "Purchased %lld sessions",
        "zh-Hant": "購課 %lld 節",
    },
}


def to_hant(s: str) -> str:
    if s in ZH_HANT_OVERRIDE:
        return ZH_HANT_OVERRIDE[s]
    t = cc.convert(s)
    return t.replace("賬單", "帳單")


def is_date_format(s: str) -> bool:
    return ("年" in s or "月" in s) and any(ch in s for ch in "MdyHmsE")


def has_cjk(s: str) -> bool:
    return any("\u4e00" <= c <= "\u9fff" for c in s)


def collect_static_strings() -> set[str]:
    pat = re.compile(r'"((?:\\.|[^"\\])*)"')
    result = set()
    for dirpath, _, files in os.walk(ROOT):
        for name in files:
            if not name.endswith(".swift"):
                continue
            text = open(os.path.join(dirpath, name), encoding="utf-8").read()
            for line in text.splitlines():
                code = line.split("//")[0]
                for match in pat.finditer(code):
                    s = match.group(1).replace('\\"', '"').replace("\\n", "\n")
                    if not has_cjk(s):
                        continue
                    if "\\(" in s:
                        continue
                    if is_date_format(s):
                        continue
                    result.add(s)
    return result


def localization_unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def main() -> None:
    strings: dict = {}
    missing_en = []

    for s in sorted(collect_static_strings()):
        en = EN.get(s)
        if en is None:
            missing_en.append(s)
            en = s
        strings[s] = {
            "extractionState": "manual",
            "localizations": {
                "en": localization_unit(en),
                "zh-Hans": localization_unit(s),
                "zh-Hant": localization_unit(to_hant(s) if s not in ZH_HANT_OVERRIDE else ZH_HANT_OVERRIDE[s]),
            },
        }

    for key, locs in FORMAT_ENTRIES.items():
        strings[key] = {
            "extractionState": "manual",
            "localizations": {
                "en": localization_unit(locs["en"]),
                "zh-Hans": localization_unit(key),
                "zh-Hant": localization_unit(locs["zh-Hant"]),
            },
        }

    # Ensure product-critical keys exist even if not currently in source as literals
    extras = {
        "课酬记": "TutorLedger",
        "未设置": "Not set",
        "导出说明": "Export note",
        "导出范围": "Export scope",
        "字段,值": "Field,Value",
        "类型": "Type",
        "_账单": "_Bill",
    }
    for key, en in extras.items():
        if key not in strings:
            strings[key] = {
                "extractionState": "manual",
                "localizations": {
                    "en": localization_unit(en),
                    "zh-Hans": localization_unit(key),
                    "zh-Hant": localization_unit(to_hant(key)),
                },
            }

    catalog = {
        "sourceLanguage": "zh-Hans",
        "strings": dict(sorted(strings.items())),
        "version": "1.0",
    }

    resources = os.path.join(ROOT, "Resources")
    os.makedirs(resources, exist_ok=True)
    out = os.path.join(resources, "Localizable.xcstrings")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
        f.write("\n")

    info = {
        "sourceLanguage": "zh-Hans",
        "strings": {
            "CFBundleDisplayName": {
                "extractionState": "manual",
                "localizations": {
                    "en": localization_unit("TutorLedger"),
                    "zh-Hans": localization_unit("课酬记"),
                    "zh-Hant": localization_unit("課酬記"),
                },
            }
        },
        "version": "1.0",
    }
    info_out = os.path.join(resources, "InfoPlist.xcstrings")
    with open(info_out, "w", encoding="utf-8") as f:
        json.dump(info, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Wrote {len(strings)} keys -> {out}")
    print(f"Missing EN: {len(missing_en)}")
    for s in missing_en:
        print(f"  - {s}")


if __name__ == "__main__":
    main()
