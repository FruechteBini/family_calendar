package de.familienkalender.app.data.local.db.dao;

import android.database.Cursor;
import androidx.annotation.NonNull;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import de.familienkalender.app.data.local.db.entity.PantryItemEntity;
import java.lang.Class;
import java.lang.Double;
import java.lang.Exception;
import java.lang.Object;
import java.lang.Override;
import java.lang.String;
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
public final class PantryDao_Impl implements PantryDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<PantryItemEntity> __insertionAdapterOfPantryItemEntity;

  private final SharedSQLiteStatement __preparedStmtOfDeleteById;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAll;

  public PantryDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfPantryItemEntity = new EntityInsertionAdapter<PantryItemEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `pantry_items` (`id`,`name`,`amount`,`unit`,`category`,`expiryDate`,`minStock`,`isLowStock`,`isExpiringSoon`,`createdAt`,`updatedAt`) VALUES (?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final PantryItemEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getName());
        if (entity.getAmount() == null) {
          statement.bindNull(3);
        } else {
          statement.bindDouble(3, entity.getAmount());
        }
        if (entity.getUnit() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getUnit());
        }
        statement.bindString(5, entity.getCategory());
        if (entity.getExpiryDate() == null) {
          statement.bindNull(6);
        } else {
          statement.bindString(6, entity.getExpiryDate());
        }
        if (entity.getMinStock() == null) {
          statement.bindNull(7);
        } else {
          statement.bindDouble(7, entity.getMinStock());
        }
        final int _tmp = entity.isLowStock() ? 1 : 0;
        statement.bindLong(8, _tmp);
        final int _tmp_1 = entity.isExpiringSoon() ? 1 : 0;
        statement.bindLong(9, _tmp_1);
        statement.bindString(10, entity.getCreatedAt());
        statement.bindString(11, entity.getUpdatedAt());
      }
    };
    this.__preparedStmtOfDeleteById = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM pantry_items WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAll = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM pantry_items";
        return _query;
      }
    };
  }

  @Override
  public Object upsert(final PantryItemEntity item, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfPantryItemEntity.insert(item);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertAll(final List<PantryItemEntity> items,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfPantryItemEntity.insert(items);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
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
  public Flow<List<PantryItemEntity>> getAll() {
    final String _sql = "SELECT * FROM pantry_items ORDER BY category, name";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"pantry_items"}, new Callable<List<PantryItemEntity>>() {
      @Override
      @NonNull
      public List<PantryItemEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfAmount = CursorUtil.getColumnIndexOrThrow(_cursor, "amount");
          final int _cursorIndexOfUnit = CursorUtil.getColumnIndexOrThrow(_cursor, "unit");
          final int _cursorIndexOfCategory = CursorUtil.getColumnIndexOrThrow(_cursor, "category");
          final int _cursorIndexOfExpiryDate = CursorUtil.getColumnIndexOrThrow(_cursor, "expiryDate");
          final int _cursorIndexOfMinStock = CursorUtil.getColumnIndexOrThrow(_cursor, "minStock");
          final int _cursorIndexOfIsLowStock = CursorUtil.getColumnIndexOrThrow(_cursor, "isLowStock");
          final int _cursorIndexOfIsExpiringSoon = CursorUtil.getColumnIndexOrThrow(_cursor, "isExpiringSoon");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final List<PantryItemEntity> _result = new ArrayList<PantryItemEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final PantryItemEntity _item;
            final int _tmpId;
            _tmpId = _cursor.getInt(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final Double _tmpAmount;
            if (_cursor.isNull(_cursorIndexOfAmount)) {
              _tmpAmount = null;
            } else {
              _tmpAmount = _cursor.getDouble(_cursorIndexOfAmount);
            }
            final String _tmpUnit;
            if (_cursor.isNull(_cursorIndexOfUnit)) {
              _tmpUnit = null;
            } else {
              _tmpUnit = _cursor.getString(_cursorIndexOfUnit);
            }
            final String _tmpCategory;
            _tmpCategory = _cursor.getString(_cursorIndexOfCategory);
            final String _tmpExpiryDate;
            if (_cursor.isNull(_cursorIndexOfExpiryDate)) {
              _tmpExpiryDate = null;
            } else {
              _tmpExpiryDate = _cursor.getString(_cursorIndexOfExpiryDate);
            }
            final Double _tmpMinStock;
            if (_cursor.isNull(_cursorIndexOfMinStock)) {
              _tmpMinStock = null;
            } else {
              _tmpMinStock = _cursor.getDouble(_cursorIndexOfMinStock);
            }
            final boolean _tmpIsLowStock;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfIsLowStock);
            _tmpIsLowStock = _tmp != 0;
            final boolean _tmpIsExpiringSoon;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfIsExpiringSoon);
            _tmpIsExpiringSoon = _tmp_1 != 0;
            final String _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
            final String _tmpUpdatedAt;
            _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
            _item = new PantryItemEntity(_tmpId,_tmpName,_tmpAmount,_tmpUnit,_tmpCategory,_tmpExpiryDate,_tmpMinStock,_tmpIsLowStock,_tmpIsExpiringSoon,_tmpCreatedAt,_tmpUpdatedAt);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Flow<List<PantryItemEntity>> getByCategory(final String category) {
    final String _sql = "SELECT * FROM pantry_items WHERE category = ? ORDER BY name";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, category);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"pantry_items"}, new Callable<List<PantryItemEntity>>() {
      @Override
      @NonNull
      public List<PantryItemEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfAmount = CursorUtil.getColumnIndexOrThrow(_cursor, "amount");
          final int _cursorIndexOfUnit = CursorUtil.getColumnIndexOrThrow(_cursor, "unit");
          final int _cursorIndexOfCategory = CursorUtil.getColumnIndexOrThrow(_cursor, "category");
          final int _cursorIndexOfExpiryDate = CursorUtil.getColumnIndexOrThrow(_cursor, "expiryDate");
          final int _cursorIndexOfMinStock = CursorUtil.getColumnIndexOrThrow(_cursor, "minStock");
          final int _cursorIndexOfIsLowStock = CursorUtil.getColumnIndexOrThrow(_cursor, "isLowStock");
          final int _cursorIndexOfIsExpiringSoon = CursorUtil.getColumnIndexOrThrow(_cursor, "isExpiringSoon");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final List<PantryItemEntity> _result = new ArrayList<PantryItemEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final PantryItemEntity _item;
            final int _tmpId;
            _tmpId = _cursor.getInt(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final Double _tmpAmount;
            if (_cursor.isNull(_cursorIndexOfAmount)) {
              _tmpAmount = null;
            } else {
              _tmpAmount = _cursor.getDouble(_cursorIndexOfAmount);
            }
            final String _tmpUnit;
            if (_cursor.isNull(_cursorIndexOfUnit)) {
              _tmpUnit = null;
            } else {
              _tmpUnit = _cursor.getString(_cursorIndexOfUnit);
            }
            final String _tmpCategory;
            _tmpCategory = _cursor.getString(_cursorIndexOfCategory);
            final String _tmpExpiryDate;
            if (_cursor.isNull(_cursorIndexOfExpiryDate)) {
              _tmpExpiryDate = null;
            } else {
              _tmpExpiryDate = _cursor.getString(_cursorIndexOfExpiryDate);
            }
            final Double _tmpMinStock;
            if (_cursor.isNull(_cursorIndexOfMinStock)) {
              _tmpMinStock = null;
            } else {
              _tmpMinStock = _cursor.getDouble(_cursorIndexOfMinStock);
            }
            final boolean _tmpIsLowStock;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfIsLowStock);
            _tmpIsLowStock = _tmp != 0;
            final boolean _tmpIsExpiringSoon;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfIsExpiringSoon);
            _tmpIsExpiringSoon = _tmp_1 != 0;
            final String _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
            final String _tmpUpdatedAt;
            _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
            _item = new PantryItemEntity(_tmpId,_tmpName,_tmpAmount,_tmpUnit,_tmpCategory,_tmpExpiryDate,_tmpMinStock,_tmpIsLowStock,_tmpIsExpiringSoon,_tmpCreatedAt,_tmpUpdatedAt);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Flow<List<PantryItemEntity>> getAlerts() {
    final String _sql = "SELECT * FROM pantry_items WHERE isLowStock = 1 OR isExpiringSoon = 1";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"pantry_items"}, new Callable<List<PantryItemEntity>>() {
      @Override
      @NonNull
      public List<PantryItemEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfAmount = CursorUtil.getColumnIndexOrThrow(_cursor, "amount");
          final int _cursorIndexOfUnit = CursorUtil.getColumnIndexOrThrow(_cursor, "unit");
          final int _cursorIndexOfCategory = CursorUtil.getColumnIndexOrThrow(_cursor, "category");
          final int _cursorIndexOfExpiryDate = CursorUtil.getColumnIndexOrThrow(_cursor, "expiryDate");
          final int _cursorIndexOfMinStock = CursorUtil.getColumnIndexOrThrow(_cursor, "minStock");
          final int _cursorIndexOfIsLowStock = CursorUtil.getColumnIndexOrThrow(_cursor, "isLowStock");
          final int _cursorIndexOfIsExpiringSoon = CursorUtil.getColumnIndexOrThrow(_cursor, "isExpiringSoon");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final List<PantryItemEntity> _result = new ArrayList<PantryItemEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final PantryItemEntity _item;
            final int _tmpId;
            _tmpId = _cursor.getInt(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final Double _tmpAmount;
            if (_cursor.isNull(_cursorIndexOfAmount)) {
              _tmpAmount = null;
            } else {
              _tmpAmount = _cursor.getDouble(_cursorIndexOfAmount);
            }
            final String _tmpUnit;
            if (_cursor.isNull(_cursorIndexOfUnit)) {
              _tmpUnit = null;
            } else {
              _tmpUnit = _cursor.getString(_cursorIndexOfUnit);
            }
            final String _tmpCategory;
            _tmpCategory = _cursor.getString(_cursorIndexOfCategory);
            final String _tmpExpiryDate;
            if (_cursor.isNull(_cursorIndexOfExpiryDate)) {
              _tmpExpiryDate = null;
            } else {
              _tmpExpiryDate = _cursor.getString(_cursorIndexOfExpiryDate);
            }
            final Double _tmpMinStock;
            if (_cursor.isNull(_cursorIndexOfMinStock)) {
              _tmpMinStock = null;
            } else {
              _tmpMinStock = _cursor.getDouble(_cursorIndexOfMinStock);
            }
            final boolean _tmpIsLowStock;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfIsLowStock);
            _tmpIsLowStock = _tmp != 0;
            final boolean _tmpIsExpiringSoon;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfIsExpiringSoon);
            _tmpIsExpiringSoon = _tmp_1 != 0;
            final String _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
            final String _tmpUpdatedAt;
            _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
            _item = new PantryItemEntity(_tmpId,_tmpName,_tmpAmount,_tmpUnit,_tmpCategory,_tmpExpiryDate,_tmpMinStock,_tmpIsLowStock,_tmpIsExpiringSoon,_tmpCreatedAt,_tmpUpdatedAt);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
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
}
