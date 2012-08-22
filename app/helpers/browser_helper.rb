require 'date'
require 'time'
module BrowserHelper

  def udpate_status_no_contact_link(opportunity, status_detail)
    %Q{
      <a class="UpdateStatus" onClick="showSpin('Status Updated')" href="#{ url_for(:controller => :Activity, :action => :update_status_no_contact, 
  				:query => {
  				  :opportunity_id => opportunity.object,
  			    :status_detail => status_detail,
  			    :origin => @params['origin']
  			    }
  			  )
  			}" 
  			data-transition="fade">
  			#{status_detail}
			</a>
    }
  end
  
  
  
  def udpate_status_won_link(opportunity)
    #launch dialog to confirm won
    %Q{
      <a class="UpdateStatus" href="#{ url_for(:controller => :Activity, :action => :confirm_win_status, 
  				:query => {
  				  :opportunity_id => opportunity.object,
  				  :origin => @params['origin']
  			    }
  			  )
  			}" 
  			data-transition="fade">
  			Won
			</a>
    }
  end
  
  def  display_contact_record(contact,criteria)
    
    search_criteria = ''
    search_criteria = criteria.gsub("(","\\(") if criteria
    search_criteria.gsub!(")","\\)")

    #puts "made it to contact record create, search #{search_criteria}"

    
    html_string = ''
    if search_criteria.blank?  || ((contact.emailaddress1.blank? || !contact.emailaddress1.downcase.match(search_criteria.downcase)) && (contact.mobilephone.blank? || !contact.mobilephone.downcase.match(search_criteria)  ) && (contact.telephone2.blank? || !contact.telephone2.match(search_criteria))  && (contact.telephone1.blank? || !contact.telephone1.match(search_criteria)) && (contact.telephone3.blank? || !contact.telephone3.match(search_criteria)))

    html_string =  %Q{
          <li role="option" tabindex="0" data-theme="c" class="contact-item ui-btn ui-btn-icon-right ui-li ui-btn-down-c ui-btn-up-c">
                 <div class="ui-btn-inner" onclick="window.open('#{url_for(:action => :show, :id => contact.object, :query => {:origin => 'contact'})} ')">
                   <div class="ui-btn-text">
                     <h3 class="ui-li-heading" style="margin-top: 0px; margin-bottom: 10px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"> <a href="#{url_for(:action => :show, :id => contact.object, :query => {:origin => 'contact'}) }" class="ui-link-inherit" style="padding-left: 0px !important">#{contact.last_first}</a></h3> 
                   </div>
                   <span class="ui-icon ui-icon-arrow-r"></span>
                 </div>
          </li>
        }  
    else
       if contact.emailaddress1 && contact.emailaddress1.downcase.match(search_criteria.downcase)
       html_string =  %Q{
          <li role="option" tabindex="0" data-theme="c" class="contact-item ui-btn ui-btn-icon-right ui-li ui-btn-down-c ui-btn-up-c">
                 <div class="ui-btn-inner" onclick="window.open('#{url_for(:action => :show, :id => contact.object, :query => {:origin => 'contact'})} ')">
                   <div class="ui-btn-text">
                     <h3 class="ui-li-heading" style="margin-top: 0px; margin-bottom: 10px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"> <a href="#{url_for(:action => :show, :id => contact.object, :query => {:origin => 'contact'}) }" class="ui-link-inherit" style="padding-left: 0px !important">#{contact.last_first}</a></h3> 
                     <div class="ui-grid-a ui-li-desc" >
                              <div class="ui-block-a" style="margin-bottom: 0px">
                                 #{contact.emailaddress1}
                              </div>
                     </div>
                   </div>
                   <span class="ui-icon ui-icon-arrow-r"></span>
                 </div>
               </li>
          }
        end
        if contact.mobilephone && contact.mobilephone.match(search_criteria)
            html_string =  html_string +  create_phone_contact_record(contact,contact.mobilephone, 'M')
        end
        if contact.telephone2 && contact.telephone2.match(search_criteria)
            html_string =  html_string +  create_phone_contact_record(contact,contact.telephone2, 'H')
        end
        if contact.telephone1 && contact.telephone1.match(search_criteria)
            html_string =  html_string +  create_phone_contact_record(contact,contact.telephone1, 'B')
            
        end
        if contact.telephone3 && contact.telephone3.match(search_criteria)
            html_string =  html_string +  create_phone_contact_record(contact,contact.telephone3, 'A')
        end

    end
    #puts "contact list #{html_string}"  
    html_string
    
  end  
  
  def create_phone_contact_record(contact, phone_number, type)
    %Q{
       <li role="option" tabindex="0" data-theme="c" class="contact-item ui-btn ui-btn-icon-right ui-li ui-btn-down-c ui-btn-up-c">
              <div class="ui-btn-inner" onclick="window.open('#{url_for(:action => :show, :id => contact.object, :query => {:origin => 'contact'})} ')">
                <div class="ui-btn-text">
                  <h3 class="ui-li-heading" style="margin-top: 0px; margin-bottom: 10px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"> <a href="#{url_for(:action => :show, :id => contact.object, :query => {:origin => 'contact'}) }" class="ui-link-inherit" style="padding-left: 0px !important">#{contact.last_first}</a></h3> 
                  <div class="ui-grid-a ui-li-desc" >
                           <div class="ui-block-a" style="margin-bottom: 0px">
                                #{type}: #{phone_number}
                           </div>
                  </div>
                </div>
                <span class="ui-icon ui-icon-arrow-r"></span>
              </div>
            </li>
       }
  end  
  
  def display_search_ac_contact(result, contacts_on_device, email_criteria, phone_criteria)
				
				html_string = ""
				if (email_criteria.blank? && phone_criteria.blank?)
					if (contacts_on_device.include?(result[0])
					  )
					 
					   html_string =  %Q{ 
					     <li role="option" tabindex="0" data-theme="c" class="contact-item ui-btn ui-btn-icon-right ui-li ui-btn-down-c ui-btn-up-c">
					      <div class="ui-btn-inner" onclick="window.open('#{url_for(:action => :show, :controller => :Contact, :id => result[0], :query => {:origin =>'SearchContacts'})} ')">
             				<div class="ui-btn-text"> 
             				   <h3 class="ui-li-heading" ><a href="#{url_for(:action => :show, :controller => :Contact, :id => result[0], :query => {:origin =>'SearchContacts'})}" class="ui-link-inherit" style="padding-left: 0px !important"> #{result[1]['lastname']}, #{result[1]['firstname']}</a></h3>
							     </div>
							  <img class="search-icon" src="/public/images/mobile_phone.png">
							  </div>
				    </li> }
					else
					   html_string = html_string + %Q{
					     <li role="option" tabindex="0" data-theme="c" class="contact-item ui-btn ui-btn-icon-right ui-li ui-btn-down-c ui-btn-up-c">
					      <div class="ui-btn-inner" onclick="window.open('#{url_for(:action => :show_AC_contact, :controller => 'Contact', :query => {:origin =>'SearchContacts', :id => result[0] })} ')">
             				<div class="ui-btn-text">
             				  <h3 class="ui-li-heading" ><a href="#{url_for(:action => :show_AC_contact, :controller => 'Contact', :query => {:origin =>'SearchContacts', :id => result[0] })}" class="ui-link-inherit" style="padding-left: 0px !important"> #{result[1]['lastname']}, #{result[1]['firstname']}</a></h3>
								     </div>
							<img class="search-icon" src="/public/images/computer_icon.png">
							</div>
				    </li>}
					end
				end	
				if (!email_criteria.blank?)
				  if (contacts_on_device.include?(result[0])
					  ) 
					   html_string =  %Q{ 
					     <li role="option" tabindex="0" data-theme="c" class="contact-item ui-btn ui-btn-icon-right ui-li ui-btn-down-c ui-btn-up-c">
					       <div class="ui-btn-inner" onclick="window.open('#{url_for(:action => :show, :controller => :Contact, :id => result[0], :query => {:origin =>'SearchContacts'})} ')">
             				<div class="ui-btn-text">
             				  <h3 class="ui-li-heading"><a href="#{url_for(:action => :show, :controller => :Contact, :id => result[0], :query => {:origin =>'SearchContacts'})}" class="ui-link-inherit" style="padding-left: 0px !important"> #{result[1]['lastname']}, #{result[1]['firstname']}</a></h3>
  							     	      <div class="ui-grid-a ui-li-desc" >
                              <div class="ui-block-a" style="margin-bottom: 0px">
                               #{result[1]['emailaddress1']}
                               </div>
                            </div>						
							   </div>
							 <img class="search-icon" src="/public/images/mobile_phone.png">
							</div>
				    </li> }
					else
					   html_string =  %Q{
					     <li role="option" tabindex="0" data-theme="c" class="contact-item ui-btn ui-btn-icon-right ui-li ui-btn-down-c ui-btn-up-c">
					      <div class="ui-btn-inner" onclick="window.open('#{url_for(:action => :show_AC_contact, :controller => 'Contact', :query => {:origin =>'SearchContacts', :id => result[0] })} ')">
             				<div class="ui-btn-text">
             				  <h3 class="ui-li-heading" ><a href="#{url_for(:action => :show_AC_contact, :controller => 'Contact', :query => {:origin =>'SearchContacts', :id => result[0] })}" class="ui-link-inherit" style="padding-left: 0px !important"> #{result[1]['lastname']}, #{result[1]['firstname']}</a></h3>
  							      	<div class="ui-grid-a ui-li-desc" >
                            <div class="ui-block-a" style="margin-bottom: 0px">
                               #{result[1]['emailaddress1']}
                            </div>
                        </div>
						   	</div>
							<img class="search-icon" src="/public/images/computer_icon.png">
							</div>
				    </li>}
					end 
				end
				if (!phone_criteria.blank?)
				    search_criteria = phone_criteria.gsub("(","\\(")
            search_criteria.gsub!(")","\\)")
            
            on_device = contacts_on_device.include?(result[0])
           
            if result[1]['mobilephone'] && result[1]['mobilephone'].match(search_criteria)
                html_string =  html_string +  create_search_ac_record(result,result[1]['mobilephone'], 'M', on_device)
            end
            if result[1]['telephone2'] && result[1]['telephone2'].match(search_criteria)
                html_string =  html_string +  create_search_ac_record(result,result[1]['telephone2'], 'H', on_device)
            end
            if result[1]['telephone1'] && result[1]['telephone1'].match(search_criteria)
                html_string =  html_string +  create_search_ac_record(result,result[1]['telephone1'], 'B' , on_device)

            end
            if result[1]['telephone3'] && result[1]['telephone3'].match(search_criteria)
                html_string =  html_string +  create_search_ac_record(result,result[1]['telephone3'], 'A', on_device)
            end
				    
				end  
   html_string
  end
  
  def create_search_ac_record(result, phone_number, type, on_device)
    html_string = ""
    if (on_device)
     html_string = create_search_ac_record_device(result, phone_number, type)
    else
     html_string = create_search_ac_record_computer(result, phone_number, type)
    end    
    html_string
  end
  
  def create_search_ac_record_device(result, phone_number, type)
    
    %Q{ 
	     <li role="option" tabindex="0" data-theme="c" class="contact-item ui-btn ui-btn-icon-right ui-li ui-btn-down-c ui-btn-up-c">
	       <div class="ui-btn-inner" onclick="window.open('#{url_for(:action => :show, :controller => :Contact, :id => result[0], :query => {:origin =>'SearchContacts'})} ')">
     				<div class="ui-btn-text">
     				  <h3 class="ui-li-heading" ><a href="#{url_for(:action => :show, :controller => :Contact, :id => result[0], :query => {:origin =>'SearchContacts'})}" class="ui-link-inherit" style="padding-left: 0px !important"> #{result[1]['lastname']}, #{result[1]['firstname']}</a></h3>
				     	      <div class="ui-grid-a ui-li-desc" >
                             <div class="ui-block-a" style="margin-bottom: 0px">
                                  #{type}: #{phone_number}
                           </div>
                    </div>				
			   </div>
			<img class="search-icon" src="/public/images/mobile_phone.png">
			</div>
    </li> }
  
  end
  
  def create_search_ac_record_computer(result, phone_number, type)
    
    %Q{
	     <li role="option" tabindex="0" data-theme="c" class="contact-item ui-btn ui-btn-icon-right ui-li ui-btn-down-c ui-btn-up-c">
	     <div class="ui-btn-inner" onclick="window.open('#{url_for(:action => :show_AC_contact, :controller => 'Contact', :query => {:origin =>'SearchContacts', :id => result[0] })} ')">
     				<div class="ui-btn-text">
     				  <h3 class="ui-li-heading" ><a href="#{url_for(:action => :show_AC_contact, :controller => 'Contact', :query => {:origin =>'SearchContacts', :id => result[0] })}" class="ui-link-inherit" style="padding-left: 0px !important"> #{result[1]['lastname']}, #{result[1]['firstname']}</a></h3>
				      	<div class="ui-grid-a ui-li-desc" >
                         <div class="ui-block-a" style="margin-bottom: 0px">
                              #{type}: #{phone_number}
                       </div>
                </div>
		   	</div>
			<img class="search-icon" src="/public/images/computer_icon.png">
			</div>
    </li>}
  
  end  
  
  def quick_task_add_panel
    %Q{
      <div data-role="collapsible" data-collapsed="true" >
  			<h3>Follow-up Task...</h3>
  		    <div class="ui-body ui-body-d">
  			  	<label for="task_subject" class="fieldLabel">Subject:<font color="red">&nbsp;&nbsp;*</font></label>
    				<input maxlength="200" type="text" id="task_subject" name="task[subject]" value="" />
    			</div>
          <div data-role="fieldcontain">
  					<div class="ui-body ui-body-d">
  		            	<label for="task_due_datetime" class="fieldLabel">Due Date:</label>
  						<input id="task_due_datetime" type="text" name="task[due_datetime]" readonly value="#{$choosed['0']}"  onClick="PickDueDateChangeFocus();"/>
			    	</div>
    			</div>
          <div data-role="fieldcontain">
  					<div class="ui-body ui-body-d">
  						<legend>Priority:</legend>
  		            	<label for="task_priority_checkbox" class="fieldLabel">
  							<img src="/public/images/red_exclamation.png"/>
  						High
  						</label>
  						<input id="task_priority_checkbox" type="checkbox" name="task[high_priority_checkbox]" class="custom" />
			    	</div>
    			</div>
  		</div>			
	  }
  end  
  
  def offline_bar
    %Q{
      	<div data-nobackbtn="true" class="ui-offline-bar#{ DeviceCapabilities.is_connected? ? ' ui-hidden' : '' }" role="banner"> Connection State: Offline </div>
    }
  end
  
  def sync_spinner
      %Q{
        	<img class="#{ DeviceCapabilities.is_syncing? ? 'ui-hidden' : '' }" id="syncSpinner" src="/public/images/syncSpinner.gif" height="12" width="12" />
      }
  end
  
  def udpate_status_lost_link(opportunity, text, status_code)
    #launch dialog to confirm lost
    %Q{
      <a class="UpdateStatus" href="#{ url_for(:controller => :Activity, :action => :confirm_lost_status, 
  				:query => {
  				  :opportunity_id => opportunity.object,
  			    :status_code => status_code,
  			    :origin => @params['origin']
  			    }
  			  )
  			}" 
  			data-transition="fade">
  			#{text}
			</a>
    }
  end
  
  def update_opportunity_statecode_link(opportunity, statecode)
     %Q{
        <a href="#{ url_for(:controller => :Opportunity, :action => :update, :id => opportunity.object, 
  				:query => {
  				  'opportunity[statecode]' => statecode
  			    })
  				}" 
  				rel="external" data-transition="fade">
  				#{statecode}
  			</a>
      }
  end

  def cancelbutton_by_origin(origin)
    case origin
      when "new-leads"
        # we've removed the icon as it overlaps with the header text; to put it back, add 'data-icon="back"' to the tag
        '<a href="/app/Opportunity?selected_tab=new-leads" data-direction="reverse" rel="external">Cancel</a>'
      when "follow-ups"
        '<a href="/app/Opportunity?selected_tab=follow-ups" data-direction="reverse" rel="external">Cancel</a>'
      when "appointments"
        '<a href="/app/Opportunity?selected_tab=appointments" data-direction="reverse" rel="external">Cancel</a>'
      when "contact"
         '<a href="/app/Contact" data-direction="reverse" rel="external">Cancel</a>'
      else
        '<a href="/app/Opportunity" data-direction="reverse" rel="external">Cancel</a>'
    end
  end
  
  def gen_options(options, selected_value)
    options.map{|option|
      selected_text = (option[:value] == selected_value) ? 'selected="true"' : ''
      "<option class=\"ui-btn-text\" #{selected_text} value=\"#{option[:value]}\">#{option[:label]}</option>"
    }.join("\n")
  end
  
  def scheduled_filter_options
    options = [
      {:value => 'All', :label => 'All'},
      {:value => 'ScheduledAppointments', :label => 'Appointments'},
      {:value => 'ScheduledCallbacks', :label => 'Callbacks'}
    ]
    
    persisted_selection = Settings.filter_values['scheduled_filter']
    persisted_selection = 'All' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end
  
  def followup_status_reason_filter_options  	
  	options = [
      {:value => 'All', :label => 'All'},
      {:value => 'NoContactMade', :label => 'No Contact Made'},
      {:value => 'ContactMade', :label => 'Contact Made'},
      {:value => 'AppointmentSet', :label => 'Appointment Set'},
      {:value => 'DealInProgress', :label => 'Deal in Progress'}
    ]
    
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}statusReason"]
    persisted_selection = 'All' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end
  
  def followup_sort_by_filter_options
		options = [
      {:value => 'LastActivityDateAscending', :label => 'Latest Activity Date'},
      {:value => 'LastActivityDateDescending', :label => 'Earliest Activity Date'},
      {:value => 'CreateDateAscending', :label => 'Created Ascending'},
      {:value => 'CreateDateDescending', :label => 'Created Descending'}
    ]
    
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}sortBy"]
    persisted_selection = 'LastActivityDateAscending' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end
  
  def followup_created_filter_options
    options = [
      {:value => 'All', :label => 'All'},
      {:value => '1', :label => '1 Day Ago'},
      {:value => '2', :label => '2 Days Ago'},
      {:value => '3', :label => '3 Days Ago'},
      {:value => '4', :label => '4 Days Ago'},
      {:value => '5', :label => '5 Days Ago'}
    ]
    
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}created"]
    persisted_selection = 'All' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end
  
  def followup_daily_filter_options
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}isDaily"]
    " checked='checked' " if persisted_selection == 'true'
  end
  
  def contact_filter_options
    options = [
      {:value => 'all', :label => 'All'},
      {:value => 'active-policies', :label => 'Active Policies'},
      {:value => 'pending-policies', :label => 'Pending Policies'},
      {:value => 'open-opps', :label => 'Open Opportunities'},
      {:value => 'won-opps', :label => 'Won Opportunities'}
    ]
    
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_CONTACT_FILTER_PREFIX}filter"]
    persisted_selection = 'all' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end

  
  def opp_detail_backbutton(origin)
      case origin
        when "new-leads"
          '<a href="/app/Opportunity?selected_tab=new-leads" data-direction="reverse" rel="external" data-icon="back">Opps</a>'
        when "follow-ups"
          '<a href="/app/Opportunity?selected_tab=follow-ups" data-direction="reverse" rel="external" data-icon="back">Opps</a>'
        when "appointments"
          '<a href="/app/Opportunity?selected_tab=appointments" data-direction="reverse" rel="external" data-icon="back">Opps</a>'
        when "contact"
           '<a href="/app/Contact" data-direction="reverse" rel="external" data-icon="back">Contacts</a>'
        else
          '<a href="/app/Opportunity" data-direction="reverse" rel="external" data-icon="back">Opps</a>'
      end
  end

  def placeholder(label=nil)
    "placeholder='#{label}'" if platform == 'apple'
  end

  def platform
    System::get_property('platform').downcase
  end

  def selected(option_value,object_value)
    "selected=\"yes\"" if option_value == object_value
  end

  def checked(option_value,object_value)
    "checked=\"yes\"" if option_value == object_value
  end
  
  def format_currency(number, options={})
  	# :currency_before => false puts the currency symbol after the number
  	# default format: $12,345,678.90
  	
  	number = number.blank? ? 0 : number # default to 0 if given number is blank
  	
  	options = {:currency_symbol => "$", :delimiter => ",", :decimal_symbol => ".", :currency_before => true, :no_decimal => false}.merge(options)
    
  	# split integer and fractional parts 
  	int, frac = ("%.2f" % number.to_f).split('.')
  	# insert the delimiters
  	int.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")

  	if options[:no_decimal]
  		frac_part = ""
  	else
  		frac_part = options[:decimal_symbol] + frac
  	end

  	if options[:currency_before]
  		options[:currency_symbol] + int + frac_part
  	else
  		int + frac_part + options[:currency_symbol]
  	end
  end
  
  def to_date(input)
    begin
      date = (Date.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = date.strftime('%m/%d/%Y')
      result
    rescue
      puts "DATE !~!~!~!~!~ DATE ISSUE !~!~!!~!~!~!~!~!~!!~!"
      puts "Could not parse date value: #{input}"
    end
  end
  
  def to_birthdate(input)
    begin
      date = (Date.strptime(input, DateUtil::BIRTHDATE_PICKER_TIME_FORMAT))
      result = date.strftime('%m/%d/%Y')
      result
    rescue
      puts "DATE !~!~!~!~!~ DATE ISSUE !~!~!!~!~!~!~!~!~!!~!"
      puts "Could not parse date value: #{input}"
    end
  end
  
  def to_date_noyear(input)
    begin
      date = (Date.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = date.strftime('%m/%d')
      result
    rescue
      puts "Could not parse date value: #{input}"
    end
  end

  def to_datetime(input)
    begin
      date = (DateTime.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = date.strftime('%m/%d/%Y %I:%M %p')
      result
    rescue
      puts "Could not parse date value: #{input}"
    end
  end
  
  def to_endtime(input)
    begin
      date = (DateTime.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = date.strftime('%I:%M %p')
      result
    rescue
      puts "Could not parse  value: #{input}"
    end
  end
  
  def to_datetime_noyear(input)
    begin
      date = (DateTime.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      date.strftime(DateUtil::NO_YEAR_FORMAT).sub(/\A0+/, '')
    rescue
      puts "Could not parse date value: #{input}"
    end
  end
  
  def days_ago_formatted(input)
    begin
      date = (DateTime.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = (Date.today - date).to_i
      if result == 0 
        return "Today"
      else
        result + "d"
      end
    rescue
      puts "Could not parse date value: #{input}, Today is: #{Date.today.to_s}"
    end
  end
  
  def format_for_mapping(location)
  end
  
  # converts True/False to Yes/No, used on contact/spouse/dependent for displaying tobacco use
  def use_tobacco_string(value)
    if value == 'True'
      'Yes'
    else
      'No'
    end
  end
  
  def generate_listview_item(item)
    if item[:label] == 'Description'
      #the gsub below is used to remove 'href' from the text so any link in the text/html are not clickable
      value = item[:value].gsub('href=', ' ')
      value.gsub!('href =', ' ')
      "<li data-icon=\"false\"><p><strong>#{item[:label]}:</strong>&nbsp;#{value}</p></li>"
    else
     "<li data-icon=\"false\"><p><strong>#{item[:label]}:</strong>&nbsp;#{item[:value]}</p></li>"
    end
  end
  
  def generate_listview_items(items)
    items.map{|item| generate_listview_item(item) }.join("\n")
  end
  
  def generate_phone_number_icons(preferred, do_not_call)
    if preferred && do_not_call
      # side-by-side icons
      %Q{ <span class="ui-icon ui-icon-donotcall"></span><span class="ui-icon ui-icon-check" style="float:right; right:33px;"></span> }
    else
      if do_not_call
        %Q{ <span class="ui-icon ui-icon-donotcall ui-icon-shadow"></span> }
      elsif preferred  
        %Q{ <span class="ui-icon ui-icon-check ui-icon-shadow"></span> }
      else
        ""
      end
    end
  end
  
  def space_if_blank(object)
    object.blank? ? '&nbsp;' : object
  end
end