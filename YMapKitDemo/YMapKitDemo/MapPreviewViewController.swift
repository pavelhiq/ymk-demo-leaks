import UIKit
import YandexMapsMobile
import os

final class MapPreviewViewController: UIViewController {
    
    private let index: Int
    private let mapViewPool: any SharedViewPool<YMKMapView>
    private let shouldReleaseMapResources: PooledResourceReleaseStrategy
    
    // MARK: UI Components
    
    private var contentView: UIView!
    
    private var mapView: YMKMapView?
    private let mapHeight: CGFloat = 192
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Item #\(index)"
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.textColor = .darkText
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var headingLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam non augue quis ante rutrum fringilla. Donec sed placerat velit, et pellentesque justo."
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .darkText
        label.numberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var mapContainerView: UIView = {
        let containerView = UIView()
        containerView.layer.backgroundColor = UIColor.lightGray.cgColor
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        containerView.isUserInteractionEnabled = false
        
        containerView.heightAnchor.constraint(equalToConstant: mapHeight).isActive = true
        
        return containerView
    }()
    
    private lazy var navigateToRelatedItemButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("Next one please!", for: .normal)
        button.addTarget(self, action: #selector(onNavigateToRelatedItemButtonClick), for: .touchUpInside)
        return button
    }()
    
    // MARK: Init
    
    init(
        index: Int,
        mapViewPool: any SharedViewPool<YMKMapView>,
        shouldReleaseMapResources: PooledResourceReleaseStrategy
    ) {
        self.index = index
        self.mapViewPool = mapViewPool
        self.shouldReleaseMapResources = shouldReleaseMapResources
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        os_log(
            "Destroying vc at index: %{public}d",
            log: OSLog.mapkitLog,
            type: .default,
            index
        )
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        os_log(
            "Entered viewDidLoad for vc at index: %{public}d",
            log: OSLog.mapkitLog,
            type: .default,
            index
        )
        
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        os_log(
            "Entered viewWillAppear for vc at index: %{public}d",
            log: OSLog.mapkitLog,
            type: .default,
            index
        )
        
        prepareMap()
        updateMap()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        os_log(
            "Entered viewDidDisappear for vc at index: %{public}d",
            log: OSLog.mapkitLog,
            type: .default,
            index
        )
        
        maybeUnloadMap()
    }
    
    // MARK: - Layout
        
    // MARK: - UI Setup
    
    private func setUpUI() {
        self.view.backgroundColor = .white
        
        self.contentView = makeContainerView()
        self.view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }
    
    private func makeContainerView() -> UIView {
        let contentWrapper = UIStackView(arrangedSubviews: [
            titleLabel,
            headingLabel,
            mapContainerView,
            UIView(),
            navigateToRelatedItemButton,
        ])
        contentWrapper.translatesAutoresizingMaskIntoConstraints = false
        contentWrapper.axis = .vertical
        contentWrapper.alignment = .fill
        contentWrapper.distribution = .fill
        contentWrapper.spacing = 16
        return contentWrapper
    }
    
    // MARK: - Action Handling
    
    @objc private func onNavigateToRelatedItemButtonClick(sender: UIButton) {
        showRelatedItem()
    }
    
    // MARK: - Navigation
    
    private func showRelatedItem() {
        let nextIndex = index + 1
        guard nextIndex <= Const.allCities.count else {
            showNoMoreRelatedItemsAlert()
            return
        }
        
        let vc = MapPreviewViewController(
            index: nextIndex,
            mapViewPool: mapViewPool,
            shouldReleaseMapResources: shouldReleaseMapResources
        )
        show(vc, sender: self)
    }
    
    private func showNoMoreRelatedItemsAlert() {
        let alert = UIAlertController(
            title: nil,
            message: "Sorry, there are no more related items.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok, got it", style: .default))
        self.present(alert, animated: true)
    }
    
    // MARK: - Map Deals
    
    private func prepareMap() {
        guard mapView == nil,
              let mapView = mapViewPool.getResource()
        else { return }

        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        self.mapView = mapView
        self.mapContainerView.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: mapContainerView.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapContainerView.bottomAnchor),
        ])
    }
    
    private func maybeUnloadMap() {
        let shouldUnloadMap: Bool = switch shouldReleaseMapResources {
        case .always:
            true
        case .onShortage:
            mapViewPool.hasResourceShortage
        case .never:
            false
        }
        
        guard shouldUnloadMap, let mapView else { return }
        mapViewPool.releaseResource(mapView)
        self.mapView = nil
    }
    
    private func updateMap() {
        guard let targetLocation = Const.allCities[safeAt: index-1] else { return }
        moveCamera(to: targetLocation, animated: false)
    }
    
    private func moveCamera(to location: YMKPoint, animated: Bool) {
        guard let map = mapView?.mapWindow.map else { return }
        let position = YMKCameraPosition(
            target: location,
            zoom: Const.defaultCameraZoom,
            azimuth: Const.defaultCameraAzimuth,
            tilt: Const.defaultCameraTilt
        )

        return animated
        ? map.move(
            with: position,
            animation: Const.defaultPositioningAnimation,
            cameraCallback: { isCompleted in
                os_log(
                    "Done settling camera on the map.",
                    log: OSLog.mapkitLog,
                    type: .default
                )
            }
        )
        : map.move(with: position)
    }
    
}

private enum Const {
    static let locationMoscow = YMKPoint(latitude: 55.755820, longitude: 37.617633)
    static let locationSpb = YMKPoint(latitude: 59.938885, longitude: 30.313921)
    static let locationPolyana = YMKPoint(latitude: 43.672435, longitude: 40.296278)
    static let locationKazan = YMKPoint(latitude: 55.796116, longitude: 49.106308)
    static let locationNN = YMKPoint(latitude: 56.326793, longitude: 44.006437)
    static let locationEkb = YMKPoint(latitude: 56.837958, longitude: 60.597114)
    static let locationSmolensk = YMKPoint(latitude: 54.782751, longitude: 32.047926)
    static let locationPskov = YMKPoint(latitude: 57.819140, longitude: 28.332373)
    static let locationTula = YMKPoint(latitude: 54.193097, longitude: 37.617134)
    static let locationVologda = YMKPoint(latitude: 59.220532, longitude: 39.891287)
    
    static let allCities = [
        Const.locationVologda,
        Const.locationEkb,
        Const.locationKazan,
        Const.locationMoscow,
        Const.locationNN,
        Const.locationPolyana,
        Const.locationPskov,
        Const.locationSmolensk,
        Const.locationSpb,
        Const.locationTula
    ]
    
    static let defaultCameraZoom: Float = 16
    static let defaultCameraAzimuth: Float = 0
    static let defaultCameraTilt: Float = 0
    static let defaultPositioningAnimation = YMKAnimation(type: .smooth, duration: 0.25)
}

extension Array {
    public subscript(safeAt index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }
        return self[index]
    }
}
