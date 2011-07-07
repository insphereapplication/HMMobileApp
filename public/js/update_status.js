$(document).ready(function() {
   	$('a.UpdateStatus').click(function() {
		
		var apptids = $('input:checkbox:checked.custom').map(function(){
			return this.value
		});
		
		notes = '&notes=' +  $('#status_note').val();
		appointments = '&appointments[]=' + $.makeArray(apptids).join('&appointments[]=');
		window.location.href = $(this).attr('href') + appointments + notes;
		$(this).attr("href", "#");
		return false;
		
	});
	
	$('li.NoContact').click(function(e) {
	    $(this).removeAttr('href');
	});
	

});