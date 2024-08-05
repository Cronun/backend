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
        "name" TEXT COLLATE "unicode" NOT NULL,
        "code" TEXT COLLATE "unicode" NOT NULL,
        CONSTRAINT departments_pk PRIMARY KEY ("code")
      );
    SQL

    DATABASE.exec <<-SQL
      CREATE TABLE IF NOT EXISTS "subjects" (
        "name" TEXT COLLATE "unicode" NOT NULL,
        "code" TEXT COLLATE "unicode" UNIQUE,
        "department_code"	TEXT NOT NULL,
        PRIMARY KEY("code"),
        FOREIGN KEY("department_code") REFERENCES "departments"("code")
      );
    SQL

    DATABASE.exec <<-SQL
      CREATE TABLE IF NOT EXISTS "groups" (
        "nrc" TEXT COLLATE "unicode" NOT NULL,
        "professors" TEXT[] COLLATE "unicode" NOT NULL,
        "schedule" JSON NOT NULL,
        "schedule_type" TEXT COLLATE "unicode" NOT NULL,
        "group_number" INTEGER NOT NULL,
        "quota_taken" INTEGER NOT NULL,
        "quota_free" INTEGER NOT NULL,
        "subject_code" TEXT NOT NULL,
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

  def self.find_subjects(*, page : (Int32 | String)? = 1, name : String? = nil, department : String? = nil)
    parsed_page : Int32 = begin
      case page
      when .nil?
        1
      when String
        page.to_i { 1 }
      else
        page
      end
    end

    parsed_page = Math.max(parsed_page, 1)

    limit = 10
    offset = (parsed_page - 1) * limit

    args = [] of String
    conditions = [] of String

    unless department.nil?
      conditions << "(departments.code ilike '%#{department}%' or departments.name ilike '%#{department}%')"
    end

    unless name.nil?
      conditions << "(subjects.name ilike '%#{name}%' or  subjects.code ilike '%#{name}%')"
    end

    conditions_str = conditions.size > 0 ? "where " + conditions.join(" and ") : ""

    query = "
        select
          subjects.code,
          subjects.name,
          departments.name as department_name,
          departments.code as department_code
        from subjects
        inner join departments on subjects.department_code = departments.code #{conditions_str}
        limit $1
        offset $2
      "

    data = DATABASE.query_all(
      query,
      limit, offset,
      as: {code: String, name: String, department_name: String, department_code: String}
    )

    subjects = data.map { |s|
      Models::Subject.new(
        code: s[:code],
        name: s[:name],
        department: Models::Department.new(s[:department_name], s[:department_code])
      )
    }

    Paginator(Models::Subject).new(page: parsed_page, data: subjects)
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
        professors:      JSON::PullParser,
        schedule:        JSON::PullParser,
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
      department = Models::Department.new(name: d[:department_name], code: d[:department_code])
      subject = Models::Subject.new(code: d[:subjects_code], name: d[:subjects_name], department: department)

      nrc = d[:nrc]
      schedule_type = d[:schedule_type]
      group_number = d[:group_number]
      quota_taken = d[:quota_taken]
      quota_free = d[:quota_free]

      professors = Array(String).new(d[:professors])
      schedule = Array(Models::Schedule).new(d[:schedule])

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
    result = DATABASE.query_one?(
      "
        select
          subjects.code,
          subjects.name,
          departments.code as department_code,
          departments.name as department_name
        from subjects
        inner join departments on departments.code = subjects.department_code
        where subjects.code = $1
      ",
      code,
      as: {code: String, name: String, department_code: String, department_name: String}
    )

    result.try { |d|
      department = Models::Department.new(code: d[:department_code], name: d[:department_name])
      Models::Subject.new(code: d[:code], name: d[:name], department: department)
    }
  end
end
