package shaders;

import flixel.system.FlxAssets.FlxShader;

// basically same shit as haxeflixel demo
// but i made some changes to the variables
class HoldNoteShader
{
   public var shader(default, null):HoldNoteShaderData = new HoldNoteShaderData();
   
   public var y(default, set):Float = 0;
   public var cutY(default, set):Float = 1;
   public var downscroll(default, set):Bool = false;

   public function new() {}
   
   function set_y(v:Float):Float
   {
      y = v;
      shader.uY.value = [y];
      return v;
   }
   function set_cutY(v:Float):Float
   {
      cutY = v;
      shader.uCutY.value = [cutY];
      return v;
   }
   function set_downscroll(v:Bool):Bool
   {
      downscroll = v;
      shader.uDownscroll.value = [downscroll];
      return v;
   }
}

class HoldNoteShaderData extends FlxShader
{
   @:glFragmentSource('
      #pragma header
      uniform float uY;
      uniform float uCutY;
      uniform bool uDownscroll;

      void main()
      {
         vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
         vec2 uv = openfl_TextureCoordv.xy;
         vec4 color = flixel_texture2D(bitmap, uv);
         
         bool shouldCut = false;

         // sets the bound accordingly
         shouldCut = (fragCoord.y + uY < uCutY);
         if(uDownscroll)
            shouldCut = !shouldCut;

         // if its out of bounds, it turns invisible
         if(color.a == 0.0 || shouldCut)
            gl_FragColor = vec4(0.0,0.0,0.0,0.0);
         else
            gl_FragColor = vec4(color.r, color.g, color.b, color.a);
      }')
   public function new()
   {
      super();
   }
}
