package data;

import flixel.math.FlxMath;

class Timings
{
	public static var timingsMap:Map<String, Array<Float>> = [
		"sick"		=> [45, 	1],
		"good"		=> [90, 	0.75],
		"bad"		=> [135, 	0.25],
		"shit"		=> [158, 	-1.0],
		"miss"		=> [180, 	-1.75],
	];

	public static var minTiming:Float = timingsMap.get("miss")[0];

	public static var score:Int = 0;
	public static var misses:Int = 0;
	public static var combo:Int = 0;
	public static var accuracy:Float = 0;

	public static var notesHit:Int = 0;
	public static var notesJudge:Float = 0;

	public static function init()
	{
		score = 0;
		misses = 0;
		combo = 0;
		accuracy = 0;
		notesHit = 0;
		notesJudge = 0;
	}

	public static function addAccuracy(judge:Float = 1)
	{
		notesHit++;
		notesJudge += judge;
		updateAccuracy();
	}

	public static function diffToJudge(noteDiff:Float):Float
	{
		noteDiff = Math.abs(noteDiff);

		var daJudge:Float = timingsMap.get("miss")[1];

		for(key => data in timingsMap)
		{
			if(noteDiff < data[0] && daJudge < data[1])
				daJudge = data[1];
		}

		return daJudge;
	}

	public static function updateAccuracy()
	{
		var rawAccuracy:Float = (notesJudge / notesHit) * 100;

		accuracy = FlxMath.roundDecimal(rawAccuracy, 2);

		accuracy = FlxMath.bound(accuracy, 0, 100);
	}

	public static function getRank():String
	{
		var result:String = "F";

		function uuh(daRank:String, maxAcc:Float, minAcc:Float):String
		{
			var daR:String = result;
			if(accuracy > minAcc && accuracy <= maxAcc)
			{
				daR = daRank;
			}
			return daR;
		}

		result = uuh("S", 100, 	95);
		result = uuh("A", 95, 	80);
		result = uuh("B", 80, 	75);
		result = uuh("C", 75, 	65);
		result = uuh("D", 65, 	60);

		if(notesHit == 0)
			result = "N/A";

		return result;
	}
}