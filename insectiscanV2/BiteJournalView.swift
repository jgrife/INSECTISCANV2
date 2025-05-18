// BiteJournalView.swift (Fixed version)
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import CoreLocation

extension UIApplication {
    static func dismissKeyboard() {
        shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

class BiteJournalViewModel: ObservableObject {
    @Published var entries: [BiteLogEntry] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var filter: EntryFilter = .all

    private let db = Firestore.firestore()

    enum EntryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case manual = "Tracked"
        case autoSaved = "Auto-Saved"
        var id: String { rawValue }
    }

    var filteredEntries: [BiteLogEntry] {
        entries.filter { entry in
            (filter == .all || (filter == .autoSaved && entry.autoSaved == true) || (filter == .manual && entry.autoSaved != true)) &&
            (searchText.isEmpty || entry.diagnosisSummary.localizedCaseInsensitiveContains(searchText) || entry.notes.localizedCaseInsensitiveContains(searchText))
        }
    }

    func loadEntries(for userId: String) {
        isLoading = true
        db.collection("users").document(userId).collection("biteLogs")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let documents = snapshot?.documents {
                        self.entries = documents.compactMap { doc in
                            try? doc.data(as: BiteLogEntry.self)
                        }
                    }
                }
            }
    }

    func deleteEntry(for userId: String, entry: BiteLogEntry) {
        db.collection("users").document(userId).collection("biteLogs").document(entry.id.uuidString).delete { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.entries.removeAll { $0.id == entry.id }
                }
            }
        }
    }
}

struct BiteJournalView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = BiteJournalViewModel()
    @State private var showDetail: BiteLogEntry? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView("Loading entries...")
                } else {
                    VStack {
                        Picker("Filter", selection: $viewModel.filter) {
                            ForEach(BiteJournalViewModel.EntryFilter.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        SearchBar(text: $viewModel.searchText)

                        if viewModel.filteredEntries.isEmpty {
                            Spacer()
                            Text("No bite logs found.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        } else {
                            List {
                                ForEach(viewModel.filteredEntries) { entry in
                                    Button(action: { showDetail = entry }) {
                                        BiteLogCard(entry: entry)
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            if let uid = authViewModel.currentUser?.id {
                                                viewModel.deleteEntry(for: uid, entry: entry)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                }
            }
            .navigationTitle("Bite Journal")
            .onAppear {
                if let uid = authViewModel.currentUser?.id {
                    viewModel.loadEntries(for: uid)
                }
            }
            .sheet(item: $showDetail) { entry in
                BiteLogDetailView(entry: entry)
            }
            .onTapGesture {
                UIApplication.dismissKeyboard()
            }
        }
    }
}

struct BiteLogCard: View {
    let entry: BiteLogEntry

    var severityColor: Color {
        switch entry.severity ?? 0 {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: entry.imageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.diagnosisSummary)
                        .font(.headline)
                    if entry.autoSaved == true {
                        Text("Auto")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
                Text(entry.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let location = entry.locationDescription {
                    Text("📍 \(location)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            Circle()
                .fill(severityColor)
                .frame(width: 14, height: 14)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search logs...", text: $text)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.done)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
