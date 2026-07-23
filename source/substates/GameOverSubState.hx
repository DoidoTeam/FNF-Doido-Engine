package substates;

import doido.Cache;
import doido.song.Conductor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import objects.CharGroup;
import states.PlayState;
#if THREAD_LOADING
import sys.thread.Mutex;
import sys.thread.Thread;
#end

class GameOverSubState extends MusicBeatSubState
{
	var bf:CharGroup;

	var folderPath:String = "base";
	var stopThread:Bool = false;
	var pressedSomething:Bool = false;

	var preloadedMusic:Array<String> = [];

	public function new(path:String = "base", bf:CharGroup)
	{
		super();
		folderPath = path;
		this.bf = bf;
	}

	override function create()
	{
		super.create();
		cameras = [FlxG.camera];
		callScript("gameOverCreate");

		Conductor.initialBPM = Std.parseFloat(Assets.text('music/gameover/$folderPath/bpm'));
		Conductor.mapBPMChanges();
		Conductor.songPos = 0;
		preloadedMusic = ['gameover/$folderPath/deathMusicEnd', 'gameover/$folderPath/deathMusic',];

		FlxG.sound.play(Assets.music('gameover/$folderPath/deathSfx'), 0.7);

		#if THREAD_LOADING
		var mutex = new Mutex();
		Thread.create(() -> {
			mutex.acquire();
		#end
			while (!stopThread)
			{
				trace('PRELOADING GAME OVER MUSIC, HURRY!!');
				Assets.music('gameover/$folderPath/deathMusicEnd');
				Assets.music('gameover/$folderPath/deathMusic');
				trace('finished preloading, phew...');
				stopThread = true;
			}
		#if THREAD_LOADING
		mutex.release();
		});
		#end

		bf.setActive(bf.char.deathChar);
		bf.playAnim('firstDeath');
		bf.char.animation.onFinish.addOnce((animName) ->
		{
			if (animName == "firstDeath")
			{
				stopThread = true;
				FlxG.sound.playMusic(Assets.music('gameover/$folderPath/deathMusic'), 0.7);
				bf.playAnim('deathLoop', true);
			}
		});
		add(bf);

		var camFollow = PlayState.instance.followCamera('boyfriend');
		FlxTween.tween(FlxG.camera.scroll, {
			x: camFollow.point.x - FlxG.width / 2,
			y: camFollow.point.y - FlxG.height / 2
		}, 1.8, {
			ease: FlxEase.cubeOut,
			startDelay: 0.4
		});

		callScript("gameOverCreatePost");
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		callScript("gameOverUpdate", [elapsed]);

		if (FlxG.sound.music != null)
			Conductor.songPos = FlxG.sound.music.time;

		if (!pressedSomething)
		{
			if (Controls.justPressed(BACK))
			{
				callScript("gameOverLeave");
				pressedSomething = true;
				stopThread = true;
				PlayState.instance.goToMenu();
			}
			if (Controls.justPressed(ACCEPT))
			{
				callScript("gameOverConfirm");
				pressedSomething = true;
				stopThread = true;

				stopMusic();
				FlxG.sound.play(Assets.music('gameover/$folderPath/deathMusicEnd'));
				bf.playAnim('deathConfirm');

				new FlxTimer().start(1.0, function(tmr:FlxTimer)
				{
					MusicBeat.getTopCamera().fade(0xFF000000);

					new FlxTimer().start(2.0, (tmr) ->
					{
						MusicBeat.skipClearCache = true;
						MusicBeat.switchState(new PlayState());
					});
				});
			}
		}
	}

	// dont call super because this substate doesnt actually have a script
	override public function callScript(fun:String, ?args:Array<Dynamic>)
	{
		// dont run regular state calls to avoid running unwanted code...
		if (!fun.startsWith("gameOver"))
			return;

		PlayState.instance.callScript(fun, args);
	}

	override function beatHit()
	{
		super.beatHit();
		if (curBeat % 2 == 0 && bf.curAnimName == 'deathLoop')
		{
			bf.playAnim('deathLoop', true);
		}
	}

	public function stopMusic()
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}
	}

	override function destroy()
	{
		stopMusic();
		for (file in preloadedMusic)
			Assets.clearMusic(file);

		super.destroy();
	}
}
