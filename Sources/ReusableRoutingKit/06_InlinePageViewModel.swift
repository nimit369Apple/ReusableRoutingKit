import Foundation
import UIKit

@available(iOS 13.0, *)
@MainActor
final class InlinePageViewModel {
  let phaseLedger = KeyValuePhaseLedger(initialPhase: PagePhases.initialized)
  var currentPhase: RouteFieldMap { phaseLedger.snapshot }
  var onPhaseChanged: ((RouteFieldMap) -> Void)?
  private let destinationText: String
  private var loadingDelayTimer: Timer?
  init(destinationText: String) {
    self.destinationText = destinationText
  }
  func beginPageSession() {
    loadingDelayTimer?.invalidate()
    loadingDelayTimer = nil
    guard let destinationURL = URL(string: destinationText) else {
      updatePagePhase(PagePhases.invalidDestination, address: destinationText)
      return
    }
    updatePagePhase(PagePhases.loading, address: destinationURL.absoluteString)
    loadingDelayTimer = Timer.scheduledTimer(
      withTimeInterval: MeridianSettings.loadingCoverDuration,
      repeats: false
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.updatePagePhase(
          PagePhases.ready,
          address: destinationURL.absoluteString
        )
      }
    }
  }
  func endPageSession() {
    loadingDelayTimer?.invalidate()
    loadingDelayTimer = nil
  }
  private func updatePagePhase(_ phase: String, address: String? = nil) {
    phaseLedger.publish(phase, destination: address)
    onPhaseChanged?(phaseLedger.snapshot)
  }
}
