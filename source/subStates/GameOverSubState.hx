package subStates;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import data.GameData.MusicBeatSubState;
import gameObjects.Character;
import states.*;

class GameOverSubState extends MusicBeatSubState
{
	public var bf:Character;
	public var bfFollow:FlxObject;

	public function new(bf:Character)
	{
		super();
		this.bf = bf;
		add(bf);

		// if your character doesnt have death anims
		// the game reloads its deathChar (default is "bf")
		if(!bf.animation.exists("firstDeath"))
			bf.reloadChar(bf.deathChar);

		bf.playAnim("firstDeath");

		bfFollow = new FlxObject(bf.x + bf.width / 2, bf.y + bf.height / 2);

		new FlxTimer().start(0.4, function(tmr:FlxTimer)
		{
			FlxG.camera.follow(bfFollow, LOCKON, FlxG.elapsed * 1);
		});

		switch(PlayState.SONG.song.toLowerCase())
		{
			default: FlxG.sound.play(Paths.music("death/deathSound"));
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(bf.animation.curAnim.name == "firstDeath"
		&& bf.animation.curAnim.finished)
		{
			bf.playAnim("deathLoop");

			CoolUtil.playMusic("death/deathMusic");
		}

		if(!ended)
		{
			if(Controls.justPressed("BACK"))
			{
				FlxG.camera.fade(FlxColor.BLACK, 0.2, false, function()
				{
					//Main.switchState(new MenuState());
					PlayState.sendToMenu();
				}, true);
				
			}

			if(Controls.justPressed("ACCEPT"))
				endBullshit();
		}
	}

	public var ended:Bool = false;

	public function endBullshit()
	{
		ended = true;
		bf.playAnim("deathConfirm");

		CoolUtil.playMusic();
		FlxG.sound.play(Paths.music("death/deathMusicEnd"));

		new FlxTimer().start(1.0, function(tmr:FlxTimer)
		{
			FlxG.camera.fade(FlxColor.BLACK, 1.0, false, null, true);

			new FlxTimer().start(2.0, function(tmr:FlxTimer)
			{
				Main.skipClearMemory = true;
				Main.switchState(new PlayState());
			});

		});
	}
}