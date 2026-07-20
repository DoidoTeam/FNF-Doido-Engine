package doido.utils;

import flixel.tweens.FlxEase;

class TweenUtil
{
	public static var availableEases:Array<String> = ["linear", "quad", "cube", "quart", "quint", "sine", "circ", "expo", "smoothStep"];
	public static var availableModifiers:Array<String> = ["InOut", "In", "Out"];

	public static function fromString(ease:String, modifier:String = "inout"):EaseFunction
	{
		return switch ((ease + modifier).toLowerCase())
		{
			case "quadin": FlxEase.quadIn;
			case "quadout": FlxEase.quadOut;
			case "quadinout": FlxEase.quadInOut;

			case "cubein": FlxEase.cubeIn;
			case "cubeout": FlxEase.cubeOut;
			case "cubeinout": FlxEase.cubeInOut;

			case "quartin": FlxEase.quartIn;
			case "quartout": FlxEase.quartOut;
			case "quartinout": FlxEase.quartInOut;

			case "quintin": FlxEase.quintIn;
			case "quintout": FlxEase.quintOut;
			case "quintinout": FlxEase.quintInOut;

			case "sinein": FlxEase.sineIn;
			case "sineout": FlxEase.sineOut;
			case "sineinout": FlxEase.sineInOut;

			case "circin": FlxEase.circIn;
			case "circout": FlxEase.circOut;
			case "circinout": FlxEase.circInOut;

			case "expoin": FlxEase.expoIn;
			case "expoout": FlxEase.expoOut;
			case "expoinout": FlxEase.expoInOut;

			case "smoothstepin": FlxEase.smoothStepIn;
			case "smoothstepout": FlxEase.smoothStepOut;
			case "smoothstepinout": FlxEase.smoothStepInOut;

			default: FlxEase.linear;
		}
	}
}
