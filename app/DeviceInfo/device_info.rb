# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'date'
class DeviceInfo
  include Rhom::PropertyBag
  include SQLHelper

  property :app_version, :string
  property :os_platform, :string
  property :os_version, :string
  property :phone_id, :string
  property :client_id, :string
  property :push_pin, :string
  property :last_sync, :string
  property :emulator, :string
  
  enable :sync
  enable :full_update
  set :sync_priority, 2 # this needs done after the App Info so that we get the device info incase their is a failure with the other models
  
  def self.find_device(id)
    @deviceinfo = DeviceInfo.find(
      :first, 
      :conditions => {'client_id' => id}
    )
      
  end  
  
  def self.check_device_information
    
   push_pin =  System.get_property('device_id') && System.get_property('device_id').length > 0  ? System.get_property('device_id') : Rho::RhoConfig.push_pin   
    
   @device_data = {
      :app_version => Rho::RhoConfig.app_version,
      :phone_id => System.get_property('phone_id'),
      :os_platform => System.get_property('platform'),
      :device_name => System.get_property('device_name'),
      :os_version => System.get_property('os_version'),
      :last_sync => Settings.last_synced.getgm.to_s,
      :emulator => System.get_property("is_emulator"),
      :client_id => Rhom::Rhom::client_id, 
      :push_pin => System.get_property('device_id') && System.get_property('device_id').length > 0  ? System.get_property('device_id') : Rho::RhoConfig.push_pin    
    }
    

    @device = DeviceInfo.find_device(@device_data[:client_id])

    if @device 
      @device.update_attributes(@device_data)    
    else
      DeviceInfo.create(@device_data)      
    end
    
  end
  
  
end
