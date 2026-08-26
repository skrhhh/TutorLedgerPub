import SwiftData
import SwiftUI

struct StudentsListView: View {
    @Query(sort: \Student.name) private var students: [Student]

    @State private var filter: StudentStatus? = .active
    @State private var searchText = ""
    @State private var showAddStudent = false

    private var filteredStudents: [Student] {
        var result: [Student]
        if let filter {
            result = students.filter { $0.status == filter }
        } else {
            result = students
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return result }
        return result.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.primarySubject.localizedCaseInsensitiveContains(query)
                || $0.subjectsRaw.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            TLPageScaffold(
                title: String(localized: "学生"),
                subtitle: String(localized: "\(students.filter { $0.status == .active }.count) 位在读"),
                trailingIcon: "plus.circle.fill",
                onTrailing: { showAddStudent = true }
            ) {
                Group {
                    if students.isEmpty {
                        EmptyStateView(
                            icon: "person.2.fill",
                            title: String(localized: "还没有学生"),
                            message: String(localized: "添加第一个学生，开始记录课时与课酬"),
                            actionTitle: String(localized: "添加学生")
                        ) { showAddStudent = true }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                TLTextInput(placeholder: String(localized: "搜索姓名或科目"), text: $searchText)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        TLFilterChip(title: String(localized: "全部"), isSelected: filter == nil) { filter = nil }
                                        ForEach(StudentStatus.allCases) { status in
                                            TLFilterChip(title: status.title, isSelected: filter == status) {
                                                filter = status
                                            }
                                        }
                                    }
                                }

                                ForEach(filteredStudents) { student in
                                    NavigationLink {
                                        StudentDetailView(student: student)
                                    } label: {
                                        StudentRowView(student: student)
                                            .tlCard(padding: 14)
                                    }
                                    .buttonStyle(.plain)
                                }

                                if filteredStudents.isEmpty {
                                    Text(searchText.isEmpty
                                          ? String(localized: "暂无学生")
                                          : String(localized: "未找到匹配的学生"))
                                        .font(.subheadline)
                                        .foregroundStyle(TLColors.secondaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        }
                        .tlKeyboardDismissibleScroll()
                    }
                }
            }
            .sheet(isPresented: $showAddStudent) {
                AddEditStudentView()
            }
        }
    }
}
