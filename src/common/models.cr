require "json"

module Cronun::Models
  record Department, name : String, code : String do
    include JSON::Serializable
  end

  struct Subject
    include JSON::Serializable

    property name : String
    property code : String
    property department : Department

    def initialize(
      @name : String,
      @code : String,
      @department : Department
    )
    end
  end

  struct Schedule
    include JSON::Serializable

    property date_start : Time
    property date_end : Time
    property place : String
    property day : String
    property professor : String
    property time_start : String?
    property time_end : String?

    def initialize(@date_start, @date_end, @place, @day, @professor, @time_start = nil, @time_end = nil)
    end
  end

  struct Group
    include JSON::Serializable

    property department : Department
    property nrc : String
    property subject : Subject
    property professors : Array(String)
    property schedule : Array(Schedule)
    property schedule_type : String?
    property group_number : String?
    property quota_taken : Int32 = 0
    property quota_free : Int32 = 0

    def initialize(
      @department : Department,
      @nrc : String,
      @subject : Subject,
      @professors = [] of String,
      @schedule = [] of Schedule,
      @schedule_type : String? = nil,
      @group_number : String? = nil,
      @quota_taken = 0,
      @quota_free = 0
    )
    end
  end
end
