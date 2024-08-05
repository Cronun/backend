require "dotenv"
Dotenv.load

require "kemal"

require "../common/models"
require "../common/database"

get "/departments" do
  Cronun::Database.get_departments.to_json
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
  Log.info { subject }

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

get "/" do
  {"hi": ":D"}.to_json
end

Kemal.run
