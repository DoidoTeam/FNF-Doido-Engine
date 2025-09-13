package subStates;

import backend.game.DoidoVideoSprite;
import flixel.FlxSprite;
import flixel.addons.display.FlxPieDial;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

enum PauseExit
{
    UNPAUSE;
    SKIP;
    RESTART;
}
class CutscenePauseSubState extends MusicBeatSubState
{
    private var buttonNames:Array<String> = ["unpause", "restart", "skip"];

    private var darkBG:FlxSprite;
    private var pieDial:FlxPieDial;
    private var curSelected:Int = 0;
    private var buttons:FlxTypedGroup<FlxSprite>;
    private var curBtn:FlxSprite;

    private var lockControls:Bool = true;
    private var lockMovement:Bool = true;
    private var holdSkip:Bool = false;
    private var skipProgress:Float = 0.0;

    private var finishCallBack:PauseExit->Void;

    public function new(?finishCallBack:PauseExit->Void)
    {
        super();
        this.finishCallBack = finishCallBack; 
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        FlxG.sound.music?.pause();
        FlxG.sound.play(Paths.sound('menu/cancelMenu'), 0.7);
        
        darkBG = new FlxSprite().makeGraphic(FlxG.width + 10, FlxG.height + 10, 0xFF000000);
        darkBG.alpha = 0.0001;
        add(darkBG);

        add(buttons = new FlxTypedGroup<FlxSprite>());
        for(i in 0...buttonNames.length)
        {
            var name = buttonNames[i];
            var btn = new FlxSprite(50 + (170 * i), FlxG.height + 20);
            btn.frames = Paths.getSparrowAtlas('hud/base/cutscene/$name');
            var anims:Array<Array<Dynamic>> = (name != "skip") ? [
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
                if(name == "skip")
                {
                    finishAnim = switch(name) {
                        case 'hold': 'hold loop';
                        case 'release': 'idle';
                        default: null;
                    }
                }
                else
                {
                    finishAnim = switch(name) {
                        case 'click': 'idle';
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
        changeSelection(0);

        pieDial = new FlxPieDial(0, 0, 48, FlxColor.WHITE, 72, CIRCLE, false);
        pieDial.x = 80 + (170 * buttons.members.length);
        pieDial.y = (FlxG.height - 184 - 30 + (pieDial.height / 2));
        pieDial.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
        pieDial.amount = 0.0;
        add(pieDial);

        moveButtons(true);
    }

    public function moveButtons(moveIn:Bool)
    {
        lockControls = true;
        lockMovement = true;

        for(btn in buttons.members)
        {
            FlxTween.cancelTweensOf(btn);
            moveSingleButton(btn, moveIn, true);
        }

        FlxTween.tween(darkBG, {alpha: moveIn ? 0.7 : 0.001}, 0.4);

        if(moveIn) {
            new FlxTimer().start(0.05, function(tmr) {
                lockControls = false;
            });

            new FlxTimer().start(0.9, function(tmr) {
                lockMovement = false;
            });
        }
    }

    public function moveSingleButton(btn:FlxSprite, moveIn:Bool, hasDelay:Bool = false)
    {
        FlxTween.tween(btn, {y: FlxG.height - btn.height - 70}, 0.3, {
            startDelay: 0.1 * (hasDelay ? btn.ID : 1),
            ease: FlxEase.cubeOut,
            onComplete: function(twn) {
                FlxTween.tween(btn, {y: moveIn ? FlxG.height - btn.height - 30 : FlxG.height + 20}, 0.4, {
                    ease: moveIn ? FlxEase.cubeInOut : FlxEase.cubeIn
                });
            }
        });
    }

    private function changeSelection(change:Int = 0)
    {
        if(change != 0) {
            curSelected += change;
		    curSelected = FlxMath.wrap(curSelected, 0, buttonNames.length - 1);
            FlxG.sound.play(Paths.sound('menu/scrollMenu'), 0.7);

            if(!lockMovement) {
                for(btn in buttons.members)
                    {
                        FlxTween.cancelTweensOf(btn);
                        btn.y = FlxG.height - btn.height - 30;
                        if(btn.ID == curSelected)
                        {
                            btn.y -= 10;
                            FlxTween.tween(btn, {y: btn.y + 10}, 0.2, {ease: FlxEase.cubeOut});
                        }
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
            if(btn.ID == curSelected) {
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
            if(Controls.justPressed(UI_LEFT))
                changeSelection(-1);
            if(Controls.justPressed(UI_RIGHT))
                changeSelection(1);

            switch(buttonNames[curSelected]) {
                case "skip":
                    holdSkip = Controls.pressed(ACCEPT);
                    if(Controls.justPressed(ACCEPT)) {
                        curBtn.animation.play('hold');
                        FlxG.sound.play(Paths.sound('menu/scrollMenu'), 0.7);
                    }
                    if(Controls.released(ACCEPT)) {
                        curBtn.animation.play('release');
                        FlxG.sound.play(Paths.sound('menu/scrollMenu'), 0.7);
                    }
                case "restart":
                    if(Controls.justPressed(ACCEPT)) {
                        curBtn.animation.play('click');
                        FlxG.sound.play(Paths.sound('menu/cancelMenu'), 0.7);

                        var time:Float = 0.3;

                        FlxTween.cancelTweensOf(darkBG);
                        FlxTween.tween(darkBG, {alpha: 0.001}, time);
                        for(btn in buttons.members)
                        {
                            FlxTween.cancelTweensOf(btn);
                            if(btn.ID != curSelected)
                                FlxTween.tween(btn, {alpha: 0.001}, time);
                        }

                        moveSingleButton(curBtn, false, false);

                        new FlxTimer().start(time + 0.6, function(tmr) {
                            if(finishCallBack != null)
                                finishCallBack(RESTART);
                            close();
                        });
                    } 
                default:
                    if(Controls.justPressed(ACCEPT)) {
                        curBtn.animation.play('click');
                        FlxG.sound.play(Paths.sound('menu/cancelMenu'), 0.7);
                        moveButtons(false);

                        new FlxTimer().start(0.9, function(tmr) {
                            if(finishCallBack != null)
                                finishCallBack(UNPAUSE);
                            close();
                        });
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
        if(skipProgress >= 1.0) {
            if(finishCallBack != null)
                finishCallBack(SKIP);
            close();
        }
    }
}