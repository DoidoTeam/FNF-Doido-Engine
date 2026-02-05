package backend.game;

import flixel.FlxCamera;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIState;
import flixel.group.FlxGroup;
import backend.song.Conductor;
import crowplexus.iris.Iris;
import backend.assets.Cache;

/*#if TOUCH_CONTROLS
import objects.mobile.*;
import flixel.FlxSubState;
#end*/

class MusicBeat
{
	public static var activeState:FlxState;
	
	public static function switchState(?newState:MusicBeatState)
	{
		FlxG.switchState(() -> newState);
	}
	
	public static function resetState()
	{
		switchState(null);
	}
}

/*
	Custom state and substate classes. Use them instead of FlxState or FlxSubstate
*/
class MusicBeatState extends FlxUIState
{
	/*#if TOUCH_CONTROLS
	public var pad:DoidoPad;
	#end*/

	override function create()
	{
		super.create();
		MusicBeat.activeState = this;
		Logs.print('switched to ${Type.getClassName(Type.getClass(this))}');
		persistentDraw = true;
		persistentUpdate = false;
		
		//Controls.setSoundKeys();
		Cache.clearCache();
		
		/*if(!Main.skipTrans)
			openSubState(new GameTransition(true, Main.lastTransition));*/

		Iris.destroyAll();

		// go back to default automatically i dont want to do it
		//Main.skipStuff(false);
		
		curStepFloat = Conductor.calcStateStep();
		curStep = _curStep = Math.floor(curStepFloat);
		//curBeat = Math.floor(curStep / 4);

		/*#if TOUCH_CONTROLS
		createPad("blank");
		Controls.resetTimer();
		#end*/
	}

	private var _curStep = 0; // actual curStep
	private var curStep = 0;
	private var curStepFloat:Float = 0;
	//private var curBeat = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateStep();
		
		#if debug
		/*if(FlxG.keys.justPressed.F5) {
			Main.skipClearMemory = (!FlxG.keys.pressed.SHIFT);
			Main.skipTrans = true;
			Main.resetState();
		}*/
		#end
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

	/*#if TOUCH_CONTROLS
	function createPad(mode:String = "blank", ?cameras:Array<FlxCamera>)
	{
		remove(pad);
		pad = new DoidoPad(mode);

		if(mode != "blank") {
			if(cameras != null)
				pad.cameras = cameras;

			add(pad);
		}
	}

	override function openSubState(SubState:FlxSubState) {
		if(!(SubState is GameTransition))
			pad.togglePad(false);
		super.openSubState(SubState);
	}

	override function closeSubState() {
		pad.togglePad(true);
		super.closeSubState();
	}
	#end*/
}

class MusicBeatSubState extends FlxSubState
{
	var subParent:FlxState;

	/*#if TOUCH_CONTROLS
	public var pad:DoidoPad = new DoidoPad();
	#end*/

	override function create()
	{
		super.create();
		subParent = MusicBeat.activeState;
		MusicBeat.activeState = this;
		persistentDraw = true;
		persistentUpdate = false;
		
		curStepFloat = Conductor.calcStateStep();
		curStep = _curStep = Math.floor(curStepFloat);
		//curBeat = Math.floor(curStep / 4);

		/*#if TOUCH_CONTROLS
		Controls.resetTimer();
		#end*/
	}
	
	override function close()
	{
		/*#if TOUCH_CONTROLS
		Controls.resetTimer();
		#end*/
		
		MusicBeat.activeState = subParent;
		super.close();
	}

	private var _curStep:Int = 0; // actual curStep
	private var curStep:Int = 0;
	private var curStepFloat:Float = 0;
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

	/*#if TOUCH_CONTROLS
	function createPad(mode:String = "blank", ?cameras:Array<FlxCamera>)
	{
		remove(pad);
		pad = new DoidoPad(mode);

		if(mode != "blank") {
			if(cameras != null)
				pad.cameras = cameras;

			add(pad);
		}
	}
	#end*/
}

