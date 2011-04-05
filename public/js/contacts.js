
function loadContactsAsync(page){
	$.post('Contact/get_contacts_page', { page: page },
		function(contacts) {				
			if (contacts && $.trim(contacts) != ""){
				$('ul#contact-list').append(contacts);
				
				$('.group-divider').each(function(){
				  var ids = $('[id='+this.id+']');
				  if(ids.length>1 && ids[0]==this)
				    $(ids[1]).remove();
				});
				
				loadContactsAsync(page + 1);
			} 
		}
	);
}