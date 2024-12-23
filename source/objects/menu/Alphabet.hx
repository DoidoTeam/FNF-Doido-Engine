package objects.menu;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

enum AlphabetAlign
{
	LEFT;
	CENTER;
	RIGHT;
}
class Alphabet extends FlxSpriteGroup
{
	public var align:AlphabetAlign = LEFT;

	public function new(x:Float = 0, y:Float = 0, ?text:String = "", bold:Bool = false)
	{
		super(x, y);
		
		atlasFrames = Paths.getSparrowAtlas("menu/alphabet/default");

		this.bold = bold;
		this.text = text;
	}

	public var text(default, set):String = "";
	public var textArray:Array<String> = [];
	public var bold:Bool = false;
	public var fieldWidth:Float = 0;

	public final boxHeight:Float = 70;

	var atlasFrames:FlxAtlasFrames;

	public function set_text(v:String):String
	{
		text = v;
		text = Std.string(text);
		textArray = text.split("");
		typeTxt();
		return v;
	}

	public var letters:String = "abcdefghijklmnopqrstuvwxyzç";
	public var numbers:String = "0123456789";
	public var symbols:String = ",.#$%&()*+-:;<=>@[]^_!¨?/|~'\"";

	public function typeTxt()
	{
		clear();

		var lastWidth:Float = 0;
		var daRow:Int = 0;

		for(i in 0...textArray.length)
		{
			var daLetter:String = textArray[i];

			if(daLetter == "\n") // \\
			{
				daRow++;
				lastWidth = 0;
				lineWidth[daRow] = 0;
				continue;
			}

			if(daLetter == " ") 
			{
				lastWidth += 35;
				lineWidth[daRow] = lastWidth;
				continue;
			}

			var letter = new AlphaLetter();
			letter.frames = atlasFrames;
			letter.row = daRow;

			letter.ID = i; // using this for typing

			// letters
			if(letters.contains(daLetter.toLowerCase()))
			{
				letter.makeLetter(daLetter, bold);
			}

			// numbers
			if(numbers.contains(daLetter))
			{
				letter.makeNumber(daLetter, bold);
			}

			// symbols
			if(symbols.contains(daLetter))
			{
				letter.makeSymbol(daLetter, bold);
			}

			// just so the width stays consistent
			letter.scale.set(1,1);
			letter.updateHitbox();

			letter.lastWidth = lastWidth;
			lastWidth += letter.width;
			lineWidth[daRow] = lastWidth;

			add(letter);
		}

		updateHitbox();
	}

	public var lineWidth:Array<Float> = [];

	public var letterSpace:FlxPoint = new FlxPoint();

	override function updateHitbox()
	{
		super.updateHitbox();
		for(rawLetter in members)
		{
			rawLetter.scale.set(scale.x, scale.y);
			rawLetter.updateHitbox();

			if(Std.isOfType(rawLetter, AlphaLetter))
			{
				var letter = cast(rawLetter, AlphaLetter);

				letter.x = x + ((letter.lastWidth * scale.x) + (letter.letterOffset.x * scale.x));

				switch(align)
				{
					default:
					case CENTER:
						letter.x -= (lineWidth[letter.row] * scale.x) / 2;
					case RIGHT:
						letter.x -= (lineWidth[letter.row] * scale.x);
				}

				// i hate you i hate you i hate you i hate you
				letter.y = y + (boxHeight * scale.y * (letter.row + 1));
				letter.y -= letter.height - (letter.letterOffset.y * scale.y);
			}
		}
	}
}
class AlphaLetter extends FlxSprite
{
	public var lastWidth:Float = 0;
	public var row:Int = 0;

	public var letterOffset:FlxPoint = new FlxPoint();

	public function new()
	{
		super();
	}

	function addAnim(animName:String, animXml:String)
	{
		animation.addByPrefix(animName, animXml, 24, true);
		animation.play(animName);
		updateHitbox();
	}

	public function makeLetter(key:String, bold:Bool = false)
	{
		if(!bold)
		{
			var captPref:String = (key == key.toUpperCase()) ? "capital" : "lowercase";
			addAnim(key, '${key.toUpperCase()} ${captPref}');
		}
		else
			addAnim(key, '${key.toUpperCase()} bold');
	}

	public function makeNumber(key:String, bold:Bool = false)
	{
		if(!bold)
			addAnim(key, '${key}0');
		else
			addAnim(key, '$key bold');
	}

	public function makeSymbol(key:String, bold:Bool = false)
	{
		var animName:String = switch(key)
		{
			default: key;
			case "'": "apostraphie";
			case ",": "comma";
			case "!": "exclamation point";
			case '"': "parentheses start";
			case ".": "period";
			case "?": "question mark";
			case "/": "slash forward";
			case "÷": "heart";
		}

		animName += (bold ? " bold" : "0");
		addAnim(key, animName);

		switch(key)
		{
			case "-": letterOffset.y = -20;
			case '"'|"'": letterOffset.y = -40;
		}
	}

	public function makeArrow(key:String)
	{
		//Logs.print('why $key');
		switch(key.toLowerCase())
		{
			case "left": addAnim("arrowL", "arrow left");
			case "down": addAnim("arrowD", "arrow down");
			case "up": 	 addAnim("arrowU", "arrow up");
			case "right":addAnim("arrowR", "arrow right");
		}
	}
}