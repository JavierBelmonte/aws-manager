import SwiftUI

struct ContentView: View {
    @State private var profiles: [String] = []
    @State private var activeProfile: String = ""
    @State private var region: String = ""
    @State private var accountId: String = ""
    @State private var isLoading = false
    @State private var selectedProfile: String?
    @State private var showAddSheet = false
    @State private var showDeleteConfirm = false
    @State private var profileToDelete: String?

    private let manager = AWSCredentialsManager()

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPanel
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear { loadAll() }
        .sheet(isPresented: $showAddSheet) {
            AddProfileSheet(manager: manager) {
                loadAll()
            }
        }
        .alert("Eliminar perfil", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                if let name = profileToDelete {
                    _ = manager.deleteProfile(name: name)
                    loadAll()
                }
            }
        } message: {
            Text("Vas a eliminar el perfil \"\(profileToDelete ?? "")\". Esta accion no se puede deshacer.")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedProfile) {
            Section {
                ForEach(profiles, id: \.self) { profile in
                    HStack {
                        Image(systemName: profile == activeProfile ? "checkmark.seal.fill" : "person.crop.circle")
                            .foregroundStyle(profile == activeProfile ? .green : .secondary)
                            .imageScale(.large)
                        VStack(alignment: .leading) {
                            Text(profile)
                                .fontWeight(profile == activeProfile ? .semibold : .regular)
                            if profile == activeProfile {
                                Text("Activo")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .tag(profile)
                    .contextMenu {
                        if profile != activeProfile {
                            Button("Activar") { switchTo(profile) }
                            Divider()
                            Button("Eliminar", role: .destructive) {
                                profileToDelete = profile
                                showDeleteConfirm = true
                            }
                        }
                    }
                }
            } header: {
                Text("Perfiles")
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
                .help("Agregar perfil")
            }
        }
        .navigationTitle("AWS Manager")
    }

    // MARK: - Detail

    private var detailPanel: some View {
        VStack(spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView("Cargando...")
                Spacer()
            } else if let selected = selectedProfile {
                profileDetail(for: selected)
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 48))
                        .foregroundStyle(.quaternary)
                    Text("Selecciona un perfil")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func profileDetail(for profile: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Profile icon
            Image(systemName: profile == activeProfile ? "checkmark.seal.fill" : "person.crop.circle")
                .font(.system(size: 48))
                .foregroundStyle(profile == activeProfile ? .green : .secondary)

            // Profile name
            Text(profile)
                .font(.largeTitle)
                .bold()

            // Active badge
            if profile == activeProfile {
                HStack(spacing: 20) {
                    InfoBadge(label: "Cuenta", value: accountId)
                    InfoBadge(label: "Region", value: region)
                }
            }

            // Action button
            if profile == activeProfile {
                Label("Perfil activo", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Button {
                    switchTo(profile)
                } label: {
                    Label("Activar este perfil", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(width: 220, height: 36)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func loadAll() {
        profiles = manager.listProfiles()
        refreshActive()
    }

    private func switchTo(_ profile: String) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let success = manager.switchProfile(to: profile)
            DispatchQueue.main.async {
                if success { refreshActive() }
                isLoading = false
            }
        }
    }

    private func refreshActive() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let info = manager.readActiveProfile()
            DispatchQueue.main.async {
                if let info {
                    activeProfile = info.name
                    region = info.region
                    accountId = info.accountId
                    selectedProfile = info.name
                    AWSStateStore.save(AWSState(
                        profile: info.name,
                        region: info.region,
                        accountId: info.accountId,
                        updatedAt: Date()
                    ))
                }
                isLoading = false
            }
        }
    }
}

// MARK: - Info Badge

struct InfoBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Add Profile Sheet

struct AddProfileSheet: View {
    let manager: AWSCredentialsManager
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var accessKey = ""
    @State private var secretKey = ""
    @State private var sessionToken = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Agregar perfil")
                .font(.headline)

            Form {
                TextField("Nombre del perfil", text: $name)
                TextField("AWS Access Key ID", text: $accessKey)
                SecureField("AWS Secret Access Key", text: $secretKey)
                TextField("Session Token (opcional)", text: $sessionToken)
            }
            .formStyle(.grouped)

            if let error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancelar") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Guardar") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || accessKey.isEmpty || secretKey.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            error = "El nombre no puede estar vacio"
            return
        }

        let success = manager.addProfile(
            name: trimmedName,
            accessKeyId: accessKey.trimmingCharacters(in: .whitespaces),
            secretAccessKey: secretKey.trimmingCharacters(in: .whitespaces),
            sessionToken: sessionToken.trimmingCharacters(in: .whitespaces)
        )

        if success {
            onDone()
            dismiss()
        } else {
            error = "Error al guardar el perfil"
        }
    }
}
