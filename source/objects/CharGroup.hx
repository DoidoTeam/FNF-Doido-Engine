package objects;

import objects.Character;
import flixel.math.FlxPoint;
import doido.utils.NoteUtil;
import flixel.group.FlxGroup.FlxTypedGroup;
import objects.ui.notes.Strumline;

class CharGroup extends FlxTypedGroup<Character>
{
	public var char:Character;
	public var isPlayer:Bool = false;
	public var strumline:Strumline;

	public function new(isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
	}

	public function addChar(charName:String, isActive:Bool = false)
	{
		var newChar = new Character(charName, isPlayer);
		add(newChar);

		if (isPlayer)
		{
			var deadCharExists:Bool = false;
			for (char in members)
			{
				if (char.curChar == newChar.deathChar)
					deadCharExists = true;
			}
			if (!deadCharExists)
			{
				trace("DEATH CHAR DOESN'T EXIST, CREATING: " + newChar.deathChar);
				var deadChar = new Character(newChar.deathChar, true);
				add(deadChar);
			}
		}

		setActive(isActive ? charName : null);
	}

	public function setActive(?charName:String)
	{
		charName = charName ?? curChar;

		char = null;
		for (char in members)
		{
			char.alpha = 0.0001;
			if (char.curChar == charName)
				this.char = char;
		}
		if (char == null)
		{
			// char = members[0];
			addChar(charName, true);
			Logs.print(charName + " DOESN'T EXIST, ADDING", WARNING);
			return;
		}
		updateChar();
	}

	public function updateChar()
	{
		char.x = x - (char.width / 2) + char.globalOffset.x;
		char.y = y - (char.height) + char.globalOffset.y;
		char.scrollFactor.set(scrollFactorX, scrollFactorY);
		char.alpha = alpha * (char.data.alpha ?? 1.0);
		char.angle = angle;
	}

	public var x(default, set):Float = 0.0;

	public function set_x(v:Float):Float
	{
		x = v;
		updateChar();
		return x;
	}

	public var y(default, set):Float = 0.0;

	public function set_y(v:Float):Float
	{
		y = v;
		updateChar();
		return y;
	}

	public function setPos(x:Float = 0, y:Float = 0)
	{
		@:bypassAccessor {
			this.x = x;
			this.y = y;
		}
		updateChar();
	}

	public var scrollFactorX(default, set):Float = 1.0;

	public function set_scrollFactorX(v:Float):Float
	{
		scrollFactorX = v;
		updateChar();
		return scrollFactorX;
	}

	public var scrollFactorY(default, set):Float = 1.0;

	public function set_scrollFactorY(v:Float):Float
	{
		scrollFactorY = v;
		updateChar();
		return scrollFactorY;
	}

	public function setScrollFactor(x:Float = 0, y:Float = 0)
	{
		scrollFactorX = x;
		scrollFactorY = y;
	}

	public var alpha(default, set):Float = 1.0;

	public function set_alpha(v:Float):Float
	{
		alpha = v;
		updateChar();
		return alpha;
	}

	public var angle(default, set):Float = 0.0;

	public function set_angle(v:Float):Float
	{
		angle = v;
		updateChar();
		char.updateOffset();
		return angle;
	}

	public function playSingAnim(lane:Int, miss:Bool = false)
	{
		if (specialAnim == IGNORE_NOTES || specialAnim == OVERRIDE_ALL)
			return;

		resetSingStep();
		specialAnim = NONE;
		playAnim(NoteUtil.getSingAnims(4)[lane] + (miss ? "miss" : ""), true);
	}

	public function resetSingStep()
	{
		char.singStep = char.singLength;
	}

	public function playAnim(animName:String, forced:Bool = true, frame:Int = 0)
		char.playAnim(animName, forced, frame);

	public function dance(forced:Bool = false)
		char.dance(forced);

	public var width(get, never):Float;

	public function get_width():Float
		return char.width;

	public var height(get, never):Float;

	public function get_height():Float
		return char.height;

	public var frameWidth(get, never):Float;

	public function get_frameWidth():Float
		return char.frameWidth;

	public var frameHeight(get, never):Float;

	public function get_frameHeight():Float
		return char.frameHeight;

	public var curChar(get, never):String;

	public function get_curChar():String
		return char.curChar;

	public var curAnimName(get, never):String;

	public function get_curAnimName():String
		return char.curAnimName;

	public var curAnimFrame(get, never):Int;

	public function get_curAnimFrame():Int
		return char.curAnimFrame;

	public function getMidpoint(?point:Null<FlxPoint>):FlxPoint
		return char.getMidpoint(point);

	public var cameraOffset(get, never):DoidoPoint;

	public function get_cameraOffset():DoidoPoint
		return char.cameraOffset;

	public var singStep(get, never):Float;

	public function get_singStep():Float
		return char.singStep;

	public var singType(get, never):SingType;

	public function get_singType():SingType
		return char.singType;

	public var singLoop(get, never):Int;

	public function get_singLoop():Int
		return char.singLoop;

	public var quickDancer(get, never):Bool;

	public function get_quickDancer():Bool
		return char.quickDancer;

	public function animExists(animName:String):Bool
		return char.animExists(animName);

	public var specialAnim(get, set):SpecialAnim;

	public function get_specialAnim():SpecialAnim
		return char.specialAnim;

	public function set_specialAnim(sp:SpecialAnim):SpecialAnim
	{
		char.specialAnim = sp;
		return char.specialAnim;
	}
}
