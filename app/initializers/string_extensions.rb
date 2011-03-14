# require 'date_time'

class String
  TIME_PARSE_FORMAT = "%m/%d/%Y %I:%M:%S %p"
  def time_formatted_string
    puts "FORMATTING TIME STRING: "
    puts self
    self.blank? ? '' : Time.parse(self, TIME_PARSE_FORMAT).to_formatted_string
  rescue
    self
  end
end