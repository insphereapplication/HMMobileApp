$(document).ready(function() {
  $('a.UpdateStatus').click(function() {
		$(this).unbind("click");
	  var apptids = $('input:checkbox:checked.custom').map(function(){
			return this.value
		});
		
		notes = '&notes=' +  $('#status_note').val();
		appointments = '&appointments[]=' + $.makeArray(apptids).join('&appointments[]=');
		var redirectUrl = $(this).attr('href') + appointments + notes;
		window.location.href = redirectUrl;
		return false;
		
	});
	
	$('li.NoContact').click(function(e) {
	    $(this).removeAttr('href');
	});
	

});