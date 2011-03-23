require '../../utils/util'
require '../../initializers/enumerable_extension'
require 'ap'

class TestDate
  attr_accessor :date_string
  def initialize(date_string)
    @date_string = date_string
  end
end


context "Extending Enumerable" do 
  
  it "should sort by the parsed date in the method given" do
    strings = [
    "8/6/10 4:10:19 PM",
    "9/5/10 1:10:18 PM",
    "8/1/10 7:10:17 PM",
    "1/1/10 6:10:16 PM",
    "2/8/10 2:10:15 PM",
    "9/8/10 1:10:14 PM",
    "2/4/10 1:10:13 PM",
    "6/1/10 1:10:12 PM",
    "2/5/10 8:10:11 PM",
    "3/5/10 7:10:10 PM"
    ]
    
    sorted = strings.map {|i| TestDate.new(i) }.date_sort(:date_string)
    
    [
      "1/1/10 6:10:16 PM",
      "2/4/10 1:10:13 PM",
      "2/5/10 8:10:11 PM",
      "2/8/10 2:10:15 PM",
      "3/5/10 7:10:10 PM",
      "6/1/10 1:10:12 PM",
      "8/1/10 7:10:17 PM",
      "8/6/10 4:10:19 PM",
      "9/5/10 1:10:18 PM",
      "9/8/10 1:10:14 PM"
    ].should == sorted.map{|d| d.date_string }
  end
  
  it "should group items for today" do
    time1,time2,time3 = 3.times.map{Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)}
   
    strings = [
      "8/6/10 4:10:19 PM",
      time1,
      time2,
      "1/1/10 6:10:16 PM",
      "2/8/10 2:10:15 PM",
      "9/8/10 1:10:14 PM",
      time3,
      "6/1/10 1:10:12 PM",
      "2/5/10 8:10:11 PM",
      "3/5/10 7:10:10 PM"
      ].map{|s| TestDate.new(s)}.select_all_occurring_today(:date_string).map{|d| d.date_string}
     
      strings.should == [time1,time2,time3]
      
  end
  
  
end