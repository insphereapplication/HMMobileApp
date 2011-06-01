module ExceptionUtil
  def self.log_exception_to_server(exception)
    unless exception.kind_of?(Exception)
      exception = new Exception(exception)
    end
    
    ClientException.create({
      :message => exception.message,
      :backtrace => exception.backtrace,
      :exception_id => Time.now.to_i.to_s
    });
  end
end

module SQLHelper
  # SQL snippets to avoid duplication. Use with caution.
  DEFAULT_PAGE_SIZE = 5
  def self.included(model)
    model.extend(ClassMethods)
  end
  
  module ClassMethods
    def get_pagination_sql(page, page_size=DEFAULT_PAGE_SIZE) 
      "limit #{page_size} offset #{page * page_size}" if page
    end
  end
  
  OPEN_STATE_CODES = ['Open', 'Scheduled']
    
  SELECT_OPEN_PHONE_CALL_SQL = %Q{
    select a.* from Opportunity o, Activity a
    where a.type='PhoneCall' and 
    a.statecode in ('Open', 'Scheduled')
  }
  
  OWNED_BY_OPEN_OPPORTUNITY_SQL = %Q{
    a.parent_type='Opportunity' and a.parent_id=o.object and 
    o.statecode not in ('Won', 'Lost')
  }
  
  CLOSED_STATECODES = ['Won', 'Lost']
  
  NO_ACTIVITIES_FOR_OPPORTUNITY_SQL =  %Q{
     not exists (
        select a.object from Activity a 
        where parent_type='Opportunity' and 
        parent_id=o.object
      )
  } 
  
  SELECT_APPOINTMENT_SQL = "select a.* from Activity a, Opportunity o where a.type='Appointment'"
  
  SCHEDULED_END_SQL = "date(scheduledend)"
  SCHEDULED_START_SQL = "date(scheduledstart)"
  CREATED_ON_SQL = "and date(o.createdon)"
  NOW_SQL = "date('now', 'localtime')"
  ORDER_BY_CREATED_ON_DESC_SQL = "order by datetime(o.createdon) desc"
  NEW_OPPORTUNITY_SQL = "select * from Opportunity o where statuscode='New Opportunity' and"
  NEW_OPPORTUNITY_IDS_SQL = %Q{ 
    select o.opportunityid from Opportunity o where statuscode = 'New Opportunity' and
    #{NO_ACTIVITIES_FOR_OPPORTUNITY_SQL}
  }
  
  APPOINTMENT_OPEN_SQL = "a.statecode in ('Open', 'Scheduled')"
    
  SELECT_FIRST_PER_OPPORTUNITY_SQL = "group by o.object order by datetime(a.scheduledend)"
  
  NEW_LEADS_SQL = %Q{
    #{NEW_OPPORTUNITY_SQL}
    #{NO_ACTIVITIES_FOR_OPPORTUNITY_SQL}
  }
end

module DateUtil
  DEFAULT_TIME_FORMAT = '%Y-%m-%d %H:%M:%S' # YYYY-MM-DD HH:MM:SS
  DATE_PICKER_TIME_FORMAT = '%m/%d/%Y %I:%M %p'
  BIRTHDATE_PICKER_TIME_FORMAT = '%m/%d/%Y'
  DEFAULT_BIRTHDATE_FORMAT = '%m/%d/%Y'
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
    
    def days_ago_relative(past_date)
      begin
        diff = (Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i
        if diff == 0
          "Today"
        else
          "Last Act -#{diff}d"
        end
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
      begin
        date = (DateTime.strptime(date_string, DATE_PICKER_TIME_FORMAT))
        date.strftime(DEFAULT_TIME_FORMAT)
      rescue
        puts "Unable to build date"
      end
    end

    def birthdate_build(date_string)
      begin
        date = (DateTime.strptime(date_string, BIRTHDATE_PICKER_TIME_FORMAT))
        date.strftime(DEFAULT_TIME_FORMAT)
      rescue
        puts "Unable to build birthdate"
      end
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
          "#{(Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i}d"
        end
      rescue Exception => e
        puts "Unable to parse days_ago_formatted: #{past_date}: #{e}"
      end
    end
    
    def days_calc_formatted(past_date)
      begin
        if  (Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i == 0
          return "Today"
        else
          "#{(Date.strptime(past_date, DEFAULT_TIME_FORMAT)  - Date.today).to_i}d"
        end
      rescue Exception => e
        puts "Unable to parse days_ago_formatted: #{past_date}: #{e}"
      end
    end
  end
  
end

module Constants
  DEFAULT_POLL_INTERVAL = 60
  BACKGROUND_POLL_INTERVAL = 600
  
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
  
  HEIGHT_FEET = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10"
  ]
  
  HEIGHT_INCHES = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "11",
    "12"
  ]
end