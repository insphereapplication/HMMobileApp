module BrowserHelper

  def udpate_status_link(opportunity, disposition)
    %Q{
      <a href=" #{ url_for(:controller => :Activity, :action => :update_status, 
				:query => {
				  :opportunity_id => opportunity.object,
		 		  'phone_call[disposition_detail]' => '',
			      'phone_call[cssi_disposition]' => disposition,
		          'phone_call[scheduledend]' => Date.today.to_s,
		          'phone_call[statecode]' => 'Completed'
			      })
				}" 
				rel="external" data-transition="fade">
				#{disposition}
			</a>
    }
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
  	options = {:currency_symbol => "$", :delimiter => ",", :decimal_symbol => ".", :currency_before => true, :no_decimal => false}.merge(options)

  	# split integer and fractional parts 
  	int, frac = ("%.2f" % number).split('.')
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
      date = Date.parse(input)
      date.strftime("%m/%d/%Y")
    rescue
      puts "Could not parse date value: #{}"
    end
  end
end