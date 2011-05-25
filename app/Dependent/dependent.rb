# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Dependent
  include Rhom::FixedSchema
  
  enable :sync
  set :sync_priority, 70

  property :contact_id, :string
  property :cssi_age, :string
  property :cssi_comments, :string
  property :cssi_dateofbirth, :string
  property :cssi_dependentsid, :string
  property :cssi_gender, :string
  property :cssi_heightft, :string
  property :cssi_heightin, :string
  property :cssi_lastname, :string
  property :cssi_name, :string
  property :cssi_usetobacco, :string
  property :cssi_weight, :string

  def contact
    puts "*** Dependent contact id = " + self.contact_id + " ***"
    Contact.find(self.contact_id)
  end
end
