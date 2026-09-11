package objects.ui.hud;

import flixel.util.FlxColor;
import doido.objects.Alphabet;
import flixel.math.FlxMath;
import objects.ui.hud.ClassHud.IconChange;
import doido.song.Conductor;

class VSliceHud extends ClassHud
{
	public var scoreTxt:FlxBitmapText;

	var botplaySin:Float = 0;
	var botplayTxt:Alphabet;

	var badScoreText:String = "SCORE WON'T BE SAVED";
	var validScore:Bool = true;

	public var healthBar:DoidoBar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public function new(play:Playable)
	{
		super("vslice", play);
		add(numberGrp);
		add(ratingGrp);

		healthBar = new DoidoBar("ui/hud/base/healthBar", "ui/hud/base/healthBar-border");
		healthBar.sideL.color = 0xFFFF0000;
		healthBar.sideR.color = 0xFF66FF33;
		add(healthBar);

		iconP1 = new HealthIcon();
		changeIcon(play.player1, PLAYER);
		add(iconP1);

		iconP2 = new HealthIcon();
		changeIcon(play.player2, ENEMY);
		add(iconP2);

		scoreTxt = new FlxBitmapText(FlxG.width / 2 + 112, 0, Assets.bitmapFont("vcr"));
		scoreTxt.setOutline(0xFF000000, 2);
		scoreTxt.alignment = CENTER;
		add(scoreTxt);

		botplayTxt = new Alphabet(FlxG.width / 2, FlxG.height / 2, "[<wave intensity=10 speed=4 delay=0.5>BOTPLAY</wave>]", true, CENTER);
		botplayTxt.scale.set(0.7, 0.7);
		botplayTxt.updateHitbox();
		botplayTxt.y -= (botplayTxt.height / 2);
		add(botplayTxt);

		updatePositions();
	}

	override function popUpRating(ratingName:String = "", assetPath:String = "base"):RatingSprite
	{
		var rating = super.popUpRating(ratingName, assetPath);
		rating.screenCenter(X);
		rating.y = FlxG.height / 2 - 150;
		rating.defaultAnim();
		return rating;
	}

	override function popUpCombo(comboNum:Int, assetPath:String = "base"):Array<ComboSprite>
	{
		var numberArray = super.popUpCombo(comboNum, assetPath);

		for (number in numberArray)
		{
			number.x -= 50;
			number.y = FlxG.height / 2 - 50;
			number.defaultAnim();
		}

		return numberArray;
	}

	override function updatePositions()
	{
		super.updatePositions();

		healthBar.x = (FlxG.width / 2) - (healthBar.border.width / 2);
		healthBar.y = (play.downscroll ? 70 : FlxG.height - healthBar.border.height - 50);

		scoreTxt.y = healthBar.y + healthBar.border.height + 8;

		updateIconPos();
	}

	override function updateScoreTxt()
	{
		if (!validScore)
			return;
		scoreTxt.text = 'Score: ' + FlxStringUtil.formatMoney(Timings.score, false, true);
	}

	override function updateTimeTxt() {}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		healthBar.percent = (health * 50);

		botplayTxt.visible = play.botplay;
		if (validScore && !play.validScore)
		{
			validScore = false;
			scoreTxt.text = badScoreText;
			scoreTxt.color = FlxColor.RED;
			scoreTxt.screenCenter(X);
		}

		for (icon in [iconP1, iconP2])
		{
			icon.globalScale = FlxMath.lerp(icon.globalScale, 1, elapsed * 6);
			if (!icon.isPlayer)
				icon.setAnim(2 - play.health);
			else
				icon.setAnim(play.health);
		}
		updateIconPos();
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
