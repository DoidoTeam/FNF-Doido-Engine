package doido.song;

import objects.ui.notes.Note;
import flixel.math.FlxMath;

typedef TimingData = {
	var name:String; // timing name
    var diff:Float; // milliseconds to hit this timing
	var hold:Float; // 
    var judge:Float; // accuracy multiplier
};
class Timings
{
    public static var timings:Map<String, TimingData> = [
        "sick" => {
			name: "sick",
            diff: 45,
			hold: 0.85,
            judge: 1.0,
        },
        "good" => {
			name: "good",
            diff: 90,
			hold: 0.6,
            judge: 0.75,
        },
        "bad" => {
			name: "bad",
            diff: 135,
			hold: 0.35, 
            judge: 0.25,
        },
        "shit" => {
			name: "shit",
            diff: 160,
			hold: 0.2,
            judge: -1.0,
        },
        "miss" => {
			name: "miss",
            diff: 180,
			hold: 0.0,
            judge: -1.75,
        },
    ];

    public static var minTiming:Float = timings.get("shit").diff;

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
		if (noteDiff < timing.diff)
		{
			for(key => data in timings)
			{
				if (data.diff > timing.diff) continue;
				if (noteDiff > data.diff) continue;
				timing = data;
			}
		}
        return timing;
    }

	public static function holdToTiming(noteHold:Float)
	{
		var timing = timings.get("miss");
		if (noteHold > timing.hold)
		{
			for(key => data in timings)
			{
				if (data.hold < timing.hold) continue;
				if (noteHold < data.hold) continue;
				timing = data;
			}
		}
        return timing;
	}

	public static function addScore(note:Note, noteDiff:Float)
	{
		var timing = diffToTiming(noteDiff);
		if (timing.name != "miss")
			ratingCount.set(timing.name, ratingCount.get(timing.name) + 1);

		if (note.missed)
		{
			if (combo > 0)
				combo = 0;
			else
				combo--;
			score += Math.ceil(100 * timing.judge);
			misses++;
		}
		else
		{
			if (combo < 0) combo = 0;
			combo++;

			if (noteDiff <= 5)
				score += 100;
			else
				score += Math.ceil(
					FlxMath.remapToRange(
						noteDiff,
						5, getTiming("good").diff,
						100, 50
					)
				);
		}
	}

	public static function addScoreHold(hold:Note)
	{
		var timing = holdToTiming(hold.holdHitPercent);
		if (timing.name != "miss")
			ratingCount.set(timing.name, ratingCount.get(timing.name) + 1);
		
		if (hold.missed)
			score -= 50;
		else
			score += Math.ceil(50 * hold.data.length * hold.holdHitPercent);
	}

    public static function addAccuracy(judge:Float)
	{
		accHit++;
		accJudge += judge;
		updateAccuracy();
	}

	public static function addAccuracyDiff(noteDiff:Float):String
	{
		var timing = diffToTiming(noteDiff);
		addAccuracy(
			timing.judge
		);
		return timing.name;
	}

	public static function addAccuracyHold(noteHold:Float):String
	{
		var timing = holdToTiming(noteHold);
		addAccuracy(
			timing.judge
		);
		return timing.name;
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