describe "Application" do 
  describe "Contact" do
    it "should sync data" do
      Rho::RhoConnectClient.logout()
      Rho::RhoConnectClient.login(Rho::RhoConfig.test_user, Rho::RhoConfig.test_password,"")
      i = 0
      while i < 10
        if Rho::RhoConnectClient.isLoggedIn() == 1
          puts "logged in"
          break
        end
        puts "sleeping"
        sleep 5
      end

      Rho::RhoConnectClient.isLoggedIn().should == 1
      Rho::RhoConnectClient.doSync
      i = 0
      
      while i < 10
        contacts = Contact.find(:all)
        break if contacts and contacts.length > 0
        sleep 5
      end
    
      contacts.should_not == nil
      contacts.length.should > 0

    end
  end
end