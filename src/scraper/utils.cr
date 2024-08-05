module Cronun::Scraper::Utils
  protected def self.fix_ñ(str : String?) : String?
    str.try do |v|
      if v.matches?(/[AEIOU]\?/)
        v.gsub("?", "Ñ")
      elsif v.matches?(/[aeiou]\?/)
        v.gsub("?", "ñ")
      else
        v
      end
    end
  end

  protected def self.parse_date(str : String?) : Time?
    str.try { |v|
      begin
        Time.parse_local(v, "%d-%b-%y")
      rescue exception
        Log.error { exception }
      end
    }
  end

  private def self.parse_time_range(str : String?) : {String, String}?
    str.try { |v|
      parts = v.split(" - ")

      if parts.size == 2
        {parts[0], parts[1]}
      end
    }
  end
end
