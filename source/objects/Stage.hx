package objects;

import flixel.FlxObject;
import flixel.FlxBasic;
import states.PlayState;
import flixel.FlxSprite;
import hscript.iris.Iris;
import doido.utils.MathUtil;

using doido.utils.ScriptUtil;

class Stage
{
	public var playState:PlayState;

	final lowQuality:Bool;

	public function new(playState:PlayState)
	{
		this.playState = playState;
		lowQuality = Save.data.lowQuality;
	}

	public var curStage:String = "";
	public var stageItems:Array<FlxObject> = [];

	public var camZoom:Float = 0.9;
	public var gfVersion:String = "";

	public var bfCam:DoidoPoint;
	public var dadCam:DoidoPoint;
	public var gfCam:DoidoPoint;

	public var bfPos:DoidoPoint;
	public var dadPos:DoidoPoint;
	public var gfPos:DoidoPoint;

	public var bfScrollFactor:DoidoPoint;
	public var dadScrollFactor:DoidoPoint;
	public var gfScrollFactor:DoidoPoint;

	public function reloadStage(curStage:String)
	{
		this.curStage = curStage;
		stageItems = [];

		// default data values
		camZoom = 0.9;
		gfVersion = "";

		dadPos = {x: 300, y: FlxG.height - 50};
		bfPos = {x: FlxG.width - 200, y: FlxG.height - 50};
		gfPos = {x: FlxG.width / 2 + 100, y: FlxG.height - 150};

		dadCam = {x: 0, y: 0};
		bfCam = {x: 0, y: 0};
		gfCam = {x: 0, y: 0};

		bfScrollFactor = {x: 1.0, y: 1.0};
		dadScrollFactor = {x: 1.0, y: 1.0};
		gfScrollFactor = {x: 1.0, y: 1.0};

		// loading the script
		var scriptPath:String = 'data/scripts/stages/$curStage';
		if (Assets.fileExists(scriptPath, SCRIPT))
			loadScript(scriptPath);
		else
		{
			loadedScript = null;
			loadCode(curStage);
		}
	}

	// to-do: make "new" function to preload assets
	function loadScript(path:String)
	{
		loadedScript = new DoidoIris(path, this, false);
		loadedScript.set("PlayState", PlayState);
		loadedScript.set("add", stageItems.push);
		loadedScript.execute();
		callScript("create");
	}

	function loadCode(cur:String)
	{
		switch (cur)
		{
			default:
				var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
				bg.scale.set(1.15, 1.15);
				bg.updateHitbox();
				bg.scrollFactor.set();
				bg.screenCenter();
				bg.zIndex = 0;
				add(bg);
		}
	}

	public function add(obj:FlxSprite)
	{
		stageItems.push(obj);
	}

	inline function getZ(bas:FlxBasic)
		ZIndex.getZ(bas);

	inline function setZ(bas:FlxBasic, val:Int)
		ZIndex.setZ(bas, val);

	inline function removeZ(bas:FlxBasic)
		ZIndex.removeZ(bas);

	// Scripts
	public var loadedScript:Iris = null;

	public function callScript(fun:String, ?args:Array<Dynamic>):Dynamic
	{
		var retValue:Dynamic = null;
		if (loadedScript != null)
		{
			var call = loadedScript.call(fun, args);
			if (call != null && call.returnValue != null)
				retValue = call.returnValue;
		}
		return retValue;
	}
}
