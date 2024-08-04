require "http/client"

module Cronun::Scraper::Services::Http
  GUAYACAN_BASE_URL = "https://guayacan02.uninorte.edu.co/4PL1CACI0N35/registro"

  def self.call_guayacan(path : String, form) : String
    response = HTTP::Client.post([GUAYACAN_BASE_URL, path].join("/"), form: form)
    response.body
  end

  def self.programas(department : String, period : String, level = "PR") : String?
    Log.info { "programas department=#{department} level=#{level} period=#{period}" }

    call_guayacan("/programas.php", {
      "elegido" => department,
      "nivel"   => level,
      "periodo" => period,
    })
  end

  def self.acreditaciones_resultado(nrc : String, period : String) : String?
    Log.info { "acreditaciones_resultado nrc=#{nrc} period=#{period}" }

    call_guayacan("/acreditaciones_resultado.php", {
      "elegido" => nrc,
      "periodo" => period,
    })
  end
end
