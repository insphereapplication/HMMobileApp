class Opportunity
  include Rhom::FixedSchema

  enable :sync

  property :status, :string
  property :source, :string
  property :status_reason, :string
  property :vendor, :string
  property :lead_type, :string  
  property :created_on, :string  
  property :updated_on, :string  
  property :priority, :string
  property :category, :string
end
