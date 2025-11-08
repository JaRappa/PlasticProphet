// Models.swift
// Basic domain stubs for PlasticProphet
// Generated as initial scaffolding

import Foundation

struct Card: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var network: String
    var last4: String
    var rewardSummary: String
}

struct Recommendation: Identifiable, Hashable {
    let id = UUID()
    var card: Card
    var merchantName: String
    var rationale: String
    var rewardText: String
}

struct PermissionsStatus {
    var cameraAuthorized: Bool = false
    var locationAuthorized: Bool = false
    var allGranted: Bool { cameraAuthorized && locationAuthorized }
}
