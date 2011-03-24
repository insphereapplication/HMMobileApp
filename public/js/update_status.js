$(document).ready(function() {
   	$('.UpdateStatus').click(function() {
   	  	var values = $('input:checkbox:checked.custom').reduce(function(sum, appointment){
			sum['appointments[]'] = appointment.value;
		});
		
	  $.get($(this).href, values);
	});
 });