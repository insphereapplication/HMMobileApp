describe "Contact" do
  it "should have a blah setter" do
    c = Contact.new
    c.respond_to?(:blah).should be_true
  end
  
  it "should return all new lead opportunities" do
      c = Contact.create
      c.should_not be_nil
  end
end