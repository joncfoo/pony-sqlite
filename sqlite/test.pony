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
    t(_StatementBind)

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
  fun apply(h: TestHelper) =>
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
        h.assert_eq[SqliteResultCode](stmt.column_count(), 9, "expected column count")

        h.assert_eq[SqliteResultCode](stmt.step(), Sqlite.result_row(), "expected row to exist")

        h.assert_eq[SqliteDataType](stmt.data_type(0), Sqlite.data_text(), "expected text")
        h.assert_eq[String](stmt.string(0), "hi there", "expected 'hi there'")

        h.assert_eq[SqliteDataType](stmt.data_type(1), Sqlite.data_integer(), "expected integer")
        h.assert_eq[SqliteDataType](stmt.data_type(2), Sqlite.data_integer(), "expected integer")
        h.assert_eq[I32](stmt.i32(1), I32.min_value(), "expected min I32")
        h.assert_eq[I32](stmt.i32(2), I32.max_value(), "expected max I32")

        h.assert_eq[SqliteDataType](stmt.data_type(3), Sqlite.data_integer(), "expected integer")
        h.assert_eq[SqliteDataType](stmt.data_type(4), Sqlite.data_integer(), "expected integer")
        h.assert_eq[I64](stmt.i64(3), I64.min_value(), "expected min I64")
        h.assert_eq[I64](stmt.i64(4), I64.max_value(), "expected max I64")

        h.assert_eq[SqliteDataType](stmt.data_type(5), Sqlite.data_float(), "expected float")
        h.assert_eq[SqliteDataType](stmt.data_type(6), Sqlite.data_float(), "expected float")
        h.assert_eq[F64](stmt.f64(5), F64.min_value(), "expected min F64")
        h.assert_eq[F64](stmt.f64(6), F64.max_value(), "expected max F64")

        h.assert_eq[SqliteDataType](stmt.data_type(7), Sqlite.data_blob(), "expected blob")
        let blob_recv = stmt.array(7)
        let blob_expect: Array[U8] = [0xde; 0xad; 0xbe; 0xef]
        h.assert_array_eq[U8](blob_recv, blob_expect, "expected same blob")

        h.assert_eq[SqliteDataType](stmt.data_type(8), Sqlite.data_null(), "expected null")
        h.assert_eq[I32](stmt.i32(8), 0, "null coercion to I32")
        h.assert_eq[I64](stmt.i64(8), 0, "null coercion to I64")
        h.assert_eq[F64](stmt.f64(8), 0, "null coercion to F64")
        h.assert_eq[String](stmt.string(8), "", "null coercion to text")
        h.assert_array_eq[U8](stmt.array(8), Array[U8], "null coercion to blob")

        h.assert_eq[SqliteResultCode](stmt.step(), Sqlite.result_done(), "expected no more rows")

        h.assert_eq[SqliteResultCode](stmt.reset(), Sqlite.result_ok(), "expected statement reset")

        h.assert_eq[SqliteResultCode](stmt.close(), Sqlite.result_ok(), "expected statement close")
      end

      h.assert_eq[SqliteResultCode](conn.close(), Sqlite.result_ok(), "expected connection close")
    end

class _StatementBind is UnitTest
  fun name(): String => "statement.bind"
  fun apply(h: TestHelper) =>
    match Sqlite(":memory:")
    | let err: SqliteError =>
      h.fail("failed to open :memory: connection: " + err.code.string() + ", " + err.description)

    | let conn: SqliteConnection =>
      create_table(h, conn)
      insert(h, conn)
      select(h, conn)
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
      h.assert_eq[SqliteResultCode](stmt.step(), Sqlite.result_done())
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
      h.assert_eq[SqliteResultCode](stmt.bind(2, F64(3.14)), Sqlite.result_ok())
      h.assert_eq[SqliteResultCode](stmt.bind(3, "oh the huge manatee!"), Sqlite.result_ok())
      h.assert_eq[SqliteResultCode](stmt.bind(4, b), Sqlite.result_ok())
      h.assert_eq[SqliteResultCode](stmt.bind(5, SqliteZeroBlob(I32(4))), Sqlite.result_ok())
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

      h.assert_eq[SqliteResultCode](stmt.step(), Sqlite.result_done())
      h.assert_eq[SqliteResultCode](stmt.close(), Sqlite.result_ok())
    end

  fun select(h: TestHelper, conn: SqliteConnection) =>
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
      h.assert_eq[SqliteResultCode](stmt.step(), Sqlite.result_row())

      h.assert_eq[I32](stmt.i32(0), 42)
      h.assert_eq[I64](stmt.i64(1), 9000)
      h.assert_eq[F64](stmt.f64(2), 3.14)
      h.assert_eq[String](stmt.string(3), "oh the huge manatee!")
      h.assert_array_eq[U8](stmt.array(4), b)
      h.assert_array_eq[U8](stmt.array(5), b2)
      h.assert_eq[SqliteDataType](stmt.data_type(6), Sqlite.data_null())

      h.assert_eq[SqliteResultCode](stmt.step(), Sqlite.result_done())
      h.assert_eq[SqliteResultCode](stmt.close(), Sqlite.result_ok())
    end
