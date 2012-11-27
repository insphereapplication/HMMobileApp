$(document).bind("pagecreate", function(e) {
    $("#search_phone", e.target).autoFormatPhone();
});

function clearFilter() {
    $("#search_name").val("");
    $("#search_email").val("");
    $("#search_phone").val("");
    return false;
}

function getFilterData() {
    return {
        "name": $("#search_name").val(),
        "email": $("#search_email").val(),
        "phone": $("#search_phone").val()
    };
}

function getFilterText() {
    var result = "";
    var txt = $("#search_name").val();
    if (txt.length > 0)
        result = txt;
    txt = $("#search_email").val();
    if (txt.length > 0) {
        if (result.length > 0)
            result += ", ";
        result += txt;
    }
    txt = $("#search_phone").val();
    if (txt.length > 0) {
        if (result.length > 0)
            result += ", ";
        result += txt;
    }
    return result;
}
