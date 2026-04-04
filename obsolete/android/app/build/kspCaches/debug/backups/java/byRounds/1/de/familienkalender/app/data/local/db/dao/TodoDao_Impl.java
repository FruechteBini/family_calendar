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
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity;
import de.familienkalender.app.data.local.db.entity.SubtodoEntity;
import de.familienkalender.app.data.local.db.entity.TodoEntity;
import de.familienkalender.app.data.local.db.entity.TodoMemberCrossRef;
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
public final class TodoDao_Impl implements TodoDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<TodoEntity> __insertionAdapterOfTodoEntity;

  private final EntityInsertionAdapter<SubtodoEntity> __insertionAdapterOfSubtodoEntity;

  private final EntityInsertionAdapter<TodoMemberCrossRef> __insertionAdapterOfTodoMemberCrossRef;

  private final SharedSQLiteStatement __preparedStmtOfDeleteMemberRefs;

  private final SharedSQLiteStatement __preparedStmtOfDeleteSubtodos;

  private final SharedSQLiteStatement __preparedStmtOfDeleteById;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAll;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAllMemberRefs;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAllSubtodos;

  public TodoDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfTodoEntity = new EntityInsertionAdapter<TodoEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `todos` (`id`,`title`,`description`,`priority`,`dueDate`,`completed`,`completedAt`,`categoryId`,`categoryName`,`categoryColor`,`categoryIcon`,`eventId`,`parentId`,`requiresMultiple`,`createdAt`,`updatedAt`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final TodoEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getTitle());
        if (entity.getDescription() == null) {
          statement.bindNull(3);
        } else {
          statement.bindString(3, entity.getDescription());
        }
        statement.bindString(4, entity.getPriority());
        if (entity.getDueDate() == null) {
          statement.bindNull(5);
        } else {
          statement.bindString(5, entity.getDueDate());
        }
        final int _tmp = entity.getCompleted() ? 1 : 0;
        statement.bindLong(6, _tmp);
        if (entity.getCompletedAt() == null) {
          statement.bindNull(7);
        } else {
          statement.bindString(7, entity.getCompletedAt());
        }
        if (entity.getCategoryId() == null) {
          statement.bindNull(8);
        } else {
          statement.bindLong(8, entity.getCategoryId());
        }
        if (entity.getCategoryName() == null) {
          statement.bindNull(9);
        } else {
          statement.bindString(9, entity.getCategoryName());
        }
        if (entity.getCategoryColor() == null) {
          statement.bindNull(10);
        } else {
          statement.bindString(10, entity.getCategoryColor());
        }
        if (entity.getCategoryIcon() == null) {
          statement.bindNull(11);
        } else {
          statement.bindString(11, entity.getCategoryIcon());
        }
        if (entity.getEventId() == null) {
          statement.bindNull(12);
        } else {
          statement.bindLong(12, entity.getEventId());
        }
        if (entity.getParentId() == null) {
          statement.bindNull(13);
        } else {
          statement.bindLong(13, entity.getParentId());
        }
        final int _tmp_1 = entity.getRequiresMultiple() ? 1 : 0;
        statement.bindLong(14, _tmp_1);
        statement.bindString(15, entity.getCreatedAt());
        statement.bindString(16, entity.getUpdatedAt());
      }
    };
    this.__insertionAdapterOfSubtodoEntity = new EntityInsertionAdapter<SubtodoEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `subtodos` (`id`,`parentId`,`title`,`completed`,`completedAt`,`createdAt`) VALUES (?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final SubtodoEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindLong(2, entity.getParentId());
        statement.bindString(3, entity.getTitle());
        final int _tmp = entity.getCompleted() ? 1 : 0;
        statement.bindLong(4, _tmp);
        if (entity.getCompletedAt() == null) {
          statement.bindNull(5);
        } else {
          statement.bindString(5, entity.getCompletedAt());
        }
        statement.bindString(6, entity.getCreatedAt());
      }
    };
    this.__insertionAdapterOfTodoMemberCrossRef = new EntityInsertionAdapter<TodoMemberCrossRef>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `todo_members` (`todoId`,`memberId`) VALUES (?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final TodoMemberCrossRef entity) {
        statement.bindLong(1, entity.getTodoId());
        statement.bindLong(2, entity.getMemberId());
      }
    };
    this.__preparedStmtOfDeleteMemberRefs = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM todo_members WHERE todoId = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteSubtodos = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM subtodos WHERE parentId = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteById = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM todos WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAll = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM todos";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAllMemberRefs = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM todo_members";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAllSubtodos = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM subtodos";
        return _query;
      }
    };
  }

  @Override
  public Object upsert(final TodoEntity todo, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfTodoEntity.insert(todo);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertAll(final List<TodoEntity> todos,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfTodoEntity.insert(todos);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertSubtodos(final List<SubtodoEntity> subtodos,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfSubtodoEntity.insert(subtodos);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object insertMemberRefs(final List<TodoMemberCrossRef> refs,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfTodoMemberCrossRef.insert(refs);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteMemberRefs(final int todoId, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteMemberRefs.acquire();
        int _argIndex = 1;
        _stmt.bindLong(_argIndex, todoId);
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
  public Object deleteSubtodos(final int parentId, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteSubtodos.acquire();
        int _argIndex = 1;
        _stmt.bindLong(_argIndex, parentId);
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
          __preparedStmtOfDeleteSubtodos.release(_stmt);
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
  public Object deleteAllSubtodos(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAllSubtodos.acquire();
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
          __preparedStmtOfDeleteAllSubtodos.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<TodoWithDetails>> getAll() {
    final String _sql = "SELECT * FROM todos WHERE parentId IS NULL ORDER BY dueDate, createdAt";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, true, new String[] {"todo_members", "family_members",
        "todos"}, new Callable<List<TodoWithDetails>>() {
      @Override
      @NonNull
      public List<TodoWithDetails> call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
            final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
            final int _cursorIndexOfPriority = CursorUtil.getColumnIndexOrThrow(_cursor, "priority");
            final int _cursorIndexOfDueDate = CursorUtil.getColumnIndexOrThrow(_cursor, "dueDate");
            final int _cursorIndexOfCompleted = CursorUtil.getColumnIndexOrThrow(_cursor, "completed");
            final int _cursorIndexOfCompletedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "completedAt");
            final int _cursorIndexOfCategoryId = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryId");
            final int _cursorIndexOfCategoryName = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryName");
            final int _cursorIndexOfCategoryColor = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryColor");
            final int _cursorIndexOfCategoryIcon = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryIcon");
            final int _cursorIndexOfEventId = CursorUtil.getColumnIndexOrThrow(_cursor, "eventId");
            final int _cursorIndexOfParentId = CursorUtil.getColumnIndexOrThrow(_cursor, "parentId");
            final int _cursorIndexOfRequiresMultiple = CursorUtil.getColumnIndexOrThrow(_cursor, "requiresMultiple");
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
            final List<TodoWithDetails> _result = new ArrayList<TodoWithDetails>(_cursor.getCount());
            while (_cursor.moveToNext()) {
              final TodoWithDetails _item;
              final TodoEntity _tmpTodo;
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
              final String _tmpPriority;
              _tmpPriority = _cursor.getString(_cursorIndexOfPriority);
              final String _tmpDueDate;
              if (_cursor.isNull(_cursorIndexOfDueDate)) {
                _tmpDueDate = null;
              } else {
                _tmpDueDate = _cursor.getString(_cursorIndexOfDueDate);
              }
              final boolean _tmpCompleted;
              final int _tmp;
              _tmp = _cursor.getInt(_cursorIndexOfCompleted);
              _tmpCompleted = _tmp != 0;
              final String _tmpCompletedAt;
              if (_cursor.isNull(_cursorIndexOfCompletedAt)) {
                _tmpCompletedAt = null;
              } else {
                _tmpCompletedAt = _cursor.getString(_cursorIndexOfCompletedAt);
              }
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
              final Integer _tmpEventId;
              if (_cursor.isNull(_cursorIndexOfEventId)) {
                _tmpEventId = null;
              } else {
                _tmpEventId = _cursor.getInt(_cursorIndexOfEventId);
              }
              final Integer _tmpParentId;
              if (_cursor.isNull(_cursorIndexOfParentId)) {
                _tmpParentId = null;
              } else {
                _tmpParentId = _cursor.getInt(_cursorIndexOfParentId);
              }
              final boolean _tmpRequiresMultiple;
              final int _tmp_1;
              _tmp_1 = _cursor.getInt(_cursorIndexOfRequiresMultiple);
              _tmpRequiresMultiple = _tmp_1 != 0;
              final String _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
              final String _tmpUpdatedAt;
              _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
              _tmpTodo = new TodoEntity(_tmpId,_tmpTitle,_tmpDescription,_tmpPriority,_tmpDueDate,_tmpCompleted,_tmpCompletedAt,_tmpCategoryId,_tmpCategoryName,_tmpCategoryColor,_tmpCategoryIcon,_tmpEventId,_tmpParentId,_tmpRequiresMultiple,_tmpCreatedAt,_tmpUpdatedAt);
              final ArrayList<FamilyMemberEntity> _tmpMembersCollection;
              final long _tmpKey_1;
              _tmpKey_1 = _cursor.getLong(_cursorIndexOfId);
              _tmpMembersCollection = _collectionMembers.get(_tmpKey_1);
              _item = new TodoWithDetails(_tmpTodo,_tmpMembersCollection);
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
  public Object getById(final int id, final Continuation<? super TodoWithDetails> $completion) {
    final String _sql = "SELECT * FROM todos WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, true, _cancellationSignal, new Callable<TodoWithDetails>() {
      @Override
      @Nullable
      public TodoWithDetails call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
            final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
            final int _cursorIndexOfPriority = CursorUtil.getColumnIndexOrThrow(_cursor, "priority");
            final int _cursorIndexOfDueDate = CursorUtil.getColumnIndexOrThrow(_cursor, "dueDate");
            final int _cursorIndexOfCompleted = CursorUtil.getColumnIndexOrThrow(_cursor, "completed");
            final int _cursorIndexOfCompletedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "completedAt");
            final int _cursorIndexOfCategoryId = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryId");
            final int _cursorIndexOfCategoryName = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryName");
            final int _cursorIndexOfCategoryColor = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryColor");
            final int _cursorIndexOfCategoryIcon = CursorUtil.getColumnIndexOrThrow(_cursor, "categoryIcon");
            final int _cursorIndexOfEventId = CursorUtil.getColumnIndexOrThrow(_cursor, "eventId");
            final int _cursorIndexOfParentId = CursorUtil.getColumnIndexOrThrow(_cursor, "parentId");
            final int _cursorIndexOfRequiresMultiple = CursorUtil.getColumnIndexOrThrow(_cursor, "requiresMultiple");
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
            final TodoWithDetails _result;
            if (_cursor.moveToFirst()) {
              final TodoEntity _tmpTodo;
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
              final String _tmpPriority;
              _tmpPriority = _cursor.getString(_cursorIndexOfPriority);
              final String _tmpDueDate;
              if (_cursor.isNull(_cursorIndexOfDueDate)) {
                _tmpDueDate = null;
              } else {
                _tmpDueDate = _cursor.getString(_cursorIndexOfDueDate);
              }
              final boolean _tmpCompleted;
              final int _tmp;
              _tmp = _cursor.getInt(_cursorIndexOfCompleted);
              _tmpCompleted = _tmp != 0;
              final String _tmpCompletedAt;
              if (_cursor.isNull(_cursorIndexOfCompletedAt)) {
                _tmpCompletedAt = null;
              } else {
                _tmpCompletedAt = _cursor.getString(_cursorIndexOfCompletedAt);
              }
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
              final Integer _tmpEventId;
              if (_cursor.isNull(_cursorIndexOfEventId)) {
                _tmpEventId = null;
              } else {
                _tmpEventId = _cursor.getInt(_cursorIndexOfEventId);
              }
              final Integer _tmpParentId;
              if (_cursor.isNull(_cursorIndexOfParentId)) {
                _tmpParentId = null;
              } else {
                _tmpParentId = _cursor.getInt(_cursorIndexOfParentId);
              }
              final boolean _tmpRequiresMultiple;
              final int _tmp_1;
              _tmp_1 = _cursor.getInt(_cursorIndexOfRequiresMultiple);
              _tmpRequiresMultiple = _tmp_1 != 0;
              final String _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
              final String _tmpUpdatedAt;
              _tmpUpdatedAt = _cursor.getString(_cursorIndexOfUpdatedAt);
              _tmpTodo = new TodoEntity(_tmpId,_tmpTitle,_tmpDescription,_tmpPriority,_tmpDueDate,_tmpCompleted,_tmpCompletedAt,_tmpCategoryId,_tmpCategoryName,_tmpCategoryColor,_tmpCategoryIcon,_tmpEventId,_tmpParentId,_tmpRequiresMultiple,_tmpCreatedAt,_tmpUpdatedAt);
              final ArrayList<FamilyMemberEntity> _tmpMembersCollection;
              final long _tmpKey_1;
              _tmpKey_1 = _cursor.getLong(_cursorIndexOfId);
              _tmpMembersCollection = _collectionMembers.get(_tmpKey_1);
              _result = new TodoWithDetails(_tmpTodo,_tmpMembersCollection);
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

  @Override
  public Flow<List<SubtodoEntity>> getSubtodos(final int parentId) {
    final String _sql = "SELECT * FROM subtodos WHERE parentId = ? ORDER BY createdAt";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, parentId);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"subtodos"}, new Callable<List<SubtodoEntity>>() {
      @Override
      @NonNull
      public List<SubtodoEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfParentId = CursorUtil.getColumnIndexOrThrow(_cursor, "parentId");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfCompleted = CursorUtil.getColumnIndexOrThrow(_cursor, "completed");
          final int _cursorIndexOfCompletedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "completedAt");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final List<SubtodoEntity> _result = new ArrayList<SubtodoEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final SubtodoEntity _item;
            final int _tmpId;
            _tmpId = _cursor.getInt(_cursorIndexOfId);
            final int _tmpParentId;
            _tmpParentId = _cursor.getInt(_cursorIndexOfParentId);
            final String _tmpTitle;
            _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            final boolean _tmpCompleted;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfCompleted);
            _tmpCompleted = _tmp != 0;
            final String _tmpCompletedAt;
            if (_cursor.isNull(_cursorIndexOfCompletedAt)) {
              _tmpCompletedAt = null;
            } else {
              _tmpCompletedAt = _cursor.getString(_cursorIndexOfCompletedAt);
            }
            final String _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getString(_cursorIndexOfCreatedAt);
            _item = new SubtodoEntity(_tmpId,_tmpParentId,_tmpTitle,_tmpCompleted,_tmpCompletedAt,_tmpCreatedAt);
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
    _stringBuilder.append("SELECT `family_members`.`id` AS `id`,`family_members`.`name` AS `name`,`family_members`.`color` AS `color`,`family_members`.`avatarEmoji` AS `avatarEmoji`,`family_members`.`createdAt` AS `createdAt`,_junction.`todoId` FROM `todo_members` AS _junction INNER JOIN `family_members` ON (_junction.`memberId` = `family_members`.`id`) WHERE _junction.`todoId` IN (");
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
      // _junction.todoId;
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
