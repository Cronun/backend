require "db"
require "pg"

module Cronun::Database
  Log = ::Log.for(self)

  DATABASE_URI = ENV["DATABASE_URI"]

  Log.info { "Opening database using #{DATABASE_URI}..." }
  DATABASE = DB.open(DATABASE_URI)

  at_exit do
    Log.info { "Closing database..." }
    db.close
  end

  def self.db
    DATABASE
  end

  struct Paginator(T)
    def initialize(@page = 1, @limit = 10, @data = [] of T)
    end

    def to_json
      {:page => @page, :limit => @limit, :data => @data}.to_json
    end
  end

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
        "professors"	JSON NOT NULL,
        "schedule"	JSON NOT NULL,
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

  def self.get_departments
    DATABASE.query_all(
      "select code, name from departments order by code asc",
      as: {code: String, name: String}
    )
  end

  def self.find_subjects(page = 1)
    limit = 10

    page = Math.max(page, 1)
    offset = (page - 1) * limit

    data = DATABASE.query_all(
      "
        select
          subjects.code,
          subjects.name,
          departments.name as department_name,
          departments.code as department_code
        from subjects
        inner join departments on subjects.department_code = departments.code
        limit #{limit}
        offset #{offset}
      ",
      as: {code: String, name: String, department_code: String, department_name: String}
    )

    subjects = data.map { |s| Models::Subject.new(
      s[:code],
      s[:name],
      Models::Department.new(s[:department_name], s[:department_code])
    ) }

    Paginator(Models::Subject).new(page: page, data: subjects)
  end

  def self.find_groups(subject_code : String)
    data = DATABASE.query_all(
      "
        select
          nrc,
          professors,
          schedule,
          schedule_type,
          group_number,
          quota_taken,
          quota_free,
          subjects.code as subjects_code,
          subjects.name as subjects_name,
          departments.name as department_name,
          departments.code as department_code
        from groups
        inner join subjects on groups.subject_code = subjects.code
        inner join departments on subjects.department_code = departments.code
        where groups.subject_code = $1
      ",
      subject_code,
      as: {
        nrc:             String,
        professors:      String,
        schedule:        String,
        schedule_type:   String,
        group_number:    Int32,
        quota_taken:     Int32,
        quota_free:      Int32,
        subjects_code:   String,
        subjects_name:   String,
        department_name: String,
        department_code: String,
      }
    )

    groups = data.map do |d|
      department = Models::Department.new(d[:department_name], d[:department_code])
      subject = Models::Subject.new(d[:subjects_code], d[:subjects_name], department)

      nrc = d[:nrc]
      schedule_type = d[:schedule_type]
      group_number = d[:group_number]
      quota_taken = d[:quota_taken]
      quota_free = d[:quota_free]

      professors = Array(String).from_json(d[:professors])
      schedule = Array(Models::Schedule).from_json(d[:schedule])

      Models::Group.new(
        department,
        nrc,
        subject,
        professors,
        schedule,
        schedule_type,
        group_number,
        quota_taken,
        quota_free
      )
    end

    groups
  end

  def self.get_subject(code : String)
    DATABASE.query_one(
      "
        select code, name, department_code, department_name
        from subjects
        where code = $1
      ",
      code,
      as: {code: String, name: String, department_code: String, department_name: String}
    )
  end
end
