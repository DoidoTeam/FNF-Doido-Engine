package backend.game;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIState;
import flixel.group.FlxGroup;
import backend.song.Conductor;
import backend.assets.Cache;
import backend.game.Transition;

class MusicBeat
{
	public static var activeState:FlxState;
	public static var nextTransition:String = '';

	public static function switchState(?target:MusicBeatState, tOut:String = 'funkin', ?tIn:String)
	{
		if(tIn != null)
			nextTransition = tIn;
		else
			nextTransition = tOut;

		var trans = new Transition(false, tOut);
		trans.finishCallback = function()
		{
			if(target != null)		
				FlxG.switchState(() -> target);
			else
				FlxG.resetState();
		};

		if(skipTrans)
			return trans.finishCallback();
		
		if(activeState != null)
			activeState.openSubState(trans);
	}
	
	public static function resetState()
	{
		switchState(null);
	}

	public static var skipClearCache:Bool = false;
	public static var skipTrans:Bool = true;
	public static var skip(get, set):Bool;

	public static function get_skip()
		return skipTrans && skipClearCache;

	public static function set_skip(newSkip:Bool) {
		skipTrans = newSkip;
		skipClearCache = newSkip;
		return newSkip;
	}
}

/*
	Custom state and substate classes. Use them instead of FlxState or FlxSubstate
*/
class MusicBeatState extends FlxUIState
{
	override function create()
	{
		super.create();
		MusicBeat.activeState = this;
		Logs.print('switched to ${Type.getClassName(Type.getClass(this))}');
		persistentDraw = true;
		persistentUpdate = false;
		
		Controls.setSoundKeys();

		if(!MusicBeat.skipClearCache)
			Cache.clearCache();

		if(!MusicBeat.skipTrans)
			openSubState(new Transition(true, MusicBeat.nextTransition));

		MusicBeat.skip = false;

		curStepFloat = Conductor.calcStateStep();
		curStep = _curStep = Math.floor(curStepFloat);
	}

	private var _curStep = 0; // actual curStep
	public var curStep = 0;
	public var curStepFloat:Float = 0;
	//private var curBeat = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateStep();
		
		if(FlxG.keys.justPressed.F5) {
			MusicBeat.skip = (!FlxG.keys.pressed.SHIFT);
			MusicBeat.resetState();
		}
	}

	private function updateStep()
	{
		curStepFloat = Conductor.calcStateStep();
		_curStep = Math.floor(curStepFloat);

		while(_curStep != curStep)
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

		function loopGroup(group:FlxGroup):Void
		{
			if(group == null) return;
			for(item in group.members)
			{
				if(item == null) continue;
				if(Std.isOfType(item, FlxGroup))
					loopGroup(cast item);
	
				/*if(item._stepHit != null)
					item._stepHit(curStep);*/
			}
		}
		loopGroup(this);
	}

	private function beatHit()
	{
		// finally you're useful for something
		//curBeat = Math.floor(curStep / 4);
	}
}

class MusicBeatSubState extends FlxSubState
{
	var subParent:FlxState;

	override function create()
	{
		super.create();
		subParent = MusicBeat.activeState;
		MusicBeat.activeState = this;
		persistentDraw = true;
		persistentUpdate = false;
		curStepFloat = Conductor.calcStateStep();
		curStep = _curStep = Math.floor(curStepFloat);
	}
	
	override function close()
	{
		MusicBeat.activeState = subParent;
		super.close();
	}

	private var _curStep:Int = 0; // actual curStep
	public var curStep:Int = 0;
	public var curStepFloat:Float = 0;
	//private var curBeat:Int = 0;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateStep();
	}

	private function updateStep()
	{
		curStepFloat = Conductor.calcStateStep();
		_curStep = Math.floor(curStepFloat);

		while(_curStep != curStep)
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

		function loopGroup(group:FlxGroup):Void
		{
			if(group == null) return;
			for(item in group.members)
			{
				if(item == null) continue;
				if(Std.isOfType(item, FlxGroup))
					loopGroup(cast item);
	
				/*if (item._stepHit != null)
					item._stepHit(curStep);*/
			}
		}
		loopGroup(this);
	}

	private function beatHit()
	{
		// finally you're useful for something
		//curBeat = Math.floor(curStep / 4);
	}
}

