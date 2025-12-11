package states;

import backend.updating.UpdateUtil.UpdateCheckCallback;
import substates.PauseSubState.PauseVinyl;
import flixel.FlxObject;
import objects.ui.DoorsScore;
import objects.ui.DoorsButton;
import openfl.display.BlendMode;
#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import SoundCompare;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxTextNew as FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;

using StringTools;

class TitleState extends MusicBeatState
{
	// Static configuration
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var initialized:Bool = false;
	public static var updateVersion:String = '';
	public static var closedState:Bool = false;
	private static var hasCheckedUpdates:Bool = false;
	
	// Instance variables
	private var report:Null<UpdateCheckCallback>;
	private var skippedIntro:Bool = false;
	private var sickSteps:Int = 0; // Basically curStep but won't be skipped if you hold the tab or resize the screen
	
	// Camera related
	public var camGame:FlxCamera;
	public var camFollowPos:FlxObject;
	public var realCamFollowPos:FlxObject;
	
	// UI Elements
	private var glasshatLogo:FlxSprite;
	private var glasshatLogoTxt:FlxText;
	private var haxeflixelLogo:FlxSprite;
	private var haxeflixelLogoTxt:FlxText;
	private var lilVinyl:PauseVinyl;
	private var lilVinylTxt:FlxText;
	private var bf:FlxSprite;
	private var gf:FlxSprite;

	//more sprites
	private var fullBlack:FlxSprite;

	override public function create():Void
	{
		// Initialize basics
		initializeBasics();
		
		// Check for updates
		checkForUpdates();
		
		// Setup camera
		setupCamera();
		
		// Check for update reports
		report = hasCheckedUpdates ? null : backend.updating.UpdateUtil.checkForUpdates();
		hasCheckedUpdates = true;
		
		// Create and add all UI elements
		createBackground();
		createLogos();
		createCharacters();

		fullBlack = new FlxSprite().makeGraphic(1920, 1080, 0xFF000000);
		fullBlack.alpha = 0.00001;
		add(fullBlack);
		
		// Handle flashing state check
		handleFlashingState();
	}

	private function initializeBasics():Void 
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		
		// Load mods that change menu music and bg
		WeekData.loadTheFirstEnabledMod();

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		super.create();

		// Load save data and preferences
		FlxG.save.bind('doors', CoolUtil.getSavePath());
		ClientPrefs.loadPrefs();
		ClientPrefs.transferToNewVersion();
		Highscore.load();
		Lang.start();
		AwardsManager.loadAchievements();
		ModifierManager.init();
		
		// Preload music
		Paths.music("SillyPause");
		Paths.music("freakyMenu");
		Paths.music("freakyMenuLoop");
		
		// Load game data
		DoorsUtil.loadAllData();
	}

	private function checkForUpdates():Void 
	{
		if(!initialized && FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
		}
		
		persistentUpdate = true;
		persistentDraw = true;
		
		// Verify required assets exist
		if(Paths.image("gravy", "preload") == null){
			throw("You have deleted the gravy. Die.");
		}
	}

	private function setupCamera():Void 
	{
		camGame = new FlxCamera();
		camFollowPos = new FlxObject(1293, 5444, 1, 1);
		realCamFollowPos = new FlxObject(1293, 5444, 1, 1);
		camGame.follow(realCamFollowPos, LOCKON, 0.95);
		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		camGame.zoom = (1280/1920) * 0.9;
		camGame.focusOn(realCamFollowPos.getPosition());
	}

	private function handleFlashingState():Void 
	{
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			MusicBeatState.switchState(new FlashingState());
		} else {
			#if desktop
			if (!DiscordClient.isInitialized)
			{
				DiscordClient.initialize();
				Application.current.onExit.add(function(exitCode) {
					DiscordClient.shutdown();
				});
			}
			#end

			startIntro();
		}
	}

	function startIntro()
	{
		if (!initialized)
		{
			MenuSongManager.changeMusic("startJingle", 1, 95);
		}

		persistentUpdate = true;

		if (initialized)
			skipIntro(true);
		else
			initialized = true;
	}
	private function createBackground():Void 
	{
		var path:String = 'titleState/parallaxLayers';
		
		// Create background layers with different scroll factors
		var layers = [
			{name: 'backgroundTop', scrollFactor: {x: 1.0, y: 1.0}, behindLogo:true, xTween: false, xOffset: 0},
			{name: 'moon', scrollFactor: {x: 1.0, y: 0.4}, behindLogo:true, xTween: false, xOffset: 0},
			{name: 'cloud3', scrollFactor: {x: 1.0, y: 0.6}, behindLogo:true, xTween: true, xOffset: 15},
			{name: 'cloud2', scrollFactor: {x: 1.0, y: 0.75}, behindLogo:true, xTween: true, xOffset: 20},
			{name: 'hotel', scrollFactor: {x: 1.0, y: 1}, behindLogo:false, xTween: false, xOffset: 0},
			{name: 'cloud1', scrollFactor: {x: 1.0, y: 0.9}, behindLogo:false, xTween: true, xOffset: 25},
			{name: 'cloud0', scrollFactor: {x: 1.0, y: 0.95}, behindLogo:false, xTween: true, xOffset: 30},
		];
		
		for (layer in layers) {
			if(!layer.behindLogo) continue;
			var sprite = new FlxSprite(0, 0).loadGraphic(Paths.image('${path}/${layer.name}'));
			sprite.antialiasing = ClientPrefs.globalAntialiasing;
			sprite.scrollFactor.set(layer.scrollFactor.x, layer.scrollFactor.y);
			add(sprite);
			
			// Add x-axis pingpong tween if specified
			if (layer.xTween) {
				FlxTween.tween(sprite, {x: sprite.x + layer.xOffset}, 2.5 + (Math.random() * 1.5), {
					type: PINGPONG, 
					ease: FlxEase.sineInOut
				});
			}
		}
		
		var wheel = new FlxSprite(1641, 57).loadGraphic(Paths.image('wheel'));
		wheel.setGraphicSize(536, 524);
		wheel.updateHitbox();
		wheel.antialiasing = ClientPrefs.globalAntialiasing;
		wheel.scrollFactor.set(1, 0.4);
		add(wheel);
		FlxTween.tween(wheel, {angle: 360}, 14, {type: LOOPING});
		
		var logoBl = new FlxSprite(1706, 122);
		logoBl.frames = Paths.getSparrowAtlas('fnf_doors_logo_animated');
		logoBl.antialiasing = ClientPrefs.globalAntialiasing;
		logoBl.setGraphicSize(405, 358);
		logoBl.updateHitbox();
		logoBl.scrollFactor.set(1, 0.4);
		add(logoBl);
		FlxTween.tween(logoBl, {y: logoBl.y + 40}, 2, {type: PINGPONG, ease: FlxEase.smootherStepInOut});
		
		for (layer in layers) {
			if(layer.behindLogo) continue;
			var sprite = new FlxSprite(0, 0).loadGraphic(Paths.image('${path}/${layer.name}'));
			sprite.antialiasing = ClientPrefs.globalAntialiasing;
			sprite.scrollFactor.set(layer.scrollFactor.x, layer.scrollFactor.y);
			add(sprite);
			
			// Add x-axis pingpong tween if specified
			if (layer.xTween) {
				FlxTween.tween(sprite, {x: sprite.x + layer.xOffset}, 2.5 + (Math.random() * 1.5), {
					type: PINGPONG, 
					ease: FlxEase.sineInOut
				});
			}
		}
		
		var ocean = new FlxSprite(0, 0).loadGraphic(Paths.image('${path}/ocean'));
		ocean.antialiasing = ClientPrefs.globalAntialiasing;
		ocean.scrollFactor.set(1.0, 1.0);
		add(ocean);

		var stairs = new FlxSprite(0, 0).loadGraphic(Paths.image('${path}/stairs'));
		stairs.antialiasing = ClientPrefs.globalAntialiasing;
		stairs.scrollFactor.set(1, 1);
		add(stairs);
	}

	private function createLogos():Void 
	{
		// GlassHat Logo
		glasshatLogo = new FlxSprite(2466, 3585).loadGraphic(Paths.image("titleState/glasshat"));
		glasshatLogo.blend = BlendMode.ADD;
		glasshatLogo.antialiasing = ClientPrefs.globalAntialiasing;
		add(glasshatLogo);

		glasshatLogoTxt = new FlxText(1784, 4429, 1920, Lang.getText("glasshatTxt", "states/title"));
		glasshatLogoTxt.setFormat(FONT, 96, 0xFFFFFFFF, CENTER, 0xFF452D25);
		glasshatLogoTxt.antialiasing = ClientPrefs.globalAntialiasing;
		add(glasshatLogoTxt);

		// HaxeFlixel Logo
		haxeflixelLogo = new FlxSprite(933, 5003).loadGraphic(Paths.image("titleState/haxeflixel"));
		haxeflixelLogo.antialiasing = ClientPrefs.globalAntialiasing;
		add(haxeflixelLogo);

		haxeflixelLogoTxt = new FlxText(333, 5723, 1920, Lang.getText("haxeflixelTxt", "states/title"));
		haxeflixelLogoTxt.setFormat(FONT, 128, 0xFFFFFFFF, CENTER, 0xFF452D25);
		haxeflixelLogoTxt.antialiasing = ClientPrefs.globalAntialiasing;
		add(haxeflixelLogoTxt);

		// Vinyl Section
		lilVinyl = new PauseVinyl(-244, 2332, FlxG.random.getObject(["rush", "screech", "seek", "figure", "eyes", "ambush"]), 1280, 1280);
		lilVinyl.rotationSpeed = 60;
		add(lilVinyl);

		lilVinylTxt = new FlxText(1061, 2592, 0, Lang.getText("love", "states/title"));
		lilVinylTxt.setFormat(FONT, 128, 0xFFFFFFFF, CENTER, 0xFF452D25);
		lilVinylTxt.antialiasing = ClientPrefs.globalAntialiasing;
		add(lilVinylTxt);
	}

	private function createCharacters():Void 
	{
		bf = new FlxSprite(1169, 1900);
		bf.frames = Paths.getSparrowAtlas("titleState/bf");
		bf.animation.addByPrefix("idle", "bf", 24, true);
		bf.animation.play("idle");
		bf.antialiasing = ClientPrefs.globalAntialiasing;
		bf.scale.set(1.6, 1.6);
		add(bf);

		gf = new FlxSprite(2245, 1900);
		gf.frames = Paths.getSparrowAtlas("titleState/gf");
		gf.animation.addByPrefix("idle", "gf", 24, true);
		gf.animation.play("idle");
		gf.antialiasing = ClientPrefs.globalAntialiasing;
		gf.scale.set(1.6, 1.6);
		add(gf);
	}

	override function update(elapsed:Float)
	{
		// Update conductor position
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		
		// Handle camera movement with mouse
		updateCameraPosition(elapsed);
		
		// Check for enter key press
		if (initialized && (FlxG.keys.justPressed.ENTER || controls.ACCEPT))
		{
			exitState();
			pressedExitState = true;
		}

		super.update(elapsed);
	}

	private function updateCameraPosition(elapsed:Float):Void 
	{
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 4, 0, 1);
		realCamFollowPos.setPosition(
			FlxMath.lerp(realCamFollowPos.x, FlxG.mouse.getScreenPosition().x / 20 + camFollowPos.x - 32, lerpVal), 
			FlxMath.lerp(realCamFollowPos.y, FlxG.mouse.getScreenPosition().y / 16 + camFollowPos.y - 22.5, lerpVal)
		);
	}

	override function stepHit()
	{
		super.stepHit();
		
		if(!closedState) {
			handleIntroSequence();
		}
	}

	private function handleIntroSequence():Void 
	{
		switch (sickSteps)
		{
			case 0:
				setupInitialPositions();
				
				// Move HaxeFlixel logo
				FlxTween.tween(haxeflixelLogo, {y:5003, alpha: 1}, Conductor.stepCrochet / 1000 * 4, {ease: FlxEase.smoothStepInOut});
				FlxTween.tween(haxeflixelLogoTxt, {y:5723, alpha: 1}, Conductor.stepCrochet / 1000 * 4, {ease: FlxEase.smoothStepInOut});
				
			case 8:
				// Move camera to HaxeFlixel logo
				FlxTween.tween(camFollowPos, {x:2744, y:4094}, Conductor.stepCrochet / 1000 * 8, {ease: FlxEase.smoothStepInOut});
				
			case 16:
				// Show GlassHat logo
				FlxTween.tween(glasshatLogo, {y:3672, alpha: 1}, Conductor.stepCrochet / 1000 * 4, {ease: FlxEase.smoothStepInOut});
				FlxTween.tween(glasshatLogoTxt, {y:4429, alpha: 1}, Conductor.stepCrochet / 1000 * 4, {ease: FlxEase.smoothStepInOut});
				
			case 24:
				// Move camera to GlassHat logo
				FlxTween.tween(camFollowPos, {x:1356, y:2972}, Conductor.stepCrochet / 1000 * 8, {ease: FlxEase.smoothStepInOut});
				
			case 32:
				// Show vinyl
				FlxTween.tween(lilVinyl, {x:-244, alpha: 1, rotationSpeed: 60}, Conductor.stepCrochet / 1000 * 4, {ease: FlxEase.smoothStepInOut});
				FlxTween.tween(lilVinylTxt, {x:1061, alpha: 1}, Conductor.stepCrochet / 1000 * 4, {ease: FlxEase.smoothStepInOut});
				
			case 40:
				// Move camera to characters
				FlxTween.tween(camFollowPos, {x:1920, y:1744}, Conductor.stepCrochet / 1000 * 8, {ease: FlxEase.smoothStepInOut});
				
			case 48:
				// Show characters 
				bf.alpha = 1;
				gf.alpha = 1;
				FlxTween.tween(bf, {x:1169}, Conductor.stepCrochet / 1000 * 4, {ease: FlxEase.cubeInOut});
				FlxTween.tween(gf, {x:2245}, Conductor.stepCrochet / 1000 * 4, {ease: FlxEase.cubeInOut});
				
			case 56:
				// Final camera position for menu
				FlxTween.tween(camFollowPos, {x:1920, y:520}, Conductor.stepCrochet / 1000 * 8, {ease: FlxEase.smoothStepInOut});
				FlxTween.tween(camGame, {zoom: 0.9}, Conductor.stepCrochet / 1000 * 8, {ease: FlxEase.smoothStepInOut});
				
			case 66:
				skipIntro();
		}
		sickSteps++;
	}

	private function setupInitialPositions():Void 
	{
		// Set initial positions for all elements
		haxeflixelLogo.y = 4183;
		haxeflixelLogo.alpha = 0;
		haxeflixelLogoTxt.y = 5984;
		haxeflixelLogoTxt.alpha = 0;
		
		glasshatLogo.y = 2660;
		glasshatLogo.alpha = 0;
		glasshatLogoTxt.y = 4634;
		glasshatLogoTxt.alpha = 0;
		
		lilVinyl.x = -852;
		lilVinyl.alpha = 0;
		lilVinyl.rotationSpeed = 0;
		lilVinylTxt.x = 2450;
		lilVinylTxt.alpha = 0;
		
		bf.alpha = 0;
		bf.x = 0;
		gf.alpha = 0;
		gf.x = 3572;
	}

	function skipIntro(?skip:Bool = false):Void
	{
		if (!skippedIntro)
		{
			MenuSongManager.crossfade("freakyMenu", 1, 102, true);
			
			// Position camera at final position
			if(skip){
				camFollowPos.setPosition(1920, 520);
				realCamFollowPos.setPosition(1920, 520);
				camGame.focusOn(realCamFollowPos.getPosition());
				camGame.snapToTarget();
				camGame.zoom = 0.9;
			}
			skippedIntro = true;
			
			// Check for updates and show update screen if needed
			if (report != null && report.newUpdate) {
				FlxG.switchState(new backend.updating.UpdateAvailableScreen(report));
			}
			closedState = true;
		}
	}

	var pressedExitState:Bool = false;
	function exitState() {
		if(pressedExitState) return;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		FlxG.cameras.list[FlxG.cameras.list.length - 1].fade(0xFF000000, 0.9, false, function(){
			fullBlack.screenCenter();
			fullBlack.alpha = 1;
		}, false);
		FlxTween.tween(camFollowPos, {x:1920, y:520}, 0.5, {ease: FlxEase.smoothStepInOut});
		FlxTween.tween(camGame, {zoom: 3}, 1.0, {ease: FlxEase.backIn, onComplete: function(twn){
			MusicBeatState.switchState(new MainMenuState());
		}});
		MenuSongManager.playSound("confirmMenu", 1.0);
		closedState = true;
		skipIntro(false);
	}
}
