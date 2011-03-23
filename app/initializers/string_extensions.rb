
class String
  def time_formatted_string
    format_time_string(:to_formatted_string)
  end
  
  
  def hour_string
    format_time_string(:hour_string)
  end
  
  private
  
  def format_time_string(format_method)
    self.blank? ? '' : Time.strptime(self, DateUtil::DEFAULT_TIME_FORMAT).hour_string
  rescue 
    self
  end
   
end