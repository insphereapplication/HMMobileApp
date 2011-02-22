describe "Contact" do
  it "should have a blah setter" do
    c = Contact.new
    c.respond_to?(:blah).should be_true
  end
end