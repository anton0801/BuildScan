import SwiftUI

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var showNewReport = false
    @State private var newReportTitle = ""
    @State private var showExport = false
    @State private var exportReport: Report?

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.l) {
                        if dataStore.reports.isEmpty {
                            EmptyStateCard(
                                icon: "doc.text",
                                title: "No Reports",
                                subtitle: "Generate your first wall inspection report",
                                color: DS.Colors.purple
                            )
                            .padding()

                            PrimaryButton("Generate Report", icon: "plus.circle") {
                                showNewReport = true
                            }
                            .padding(.horizontal, DS.Spacing.l)
                        } else {
                            ForEach(dataStore.reports) { report in
                                ReportCard(report: report, scanCount: report.scanIds.count) {
                                    exportReport = report
                                    showExport = true
                                } onDelete: {
                                    dataStore.deleteReport(report)
                                }
                                .padding(.horizontal, DS.Spacing.l)
                            }
                            Spacer(minLength: 40)
                        }
                    }
                    .padding(.top, DS.Spacing.m)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(DS.Colors.cyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewReport = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(DS.Colors.cyan)
                    }
                }
            }
            .sheet(isPresented: $showNewReport) {
                NewReportSheet(isPresented: $showNewReport, title: $newReportTitle, dataStore: dataStore)
            }
            .sheet(item: $exportReport) { report in
                ExportView(report: report)
                    .environmentObject(dataStore)
            }
        }
    }
}

struct ReportCard: View {
    let report: Report
    let scanCount: Int
    let onExport: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(DS.Colors.purple)
                        .padding(8)
                        .background(DS.Colors.purple.opacity(0.12))
                        .cornerRadius(DS.Radius.s)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.title)
                            .font(DS.Typography.subheading())
                            .foregroundColor(DS.Colors.textPrimary)
                        Text(report.createdAt, style: .date)
                            .font(DS.Typography.caption(11))
                            .foregroundColor(DS.Colors.textMuted)
                    }
                    Spacer()
                    Menu {
                        Button("Export") { onExport() }
                        Button("Delete", role: .destructive) { showDeleteConfirm = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(DS.Colors.textMuted)
                    }
                }

                Divider().background(DS.Colors.divider)

                HStack {
                    Label("\(scanCount) scans", systemImage: "camera.fill")
                        .font(DS.Typography.caption())
                        .foregroundColor(DS.Colors.textMuted)
                    Spacer()
                    Button(action: onExport) {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .font(DS.Typography.caption())
                            .foregroundColor(DS.Colors.cyan)
                    }
                }
            }
        }
        .alert("Delete Report?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct NewReportSheet: View {
    @Binding var isPresented: Bool
    @Binding var title: String
    let dataStore: DataStore
    @State private var selectedScans: Set<String> = []
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.l) {
                        BSTextField(placeholder: "Report title", text: $title, icon: "doc.text.fill")
                            .padding(.horizontal, DS.Spacing.l)

                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            Text("Select Scans")
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.textMuted)
                                .padding(.horizontal, DS.Spacing.l)

                            ForEach(dataStore.scans) { scan in
                                HStack {
                                    ScanRowCard(scan: scan, rooms: dataStore.rooms)
                                    Image(systemName: selectedScans.contains(scan.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedScans.contains(scan.id) ? DS.Colors.cyan : DS.Colors.textMuted)
                                }
                                .padding(.horizontal, DS.Spacing.l)
                                .onTapGesture {
                                    if selectedScans.contains(scan.id) {
                                        selectedScans.remove(scan.id)
                                    } else {
                                        selectedScans.insert(scan.id)
                                    }
                                }
                            }
                        }

                        PrimaryButton("Generate Report", icon: "doc.badge.plus") {
                            guard !title.isEmpty else { return }
                            let report = Report(title: title, scanIds: Array(selectedScans), notes: notes,
                                               summary: "Report for \(selectedScans.count) scans")
                            dataStore.addReport(report)
                            isPresented = false
                        }
                        .padding(.horizontal, DS.Spacing.l)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, DS.Spacing.l)
                }
            }
            .navigationTitle("New Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }.foregroundColor(DS.Colors.textMuted)
                }
            }
        }
    }
}

// MARK: - Export View
struct ExportView: View {
    let report: Report
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var exported = false

    var reportScans: [Scan] { dataStore.scans.filter { report.scanIds.contains($0.id) } }

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.xl) {
                        // Export preview
                        DSCard {
                            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(DS.Colors.purple)
                                        .font(.system(size: 24))
                                    Text(report.title)
                                        .font(DS.Typography.heading())
                                        .foregroundColor(DS.Colors.textPrimary)
                                }

                                Divider().background(DS.Colors.divider)

                                Text("Generated: \(report.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.textMuted)

                                Text("Total Scans: \(reportScans.count)")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.textMuted)

                                let high = reportScans.filter { $0.riskLevel == .high }.count
                                let med = reportScans.filter { $0.riskLevel == .medium }.count
                                if high > 0 {
                                    Text("⚠️ \(high) high-risk issues require immediate attention")
                                        .font(DS.Typography.caption())
                                        .foregroundColor(DS.Colors.danger)
                                }

                                if !reportScans.isEmpty {
                                    Divider().background(DS.Colors.divider)
                                    ForEach(reportScans.prefix(3)) { scan in
                                        HStack {
                                            Text(scan.crackType.rawValue)
                                                .font(DS.Typography.caption())
                                                .foregroundColor(DS.Colors.textSecondary)
                                            Spacer()
                                            RiskBadge(level: scan.riskLevel)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        // Export options
                        VStack(spacing: DS.Spacing.m) {
                            ExportOptionButton(icon: "doc.text", label: "Export as PDF", subtitle: "Formatted report document") {
                                exported = true
                            }
                            ExportOptionButton(icon: "tablecells", label: "Export as CSV", subtitle: "Spreadsheet data") {
                                exported = true
                            }
                            ExportOptionButton(icon: "square.and.arrow.up", label: "Share Report", subtitle: "Send via AirDrop, Mail, etc.") {
                                shareReport()
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        if exported {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DS.Colors.safe)
                                Text("Report exported successfully!")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.safe)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, DS.Spacing.l)
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(DS.Colors.cyan)
                }
            }
        }
    }

    private func shareReport() {
        let content = """
        Build Scan Report: \(report.title)
        Generated: \(report.createdAt.formatted())
        Total Scans: \(reportScans.count)
        
        Issues:
        \(reportScans.map { "- \($0.crackType.rawValue): \($0.riskLevel.rawValue)" }.joined(separator: "\n"))
        """
        let av = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true)
    }
}

struct ExportOptionButton: View {
    let icon: String
    let label: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            DSCard(padding: DS.Spacing.m) {
                HStack(spacing: DS.Spacing.m) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(DS.Colors.cyan)
                        .frame(width: 40, height: 40)
                        .background(DS.Colors.cyan.opacity(0.12))
                        .cornerRadius(DS.Radius.s)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(DS.Typography.subheading(14))
                            .foregroundColor(DS.Colors.textPrimary)
                        Text(subtitle)
                            .font(DS.Typography.caption(11))
                            .foregroundColor(DS.Colors.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(DS.Colors.textMuted)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddTask = false
    @State private var filterStatus: TaskStatus? = nil
    @State private var showTaskDetail: RepairTask? = nil

    var filteredTasks: [RepairTask] {
        if let s = filterStatus { return dataStore.tasks.filter { $0.status == s } }
        return dataStore.tasks
    }

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Repair Tasks")
                                .font(DS.Typography.display(26))
                                .foregroundColor(DS.Colors.textPrimary)
                            Text("\(dataStore.tasks.filter { $0.status != .done }.count) pending")
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.textMuted)
                        }
                        Spacer()
                        Button(action: { showAddTask = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(DS.Colors.cyan)
                                .padding(10)
                                .background(DS.Colors.card)
                                .cornerRadius(DS.Radius.m)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.top, DS.Spacing.l)
                    .padding(.bottom, DS.Spacing.m)

                    // Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.s) {
                            FilterChip(label: "All", isSelected: filterStatus == nil) { filterStatus = nil }
                            ForEach(TaskStatus.allCases, id: \.self) { status in
                                FilterChip(label: status.rawValue, isSelected: filterStatus == status) {
                                    filterStatus = filterStatus == status ? nil : status
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)
                    }
                    .padding(.bottom, DS.Spacing.m)

                    if filteredTasks.isEmpty {
                        Spacer()
                        EmptyStateCard(
                            icon: "checkmark.circle",
                            title: filterStatus != nil ? "No \(filterStatus!.rawValue) Tasks" : "All Clear!",
                            subtitle: "Create tasks to track repair work",
                            color: DS.Colors.safe
                        )
                        .padding(.horizontal, DS.Spacing.l)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: DS.Spacing.s) {
                                ForEach(filteredTasks) { task in
                                    TaskCard(task: task) {
                                        var updated = task
                                        switch task.status {
                                        case .pending: updated.status = .inProgress
                                        case .inProgress: updated.status = .done
                                        case .done: updated.status = .pending
                                        }
                                        dataStore.updateTask(updated)
                                    } onDelete: {
                                        dataStore.deleteTask(task)
                                    }
                                    .padding(.horizontal, DS.Spacing.l)
                                }
                                Spacer(minLength: 100)
                            }
                            .padding(.top, DS.Spacing.s)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet(isPresented: $showAddTask, dataStore: dataStore)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TaskCard: View {
    let task: RepairTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false

    var statusIcon: String {
        switch task.status {
        case .pending: return "circle"
        case .inProgress: return "circle.dotted"
        case .done: return "checkmark.circle.fill"
        }
    }

    var statusColor: Color {
        switch task.status {
        case .pending: return DS.Colors.textMuted
        case .inProgress: return DS.Colors.warning
        case .done: return DS.Colors.safe
        }
    }

    var body: some View {
        DSCard(padding: DS.Spacing.m) {
            HStack(spacing: DS.Spacing.m) {
                Button(action: onToggle) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 24))
                        .foregroundColor(statusColor)
                }
                .buttonStyle(ScaleButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(task.title)
                            .font(DS.Typography.subheading(14))
                            .foregroundColor(task.status == .done ? DS.Colors.textMuted : DS.Colors.textPrimary)
                            .strikethrough(task.status == .done)

                        Spacer()

                        // Priority
                        Text(task.priority.rawValue)
                            .font(DS.Typography.caption(10))
                            .foregroundColor(task.priority.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(task.priority.color.opacity(0.12))
                            .cornerRadius(DS.Radius.full)
                    }

                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(DS.Typography.caption())
                            .foregroundColor(DS.Colors.textMuted)
                            .lineLimit(2)
                    }

                    HStack(spacing: DS.Spacing.s) {
                        if let due = task.dueDate {
                            Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .font(DS.Typography.caption(11))
                                .foregroundColor(due < Date() && task.status != .done ? DS.Colors.danger : DS.Colors.textMuted)
                        }
                        Spacer()
                        Text(task.status.rawValue)
                            .font(DS.Typography.caption(11))
                            .foregroundColor(statusColor)
                    }
                }

                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(DS.Colors.textMuted)
                }
            }
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct AddTaskSheet: View {
    @Binding var isPresented: Bool
    let dataStore: DataStore
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400 * 7)

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.l) {
                        BSTextField(placeholder: "Task title", text: $title, icon: "checkmark.circle")
                        BSTextField(placeholder: "Description", text: $description, icon: "text.alignleft")

                        // Priority
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text("Priority")
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.textMuted)
                            HStack(spacing: DS.Spacing.s) {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        Text(p.rawValue)
                                            .font(DS.Typography.caption())
                                            .foregroundColor(priority == p ? DS.Colors.btnPrimaryText : p.color)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(priority == p ? p.color : p.color.opacity(0.12))
                                            .cornerRadius(DS.Radius.full)
                                    }
                                }
                            }
                        }

                        // Due date
                        DSCard(padding: DS.Spacing.m) {
                            VStack(spacing: DS.Spacing.m) {
                                Toggle(isOn: $hasDueDate) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(DS.Colors.cyan)
                                        Text("Set Due Date")
                                            .font(DS.Typography.body())
                                            .foregroundColor(DS.Colors.textPrimary)
                                    }
                                }
                                .tint(DS.Colors.cyan)

                                if hasDueDate {
                                    DatePicker("", selection: $dueDate, in: Date()..., displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .colorScheme(.dark)
                                }
                            }
                        }

                        PrimaryButton("Add Task", icon: "plus.circle") {
                            guard !title.isEmpty else { return }
                            let task = RepairTask(
                                title: title,
                                description: description,
                                priority: priority,
                                status: .pending,
                                dueDate: hasDueDate ? dueDate : nil
                            )
                            dataStore.addTask(task)
                            isPresented = false
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.top, DS.Spacing.l)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }.foregroundColor(DS.Colors.textMuted)
                }
            }
        }
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.s) {
                        if dataStore.activities.isEmpty {
                            EmptyStateCard(
                                icon: "clock.arrow.circlepath",
                                title: "No Activity",
                                subtitle: "Actions will appear here",
                                color: DS.Colors.purple
                            )
                            .padding()
                        } else {
                            ForEach(dataStore.activities) { activity in
                                ActivityRow(activity: activity)
                                    .padding(.horizontal, DS.Spacing.l)
                            }
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.top, DS.Spacing.m)
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(DS.Colors.cyan)
                }
            }
        }
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: activity.type.icon)
                .font(.system(size: 16))
                .foregroundColor(activity.type.color)
                .frame(width: 38, height: 38)
                .background(activity.type.color.opacity(0.12))
                .cornerRadius(DS.Radius.s)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(DS.Typography.body())
                    .foregroundColor(DS.Colors.textPrimary)
                Text(activity.timestamp, style: .relative)
                    .font(DS.Typography.caption(11))
                    .foregroundColor(DS.Colors.textMuted)
            }
            Spacer()
        }
        .padding(DS.Spacing.m)
        .background(DS.Colors.card)
        .cornerRadius(DS.Radius.m)
    }
}
