import CloudKit
import Foundation
import UIKit

// MARK: - Destination Validation
protocol AddressNormalizing {
  func sanitizeAddress(
    _ unverifiedAddress: String?
  ) -> String?
}
struct SimpleAddressNormalizer:
  AddressNormalizing
{
  func sanitizeAddress(
    _ unverifiedAddress: String?
  ) -> String? {
    guard let unverifiedAddress else {
      return nil
    }
    let cleanAddress =
      unverifiedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      cleanAddress.isEmpty == false,
      let destinationURL = URL(string: cleanAddress),
      destinationURL.scheme?.isEmpty == false
    else {
      return nil
    }
    return cleanAddress
  }
}
protocol RouteConfigurationLoading {
  func loadRemotePacket(
    completion:
      @escaping (
        RemoteRoutePacket?,
        Error?
      ) -> Void
  )
}
final class CloudRouteConfigurationLoader:
  RouteConfigurationLoading
{
  func loadRemotePacket(
    completion:
      @escaping (
        RemoteRoutePacket?,
        Error?
      ) -> Void
  ) {
    let cloudSpace = CKContainer(
      identifier:
        MeridianSettings
        .cloudIdentifier
    )
    let publicStore = cloudSpace.publicCloudDatabase
    let cloudRecordKey = CKRecord.ID(
      recordName:
        MeridianSettings
        .publicRecordName
    )
    publicStore.fetch(
      withRecordID: cloudRecordKey
    ) { configurationRecord, fetchFailure in
      if let fetchFailure {
        completion(nil, fetchFailure)
        return
      }
      guard let configurationRecord else {
        completion(nil, nil)
        return
      }
      let modeValue =
        configurationRecord[
          MeridianSettings
            .routeField
        ]
      let addressValue =
        configurationRecord[
          MeridianSettings
            .addressField
        ]
      let parsedMode: String?
      if let modeString = modeValue as? String {
        parsedMode = modeString
      } else if let modeNumber = modeValue as? NSNumber {
        parsedMode = modeNumber.stringValue
      } else if let modeValue {
        parsedMode = String(describing: modeValue)
      } else {
        parsedMode = nil
      }
      let parsedAddress: String?
      if let destinationText = addressValue as? String {
        parsedAddress = destinationText
      } else if let addressNSString = addressValue as? NSString {
        parsedAddress = addressNSString as String
      } else if let addressValue {
        parsedAddress =
          String(describing: addressValue)
      } else {
        parsedAddress = nil
      }
      completion(
        RemoteRoutePacket(
          routeFlag: parsedMode,
          destinationText:
            parsedAddress
        ),
        nil
      )
    }
  }
}
// MARK: - Deterministic Route Resolver
protocol RouteDeciding {
  func chooseRoute(
    from packet: RemoteRoutePacket
  ) -> RouteChoice
}
struct ValueRouteDecider: RouteDeciding {
  func chooseRoute(
    from packet: RemoteRoutePacket
  ) -> RouteChoice {
    guard let selectedMode = packet.routeFlag else {
      return makeSelection(RouteValues.cachedFallback)
    }
    switch selectedMode {
    case "3":
      return makeSelection(
        RouteValues.embeddedPage,
        address: packet.destinationText
      )
    case "4":
      return makeSelection(
        RouteValues.externalPage,
        address: packet.destinationText
      )
    case "5":
      return makeSelection(RouteValues.nativeApplication)
    default:
      return makeSelection(RouteValues.cachedFallback)
    }
  }
  private func makeSelection(
    _ decision: String,
    address: String? = nil
  ) -> RouteChoice {
    var record: RouteChoice = [FieldNames.decision: decision]
    record[FieldNames.destination] = address
    return record
  }
}
