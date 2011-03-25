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


function checkEmail(myForm) {
	
	
	if ((myForm.elements["contact[emailaddress1]"].value.length==0) ||(myForm.elements["contact[emailaddress1]"].value==null)) {
      return true;
   }
   else { 
	if (/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(myForm.elements["contact[emailaddress1]"].value)){
			return true;
			}
			alert("Invalid E-mail Address! Please re-enter.");
			return false;
	}
}