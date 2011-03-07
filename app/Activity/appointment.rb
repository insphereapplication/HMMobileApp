class Appointment < Activity
  def self.open_appointments
    find(:all, :conditions => {'statecode' => 'Scheduled'})
  end
  
  def self.past_due_appointments
    @past_due_appointments ||= open_appointments.select{|appointment| appointment.scheduledend && Date.today > Date.strptime(appointment.scheduledend, "%m/%d/%Y")}
  end
  
  def self.future_appointments
    @future_appointments ||= open_appointments.select{|appointment| appointment.scheduledend && Date.today < Date.strptime(appointment.scheduledend, "%m/%d/%Y")}
  end
  
  def self.todays_appointments
    @todays_appointments ||= open_appointments.select{|appointment| appointment.scheduledend && Date.today == Date.strptime(appointment.scheduledend, "%m/%d/%Y")}
  end
end