import Foundation
import CoreData

extension SavedArticle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedArticle> {
        return NSFetchRequest<SavedArticle>(entityName: "SavedArticle")
    }

    @NSManaged public var articleID: Int64
    @NSManaged public var datePostedString: String?
    @NSManaged public var imageURLString: String?
    @NSManaged public var savedAt: Date?
    @NSManaged public var significance: String?
    @NSManaged public var subreddit: String?
    @NSManaged public var summary: String?
    @NSManaged public var tagsJSON: String?
    @NSManaged public var title: String?
    @NSManaged public var urlString: String?

}

extension SavedArticle : Identifiable {

} 