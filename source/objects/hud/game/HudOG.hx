package objects.hud.game;

import flixel.math.FlxPoint;
import backend.song.Conductor;
import backend.song.Timings;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.hud.HudClass.IconChange;
import states.PlayState;
import flixel.util.FlxStringUtil;

class HudOG extends HudClass
{
	public var infoTxt:FlxText;
	
	var botplaySin:Float = 0;
	var botplayTxt:FlxText;
	var badScoreTxt:FlxText;

	// health bar
	public var healthBar:DoidoBar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public function new()
	{
		super("OG");
		add(ratingGrp);
		healthBar = new DoidoBar("hud/base/healthBar", "hud/base/healthBarBorder");
        healthBar.sideL.color = 0xFFFF0000;
        healthBar.sideR.color = 0xFF66FF33;
		add(healthBar);
		
		final SONG = PlayState.SONG;
		iconP1 = new HealthIcon();
		changeIcon(SONG.player1, PLAYER);
		add(iconP1);

		iconP2 = new HealthIcon();
		changeIcon(SONG.player2, ENEMY);
		add(iconP2);
		
		infoTxt = new FlxText(FlxG.width / 2 + 112, 0, 0, "hi there! i am using whatsapp");
		infoTxt.setFormat(Main.gFont, 20, 0xFFFFFFFF, LEFT);
		infoTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		add(infoTxt);
		
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

		updatePositions();
		for(i in [
			infoTxt,
			healthBar,
			iconP1,
			iconP2,
		])
			alphaList.push(i);
	}

	override function updateInfoTxt()
	{
		super.updateInfoTxt();
		infoTxt.text = 'Score: ' + FlxStringUtil.formatMoney(Timings.score, false, true);
	}

	public function updateIconPos()
	{
		var healthBarPos = FlxPoint.get(
			healthBar.x + FlxMath.lerp(healthBar.border.width, 0, healthBar.percent / 100),
			healthBar.y - (healthBar.border.height / 2)
		);

		iconP1.y = healthBarPos.y - (iconP1.height / 2);
		iconP2.y = healthBarPos.y - (iconP2.height / 2);

		iconP1.x = healthBarPos.x - 20;
		iconP2.x = healthBarPos.x - iconP2.width + 32;
	}

	override function updatePositions()
	{
		super.updatePositions();
		healthBar.x = (FlxG.width / 2) - (healthBar.border.width / 2);
		healthBar.y = (downscroll ? 70 : FlxG.height - healthBar.border.height - 50);
		
		updateInfoTxt();
		infoTxt.y = healthBar.y + healthBar.border.height + 4;
		
		badScoreTxt.y = healthBar.y - badScoreTxt.height - 4;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		healthBar.percent = (health * 50);
		
		botplayTxt.visible = PlayState.botplay;
		badScoreTxt.visible = !PlayState.validScore;
		if(botplayTxt.visible)
		{
			botplaySin += elapsed * Math.PI;
			botplayTxt.alpha = 0.5 + Math.sin(botplaySin) * 0.8;
		}

		for(icon in [iconP1, iconP2])
		{
			icon.scale.set(
				FlxMath.lerp(icon.scale.x, 1, FlxG.elapsed * 6),
				FlxMath.lerp(icon.scale.y, 1, FlxG.elapsed * 6)
			);
			if(!icon.isPlayer)
				icon.setAnim(2 - health);
			else
				icon.setAnim(health);
			
			icon.updateHitbox();
		}
		updateIconPos();
	}

	override function addRating(rating:Rating)
	{
		super.addRating(rating);
		rating.numberOffset.x += 64;
		if(rating.assetModifier == "pixel")
			rating.numberOffset.x /= 5;
		rating.setPos(FlxG.width / 2 + 130, FlxG.height / 2 - 80);
		rating.playRating();
	}

	override function changeIcon(newIcon:String = "face", type:IconChange = ENEMY)
	{
		super.changeIcon(newIcon, type);
		var isPlayer:Bool = (type == PLAYER);
		var icon = (isPlayer ? iconP1 : iconP2);
		icon.setIcon(newIcon, isPlayer);
	}

	override function beatHit(curBeat:Int = 0)
	{
		super.beatHit(curBeat);
		if(curBeat % 2 == 0)
		{
			for(icon in [iconP1, iconP2])
			{
				icon.scale.set(1.3,1.3);
				icon.updateHitbox();
				updateIconPos();
			}
		}
	}
}