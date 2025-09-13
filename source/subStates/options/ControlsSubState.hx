package subStates.options;

import backend.song.Conductor;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepad.FlxGamepadModel;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import flixel.input.gamepad.id.PS4ID;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import objects.hud.HealthIcon;
import objects.menu.Alphabet;
import objects.menu.options.OptionSelector;
import objects.note.Note;
import objects.note.Strumline;
import states.PlayState;

class ControlsSubState extends MusicBeatSubState
{
    var downscroll:Bool = SaveData.data.get('Downscroll');
    var downMult:Int = 0;
    var strumline:Strumline;
    var deadIcon:HealthIcon;

    var gamepadSelector:OptionSelector;
    var grpItems:FlxTypedGroup<Alphabet>;
    var grpTxtOne:FlxTypedGroup<FlxText>;
    var grpTxtTwo:FlxTypedGroup<FlxText>;
    var backspaceTxt:FlxText;

    var curBind:Int = 0;
    var curLane:Int = 0;
    var changinBinds:Int = 0; // 0 = not changing // 1 = selecting lane // 2 = changing binds
    var isGamepad:Bool = false;
    var curSelected:Int = 0;
    var optionShit:Array<String> = [
        'edit binds',
        'clear binds',
    ];

    var bindArrows:FlxTypedGroup<FlxText>;

    var curGamepad:FlxGamepad;

    public function new()
    {
        super();
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        downMult = downscroll ? -1 : 1;
        var bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuInvert'));
        bg.color = 0xFFC500C5;
        bg.screenCenter();
        add(bg);

        strumline = new Strumline(FlxG.width / 2, null, false, true, true, PlayState.assetModifier);
        strumline.downscroll = downscroll;
        strumline.updateHitbox();
        add(strumline);

        deadIcon = new HealthIcon();
        deadIcon.setIcon("bf", true);
        deadIcon.setAnim(0); // die bf
        deadIcon.x = FlxG.width - deadIcon.width - 128;
        deadIcon.y = strumline.strumGroup.members[0].y - deadIcon.height / 2;
        add(deadIcon);

        add(grpTxtOne = new FlxTypedGroup<FlxText>());
        add(grpTxtTwo = new FlxTypedGroup<FlxText>());
        for(i in 0...5)
        {
            for(j in 0...2)
            {
                var bindTxt = new FlxText(0, 0, 0, ((j == 0) ? "a" : "b") + i);
                bindTxt.setFormat(Main.gFont, 24, 0xFFFFFFFF, CENTER);
                bindTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
                (j == 0 ? grpTxtOne : grpTxtTwo).add(bindTxt);
                bindTxt.ID = i;
            }
        }
        grpTxtOne.ID = 0;
        grpTxtTwo.ID = 1;

        add(grpItems = new FlxTypedGroup<Alphabet>());
        for(i in 0...optionShit.length)
        {
            var item = new Alphabet(FlxG.width / 2, 0, optionShit[i], true);
            item.align = CENTER;
            item.scale.set(0.75,0.75);
            item.updateHitbox();
            item.y = FlxG.height - item.height - 10;
            if(!downscroll)
                item.y -= ((item.height + 10) * (optionShit.length - 1 - i));
            else
                item.y = 10 + (item.height + 10) * i;
            grpItems.add(item);
            item.ID = i;
        }
        gamepadSelector = new OptionSelector('keyboard', false);
        gamepadSelector.options = ['keyboard', 'gamepad'];
        var gamepadPos = grpItems.members[downscroll ? grpItems.members.length - 1 : 0].y + (70 / 2);
        gamepadSelector.setY(gamepadPos + (downscroll ? 60 : -70));
        add(gamepadSelector);
        changeSelection();
        changeGamepad();
        spawnBinds();
        
        add(bindArrows = new FlxTypedGroup<FlxText>());
        for(i in 0...2)
        {
            var arrow = new FlxText(0, 0, 0, (i == 0) ? ">" : "<");
            arrow.setFormat(Main.gFont, 24, 0xFFFFFFFF, CENTER);
            arrow.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
            arrow.visible = false;
            bindArrows.add(arrow);
            arrow.ID = i;
        }
        setArrowPos(1);

        backspaceTxt = new FlxText(0, 10, 0, "");
        backspaceTxt.setFormat(Main.gFont, 24, 0xFFFFFFFF, CENTER);
        backspaceTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
        backspaceTxt.visible = false;
        add(backspaceTxt);
        if(downscroll)
            backspaceTxt.y = FlxG.height - backspaceTxt.height - 10;

        #if TOUCH_CONTROLS
		createPad("back", [FlxG.cameras.list[FlxG.cameras.list.length - 1]]);
		#end
    }

    var allBinds:Array<String> = Controls.changeableControls;

    function spawnBinds()
    {
        var allGroups = [grpTxtOne, grpTxtTwo];
        for(group in allGroups)
        {
            for(bind in group.members)
            {
                bind.color = 0xFFFFFFFF;
                var button:Null<Int> = Controls.allControls.get(allBinds[bind.ID])[isGamepad ? 1 : 0][group.ID];
                if(button == null)
                    button = -1;

                if(isGamepad)
                    bind.text = formatKey(FlxPad.toStringMap[button]);
                else
                    bind.text = formatKey(FlxKey.toStringMap[button]);

                bind.y = strumline.strumGroup.members[0].y + 70;
                if(group == grpTxtTwo)
                    bind.y += 50; // 50

                if(downscroll)
                    bind.y -= bind.height + 50 + 70 * 2;

                if(bind.ID <= 3)
                    bind.x = strumline.strumGroup.members[bind.ID].x;
                else
                    bind.x = deadIcon.x + deadIcon.width / 2;

                bind.x -= bind.width / 2;
            }
        }

        var allBinds:Array<FlxText> = [];
        for(group in allGroups)
            for(bind in group.members)
                allBinds.push(bind);

        for(bind in allBinds)
        for(dBind in allBinds)
            if(bind.text == dBind.text
            && dBind != bind
            && bind.text != '---'
            && dBind.text != '---')
                bind.color = dBind.color = 0xFFFF0000;
    }

    final formatNum:Array<String> = ['ZERO','ONE','TWO','THREE','FOUR','FIVE','SIX','SEVEN','EIGHT','NINE'];
    final ps4Binds:Map<String, String> = [
        "LB" => "L1",
        "LT" => "L2",
        "RB" => "R1",
        "RT" => "R2",
        "A"  => "CROSS",
        "B"  => "CIRCLE",
        "X"  => "SQUARE",
        "Y"  => "TRIANGLE",
        "START" => "OPTIONS",
        "SELECT" => "SHARE",
    ];
    final nSwitchBinds:Map<String, String> = [
        "LB" => "L",
        "LT" => "ZL",
        "RB" => "R",
        "RT" => "ZR",
        "A"  => "B",
        "B"  => "A",
        "X"  => "Y",
        "Y"  => "X",
        "START" => "PLUS",
        "SELECT" => "MINUS",
    ];

    function formatKey(rawKey:Null<String>):String
    {
        var fKey:String = '---';
        if(rawKey != null && rawKey != 'NONE')
        {
            fKey = rawKey;
            for(num in formatNum)
            {
                if(fKey.contains(num))
                    fKey = fKey.replace(num, '${formatNum.indexOf(num)}');
            }

            if(fKey.contains('NUMPAD'))
            {
                fKey = fKey.replace('NUMPAD', '');
                fKey += '#';
            }

            if(isGamepad)
            {
                fKey = fKey.replace("BACK", "SELECT"); // select fica menos confuso (eu acho)
                
                fKey = fKey.replace("DPAD_", "D-");

                if(fKey.contains("SHOULDER") || fKey.contains("TRIGGER"))
                {
                    fKey = fKey.replace("LEFT", "L");
                    fKey = fKey.replace("RIGHT", "R");
                    if(fKey.contains("SHOULDER"))
                    {
                        fKey = fKey.replace("_SHOULDER", "");
                        fKey += "B";
                    }
                    if(fKey.contains("TRIGGER"))
                    {
                        fKey = fKey.replace("_TRIGGER", "");
                        fKey += "T";
                    }
                }

                if(fKey.contains("STICK"))
                {
                    fKey = fKey.replace("LEFT_STICK",  "L-STICK");
                    fKey = fKey.replace("RIGHT_STICK", "R-STICK");
                    fKey = fKey.replace("_DIGITAL", "");
                    fKey = fKey.replace("_", "\n");
                }

                if(curGamepad != null)
                {
                    var convertMap:Int = 0;
                    if([PS4, PSVITA].contains(curGamepad.detectedModel))
                        convertMap = 1;
                    if([SWITCH_PRO].contains(curGamepad.detectedModel))
                        convertMap = 2;
                    
                    if(convertMap > 0)
                    {
                        for(bind => newBind in ((convertMap == 1) ? ps4Binds : nSwitchBinds))
                            if(fKey == bind)
                                fKey = newBind;
                    }
                }
            }
        }
        return fKey;
    }
    
    var inputDelay:Float = 0.1;
    var flickTimer:Float = 0;
    var rawAnalogs:Array<Bool> = [];
    var deadzone:Float = 0.1;

    function checkAnalogs()
    {
        rawAnalogs = [
            curGamepad.analog.value.LEFT_STICK_X  < -deadzone,
            curGamepad.analog.value.LEFT_STICK_X  > deadzone,
            curGamepad.analog.value.LEFT_STICK_Y  < -deadzone,
            curGamepad.analog.value.LEFT_STICK_Y  > deadzone,
            curGamepad.analog.value.RIGHT_STICK_X < -deadzone,
            curGamepad.analog.value.RIGHT_STICK_X > deadzone,
            curGamepad.analog.value.RIGHT_STICK_Y < -deadzone,
            curGamepad.analog.value.RIGHT_STICK_Y > deadzone,
        ];
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        curGamepad = FlxG.gamepads.lastActive;

        for(strum in strumline.strumGroup.members)
            if(strum.animation.curAnim.name == 'confirm' && strum.animation.curAnim.finished)
                strum.playAnim('static');

        backspaceTxt.visible = (changinBinds == 2);
        if(backspaceTxt.visible)
        {
            backspaceTxt.text = (!isGamepad ? "PRESS BACKSPACE TO CLEAR" : "CLICK AN ANALOG STICK TO CLEAR");
            backspaceTxt.screenCenter(X);
        }

        if(changinBinds == 1)
        {
            setArrowPos(elapsed * 16);
        }
        else
        {
            for(arrow in bindArrows.members)
                if(arrow.visible)
                    arrow.visible = false;
        }

        if(inputDelay > 0.0)
        {
            inputDelay -= elapsed;
            return;
        }

        // flickering current 
        for(group in [grpTxtOne, grpTxtTwo])
        {
            for(item in group.members)
            {
                if(changinBinds == 2 && group.ID == curLane)
                {
                    if(item.ID == curBind)
                    {
                        if(flickTimer >= 0.1)
                        {
                            flickTimer = 0;
                            item.visible = !item.visible;
                        }
                    }
                    else
                        item.visible = true;
                }
                else
                    item.visible = true;
            }
        }

        if(changinBinds == 2 && !rawAnalogs.contains(true))
        {
            flickTimer += elapsed;
            var jpKey:Bool = FlxG.keys.justPressed.ANY;
            var jpPad:Bool = false;
            if(curGamepad != null)
                jpPad = curGamepad.justPressed.ANY;

            var key:Int = -1;
            if(!isGamepad)
            {
                key = FlxG.keys.firstJustPressed();
                if(key == FlxKey.BACKSPACE)
                    key = FlxKey.NONE;
            }
            else if(curGamepad != null)
            {
                key = curGamepad.firstJustPressedID();
                if(key == FlxPad.LEFT_STICK_CLICK
                || key == FlxPad.RIGHT_STICK_CLICK)
                    key = FlxPad.NONE;
                
                if(curGamepad.detectedModel == PS4)
                {
                    var rawKey = curGamepad.firstJustPressedRawID();
                    if(rawKey == PS4ID.L2)
                        key = FlxPad.LEFT_TRIGGER;
                    if(rawKey == PS4ID.R2)
                        key = FlxPad.RIGHT_TRIGGER;
                }

                checkAnalogs();
                var digitalAnalogs:Array<FlxPad> = [
                    FlxPad.LEFT_STICK_DIGITAL_LEFT,
                    FlxPad.LEFT_STICK_DIGITAL_RIGHT,
                    FlxPad.LEFT_STICK_DIGITAL_UP,
                    FlxPad.LEFT_STICK_DIGITAL_DOWN,
                    FlxPad.RIGHT_STICK_DIGITAL_LEFT,
                    FlxPad.RIGHT_STICK_DIGITAL_RIGHT,
                    FlxPad.RIGHT_STICK_DIGITAL_UP,
                    FlxPad.RIGHT_STICK_DIGITAL_DOWN,
                ];
                for(i in 0...rawAnalogs.length)
                {
                    if(rawAnalogs[i])
                        key = digitalAnalogs[i];
                }
            }

            if(!isGamepad)
            {
                if(jpKey)
                    setKeyBind(key, true);
                if(jpPad)
                    setKeyBind(key, false);
                return;
            }
            else
            {
                if(jpKey)
                    setKeyBind(key, false);
                if(jpPad)
                    setKeyBind(key, true);
                return;
            }
        }

        var gameAlpha:Float = 1.0;
        if(changinBinds > 0)
        {
            gameAlpha = 0.1;
            for(item in grpItems.members)
                item.alpha = gameAlpha;
        }
        for(item in gamepadSelector.members)
            item.alpha = gameAlpha;

        if(curGamepad != null)
            checkAnalogs();

        var curOpt:String = optionShit[curSelected];
        if(Controls.justPressed(BACK))
        {
            if(changinBinds == 0)
                close();
            if(changinBinds == 1)
            {
                changinBinds = 0;
                changeLane();
                changeSelection();
            }
        }
        if(Controls.justPressed(ACCEPT))
        {
            if(changinBinds < 2 && curOpt == 'edit binds')
            {
                FlxG.sound.play(Paths.sound('menu/scrollMenu'));
                changinBinds++;
                changeLane();
            }
        }
        if(changinBinds == 1)
        {
            if(Controls.justPressed(UI_UP) || Controls.justPressed(UI_DOWN))
                changeLane(true);
        }
        if(changinBinds > 0)
            return;

        gamepadSelector.arrowL.animation.play(Controls.pressed(UI_LEFT) ? "push" : "idle");
        gamepadSelector.arrowR.animation.play(Controls.pressed(UI_RIGHT)? "push" : "idle");

        if(Controls.justPressed(ACCEPT))
        {
            FlxG.sound.play(Paths.sound('menu/scrollMenu'));
            switch(curOpt)
            {
                case 'clear binds':
                    for(i in allBinds)
                    {
                        var daNum:Int = isGamepad ? 1 : 0;

                        var newKey:Array<Null<Int>> = [null, null];

                        Controls.allControls.get(i)[daNum] = newKey;
                    }
                    Controls.save();
                    spawnBinds();
            }
        }

        if(Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT))
            changeGamepad(true);

        if(Controls.justPressed(UI_UP))
            changeSelection(-1);
        if(Controls.justPressed(UI_DOWN))
            changeSelection(1);
    }

    function setArrowPos(lerpTime:Float = 0)
    {
        var arrowX:Array<Float> = [0,0];
        var arrowY:Float = 0;
        var group:FlxTypedGroup<FlxText> = [grpTxtOne, grpTxtTwo][curLane];

        var arrowWidth:Float = bindArrows.members[0].width;

        arrowX = [group.members[0].x - arrowWidth - 10, group.members[3].x + group.members[3].width + 10];
        arrowY = group.members[0].y + group.members[0].height / 2;

        for(arrow in bindArrows.members)
        {
            arrow.x = FlxMath.lerp(arrow.x, arrowX[arrow.ID], lerpTime);
            arrow.y = FlxMath.lerp(arrow.y, arrowY - arrow.height / 2, lerpTime);
            arrow.visible = (lerpTime == 1 ? false : true);
        }
    }

    function setKeyBind(key:Int = -1, valid:Bool = false)
    {
        FlxG.sound.play(Paths.sound('menu/scrollMenu'));

        if(valid)
        {
            //var newKey:Array<Dynamic> = [[null, null],[null, null]];
            Controls.allControls.get(allBinds[curBind])[isGamepad ? 1 : 0][curLane] = key;
            Controls.save();
        }
        spawnBinds();
        curBind++;

        if(!valid)
            curBind = 5;

        if(curBind > 4)
        {
            curBind = 0;
            changinBinds = 0;
            changeLane();
            changeSelection();
            return;
        }
    }

    function changeGamepad(change:Bool = false)
    {
        if(change)
        {
            FlxG.sound.play(Paths.sound('menu/scrollMenu'));
            isGamepad = !isGamepad;
            spawnBinds();
        }
        
        gamepadSelector.changeSelection(change ? 1 : 0);
        gamepadSelector.setX((FlxG.width / 2) - gamepadSelector.getWidth() / 2);
    }

    function changeSelection(change:Int = 0)
    {
        if(change != 0)
            FlxG.sound.play(Paths.sound('menu/scrollMenu'));

        curSelected += change;
        curSelected = FlxMath.wrap(curSelected, 0, optionShit.length - 1);

        for(item in grpItems.members)
        {
            item.alpha = 0.4;
            if(item.ID == curSelected)
                item.alpha = 1.0;
        }
    }

    function changeLane(change:Bool = false)
    {
        if(change)
        {
            FlxG.sound.play(Paths.sound('menu/scrollMenu'));
            curLane = ((curLane == 0) ? 1 : 0);
        }

        for(group in [grpTxtOne, grpTxtTwo])
        {
            for(item in group.members)
            {
                item.alpha = 0.4;
                if(curLane == group.ID || changinBinds == 0)
                    item.alpha = 1.0;
            }
        }
    }
}