module Cronun::Scraper::Data
  def self.get_group(nrc : String, period : String, department : Models::Department)
    body = Services::Http.acreditaciones_resultado(nrc: nrc, period: period)
    html = parse_html(body)

    subject_name = subject_name(html)
    if subject_name.nil? || subject_name.empty?
      Log.error { "No subject name found" }
      return
    end

    subject_data = self.parse_subject_data(html)
    if subject_data.nil?
      Log.error { "No subject data found" }
      return
    end

    schedule_type = html
      .xpath_node("//*[@id=\"acreditaciones_resultado\"]/div/div/p[3]")
      .try &.text.upcase.gsub(/MODALIDAD\s*:/, "").strip

    if schedule_type.nil?
      Log.error { "No schedule type found" }
      return
    end

    quota = self.parse_quota(html)
    if quota.nil?
      Log.error { "No quota found" }
      return
    end

    schedule = parse_schedule(html)
    professors = schedule.map(&.professor).uniq

    subject_code, group_number, _ = subject_data

    {
      subject_name:  subject_name,
      subject_code:  subject_code,
      group_number:  group_number,
      nrc:           nrc,
      schedule_type: schedule_type,
      quota_taken:   quota[0],
      quota_free:    quota[1],
      professors:    professors.to_a,
      schedule:      schedule,
    }
  end

  private def self.subject_name(html) : String?
    html
      .xpath_node("//*[@id=\"acreditaciones_resultado\"]/div/div/p[1]")
      .try &.text.strip.upcase
  end

  private def self.parse_subject_data(html) : {String, String, String}?
    node = html.xpath_node("//*[@id=\"acreditaciones_resultado\"]/div/div/p[2]")

    if node
      regex = /MATERIA: ([\w\s]+) GRUPO: (\d+) NRC: (\d+)/im
      str = node.text.strip.gsub(/[\s\t]+/, " ").upcase

      if matches = str.match(regex)
        if matches.size == 4
          return {matches[1], matches[2], matches[3]}
        end
      end
    end
  end

  private def self.parse_quota(html) : {Int32, Int32}?
    node = html.xpath_node("//*[@id=\"acreditaciones_resultado\"]/div/div/p[4]")

    if node
      regex = /Matriculados: (\d+) Cupos Disponibles Totales: (\d+)/i
      str = node.text.gsub(/[\n\t\s]+/, " ")

      if matches = str.match(regex)
        if matches.size == 3
          {matches[1].to_i, matches[2].to_i}
        end
      end
    end
  end

  private def self.parse_schedule(html) : Array(Models::Schedule)
    schedule = html
      .xpath_nodes("//tr").to_a[1..]
      .map do |tr|
        tds = tr.children
          .map(&.text.strip.upcase)
          .reject(&.empty?)

        date_start = Utils.parse_date(tds[0]?)
        date_end = Utils.parse_date(tds[1]?)
        professor = tds[2]?.try(&.strip.upcase)

        day = tds[3]?
        place = tds[5]?
        time_start, time_end = tds[4]?.try(&.split(" - ")) || {nil, nil}

        next unless (
                      date_start && date_end &&
                      professor &&
                      day && place &&
                      time_start && time_end
                    )

        Models::Schedule.new(
          date_start: date_start,
          date_end: date_end,
          place: place,
          day: day,
          time_start: time_start,
          time_end: time_end,
          professor: professor
        )
      end

    schedule.reject(&.nil?).map(&.not_nil!)
  end
end
