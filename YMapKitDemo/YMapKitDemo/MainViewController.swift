import UIKit

final class MainViewController: UIViewController {

    private lazy var openMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.setTitle("Full-screen Map", for: .normal)
        button.addTarget(self, action: #selector(onMapButtonClick), for: .touchUpInside)
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
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }
    
    private func makeContentView() -> UIView {
        let contentWrapper = UIStackView(arrangedSubviews: [
            openMapButton,
        ])
        contentWrapper.axis = .vertical
        contentWrapper.alignment = .fill
        contentWrapper.distribution = .fill
        contentWrapper.spacing = 16
        return contentWrapper
    }
    
    // MARK: - Action Handling
    
    @objc private func onMapButtonClick(sender: UIButton) {
        openFullScreenMap()
    }
    
    // MARK: - Navigation
    
    private func openFullScreenMap() {
        let vc = MapViewController()
        show(vc, sender: self)
    }

}
