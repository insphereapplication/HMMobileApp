function autodividersSelector(li) {
    return li.text().slice(0, 1).toUpperCase();
}

function getContent(pageNum, pageSize) {
    var result = "";
    $.ajax({
        async: false,
        url: "/app/Contact/get_jqm_contacts_page",
        data: { page: pageNum, pageSize: pageSize },
        success: function(data) {
            result = data;
        }
    });
    return result;
}
