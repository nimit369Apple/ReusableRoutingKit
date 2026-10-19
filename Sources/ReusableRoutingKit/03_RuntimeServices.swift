// MARK: - Link presentation service
import Foundation
import SafariServices
import UIKit

// MARK: - Runtime timing + foreground lifecycle
// MARK: - Retry Scheduler
@available(iOS 13.0, *)
@MainActor
protocol RetryScheduling: AnyObject {
  func scheduleRetry(
    after delay: TimeInterval,
    onFire: @escaping @MainActor () -> Void
  )
  func cancelRetry()
}
@available(iOS 13.0, *)
@MainActor
final class OneShotRetryClock:
  RetryScheduling
{
  private var retryHandle: Timer?
  func scheduleRetry(
    after delay: TimeInterval,
    onFire: @escaping @MainActor () -> Void
  ) {
    cancelRetry()
    retryHandle = Timer.scheduledTimer(
      withTimeInterval: delay,
      repeats: false
    ) { _ in
      Task { @MainActor in
        onFire()
      }
    }
  }
  func cancelRetry() {
    retryHandle?.invalidate()
    retryHandle = nil
  }
}
// MARK: - Startup Preference Polling
@available(iOS 13.0, *)
@MainActor
protocol PreferencePolling: AnyObject {
  func startPollingFlag(
    every delay: TimeInterval,
    onFire: @escaping @MainActor () -> Void
  )
  func stopPollingFlag()
}
@available(iOS 13.0, *)
@MainActor
final class RepeatingPreferenceClock:
  PreferencePolling
{
  private var pollHandle: Timer?
  func startPollingFlag(
    every delay: TimeInterval,
    onFire: @escaping @MainActor () -> Void
  ) {
    stopPollingFlag()
    pollHandle = Timer.scheduledTimer(
      withTimeInterval: delay,
      repeats: true
    ) { _ in
      Task { @MainActor in
        onFire()
      }
    }
  }
  func stopPollingFlag() {
    pollHandle?.invalidate()
    pollHandle = nil
  }
}
// MARK: - Foreground Monitor
@available(iOS 13.0, *)
@MainActor
protocol AppForegroundObserving: AnyObject {
  func startListeningForForeground(
    onFire: @escaping @MainActor () -> Void
  )
  func stopListeningForForeground()
}
@available(iOS 13.0, *)
@MainActor
final class AppForegroundListener:
  NSObject,
  AppForegroundObserving
{
  private var foregroundAction: (@MainActor () -> Void)?
  private var isForegroundListenerAttached = false
  func startListeningForForeground(
    onFire: @escaping @MainActor () -> Void
  ) {
    guard isForegroundListenerAttached == false else {
      return
    }
    foregroundAction = onFire
    NotificationCenter.default.addObserver(
      self,
      selector:
        #selector(handleForegroundSignal),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    isForegroundListenerAttached = true
  }
  func stopListeningForForeground() {
    NotificationCenter.default.removeObserver(self)
    foregroundAction = nil
    isForegroundListenerAttached = false
  }
  @objc
  private func handleForegroundSignal() {
    foregroundAction?()
  }
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
@available(iOS 13.0, *)
@MainActor
protocol ActiveWindowFinding {
  func findEntryWindow(
    for owner: UIViewController
  ) -> UIWindow?
  func findDisplayWindow() -> UIWindow?
  func topmostPresenter(
    from candidate: UIViewController?
  ) -> UIViewController?
}
@available(iOS 13.0, *)
@MainActor
struct ConnectedWindowFinder:
  ActiveWindowFinding
{
  func findEntryWindow(
    for owner: UIViewController
  ) -> UIWindow? {
    let sceneCandidates =
      UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    let activeScene =
      sceneCandidates.first {
        $0.activationState == .foregroundActive
      }
    let inactiveScene =
      sceneCandidates.first {
        $0.activationState == .foregroundInactive
      }
    guard
      let chosenScene =
        activeScene
        ?? inactiveScene
        ?? sceneCandidates.first
    else {
      return nil
    }
    let keyWindow =
      chosenScene.windows.first {
        $0.isKeyWindow
      }
    let normalWindow =
      chosenScene.windows.first {
        $0.windowLevel == .normal
      }
    return owner.view.window
      ?? owner.navigationController?.view.window
      ?? keyWindow
      ?? normalWindow
      ?? chosenScene.windows.first
  }
  func findDisplayWindow() -> UIWindow? {
    let sceneCandidates =
      UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    let preferredScene =
      sceneCandidates.first {
        $0.activationState == .foregroundActive
      } ?? sceneCandidates.first
    return preferredScene?.windows.first {
      $0.isKeyWindow
    } ?? preferredScene?.windows.first
  }
  func topmostPresenter(
    from candidate: UIViewController?
  ) -> UIViewController? {
    guard let candidate else {
      return nil
    }
    if let navigationController =
      candidate as? UINavigationController
    {
      return topmostPresenter(
        from: navigationController.visibleViewController
      )
    }
    if let presentedViewController =
      candidate.presentedViewController
    {
      return topmostPresenter(
        from: presentedViewController
      )
    }
    return candidate
  }
}

// MARK: - Destination Presentation
@available(iOS 13.0, *)
@MainActor
protocol LinkPresenting {
  func sendToDefaultBrowser(
    _ address: String
  )
  func displayInsideApplication(
    _ address: String
  )
  func displayInSafariSheet(
    _ address: String
  )
}
@available(iOS 13.0, *)
@MainActor
final class LinkDisplayManager:
  LinkPresenting
{
  private let windowFinder: ActiveWindowFinding
  init(
    windowFinder:
      ActiveWindowFinding
  ) {
    self.windowFinder = windowFinder
  }
  func sendToDefaultBrowser(
    _ address: String
  ) {
    guard let destinationURL = URL(string: address) else {
      return
    }
    UIApplication.shared.open(
      destinationURL,
      options: [:],
      completionHandler: nil
    )
  }
  func displayInsideApplication(
    _ address: String
  ) {
    let pageModel =
      LaunchDependencies
      .buildPageModel(
        address: address
      )
    let pageController =
      InlinePageViewController(
        pageModel: pageModel
      )
    guard
      let appWindow =
        windowFinder
        .findDisplayWindow(),
      let presenter =
        windowFinder.topmostPresenter(
          from: appWindow.rootViewController
        )
    else {
      return
    }
    pageController.modalPresentationStyle = .fullScreen
    presenter.present(
      pageController,
      animated: false
    )
  }
  func displayInSafariSheet(
    _ address: String
  ) {
    guard let destinationURL = URL(string: address) else {
      return
    }
    guard
      let appWindow =
        windowFinder
        .findDisplayWindow(),
      let presenter =
        windowFinder.topmostPresenter(
          from: appWindow.rootViewController
        )
    else {
      return
    }
    let safariPage =
      SFSafariViewController(url: destinationURL)
    presenter.present(
      safariPage,
      animated: true
    )
  }
}
