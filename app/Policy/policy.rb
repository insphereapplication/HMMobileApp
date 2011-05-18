# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Policy
  include Rhom::FixedSchema

  enable :sync
  set :sync_priority, 60
  
  #add model specifc code here
end
