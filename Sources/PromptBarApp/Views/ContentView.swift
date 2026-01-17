import AppKit
import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PromptStore
    @EnvironmentObject private var settings: SettingsStore

    @FocusState private var searchFocused: Bool
    @State private var showingNewFolder = false
    @State private var showingNewPrompt = false

    var body: some View {
        ZStack {
            GlassBackground(material: .sidebar, blendingMode: .behindWindow)
            LinearGradient(
                colors: [
                    Theme.accent.opacity(0.25),
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                topBar
                HStack(spacing: 0) {
                    FolderSidebarView(showingNewFolder: $showingNewFolder)
                    Divider().opacity(0.2)
                    PromptPaneView(showingNewPrompt: $showingNewPrompt)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.glassFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.glassStroke, lineWidth: 1)
                        )
                )
            }
            .padding(14)
        }
        .accentColor(Theme.accent)
        .onAppear {
            DispatchQueue.main.async {
                searchFocused = true
            }
        }
        .onChange(of: store.selectedFolderID) { _ in
            searchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearchField)) { _ in
            searchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewFolder)) { _ in
            showingNewFolder = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewPrompt)) { _ in
            if store.selectedFolderID == nil {
                showingNewFolder = true
            } else {
                showingNewPrompt = true
            }
        }
        .onExitCommand {
            handleEscape()
        }
        .sheet(isPresented: $showingNewFolder) {
            NewFolderView { name, iconName in
                store.addFolder(name: name, iconName: iconName)
            }
        }
        .sheet(isPresented: $showingNewPrompt) {
            if let folderID = store.selectedFolderID {
                NewPromptView { title, content in
                    store.addPrompt(folderID: folderID, title: title, content: content)
                }
            } else {
                EmptyStateView(
                    title: "Select a folder",
                    message: "Pick a folder on the left to add a prompt."
                )
                .frame(width: 420, height: 260)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if store.selectedFolderID != nil {
                Button {
                    store.selectFolder(nil)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(6)
                .background(Theme.glassFill)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.glassStroke, lineWidth: 1)
                )
            }

            TextField(store.selectedFolderID == nil ? "Search folders" : "Search prompts", text: $store.searchQuery)
                .textFieldStyle(.plain)
                .font(settings.font(.body))
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Theme.glassFill)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.glassStroke, lineWidth: 1)
                )
                .frame(maxWidth: .infinity)
                .focused($searchFocused)
                .onSubmit {
                    handleSubmit()
                }

            Group {
                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .semibold))
                    }
                } else {
                    Button {
                        openSettingsLegacy()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(6)
            .background(Theme.glassFill)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.glassStroke, lineWidth: 1)
            )
        }
        .foregroundColor(Theme.textPrimary)
    }

    private func handleEscape() {
        if store.selectedFolderID != nil {
            store.selectFolder(nil)
            searchFocused = true
            return
        }
        if !store.searchQuery.isEmpty {
            store.searchQuery = ""
            searchFocused = true
        }
    }

    private func openSettingsLegacy() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private func handleSubmit() {
        if store.selectedFolderID == nil {
            if let folder = store.filteredFolders().first {
                store.selectFolder(folder.id)
            }
            return
        }

        guard let folderID = store.selectedFolderID else { return }
        let prompts = store.filteredPrompts(in: folderID)

        if let selectedID = store.selectedPromptID,
           let selected = prompts.first(where: { $0.id == selectedID }) {
            store.copyPrompt(selected)
            return
        }

        if let first = prompts.first {
            store.copyPrompt(first)
        }
    }
}

private struct FolderSidebarView: View {
    @EnvironmentObject private var store: PromptStore
    @EnvironmentObject private var settings: SettingsStore
    @Binding var showingNewFolder: Bool

    @State private var folderToDelete: PromptFolder?
    @State private var folderToRename: PromptFolder?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Folders")
                    .font(settings.font(.subtitle, weight: .semibold))
                Spacer()
                Button {
                    showingNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)

            List(selection: folderSelectionBinding) {
                ForEach(store.filteredFolders()) { folder in
                    HStack {
                        Image(systemName: folder.iconName)
                            .foregroundColor(Theme.textSecondary)
                        Text(folder.name)
                        Spacer()
                        Text("\(folder.prompts.count)")
                            .font(settings.font(.small))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .font(settings.font(.body))
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("Rename Folder") {
                            folderToRename = folder
                        }
                        Button("Delete Folder") {
                            folderToDelete = folder
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 240)
        .padding(12)
        .background(Color.black.opacity(0.15))
        .cornerRadius(14)
        .confirmationDialog("Delete this folder?", isPresented: deleteFolderDialogBinding, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let folder = folderToDelete {
                    store.deleteFolder(id: folder.id)
                    folderToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                folderToDelete = nil
            }
        }
        .sheet(item: $folderToRename) { folder in
            RenameFolderView(folder: folder) { name, iconName in
                store.updateFolder(id: folder.id, name: name, iconName: iconName)
            }
        }
        .foregroundColor(Theme.textPrimary)
    }

    private var deleteFolderDialogBinding: Binding<Bool> {
        Binding(
            get: { folderToDelete != nil },
            set: { newValue in
                if !newValue {
                    folderToDelete = nil
                }
            }
        )
    }

    private var folderSelectionBinding: Binding<UUID?> {
        Binding(
            get: { store.selectedFolderID },
            set: { newValue in
                DispatchQueue.main.async {
                    store.selectFolder(newValue)
                }
            }
        )
    }
}

private struct PromptPaneView: View {
    @EnvironmentObject private var store: PromptStore
    @EnvironmentObject private var settings: SettingsStore
    @Binding var showingNewPrompt: Bool

    @State private var promptToDelete: PromptItem?
    @State private var promptToEdit: PromptItem?
    @State private var promptToRename: PromptItem?
    @State private var folderToRename: PromptFolder?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let folderID = store.selectedFolderID,
               let folder = store.folders.first(where: { $0.id == folderID }) {
                promptList(for: folder)
            } else {
                EmptyStateView(
                    title: "Type to search",
                    message: "Start typing to filter folders and press enter to open one."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(Theme.textPrimary)
        .onReceive(NotificationCenter.default.publisher(for: .editSelectedPrompt)) { _ in
            openEditorForSelection()
        }
        .sheet(item: $folderToRename) { folder in
            RenameFolderView(folder: folder) { name, iconName in
                store.updateFolder(id: folder.id, name: name, iconName: iconName)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let folder = currentFolder {
                    Button {
                        folderToRename = folder
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: folder.iconName)
                                .foregroundColor(Theme.textSecondary)
                            Text(folder.name)
                                .font(settings.font(.title, weight: .semibold))
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Prompts")
                        .font(settings.font(.title, weight: .semibold))
                }
                Text(currentSubtitle)
                    .font(settings.font(.small))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
            if store.selectedFolderID != nil {
                Button {
                    showingNewPrompt = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                        .font(settings.font(.small, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Theme.accentSoft)
                .cornerRadius(10)
            }
        }
    }

    private var currentFolder: PromptFolder? {
        guard let folderID = store.selectedFolderID else { return nil }
        return store.folders.first(where: { $0.id == folderID })
    }

    private var currentSubtitle: String {
        guard let folder = currentFolder else {
            return "Select a folder to see prompts"
        }
        let count = store.filteredPrompts(in: folder.id).count
        return "\(count) prompt\(count == 1 ? "" : "s")"
    }

    private func promptList(for folder: PromptFolder) -> some View {
        List(selection: $store.selectedPromptID) {
            ForEach(store.filteredPrompts(in: folder.id)) { prompt in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(prompt.title)
                            .font(settings.font(.body, weight: .semibold))
                        Spacer()
                        if store.lastCopiedPromptID == prompt.id {
                            Text("Copied")
                                .font(settings.font(.badge, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accentSoft)
                                .cornerRadius(6)
                        }
                    }
                    Text(prompt.content)
                        .font(settings.font(.small))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .contextMenu {
                    Button("Copy Prompt") {
                        store.copyPrompt(prompt)
                    }
                    Button("Rename Prompt") {
                        promptToRename = prompt
                    }
                    Button("Edit Prompt") {
                        promptToEdit = prompt
                    }
                    Button("Delete Prompt", role: .destructive) {
                        promptToDelete = prompt
                    }
                }
                .onTapGesture(count: 2) {
                    store.copyPrompt(prompt)
                }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .confirmationDialog("Delete this prompt?", isPresented: deletePromptDialogBinding, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let prompt = promptToDelete {
                    store.deletePrompt(id: prompt.id, folderID: folder.id)
                    promptToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                promptToDelete = nil
            }
        }
        .sheet(item: $promptToEdit) { prompt in
            EditPromptView(prompt: prompt) { title, content in
                store.updatePrompt(folderID: folder.id, promptID: prompt.id, title: title, content: content)
            }
        }
        .sheet(item: $promptToRename) { prompt in
            RenamePromptView(prompt: prompt) { title in
                store.renamePrompt(folderID: folder.id, promptID: prompt.id, title: title)
            }
        }
    }

    private func openEditorForSelection() {
        guard let folderID = store.selectedFolderID else { return }
        let prompts = store.filteredPrompts(in: folderID)

        if let selectedID = store.selectedPromptID,
           let selected = prompts.first(where: { $0.id == selectedID }) {
            promptToEdit = selected
            return
        }

        if let first = prompts.first {
            promptToEdit = first
        }
    }

    private var deletePromptDialogBinding: Binding<Bool> {
        Binding(
            get: { promptToDelete != nil },
            set: { newValue in
                if !newValue {
                    promptToDelete = nil
                }
            }
        )
    }
}

private struct EmptyStateView: View {
    @EnvironmentObject private var settings: SettingsStore
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(settings.font(.title, weight: .semibold))
            Text(message)
                .font(settings.font(.small))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Theme.glassFill)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.glassStroke, lineWidth: 1)
        )
    }
}

private struct NewFolderView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var iconName = FolderIconOptions.defaults.first ?? "folder"

    let onSave: (String, String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("New Folder")
                .font(settings.font(.title, weight: .semibold))

            TextField("Folder name", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(settings.font(.body))
                .frame(width: 300)

            IconPicker(selected: $iconName)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                Button("Create") {
                    onSave(name, iconName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
    }
}

private struct NewPromptView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""

    let onSave: (String, String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("New Prompt")
                .font(settings.font(.title, weight: .semibold))

            TextField("Prompt title", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(settings.font(.body))

            TextEditor(text: $content)
                .frame(minHeight: 140)
                .font(settings.font(.body))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    onSave(title, content)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}

private struct RenameFolderView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var iconName: String

    let onSave: (String, String) -> Void

    init(folder: PromptFolder, onSave: @escaping (String, String) -> Void) {
        self.onSave = onSave
        _name = State(initialValue: folder.name)
        _iconName = State(initialValue: folder.iconName)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Rename Folder")
                .font(settings.font(.title, weight: .semibold))

            TextField("Folder name", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(settings.font(.body))
                .frame(width: 320)

            IconPicker(selected: $iconName)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    onSave(name, iconName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
    }
}

private enum FolderIconOptions {
    static let defaults = [
        "folder",
        "briefcase",
        "bookmark",
        "sparkles",
        "lightbulb",
        "doc.text",
        "terminal",
        "tray",
        "tag",
        "person"
    ]
}

private struct IconPicker: View {
    @EnvironmentObject private var settings: SettingsStore
    @Binding var selected: String

    private let columns = Array(repeating: GridItem(.fixed(28), spacing: 10), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(settings.font(.small, weight: .semibold))
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(FolderIconOptions.defaults, id: \.self) { icon in
                    Button {
                        selected = icon
                    } label: {
                        Image(systemName: icon)
                            .frame(width: 28, height: 28)
                            .foregroundColor(selected == icon ? Theme.accent : Theme.textSecondary)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selected == icon ? Theme.accentSoft : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct RenamePromptView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String

    let onSave: (String) -> Void

    init(prompt: PromptItem, onSave: @escaping (String) -> Void) {
        self.onSave = onSave
        _title = State(initialValue: prompt.title)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Rename Prompt")
                .font(settings.font(.title, weight: .semibold))

            TextField("Prompt title", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(settings.font(.body))
                .frame(width: 360)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    onSave(title)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
    }
}

private struct EditPromptView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var content: String

    let onSave: (String, String) -> Void

    init(prompt: PromptItem, onSave: @escaping (String, String) -> Void) {
        self.onSave = onSave
        _title = State(initialValue: prompt.title)
        _content = State(initialValue: prompt.content)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Prompt")
                .font(settings.font(.title, weight: .semibold))

            TextField("Prompt title", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(settings.font(.body))

            TextEditor(text: $content)
                .frame(minHeight: 160)
                .font(settings.font(.body))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    onSave(title, content)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 560)
    }
}
