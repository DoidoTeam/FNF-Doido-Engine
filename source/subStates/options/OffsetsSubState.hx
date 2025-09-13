package subStates.options;

import backend.song.Conductor;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.sound.FlxSound;
import objects.hud.HealthIcon;
import objects.menu.Alphabet;
import objects.menu.options.OptionSelector;
import states.PlayState;

class OffsetsSubState extends MusicBeatSubState
{
    var strumline:OffsetStrumline;

    var downscroll:Bool = SaveData.data.get('Downscroll');
    var downMult:Int = 1;

    static var curSelected:Int = 0;
    var optionShit = ["Music Offset", "Input Offset", "Test Input"];
    var grpOptions:FlxTypedGroup<Alphabet>;
    var grpSelectors:FlxTypedGroup<OptionSelector>;

    var offsetCurBeat:Int = 0;
    var _offsetCurBeat:Int = 0;
    var crochet:Float = Conductor.calcBeat(85);
    var songPos:Float = Conductor.musicOffset;
    var offsetMusic:FlxSound;
    var testingInput:Bool = false;
    var countdown:Int = 0;
    var countdownSpr:Alphabet;

    var averageTxt:FlxText;
    var notesHit:Int = 0;
    var offsetAverage:Int = 0;

    var loopedTimes:Int = 0;

    public function new()
    {
        super();
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        if(FlxG.sound.music != null)
            FlxG.sound.music.pause();
        offsetMusic = new FlxSound().loadEmbedded(Paths.music('settingOff'), true, false, function() {
            loopedTimes++;
        });
        offsetMusic.play();
        FlxG.sound.list.add(offsetMusic);

        downMult = downscroll ? -1 : 1;
        var bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuInvert'));
        bg.color = 0xFF7000CC;
        bg.screenCenter();
        add(bg);

        countdownSpr = new Alphabet(0, 0, "holyshit", true);
        countdownSpr.align = CENTER;
        countdownSpr.updateHitbox();
        countdownSpr.x = FlxG.width - FlxG.width / 4;
        countdownSpr.screenCenter(Y);
        add(countdownSpr);
        countdownSpr.text = "";

        averageTxt = new FlxText(0, 0, 0, "Holy Shit");
        averageTxt.setFormat(Main.gFont, 24, 0xFFFFFFFF, CENTER);
        averageTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
        averageTxt.y = (downscroll ? FlxG.height - averageTxt.height - 180 : 180);
        changeAverageTxt('');
        add(averageTxt);

        /*strumline = new Strumline(
            FlxG.width - FlxG.width / 4, null,
            downscroll,
            true, true, PlayState.assetModifier
        );*/
        strumline = new OffsetStrumline(downscroll);
        add(strumline);

        grpOptions = new FlxTypedGroup<Alphabet>();
        var optionHeight:Float = (70 * 0.75) + 10;
        for(i in 0...optionShit.length)
        {
            var option = new Alphabet(60, 0, optionShit[i], true);
            option.scale.set(0.75,0.75);
            option.updateHitbox();
            option.ID = i;
            option.y = FlxG.height / 2 + (optionHeight * i);
            option.y -= (optionHeight * (optionShit.length / 2));
            grpOptions.add(option);
        }
        add(grpOptions);

        grpSelectors = new FlxTypedGroup<OptionSelector>();
        var mizera:Array<String> = ['Song Offset', 'Input Offset'];
        for(i in 0...2)
        {
            var daOption = grpOptions.members[i];
            var selector = new OptionSelector(mizera[i]);
            //selector.options = SaveData.displaySettings.get(mizera[i])[3];
            selector.wrapValue = false;
            selector.setY(daOption.y + optionHeight / 2);
            selector.setX(daOption.x + 450);
            selector.ID = i;
            grpSelectors.add(selector);
        }
        add(grpSelectors);

        #if TOUCH_CONTROLS
		createPad("back", [FlxG.cameras.list[FlxG.cameras.list.length - 1]]);
		#end

        changeOption();
        offsetBeatHit();
    }

    function changeAverageTxt(newText:String)
    {
        averageTxt.text = newText;
        averageTxt.x = FlxG.width - FlxG.width / 4 - averageTxt.width / 2;
    }

    function changeOption(change:Int = 0)
    {
        if(change != 0) FlxG.sound.play(Paths.sound('menu/scrollMenu'));

        curSelected += change;
        curSelected = FlxMath.wrap(curSelected, 0, optionShit.length - 1);

        for(item in grpOptions.members)
        {
            item.alpha = 0.4;
            if(item.ID == curSelected && !testingInput)
                item.alpha = 1.0;
        }
        for(selec in grpSelectors.members)
        for(item in [selec.arrowL, selec.text, selec.arrowR])
        {
            item.alpha = 0.4;
            if(selec.ID == curSelected)
                item.alpha = 1.0;
        }
    }

    var holdTimer:Float = 0;

    function changeSelector(change:Int = 0)
    {
        if(change != 0 && holdTimer < 0.5)
            FlxG.sound.play(Paths.sound('menu/scrollMenu'));
        
        var selector = grpSelectors.members[curSelected];
        selector.changeSelection(change);
        selector.setX(grpOptions.members[selector.ID].x + 450);

        SaveData.data.set(['Song Offset','Input Offset'][curSelected], grpSelectors.members[curSelected].value);
        SaveData.save();

        if(curSelected == 0)
        {
            songPos -= change;
            if(PlayState.instance != null)
                PlayState.instance.updateOption('Song Offset');
        }
    }

    function offsetBeatHit()
    {
        cameras[0].zoom = 1.025; // 1.05, 1.025
        //Logs.print("hello " + offsetCurBeat);
        if(testingInput && countdown <= 4)
        {
            countdownSpr.text = ["3","2","1","GO",""][countdown];
            countdown++;
        }

        var rawOffsetMusicTime:Float = offsetMusic.time + (offsetMusic.length * loopedTimes);
        var realOffsetMusicTime:Float = rawOffsetMusicTime + Conductor.musicOffset;
        if(Math.abs(songPos - realOffsetMusicTime) >= 20)
        {
            Logs.print('synced $songPos to $realOffsetMusicTime');
            songPos = realOffsetMusicTime;
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        songPos += elapsed * 1000;
        _offsetCurBeat = Math.floor(songPos / crochet);
        while(_offsetCurBeat != offsetCurBeat)
        {
            if(_offsetCurBeat > offsetCurBeat)
                offsetCurBeat++;
            else
                offsetCurBeat = _offsetCurBeat;
            offsetBeatHit();
        }

        var pressed:Array<Bool> = [
            Controls.pressed(LEFT),
            Controls.pressed(DOWN),
            Controls.pressed(UP),
            Controls.pressed(RIGHT),
            Controls.pressed(ACCEPT),
        ];
        var justPressed:Array<Bool> = [
            Controls.justPressed(LEFT),
            Controls.justPressed(DOWN),
            Controls.justPressed(UP),
            Controls.justPressed(RIGHT),
            Controls.justPressed(ACCEPT),
        ];

        cameras[0].zoom = FlxMath.lerp(cameras[0].zoom, 1.0, elapsed * 6);
        
        if(!testingInput)
        {
            if(Controls.justPressed(BACK))
            {
                cameras[0].zoom = 1.0;
                offsetMusic.stop();
                if(FlxG.sound.music != null)
                    FlxG.sound.music.play();
                close();
            }
        
            if(Controls.justPressed(UI_UP))
                changeOption(-1);
            if(Controls.justPressed(UI_DOWN))
                changeOption(1);
        
            if(curSelected != 2)
            {
                if(Controls.justPressed(UI_LEFT)) {
                    holdTimer = 0;
                    changeSelector(-1);
                }
                if(Controls.justPressed(UI_RIGHT)) {
                    holdTimer = 0;
                    changeSelector(1);
                }
                if(Controls.pressed(UI_LEFT) || Controls.pressed(UI_RIGHT))
                    holdTimer += elapsed;
                else
                    holdTimer = 0;
        
                if(holdTimer >= 0.5)
                {
                    function toInt(bool:Bool):Int
                        return bool ? 1 : 0;
                    changeSelector(toInt(Controls.pressed(UI_RIGHT))-toInt(Controls.pressed(UI_LEFT)));
                }
            }
            else if(Controls.justPressed(ACCEPT))
            {
                Logs.print('started testing!!');
                testingInput = true;
                changeOption();
                countdown = 0;
                notesHit = 0;
                offsetAverage = 0;
                changeAverageTxt('');
                for(i in 0...4)
                {
                    var note = new OffsetNote(
                        (Math.floor(songPos / crochet) * crochet) + crochet * (i + 5),
                        (i == 3)
                    );
                    strumline.notesGrp.add(note);
                    note.offset.y -= 2000;
                    /*var note = new Note();
                    note.updateData(
                        (Math.floor(songPos / crochet) * crochet) + crochet * (i + 5),
                        i, (i == 3) ? "end_test" : "none", PlayState.assetModifier
                    );
                    note.reloadSprite();
                    strumline.addNote(note);
                    note.x -= 1000;*/
                }
            }
        }
        else
        {
            for(note in strumline.notesGrp)
            {
                note.updateHitbox();
                note.offset.x += note.frameWidth * note.scale.x / 2;
                note.offset.y += note.frameHeight * note.scale.y / 2;
                var thisStrum = strumline.strum;
                
                // follows the strum
                var offsetY = (note.songTime - songPos) * (1.0 * 0.45);
                
                note.angle = thisStrum.angle;
                CoolUtil.setNotePos(note, thisStrum, downscroll ? 180 : 0, 0, offsetY);

                if(justPressed.contains(true))
                {
                    if(Math.abs(note.songTime - songPos) <= 100
                    && note.visible)
                    {
                        strumline.playAnim("confirm");
                        note.visible = false;
                        notesHit++;
                        var noteDiff:Int = Math.floor(note.songTime - songPos);
                        offsetAverage += noteDiff;
                        changeAverageTxt('${noteDiff}ms');
                    }
                }
                if(note.lastNote)
                {
                    if(note.songTime - songPos <= -100 || !note.visible)
                    {
                        Logs.print('ended');
                        testingInput = false;
                        if(notesHit != 0) {
                            offsetAverage = Math.floor(offsetAverage / notesHit);
                            changeAverageTxt('Recommended Input Offset: ${-offsetAverage}ms');
                        } else {
                            changeAverageTxt('No Notes Hit');
                        }
                        
                        changeOption();
                    }
                }
            }
            if(!testingInput)
            {
                for(note in strumline.notesGrp)
                    strumline.notesGrp.remove(note);
            }
        }
        
        if(testingInput)
        {
            if(pressed.contains(true))
            {
                if(!["pressed", "confirm"].contains(strumline.strum.animation.curAnim.name))
                    strumline.playAnim("pressed");
            }
            else
                strumline.playAnim("static");
        }
        else
        {
            if(strumline.strum.animation.curAnim.name != "static"
            && strumline.strum.animation.curAnim.finished)
                strumline.playAnim("static");
        }
    }
}
class OffsetNote extends FlxSprite
{
    public var songTime:Float = 0.0;
    public var lastNote:Bool = false;

    public function new(songTime:Float = 0, lastNote:Bool = false)
    {
        super();
        this.songTime = songTime;
        this.lastNote = lastNote;
        frames = Paths.getSparrowAtlas('notes/_other/offset/spacebar_note');
        animation.addByPrefix('note', 'note', 0, false);
        animation.play('note');
        scale.set(0.7,0.7);
        updateHitbox();
    }
}
class OffsetStrumline extends FlxGroup
{
    public var strum:FlxSprite;
    public var notesGrp:FlxTypedGroup<OffsetNote>;

    public function new(downscroll:Bool)
    {
        super();
        strum = new FlxSprite(FlxG.width - FlxG.width / 4, (downscroll ? FlxG.height - 110 : 110));
        strum.frames = Paths.getSparrowAtlas('notes/_other/offset/spacebar_note');
        for(i in ['static', 'pressed', 'confirm'])
            strum.animation.addByPrefix(i, i, 24, false);
        
        strum.scale.set(0.7,0.7);
        strum.updateHitbox();
        playAnim('static', true);
        add(strum);
        add(notesGrp = new FlxTypedGroup<OffsetNote>());
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateOffsets();
    }

    public function playAnim(animName:String, forced:Bool = false) {
        strum.animation.play(animName, forced);
        updateOffsets();
    }

    public function updateOffsets()
    {
        strum.updateHitbox();
		strum.offset.x += strum.frameWidth * strum.scale.x / 2;
		strum.offset.y += strum.frameHeight* strum.scale.y / 2;
    }
}