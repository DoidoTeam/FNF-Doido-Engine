package subStates.video;

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
import subStates.CutscenePauseSubState;

class VideoPlayerSubState extends MusicBeatSubState
{
    private var video:DoidoVideoSprite;

    public function new(key:String, ?finishCallBack:Void->Void)
    {
        super();
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        FlxG.sound.music?.pause();

        #if hxvlc
        video = new DoidoVideoSprite();
		video.antialiasing = SaveData.data.get("Antialiasing");

		video.bitmap.onFormatSetup.add(function():Void {
			if (video.bitmap != null && video.bitmap.bitmapData != null) {
				video.setGraphicSize(FlxG.width, FlxG.height);
				video.updateHitbox();
				video.screenCenter();
			}
		});

        video.bitmap.onEndReached.add(function():Void {
            close();
        });

        if(finishCallBack != null) 
            video.bitmap.onEndReached.add(finishCallBack);

        video.load(Paths.video(key));
        add(video);
        
        new FlxTimer().start(0.001, function(tmr) {
            video.play();
        });
        #else
        video = new DoidoVideoSprite(Paths.video(key));
		add(video);

        video.closeCallBack = close;
        
        if(finishCallBack != null) 
            video.finishCallBack = finishCallBack;
        #end
    }

    public function pauseVideo()
    {
        FlxG.sound.play(Paths.sound('menu/cancelMenu'), 0.7);
        video.pause();
        
        openSubState(new subStates.CutscenePauseSubState(function(exit:PauseExit) {
            switch(exit) {
                case SKIP:
                    #if html5
                    video.finish();
                    #end
                    
                    close();
                case RESTART:
                    video.restart();
                default:
                    video.resume();
            }
        }));
    }

    override function close()
    {
        video.destroy();
        FlxG.sound.music?.resume();

        super.close();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(Controls.justPressed(ACCEPT))
            pauseVideo();
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