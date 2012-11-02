function ScrollView(page, url, pageSize) {
    var $page = $(page),
        $filter = $page.find(".scrollable-list-filter"),
        $filterTxt = $filter.find(".scrollable-list-filter-txt")
                            .find("span.ui-btn-text"),
        $scroll = $page.find(".iscroll-wrapper"),
        scroll = $scroll.jqmData("iscrollview"),
        $list = $scroll.find("ul.scrollable-listview"),
        filterTxt, requestData, currentpage, pages;

    function adjustScrollView() {
        scroll.resizeWrapper();
        scroll.refresh();
    }

    $filter.bind({
        collapse: adjustScrollView,
        expand: adjustScrollView
    });

    $filter.find(".scrollable-list-filter-find").click(function() {
        $filter.trigger("collapse");
        reset();
    });

    $filter.find(".scrollable-list-filter-clear").click(function() {
        $filter.trigger("collapse");
        clearFilter();
        reset();
    });

    function getContent(pageNum, pageSize, reset, fnc) {
        requestData.page = pageNum;
        requestData.pageSize = pageSize;
        requestData.reset = reset;
        $.ajax({
            url: url,
            data: requestData,
            success: function(data) {
                var rows = data.split("<li");
                fnc((rows.length > 1) ? rows.slice(1, pageSize) : []);
            }
        });
    }

    $scroll.bind({
        iscroll_onpullup: function() {
            if (pages[0].length > 0) {
                var item = $list.find("li").eq($list.length - 5);
                $list.append("<li" + pages[0].join("<li"));
                scroll.refresh(null, null, function() {
                    if (item.length > 0)
                        scroll.scrollToElement(item[0], 0);
                });
                pages[0] = pages[1];
                getContent(currentpage++, pageSize, false, function(data) {
                    pages[1] = data;
                });
            }
            else
                scroll.refresh();
        }
    });

    function reset() {
        requestData = getFilterData();
        var txt = getFilterText();
        if (txt.length > 0)
            txt = " " + txt;
        $filterTxt.text(filterTxt + txt);
        currentpage = 3;
        pages = [[], []];
        $list.empty();
        getContent(0, pageSize * 3, true, function(data) {
            if (data.length > 0) {
                $list.append("<li" + data.splice(0, pageSize).join("<li"));
                scroll.refresh();
            }
            if (data.length > 0)
                pages[0] = data.splice(0, pageSize);
            if (data.length > 0)
                pages[1] = data;
        });
    }

    filterTxt = $filterTxt.html();
    var index = filterTxt.indexOf("<");
    if (index > 0)
        filterTxt = filterTxt.substr(0, index);
    filterTxt = $.trim(filterTxt);
    reset();
}
