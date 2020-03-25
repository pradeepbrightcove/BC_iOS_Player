//
//  ServerConstants.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/10/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

enum ModelConstants {
    static let RegionField = "region"
    static let RegionCodeField = "region_code"
    static let ChannelsField = "channels"
    static let StartTimeField = "start_time"

    static let StartField = "start"
    static let DurationSecondsField = "duration_seconds"
    static let ChannelIDField = "channel_id"
    static let ChannelCodeField = "channel_code"
    static let ChannelNameField = "channel_name"
    static let ResourceIDField = "mvpd_resource_id"
    static let PriorityField = "priority"
    static let RegionNameField = "region_name"
    static let ApplicationIDField = "application_id"
    static let PlatformField = "platform"
    static let ProgramIDField = "program_id"
    static let ProgramCodeField = "program_code"
    static let ProgramTitleField = "program_title"
    static let ProgramTitleBriefField = "program_title_brief"
    static let LiveField = "live"
    static let ProgramsField = "programs"
    static let CurrentTimeField = "current_time"
    static let EmbedCodeField = "embed_code"
    static let ProviderCodeField = "provider_code"
    static let OptField = "opt"
    static let ApiKeyField = "backlot_api_key"
    static let DeviceZIPField = "device_zip"
    static let BillingZIPField = "billing_zip"
    static let UserIdField = "user_id"
    static let MVPDNameField = "mvpd_name"
    static let JWTTokenField = "jwt_token"
    static let ErrorCodeField = "error_code"
    static let OKField = "ok"
    static let ShortMediaTokenField = "short_media_token"
    static let TokenField = "token"
    static let AuthorizationField = "Authorization"
    static let ApplicationIdField = "application_id"
    static let PlatformValue = "ios"

    static let ChannelField = "channel"
    static let CurrentAirDateField = "current_air_date"
    static let CurrentProgramCodeField = "current_program_code"

    static let PrimaryValue = "Primary"
    static let AlternateValue = "Alternate"

    static let RequestorId = "requestor_id"
    static let SignedRequestorId = "signed_requestor_id"
    static let ConcurrencyApplicationId = "application_guid"
    static let SoftwareStatement = "software_statement"

    static let ProgramPollingDelayField = "programPollingDelay"
    static let DeviceZipTimeoutField = "deviceZipTimeout"
    static let ErrorsField = "errors"

    static let BlacklistedMvpdsField = "blacklistedMvpdIds"

    static let ErrorModelBodyField = "body"
    static let ErrorModelCodeField = "code"
    static let ErrorModelHeaderField = "header"
    static let ErrorModelRecoveryField = "recovery"
    static let ErrorModelIconField = "icon_class"

    static let ContactValue = "contact"
    static let CareersValue = "careers"
    static let PrivacyValue = "privacy"
    static let CertificationValue = "certifications"
    static let ResourcesValue = "resources"
    static let PressValue = "press"
    static let AboutUsValue = "about"
    static let UserAgreementValue = "userAgreement"

    static let unsecureErrorTitle = "Unsecure device."
    static let unsecureErrorMessage = "The device is rooted. For security reasons the application " +
                                      "cannot be run from a rooted device."
}
