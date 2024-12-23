package backend.system;

import lime.app.Application;

#if DISCORD_RPC
import Sys.sleep;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
#end

/*
	New Discord.hx rewrite is here!

	Main purpose is to simplify Discord RPC implementation throughout the engine,
	removing many redundancies and the huge mess that was incompatible platforms.

	The current system is split into 2 classes, DiscordIO and DiscordAPI.
	DiscordIO is used by the game to set RPC status and is what decides wether its
	on or off. It's also used to block other platforms (HTML5, Neko and Android)
	from accessing DiscordAPI, to avoid having to use if statements to fix any
	classes they cant use.

	DiscordAPI functions largely like the old DiscordClient but now is able to remember
	the last RPC status used and fixes a couple of unoptimized things (trying to initialize
	or shutdown while isInitialized is true or false, respectively, now stops the function
	from doing anything)

	Another feature is that you can now toggle Discord RPC from the Options Menu!

	- teles
*/

class DiscordIO
{
	public static var lastDetails:String = "In the Menus";
	public static function initialize()
	{
		#if DISCORD_RPC
		if (!DiscordAPI.isInitialized) {
			DiscordAPI.initialize();
			
			Application.current.window.onClose.add(function() {
				DiscordAPI.shutdown();
			});

			Logs.print("initialized Discord RPC");
		}
		#end
	}

	public static function shutdown()
	{
		#if DISCORD_RPC
		DiscordAPI.shutdown();
		Logs.print("shutdown Discord RPC");
		#end
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?log:Bool = true)
	{
		#if DISCORD_RPC
		DiscordAPI.changePresence(details, state);
		if(log)
			Logs.print("changed RPC to " + details);
		lastDetails = details;
		#end
	}

	public static function check()
	{
		#if DISCORD_RPC
		if(SaveData.data.get("Discord RPC"))
			DiscordAPI.initialize();
		else
			shutdown();
		#end
	}
}

#if DISCORD_RPC
class DiscordAPI
{
	public static var isInitialized:Bool = false;
	private static final _defaultID:String = "1125409482101493823";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordRichPresence = DiscordRichPresence.create();

	public dynamic static function shutdown() {
		if(isInitialized)
			Discord.Shutdown();
		isInitialized = false;
	}
	
	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		var requestPtr:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) //New Discord IDs/Discriminator system
			Logs.print('(Discord) Connected to User (${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)})');
		else //Old discriminators
			Logs.print('(Discord) Connected to User (${cast(requestPtr.username, String)})');

		changePresence(DiscordIO.lastDetails);
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		Logs.print('Discord: Error ($errorCode: ${cast(message, String)})', ERROR);
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		Logs.print('Discord: Disconnected ($errorCode: ${cast(message, String)})');
	}

	public static function initialize()
	{
		if(isInitialized) //stop!
			return;

		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), 1, null);

		Logs.print("Discord Client initialized");

		sys.thread.Thread.create(() ->
		{
			var localID:String = clientID;
			while (localID == clientID)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();

				// Wait 2 seconds until the next loop...
				Sys.sleep(2);
			}
		});
		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = 'icon';
		presence.largeImageText = "Engine Version: " + Application.current.meta.get('version');
		presence.smallImageKey = smallImageKey;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();
	}

	public static function updatePresence() {
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
	}
	
	public static function resetClientID() {
		clientID = _defaultID;
	}

	private static function set_clientID(newID:String)
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}
}
#end