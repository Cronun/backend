require "json"

module Cronun::Scraper::Data
  DEPARTMENTS_JSON_PATH = Path["src/data/departments.json"]

  def self.departments : Array(Models::Department)
    Log.info { "Reading departments from #{DEPARTMENTS_JSON_PATH}" }
    Array(Models::Department).from_json(File.open(DEPARTMENTS_JSON_PATH))
  end

  def self.get_nrcs_by_department(department : Models::Department, period : String) : Array(String)
    body = Services::Http.programas(department: department.code, period: period)
    html = parse_html(body)

    nrcs = html
      .xpath_nodes("//option[not(@disabled=\"disabled\")]")
      .map { |n| n["value"] }
      .to_set
      .to_a

    nrcs
  end
end
