package shaders;

import flixel.system.FlxAssets.FlxShader;

// basically same shit as haxeflixel demo
// but i made some changes to the variables
class DistantNoteShader
{
   public var shader(default, null):DistantNoteShaderData = new DistantNoteShaderData();
   
   public var downscroll(default, set):Bool = false;

   public function new() {}
   
   function set_downscroll(v:Bool):Bool
   {
      downscroll = v;
      shader.uDownscroll.value = [downscroll];
      return v;
   }
}

class DistantNoteShaderData extends FlxShader
{
   @:glFragmentSource('
    #pragma header

    uniform bool uDownscroll;

    void main()
    {
        vec2 uv = openfl_TextureCoordv.xy;
        vec2 iResolution = openfl_TextureSize;
        vec2 fragCoord = openfl_TextureCoordv * iResolution;
        
        float actualY = uv.y;
        if(uDownscroll)
            actualY = (iResolution.y - (uv.y * iResolution.y)) / iResolution.y;

        actualY -= 0.42;
        
        uv.x += (actualY / 0.8) * (fragCoord.x - (iResolution.x * 0.5)) / iResolution.x;
        
        gl_FragColor = flixel_texture2D(bitmap, uv);
    }')
   public function new()
   {
      super();
   }
}
/*
// og shader
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    float actualY = uv.y;
    
    bool uDownscroll = false;
    if(uDownscroll)
        actualY = (iResolution.y - (uv.y * iResolution.y)) / iResolution.y;
    
    actualY -= 0.42;
    
    uv.x += ((actualY) / 0.8) * (fragCoord.x - (iResolution.x * 0.5)) / iResolution.x;
    
    fragColor = texture(iChannel0, uv);
}
*/
