package data;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import haxe.Timer;
//import openfl.display.FPS;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * FPS class extension to display memory usage.
 * @author Kirill Poletaev
 * https://keyreal-code.github.io/haxecoder-tutorials/17_displaying_fps_and_memory_usage_using_openfl.html
 */

class FPSCounter extends TextField
{
	private var times:Array<Float>;
	private var memPeak:Float = 0;

	public function new(inX:Float = 10.0, inY:Float = 10.0) 
	{
		super();
		x = inX;
		y = inY;
		selectable = false;
		defaultTextFormat = new TextFormat(Main.gFont, 14, 0x000000);
		text = "FPS: ";
		
		times = [];
		addEventListener(Event.ENTER_FRAME, onEnter);
		visible = SaveData.data.get("FPS Counter");
		width = 300;
		height = 70;
	}

	private function onEnter(_:Event)
	{
		if(!visible) return;
		
		var now = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1)
			times.shift();
		
		var fps:Int = times.length;
		if (fps > FlxG.updateFramerate)
			fps = FlxG.updateFramerate;
		
		var mem:Float = Math.round(System.totalMemory / 1024 / 1024 * 100) / 100;
		if(mem > memPeak)
			memPeak = mem;
		
		if(fps < 30 || fps > 360
		|| mem >= 2 * 1024)
		{
			textColor = 0xFF0000;
		}
		else
			textColor = 0xFFFFFF;
		
		text = 'FPS: ${fps}\n'
		+ 'Memory: ${formatMemory(mem)}\n'
		+ 'MaxMem: ${formatMemory(memPeak)}';
	}
	
	function formatMemory(memory:Float):String
	{
		var unit:String = "MB";
		if(memory >= 1024)
		{
			unit = "GB";
			memory /= 1024;
		}
		memory = Math.floor(memory * 100) / 100;
		
		return '$memory $unit';
	}
}