package states;

class ScriptedState extends MusicBeatState
{
	public var script:String = "";

	public function new(script:String = "")
	{
		super();
		this.script = script;
	}

	override function resetState()
	{
		MusicBeat.skipTrans = true;
		MusicBeat.skipClearCache = (!FlxG.keys.pressed.SHIFT);
		MusicBeat.switchState(new ScriptedState(script));
	}
}
