"""
[SQLite](https://sqlite.org/) bindings for Pony.
"""

use "lib:sqlite3"
use "debug"

use @sqlite3_libversion[Pointer[U8]]()
use @sqlite3_open_v2[SqliteResultCode](
  file_name: Pointer[U8] tag,
  connection: Pointer[Pointer[_Connection]],
  flags: I32,
  vfs: Pointer[U8] tag
)
use @sqlite3_close_v2[SqliteResultCode](connection: Pointer[_Connection] tag)
use @sqlite3_errstr[Pointer[U8]](rc: SqliteResultCode)

use @sqlite3_prepare_v3[SqliteResultCode](
  connection: Pointer[_Connection] tag,
  sql: Pointer[U8] tag,
  sql_len: I32,
  prepare_flags: SqlitePrepareFlag,
  statement: Pointer[Pointer[_Statement]],
  sql_tail: Pointer[Pointer[U8]]
)
use @sqlite3_step[SqliteResultCode](statement: Pointer[_Statement] tag)
use @sqlite3_reset[SqliteResultCode](statement: Pointer[_Statement] tag)
use @sqlite3_finalize[SqliteResultCode](statement: Pointer[_Statement] tag)

use @sqlite3_bind_parameter_count[I32](statement: Pointer[_Statement] tag)
use @sqlite3_bind_parameter_index[I32](statement: Pointer[_Statement] tag, name: Pointer[U8] tag)
use @sqlite3_bind_parameter_name[Pointer[U8]](statement: Pointer[_Statement] tag, column: I32)
use @sqlite3_bind_null[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32)
use @sqlite3_bind_double[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: F64)
use @sqlite3_bind_int[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: I32)
use @sqlite3_bind_int64[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: I64)
use @sqlite3_bind_text[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: Pointer[U8] tag, length: I32)
// use @sqlite3_bind_text64[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: Pointer[U8] tag, length: U64, encoding: U8)
use @sqlite3_bind_blob[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: Pointer[U8] tag, length: I32)
// use @sqlite3_bind_blob64[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: Pointer[U8] tag, length: I64)
use @sqlite3_bind_zeroblob[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, length: I32)
use @sqlite3_bind_zeroblob64[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, length: I64)

use @sqlite3_column_count[I32](statement: Pointer[_Statement] tag)
use @sqlite3_column_type[SqliteDataType](statement: Pointer[_Statement] tag, column: I32)
use @sqlite3_column_blob[Pointer[U8]](statement: Pointer[_Statement] tag, column: I32)
use @sqlite3_column_double[F64](statement: Pointer[_Statement] tag, column: I32)
use @sqlite3_column_int[I32](statement: Pointer[_Statement] tag, column: I32)
use @sqlite3_column_int64[I64](statement: Pointer[_Statement] tag, column: I32)
use @sqlite3_column_text[Pointer[U8]](statement: Pointer[_Statement] tag, column: I32)
use @sqlite3_column_bytes[I32](statement: Pointer[_Statement] tag, column: I32)


primitive Sqlite
  """
  This primitive contains supporting functions for SQLite.
  """

  fun apply(
    file_name: String,
    open_flags: SqliteOpenFlag = Sqlite.open_readwrite() or Sqlite.open_create()
  ): (SqliteConnection | SqliteError) =>
    """
    Opens a connection to a SQLite database. Returns `SqliteConnection` if the
    database could be successfully opened or `SqliteError` if it could not.

    `file_name` can be empty, `":memory:"`, path to a file, or a URI.

    If `file_name` is empty, then a temporary database is created and used until
    the database connection is closed. If `file_name` is `":memory:"` then an
    in-memory database is created and used.

    `open_flags` is used to control how SQLite opens the database
    connection. The default value creates a database if it does not already
    exist and opens it in read+write mode.

    See https://sqlite.org/c3ref/open.html and https://sqlite.org/inmemorydb.html
    """
    var conn: Pointer[_Connection] = conn.create()
    let rc = @sqlite3_open_v2(
        file_name.clone().cstring(),
        addressof conn,
        open_flags,
        Pointer[U8].create()
    )

    if rc != Sqlite.result_ok() then
      @sqlite3_close_v2(conn)
      SqliteError(rc)
    else
      SqliteConnection._create(conn)
    end

  fun version(): String iso^ =>
    """
    The SQLite version.
    """
    recover
      String.copy_cstring(@sqlite3_libversion())
    end

  fun result_description(rc: SqliteResultCode): String iso^ =>
    """
    Description of a `ResultCode`.
    """
    recover
      String.copy_cstring(@sqlite3_errstr(rc))
    end

  // https://sqlite.org/c3ref/c_abort.html
  fun open_readonly():       SqliteOpenFlag => 0x00000001  /* Ok for sqlite3_open_v2() */
  fun open_readwrite():      SqliteOpenFlag => 0x00000002  /* Ok for sqlite3_open_v2() */
  fun open_create():         SqliteOpenFlag => 0x00000004  /* Ok for sqlite3_open_v2() */
  fun open_deleteonclose():  SqliteOpenFlag => 0x00000008  /* VFS only */
  fun open_exclusive():      SqliteOpenFlag => 0x00000010  /* VFS only */
  fun open_autoproxy():      SqliteOpenFlag => 0x00000020  /* VFS only */
  fun open_uri():            SqliteOpenFlag => 0x00000040  /* Ok for sqlite3_open_v2() */
  fun open_memory():         SqliteOpenFlag => 0x00000080  /* Ok for sqlite3_open_v2() */
  fun open_main_db():        SqliteOpenFlag => 0x00000100  /* VFS only */
  fun open_temp_db():        SqliteOpenFlag => 0x00000200  /* VFS only */
  fun open_transient_db():   SqliteOpenFlag => 0x00000400  /* VFS only */
  fun open_main_journal():   SqliteOpenFlag => 0x00000800  /* VFS only */
  fun open_temp_journal():   SqliteOpenFlag => 0x00001000  /* VFS only */
  fun open_subjournal():     SqliteOpenFlag => 0x00002000  /* VFS only */
  fun open_master_journal(): SqliteOpenFlag => 0x00004000  /* VFS only */
  fun open_nomutex():        SqliteOpenFlag => 0x00008000  /* Ok for sqlite3_open_v2() */
  fun open_fullmutex():      SqliteOpenFlag => 0x00010000  /* Ok for sqlite3_open_v2() */
  fun open_sharedcache():    SqliteOpenFlag => 0x00020000  /* Ok for sqlite3_open_v2() */
  fun open_privatecache():   SqliteOpenFlag => 0x00040000  /* Ok for sqlite3_open_v2() */
  fun open_wal():            SqliteOpenFlag => 0x00080000  /* VFS only */

  // https://sqlite.org/c3ref/c_prepare_normalize.html#sqlitepreparepersistent
  fun prepare_persistent(): SqlitePrepareFlag =>
    """
    A hint to the query planner that the prepared statement will be retained
    for a long time and probably reused many times.
    """
    1

  fun prepare_no_vtab(): SqlitePrepareFlag =>
    """
    The SQLITE_PREPARE_NO_VTAB flag causes the SQL compiler to return an error
    (error rc SQLITE_ERROR) if the statement uses any virtual tables.
    """
    4

  // https://sqlite.org/c3ref/c_blob.html
  fun data_integer(): SqliteDataType =>
    """
    Integer data-type
    """
    1

  fun data_float(): SqliteDataType =>
    """
    Float data-type
    """
    2

  fun data_text(): SqliteDataType =>
    """
    Text data-type
    """
    3

  fun data_blob(): SqliteDataType =>
    """
    Blob data-type
    """
    4

  fun data_null(): SqliteDataType =>
    """
    Null data-type
    """
    5

  // https://sqlite.org/c3ref/c_abort.html
  fun result_ok(): SqliteResultCode =>
    """
    Successful result
    """
    0

  fun result_err(): SqliteResultCode =>
    """
    Generic error
    """
    1

  fun result_internal(): SqliteResultCode =>
    """
    Internal logic error in SQLite
    """
    2

  fun result_perm(): SqliteResultCode =>
    """
    Access permission denied
    """
    3

  fun result_abort(): SqliteResultCode =>
    """
    Callback routine requested an abort
    """
    4

  fun result_busy(): SqliteResultCode =>
    """
    The database file is locked
    """
    5

  fun result_locked(): SqliteResultCode =>
    """
    A table in the database is locked
    """
    6

  fun result_nomem(): SqliteResultCode =>
    """
    A malloc() failed
    """
    7

  fun result_readonly(): SqliteResultCode =>
    """
    Attempt to write a readonly database
    """
    8

  fun result_interrupt(): SqliteResultCode =>
    """
    Operation terminated by `sqlite3_interrupt()`
    """
    9

  fun result_ioerr(): SqliteResultCode =>
    """
    Some kind of disk I/O error occurred
    """
    10

  fun result_corrupt(): SqliteResultCode =>
    """
    The database disk image is malformed
    """
    11

  fun result_notfound(): SqliteResultCode =>
    """
    Unknown opcode in `sqlite3_file_control()`
    """
    12

  fun result_full(): SqliteResultCode =>
    """
    Insertion failed because database is full
    """
    13

  fun result_cantopen(): SqliteResultCode =>
    """
    Unable to open the database file
    """
    14

  fun result_protocol(): SqliteResultCode =>
    """
    Database lock protocol error
    """
    15

  fun result_empty(): SqliteResultCode =>
    """
    Internal use only
    """
    16

  fun result_schema(): SqliteResultCode =>
    """
    The database schema changed
    """
    17

  fun result_toobig(): SqliteResultCode =>
    """
    String or BLOB exceeds size limit
    """
    18

  fun result_constraint(): SqliteResultCode =>
    """
    Abort due to constraint violation
    """
    19

  fun result_mismatch(): SqliteResultCode =>
    """
    Data type mismatch
    """
    20

  fun result_misuse(): SqliteResultCode =>
    """
    Library used incorrectly
    """
    21

  fun result_nolfs(): SqliteResultCode =>
    """
    Uses OS features not supported on host
    """
    22

  fun result_auth(): SqliteResultCode =>
    """
    Authorization denied
    """
    23

  fun result_format(): SqliteResultCode =>
    """
    Not used
    """
    24

  fun result_range(): SqliteResultCode =>
    """
    2nd parameter to sqlite3_bind out of range
    """
    25

  fun result_notadb(): SqliteResultCode =>
    """
    File opened that is not a database file
    """
    26

  fun result_notice(): SqliteResultCode =>
    """
    Notifications from `sqlite3_log()`
    """
    27

  fun result_warning(): SqliteResultCode =>
    """
    Warnings from `sqlite3_log()`
    """
    28

  fun result_row(): SqliteResultCode =>
    """
    `sqlite3_step()` has another row ready
    """
    100

  fun result_done(): SqliteResultCode =>
    """
    `sqlite3_step()` has finished executing
    """
    101

  // extended error codes
  // https://sqlite.org/c3ref/result_c_abort_rollback.html
  fun result_error_missing_collseq(): SqliteResultCode =>
    result_err() or (1<<8)

  fun result_error_retry(): SqliteResultCode =>
    result_err() or (2<<8)

  fun result_error_snapshot(): SqliteResultCode =>
    result_err() or (3<<8)

  fun result_ioerr_read(): SqliteResultCode =>
    result_ioerr() or (1<<8)

  fun result_ioerr_short_read(): SqliteResultCode =>
    result_ioerr() or (2<<8)

  fun result_ioerr_write(): SqliteResultCode =>
    result_ioerr() or (3<<8)

  fun result_ioerr_fsync(): SqliteResultCode =>
    result_ioerr() or (4<<8)

  fun result_ioerr_dir_fsync(): SqliteResultCode =>
    result_ioerr() or (5<<8)

  fun result_ioerr_truncate(): SqliteResultCode =>
    result_ioerr() or (6<<8)

  fun result_ioerr_fstat(): SqliteResultCode =>
    result_ioerr() or (7<<8)

  fun result_ioerr_unlock(): SqliteResultCode =>
    result_ioerr() or (8<<8)

  fun result_ioerr_rdlock(): SqliteResultCode =>
    result_ioerr() or (9<<8)

  fun result_ioerr_delete(): SqliteResultCode =>
    result_ioerr() or (10<<8)

  fun result_ioerr_blocked(): SqliteResultCode =>
    result_ioerr() or (11<<8)

  fun result_ioerr_nomem(): SqliteResultCode =>
    result_ioerr() or (12<<8)

  fun result_ioerr_access(): SqliteResultCode =>
    result_ioerr() or (13<<8)

  fun result_ioerr_checkreservedlock(): SqliteResultCode =>
    result_ioerr() or (14<<8)

  fun result_ioerr_lock(): SqliteResultCode =>
    result_ioerr() or (15<<8)

  fun result_ioerr_close(): SqliteResultCode =>
    result_ioerr() or (16<<8)

  fun result_ioerr_dir_close(): SqliteResultCode =>
    result_ioerr() or (17<<8)

  fun result_ioerr_shmopen(): SqliteResultCode =>
    result_ioerr() or (18<<8)

  fun result_ioerr_shmsize(): SqliteResultCode =>
    result_ioerr() or (19<<8)

  fun result_ioerr_shmlock(): SqliteResultCode =>
    result_ioerr() or (20<<8)

  fun result_ioerr_shmmap(): SqliteResultCode =>
    result_ioerr() or (21<<8)

  fun result_ioerr_seek(): SqliteResultCode =>
    result_ioerr() or (22<<8)

  fun result_ioerr_delete_noent(): SqliteResultCode =>
    result_ioerr() or (23<<8)

  fun result_ioerr_mmap(): SqliteResultCode =>
    result_ioerr() or (24<<8)

  fun result_ioerr_gettemppath(): SqliteResultCode =>
    result_ioerr() or (25<<8)

  fun result_ioerr_convpath(): SqliteResultCode =>
    result_ioerr() or (26<<8)

  fun result_ioerr_vnode(): SqliteResultCode =>
    result_ioerr() or (27<<8)

  fun result_ioerr_result_auth(): SqliteResultCode =>
    result_ioerr() or (28<<8)

  fun result_ioerr_begin_atomic(): SqliteResultCode =>
    result_ioerr() or (29<<8)

  fun result_ioerr_commit_atomic(): SqliteResultCode =>
    result_ioerr() or (30<<8)

  fun result_ioerr_rollback_atomic(): SqliteResultCode =>
    result_ioerr() or (31<<8)

  fun result_locked_sharedcache(): SqliteResultCode =>
    result_locked() or (1<<8)

  fun result_locked_vtab(): SqliteResultCode =>
    result_locked() or (2<<8)

  fun result_busy_recovery(): SqliteResultCode =>
    result_busy() or (1<<8)

  fun result_busy_snapshot(): SqliteResultCode =>
    result_busy() or (2<<8)

  fun result_cantopen_notempdir(): SqliteResultCode =>
    result_cantopen() or (1<<8)

  fun result_cantopen_isdir(): SqliteResultCode =>
    result_cantopen() or (2<<8)

  fun result_cantopen_fullpath(): SqliteResultCode =>
    result_cantopen() or (3<<8)

  fun result_cantopen_convpath(): SqliteResultCode =>
    result_cantopen() or (4<<8)

  fun result_cantopen_dirtywal(): SqliteResultCode =>
    result_cantopen() or (5<<8) /* Not Used */

  fun result_corrupt_vtab(): SqliteResultCode =>
    result_corrupt() or (1<<8)

  fun result_corrupt_sequence(): SqliteResultCode =>
    result_corrupt() or (2<<8)

  fun result_readonly_recovery(): SqliteResultCode =>
    result_readonly() or (1<<8)

  fun result_readonly_cantlock(): SqliteResultCode =>
    result_readonly() or (2<<8)

  fun result_readonly_rollback(): SqliteResultCode =>
    result_readonly() or (3<<8)

  fun result_readonly_dbmoved(): SqliteResultCode =>
    result_readonly() or (4<<8)

  fun result_readonly_cantinit(): SqliteResultCode =>
    result_readonly() or (5<<8)

  fun result_readonly_directory(): SqliteResultCode =>
    result_readonly() or (6<<8)

  fun result_abort_rollback(): SqliteResultCode =>
    result_abort() or (2<<8)

  fun result_constraint_check(): SqliteResultCode =>
    result_constraint() or (1<<8)

  fun result_constraint_commithook(): SqliteResultCode =>
    result_constraint() or (2<<8)

  fun result_constraint_foreignkey(): SqliteResultCode =>
    result_constraint() or (3<<8)

  fun result_constraint_function(): SqliteResultCode =>
    result_constraint() or (4<<8)

  fun result_constraint_notnull(): SqliteResultCode =>
    result_constraint() or (5<<8)

  fun result_constraint_primarykey(): SqliteResultCode =>
    result_constraint() or (6<<8)

  fun result_constraint_trigger(): SqliteResultCode =>
    result_constraint() or (7<<8)

  fun result_constraint_unique(): SqliteResultCode =>
    result_constraint() or (8<<8)

  fun result_constraint_vtab(): SqliteResultCode =>
    result_constraint() or (9<<8)

  fun result_constraint_rowid(): SqliteResultCode =>
    result_constraint() or (10<<8)

  fun result_notice_recover_wal(): SqliteResultCode =>
    result_notice() or (1<<8)

  fun result_notice_recover_rollback(): SqliteResultCode =>
    result_notice() or (2<<8)

  fun result_warning_autoindex(): SqliteResultCode =>
    result_warning() or (1<<8)

  fun result_auth_user(): SqliteResultCode =>
    result_auth() or (1<<8)

  fun result_ok_load_permanently(): SqliteResultCode =>
    result_ok() or (1<<8)


class SqliteConnection
  """
  A connection to a SQLite database. Use this to create SQL statements. Call
  `close()` when you have finished working with the database.
  """
  let _conn: Pointer[_Connection] tag
  var _closed: Bool = false

  new ref _create(handle: Pointer[_Connection] tag) =>
    """
    """
    _conn = handle

  fun _final() =>
    if not _closed then
      // just in case
      @sqlite3_close_v2(_conn)
    end

  fun ref close(): SqliteResultCode =>
    """
    Closes the connection to the database.
    """
    if _closed then
      Sqlite.result_ok()
    else
      _closed = true
      @sqlite3_close_v2(_conn)
    end

  fun closed(): Bool =>
    """
    Connection closed status.
    """
    _closed

  fun sql(
    sql': String,
    prepare_flags: SqlitePrepareFlag = 0
  ): (SqliteStatement | SqliteError) =>
    """
    Create a SQL statement to be executed.  Returns `SqliteStatement` if `sql'`
    is a valid SQL statement, otherwise `SqliteError` is returned. Be sure
    to close the statement when you have finished working with it.

    `sql'` is any valid SQL syntax that SQLite understands.

    `prepare_flags` can be used to control how SQLite creates the underlying
    statement.

    See https://sqlite.org/c3ref/prepare.html
    """
    var stmt: Pointer[_Statement] = stmt.create()
    var sql_tail_unused: Pointer[U8] = sql_tail_unused.create()
    let rc = @sqlite3_prepare_v3(
      _conn,
      sql'.cpointer(),
      sql'.size().i32()+1, // include terminating null character
      prepare_flags,
      addressof stmt,
      addressof sql_tail_unused
    )
    if rc != Sqlite.result_ok() then
      Debug.out("prepare statement failed")
      SqliteError(rc)
    else
      if stmt.is_null() then
        Debug.out("prepare statement was null")
        SqliteError(Sqlite.result_err())
      else
        SqliteStatement._create(stmt)
      end
    end


class SqliteStatement
  """
  Prepared statement that points to a result set. Be sure to close the
  statement when you have finished working with it.  Using the statement
  after it has been closed results in undefined behaviour.

  Note: The `f64`, `i32`, `i64`, `string`, and `array` functions potentially
  coerce data to fit the type retrieved. This is a facet of SQLite.
  See https://www.sqlite.org/datatype3.html for more details.
  """
  let _stmt: Pointer[_Statement] tag
  var _closed: Bool = false

  new ref _create(stmt: Pointer[_Statement] tag) =>
    _stmt = stmt

  fun _final() =>
    if not _closed then
      @sqlite3_finalize(_stmt)
    end

  fun ref close(): SqliteResultCode =>
    """
    Closes the statement. Be sure _not_ to use the statement after it has
    been closed.

    See https://sqlite.org/c3ref/finalize.html
    """
    if _closed then
      Sqlite.result_ok()
    else
      _closed = true
      @sqlite3_finalize(_stmt)
    end

  fun closed(): Bool =>
    """
    Statement closed status.
    """
    _closed

  fun bind(index: I32, value: (None | F64 | I32 | I64 | String | Array[U8] | SqliteZeroBlob)): SqliteResultCode =>
    """
    Binds a value to a parameter in the statement.

    `index` is the index of the parameter (starting at 0).

    Parameters in a SQL statement can take the form of: `?`, `?NNN`, `:VVV`,
    `@VVV`, and `$VVV`, where `NNN` is an integer and `VVV` is an alphanumeric
    identifier.

    Note: The maximum length of `String` and `Array[U8]` this method supports
    is limited to `i32.max_value()`.  Please file an issue if you want to
    support larger strings and arrays.

    See https://sqlite.org/c3ref/bind_blob.html
    """
    match value
    | None =>
      @sqlite3_bind_null(_stmt, index+1)
    | let v: F64 =>
      @sqlite3_bind_double(_stmt, index+1, v)
    | let v: I32 =>
      @sqlite3_bind_int(_stmt, index+1, v)
    | let v: I64 =>
      @sqlite3_bind_int64(_stmt, index+1, v)
    | let v: String =>
        @sqlite3_bind_text(_stmt, index+1, v.cpointer(), v.size().i32())
    | let v: Array[U8] =>
        @sqlite3_bind_blob(_stmt, index+1, v.cpointer(), v.size().i32())
    | let v: SqliteZeroBlob =>
      match v.length
      | let v': I32 =>
        @sqlite3_bind_zeroblob(_stmt, index+1, v')
      | let v': I64 =>
        @sqlite3_bind_zeroblob64(_stmt, index+1, v')
      end
    end

  fun bind_count(): I32 =>
    """
    Returns the total number of bound parameters in the statement.

    See https://sqlite.org/c3ref/bind_parameter_count.html
    """
    @sqlite3_bind_parameter_count(_stmt)

  fun bind_index(name: String): I32 =>
    """
    Returns the index of the named parameter.

    Note: indexes start at 0 unlike SQLite which starts at 1.

    See https://sqlite.org/c3ref/bind_parameter_index.html
    """
    @sqlite3_bind_parameter_index(_stmt, name.cpointer()) - 1

  fun bind_name(index: I32): String iso^ =>
    """
    Returns the name of the parameter at the specified index.

    Note: indexes start at 0 unlike SQLite which starts at 1.

    See https://sqlite.org/c3ref/bind_parameter_name.html
    """
    recover
      String.from_cstring(@sqlite3_bind_parameter_name(_stmt, index + 1))
    end

  fun step(): SqliteResultCode =>
    """
    Call `step()` repeatedly to iterate over the result set.

    If further rows exist, `Sqlite.result_row()` is returned.

    If the end of the result set is reached, `Sqlite.result_done()` is returned.

    See https://sqlite.org/c3ref/step.html
    """
    if _closed then
      Sqlite.result_misuse()
    else
      @sqlite3_step(_stmt)
    end

  fun reset(): SqliteResultCode =>
    """
    Resets the statement to its initial state.  Call this if you wish to
    re-iterate over the result set.

    See https://sqlite.org/c3ref/reset.html
    """
    if _closed then
      Sqlite.result_misuse()
    else
      @sqlite3_reset(_stmt)
    end

  fun column_count(): I32 =>
    """
    The number of columns in the result set returned by this statement.

    See https://sqlite.org/c3ref/column_count.html
    """
    @sqlite3_column_count(_stmt)

  fun data_type(column: I32): SqliteDataType =>
    """
    Returns the data-type for _initial_ data-type of the column.
    """
    @sqlite3_column_type(_stmt, column)

  fun f64(column: I32): F64 =>
    """
    Retrieve the column as a `F64` value.
    """
    @sqlite3_column_double(_stmt, column)

  fun i32(column: I32): I32 =>
    """
    Retrieve the column as an `I32` value.
    """
    @sqlite3_column_int(_stmt, column)

  fun i64(column: I32): I64 =>
    """
    Retrieve the column as an `I64` value.
    """
    @sqlite3_column_int64(_stmt, column)

  fun string(column: I32): String iso^ =>
    """
    Retrieve the column as an `String` value.
    """
    let str = @sqlite3_column_text(_stmt, column)
    let length = @sqlite3_column_bytes(_stmt, column).usize()
    String.copy_cpointer(str, length).clone()

  fun array(column: I32): Array[U8] ref^ =>
    """
    Retrieve the column as a BLOB (`Array[U8]`).
    """
    let bytes = @sqlite3_column_blob(_stmt, column)
    let length = @sqlite3_column_bytes(_stmt, column)
    Array[U8].from_cpointer(bytes, length.usize()).clone()


class SqliteError
  """
  Convenience class used to relay a SQLite error code and its description.
  """
  let code: SqliteResultCode
  let description: String

  new create(code': SqliteResultCode) =>
    code = code'
    description = Sqlite.result_description(code)

  fun box string(): String iso^ =>
    recover
      String
        .>append("SqliteError(")
        .>append(code.string())
        .>append(", '")
        .>append(description)
        .>append("')")
    end


class SqliteZeroBlob
  """
  Placeholder used tell SQLite to fill a blob with 0s of `length`.
  """
  let length: (I32 | I64)
  new create(length': (I32 | I64)) =>
    length = length'


primitive _Connection
"""
_Connection represents the opaque structure `sqlite3`
"""

primitive _Statement
"""
_Statement represents the opaque structure `sqlite3_stmt`
"""

type SqliteOpenFlag is I32
  """
  Bit values intended to be used while opening SQLite databases.

  See https://sqlite.org/c3ref/c_open_autoproxy.html
  """

type SqliteResultCode is I32
  """
  Result codes that the underlying SQLite APIs return.

  See https://sqlite.org/rescode.html
  """

type SqlitePrepareFlag is U32
  """
  Bit values intended to be used while creating SQL statements.

  See https://sqlite.org/c3ref/c_prepare_normalize.html
  """

type SqliteDataType is I32
  """
  Representation of SQLite data-type.

  See https://sqlite.org/c3ref/c_blob.html
  """
