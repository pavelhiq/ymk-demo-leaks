import UIKit
import YandexMapsMobile
import os

final class MapViewController: UIViewController {
    
    private var contentView: UIView!
    private var mapView: YMKMapView!
    
    private lazy var mapObjectTapListener: YMKMapObjectTapListener = MapObjectTapListener(viewController: self)
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
    }
    
    // MARK: - UI Setup
    
    private func setUpUI() {
        self.view.backgroundColor = .white

        setUpMapView()
        
        contentView = UIView()
        self.view.addSubview(contentView)
        contentView.frame = self.view.bounds
        contentView.insertSubview(mapView, at: 0)
    }
    
    private func setUpMapView() {
        #if targetEnvironment(simulator)
        mapView = YMKMapView(frame: self.view.bounds, vulkanPreferred: true)
        #else
        mapView = YMKMapView(frame: self.view.bounds)
        #endif
        
        mapView.mapWindow.map.mapType = .vectorMap
        
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: Const.targetLocation, zoom: 16, azimuth: 0, tilt: 0),
            animation: YMKAnimation(type: YMKAnimationType.smooth, duration: 1),
            cameraCallback: { [weak self] isCompleted in
                guard let map = self?.mapView.mapWindow.map else { return }
                self?.addPlacemark(map)
            }
        )
    }
    
    private func addPlacemark(_ map: YMKMap) {
        let placemarkImage = UIImage(systemName: "mappin.and.ellipse") ?? UIImage()
        let placemark = map.mapObjects.addPlacemark()
        placemark.geometry = Const.pinLocation
        placemark.setIconWith(placemarkImage)
        
        placemark.addTapListener(with: mapObjectTapListener)
    }
}

final private class MapObjectTapListener: NSObject, YMKMapObjectTapListener {
    
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
        os_log(
            "Did tap on map object at (%{public}f, %{public}f)",
            log: OSLog.mapkitLog,
            type: .default,
            point.latitude,
            point.longitude
        )
        return true
    }
    
}

private enum Const {
    static let targetLocation = YMKPoint(latitude: 59.925719, longitude: 30.296367)
    static let pinLocation = YMKPoint(latitude: 59.925809, longitude: 30.296633)
}
