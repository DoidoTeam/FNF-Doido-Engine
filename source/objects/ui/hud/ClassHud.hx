package objects.ui.hud;

import flixel.math.FlxMath;
import flixel.FlxSprite;

enum IconChange
{
	PLAYER;
	ENEMY;
}

class ClassHud extends FlxGroup
{
	public var play:Playable;
	public var hudName:String = "base";
	public var separator:String = " | ";
	public var health:Float = 1;
	public var numberGrp:FlxGroup;
	public var ratingGrp:FlxGroup;

	public var alpha(default, set):Float = 1.0;
	public var alphaList:Map<FlxSprite, Float> = [];

	public function set_alpha(v:Float):Float
	{
		alpha = v;
		for (item => stored in alphaList)
			if (item != null)
				item.alpha = stored * alpha;
		return alpha;
	}

	public function updateAlphaList(list:Array<FlxSprite>)
	{
		for (spr in list)
			alphaList.set(spr, spr.alpha);
	}

	public function new(hudName:String, play:Playable)
	{
		super();
		this.hudName = hudName;
		this.play = play;
		numberGrp = new FlxGroup();
		ratingGrp = new FlxGroup();
	}

	public function init()
	{
		updateScoreTxt();
	}

	public function updateScoreTxt() {}

	public function updatePositions()
	{
		updateScoreTxt();
	}

	public function changeIcon(newIcon:String = "face", type:IconChange = ENEMY) {}

	public function stepHit(curStep:Int = 0) {}

	public function beatHit(curBeat:Int = 0) {}

	var ratingCount:Int = 0;

	public function popUpRating(ratingName:String = "", assetPath:String = "base"):RatingSprite
	{
		var rating:RatingSprite = cast ratingGrp.recycle(RatingSprite, () -> new RatingSprite(assetPath));
		rating.setUp(ratingName);

		if (!ratingGrp.members.contains(rating))
			ratingGrp.add(rating);

		rating.zIndex = ratingCount;
		ratingCount++;
		ratingGrp.members.sort(ZIndex.sortAscending);
		return rating;
	}

	var comboCount:Int = 0;

	public function popUpCombo(comboNum:Int, assetPath:String = "base"):Array<ComboSprite>
	{
		var comboStr:String = '${Math.abs(comboNum)}'.lpad("0", 3);
		if (comboNum < 0)
			comboStr = '-$comboStr';
		var stringArr = comboStr.split("");

		var numberArray:Array<ComboSprite> = [];
		for (i in 0...stringArr.length)
		{
			var number:ComboSprite = cast numberGrp.recycle(ComboSprite, () -> new ComboSprite(assetPath));
			number.setUp(stringArr[i]);

			if (comboNum <= 0)
				number.color = number.badColor;

			if (!numberGrp.members.contains(number))
				numberGrp.add(number);

			number.zIndex = comboCount;
			numberArray.push(number);
		}
		positionCombo(numberArray);
		comboCount++;
		numberGrp.members.sort(ZIndex.sortAscending);
		return numberArray;
	}

	function positionCombo(numberArray:Array<ComboSprite>)
	{
		var numWidth:Float = -1;
		for (i in 0...numberArray.length)
		{
			var number = numberArray[i];
			if (numWidth == -1)
				numWidth = number.width - 8;

			number.screenCenter(X);
			number.x += numWidth * i;
			number.x -= (numWidth * (numberArray.length - 1)) / 2;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		health = FlxMath.lerp(health, play.health, elapsed * 8);
		if (Math.abs(health - play.health) <= 0.00001)
			health = play.health;
		// updateTimeTxt();
	}
}
