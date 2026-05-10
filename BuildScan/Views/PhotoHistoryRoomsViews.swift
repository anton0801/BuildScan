import SwiftUI

// MARK: - Photo Storage
struct PhotoStorageView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedScan: Scan?
    @State private var filterRisk: RiskLevel? = nil
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var filteredScans: [Scan] {
        if let r = filterRisk { return dataStore.scans.filter { $0.riskLevel == r } }
        return dataStore.scans
    }

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Photo Storage")
                            .font(DS.Typography.display(26))
                            .foregroundColor(DS.Colors.textPrimary)
                        Text("\(filteredScans.count) scans")
                            .font(DS.Typography.caption())
                            .foregroundColor(DS.Colors.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.top, DS.Spacing.l)
                    .padding(.bottom, DS.Spacing.m)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.s) {
                            FilterChip(label: "All", isSelected: filterRisk == nil) { filterRisk = nil }
                            ForEach(RiskLevel.allCases, id: \.self) { level in
                                FilterChip(label: level.rawValue, isSelected: filterRisk == level, color: level.color) {
                                    filterRisk = filterRisk == level ? nil : level
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)
                    }
                    .padding(.bottom, DS.Spacing.m)

                    if filteredScans.isEmpty {
                        Spacer()
                        EmptyStateCard(
                            icon: "photo.stack",
                            title: "No Photos",
                            subtitle: "Scan walls to build your photo library",
                            color: DS.Colors.cyan
                        )
                        .padding(.horizontal, DS.Spacing.l)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: DS.Spacing.s) {
                                ForEach(filteredScans) { scan in
                                    PhotoThumbnail(scan: scan)
                                        .onTapGesture { selectedScan = scan }
                                }
                            }
                            .padding(.horizontal, DS.Spacing.l)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedScan) { scan in
                NavigationView {
                    ScanDetailView(scan: scan)
                        .environmentObject(dataStore)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PhotoThumbnail: View {
    let scan: Scan

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let img = scan.image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            } else {
                ZStack {
                    DS.Colors.card
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DS.Colors.textMuted)
                }
                .aspectRatio(1, contentMode: .fit)
            }

            // Risk badge overlay
            Circle()
                .fill(scan.riskLevel.color)
                .frame(width: 10, height: 10)
                .padding(6)
        }
        .cornerRadius(DS.Radius.s)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.s)
                .stroke(DS.Colors.divider, lineWidth: 0.5)
        )
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = DS.Colors.cyan
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DS.Typography.caption())
                .foregroundColor(isSelected ? DS.Colors.btnPrimaryText : DS.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : DS.Colors.card)
                .cornerRadius(DS.Radius.full)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : DS.Colors.divider, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedScan: Scan?

    var sortedScans: [Scan] {
        dataStore.scans.sorted { $0.createdAt > $1.createdAt }
    }

    var groupedScans: [(String, [Scan])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var groups: [String: [Scan]] = [:]
        for scan in sortedScans {
            let key = formatter.string(from: scan.createdAt)
            groups[key, default: []].append(scan)
        }
        return groups.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.l) {
                        if sortedScans.isEmpty {
                            EmptyStateCard(
                                icon: "clock.arrow.circlepath",
                                title: "No History Yet",
                                subtitle: "Your scan history will appear here",
                                color: DS.Colors.purple
                            )
                            .padding()
                        } else {
                            ForEach(groupedScans, id: \.0) { date, scans in
                                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                    Text(date)
                                        .font(DS.Typography.caption())
                                        .foregroundColor(DS.Colors.textMuted)
                                        .padding(.horizontal, DS.Spacing.l)

                                    ForEach(scans) { scan in
                                        ScanRowCard(scan: scan, rooms: dataStore.rooms)
                                            .padding(.horizontal, DS.Spacing.l)
                                            .onTapGesture { selectedScan = scan }
                                    }
                                }
                            }
                            Spacer(minLength: 40)
                        }
                    }
                    .padding(.top, DS.Spacing.l)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(DS.Colors.cyan)
                }
            }
            .sheet(item: $selectedScan) { scan in
                NavigationView {
                    ScanDetailView(scan: scan)
                        .environmentObject(dataStore)
                }
            }
        }
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    @EnvironmentObject var dataStore: DataStore

    var sortedScans: [Scan] { dataStore.scans.sorted { $0.createdAt < $1.createdAt } }

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sortedScans.enumerated()), id: \.element.id) { idx, scan in
                        HStack(alignment: .top, spacing: DS.Spacing.m) {
                            // Timeline track
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(scan.riskLevel.color)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(DS.Colors.bgPrimary, lineWidth: 2))

                                if idx < sortedScans.count - 1 {
                                    Rectangle()
                                        .fill(DS.Colors.divider)
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 14)
                            .padding(.top, 2)

                            // Content
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(scan.crackType.rawValue)
                                        .font(DS.Typography.subheading(14))
                                        .foregroundColor(DS.Colors.textPrimary)
                                    Spacer()
                                    RiskBadge(level: scan.riskLevel)
                                }

                                Text(scan.createdAt, style: .date)
                                    .font(DS.Typography.caption(11))
                                    .foregroundColor(DS.Colors.textMuted)

                                if !scan.notes.isEmpty {
                                    Text(scan.notes)
                                        .font(DS.Typography.body())
                                        .foregroundColor(DS.Colors.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(DS.Spacing.m)
                            .background(DS.Colors.card)
                            .cornerRadius(DS.Radius.m)
                            .padding(.bottom, DS.Spacing.m)
                        }
                        .padding(.horizontal, DS.Spacing.l)
                    }
                }
                .padding(.top, DS.Spacing.l)
                .padding(.bottom, 60)
            }
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Comparison View
struct ComparisonView: View {
    let scan: Scan
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var compareScan: Scan?
    @State private var sliderValue: CGFloat = 0.5

    var otherScans: [Scan] {
        dataStore.scans.filter { $0.id != scan.id && $0.roomId == scan.roomId }
    }

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xl) {
                    if otherScans.isEmpty {
                        EmptyStateCard(
                            icon: "rectangle.split.2x1",
                            title: "No Comparison Available",
                            subtitle: "Scan the same room again to compare changes",
                            color: DS.Colors.purple
                        )
                        .padding()
                    } else {
                        // Before/After
                        VStack(spacing: DS.Spacing.m) {
                            Text("Before / After Comparison")
                                .font(DS.Typography.subheading())
                                .foregroundColor(DS.Colors.textSecondary)

                            HStack(spacing: DS.Spacing.m) {
                                // Before
                                VStack(spacing: 6) {
                                    Text("BEFORE")
                                        .font(DS.Typography.caption(10))
                                        .foregroundColor(DS.Colors.textMuted)
                                        .tracking(2)

                                    ZStack {
                                        if let cs = compareScan ?? otherScans.first, let img = cs.image {
                                            Image(uiImage: img)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 180)
                                                .clipped()
                                        } else {
                                            DS.Colors.card.frame(height: 180)
                                            Image(systemName: "camera").foregroundColor(DS.Colors.textMuted)
                                        }
                                    }
                                    .cornerRadius(DS.Radius.m)

                                    if let cs = compareScan ?? otherScans.first {
                                        RiskBadge(level: cs.riskLevel)
                                        Text(cs.createdAt, style: .date)
                                            .font(DS.Typography.caption(11))
                                            .foregroundColor(DS.Colors.textMuted)
                                    }
                                }

                                // After (current)
                                VStack(spacing: 6) {
                                    Text("AFTER")
                                        .font(DS.Typography.caption(10))
                                        .foregroundColor(DS.Colors.textMuted)
                                        .tracking(2)

                                    ZStack {
                                        if let img = scan.image {
                                            Image(uiImage: img)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 180)
                                                .clipped()
                                        } else {
                                            DS.Colors.card.frame(height: 180)
                                            Image(systemName: "camera").foregroundColor(DS.Colors.textMuted)
                                        }
                                    }
                                    .cornerRadius(DS.Radius.m)

                                    RiskBadge(level: scan.riskLevel)
                                    Text(scan.createdAt, style: .date)
                                        .font(DS.Typography.caption(11))
                                        .foregroundColor(DS.Colors.textMuted)
                                }
                            }
                            .padding(.horizontal, DS.Spacing.l)
                        }

                        // Change summary
                        DSCard {
                            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                                Text("Change Summary")
                                    .font(DS.Typography.subheading())
                                    .foregroundColor(DS.Colors.textPrimary)

                                if let cs = compareScan ?? otherScans.first {
                                    let widthDiff = scan.width - cs.width
                                    let lengthDiff = scan.length - cs.length
                                    ChangeSummaryRow(label: "Width", before: cs.width, after: scan.width, unit: "mm")
                                    Divider().background(DS.Colors.divider)
                                    ChangeSummaryRow(label: "Length", before: cs.length, after: scan.length, unit: "mm")
                                    Divider().background(DS.Colors.divider)
                                    HStack {
                                        Text("Risk Level")
                                            .font(DS.Typography.body())
                                            .foregroundColor(DS.Colors.textMuted)
                                        Spacer()
                                        RiskBadge(level: cs.riskLevel)
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 10))
                                            .foregroundColor(DS.Colors.textMuted)
                                        RiskBadge(level: scan.riskLevel)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        // Select compare scan
                        if otherScans.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DS.Spacing.m) {
                                    ForEach(otherScans) { s in
                                        Button(action: { compareScan = s }) {
                                            VStack(spacing: 4) {
                                                Text(s.createdAt, style: .date)
                                                    .font(DS.Typography.caption(11))
                                                    .foregroundColor(compareScan?.id == s.id ? DS.Colors.cyan : DS.Colors.textMuted)
                                                RiskBadge(level: s.riskLevel)
                                            }
                                            .padding(DS.Spacing.m)
                                            .background(compareScan?.id == s.id ? DS.Colors.cyan.opacity(0.1) : DS.Colors.card)
                                            .cornerRadius(DS.Radius.m)
                                        }
                                    }
                                }
                                .padding(.horizontal, DS.Spacing.l)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.top, DS.Spacing.l)
            }
            .navigationTitle("Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(DS.Colors.cyan)
                }
            }
        }
    }
}

struct ChangeSummaryRow: View {
    let label: String
    let before: Double
    let after: Double
    let unit: String

    var diff: Double { after - before }
    var isWorse: Bool { diff > 0 }

    var body: some View {
        HStack {
            Text(label)
                .font(DS.Typography.body())
                .foregroundColor(DS.Colors.textMuted)
            Spacer()
            HStack(spacing: 4) {
                Text(String(format: "%.1f\(unit)", before))
                    .font(DS.Typography.caption())
                    .foregroundColor(DS.Colors.textMuted)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(DS.Colors.textMuted)
                Text(String(format: "%.1f\(unit)", after))
                    .font(DS.Typography.caption())
                    .foregroundColor(DS.Colors.textPrimary)

                if diff != 0 {
                    Image(systemName: isWorse ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10))
                        .foregroundColor(isWorse ? DS.Colors.danger : DS.Colors.safe)
                }
            }
        }
    }
}

// MARK: - Rooms View
struct RoomsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddRoom = false
    @State private var newRoomName = ""
    @State private var newRoomIcon = "house.fill"

    let roomIcons = ["house.fill", "sofa.fill", "bed.double.fill", "fork.knife", "bathtub.fill",
                     "arrow.down.to.line", "door.sliding.right.hand.closed", "building.2.fill",
                     "car.fill", "gym.bag.fill"]

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.l) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rooms")
                                    .font(DS.Typography.display(26))
                                    .foregroundColor(DS.Colors.textPrimary)
                                Text("\(dataStore.rooms.count) rooms tracked")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.textMuted)
                            }
                            Spacer()
                            Button(action: { showAddRoom = true }) {
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

                        // Rooms list
                        ForEach(dataStore.rooms) { room in
                            NavigationLink(destination: RoomDetailView(room: room).environmentObject(dataStore)) {
                                RoomCard(room: room, scans: dataStore.scansForRoom(room.id))
                                    .padding(.horizontal, DS.Spacing.l)
                            }
                        }

                        if dataStore.rooms.isEmpty {
                            EmptyStateCard(
                                icon: "building.2",
                                title: "No Rooms",
                                subtitle: "Add rooms to organize your scans",
                                color: DS.Colors.cyan
                            )
                            .padding(.horizontal, DS.Spacing.l)
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddRoom) {
                AddRoomSheet(isPresented: $showAddRoom, name: $newRoomName, icon: $newRoomIcon, icons: roomIcons) { name, icon in
                    let room = Room(name: name, icon: icon)
                    dataStore.addRoom(room)
                    showAddRoom = false
                    newRoomName = ""
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct RoomCard: View {
    let room: Room
    let scans: [Scan]

    var highestRisk: RiskLevel {
        scans.map { $0.riskLevel }.max(by: { a, b in
            let order: [RiskLevel] = [.low, .medium, .high]
            return (order.firstIndex(of: a) ?? 0) < (order.firstIndex(of: b) ?? 0)
        }) ?? .low
    }

    var body: some View {
        DSCard {
            HStack(spacing: DS.Spacing.m) {
                Image(systemName: room.icon)
                    .font(.system(size: 22))
                    .foregroundColor(DS.Colors.cyan)
                    .frame(width: 48, height: 48)
                    .background(DS.Colors.cyan.opacity(0.12))
                    .cornerRadius(DS.Radius.m)

                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(DS.Typography.subheading())
                        .foregroundColor(DS.Colors.textPrimary)

                    HStack(spacing: DS.Spacing.s) {
                        Label("\(scans.count) scans", systemImage: "camera.fill")
                            .font(DS.Typography.caption(11))
                            .foregroundColor(DS.Colors.textMuted)

                        if scans.filter({ $0.riskLevel != .low }).count > 0 {
                            Label("\(scans.filter({ $0.riskLevel != .low }).count) issues", systemImage: "exclamationmark.triangle.fill")
                                .font(DS.Typography.caption(11))
                                .foregroundColor(DS.Colors.warning)
                        }
                    }
                }

                Spacer()

                if !scans.isEmpty {
                    RiskBadge(level: highestRisk)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DS.Colors.textMuted)
            }
        }
    }
}

struct RoomDetailView: View {
    let room: Room
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedScan: Scan?

    var scans: [Scan] { dataStore.scansForRoom(room.id) }

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.l) {
                    // Room header
                    DSCard {
                        HStack(spacing: DS.Spacing.m) {
                            Image(systemName: room.icon)
                                .font(.system(size: 32))
                                .foregroundColor(DS.Colors.cyan)
                                .frame(width: 64, height: 64)
                                .background(DS.Colors.cyan.opacity(0.12))
                                .cornerRadius(DS.Radius.m)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(room.name)
                                    .font(DS.Typography.heading())
                                    .foregroundColor(DS.Colors.textPrimary)
                                Text("\(scans.count) total scans")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.textMuted)
                                Text("\(scans.filter { $0.riskLevel != .low }.count) issues found")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.warning)
                            }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    if scans.isEmpty {
                        EmptyStateCard(
                            icon: "camera.viewfinder",
                            title: "No Scans",
                            subtitle: "Scan this room to start tracking",
                            color: DS.Colors.cyan
                        )
                        .padding(.horizontal, DS.Spacing.l)
                    } else {
                        ForEach(scans) { scan in
                            ScanRowCard(scan: scan, rooms: dataStore.rooms)
                                .padding(.horizontal, DS.Spacing.l)
                                .onTapGesture { selectedScan = scan }
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, DS.Spacing.l)
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedScan) { scan in
            NavigationView {
                ScanDetailView(scan: scan)
                    .environmentObject(dataStore)
            }
        }
    }
}

struct AddRoomSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    @Binding var icon: String
    let icons: [String]
    let onAdd: (String, String) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xl) {
                    BSTextField(placeholder: "Room name", text: $name, icon: "house.fill")
                        .padding(.horizontal, DS.Spacing.l)

                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        Text("Select Icon")
                            .font(DS.Typography.caption())
                            .foregroundColor(DS.Colors.textMuted)
                            .padding(.horizontal, DS.Spacing.l)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: DS.Spacing.m) {
                            ForEach(icons, id: \.self) { i in
                                Button(action: { icon = i }) {
                                    Image(systemName: i)
                                        .font(.system(size: 20))
                                        .foregroundColor(icon == i ? DS.Colors.btnPrimaryText : DS.Colors.textSecondary)
                                        .frame(width: 48, height: 48)
                                        .background(icon == i ? DS.Colors.cyan : DS.Colors.card)
                                        .cornerRadius(DS.Radius.m)
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)
                    }

                    Spacer()

                    PrimaryButton("Add Room", icon: "plus.circle") {
                        guard !name.isEmpty else { return }
                        onAdd(name, icon)
                    }
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.bottom, 40)
                }
                .padding(.top, DS.Spacing.l)
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(DS.Colors.textMuted)
                }
            }
        }
    }
}
