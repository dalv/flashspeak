import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// The CSV export, built only when the user shares it.
struct PhraseExport: Transferable {
    let makeData: @MainActor @Sendable () -> Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { export in
            await export.makeData()
        }
        .suggestedFileName("FlashSpeak phrases.csv")
    }
}
