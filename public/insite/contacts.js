function clearFilter() {
    $("#contact_filter").val("all").selectmenu("refresh");
    $("#search_input").val("");
}

function getFilterData() {
    return { "filter": $("#contact_filter").val(), "search_terms": $("#search_input").val() };
}

function getFilterText() {
    var select = $("#contact_filter")[0];
    var txt = select.options[select.selectedIndex].text;
    var index = txt.indexOf(" ");
    if (index > 0)
        txt = txt.substr(0, index);
    var result = txt;
    txt = $("#search_input").val();
    if (txt.length > 0)
        result += ", " + txt;
    return result;
}
