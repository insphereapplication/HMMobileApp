function completeSelectedActivities() {
    var ids = $("input:checked", $(".scrollable-listview")).parent().map(function() {
        return $(this).attr("activity-id");
    }).get();
    if (ids.length > 0)
        location.href = location.href.replace(/\?.*$/, '') + '?' +
                $.param({ "selected-activity": ids });
    else
        $.post("/app/Activity/complete_activities_alert");
}

function onRowClick(e, width, url) {
    if (e.pageX < width)
        $("input", $(e.target).parent()).click();
    else
        window.open(url);
}

function clearFilter() {
    $("#activity_type_filter").val("All").selectmenu("refresh");
    $("#activity_status_filter").val("Today").selectmenu("refresh");
    $("#activity_priority_filter").val("All").selectmenu("refresh");
}

function getFilterData() {
    return {
        "type": $("#activity_type_filter").val(),
        "status": $("#activity_status_filter").val(),
        "priority": $("#activity_priority_filter").val()
    };
}

function getFilterText() {
    return getSelectValue("activity_type_filter") + ", " +
            getSelectValue("activity_status_filter") + ", " +
            getSelectValue("activity_priority_filter");
}

function getSelectValue(id) {
    var select = $("#" + id)[0];
    var txt = select.options[select.selectedIndex].text;
    var index = txt.indexOf(" ");
    if (index > 0)
        txt = txt.substr(0, index);
    return txt;
}
