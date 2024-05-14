package gameObjects;

//import haxe.Json;
//import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import data.CharacterData.DoidoOffsets;

using StringTools;

class Character extends FlxSprite
{
	public function new() {
		super();
	}

	public var curChar:String = "bf";
	public var isPlayer:Bool = false;

	public var holdTimer:Float = Math.NEGATIVE_INFINITY;
	public var holdLength:Float = 0.7;
	public var holdLoop:Int = 4;

	public var idleAnims:Array<String> = [];

	public var quickDancer:Bool = false;
	public var specialAnim:Int = 0;

	// warning, only uses this
	// if the current character doesnt have game over anims
	public var deathChar:String = "bf";

	public var globalOffset:FlxPoint = new FlxPoint();
	public var cameraOffset:FlxPoint = new FlxPoint();
	public var ratingsOffset:FlxPoint = new FlxPoint();
	private var scaleOffset:FlxPoint = new FlxPoint();

	public function reloadChar(curChar:String = "bf"):Character
	{
		this.curChar = curChar;

		holdLoop = 4;
		holdLength = 0.7;
		idleAnims = ["idle"];

		quickDancer = false;

		flipX = flipY = false;
		scale.set(1,1);
		antialiasing = FlxSprite.defaultAntialiasing;
		isPixelSprite = false;
		deathChar = "bf";

		var storedPos:Array<Float> = [x, y];
		globalOffset.set();
		cameraOffset.set();
		ratingsOffset.set();

		animOffsets = []; // reset it

		// what
		switch(curChar)
		{
			case "gemamugen":
				frames = Paths.getSparrowAtlas("characters/gemamugen/gemamugen");
				
				animation.addByPrefix('idle', 		'idle', 24, true);
				animation.addByPrefix('idle-alt',	'chacharealsmooth', 24, true);
				animation.addByPrefix('singLEFT', 	'left', 24, false);
				animation.addByPrefix('singDOWN', 	'down', 24, false);
				animation.addByPrefix('singUP', 	'up', 24, false);
				animation.addByPrefix('singRIGHT', 	'right', 24, false);

				scale.set(2,2);
			
			case "senpai" | "senpai-angry":
				frames = Paths.getSparrowAtlas("characters/senpai/senpai");
				
				if(curChar == "senpai") {
					animation.addByPrefix('idle', 		'Senpai Idle instance 1', 		24, false);
					animation.addByPrefix('singLEFT', 	'SENPAI LEFT NOTE instance 1', 	24, false);
					animation.addByPrefix('singDOWN', 	'SENPAI DOWN NOTE instance 1', 	24, false);
					animation.addByPrefix('singUP', 	'SENPAI UP NOTE instance 1', 	24, false);
					animation.addByPrefix('singRIGHT', 	'SENPAI RIGHT NOTE instance 1',	24, false);
				} else {
					animation.addByPrefix('idle', 		'Angry Senpai Idle instance 1', 		24, false);
					animation.addByPrefix('singLEFT', 	'Angry Senpai LEFT NOTE instance 1', 	24, false);
					animation.addByPrefix('singDOWN', 	'Angry Senpai DOWN NOTE instance 1', 	24, false);
					animation.addByPrefix('singUP', 	'Angry Senpai UP NOTE instance 1', 		24, false);
					animation.addByPrefix('singRIGHT', 	'Angry Senpai RIGHT NOTE instance 1',	24, false);
				}
				
				antialiasing = false;
				isPixelSprite = true;
				scale.set(6,6);
				
			case "spirit":
				frames = Paths.getPackerAtlas("characters/senpai/spirit");
				
				animation.addByPrefix('idle', 		"idle spirit_", 24, true);
				animation.addByPrefix('singLEFT', 	"left_", 		24, false);
				animation.addByPrefix('singDOWN', 	"spirit down_", 24, false);
				animation.addByPrefix('singUP', 	"up_", 			24, false);
				animation.addByPrefix('singRIGHT', 	"right_", 		24, false);
				
				antialiasing = false;
				isPixelSprite = true;
				scale.set(6,6);

			case "bf-pixel":
				frames = Paths.getSparrowAtlas("characters/bf-pixel/bfPixel");

				animation.addByPrefix('idle', 			'BF IDLE', 		24, false);
				animation.addByPrefix('singUP', 		'BF UP NOTE', 	24, false);
				animation.addByPrefix('singLEFT', 		'BF LEFT NOTE', 24, false);
				animation.addByPrefix('singRIGHT', 		'BF RIGHT NOTE',24, false);
				animation.addByPrefix('singDOWN', 		'BF DOWN NOTE', 24, false);
				animation.addByPrefix('singUPmiss', 	'BF UP MISS', 	24, false);
				animation.addByPrefix('singLEFTmiss', 	'BF LEFT MISS', 24, false);
				animation.addByPrefix('singRIGHTmiss', 	'BF RIGHT MISS',24, false);
				animation.addByPrefix('singDOWNmiss', 	'BF DOWN MISS', 24, false);

				flipX = true;
				antialiasing = false;
				isPixelSprite = true;
				scale.set(6,6);

				deathChar = "bf-pixel-dead";
				if(isPlayer)
					Paths.preloadGraphic("characters/bf-pixel/bfPixelsDEAD");

			case "bf-pixel-dead":
				frames = Paths.getSparrowAtlas("characters/bf-pixel/bfPixelsDEAD");

				animation.addByPrefix('firstDeath', 	"BF Dies pixel",24, false);
				animation.addByPrefix('deathLoop', 		"Retry Loop", 	24, true);
				animation.addByPrefix('deathConfirm', 	"RETRY CONFIRM",24, false);
				animation.play('firstDeath');

				idleAnims = ["firstDeath"];

				flipX = true;
				scale.set(6,6);
				antialiasing = false;
				isPixelSprite = true;
				
			case "gf-pixel":
				frames = Paths.getSparrowAtlas("characters/gf-pixel/gfPixel");
				
				animation.addByIndices('danceLeft',  'GF IDLE', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF IDLE', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				
				idleAnims = ["danceLeft", "danceRight"];
				
				scale.set(6,6);
				antialiasing = false;
				isPixelSprite = true;
				quickDancer = true;
				flipX = isPlayer;
			
			case 'luano-day'|'luano-night':
				frames = Paths.getSparrowAtlas('characters/luano/luano');

				var pref:String = (curChar == 'luano-night') ? 'night ' : '';

				animation.addByPrefix('idle', 		'${pref}idle', 24, false);
				animation.addByPrefix('singLEFT', 	'${pref}left', 24, false);
				animation.addByPrefix('singDOWN', 	'${pref}down', 24, false);
				animation.addByPrefix('singUP', 	'${pref}up',   24, false);
				animation.addByPrefix('singRIGHT', 	'${pref}right',24, false);
				animation.addByPrefix('jump', 		'${pref}jump',24, false);

				holdLoop = 0;
			
			case 'spooky'|'spooky-player':
				frames = Paths.getSparrowAtlas('characters/spooky/SpookyKids');

				animation.addByIndices('danceLeft',	'Idle', [0,2,4,8], 		"", 12, false);
				animation.addByIndices('danceRight','Idle', [10,12,14,16], 	"", 12, false);
				var leftRight:Array<String> = ['singLEFT','singRIGHT'];
				if(curChar == 'spooky-player')
					leftRight.reverse();
				animation.addByPrefix('${leftRight[0]}','SingLEFT', 24, false);
				animation.addByPrefix('singDOWN', 		'SingDOWN', 24, false);
				animation.addByPrefix('singUP', 		'SingUP',   24, false);
				animation.addByPrefix('${leftRight[1]}','SingRIGHT',24, false);
				
				idleAnims = ["danceLeft", "danceRight"];
				quickDancer = true;
				
			case "bf":
				frames = Paths.getSparrowAtlas("characters/bf/BOYFRIEND");

				animation.addByPrefix('idle', 			'BF idle dance', 		24, false);
				animation.addByPrefix('singUP', 		'BF NOTE UP0', 			24, false);
				animation.addByPrefix('singLEFT', 		'BF NOTE LEFT0', 		24, false);
				animation.addByPrefix('singRIGHT', 		'BF NOTE RIGHT0', 		24, false);
				animation.addByPrefix('singDOWN', 		'BF NOTE DOWN0', 		24, false);
				animation.addByPrefix('singUPmiss', 	'BF NOTE UP MISS', 		24, false);
				animation.addByPrefix('singLEFTmiss', 	'BF NOTE LEFT MISS', 	24, false);
				animation.addByPrefix('singRIGHTmiss', 	'BF NOTE RIGHT MISS', 	24, false);
				animation.addByPrefix('singDOWNmiss', 	'BF NOTE DOWN MISS', 	24, false);
				animation.addByPrefix('hey', 			'BF HEY', 				24, false);

				animation.addByPrefix('firstDeath', 	"BF dies", 			24, false);
				animation.addByPrefix('deathLoop', 		"BF Dead Loop", 	24, true);
				animation.addByPrefix('deathConfirm', 	"BF Dead confirm", 	24, false);

				animation.addByPrefix('scared', 'BF idle shaking', 24);

				flipX = true;

			case "gf" | "gf-tutorial":
				// GIRLFRIEND CODE
				frames = Paths.getSparrowAtlas('characters/gf/GF_assets' + ((curChar == "gf-tutorial") ? "_singer" : ""));
				animation.addByPrefix('cheer', 'GF Cheer', 24, false);
				if(curChar == 'gf-tutorial')
				{
					animation.addByPrefix('singLEFT', 	'GF left note', 24, false);
					animation.addByPrefix('singRIGHT', 	'GF Right Note', 24, false);
					animation.addByPrefix('singUP', 	'GF Up Note', 24, false);
					animation.addByPrefix('singDOWN', 	'GF Down Note', 24, false);
				}
				animation.addByIndices('sad', 		'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
				animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight','GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				//animation.addByIndices('hairBlow', 	"GF Dancing Beat Hair blowing", [0, 1, 2, 3], "", 24);
				//animation.addByIndices('hairFall', 	"GF Dancing Beat Hair Landing", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);
				animation.addByPrefix('scared', 'GF FEAR', 24);

				idleAnims = ["danceLeft", "danceRight"];
				quickDancer = true;
				flipX = isPlayer;

			case "dad":
				// DAD ANIMATION LOADING CODE
				frames = Paths.getSparrowAtlas("characters/dad/DADDY_DEAREST");
				animation.addByPrefix('idle', 		'Dad idle dance', 		24, false);
				animation.addByPrefix('singUP', 	'Dad Sing Note UP', 	24, false);
				animation.addByPrefix('singRIGHT', 	'Dad Sing Note RIGHT', 	24, false);
				animation.addByPrefix('singDOWN', 	'Dad Sing Note DOWN', 	24, false);
				animation.addByPrefix('singLEFT', 	'Dad Sing Note LEFT', 	24, false);

				animation.addByIndices('idle-loop', 	'Dad idle dance',  [11,12,13,14], "", 24, true);
				animation.addByIndices('singUP-loop', 	'Dad Sing Note UP',    [3,4,5,6], "", 24, true);
				animation.addByIndices('singRIGHT-loop','Dad Sing Note RIGHT', [3,4,5,6], "", 24, true);
				animation.addByIndices('singLEFT-loop', 'Dad Sing Note LEFT',  [3,4,5,6], "", 24, true);

			default:
				return reloadChar(isPlayer ? "bf" : "dad");
		}
		
		// offset gettin'
		switch(curChar)
		{
			default:
				try {
					var charData:DoidoOffsets = cast Paths.json('images/characters/_offsets/${curChar}');
					
					for(i in 0...charData.animOffsets.length)
					{
						var animData:Array<Dynamic> = charData.animOffsets[i];
						addOffset(animData[0], animData[1], animData[2]);
					}
					globalOffset.set(charData.globalOffset[0], charData.globalOffset[1]);
					cameraOffset.set(charData.cameraOffset[0], charData.cameraOffset[1]);
					ratingsOffset.set(charData.ratingsOffset[0], charData.ratingsOffset[1]);
				} catch(e) {
					trace('$curChar offsets not found');
				}
		}
		
		playAnim(idleAnims[0]);

		updateHitbox();
		scaleOffset.set(offset.x, offset.y);

		if(isPlayer)
			flipX = !flipX;

		dance();

		setPosition(storedPos[0], storedPos[1]);

		return this;
	}

	private var curDance:Int = 0;

	public function dance(forced:Bool = false)
	{
		if(specialAnim > 0) return;

		switch(curChar)
		{
			default:
				playAnim(idleAnims[curDance]);
				curDance++;

				if (curDance >= idleAnims.length)
					curDance = 0;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(animation.getByName(animation.curAnim.name + '-loop') != null)
			if(animation.curAnim.finished)
				playAnim(animation.curAnim.name + '-loop');
		
		if(specialAnim == 2 && animation.curAnim.finished)
		{
			specialAnim = 0;
			dance();
		}
	}

	// animation handler
	public var animOffsets:Map<String, Array<Float>> = [];

	public function addOffset(animName:String, offX:Float = 0, offY:Float = 0):Void
		return animOffsets.set(animName, [offX, offY]);

	public function playAnim(animName:String, ?forced:Bool = false, ?reversed:Bool = false, ?frame:Int = 0)
	{
		if(!animation.exists(animName)) return;
		
		animation.play(animName, forced, reversed, frame);
		
		try
		{
			var daOffset = animOffsets.get(animName);
			offset.set(daOffset[0] * scale.x, daOffset[1] * scale.y);
		}
		catch(e)
			offset.set(0,0);

		// useful for pixel notes since their offsets are not 0, 0 by default
		offset.x += scaleOffset.x;
		offset.y += scaleOffset.y;
	}
}