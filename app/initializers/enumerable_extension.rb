require 'date'

#
# Convenience extension methods to Enumerable (Array and Hash) to avoid a lot of duplicate date sorting and selecting and parsing, etc.
#
module Enumerable
  
  # this is necessary because apparently on Rhodes, the default date format is %d/%m/%Y, so we have to explicitly set the normal format
  DEFAULT_PARSE_FORMAT = "%m/%d/%Y"
  
  def select_all_before_today(date_method, format=DEFAULT_PARSE_FORMAT)
    select do |item| 
      date_compare(item, date_method, format) { |date| Date.today > date }
    end
  end
  
  def select_all_after_today(date_method, format=DEFAULT_PARSE_FORMAT)
    select do |item| 
      date_compare(item, date_method, format) { |date| Date.today < date }
    end
  end
  
  def select_all_occurring_today(date_method, format=DEFAULT_PARSE_FORMAT)
    select do |item| 
      date_compare(item, date_method, format) { |date| Date.today == date }
    end
  end
  
  def date_sort(date_method, format=DEFAULT_PARSE_FORMAT)
    sort do |item1, item2| 
      get_date(item1.send(date_method), format) <=> get_date(item2.send(date_method), format)
    end
  end
  
  def date_compare(item, date_method, format)
    if date = get_date(item.send(date_method), format)
      return yield(date) if block_given?
    else
      false
    end
  end
  
  # If date_value is a Date type then return it, otherwise attempt to parse the String into a Date
  def get_date(date_value, format)
    return date_value if date_value.kind_of?(Date)
    begin
      Date.strptime(date_value, format)
    rescue Exception => ex
      puts "Error parsing Date: #{ex.inspect}"
    end
  end
end