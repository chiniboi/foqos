import CodeScanner
import CoreNFC
import SwiftUI

class PhysicalReader {
  private let nfcScanner: NFCScannerUtil = NFCScannerUtil()

  func readNFCTag(
    onSuccess: @escaping (String) -> Void,
    onFailure: @escaping (String) -> Void = { _ in }
  ) {
    nfcScanner.onTagScanned = { result in
      let tagId = result.url ?? result.id
      onSuccess(tagId)
    }
    nfcScanner.onError = onFailure

    nfcScanner.scan(profileName: "")
  }

  /// The simulator has no camera, so adding a code there invents one.
  private var simulatedCodeValue: String? {
    #if targetEnvironment(simulator)
      return "simulated-code-\(Int.random(in: 1000...9999))"
    #else
      return nil
    #endif
  }

  func readQRCode(
    onSuccess: @escaping (String) -> Void,
    onFailure: @escaping (String) -> Void
  ) -> some View {
    return LabeledCodeScannerView(
      heading: "Scan to set",
      subtitle: "Point your camera at a QR/Barcode code to set a physical unblock.",
      simulatedData: simulatedCodeValue
    ) { result in
      switch result {
      case .success(let scanResult):
        onSuccess(scanResult.string)
      case .failure(let error):
        onFailure(error.localizedDescription)
      }
    }
  }
}
