function ScrollView(page, pageSize) {
    var $page = $(page),
        $filter = $page.find(".scrollable-list-filter"),
        $filterTxt = $filter.find(".scrollable-list-filter-txt"),
        $scroll = $page.find(".iscroll-wrapper"),
        $list = $scroll.find("ul.ui-listview"),
        scroll = $scroll.jqmData("iscrollview"),
        currentPage = 0;

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
        
    });

    $filter.find(".scrollable-list-filter-clear").click(function() {
        $filter.trigger("collapse");
        
    });

    $scroll.bind({
        iscroll_onpulldown: function() {
            currentPage--;
            if (currentPage < 0)
                currentPage = 0;
            var newContent = getContent(currentPage, pageSize);
            if (newContent) {
                //$list.prepend(newContent).listview("refresh");
                $list.empty().append(newContent).listview("refresh");
                scroll.refresh();
            }
        },
        iscroll_onpullup: function() {
            currentPage++;
            var newContent = getContent(currentPage, pageSize);
            if (newContent) {
                //$list.append(newContent).listview("refresh");
                $list.empty().append(newContent).listview("refresh");
                scroll.refresh(null, null, function() {
                    // scroll.scrollToElement($list.find("li:last-child")[0], 400);
                    scroll.scrollToElement($list.find("li:first-child")[0], 400);
                });
            }
            else
                // reset current page to previous value because no more data
                currentPage--;
        }
    });

    $list.listview({
        autodividersSelector: autodividersSelector
    });
}
