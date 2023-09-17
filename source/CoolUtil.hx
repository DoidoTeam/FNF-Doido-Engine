package;

import flixel.FlxG;
import flixel.util.FlxSort;
import flixel.math.FlxMath;
import gameObjects.hud.note.Note;

using StringTools;

class CoolUtil
{
	// general things
	inline public static function formatChar(char:String):String
	{
		return char.substring(0, char.lastIndexOf('-'));
	}
	
	public static function getDiffs(?week:String):Array<String>
	{
		return switch(week)
		{
			default: ["easy", "normal", "hard"];
		}
	}

	public static function charList():Array<String>
	{
		return [
			"dad",
			"gf",
			"bf",
			"bf-pixel",
			"bf-pixel-dead",
			"gf-pixel",
			"senpai",
			"senpai-angry",
			"spirit",
			"gemamugen",
		];
	}

	public static function coolTextFile(key:String):Array<String>
	{
		var daList:Array<String> = Paths.text(key).split('\n');

		for(i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}
	
	public static function posToTimer(mil:Float = 0, ?divisor:String = ":"):String
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
		
		return '$disMin$divisor$disSec';
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
	public static function getDirection(i:Int)
		return ["left", "down", "up", "right"][i];
	
	public static function noteWidth()
	{
		return (160 * 0.7); // 112
	}
	
	public static function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.songTime, Obj2.songTime);

	// music management stuff
	public static var curMusic:String = "none";
	public static function playMusic(?key:String, ?force:Bool = false, ?vol:Float = 1)
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

			if(curMusic != key || force)
			{
				curMusic = key;
				FlxG.sound.playMusic(Paths.music(key), vol);
				//FlxG.sound.music.loadEmbedded(Paths.music(key), true, false);
				FlxG.sound.music.play(true);
			}
		}
	}
}