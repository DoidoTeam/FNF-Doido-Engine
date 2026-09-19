package subStates.cutscenes;

#if VIDEOS_ALLOWED
import doido.objects.DoidoVideo;
import flixel.FlxSprite;
import flixel.addons.display.FlxPieDial;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import substates.cutscenes.CutscenePauseSubState;

class VideoPlayerSubState extends MusicBeatSubState
{
    private var video:DoidoVideo;

    public function new(key:String, ?finishCallBack:Void->Void)
    {
        super();
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        FlxG.sound.music?.pause();

        video = new DoidoVideo();
        video.antialiasing = Save.data.antialiasing;
        video.exitSignal.add(() -> {
            if(finishCallBack != null)
                finishCallBack();
            close();
        });
        video.load(Assets.video(key));
        add(video);

        new FlxTimer().start(0.001, function(tmr) {
            video.play();
        });
    }

    public function pauseVideo()
    {
        FlxG.sound.play(Assets.sound('cancel'), 0.7);
        video.pause();
        
        openSubState(new CutscenePauseSubState(function(exit:PauseExit) {
            switch(exit) {
                case SKIP:
                    video.finish();
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

        if(Controls.justPressed(ACCEPT) || Controls.justPressed(BACK))
            pauseVideo();
    }
}
#else
class VideoPlayerSubState extends MusicBeatSubState
{
    public function new(key:String)
    {
        super();
        Logs.print('Videos are disabled!!! Enable them in your Project.xml to play "${key}"', WARNING);
    }

    override function create()
    {
        super.create();
        close();
    }
}
#end