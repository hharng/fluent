
import Foundation

extension Memory {
    public func make(_ name: String, metadata: Metadata = Metadata()) throws {
        guard self[name] == nil else {
            throw MemoryError.doesExistAlready(name)
        }
        
        var table = [String: Node]()
        table[Metadata.key] = try metadata.makeNode()
        self[name] = Node(table)
    }
    
    public func set(_ name: String, data: Node, idKey: String = "id") throws {
        if self[name] == nil {
            try make(name)
        }
        
        guard var table = self[name] else {
            throw MemoryError.doesNotExist(name)
        }
        
        let metadata = try Metadata(node: table[Metadata.key]!)
        metadata.increment += 1
        metadata.lastUpdatedDate = Date()
        
        var newData = data.nodeObject
        newData?[idKey] = Node(metadata.increment)
        
        table["\(metadata.increment)"] = try newData?.makeNode() ?? data
        table[Metadata.key] = try metadata.makeNode()
        
        self[name] = table
        
    }
    
    public func get(_ name: String, filters: [Fluent.Filter]? = nil) throws -> Node { // dirty
        guard let table = self[name]?.nodeObject else {
            throw MemoryError.doesNotExist(name)
        }
        
        guard let filters = filters else {
            return Node([Node](table.values))
        }
        
        let values = [Node](table.values)
        var result: [Node] = []
        var pass: Bool = false
        for node in values {
            for filter in filters {
                if let o = node.nodeObject {
                    pass = filterCheck(filter: filter, object: o) || pass
                } else {
                    pass = false
                }
            }

            if pass {
               result.append(node)
            }
            pass = false
        }
        
        return Node(result)
    }
    
    public func update(_ name: String, data: Node, filter: Fluent.Filter, idKey: String = "id") throws { // dirty
        guard var table = self[name]?.nodeObject else {
            throw MemoryError.doesNotExist(name)
        }
        
        let values = [Node](table.values)
        var result: [Node] = []
        for node in values {
            if let o = node.nodeObject,
               filterCheck(filter: filter, object: o) {
            
                result.append(node)
            }
        }
        
        for node in result {
            var object = node.nodeObject!
            
            for (key, val) in data.nodeObject! {
                object[key] = val
            }
            
            if let id = object[idKey]?.string {
                table[id] = Node(object)
            }
        }
        
        self[name] = Node(table)
    }
    
    public func remove(_ name: String, filter: Filter) throws {
        guard var table = self[name]?.object else {
            throw MemoryError.doesNotExist(name)
        }
        
        table.removeValue(forKey: "\(index)")
    }
    
    public func remove(_ name: String, at index: Int) throws {
        guard var table = self[name]?.object else {
            throw MemoryError.doesNotExist(name)
        }
        
        table.removeValue(forKey: "\(index)")
    }
    
    public func remove(_ name: String) throws {
        self.store.removeValue(forKey: name)
    }
    
    ///
    
    internal func filterCheck(filter: Fluent.Filter, object: [String: Node]) -> Bool {
        switch filter.method {
        case .compare(let key, let comparison, let val):
            switch comparison {
            case .equals:
                if let value = object[key]?.string,
                    let val = val.string,
                    val == value {
                    
                    return true
                }
                return false
            case .contains:
                if let value = object[key]?.string,
                    let val = val.string,
                    value.contains(val) {
                    
                    return true
                }
                return false
            case .greaterThan:
                if  let value = object[key]?.double,
                    let val = val.double,
                    value > val {
                    
                    return true
                }
                return false
            case .greaterThanOrEquals:
                if let value = object[key]?.double,
                    let val = val.double,
                    value >= val {
                    return true
                }
                return false
            case .hasPrefix:
                if let value = object[key]?.string,
                    let val = val.string,
                    value.hasPrefix(val) {
                    return true
                }
                return false
            case .hasSuffix:
                if let value = object[key]?.string,
                    let val = val.string,
                    value.hasSuffix(val) {
                    return true
                }
                return false
            case .lessThan:
                if let value = object[key]?.double,
                    let val = val.double,
                    value < val {
                    return true
                }
                return false
            case .lessThanOrEquals:
                if let value = object[key]?.double,
                    let val = val.double,
                    value <= val {
                    return true
                }
                return false
            case .notEquals:
                if let value = object[key]?.string,
                    let val = val.string,
                    value != val {
                    return true
                }
                return false
            }
        case .subset(let key, let scope, let subset):
            switch scope {
            case .in:
                if let value = object[key],
                    subset.contains(value) {
                    
                    return true
                }
            case .notIn:
                if let value = object[key],
                    !subset.contains(value) {
                    
                    return true
                }
            }
        }
        return false
    }
}

extension Memory: CustomStringConvertible {
    public var description: String {
        return "In memory ...\n\(self.store)"
    }
}

public enum MemoryError: Error {
    case doesExistAlready(String)
    case doesNotExist(String)
}
