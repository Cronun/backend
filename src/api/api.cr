require "dotenv"
Dotenv.load

require "kemal"

require "../common/models"
# require "../common/database"

# get "/departments" do
#   Cronun::Database.get_departments.to_json
# end

# get "/subjects" do |env|
#   page = env.params.query["page"]?.try(&.to_i { 1 }) || 1

#   subjects = Cronun::Database.find_subjects(page)
#   subjects.to_json
# end

# get "/subjects/:subject_code/groups" do |env|
#   subject_code = env.params.url["subject_code"].as(String)

#   groups = Cronun::Database.find_groups(subject_code)
#   groups.to_json
# end

# get "/" do
#   {"hi": ":D"}.to_json
# end

Kemal.run
