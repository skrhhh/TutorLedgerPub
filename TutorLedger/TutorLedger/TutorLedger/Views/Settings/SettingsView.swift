import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("currencySymbol") private var currencySymbol = "¥"

    @State private var defaultDuration = AppSettings.defaultDurationHours
    @State private var durationPresetsText = AppSettings.durationPresetsText
    @State private var customCurrencyText = ""
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var exportError: String?
    @State private var showExportError = false
    @State private var lastExportText = AppSettings.lastExportDisplayText

    private var isCustomCurrency: Bool {
        !AppSettings.commonCurrencySymbols.contains(currencySymbol)
    }

    var body: some View {
        NavigationStack {
            TLPageScaffold(title: String(localized: "设置")) {
                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(TLColors.breezeGradient)
                                    .frame(width: 56, height: 56)
                                Image(systemName: "book.closed.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("课酬记")
                                    .font(.title3.bold())
                                    .foregroundStyle(TLColors.primaryText)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
                                Text("记录课时，算清课酬")
                                    .font(.caption)
                                    .foregroundStyle(TLColors.secondaryText)
                            }
                            Spacer()
                            Text(AppSettings.appVersionText)
                                .font(.caption)
                                .foregroundStyle(TLColors.secondaryText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(TLColors.softFillGradient)
                                .clipShape(Capsule())
                        }
                        .tlCard(padding: 14)

                        if AppSettings.needsBackupReminder {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(TLColors.pending)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("建议备份数据")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(TLColors.primaryText)
                                    Text("数据仅保存在本机，换机前请导出 CSV 备份。建议每月至少备份一次。")
                                        .font(.caption)
                                        .foregroundStyle(TLColors.secondaryText)
                                }
                            }
                            .tlCard(padding: 14)
                        }

                        TLFormCard(title: String(localized: "默认设置"), icon: "slider.horizontal.3") {
                            TLFormRow(label: String(localized: "默认课时时长")) {
                                TLDurationPicker(hours: $defaultDuration)
                            }
                            .onChange(of: defaultDuration) { _, v in
                                AppSettings.defaultDurationHours = v
                            }

                            TLFormRow(label: String(localized: "时长快捷选项")) {
                                VStack(alignment: .leading, spacing: 6) {
                                    TLTextInput(
                                        placeholder: "1, 1.5, 2, 2.5, 3",
                                        text: $durationPresetsText
                                    )
                                    Text("逗号分隔，记课时可快速选择")
                                        .font(.caption2)
                                        .foregroundStyle(TLColors.secondaryText)
                                }
                            }
                            .onChange(of: durationPresetsText) { _, v in
                                AppSettings.durationPresetsText = v
                            }

                            TLFormRow(label: String(localized: "货币符号")) {
                                VStack(alignment: .leading, spacing: 10) {
                                    FlowLayout(spacing: 8) {
                                        ForEach(AppSettings.commonCurrencySymbols, id: \.self) { symbol in
                                            currencyChip(symbol)
                                        }
                                        currencyChip(String(localized: "自定义"), isCustom: true)
                                    }
                                    if isCustomCurrency {
                                        TLTextInput(
                                            placeholder: String(localized: "输入符号，如 ₱"),
                                            text: $customCurrencyText
                                        )
                                        .onChange(of: customCurrencyText) { _, v in
                                            let trimmed = v.trimmingCharacters(in: .whitespacesAndNewlines)
                                            if !trimmed.isEmpty { currencySymbol = trimmed }
                                        }
                                    }
                                    Text(String(format: String(localized: "预览：%@"), MoneyFormat.display(cents: 123450)))
                                        .font(.caption)
                                        .foregroundStyle(TLColors.teal)
                                }
                            }
                        }

                        #if DEBUG
                        TLFormCard(title: String(localized: "演示数据"), icon: "hammer.fill") {
                            Button("填入本月演示流水") {
                                DemoSeed.populate(context: modelContext, reset: true)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TLColors.teal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text("会清空当前学生后写入本月虚构课时，仅调试包可用。")
                                .font(.caption)
                                .foregroundStyle(TLColors.secondaryText)
                        }
                        #endif

                        TLFormCard(title: String(localized: "数据"), icon: "externaldrive") {
                            TLDetailRow(
                                label: String(localized: "上次导出"),
                                value: lastExportText,
                                valueColor: TLColors.secondaryText
                            )
                            TLSettingsRow(icon: "square.and.arrow.up", title: String(localized: "导出 / 分享 CSV")) {
                                shareCSV()
                            }
                            Button("重新查看引导") {
                                hasCompletedOnboarding = false
                            }
                            .font(.subheadline)
                            .foregroundStyle(TLColors.teal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                        }

                        TLFormCard(title: String(localized: "关于与支持"), icon: "doc.text") {
                            legalLinkRow(
                                icon: "hand.raised",
                                title: String(localized: "隐私政策"),
                                url: LegalLinks.privacyPolicy
                            )
                            legalLinkRow(
                                icon: "doc.plaintext",
                                title: String(localized: "用户协议"),
                                url: LegalLinks.termsOfService
                            )
                            legalLinkRow(
                                icon: "questionmark.circle",
                                title: String(localized: "支持与帮助"),
                                url: LegalLinks.support
                            )
                            TLSettingsRow(
                                icon: "envelope",
                                title: String(localized: "联系邮箱"),
                                value: LegalLinks.supportEmail
                            ) {
                                if let url = URL(string: "mailto:\(LegalLinks.supportEmail)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }

                        Text("数据保存在本机，无需登录 · 暂无 iCloud 同步")
                            .font(.caption)
                            .foregroundStyle(TLColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .tlKeyboardDismissibleScroll()
            }
            .activityShareSheet(isPresented: $showShareSheet, items: shareItems) { completed in
                if completed {
                    AppSettings.lastExportDate = .now
                    lastExportText = AppSettings.lastExportDisplayText
                }
            }
            .alert("导出失败", isPresented: $showExportError) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
            .onAppear {
                lastExportText = AppSettings.lastExportDisplayText
                if isCustomCurrency {
                    customCurrencyText = currencySymbol
                }
            }
            .onChange(of: currencySymbol) { _, v in
                AppSettings.currencySymbol = v
            }
        }
    }

    private func currencyChip(_ symbol: String, isCustom: Bool = false) -> some View {
        let selected = isCustom ? isCustomCurrency : currencySymbol == symbol
        return Button {
            if isCustom {
                customCurrencyText = isCustomCurrency ? currencySymbol : ""
                if !customCurrencyText.isEmpty {
                    currencySymbol = customCurrencyText
                }
            } else {
                currencySymbol = symbol
                customCurrencyText = ""
            }
        } label: {
            Text(symbol)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? .white : TLColors.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if selected {
                        TLColors.breezeGradient
                    } else {
                        TLColors.softFillGradient
                    }
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func legalLinkRow(icon: String, title: String, url: URL) -> some View {
        TLSettingsRow(icon: icon, title: title) {
            UIApplication.shared.open(url)
        }
    }

    private func shareCSV() {
        do {
            let csv = try ExportService.makeCSV(context: modelContext)
            let url = try ShareService.temporaryCSVURL(from: csv)
            shareItems = [url]
            showShareSheet = true
            AnalyticsService.exportCSV(source: "settings")
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }
}

private enum LegalLinks {
    static let privacyPolicy = URL(string: "https://github.com/skrhhh/TutorLedger_setting/blob/main/Privacy-Policy.md")!
    static let termsOfService = URL(string: "https://github.com/skrhhh/TutorLedger_setting/blob/main/Terms-of-Service.md")!
    static let support = URL(string: "https://github.com/skrhhh/TutorLedger_setting/blob/main/Support.md")!
    static let supportEmail = "735596553@qq.com"
}
