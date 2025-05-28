package subStates.video;

import backend.game.GameData.MusicBeatSubState;
#if hxvlc
import backend.game.DoidoVideoSprite;
import flixel.FlxSprite;
import flixel.addons.display.FlxPieDial;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import subStates.CutscenePauseSubState;

class VideoPlayerSubState extends MusicBeatSubState
{
    private var video:DoidoVideoSprite;

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

        new FlxTimer().start(0.001, function(tmr) {
            video.play();
        });
    }

    public function pauseVideo()
    {
        FlxG.sound.play(Paths.sound('menu/cancelMenu'), 0.7);
        video.pause();
        
        openSubState(new subStates.CutscenePauseSubState(function(exit:PauseExit) {
            switch(exit) {
                case SKIP:
                    for(event in video.bitmap.onEndReached.__listeners)
                        event();
                case RESTART:
                    video.restart();
                default:
                    video.resume();
            }
        }));
        
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(video.bitmap?.isPlaying)
        {
            if(Controls.justPressed(ACCEPT))
                pauseVideo();
        }
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