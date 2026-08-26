import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [TLColors.cyan.opacity(0.25), TLColors.mint.opacity(0.08)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 50
                        )
                    )
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(TLColors.breezeGradient)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TLColors.primaryText)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(TLColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(TLPrimaryButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var icon: String?
    var subtitle: String?
    var tint: Color = TLColors.teal

    private var valueGradient: LinearGradient {
        if tint == TLColors.income { return TLColors.incomeGradient }
        if tint == TLColors.pending { return TLColors.pendingGradient }
        return LinearGradient(
            colors: [tint, tint.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let icon {
                    TLIconBadge(icon: icon, color: tint, size: 32)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(valueGradient)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(tint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tlCard(padding: 14)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 60, height: 60)
                .offset(x: 8, y: -8)
                .allowsHitTesting(false)
        }
    }
}

struct LessonRowView: View {
    let lesson: LessonRecord

    private var dateText: String {
        TLDateFormat.monthDayTime(lesson.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            TLAvatarView(name: lesson.student?.name ?? "?", size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.student?.name ?? String(localized: "未知学生"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLColors.primaryText)
                Text("\(dateText) · \(lesson.subject)")
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
                Text(MoneyFormat.display(hours: lesson.durationHours))
                    .font(.caption2)
                    .foregroundStyle(TLColors.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(MoneyFormat.display(cents: lesson.amountCents))
                    .font(.subheadline.bold())
                    .foregroundStyle(lesson.billingStatus == .void
                        ? AnyShapeStyle(TLColors.secondaryText)
                        : AnyShapeStyle(TLColors.incomeGradient))
                    .strikethrough(lesson.billingStatus == .void, color: TLColors.secondaryText)
                TLStatusBadge(text: lesson.billingStatus.title, color: statusColor)
            }
        }
        .padding(.vertical, 6)
        .opacity(lesson.billingStatus == .void ? 0.72 : 1)
    }

    private var statusColor: Color {
        switch lesson.billingStatus {
        case .paid, .deducted: TLColors.income
        case .pending, .billed: TLColors.pending
        case .void: TLColors.secondaryText
        }
    }
}

struct StudentRowView: View {
    let student: Student

    var body: some View {
        HStack(spacing: 12) {
            TLAvatarView(name: student.name, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLColors.primaryText)
                Text("\(student.grade.title) · \(student.primarySubject)")
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
                TLStatusBadge(text: student.billingMode.title, color: TLColors.teal)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if student.billingMode == .prepaid {
                    Text(String(localized: "剩 \(student.packageRemainingHours) 节"))
                        .font(.subheadline.bold())
                        .foregroundStyle(
                            student.isLowPackage
                                ? TLColors.pendingGradient
                                : TLColors.accentGradient
                        )
                } else if student.pendingAmountCents > 0 {
                    Text(MoneyFormat.display(cents: student.pendingAmountCents))
                        .font(.subheadline.bold())
                        .foregroundStyle(TLColors.pendingGradient)
                }
                Text(student.status.title)
                    .font(.caption2)
                    .foregroundStyle(TLColors.secondaryText)
            }
        }
        .padding(.vertical, 6)
    }
}

struct TLFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : TLColors.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        TLColors.breezeGradient
                    } else {
                        TLColors.softFillGradient
                    }
                }
                .clipShape(Capsule())
                .overlay {
                    if !isSelected {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [TLColors.tealLight.opacity(0.4), TLColors.cyan.opacity(0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct UpcomingLessonRowView: View {
    let student: Student
    let date: Date

    var body: some View {
        HStack(spacing: 12) {
            TLAvatarView(name: student.name, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLColors.primaryText)
                Text(student.primarySubject)
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(relativeDayText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLColors.teal)
                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }

    private var relativeDayText: String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDateInToday(date) { return String(localized: "今天") }
        if calendar.isDateInTomorrow(date) { return String(localized: "明天") }
        return TLDateFormat.monthDay(date)
    }

    private var timeText: String {
        TLDateFormat.time(date)
    }
}

struct PackageTransactionRowView: View {
    let transaction: PackageTransaction

    var body: some View {
        HStack(spacing: 12) {
            TLIconBadge(icon: iconName, color: tintColor, size: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TLColors.primaryText)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(TLColors.secondaryText)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption2)
                        .foregroundStyle(TLColors.secondaryText)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(hoursText)
                    .font(.subheadline.bold())
                    .foregroundStyle(hoursGradient)
                if let amount = transaction.amountCents, amount > 0 {
                    Text(MoneyFormat.display(cents: amount))
                        .font(.caption)
                        .foregroundStyle(TLColors.incomeGradient)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch transaction.type {
        case .purchase: "plus.circle.fill"
        case .deduct: "minus.circle.fill"
        case .adjust: "arrow.triangle.2.circlepath"
        }
    }

    private var tintColor: Color {
        switch transaction.type {
        case .purchase: TLColors.income
        case .deduct: TLColors.pending
        case .adjust: TLColors.cyan
        }
    }

    private var hoursText: String {
        switch transaction.type {
        case .purchase:
            return String(localized: "+\(transaction.hours) 节")
        case .deduct:
            return String(localized: "-\(transaction.hours) 节")
        case .adjust:
            return transaction.hours >= 0
                ? String(localized: "+\(transaction.hours) 节")
                : String(localized: "\(transaction.hours) 节")
        }
    }

    private var hoursGradient: LinearGradient {
        switch transaction.type {
        case .purchase: TLColors.incomeGradient
        case .deduct: TLColors.pendingGradient
        case .adjust: TLColors.accentGradient
        }
    }

    private var formattedDate: String {
        TLDateFormat.monthDayTime(transaction.date)
    }
}
