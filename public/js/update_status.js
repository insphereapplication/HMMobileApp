$(document).ready(function() {
   	$('.UpdateStatus').click(function() {

   	  	var apptids = $('input:checkbox:checked.custom').map(function(){
			return this.value
		});
		appts = {};
		for ( var i=0, len=apptids.length; i<len; ++i ){
		  appts['appointments[' + i + ']'] = apptids[i];
		}

	  $.get($(this).href, appts);
	});
 });