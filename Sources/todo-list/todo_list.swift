import Foundation
import ArgumentParser


struct TodoItem: Codable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var done: Bool
    let createdAt: Date
}


enum Store {
    private static var url: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".todo.json")
    }

    static func load() -> [TodoItem] {
        do {
            let data = try Data(contentsOf: url)
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            return try dec.decode([TodoItem].self, from: data)
        } catch {
            return []
        }
    }

    static func save(_ tasks: [TodoItem]) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        let data = try enc.encode(tasks)
        try data.write(to: url, options: [.atomic])
    }
}


@main
struct Todo: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "todo",
        abstract: "CLI todo-list",
        subcommands: [Add.self, List.self, Done.self, Remove.self, Clear.self],
        defaultSubcommand: List.self
    )
}


extension Todo {
    struct Add: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "додати нове завдання")

        @Argument(help: "текст завдання")
        var title: [String]

        func run() throws {
            let text = title.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw ValidationError("порожній заголовок завдання") }

            var tasks = Store.load()
            tasks.append(TodoItem(id: UUID(), title: text, done: false, createdAt: Date()))
            try Store.save(tasks)
            print("додано: \(text)")
        }
    }

    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "показати список завдань")

        @Flag(name: [.customShort("p"), .long], help: "показати лише невиконані")
        var pending: Bool = false

        func run() throws {
            let tasks = Store.load()
            let visible = pending ? tasks.filter { !$0.done } : tasks

            if visible.isEmpty {
                print(pending ? "немає невиконаних завдань" : "поки зовсім немає завдань")
                return
            }

            for (idx, t) in visible.enumerated() {
                let mark = t.done ? "+" : "-"
                print("\(idx + 1). \(mark) \(t.title)")
            }
        }
    }

    struct Done: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "позначити завдання як виконане за номером")

        @Argument(help: "номер завдання з команди list.")
        var index: Int

        func run() throws {
            var tasks = Store.load()
            guard index > 0 && index <= tasks.count else {
                throw ValidationError("неправильний номер: \(index) подивись `todo list`")
            }
            tasks[index - 1].done = true
            try Store.save(tasks)
            print("готово: \(tasks[index - 1].title)")
        }
    }

    struct Remove: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "видалити завдання за номером")

        @Argument(help: "номер завдання з команди list")
        var index: Int

        func run() throws {
            var tasks = Store.load()
            guard index > 0 && index <= tasks.count else {
                throw ValidationError("неправильний номер: \(index). подивись `todo list`.")
            }
            let removed = tasks.remove(at: index - 1)
            try Store.save(tasks)
            print("видалено: \(removed.title)")
        }
    }

    struct Clear: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "очистити весь список завдань")

        @Flag(name: .shortAndLong, help: "підтвердити очищення")
        var yes: Bool = false

        func run() throws {
            guard yes else {
                throw ValidationError("`todo clear --yes`")
            }
            try Store.save([])
            print("список очищено")
        }
    }
}
