package;

import flixel.FlxG;
import flixel.util.FlxSort;
import gameObjects.hud.note.Note;

class CoolUtil
{
	public static function getDirection(i:Int)
		return ["left", "down", "up", "right"][i];

	public static function noteWidth()
	{
		return (160 * 0.7); // 112
	}
	
	public static function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.songTime, Obj2.songTime);

	// easier music management stuff
	public static var curMusic:String = "none";
	public static function playMusic(?key:String, ?vol:Float = 1)
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

			if(curMusic != key)
			{
				curMusic = key;
				FlxG.sound.playMusic(Paths.music(key), vol);
				//FlxG.sound.music.loadEmbedded(Paths.music(key), true, false);
				FlxG.sound.music.play(true);
			}
		}
	}
}