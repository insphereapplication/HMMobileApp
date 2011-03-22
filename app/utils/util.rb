module DateUtil
  class << self    
    def days_ago(past_date)
      begin
        (Date.today - Date.strptime(past_date, "%m/%d/%Y")).to_i
      rescue
        puts "Unable to parse date: #{}; no age returned"
      end
    end
    
    def seconds_until_hour(input_time)
      begin
        (60 - input_time.min)*60
      rescue
        puts "unable to calculate seconds until hour for time #{input_time}"
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
        if  (Date.today - Date.strptime(past_date, "%m/%d/%Y")).to_i == 0
          return "Today"
        else
          ((Date.today - Date.strptime(past_date, "%m/%d/%Y")).to_i + "d")
        end
      rescue
        puts "Unable to parse date: #{past_date}; no age returned"
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
  
  STATE_CODES = [
    ["AL", "Alabama"],
		["AK","Alaska"],
		["AZ","Arizona"],
		["AR","Arkansas"],
		["BC","British Columbia"],
		["CA","California"],
		["CO","Colorado"],
		["CT","Connecticut"],
		["DC","District of Columbia"],
		["DE","Delaware"],
		["FL","Florida"],
		["GA","Georgia"],
		["HI","Hawaii"],
		["ID","Idaho"],
		["IL","Illinois"],
		["IN","Indiana"],
		["IA","Iowa"],
		["KS","Kansas"],
		["KY","Kentucky"],
		["LA","Louisiana"],
		["ME","Maine"],
		["MD","Maryland"],
		["MA","Massachusetts"],
		["MI","Michigan"],
		["MN","Minnesota"],
		["MS","Mississippi"],
		["MO","Missouri"],
		["MT","Montana"],
		["NE","Nebraska"],
		["NV","Nevada"],
		["NH","New Hampshire"],
		["NJ","New Jersey"],
		["NM","New Mexico"],
		["NY","New York"],
		["NC","North Carolina"],
		["ND","North Dakota"],
		["OH","Ohio"],
		["OK","Oklahoma"],
		["ON","Ontario"],
		["OR","Oregon"],
		["PA","Pennsylvania"],
		["QC","Quebec"],
		["RI","Rhode Island"],
		["SC","South Carolina"],
		["SD","South Dakota"],
		["TN","Tennessee"],
		["TX","Texas"],
		["UT","Utah"],
		["VT","Vermont"],
		["VA","Virginia"],
		["WA","Washington"],
		["WV","West Virginia"],
		["WI","Wisconsin"],
		["WY","Wyoming"]
  ]
end