#!/usr/bin/env bash

set -euo pipefail

# Calling this something other than TOP because idk if it will mess something up
# by having an env var named TOP. It serves the same purpose and should have the
# same value (minus the relative part), but just in case! And apprently now I am
# using this THE_BLAH syntax for locations lol.
THE_TOP="${HOME}/PersonalCode/sqlite/sqlite"
THE_BLD="${HOME}/PersonalCode/sqlite/bld"
THE_SQLITE_JDBC="${HOME}/PersonalCode/sqlite-jdbc"

# From sqlite-jdbc's Makefile
export CFLAGS=""
# export CFLAGS+=" -DSQLITE_ENABLE_LOAD_EXTENSION=1"
# export CFLAGS+=" -DSQLITE_HAVE_ISNAN"
# export CFLAGS+=" -DHAVE_USLEEP=1"
export CFLAGS+=" -DSQLITE_ENABLE_COLUMN_METADATA" # Enabled because _sqlite3_column_table_name
# export CFLAGS+=" -DSQLITE_CORE"
# export CFLAGS+=" -DSQLITE_ENABLE_FTS3"
# export CFLAGS+=" -DSQLITE_ENABLE_FTS3_PARENTHESIS"
# export CFLAGS+=" -DSQLITE_ENABLE_FTS5"
# export CFLAGS+=" -DSQLITE_ENABLE_RTREE"
# export CFLAGS+=" -DSQLITE_ENABLE_STAT4"
# export CFLAGS+=" -DSQLITE_ENABLE_DBSTAT_VTAB"
# export CFLAGS+=" -DSQLITE_ENABLE_MATH_FUNCTIONS"
# export CFLAGS+=" -DSQLITE_THREADSAFE=1"
# export CFLAGS+=" -DSQLITE_DEFAULT_MEMSTATUS=0"
# export CFLAGS+=" -DSQLITE_DEFAULT_FILE_PERMISSIONS=0666"
# export CFLAGS+=" -DSQLITE_MAX_VARIABLE_NUMBER=250000"
# export CFLAGS+=" -DSQLITE_MAX_MMAP_SIZE=1099511627776"
# export CFLAGS+=" -DSQLITE_MAX_LENGTH=2147483647"
# export CFLAGS+=" -DSQLITE_MAX_COLUMN=32767"
# export CFLAGS+=" -DSQLITE_MAX_SQL_LENGTH=1073741824"
# export CFLAGS+=" -DSQLITE_MAX_FUNCTION_ARG=127"
# export CFLAGS+=" -DSQLITE_MAX_ATTACHED=125"
# export CFLAGS+=" -DSQLITE_MAX_PAGE_COUNT=4294967294"
# export CFLAGS+=" -DSQLITE_DISABLE_PAGECACHE_OVERFLOW_STATS"

# COMPILE SQLITE
cd ${THE_BLD} # Into sqlite build zone
make clean || true
${THE_TOP}/configure
make

# COMPILE AND TEST SQLITE-JDBC
cd ${THE_SQLITE_JDBC} # Back into sqlite-jdbc
git restore src/main/resources/org/sqlite/native/Mac/aarch64/libsqlitejdbc.dylib
make clean
mvn -T 1C clean
make native SQLITE_OBJ=${THE_BLD}/sqlite3.o SQLITE_HEADER=${THE_BLD}/sqlite3.h
mvn -T 1C verify

# TEST SQLITE
cd ${THE_BLD} # Into sqlite build zone
make devtest
# make devtest does not use a non-zero exit code when there are failures
number_of_failures="$(sqlite3 ${THE_BLD}/testrunner.db "SELECT count(*) FROM jobs WHERE state = 'failed';")"
if [[ "${number_of_failures}" != 0 ]]; then
    echo "FAILURES:"
    sqlite3 ${THE_BLD}/testrunner.db "SELECT displayname FROM jobs WHERE state = 'failed';"
    exit 1
fi
