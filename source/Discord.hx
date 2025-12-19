package;
#if DISCORD
import Sys.sleep;
import discord_rpc.DiscordRpc;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

using StringTools;

class DiscordClient
{
	public static var isInitialized:Bool = false;
	public function new()
	{
		#if DISCORD
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "1063824386727096320",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");

		while (true)
		{
			DiscordRpc.process();
			sleep(2);
			//trace("Discord Client Update");
		}

		DiscordRpc.shutdown();
		#end
	}
	
	public static function shutdown()
	{
		#if DISCORD
		DiscordRpc.shutdown();
		#end
	}
	
	static function onReady()
	{
		#if DISCORD
		DiscordRpc.presence({
			details: "In the Menus",
			state: null,
			largeImageKey: 'gameicon',
			largeImageText: "Psych Engine"
		});
		#end
	}

	static function onError(_code:Int, _message:String)
	{
		#if DISCORD
		trace('Error! $_code : $_message');
		#end
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		#if DISCORD
		trace('Disconnected! $_code : $_message');
		#end
	}

	public static function initialize()
	{
		#if DISCORD
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		trace("Discord Client initialized");
		isInitialized = true;
		#end
	}

	/**
	 * Changes the Discord presence of the user.
	 * @param details The details of the presence.
	 * @param state The state of the presence.
	 * @param smallImageKey The key of the small image to be displayed.
	 * @param largeImage The key of the large image to be displayed.
	 * @param hasStartTimestamp Whether the presence has a start timestamp.
	 * @param endTimestamp The end timestamp of the presence.
	 */
	public static function changePresence(details:String, state:Null<String>, ?largeImageKey:String = 'gameicon', ?smallImageKey : String = '', ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		#if DISCORD
		var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: largeImageKey,
			largeImageText: "Engine Version: " + MainMenuState.doorsEngineVersion,
			smallImageKey: smallImageKey == "" ? null : smallImageKey,
			startTimestamp : Std.int(startTimestamp / 1000),
            endTimestamp : Std.int(endTimestamp / 1000)
		});
		#end

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $largeImage, $hasStartTimestamp, $endTimestamp');
	}

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		#if DISCORD
		Lua_helper.add_callback(lua, "changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});
		#end
	}
	#end
}
#end