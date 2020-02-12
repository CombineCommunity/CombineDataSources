//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import Foundation

public protocol SectionProtocol {
    associatedtype Element
    
    var header: String? { get }
    var footer: String? { get }
    var items: [Element] { get }
}

public struct Section<Element: Hashable>: SectionProtocol, Identifiable {
    public init(header: String? = nil, items: [Element], footer: String? = nil, id: String? = nil) {
        self.id = id ?? header ?? UUID().uuidString
        self.header = header
        self.items = items
        self.footer = footer
    }
    
    public let id: String
    
    public let header: String?
    public let footer: String?
    public let items: [Element]
}

extension Section: Equatable {
    public static func == (lhs: Section<Element>, rhs: Section<Element>) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Section: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Section: RandomAccessCollection {
    public var startIndex: Int {
        return items.startIndex
    }
    
    public var endIndex: Int {
        return items.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return items.index(after: i)
    }
    
    public subscript(index: Int) -> Element {
        return items[index]
    }
    
    public var count: Int {
        return items.count
    }
}
