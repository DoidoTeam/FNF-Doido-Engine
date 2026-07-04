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
		return calcStep(bpm);

	public static var crochet(get, never):Float;

	public static function get_crochet():Float
		return calcBeat(bpm);

	inline public static function calcBeat(bpm:Float):Float
		return (60 / bpm) * 1000;

	inline public static function calcStep(bpm:Float):Float
		return calcBeat(bpm) / 4;

	public static function mapBPMChanges(?events:Array<Dynamic>)
	{
		bpmChangeMap = [];
		if (events == null)
			return;

		for (event in events)
		{
			if (event.name == "BPM Change")
			{
				bpmChangeMap.push({
					stepTime: event.stepTime,
					songTime: 0,
					startBPM: 0,
					targetBPM: event.data[0],
					length: 0,
					ease: FlxEase.linear
				});
			}

			if (event.name == "Linear BPM Change")
			{
				var easeFunc:EaseFunction = FlxEase.linear;

				if (event.data.length > 2)
				{
					if (event.data[2] != "")
						easeFunc = Reflect.field(FlxEase, event.data[2]);
				}

				bpmChangeMap.push({
					stepTime: event.stepTime,
					songTime: 0,
					startBPM: 0,
					targetBPM: event.data[0],
					length: event.data[1],
					ease: easeFunc
				});
			}
		}

		// no bpm changes? no pass
		if (bpmChangeMap.length < 0)
			return;

		// BAKING THE EVENTS
		bpmChangeMap.sort((Obj1, Obj2) -> Std.int(Obj1.stepTime - Obj2.stepTime));

		var curBPM:Float = initialBPM;
		var curStep:Float = 0;
		var curTime:Float = 0;

		for (event in bpmChangeMap)
		{
			var stepDiff = event.stepTime - curStep;

			curTime += stepDiff * calcStep(curBPM);

			event.songTime = curTime;
			event.startBPM = curBPM;

			// linear bpm change
			if (event.length > 0)
			{
				var avgBPM = (curBPM + event.targetBPM) / 2;
				var rampTime = event.length * calcStep(avgBPM);

				curTime += rampTime;
				curStep += event.length;
				curBPM = event.targetBPM;
			}
			else // regular bpm change
				curBPM = event.targetBPM;

			curStep = event.stepTime;
		}
	}

	public static function getBPMAtTime(?time:Float):Float
	{
		if (time == null)
			time = songPos;
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

	public static function getStepAtTime(?time:Float):Float
	{
		if (time == null)
			time = songPos;

		var totalSteps:Float = 0;
		var lastTime:Float = 0;

		if (bpmChangeMap.length > 0)
		{
			for (event in bpmChangeMap)
			{
				if (time < event.songTime)
					break;

				totalSteps += (event.songTime - lastTime) / calcStep(getBPMAtTime(lastTime));
				lastTime = event.songTime;

				// linear bpm change
				if (event.length > 0)
				{
					var rampDuration = getEventRampDuration(event);

					if (time <= event.songTime + rampDuration)
					{
						var percent = FlxMath.bound((time - event.songTime) / rampDuration, 0, 1);

						var curBPM = FlxMath.lerp(event.startBPM, event.targetBPM, event.ease(percent));

						totalSteps += (time - lastTime) / calcStep(curBPM);
						return totalSteps;
					}
					else
					{
						totalSteps += event.length;
						lastTime += rampDuration;
					}
				}
			}
		}

		totalSteps += (time - lastTime) / calcStep(getBPMAtTime(time));

		return totalSteps;
	}

	public static function getTimeAtStep(step:Float):Float
	{
		var totalTime:Float = 0;
		var lastStep:Float = 0;

		if (bpmChangeMap.length > 0)
		{
			for (event in bpmChangeMap)
			{
				if (step < event.stepTime)
					break;

				totalTime += (event.stepTime - lastStep) * calcStep(getBPMAtTime(totalTime));
				lastStep = event.stepTime;

				if (event.length > 0)
				{
					if (step <= event.stepTime + event.length)
					{
						var percent = FlxMath.bound((step - event.stepTime) / event.length, 0, 1);

						var curBPM = FlxMath.lerp(event.startBPM, event.targetBPM, event.ease(percent));

						totalTime += (step - lastStep) * calcStep(curBPM);
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

		totalTime += (step - lastStep) * calcStep(getBPMAtTime(totalTime));

		return totalTime;
	}

	public static function getBeatAtTime(?time:Float):Float
	{
		if (time == null)
			time = songPos;
		return getStepAtTime(time) / 4;
	}

	//note: in SECONDS
	public static function getStepDuration(step:Float, length:Float)
		return (getTimeAtStep(step + length) - getTimeAtStep(step)) / 1000;

	static function getEventRampDuration(event:BPMChangeEvent):Float
	{
		var avgBPM = (event.startBPM + event.targetBPM) / 2;
		return event.length * calcStep(avgBPM);
	}
}
