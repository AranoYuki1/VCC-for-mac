//
//  ProcessorType.swift
//  VCCMac
//
//  Created by yuki on 2023/01/10.
//

import Foundation

public enum ProcessorType: String {
    case arm64 = "arm64"
    case x86_64 = "x86_64"
    case unknown = "unknown"
    
    public static func current() -> ProcessorType {
        var sysInfo = utsname()
        guard uname(&sysInfo) == EXIT_SUCCESS else { return .unknown }
        let data = Data(bytes: &sysInfo.machine, count: Int(_SYS_NAMELEN))
        guard let identifier = String(data: data, encoding: .ascii) else { return .unknown }
        let processor = identifier.trimmingCharacters(in: .controlCharacters)
        guard let type = ProcessorType(rawValue: processor) else { return .unknown }
        return type
    }
}
