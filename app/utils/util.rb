module DateUtil
  class << self    
    def days_ago(past_date)
      begin
        (Date.today - Date.strptime(past_date, "%m/%d/%Y")).to_i
      rescue
        puts "Unable to parse date: #{}; no age returned"
      end
    end
    
    def date_build(date_string)
      date = (DateTime.strptime(date_string, '%m/%d/%Y %I:%M %p'))
      result = date.strftime('%Y/%m/%d %H:%M')
      result
    end

    def end_date_time(date_string, duration)
      date = (DateTime.strptime(date_string, '%m/%d/%Y %I:%M %p'))
      end_date = date + ((duration.to_f)/60/24)
      end_date.strftime('%m/%d/%Y %H:%M')
    end
  
    def days_from_now(future_date)
      begin
        (Date.strptime(future_date, "%m/%d/%Y") - Date.today).to_i
      rescue
        puts "Unable to parse date: #{}; no age returned"
      end
    end
  
    def days_ago_formatted(past_date)
      begin
        if (Date.today - Date.strptime(past_date, "%m/%d/%Y")).to_i == 0
          return "Today"
        else
          return (Date.today - Date.strptime(past_date, "%m/%d/%Y")).to_i + "d"
        end
      rescue
        puts "Unable to parse date: #{}; no age returned"
      end
    end
  end
end

module Constants
  OTHER_LOST_REASONS = [
    "Covered By Competitor",
    "Wrong Number",
    "No Answer",
    "Disconnected Phone",
    "Deceased",
    "Cost",
    "Insufficient Coverage",
    "Other",
    "Insurance Not Desired",
    "Uninsurable",
    "Group Insurance",
    "Under Age",
    "Over Age",
    "Medicaid",
    "Never Inquired",
    "Does Not Speak English",
    "Working With Agent",
    "Covered By Spouse"
  ]
  
  COMPETITORS = [
    "Aetna",
    "AIG",
    "Allianz",
    "Assurant",
    "Berkshire Life",
    "Blue Cross / Blue Shield",
    "Cigna",
    "Genworth",
    "Golden Rule",
    "Guardian",
    "Humana",
    "Kaiser",
    "Lafayette Life",
    "Lincoln",
    "MassMutual",
    "Met Life",
    "National Health",
    "NewYork Life",
    "Principle",
    "Prudential",
    "The Hartford",
    "Transamerica",
    "United Health Care",
    "Unknown",
    "Unum",
    "VantisLife"
  ]
end