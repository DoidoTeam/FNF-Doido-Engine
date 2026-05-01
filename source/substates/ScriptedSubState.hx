package substates;

import hscript.iris.Iris;

using doido.utils.ScriptUtil;

class ScriptedSubState extends MusicBeatSubState
{
	public var script:String = "";
	public var loadedScript:Iris = null;

	public function new(script:String = "")
	{
		super();
		this.script = script;
		loadScript('data/scripts/substates/$script');
	}
}
