require "dotenv"
Dotenv.load

require "kemal"

require "../common/models"
require "../common/database"

before_all do |env|
  env.response.content_type = "application/json"
end

get "/departments" do
  departments = Cronun::Database.get_departments
  departments.to_json
end

get "/subjects" do |env|
  page = env.params.query["page"]?
  name = env.params.query["name"]?
  department = env.params.query["department"]?

  subjects = Cronun::Database.find_subjects(department: department, name: name, page: page)
  subjects.to_json
end

get "/subjects/:subject_code" do |env|
  subject_code = env.params.url["subject_code"].as(String)
  subject = Cronun::Database.get_subject(subject_code)

  if subject.nil?
    halt(env, status_code: 404, response: "Not Found")
  else
    subject.to_json
  end
end

get "/subjects/:subject_code/groups" do |env|
  subject_code = env.params.url["subject_code"].as(String)

  groups = Cronun::Database.find_groups(subject_code)
  groups.to_json
end

def get_total(key : String, table : String) : Int64
  Cronun::Database.db.scalar("select count(#{key}) from #{table}").as(Int64)
end

get "/" do
  {
    "departments" => get_total("code", "departments"),
    "subjects"    => get_total("code", "subjects"),
    "groups"      => get_total("nrc", "groups"),
  }.to_json
end

Kemal.run
