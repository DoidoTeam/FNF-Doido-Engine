package backend.song;

import flixel.math.FlxMath;

class Timings
{
	public static var timingsArray:Array<Array<Dynamic>> = [
		["sick",	45,		1],
		["good",	90,		0.75],
		["bad",		135,	0.25],
		["shit",	160,	-1.0],
		["miss",	180,	-1.75],
	];
	public static var holdTimings:Array<Dynamic> = [
		[0.85, timingsArray[0][1]], // sick
		[0.60, timingsArray[1][1]], // good
		[0.35, timingsArray[2][1]], // bad
		[0.20, timingsArray[3][1]], // shit
	];
	
	public static var minTiming:Float = getTimings("miss")[1];

	// score and accuracy
	public static var score:Int = 0;
	public static var accuracy:Float = 0;
	// accuracy calculation
	public static var accHit:Int = 0;
	public static var accJudge:Float = 0;
	// note stuff
	public static var combo:Int = 0;
	public static var notesHit:Int = 0;
	public static var misses:Int = 0;
	// ratings
	public static var ratingCount:Map<String, Int> = [];

	public static function init()
	{
		score = 0;
		accuracy = 0;
		accHit = 0;
		accJudge = 0;
		combo = 0;
		notesHit = 0;
		misses = 0;
		ratingCount = [
			"sick" 	=> 0,
			"good" 	=> 0,
			"bad"	=> 0,
			"shit"	=> 0,
		];
	}

	public static function addAccuracy(judge:Float = 1)
	{
		accHit++;
		accJudge += judge;
		updateAccuracy();
	}

	public static function diffToRating(noteDiff:Float):String
		return noteDiffToList(noteDiff)[0];

	public static function diffToJudge(noteDiff:Float):Float
		return noteDiffToList(noteDiff)[2];
	
	public static function noteDiffToList(noteDiff:Float):Array<Dynamic>
	{		
		var daList:Array<Dynamic> = timingsArray[timingsArray.length - 1];
		
		for(i in timingsArray)
		{
			if(Math.abs(noteDiff) <= i[1])
			{
				daList = i;
				break;
			}
		}
		
		return daList;
	}
	
	public static function getTimings(rating:String = "sick"):Array<Dynamic>
	{
		var daList:Array<Dynamic> = timingsArray[0];
		
		for(i in timingsArray)
		{
			if(i[0] == rating)
				daList = i;
		}
		
		return daList;
	}

	public static function updateAccuracy()
	{
		var rawAccuracy:Float = (accJudge / accHit) * 100;

		accuracy = FlxMath.roundDecimal(rawAccuracy, 2);

		accuracy = FlxMath.bound(accuracy, 0, 100);
	}

	public static function getRank(?accuracy:Float, ?misses:Int, inGame:Bool = true, hasPlus:Bool = true):String
	{
		if(misses == null)
			misses = Timings.misses;

		if(accuracy == null)
			accuracy = Timings.accuracy;

		var result:String = "F";
		function calc(daRank:String, maxAcc:Float, minAcc:Float)
		{
			if(accuracy > minAcc && accuracy <= maxAcc)
				result = daRank;
		}

		// main ranks
		calc("D", 65, 60);
		calc("C", 75, 65);
		calc("B", 80, 75);
		calc("A", 95, 80);
		calc("S", 100,95);

		// pluses for your rank
		if(misses == 0) {
			if(hasPlus)
				result += "+";
			if(accuracy == 100.0)
				result = "P";
		}
		
		// you cant give a result without notes :/
		if(inGame ? (accHit <= 0) : (accuracy == 0 && misses == 0))
			result = "N/A";

		return result;
	}
}