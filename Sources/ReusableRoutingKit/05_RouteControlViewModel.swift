import Foundation
import UIKit

@available(iOS 13.0, *)
@MainActor
final class RouteViewModel {
  let phaseLedger = KeyValuePhaseLedger(initialPhase: RoutePhases.idle)
  var currentPhase: RouteFieldMap { phaseLedger.snapshot }
  var onPhaseChanged: ((RouteFieldMap) -> Void)?
  private let remoteLoader: RouteConfigurationLoading
  private let routeDecider: RouteDeciding
  private let preferenceStore: SessionPreferenceStore
  private let addressNormalizer: AddressNormalizing
  private let linkPresenter: LinkPresenting
  private let retryClock: RetryScheduling
  private let foregroundMonitor: AppForegroundObserving
  init(
    remoteLoader:
      RouteConfigurationLoading,
    routeDecider:
      RouteDeciding,
    preferenceStore:
      SessionPreferenceStore,
    addressNormalizer:
      AddressNormalizing,
    linkPresenter:
      LinkPresenting,
    retryClock:
      RetryScheduling,
    foregroundMonitor:
      AppForegroundObserving
  ) {
    self.remoteLoader =
      remoteLoader
    self.routeDecider =
      routeDecider
    self.preferenceStore =
      preferenceStore
    self.addressNormalizer =
      addressNormalizer
    self.linkPresenter =
      linkPresenter
    self.retryClock =
      retryClock
    self.foregroundMonitor =
      foregroundMonitor
  }
  func checkRouteAvailability(
    shouldVerify: Bool,
    completion: @escaping ([String: Bool]) -> Void
  ) {
    guard shouldVerify else {
      completion(
        MeridianSettings
          .successPayload
      )
      return
    }
    reloadRemoteRoute()
    completion(
      MeridianSettings
        .successPayload
    )
  }
  func enableForegroundUpdates() {
    foregroundMonitor
      .startListeningForForeground {
        [weak self] in
        self?.reloadRemoteRoute()
      }
  }
  func disableForegroundUpdates() {
    foregroundMonitor
      .stopListeningForForeground()
  }
  func openOutsideApplication(
    _ chosenRoute: String
  ) {
    linkPresenter
      .sendToDefaultBrowser(chosenRoute)
  }
  func openSafariPresentation(
    _ chosenRoute: String
  ) {
    linkPresenter
      .displayInSafariSheet(chosenRoute)
  }
  func openInlinePresentation(
    _ chosenRoute: String
  ) {
    linkPresenter
      .displayInsideApplication(chosenRoute)
  }
  // MARK: - Remote Loading
  private func reloadRemoteRoute() {
    retryClock.cancelRetry()
    updateRoutePhase(RoutePhases.fetchingSettings)
    remoteLoader
      .loadRemotePacket {
        [weak self] packet, remoteFailure in
        Task { @MainActor [weak self] in
          guard let self else {
            return
          }
          if let remoteFailure {
            print(
              " remoteConfigurationAcquisitionError: "
                + remoteFailure.localizedDescription
            )
            self.recoverFromLastAddress()
            return
          }
          guard let packet else {
            self.recoverFromLastAddress()
            return
          }
          self.applyRemotePacket(packet)
        }
      }
  }
  // MARK: - Route Evaluation
  private func applyRemotePacket(
    _ packet: RemoteRoutePacket
  ) {
    guard let selectedMode = packet.routeFlag else {
      recoverFromLastAddress()
      return
    }
    print(
      "remoteRoutingConfigurationCloudRecord 1: \(selectedMode)"
    )
    preferenceStore
      .writeEntryPreference("1")
    let chosenRoute =
      routeDecider.chooseRoute(
        from: packet
      )
    let unverifiedAddress = chosenRoute[FieldNames.destination]
    switch chosenRoute[FieldNames.decision] {
    case RouteValues.embeddedPage:
      preferenceStore
        .writeEntryPreference("1")
      guard
        let safeAddress =
          addressNormalizer
          .sanitizeAddress(
            unverifiedAddress
          )
      else {
        recoverFromLastAddress()
        return
      }
      preferenceStore
        .writeLastAddress(
          safeAddress
        )
      updateRoutePhase(
        RoutePhases.openingInlinePage
      )
      linkPresenter
        .displayInsideApplication(
          safeAddress
        )
      retryClock.cancelRetry()
      disableForegroundUpdates()
    case RouteValues.externalPage:
      preferenceStore
        .writeEntryPreference("1")
      guard
        let safeAddress =
          addressNormalizer
          .sanitizeAddress(
            unverifiedAddress
          )
      else {
        recoverFromLastAddress()
        return
      }
      preferenceStore
        .writeLastAddress(
          safeAddress
        )
      updateRoutePhase(
        RoutePhases.openingExternalPage
      )
      linkPresenter
        .sendToDefaultBrowser(
          safeAddress
        )
    case RouteValues.nativeApplication:
      preferenceStore
        .writeEntryPreference("0")
      retryClock.cancelRetry()
      updateRoutePhase(
        RoutePhases.awaitingNativeExperience
      )
    default:
      recoverFromLastAddress()
    }
  }
  // MARK: - Fallback / Retry
  private func recoverFromLastAddress() {
    updateRoutePhase(
      RoutePhases.checkingSavedAddress
    )
    let savedAddress =
      preferenceStore
      .readLastAddress()
    guard
      let usableSavedAddress =
        addressNormalizer
        .sanitizeAddress(
          savedAddress
        )
    else {
      planAnotherFetch()
      return
    }
    preferenceStore
      .writeEntryPreference("1")
    linkPresenter
      .displayInsideApplication(
        usableSavedAddress
      )
    retryClock.cancelRetry()
    disableForegroundUpdates()
  }
  private func planAnotherFetch() {
    updateRoutePhase(RoutePhases.pendingRefresh)
    retryClock.scheduleRetry(
      after:
        MeridianSettings
        .retryDelay
    ) { [weak self] in
      self?.reloadRemoteRoute()
    }
  }
  // MARK: - State Binding
  private func updateRoutePhase(_ nextPhase: String) {
    phaseLedger.publish(nextPhase)
    onPhaseChanged?(phaseLedger.snapshot)
  }
}
