import Foundation
import UIKit

@available(iOS 13.0, *)
@MainActor
public struct LaunchDependencies {
  static let preferenceStore: SessionPreferenceStore =
    LocalPreferenceVault()
  static let addressNormalizer: AddressNormalizing =
    SimpleAddressNormalizer()
  static let remoteLoader: RouteConfigurationLoading =
    CloudRouteConfigurationLoader()
  static let routeDecider: RouteDeciding =
    ValueRouteDecider()
  static let retryClock: RetryScheduling =
    OneShotRetryClock()
  static let foregroundMonitor: AppForegroundObserving =
    AppForegroundListener()
  static let entryPoller: PreferencePolling =
    RepeatingPreferenceClock()
  static let windowFinder: ActiveWindowFinding =
    ConnectedWindowFinder()
  static let linkPresenter: LinkPresenting =
    LinkDisplayManager(
      windowFinder: windowFinder
    )
  static let routingModel =
    RouteViewModel(
      remoteLoader:
        remoteLoader,
      routeDecider:
        routeDecider,
      preferenceStore:
        preferenceStore,
      addressNormalizer:
        addressNormalizer,
      linkPresenter:
        linkPresenter,
      retryClock:
        retryClock,
      foregroundMonitor:
        foregroundMonitor
    )
  static let routeGateway =
    RouteServiceFacade(
      routingModel: routingModel
    )
  public static func buildLaunchModel()
    -> LaunchViewModel
  {
    LaunchViewModel(
      preferenceStore:
        preferenceStore,
      entryPoller:
        entryPoller,
      routeGateway:
        routeGateway
    )
  }
  static func buildPageModel(
    address: String
  ) -> InlinePageViewModel {
    InlinePageViewModel(
      destinationText: address
    )
  }
  /// Public helper so the app-owned storyboard View does not access package-internal protocols.
  public static func findEntryWindow(for owner: UIViewController) -> UIWindow? {
    windowFinder.findEntryWindow(for: owner)
  }
}
@available(iOS 13.0, *)
@MainActor
public final class RouteServiceFacade: NSObject {
  public static var sharedRouteFacade: RouteServiceFacade {
    LaunchDependencies
      .routeGateway
  }
  private let routingModel: RouteViewModel
  init(
    routingModel:
      RouteViewModel
  ) {
    self.routingModel = routingModel
    super.init()
  }
  // MARK: - Existing Runtime Surface
  public func evaluateRoutingAvailability(
    _ shouldVerify: Bool,
    _ completion:
      @escaping ([String: Bool]) -> Void
  ) {
    routingModel
      .checkRouteAvailability(
        shouldVerify:
          shouldVerify,
        completion: completion
      )
  }
  public func subscribeToAppForeground() {
    routingModel
      .enableForegroundUpdates()
  }
  public func openAddressInSystemBrowser(
    _ address: String
  ) {
    routingModel
      .openOutsideApplication(
        address
      )
  }
  public func forwardAddressOutward(
    _ address: String
  ) {
    openAddressInSystemBrowser(
      address
    )
  }
  public func openAddressWithSafariController(
    _ address: String
  ) {
    routingModel
      .openSafariPresentation(
        address
      )
  }
  public func openAddressInEmbeddedPage(
    _ address: String
  ) {
    routingModel
      .openInlinePresentation(
        address
      )
  }
  public func readRoutingAvailability(
    _ shouldVerify: Bool,
    _ completion:
      @escaping ([String: Bool]) -> Void
  ) {
    evaluateRoutingAvailability(
      shouldVerify,
      completion
    )
  }
  public func watchApplicationForeground() {
    subscribeToAppForeground()
  }
  public func openAddressExternally(
    _ address: String
  ) {
    openAddressInSystemBrowser(
      address
    )
  }
  public func startDefaultBrowser(
    _ address: String
  ) {
    forwardAddressOutward(
      address
    )
  }
  public func presentWithSafari(
    _ address: String
  ) {
    openAddressWithSafariController(
      address
    )
  }
  public func presentInlinePage(
    _ address: String
  ) {
    openAddressInEmbeddedPage(
      address
    )
  }
}
