//FORM VALIDATIONS
// function ValidateEdit(form)
// {
// 
//    if(IsEmpty(form.elements["contact[emailaddress1]"])) 
//    { 
// 		return true;
//    } 
//  
//    if (!isValidEmail(form.elements["contact[emailaddress1]"])) 
//    { 
//       alert('Please enter a valid email format') 
//       contact[emailaddress1].focus(); 
//       return false; 
//       }
//  
// return true;
//  
// }
// 
// function IsEmpty(aTextField) {
// 	alert('checking email format'); 
   // if ((aTextField.value.length==0) ||
   // (aTextField.value==null)) {
   //    return true;
   // }
   // else { return false; }
// }
// 
// function isValidEmail(str) {
//    return (str.indexOf(".") > 2) && (str.indexOf("@") > 0);
// 
// }

quick_task_validation = {'task[subject]' : {	
   required: function(element) {
			  var a = $("#task_due_datetime").val();
	          return $("#task_priority_checkbox:checked").val() == 'on' || $("#task_due_datetime").val() != "" ;
	      }
		
	}
}

function checkEdit(myForm) {
		//make sure preferred phone has a value entered
		switch (myForm.elements["contact[cssi_preferredphone]"].value)
		{
		case ("Mobile"):
		  if (myForm.elements["contact[mobilephone]"].value.length == 0){
			alert('Please enter a number for preferred phone (Mobile)');
			myForm.elements["contact[mobilephone]"].focus();
			return false;
		}
		  break;
		case ("Business"):
		  if (myForm.elements["contact[telephone1]"].value.length == 0){
			alert('Please enter a number for preferred phone (Business)');
			myForm.elements["contact[telephone1]"].focus();
			return false;
		}
		  break;
		case ("Home"):
		  if (myForm.elements["contact[telephone2]"].value.length == 0){
			alert('Please enter a number for preferred phone (Home)');
			myForm.elements["contact[telephone2]"].focus();
			return false;
		}
		  break;
		case ("Alternate"):
		  if (myForm.elements["contact[telephone3]"].value.length == 0){
			alert('Please enter a number for preferred phone (Alternate)');
			myForm.elements["contact[telephone3]"].focus();
			return false;
		}
		  break;
		}

	if ((myForm.elements["contact[emailaddress1]"].value.length==0) ||(myForm.elements["contact[emailaddress1]"].value==null)) {
      return true;
   }
   else { 
	if (/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(myForm.elements["contact[emailaddress1]"].value)){
			return true;
			}
			alert("Invalid E-mail Address! Please re-enter.");
			myForm.elements["contact[emailaddress1]"].focus();
			return false;
	}
	var a = "hello";
	switch (a){
		case ("hello"):
		alert('this says hello');
		break;
	}
}

// Phone Number Validation


// Dependent Add / Edit
$('#dependent_new_page, #dependent_edit_page').live('pagecreate',function(event){
	$("#dependent_form").validate({
	  rules: {
	    'dependent[cssi_name]' : {
	      required: true,
		  maxlength: 100
	    },
	    'dependent[cssi_lastname]' : {
		  maxlength: 100
	    },
		'dependent[cssi_weight]' : {
		  min: 0,
		  max: 1000,
		  digits: true
	    },
		'dependent[cssi_comments]' : {
		  maxlength: 250
	    }
	  }
	});	
});

// Spouse Add / Edit
$('#spouse_new_page, #spouse_edit_page').live('pagecreate',function(event){
	$("#spouse_form").validate({
	  rules: {
	    'contact[cssi_spousename]' : {
	      required: true,
		  maxlength: 100
	    },
	    'contact[cssi_spouselastname]' : {
		  maxlength: 100
	    },
		'contact[cssi_spouseweight]' : {
		  min: 0,
		  max: 1000,
		  digits: true
	    }
	  }
	});	
});

// Contact Edit
$('#contact_edit_page').live('pagecreate',function(event){
	$("#contact_edit").validate({
	  rules: {
		'contact[firstname]' : {
		  required: true,
		  maxlength: 50
		},
		'contact[lastname]' : {
		  required: true,
		  maxlength: 50
		},
	    'contact[mobilephone]' : {
		  phoneUS: true,
		  preferredMobile: true
	    },
		'contact[telephone1]' : {
		  phoneUS: true,
		  preferredBusiness: true,
		  required: function(element) {
			          return  $("#contact_cssi_businessphoneext").val() != null && $("#contact_cssi_businessphoneext").val() != '' ;
			      }
		},
		'contact[telephone2]' : {
		  phoneUS: true,
		  preferredHome: true
		},
		'contact[telephone3]' : {
		  phoneUS: true,
		  preferredAlternate: true
		},
		'contact[emailaddress1]' : {
		  email: true,
		  maxlength: 255
		},
		'contact[cssi_weight]' : {
		  min: 0,
		  max: 1000,
		  digits: true		  
		},
		'contact[address1_line1]' : {
		  maxlength: 200	
		},
		'contact[address1_line2]' : {
		  maxlength: 255	
		},
		'contact[address1_city]' : {
		  maxlength: 50	
		},
		'contact[address1_postalcode]' : {
		  maxlength: 20	
		},
		'contact[address2_line1]' : {
		  maxlength: 200	
		},
		'contact[address2_line2]' : {
		  maxlength: 200	
		},
		'contact[address2_city]' : {
		  maxlength: 50	
		},
		'contact[address2_postalcode]' : {
		  maxlength: 20	
		}
	  }
	});
	
	// Creates a US phone number ('### ### ####') validator
	jQuery.validator.addMethod("phoneUS", function(phone_number, element) {
	    phone_number = phone_number.replace(/\s+/g, ""); 
		return this.optional(element) || phone_number.length > 9 &&
			phone_number.match(/^(\([0-9]\d{2}\)|[0-9]\d{2})-?[0-9]\d{2}-?\d{4}$/);
	}, "Please specify a valid phone number in format ### ### ####");
	
	// Creates an 'at least one of these are required' validator
	jQuery.validator.addMethod('required_group', function(val, el) {
		var $module = $(el).parents('div.panel');
		return $("#contact_edit").find('.required_group:filled').length;
		}, 'Please fill out at least one of these fields.');
		
	jQuery.validator.addMethod("preferredMobile", function(phone_number, element) {
		    return !($('#contact_preferredphone').val() == "Mobile" && phone_number == '');
		}, "Please fill out preferred number");	
		
	jQuery.validator.addMethod("preferredBusiness", function(phone_number, element) {
		    return !($('#contact_preferredphone').val() == "Business" && phone_number == '');
		}, "Please fill out preferred number");
			
	jQuery.validator.addMethod("preferredHome", function(phone_number, element) {
		    return !($('#contact_preferredphone').val() == "Home" && phone_number == '');
		}, "Please fill out preferred number");
				
	jQuery.validator.addMethod("preferredAlternate", function(phone_number, element) {
		    return !($('#contact_preferredphone').val() == "Alternate" && phone_number == '');
		}, "Please fill out preferred number");
	
});

// Contact Add
$('#contact_new_page').live('pagecreate',function(event){
	$("#contact_new").validate({
		  rules: {
			'contact[firstname]' : {
			  required: true,
			  maxlength: 50
		    },
			'contact[lastname]' : {
			  required: true,
			  maxlength: 50
		    },
		    'contact[mobilephone]' : {
			  phoneUS: true,
			  preferredMobile: true
		    },
			'contact[telephone1]' : {
			  phoneUS: true,
			  preferredBusiness: true
			},
			'contact[telephone2]' : {
			  phoneUS: true,
			  preferredHome: true
			},
			'contact[telephone3]' : {
			  phoneUS: true,
			  preferredAlternate: true
			},
			'contact[emailaddress1]' : {
			  email: true,
			  maxlength: 255
			},
			'contact[address1_line1]' : {
			  maxlength: 200	
			},
			'contact[address1_line2]' : {
			  maxlength: 255	
			},
			'contact[address1_city]' : {
			  maxlength: 50	
			},
			'contact[address1_postalcode]' : {
			  maxlength: 20	
			},
			'contact[address2_line1]' : {
			  maxlength: 200	
			},
			'contact[address2_line2]' : {
			  maxlength: 200	
			},
			'contact[address2_city]' : {
			  maxlength: 50	
			},
			'contact[address2_postalcode]' : {
			  maxlength: 20	
			}
		  }
		});

		// Creates a US phone number ('### ### ####') validator
		jQuery.validator.addMethod("phoneUS", function(phone_number, element) {
		    phone_number = phone_number.replace(/\s+/g, ""); 
			return this.optional(element) || phone_number.length > 9 &&
				phone_number.match(/^(\([0-9]\d{2}\)|[0-9]\d{2})-?[0-9]\d{2}-?\d{4}$/);
		}, "Please specify a valid phone number in format ### ### ####");

		// Creates an 'at least one of these are required' validator
		jQuery.validator.addMethod('required_group', function(val, el) {
			var $module = $(el).parents('div.panel');
			return $("#contact_new").find('.required_group:filled').length;
			}, 'Please fill out at least one of these fields.');

		jQuery.validator.addMethod("preferredMobile", function(phone_number, element) {
			    return !($('#contact_preferredphone').val() == "Mobile" && phone_number == '');
			}, "Please fill out preferred number");	

		jQuery.validator.addMethod("preferredBusiness", function(phone_number, element) {
			    return !($('#contact_preferredphone').val() == "Business" && phone_number == '');
			}, "Please fill out preferred number");

		jQuery.validator.addMethod("preferredHome", function(phone_number, element) {
			    return !($('#contact_preferredphone').val() == "Home" && phone_number == '');
			}, "Please fill out preferred number");

		jQuery.validator.addMethod("preferredAlternate", function(phone_number, element) {
			    return !($('#contact_preferredphone').val() == "Alternate" && phone_number == '');
			}, "Please fill out preferred number");
});

// AppDetail Add / Edit
$('#appdetail_add_page, #appdetail_edit_page').live('pagecreate',function(event){
	$("#appdetail").validate({
	  rules: {
	    'appdetail[cssi_carrierid]' : {
	      notBlank: true
	    },
		'appdetail[cssi_lineofbusinessid]' : {
	      notBlank: true
	    },
		'appdetail[cssi_applicationssubmitted]' : {
			required: true,
			min: 1,
			maxlength: 5
		}
	  }
	});
	
	jQuery.validator.addMethod('notBlank', function(val, el) {
	        return (val != '');
	    }, 'Please select an option.');	
});

// Lost Other 
$('#lost_other_page').live('pagecreate',function(event){
	validation_rules = {
	    'status_code' : {
	      notBlank: true
	  		}
		}
	validation_rules = $.extend(validation_rules,quick_task_validation)
	$("#lost_opportunity_other_form").validate({
	  rules: validation_rules
	});
	
	jQuery.validator.addMethod('notBlank', function(val, el) {
	        return (val != '');
	    }, '<br/>Please select an option.');	
});

// Callback Add / Edit
$('#callback_create, #callback_edit').live('pagecreate',function(event){
	$("#call_back_form").validate({
          focusInvalid: navigator.userAgent.toLowerCase().indexOf("android") < 0,
	  rules: {
	    'phone_number' : {
	      phoneUS: true,
		  required: true
	    },
		'phonecall_subject' : {
		 required: true	
		}
	  }
	});
	
	// Creates a US phone number ('### ### ####') validator
	jQuery.validator.addMethod("phoneUS", function(phone_number, element) {
	    phone_number = phone_number.replace(/\s+/g, ""); 
		return this.optional(element) || phone_number.length > 9 &&
			phone_number.match(/^(\([0-9]\d{2}\)|[0-9]\d{2})-?[0-9]\d{2}-?\d{4}$/);
	}, "Please specify a valid phone number in format ### ### ####");
});

//Create Activity - Task
$('#new_task').live('pagecreate',function(event){
	$("#new_task_form").validate({
	  rules: {
	    'task_subject' : {
		  required: true
	    }
	  }
	});
});

//Create Activity - Phone Call
$('#new_phonecall').live('pagecreate',function(event){
	$("#new_phonecall_form").validate({
	  rules: {
	    'phonecall_subject': {
		  required: true
	    },
		'phonecall_number': {
			required: true,
			phoneUS: true
		},
		'callback_datetime' : {
			required: true
		}
	  }
	});
	
	// Creates a US phone number ('### ### ####') validator
	jQuery.validator.addMethod("phoneUS", function(phone_number, element) {
	    phone_number = phone_number.replace(/\s+/g, ""); 
		return this.optional(element) || phone_number.length > 9 &&
			phone_number.match(/^(\([0-9]\d{2}\)|[0-9]\d{2})-?[0-9]\d{2}-?\d{4}$/);
	}, "Please specify a valid phone number in format ### ### ####");
});


// //Create Activity - Phone Call from a Contact
$('#new_phonecall_contact_page').live('pagecreate',function(event){
	$("#contact_phonecall_form").validate({
	  rules: {
		'phonecall_subject': {
		  required: true
	    },
		'phone_number': {
			required: true,
			phoneUS: true
		},
		'callback_datetime' : {
			required: true
		}
	  }
	});
	
	// Creates a US phone number ('### ### ####') validator
	jQuery.validator.addMethod("phoneUS", function(phone_number, element) {
	    phone_number = phone_number.replace(/\s+/g, ""); 
		return this.optional(element) || phone_number.length > 9 &&
			phone_number.match(/^(\([0-9]\d{2}\)|[0-9]\d{2})-?[0-9]\d{2}-?\d{4}$/);
	}, "Please specify a valid phone number in format ### ### ####");
});


//Create Activity - Appointment
$('#new_appointment').live('pagecreate',function(event){
	$("#new_appointment_form").validate({
	  rules: {
	    'appointment_subject' : {
		  required: true
	    },
		'appointment_datetime' : {
			required: true
		},
		'appointment_location' : {
			required: true
		}
		
	  }
	});
});

//Create Activity - Contact Appointment
$('#new_contact_appointment').live('pagecreate',function(event){
	$("#new_contact_appointment_form").validate({
	  rules: {
	    'appointment_subject' : {
		  required: true
	    },
		'appointment_datetime' : {
			required: true
		},
		'location' : {
			required: true
		}
	  }
	});
});

//Create Activity - task
$('#new_contact_task').live('pagecreate',function(event){
	$("#new_contact_task_form").validate({
	  rules: {
	    'task_subject' : {
		  required: true
	    }
	  }
	});
});

// pin reset 
$('#pin_reset_page').live('pagecreate',function(event){
	$("#reset_pin_form").validate({
	     rules: {
	        'enter_pin' : {
	          required: true,
	          number: true,
			  minlength: 4
	        },
			'verify_pin' : {
			      equalTo: "#enter_pin"
			    }
	     }
	    });

});

// mark as won oage 
$('#mark_as_won_page').live('pagecreate',function(event){
	$("#won_form").validate({
	     rules: quick_task_validation
	    });

});



// Appointment Add / Edit
$('#appointment_add_page').live('pagecreate',function(event){
	$("#appointment_form").validate();
});


// Appointment Add 
$('#appointment_edit_page').live('pagecreate',function(event){
	$("#appointment_edit_form").validate({
		rules: {
		    'appointment_subject' : {
			  required: true
		    }
		}
	});
});

// HACK ATTACK! - This is a fix for a known issue with JQuery Mobile related to focus and loss of input issues. - twitty.6.14.11
// Please check https://github.com/jquery/jquery-mobile/issues/756 to see if the issue has been addressed offically. - twitty.6.14.11

$('#dependent_new_page, #dependent_edit_page, #spouse_new_page, #spouse_edit_page, #contact_edit_page, #contact_new_page, #appdetail_add_page, #appdetail_edit_page, #callback_create, #callback_edit, #appointment_add_page, #appointment_edit_page, #lost_other_page, #pin_reset_page','#mark_as_won_page','#new_task', '#new_appointment', '#new_contact_task', '#new_phonecall_contact_page', '#new_contact_appointment').live('pageshow',function(event){
	$('input').one('keypress',function(ev) { $('<div></div>').appendTo('body') });
});

// Emulate iOS phone numbers formatting on Android
//if (navigator.userAgent.toLowerCase().indexOf("android") >= 0) {
   $.fn.usphone = function() {
        this.keyup(function(e) {
            // do not process del, backspace, escape, arrow left and arrow right characters
            var k = e.which;
            if (k == 8 || k == 46 || k == 27 || k == 37 || k == 39)
                return;
            // remove invalid characters
            var value = "";
            for (var i = 0; i < this.value.length; i++) {
                var ch = this.value[i];
                if (ch >= "0" && ch <= "9")
                    value += ch;
            }
			var ua = navigator.userAgent
			var androidversion = parseFloat(ua.slice(ua.indexOf("Android")+8)); 
			if ((androidversion >= 4.0 && value.length >= 10) || androidversion < 4.0 || ua.toLowerCase().indexOf("ios") >= 0 || ua.toLowerCase().indexOf("iphone") >= 0 || ua.toLowerCase().indexOf("ipad") >= 0)
			{				
            // remove extra characters
            if (value.length > 10)
                value = value.substring(0, 10);
            // insert formatting characters
            if (value.length >= 3)
                value = "(" + value.substring(0, 3) + ")" + value.substring(3);
            if (value.length > 5)
                value = value.substring(0, 5) + " " + value.substring(5);
            if (value.length > 9)
                value = value.substring(0, 9) + "-" + value.substring(9);
			// set new value
            var $this = this;
            var length = value.length;
            setTimeout(function() {
                $this.value = value;
                $this.setSelectionRange(length, length);
            }, 0);
			}
            
        });
    };

    $('#contact_edit_page, #contact_new_page, #callback_create, #callback_edit, #new_phonecall_contact_page, #new_phonecall').live('pagecreate', function() {
        $('[type^="tel"]').usphone();
    });
//}

// Automatically format 10 digits to phone number
$.fn.autoFormatPhone = function() {
    this.keyup(function(e) {
        // do not process del, backspace, escape, arrow left and arrow right characters
        var k = e.which;
        if (k == 8 || k == 46 || k == 27 || k == 37 || k == 39)
            return;
        var value = this.value;
        if (value.length == 10) {
            // check for all numbers
            for (var i = 0; i < value.length; i++) {
                var ch = value[i];
                if (ch < "0" || ch > "9")
                    return;
            }
            // insert formatting characters
            value = "(" + value.substring(0, 3) + ")" + value.substring(3);
            value = value.substring(0, 5) + " " + value.substring(5);
            value = value.substring(0, 9) + "-" + value.substring(9);
            // set new value
            var $this = this;
            var length = value.length;
            setTimeout(function() {
                $this.value = value;
                $this.setSelectionRange(length, length);
            }, 0);
        }
    });
};
