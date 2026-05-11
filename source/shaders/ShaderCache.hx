package shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxCamera;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;

class ShaderCache
{
	private var active:Map<FlxCamera, Array<String>>;
	private var cache:Map<String, BitmapFilter>;

	public function new()
	{
		@:bypassAccessor enabled = Save.data.shaders;
		active = [];
		cache = [];
	}

	public var enabled(default, set):Bool;

	public function set_enabled(b:Bool):Bool
	{
		enabled = b;
		toggleShaders();
		return enabled;
	}

	public function toggleShaders()
	{
		for (cam => shaders in active)
			cam.filters = (enabled ? getCachedFilters(shaders) : []);
	}

	public function setShaders(cam:FlxCamera, shaders:Array<String>)
	{
		active.set(cam, shaders);
		if (enabled)
			cam.filters = getCachedFilters(shaders);
	}

	public function getCachedFilters(shaders:Array<String>):Array<BitmapFilter>
	{
		var filters = [];
		for (name in shaders)
		{
			var filter:BitmapFilter = cache.get(name);
			if (filter != null)
				filters.push(filter);
		}
		return filters;
	}

    public function cacheShader(name:String, shader:Dynamic)
    {
        if(Std.isOfType(shader, FlxRuntimeShader))
            cache.set(name, new ShaderFilter(shader));
        else if(Std.isOfType(shader, ShaderFilter))
            cache.set(name, shader);
    }
}
