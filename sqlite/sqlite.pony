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
use @sqlite3_bind_text[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: Pointer[U8] tag, length: I32, destructor: @{(): None})
use @sqlite3_bind_text64[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: Pointer[U8] tag, length: U64, destructor: @{(): None}, encoding: U8)
use @sqlite3_bind_blob[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: Pointer[U8] tag, length: I32, destructor: @{(): None})
use @sqlite3_bind_blob64[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, value: Pointer[U8] tag, length: U64, destructor: @{(): None})
use @sqlite3_bind_zeroblob[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, length: I32)
use @sqlite3_bind_zeroblob64[SqliteResultCode](statement: Pointer[_Statement] tag, column: I32, length: U64)

use @sqlite3_column_count[I32](statement: Pointer[_Statement] tag)
use @sqlite3_column_name[Pointer[U8]](statement: Pointer[_Statement] tag, column: I32)
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
  Placeholder used to tell SQLite to fill a blob with 0s of size `length`.
  """
  let length: (I32 | U64)
  new create(length': (I32 | U64)) =>
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
