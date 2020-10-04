import Foundation

struct Note {
    let localID: UUID
    let content: String?
    let creationDate: Date
    var image: MemoImage?
    let mood: UInt8
    let title: String?
}
