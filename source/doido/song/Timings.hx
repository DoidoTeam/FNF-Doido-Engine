package doido.song;

import flixel.math.FlxMath;

typedef TimingData = {
    var diff:Float; // milliseconds to hit this timing
    var judge:Float; // accuracy multiplier
};
class Timings
{
    public static var timings:Map<String, TimingData> = [
        "sick" => {
            diff: 45,
            judge: 1.0,
        },
        "good" => {
            diff: 90,
            judge: 0.75
        },
        "bad" => {
            diff: 135,
            judge: 0.25
        },
        "shit" => {
            diff: 160,
            judge: -1.0
        },
        "miss" => {
            diff: 180,
            judge: -1.75
        },
    ];

    public static var minTiming:Float = timings.get("miss").diff;

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

    public static function getTiming(name:String):TimingData
    {
        return timings.get(name);
    }

    public static function diffToTiming(noteDiff:Float):TimingData
	{
        var timing = timings.get("miss");
        for(key => data in timings)
        {
            if (data.diff > timing.diff) continue;
            if (noteDiff > data.diff) continue;
            timing = data;
        }
        return timing;
    }

    public static function addAccuracy(judge:Float = 1)
	{
		accHit++;
		accJudge += judge;
		updateAccuracy();
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
			result = "?";

		return result;
	}
}