function validate(form){
	alert('I have begun to validate');
	if ((form.elements["callback_datetime"].value.length==0) ||form.elements["callback_datetime"].value==null)) {
      	alert('Please choose a callback date and time.');
		return false;
   }
   else { return true; }	
}