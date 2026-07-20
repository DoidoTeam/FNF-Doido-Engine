package doido.objects.system;

import haxe.Timer;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;
import doido.utils.MemoryUtil;
import flixel.math.FlxMath;

class FPSCounter extends Sprite
{
	var bg:Sprite;
	var fpsField:CounterField;
	var labelField:CounterField;
	var memField:CounterField;

	public var bgWidth:Float = 80;
	public var bgHeight:Float = 50;
	public var fps:Float = 0;

	// used for frame calculations
	private var frameCount:Int = 0;
	private var frameTime:Float = 0;

	// used so the counter doesnt update as often
	private var lastFps:Float = -1;
	private var lastMem:Float = -1;

	// how often the counter updates
	private final updateTime:Float = 150;

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
	}

	private override function __enterFrame(deltaTime:Float)
	{
		if (!visible)
			return;

		frameCount++;
		frameTime += deltaTime;

		if (frameTime < updateTime || deltaTime <= 0)
			return;

		fps = frameCount * (1000 / frameTime);
		frameTime = 0;
		frameCount = 0;

		var displayFps = fps;
		if (displayFps > FlxG.updateFramerate)
			displayFps = FlxG.updateFramerate;

		if (displayFps != lastFps)
			drawFps(displayFps);

		var mem:Float = System.totalMemoryNumber;
		if (Math.abs(mem - lastMem) > 51200)
			drawMem(mem);

		var expectedWidth = Math.max(labelField.x + labelField.textWidth, memField.x + memField.textWidth) + 12;
		var expectedHeight = memField.y + memField.textHeight + 12;

		if (expectedWidth != bgWidth || expectedHeight != bgHeight)
		{
			bgWidth = expectedWidth;
			bgHeight = expectedHeight;
			bg.width = bgWidth;
			bg.height = bgHeight;
		}
	}

	inline function drawFps(fps:Float)
	{
		lastFps = fps;
		fpsField.text = '${Math.round(fps)}';
		labelField.x = fpsField.x + fpsField.getLineMetrics(0).width + 4;
		fpsField.textColor = (fps < 30) ? 0xFF0000 : 0xFFFFFF;
	}

	inline function drawMem(mem:Float)
	{
		lastMem = mem;
		memField.text = MemoryUtil.formatMemory(mem);
		memField.textColor = (mem > 1024 * 1024 * 1024) ? 0xFF0000 : 0xFFFFFF;
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
