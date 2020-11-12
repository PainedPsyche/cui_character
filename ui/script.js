$(document).ready(function() {
    window.addEventListener('message', function(event) {
        if (event.data.action == 'setVisible') {
            if (event.data.show) {
                $('body').fadeIn(100)
            }
            else {
                $('body').fadeOut(100)
            }
        }
        else if (event.data.action == 'clearAllTabs') {
            $('.tablinks').hide()
            $('.tablinks').removeClass('active');
            $('.tabcontent').hide()
            $('.tabcontent').empty()
        }
        else if (event.data.action == 'enableTab') {
            $('button' + '#tab-' + event.data.tab + '.tablinks').show()
            $.get('pages/' + event.data.tab + '.html', function(data) {
                $('div#' + event.data.tab + '.tabcontent').html(data);
            });
        }
        else if (event.data.action == 'activateTab') {
            $('#tab-' + event.data.tab).addClass('active');
            $('#' + event.data.tab).show()
        }
    });
});

function closeWindow(save) {
    $.post('https://cui_character/close', JSON.stringify({save:save}));
}

function openTab(evt, tab) {
    let wasActive = $(evt.target).hasClass('active');

    $('.tabcontent').hide();
    $('.tablinks').removeClass('active');
    $('#' + tab).show();

    if (!wasActive) {
        $.post('https://cui_character/playSound', JSON.stringify({sound:'tabchange'}));
    }

    $(evt.target).addClass('active')
}

var accept = false;
$('.panelbottom button').on('click', function(evt) {
    evt.preventDefault();
    $.post('https://cui_character/playSound', JSON.stringify({sound:'buttonclick'}));
});

$('#main .menuclose').on('click', function(evt) {
    evt.preventDefault();
    if (evt.target.id == 'accept') {
        accept = true;
    }
    else if (evt.target.id == 'cancel') {
        accept = false;
    }
    $('.popup').fadeIn(100);
    $('.overlay').fadeIn(100);
    $('#main').css('pointer-events', 'none');
});

$('.popup button').on('click', function(evt) {
    evt.preventDefault();
    $('.popup').fadeOut(100);
    $('.overlay').fadeOut(100);
    $('#main').css('pointer-events', 'auto');
});

$('.popup #yes').on('click', function(evt) {
    evt.preventDefault();

    let save = false;
    if (accept == true) {
        save = true;
    }

    closeWindow(save)
});