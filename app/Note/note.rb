class Note
  include Rhom::FixedSchema

  property :annotationid, :string
  property :parent_id, :string
  property :parent_type, :string
  property :createdon, :string
  property :notetext, :string
  property :modifiedon, :string
  property :subject, :string
  
  enable :sync
  set :sync_priority, 5
  
  belongs_to :parent_id, ['Activity', 'Opportunity']
   
  def parent
    if self.parent_type && self.parent_id
      parent = Object.const_get(self.parent_type.capitalize) 
      parent.find(:first, :conditions => {"#{self.parent_type.downcase}id" => self.parent_id})
    end
  end
  
  def opportunity
    parent if parent && parent_type.downcase == "opportunity"
  end
  
  def phone_call
    parent if parent && parent_type.downcase == "phonecall"
  end

end
