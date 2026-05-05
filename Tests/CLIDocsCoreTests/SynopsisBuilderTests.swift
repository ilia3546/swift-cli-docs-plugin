import XCTest
import ArgumentParserToolInfo
@testable import CLIDocsCore

final class SynopsisBuilderTests: XCTestCase {
    func testSimpleSynopsisOrderingPlacesPositionalsLast() throws {
        let json = """
        {
          "serializationVersion": 0,
          "command": {
            "commandName": "demo",
            "shouldDisplay": true,
            "arguments": [
              {"kind": "positional", "shouldDisplay": true, "isOptional": false, "isRepeating": false, "parsingStrategy": "default", "valueName": "path"},
              {"kind": "flag", "shouldDisplay": true, "isOptional": true, "isRepeating": false, "parsingStrategy": "default", "names": [{"kind": "long", "name": "release"}], "preferredName": {"kind": "long", "name": "release"}}
            ]
          }
        }
        """
        let tool = try DumpHelpRunner().decode(Data(json.utf8))
        let synopsis = SynopsisBuilder.build(commandPath: ["demo"], arguments: tool.command.arguments)
        XCTAssertEqual(synopsis, "demo [--release] <path>")
    }

    func testRepeatingPositionalGetsEllipsis() throws {
        let json = """
        {
          "serializationVersion": 0,
          "command": {
            "commandName": "demo",
            "shouldDisplay": true,
            "arguments": [
              {"kind": "positional", "shouldDisplay": true, "isOptional": false, "isRepeating": true, "parsingStrategy": "default", "valueName": "path"}
            ]
          }
        }
        """
        let tool = try DumpHelpRunner().decode(Data(json.utf8))
        let synopsis = SynopsisBuilder.build(commandPath: ["demo"], arguments: tool.command.arguments)
        XCTAssertEqual(synopsis, "demo <path>...")
    }

    func testHiddenArgsExcludedFromSynopsis() throws {
        let json = """
        {
          "serializationVersion": 0,
          "command": {
            "commandName": "demo",
            "shouldDisplay": true,
            "arguments": [
              {"kind": "flag", "shouldDisplay": false, "isOptional": true, "isRepeating": false, "parsingStrategy": "default", "names": [{"kind": "long", "name": "secret"}], "preferredName": {"kind": "long", "name": "secret"}},
              {"kind": "flag", "shouldDisplay": true, "isOptional": true, "isRepeating": false, "parsingStrategy": "default", "names": [{"kind": "long", "name": "verbose"}], "preferredName": {"kind": "long", "name": "verbose"}}
            ]
          }
        }
        """
        let tool = try DumpHelpRunner().decode(Data(json.utf8))
        let synopsis = SynopsisBuilder.build(commandPath: ["demo"], arguments: tool.command.arguments)
        XCTAssertEqual(synopsis, "demo [--verbose]")
    }
}
