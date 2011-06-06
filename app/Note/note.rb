class Note
  include Rhom::FixedSchema

  property :annotationid, :string
  property :parent_id, :string
  property :parent_type, :string
  property :createdon, :string
  property :notetext, :string
  property :modifiedon, :string
  property :subject, :string
  property :temp_id, :string
  
  set :schema_version, '1.0'
  enable :sync
  set :sync_priority, 50
  
  belongs_to :parent_id, ['Activity', 'Opportunity']
   
  def parent
    if self.parent_type && self.parent_id
      rhodes_parent_type = ['phonecall', 'appointment'].include?(self.parent_type.downcase) ? "Activity" : self.parent_type.capitalize
      parent = Object.const_get(rhodes_parent_type) 
      parent.find(:first, :conditions => {"#{rhodes_parent_type.downcase}id" => self.parent_id})
    end
  end
  
  def opportunity
    parent if parent && parent_type.downcase == "opportunity"
  end
  
  def phone_call
    parent if parent && parent_type.downcase == "phonecall"
  end
  
  def self.find_note(id)
    
    if (id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @note = Note.find(id)
    else
      id.gsub!(/[{}]/,"")
      @note = Note.find_by_sql(%Q{
          select n.* from Note n where temp_id='#{id}'
        }).first
      @note
      end
  end
  
  def self.find_opportunity(id)
    
    if (id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @opportunity = Opportunity.find(id)
    else
      id.gsub!(/[{}]/,"")
      @opportunity = Opportunity.find_by_sql(%Q{
          select o.* from Opportunity o where temp_id='#{id}'
        }).first
      @opportunity
      end
  end
  
  def self.create_new(params)
      puts "*"*80 + " CALLING CREATE!"
      new_note = Note.create(params)
      new_note.update_attributes( :temp_id => new_note.object )
      new_note
  end
  
  def create_note(note_text)
    unless note_text.blank?
      Note.create_new({
        :notetext => note_text, 
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
        :parent_id => self.object,
        :parent_type => 'Opportunity' 
      })
    end
  end
  
  def parent_opportunity
    phone_call ? phone_call.opportunity : opportunity
  end

end
