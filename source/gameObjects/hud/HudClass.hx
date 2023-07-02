package gameObjects.hud;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import data.Timings;
import states.PlayState;

class HudClass extends FlxGroup
{
	public var infoTxt:FlxText;

	// health bar
	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;

	// icon stuff
	public var iconBf:HealthIcon;
	public var iconDad:HealthIcon;

	public function new()
	{
		super();
		healthBarBG = new FlxSprite().loadGraphic(Paths.image("hud/base/healthBar"));
		add(healthBarBG);

		healthBar = new FlxBar(
			0, 0,
			RIGHT_TO_LEFT,
			Math.floor(healthBarBG.width) - 8,
			Math.floor(healthBarBG.height) - 8
		);
		healthBar.createFilledBar(0xFFFF0000, 0xFF00FF00);
		healthBar.updateBar();
		add(healthBar);

		iconDad = new HealthIcon();
		iconDad.setIcon(PlayState.SONG.player2, false);
		add(iconDad);

		iconBf = new HealthIcon();
		iconBf.setIcon(PlayState.SONG.player1, true);
		add(iconBf);

		infoTxt = new FlxText(0, 0, 0, "nothing");
		infoTxt.setFormat(Main.gFont, 18, 0xFFFFFFFF);
		infoTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		add(infoTxt);

		updateHitbox();
	}

	public final separator:String = " || ";

	public function updateText()
	{
		infoTxt.text = "";

		infoTxt.text += 			'Score: '		+ Timings.score;
		infoTxt.text += separator + 'Accuracy: '	+ Timings.accuracy + "%" + ' [${Timings.getRank()}]';
		infoTxt.text += separator + 'Misses: '		+ Timings.misses;

		infoTxt.screenCenter(X);
	}

	public function updateHitbox(downscroll:Bool = false)
	{
		healthBarBG.screenCenter(X);
		healthBarBG.y = (downscroll ? 50 : FlxG.height - healthBarBG.height - 50);

		healthBar.setPosition(healthBarBG.x + 4, healthBarBG.y + 4);
		updateIconPos();

		updateText();
		infoTxt.screenCenter(X);
		infoTxt.y = healthBarBG.y + healthBarBG.height + 4;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		healthBar.percent = (PlayState.health * 50);

		updateIconPos();
	}

	public function updateIconPos()
	{
		var barX:Float = (healthBarBG.x + (healthBarBG.width * (2 - PlayState.health) / 2));
		var barY:Float = (healthBarBG.y + healthBarBG.height / 2);

		for(icon in [iconDad, iconBf])
		{
			icon.scale.set(
				FlxMath.lerp(icon.scale.x, 1, FlxG.elapsed * 6),
				FlxMath.lerp(icon.scale.y, 1, FlxG.elapsed * 6)
			);
			icon.updateHitbox();

			icon.y = barY - icon.height / 2 - 12;
			icon.x = barX;

			if(icon == iconDad)
				icon.x -= icon.width - 24;
			else
				icon.x -= 24;

			if(icon == iconDad)
				icon.setAnim(2 - PlayState.health);
			else
				icon.setAnim(PlayState.health);
		}
	}

	public function beatHit(curBeat:Int = 0)
	{
		if(curBeat % 2 == 0)
		{
			for(icon in [iconDad, iconBf])
			{
				icon.scale.set(1.3,1.3);
				icon.updateHitbox();
				updateIconPos();
			}
		}
	}
}