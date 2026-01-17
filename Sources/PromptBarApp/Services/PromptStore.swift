import Foundation

final class PromptStore: ObservableObject {
    @Published var folders: [PromptFolder]
    @Published var selectedFolderID: UUID?
    @Published var selectedPromptID: UUID?
    @Published var searchQuery: String = ""
    @Published var lastCopiedPromptID: UUID?

    private let storage: Storage

    init(storage: Storage = Storage()) {
        self.storage = storage
        self.folders = storage.load()
    }

    func addFolder(name: String, iconName: String = "folder") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let folder = PromptFolder(id: UUID(), name: trimmed, iconName: iconName, prompts: [])
        folders.append(folder)
        folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        persist()
    }

    func renameFolder(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[index].name = trimmed
        folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        persist()
    }

    func updateFolder(id: UUID, name: String, iconName: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[index].name = trimmed
        folders[index].iconName = iconName
        folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        persist()
    }

    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
        if selectedFolderID == id {
            selectedFolderID = nil
            selectedPromptID = nil
        }
        persist()
    }

    func addPrompt(folderID: UUID, title: String, content: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
        let prompt = PromptItem(id: UUID(), title: trimmedTitle, content: content, updatedAt: Date())
        folders[index].prompts.append(prompt)
        folders[index].prompts.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        persist()
    }

    func updatePrompt(folderID: UUID, promptID: UUID, title: String, content: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }) else { return }
        guard let promptIndex = folders[folderIndex].prompts.firstIndex(where: { $0.id == promptID }) else { return }
        folders[folderIndex].prompts[promptIndex].title = trimmedTitle
        folders[folderIndex].prompts[promptIndex].content = content
        folders[folderIndex].prompts[promptIndex].updatedAt = Date()
        folders[folderIndex].prompts.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        persist()
    }

    func renamePrompt(folderID: UUID, promptID: UUID, title: String) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }) else { return }
        guard let promptIndex = folders[folderIndex].prompts.firstIndex(where: { $0.id == promptID }) else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let existingContent = folders[folderIndex].prompts[promptIndex].content
        updatePrompt(folderID: folderID, promptID: promptID, title: trimmedTitle, content: existingContent)
    }

    func deletePrompt(id: UUID, folderID: UUID) {
        guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
        folders[index].prompts.removeAll { $0.id == id }
        if selectedPromptID == id {
            selectedPromptID = nil
        }
        persist()
    }

    func filteredFolders() -> [PromptFolder] {
        if selectedFolderID != nil {
            return folders
        }
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return folders }
        return folders.filter { folder in
            folder.name.localizedCaseInsensitiveContains(query)
        }
    }

    func filteredPrompts(in folderID: UUID) -> [PromptItem] {
        guard let folder = folders.first(where: { $0.id == folderID }) else { return [] }
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return folder.prompts }
        return folder.prompts.filter { prompt in
            prompt.title.localizedCaseInsensitiveContains(query) ||
            prompt.content.localizedCaseInsensitiveContains(query)
        }
    }

    func selectFolder(_ id: UUID?) {
        selectedFolderID = id
        selectedPromptID = nil
        searchQuery = ""
    }

    func copyPrompt(_ prompt: PromptItem) {
        Clipboard.copy(prompt.content)
        lastCopiedPromptID = prompt.id
    }

    private func persist() {
        storage.save(folders)
    }
}
