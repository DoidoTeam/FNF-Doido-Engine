package shaders;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxShader;

class RGBPalette extends FlxShader
{
	@:glFragmentHeader('
		#pragma header
		
		uniform vec3 uR;
		uniform vec3 uG;
		uniform vec3 uB;
		uniform float uMult;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec4 color = flixel_texture2D(bitmap, coord);
			if (!hasTransform || color.a == 0.0 || uMult == 0.0) {
				return color;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * uR + color.g * uG + color.b * uB, vec3(1.0));
			newColor.a = color.a;
			
			color = mix(color, newColor, uMult);
			
			if(color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')
	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')
	public function new()
	{
		super();
		setColor(FlxColor.WHITE, FlxColor.GRAY, FlxColor.BLACK, 1.0);
	}

	public var mult(default, set):Float = 1.0;

	inline function set_mult(v:Float):Float
	{
		mult = FlxMath.bound(v, 0, 1);
		this.uMult.value = [mult];
		return mult;
	}

	public var red(default, set):FlxColor;

	inline function set_red(v:FlxColor):FlxColor
	{
		red = v;
		this.uR.value = [v.redFloat, v.greenFloat, v.blueFloat];
		return v;
	}

	public var green(default, set):FlxColor;

	inline function set_green(v:FlxColor):FlxColor
	{
		green = v;
		this.uG.value = [v.redFloat, v.greenFloat, v.blueFloat];
		return v;
	}

	public var blue(default, set):FlxColor;

	inline function set_blue(v:FlxColor):FlxColor
	{
		blue = v;
		this.uB.value = [v.redFloat, v.greenFloat, v.blueFloat];
		return v;
	}

	public function setColor(color1:FlxColor, color2:FlxColor, color3:FlxColor, ?mult:Float)
	{
		red = color1;
		green = color2;
		blue = color3;
		if (mult != null)
			this.mult = mult;
	}
}
