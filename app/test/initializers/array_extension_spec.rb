require '../../initializers/array_extension'

describe Array do
  
  before(:each) do
    @ary = [1,2,3,4,5]
  end
  
  it "should rotate an array" do
    @ary.rotate!.should == [2,3,4,5,1]
  end
  
  it "should counter-rotate an array" do
    @ary.counter_rotate!.should == [5,1,2,3,4]
  end
  
  it "should orient an array" do
    @ary.orient!(3).should == [3,4,5,1,2]
  end
  
  it "should rotate and return the next element" do
    @ary.next!.should == 2
  end
  
  it "should rotate and return the previous element" do
    @ary.previous!.should == 5
  end
  
  it "should handle single object arrays" do
    [1].rotate!.should == [1]
    [1].counter_rotate!.should == [1]
    [1].next!.should == 1
    [1].previous!.should == 1
  end
  
  it "should handle empty arrays" do
    [].rotate!.should == []
    [].counter_rotate!.should == []
    [].next!.should == nil
    [].previous!.should == nil
  end
end