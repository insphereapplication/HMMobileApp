module ExceptionUtil
  def self.log_exception_to_server(exception, type=nil)
    #Changing the error type if criterea below is met since these are actually handled gracefully
    type="E501" if !exception.backtrace.blank? && exception.backtrace.index("lib/rho/render.rb:169:in `eval_compiled_file'") == 1 and exception.backtrace.index("lib/rho/render.rb:169:in `render'") == 2
    
    unless exception.kind_of?(Exception)
      exception = new Exception(exception)
    end
    message = exception.message  ? exception.message[0,2000] : ""
    backtrace = exception.backtrace ? exception.backtrace[0,2000] : ""
    exception_data = {
      :message => message,
      :backtrace => backtrace,
      :exception_id => Time.now.to_f.to_s.gsub(/\./,''),
      :client_created_on => Time.now.utc.to_s,
      :exception_type => type
    }
    
    begin
      exception_data.merge!({
        :device_id => System.get_property('phone_id'),
        :rho_device_id => Rhom::Rhom::client_id, 
        :client_platform => System.get_property('platform'),
        :has_network => System.get_property('has_network'),
        :device_name => System.get_property('device_name'),
        :os_version => System.get_property('os_version')
      })
    rescue
      exception_data.merge!({:device_data_error => "Error while extracting device-specific data."})
    end
    
    puts exception_data.inspect
    
    ClientException.create(exception_data)
  end
end

module SQLHelper
  # SQL snippets to avoid duplication. Use with caution.
  DEFAULT_PAGE_SIZE = 20
  CONTACT_DEFAULT_PAGE_SIZE = 100
  def self.included(model)
    model.extend(ClassMethods)
  end
  
  module ClassMethods
    def get_pagination_sql(page, page_size=DEFAULT_PAGE_SIZE) 
      "limit #{page_size} offset #{page.to_i * page_size.to_i}" if page
    end

    def new_leads_sql
      %Q{
        select *
        from Opportunity o
        where o.ownerid = '#{StaticEntity.system_user_id}'
            and o.statuscode='New Opportunity'
            and not exists (select a.object from Activity a
                            where parent_type='Opportunity'
                                and parent_id=o.object
                                and a.type in ('PhoneCall','Appointment'))
      }
    end
  end
  
  SELECT_EMAILS_SQL = %Q{
    select a.* from Opportunity o, Activity a
    where a.type='Email' 
  }
  
  LATEST_INTEGRATED_LEAD = %Q{
    SELECT createdon
    FROM Opportunity
    WHERE cssi_inputsource='Integrated'
    ORDER BY createdon DESC
    LIMIT 1
  }
  
  LATEST_ASSIGNED_LEAD = %Q{
    SELECT cssi_assigneddate, createdon, cssi_assetownerid, ownerid
    FROM Opportunity
    ORDER BY cssi_assigneddate DESC
    LIMIT 1
  }
  
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
  
  # SQL building blocks for the Scheduled tab on the Opportunities page
  SELECT_SCHEDULED_SQL = "select CASE
  WHEN a.scheduledstart IS NULL THEN a.scheduledend
  WHEN a.scheduledstart = '' THEN a.scheduledend
  ELSE a.scheduledstart
  END as scheduledtime, a.* from Activity a, Opportunity o where (a.type='Appointment' or a.type='PhoneCall')"
  
  SELECT_SCHEDULED_NO_WHERE_SQL = "select CASE
  WHEN a.scheduledstart IS NULL THEN a.scheduledend
  WHEN a.scheduledstart = '' THEN a.scheduledend
  ELSE a.scheduledstart
  END as scheduledtime, a.*, c.firstname, c.lastname from Activity a, Opportunity o, Contact c"
  
  SCHEDULED_END_SQL = "date(scheduledend)"
  SCHEDULED_START_SQL = "date(scheduledstart)"
  SCHEDULED_TIME_SQL = "date(scheduledtime)"
  SCHEDULED_OPEN_SQL = "a.statecode in ('Open', 'Scheduled')"
  SCHEDULED_ORDERBY_SQL = "order by datetime(scheduledtime)"
  
  CREATED_ON_SQL = "and date(o.createdon)"
  NOW_SQL = "date('now', 'localtime')"
  ORDER_BY_CREATED_ON_DESC_SQL = "order by datetime(o.createdon) desc"
  
  SELECT_FIRST_PER_OPPORTUNITY_SQL = "group by o.object order by datetime(a.scheduledend)"
end

module DateUtil
  DEFAULT_TIME_FORMAT = '%Y-%m-%d %H:%M:%S' # YYYY-MM-DD HH:MM:SS
  DATE_PICKER_TIME_FORMAT = '%m/%d/%Y %I:%M %p'
  BIRTHDATE_PICKER_TIME_FORMAT = '%m/%d/%Y'
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
  PIN_EXPIRE_SECONDS = 900

  
  TAB_INDEX = {
    "Opportunities" => 0,
    "Contacts" => 1,
    "Activities" => 2,
    "Tools" => 3        
  }
  
  OTHER_LOST_REASONS = [
    ["Not Interested","Insurance Not Desired"],
    ["Wrong Number/Disconnected",'Wrong Number'],
    ["Covered By Competitor","Covered By Competitor"],
    ["Wrong Number","Wrong Number"],
    ["No Answer","No Answer"],
    ["Disconnected Phone","Disconnected Phone"],
    ["Deceased","Deceased"],
    ["Cost","Cost"],
    ["Insufficient Coverage","Insufficient Coverage"],
    ["Other","Other"],
    ["Insurance Not Desired","Insurance Not Desired"],
    ["Uninsurable","Uninsurable"],
    ["Group Insurance","Group Insurance"],
    ["Under Age","Under Age"],
    ["Over Age","Over Age"],
    ["Medicaid","Medicaid"],
    ["Never Inquired","Never Inquired"],
    ["Does Not Speak English","Does Not Speak English"],
    ["Working With Agent","Working With Agent"],
    ["Covered By Spouse","Covered By Spouse"]
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
    "11"
  ]
  
  PERSISTED_CONTACT_FILTER_PREFIX = 'contact_'
  CONTACT_FILTERS = [
    {:name => 'filter', :default_value => 'All'},
    {:name => 'search_terms', :default_value => ''}
  ]
  
  PERSISTED_FOLLOWUP_FILTER_PREFIX = 'followup_'
  FOLLOWUP_FILTERS = [
    {:name => 'statusReason', :default_value => 'All'},
    {:name => 'sortBy', :default_value => 'LastActivityDateAscending'},
    {:name => 'created', :default_value => 'All'},
    {:name => 'isDaily', :default_value => 'false'}
  ]
  
  PERSISTED_SCHEDULED_FILTER_PREFIX = 'scheduled_'
  SCHEDULED_FILTERS = [
    {:name => 'filter', :default_value => 'All'},
    {:name => 'search', :default_value => ''}
  ]
end