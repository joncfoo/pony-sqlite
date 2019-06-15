use "lib:sqlite3"

class SqliteColumn
  let _stmt: Pointer[_Statement] tag
  let index: I32
  let name: String
  let data_type: SqliteDataType

  new _create(stmt: Pointer[_Statement] tag, index': I32, name': String) =>
    _stmt = stmt
    index = index'
    name = name'
    data_type = @sqlite3_column_type(_stmt, index')

  fun f64(): F64 =>
    """
    Retrieve this column as a `F64` value.
    """
    @sqlite3_column_double(_stmt, index)

  fun f64_n(): (F64 | None) =>
    """
    Retrieve the column as a `F64` value.
    """
    if data_type == Sqlite.data_null() then
      None
    else
      @sqlite3_column_double(_stmt, index)
    end

  fun i32(): I32 =>
    """
    Retrieve this column as an `I32` value.
    """
    @sqlite3_column_int(_stmt, index)

  fun i32_n(): (I32 | None) =>
    """
    Retrieve the column as an `I32` value.
    """
    if data_type == Sqlite.data_null() then
      None
    else
      @sqlite3_column_int(_stmt, index)
    end

  fun i64(): I64 =>
    """
    Retrieve this column as an `I64` value.
    """
    @sqlite3_column_int64(_stmt, index)

  fun i64_n(): (I64 | None) =>
    """
    Retrieve the column as an `I64` value.
    """
    if data_type == Sqlite.data_null() then
      None
    else
      @sqlite3_column_int64(_stmt, index)
    end

  fun string(): String iso^ =>
    """
    Retrieve this column as an `String` value.
    """
    let str = @sqlite3_column_text(_stmt, index)
    let length = @sqlite3_column_bytes(_stmt, index).usize()
    String.copy_cpointer(str, length).clone()

  fun string_n(): (String iso^ | None) =>
    """
    Retrieve the column as an `String` value.
    """
    if data_type == Sqlite.data_null() then
      None
    else
      let str = @sqlite3_column_text(_stmt, index)
      let length = @sqlite3_column_bytes(_stmt, index).usize()
      String.copy_cpointer(str, length).clone()
    end

  fun array(): Array[U8] ref^ =>
    """
    Retrieve this column as a BLOB (`Array[U8]`).
    """
    let bytes = @sqlite3_column_blob(_stmt, index)
    let length = @sqlite3_column_bytes(_stmt, index)
    Array[U8].from_cpointer(bytes, length.usize()).clone()

  fun array_n(): (Array[U8] ref^ | None) =>
    """
    Retrieve the column as a BLOB (`Array[U8]`).
    """
    if data_type == Sqlite.data_null() then
      None
    else
      let bytes = @sqlite3_column_blob(_stmt, index)
      let length = @sqlite3_column_bytes(_stmt, index)
      Array[U8].from_cpointer(bytes, length.usize()).clone()
    end
