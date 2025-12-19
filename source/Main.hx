package;

import backend.system.AudioSwitchFix;
import backend.system.CrashHandler;
import PopUp.PopupManager;
import lime.text.harfbuzz.HBLanguage;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import debug.FPSCounter;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import gamejolt.*;
import sys.FileSystem;

//crash handler stuff
#if CRASH_HANDLER
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

#if ALLOW_MULTITHREADING
import sys.thread.Thread;
#end

#if mobile
import mobile.util.MobileUtil;
#end

using StringTools;

#if windows
@:buildXml('
<target id="haxe">
	<lib name="wininet.lib" if="windows" />
	<lib name="dwmapi.lib" if="windows" />
</target>
')

@:cppFileCode('
#include <windows.h>
#include <winuser.h>
#pragma comment(lib, "Shell32.lib")
extern "C" HRESULT WINAPI SetCurrentProcessExplicitAppUserModelID(PCWSTR AppID);
')
#end

class Main extends Sprite
{
	var mouse:DoorsMouse;

	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:FPSCounter;

	public static var noTerminalColor:Bool = false;
	public static var audioDisconnected:Bool = false;
	public static var changeID:Int = 0;

	#if ALLOW_MULTITHREADING
	public static var gameThreads:Array<Thread> = [];
	#end
	public static function main():Void
	{
		// We need to make the crash handler LITERALLY FIRST so nothing EVER gets past it.
		CrashHandler.initialize();
		CrashHandler.queryStatus();

		#if windows
		AudioSwitchFix.init(); // Mobile ja arruma o audio, então n precisamos disso
		CppAPI.darkMode();
     	#end

		Lib.current.addChild(new Main());
	}

	public function new()
	{
		// DPI Scaling fix for windows 
		// this shouldn't be needed for other systems
		// Credit to YoshiCrafter29 for finding this function
		#if windows
		untyped __cpp__("SetProcessDPIAware();");	

		var display = lime.system.System.getDisplay(0);
		if (display != null) {
			var dpiScale:Float = display.dpi / 96;
			Application.current.window.width = Std.int(gameWidth * dpiScale);
			Application.current.window.height = Std.int(gameHeight * dpiScale);

			Application.current.window.x = Std.int((Application.current.window.display.bounds.width - Application.current.window.width) / 2);
			Application.current.window.y = Std.int((Application.current.window.display.bounds.height - Application.current.window.height) / 2);
		}
		#end

		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private static var __threadCycle:Int = 0;
	public static function execAsync(func:Void->Void) {
		#if ALLOW_MULTITHREADING
		var thread = gameThreads[(__threadCycle++) % gameThreads.length];
		thread.events.run(func);
		#else
		func();
		#end
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}
	
	public static var popupManager:PopupManager;

	private function setupGame():Void
	{
		FlxG.stage.quality = MEDIUM;

        #if mobile
		Sys.setCwd(haxe.io.Path.addTrailingSlash(MobileUtil.getDirectory()));
		MobileUtil.getPermissions();

		// Data folder
		if (!FileSystem.exists('assets/')) {
			extension.androidtools.Tools.showAlertDialog("FNF: Doors Engine Requirement", "Please copy the Assets folder from the APK to " + MobileUtil.getDirectory() + ", so you can play", {name: "OK", func: null}, null);
		}
		#end
		
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		addChild(new FlxGame(gameWidth, gameHeight, TitleState, #if (flixel < "5.0.0") 1, #end framerate, framerate, skipSplash, startFullscreen));
		
		#if ALLOW_MULTITHREADING
		for(i in 0...4)
			gameThreads.push(Thread.createWithEventLoop(function() {Thread.current().events.promise();}));
		#end

		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}

		DoorsVideoSprite.init();
		MenuSongManager.init();
		
		FlxG.signals.gameResized.add(fixCameraShaders);

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end
		
		popupManager = new PopupManager();
		addChild(popupManager);
	}

	
	public static function fixCameraShaders(w:Int, h:Int) //fixes shaders after resizing the window / fullscreening
	{
		if (FlxG.cameras.list.length > 0)
		{
			for (cam in FlxG.cameras.list)
			{
				if (cam.flashSprite != null)
				{
					@:privateAccess 
					{
						cam.flashSprite.__cacheBitmap = null;
						cam.flashSprite.__cacheBitmapData = null;
						cam.flashSprite.__cacheBitmapData2 = null;
						cam.flashSprite.__cacheBitmapData3 = null;
						cam.flashSprite.__cacheBitmapColorTransform = null;
					}
				}
			}
		}
	}
}
