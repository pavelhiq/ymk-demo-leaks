import UIKit
import YandexMapsMobile
import os

final class MainViewController: UIViewController {

    private lazy var openFullScreenMapButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("Full-screen Map", for: .normal)
        button.addTarget(self, action: #selector(onFullScreenMapButtonClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var openNonSharedMapFlowButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("Non-shared Maps", for: .normal)
        button.addTarget(self, action: #selector(onNonSharedMapsFlowButtonClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var openSharedMapFlowButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("Shared Maps", for: .normal)
        button.addTarget(self, action: #selector(onSharedMapsFlowButtonClick), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
    }
    
    // MARK: - UI Setup
    
    private func setUpUI() {
        self.view.backgroundColor = .white
        
        let contentView = makeContentView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }
    
    private func makeContentView() -> UIView {
        let contentWrapper = UIStackView(arrangedSubviews: [
            openFullScreenMapButton,
            openNonSharedMapFlowButton,
            openSharedMapFlowButton,
            UIView(),
        ])
        contentWrapper.axis = .vertical
        contentWrapper.alignment = .fill
        contentWrapper.distribution = .fill
        contentWrapper.spacing = 16
        return contentWrapper
    }
    
    // MARK: - Action Handling
    
    @objc private func onFullScreenMapButtonClick(sender: UIButton) {
        openFullScreenMap()
    }

    @objc private func onNonSharedMapsFlowButtonClick(sender: UIButton) {
        openNonSharedMapsFlow()
    }
    
    @objc private func onSharedMapsFlowButtonClick(sender: UIButton) {
        openSharedMapsFlow()
    }
    
    // MARK: - Navigation
    
    private func openFullScreenMap() {
        let vc = MapViewController()
        show(vc, sender: self)
    }
    
    private func openNonSharedMapsFlow() {
        let mapViewPool = SharedViewPoolImpl(
            poolMaxSize: nil,
            viewFactory: makeMapView,
            viewCleanUp: nil
        )
        let startIndex = 1
        let vc = MapPreviewViewController(
            index: startIndex,
            mapViewPool: mapViewPool,
            shouldReleaseMapResources: .never
        )
        show(vc, sender: self)
    }
    
    private func openSharedMapsFlow() {
        let mapViewPool = SharedViewPoolImpl(
            poolMaxSize: 2,
            viewFactory: makeMapView,
            viewCleanUp: cleanUpMapView(_:)
        )
        let startIndex = 1
        let vc = MapPreviewViewController(
            index: startIndex,
            mapViewPool: mapViewPool,
            shouldReleaseMapResources: .always
        )
        show(vc, sender: self)
    }
    
    // MARK: - Map Deals
    
    private let signposter = OSSignposter(logHandle: OSLog.mapkitLog)
    
    private func makeMapView() -> YMKMapView {
        os_log(
            "Making a new YMKMapView instance ...",
            log: OSLog.mapkitLog,
            type: .default
        )
        
        let sid = signposter.makeSignpostID()
        let state = signposter.beginInterval("map.make", id: sid)
        defer { signposter.endInterval("map.make", state) }
        
        let mapView: YMKMapView
#if targetEnvironment(simulator)
        mapView = YMKMapView(frame: .zero, vulkanPreferred: true)
#else
        mapView = YMKMapView(frame: .zero)
#endif
        mapView.mapWindow.map.mapType = .vectorMap
        mapView.setNoninteractive(true)
        
        return mapView
    }
    
    private func cleanUpMapView(_ mapView: YMKMapView) {
        os_log(
            "Cleaning up the map instance %{public}p",
            log: OSLog.mapkitLog,
            type: .default,
            mapView
        )
        
        let sid = signposter.makeSignpostID()
        let state = signposter.beginInterval("map.cleanup", id: sid)
        defer { signposter.endInterval("map.cleanup", state) }
        
        // do some agressive cleanup
        mapView.mapWindow.map.mapObjects.clear()    // likely inexpensive to re-create
        mapView.mapWindow.map.resetMapStyles()      // ?
        mapView.mapWindow.map.wipe()                // not ideal in slow networks
        mapView.removeFromSuperview()               // layout costs
    }

}
