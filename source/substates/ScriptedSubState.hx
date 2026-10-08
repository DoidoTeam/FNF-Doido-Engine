package substates;

using doido.utils.ScriptUtil;

class ScriptedSubState extends MusicBeatSubState
{
	public var script:String = "";

	public function new(script:String = "")
	{
		super();
		this.script = script;
	}
}
