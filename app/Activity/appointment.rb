class Appointment < Activity
  def self.open_appointments
    find(:all, :conditions => {'statecode' => 'Scheduled'})
  end
end