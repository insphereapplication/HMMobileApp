class Contact
  include Rhom::FixedSchema

  enable :sync

  property :first_name, :string
  property :last_name, :string
  property :city, :string
  property :state, :string
  property :zip, :string  
  property :phone, :string  
  property :sex, :string  
  property :date_of_birth, :string  
end
