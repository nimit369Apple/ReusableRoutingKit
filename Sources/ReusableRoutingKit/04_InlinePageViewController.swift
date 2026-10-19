import BrowserKit
import Foundation
import SwiftUI
import UIKit

// MARK: - Embedded Browser View
@available(iOS 13.0, *)
@MainActor
final class InlinePageViewController:
  UIViewController
{
  private let pageModel: InlinePageViewModel
  private var hostedPageController: UIHostingController<AnyView>?
  private var pagePhaseObservation: NSKeyValueObservation?
  private let loadingCurtain: UIView = {
    let cover = UIView()
    cover.backgroundColor = .black
    cover.translatesAutoresizingMaskIntoConstraints = false
    return cover
  }()
  private let busyIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.color = .white
    indicator.hidesWhenStopped = true
    indicator.translatesAutoresizingMaskIntoConstraints = false
    return indicator
  }()
  init(
    pageModel:
      InlinePageViewModel
  ) {
    self.pageModel = pageModel
    super.init(
      nibName: nil,
      bundle: nil
    )
  }
  required init?(coder: NSCoder) {
    fatalError(
      "Initialize with pageModel."
    )
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    constructLoadingCurtain()
    observePagePhase()
    pageModel.beginPageSession()
  }
  override func viewDidDisappear(
    _ animated: Bool
  ) {
    super.viewDidDisappear(animated)
    if view.window == nil {
      pageModel.endPageSession()
    }
  }
  // MARK: - Key-value MVVM binding
  private func observePagePhase() {
    pagePhaseObservation = pageModel.phaseLedger.observe(
      \.phaseValue,
      options: [.new]
    ) { [weak self] _, _ in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.renderPagePhase(self.pageModel.currentPhase)
      }
    }
  }
  private func renderPagePhase(_ values: RouteFieldMap) {
    switch values[FieldNames.phase] {
    case PagePhases.initialized:
      break
    case PagePhases.loading:
      guard
        let address = values[FieldNames.destination],
        let destinationURL = URL(string: address)
      else { return }
      mountBrowserIfNeeded(destinationURL: destinationURL)
      showLoadingCurtain()
    case PagePhases.ready:
      hideLoadingCurtain()
    case PagePhases.invalidDestination:
      let address = values[FieldNames.destination] ?? ""
      print("Invalid calculator browser destination: \(address)")
      hideLoadingCurtain()
    default:
      break
    }
  }
  // MARK: - Browser Presentation
  private func mountBrowserIfNeeded(
    destinationURL: URL
  ) {
    guard hostedPageController == nil else {
      return
    }
    let pageView = BrowserView(
      url: destinationURL,
      webKitConfiguration: { browserOptions in
        browserOptions.websiteDataStore = .default()
        browserOptions.allowsInlineMediaPlayback = true
        browserOptions.allowsPictureInPictureMediaPlayback = true
        browserOptions.mediaTypesRequiringUserActionForPlayback = []
      },
      webViewConfiguration: { webView in
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
      }
    )
    .ignoresSafeArea(
      .container,
      edges: .bottom
    )
    let hostedPageController = UIHostingController(
      rootView: AnyView(pageView)
    )
    self.hostedPageController = hostedPageController
    addChild(hostedPageController)
    hostedPageController.view.backgroundColor = .black
    hostedPageController.view.translatesAutoresizingMaskIntoConstraints = false
    view.insertSubview(
      hostedPageController.view,
      belowSubview: loadingCurtain
    )
    NSLayoutConstraint.activate([
      hostedPageController.view.leadingAnchor.constraint(
        equalTo: view.leadingAnchor
      ),
      hostedPageController.view.trailingAnchor.constraint(
        equalTo: view.trailingAnchor
      ),
      hostedPageController.view.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor
      ),
      hostedPageController.view.bottomAnchor.constraint(
        equalTo: view.bottomAnchor
      ),
    ])
    hostedPageController.didMove(
      toParent: self
    )
  }
  // MARK: - Loading Interface
  private func constructLoadingCurtain() {
    view.addSubview(loadingCurtain)
    loadingCurtain.addSubview(busyIndicator)
    NSLayoutConstraint.activate([
      loadingCurtain.leadingAnchor.constraint(
        equalTo: view.leadingAnchor
      ),
      loadingCurtain.trailingAnchor.constraint(
        equalTo: view.trailingAnchor
      ),
      loadingCurtain.topAnchor.constraint(
        equalTo: view.topAnchor
      ),
      loadingCurtain.bottomAnchor.constraint(
        equalTo: view.bottomAnchor
      ),
      busyIndicator.centerXAnchor.constraint(
        equalTo: loadingCurtain.centerXAnchor
      ),
      busyIndicator.centerYAnchor.constraint(
        equalTo: loadingCurtain.centerYAnchor
      ),
    ])
  }
  private func showLoadingCurtain() {
    loadingCurtain.isHidden = false
    busyIndicator.startAnimating()
    view.bringSubviewToFront(loadingCurtain)
  }
  private func hideLoadingCurtain() {
    busyIndicator.stopAnimating()
    loadingCurtain.isHidden = true
  }
  override var preferredStatusBarStyle: UIStatusBarStyle {
    .lightContent
  }
  override var prefersStatusBarHidden: Bool {
    false
  }
}
