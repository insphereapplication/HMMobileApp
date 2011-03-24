$(document).ready(function() {
   	$('.UpdateStatus').click(function() {

   	  	var apptids = $('input:checkbox:checked.custom').map(function(){
			return this.value
		});
		appts = {};
		for ( var i=0, len=apptids.length; i<len; ++i ){
		  appts['appointments[]'] = apptids[i]
		}
		// for (var id in apptids){
		// 	appts['blerg[]'] = id;
		// }
	  $.get($(this).href, {'appointments[]' : ["0","1"]});
	});
 });