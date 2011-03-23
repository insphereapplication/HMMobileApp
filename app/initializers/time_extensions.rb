
class Time
  def to_formatted_string
    strftime(DateUtil::DEFAULT_TIME_FORMAT)
  end
  
  def hour_string
    strftime(DateUtil::HOUR_FORMAT).sub(/\A0+/, '')
  end
end