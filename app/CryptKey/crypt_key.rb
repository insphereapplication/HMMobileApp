# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class CryptKey
  include Rhom::PropertyBag

  # Uncomment the following line to enable sync with CryptKey.
  enable :sync
  set :sync_priority, 100
  property :mobile_crypt_key, :string
  #add model specifc code here
  
  def self.instance
    CryptKey.find(:all).first
  end
end
