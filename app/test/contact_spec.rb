describe "Contact" do
  
  it "should be a fixed schema" do
    Contact.fixed_schema?.should be_true
  end
end