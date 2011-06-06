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
		  max: 1000
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
		  max: 1000
	    }
	  }
	});	
});

$('#contact_edit_page').live('pagecreate',function(event){
	jQuery.validator.addMethod("phoneUS", function(phone_number, element) {
	    phone_number = phone_number.replace(/\s+/g, ""); 
		return this.optional(element) || phone_number.length > 9 &&
			phone_number.match(/^(\([2-9]\d{2}\)|[2-9]\d{2})-?[2-9]\d{2}-?\d{4}$/);
	}, "Please specify a valid phone number in format ### ### ####");
	
	$("#contact_edit").validate({
	  rules: {
	    'contact[mobilephone]' : {
		  phoneUS: true
	    },
		'contact[telephone1]' : {
		  phoneUS: true
		},
		'contact[telephone2]' : {
		  phoneUS: true
		},
		'contact[telephone3]' : {
		  phoneUS: true
		},
		'contact[emailaddress1]' : {
		  email: true,
		  maxlength: 255
		},
		'contact[cssi_weight]' : {
		  min: 0,
		  max: 1000		  
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
	jQuery.validator.addMethod('required_group', function(val, el) {
		var $module = $(el).parents('div.panel');
		return $("#contact_edit").find('.required_group:filled').length;
		}, 'Please fill out at least one of these fields.');
});


// HACK ATTACK! - This is a fix for a known issue with JQuery Mobile related to focus and loss of input issues. - twitty.6.14.11
// Please check https://github.com/jquery/jquery-mobile/issues/756 to see if the issue has been addressed offically. - twitty.6.14.11
$('#dependent_new_page, #dependent_edit_page, #spouse_new_page, #spouse_edit_page, #contact_edit_page').live('pageshow',function(event){
	$('input').one('keypress',function(ev) { $('<div></div>').appendTo('body') });
});