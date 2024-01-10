package data;

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
		var rawAccuracy:Float = (notesJudge / notesHit) * 100;

		accuracy = FlxMath.roundDecimal(rawAccuracy, 2);

		accuracy = FlxMath.bound(accuracy, 0, 100);
	}

	public static function getRank():String
	{
		var result:String = "F";
		function calc(daRank:String, maxAcc:Float, minAcc:Float)
		{
			if(accuracy > minAcc && accuracy <= maxAcc)
				result = daRank;
		}
		
		// main ranks
		calc("S", 100,	95);
		calc("A", 95, 	80);
		calc("B", 80, 	75);
		calc("C", 75, 	65);
		calc("D", 65, 	60);
		
		// pluses for your rank
		var extraPlus:Array<Bool> = [
			(misses == 0),
			(accuracy == 100.0),
		];
		for(i in extraPlus)
			if(i) result += '+';
		
		// you cant give a result without notes :/
		if(notesHit <= 0)
			result = "N/A";

		return result;
	}
}