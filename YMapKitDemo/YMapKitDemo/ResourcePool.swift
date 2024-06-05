import UIKit
import YandexMapsMobile
import os

enum PooledResourceReleaseStrategy {
    case always
    case onShortage
    case never
}

protocol ResourcePool<Resource>: AnyObject {
    associatedtype Resource: AnyObject
    func getResource() -> Resource?
    func releaseResource(_ resource: Resource)
    var hasResourceShortage: Bool { get }
}

protocol SharedViewPool<V>: ResourcePool where V == Resource {
    associatedtype V: UIView
}

final class SharedViewPoolImpl<V: UIView>: SharedViewPool {
    
    private let poolSizeLimit: Int
    private let viewFactory: () -> V
    private let viewCleanUp: ((V) -> ())?
    
    private var resourcesAvailable = Set<V>()
    private var resourcesInUse = Set<V>()
    
    private var count: Int {
        resourcesAvailable.count + resourcesInUse.count
    }
    
    init(
        poolMaxSize: Int?,
        viewFactory: @escaping () -> V,
        viewCleanUp: ((V) -> ())? = nil
    ) {
        self.poolSizeLimit = poolMaxSize ?? Int.max
        self.viewFactory = viewFactory
        self.viewCleanUp = viewCleanUp
    }
    
    // MARK: - ResourcePool
    
    var hasResourceShortage: Bool {
        count == poolSizeLimit && resourcesAvailable.count == 0
    }
    
    func getResource() -> V? {
        defer { dumpPoolState() }
        
        if resourcesAvailable.isEmpty {
            guard count < poolSizeLimit else { return nil }
            let newObject = viewFactory()
            resourcesInUse.insert(newObject)
            return newObject
        } else if let pooledObject = resourcesAvailable.first {
            resourcesAvailable.remove(pooledObject)
            resourcesInUse.insert(pooledObject)
            return pooledObject
        }
        assertionFailure("Failed to get an existing view from the resource pool!")
        return nil
    }
    
    func releaseResource(_ view: V) {
        defer { dumpPoolState() }
        
        viewCleanUp?(view)
        resourcesInUse.remove(view)
        resourcesAvailable.insert(view)
    }
    
    private func dumpPoolState() {
        os_log(
            "Pool state | in use: %{public}d, available: %{public}d, total: %{public}d (limit: %{public}d)",
            log: OSLog.mapkitLog,
            type: .default,
            resourcesInUse.count,
            resourcesAvailable.count,
            count,
            poolSizeLimit
        )
    }
    
}
