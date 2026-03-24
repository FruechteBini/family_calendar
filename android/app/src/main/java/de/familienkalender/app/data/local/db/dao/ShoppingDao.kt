package de.familienkalender.app.data.local.db.dao

import androidx.room.*
import de.familienkalender.app.data.local.db.entity.ShoppingItemEntity
import de.familienkalender.app.data.local.db.entity.ShoppingListEntity
import kotlinx.coroutines.flow.Flow

data class ShoppingListWithItems(
    @Embedded val list: ShoppingListEntity,
    @Relation(parentColumn = "id", entityColumn = "shoppingListId")
    val items: List<ShoppingItemEntity>
)

@Dao
interface ShoppingDao {

    @Transaction
    @Query("SELECT * FROM shopping_lists WHERE status = 'active' LIMIT 1")
    fun getActiveList(): Flow<ShoppingListWithItems?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertList(list: ShoppingListEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertItems(items: List<ShoppingItemEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertItem(item: ShoppingItemEntity)

    @Query("DELETE FROM shopping_items WHERE id = :id")
    suspend fun deleteItem(id: Int)

    @Query("DELETE FROM shopping_items WHERE shoppingListId = :listId")
    suspend fun deleteItemsForList(listId: Int)

    @Query("DELETE FROM shopping_lists")
    suspend fun deleteAllLists()

    @Query("DELETE FROM shopping_items")
    suspend fun deleteAllItems()
}
