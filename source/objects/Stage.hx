package objects;

import crowplexus.iris.Iris;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import states.PlayState;
import objects.StageScript;

class Stage extends FlxGroup
{
	public var script:StageScript;
	public static var instance:Stage;

	public var curStage:String = "";
	public var gfVersion:String = "no-gf";
	public var camZoom:Float = 1;

	// things to help your stage get better
	public var bfPos:FlxPoint  = new FlxPoint();
	public var dadPos:FlxPoint = new FlxPoint();
	public var gfPos:FlxPoint  = new FlxPoint();

	public var bfCam:FlxPoint  = new FlxPoint();
	public var dadCam:FlxPoint = new FlxPoint();
	public var gfCam:FlxPoint  = new FlxPoint();

	public var foreground:FlxGroup;

	var loadedScripts:Array<Iris> = [];
	var scripted:Array<String> = [];

	private var lowQuality:Bool = false;

	public function new() {
		super();
		foreground = new FlxGroup();
		instance = this;
	}

	public function reloadStageFromSong(song:String = "test"):Void
	{
		var stageList:Array<String> = [];
		
		stageList = switch(song)
		{
			default: ["stage"];
			
			case "collision": ["mugen"];
			
			case "senpai"|"roses": 	["school"];
			case "thorns": 			["school-evil"];
			
			//case "template": ["preload1", "preload2", "starting-stage"];
		};

		//this stops you from fucking stuff up by changing this mid song
		lowQuality = SaveData.data.get("Low Quality");
		
		/*
		*	makes changing stages easier by preloading
		*	a bunch of stages at the create function
		*	(remember to put the starting stage at the last spot of the array)
		*/
		for(i in stageList) {
			preloadScript(i);
			reloadStage(i);
		}
	}

	public function reloadStage(curStage:String = "")
	{
		this.clear();
		foreground.clear();
		this.curStage = curStage;
		
		gfPos.set(660, 580);
		dadPos.set(260, 700);
		bfPos.set(1100, 700);
		
		if(scripted.contains(curStage))
			callScript("create");
		else
			loadCode(curStage);

		PlayState.defaultCamZoom = camZoom;
	}

	public function preloadScript(stage:String = "")
	{
		var path:String = 'images/stages/_scripts/$stage';
		
		if(Paths.fileExists('$path.hxc'))
			path += '.hxc';
		else if(Paths.fileExists('$path.hx'))
			path += '.hx';
		else
			return;

		var newScript:Iris = new Iris(Paths.script('$path'), {name: path, autoRun: false, autoPreset: true});

		// variables to be used inside the scripts
		newScript.set("FlxSprite", FlxSprite);
		newScript.set("Paths", Paths);
		newScript.set("this", instance);

		newScript.set("add", add);
		newScript.set("foreground", foreground);

		newScript.set("bfPos", bfPos);
		newScript.set("dadPos", dadPos);
		newScript.set("gfPos", gfPos);

		newScript.set("bfCam", bfCam);
		newScript.set("dadCam", dadCam);
		newScript.set("gfCam", gfCam);

		newScript.set("lowQuality", lowQuality);

		newScript.execute();

		loadedScripts.push(newScript);
		scripted.push(stage);
	}

	// Hardcode your stages here!
	public function loadCode(curStage:String = "")
	{
		if(script != null)
			script = null;
		gfVersion = getGfVersion(curStage);

		switch(curStage)
		{
			default:
				this.curStage = "stage";
				script = new objects.stages.BaseStage(this);
				
			case "school":
				script = new objects.stages.School(this);
				
			case "school-evil":
				script = new objects.stages.SchoolEvil(this);
		}
	}

	public function getGfVersion(curStage:String)
	{
		return switch(curStage)
		{
			case "mugen": "no-gf";
			case "school"|"school-evil": "gf-pixel";
			default: "gf";
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(script != null)
			script.update(elapsed);
		callScript("update", [elapsed]);
	}
	
	public function stepHit(curStep:Int = -1)
	{
		// beat hit
		// if(curStep % 4 == 0)
		if(script != null)
			script.stepHit(curStep);
		callScript("stepHit", [curStep]);
	}

	public function callScript(fun:String, ?args:Array<Dynamic>)
	{
		for(i in 0...loadedScripts.length) {
			if(scripted[i] != curStage)
				continue;

			var script:Iris = loadedScripts[i];

			@:privateAccess {
				var ny: Dynamic = script.interp.variables.get(fun);
				try {
					if(ny != null && Reflect.isFunction(ny))
						script.call(fun, args);
				} catch(e) {
					Logs.print('error parsing script: ' + e, ERROR);
				}
			}
		}
	}
}