package de.familienkalender.app.data.local.db.dao;

import android.database.Cursor;
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
import de.familienkalender.app.data.local.db.entity.ShoppingItemEntity;
import de.familienkalender.app.data.local.db.entity.ShoppingListEntity;
import java.lang.Class;
import java.lang.Exception;
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
public final class ShoppingDao_Impl implements ShoppingDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<ShoppingListEntity> __insertionAdapterOfShoppingListEntity;

  private final EntityInsertionAdapter<ShoppingItemEntity> __insertionAdapterOfShoppingItemEntity;

  private final SharedSQLiteStatement __preparedStmtOfDeleteItem;

  private final SharedSQLiteStatement __preparedStmtOfDeleteItemsForList;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAllLists;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAllItems;

  public ShoppingDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfShoppingListEntity = new EntityInsertionAdapter<ShoppingListEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `shopping_lists` (`id`,`weekStartDate`,`status`,`sortedByStore`,`createdAt`) VALUES (?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final ShoppingListEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getWeekStartDate());
        statement.bindString(3, entity.getStatus());
        if (entity.getSortedByStore() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getSortedByStore());
        }
        statement.bindString(5, entity.getCreatedAt());
      }
    };
    this.__insertionAdapterOfShoppingItemEntity = new EntityInsertionAdapter<ShoppingItemEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `shopping_items` (`id`,`shoppingListId`,`name`,`amount`,`unit`,`category`,`checked`,`source`,`recipeId`,`aiAccessible`,`sortOrder`,`storeSection`,`createdAt`,`updatedAt`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final ShoppingItemEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindLong(2, entity.getShoppingListId());
        statement.bindString(3, entity.getName());
        if (entity.getAmount() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getAmount());
        }
        if (entity.getUnit() == null) {
          statement.bindNull(5);
        } else {
          statement.bindString(5, entity.getUnit());
        }
        statement.bindString(6, entity.getCategory());
        final int _tmp = entity.getChecked() ? 1 : 0;
        statement.bindLong(7, _tmp);
        statement.bindString(8, entity.getSource());
        if (entity.getRecipeId() == null) {
          statement.bindNull(9);
        } else {
          statement.bindLong(9, entity.getRecipeId());
        }
        final int _tmp_1 = entity.getAiAccessible() ? 1 : 0;
        statement.bindLong(10, _tmp_1);
        if (entity.getSortOrder() == null) {
          statement.bindNull(11);
        } else {
          statement.bindLong(11, entity.getSortOrder());
        }
        if (entity.getStoreSection() == null) {
          statement.bindNull(12);
        } else {
          statement.bindString(12, entity.getStoreSection());
        }
        statement.bindString(13, entity.getCreatedAt());
        statement.bindString(14, entity.getUpdatedAt());
      }
    };
    this.__preparedStmtOfDeleteItem = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM shopping_items WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteItemsForList = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM shopping_items WHERE shoppingListId = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAllLists = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM shopping_lists";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAllItems = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM shopping_items";
        return _query;
      }
    };
  }

  @Override
  public Object upsertList(final ShoppingListEntity list,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfShoppingListEntity.insert(list);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertItems(final List<ShoppingItemEntity> items,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfShoppingItemEntity.insert(items);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertItem(final ShoppingItemEntity item,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfShoppingItemEntity.insert(item);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteItem(final int id, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteItem.acquire();
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
          __preparedStmtOfDeleteItem.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteItemsForList(final int listId, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteItemsForList.acquire();
        int _argIndex = 1;
        _stmt.bindLong(_argIndex, listId);
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
          __preparedStmtOfDeleteItemsForList.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteAllLists(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAllLists.acquire();
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
          __preparedStmtOfDeleteAllLists.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteAllItems(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAllItems.acquire();
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
          __preparedStmtOfDeleteAllItems.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<ShoppingListWithItems> getActiveList() {
    final String _sql = "SELECT * FROM shopping_lists WHERE status = 'active' LIMIT 1";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, true, new String[] {"shopping_items",
        "shopping_lists"}, new Callable<ShoppingListWithItems>() {
      @Override
      @Nullable
      public ShoppingListWithItems call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfWeekStartDate = CursorUtil.getColumnIndexOrThrow(_cursor, "weekStartDate");
            final int _cursorIndexOfStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "status");
            final int _cursorIndexOfSortedByStore = CursorUtil.getColumnIndexOrThrow(_cursor, "sortedByStore");
            final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
            final LongSparseArray<ArrayList<ShoppingItemEntity>> _collectionItems = new LongSparseArray<ArrayList<ShoppingItemEntity>>();
            while (_cursor.moveToNext()) {
              final long _tmpKey;
              _tmpKey = _cursor.getLong(_cursorIndexOfId);
              if (!_collectionItems.containsKey(_tmpKey)) {
                _collectionItems.put(_tmpKey, new ArrayList<ShoppingItemEntity>());
              }
            }
            _cursor.moveToPosition(-1);
            __fetchRelationshipshoppingItemsAsdeFamilienkalenderAppDataLocalDbEntityShoppingItemEntity(_collectionItems);
            final ShoppingListWithItems _result;
            if (_cursor.moveToFirst()) {
              final ShoppingListEntity _tmpList;
              final int _tmpId;
              _tmpId = _cursor.getInt(_cursorIndexOfId);
              final String _tmpWeekStartDate;
              _tmpWeekStartDate = _cursor.getString(_cursorIndexOfWeekStartDate);
              final String _tmpStatus;
              _tmpStatus = _cursor.getString(_cursorIndexOfStatus);
              final String _tmpSortedByStore;
              if (_cursor.isNull(_cursorIndexOfSortedByStore)) {
                _tmpSortedByStore = null;
              } else {
                _tmpSortedByStore = _cursor.getString(_cursorIndexOfSortedByStore);
              }
              final String _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
              _tmpList = new ShoppingListEntity(_tmpId,_tmpWeekStartDate,_tmpStatus,_tmpSortedByStore,_tmpCreatedAt);
              final ArrayList<ShoppingItemEntity> _tmpItemsCollection;
              final long _tmpKey_1;
              _tmpKey_1 = _cursor.getLong(_cursorIndexOfId);
              _tmpItemsCollection = _collectionItems.get(_tmpKey_1);
              _result = new ShoppingListWithItems(_tmpList,_tmpItemsCollection);
            } else {
              _result = null;
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

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }

  private void __fetchRelationshipshoppingItemsAsdeFamilienkalenderAppDataLocalDbEntityShoppingItemEntity(
      @NonNull final LongSparseArray<ArrayList<ShoppingItemEntity>> _map) {
    if (_map.isEmpty()) {
      return;
    }
    if (_map.size() > RoomDatabase.MAX_BIND_PARAMETER_CNT) {
      RelationUtil.recursiveFetchLongSparseArray(_map, true, (map) -> {
        __fetchRelationshipshoppingItemsAsdeFamilienkalenderAppDataLocalDbEntityShoppingItemEntity(map);
        return Unit.INSTANCE;
      });
      return;
    }
    final StringBuilder _stringBuilder = StringUtil.newStringBuilder();
    _stringBuilder.append("SELECT `id`,`shoppingListId`,`name`,`amount`,`unit`,`category`,`checked`,`source`,`recipeId`,`aiAccessible`,`sortOrder`,`storeSection`,`createdAt`,`updatedAt` FROM `shopping_items` WHERE `shoppingListId` IN (");
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
      final int _itemKeyIndex = CursorUtil.getColumnIndex(_cursor, "shoppingListId");
      if (_itemKeyIndex == -1) {
        return;
      }
      final int _cursorIndexOfId = 0;
      final int _cursorIndexOfShoppingListId = 1;
      final int _cursorIndexOfName = 2;
      final int _cursorIndexOfAmount = 3;
      final int _cursorIndexOfUnit = 4;
      final int _cursorIndexOfCategory = 5;
      final int _cursorIndexOfChecked = 6;
      final int _cursorIndexOfSource = 7;
      final int _cursorIndexOfRecipeId = 8;
      final int _cursorIndexOfAiAccessible = 9;
      final int _cursorIndexOfSortOrder = 10;
      final int _cursorIndexOfStoreSection = 11;
      final int _cursorIndexOfCreatedAt = 12;
      final int _cursorIndexOfUpdatedAt = 13;
      while (_cursor.moveToNext()) {
        final long _tmpKey;
        _tmpKey = _cursor.getLong(_itemKeyIndex);
        final ArrayList<ShoppingItemEntity> _tmpRelation = _map.get(_tmpKey);
        if (_tmpRelation != null) {
          final ShoppingItemEntity _item_1;
          final int _tmpId;
          _tmpId = _cursor.getInt(_cursorIndexOfId);
          final int _tmpShoppingListId;
          _tmpShoppingListId = _cursor.getInt(_cursorIndexOfShoppingListId);
          final String _tmpName;
          _tmpName = _cursor.getString(_cursorIndexOfName);
          final String _tmpAmount;
          if (_cursor.isNull(_cursorIndexOfAmount)) {
            _tmpAmount = null;
          } else {
            _tmpAmount = _cursor.getString(_cursorIndexOfAmount);
          }
          final String _tmpUnit;
          if (_cursor.isNull(_cursorIndexOfUnit)) {
            _tmpUnit = null;
          } else {
            _tmpUnit = _cursor.getString(_cursorIndexOfUnit);
          }
          final String _tmpCategory;
          _tmpCategory = _cursor.getString(_cursorIndexOfCategory);
          final boolean _tmpChecked;
          final int _tmp;
          _tmp = _cursor.getInt(_cursorIndexOfChecked);
          _tmpChecked = _tmp != 0;
          final String _tmpSource;
          _tmpSource = _cursor.getString(_cursorIndexOfSource);
          final Integer _tmpRecipeId;
          if (_cursor.isNull(_cursorIndexOfRecipeId)) {
            _tmpRecipeId = null;
          } else {
            _tmpRecipeId = _cursor.getInt(_cursorIndexOfRecipeId);
          }
          final boolean _tmpAiAccessible;
          final int _tmp_1;
          _tmp_1 = _cursor.getInt(_cursorIndexOfAiAccessible);
          _tmpAiAccessible = _tmp_1 != 0;
          final Integer _tmpSortOrder;
          if (_cursor.isNull(_cursorIndexOfSortOrder)) {
            _tmpSortOrder = null;
          } else {
            _tmpSortOrder = _cursor.getInt(_cursorIndexOfSortOrder);
          }
          final String _tmpStoreSection;
          if (_cursor.isNull(_cursorIndexOfStoreSection)) {
            _tmpStoreSection = null;
          } else {
            _tmpStoreSection = _cursor.getString(_cursorIndexOfStoreSection);
          }
          final String _tmpCreatedAt;
          _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
          final String _tmpUpdatedAt;
          _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
          _item_1 = new ShoppingItemEntity(_tmpId,_tmpShoppingListId,_tmpName,_tmpAmount,_tmpUnit,_tmpCategory,_tmpChecked,_tmpSource,_tmpRecipeId,_tmpAiAccessible,_tmpSortOrder,_tmpStoreSection,_tmpCreatedAt,_tmpUpdatedAt);
          _tmpRelation.add(_item_1);
        }
      }
    } finally {
      _cursor.close();
    }
  }
}
