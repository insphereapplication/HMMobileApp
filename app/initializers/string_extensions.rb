class String
  def time_formatted_string
    format_time_string(:to_formatted_string)
  end
  
  def hour_string
    format_time_string(:hour_string)
  end
  
  def capitalize_words
    if self.match(/^[a-z \&'-]+$|^[A-Z \&'-]+$/)
      self.scan(/\w+|\W+/).map(&:capitalize).join
    else
      self
    end
  end
  
  private
  def format_time_string(format_method)
    self.blank? ? '' : Time.strptime(self, DateUtil::DEFAULT_TIME_FORMAT).send(format_method)
  rescue 
    self
  end
end