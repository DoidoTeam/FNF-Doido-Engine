package states;

import hscript.iris.Iris;

using doido.utils.ScriptUtil;

class ScriptedState extends MusicBeatState
{
	public var script:String = "";
	public var loadedScript:Iris = null;

	public function new(script:String = "")
	{
		super();
		this.script = script;
		loadScript('data/scripts/states/$script');
	}

	override function resetState()
	{
		MusicBeat.skipTrans = true;
		MusicBeat.skipClearCache = (!FlxG.keys.pressed.SHIFT);
		MusicBeat.switchState(new ScriptedState(script));
	}
}
