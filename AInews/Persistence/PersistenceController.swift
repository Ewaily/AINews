import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AINewsDataModel") // Ensure this matches your .xcdatamodeld file name

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application, although it may be useful during development.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Preview controller for SwiftUI Previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Add some sample data for previews if needed
        for i in 0..<5 {
            let newItem = SavedArticle(context: viewContext)
            newItem.savedAt = Date()
            newItem.articleID = Int64(i)
            newItem.title = "Sample Saved Article Title \(i)"
            newItem.summary = "This is a sample summary for a saved article."
            newItem.urlString = "https://example.com/article/\(i)"
            newItem.tagsJSON = "[\"AI\", \"Sample\"]" // Correctly escaped JSON string for tags
            newItem.significance = "HIGH"
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error while saving context \(nsError), \(nsError.userInfo)")
                // In a real app, handle this error more gracefully
            }
        }
    }
} 