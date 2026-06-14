package doido.objects.system;

import haxe.Timer;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;
import doido.utils.MemoryUtil;

class FPSCounter extends Sprite
{
	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var deltaTimeout:Float = 0.0;

	var bg:Sprite;
	var fpsField:CounterField;
	var labelField:CounterField;
	var memField:CounterField;

	// Use this if you want to add a watermark to the counter!
	var watermark:String = "";
	var debug:Bool = #if debug true #else false #end;

	public var bgWidth:Float = 80;
	public var bgHeight:Float = 50;

	public function new(x:Float = 0, y:Float = 0)
	{
		super();
		this.x = x;
		this.y = y;

		bg = new Sprite();
		bg.graphics.beginFill(0x000000, 0.5);
		bg.graphics.drawRoundRect(x, y, bgWidth, bgHeight, 6, 6);
		bg.graphics.endFill();
		addChild(bg);

		fpsField = new CounterField(x + 5, y + 5, 22, 100, "", Main.globalFont, 0xFFFFFF);
		addChild(fpsField);

		labelField = new CounterField(x, y + 5 + 9, 12, 100, "FPS", Main.globalFont, 0xFFFFFF);
		addChild(labelField);

		memField = new CounterField(x + 5, y + 5 + 21, 14, 300, "", Main.globalFont, 0xFFFFFF);
		addChild(memField);

		visible = Save.data.fpsCounter;
		// watermark = 'DE-Pudim ${Main.internalVer}';

		times = [];
	}

	private override function __enterFrame(deltaTime:Float)
	{
		if (!visible)
			return;

		final now:Float = Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();

		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 50)
		{
			deltaTimeout += deltaTime;
			return;
		}

		var fps:Int = times.length;
		if (fps > FlxG.updateFramerate)
			fps = FlxG.updateFramerate;

		fpsField.text = '$fps';
		labelField.x = fpsField.x + fpsField.getLineMetrics(0).width + 4;

		memField.text = MemoryUtil.formatMemory(System.totalMemoryNumber);

		if (debug)
		{
			#if windows
			memField.text += ' / ${MemoryUtil.formatMemory(doido.system.Windows.getMem())}';
			#end

			memField.text += '\n${Type.getClassName(Type.getClass(FlxG.state))}';
		}

		memField.text += '\n${watermark}';

		if (fps < 30 || fps > 360)
			fpsField.textColor = 0xFF0000;
		else
			fpsField.textColor = 0xFFFFFF;

		graphics.clear();

		bgWidth = Math.max(labelField.x + labelField.textWidth, memField.x + memField.textWidth) + 12;
		bgHeight = memField.y + memField.textHeight + 12;

		bg.width = bgWidth;
		bg.height = bgHeight;
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

		if (width != 0)
			this.width = width;

		selectable = false;
		defaultTextFormat = new TextFormat(font, size, color);
	}
}
