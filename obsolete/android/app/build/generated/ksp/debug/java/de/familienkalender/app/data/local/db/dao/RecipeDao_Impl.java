package de.familienkalender.app.data.local.db.dao;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.collection.LongSparseArray;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.room.util.RelationUtil;
import androidx.room.util.StringUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import de.familienkalender.app.data.local.db.entity.IngredientEntity;
import de.familienkalender.app.data.local.db.entity.RecipeEntity;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Float;
import java.lang.Integer;
import java.lang.Object;
import java.lang.Override;
import java.lang.String;
import java.lang.StringBuilder;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import javax.annotation.processing.Generated;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlinx.coroutines.flow.Flow;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class RecipeDao_Impl implements RecipeDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<RecipeEntity> __insertionAdapterOfRecipeEntity;

  private final EntityInsertionAdapter<IngredientEntity> __insertionAdapterOfIngredientEntity;

  private final SharedSQLiteStatement __preparedStmtOfDeleteIngredients;

  private final SharedSQLiteStatement __preparedStmtOfDeleteById;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAll;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAllIngredients;

  public RecipeDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfRecipeEntity = new EntityInsertionAdapter<RecipeEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `recipes` (`id`,`title`,`source`,`cookidooId`,`servings`,`prepTimeActiveMinutes`,`prepTimePassiveMinutes`,`difficulty`,`lastCookedAt`,`cookCount`,`notes`,`imageUrl`,`aiAccessible`,`createdAt`,`updatedAt`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final RecipeEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getTitle());
        statement.bindString(3, entity.getSource());
        if (entity.getCookidooId() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getCookidooId());
        }
        statement.bindLong(5, entity.getServings());
        if (entity.getPrepTimeActiveMinutes() == null) {
          statement.bindNull(6);
        } else {
          statement.bindLong(6, entity.getPrepTimeActiveMinutes());
        }
        if (entity.getPrepTimePassiveMinutes() == null) {
          statement.bindNull(7);
        } else {
          statement.bindLong(7, entity.getPrepTimePassiveMinutes());
        }
        statement.bindString(8, entity.getDifficulty());
        if (entity.getLastCookedAt() == null) {
          statement.bindNull(9);
        } else {
          statement.bindString(9, entity.getLastCookedAt());
        }
        statement.bindLong(10, entity.getCookCount());
        if (entity.getNotes() == null) {
          statement.bindNull(11);
        } else {
          statement.bindString(11, entity.getNotes());
        }
        if (entity.getImageUrl() == null) {
          statement.bindNull(12);
        } else {
          statement.bindString(12, entity.getImageUrl());
        }
        final int _tmp = entity.getAiAccessible() ? 1 : 0;
        statement.bindLong(13, _tmp);
        statement.bindString(14, entity.getCreatedAt());
        statement.bindString(15, entity.getUpdatedAt());
      }
    };
    this.__insertionAdapterOfIngredientEntity = new EntityInsertionAdapter<IngredientEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `ingredients` (`id`,`recipeId`,`name`,`amount`,`unit`,`category`) VALUES (?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final IngredientEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindLong(2, entity.getRecipeId());
        statement.bindString(3, entity.getName());
        if (entity.getAmount() == null) {
          statement.bindNull(4);
        } else {
          statement.bindDouble(4, entity.getAmount());
        }
        if (entity.getUnit() == null) {
          statement.bindNull(5);
        } else {
          statement.bindString(5, entity.getUnit());
        }
        statement.bindString(6, entity.getCategory());
      }
    };
    this.__preparedStmtOfDeleteIngredients = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM ingredients WHERE recipeId = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteById = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM recipes WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAll = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM recipes";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAllIngredients = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM ingredients";
        return _query;
      }
    };
  }

  @Override
  public Object upsert(final RecipeEntity recipe, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfRecipeEntity.insert(recipe);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertAll(final List<RecipeEntity> recipes,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfRecipeEntity.insert(recipes);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertIngredients(final List<IngredientEntity> ingredients,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfIngredientEntity.insert(ingredients);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteIngredients(final int recipeId,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteIngredients.acquire();
        int _argIndex = 1;
        _stmt.bindLong(_argIndex, recipeId);
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteIngredients.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteById(final int id, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteById.acquire();
        int _argIndex = 1;
        _stmt.bindLong(_argIndex, id);
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteById.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteAll(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAll.acquire();
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteAll.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteAllIngredients(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAllIngredients.acquire();
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteAllIngredients.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<RecipeWithIngredients>> getAll() {
    final String _sql = "SELECT * FROM recipes ORDER BY title";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, true, new String[] {"ingredients",
        "recipes"}, new Callable<List<RecipeWithIngredients>>() {
      @Override
      @NonNull
      public List<RecipeWithIngredients> call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
            final int _cursorIndexOfSource = CursorUtil.getColumnIndexOrThrow(_cursor, "source");
            final int _cursorIndexOfCookidooId = CursorUtil.getColumnIndexOrThrow(_cursor, "cookidooId");
            final int _cursorIndexOfServings = CursorUtil.getColumnIndexOrThrow(_cursor, "servings");
            final int _cursorIndexOfPrepTimeActiveMinutes = CursorUtil.getColumnIndexOrThrow(_cursor, "prepTimeActiveMinutes");
            final int _cursorIndexOfPrepTimePassiveMinutes = CursorUtil.getColumnIndexOrThrow(_cursor, "prepTimePassiveMinutes");
            final int _cursorIndexOfDifficulty = CursorUtil.getColumnIndexOrThrow(_cursor, "difficulty");
            final int _cursorIndexOfLastCookedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "lastCookedAt");
            final int _cursorIndexOfCookCount = CursorUtil.getColumnIndexOrThrow(_cursor, "cookCount");
            final int _cursorIndexOfNotes = CursorUtil.getColumnIndexOrThrow(_cursor, "notes");
            final int _cursorIndexOfImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "imageUrl");
            final int _cursorIndexOfAiAccessible = CursorUtil.getColumnIndexOrThrow(_cursor, "aiAccessible");
            final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
            final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
            final LongSparseArray<ArrayList<IngredientEntity>> _collectionIngredients = new LongSparseArray<ArrayList<IngredientEntity>>();
            while (_cursor.moveToNext()) {
              final long _tmpKey;
              _tmpKey = _cursor.getLong(_cursorIndexOfId);
              if (!_collectionIngredients.containsKey(_tmpKey)) {
                _collectionIngredients.put(_tmpKey, new ArrayList<IngredientEntity>());
              }
            }
            _cursor.moveToPosition(-1);
            __fetchRelationshipingredientsAsdeFamilienkalenderAppDataLocalDbEntityIngredientEntity(_collectionIngredients);
            final List<RecipeWithIngredients> _result = new ArrayList<RecipeWithIngredients>(_cursor.getCount());
            while (_cursor.moveToNext()) {
              final RecipeWithIngredients _item;
              final RecipeEntity _tmpRecipe;
              final int _tmpId;
              _tmpId = _cursor.getInt(_cursorIndexOfId);
              final String _tmpTitle;
              _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
              final String _tmpSource;
              _tmpSource = _cursor.getString(_cursorIndexOfSource);
              final String _tmpCookidooId;
              if (_cursor.isNull(_cursorIndexOfCookidooId)) {
                _tmpCookidooId = null;
              } else {
                _tmpCookidooId = _cursor.getString(_cursorIndexOfCookidooId);
              }
              final int _tmpServings;
              _tmpServings = _cursor.getInt(_cursorIndexOfServings);
              final Integer _tmpPrepTimeActiveMinutes;
              if (_cursor.isNull(_cursorIndexOfPrepTimeActiveMinutes)) {
                _tmpPrepTimeActiveMinutes = null;
              } else {
                _tmpPrepTimeActiveMinutes = _cursor.getInt(_cursorIndexOfPrepTimeActiveMinutes);
              }
              final Integer _tmpPrepTimePassiveMinutes;
              if (_cursor.isNull(_cursorIndexOfPrepTimePassiveMinutes)) {
                _tmpPrepTimePassiveMinutes = null;
              } else {
                _tmpPrepTimePassiveMinutes = _cursor.getInt(_cursorIndexOfPrepTimePassiveMinutes);
              }
              final String _tmpDifficulty;
              _tmpDifficulty = _cursor.getString(_cursorIndexOfDifficulty);
              final String _tmpLastCookedAt;
              if (_cursor.isNull(_cursorIndexOfLastCookedAt)) {
                _tmpLastCookedAt = null;
              } else {
                _tmpLastCookedAt = _cursor.getString(_cursorIndexOfLastCookedAt);
              }
              final int _tmpCookCount;
              _tmpCookCount = _cursor.getInt(_cursorIndexOfCookCount);
              final String _tmpNotes;
              if (_cursor.isNull(_cursorIndexOfNotes)) {
                _tmpNotes = null;
              } else {
                _tmpNotes = _cursor.getString(_cursorIndexOfNotes);
              }
              final String _tmpImageUrl;
              if (_cursor.isNull(_cursorIndexOfImageUrl)) {
                _tmpImageUrl = null;
              } else {
                _tmpImageUrl = _cursor.getString(_cursorIndexOfImageUrl);
              }
              final boolean _tmpAiAccessible;
              final int _tmp;
              _tmp = _cursor.getInt(_cursorIndexOfAiAccessible);
              _tmpAiAccessible = _tmp != 0;
              final String _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
              final String _tmpUpdatedAt;
              _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
              _tmpRecipe = new RecipeEntity(_tmpId,_tmpTitle,_tmpSource,_tmpCookidooId,_tmpServings,_tmpPrepTimeActiveMinutes,_tmpPrepTimePassiveMinutes,_tmpDifficulty,_tmpLastCookedAt,_tmpCookCount,_tmpNotes,_tmpImageUrl,_tmpAiAccessible,_tmpCreatedAt,_tmpUpdatedAt);
              final ArrayList<IngredientEntity> _tmpIngredientsCollection;
              final long _tmpKey_1;
              _tmpKey_1 = _cursor.getLong(_cursorIndexOfId);
              _tmpIngredientsCollection = _collectionIngredients.get(_tmpKey_1);
              _item = new RecipeWithIngredients(_tmpRecipe,_tmpIngredientsCollection);
              _result.add(_item);
            }
            __db.setTransactionSuccessful();
            return _result;
          } finally {
            _cursor.close();
          }
        } finally {
          __db.endTransaction();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Object getById(final int id,
      final Continuation<? super RecipeWithIngredients> $completion) {
    final String _sql = "SELECT * FROM recipes WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, true, _cancellationSignal, new Callable<RecipeWithIngredients>() {
      @Override
      @Nullable
      public RecipeWithIngredients call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
            final int _cursorIndexOfSource = CursorUtil.getColumnIndexOrThrow(_cursor, "source");
            final int _cursorIndexOfCookidooId = CursorUtil.getColumnIndexOrThrow(_cursor, "cookidooId");
            final int _cursorIndexOfServings = CursorUtil.getColumnIndexOrThrow(_cursor, "servings");
            final int _cursorIndexOfPrepTimeActiveMinutes = CursorUtil.getColumnIndexOrThrow(_cursor, "prepTimeActiveMinutes");
            final int _cursorIndexOfPrepTimePassiveMinutes = CursorUtil.getColumnIndexOrThrow(_cursor, "prepTimePassiveMinutes");
            final int _cursorIndexOfDifficulty = CursorUtil.getColumnIndexOrThrow(_cursor, "difficulty");
            final int _cursorIndexOfLastCookedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "lastCookedAt");
            final int _cursorIndexOfCookCount = CursorUtil.getColumnIndexOrThrow(_cursor, "cookCount");
            final int _cursorIndexOfNotes = CursorUtil.getColumnIndexOrThrow(_cursor, "notes");
            final int _cursorIndexOfImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "imageUrl");
            final int _cursorIndexOfAiAccessible = CursorUtil.getColumnIndexOrThrow(_cursor, "aiAccessible");
            final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
            final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
            final LongSparseArray<ArrayList<IngredientEntity>> _collectionIngredients = new LongSparseArray<ArrayList<IngredientEntity>>();
            while (_cursor.moveToNext()) {
              final long _tmpKey;
              _tmpKey = _cursor.getLong(_cursorIndexOfId);
              if (!_collectionIngredients.containsKey(_tmpKey)) {
                _collectionIngredients.put(_tmpKey, new ArrayList<IngredientEntity>());
              }
            }
            _cursor.moveToPosition(-1);
            __fetchRelationshipingredientsAsdeFamilienkalenderAppDataLocalDbEntityIngredientEntity(_collectionIngredients);
            final RecipeWithIngredients _result;
            if (_cursor.moveToFirst()) {
              final RecipeEntity _tmpRecipe;
              final int _tmpId;
              _tmpId = _cursor.getInt(_cursorIndexOfId);
              final String _tmpTitle;
              _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
              final String _tmpSource;
              _tmpSource = _cursor.getString(_cursorIndexOfSource);
              final String _tmpCookidooId;
              if (_cursor.isNull(_cursorIndexOfCookidooId)) {
                _tmpCookidooId = null;
              } else {
                _tmpCookidooId = _cursor.getString(_cursorIndexOfCookidooId);
              }
              final int _tmpServings;
              _tmpServings = _cursor.getInt(_cursorIndexOfServings);
              final Integer _tmpPrepTimeActiveMinutes;
              if (_cursor.isNull(_cursorIndexOfPrepTimeActiveMinutes)) {
                _tmpPrepTimeActiveMinutes = null;
              } else {
                _tmpPrepTimeActiveMinutes = _cursor.getInt(_cursorIndexOfPrepTimeActiveMinutes);
              }
              final Integer _tmpPrepTimePassiveMinutes;
              if (_cursor.isNull(_cursorIndexOfPrepTimePassiveMinutes)) {
                _tmpPrepTimePassiveMinutes = null;
              } else {
                _tmpPrepTimePassiveMinutes = _cursor.getInt(_cursorIndexOfPrepTimePassiveMinutes);
              }
              final String _tmpDifficulty;
              _tmpDifficulty = _cursor.getString(_cursorIndexOfDifficulty);
              final String _tmpLastCookedAt;
              if (_cursor.isNull(_cursorIndexOfLastCookedAt)) {
                _tmpLastCookedAt = null;
              } else {
                _tmpLastCookedAt = _cursor.getString(_cursorIndexOfLastCookedAt);
              }
              final int _tmpCookCount;
              _tmpCookCount = _cursor.getInt(_cursorIndexOfCookCount);
              final String _tmpNotes;
              if (_cursor.isNull(_cursorIndexOfNotes)) {
                _tmpNotes = null;
              } else {
                _tmpNotes = _cursor.getString(_cursorIndexOfNotes);
              }
              final String _tmpImageUrl;
              if (_cursor.isNull(_cursorIndexOfImageUrl)) {
                _tmpImageUrl = null;
              } else {
                _tmpImageUrl = _cursor.getString(_cursorIndexOfImageUrl);
              }
              final boolean _tmpAiAccessible;
              final int _tmp;
              _tmp = _cursor.getInt(_cursorIndexOfAiAccessible);
              _tmpAiAccessible = _tmp != 0;
              final String _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
              final String _tmpUpdatedAt;
              _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
              _tmpRecipe = new RecipeEntity(_tmpId,_tmpTitle,_tmpSource,_tmpCookidooId,_tmpServings,_tmpPrepTimeActiveMinutes,_tmpPrepTimePassiveMinutes,_tmpDifficulty,_tmpLastCookedAt,_tmpCookCount,_tmpNotes,_tmpImageUrl,_tmpAiAccessible,_tmpCreatedAt,_tmpUpdatedAt);
              final ArrayList<IngredientEntity> _tmpIngredientsCollection;
              final long _tmpKey_1;
              _tmpKey_1 = _cursor.getLong(_cursorIndexOfId);
              _tmpIngredientsCollection = _collectionIngredients.get(_tmpKey_1);
              _result = new RecipeWithIngredients(_tmpRecipe,_tmpIngredientsCollection);
            } else {
              _result = null;
            }
            __db.setTransactionSuccessful();
            return _result;
          } finally {
            _cursor.close();
            _statement.release();
          }
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }

  private void __fetchRelationshipingredientsAsdeFamilienkalenderAppDataLocalDbEntityIngredientEntity(
      @NonNull final LongSparseArray<ArrayList<IngredientEntity>> _map) {
    if (_map.isEmpty()) {
      return;
    }
    if (_map.size() > RoomDatabase.MAX_BIND_PARAMETER_CNT) {
      RelationUtil.recursiveFetchLongSparseArray(_map, true, (map) -> {
        __fetchRelationshipingredientsAsdeFamilienkalenderAppDataLocalDbEntityIngredientEntity(map);
        return Unit.INSTANCE;
      });
      return;
    }
    final StringBuilder _stringBuilder = StringUtil.newStringBuilder();
    _stringBuilder.append("SELECT `id`,`recipeId`,`name`,`amount`,`unit`,`category` FROM `ingredients` WHERE `recipeId` IN (");
    final int _inputSize = _map.size();
    StringUtil.appendPlaceholders(_stringBuilder, _inputSize);
    _stringBuilder.append(")");
    final String _sql = _stringBuilder.toString();
    final int _argCount = 0 + _inputSize;
    final RoomSQLiteQuery _stmt = RoomSQLiteQuery.acquire(_sql, _argCount);
    int _argIndex = 1;
    for (int i = 0; i < _map.size(); i++) {
      final long _item = _map.keyAt(i);
      _stmt.bindLong(_argIndex, _item);
      _argIndex++;
    }
    final Cursor _cursor = DBUtil.query(__db, _stmt, false, null);
    try {
      final int _itemKeyIndex = CursorUtil.getColumnIndex(_cursor, "recipeId");
      if (_itemKeyIndex == -1) {
        return;
      }
      final int _cursorIndexOfId = 0;
      final int _cursorIndexOfRecipeId = 1;
      final int _cursorIndexOfName = 2;
      final int _cursorIndexOfAmount = 3;
      final int _cursorIndexOfUnit = 4;
      final int _cursorIndexOfCategory = 5;
      while (_cursor.moveToNext()) {
        final long _tmpKey;
        _tmpKey = _cursor.getLong(_itemKeyIndex);
        final ArrayList<IngredientEntity> _tmpRelation = _map.get(_tmpKey);
        if (_tmpRelation != null) {
          final IngredientEntity _item_1;
          final int _tmpId;
          _tmpId = _cursor.getInt(_cursorIndexOfId);
          final int _tmpRecipeId;
          _tmpRecipeId = _cursor.getInt(_cursorIndexOfRecipeId);
          final String _tmpName;
          _tmpName = _cursor.getString(_cursorIndexOfName);
          final Float _tmpAmount;
          if (_cursor.isNull(_cursorIndexOfAmount)) {
            _tmpAmount = null;
          } else {
            _tmpAmount = _cursor.getFloat(_cursorIndexOfAmount);
          }
          final String _tmpUnit;
          if (_cursor.isNull(_cursorIndexOfUnit)) {
            _tmpUnit = null;
          } else {
            _tmpUnit = _cursor.getString(_cursorIndexOfUnit);
          }
          final String _tmpCategory;
          _tmpCategory = _cursor.getString(_cursorIndexOfCategory);
          _item_1 = new IngredientEntity(_tmpId,_tmpRecipeId,_tmpName,_tmpAmount,_tmpUnit,_tmpCategory);
          _tmpRelation.add(_item_1);
        }
      }
    } finally {
      _cursor.close();
    }
  }
}
