use "lib:sqlite3"
use "collections"

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
  let _bound_parameters: Map[String, I32] = _bound_parameters.create()

  new ref _create(stmt: Pointer[_Statement] tag) =>
    _stmt = stmt

    for n in Range[I32](0, bind_count()) do
      let name = bind_name(n)
      if name.size() > 0 then
        _bound_parameters(consume name) = n
      end
    end

  fun _final() =>
    if not _closed then
      // just in case
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

  fun @_noop() =>
    // used as a function callback
    None

  fun bind(parameter: (I32 | String), value: (None | F64 | I32 | I64 | String box | Array[U8] box | SqliteZeroBlob)): SqliteResultCode =>
    """
    Binds a value to a parameter in the statement.

    `parameter` is either the index or the name of the parameter.

    Parameters in a SQL statement can take the form of: `?`, `?NNN`, `:VVV`,
    `@VVV`, and `$VVV`, where `NNN` is an integer and `VVV` is an alphanumeric
    identifier.

    Note: indexes start at 0.

    Note: The default maximum length of `String` and `Array[U8]` that SQLite
    supports is 1,000,000,000 bytes.

    See https://sqlite.org/c3ref/bind_blob.html
    """

    let column_index =
      match parameter
      | let p: I32 =>
        p
      | let p: String =>
        try
          _bound_parameters(p)?
        else
          return Sqlite.result_err()
        end
      end

    match value
    | None =>
      @sqlite3_bind_null(_stmt, column_index+1)
    | let v: F64 =>
      @sqlite3_bind_double(_stmt, column_index+1, v)
    | let v: I32 =>
      @sqlite3_bind_int(_stmt, column_index+1, v)
    | let v: I64 =>
      @sqlite3_bind_int64(_stmt, column_index+1, v)
    | let v: String box =>
      let length = v.size().u64()
      if length <= I32.max_value().u64() then
        @sqlite3_bind_text(_stmt, column_index+1, v.cpointer(), v.size().i32(), addressof this._noop)
      else
        // you must have a lot of RAM available :)
        let utf8: U8 = 1
        @sqlite3_bind_text64(_stmt, column_index+1, v.cpointer(), length, addressof this._noop, utf8)
      end
    | let v: Array[U8] box =>
      let length = v.size().u64()
      if length <= I32.max_value().u64() then
        @sqlite3_bind_blob(_stmt, column_index+1, v.cpointer(), v.size().i32(), addressof this._noop)
      else
        // you must have a lot of RAM available :)
        @sqlite3_bind_blob64(_stmt, column_index+1, v.cpointer(), length, addressof this._noop)
      end
    | let v: SqliteZeroBlob =>
      match v.length
      | let v': I32 =>
        @sqlite3_bind_zeroblob(_stmt, column_index+1, v')
      | let v': U64 =>
        @sqlite3_bind_zeroblob64(_stmt, column_index+1, v')
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

  fun execute(): SqliteResultSet =>
    SqliteResultSet._create(_stmt)
