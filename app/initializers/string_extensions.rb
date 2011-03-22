
class String
  def time_formatted_string
    self.blank? ? '' : Time.parse(self, DateUtil::DEFAULT_TIME_FORMAT).to_formatted_string
  rescue
    self
  end
end