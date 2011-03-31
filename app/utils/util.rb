module DateUtil
  DEFAULT_TIME_FORMAT = '%Y-%m-%d %H:%M:%S' # YYYY-MM-DD HH:MM:SS
  DATE_PICKER_TIME_FORMAT = '%m/%d/%Y %I:%M %p'
  HOUR_FORMAT = '%I:%M %p'
  NO_YEAR_FORMAT = '%m/%d %I:%M %p'
  
  class << self    
    def offset
      Time.now.utc_offset
    end
    
    def days_ago(past_date)
      begin
        (Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i
      rescue Exception => e
        puts "Unable to parse days_ago: #{past_date}: #{e}"
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
      date = (DateTime.strptime(date_string, DATE_PICKER_TIME_FORMAT))
      date.strftime(DEFAULT_TIME_FORMAT)
    end

    def end_date_time(date_string, duration)
      date = (Time.strptime(date_string, DATE_PICKER_TIME_FORMAT))
      end_date = date + (((duration.to_f)*60))
      end_date.strftime(DEFAULT_TIME_FORMAT)
    end
  
    def days_from_now(future_date)
      begin
        (Date.strptime(future_date, DEFAULT_TIME_FORMAT) - Date.today).to_i
      rescue Exception => e
        puts "Unable to process days_from_now: #{future_date}: #{e}"
      end
    end
  
    def days_ago_formatted(past_date)
      begin
        if  (Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i == 0
          return "Today"
        else
          "#{(Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i} d"
        end
      rescue Exception => e
        puts "Unable to parse days_ago_formatted: #{past_date}: #{e}"
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
    ["AL", "AL"],
		["AK","AK"],
		["AZ","AZ"],
		["AR","AR"],
		["BC","BC"],
		["CA","CA"],
		["CO","CO"],
		["CT","CT"],
		["DC","DC"],
		["DE","DE"],
		["FL","FL"],
		["GA","GA"],
		["HI","HI"],
		["ID","ID"],
		["IL","IL"],
		["IN","IN"],
		["IA","IA"],
		["KS","KS"],
		["KY","KY"],
		["LA","LA"],
		["ME","ME"],
		["MD","MD"],
		["MA","MA"],
		["MI","MI"],
		["MN","MN"],
		["MS","MS"],
		["MO","MO"],
		["MT","MT"],
		["NE","NE"],
		["NV","NV"],
		["NH","NH"],
		["NJ","NJ"],
		["NM","NM"],
		["NY","NY"],
		["NC","NC"],
		["ND","ND"],
		["OH","OH"],
		["OK","OK"],
		["ON","ON"],
		["OR","OR"],
		["PA","PA"],
		["QC","QC"],
		["RI","RI"],
		["SC","SC"],
		["SD","SD"],
		["TN","TN"],
		["TX","TX"],
		["UT","UT"],
		["VT","VT"],
		["VA","VA"],
		["WA","WA"],
		["WV","WV"],
		["WI","WI"],
		["WY","WY"]
  ]
end