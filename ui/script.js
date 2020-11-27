var hairColors = {}
var lipstickColors = {}
var facepaintColors = {}
var blusherColors = {}

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
        else if (event.data.action == 'enableTabs') {
            for (const value of Object.values(event.data.tabs)) {
                $('button' + '#tab-' + value + '.tablinks').show()
                loadTabContent(value, event.data.character)
            }
        }
        else if (event.data.action == 'activateTab') {
            $('#tab-' + event.data.tab).addClass('active');
            $('#' + event.data.tab).show()
        }
        else if (event.data.action == 'reloadTab') {
            $('div#' + event.data.tab + '.tabcontent').empty();
            loadTabContent(event.data.tab, event.data.character)
        }
        else if (event.data.action == 'refreshViewButtons') {
            $('.cameraview').removeClass('active')
            $('#view' + event.data.view).addClass('active')
        }
        else if (event.data.action == 'refreshMakeup') {
            refreshMakeupUI(event.data.character, true)
        }
        else if (event.data.action == 'loadColorData') {
            hairColors = event.data.hair
            lipstickColors = event.data.lipstick
            facepaintColors = event.data.facepaint
            blusherColors = event.data.blusher
        }
    });
});

/*  camera control  */
function setView(event, view) {
    let wasActive = $(event.target).hasClass('active');
    $('.cameraview').removeClass('active')

    if (!wasActive) {
        $.post('https://cui_character/setCameraView', JSON.stringify({
            view: view,
        }));
    }

    $(event.target).addClass('active')
}

var moving = false
var lastOffsetX = 0
var lastOffsetY = 0
var lastScreenX = 0.5 * screen.width
var lastScreenY = 0.5 * screen.height

$('#cameracontrol').on('mousedown', function(event) {
    if (event.button == 0) {
        moving = true;
    }
});

$('#cameracontrol').on('mouseup', function(event) {
    if (moving && event.button == 0) {
        moving = false;
    }
});

$('#cameracontrol').on('mousemove', function(event) {
    if (moving == true) {
        let offsetX = event.screenX - lastScreenX;
        let offsetY = event.screenY - lastScreenY;
        if ((lastOffsetX > 0 && offsetX < 0) || (lastOffsetX < 0 && offsetX > 0)) {
            offsetX = 0
        }
        if ((lastOffsetY > 0 && offsetY < 0) || (lastOffsetY < 0 && offsetY > 0)) {
            offsetY = 0
        }
        lastScreenX = event.screenX;
        lastScreenY = event.screenY;
        lastOffsetX = offsetX;
        lastOffsetY = offsetY;
        $.post('https://cui_character/updateCameraRotation', JSON.stringify({
            x: offsetX,
            y: offsetY,
        }));
    }
});

$('#cameracontrol').on('wheel', function(event) {
    let zoom = event.originalEvent.deltaY / 2000;
    $.post('https://cui_character/updateCameraZoom', JSON.stringify({
        zoom: zoom,
    }));
});

/*  content loading     */
function loadTabContent(tabName, charData) {
    $.get('pages/' + tabName + '.html', function(data) {
        let tab =  $('div#' + tabName + '.tabcontent');
        tab.html(data);
        if (tabName == 'style') {
            loadOptionalContent(tab, charData);
            loadColorPalettes(tab)
        }
        refreshContentData(tab, charData);
        if (tabName == 'identity') {
            updatePortrait('mom');
            updatePortrait('dad');
        }
    });
}

function loadOptionalContent(element, charData) {
    let hair = element.find('#hair');
    let makeup = element.find('#makeup');
    let facialhair = element.find('#facialhair')
    let chesthair = element.find('#chesthair')

    hair.empty()
    makeup.empty()
    facialhair.empty()

    if (chesthair.hasClass('group')) {
        chesthair.removeClass('group')
    }

    if (chesthair.hasClass('group')) {
        chesthair.removeClass('group')
    }

    let hairpage = 'pages/optional/hair_';
    let makeuppage = 'pages/optional/makeup_';
    // male
    if (charData.sex == 0) {
        let suffix = 'male.html'
        hairpage = hairpage + suffix;
        makeuppage = makeuppage + suffix;
        facialhair.addClass('group')
        $.get('pages/optional/facialhair.html', function(data) {
            facialhair.html(data);
            loadColorPalettes(facialhair);
            refreshContentData(facialhair, charData);
        });
        chesthair.addClass('group')
        $.get('pages/optional/chesthair.html', function(data) {
            chesthair.html(data);
            loadColorPalettes(chesthair);
            refreshContentData(chesthair, charData);
        });
    }
    // female
    else if (charData.sex == 1) {
        let suffix = 'female.html'
        hairpage = hairpage + suffix;
        makeuppage = makeuppage + suffix;
    }

    $.get(hairpage, function(data) {
        hair.html(data);
        loadColorPalettes(hair);
        refreshContentData(hair, charData);
    });

    $.get(makeuppage, function(data) {
        makeup.html(data);
        loadColorPalettes(makeup);
        refreshMakeupUI(charData, false)
        refreshContentData(makeup, charData);
    });
}

function loadColorPalettes(element) {
    $(element).find('.palette').each(function() {
        let colorData = null
        if ($(this).hasClass('hair')) {
            colorData = hairColors;
        }
        else if ($(this).hasClass('lipstick')) {
            colorData = lipstickColors;
        }
        else if ($(this).hasClass('facepaint')) {
            colorData = facepaintColors;
        }
        else if ($(this).hasClass('blusher')) {
            colorData = blusherColors;
        }

        $(this).empty()
        let id = $(this).attr('id')
        for (const color of colorData) {
            let inputTag = '<input type="radio" name="' + id + '" ' + 'value="' + color.index + '"/>';
            let newElement = $('<div class="radiocolor">' + inputTag + '<label></label></div>');
            newElement.find('input[type="radio"] + label').css('background-color', color.hex);
            $(this).append(newElement);
        }
    });
}

var accept = false;

var popupCallback = null;
var popupVal = false

/*  window controls   */
function openPopup(data, callback, val) {
    $('.popup .title').text(data.title)
    $('.popup .message').text(data.message)
    $('.popup').fadeIn(100);
    $('.overlay').fadeIn(100);
    $('#main').css('pointer-events', 'none');
    $('#cameracontrol').css('pointer-events', 'none');
    popupCallback = callback
    popupVal = val
}

function closePopup() {
    $('.popup').fadeOut(100);
    $('.overlay').fadeOut(100);
    $('#main').css('pointer-events', 'auto');
    $('#cameracontrol').css('pointer-events', 'auto');

    if (popupCallback) {
        popupCallback = null;
    }
    popupVal = false
}

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

    let action = accept ? 'save' : 'discard';
    let message = 'Are you sure you want to ' + action + ' your changes and exit?';
    let popupData = { 
        title: 'confirmation', 
        message: message
    };
    openPopup(popupData, closeWindow, accept);
});

$('.popup #no').on('click', function(evt) {
    evt.preventDefault();
    closePopup();
});

$('.popup #yes').on('click', function(evt) {
    evt.preventDefault();

    if (popupCallback) {
        popupCallback(popupVal)
    }

    closePopup();
});

/*  option/value ui controls   */

$(document).on('click', '.list .controls button', function(evt) {
    let list = $(this).siblings('select').first();
    let numOpt = list.children('option').length
    let oldVal = list.find('option:selected');
    let newVal = null;

    if ($(this).hasClass('left')) {
        if (list.prop('selectedIndex') == 0) {
            newVal = list.prop('selectedIndex', numOpt - 1);
        }
        else {
            newVal = oldVal.prev();
        }
    }
    else if ($(this).hasClass('right')) {
        if (list.prop('selectedIndex') == numOpt - 1) {
            newVal = list.prop('selectedIndex', 0);
        }
        else {
            newVal = oldVal.next();
        }
    }
    oldVal.prop('selected', false)
    newVal.prop('selected', true)
    newVal.trigger('change')
});

/*  option/value change effects     */
function updateGender(value) {
    $.post('https://cui_character/updateGender', JSON.stringify({
        value: value,
    }));
}

function updateHeadBlend(key, value) {
    $.post('https://cui_character/updateHeadBlend', JSON.stringify({
        key: key,
        value: value,
    }));
}

function updateFaceFeature(key, value, index) {
    $.post('https://cui_character/updateFaceFeature', JSON.stringify({
        key: key,
        value: value,
        index: index,
    }));
}

function updateEyeColor(value) {
    $.post('https://cui_character/updateEyeColor', JSON.stringify({
        value: value,
    }));
}

function updateHairColor(key, value, highlight) {
    $.post('https://cui_character/updateHairColor', JSON.stringify({
        key: key,
        value: value,
        highlight: highlight,
    }));
}

function updateHeadOverlay(key, keyPaired, value, index, isOpacity) {
    $.post('https://cui_character/updateHeadOverlay', JSON.stringify({
        key: key,
        keyPaired: keyPaired,
        value: value,
        index: index,
        isOpacity: isOpacity,
    }));
}

function updateOverlayColor(key, value, index, colortype) {
    $.post('https://cui_character/updateOverlayColor', JSON.stringify({
        key: key,
        value: value,
        index: index,
        colortype: colortype,
    }));
}

function updateComponent(drawable, dvalue, texture, tvalue, index) {
    $.post('https://cui_character/updateComponent', JSON.stringify({
        drawable: drawable,
        dvalue: dvalue,
        texture: texture,
        tvalue: tvalue,
        index: index,
    }));
}

function updatePortrait(elemId) {
    let portraitImgId = '#parents' + elemId;
    let portraitName = $('select#' + elemId + '.headblend').find(':selected').data('portrait');
    $(portraitImgId).attr('src', 'https://nui-img/char_creator_portraits/' + portraitName);
}

// working around unintuitive/bad behavior:
// https://forum.jquery.com/topic/alert-message-when-clicked-selected-radio-button
var radioChecked = false
$(document).on('mouseenter', 'input:radio[name=sex] + label', function(evt) {
    if ($(this).prev().is(':checked')) {
        radioChecked = true;
    }
    else {
        radioChecked = false;
    }
});

$(document).on('click', 'input:radio[name=sex]', function(evt) {
    if(radioChecked == false)
    {
        let popupData = {
            title: 'confirmation', 
            message: 'Changing your character\'s gender will reset all current customizations. Are you sure you want to do this?'
        };
        openPopup(popupData, function(target) {
            target.prop('checked', true);
            updateGender(target.val());
        }, $(this));
    }
    return false;
});

$(document).on('click', '.palette input:radio + label', function(evt) {
    let radio = $(this).prev();
    if (radio.is(':not(:checked)')) {
        radio.prop('checked', true);
        radio.trigger('change');
    }
});

$(document).on('change', 'select.headblend', function(evt) {
    updatePortrait($(this).attr('id'));
    updateHeadBlend($(this).attr('id'), $(this).val());
});

$(document).on('change', 'select.eyecolor', function(evt) {
    updateEyeColor($(this).val());
});

$(document).on('change', 'select.component.hairstyle', function(evt) {
    // NOTE: hairstyle is a special case as you don't get to select texture for it
    updateComponent($(this).attr('id'), $(this).val(), 'hair_2', 0, $(this).data('index'));
});

$(document).on('refresh', 'input[type=range].headblend', function(evt) {
    let valueLeft = $(this).parent().siblings('.valuelabel.left');
    let valueRight = $(this).parent().siblings('.valuelabel.right');
    valueLeft.text((100 - $(this).val()).toString() + '%');
    valueRight.text($(this).val().toString() + '%');
});

$(document).on('input', 'input[type=range].headblend', function(evt) {
    $(this).trigger('refresh')
    updateHeadBlend($(this).attr('id'), $(this).val());
});

$(document).on('input', 'input[type=range].facefeature', function(evt) {
    updateFaceFeature($(this).attr('id'), $(this).val(), $(this).data('index'));
});

$(document).on('change', 'select.headoverlay', function(evt) {
    // find the opacity range slider id for this feature
    let pairedId = $(this).parents().eq(2).find('.headoverlay').eq(1).attr('id');
    updateHeadOverlay($(this).attr('id'), pairedId, $(this).val(), $(this).data('index'), false);
});

$(document).on('refresh', 'input[type=range].headoverlay', function(evt) {
    let valueCenter = $(this).parent().siblings('.valuelabel.center');
    valueCenter.text($(this).val().toString() + '%');
});

$(document).on('input', 'input[type=range].headoverlay', function(evt) {
    $(this).trigger('refresh')

    // find the style select list id for which this is the opacity value
    let pairedId = $(this).parents().eq(2).find('.headoverlay').eq(0).attr('id');
    updateHeadOverlay($(this).attr('id'), pairedId, $(this).val(), $(this).data('index'), true);
});

$(document).on('change', '.palette.haircolor input:radio', function(evt) {
    // NOTE: 'name' attribute value is taken from palette's id
    let highlight = $(this).attr('name') != 'hair_color_1' ? true : false;
    updateHairColor($(this).attr('name'), $(this).val(), highlight)
});

$(document).on('change', '.palette.overlaycolor input:radio', function(evt) {
    // NOTE: 'name' attribute value is taken from palette's id
    let palette = $(this).parents().eq(1)
    updateOverlayColor($(this).attr('name'), $(this).val(), palette.data('index'), palette.data('colortype'))
});

$(document).on('change', 'select.makeuptype', function(evt) {
    let value = $(this).find('option:selected').val();
    $.post('https://cui_character/updateMakeupType', JSON.stringify({type:value}));
});

function refreshMakeupUI(charData, setDefaultMakeup) {
    let makeupcontrol = $(document).find('#makeup .list').first()
    let makeuppage = 'pages/optional/makeup_'
    let type = charData.makeup_type;

    switch (type) {
        // 'None'
        case 0:
            $.post('https://cui_character/clearMakeup', JSON.stringify({}));
            break;
        // 'Eye Makeup'
        case 1:
            makeuppage += 'eye.html'
            break;
        // 'Face Paint'
        case 2:
            makeuppage += 'facepaint.html'
            break;
        // 'Blusher'
        case 3:
            makeuppage += 'blusher.html'
            break;
        default:
            break;
    }

    // Remove all content
    makeupcontrol.nextAll('div').remove();

    $.get(makeuppage, function(data) {
        let makeupcontent = makeupcontrol.after(data).next()
        loadColorPalettes(makeupcontent);
        refreshContentData(makeupcontent, charData);

        if (setDefaultMakeup) {
            let makeupoption = makeupcontent.find('select option').first()
            if (makeupoption) {
                makeupoption.prop('selected', true)
                makeupoption.trigger('change')
            }
        }
    });
}

/*  interface and current character synchronization     */
function refreshContentData(element, data) {
    for (const [key, value] of Object.entries(data)) {
        let keyId = '#' + key;
        let control = element.find(keyId);
        if (control.length) {
            let controltype = control.prop('nodeName');
            if (controltype == 'SELECT') { // arrow lists
                control.val(value);
            }
            else if (controltype == 'INPUT') { // range sliders
                // NOTE: Check out property 'type' (ex. range) if this isn't unique enough
                control.val(value)
                control.trigger('refresh')
            }
            else if (controltype == 'DIV') { // radio button groups
                let radio = control.find(':radio[value=' + value + ']');
                radio.prop('checked', true);
            }
        }
    }
}

/* TODO: Possibly add more sounds (mouseover?)
$('.panelbottom button').mouseenter(function(evt) {
    console.log('hovered')
    $.post('https://cui_character/playSound', JSON.stringify({sound:'mouseover'}));
});

$('.radioitem input:radio:not(:checked) + label').hover(function(evt) {
    console.log('hovered')
    $.post('https://cui_character/playSound', JSON.stringify({sound:'mouseover'}));
});
*/