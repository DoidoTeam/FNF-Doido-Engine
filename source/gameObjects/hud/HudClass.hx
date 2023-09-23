package gameObjects.hud;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import data.Conductor;
import data.Timings;
import states.PlayState;

class HudClass extends FlxGroup
{
	public var infoTxt:FlxText;
	public var timeTxt:FlxText;
	
	var botplaySin:Float = 0;
	var botplayTxt:FlxText;
	var badScoreTxt:FlxText;

	// health bar
	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;
	var smoothBar:Bool = true;

	// icon stuff
	public var iconBf:HealthIcon;
	public var iconDad:HealthIcon;

	public var invertedIcons:Bool = false;
	public var health:Float = 1;

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
		
		smoothBar = SaveData.data.get('Smooth Healthbar');

		iconDad = new HealthIcon();
		iconDad.setIcon(PlayState.SONG.player2, false);
		iconDad.ID = 0;
		add(iconDad);

		iconBf = new HealthIcon();
		iconBf.setIcon(PlayState.SONG.player1, true);
		iconBf.ID = 1;
		add(iconBf);

		changeIcon(0, iconDad.curIcon);

		infoTxt = new FlxText(0, 0, 0, "hi there! i am using whatsapp");
		infoTxt.setFormat(Main.gFont, 20, 0xFFFFFFFF, CENTER);
		infoTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		add(infoTxt);
		
		timeTxt = new FlxText(0, 0, 0, "nuts / balls even");
		timeTxt.setFormat(Main.gFont, 32, 0xFFFFFFFF, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		timeTxt.visible = SaveData.data.get('Song Timer');
		add(timeTxt);
		
		badScoreTxt = new FlxText(0,0,0,"SCORE WILL NOT BE SAVED");
		badScoreTxt.setFormat(Main.gFont, 26, 0xFFFF0000, CENTER);
		badScoreTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		badScoreTxt.screenCenter(X);
		badScoreTxt.visible = false;
		add(badScoreTxt);
		
		botplayTxt = new FlxText(0,0,0,"[BOTPLAY]");
		botplayTxt.setFormat(Main.gFont, 40, 0xFFFFFFFF, CENTER);
		botplayTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		botplayTxt.screenCenter();
		botplayTxt.visible = false;
		add(botplayTxt);

		updateHitbox();
		health = PlayState.health;
	}

	public final separator:String = " | ";

	public function updateText()
	{
		infoTxt.text = "";
		
		infoTxt.text += 			'Score: '		+ Timings.score;
		infoTxt.text += separator + 'Accuracy: '	+ Timings.accuracy + "%" + ' [${Timings.getRank()}]';
		infoTxt.text += separator + 'Misses: '		+ Timings.misses;

		infoTxt.screenCenter(X);
	}
	
	public function updateTimeTxt()
	{
		timeTxt.text
		= CoolUtil.posToTimer(Conductor.songPos)
		+ ' / '
		+ CoolUtil.posToTimer(PlayState.songLength);
		timeTxt.screenCenter(X);
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
		
		badScoreTxt.y = healthBarBG.y - badScoreTxt.height - 4;
		
		updateTimeTxt();
		timeTxt.y = downscroll ? (FlxG.height - timeTxt.height - 8) : (8);
	}
	
	public function setAlpha(hudAlpha:Float = 1, ?tweenTime:Float = 0)
	{
		// put the items you want to set invisible when the song starts here
		var allItems:Array<FlxSprite> = [
			infoTxt,
			timeTxt,
			healthBar,
			healthBarBG,
			iconBf,
			iconDad,
		];
		for(item in allItems)
		{
			if(tweenTime <= 0)
				item.alpha = hudAlpha;
			else
				FlxTween.tween(item, {alpha: hudAlpha}, tweenTime, {ease: FlxEase.cubeOut});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		health = FlxMath.lerp(health, PlayState.health, elapsed * 8);
		if(Math.abs(health - PlayState.health) <= 0.00001 || !smoothBar)
			health = PlayState.health;
		
		healthBar.percent = (health * 50);
		
		botplayTxt.visible = PlayState.botplay;
		badScoreTxt.visible = !PlayState.validScore;
		
		if(botplayTxt.visible)
		{
			botplaySin += elapsed * Math.PI;
			botplayTxt.alpha = 0.5 + Math.sin(botplaySin) * 0.8;
		}

		updateIconPos();
		updateTimeTxt();
	}

	public function updateIconPos()
	{
		var formatHealth = (2 - health);
		if(invertedIcons)
			formatHealth = health;

		var barX:Float = (healthBarBG.x + (healthBarBG.width * (formatHealth) / 2));
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

			var leftIcon = iconDad;
			if(invertedIcons)
				leftIcon = iconBf;

			if(icon == leftIcon)
				icon.x -= icon.width - 24;
			else
				icon.x -= 24;

			if(!icon.isPlayer)
				icon.setAnim(2 - health);
			else
				icon.setAnim(health);

			if(!invertedIcons)
				icon.flipX = icon.isPlayer;
			else
				icon.flipX = !icon.isPlayer;
		}

		healthBar.flipX = invertedIcons;
	}

	public function changeIcon(iconID:Int = 0, newIcon:String = "face")
	{
		for(icon in [iconDad, iconBf])
		{
			if(icon.ID == iconID)
				icon.setIcon(newIcon, icon.isPlayer);
		}
		updateIconPos();

		healthBar.createFilledBar(
			HealthIcon.getColor(iconDad.curIcon),
			HealthIcon.getColor(iconBf.curIcon)
		);
		healthBar.updateBar();
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