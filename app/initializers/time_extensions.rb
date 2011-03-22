
class Time
  def to_formatted_string
    strftime(DateUtil::DEFAULT_TIME_FORMAT)
  end
end