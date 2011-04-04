class Activity
  include Rhom::FixedSchema
  include SQLHelper
  
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
  property :cssi_dispositiondetail, :string
  
  index :activity_pk_index, [:activityid]
  unique_index :unique_activity, [:activityid] 
  
  index :activity_parent_index, [:parent_id, :parent_type]
  index :activity_statuscode_index, [:statuscode]
  index :activity_statecode_index, [:statecode]
  
  enable :sync
  set :sync_priority, 2 # this needs to be loaded before opportunities so that opportunities can know their context
  
  OPEN_STATE_CODES = ['Open', 'Scheduled']
  
  def parent
    if self.parent_type && self.parent_id
      parent = Object.const_get(self.parent_type.capitalize) 
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
  
  def self.todays_follow_ups(page=nil, page_size=DEFAULT_PAGE_SIZE) 
    find_by_sql(%Q{
        #{SELECT_OPEN_PHONE_CALL_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_END_SQL} = #{NOW_SQL}
        #{SELECT_FIRST_PER_OPPORTUNITY_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def self.past_due_follow_ups(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
        #{SELECT_OPEN_PHONE_CALL_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_END_SQL} < #{NOW_SQL}
        #{SELECT_FIRST_PER_OPPORTUNITY_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def self.future_follow_ups(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
        #{SELECT_OPEN_PHONE_CALL_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_END_SQL} > #{NOW_SQL}
        #{SELECT_FIRST_PER_OPPORTUNITY_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def create_note(note_text)
    unless note_text.blank?
      Note.create({
        :notetext => note_text, 
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
        :parent_id => self.object,
        :parent_type => 'PhoneCall' 
      })
    end
  end
# end

# class Appointment < Activity
  
  def self.open_appointments(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
        select a.* from Activity a, Opportunity o where type='Appointment' and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def self.past_due_appointments(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
        #{SELECT_APPOINTMENT_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_START_SQL} > #{NOW_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def self.future_appointments(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
        #{SELECT_APPOINTMENT_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_START_SQL} < #{NOW_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def self.todays_appointments(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
        #{SELECT_APPOINTMENT_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_START_SQL} = #{NOW_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def complete
    update_attributes({
      :statuscode => 'Completed',
      :statecode => 'Completed'
    })
  end
  
end
