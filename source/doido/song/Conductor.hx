package doido.song;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxEase.EaseFunction;

typedef BPMChangeEvent =
{
	var stepTime:Float; // step where event starts
	var songTime:Float; // calculated millisecond time
	var startBPM:Float; // bpm at the start of event
	var targetBPM:Float; // target bpm to change
	var length:Float; // lenght in steps
	var ease:EaseFunction; // bpm change easing

	// signature
	var beatSteps:Int;
	var beatTime:Float;
	var sectionBeats:Float;
	var sectionTime:Float;
}

typedef Timeline =
{
	var step:Float;
	var beat:Float;
	var section:Float;
}

class Conductor
{
	public static var songPos:Float = 0;
	public static var musicOffset:Float = 0;
	public static var inputOffset:Float = 0;

	public static var initialBPM:Float = 100;
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static var bpm(get, never):Float;

	public static function get_bpm():Float
		return getBPMAtTime(songPos);

	public static var stepCrochet(get, never):Float;

	public static function get_stepCrochet():Float
		return calcStep(bpm, getBeatSteps());

	public static var crochet(get, never):Float;

	public static function get_crochet():Float
		return calcBeat(bpm);

	inline public static function calcBeat(bpm:Float):Float
		return (60 / bpm) * 1000;

	inline public static function calcStep(bpm:Float, beatSteps:Float = 4):Float
		return calcBeat(bpm) / beatSteps;

	public static var conductorEvents:Array<String> = ["BPM Change", "Linear BPM Change", "Time Signature Change"];

	public static function mapBPMChanges(?events:Array<Dynamic>)
	{
		bpmChangeMap = [];
		if (events == null)
			return;

		var curBPM:Float = initialBPM;
		var curSecBeats:Float = 4;
		var curBeatSteps:Int = 4;
		for (event in events)
		{
			if (!conductorEvents.contains(event.name))
				continue;

			var newChange:BPMChangeEvent = {
				stepTime: event.stepTime,
				songTime: 0,
				startBPM: 0,
				targetBPM: curBPM,
				length: 0,
				ease: FlxEase.linear,
				sectionBeats: curSecBeats,
				beatSteps: curBeatSteps,
				sectionTime: 0,
				beatTime: 0
			};

			switch (event.name)
			{
				case "BPM Change":
					newChange.targetBPM = event.data[0];
				case "Linear BPM Change":
					newChange.targetBPM = event.data[0];
					newChange.length = event.data[1];
				// ease
				case "Time Signature Change":
					curSecBeats = event.data[0];
					curBeatSteps = Math.floor(16 / event.data[1]);
					newChange.sectionBeats = curSecBeats;
					newChange.beatSteps = curBeatSteps;
			}

			curBPM = newChange.targetBPM;
			bpmChangeMap.push(newChange);
		}

		// no bpm changes? no pass
		if (bpmChangeMap.length <= 0)
			return;

		// BAKING THE EVENTS
		bpmChangeMap.sort((Obj1, Obj2) -> Std.int(Obj1.stepTime - Obj2.stepTime));

		var curTime:Float = 0;
		var curStep:Float = 0;
		var curBeat:Float = 0;
		var curSection:Float = 0;
		curBPM = initialBPM;
		curSecBeats = 4;
		curBeatSteps = 4;

		for (event in bpmChangeMap)
		{
			var stepDiff = event.stepTime - curStep;

			curTime += stepDiff * calcStep(curBPM, curBeatSteps);
			curBeat += stepDiff / curBeatSteps;
			curSection += stepDiff / (curBeatSteps * curSecBeats);

			event.songTime = curTime;
			event.startBPM = curBPM;
			event.beatTime = curBeat;
			event.sectionTime = curSection;

			// linear bpm change -- NOT WORKING!
			if (event.length > 0)
			{
				var avgBPM = (curBPM + event.targetBPM) / 2;
				var rampTime = event.length * calcStep(avgBPM, curBeatSteps);

				curTime += rampTime;
				curStep += event.length;
				curBPM = event.targetBPM;
			}
			else // regular bpm change
				curBPM = event.targetBPM;

			curStep = event.stepTime;
			curSecBeats = event.sectionBeats;
			curBeatSteps = event.beatSteps;
		}

		// trace(bpmChangeMap);
	}

	public static function getTimelineAtTime(?time:Float):Timeline
	{
		time = time ?? songPos;

		var change = getLatestChange(time);
		if (change == null)
		{
			var step = time / calcStep(initialBPM, 4);
			return {
				step: step,
				beat: step / 4,
				section: (step / (4 * 4))
			}
		}
		else
		{
			var elapsedSteps = (time - change.songTime) / (calcStep(change.targetBPM, change.beatSteps));
			return {
				step: change.stepTime + elapsedSteps,
				beat: change.beatTime + (elapsedSteps / change.beatSteps),
				section: change.sectionTime + (elapsedSteps / (change.beatSteps * change.sectionBeats))
			}
		}
	}

	public static function getStepAtTime(?time:Float):Float
		return getTimelineAtTime(time).step;

	public static function getBeatAtTime(?time:Float):Float
		return getTimelineAtTime(time).beat;

	public static function getSectionAtTime(?time:Float):Float
		return getTimelineAtTime(time).section;

	//rewrite later
	public static function getTimeAtStep(step:Float):Float
	{
		var totalTime:Float = 0;
		var lastStep:Float = 0;
		var curBeatSteps:Int = 4;

		if (bpmChangeMap.length > 0)
		{
			for (event in bpmChangeMap)
			{
				if (step < event.stepTime)
					break;

				totalTime += (event.stepTime - lastStep) * calcStep(getBPMAtTime(totalTime), curBeatSteps);
				lastStep = event.stepTime;
				curBeatSteps = event.beatSteps;

				if (event.length > 0)
				{
					if (step <= event.stepTime + event.length)
					{
						var percent = FlxMath.bound((step - event.stepTime) / event.length, 0, 1);

						var curBPM = FlxMath.lerp(event.startBPM, event.targetBPM, event.ease(percent));

						totalTime += (step - lastStep) * calcStep(curBPM, curBeatSteps);
						return totalTime;
					}
					else
					{
						var rampDuration = getEventRampDuration(event);

						totalTime += rampDuration;
						lastStep += event.length;
					}
				}
			}
		}

		totalTime += (step - lastStep) * calcStep(getBPMAtTime(totalTime), curBeatSteps);

		return totalTime;
	}

	public static function getBPMAtTime(?time:Float):Float
	{
		time = time ?? songPos;
		var curBPM:Float = initialBPM;

		// you only gotta change the bpm if theres bpm change events duhh
		if (bpmChangeMap.length > 0)
		{
			for (event in bpmChangeMap)
			{
				if (time < event.songTime)
					break;

				// linear bpm change
				if (event.length > 0)
				{
					var rampDuration = getEventRampDuration(event);
					if (time <= event.songTime + rampDuration)
					{
						var percent = FlxMath.bound((time - event.songTime) / rampDuration, 0, 1);

						return FlxMath.lerp(event.startBPM, event.targetBPM, event.ease(percent));
					}
					else
						curBPM = event.targetBPM;
				}
				else // regular bpm change
					curBPM = event.targetBPM;
			}
		}

		return curBPM;
	}

	// note: in SECONDS
	public static function getStepDuration(step:Float, length:Float)
		return (getTimeAtStep(step + length) - getTimeAtStep(step)) / 1000;

	static function getEventRampDuration(event:BPMChangeEvent):Float
	{
		var avgBPM = (event.startBPM + event.targetBPM) / 2;
		return event.length * calcStep(avgBPM, getBeatSteps());
	}

	public static function getSectionBeats():Float
	{
		var change = getLatestChange();
		return change == null ? 4 : change.sectionBeats;
	}

	public static function getBeatSteps():Int
	{
		var change = getLatestChange();
		return change == null ? 4 : change.beatSteps;
	}

	public static function getLatestChange(?time:Float):BPMChangeEvent
	{
		time = time ?? songPos;
		var i = bpmChangeMap.length - 1;
		while (i >= 0)
		{
			var change = bpmChangeMap[i];
			if (time >= change.songTime)
				return change;
			i--;
		}
		return null;
	}
}
