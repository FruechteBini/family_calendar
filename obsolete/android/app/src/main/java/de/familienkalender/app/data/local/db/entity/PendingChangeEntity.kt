package de.familienkalender.app.data.local.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Queued offline change to be replayed when connectivity is restored.
 *
 * @property entityType Domain type, e.g. "event", "todo", "category", "family_member",
 *   "recipe", "meal_plan", "shopping_item".
 * @property entityId Server-side ID of the entity. Null for CREATE operations where the
 *   server ID is not yet known.
 * @property action HTTP verb: "CREATE", "UPDATE", "DELETE", or "PATCH".
 * @property endpoint Full API path, e.g. "api/todos/".
 * @property payload JSON body to send. Null for DELETE.
 */
@Entity(tableName = "pending_changes")
data class PendingChangeEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val entityType: String,
    val entityId: Int?,
    val action: String,
    val endpoint: String,
    val payload: String?,
    val createdAt: Long = System.currentTimeMillis()
)
