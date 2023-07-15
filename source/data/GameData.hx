package data;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIState;
import data.Conductor.BPMChangeEvent;

class MusicBeatState extends FlxUIState
{
	override function create()
	{
		super.create();
		trace('switched to ${Type.getClassName(Type.getClass(FlxG.state))}');

		if(!Main.skipClearMemory)
			Paths.clearMemory();
		
		if(!Main.skipTrans)
			openSubState(new GameTransition(true));

		// go back to default automatically i dont want to do it
		Main.skipStuff(false);
	}

	private var _curStep = 0; // fake curStep
	private var curStep = 0;
	private var curBeat = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateBeat();
	}

	private function updateBeat()
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for(change in Conductor.bpmChangeMap)
		{
			if (Conductor.songPos >= change.songTime)
				lastChange = change;
		}

		_curStep = lastChange.stepTime + Math.floor((Conductor.songPos - lastChange.songTime) / Conductor.stepCrochet);

		if(_curStep != curStep)
			stepHit();
	}

	private function stepHit()
	{
		if(_curStep > curStep)
			curStep++;
		else
		{
			curStep = _curStep;
		}

		if(curStep % 4 == 0)
			beatHit();

		for(item in members)
		{
			if (item._stepHit != null)
				item._stepHit(curStep);
		}
	}

	private function beatHit()
	{
		// finally you're useful for something
		curBeat = Math.floor(curStep / 4);
	}
}

class MusicBeatSubState extends FlxSubState
{
	override function create()
	{
		super.create();
	}
}