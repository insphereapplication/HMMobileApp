$(document).ready(function() {
   	$('.UpdateStatus').click(function() {

		var apptids = $('input:checkbox:checked.custom').map(function(){
			return this.value
		});

		appointments = "&appointments[]=" + $.makeArray(apptids).join(",");
		window.location.href = $(this).attr('href') + appointments;
		return false;
	});
	$('.UpdateStatusWon').click(function() {

		if(confirm('Note: You will not be able to make changes to this opportunity on your device after marking it as won. Proceed?')){			
			var apptids = $('input:checkbox:checked.custom').map(function(){
				return this.value
			});
	
			appointments = "&appointments[]=" + $.makeArray(apptids).join(",");
			window.location.href = $(this).attr('href') + appointments;
			return false;
		}
		else{
			return false;
		}
	});
	$('.UpdateStatusLost').click(function() {

		if(confirm('Note: You will not be able to make changes to this opportunity on your device after marking it as lost. Proceed?')){			
			var apptids = $('input:checkbox:checked.custom').map(function(){
				return this.value
			});
	
			appointments = "&appointments[]=" + $.makeArray(apptids).join(",");
			window.location.href = $(this).attr('href') + appointments;
			return false;
		}
		else{
			return false;
		}
	});
 });