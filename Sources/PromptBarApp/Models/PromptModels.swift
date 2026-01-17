import Foundation

struct PromptItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var updatedAt: Date
}

struct PromptFolder: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var iconName: String
    var prompts: [PromptItem]

    init(id: UUID, name: String, iconName: String = "folder", prompts: [PromptItem]) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.prompts = prompts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "folder"
        prompts = try container.decode([PromptItem].self, forKey: .prompts)
    }
}

extension PromptFolder {
    static func sampleData() -> [PromptFolder] {
        let samplePrompts = [
            PromptItem(
                id: UUID(),
                title: "Project kickoff",
                content: "Draft a concise kickoff summary with goals, scope, risks, and timeline.",
                updatedAt: Date()
            ),
            PromptItem(
                id: UUID(),
                title: "Bug report",
                content: "Summarize the issue, steps to reproduce, expected vs actual, and impact.",
                updatedAt: Date()
            )
        ]

        return [
            PromptFolder(id: UUID(), name: "Work", iconName: "briefcase", prompts: samplePrompts),
            PromptFolder(id: UUID(), name: "Personal", iconName: "sparkles", prompts: [])
        ]
    }
}
