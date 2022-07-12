$(document).off('click.tab.data-api');
    $(document).on('click.tab.data-api', '[data-toggle="tab"]', function (e) {
        e.preventDefault();
        var tab = $($(this).attr('href'));
        var activate = !tab.hasClass('active');
        $('div.tab-content>div.tab-pane.active').removeClass('active');
        $('ul.nav.nav-tabs>li.active').removeClass('active');
        if (activate) {
            $(this).tab('show')
        }
    });
