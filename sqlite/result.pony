use "lib:sqlite3"
use "collections"

class SqliteResultSet is Iterator[SqliteColumn]
  let _stmt: Pointer[_Statement] tag
  var _iter_index: I32 = -1
  var _iter_stop: Bool = false
  let column_count: I32
    """
    The number of columns in the result set returned by the statement.

    See https://sqlite.org/c3ref/column_count.html
    """
  var err: (SqliteResultCode | None) = None

  let columns: Map[String, I32] = columns.create()

  new ref _create(stmt: Pointer[_Statement] tag) =>
    _stmt = stmt
    column_count = @sqlite3_column_count(_stmt)

    for i in Range[I32](0, column_count) do
      let cname = recover val
        String.copy_cstring(@sqlite3_column_name(_stmt, i))
      end
      columns(cname) = i
    end

  fun ref has_next(): Bool =>
    not _iter_stop

  fun ref next(): SqliteColumn? =>
    var step_result = @sqlite3_step(_stmt)

    if step_result == Sqlite.result_row() then
      _iter_index = _iter_index + 1
      column(_iter_index)?
    elseif step_result == Sqlite.result_done() then
      _iter_stop = true
      error
    else
      _iter_stop = true
      err = step_result
      error
    end

  fun step(): SqliteResultCode =>
    """
    Call `step()` repeatedly to iterate over the result set.

    If further rows exist, `Sqlite.result_row()` is returned.

    If the end of the result set is reached, `Sqlite.result_done()` is returned.

    See https://sqlite.org/c3ref/step.html
    """
    @sqlite3_step(_stmt)

  fun reset(): SqliteResultCode =>
    """
    Resets the statement to its initial state.  Call this if you wish to
    re-iterate over the result set.

    See https://sqlite.org/c3ref/reset.html
    """
    @sqlite3_reset(_stmt)

  fun column(n: (I32 | String)): SqliteColumn? =>
    match n
    | let index: I32 =>
      if (index < 0) or (index >= column_count) then
        error
      end

      let cname = recover val
        String.copy_cstring(@sqlite3_column_name(_stmt, index))
      end
      SqliteColumn._create(_stmt, index, cname)
    | let cname: String =>
      try
        SqliteColumn._create(_stmt, columns(cname)?, cname)
      else
        error
      end
    end

  fun column_name(index: I32): String iso^? =>
    """
    Returns the name of the column.

    See https://sqlite.org/c3ref/column_name.html
    """
    if (index < 0) or (index >= column_count) then
      error
    end

    recover
      String.copy_cstring(@sqlite3_column_name(_stmt, index))
    end
