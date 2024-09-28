package;

import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import gameObjects.hud.note.Note;

using StringTools;

class CoolUtil
{
	// general things
	inline public static function formatChar(char:String):String
	{
		return char.substring(0, char.lastIndexOf('-'));
	}

	inline public static function displayName(song:String):String
		return song.toUpperCase().replace("-", " ");

	public static function charList():Array<String>
	{
		return [
			"face",
			"dad",
			"gf",
			"bf",
			"bf-dead",
			"bf-pixel",
			"bf-pixel-dead",
			"gf-pixel",
			"spooky",
			"spooky-player",
			"luano-day",
			"luano-night",
			"senpai",
			"senpai-angry",
			"spirit",
			"gemamugen",
			"zero"
		];
	}
	
	public static function coolTextFile(key:String):Array<String>
	{
		var daList:Array<String> = Paths.text(key).split('\n');

		for(i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}
	
	public static function posToTimer(mil:Float = 0, hasMil:Bool = false):String
	{
		if(mil < 0) mil = 0;
		// gets song pos and makes a timer out of it
		var sec:Int = Math.floor(mil / 1000);
		var min:Int = Math.floor(sec / 60);
		
		function forceZero(shit:String):String
		{
			while(shit.length <= 1)
				shit = '0' + shit;
			return shit;
		}
		
		var disSec:String = '${sec % 60}';
		var disMin:String = '$min';
		disSec = forceZero(disSec);
		//disMin = forceZero(disMin);
		
		if(!hasMil)
			return '$disMin:$disSec';
		else
			return '$disMin:${disSec}.${Math.floor((mil % 1000) / 10)}';
	}
	
	inline public static function intArray(end:Int, start:Int = 0):Array<Int>
	{
		if(start > end) {
			var oldStart = start;
			start = end;
			end = oldStart;
		}
		
		var result:Array<Int> = [];
		for(i in start...end + 1)
		{
			result.push(i);
		}
		return result;
	}
	
	// custom camera follow because default lerp is broken :(
	public static function dumbCamPosLerp(cam:flixel.FlxCamera, target:flixel.FlxObject, lerp:Float = 1)
	{
		cam.scroll.x = FlxMath.lerp(cam.scroll.x, target.x - FlxG.width / 2, lerp);
		cam.scroll.y = FlxMath.lerp(cam.scroll.y, target.y - FlxG.height/ 2, lerp);
	}
	
	// NOTE STUFF
	inline public static function getDirection(i:Int)
		return ["left", "down", "up", "right"][i];
	
	inline public static function noteWidth()
		return (160 * 0.7); // 112
	
	public static function setNotePos(note:FlxSprite, target:FlxSprite, angle:Float, offsetX:Float, offsetY:Float, usesLerp:Bool = false)
	{
		var radAngle = FlxAngle.asRadians(angle);
		note.x = target.x
			+ (Math.cos(radAngle) * offsetX)
			+ (Math.sin(radAngle) * offsetY);
		note.y = target.y
			+ (Math.cos(radAngle) * offsetY)
			+ (Math.sin(radAngle) * offsetX);
	}
	
	public static function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.songTime, Obj2.songTime);

	// music management stuff
	public static var curMusic:String = "none";
	public static function playMusic(?key:String, ?forceRestart:Bool = false, ?vol:Float = 0.5)
	{
		if (Paths.dumpExclusions.contains('music/' + curMusic + '.ogg'))
			Paths.dumpExclusions.remove  ('music/' + curMusic + '.ogg');
		
		if(key == null)
		{
			curMusic = "none";
			FlxG.sound.music.stop();
		}
		else
		{
			Paths.dumpExclusions.push('music/' + key + '.ogg');

			if(curMusic != key || forceRestart)
			{
				curMusic = key;
				FlxG.sound.playMusic(Paths.music(key), vol);
				//FlxG.sound.music.loadEmbedded(Paths.music(key), true, false);
				FlxG.sound.music.play(true);
			}
		}
	}

	public static function stringToBool(str:String):Bool
	{
		str = str.toLowerCase();
		if(str == "true" || str == "1")
			return true;
		return false;
	}

	public static function stringToFloat(str:String, ?backup:Float = 0):Float
	{
		var num:Float = Std.parseFloat(str);
		if(!Std.isOfType(num, Float))
			num = backup;
		return num;
	}

	public static function stringToInt(str:String, ?backup:Int = 0):Int
	{
		var num:Int = Std.parseInt(str);
		if(!Std.isOfType(num, Int))
			num = backup;
		return num;
	}

	public static function stringToEase(str:String = 'linear'):EaseFunction
	{
		// linear/quad/cube/quart/quint/sine/circ/expo
		return switch(str.toLowerCase())
		{
			case 'quadin': FlxEase.quadIn;
			case 'quadinout': FlxEase.quadInOut;
			case 'quadout': FlxEase.quadOut;

			case 'cubein': FlxEase.cubeIn;
			case 'cubeinout': FlxEase.cubeInOut;
			case 'cubeout': FlxEase.cubeOut;
			
			case 'quartin': FlxEase.quartIn;
			case 'quartinout': FlxEase.quartInOut;
			case 'quartout': FlxEase.quartOut;

			case 'quintin': FlxEase.quintIn;
			case 'quintinout': FlxEase.quintInOut;
			case 'quintout': FlxEase.quintOut;

			case 'sinein': FlxEase.sineIn;
			case 'sineinout': FlxEase.sineInOut;
			case 'sineout': FlxEase.sineOut;

			case 'circin': FlxEase.circIn;
			case 'circinout': FlxEase.circInOut;
			case 'circout': FlxEase.circOut;

			case 'expoin': FlxEase.expoIn;
			case 'expoinout': FlxEase.expoInOut;
			case 'expoout': FlxEase.expoOut;

			default: FlxEase.linear;
		}
	}
	public static function stringToColor(str:String):Int
	{
		if(str.startsWith('#') || str.startsWith('0x'))
			return FlxColor.fromString(str);
		else
			return switch(str.toLowerCase())
			{
				case 'black': 	0xFF000000;
				case 'silver':  0xFFC0C0C0;
				case 'gray': 	0xFF808080;
				case 'red': 	0xFFFF0000;
				case 'purple':  0xFF800080;
				case 'pink': 	0xFFFF00FF;
				case 'green': 	0xFF008000;
				case 'lime': 	0xFF00FF00;
				case 'yellow':  0xFFFFFF00;
				case 'blue': 	0xFF0000FF;
				case 'aqua': 	0xFF00FFFF;
				default: 		0xFFFFFFFF;
			}
	}

	public static function openURL(url:String)
	{
		if(Main.activeState != null)
			Main.activeState.openSubState(new subStates.WebsiteSubState(url));
	}

	public static function playHitSound(?sound:String, ?volume:Float)
	{
		if(sound == null) sound = SaveData.data.get("Hitsounds");
		if(sound == "OFF") return;
		
		if(volume == null) volume = SaveData.data.get("Hitsound Volume") / 100;
		FlxG.sound.play(Paths.sound('hitsounds/${sound}'), volume);
	}

	// ONLY USE FORCED IF REALLY NEEDED
	public static function flash(?camera:FlxCamera, ?duration:Float = 0.5, ?color:FlxColor, ?forced:Bool = false)
	{
		if(camera == null)
			camera = FlxG.camera;
		if(color == null)
			color = 0xFFFFFFFF;
		
		if(!forced)
		{
			if(SaveData.data.get("Flashing Lights") == "OFF") return;

			if(SaveData.data.get("Flashing Lights") == "REDUCED")
				color.alphaFloat = 0.4;
		}
		camera.flash(color, duration, null, true);
	}
}