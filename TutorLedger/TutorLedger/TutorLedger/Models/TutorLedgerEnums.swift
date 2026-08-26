import Foundation

enum BillingMode: String, CaseIterable, Identifiable {
    case prepaid
    case postpaid
    case perSession

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prepaid: String(localized: "先付课包")
        case .postpaid: String(localized: "课后结算")
        case .perSession: String(localized: "按次现结")
        }
    }
}

enum StudentStatus: String, CaseIterable, Identifiable {
    case active
    case paused
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: String(localized: "在读")
        case .paused: String(localized: "停课")
        case .archived: String(localized: "结课")
        }
    }
}

enum GradeLevel: String, CaseIterable, Identifiable {
    case primary
    case junior
    case senior
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .primary: String(localized: "小学")
        case .junior: String(localized: "初中")
        case .senior: String(localized: "高中")
        case .other: String(localized: "其他")
        }
    }
}

enum SettlementCycle: String, CaseIterable, Identifiable {
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: String(localized: "周结")
        case .monthly: String(localized: "月结")
        }
    }
}

enum LessonType: String, CaseIterable, Identifiable {
    case normal
    case trial
    case makeup
    case free

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: String(localized: "正常")
        case .trial: String(localized: "试讲")
        case .makeup: String(localized: "补课")
        case .free: String(localized: "赠课")
        }
    }
}

enum LessonBillingStatus: String, CaseIterable {
    case deducted
    case pending
    case billed
    case paid
    case void

    var title: String {
        switch self {
        case .deducted: String(localized: "已扣课")
        case .pending: String(localized: "待结算")
        case .billed: String(localized: "已出账")
        case .paid: String(localized: "已收款")
        case .void: String(localized: "已作废")
        }
    }
}

enum BillStatus: String, CaseIterable, Identifiable {
    case draft
    case sent
    case paid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: String(localized: "待发送")
        case .sent: String(localized: "已发送")
        case .paid: String(localized: "已收款")
        }
    }
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case wechat
    case alipay
    case cash
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wechat: String(localized: "微信")
        case .alipay: String(localized: "支付宝")
        case .cash: String(localized: "现金")
        case .other: String(localized: "其他")
        }
    }
}

enum PackageTransactionType: String {
    case purchase
    case deduct
    case adjust

    var title: String {
        switch self {
        case .purchase: String(localized: "购课")
        case .deduct: String(localized: "扣课")
        case .adjust: String(localized: "调整")
        }
    }
}
