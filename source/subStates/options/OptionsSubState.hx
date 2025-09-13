package subStates.options;

import backend.game.SaveData.SettingType;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.addons.display.FlxSliceSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.menu.Alphabet;
import objects.menu.options.*;
import states.PlayState;
import states.menu.MainMenuState;

class OptionsSubState extends MusicBeatSubState
{
    var mainShit:Array<String> = [
        "preferences",
        "gameplay",
        "appearance",
        #if TOUCH_CONTROLS "mobile", #end
        "adjust offsets",
        "controls",
    ];
    var optionShit:Map<String, Array<String>> =
	[
        "preferences" => [
            #if desktop
            "Window Size",
            #end
            "Flashing Lights",
            "Cutscenes",
            #if desktop
            "FPS Counter",
            "Unfocus Pause",
            #end
            #if desktop
            "Delay on Unpause",
            #end
            #if DISCORD_RPC
            "Discord RPC",
            #end
            "Shaders",
            "Low Quality",
        ],
		"gameplay" => [
			"Can Ghost Tap",
			"Downscroll",
			"Middlescroll",
            #if desktop
            "Framerate Cap",
            #end
            "Hitsounds",
            "Hitsound Volume",
		],
		"appearance" => [
            "Note Splashes",
            "Hold Splashes",
            #if desktop
			"Antialiasing",
            #end
            "Split Holds",
            "Static Hold Anim",
            "Single Rating",
			"Song Timer",
			"Song Timer Info",
			"Song Timer Style",
		],
        #if TOUCH_CONTROLS
        "mobile" => [
            "Invert Swipes",
            "Button Opacity",
            "Hitbox Opacity",
        ]
        #end
	];
    
    var restartTimer:Float = 0;
    var forceRestartOptions:Array<String> = [ // options that you gotta restart the song for them to reload sorry
        "Can Ghost Tap", // you can't cheat >:]
        "Low Quality",
        "Split Holds" // it dont work
    ];
    var reloadOptions:Array<String> = [ // options that need some manual reloading on playstate when changed
        "Antialiasing",
        "Song Timer",
        "Shaders"
    ];
    // anything else already updates automatically
    var playState:PlayState = null;
    
    var curCat:String = 'gameplay';

    var curSelected:Int = 0;
    var startCounter:Int = 0;
    var storedSelected:Map<String, Int> = [];

    var grpItems:FlxTypedGroup<Alphabet>;
    var grpAttachs:FlxGroup;
    var restartTxt:Alphabet;
    var infoBG:FlxSprite;
    var infoTxt:FlxText;
    
    var curAttach:FlxBasic;

    var bg:FlxSprite;
    var bgColors:Map<String, FlxColor> = [
		"main" 		    => 0xFFCF68F7,
        "preferences"   => 0xFFFF4949,
		"gameplay"	    => 0xFF83E6AA,
		"appearance"    => 0xFFF36B8F,
	];
    
    public function new(?playState:PlayState)
    {
        super();
        this.playState = playState;
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        if(playState != null)
        {
            for(i in ["Downscroll", "Middlescroll"])
                if(PlayState.hasModchart)
                    forceRestartOptions.push(i);
                else
                    reloadOptions.push(i);
        }

        #if !html5
        CoolUtil.playMusic('lilBitBack');
        #end
		DiscordIO.changePresence("Options - Tweakin' the Settings");

        bg = new FlxSprite();
        if(playState == null)
            bg.loadGraphic(Paths.image('menu/backgrounds/menuDesat'));
        else
        {
            bg.makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
            bg.alpha = 0;
            FlxTween.tween(bg, {alpha: 0.8}, 0.1);
        }
        bg.screenCenter();
        add(bg);

        grpItems = new FlxTypedGroup<Alphabet>();
        grpAttachs = new FlxGroup();
        add(grpItems);
        add(grpAttachs);

        restartTxt = new Alphabet(FlxG.width / 2, 12, "restart the song to apply some settings", true);
        restartTxt.align = CENTER;
        restartTxt.scale.set(0.45,0.45);
        restartTxt.updateHitbox();
        restartTxt.color = 0xFFFF0000;
        restartTxt.alpha = 0.0;
        add(restartTxt);

        infoBG = new FlxSprite().makeGraphic(FlxG.width + 20, FlxG.height, 0xFF000000);
        infoBG.visible = false;
        infoBG.alpha = 0.6;
        add(infoBG);

        infoTxt = new FlxText(0, 0, FlxG.width * 0.8, 'balls');
		infoTxt.setFormat(Main.gFont, 28, 0xFFFFFFFF, CENTER);
        //infoTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5); // kinda useless now
        add(infoTxt);

        spawnItems('main');

        #if TOUCH_CONTROLS
		createPad("back", [FlxG.cameras.list[FlxG.cameras.list.length - 1]]);
		#end
    }

    var inputDelay:Float = 0.1;

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        infoBG.visible = (curCat != 'main');
        if(curCat != 'main')
            updateItemPos(elapsed * 8);

        if(restartTimer > 0.0)
            restartTimer -= elapsed;
        else if(restartTxt.alpha > 0.0)
            restartTxt.alpha -= elapsed / 0.4;

        infoTxt.y = FlxMath.lerp(infoTxt.y, FlxG.height - infoTxt.height - 12, elapsed * 8);
        infoBG.y = infoTxt.y - 12;

        if(inputDelay > 0.0)
        {
            inputDelay -= elapsed;
            return;
        }

        if(Controls.justPressed(BACK))
        {
            if(curCat == 'main')
            {
                persistentDraw = true;
                if(playState == null)
                    Main.switchState(new MainMenuState());
                else
                {
                    CoolUtil.playMusic();
                    close();
                }
            }
            else
            {
                FlxG.sound.play(Paths.sound('menu/cancelMenu'));
                spawnItems('main');
            }
        }

        if(Controls.justPressed(UI_UP))
            changeSelection(-1);
        if(Controls.justPressed(UI_DOWN))
            changeSelection(1);

        if(curCat == 'main')
        {
            if(Controls.justPressed(ACCEPT) && startCounter >= mainShit.length)
            {
                switch(mainShit[curSelected])
                {
                    case "controls":
                        /*FlxG.sound.play(Paths.sound('METAL-BAR'));
                        Logs.print('FUCK YOU!!', WARNING);*/
                        persistentDraw = false;
                        openSubState(new ControlsSubState());
                    case "adjust offsets":
                        persistentDraw = false;
                        openSubState(new OffsetsSubState());
                    default:
                        FlxG.sound.play(Paths.sound('menu/scrollMenu'));
                        spawnItems(mainShit[curSelected]);
                }
            }
        }
        else
        {
            var curOption:String = optionShit.get(curCat)[curSelected];
            if(Controls.justPressed(ACCEPT))
            {
                if(Std.isOfType(curAttach, OptionCheckmark))
                {
                    FlxG.sound.play(Paths.sound('menu/scrollMenu'));
                    var check:OptionCheckmark = cast curAttach;
                    check.setValue(!check.value);
                    SaveData.data.set(curOption, check.value);
                    // custom stuff
                    /*if(curOption == "")
                    {

                    }*/
                    SaveData.save();
                    checkReload();
                }
            }

            if(Std.isOfType(curAttach, OptionSelector))
            {
                var holdMax:Float = 0.4;
                var selec:OptionSelector = cast curAttach;
                if(Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT) || selec.holdTimer >= holdMax)
                {
                    var selChange:Int = -(Controls.pressed(UI_LEFT) ? 1 : 0) + (Controls.pressed(UI_RIGHT) ? 1 : 0);
                    if(selChange != 0)
                    {
                        selec.changeSelection(selChange);
                        SaveData.data.set(selec.label, selec.value);
                        SaveData.save();

                        // custom stuff
                        if(selec.label == "Window Size")
                            SaveData.updateWindowSize();
                        #if TOUCH_CONTROLS
                        else if(selec.label == "Button Opacity")
                            pad.togglePad(true);
                        #end
                        // only happens when youre not holding the selector
                        if(selec.holdTimer < holdMax)
                        {
                            if(selec.label.startsWith('Hitsound'))
                                CoolUtil.playHitSound();
                        }
                        
                        checkReload();
                    }

                    if(selec.holdTimer >= holdMax)
                        selec.holdTimer = holdMax - 0.005; // 0.02
                    /*else
                        FlxG.sound.play(Paths.sound('menu/scrollMenu'));*/
                }
                
                selec.arrowL.animation.play(Controls.pressed(UI_LEFT) ? "push" : "idle", true);
                selec.arrowR.animation.play(Controls.pressed(UI_RIGHT)? "push" : "idle", true);
                
                if(Controls.pressed(UI_LEFT) || Controls.pressed(UI_RIGHT)
                && selec.holdTimer <= holdMax
                && Std.isOfType(selec.options[0], Int))
                    selec.holdTimer += elapsed;
                if(Controls.released(UI_LEFT) || Controls.released(UI_RIGHT))
                    selec.holdTimer = 0;
            }
        }
    }

    function updateItemPos(lerpTime:Float)
    {
        var itemY:Array<Float> = [];
        for(item in grpItems.members)
        {
            itemY[item.ID] = 100 + (80 * item.ID);
        }
        while(itemY[curSelected] > FlxG.height - 260)
        {
            for(i in 0...itemY.length)
                itemY[i] -= 10;
        }

        var maxAttach:Float = 0;
        for(rawItem in grpAttachs.members)
        {
            var daWidth = grpItems.members[rawItem.ID].width;
            if(Std.isOfType(rawItem, OptionSelector))
            {
                var item:OptionSelector = cast rawItem;
                var daCalc = daWidth + item.getWidth() + 42;
                if(daCalc > maxAttach)
                    maxAttach = daCalc;
            }
            else if(Std.isOfType(rawItem, OptionCheckmark))
            {
                var item:OptionCheckmark = cast rawItem;
                var daCalc = daWidth + item.width + 42;
                if(daCalc > maxAttach)
                    maxAttach = daCalc;
            }
        }

        var posItem:Float = (FlxG.width / 2) - (maxAttach / 2);
        var posAttach:Float = posItem + maxAttach;

        for(item in grpItems.members)
        {
            item.x = FlxMath.lerp(item.x, posItem, lerpTime);
            item.y = FlxMath.lerp(item.y, itemY[item.ID], lerpTime);
        }
        for(rawItem in grpAttachs.members)
        {
            var daItem = grpItems.members[rawItem.ID];
            if(Std.isOfType(rawItem, FlxSprite))
            {
                var item:FlxSprite = cast rawItem;
                item.x = FlxMath.lerp(item.x, posAttach - item.width, lerpTime);
                item.y = daItem.y + daItem.height / 2 - item.height / 2;
            }
            if(Std.isOfType(rawItem, OptionSelector))
            {
                var selec:OptionSelector = cast rawItem;
                selec.setX(FlxMath.lerp(selec.arrowL.x, posAttach - selec.getWidth(), lerpTime));
                selec.setY(daItem.y + daItem.height / 2);
                if(selec.ID != curSelected)
                {
                    selec.holdTimer = 0.0;
                    for(arrow in [selec.arrowL, selec.arrowR])
                        if(arrow.animation.curAnim.name == 'push')
                            arrow.animation.play('idle', true);
                }
            }
        }
    }

    function spawnItems(curCat:String)
    {
        this.curCat = curCat;
        grpItems.clear();
        grpAttachs.clear();

        if(bgColors.exists(curCat))
            bg.color = bgColors.get(curCat);
        
        if(!storedSelected.exists(curCat))
            storedSelected.set(curCat, 0);

        curSelected = storedSelected.get(curCat);

        infoTxt.visible = (curCat != 'main');
        if(curCat == 'main')
        {
            for(i in 0...mainShit.length)
            {
                var item = new Alphabet(0, 0, mainShit[i], true);
                grpItems.add(item);
                item.align = CENTER;
                item.updateHitbox();
                item.ID = i;

                item.x = FlxG.width / 2;
                item.y = (FlxG.height / 2) - (item.height / 2);
                item.y += (100 * i);
                item.y -= (100 * ((mainShit.length - 1) / 2));

                if(playState == null)
                    startCounter++;
                else if(startCounter < mainShit.length) {
                    item.y += 20;
                    item.alpha = 0;

                    var newAlpha = 0.4;
                    if(i == curSelected)
                        newAlpha = 1.0;
    
                    FlxTween.tween(item, {y: item.y - 20, alpha: newAlpha}, 0.15, {ease: FlxEase.quadInOut, startDelay: 0.05 * i,
                    onComplete: function(twn:FlxTween) {
                        startCounter++;
                    }});
                }
            }
        }
        else
        {
            var curOption = optionShit.get(curCat);
            for(i in 0...curOption.length)
            {
                var item = new Alphabet(0, 0, curOption[i], true);
                grpItems.add(item);
                item.scale.set(0.75,0.75);
                item.updateHitbox();
                item.ID = i;

                if(!SaveData.displaySettings.exists(curOption[i])) continue;

                var daSave = SaveData.displaySettings.get(curOption[i]);
                if(daSave[1] == CHECKMARK)
                {
                    var check = new OptionCheckmark(SaveData.data.get(curOption[i]), 0.75);
                    check.ID = i;
                    grpAttachs.add(check);
                }
                if(daSave[1] == SELECTOR)
                {
                    var selec = new OptionSelector(curOption[i]);
                    grpAttachs.add(selec);
                    selec.ID = i;
                }
            }
            updateItemPos(1);
        }
        changeSelection();

        #if TOUCH_CONTROLS
        Controls.resetTimer();
        #end
    }
    
    function changeSelection(change:Int = 0)
    {
        if(startCounter < mainShit.length)
            return;

        if(change != 0)
            FlxG.sound.play(Paths.sound('menu/scrollMenu'));
        
        curSelected += change;
        curSelected = FlxMath.wrap(curSelected, 0, grpItems.length - 1);
        storedSelected.set(curCat, curSelected);

        for(item in grpItems.members)
        {
            item.alpha = 0.4;
            if(item.ID == curSelected)
                item.alpha = 1.0;
        }

        if(curCat == 'main') return;

        if(SaveData.displaySettings.exists(optionShit.get(curCat)[curSelected]))
        {
            infoTxt.text = SaveData.displaySettings.get(optionShit.get(curCat)[curSelected])[2];
            infoTxt.screenCenter(X);
            infoTxt.y = FlxG.height - infoTxt.height - 12 - 18;
        }

        for(rawItem in grpAttachs.members)
        {
            if(Std.isOfType(rawItem, FlxSprite))
            {
                var item:FlxSprite = cast rawItem;
                item.alpha = 0.4;
                if(item.ID == curSelected)
                    item.alpha = 1.0;
            }
            if(Std.isOfType(rawItem, OptionSelector))
            {
                var selec:OptionSelector = cast rawItem;
                var itemAlpha:Float = 0.4;
                if(selec.ID == curSelected)
                    itemAlpha = 1.0;
                for(item in selec.members)
                    item.alpha = itemAlpha;
            }

            if(rawItem.ID == curSelected)
                curAttach = rawItem;
        }
    }

    function checkReload():Void
    {
        if(playState == null) return;

        var curOption:String = optionShit.get(curCat)[curSelected];
        if(reloadOptions.contains(curOption))
            playState.updateOption(curOption);

        if(forceRestartOptions.contains(curOption))
        {
            restartTxt.alpha = 1.0;
            restartTimer = 5.0;
        }
    }
}