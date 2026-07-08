package;

import flixel.FlxState;
import doido.Cache;
import doido.MusicBeat.MusicBeatState;
import doido.song.Highscore;
import doido.system.Discord.DiscordIO;
import doido.utils.EditorUtil.EditorSave;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import states.*;
#if MODS_FOLDER
import doido.Mods;
#end

class Init extends MusicBeatState
{
	override function create()
	{
		super.create();
		Save.init();
		Controls.load();
		Highscore.load();
		EditorSave.load();
		DiscordIO.check();

		Main.setWindowSize(Save.data.windowSize);
		#if windows
		doido.system.Windows.setDarkMode(Save.data.darkMode);
		#end

		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;

		#if MODS_FOLDER
		Mods.init();
		#end

		FlxGraphic.defaultPersist = true;
		openfl.Assets.cache.enabled = false;
		Cache.initCache();
		flagState();

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end
	}

	/*
	 * A function to call some of the engines build flags from
	 * other states.
	 */
	public static function flagState()
	{
		MusicBeat.stopMusic();
		#if MODS_FOLDER
		Mods.reload = false;
		var initialState:String = Mods.initialState;
		if (initialState != "")
		{
			if (Assets.fileExists('data/scripts/states/$initialState', SCRIPT))
				return MusicBeat.switchState(new ScriptedState(initialState));

			var state = Type.resolveClass(initialState);
			if (state != null)
			{
				var instance = Type.createInstance(state, []);
				if (Std.isOfType(instance, FlxState))
					return MusicBeat.switchState(cast instance);
			}
		}
		#end
		TitleState.introEnded = false;
		MusicBeat.switchState(new TitleState());
	}
}
