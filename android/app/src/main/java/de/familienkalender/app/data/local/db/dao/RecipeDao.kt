package de.familienkalender.app.data.local.db.dao

import androidx.room.*
import de.familienkalender.app.data.local.db.entity.IngredientEntity
import de.familienkalender.app.data.local.db.entity.RecipeEntity
import kotlinx.coroutines.flow.Flow

data class RecipeWithIngredients(
    @Embedded val recipe: RecipeEntity,
    @Relation(parentColumn = "id", entityColumn = "recipeId")
    val ingredients: List<IngredientEntity>
)

@Dao
interface RecipeDao {

    @Transaction
    @Query("SELECT * FROM recipes ORDER BY title")
    fun getAll(): Flow<List<RecipeWithIngredients>>

    @Transaction
    @Query("SELECT * FROM recipes WHERE id = :id")
    suspend fun getById(id: Int): RecipeWithIngredients?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(recipe: RecipeEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(recipes: List<RecipeEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertIngredients(ingredients: List<IngredientEntity>)

    @Query("DELETE FROM ingredients WHERE recipeId = :recipeId")
    suspend fun deleteIngredients(recipeId: Int)

    @Query("DELETE FROM recipes WHERE id = :id")
    suspend fun deleteById(id: Int)

    @Query("DELETE FROM recipes")
    suspend fun deleteAll()

    @Query("DELETE FROM ingredients")
    suspend fun deleteAllIngredients()
}
