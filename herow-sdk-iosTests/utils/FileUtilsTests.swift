//
//  FileUtilsTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 04/03/2021.
//

import XCTest
@testable import herow_sdk_ios
class FileUtilsTests: XCTestCase {

    var content: String?
    var data: Data?
    let fileName: String = "test.test"

    override func setUp() {
        content = "I love writing/loading content from file with Promise"
        data = content!.data(using: .utf8)
    }

    override func tearDown() {
        try? FileUtils.deleteFile(directory: .documentDirectory, fileName: fileName)
        super.tearDown()
    }

    func testFile() {

        if let url: URL = try? FileUtils.generateDocumentPath(directory: .documentDirectory, fileName: fileName),
            let documentExists: Bool = try? url.checkResourceIsReachable() {
            XCTAssertFalse(documentExists)
        }
        FileUtils.createAppSupportDirectoryIfNeeded()
        XCTAssertTrue(FileUtils.saveToFileSync( fileName: fileName, data: data!))
        XCTAssertTrue(FileUtils.deleteFileSync( fileName: fileName))
    }


}
