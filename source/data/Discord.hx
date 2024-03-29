package data;

import lime.app.Application;

#if !html5
import Sys.sleep;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
#end

class DiscordClient
{
	public static var isInitialized:Bool = false;
	private static final _defaultID:String = "1125409482101493823";
	public static var clientID(default, set):String = _defaultID;
	#if !html5
	private static var presence:DiscordRichPresence = DiscordRichPresence.create();
	#end

	public static function check()
	{
		#if DISCORD_RPC
		if(SaveData.data.get('Discord RPC')) initialize();
		else if(isInitialized) shutdown();
		#end
	}
	
	public static function prepare()
	{
		#if DISCORD_RPC
		if (!isInitialized && SaveData.data.get('Discord RPC'))
			initialize();

		Application.current.window.onClose.add(function() {
			if(isInitialized) shutdown();
		});
		#end
	}

	public dynamic static function shutdown() {
		#if DISCORD_RPC
		Discord.Shutdown();
		isInitialized = false;
		#end
	}
	
	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		#if DISCORD_RPC
		var requestPtr:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) //New Discord IDs/Discriminator system
			trace('(Discord) Connected to User (${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)})');
		else //Old discriminators
			trace('(Discord) Connected to User (${cast(requestPtr.username, String)})');

		changePresence();
		#end
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		#if DISCORD_RPC
		trace('Discord: Error ($errorCode: ${cast(message, String)})');
		#end
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		#if DISCORD_RPC
		trace('Discord: Disconnected ($errorCode: ${cast(message, String)})');
		#end
	}

	public static function initialize()
	{
		#if DISCORD_RPC
		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), 1, null);

		if(!isInitialized) trace("Discord Client initialized");

		sys.thread.Thread.create(() ->
		{
			var localID:String = clientID;
			while (localID == clientID)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();

				// Wait 0.5 seconds until the next loop...
				Sys.sleep(0.5);
			}
		});
		isInitialized = true;
		#end
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		#if DISCORD_RPC
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
		#end
		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	public static function updatePresence() {
		#if DISCORD_RPC
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
		#end
	}
	
	public static function resetClientID() {
		#if DISCORD_RPC
		clientID = _defaultID;
		#end
	}

	private static function set_clientID(newID:String)
	{
		#if DISCORD_RPC
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
		#end
	}
}