package objects.ui.hud;

import flixel.util.FlxColor;
import doido.objects.Alphabet;
import flixel.math.FlxMath;
import objects.ui.hud.ClassHud.IconChange;
import doido.song.Conductor;

// Used in the ChartTestSubState
class TestHud extends ClassHud
{
	public var scoreTxt:FlxBitmapText;
	public var timeTxt:FlxBitmapText;

	var botplaySin:Float = 0;
	var botplayTxt:Alphabet;

	public function new(play:Playable)
	{
		super("test", play);
		add(numberGrp);
		add(ratingGrp);

		scoreTxt = new FlxBitmapText(0, 0, Assets.bitmapFont("vcr"));
		scoreTxt.setOutline(0xFF000000, 2);
		scoreTxt.alignment = CENTER;
		scoreTxt.scale.set(1.3, 1.3);
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

		updatePositions();
	}

	override function popUpRating(ratingName:String = "", assetPath:String = "base"):RatingSprite
	{
		var rating = super.popUpRating(ratingName, assetPath);
		rating.ratingScale = 0.7;
		rating.screenCenter(X);
		rating.y = ratingPos;
		rating.defaultAnim();
		return rating;
	}

	override function popUpCombo(comboNum:Int, assetPath:String = "base"):Array<ComboSprite>
	{
		var numberArray = super.popUpCombo(comboNum, assetPath);

		for (number in numberArray)
		{
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
		scoreTxt.screenCenter(X);
		scoreTxt.y = (play.downscroll ? 15 : FlxG.height - scoreTxt.height - 15);
		timeTxt.screenCenter(X);
		timeTxt.y = play.downscroll ? (FlxG.height - timeTxt.height - 14) : (14);
	}

	override function updateScoreTxt()
	{
		var scoreText:String = "";
		scoreText = 'Accuracy: ${Timings.accuracy}%' + ' -- Step: ${play.curStep}\n';
		scoreText += 'Hits: ${Timings.notesHit} -- Misses: ${Timings.misses}';
		scoreTxt.text = scoreText;
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
		botplayTxt.visible = play.botplay;
		updateTimeTxt();
	}
}
