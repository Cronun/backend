require "dotenv"
Dotenv.load

require "log"
require "option_parser"

n_departments = 1
n_groups : Int32? = 5
period = "202430"

option_parser = OptionParser.parse do |parser|
  parser.banner = "Cronun Scraper"

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  parser.on "-p PERIOD", "--period=PERIOD", "Period. (Default: #{period})" do |v|
    period = v
  end

  parser.on "-d NDEPARTMENTS", "--n-departments=NDEPARTMENTS", "Numer of departments to process (Default: #{n_departments})" do |v|
    n_departments = v.to_i? || 1
  end

  parser.on "-g NGROUPS", "--n-groups=NGROUPS", "Numer of groups to process per department (Default: #{n_groups})" do |v|
    n_groups = v.to_i?
  end

  parser.missing_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is missing something."
    STDERR.puts ""
    STDERR.puts parser
    exit(1)
  end

  parser.invalid_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

Log.info {
  "Using period=#{period} n_departments=#{n_departments} n_groups=#{n_groups}"
}

require "./utils"
require "../common/*"
require "./services/*"
require "./data"

Cronun::Database.create_db_tables

queue = Queue.new

departments = Cronun::Scraper::Data.departments

departments.each do |department|
  Cronun::Database.db.exec(
    "
      insert into departments(code, name) values ($1, $2)
      on conflict(code) do update
        set name = excluded.name
    ",
    department.code,
    department.name
  )
end

departments[...n_departments].each do |department|
  Log.info { department }

  nrcs = Cronun::Scraper::Data.get_nrcs_by_department(department, period)

  Log.info { "Found #{nrcs.size} NRCs for #{department.name}" }

  nrcs.each_with_index do |nrc, index|
    unless n_groups.nil?
      next if index > n_groups.not_nil! - 1
    end

    queue.add do
      Log.info { "Processing NRC=#{nrc}" }
      data = Cronun::Scraper::Data.get_group(nrc, period, department)

      if data.nil?
        Log.info { "Deleting NRC=#{nrc}" }
        Cronun::Database.db.exec("delete from groups where nrc=$1", nrc)
      else
        subject = Cronun::Models::Subject.new(
          name: data[:subject_name],
          code: data[:subject_code],
          department: department,
        )

        Log.debug { "Inserting subject=#{subject}" }

        Cronun::Database.db.exec(
          "
            insert into subjects(code, name, department_code) values ($1, $2, $3)
            on conflict (code) do update
              set name = excluded.name
          ",
          subject.code,
          subject.name,
          department.code
        )

        group = Cronun::Models::Group.new(
          department: department,
          nrc: data[:nrc],
          subject: subject,
          professors: data[:professors],
          schedule: data[:schedule],
          schedule_type: data[:schedule_type],
          group_number: data[:group_number],
          quota_taken: data[:quota_taken],
          quota_free: data[:quota_free],
        )

        Log.debug { "Inserting group=#{group}" }

        Cronun::Database.db.exec(
          "
            insert into groups(
              nrc,
              professors,
              schedule,
              schedule_type,
              group_number,
              quota_taken,
              quota_free,
              subject_code
            )
            values ($1, $2, $3, $4, $5, $6, $7, $8)
            on conflict (nrc) do update
              set professors = excluded.professors,
                  schedule = excluded.schedule,
                  schedule_type = excluded.schedule_type,
                  group_number = excluded.group_number,
                  quota_taken = excluded.quota_taken,
                  quota_free = excluded.quota_free,
                  subject_code = excluded.subject_code
          ",
          group.nrc,
          group.professors,
          group.schedule.to_json,
          group.schedule_type,
          group.group_number,
          group.quota_taken,
          group.quota_free,
          subject.code
        )
      end
    end
  end

  queue.close
end

spawn do
  loop do
    if queue.done? && queue.empty?
      Log.info { "DONE! :D" }
      exit(0)
    end

    sleep(0.5)
  end
end

sleep
