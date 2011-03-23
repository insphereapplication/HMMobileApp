class Note
  include Rhom::PropertyBag

  
  property :annotationid, :string
  property :parent_id, :string
  property :parent_type, :string
  property :createdon, :string
  property :notetext, :string
  
  enable :sync
  # set :sync_priority, 2
  
  def parent
    if self.parent_type && self.parent_id
      parent = Object.const_get(self.parent_type.capitalize) 
      parent.find(:first, :conditions => {"#{self.parent_type.downcase}id" => self.parent_id})
    end
  end
  
  def opportunity
    parent if parent && parent_type.downcase == "opportunity"
  end

end
