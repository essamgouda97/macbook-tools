import XCTest
@testable import MacToolsCore

final class MacToolsCoreTests: XCTestCase {
    func testKeychainManagerSaveAndRetrieve() throws {
        let manager = KeychainManager(service: "com.macbooktools.test")

        // Clean up any previous test data
        try? manager.delete(forKey: "test_key")

        // Test save and retrieve
        try manager.save("test_value", forKey: "test_key")
        let retrieved = manager.get(forKey: "test_key")
        XCTAssertEqual(retrieved, "test_value")

        // Clean up
        try manager.delete(forKey: "test_key")
        XCTAssertNil(manager.get(forKey: "test_key"))
    }

    func testAccessibilityManagerPermissionCheck() {
        // This test just verifies the check doesn't crash
        _ = AccessibilityManager.hasPermission
    }
}
