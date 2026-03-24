package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class ProposalCreate(
    @SerializedName("proposed_date") val proposedDate: String,
    val message: String? = null
)

data class ProposalRespondRequest(
    val response: String,
    val message: String? = null,
    @SerializedName("counter_date") val counterDate: String? = null
)

data class ProposalMember(
    val id: Int,
    val name: String,
    @SerializedName("avatar_emoji") val avatarEmoji: String
)

data class ProposalResponse(
    val id: Int,
    val proposer: ProposalMember,
    @SerializedName("proposed_date") val proposedDate: String,
    val status: String,
    val message: String?,
    val responses: List<ProposalResponseItem>
)

data class ProposalResponseItem(
    val member: ProposalMember,
    val response: String,
    @SerializedName("counter_proposal_id") val counterProposalId: Int?,
    val message: String?
)

data class PendingProposalDetail(
    val id: Int,
    @SerializedName("todo_id") val todoId: Int,
    @SerializedName("todo_title") val todoTitle: String,
    val proposer: ProposalMember,
    @SerializedName("proposed_date") val proposedDate: String,
    val message: String?,
    val status: String,
    @SerializedName("created_at") val createdAt: String
)
