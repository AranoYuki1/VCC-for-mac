//
//  AppFailureModel.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import CoreUtil

final class AppFailureModel {
    let appModel: AppModel
    let logger: Logger
    let reasons: [VPMRequirementChecker.FailureReason]
    
    init(reasons: [VPMRequirementChecker.FailureReason], appModel: AppModel, logger: Logger) {
        self.logger = logger
        self.reasons = reasons
        self.appModel = appModel
    }
}
