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

// SAMPLE CODE for setting a min and a max length on a text box using the jquery validation plugin. - twitty.6.14.11
$('#dependent_add_page').live('pagecreate',function(event){
	$("#dependent_add").validate({
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
// SAMPLE CODE for creating a 'at least one from this group must be filled out' validation group. - twitty.6.14.11	
//jQuery.validator.addMethod('required_group', function(val, el) {
//	var $module = $(el).parents('div.panel');
//	return $("#dependent_add").find('.required_group:filled').length;
//	}, 'Please fill out at least one of these fields.');	
});

// HACK ATTACK! - This is a fix for a known issue with JQuery Mobile related to focus and loss of input issues. - twitty.6.14.11
// Please check https://github.com/jquery/jquery-mobile/issues/756 to see if the issue has been addressed offically. - twitty.6.14.11
$('#dependent_add_page').live('pageshow',function(event){
	$('input').one('keypress',function(ev) { $('<div></div>').appendTo('body') });
});