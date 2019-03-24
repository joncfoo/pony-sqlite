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
        h.assert_eq[String](stmt.text(0), "hi there", "expected 'hi there'")

        h.assert_eq[SqliteDataType](stmt.data_type(1), Sqlite.data_integer(), "expected integer")
        h.assert_eq[SqliteDataType](stmt.data_type(2), Sqlite.data_integer(), "expected integer")
        h.assert_eq[I32](stmt.int(1), I32.min_value(), "expected min I32")
        h.assert_eq[I32](stmt.int(2), I32.max_value(), "expected max I32")

        h.assert_eq[SqliteDataType](stmt.data_type(3), Sqlite.data_integer(), "expected integer")
        h.assert_eq[SqliteDataType](stmt.data_type(4), Sqlite.data_integer(), "expected integer")
        h.assert_eq[I64](stmt.int64(3), I64.min_value(), "expected min I64")
        h.assert_eq[I64](stmt.int64(4), I64.max_value(), "expected max I64")

        h.assert_eq[SqliteDataType](stmt.data_type(5), Sqlite.data_float(), "expected float")
        h.assert_eq[SqliteDataType](stmt.data_type(6), Sqlite.data_float(), "expected float")
        h.assert_eq[F64](stmt.double(5), F64.min_value(), "expected min F64")
        h.assert_eq[F64](stmt.double(6), F64.max_value(), "expected max F64")

        h.assert_eq[SqliteDataType](stmt.data_type(7), Sqlite.data_blob(), "expected blob")
        let blob_recv = stmt.blob(7)
        let blob_expect: Array[U8] = [0xde; 0xad; 0xbe; 0xef]
        h.assert_array_eq[U8](blob_recv, blob_expect, "expected same blob")

        h.assert_eq[SqliteDataType](stmt.data_type(8), Sqlite.data_null(), "expected null")
        h.assert_eq[I32](stmt.int(8), 0, "null coercion to I32")
        h.assert_eq[I64](stmt.int64(8), 0, "null coercion to I64")
        h.assert_eq[F64](stmt.double(8), 0, "null coercion to F64")
        h.assert_eq[String](stmt.text(8), "", "null coercion to text")
        h.assert_array_eq[U8](stmt.blob(8), Array[U8], "null coercion to blob")

        h.assert_eq[SqliteResultCode](stmt.step(), Sqlite.result_done(), "expected no more rows")

        h.assert_eq[SqliteResultCode](stmt.reset(), Sqlite.result_ok(), "expected statement reset")

        h.assert_eq[SqliteResultCode](stmt.close(), Sqlite.result_ok(), "expected statement close")
      end

      h.assert_eq[SqliteResultCode](conn.close(), Sqlite.result_ok(), "expected connection close")
    end
