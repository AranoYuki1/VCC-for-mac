//
//  VCCMacTests.swift
//  VCCMacTests
//
//  Created by yuki on 2022/12/27.
//

import XCTest
@testable import VCCMac

extension Bundle {
    static let current = Bundle(for: { class __ {}; return  __.self }())
}

final class VCCMacTests: XCTestCase {
    func testProjectType() async throws {
        let catalyst = try VPMCatalyst()
        let vpm = VPM(catalyst: catalyst)
        
        guard let avatarProjectURL = Bundle.current.url(forResource: "Avatar", withExtension: nil) else {
            return XCTFail("No project.")
        }
        
        let projectType = try await vpm.getProjectType(at: avatarProjectURL)
        XCTAssertEqual(projectType, .avatarVPM)
    }
    
    func testListTemplates() async throws {
        let catalyst = try VPMCatalyst()
        let vpm = VPM(catalyst: catalyst)
        
        print(try await vpm.listTemplates()) 
    }
    
    func testRequirements() async throws {
        let catalyst = try VPMCatalyst()
        let vpm = VPM(catalyst: catalyst)
        
        try await vpm.checkHub()
        try await vpm.checkUnity()
    }
}
