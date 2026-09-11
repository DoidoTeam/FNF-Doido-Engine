package objects.ui.hud;

import flixel.util.FlxColor;
import doido.objects.Alphabet;
import flixel.math.FlxMath;
import objects.ui.hud.ClassHud.IconChange;

class BaseHud extends ClassHud
{
	public var scoreTxt:FlxBitmapText;
	public var timeTxt:FlxBitmapText;

	var botplaySin:Float = 0;
	var botplayTxt:Alphabet;

	var badScoreText:String = "SCORE WON'T BE SAVED";
	var validScore:Bool = true;

	public var healthBar:DoidoBar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public function new(play:Playable)
	{
		super("doido", play);
		add(numberGrp);
		add(ratingGrp);

		healthBar = new DoidoBar("ui/hud/base/healthBar", "ui/hud/base/healthBar-border");
		add(healthBar);

		iconP1 = new HealthIcon();
		changeIcon(play.player1, PLAYER);
		add(iconP1);

		iconP2 = new HealthIcon();
		changeIcon(play.player2, ENEMY);
		add(iconP2);

		scoreTxt = new FlxBitmapText(0, 0, Assets.bitmapFont("vcr"));
		scoreTxt.setOutline(0xFF000000, 2);
		scoreTxt.alignment = CENTER;
		add(scoreTxt);

		timeTxt = new FlxBitmapText(0, 0, Assets.bitmapFont("vcr"));
		timeTxt.setOutline(0xFF000000, 2);
		timeTxt.alignment = CENTER;
		timeTxt.scale.set(1.4, 1.4);
		timeTxt.updateHitbox();
		add(timeTxt);

		botplayTxt = new Alphabet(FlxG.width / 2, FlxG.height / 2, "[<wave intensity=10 speed=4 delay=0.5>BOTPLAY</wave>]", true, CENTER);
		botplayTxt.scale.set(0.7, 0.7);
		botplayTxt.updateHitbox();
		botplayTxt.y -= (botplayTxt.height / 2);
		add(botplayTxt);

		updateAlphaList([healthBar, iconP1, iconP2, scoreTxt, timeTxt]);
		updatePositions();
	}

	override function popUpRating(ratingName:String = "", assetPath:String = "base"):RatingSprite
	{
		var rating = super.popUpRating(ratingName, assetPath);
		rating.ratingScale = 0.7;
		rating.screenCenter(X);
		if (play.middlescroll #if TOUCH_CONTROLS && !Save.data.modernControls #end)
			rating.x -= FlxG.width / 4;
		rating.y = ratingPos;
		rating.defaultAnim();
		return rating;
	}

	override function popUpCombo(comboNum:Int, assetPath:String = "base"):Array<ComboSprite>
	{
		var numberArray = super.popUpCombo(comboNum, assetPath);

		for (number in numberArray)
		{
			if (play.middlescroll #if TOUCH_CONTROLS && !Save.data.modernControls #end)
				number.x -= FlxG.width / 4;
			number.y = ratingPos + 75;
			number.defaultAnim();
		}

		return numberArray;
	}

	var ratingPos(get, never):Int;

	function get_ratingPos():Int
		return play.downscroll ? FlxG.height - 150 : 65;

	override function positionCombo(numberArray:Array<ComboSprite>)
	{
		for (number in numberArray)
			number.numberScale = 0.7;
		super.positionCombo(numberArray);
	}

	override function updatePositions()
	{
		super.updatePositions();

		healthBar.x = (FlxG.width / 2) - (healthBar.border.width / 2);
		healthBar.y = (play.downscroll ? 70 : FlxG.height - healthBar.border.height - 50);

		scoreTxt.screenCenter(X);
		scoreTxt.y = healthBar.y + healthBar.border.height + 8;
		timeTxt.screenCenter(X);
		timeTxt.y = play.downscroll ? (FlxG.height - timeTxt.height - 14) : (14);

		updateIconPos();
	}

	override function updateScoreTxt()
	{
		if (!validScore)
		{
			scoreTxt.text = badScoreText;
			scoreTxt.color = FlxColor.RED;
			return;
		}

		super.updateScoreTxt();
		scoreTxt.text = defaultScoreText;
	}

	override function updateTimeTxt()
	{
		timeTxt.visible = (Save.data.songTimer != "OFF");
		if (!timeTxt.visible)
			return;

		super.updateTimeTxt();
		timeTxt.text = defaultTimeText;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		healthBar.percent = (health * 50);

		botplayTxt.visible = play.botplay;
		if (validScore && !play.validScore) {
			validScore = false;
			updatePositions();
		}
		/*if(botplayTxt.visible)
			{
				botplaySin += elapsed * Math.PI;
				botplayTxt.alpha = 0.5 + Math.sin(botplaySin) * 0.8;
		}*/

		for (icon in [iconP1, iconP2])
		{
			icon.globalScale = FlxMath.lerp(icon.globalScale, 1, elapsed * 6);
			if (!icon.isPlayer)
				icon.setAnim(2 - play.health);
			else
				icon.setAnim(play.health);
		}
		updateIconPos();
		updateTimeTxt();
	}

	public function updateIconPos()
	{
		var healthBarPos:DoidoPoint = {
			x: healthBar.x + FlxMath.lerp(healthBar.border.width, 0, healthBar.percent / 100),
			y: healthBar.y - (healthBar.border.height / 2)
		};

		iconP1.y = healthBarPos.y - (iconP1.height / 2);
		iconP2.y = healthBarPos.y - (iconP2.height / 2);

		iconP1.x = healthBarPos.x - 20;
		iconP2.x = healthBarPos.x - iconP2.width + 32;
	}

	override function changeIcon(newIcon:String = "face", type:IconChange = ENEMY)
	{
		super.changeIcon(newIcon, type);
		var isPlayer:Bool = (type == PLAYER);
		var icon = (isPlayer ? iconP1 : iconP2);
		icon.setIcon(newIcon, isPlayer);

		(isPlayer ? healthBar.sideR : healthBar.sideL).color = icon.barColor;
	}

	override function beatHit(curBeat:Int = 0)
	{
		super.beatHit(curBeat);
		if (curBeat % 2 == 0)
		{
			for (icon in [iconP1, iconP2])
			{
				icon.globalScale = 1.3;
				updateIconPos();
			}
		}
	}
}
