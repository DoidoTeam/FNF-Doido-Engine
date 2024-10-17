package gameObjects;

import states.PlayState;
import gameObjects.hud.note.Note;
import flxanimate.animate.FlxAnim;
import flxanimate.FlxAnimate;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import data.CharacterData;
import data.CharacterData.*;

using StringTools;

class Character extends FlxAnimate
{
	public var curChar:String = "bf";
	public var isPlayer:Bool = false;
	public var onEditor:Bool = false;

	public var holdTimer:Float = Math.NEGATIVE_INFINITY;
	public var holdLength:Float = 0.7;
	public var holdLoop:Int = 4;

	public var idleAnims:Array<String> = ["idle"];
	public var altIdle:String = "";
	public var altSing:String = "";

	public var quickDancer:Bool = false;
	public var specialAnim:Int = 0;

	// warning, only uses this
	// if the current character doesnt have game over anims
	public var deathChar:String = "bf-dead";

	public var globalOffset:FlxPoint = new FlxPoint();
	public var cameraOffset:FlxPoint = new FlxPoint();
	public var ratingsOffset:FlxPoint = new FlxPoint();
	private var scaleOffset:FlxPoint = new FlxPoint();

	public function new(curChar:String = "bf", isPlayer:Bool = false, onEditor:Bool = false)
	{
		super(0,0,false);
		this.onEditor = onEditor;
		this.isPlayer = isPlayer;
		this.curChar = curChar;
		
		antialiasing = FlxSprite.defaultAntialiasing;
		isPixelSprite = false;
		
		var doidoChar = CharacterData.defaultChar();
		// what
		switch(curChar)
		{
			case "zero":
				doidoChar.spritesheet += 'zero/zero';
				doidoChar.anims = [
					["idle", 	 'idle', 24, false],
					['intro', 	'intro', 24, false],

					["singLEFT", 'left', 24, false],
					["singDOWN", 'down', 24, false],
					["singUP",   'up', 	 24, false],
					["singRIGHT",'right',24, false],
				];
				antialiasing = false;
				scale.set(12,12);
			case "gemamugen":
				doidoChar.spritesheet += 'gemamugen/gemamugen';
				doidoChar.anims = [
					["idle", 	 'idle', 24, true],
					['idle-alt', 'chacharealsmooth', 24, true],

					["singLEFT", 'left', 24, false],
					["singDOWN", 'down', 24, false],
					["singUP",   'up', 	 24, false],
					["singRIGHT",'right',24, false],
				];
				scale.set(2,2);
			
			case "senpai" | "senpai-angry":
				doidoChar.spritesheet = 'characters/senpai/senpai';

				if(curChar == "senpai") {
					doidoChar.anims = [
						['idle', 		'Senpai Idle instance 1', 		24, false],
						['singLEFT', 	'SENPAI LEFT NOTE instance 1', 	24, false],
						['singDOWN', 	'SENPAI DOWN NOTE instance 1', 	24, false],
						['singUP', 		'SENPAI UP NOTE instance 1', 	24, false],
						['singRIGHT', 	'SENPAI RIGHT NOTE instance 1',	24, false],
					];
				} else {
					doidoChar.anims = [
						['idle', 		'Angry Senpai Idle instance 1', 		24, false],
						['singLEFT', 	'Angry Senpai LEFT NOTE instance 1', 	24, false],
						['singDOWN', 	'Angry Senpai DOWN NOTE instance 1', 	24, false],
						['singUP', 		'Angry Senpai UP NOTE instance 1', 		24, false],
						['singRIGHT', 	'Angry Senpai RIGHT NOTE instance 1',	24, false],
					];
				}
				antialiasing = false;
				isPixelSprite = true;
				scale.set(6,6);
				
			case "spirit":
				doidoChar.spritesheet += 'senpai/spirit';
				doidoChar.anims = [
					['idle', 		"idle spirit_", 24, true],
					['singLEFT', 	"left_", 		24, false],
					['singDOWN', 	"spirit down_", 24, false],
					['singUP', 		"up_", 			24, false],
					['singRIGHT', 	"right_", 		24, false],
				];

				antialiasing = false;
				isPixelSprite = true;
				scale.set(6,6);
				
			case "bf-pixel":
				deathChar = "bf-pixel-dead";
				doidoChar.spritesheet += 'bf-pixel/bfPixel';
				doidoChar.anims = [
					['idle', 			'BF IDLE', 		24, false],
					['singUP', 			'BF UP NOTE', 	24, false],
					['singLEFT', 		'BF LEFT NOTE', 24, false],
					['singRIGHT', 		'BF RIGHT NOTE',24, false],
					['singDOWN', 		'BF DOWN NOTE', 24, false],
					['singUPmiss', 		'BF UP MISS', 	24, false],
					['singLEFTmiss', 	'BF LEFT MISS', 24, false],
					['singRIGHTmiss', 	'BF RIGHT MISS',24, false],
					['singDOWNmiss', 	'BF DOWN MISS', 24, false],
				];

				flipX = true;
				antialiasing = false;
				isPixelSprite = true;
				scale.set(6,6);

			case "bf-pixel-dead":
				deathChar = "bf-pixel-dead";
				doidoChar.spritesheet += 'bf-pixel/bfPixelsDEAD';
				doidoChar.anims = [
					['firstDeath', 		"BF Dies pixel",24, false, CoolUtil.intArray(55)],
					['deathLoop', 		"Retry Loop", 	24, true],
					['deathConfirm', 	"RETRY CONFIRM",24, false],
				];

				idleAnims = ["firstDeath"];

				flipX = true;
				scale.set(6,6);
				antialiasing = false;
				isPixelSprite = true;
				
			case "gf-pixel":
				doidoChar.spritesheet += 'gf-pixel/gfPixel';
				doidoChar.anims = [
					['danceLeft', 	"GF IDLE", 24, false, [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]],
					['danceRight', 	"GF IDLE", 24, false, [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]],
				];

				idleAnims = ["danceLeft", "danceRight"];
				
				scale.set(6,6);
				antialiasing = false;
				isPixelSprite = true;
				quickDancer = true;
				flipX = isPlayer;
			
			case 'luano-day'|'luano-night':
				var pref:String = (curChar == 'luano-night') ? 'night ' : '';
				doidoChar.spritesheet += 'luano/luano';
				doidoChar.anims = [
					['idle', 		'${pref}idle', 24, false],
					['singLEFT', 	'${pref}left', 24, false],
					['singDOWN', 	'${pref}down', 24, false],
					['singUP', 		'${pref}up',   24, false],
					['singRIGHT', 	'${pref}right',24, false],
					['jump', 		'${pref}jump', 24, false],
				];

				holdLoop = 0;
			
			case 'spooky'|'spooky-player':
				var leftRight:Array<String> = ['singLEFT','singRIGHT'];
				if(curChar == 'spooky-player')
					leftRight.reverse();

				doidoChar.spritesheet += 'spooky/SpookyKids';
				doidoChar.anims = [
					['danceLeft',	'Idle', 12, false, [0,2,4,8]],
					['danceRight',	'Idle', 12, false, [10,12,14,16]],

					['${leftRight[0]}',	'SingLEFT', 24, false],
					['singDOWN', 		'SingDOWN', 24, false],
					['singUP', 			'SingUP',   24, false],
					['${leftRight[1]}',	'SingRIGHT',24, false],
				];
				
				idleAnims = ["danceLeft", "danceRight"];
				quickDancer = true;
			
			case "pico":
				doidoChar.spritesheet += 'pico/Pico_FNF_assetss';
				doidoChar.anims = [
					['idle',		'Pico Idle Dance', 24, false],
					['singRIGHT',	'Pico NOTE LEFT0', 24, false],
					['singDOWN', 	'Pico Down Note0', 24, false],
					['singUP', 		'pico Up note0',   24, false],
					['singLEFT',	'Pico Note Right0',24, false],
					// playable pico support soon maybe
					['singRIGHTmiss',	'Pico NOTE LEFT miss', 24, false],
					['singDOWNmiss',	'Pico Down Note MISS', 24, false],
					['singUPmiss', 		'pico Up note miss',   24, false],
					['singLEFTmiss',	'Pico Note Right Miss',24, false],
				];
				flipX = true;

			case "gf":
				isAnimateAtlas = true;
				doidoChar.spritesheet += 'gf/gf-spritemap';
				doidoChar.anims = [
					['sad',			'gf sad',			24, false, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]],
					['danceLeft',	'GF Dancing Beat',	24, false, [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]],
					['danceRight',	'GF Dancing Beat',	24, false, [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]],
					
					['cheer', 		'GF Cheer', 	24, false],
					['singLEFT', 	'GF left note', 24, false],
					['singRIGHT', 	'GF Right Note',24, false],
					['singUP', 		'GF Up Note', 	24, false],
					['singDOWN', 	'GF Down Note', 24, false],
				];

				idleAnims = ["danceLeft", "danceRight"];
				quickDancer = true;
				flipX = isPlayer;
			
			case "no-gf":
				doidoChar.spritesheet += 'gf/no-gf/no-gf';
				doidoChar.anims = [
					['idle', 'idle'],
				];

			case "dad":
				doidoChar.spritesheet += 'dad/DADDY_DEAREST';
				doidoChar.anims = [
					['idle', 		'Dad idle dance', 		24, false],
					['singUP', 		'Dad Sing Note UP', 	24, false],
					['singRIGHT', 	'Dad Sing Note RIGHT', 	24, false],
					['singDOWN', 	'Dad Sing Note DOWN', 	24, false],
					['singLEFT', 	'Dad Sing Note LEFT', 	24, false],

					['idle-loop', 		'Dad idle dance', 		24, true, [11,12,13,14]],
					['singUP-loop', 	'Dad Sing Note UP', 	24, true, [3,4,5,6]],
					['singRIGHT-loop',	'Dad Sing Note RIGHT', 	24, true, [3,4,5,6]],
					['singLEFT-loop', 	'Dad Sing Note LEFT', 	24, true, [3,4,5,6]],
				];
			
			default: // case "bf"
				if(!["bf", "face"].contains(curChar))
					curChar = (isPlayer ? "bf" : "face");

				if(curChar == "bf")
				{
					doidoChar.spritesheet += 'bf/BOYFRIEND';
					doidoChar.anims = [
						['idle', 			'BF idle dance', 		24, false],
						['singUP', 			'BF NOTE UP0', 			24, false],
						['singLEFT', 		'BF NOTE LEFT0', 		24, false],
						['singRIGHT', 		'BF NOTE RIGHT0', 		24, false],
						['singDOWN', 		'BF NOTE DOWN0', 		24, false],
						['singUPmiss', 		'BF NOTE UP MISS', 		24, false],
						['singLEFTmiss', 	'BF NOTE LEFT MISS', 	24, false],
						['singRIGHTmiss', 	'BF NOTE RIGHT MISS', 	24, false],
						['singDOWNmiss', 	'BF NOTE DOWN MISS', 	24, false],
						['hey', 			'BF HEY', 				24, false],
						['scared', 			'BF idle shaking', 		24, true],
					];
					
					flipX = true;
				}
				else if(curChar == "face")
				{
					isAnimateAtlas = true;
					doidoChar.spritesheet += 'face';
					doidoChar.anims = [
						['idle', 			'idle-alive', 		24, false],
						['idlemiss', 		'idle-dead', 		24, false],

						['singLEFT', 		'left-alive', 		24, false],
						['singDOWN', 		'down-alive', 		24, false],
						['singUP', 			'up-alive', 		24, false],
						['singRIGHT', 		'right-alive', 		24, false],
						['singLEFTmiss', 	'left-dead', 		24, false],
						['singDOWNmiss', 	'down-dead', 		24, false],
						['singUPmiss', 		'up-dead', 			24, false],
						['singRIGHTmiss', 	'right-dead', 		24, false],
					];
				}
				this.curChar = curChar;
			
			case "bf-dead":
				doidoChar.spritesheet += 'bf/BOYFRIEND';
				doidoChar.anims = [
					['firstDeath', 		"BF dies", 			24, false],
					['deathLoop', 		"BF Dead Loop", 	24, true],
					['deathConfirm', 	"BF Dead confirm", 	24, false],
				];

				idleAnims = ['firstDeath'];
				
				flipX = true;
		}

		if(!isAnimateAtlas)
		{
			if(Paths.fileExists('images/${doidoChar.spritesheet}.txt'))
				frames = Paths.getPackerAtlas(doidoChar.spritesheet);
			else if(Paths.fileExists('images/${doidoChar.spritesheet}.json'))
				frames = Paths.getAsepriteAtlas(doidoChar.spritesheet);
			else
				frames = Paths.getSparrowAtlas(doidoChar.spritesheet);

			for(i in 0...doidoChar.anims.length)
			{
				var anim:Array<Dynamic> = doidoChar.anims[i];
				if(anim.length > 4)
					animation.addByIndices(anim[0],  anim[1], anim[4], "", anim[2], anim[3]);
				else
					animation.addByPrefix(anim[0], anim[1], anim[2], anim[3]);
			}
		}
		else
		{
			loadAtlas(Paths.getPath('images/${doidoChar.spritesheet}'));
			showPivot = false;
			for(i in 0...doidoChar.anims.length)
			{
				var dAnim:Array<Dynamic> = doidoChar.anims[i];
				if(dAnim.length > 4)
					anim.addBySymbolIndices(dAnim[0], dAnim[1], dAnim[4], dAnim[2], dAnim[3]);
				else
					anim.addBySymbol(dAnim[0], dAnim[1], dAnim[2], dAnim[3]);
			}
		}
		// adding animations to array
		for(i in 0...doidoChar.anims.length) {
			var daAnim = doidoChar.anims[i][0];
			if(animExists(daAnim) && !animList.contains(daAnim))
				animList.push(daAnim);
		}
		// prevents crashing
		for(i in 0...idleAnims.length)
		{
			if(!animList.contains(idleAnims[i]))
				idleAnims[i] = animList[0];
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
	}

	/*public function reloadChar(curChar:String = "bf"):Character
	{
		return this;
	}*/

	private var curDance:Int = 0;

	public function dance(forced:Bool = false)
	{
		if(specialAnim > 0) return;

		switch(curChar)
		{
			default:
				var daIdle = idleAnims[curDance];
				if(animExists(daIdle + altIdle))
					daIdle += altIdle;
				playAnim(daIdle);
				curDance++;

				if (curDance >= idleAnims.length)
					curDance = 0;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if(!onEditor)
		{
			if(animExists(curAnimName + '-loop') && curAnimFinished())
				playAnim(curAnimName + '-loop');
	
			if(specialAnim > 0 && specialAnim != 3 && curAnimFinished())
			{
				specialAnim = 0;
				dance();
			}
		}
	}

	public var singAnims:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	public function playNote(note:Note, miss:Bool = false)
	{
		var daAnim:String = singAnims[note.noteData];
		if(animExists(daAnim + 'miss') && miss)
			daAnim += 'miss';

		if(animExists(daAnim + altSing))
			daAnim += altSing;

		holdTimer = 0;
		specialAnim = 0;
		playAnim(daAnim, true);
	}

	// animation handler
	public var curAnimName:String = '';
	public var animList:Array<String> = [];
	public var animOffsets:Map<String, Array<Float>> = [];

	public function addOffset(animName:String, offX:Float = 0, offY:Float = 0):Void
		return animOffsets.set(animName, [offX, offY]);

	public function playAnim(animName:String, ?forced:Bool = false, ?reversed:Bool = false, ?frame:Int = 0)
	{
		if(!animExists(animName)) return;
		
		curAnimName = animName;
		if(!isAnimateAtlas)
			animation.play(animName, forced, reversed, frame);
		else
			anim.play(animName, forced, reversed, frame);
		
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

	public function animExists(animName:String):Bool
	{
		if(!isAnimateAtlas)
			return animation.getByName(animName) != null;
		else
			return anim.getByName(animName) != null;
	}

	public function curAnimFrame():Int
	{
		if(!isAnimateAtlas)
			return animation.curAnim.curFrame;
		else
			return anim.curSymbol.curFrame;
	}

	public function curAnimFinished():Bool
	{
		if(!isAnimateAtlas)
			return animation.curAnim.finished;
		else
			return anim.finished;
	}
}