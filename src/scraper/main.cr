require "log"

require "./utils"
require "../common/*"
require "./services/*"
require "./data"

Cronun::Database.create_db_tables

queue = Queue.new

PERIOD = "202430"

N_DEPARTMENTS = 1
N_NRCS        = 5

departments = Cronun::Scraper::Data.departments

departments.each do |department|
  Cronun::DATABASE.exec(
    "insert or replace into departments(code, name) values (?, ?)",
    department.code,
    department.name
  )
end

departments[...N_DEPARTMENTS].each do |department|
  nrcs = Cronun::Scraper::Data.get_nrcs_by_department(department, PERIOD)

  Log.info { "Found #{nrcs.size} NRCs for #{department.name}" }

  nrcs[...N_NRCS].each_with_index do |nrc, index|
    queue.add do
      Log.info { "Processing NRC=#{nrc}" }
      data = Cronun::Scraper::Data.get_group(nrc, PERIOD, department)

      if data.nil?
        Log.info { "Deleting NRC=#{nrc}" }
        Cronun::DATABASE.exec("delete from groups where nrc=?", nrc)
      else
        subject = Cronun::Models::Subject.new(
          name: data[:subject_name],
          code: data[:subject_code],
          department: department,
        )

        Log.info { "Inserting subject=#{subject}" }

        Cronun::DATABASE.exec(
          "insert or replace into subjects(code, name, department_code) values (?, ?, ?)",
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

        Log.info { "Inserting group=#{group}" }

        Cronun::DATABASE.exec(
          "insert or replace into groups(
          nrc,
          professors,
          schedule,
          schedule_type,
          group_number,
          quota_taken,
          quota_free,
          subject_code
        )
        values (?, ?, ?, ?, ?, ?, ?, ?)",
          group.nrc,
          group.professors.to_json,
          group.schedule.to_json,
          group.schedule_type,
          group.group_number,
          group.quota_taken,
          group.quota_free,
          subject.code
        )
      end

      if index == N_NRCS - 1
        Log.info { "DONE! :D" }
        exit(0)
      end
    end
  end
end

sleep
