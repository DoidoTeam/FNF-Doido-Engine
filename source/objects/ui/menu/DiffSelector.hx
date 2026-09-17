package objects.ui.menu;

import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.math.FlxMath;

enum SelectorType
{
	STORY;
	FREEPLAY;
}

class DiffSelector extends FlxGroup
{
	public var arrowL:FlxSprite;
	public var diffSpr:FlxSprite;
	public var arrowR:FlxSprite;

	public var diffPos:DoidoPoint = {x: 0, y: 0};
	public var leftX:Float = 0;
	public var rightX:Float = 0;

	public var curDiff:String = "";
	public var curId:Int = 0; // rename later
	public var diffCount:Int = 0;

	// lol
	var storedY:Float = -1;
	var storedHeight:Float = -1;

	// style
	public var style:SelectorType = FREEPLAY;
	public var styleData:Map<SelectorType, Map<String, Dynamic>> = [
		FREEPLAY => [
			"arrowSpr" => "menu/freeplay/selector",
			"arrowIdleL" => "arrow pointer loop",
			"arrowPushL" => "arrow pointer loop",
			"arrowIdleR" => "arrow pointer loop",
			"arrowPushR" => "arrow pointer loop",
			"arrowFlipL" => false,
			"arrowFlipR" => true,
			"arrowScale" => 1,
			"diff" => "menu/freeplay/diff/"
		],
		STORY => [
			"arrowSpr" => "menu/menuArrows",
			"arrowIdleL" => "arrow left",
			"arrowPushL" => "arrow push left",
			"arrowIdleR" => "arrow right",
			"arrowPushR" => "arrow push right",
			"arrowFlipL" => false,
			"arrowFlipR" => false,
			"arrowScale" => 0.8,
			"diff" => "menu/story/diff/"
		]
	];

	var dots:FlxTypedGroup<FlxSprite>;
	var dotSpacing:Float = 20;

	public function new(style:SelectorType)
	{
		super();
		this.style = style;

		arrowL = new FlxSprite();
		arrowL.frames = Assets.sparrow(curStyle.get("arrowSpr"));
		arrowL.animation.addByPrefix("idle", curStyle.get("arrowIdleL"), 24, true);
		arrowL.animation.addByPrefix("push", curStyle.get("arrowPushL"), 24, true);
		arrowL.flipX = curStyle.get("arrowFlipL");
		arrowL.scale.set(curStyle.get("arrowScale"), curStyle.get("arrowScale"));
		arrowL.updateHitbox();
		arrowL.animation.play("idle");

		arrowR = new FlxSprite();
		arrowR.frames = Assets.sparrow(curStyle.get("arrowSpr"));
		arrowR.animation.addByPrefix("idle", curStyle.get("arrowIdleR"), 24, true);
		arrowR.animation.addByPrefix("push", curStyle.get("arrowPushR"), 24, true);
		arrowR.flipX = curStyle.get("arrowFlipR");
		arrowR.scale.set(curStyle.get("arrowScale"), curStyle.get("arrowScale"));
		arrowR.updateHitbox();
		arrowR.animation.play("idle");

		add(arrowL);
		add(arrowR);

		diffSpr = new FlxSprite();
		add(diffSpr);

		dots = new FlxTypedGroup<FlxSprite>();
		add(dots);

		changeDiff();
	}

	public function changeDiff(diff:String = "", id:Int = 0, count:Int = 0, change:Int = 0)
	{
		if (curDiff == diff && curId == id && diffCount == count)
			return;

		var animate:Bool = curDiff != diff;
		curDiff = diff;
		curId = id;
		diffCount = count;

		if (Assets.fileExists("images/" + curStyle.get("diff") + diff.toLowerCase(), XML))
		{
			// trace("gulp");
			diffSpr.frames = Assets.sparrow(curStyle.get("diff") + diff.toLowerCase());
			diffSpr.animation.addByPrefix("idle", "idle", 24, true);
			diffSpr.animation.play("idle");
		}
		else
			diffSpr.loadImage(curStyle.get("diff") + diff.toLowerCase());

		diffSpr.scale.set(0.9, 0.9);
		diffSpr.updateHitbox();

		dots.killMembers();
		if (count > 0)
		{
			for (i in 0...count + 1)
			{
				var dot = dots.recycle(FlxSprite);
				dot.loadImage("menu/freeplay/separator");
				dot.alpha = i == id ? 1 : 0.4;
				dot.ID = i;
				dots.add(dot);
			}
		}

		for (arrow in [arrowL, arrowR])
			arrow.alpha = (count > 0 ? 1.0 : 0.0001);

		if (storedY == -1)
			storedY = diffSpr.y;
		if (storedHeight == -1)
			storedHeight = diffSpr.height;

		updateHitbox();

		if (animate)
		{
			diffSpr.y -= 20;
			diffSpr.alpha = 0;
		}

		if (change > 0)
			arrowR.x += 15;
		else if (change < 0)
			arrowL.x -= 15;
	}

	public function updateHitbox()
	{
		diffSpr.x = (diffPos.x - (diffSpr.width / 2));
		diffSpr.y = diffPos.y;

		leftX = diffSpr.x - arrowL.width - 15;
		rightX = diffSpr.x + diffSpr.width + 15;

		arrowL.y = (storedY + storedHeight / 2 - arrowL.height / 2);
		arrowR.y = arrowL.y;

		dots.forEachAlive((dot) ->
		{
			dot.x = diffPos.x - (dot.width / 2) + (dotSpacing * dot.ID) - (diffCount * dotSpacing) / 2;
			dot.y = diffPos.y + storedHeight + 10;
		});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		diffSpr.y = FlxMath.lerp(diffSpr.y, diffPos.y, elapsed * 12);
		diffSpr.alpha = FlxMath.lerp(diffSpr.alpha, 1, elapsed * 8);

		arrowL.x = FlxMath.lerp(arrowL.x, leftX, elapsed * 8);
		arrowR.x = FlxMath.lerp(arrowR.x, rightX, elapsed * 8);
	}

	var curStyle(get, never):Map<String, Dynamic>;

	function get_curStyle():Map<String, Dynamic>
		return styleData.get(style);
}
