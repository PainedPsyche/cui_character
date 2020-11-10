$(function () {
    window.addEventListener('message', function(event) {
        if (event.data.action == 'setVisible') {
            $("body").css("display", event.data.show ? "block" : "none");
        }
    });
});

function closeWindow(save) {
    console.log('hit close')
    $.post('https://cui_character/close', JSON.stringify({save:save}));
}

function openTab(evt, tab) {
    $('.tabcontent').hide()
    $('.tablinks').removeClass('active')
    $('#' + tab).show()
    $(evt.target).addClass('active')
}