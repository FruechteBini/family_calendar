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
import de.familienkalender.app.data.local.db.entity.EventEntity;
import de.familienkalender.app.data.local.db.entity.EventMemberCrossRef;
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity;
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
public final class EventDao_Impl implements EventDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<EventEntity> __insertionAdapterOfEventEntity;

  private final EntityInsertionAdapter<EventMemberCrossRef> __insertionAdapterOfEventMemberCrossRef;

  private final SharedSQLiteStatement __preparedStmtOfDeleteMemberRefs;

  private final SharedSQLiteStatement __preparedStmtOfDeleteById;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAll;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAllMemberRefs;

  public EventDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfEventEntity = new EntityInsertionAdapter<EventEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `events` (`id`,`title`,`description`,`start`,`end`,`allDay`,`categoryId`,`categoryName`,`categoryColor`,`categoryIcon`,`createdAt`,`updatedAt`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final EventEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getTitle());
        if (entity.getDescription() == null) {
          statement.bindNull(3);
        } else {
          statement.bindString(3, entity.getDescription());
        }
        statement.bindString(4, entity.getStart());
        statement.bindString(5, entity.getEnd());
        final int _tmp = entity.getAllDay() ? 1 : 0;
        statement.bindLong(6, _tmp);
        if (entity.getCategoryId() == null) {
          statement.bindNull(7);
        } else {
          statement.bindLong(7, entity.getCategoryId());
        }
        if (entity.getCategoryName() == null) {
          statement.bindNull(8);
        } else {
          statement.bindString(8, entity.getCategoryName());
        }
        if (entity.getCategoryColor() == null) {
          statement.bindNull(9);
        } else {
          statement.bindString(9, entity.getCategoryColor());
        }
        if (entity.getCategoryIcon() == null) {
          statement.bindNull(10);
        } else {
          statement.bindString(10, entity.getCategoryIcon());
        }
        statement.bindString(11, entity.getCreatedAt());
        statement.bindString(12, entity.getUpdatedAt());
      }
    };
    this.__insertionAdapterOfEventMemberCrossRef = new EntityInsertionAdapter<EventMemberCrossRef>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `event_members` (`eventId`,`memberId`) VALUES (?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final EventMemberCrossRef entity) {
        statement.bindLong(1, entity.getEventId());
        statement.bindLong(2, entity.getMemberId());
      }
    };
    this.__preparedStmtOfDeleteMemberRefs = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM event_members WHERE eventId = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteById = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM events WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAll = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM events";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAllMemberRefs = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM event_members";
        return _query;
      }
    };
  }

  @Override
  public Object upsert(final EventEntity event, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfEventEntity.insert(event);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertAll(final List<EventEntity> events,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfEventEntity.insert(events);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object insertMemberRefs(final List<EventMemberCrossRef> refs,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfEventMemberCrossRef.insert(refs);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteMemberRefs(final int eventId, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteMemberRefs.acquire();
        int _argIndex = 1;
        _stmt.bindLong(_argIndex, eventId);
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
          __preparedStmtOfDeleteMemberRefs.release(_stmt);
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
  public Object deleteAllMemberRefs(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAllMemberRefs.acquire();
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
          __preparedStmtOfDeleteAllMemberRefs.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<EventWithMembers>> getEventsBetween(final String from, final String to) {
    final String _sql = "SELECT * FROM events WHERE start >= ? AND start <= ? ORDER BY start";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 2);
    int _argIndex = 1;
    _statement.bindString(_argIndex, from);
    _argIndex = 2;
    _statement.bindString(_argIndex, to);
    return CoroutinesRoom.createFlow(__db, true, new String[] {"event_members", "family_members",
        "events"}, new Callable<List<EventWithMembers>>() {
      @Override
      @NonNull
      public List<EventWithMembers> call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
            final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
            final int _cursorIndexOfStart = CursorUtil.getColumnIndexOrThrow(_cursor, "start");
            final int _cursorIndexOfEnd = CursorUtil.getColumnIndexOrThrow(_cursor, "end");
            final int _cursorIndexOfAllDay = CursorUtil.getColumnIndexOrThrow(_cursor, "allDay");
            final int _cursorIndexOfCategoryId = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryId");
            final int _cursorIndexOfCategoryName = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryName");
            final int _cursorIndexOfCategoryColor = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryColor");
            final int _cursorIndexOfCategoryIcon = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryIcon");
            final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
            final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
            final LongSparseArray<ArrayList<FamilyMemberEntity>> _collectionMembers = new LongSparseArray<ArrayList<FamilyMemberEntity>>();
            while (_cursor.moveToNext()) {
              final long _tmpKey;
              _tmpKey = _cursor.getLong(_cursorIndexOfId);
              if (!_collectionMembers.containsKey(_tmpKey)) {
                _collectionMembers.put(_tmpKey, new ArrayList<FamilyMemberEntity>());
              }
            }
            _cursor.moveToPosition(-1);
            __fetchRelationshipfamilyMembersAsdeFamilienkalenderAppDataLocalDbEntityFamilyMemberEntity(_collectionMembers);
            final List<EventWithMembers> _result = new ArrayList<EventWithMembers>(_cursor.getCount());
            while (_cursor.moveToNext()) {
              final EventWithMembers _item;
              final EventEntity _tmpEvent;
              final int _tmpId;
              _tmpId = _cursor.getInt(_cursorIndexOfId);
              final String _tmpTitle;
              _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
              final String _tmpDescription;
              if (_cursor.isNull(_cursorIndexOfDescription)) {
                _tmpDescription = null;
              } else {
                _tmpDescription = _cursor.getString(_cursorIndexOfDescription);
              }
              final String _tmpStart;
              _tmpStart = _cursor.getString(_cursorIndexOfStart);
              final String _tmpEnd;
              _tmpEnd = _cursor.getString(_cursorIndexOfEnd);
              final boolean _tmpAllDay;
              final int _tmp;
              _tmp = _cursor.getInt(_cursorIndexOfAllDay);
              _tmpAllDay = _tmp != 0;
              final Integer _tmpCategoryId;
              if (_cursor.isNull(_cursorIndexOfCategoryId)) {
                _tmpCategoryId = null;
              } else {
                _tmpCategoryId = _cursor.getInt(_cursorIndexOfCategoryId);
              }
              final String _tmpCategoryName;
              if (_cursor.isNull(_cursorIndexOfCategoryName)) {
                _tmpCategoryName = null;
              } else {
                _tmpCategoryName = _cursor.getString(_cursorIndexOfCategoryName);
              }
              final String _tmpCategoryColor;
              if (_cursor.isNull(_cursorIndexOfCategoryColor)) {
                _tmpCategoryColor = null;
              } else {
                _tmpCategoryColor = _cursor.getString(_cursorIndexOfCategoryColor);
              }
              final String _tmpCategoryIcon;
              if (_cursor.isNull(_cursorIndexOfCategoryIcon)) {
                _tmpCategoryIcon = null;
              } else {
                _tmpCategoryIcon = _cursor.getString(_cursorIndexOfCategoryIcon);
              }
              final String _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
              final String _tmpUpdatedAt;
              _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
              _tmpEvent = new EventEntity(_tmpId,_tmpTitle,_tmpDescription,_tmpStart,_tmpEnd,_tmpAllDay,_tmpCategoryId,_tmpCategoryName,_tmpCategoryColor,_tmpCategoryIcon,_tmpCreatedAt,_tmpUpdatedAt);
              final ArrayList<FamilyMemberEntity> _tmpMembersCollection;
              final long _tmpKey_1;
              _tmpKey_1 = _cursor.getLong(_cursorIndexOfId);
              _tmpMembersCollection = _collectionMembers.get(_tmpKey_1);
              _item = new EventWithMembers(_tmpEvent,_tmpMembersCollection);
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
  public Flow<List<EventWithMembers>> getAll() {
    final String _sql = "SELECT * FROM events ORDER BY start";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, true, new String[] {"event_members", "family_members",
        "events"}, new Callable<List<EventWithMembers>>() {
      @Override
      @NonNull
      public List<EventWithMembers> call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
            final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
            final int _cursorIndexOfStart = CursorUtil.getColumnIndexOrThrow(_cursor, "start");
            final int _cursorIndexOfEnd = CursorUtil.getColumnIndexOrThrow(_cursor, "end");
            final int _cursorIndexOfAllDay = CursorUtil.getColumnIndexOrThrow(_cursor, "allDay");
            final int _cursorIndexOfCategoryId = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryId");
            final int _cursorIndexOfCategoryName = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryName");
            final int _cursorIndexOfCategoryColor = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryColor");
            final int _cursorIndexOfCategoryIcon = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryIcon");
            final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
            final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
            final LongSparseArray<ArrayList<FamilyMemberEntity>> _collectionMembers = new LongSparseArray<ArrayList<FamilyMemberEntity>>();
            while (_cursor.moveToNext()) {
              final long _tmpKey;
              _tmpKey = _cursor.getLong(_cursorIndexOfId);
              if (!_collectionMembers.containsKey(_tmpKey)) {
                _collectionMembers.put(_tmpKey, new ArrayList<FamilyMemberEntity>());
              }
            }
            _cursor.moveToPosition(-1);
            __fetchRelationshipfamilyMembersAsdeFamilienkalenderAppDataLocalDbEntityFamilyMemberEntity(_collectionMembers);
            final List<EventWithMembers> _result = new ArrayList<EventWithMembers>(_cursor.getCount());
            while (_cursor.moveToNext()) {
              final EventWithMembers _item;
              final EventEntity _tmpEvent;
              final int _tmpId;
              _tmpId = _cursor.getInt(_cursorIndexOfId);
              final String _tmpTitle;
              _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
              final String _tmpDescription;
              if (_cursor.isNull(_cursorIndexOfDescription)) {
                _tmpDescription = null;
              } else {
                _tmpDescription = _cursor.getString(_cursorIndexOfDescription);
              }
              final String _tmpStart;
              _tmpStart = _cursor.getString(_cursorIndexOfStart);
              final String _tmpEnd;
              _tmpEnd = _cursor.getString(_cursorIndexOfEnd);
              final boolean _tmpAllDay;
              final int _tmp;
              _tmp = _cursor.getInt(_cursorIndexOfAllDay);
              _tmpAllDay = _tmp != 0;
              final Integer _tmpCategoryId;
              if (_cursor.isNull(_cursorIndexOfCategoryId)) {
                _tmpCategoryId = null;
              } else {
                _tmpCategoryId = _cursor.getInt(_cursorIndexOfCategoryId);
              }
              final String _tmpCategoryName;
              if (_cursor.isNull(_cursorIndexOfCategoryName)) {
                _tmpCategoryName = null;
              } else {
                _tmpCategoryName = _cursor.getString(_cursorIndexOfCategoryName);
              }
              final String _tmpCategoryColor;
              if (_cursor.isNull(_cursorIndexOfCategoryColor)) {
                _tmpCategoryColor = null;
              } else {
                _tmpCategoryColor = _cursor.getString(_cursorIndexOfCategoryColor);
              }
              final String _tmpCategoryIcon;
              if (_cursor.isNull(_cursorIndexOfCategoryIcon)) {
                _tmpCategoryIcon = null;
              } else {
                _tmpCategoryIcon = _cursor.getString(_cursorIndexOfCategoryIcon);
              }
              final String _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
              final String _tmpUpdatedAt;
              _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
              _tmpEvent = new EventEntity(_tmpId,_tmpTitle,_tmpDescription,_tmpStart,_tmpEnd,_tmpAllDay,_tmpCategoryId,_tmpCategoryName,_tmpCategoryColor,_tmpCategoryIcon,_tmpCreatedAt,_tmpUpdatedAt);
              final ArrayList<FamilyMemberEntity> _tmpMembersCollection;
              final long _tmpKey_1;
              _tmpKey_1 = _cursor.getLong(_cursorIndexOfId);
              _tmpMembersCollection = _collectionMembers.get(_tmpKey_1);
              _item = new EventWithMembers(_tmpEvent,_tmpMembersCollection);
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
  public Object getById(final int id, final Continuation<? super EventWithMembers> $completion) {
    final String _sql = "SELECT * FROM events WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, true, _cancellationSignal, new Callable<EventWithMembers>() {
      @Override
      @Nullable
      public EventWithMembers call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
            final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
            final int _cursorIndexOfStart = CursorUtil.getColumnIndexOrThrow(_cursor, "start");
            final int _cursorIndexOfEnd = CursorUtil.getColumnIndexOrThrow(_cursor, "end");
            final int _cursorIndexOfAllDay = CursorUtil.getColumnIndexOrThrow(_cursor, "allDay");
            final int _cursorIndexOfCategoryId = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryId");
            final int _cursorIndexOfCategoryName = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryName");
            final int _cursorIndexOfCategoryColor = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryColor");
            final int _cursorIndexOfCategoryIcon = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryIcon");
            final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
            final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
            final LongSparseArray<ArrayList<FamilyMemberEntity>> _collectionMembers = new LongSparseArray<ArrayList<FamilyMemberEntity>>();
            while (_cursor.moveToNext()) {
              final long _tmpKey;
              _tmpKey = _cursor.getLong(_cursorIndexOfId);
              if (!_collectionMembers.containsKey(_tmpKey)) {
                _collectionMembers.put(_tmpKey, new ArrayList<FamilyMemberEntity>());
              }
            }
            _cursor.moveToPosition(-1);
            __fetchRelationshipfamilyMembersAsdeFamilienkalenderAppDataLocalDbEntityFamilyMemberEntity(_collectionMembers);
            final EventWithMembers _result;
            if (_cursor.moveToFirst()) {
              final EventEntity _tmpEvent;
              final int _tmpId;
              _tmpId = _cursor.getInt(_cursorIndexOfId);
              final String _tmpTitle;
              _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
              final String _tmpDescription;
              if (_cursor.isNull(_cursorIndexOfDescription)) {
                _tmpDescription = null;
              } else {
                _tmpDescription = _cursor.getString(_cursorIndexOfDescription);
              }
              final String _tmpStart;
              _tmpStart = _cursor.getString(_cursorIndexOfStart);
              final String _tmpEnd;
              _tmpEnd = _cursor.getString(_cursorIndexOfEnd);
              final boolean _tmpAllDay;
              final int _tmp;
              _tmp = _cursor.getInt(_cursorIndexOfAllDay);
              _tmpAllDay = _tmp != 0;
              final Integer _tmpCategoryId;
              if (_cursor.isNull(_cursorIndexOfCategoryId)) {
                _tmpCategoryId = null;
              } else {
                _tmpCategoryId = _cursor.getInt(_cursorIndexOfCategoryId);
              }
              final String _tmpCategoryName;
              if (_cursor.isNull(_cursorIndexOfCategoryName)) {
                _tmpCategoryName = null;
              } else {
                _tmpCategoryName = _cursor.getString(_cursorIndexOfCategoryName);
              }
              final String _tmpCategoryColor;
              if (_cursor.isNull(_cursorIndexOfCategoryColor)) {
                _tmpCategoryColor = null;
              } else {
                _tmpCategoryColor = _cursor.getString(_cursorIndexOfCategoryColor);
              }
              final String _tmpCategoryIcon;
              if (_cursor.isNull(_cursorIndexOfCategoryIcon)) {
                _tmpCategoryIcon = null;
              } else {
                _tmpCategoryIcon = _cursor.getString(_cursorIndexOfCategoryIcon);
              }
              final String _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
              final String _tmpUpdatedAt;
              _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
              _tmpEvent = new EventEntity(_tmpId,_tmpTitle,_tmpDescription,_tmpStart,_tmpEnd,_tmpAllDay,_tmpCategoryId,_tmpCategoryName,_tmpCategoryColor,_tmpCategoryIcon,_tmpCreatedAt,_tmpUpdatedAt);
              final ArrayList<FamilyMemberEntity> _tmpMembersCollection;
              final long _tmpKey_1;
              _tmpKey_1 = _cursor.getLong(_cursorIndexOfId);
              _tmpMembersCollection = _collectionMembers.get(_tmpKey_1);
              _result = new EventWithMembers(_tmpEvent,_tmpMembersCollection);
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

  private void __fetchRelationshipfamilyMembersAsdeFamilienkalenderAppDataLocalDbEntityFamilyMemberEntity(
      @NonNull final LongSparseArray<ArrayList<FamilyMemberEntity>> _map) {
    if (_map.isEmpty()) {
      return;
    }
    if (_map.size() > RoomDatabase.MAX_BIND_PARAMETER_CNT) {
      RelationUtil.recursiveFetchLongSparseArray(_map, true, (map) -> {
        __fetchRelationshipfamilyMembersAsdeFamilienkalenderAppDataLocalDbEntityFamilyMemberEntity(map);
        return Unit.INSTANCE;
      });
      return;
    }
    final StringBuilder _stringBuilder = StringUtil.newStringBuilder();
    _stringBuilder.append("SELECT `family_members`.`id` AS `id`,`family_members`.`name` AS `name`,`family_members`.`color` AS `color`,`family_members`.`avatarEmoji` AS `avatarEmoji`,`family_members`.`createdAt` AS `createdAt`,_junction.`eventId` FROM `event_members` AS _junction INNER JOIN `family_members` ON (_junction.`memberId` = `family_members`.`id`) WHERE _junction.`eventId` IN (");
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
      // _junction.eventId;
      final int _itemKeyIndex = 5;
      if (_itemKeyIndex == -1) {
        return;
      }
      final int _cursorIndexOfId = 0;
      final int _cursorIndexOfName = 1;
      final int _cursorIndexOfColor = 2;
      final int _cursorIndexOfAvatarEmoji = 3;
      final int _cursorIndexOfCreatedAt = 4;
      while (_cursor.moveToNext()) {
        final long _tmpKey;
        _tmpKey = _cursor.getLong(_itemKeyIndex);
        final ArrayList<FamilyMemberEntity> _tmpRelation = _map.get(_tmpKey);
        if (_tmpRelation != null) {
          final FamilyMemberEntity _item_1;
          final int _tmpId;
          _tmpId = _cursor.getInt(_cursorIndexOfId);
          final String _tmpName;
          _tmpName = _cursor.getString(_cursorIndexOfName);
          final String _tmpColor;
          _tmpColor = _cursor.getString(_cursorIndexOfColor);
          final String _tmpAvatarEmoji;
          _tmpAvatarEmoji = _cursor.getString(_cursorIndexOfAvatarEmoji);
          final String _tmpCreatedAt;
          _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
          _item_1 = new FamilyMemberEntity(_tmpId,_tmpName,_tmpColor,_tmpAvatarEmoji,_tmpCreatedAt);
          _tmpRelation.add(_item_1);
        }
      }
    } finally {
      _cursor.close();
    }
  }
}
