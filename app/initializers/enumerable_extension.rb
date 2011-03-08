require 'date'

module Enumerable
  def select_all_before_today(date_method, format="%m/%d/%Y")
    select{|item| item.send(date_method) && Date.today > Date.strptime(item.send(date_method), format)}
  end
  
  def select_all_after_today(date_method, format="%m/%d/%Y")
    select{|item| item.send(date_method) && Date.today < Date.strptime(item.send(date_method), format)}
  end
  
  def select_all_occurring_today(date_method, format="%m/%d/%Y")
    select{|item| item.send(date_method) && Date.today == Date.strptime(item.send(date_method), format)}
  end
end