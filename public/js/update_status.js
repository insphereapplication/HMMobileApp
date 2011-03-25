$(document).ready(function() {
   	$('.UpdateStatus').click(function() {

		var apptids = $('input:checkbox:checked.custom').map(function(){
			return this.value
		});

		appointments = "&appointments[]=" + $.makeArray(apptids).join(",");
		window.location.href = $(this).attr('href') + appointments;
		return false;
	});
 });