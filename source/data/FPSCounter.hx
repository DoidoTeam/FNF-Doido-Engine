package data;

import haxe.Timer;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;

class FPSCounter extends Sprite
{
	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var deltaTimeout:Float = 0.0;

	var fpsField:CounterField;
	var labelField:CounterField;
	var memField:CounterField;

	// Use this if you want to add a watermark to the counter!
	var watermark:String = "";

	public function new(x:Float = 0, y:Float = 0)
	{
		super();
		this.x = x;
		this.y = y;

		fpsField = new CounterField(0, 0, 22, 100, "", Main.gFont, 0xFFFFFF);
		addChild(fpsField);

		labelField = new CounterField(-30, 9, 12, 100, "FPS", Main.gFont, 0xFFFFFF);
		addChild(labelField);

		memField = new CounterField(0, 21, 14, 300, "", Main.gFont, 0xFFFFFF);
		addChild(memField);

		visible = SaveData.data.get("FPS Counter");
		
		times = [];
	}

	private override function __enterFrame(deltaTime:Float)
	{
		if(!visible) return;
		
		final now:Float = Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 50) {
			deltaTimeout += deltaTime;
			return;
		}
		
		var fps:Int = times.length;
		if (fps > FlxG.updateFramerate)
			fps = FlxG.updateFramerate;

		fpsField.text = '$fps';
		labelField.x = fpsField.getLineMetrics(0).width + 5;

		var mem:Float = Math.abs(Math.round(System.totalMemory / 1024 / 1024 * 100) / 100);
		memField.text = CoolUtil.formatBytes(mem);

		#if debug
		memField.text += '\n${Type.getClassName(Type.getClass(FlxG.state))}';
		#end

		memField.text += '\n${watermark}';
		
		if(fps < 30 || fps > 360)
			fpsField.textColor = 0xFF0000;
		else
			fpsField.textColor = 0xFFFFFF;

		if(mem >= 2 * 1024)
			memField.textColor = 0xFF0000;
		else
			memField.textColor = 0xFFFFFF;
	}
}

class CounterField extends TextField
{
	public function new(x:Float = 0, y:Float = 0, size:Int = 14, width:Float = 0, initText:String = "", font:String = "", color:Int = 0xFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;
		this.text = initText;

		if(width != 0)
			this.width = width;

		selectable = false;
		defaultTextFormat = new TextFormat(font, size, color);
	}
}