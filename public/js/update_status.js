$(document).ready(function() {
   	$('.UpdateStatus').click(function() {

		var apptids = $('input:checkbox:checked.custom').map(function(){
			return this.value
		});
		
		notes = '&notes=' +  $('#status_note').val();
		appointments = '&appointments[]=' + $.makeArray(apptids).join('&appointments[]=');
		window.location.href = $(this).attr('href') + appointments + notes;
		return false;
	});
	$('.UpdateStatusWon').click(function() {

		// if(confirm('Click OK to Confirm this Opportunity as Won')){			
			var apptids = $('input:checkbox:checked.custom').map(function(){
				return this.value
			});
			
			notes = '&notes=' +  $('#status_note').val();
			appointments = '&appointments[]=' + $.makeArray(apptids).join('&appointments[]=');
			window.location.href = $(this).attr('href') + appointments + notes;
			return false;
		// }
		// else{
		// 	return false;
		// }
	});
	$('.UpdateStatusLost').click(function() {

		// if(confirm('Click OK to Confirm this Opportunity as Lost')){			
			var apptids = $('input:checkbox:checked.custom').map(function(){
				return this.value
			});
	
			notes = '&notes=' +  $('#status_note').val();
			appointments = '&appointments[]=' + $.makeArray(apptids).join('&appointments[]=');
			window.location.href = $(this).attr('href') + appointments + notes;
			return false;
		// }
		// 	else{
		// 		return false;
		// 	}
	});
 });