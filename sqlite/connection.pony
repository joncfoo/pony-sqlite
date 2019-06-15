use "lib:sqlite3"
use "debug"

class SqliteConnection
  """
  A connection to a SQLite database. Use this to create SQL statements. Call
  `close()` when you have finished working with the connection.
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
      SqliteError(rc)
    else
      if stmt.is_null() then
        SqliteError(Sqlite.result_err())
      else
        SqliteStatement._create(stmt)
      end
    end
