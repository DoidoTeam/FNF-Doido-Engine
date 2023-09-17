package data;

import flixel.FlxG;
import data.SongData.SwagSong;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}
class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = calcBeat(bpm);
	public static var stepCrochet:Float = calcStep(bpm);

	public static var songPos:Float = 0;

	public static function setBPM(bpm:Float = 100)
	{
		Conductor.bpm = bpm;
		crochet = calcBeat(bpm);
		stepCrochet = calcStep(bpm);
	}

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static function mapBPMChanges(?song:SwagSong)
	{
		bpmChangeMap = [];

		if(song == null) return;

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += calcStep(curBPM) * deltaSteps;
		}
		//trace("new BPM map BUDDY " + bpmChangeMap);
	}

	public static function calcBeat(bpm:Float):Float
		return ((60 / bpm) * 1000);

	public static function calcStep(bpm:Float):Float
		return calcBeat(bpm) / 4;
	
	public static function calcStateStep():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for(change in bpmChangeMap)
		{
			if (songPos >= change.songTime)
				lastChange = change;
		}

		return lastChange.stepTime + Math.floor((songPos - lastChange.songTime) / stepCrochet);
	}
}