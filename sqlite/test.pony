use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(t: PonyTest) =>
    t(_TestVersion)
    t(_TestOpenClose)
    t(_TestStatement)
    //t(_StatementBind)

class _TestVersion is UnitTest
  fun name(): String => "version"
  fun apply(h: TestHelper) =>
    h.assert_eq[String](Sqlite.version(), "3.27.2")

class _TestOpenClose is UnitTest
  fun name(): String => "open_close"
  fun apply(h: TestHelper) =>
    match Sqlite(":memory:")
    | let err: SqliteError =>
      h.fail("failed to open :memory: connection: " + err.code.string() + ", " + err.description)

    | let conn: SqliteConnection =>
      h.assert_eq[SqliteResultCode](conn.close(), Sqlite.result_ok(), "expected connection close")
    end

class _TestStatement is UnitTest
  fun name(): String => "statement"
  fun apply(h: TestHelper)? =>
    match Sqlite(":memory:")
    | let err: SqliteError =>
      h.fail("failed to open :memory: connection: " + err.code.string() + ", " + err.description)

    | let conn: SqliteConnection =>
      match conn.sql(
        """
        select
          'hi' || ' there' as str,
          -2147483648 as min_int,
          2147483647 as max_int,
          -9223372036854775808 as min_int64,
          9223372036854775807 as max_int64,
          -1.7976931348623157081452742373e+308 as min_double,
          1.79769313486231570814527423731e+308 as max_double,
          x'deadbeef' as blob,
          null as null_value
        """
        )
      | let err: SqliteError =>
        h.fail("failed prepare statement: " + err.code.string() + ", " + err.description)

      | let stmt: SqliteStatement =>
        let rs = stmt.execute()
        h.assert_eq[SqliteResultCode](rs.column_count, 9, "expected column count")

        h.assert_eq[SqliteResultCode](rs.step(), Sqlite.result_row(), "expected row to exist")

        let colText = rs.column(0)?
        h.assert_eq[I32](colText.index, 0)
        h.assert_eq[String](colText.name, "str")
        h.assert_eq[SqliteDataType](colText.data_type, Sqlite.data_text(), "expected text")
        h.assert_eq[String](colText.string(), "hi there", "expected 'hi there'")

        let colMinI32 = rs.column(1)?
        let colMaxI32 = rs.column(2)?
        h.assert_eq[I32](colMinI32.index, 1)
        h.assert_eq[I32](colMaxI32.index, 2)
        h.assert_eq[String](colMinI32.name, "min_int")
        h.assert_eq[String](colMaxI32.name, "max_int")
        h.assert_eq[SqliteDataType](colMinI32.data_type, Sqlite.data_integer(), "expected integer")
        h.assert_eq[SqliteDataType](colMaxI32.data_type, Sqlite.data_integer(), "expected integer")
        h.assert_eq[I32](colMinI32.i32(), I32.min_value(), "expected min I32")
        h.assert_eq[I32](colMaxI32.i32(), I32.max_value(), "expected max I32")

        let colMinI64 = rs.column(3)?
        let colMaxI64 = rs.column(4)?
        h.assert_eq[I32](colMinI64.index, 3)
        h.assert_eq[I32](colMaxI64.index, 4)
        h.assert_eq[String](colMinI64.name, "min_int64")
        h.assert_eq[String](colMaxI64.name, "max_int64")
        h.assert_eq[SqliteDataType](colMinI64.data_type, Sqlite.data_integer(), "expected integer")
        h.assert_eq[SqliteDataType](colMaxI64.data_type, Sqlite.data_integer(), "expected integer")
        h.assert_eq[I64](colMinI64.i64(), I64.min_value(), "expected min I64")
        h.assert_eq[I64](colMaxI64.i64(), I64.max_value(), "expected max I64")

        let colMinF64 = rs.column(5)?
        let colMaxF64 = rs.column(6)?
        h.assert_eq[I32](colMinF64.index, 5)
        h.assert_eq[I32](colMaxF64.index, 6)
        h.assert_eq[String](colMinF64.name, "min_double")
        h.assert_eq[String](colMaxF64.name, "max_double")
        h.assert_eq[SqliteDataType](colMinF64.data_type, Sqlite.data_float(), "expected float")
        h.assert_eq[SqliteDataType](colMaxF64.data_type, Sqlite.data_float(), "expected float")
        h.assert_eq[F64](colMinF64.f64(), F64.min_value(), "expected min F64")
        h.assert_eq[F64](colMaxF64.f64(), F64.max_value(), "expected max F64")

        let colBlob = rs.column(7)?
        h.assert_eq[I32](colBlob.index, 7)
        h.assert_eq[String](colBlob.name, "blob")
        h.assert_eq[SqliteDataType](colBlob.data_type, Sqlite.data_blob(), "expected blob")
        let blob_recv = colBlob.array()
        let blob_expect: Array[U8] = [0xde; 0xad; 0xbe; 0xef]
        h.assert_array_eq[U8](blob_recv, blob_expect, "expected same blob")

        let colNull = rs.column(8)?
        h.assert_eq[I32](colNull.index, 8)
        h.assert_eq[String](colNull.name, "null_value")
        h.assert_eq[SqliteDataType](colNull.data_type, Sqlite.data_null(), "expected null")
        h.assert_eq[I32](colNull.i32(), 0, "null coercion to I32")
        h.assert_eq[I64](colNull.i64(), 0, "null coercion to I64")
        h.assert_eq[F64](colNull.f64(), 0, "null coercion to F64")
        h.assert_eq[String](colNull.string(), "", "null coercion to text")
        h.assert_array_eq[U8](colNull.array(), Array[U8], "null coercion to blob")

        h.assert_eq[SqliteResultCode](rs.step(), Sqlite.result_done(), "expected no more rows")

        h.assert_eq[SqliteResultCode](rs.reset(), Sqlite.result_ok(), "expected statement reset")

        h.assert_eq[SqliteResultCode](stmt.close(), Sqlite.result_ok(), "expected statement close")
      end

      h.assert_eq[SqliteResultCode](conn.close(), Sqlite.result_ok(), "expected connection close")
    end


class _StatementBind is UnitTest
  fun name(): String => "statement.bind"
  fun apply(h: TestHelper)? =>
    match Sqlite(":memory:")
    | let err: SqliteError =>
      h.fail("failed to open :memory: connection: " + err.code.string() + ", " + err.description)

    | let conn: SqliteConnection =>
      create_table(h, conn)
      insert(h, conn)
      select(h, conn)?
      h.assert_eq[SqliteResultCode](conn.close(), Sqlite.result_ok(), "expected connection close")
    end

  fun create_table(h: TestHelper, conn: SqliteConnection) =>
    match conn.sql(
      """
      create table khajana (
        id integer primary key,
        ints integer not null,
        int64s integer not null,
        doubles real not null,
        strings text not null,
        blobs blob not null,
        blobs2 blob not null,
        nulls text
      )
      """
    )
    | let err: SqliteError =>
      h.fail("failed prepare statement: " + err.code.string() + ", " + err.description)

    | let stmt: SqliteStatement =>
      let rs = stmt.execute()
      h.assert_eq[SqliteResultCode](rs.step(), Sqlite.result_done())
      h.assert_eq[SqliteResultCode](stmt.close(), Sqlite.result_ok())
    end

  fun insert(h: TestHelper, conn: SqliteConnection) =>
    match conn.sql(
      """
      insert into khajana (ints, int64s, doubles, strings, blobs, blobs2, nulls)
      values (?, ?2, :doubles, @strings, $blobs, $blobs2, ?)
      """
    )
    | let err: SqliteError =>
      h.fail("statement insert khajana: " + err.code.string() + ", " + err.description)

    | let stmt: SqliteStatement =>
      let b: Array[U8] = [0xde; 0xad; 0xbe; 0xef]
      h.assert_eq[SqliteResultCode](stmt.bind(0, I32(42)), Sqlite.result_ok())
      h.assert_eq[SqliteResultCode](stmt.bind(1, I64(9000)), Sqlite.result_ok())
      h.assert_eq[SqliteResultCode](stmt.bind(":doubles", F64(3.14)), Sqlite.result_ok())
      h.assert_eq[SqliteResultCode](stmt.bind("@strings", "oh the huge manatee!"), Sqlite.result_ok())
      h.assert_eq[SqliteResultCode](stmt.bind("$blobs", b), Sqlite.result_ok())
      h.assert_eq[SqliteResultCode](stmt.bind("$blobs2", SqliteZeroBlob(I32(4))), Sqlite.result_ok())
      h.assert_eq[SqliteResultCode](stmt.bind(6, None), Sqlite.result_ok())

      h.assert_eq[I32](stmt.bind_index("?2"), 1)
      h.assert_eq[I32](stmt.bind_index(":doubles"), 2)
      h.assert_eq[I32](stmt.bind_index("@strings"), 3)
      h.assert_eq[I32](stmt.bind_index("$blobs"), 4)
      h.assert_eq[I32](stmt.bind_index("$blobs2"), 5)

      h.assert_eq[String](stmt.bind_name(1), "?2")
      h.assert_eq[String](stmt.bind_name(2), ":doubles")
      h.assert_eq[String](stmt.bind_name(3), "@strings")
      h.assert_eq[String](stmt.bind_name(4), "$blobs")
      h.assert_eq[String](stmt.bind_name(5), "$blobs2")

      h.assert_eq[I32](stmt.bind_count(), 7)

      let rs = stmt.execute()
      h.assert_eq[SqliteResultCode](rs.step(), Sqlite.result_done())
      h.assert_eq[SqliteResultCode](stmt.close(), Sqlite.result_ok())
    end

  fun select(h: TestHelper, conn: SqliteConnection)? =>
    match conn.sql(
      """
      select ints, int64s, doubles, strings, blobs, blobs2, nulls from khajana limit 1
      """
    )
    | let err: SqliteError =>
      h.fail("statement select khajana: " + err.code.string() + ", " + err.description)

    | let stmt: SqliteStatement =>
      let b: Array[U8] = [0xde; 0xad; 0xbe; 0xef]
      let b2: Array[U8] = [0; 0; 0; 0]
      let rs = stmt.execute()
      h.assert_eq[SqliteResultCode](rs.step(), Sqlite.result_row())

      h.assert_eq[I32](rs.column(0)?.i32(), 42)
      h.assert_eq[I64](rs.column(1)?.i64(), 9000)
      h.assert_eq[F64](rs.column(2)?.f64(), 3.14)
      h.assert_eq[String](rs.column(3)?.string(), "oh the huge manatee!")
      h.assert_array_eq[U8](rs.column(4)?.array(), b)
      h.assert_array_eq[U8](rs.column(5)?.array(), b2)
      h.assert_eq[SqliteDataType](rs.column(6)?.data_type, Sqlite.data_null())

      h.assert_eq[SqliteResultCode](rs.step(), Sqlite.result_done())
      h.assert_eq[SqliteResultCode](stmt.close(), Sqlite.result_ok())
    end
