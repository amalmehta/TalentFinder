import Foundation
import TalentFinderCore

// Writes the website's survey data and scoring fixtures. Run from the repository root:
//     swift run ExportWebData
let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath)
for (path, data) in [(WebExport.surveyPath, try WebExport.surveyJSON()), (WebExport.fixturesPath, try WebExport.fixturesJSON())] {
    let url = root.appendingPathComponent(path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
    print("Wrote \(path)")
}
