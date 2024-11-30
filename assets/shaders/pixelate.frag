#pragma header

uniform float uAmount;

void main()
{
    vec2 uv = openfl_TextureCoordv;
	uv.x = floor(uv.x * uAmount) / uAmount;
	uv.y = floor(uv.y * uAmount) / uAmount;
	gl_FragColor = flixel_texture2D(bitmap, fract(uv));
}