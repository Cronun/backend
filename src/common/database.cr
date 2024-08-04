require "sqlite3"

module Cronun
  Log = ::Log.for(self)

  DATABASE_PATH = "sqlite3://src/data/database.db"
  DATABASE      = DB.open(DATABASE_PATH)

  def self.create_db_tables
    Log.info { "Creating DB tables..." }

    DATABASE.exec <<-SQL
      CREATE TABLE IF NOT EXISTS "departments" (
        "name"	TEXT NOT NULL,
        "code"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("code")
      );
    SQL

    DATABASE.exec <<-SQL
      CREATE TABLE IF NOT EXISTS "subjects" (
        "name"	TEXT NOT NULL,
        "code"	TEXT UNIQUE,
        "department_code"	TEXT NOT NULL,
        PRIMARY KEY("code"),
        FOREIGN KEY("department_code") REFERENCES "departments"("code")
      );
    SQL

    DATABASE.exec <<-SQL
      CREATE TABLE IF NOT EXISTS "groups" (
        "nrc"	TEXT NOT NULL,
        "professors"	BLOB NOT NULL,
        "schedule"	BLOB NOT NULL,
        "schedule_type"	TEXT NOT NULL,
        "group_number"	INTEGER NOT NULL,
        "quota_taken"	INTEGER NOT NULL,
        "quota_free"	INTEGER NOT NULL,
        "subject_code"	TEXT NOT NULL,
        PRIMARY KEY("nrc"),
        FOREIGN KEY("subject_code") REFERENCES "subjects"("code")
      );
    SQL
  end
end
