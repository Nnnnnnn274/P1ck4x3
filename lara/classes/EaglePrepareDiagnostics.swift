import SwiftUI
import UIKit
import Combine
import Darwin

/// Passive, user-triggered diagnostics for Prepare.
///
/// A report is assembled only after the user asks for one. Prepare writes one
/// tiny durable checkpoint only at broad phase boundaries, never while
/// DarkSword's race is executing.
@MainActor
final class EaglePrepareDiagnostics: ObservableObject {
    static let shared = EaglePrepareDiagnostics()

    @Published private(set) var reportURL: URL?
    @Published private(set) var isCreatingReport = false
    @Published private(set) var reportError: String?

    private init() {}

    func createReport() {
        guard !isCreatingReport else { return }

        isCreatingReport = true
        reportError = nil

        let metadata = Self.metadata()
        let attemptCheckpoint = EaglePrepareAttemptJournal.diagnosticText()
        DispatchQueue.global(qos: .utility).async {
            do {
                let url = try Self.writeReport(
                    metadata: metadata,
                    attemptCheckpoint: attemptCheckpoint
                )
                DispatchQueue.main.async {
                    self.reportURL = url
                    self.isCreatingReport = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.reportError = error.localizedDescription
                    self.isCreatingReport = false
                }
            }
        }
    }

    nonisolated private static func writeReport(
        metadata: String,
        attemptCheckpoint: String
    ) throws -> URL {
        let manager = FileManager.default
        let documents = try manager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let source = documents.appendingPathComponent("lara.log")
        let previousSource = documents.appendingPathComponent("lara.previous.log")
        let olderSource = documents.appendingPathComponent("lara.previous.2.log")
        let destinationFolder = documents.appendingPathComponent(
            "EaglePrepareReports",
            isDirectory: true
        )

        try manager.createDirectory(
            at: destinationFolder,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )

        let logText = readTail(source, maximumBytes: 256 * 1024)
        let previousLogText = readTail(previousSource, maximumBytes: 256 * 1024)
        let olderLogText = readTail(olderSource, maximumBytes: 256 * 1024)
        let report = """
        Eagle Prepare Diagnostic
        Generated only after the user requested this report.
        Report creation never starts automatically and adds no live Prepare observer.
        Prepare updates one small checkpoint only outside DarkSword's race.

        \(metadata)

        \(attemptCheckpoint)

        Older app session (may be unrelated; last 256 KB, addresses redacted)
        ----------------------------------------------------------------------
        \(redact(olderLogText))

        Previous app session (may be unrelated; last 256 KB, addresses redacted)
        -------------------------------------------------------------------------
        \(redact(previousLogText))

        Current app session (last 256 KB, addresses redacted)
        -----------------------------------------------------
        \(redact(logText))
        """

        let filename = "Eagle-Prepare-Diagnostic-\(filenameTimestamp()).txt"
        let destination = destinationFolder.appendingPathComponent(filename)
        let reportData = Data(report.utf8)
        guard !reportData.isEmpty, reportData.count <= 1024 * 1024 else {
            throw CocoaError(.fileWriteOutOfSpace)
        }
        try reportData.write(to: destination, options: .atomic)
        try? manager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: destination.path
        )
        pruneReports(in: destinationFolder, keeping: 10, preserving: destination)
        return destination
    }

    nonisolated private static func readTail(
        _ url: URL,
        maximumBytes: Int
    ) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return "<not available>"
        }
        defer { try? handle.close() }

        do {
            let end = try handle.seekToEnd()
            let count = min(max(1, maximumBytes), 1024 * 1024)
            let limit = UInt64(count)
            if end > limit {
                try handle.seek(toOffset: end - limit)
            } else {
                try handle.seek(toOffset: 0)
            }
            let chunk = try handle.read(upToCount: count + 1) ?? Data()
            let data = chunk.count <= count ? chunk : Data(chunk.suffix(count))
            return String(decoding: data, as: UTF8.self)
        } catch {
            return "<could not read: \(error.localizedDescription)>"
        }
    }

    nonisolated private static func pruneReports(
        in folder: URL,
        keeping limit: Int,
        preserving protectedURL: URL
    ) {
        guard limit > 0 else { return }
        let manager = FileManager.default
        let keys: Set<URLResourceKey> = [
            .contentModificationDateKey,
            .isRegularFileKey,
            .isSymbolicLinkKey,
        ]
        let reports = ((try? manager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        )) ?? []).compactMap { url -> (URL, Date)? in
            guard url.lastPathComponent.hasPrefix("Eagle-Prepare-Diagnostic-"),
                  url.pathExtension.lowercased() == "txt",
                  let values = try? url.resourceValues(forKeys: keys),
                  values.isRegularFile == true,
                  values.isSymbolicLink != true else { return nil }
            return (url, values.contentModificationDate ?? .distantPast)
        }.sorted { $0.1 > $1.1 }

        let protectedPath = protectedURL.standardizedFileURL.path
        var retained = 1
        for report in reports where report.0.standardizedFileURL.path != protectedPath {
            if retained < limit {
                retained += 1
            } else {
                try? manager.removeItem(at: report.0)
            }
        }
    }

    private static func metadata() -> String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let machine = machineIdentifier()
        let systemBuild = sysctlString("kern.osversion") ?? "unknown"
        let support = eagleSupportAssessment(
            version: os,
            machine: machine,
            systemBuild: systemBuild == "unknown" ? nil : systemBuild
        )
        let locale = Locale.current.identifier
        let launchContext = islcruntime() ? "LiveContainer" : "native app"

        return """
        App: Eagle \(version) (\(build))
        Device: \(machine)
        iOS: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion) (\(systemBuild))
        Prepare support: \(support.status.rawValue) [\(support.reason.rawValue)]
        Launch context: \(launchContext)
        Locale: \(locale)
        Generated: \(ISO8601DateFormatter().string(from: Date()))
        """
    }

    nonisolated private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0,
              size > 1, size <= 4_096 else {
            return nil
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else {
            return nil
        }
        let length = buffer.firstIndex(of: 0) ?? buffer.count
        return String(decoding: buffer[..<length].map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    nonisolated private static func machineIdentifier() -> String {
        var info = utsname()
        uname(&info)
        let capacity = MemoryLayout.size(ofValue: info.machine)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                let length = strnlen($0, capacity)
                let bytes = UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self)
                return String(
                    decoding: UnsafeBufferPointer(start: bytes, count: length),
                    as: UTF8.self
                )
            }
        }
    }

    nonisolated private static func redact(_ input: String) -> String {
        var output = input

        let patterns = [
            #"0x[0-9a-fA-F]{6,}"#,
            #"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"#
        ]

        for pattern in patterns {
            guard let expression = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(output.startIndex..., in: output)
            output = expression.stringByReplacingMatches(
                in: output,
                range: range,
                withTemplate: pattern.hasPrefix("0x") ? "<address>" : "<uuid>"
            )
        }

        return output
    }

    nonisolated private static func filenameTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}

struct EaglePrepareCrashReportCard: View {
    @ObservedObject private var diagnostics = EaglePrepareDiagnostics.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)

                Text(LaraL10n.text(
                    en: "Prepare diagnostics",
                    es: "Diagnóstico de preparación"
                ))
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 0)
            }

            Text(LaraL10n.text(
                en: "If Prepare fails or the iPhone restarts, create and share this report.",
                es: "Si Preparar falla o el iPhone se reinicia, crea y comparte este reporte."
            ))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let url = diagnostics.reportURL {
                ShareLink(item: url) {
                    Label(
                        LaraL10n.text(en: "Share Prepare Report", es: "Compartir reporte de preparación"),
                        systemImage: "square.and.arrow.up"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
            } else {
                Button {
                    diagnostics.createReport()
                } label: {
                    HStack {
                        if diagnostics.isCreatingReport {
                            EagleRainbowSpinner(size: 18)
                        }
                        Text(LaraL10n.text(en: "Create Prepare Report", es: "Crear reporte de preparación"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
                .disabled(diagnostics.isCreatingReport)
            }

            if let error = diagnostics.reportError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.22), lineWidth: 1)
        }
    }
}
