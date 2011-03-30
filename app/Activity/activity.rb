class Activity
  include Rhom::FixedSchema
  
  property :statecode, :string
  property :activityid, :string
  property :phonenumber, :string
  property :parent_type, :string
  property :cssi_phonetype, :string
  property :subject, :string
  property :cssi_fromrhosync, :string
  property :type, :string
  property :parent_id, :string
  property :scheduledstart, :string
  property :scheduledend, :string
  property :cssi_disposition, :string
  property :statuscode, :string
  property :location, :string
  property :cssi_location, :string
  property :description, :string
  
  index :activity_pk_index, [:activityid]
  unique_index :unique_activity, [:activityid] 
  
  index :activity_parent_index, [:parent_id, :parent_type]
  index :activity_statuscode_index, [:statuscode]
  index :activity_statecode_index, [:statecode]
  
  enable :sync
  set :sync_priority, 2 # this needs to be loaded first so that opportunities can know their context
  
  OPEN_STATE_CODES = ['Open', 'Scheduled']
  
  def parent
    if self.parent_type && self.parent_id
      parent = Object.const_get(self.parent_type.capitalize) 
      puts "PARENT TYPE: #{parent} -- ID: #{parent_id}"
      parent.find(:first, :conditions => {"#{self.parent_type.downcase}id" => self.parent_id})
    end
  end
  
  def opportunity
    parent if parent && parent_type.downcase == "opportunity"
  end
  
  def contact
    parent if parent && parent_type.downcase == "contact"
  end
  
  def open?
    OPEN_STATE_CODES.include?(self.statecode)
  end
  
  def days_past_due
    DateUtil.days_ago(self.scheduledend) 
  end
  
  def activity_type
    if type == "PhoneCall"
      "Phone Call"
    else
      type
    end
  end
  
# end

# class PhoneCall < Activity
  
  def self.todays_follow_ups
    find_by_sql(%Q{
        select a.* from Opportunity o, Activity a
        where a.type='PhoneCall' and 
        a.statecode in ('Open', 'Scheduled') and
        a.parent_type='Opportunity' and a.parent_id=o.object and 
        o.statecode not in ('Won', 'Lost') and
        (date(scheduledend) = date('now', 'localtime'))
        group by o.object order by datetime(a.scheduledend)
      })
  end
  
  def self.past_due_follow_ups
    find_by_sql(%Q{
        select a.* from Opportunity o, Activity a 
        where a.type='PhoneCall' and 
        a.statecode in ('Open', 'Scheduled') and
        a.parent_type='Opportunity' and a.parent_id=o.object and 
        o.statecode not in ('Won', 'Lost') and
        (date(scheduledend) < date('now', 'localtime'))
        group by o.object order by datetime(a.scheduledend)
      })
  end
  
  def self.future_follow_ups
    find_by_sql(%Q{
        select a.* from Opportunity o, Activity a
        where a.type='PhoneCall' and 
        a.statecode in ('Open', 'Scheduled') and
        a.parent_type = 'Opportunity' and a.parent_id=o.object and 
        o.statecode not in ('Won', 'Lost') and
        (date(scheduledend) > date('now', 'localtime'))
        group by o.object order by datetime(a.scheduledend)
      })
  end
  
  def create_note(note_text)
    unless note_text.blank?
      Note.create({
        :notetext => note_text, 
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
        :parent_id => self.object,
        :parent_type => 'phonecall' 
      })
    end
  end
# end

# class Appointment < Activity
  
  def self.open_appointments
    find(:all, :conditions => {'statecode' => 'Scheduled'}).reject{|appointment| appointment.parent.closed? }
  end
  
  def self.past_due_appointments
    open_appointments.select_all_before_today(:scheduledstart).time_sort(:scheduledstart)
  end
  
  def self.future_appointments
    open_appointments.select_all_after_today(:scheduledstart).time_sort(:scheduledstart)
  end
  
  def self.todays_appointments
    open_appointments.select_all_occurring_today(:scheduledstart).time_sort(:scheduledstart)
  end
  
  def complete
    update_attributes({
      :statuscode => 'Completed',
      :statecode => 'Completed'
    })
  end
  
end
