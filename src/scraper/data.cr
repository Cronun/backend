require "xml"

require "./data/departments"
require "./data/groups"

module Cronun::Scraper::Data
  Log = ::Log.for(self)

  protected def self.parse_html(body : String)
    XML.parse_html(body)
  end
end
