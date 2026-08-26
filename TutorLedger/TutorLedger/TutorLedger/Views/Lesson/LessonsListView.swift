import SwiftData
import SwiftUI

struct LessonsListView: View {
    @Query(sort: \Student.name) private var students: [Student]
    @Query(sort: \LessonRecord.date, order: .reverse) private var allLessons: [LessonRecord]

    @State private var searchText = ""
    @State private var selectedStudentID: UUID?
    @State private var selectedMonth = Date.now
    @State private var filterByMonth = false
    @State private var statusFilter: LessonListStatusFilter = .active

    private var filteredLessons: [LessonRecord] {
        var result = allLessons.filter { statusFilter.includes($0.billingStatus) }

        if filterByMonth {
            let calendar = Calendar.current
            guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)),
                  let end = calendar.date(byAdding: .month, value: 1, to: start) else {
                return result
            }
            result = result.filter { $0.date >= start && $0.date < end }
        }

        if let selectedStudentID {
            result = result.filter { $0.student?.id == selectedStudentID }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                ($0.student?.name.localizedCaseInsensitiveContains(query) ?? false)
                    || $0.subject.localizedCaseInsensitiveContains(query)
                    || $0.note.localizedCaseInsensitiveContains(query)
            }
        }

        return result
    }

    private var monthTitle: String {
        TLDateFormat.yearMonth(selectedMonth)
    }

    var body: some View {
        TLPageScaffold(
            title: String(localized: "课时流水"),
            subtitle: String(localized: "\(filteredLessons.count) 条记录"),
            showBack: true
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    TLTextInput(placeholder: String(localized: "搜索学生、科目或备注"), text: $searchText)

                    TLFormCard(title: String(localized: "筛选"), icon: "line.3.horizontal.decrease.circle") {
                        HStack(spacing: 8) {
                            ForEach(LessonListStatusFilter.allCases) { filter in
                                TLFilterChip(title: filter.title, isSelected: statusFilter == filter) {
                                    statusFilter = filter
                                }
                            }
                        }

                        Toggle("按月份筛选", isOn: $filterByMonth)
                            .tint(TLColors.teal)
                        if filterByMonth {
                            HStack {
                                Button {
                                    selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(TLColors.teal)
                                        .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)

                                Text(monthTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(TLColors.primaryText)
                                    .frame(maxWidth: .infinity)

                                Button {
                                    selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(TLColors.teal)
                                        .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                TLFilterChip(title: String(localized: "全部学生"), isSelected: selectedStudentID == nil) {
                                    selectedStudentID = nil
                                }
                                ForEach(students.filter { $0.status == .active }) { student in
                                    TLFilterChip(title: student.name, isSelected: selectedStudentID == student.id) {
                                        selectedStudentID = student.id
                                    }
                                }
                            }
                        }
                    }

                    if filteredLessons.isEmpty {
                        EmptyStateView(
                            icon: "book.fill",
                            title: String(localized: "暂无课时"),
                            message: searchText.isEmpty
                                ? String(localized: "调整筛选条件试试")
                                : String(localized: "未找到匹配的课时记录")
                        )
                        .padding(.top, 20)
                    } else {
                        ForEach(filteredLessons) { lesson in
                            NavigationLink {
                                LessonDetailView(lesson: lesson)
                            } label: {
                                LessonRowView(lesson: lesson).tlCard(padding: 14)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .tlKeyboardDismissibleScroll()
        }
    }
}

private enum LessonListStatusFilter: String, CaseIterable, Identifiable {
    case active
    case voided
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: String(localized: "有效")
        case .voided: String(localized: "已作废")
        case .all: String(localized: "全部")
        }
    }

    func includes(_ status: LessonBillingStatus) -> Bool {
        switch self {
        case .active: status != .void
        case .voided: status == .void
        case .all: true
        }
    }
}
