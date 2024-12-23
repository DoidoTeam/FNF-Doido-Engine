package subStates;

import backend.game.GameData.MusicBeatSubState;
#if VIDEOS_ALLOWED
import backend.game.DoidoVideoSprite;
import flixel.FlxSprite;
import flixel.addons.display.FlxPieDial;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class VideoPlayerSubState extends MusicBeatSubState
{
    private var video:DoidoVideoSprite;

    private var darkBG:FlxSprite;
    private var pieDial:FlxPieDial;
    private var curSelection:Int = 0;
    private var buttons:FlxTypedGroup<FlxSprite>;
    private var curBtn:FlxSprite;

    private var lockControls:Bool = true;
    private var holdSkip:Bool = false;
    private var skipProgress:Float = 0.0;

    public function new(key:String, ?finishCallBack:Void->Void)
    {
        super();
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        FlxG.sound.music?.pause();
        video = new DoidoVideoSprite();
		video.antialiasing = SaveData.data.get("Antialiasing");
		video.bitmap.onFormatSetup.add(function():Void
		{
			if (video.bitmap != null && video.bitmap.bitmapData != null)
			{
				video.setGraphicSize(FlxG.width, FlxG.height);
				video.updateHitbox();
				video.screenCenter();
			}
		});
        video.bitmap.onEndReached.add(function():Void
        {
            FlxG.sound.music?.resume();
            video.destroy();
            close();
        });
        if(finishCallBack != null)
            video.bitmap.onEndReached.add(finishCallBack);
		
        Logs.print('loaded video $key.mp4');
        video.load(Paths.video(key));
        add(video);
        
        darkBG = new FlxSprite().makeGraphic(FlxG.width + 10, FlxG.height + 10, 0xFF000000);
        darkBG.alpha = 0.0001;
        add(darkBG);

        add(buttons = new FlxTypedGroup<FlxSprite>());
        for(i in 0...2)
        {
            var btn = new FlxSprite(50 + (170 * i), FlxG.height + 20);
            btn.frames = Paths.getSparrowAtlas('hud/base/videos/${(i == 0) ? 'unpause' : 'skip'}');
            var anims:Array<Array<Dynamic>> = (i == 0) ? [
                ['idle', true],
                ['click', false],
            ] : [
                ['idle', true],
                ['hold', false],
                ['hold loop', true],
                ['release', false],
            ];
            for(j in anims)
                btn.animation.addByPrefix(j[0], '${j[0]}0', 24, j[1]);

            function endAnim(name:String)
            {
                var finishAnim:Null<String> = null;
                if(i == 0)
                {
                    finishAnim = switch(name) {
                        case 'click': 'idle';
                        default: null;
                    }
                }
                if(i == 1)
                {
                    finishAnim = switch(name) {
                        case 'hold': 'hold loop';
                        case 'release': 'idle';
                        default: null;
                    }
                }
                if(finishAnim != null)
                    btn.animation.play(finishAnim);
            }

            #if (flixel < "5.9.0")
            btn.animation.finishCallback = endAnim;
            #else
            btn.animation.onFinish.add(endAnim);
            #end

            btn.ID = i;
            btn.animation.play('idle');
            buttons.add(btn);
        }
        changeSelection(false);

        pieDial = new FlxPieDial(0, 0, 48, FlxColor.WHITE, 72, CIRCLE, false);
        pieDial.x = 80 + (170 * buttons.members.length);
        pieDial.y = (FlxG.height - 184 - 30 + (pieDial.height / 2));
        pieDial.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
        pieDial.amount = 0.0;
        add(pieDial);

        new FlxTimer().start(0.001, function(tmr) {
            lockControls = false;
            video.play();
        });
    }

    public function pauseVideo(isPause:Bool)
    {
        lockControls = true;
        FlxG.sound.play(Paths.sound('menu/cancelMenu'), 0.7);
        if(isPause)
            video.pause();

        for(btn in buttons.members)
        {
            FlxTween.tween(btn, {y: FlxG.height - btn.height - 70}, 0.3, {
                startDelay: 0.1 * btn.ID,
                ease: FlxEase.cubeOut,
                onComplete: function(twn) {
                    FlxTween.tween(btn, {y: isPause ? FlxG.height - btn.height - 30 : FlxG.height + 20}, 0.4, {
                        ease: isPause ? FlxEase.cubeInOut : FlxEase.cubeIn
                    });
                }
            });
        }

        FlxTween.tween(darkBG, {alpha: isPause ? 0.7 : 0.001}, 0.4);
        new FlxTimer().start(0.75, function(tmr) {
            lockControls = false;
            if(!isPause)
                video.resume();
        });
    }

    private function changeSelection(change:Bool = true)
    {
        if(change) {
            curSelection = ((curSelection == 0) ? 1 : 0);
            FlxG.sound.play(Paths.sound('menu/scrollMenu'), 0.7);
            for(btn in buttons.members)
            {
                FlxTween.cancelTweensOf(btn);
                btn.y = FlxG.height - btn.height - 30;
                if(btn.ID == curSelection)
                {
                    btn.y -= 10;
                    FlxTween.tween(btn, {y: btn.y + 10}, 0.2, {ease: FlxEase.cubeOut});
                }
            }
            if(curBtn?.animation.curAnim.name.startsWith('hold')) {
                curBtn.animation.play('release');
                holdSkip = false;
            }
        }
        for(btn in buttons.members)
        {
            btn.color = 0xFF555555;
            if(btn.ID == curSelection) {
                btn.color = 0xFFFFFFFF;
                curBtn = btn;
            }
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(!lockControls)
        {
            if(video.bitmap?.isPlaying)
            {
                if(Controls.justPressed(ACCEPT))
                    pauseVideo(true);
            }
            else
            {
                if(Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT))
                    changeSelection();
                if(curSelection == 0)
                {
                    if(Controls.justPressed(ACCEPT))
                    {
                        curBtn.animation.play('click');
                        pauseVideo(false);
                    }
                }
                if(curSelection == 1)
                {
                    holdSkip = Controls.pressed(ACCEPT);
                    if(Controls.justPressed(ACCEPT)) {
                        curBtn.animation.play('hold');
                        FlxG.sound.play(Paths.sound('menu/scrollMenu'), 0.7);
                    }
                    if(Controls.released(ACCEPT)) {
                        curBtn.animation.play('release');
                        FlxG.sound.play(Paths.sound('menu/scrollMenu'), 0.7);
                    }
                }
            }
        }
        if(holdSkip)
            skipProgress += elapsed;
        else
            skipProgress -= elapsed * 2;
        skipProgress = FlxMath.bound(skipProgress, 0, 1);
        pieDial.amount = skipProgress;
        pieDial.alpha = (pieDial.amount <= 0.02 ? 0.0001 : 1.0);
        if(skipProgress >= 1.0)
            for(event in video.bitmap.onEndReached.__listeners)
                event();
    }
}
#else
class VideoPlayerSubState extends MusicBeatSubState
{
    public function new(key:String)
    {
        super();
        Logs.print('Videos are disabled!! Enable them at "Project.xml" to play "${key}"', WARNING);
    }

    override function create()
    {
        super.create();
        close();
    }
}
#end