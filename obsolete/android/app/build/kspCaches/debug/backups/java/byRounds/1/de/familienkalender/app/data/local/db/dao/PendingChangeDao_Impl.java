package de.familienkalender.app.data.local.db.dao;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import de.familienkalender.app.data.local.db.entity.PendingChangeEntity;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Integer;
import java.lang.Long;
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
public final class PendingChangeDao_Impl implements PendingChangeDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<PendingChangeEntity> __insertionAdapterOfPendingChangeEntity;

  private final SharedSQLiteStatement __preparedStmtOfDeleteById;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAll;

  public PendingChangeDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfPendingChangeEntity = new EntityInsertionAdapter<PendingChangeEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR ABORT INTO `pending_changes` (`id`,`entityType`,`entityId`,`action`,`endpoint`,`payload`,`createdAt`) VALUES (nullif(?, 0),?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final PendingChangeEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getEntityType());
        if (entity.getEntityId() == null) {
          statement.bindNull(3);
        } else {
          statement.bindLong(3, entity.getEntityId());
        }
        statement.bindString(4, entity.getAction());
        statement.bindString(5, entity.getEndpoint());
        if (entity.getPayload() == null) {
          statement.bindNull(6);
        } else {
          statement.bindString(6, entity.getPayload());
        }
        statement.bindLong(7, entity.getCreatedAt());
      }
    };
    this.__preparedStmtOfDeleteById = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM pending_changes WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAll = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM pending_changes";
        return _query;
      }
    };
  }

  @Override
  public Object insert(final PendingChangeEntity change,
      final Continuation<? super Long> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Long>() {
      @Override
      @NonNull
      public Long call() throws Exception {
        __db.beginTransaction();
        try {
          final Long _result = __insertionAdapterOfPendingChangeEntity.insertAndReturnId(change);
          __db.setTransactionSuccessful();
          return _result;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteById(final long id, final Continuation<? super Unit> $completion) {
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
  public Object getAll(final Continuation<? super List<PendingChangeEntity>> $completion) {
    final String _sql = "SELECT * FROM pending_changes ORDER BY createdAt ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<List<PendingChangeEntity>>() {
      @Override
      @NonNull
      public List<PendingChangeEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfEntityType = CursorUtil.getColumnIndexOrThrow(_cursor, "entityType");
          final int _cursorIndexOfEntityId = CursorUtil.getColumnIndexOrThrow(_cursor, "entityId");
          final int _cursorIndexOfAction = CursorUtil.getColumnIndexOrThrow(_cursor, "action");
          final int _cursorIndexOfEndpoint = CursorUtil.getColumnIndexOrThrow(_cursor, "endpoint");
          final int _cursorIndexOfPayload = CursorUtil.getColumnIndexOrThrow(_cursor, "payload");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final List<PendingChangeEntity> _result = new ArrayList<PendingChangeEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final PendingChangeEntity _item;
            final long _tmpId;
            _tmpId = _cursor.getLong(_cursorIndexOfId);
            final String _tmpEntityType;
            _tmpEntityType = _cursor.getString(_cursorIndexOfEntityType);
            final Integer _tmpEntityId;
            if (_cursor.isNull(_cursorIndexOfEntityId)) {
              _tmpEntityId = null;
            } else {
              _tmpEntityId = _cursor.getInt(_cursorIndexOfEntityId);
            }
            final String _tmpAction;
            _tmpAction = _cursor.getString(_cursorIndexOfAction);
            final String _tmpEndpoint;
            _tmpEndpoint = _cursor.getString(_cursorIndexOfEndpoint);
            final String _tmpPayload;
            if (_cursor.isNull(_cursorIndexOfPayload)) {
              _tmpPayload = null;
            } else {
              _tmpPayload = _cursor.getString(_cursorIndexOfPayload);
            }
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            _item = new PendingChangeEntity(_tmpId,_tmpEntityType,_tmpEntityId,_tmpAction,_tmpEndpoint,_tmpPayload,_tmpCreatedAt);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @Override
  public Flow<Integer> getCount() {
    final String _sql = "SELECT COUNT(*) FROM pending_changes";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"pending_changes"}, new Callable<Integer>() {
      @Override
      @NonNull
      public Integer call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final Integer _result;
          if (_cursor.moveToFirst()) {
            final int _tmp;
            _tmp = _cursor.getInt(0);
            _result = _tmp;
          } else {
            _result = 0;
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
