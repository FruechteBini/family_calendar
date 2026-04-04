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
import de.familienkalender.app.data.local.db.entity.CookingHistoryEntity;
import de.familienkalender.app.data.local.db.entity.MealPlanEntity;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Integer;
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
public final class MealPlanDao_Impl implements MealPlanDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<MealPlanEntity> __insertionAdapterOfMealPlanEntity;

  private final EntityInsertionAdapter<CookingHistoryEntity> __insertionAdapterOfCookingHistoryEntity;

  private final SharedSQLiteStatement __preparedStmtOfDeleteSlot;

  private final SharedSQLiteStatement __preparedStmtOfDeleteForWeek;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAll;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAllHistory;

  public MealPlanDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfMealPlanEntity = new EntityInsertionAdapter<MealPlanEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `meal_plan` (`id`,`planDate`,`slot`,`recipeId`,`servingsPlanned`,`createdAt`,`updatedAt`) VALUES (?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final MealPlanEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getPlanDate());
        statement.bindString(3, entity.getSlot());
        statement.bindLong(4, entity.getRecipeId());
        statement.bindLong(5, entity.getServingsPlanned());
        statement.bindString(6, entity.getCreatedAt());
        statement.bindString(7, entity.getUpdatedAt());
      }
    };
    this.__insertionAdapterOfCookingHistoryEntity = new EntityInsertionAdapter<CookingHistoryEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `cooking_history` (`id`,`recipeId`,`cookedAt`,`servingsCooked`,`rating`,`notes`,`createdAt`) VALUES (?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final CookingHistoryEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindLong(2, entity.getRecipeId());
        statement.bindString(3, entity.getCookedAt());
        statement.bindLong(4, entity.getServingsCooked());
        if (entity.getRating() == null) {
          statement.bindNull(5);
        } else {
          statement.bindLong(5, entity.getRating());
        }
        if (entity.getNotes() == null) {
          statement.bindNull(6);
        } else {
          statement.bindString(6, entity.getNotes());
        }
        statement.bindString(7, entity.getCreatedAt());
      }
    };
    this.__preparedStmtOfDeleteSlot = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM meal_plan WHERE planDate = ? AND slot = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteForWeek = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM meal_plan WHERE planDate >= ? AND planDate <= ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAll = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM meal_plan";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAllHistory = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM cooking_history";
        return _query;
      }
    };
  }

  @Override
  public Object upsert(final MealPlanEntity mealPlan,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfMealPlanEntity.insert(mealPlan);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertAll(final List<MealPlanEntity> plans,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfMealPlanEntity.insert(plans);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertHistory(final List<CookingHistoryEntity> history,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfCookingHistoryEntity.insert(history);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteSlot(final String date, final String slot,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteSlot.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, date);
        _argIndex = 2;
        _stmt.bindString(_argIndex, slot);
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
          __preparedStmtOfDeleteSlot.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteForWeek(final String from, final String to,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteForWeek.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, from);
        _argIndex = 2;
        _stmt.bindString(_argIndex, to);
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
          __preparedStmtOfDeleteForWeek.release(_stmt);
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
  public Object deleteAllHistory(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAllHistory.acquire();
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
          __preparedStmtOfDeleteAllHistory.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<MealPlanEntity>> getForWeek(final String from, final String to) {
    final String _sql = "SELECT * FROM meal_plan WHERE planDate >= ? AND planDate <= ? ORDER BY planDate, slot";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 2);
    int _argIndex = 1;
    _statement.bindString(_argIndex, from);
    _argIndex = 2;
    _statement.bindString(_argIndex, to);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"meal_plan"}, new Callable<List<MealPlanEntity>>() {
      @Override
      @NonNull
      public List<MealPlanEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfPlanDate = CursorUtil.getColumnIndexOrThrow(_cursor, "planDate");
          final int _cursorIndexOfSlot = CursorUtil.getColumnIndexOrThrow(_cursor, "slot");
          final int _cursorIndexOfRecipeId = CursorUtil.getColumnIndexOrThrow(_cursor, "recipeId");
          final int _cursorIndexOfServingsPlanned = CursorUtil.getColumnIndexOrThrow(_cursor, "servingsPlanned");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final List<MealPlanEntity> _result = new ArrayList<MealPlanEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final MealPlanEntity _item;
            final int _tmpId;
            _tmpId = _cursor.getInt(_cursorIndexOfId);
            final String _tmpPlanDate;
            _tmpPlanDate = _cursor.getString(_cursorIndexOfPlanDate);
            final String _tmpSlot;
            _tmpSlot = _cursor.getString(_cursorIndexOfSlot);
            final int _tmpRecipeId;
            _tmpRecipeId = _cursor.getInt(_cursorIndexOfRecipeId);
            final int _tmpServingsPlanned;
            _tmpServingsPlanned = _cursor.getInt(_cursorIndexOfServingsPlanned);
            final String _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
            final String _tmpUpdatedAt;
            _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
            _item = new MealPlanEntity(_tmpId,_tmpPlanDate,_tmpSlot,_tmpRecipeId,_tmpServingsPlanned,_tmpCreatedAt,_tmpUpdatedAt);
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
  public Flow<List<CookingHistoryEntity>> getHistoryForRecipe(final int recipeId) {
    final String _sql = "SELECT * FROM cooking_history WHERE recipeId = ? ORDER BY cookedAt DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, recipeId);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"cooking_history"}, new Callable<List<CookingHistoryEntity>>() {
      @Override
      @NonNull
      public List<CookingHistoryEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfRecipeId = CursorUtil.getColumnIndexOrThrow(_cursor, "recipeId");
          final int _cursorIndexOfCookedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "cookedAt");
          final int _cursorIndexOfServingsCooked = CursorUtil.getColumnIndexOrThrow(_cursor, "servingsCooked");
          final int _cursorIndexOfRating = CursorUtil.getColumnIndexOrThrow(_cursor, "rating");
          final int _cursorIndexOfNotes = CursorUtil.getColumnIndexOrThrow(_cursor, "notes");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final List<CookingHistoryEntity> _result = new ArrayList<CookingHistoryEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final CookingHistoryEntity _item;
            final int _tmpId;
            _tmpId = _cursor.getInt(_cursorIndexOfId);
            final int _tmpRecipeId;
            _tmpRecipeId = _cursor.getInt(_cursorIndexOfRecipeId);
            final String _tmpCookedAt;
            _tmpCookedAt = _cursor.getString(_cursorIndexOfCookedAt);
            final int _tmpServingsCooked;
            _tmpServingsCooked = _cursor.getInt(_cursorIndexOfServingsCooked);
            final Integer _tmpRating;
            if (_cursor.isNull(_cursorIndexOfRating)) {
              _tmpRating = null;
            } else {
              _tmpRating = _cursor.getInt(_cursorIndexOfRating);
            }
            final String _tmpNotes;
            if (_cursor.isNull(_cursorIndexOfNotes)) {
              _tmpNotes = null;
            } else {
              _tmpNotes = _cursor.getString(_cursorIndexOfNotes);
            }
            final String _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
            _item = new CookingHistoryEntity(_tmpId,_tmpRecipeId,_tmpCookedAt,_tmpServingsCooked,_tmpRating,_tmpNotes,_tmpCreatedAt);
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
