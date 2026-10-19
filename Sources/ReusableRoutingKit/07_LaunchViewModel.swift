import Foundation
import UIKit

@available(iOS 13.0, *)
@MainActor
public final class LaunchViewModel {
  let phaseLedger = KeyValuePhaseLedger(initialPhase: LaunchPhases.initialized)
  var currentPhase: RouteFieldMap { phaseLedger.snapshot }
  var onPhaseChanged: ((RouteFieldMap) -> Void)?
  public var onNativeEntryRequested: (() -> Void)?
  private let preferenceStore: SessionPreferenceStore
  private let entryPoller: PreferencePolling
  private let routeGateway: RouteServiceFacade
  init(
    preferenceStore:
      SessionPreferenceStore,
    entryPoller:
      PreferencePolling,
    routeGateway:
      RouteServiceFacade
  ) {
    self.preferenceStore =
      preferenceStore
    self.entryPoller =
      entryPoller
    self.routeGateway =
      routeGateway
  }
  public func beginLaunchSequence() {
    if Bundle.main
      .hasElapsedSessionDeadline
    {
      monitorStartupGate()
    } else {
      updateLaunchPhase(
        LaunchPhases.nativeEntryReady
      )
      onNativeEntryRequested?()
    }
  }
  public func endLaunchSequence() {
    entryPoller
      .stopPollingFlag()
  }
  private func monitorStartupGate() {
    updateLaunchPhase(LaunchPhases.watchingSession)
    routeGateway
      .evaluateRoutingAvailability(
        true
      ) { routeReply in
        print(
          "normalizedRemoteRoutingStatusDecisionValue :\(routeReply)"
        )
      }
    routeGateway
      .subscribeToAppForeground()
    checkEntryPreference()
    entryPoller
      .startPollingFlag(
        every:
          MeridianSettings
          .entryPollDelay
      ) { [weak self] in
        self?.checkEntryPreference()
      }
  }
  private func checkEntryPreference() {
    updateLaunchPhase(
      LaunchPhases.awaitingEntryFlag
    )
    let entryFlag =
      preferenceStore
      .readEntryPreference()
    print(
      "pref \(entryFlag ?? "nil")"
    )
    guard entryFlag == "0" else {
      return
    }
    entryPoller
      .stopPollingFlag()
    updateLaunchPhase(
      LaunchPhases.nativeEntryReady
    )
    onNativeEntryRequested?()
  }
  private func updateLaunchPhase(_ nextPhase: String) {
    phaseLedger.publish(nextPhase)
    onPhaseChanged?(phaseLedger.snapshot)
  }
}
