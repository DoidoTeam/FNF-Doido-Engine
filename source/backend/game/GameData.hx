package backend.game;

import flixel.FlxBasic;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUISubState;
import flixel.group.FlxGroup;
import backend.song.Conductor;
import crowplexus.iris.Iris;

class MusicBeatState extends FlxUIState
{
	override function create()
	{
		super.create();
		Main.activeState = this;
		Logs.print('switched to ${Type.getClassName(Type.getClass(this))}');
		persistentDraw = true;
		persistentUpdate = false;
		
		Controls.setSoundKeys();

		if(!Main.skipClearMemory)
			Paths.clearMemory();
		
		if(!Main.skipTrans)
			openSubState(new GameTransition(true, Main.lastTransition));

		Iris.destroyAll();

		// go back to default automatically i dont want to do it
		Main.skipStuff(false);
		curStep = _curStep = Conductor.calcStateStep();
		curBeat = Math.floor(curStep / 4);
	}

	private var _curStep = 0; // actual curStep
	private var curStep = 0;
	private var curBeat = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateBeat();

		if(FlxG.keys.justPressed.F5) {
			Main.skipStuff();
			Main.resetState();
		}
	}

	private function updateBeat()
	{
		_curStep = Conductor.calcStateStep();

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
	
				if(item._stepHit != null)
					item._stepHit(curStep);
			}
		}
		loopGroup(this);
	}

	private function beatHit()
	{
		// finally you're useful for something
		curBeat = Math.floor(curStep / 4);
	}
}

class MusicBeatSubState extends FlxUISubState
{
	var subParent:FlxState;

	override function create()
	{
		super.create();
		subParent = Main.activeState;
		Main.activeState = this;
		persistentDraw = true;
		persistentUpdate = false;
		curStep = _curStep = Conductor.calcStateStep();
		curBeat = Math.floor(curStep / 4);
	}
	
	override function close()
	{
		Main.activeState = subParent;
		super.close();
	}

	private var _curStep = 0; // actual curStep
	private var curStep = 0;
	private var curBeat = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateBeat();
	}

	private function updateBeat()
	{
		_curStep = Conductor.calcStateStep();

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
	
				if (item._stepHit != null)
					item._stepHit(curStep);
			}
		}
		loopGroup(this);
	}

	private function beatHit()
	{
		// finally you're useful for something
		curBeat = Math.floor(curStep / 4);
	}
}

