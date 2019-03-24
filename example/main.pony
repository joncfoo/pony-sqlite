use "../sqlite"

actor Main
  let out: OutStream
  new create(env: Env) =>
    out = env.out

    match Sqlite(":memory:")
    | let conn: SqliteConnection =>
      run(conn)
      conn.close()
    | let err: SqliteError =>
      out.print("failed to open database: " + err.string())
    end

  fun run(conn: SqliteConnection) =>
    let stmtCreate = conn.sql("""
      create table users (
        id    integer primary key,
        name  text  not null,
        age   int   not null check (age > 0),
        email text  not null
      )
    """)

    match stmtCreate
    | let err: SqliteError =>
      out.print("failed to create statement: " + err.string())
    | let stmt: SqliteStatement =>
      match stmt.step()
      | Sqlite.result_done() =>
        out.print("created table successfully")
        insert_rows(conn)
      | let other: SqliteResultCode =>
        out.print("unexpected state: " + SqliteError(other).string())
      end

      stmt.close()
    end

  fun insert_rows(conn: SqliteConnection) =>
    let stmtInsert = conn.sql("""
      insert into users
      (name, age, email)
      values
      ("tim", 40, "tim@example.com"),
      ("anika", 20, "anika@example.com"),
      ("anders", 30, "anders@example.com")
    """)

    match stmtInsert
    | let err: SqliteError =>
      out.print("failed to insert data: " + err.string())
    | let stmt: SqliteStatement =>
      match stmt.step()
      | Sqlite.result_done() =>
        out.print("inserted data successfully")
        get_rows(conn)
      | let other: SqliteResultCode =>
        out.print("unexpected state: " + SqliteError(other).string())
      end

      stmt.close()
    end

  fun get_rows(conn: SqliteConnection) =>
    let stmtGet = conn.sql("""
      select id, name, age, email from users
    """)

    match stmtGet
    | let err: SqliteError =>
      out.print("failed to get data: " + err.string())
    | let stmt: SqliteStatement =>
      var result = stmt.step()
      while result == Sqlite.result_row() do
        out.print(
          "id = "+stmt.int64(0).string()
          +", name = "+stmt.text(1)
          +", age ="+stmt.int(2).string()
          +", email = "+stmt.text(3)
        )
        result = stmt.step()
      end

      match result
      | Sqlite.result_done() =>
        out.print("fetched all rows")
      | let other: SqliteResultCode =>
        out.print("unexpected state: " + SqliteError(other).string())
      end

      stmt.close()
    end
