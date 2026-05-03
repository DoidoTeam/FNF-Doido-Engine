package doido;

#if MODS_FOLDER
import polymod.util.VersionUtil;
import thx.semver.VersionRule;
import polymod.format.ParseRules;
import polymod.Polymod;
import polymod.PolymodConfig;
import thx.semver.Version;
import sys.io.File;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import haxe.io.Bytes;

typedef Mod =
{
	var name:String;
	var enabled:Bool;
}

typedef ModList =
{
	var mods:Array<Mod>;
}

typedef ModConfig =
{
	var ?reload:Bool;
	var ?initialState:String;
	var ?redirects:Array<StateRedirect>;
	var ?options:Array<ModOption>;
}

typedef StateRedirect =
{
	var origin:String;
	var target:String;
}

typedef ModOption =
{
	var name:String;
	var value:Dynamic;
	var ?desc:String;

	// extra settings
	var ?playStateWarning:Bool;

	// SELECTORS
	var ?options:Array<String>;

	// SLIDERS
	var ?step:Float;
	var ?hold:Float;
	var ?limits:Array<Float>;
}

/*
 * This is a very early version of Doido's new Mod API.
 * Please keep in mind a lot of things are not yet implemented
 * and others may break when we change stuff.
 * TO-DO
 * - Mod Settings
 * - Better Meta
 * - Better Mod Manager
 * - Support for more soft-coded things
 */
class Mods
{
	public static var modList:ModList = {mods: []};
	public static var modMetas:Array<ModMetadata> = [];
	public static var modConfigs:Map<String, ModConfig> = [];
	public static var enabledMods:Array<String> = [];

	public static final API_VERSION:Version = "0.2.1";
	public static final MOD_ROOT:String = "mods";
	public static final ASSETS_ROOT:String = "assets";
	public static final VERSION_RULE:VersionRule = '>=${API_VERSION.major}.${API_VERSION.minor}.0 <=${API_VERSION}';

	public static final ignoredFiles:Array<String> = [
		'assets/data/weeks/order.json',
		'assets/data/credits/order.json',
		'assets/data/credits/doido.json',
		'$MOD_ROOT/mods.json'
	];
	public static final ignoredStates:Array<String> = [
		// states
		'doido.objects.system.CrashHandler',
		'states.LoadingState',
		'states.PlayState',
		'states.ScriptedState',
		'states.editors.CharacterEditor',
		'states.editors.ChartingState',
		// substates
		'doido.objects.WebsiteWarning',
		'doido.objects.system.Transition',
		'substates.ScriptedSubState',
		'substates.editors.ChartTestSubState',
		'substates.editors.PopupSubState',
		'substates.menus.ModSubState',
		'substates.menus.OptionsSubState',
	];

	public static function init()
	{
		PolymodConfig.modMetadataFile = 'meta.json';
		PolymodConfig.modIconFile = 'icon.png';
		Polymod.init({
			modRoot: MOD_ROOT,
			dirs: [],
			frameworkParams: {
				coreAssetRedirect: ASSETS_ROOT
			},
			apiVersionRule: VERSION_RULE,
			errorCallback: onError,
			parseRules: new ParseRules(), // disables it i hope
			ignoredFiles: ignoredFiles,
			useScriptedClasses: false
		});
		loadJson();
		scan();
	}

	// scans the mods folder for new mods n stuff
	public static function scan()
	{
		modMetas = []; // just to be sure
		modMetas = Polymod.scan({modRoot: "mods"});
		var scanned:Array<String> = [];
		for (meta in modMetas)
		{
			if (!VersionUtil.match(meta.apiVersion, VERSION_RULE))
			{
				Logs.print('Mod "${meta.id}" was built for incompatible API version ${meta.apiVersion.toString()}, expected "${VERSION_RULE.toString()}"',
					POLYMOD);
				continue;
			}
			if (!exists(meta.id))
				setMod(meta.id, false); // just to be safe
			scanned.push(meta.id);
		}
		trace(scanned);

		for (mod in modList.mods)
			if (!scanned.contains(mod.name))
				modList.mods.remove(mod);

		saveJson();
		loadMods();
	}

	public static function loadJson()
	{
		try
		{
			modList = cast haxe.Json.parse(openfl.Assets.getText("mods/mods.json").trim());
		}
		catch (e)
		{
			Logs.print('Error loading Mod List: $e', ERROR);
			modList = {mods: []};
		}
	}

	public static function saveJson()
	{
		var data:String = haxe.Json.stringify(modList, "\t");
		File.saveContent("mods/mods.json", data);
	}

	public static function loadMods()
	{
		var newMods:Array<String> = [];
		for (mod in modList.mods)
			if (mod.enabled)
				newMods.push(mod.name);

		Polymod.loadOnlyMods(newMods);

		for (mod in newMods)
		{
			var config:ModConfig = {};
			try
			{
				config = cast getJSON("config", mod);
			}
			catch (e)
			{
				Logs.print('MOD CONFIG LOAD ERROR: $e', POLYMOD);
			}

			config.redirects = config.redirects ?? [];
			config.initialState = config.initialState ?? "";
			config.reload = config.reload ?? false;
			config.options = config.options ?? [];
			modConfigs.set(mod, config);

			for (option in config.options)
			{
				if (Save.data.modData.get(option.name) != null)
					continue;

				Save.data.modData.set(option.name, option.value);
			}
		}

		if (!reload)
		{
			var added = newMods.filter(m -> !enabledMods.contains(m));
			var removed = enabledMods.filter(m -> !newMods.contains(m));
			var changed = added.concat(removed);

			for (mod in changed)
			{
				var config = modConfigs.get(mod);
				if (config != null && (config.reload ?? false))
				{
					reload = true;
					break;
				}
			}
		}
		enabledMods = newMods;
	}

	public static function getMod(mod:String)
	{
		var index:Int = getIndex(mod);
		return index == -1 ? false : modList.mods[index].enabled;
	}

	public static function setMod(mod:String, ?enable:Bool, save:Bool = false)
	{
		var index:Int = getIndex(mod);

		if (index == -1)
			addMod(mod);
		else
			modList.mods[index].enabled = enable ?? modList.mods[index].enabled;

		if (save)
		{
			saveJson();
			loadMods();
		}
	}

	// unsafe, dont use
	public static function addMod(mod:String)
	{
		modList.mods.push({
			name: mod,
			enabled: false
		});
	}

	public static function getIndex(mod:String)
	{
		for (i in 0...modList.mods.length)
			if (mod == modList.mods[i].name)
				return i;

		return -1;
	}

	public static function exists(mod:String)
		return getIndex(mod) >= 0;

	public static function move(index:Int, offset:Int)
	{
		// check if its in bounds
		if (index + offset >= modList.mods.length || index + offset < 0)
			return;

		var temp = modList.mods[index];
		modList.mods[index] = modList.mods[index + offset];
		modList.mods[index + offset] = temp;

		if (!reload)
		{
			for (mod in [modList.mods[index], modList.mods[index + offset]])
			{
				var config = modConfigs.get(mod.name);
				if (config != null && (config.reload ?? false))
				{
					reload = true;
					break;
				}
			}
		}

		saveJson();
		loadMods();
	}

	static var skippedErrors:Array<PolymodErrorType> = [NOTICE];

	public static function onError(err:PolymodError):Void
	{
		if (skippedErrors.contains(err.severity))
			return;

		Logs.print('Polymod.${(cast err.origin).toUpperCase()} | ${err.message}', POLYMOD, true, true, false);
	}

	public static function getIcon(mod:String)
	{
		var meta = getMeta(mod);
		var icon:Bytes = (meta != null) ? meta.icon : null; // just making sure we dont crash

		if (icon == null)
			return Assets.image("icon");
		else
			return FlxGraphic.fromBitmapData(BitmapData.fromBytes(icon));
	}

	public static function getTitle(mod:String):String
	{
		var meta = getMeta(mod);
		return meta != null ? meta.title : "unknown";
	}

	public static function getMeta(mod:String):ModMetadata
	{
		for (meta in modMetas)
			if (meta.id == mod)
				return meta;

		return null;
	}

	public static var reload:Bool = false;
	public static var stateRedirects(get, never):Map<String, String>;
	public static var initialState(get, never):String;
	public static var modOptions(get, never):Array<ModOption>;

	public static function get_stateRedirects():Map<String, String>
	{
		var redirects:Map<String, String> = [];

		for (mod in modList.mods)
		{
			if (!mod.enabled)
				continue;

			var config = modConfigs.get(mod.name);
			if (config == null)
				continue;

			for (redirect in config.redirects)
				if (!ignoredStates.contains(redirect.origin))
					redirects.set(redirect.origin, redirect.target);
		}

		return redirects;
	}

	public static function get_initialState():String
	{
		var init:String = "";

		for (mod in modList.mods)
		{
			if (!mod.enabled)
				continue;
			var config = modConfigs.get(mod.name);
			if (config == null)
				continue;
			init = config.initialState;
		}

		return init;
	}

	public static function get_modOptions():Array<ModOption>
	{
		var options:Array<ModOption> = [];

		for (mod in modList.mods)
		{
			if (!mod.enabled)
				continue;
			var config = modConfigs.get(mod.name);
			if (config == null)
				continue;
			options = options.concat(config.options);
		}

		return options;
	}

	public static function getJSON(key:String, mod:String):Dynamic
		return haxe.Json.parse(Polymod.getFileSystem().getFileContent(getPath('$key.json', mod)).trim());

	public static inline function getPath(key:String, mod:String):String
		return 'mods/$mod/$key';
}
#end
