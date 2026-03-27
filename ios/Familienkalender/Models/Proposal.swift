import Foundation

struct ProposalCreate: Codable {
    let proposedDate: String
    var message: String?
}

struct ProposalRespondRequest: Codable {
    let response: String
    var message: String?
    var counterDate: String?
}

struct ProposalDetail: Codable, Identifiable {
    let id: Int
    let todoId: Int
    let proposer: FamilyMemberResponse
    let proposedDate: String
    let message: String?
    let status: String
    let responses: [ProposalResponseDetail]
    let createdAt: String
}

struct ProposalResponseDetail: Codable, Identifiable {
    let id: Int
    let member: FamilyMemberResponse
    let response: String
    let counterProposalId: Int?
    let message: String?
    let createdAt: String
}

struct PendingProposalDetail: Codable, Identifiable {
    let id: Int
    let todoId: Int
    let todoTitle: String
    let proposer: FamilyMemberResponse
    let proposedDate: String
    let message: String?
    let status: String
    let createdAt: String
}
