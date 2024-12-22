package subStates;

import flixel.FlxCamera;
import backend.game.GameData.MusicBeatSubState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.CharGroup;
import states.*;

class GameOverSubState extends MusicBeatSubState
{
	public var bf:CharGroup;
	public var bfFollow:FlxObject;

	public function new(bf:CharGroup)
	{
		super();
		this.bf = bf;
		bf.curChar = bf.char.deathChar;
	}

	public var loopTimer:FlxTimer;
	
	override function create()
	{
		super.create();
		PlayState.instance.setScript("this", this);
		callScript("gameOverCreate");
		add(bf);
		// the game loads the deathChar you set in Character.hx (default is "bf-dead")
		bf.reload();
		bf.char.playAnim("firstDeath", true);
		
		new FlxTimer().start(0.4, function(tmr:FlxTimer)
		{
			bfFollow = new FlxObject(
				bf.char.getMidpoint().x - 200 - bf.char.cameraOffset.x,
				bf.char.getMidpoint().y - 20  + bf.char.cameraOffset.y
			);
		});

		// death sound
		FlxG.sound.play(switch(PlayState.SONG.song)
		{
			default: Paths.music("death/deathSound");
		});

		// awaits 58 frames to begin music
		loopTimer = new FlxTimer().start((1 / 24) * 58, function(tmr:FlxTimer)
		{
			bf.char.playAnim("deathLoop");
			CoolUtil.playMusic("death/deathMusic");
		});
		callScript("gameOverCreatePost");

		#if TOUCH_CONTROLS
		createPad("back", [fadeCamera()]);
		#end
	}

	function fadeCamera():FlxCamera {
		return FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		callScript("gameOverUpdate", [elapsed]);
		if(bfFollow != null)
			CoolUtil.camPosLerp(FlxG.camera, bfFollow, elapsed * 2);

		if(!ended)
		{
			if(Controls.justPressed(BACK))
			{
				fadeCamera().fade(FlxColor.BLACK, 0.2, false, function()
				{
					PlayState.sendToMenu();
				}, true);
			}

			if(Controls.justPressed(ACCEPT))
				endBullshit();
		}
		callScript("gameOverUpdatePost", [elapsed]);
	}

	public var ended:Bool = false;

	public function endBullshit()
	{
		ended = true;
		bf.char.playAnim("deathConfirm");
		if(loopTimer != null)
			loopTimer.cancel();

		CoolUtil.playMusic();
		FlxG.sound.play(Paths.music("death/deathMusicEnd"));

		new FlxTimer().start(1.0, function(tmr:FlxTimer)
		{
			fadeCamera().fade(FlxColor.BLACK, 1.0, false, null, true);

			new FlxTimer().start(2.0, function(tmr:FlxTimer)
			{
				Main.skipClearMemory = true;
				Main.resetState('base');
			});
		});
	}

	function callScript(fun:String, ?args:Array<Dynamic>) {
		try {
			PlayState.instance.callScript(fun, args);
		} catch(e) {
			// avoiding the crash lol
		}
	}
}