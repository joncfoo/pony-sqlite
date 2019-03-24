# pony-sqlite

[SQLite](https://sqlite.org/) bindings for [Pony](https://www.ponylang.io/).

# API documentation

API documentation can be found [here](https://joncfoo.github.io/pony-sqlite/docs/sqlite--index/)

# developing

This project uses the Pony docker image for building and testing.

1. build the sqlite library

```bash
make sqlite
```

2. build and test while you edit code

```bash
make watch
```

> Note: this step requires [entr](http://eradman.com/entrproject/) to be
> installed locally
