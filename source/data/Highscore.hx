package data;

import flixel.FlxG;
import flixel.math.FlxMath;

typedef ScoreData = {
	var score:Float;
	var accuracy:Float;
	var misses:Float;
}
class Highscore
{
	public static var highscoreMap:Map<String, ScoreData> = [];

	public static function addScore(song:String, newScore:ScoreData)
	{
		var oldScore:ScoreData = getScore(song);

		if(newScore.score >= oldScore.score)
			highscoreMap.set(song, newScore);
		
		save();
	}

	public static function getScore(song:String):ScoreData
	{
		if(!highscoreMap.exists(song))
			return {score: 0, accuracy: 0, misses: 0};
		else
			return highscoreMap.get(song);
	}
	
	public static function save()
	{
		FlxG.save.data.highscoreMap = highscoreMap;
		SaveData.save();
	}

	public static function load()
	{
		if(FlxG.save.data.highscoreMap == null)
			FlxG.save.data.highscoreMap = highscoreMap;

		highscoreMap = FlxG.save.data.highscoreMap;

		save();
	}
}