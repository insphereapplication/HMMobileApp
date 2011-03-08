class Appointment < Activity
  
  # an array of class-level cache objects
  CACHED = [@open_appointments]
  
  # clear out all class-level cache objects
  def self.clear_cache
    CACHED.each {|cache| cache = nil }
  end
  
  def self.open_appointments
    @open_appointments ||= find(:all, :conditions => {'statecode' => 'Scheduled'})
  end
  
  def self.past_due_appointments
    open_appointments.select_all_before_today(:scheduledend) #select{|appointment| appointment.scheduledend && Date.today > Date.strptime(appointment.scheduledend, "%m/%d/%Y")}
  end
  
  def self.future_appointments
    open_appointments.select_all_after_today(:scheduledend) #select{|appointment| appointment.scheduledend && Date.today < Date.strptime(appointment.scheduledend, "%m/%d/%Y")}
  end
  
  def self.todays_appointments
    open_appointments.select_all_occurring_today(:scheduledend) #select{|appointment| appointment.scheduledend && Date.today == Date.strptime(appointment.scheduledend, "%m/%d/%Y")}
  end
end