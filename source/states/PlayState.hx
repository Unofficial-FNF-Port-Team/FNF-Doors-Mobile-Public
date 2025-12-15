package states;

import backend.metadata.SongMetadata;
import flixel.sound.filters.FlxFilteredSound;
import objects.NewCredit.CreditTemplate;
import online.Leaderboards;
import backend.BaseStage.Countdown;
import backend.MechanicsManager;
import shaders.*;
import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.util.FlxAxes;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxTextNew as FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import objects.Note;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import AwardsManager;
import StageData;
import FunkinLua;
import objects.ColorBar;
import DoorsUtil;

#if !flash 
import openfl.filters.ShaderFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

//Modcharting stuff whaaaaaaat
import modcharting.ModchartFuncs;
import modcharting.NoteMovement;
import modcharting.PlayfieldRenderer;

class PlayState extends MusicBeatState
{
	var noteRows:Array<Array<Array<Note>>> = [[],[]];

	public static final STRUM_X = 42;
	public static final STRUM_X_MIDDLESCROLL = -278;

	public static var currentStageObject:Dynamic;
	public static var gameStages:Map<String,FunkyFunct> = new Map<String,FunkyFunct>();
	public static var gameParameters:Map<String,Dynamic> = new Map<String,Dynamic>();
	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxFilteredSound> = new Map<String, FlxFilteredSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var momMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var MOM_X:Float = 100;
	public var MOM_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var ADDITIONALPOS_X:Array<Float> = [];
	public var ADDITIONALPOS_Y:Array<Float> = [];
	public var songCharacterGroups:Array<FlxSpriteGroup> = [];
	public var songCharacters:Array<Dynamic> = [];

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var momGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Null<Int> = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxFilteredSound;

	public var dadGhostTween:FlxTween = null;
	public var bfGhostTween:FlxTween = null;
	public var gfGhostTween:FlxTween = null;
	public var momGhostTween:FlxTween = null;

	public var momGhost:FlxSprite = null;
	public var dadGhost:FlxSprite = null;
	public var bfGhost:FlxSprite = null;
	public var gfGhost:FlxSprite = null;

	public var dad:Character = null;
	public var gf:Character = null;
	public var mom:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpHoldSplashes:FlxTypedGroup<SustainSplash>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camX = 0;
	public var camY = 0;
	public var bfcamX = 0;
	public var bfcamY = 0;
	public var offsetX = 0;
	public var offsetY = 0;
	public var bfoffsetX = 0;
	public var bfoffsetY = 0;
	public var camZooming:Bool = true;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var camEventZooming:Bool = false;
	private var zoomTween:FlxTween;
	private var curSong:String = "";

	public var currentlyMovingCamera:Bool = false;
	public var cameraFocusedOnChar:Bool = false;
	public var cameraFocusedOn:Int = 0;
	public var eventCameraPoint:FlxPoint;
	public var cameraEventOffset:FlxPoint;
	public var camfollowEnabled = true;

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var lerpedHealth:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:ColorBar;
	public var aegisOverlay:ColorBar;
	public var theHealthBarAimedPosY:Float;
	public var theRatingsAimedPosY:Float;
	public var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:ColorBar;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	public var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public static var healthGain:Float = 1;
	public static var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	//testing new input system for sustains
	public var guitarHeroSustains:Bool = true;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var iconP3:HealthIcon;
	public var iconP4:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camBackground:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	public var cameraChangeInstant:Bool = false;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	public var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var cameraOffsets:Array<Array<Float>> = [];

	public var defaultCamZoom:Float = 1.05;
	public var CAMZOOMCONST:Float = 1.05;
	public var CAMZOOMCONST2:Float = 1.05;

	public var defaultCamAngle:Float = 0;

	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;
	
	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	public var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	var largeIcon:String = "";
	var smallIcon:String = "";
	#end

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<String>;

	public var precacheList:Map<String, String> = new Map<String, String>();

	// Character 2
	var opponent2sing:Bool = false;
	var bothOpponentsSing:Bool = false;

	var songCreditBox:NewCredit;
	var manuallySpawnCredits:Bool = false;

	// Halt stuff
	public var enableHaltLerp:Bool = true;
	public var unlockOnTheEdge:Bool = false;

	// Seek stuff
	var toggleSprint:Array<Int> = [384];
	var notRunning:Bool = true;
	
	// Warning image stuff
	public var allowCountdown:Bool = true;
	var warningConfirmed:Int = 1;
	var maxWarning:Int = 1;
	var warningImage:FlxSprite;
	
	// ITEMS
	public var itemInventory:ItemInventory;
	public var vitaVignette:FlxSprite;
	var itemBoxTargetX:Float = FlxG.width * 0.01;

	// Figure
	var taikoActive:Bool = false;
	public var taikoSpot:FlxSprite;
	var taikoVignette:FlxSprite;
	var defaultx0:Float;
	var defaultx1:Float;
	var defaulty0:Float;
	var defaulty1:Float;

	// Glitch
	var glitchChroma:RGBGlitchShader;
	var glitchCharShader:GlitchChar;
	var bgGlitchGlitch:GlitchEden;
	public var shaderUpdates:Array<Float->Void> = [];
	var glitchTimer:Bool = false;
	var glitchTimerTimer:Float = Conductor.crochet/1000;
	var fakeHealth:Float = 1;
	var timeResetGlitch:Float = Conductor.crochet/1000;

	var dripBackground:DripBGShader;
	
	var bargainAlphaState:Bool = true; //True = opaque, False = transparent

	var chromaticEvent:ChromaticAberration;
	var hasChromaticAberration:Bool = false;
	var chromaticPoint:FlxPoint;
	
	var pixelEvent:MosaicShader;
	var scanlineEvent:ScanlineShader;
	var hasPixel:Bool = false;
	var pixelPoint:FlxPoint;
	var scanlinePoint:FlxPoint;

	public var camGameFilters:Array<BitmapFilter> = [];
	public var camBackgroundFilters:Array<BitmapFilter> = [];
	public var camHUDFilters:Array<BitmapFilter> = [];
	public var camOtherFilters:Array<BitmapFilter> = [];

	var hasVignette:Bool = true;
	
	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private final iPissedOnTheMoon:Array<String> = ["halt", "onward", "onward-hell", "stare", "always-watching", "always-watching-hell","stare-hell", "watch-out", "eye-spy", "eye-spy-hell", "left-behind-hell"];
	public static var isLeftSong:Bool = true;

	//stop timers and tweens
	var stopTweens = new Array<FlxTween>();
	var stopTimers = new Array<FlxTimer>();
	//yeah

	//fake timer
	final hasFakeTimerArray:Array<String> = ['left-behind', 'invader', '404', 'left-behind-hell'];
	private var hasFakeTimer:Bool;
	public var songLengthFake:Float;
	//yeah

	public var vignetteShader:VignetteShader;

	public var isBadApple:Bool = false;
	var badAppleWhite:FlxSprite;
	var topCinematicBar:FlxSprite;
	var bottomCinematicBar:FlxSprite;

	//tibu's sick ass black bars
	var topBarsALT:FlxSprite; //THESE ONES AREN'T THE ONES WITH TWEEN BUT NORMAL TWEEN YEAHHHH
	var bottomBarsALT:FlxSprite; //THIS TOO
	public var camBars:FlxCamera;

	//pause lag reduced maybe
	var precacheImagePause:FlxSprite;

	var moneyIndicator:MoneyIndicator;
	var knobIndicator:MoneyIndicator;

	//mechanics thing idfk
	public var activeMechanics:Map<String, MechanicsManager> = [];

	//left side idk
	public var leftSideShit = false;

	//bf pop off woah
	var bfGhostPopOff = false;

	//lyrics for small spider
	var lyrics:Array<String> = [];
	//1 = current one, 2 = 0.5 alpha, 3 = 0.25 alpha, 4 disappears and destroyed
	var lyricsFlxText:Array<FlxText> = []; 
	var curLyricsIndex:Int = 0;

	//combo position since i'm putting it in camGame and not all stages are cool
	public var comboPosition:Array<Float> = [-420, 69];
	public var comboScale:Float = 0.7;
	
	//lighting items
	public var lighterBall:FlxSprite;
	var lighterTween:FlxTween;
	var flashBall:FlxSprite;
	private var lighterCounter:Int = 0;

	//check DoorsUtil to see where it's used!
	public var activeModifiers:Array<Int> = [];

	//Is true if you are in a greenhouse stage, is set inside the stages, but used here.
	public var isGreenhouseStage:Bool = false;

	/* Spawn animations
	* IF true, it doesn't spawn the black screen before the countdown ends, and instead does the spawn animation.
	* Otherwise, countdown is obscured.
	*/
	public var hasSpawnAnimation:Bool = false;

	private var _prevHealth:Float;
	function set_health(v:Float) {
		health = v;
		/*if(v >= _prevHealth || v >= 1.97) { 
			_prevHealth = health;
			return health;
		}
		var char:Character = leftSideShit ? dad : boyfriend;
		FlxTween.cancelTweensOf(healthBar.frontColorTransform);
		healthBar.frontColorTransform.color = FlxColor.fromRGB(255, 0, 0);
		FlxTween.tween(
			healthBar.frontColorTransform, 
			{
				redOffset: char.healthColorArray[0],
				greenOffset: char.healthColorArray[1],
				blueOffset: char.healthColorArray[2]
			},
			Conductor.crochet/1000 * 4, 
			{ease: FlxEase.circOut}
		);
		_prevHealth = health;*/
		return health;
	}

	//Functions modified and/or copied from FunkinLua

	public function getFlxEaseByString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	function cancelTween(tag:String) {
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}

	function setTweenActive(tag:String, ?b:Bool = true) {
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).active = b;
		}
	}

	function resetSpriteTag(tag:String) {
		if(!PlayState.instance.modchartSprites.exists(tag)) {
			return;
		}

		var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartSprites.remove(tag);
	}
	public function scaleThis(sprite:ModchartSprite, x:Float, y:Float):Void{
		sprite.scale.set(x,y);
		sprite.updateHitbox();
	}

	public function pushModchartSprite(tag:String, leSprite:ModchartSprite):Void {
		tag = tag.replace('.', '');
		resetSpriteTag(tag);
		PlayState.instance.modchartSprites.set(tag, leSprite);
		leSprite.active = true;
	}

	public function getModchartSprite(tag:String):ModchartSprite {
		return PlayState.instance.modchartSprites.get(tag);
	}

	public function charListType(typeName:String):Int{
		var charType:Int = 0;
		switch(typeName.toLowerCase()) {
			case 'dad': charType = 1;
			case 'gf' | 'girlfriend': charType = 2;
		}
		return charType;
	}

	function cameraFromString(cam:String):FlxCamera {
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}
		return PlayState.instance.camGame;
	}

	function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}

	public function getVignetteState(songName:String):Bool{
		if(!ClientPrefs.data.shaders) return false;

		songName = songName.toLowerCase();
		switch(songName){
			/*case 'encounter' | 'ready-or-not' | 'delve' | 'found-you':
				return false;
			case 'not-a-sound'  | "not-a-sound-hell" | 'tranquil' | 'imperceptible' | 'hyperacusis' | 'depths-below':
				return true;*/
			case 'onward' | 'halt' | 'onward-hell':
				return false;
			case 'angry-spider' | 'jumpscare' | 'itzy-bitzy' | 'kumo' | 'drawer':
				return false;
			case 'guidance':
				return false;
		}

		return true;
	}


	public function setStrumPositionsFromName(songName:String):Int
	{
		songName = songName.toLowerCase();
		switch (songName)
		{
			case 'encounter' | 'ready-or-not' | 'delve' | 'found-you' | 'found-you-hell':
				return -3000;
			case 'not-a-sound'  | "not-a-sound-hell" | 'tranquil' | 'imperceptible' | 'hyperacusis' | 'depths-below':
				return -3000;
			case 'halt' | 'onward' | 'onward-hell':
				return -3000;
			case 'starting-point':
				return -3000;
			default:
				return 0;
		}	
		return 0;
	}

	public function playAnim(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
	{
		//I couldn't be bothered to rewrite this I'm sorry lol
		if(PlayState.instance.getLuaObject(obj, false) != null) {
			var luaObj:FlxSprite = PlayState.instance.getLuaObject(obj,false);
			if(luaObj.animation.getByName(name) != null)
			{
				luaObj.animation.play(name, forced, reverse, startFrame);
				if(Std.isOfType(luaObj, ModchartSprite))
				{
					//convert luaObj to ModchartSprite
					var obj:Dynamic = luaObj;
					var luaObj:ModchartSprite = obj;

					var daOffset = luaObj.animOffsets.get(name);
					if (luaObj.animOffsets.exists(name))
					{
						luaObj.offset.set(daOffset[0], daOffset[1]);
					}
					else
						luaObj.offset.set(0, 0);
				}
			}
			return true;
		}

		var spr:FlxSprite = Reflect.getProperty(PlayState.instance, obj);
		if(spr != null) {
			if(spr.animation.getByName(name) != null)
			{
				if(Std.isOfType(spr, Character))
				{
					//convert spr to Character
					var obj:Dynamic = spr;
					var spr:Character = obj;
					spr.playAnim(name, forced, reverse, startFrame);
				}
				else
					spr.animation.play(name, forced, reverse, startFrame);
			}
			return true;
		}
		return false;
	}

	public static function preloadEverything(){
		Paths.clearStoredMemory();

		var theMap:Map<String, Array<String>> = [
			"images" => [],
			"sounds" => [],
			"music" => [],
			"instogg" => []
		];

		try{
			var map = getConstantPreloadStuff();
			for(a in map.get("images")){
				theMap.get("images").push(a);
			}
			for(s in map.get("sounds")){
				theMap.get("sounds").push(s);
			}
			for(m in map.get("music")){
				theMap.get("music").push(m);
			}

				for(a in getCharacterPreloadShit()){
					theMap.get("images").push(a);
				}
				if(isStoryMode || SONG.freeplayStage == null){
					for(a in getStagePreloadShit(SONG.stage).get("images")){
						theMap.get("images").push(a);
					}
				} else {
					trace(SONG.freeplayStage);
					if(SONG.freeplayStage.contains("-alt")) {
						var altID = Std.parseInt(SONG.freeplayStage.substr(SONG.freeplayStage.indexOf("-alt") + 4, 999));
						for(a in getStagePreloadShit(SONG.freeplayStage.replace('-alt${altID}', ""), altID).get("images")){
							theMap.get("images").push(a);
						}
					} else {
						for(a in getStagePreloadShit(SONG.freeplayStage, 0).get("images")){
							theMap.get("images").push(a);
						}
					}
				}
			theMap.get("instogg").push(PlayState.SONG.song);

		} catch(e){trace(e);}
		
		return theMap;
	}

	public static function getConstantPreloadStuff(){ //returns stuff that's always preloaded in playstate
		//images
		var imagesToLoad:Array<String> = [
			'timeBarInside',
			'healthBars/healthbarMask',
			'storyItems/inventory_box2',
			'ready', 'set', 'go',
			"sick", "good", "bad", "shit",
			"combo",
			"storyItems/white_vignette",
			"alphabet"
		];
		for(i in 0...10){
			imagesToLoad.push("num" + i);
		}

		//sound
		var soundsToLoad:Array<String> = [
			'intro3', 'intro2', 'intro1', 
			'introGo', 'HeartbeatMessup', 'hitsound',
			'missnote1', 'missnote2', 'missnote3',
		];

		//music
		var musicToLoad:Array<String> = [
			"SillyPause"
		];

		var theMap:Map<String, Array<String>> = [
			"images" => imagesToLoad,
			"sounds" => soundsToLoad,
			"music" => musicToLoad
		];
		return theMap;
	}

	public static function getCharacterPreloadShit(){
		var imagesToLoad:Array<String> = [];
		var chars = [];
		if(SONG == null){}
		else if(SONG.characters == null){
			chars = [SONG.player1, SONG.player2, SONG.gfVersion, SONG.player3];
		} else chars = SONG.characters;

		for(c in chars){
			imagesToLoad.push(Character.getCharacterPath(c));
		}
		return imagesToLoad;
	}

	public static var isTestingGreenhouse:Bool = false;

	// -1 = unknown, 0 = no alt, 1+ = alt ID
	public static function getStagePreloadShit(stageName:String, ?altID:Int = 0){
		var map:Null<Map<String, Array<String>>> = switch(stageName.toLowerCase()){
			case 'gangsta': states.stages.Gangsta.getPreloadShit();
			case 'bargainbg': states.stages.BargainBG.getPreloadShit();
			case 'jack': states.stages.Jack.getPreloadShit();
			case 'glitch': states.stages.Glitch.getPreloadShit();
			case 'abuse': states.stages.Boykisser.getPreloadShit();
			case 'abush': 
				states.stages.Ambush.altID = FlxG.random.int(0, 2);
				states.stages.Ambush.getPreloadShit();
			case 'startpoint': states.stages.StartingPoint.getPreloadShit();
			case 'bad': states.stages.Bad.getPreloadShit();
			case 'mutant': states.stages.Mutant.getPreloadShit();
			case 'mg': states.stages.MG.getPreloadShit();
			case 'rush': 
				states.stages.Rush.altID = FlxG.random.int(0, 3);
				if(isStoryMode){
					if(DoorsUtil.isGreenhouse){
						states.stages.RushGreenhouse.getPreloadShit();
					} else {
						states.stages.Rush.getPreloadShit();
					}
				} else {
					states.stages.Rush.getPreloadShit();
				}
			case 'rush-greenhouse': states.stages.RushGreenhouse.getPreloadShit();
			case 'eyes': 
				states.stages.Eyes.altID = FlxG.random.int(0, 3);
				if(isStoryMode){
					if(DoorsUtil.isGreenhouse){
						states.stages.EyesGreenhouse.getPreloadShit();
					} else {
						states.stages.Eyes.getPreloadShit();
					}
				} else {
					states.stages.Eyes.getPreloadShit();
				}
			case 'eyes-greenhouse': states.stages.EyesGreenhouse.getPreloadShit();
			case 'lobby': states.stages.Lobby.getPreloadShit();
			case 'figureend': states.stages.Figure100.getPreloadShit();
			case 'f-library': states.stages.Library.getPreloadShit();
			case 'timothy': 
				states.stages.Timothy.altID = FlxG.random.int(0, 1);
				states.stages.Timothy.getPreloadShit();
			case 'timothy_joke': states.stages.TimothyJoke.getPreloadShit();
			case 'elevator': states.stages.Elevator.getPreloadShit();
			case 'corridor': states.stages.SeekCorridor.getPreloadShit();
			case 'halt': states.stages.Halt.getPreloadShit();
			case 'screech': 
				states.stages.Screech.altID = FlxG.random.int(0, 3);
				if(isStoryMode){
					if(DoorsUtil.isGreenhouse){
						states.stages.ScreechGreenhouse.getPreloadShit();
					} else {
						states.stages.Screech.getPreloadShit();
					}
				} else {
					states.stages.Screech.getPreloadShit();
				}
			case 'screech-greenhouse': states.stages.ScreechGreenhouse.getPreloadShit();
			case 'lilguys': states.stages.LilGuys.getPreloadShit();
			case 'sencounter': states.stages.Sencounter.getPreloadShit();
			case 'jeff-kill': states.stages.JeffKill.getPreloadShit();
			default : states.stages.Stage.getPreloadShit();
		}

		if(map == null) map = ["images" => []];
		return map;
	}

	override public function create()
	{
		DoorsUtil.loadRunData();
		if(!isStoryMode){
			for(mod in ModifierManager.defaultModifiers){
				DoorsUtil.modifierActive(mod.ID);
			}
		}
		
		ratingStuff = [
			[Lang.getText("yousuck", "generalshit/ratings"), 0.2], //From 0% to 19%
			[Lang.getText("shit", "generalshit/ratings"), 0.4], //From 20% to 39%
			[Lang.getText("bad", "generalshit/ratings"), 0.5], //From 40% to 49%
			[Lang.getText("bruh", "generalshit/ratings"), 0.6], //From 50% to 59%
			[Lang.getText("meh", "generalshit/ratings"), 0.69], //From 60% to 68%
			[Lang.getText("nice", "generalshit/ratings"), 0.7], //69%
			[Lang.getText("good", "generalshit/ratings"), 0.8], //From 70% to 79%
			[Lang.getText("great", "generalshit/ratings"), 0.9], //From 80% to 89%
			[Lang.getText("sick", "generalshit/ratings"), 1], //From 90% to 99%
			[Lang.getText("perfect", "generalshit/ratings"), 1] //The value on this one isn't used actually, since Perfect is always "1"
		];

		instance = this;
		
		#if debug
		debugKeysChart = ClientPrefs.keyBinds.get('debug_1').copy();
		debugKeysCharacter = ClientPrefs.keyBinds.get('debug_2').copy();
		#end
		playbackRate = 1;

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right',
			'heartbeat_left',
			'heartbeat_right'
		];

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = 1;
		healthLoss = 1;
		instakillOnMiss = DoorsUtil.modifierActive(15);
		cpuControlled = DoorsUtil.modifierActive(54);
		practiceMode = DoorsUtil.modifierActive(55) || cpuControlled;

		guitarHeroSustains = true;
		camGame = new FlxCamera();
		camBars = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camBars.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camBars, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpHoldSplashes = new FlxTypedGroup<SustainSplash>();
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		//CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode";
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end 

		var songName:String = Paths.formatToSongPath(SONG.song);
		songName = songName.toLowerCase();

		#if desktop
		var songMetadata = new SongMetadata(SONG.song.toLowerCase().replace(' ', '-'));
		largeIcon = songMetadata.ostArtPath.toLowerCase();
		smallIcon = "";
		if(isStoryMode) {
			var rank = DoorsUtil.calculateRunRank();
			smallIcon = switch(rank) {
				case P: "rank_p";
				case S: "rank_s";
				case A: "rank_a";
				case B: "rank_b";
				case C: "rank_c";
				case D: "rank_d";
				case F: "rank_f";
				default: "rank_a";
			}
		}
		#end

		if(isStoryMode || SONG.freeplayStage == null){
			curStage = SONG.stage;
		} 
		else {
			if(SONG.freeplayStage.contains("-alt")){
				curStage = SONG.freeplayStage.replace(
					SONG.freeplayStage.substr(
						SONG.freeplayStage.indexOf("-alt"), 999
					), ""
				);
			} else {
				curStage = SONG.freeplayStage;
			}
		}
		
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(isStoryMode && DoorsUtil.isGreenhouse && StageData.getStageFile(curStage + "-greenhouse") != null)
			stageData = StageData.getStageFile(curStage + "-greenhouse");

		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				fullCharPositions: [[770, 100],[400, 130],[100, 100],[100, 100]],

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				secOpponent: [100, 100],
				hide_girlfriend: true,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		CAMZOOMCONST = stageData.defaultZoom;
		CAMZOOMCONST2 = stageData.defaultZoom;

		isPixelStage = stageData.isPixelStage;

		if(SONG.characters != null){
			if(stageData.fullCharPositions != null){
				BF_X = stageData.fullCharPositions[0][0];
				BF_Y = stageData.fullCharPositions[0][1];
				GF_X = stageData.fullCharPositions[1][0];
				GF_Y = stageData.fullCharPositions[1][1];
				DAD_X = stageData.fullCharPositions[2][0];
				DAD_Y = stageData.fullCharPositions[2][1];
				for(i in 3...stageData.fullCharPositions.length){
					ADDITIONALPOS_X.push(stageData.fullCharPositions[i][0]);
					ADDITIONALPOS_Y.push(stageData.fullCharPositions[i][1]);
				}
			} else {
				BF_X = stageData.boyfriend[0];
				BF_Y = stageData.boyfriend[1];
				GF_X = stageData.girlfriend[0];
				GF_Y = stageData.girlfriend[1];
				DAD_X = stageData.opponent[0];
				DAD_Y = stageData.opponent[1];
				if (stageData.secOpponent != null){
					ADDITIONALPOS_X.push(stageData.secOpponent[0]);
					ADDITIONALPOS_Y.push(stageData.secOpponent[1]);
				}
				if(SONG.characters.length > 3){
					for(i in 4...SONG.characters.length){
						ADDITIONALPOS_X.push(i * 200 - 800);
						ADDITIONALPOS_Y.push(i * 100 - 400);
					}
				}
			}
		} else {
			BF_X = stageData.boyfriend[0];
			BF_Y = stageData.boyfriend[1];
			GF_X = stageData.girlfriend[0];
			GF_Y = stageData.girlfriend[1];
			DAD_X = stageData.opponent[0];
			DAD_Y = stageData.opponent[1];
			if (stageData.secOpponent != null){
				MOM_X = stageData.secOpponent[0];
				MOM_Y = stageData.secOpponent[1];
			} else{
				MOM_X = 0;
				MOM_Y = -1000;
			}
		}

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		songCharacterGroups.push(boyfriendGroup);
		songCharacterGroups.push(gfGroup);
		songCharacterGroups.push(dadGroup);
		if(SONG.characters != null){
			for(i in 0...ADDITIONALPOS_X.length){
				songCharacterGroups.push(new FlxSpriteGroup(ADDITIONALPOS_X[i], ADDITIONALPOS_Y[i]));
			}
		}


		DoorsUtil.reloadMaxHealth();

		currentStageObject = null;
		switch (curStage.toLowerCase())
		{
			case 'a60': currentStageObject = new states.stages.A60();
			case 'gangsta': currentStageObject = new states.stages.Gangsta();
			case 'bargainbg': currentStageObject = new states.stages.BargainBG();
			case 'jack': currentStageObject = new states.stages.Jack();
			case 'glitch': currentStageObject = new states.stages.Glitch();
			case 'abuse': currentStageObject = new states.stages.Boykisser();
			case 'abush': currentStageObject = new states.stages.Ambush();
			case 'startpoint': currentStageObject = new states.stages.StartingPoint();
			case 'bad': currentStageObject = new states.stages.Bad();
			case 'mutant': currentStageObject = new states.stages.Mutant();
			case 'mg': currentStageObject = new states.stages.MG();
			case 'rush': 
				if((isStoryMode && DoorsUtil.isGreenhouse) || isTestingGreenhouse){
					currentStageObject = new states.stages.RushGreenhouse();
				} else {
					currentStageObject = new states.stages.Rush();
				}
			case 'rush-greenhouse': currentStageObject = new states.stages.RushGreenhouse();
			case 'eyes': 
				if((isStoryMode && DoorsUtil.isGreenhouse) || isTestingGreenhouse){
					currentStageObject = new states.stages.EyesGreenhouse();
				} else {
					currentStageObject = new states.stages.Eyes();
				}
			case 'eyes-greenhouse': currentStageObject = new states.stages.EyesGreenhouse();
			case 'lobby': currentStageObject = new states.stages.Lobby();
			case 'figureend': currentStageObject = new states.stages.Figure100();
			case 'f-library': currentStageObject = new states.stages.Library();
			case 'timothy': currentStageObject = new states.stages.Timothy();
			case 'timothy_joke': currentStageObject = new states.stages.TimothyJoke();
			case 'elevator': currentStageObject = new states.stages.Elevator();
			case 'corridor': currentStageObject = new states.stages.SeekCorridor();
			case 'halt': currentStageObject = new states.stages.Halt();
			case 'screech': 
				if((isStoryMode && DoorsUtil.isGreenhouse) || isTestingGreenhouse){
					currentStageObject = new states.stages.ScreechGreenhouse();
				} else {
					currentStageObject = new states.stages.Screech();
				}
			case 'screech-greenhouse': currentStageObject = new states.stages.ScreechGreenhouse();
			case 'lilguys': currentStageObject = new states.stages.LilGuys();
			case 'sencounter': currentStageObject = new states.stages.Sencounter();
			case 'jeff-kill': currentStageObject = new states.stages.JeffKill();
			case 'drip':
				if(ClientPrefs.data.shaders)
				{
					camBackground = new FlxCamera();
					camGame = new FlxCamera();
					camHUD = new FlxCamera();
					camOther = new FlxCamera();
	
					camGame.bgColor.alpha = 0;
					camHUD.bgColor.alpha = 0;
					camOther.bgColor.alpha = 0;
	
					FlxG.cameras.reset(camBackground);
					FlxG.cameras.add(camGame, true);
					FlxG.cameras.add(camHUD, false);
					FlxG.cameras.add(camOther, false);

					dripBackground = new DripBGShader();
					add(dripBackground);
					var filter:ShaderFilter = new ShaderFilter(dripBackground.shader);
					camBackground.setFilters([filter]);
				}
				else
				{
					var bg:FlxSprite = new FlxSprite(-800, -400).makeSolid(FlxG.width * 4, FlxG.height * 2, FlxColor.GRAY);
					add(bg);
				}
			case 'stage' | 'daddyissues': currentStageObject = new states.stages.Stage();
		}

		switch(SONG.characters[2].toLowerCase())
		{
			case 'seek':
				if(SONG.song.toLowerCase() != 'delve' && DoorsUtil.modifierActive(42))
					new states.mechanics.SeekRunningHealthDrain();
				else
					new states.mechanics.HealthDrain(1, 'seek');
				

			case 'figure' | 'figurebooks' | 'db-figure' | 'figure100':
				new states.mechanics.FigureBlurMechanic();

			case 'eyes':
				new states.mechanics.OvertimeHealthDrain('eyes');

			case 'halt':
				new states.mechanics.HaltMechanic();

			case 'screech' | 'screech_shaded':
				new states.mechanics.ScreechMechanic();
		}

		switch(SONG.song.toLowerCase())
		{
			case 'guidance' | 'starting-point':
				var noDed = new states.mechanics.NoDeath();
				if(SONG.song.toLowerCase() == "starting-point") noDed.skipOnDeath = true;

			case 'daddy-issues':
				new states.mechanics.healthGain.HealthGainSeek(1);

			case 'angry-spider':
				new states.mechanics.LeftSide();
		}

		if(isGreenhouseStage) new states.mechanics.SnareMechanic();
		else if(DoorsUtil.modifierActive(62)) {
			isGreenhouseStage = true;
			new states.mechanics.SnareMechanic();
		}

		if(DoorsUtil.modifierActive(47)) new states.mechanics.modifiers.SweetTooth();
		if(DoorsUtil.modifierActive(48)) new states.mechanics.modifiers.KillerInstinct();
		if(DoorsUtil.modifierActive(50)) new states.mechanics.modifiers.Corruption();
		if(DoorsUtil.modifierActive(52)) new states.mechanics.modifiers.JackShit();
		if(DoorsUtil.modifierActive(53)) new states.mechanics.modifiers.HideMechanic();
		if(DoorsUtil.modifierActive(58)) new states.mechanics.modifiers.Fading();
		if(DoorsUtil.modifierActive(59)) new states.mechanics.modifiers.Overdrive();
		if(DoorsUtil.modifierActive(60)) new states.mechanics.modifiers.TrueDarkness();
		
		
        var songMetadata:SongMetadata = new SongMetadata(PlayState.SONG.song.toLowerCase().replace(' ', '-'));
		if(songMetadata.deathMetadata.deathSpeaker == "GUIDING") new states.mechanics.GuidanceNotes();

		createBars(false);

		if(SONG.song.toLowerCase() == 'left-behind-hell' || isStoryMode ? false : DoorsUtil.modifierActive(49))
		{
			glitchTimer = true;
			if(!iPissedOnTheMoon.contains(SONG.song.toLowerCase()))
				iPissedOnTheMoon.push(SONG.song.toLowerCase());
		}

		CustomFadeTransition.nextCamera = camOther;

		hasVignette = getVignetteState(SONG.song);
		if(ClientPrefs.data.shaders)
		{
			//permanent shaders
			if(hasVignette)
			{
				vignetteShader = new VignetteShader();
				vignetteShader.darkness = 25.0;
				vignetteShader.extent = 0.25;
				var shaderFilter3:ShaderFilter = new ShaderFilter(vignetteShader.shader);
				camGameFilters.push(shaderFilter3);
				updateCameraFilters("camGame");
			}
		}
		
		if(!stageData.hide_girlfriend){
			add(gfGroup);
		}
		add(dadGroup);
		add(boyfriendGroup);

		if(songCharacterGroups.length > 3 && songCharacterGroups[3] != null){
			for(i in 3...songCharacterGroups.length){
				add(songCharacterGroups[i]);
			}
		}

		switch(curStage)
		{
			default:
				callStageFunctions("foregroundAdd", []);
		}

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			stageData.hide_girlfriend =  true;
			SONG.gfVersion = 'gf'; //Fix for the Chart Editor
		}

		if(SONG.characters != null){
			boyfriend = new Character(0, 0, SONG.characters[0], true);
			startCharacterPos(boyfriend);
			if(boyfriend.attachChar!=null){
				songCharacterGroups[0].add(boyfriend.attachChar);
			}
			songCharacterGroups[0].add(boyfriend);

			if(stageData.hide_girlfriend){
				gf = null;
			} else {
				gf = new Character(0, 0, SONG.characters[1]);
				startCharacterPos(gf);
				gf.scrollFactor.set(0.95, 0.95);
				if(gf.attachChar!=null){
					songCharacterGroups[1].add(gf.attachChar);
				}
				songCharacterGroups[1].add(gf);
			}

			dad = new Character(0, 0, SONG.characters[2]);
			startCharacterPos(dad, true);
			if(dad.attachChar!=null){
				songCharacterGroups[2].add(dad.attachChar);
			}
			songCharacterGroups[2].add(dad);

			songCharacters.push(boyfriend);
			songCharacters.push(gf);
			songCharacters.push(dad);
			if(SONG.characters.length > 3){
				for(i in 3...SONG.characters.length){
					var newChar = new Character(0, 0, SONG.characters[i]);
					startCharacterPos(newChar);
					if(newChar.attachChar!=null){
						songCharacterGroups[i].add(newChar.attachChar);
					}
					songCharacterGroups[i].add(newChar);
					songCharacters.push(newChar);
				}
				mom = songCharacters[3];
			}

			boyfriend = songCharacters[0];
			gf = songCharacters[1];
			dad = songCharacters[2];
		}

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		uiGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(uiGroup);
		add(noteGroup);

		Conductor.songPosition = -5000 / Conductor.songPosition;

		topCinematicBar = new FlxSprite(0, -400).makeSolid(1280, 400, FlxColor.BLACK);
		topCinematicBar.cameras = [camHUD];
		uiGroup.add(topCinematicBar);
		bottomCinematicBar = new FlxSprite(0, 720).makeSolid(1280, 400, FlxColor.BLACK);
		bottomCinematicBar.cameras = [camHUD];
		uiGroup.add(bottomCinematicBar);

		#if mobile
		switch (SONG.characters[2].toLowerCase())
		   {
			 case 'eyes' | 'halt':
		   	    addMobileControls(false, 1);
			 default:
				if (SONG.hasHeartbeat) {
				  addMobileControls(false, 2);
				} else {
				  addMobileControls(false);
				}
		   }
			mobileControls.visible = false;
		#end

		strumLine = new FlxSprite(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeSolid(FlxG.width, 10);
		if(ClientPrefs.data.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.data.timeBarType != 'disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 253, 0, 400, "", 32);
		timeTxt.setFormat(FONT, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.antialiasing = ClientPrefs.globalAntialiasing;
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.data.timeBarType == 'songname')
		{
			timeTxt.text = CoolUtil.getDisplaySong(SONG.song);
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.screenCenter();
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.WHITE;
		timeBarBG.xAdd = 0; //-12;
		timeBarBG.yAdd = 0; //-10;
		timeBarBG.antialiasing = true;
		
		var d:FlxGraphic = Paths.image('timeBarInside');
		
		//timeBarBG.x + 4, timeBarBG.y + 4
		timeBar = new ColorBar(timeBarBG.x, timeBarBG.y, LEFT_TO_RIGHT, Std.int(d.width), Std.int(d.height), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		//timeBar.createFilledBar(0x00000000, 0xFFEDDEC7);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		timeBar.antialiasing = true;
		
		timeBar.createImageEmptyBar(Paths.image('timeBarInside'), FlxColor.WHITE) ;
		timeBar.createImageFilledBar(Paths.image('timeBarInside'), FlxColor.WHITE) ;
		timeBar.frontColorTransform.color = 0xFFFFF9EF;
		timeBar.backColorTransform.color = 0x01000000;
		timeBar.backColorTransform.alphaMultiplier = 0.00001;
		timeBar.blend = BlendMode.ADD;
		
		uiGroup.add(timeBar);
		uiGroup.add(timeBarBG);
		uiGroup.add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		songCreditBox = new NewCredit(CreditTemplate.SONG, SONG.song);
		songCreditBox.cameras = [camOther];
		uiGroup.add(songCreditBox);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		noteGroup.add(strumLineNotes);

		if(ClientPrefs.data.timeBarType == 'songname' || ClientPrefs.data.timeBarType == 'songname-timeleft')
		{
			timeTxt.size = 24;
			timeTxt.y += 7;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		SustainSplash.startCrochet = Conductor.stepCrochet;
		SustainSplash.frameRate = Math.floor(24 / 200 * SONG.bpm);
		var splash:SustainSplash = new SustainSplash();
		grpHoldSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		noteGroup.add(grpHoldSplashes);
		noteGroup.add(grpNoteSplashes);

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		// Modcharting stuff

		switch (SONG.song){
			case '404' | 'left-behind' | 'left-behind-hell':
				noteGroup.remove(grpNoteSplashes);
				noteGroup.remove(grpHoldSplashes);
				playfieldRenderer = new PlayfieldRenderer(strumLineNotes, notes, this);
				playfieldRenderer.cameras = [camHUD];
				noteGroup.add(playfieldRenderer);
				noteGroup.add(grpNoteSplashes);
				noteGroup.add(grpHoldSplashes);
			default:
				if(DoorsUtil.modifierActive(61) && ModifierManager.isModifierApplicable(61, SONG.song)){
					noteGroup.remove(grpNoteSplashes);
					noteGroup.remove(grpHoldSplashes);
					playfieldRenderer = new PlayfieldRenderer(strumLineNotes, notes, this);
					playfieldRenderer.cameras = [camHUD];
					noteGroup.add(playfieldRenderer);
					noteGroup.add(grpNoteSplashes);
					noteGroup.add(grpHoldSplashes);
				}
		}

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}

		add(camFollowPos);
		switch(curStage){
			default:
				camGame.follow(camFollowPos, LOCKON, 1);
		}
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		camGame.zoom = defaultCamZoom;
		camGame.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection();

		//create cinematics bar

		healthBarBG = new AttachedSprite('healthBars/healthBar');
		if(ClientPrefs.data.downScroll){
			healthBarBG.y = FlxG.height * 0.15;
		} else{
			healthBarBG.y = FlxG.height * 0.93;
		}
		
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.data.hideHud;
		healthBarBG.xAdd = 0;
		healthBarBG.yAdd = 0;
		healthBarBG.scale.set(1, 1);
		healthBarBG.updateHitbox();
		healthBarBG.antialiasing = ClientPrefs.globalAntialiasing;

		healthBar = new ColorBar(healthBarBG.x, healthBarBG.y - 82, RIGHT_TO_LEFT, Std.int(healthBarBG.width), Std.int(healthBarBG.height), this,
			'lerpedHealth', 0, DoorsUtil.maxHealth);
		healthBar.scrollFactor.set();
		healthBar.antialiasing = false;
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		healthBar.createImageEmptyBar(Paths.image('healthBars/healthbarMask'), 0x00000000) ;
		healthBar.createImageFilledBar(Paths.image('healthBars/healthbarMask'), FlxColor.WHITE) ;
		uiGroup.add(healthBar);

		aegisOverlay = new ColorBar(healthBarBG.x, healthBarBG.y - 82, RIGHT_TO_LEFT, Std.int(healthBarBG.width), Std.int(healthBarBG.height), this,
		'lerpedHealth', DoorsUtil.maxHealth, DoorsUtil.maxHealth*2);
		aegisOverlay.scrollFactor.set();
		aegisOverlay.antialiasing = false;
		aegisOverlay.visible = !ClientPrefs.data.hideHud;
		aegisOverlay.alpha = ClientPrefs.data.healthBarAlpha;
		aegisOverlay.blend = BlendMode.MULTIPLY;
		aegisOverlay.createImageEmptyBar(Paths.image('healthBars/healthbarMask'), 0x00000000) ;
		aegisOverlay.createImageFilledBar(Paths.image('healthBars/healthbarMask'), FlxColor.WHITE) ;
		uiGroup.add(aegisOverlay);

		if(glitchTimer) healthBar.parentVariable = 'fakeHealth'; //glitch random health for left behind hell
		uiGroup.add(healthBarBG);
		
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 40;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 40;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;

		if(gf != null){
			iconP3 = new HealthIcon(gf.healthIcon, false);
		} else {
			iconP3 = new HealthIcon(boyfriend.healthIcon, false);
		}
		iconP3.y = healthBar.y - 60;
		iconP3.visible = !ClientPrefs.data.hideHud;
		iconP3.alpha = ClientPrefs.data.healthBarAlpha;

		if(mom != null){
			iconP4 = new HealthIcon(mom.healthIcon, false);
		} else {
			iconP4 = new HealthIcon(boyfriend.healthIcon, false);
		}
		iconP4.y = healthBar.y - 20;
		iconP4.visible = !ClientPrefs.data.hideHud;
		iconP4.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		
		uiGroup.add(iconP1);
		uiGroup.add(iconP2);
		if(SONG.song.toLowerCase() == 'bargain'){
			uiGroup.add(iconP3);
		}

		scoreTxt = new FlxText(0, healthBarBG.y - 20, FlxG.width, "", 20);
		scoreTxt.setFormat(FONT, 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.antialiasing = ClientPrefs.globalAntialiasing;
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		uiGroup.add(scoreTxt);

		#if final
		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, Lang.getText("botplayText", "generalshit"), 32);
		botplayTxt.setFormat(FONT, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.antialiasing = ClientPrefs.globalAntialiasing;
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);
		if(ClientPrefs.data.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}
		#end

		if(isStoryMode)
		{		
			if(ClientPrefs.data.downScroll)
				moneyIndicator = new MoneyIndicator(FlxG.width * 0.90, FlxG.height * 0.12, false);
			else
				moneyIndicator = new MoneyIndicator(FlxG.width * 0.05, FlxG.height * 0.80, false);

			add(moneyIndicator);
			
			if(ClientPrefs.data.downScroll)
				knobIndicator = new MoneyIndicator(FlxG.width * 0.90, FlxG.height * 0.20, true);
			else
				knobIndicator = new MoneyIndicator(FlxG.width * 0.05, FlxG.height * 0.88, true);

			add(knobIndicator);

			moneyIndicator.cameras = [camHUD];
			knobIndicator.cameras = [camHUD];
		}

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];

		if(!hasSpawnAnimation) {
			camGame.fade(FlxColor.BLACK, 0.001, false, true);
		}

		if (isStoryMode)
		{
			if(DoorsUtil.modifierActive(13) && DoorsUtil.curRun.latestHealth >= DoorsUtil.maxHealth/2)
			{
				health = DoorsUtil.maxHealth/2;
			}
			else
			{
				health = DoorsUtil.curRun.latestHealth;
			}

			if(DoorsUtil.modifierActive(14) && DoorsUtil.curRun.latestHealth >= DoorsUtil.maxHealth/5)
			{
				health = DoorsUtil.maxHealth/5;
			}
			else
			{
				health = DoorsUtil.curRun.latestHealth;
			}

			if(!DoorsUtil.modifierActive(13) && !DoorsUtil.modifierActive(14))
			{
				health = DoorsUtil.curRun.latestHealth;
			}
		}
		else
		{
			health = DoorsUtil.maxHealth/2;
		}

		if(ClientPrefs.data.iconsOnHB || isGreenhouseStage || dad.curCharacter == "halt" || dad.curCharacter == "eyes"){
			iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(50, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - 26;
			iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(50, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - 26 * 2;
			iconP3.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(50, 0, 100, 100, 0) * 0.01)) - (150 * iconP3.scale.x) / 2 - 26 * 2 - 75;
			iconP4.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(50, 0, 100, 100, 0) * 0.01)) - (150 * iconP4.scale.x) / 2 - 26 * 2 - 150;
		} else {
			iconP1.x = healthBar.x + healthBar.width - 26*2;
			iconP2.x = healthBar.x - 26*2 - 40;
			iconP3.x = healthBar.x - 26*2 - 90;
			iconP4.x = healthBar.x - 26*2 - 140;
		}


		startingSong = true;

		var daSong:String = Paths.formatToSongPath(curSong);

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/' ));// using push instead of insert because these should run after everything else
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		switch (daSong.toLowerCase()){
			case '404' | 'left-behind' | 'left-behind-hell':
				if(ClientPrefs.data.shaders)
				{
					glitchChroma = new RGBGlitchShader(0.1);
					add(glitchChroma);
	
					var filter:ShaderFilter = new ShaderFilter(glitchChroma.shader);
					camGameFilters.push(filter);
					updateCameraFilters('camGame');
					camHUDFilters.push(filter);
					updateCameraFilters('camHUD');

					bgGlitchGlitch = new GlitchEden();
				}

			case 'not-a-sound' | "not-a-sound-hell" | 'tranquil' | 'imperceptible' | 'hyperacusis' | 'depths-below':
				taikoActive = false;

				taikoSpot = new FlxSprite();
				taikoSpot.frames = Paths.getSparrowAtlas('TaikoHeart');
				taikoSpot.animation.addByPrefix('idle', 'Heartbeat', 24, false);
				taikoSpot.visible = false;
				taikoSpot.cameras = [camHUD];
				taikoSpot.antialiasing = ClientPrefs.globalAntialiasing;
				taikoSpot.screenCenter();
				taikoSpot.animation.play('idle');

				add(taikoVignette);
				add(taikoSpot);
		}


		switch(dad.curCharacter){
			case 'glitch' | 'glitch-alt':
				if(ClientPrefs.data.shaders){
					var glitchCharShader = new GlitchPosterize();
					dad.shader = glitchCharShader.shader;
					glitchCharShader.amount = dad.curCharacter == "glitch" ? 0.03 : 0.2;
				}
			case 'guidingLight':
				dad.alpha = 0;
				dad.blend = BlendMode.HARDLIGHT;
		}

		if(!stageData.hide_girlfriend){
			switch(gf.curCharacter){
				case 'glitch' | 'glitch-alt':
					if(ClientPrefs.data.shaders){
						var glitchCharShader = new GlitchPosterize();
						gf.shader = glitchCharShader.shader;
						glitchCharShader.amount = gf.curCharacter == "glitch" ? 0.03 : 0.2;
					}
			}
		}

		if(mom != null){
			switch(mom.curCharacter){
				case 'glitch' | 'glitch-alt':
					if(ClientPrefs.data.shaders){
						var glitchCharShader = new GlitchPosterize();
						mom.shader = glitchCharShader.shader;
						glitchCharShader.amount = mom.curCharacter == "glitch" ? 0.03 : 0.2;
					}
			}
		}

		if (isStoryMode){
			itemInventory = new ItemInventory(VERTICAL, this);
			itemInventory.cameras = [camHUD];
			add(itemInventory);
		}

		allowCountdown = false;

		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();
		
		snapCamFollowToPos(dad.x, dad.y);

		if(ClientPrefs.data.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');

		//precaching them ONLY if ghost tapping is off since if not they aren't going to be used
		if(!ClientPrefs.data.ghostTapping)
		{
			precacheList.set('missnote1', 'sound');
			precacheList.set('missnote2', 'sound');
			precacheList.set('missnote3', 'sound');
		}

		precacheList.set('SillyPause', 'music');

		precacheList.set('alphabet', 'image');
		
		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, CoolUtil.getDisplaySong(SONG.song), largeIcon, smallIcon);
		#end

		if(!ClientPrefs.data.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000;

		// Modchart

		switch(SONG.song){
			case '404' | 'left-behind' | 'left-behind-hell':
				ModchartFuncs.loadLuaFunctions();
				
			default:
				if(DoorsUtil.modifierActive(61) && ModifierManager.isModifierApplicable(61, SONG.song)){
					ModchartFuncs.loadLuaFunctions();
				}
		}

		generateStaticArrows(0);
		generateStaticArrows(1);
		if(SONG.hasHeartbeat){
			generateStaticArrows(1, true);
		}

		if (SONG.song == 'not-a-sound' || SONG.song == "not-a-sound-hell" || SONG.song == 'tranquil' || SONG.song == 'imperceptible' || SONG.song == 'hyperacusis' || SONG.song == 'depths-below'){			
			var s0 = playerStrums.members[4];
			var s1 = playerStrums.members[5];

			s0.direction = 0;
			s1.direction = 180;
			s0.angle = 90;
			s1.angle = 270;
			s0.x = 545;
			s1.x = 625;
			s0.y = 284;
			s1.y = 284;
			s0.alpha = 1;
			s1.alpha = 1;
			s0.visible = false;
			s1.visible = false;
			
			taikoSpot.visible = true;
			taikoSpot.alpha = 0.1;
		}

		super.create();

		cacheCountdown();
		cachePopUpScore();
		for (key => type in precacheList)
		{
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		Paths.clearUnusedMemory();
		
		camFollowPos.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
		camFollowPos.x -= boyfriend.cameraPosition[0];
		camFollowPos.y += boyfriend.cameraPosition[1];
		camGame.snapToTarget();
		
		CustomFadeTransition.nextCamera = camOther;
		stagesFunc(function(stage:BaseStage) stage.createPost());
		callOnLuas('onCreatePost', []);

		openSubState(new MechanicPosterSubstate());

		for(mechanic in activeMechanics)
		{
			mechanic.createPost();
		}

		// endSong - startingSong = true

		FlxG.console.registerFunction("endSong", function() {
			startingSong = true;
			endSong();
		});
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1){
				for (note in notes) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		return value;
	}

	public function reloadHealthBarColors()
	{
		var char1:Character = leftSideShit ? boyfriend : dad;
		var char2:Character = leftSideShit ? dad : boyfriend;

		healthBar.backColorTransform.color = FlxColor.fromRGB(char1.healthColorArray[0], char1.healthColorArray[1], char1.healthColorArray[2]);
		healthBar.frontColorTransform.color = FlxColor.fromRGB(char2.healthColorArray[0], char2.healthColorArray[1], char2.healthColorArray[2]);

		aegisOverlay.backColorTransform.color = 0x00FFFFFF;
		aegisOverlay.frontColorTransform.color = 0x80FFD44D;

		healthBar.updateBar();
		aegisOverlay.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					if(newBoyfriend.attachChar!=null){
						songCharacterGroups[0].add(newBoyfriend.attachChar);
					}
					songCharacterGroups[0].add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					songCharacterGroups[2].add(newDad);
					if(newDad.attachChar!=null){
						songCharacterGroups[2].add(newDad.attachChar);
					}
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					if(newGf.attachChar!=null){
						songCharacterGroups[1].add(newGf.attachChar);
					}
					songCharacterGroups[1].add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
				}

			case 3:
				if(mom != null && !momMap.exists(newCharacter)) {
					var newMom:Character = new Character(0, 0, newCharacter);
					newMom.scrollFactor.set(0.95, 0.95);
					momMap.set(newCharacter, newMom);
					if(newMom.attachChar!=null){
						songCharacterGroups[3].add(newMom.attachChar);
					}
					songCharacterGroups[3].add(newMom);
					startCharacterPos(newMom);
					newMom.alpha = 0.00001;
				}
		}
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		final filepath:String = Paths.video(name);

		if (#if sys !FileSystem.exists(filepath) #else !OpenFlAssets.exists(filepath) #end)
		{
			FlxG.log.warn('Couldnt find video file: $name');
			startAndEnd();
			return;
		}

		var video:FlxVideo = new FlxVideo();

		video.onEndReached.add(function():Void
		{
			video.dispose();
			startAndEnd();
			return;
		}, true);

		if (video.load(filepath))
		    video.play();
		else
		{
			video.dispose();
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var startTimer:FlxTimer;
	var creditsTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);

		var introAlts:Array<String> = introAssets.get('default');
		
		for (asset in introAlts)
			Paths.image(asset);
		
		Paths.sound('intro3');
		Paths.sound('intro2');
		Paths.sound('intro1');
		Paths.sound('introGo');
	}


	public var countdownCounter:Int = 0;
	public var inIntro:Bool = false;
	public function startCountdown()
	{
		#if mobile
			mobileControls.visible = true;
		#end
		
		if(startedCountdown) {
			return false;
		}

		inCutscene = false;
		if(allowCountdown && !inIntro) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			// Modchart stuff
			switch (SONG.song){
				case '404' | 'left-behind' | 'left-behind-hell' | 'starting-point' | 'guidance':
					NoteMovement.getDefaultStrumPos(this);
				case 'halt' | 'onward' | 'onward-hell':
					for(i in 0...playerStrums.members.length)
					{
						if(storyDifficulty > 2 || (DoorsUtil.modifierActive(51) && !isStoryMode))
						{
							FlxTween.tween(playerStrums.members[3], {x: 1068 , angle: 0}, 0.3, {ease: FlxEase.quintOut, startDelay: 0});
							FlxTween.tween(playerStrums.members[2], {x: 956, angle: 0}, 0.3, {ease: FlxEase.quintOut, startDelay: 0.05});
							FlxTween.tween(playerStrums.members[1], {x: 844, angle: 0}, 0.3, {ease: FlxEase.quintOut, startDelay: 0.1});
							FlxTween.tween(playerStrums.members[0], {x: 732, angle: 0}, 0.3, {ease: FlxEase.quintOut, startDelay: 0.15});	
						}
						else if(!ClientPrefs.data.middleScroll)
						{
							playerStrums.members[i].x -= 320;
						}
					}
			}

			if(DoorsUtil.modifierActive(61) && ModifierManager.isModifierApplicable(61, SONG.song)){
				NoteMovement.getDefaultStrumPos(this);
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;

			//buildCredits();
			

			var swagCounter:Int = 0;
			countdownCounter = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBop(tmr.loopsLeft);
				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3'), 0.6);
						theMouse.isTransparent = true;
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2'), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1'), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo'), 0.6);
						tick = GO;
					case 4:
						tick = START;
						if(isStoryMode){
							moneyIndicator.fadeOut();
							knobIndicator.fadeOut();
						}
						if(!manuallySpawnCredits){
							new FlxTimer().start(Conductor.crochet / 1000 * 32, function(tmr){
								songCreditBox.start();
							});
						}
						canPause = true;
						if(!hasSpawnAnimation) 
							camGame.fade(FlxColor.BLACK, Conductor.crochet / 1000 / playbackRate, true, true);
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.data.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.data.middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});
				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));

				swagCounter += 1;
				countdownCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				invalidateNote(daNote);
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				invalidateNote(daNote);
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		scoreTxt.text = '${Lang.getText("score", "generalshit")}: ' + songScore
		+ ' | ${Lang.getText("misses", "generalshit")}: ' + songMisses
		+ ' | ${Lang.getText("rating", "generalshit")}: ' + ratingName
		+ (ratingName != '?' ? ' (${CoolUtil.quantize(ratingPercent * 100, 100)}%) - $ratingFC' : '');

		if(ClientPrefs.data.scoreZoom && !miss && !cpuControlled)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		//vocals.volume = 1;
		vocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		if(hasFakeTimerArray.contains(SONG.song.toLowerCase()))
		{
			hasFakeTimer = true;
			songLengthFake = getFakeTime(SONG.song.toLowerCase());
		}

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, CoolUtil.getDisplaySong(SONG.song), largeIcon, smallIcon, true, songLength);
		#end
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	var vocalsFinished:Bool = false;
	private function convertToDoorsNote(note:Dynamic, gamerNote:Note){
		if(gamerNote.assignedChars != null && gamerNote.assignedChars.length > 0){ 
			gamerNote.assignedChars = note[4];
		} else {
			switch(gamerNote.noteType){
				case 'GF Sing':
					gamerNote.assignedChars = [1];
					gamerNote.noteType = "";
				case 'Mom Sing':
					gamerNote.assignedChars = [3];
					gamerNote.noteType = "";
				case 'Mom GF Sing':
					gamerNote.assignedChars = [1, 3];
					gamerNote.noteType = "";
				case 'Dad GF Sing':
					gamerNote.assignedChars = [1, 2];
					gamerNote.noteType = "";
				case 'Dad Mom Sing':
					gamerNote.assignedChars = [2, 3];
					gamerNote.noteType = "";
				case 'All Sing':
					gamerNote.assignedChars = [1, 2, 3];
					gamerNote.noteType = "";
				default:
					if(gamerNote.mustPress){
						gamerNote.assignedChars = [0];
					} else {
						gamerNote.assignedChars = [2];
					}
			}
		}
		
		gamerNote.useNewCharSystem = true;
		if(gamerNote.assignedChars.contains(0)){
			gamerNote.mustPress = true;
		}
		
		stagesFunc(function(stage:BaseStage) stage.noteConvert(note, gamerNote));
	}

	private function generateSong(dataPath:String):Void
	{
		var songData = SONG;
		songSpeed = songData.speed;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices) {
			vocals = new FlxFilteredSound();
			vocals.loadEmbedded(Paths.voices(PlayState.SONG.song));
		}
		else
			vocals = new FlxFilteredSound();

		vocals.onComplete = function()
		{
			vocalsFinished = true;
		}

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		var snd = new FlxFilteredSound();
		snd.loadEmbedded(Paths.inst(PlayState.SONG.song));
		FlxG.sound.list.add(snd);

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		if (OpenFlAssets.exists(file) && !chartingMode) {
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.data.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}
				
				if (songNotes[1] > 7 && songData.hasHeartbeat){
					gottaHitNote = true;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, songNotes[1] > 7, songNotes[4]);
				swagNote.row = Conductor.secsToRow(daStrumTime);
					if(noteRows[gottaHitNote?0:1][swagNote.row]==null)
						noteRows[gottaHitNote?0:1][swagNote.row]=[];
					noteRows[gottaHitNote ? 0 : 1][swagNote.row].push(swagNote);
				
				swagNote.mustPress = gottaHitNote;
				if (songData.hasHeartbeat){
					swagNote.isHeartbeat = songNotes[1] > 7;
				}
				if(gottaHitNote){
					swagNote.isOppNote = daNoteData > 3;
				}else{
					swagNote.isOppNote = daNoteData < 4;
				}
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength;
				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true, false, false, songNotes[4]);
						sustainNote.mustPress = gottaHitNote;
						if(gottaHitNote){
							sustainNote.isOppNote = daNoteData > 3;
						}else{
							sustainNote.isOppNote = daNoteData < 4;
						}
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						sustainNote.correctionOffset = swagNote.height / 2;
						if(oldNote.isSustainNote)
						{
							oldNote.scale.y *= 44 / oldNote.frameHeight;
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if(ClientPrefs.data.downScroll) sustainNote.correctionOffset = 0;
						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}

						convertToDoorsNote(songNotes, sustainNote);
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
				if(swagNote.assignedChars != null && swagNote.assignedChars.length > 0){
					convertToDoorsNote(songNotes, swagNote);
				} 
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.data.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));

		switch(event.event) {
			case "timCum":
				if(!eventPushedMap.exists(event.event)) {
					new states.mechanics.TimothyCum();
				}
			case "spawn lyrics":
				if(event.value1 == "true" || event.value1 == ""){ //translate
					lyrics.push(Lang.getText(event.value2.replace(" ", "_"), "lyrics/"+SONG.song.toLowerCase()));
					trace('${event.value2.replace(" ", "_")} | ${"lyrics/"+SONG.song.toLowerCase()}');
				} else {
					lyrics.push(event.value2);
				}

			case "spawn credits":
				manuallySpawnCredits = true;

			case "Pixelated Effect":
				if(!ClientPrefs.data.shaders) return;
				if(!hasPixel){
					pixelEvent = new MosaicShader();
					pixelEvent.strength = 0;
					add(pixelEvent);

					scanlineEvent = new ScanlineShader();
					scanlineEvent.strength = 0;
					scanlineEvent.pixelsBetweenEachLine = 15.0;
					scanlineEvent.smooth = false;
					add(scanlineEvent);

					var filter:ShaderFilter = new ShaderFilter(pixelEvent.shader);

					camGameFilters.push(filter);
					camHUDFilters.push(filter);
					
					filter = new ShaderFilter(scanlineEvent.shader);

					camGameFilters.push(filter);
					camHUDFilters.push(filter);

					updateCameraFilters('camGame');
					updateCameraFilters('camHUD');

					hasPixel = true;
					pixelPoint = new FlxPoint(0, 0);
					scanlinePoint = new FlxPoint(0, 0);
				}

			case 'Chromatic Aberrate':
				if(!ClientPrefs.data.shaders) return;
				if(chromaticEvent == null){
					chromaticEvent = new ChromaticAberration();
					chromaticEvent.iOffset = 0;
					add(chromaticEvent);

					var filter:ShaderFilter = new ShaderFilter(chromaticEvent.shader);

					camGameFilters.push(filter);
					camHUDFilters.push(filter);

					updateCameraFilters('camGame');
					updateCameraFilters('camHUD');

					hasChromaticAberration = true;
					chromaticPoint = new FlxPoint(0, 0);
				}
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'mom' | 'opponent2' | '2':
						charType = 3;
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		switch(event.event) {
			case "timCum": return 500;
			case "spawnSeek": return 3084;
			case "db-figureSpawn": return 1501;
			case "spawnEyes": return 1042;
			case "screechHit": return 273;
			case "bfThrowMic": return 200;
			case "bfStartThrowMic": return 700;
			case "seekDodge": 
				return (Conductor.crochet) * Math.round(Conductor.bpm / 37.5);
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int, ?generateHeartbeat = false):Void
	{
		var songName:String = Paths.formatToSongPath(SONG.song);
		songName = songName.toLowerCase();
		if (!generateHeartbeat){
			for (i in 0...4)
				{
					// FlxG.log.add(i);
					var targetAlpha:Float = 1;
					if (player < 1)
					{
						switch (SONG.song){
							case '404' | 'left-behind' | 'left-behind-hell':
								//nothin
							default:
								if(!DoorsUtil.modifierActive(61) && ModifierManager.isModifierApplicable(61, SONG.song)){
									if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
									else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
								}
						}
					}
		
					var babyArrow:StrumNote;
					switch (SONG.song){
						case '404' | 'left-behind' | 'left-behind-hell':
							babyArrow = new StrumNote(STRUM_X, strumLine.y, i, player, -1);
						default:
							if(!DoorsUtil.modifierActive(61) && ModifierManager.isModifierApplicable(61, SONG.song)){
								babyArrow = new StrumNote(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player, -1);
							} else {
								babyArrow = new StrumNote(STRUM_X, strumLine.y, i, player, -1);
							}
					}
					babyArrow.downScroll = ClientPrefs.data.downScroll;
					if (!skipArrowStartTween)
					{
						
						if(!['404', 'left-behind', 'left-behind-hell'].contains(SONG.song) && !DoorsUtil.modifierActive(61) && ModifierManager.isModifierApplicable(61, SONG.song)){
							babyArrow.y += 300;
							FlxTween.tween(babyArrow, {y: babyArrow.y - 300}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
						}
						babyArrow.alpha = 0;
						FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
					}
					else
					{
						babyArrow.strumSprite.alpha = targetAlpha;
					}
		
					if (player == 1)
					{
						playerStrums.add(babyArrow);
					}
					else
					{
						var songBased:Int = setStrumPositionsFromName(songName);
						if(songBased!= 0){
							babyArrow.x = songBased;
						}
						switch (SONG.song){
							case '404' | 'left-behind' | 'left-behind-hell':
								//nothin
							default:
								if(!DoorsUtil.modifierActive(61) && ModifierManager.isModifierApplicable(61, SONG.song)){
									if(ClientPrefs.data.middleScroll)
									{
										babyArrow.x += 310;
										if(i > 1) { //Up and Right
											babyArrow.x += FlxG.width / 2 + 25;
										}
									}
								}
						}
						opponentStrums.add(babyArrow);
					}
		
					strumLineNotes.add(babyArrow);
					babyArrow.postAddedToGroup();
				}
		} else {
			for (i in 4...6){
					// FlxG.log.add(i);
					var babyArrow:StrumNote = new StrumNote(STRUM_X_MIDDLESCROLL, strumLine.y, i, 1, -1);
					babyArrow.downScroll = true;
					babyArrow.strumSprite.alpha = 1;
					playerStrums.add(babyArrow);
					strumLineNotes.add(babyArrow);
					babyArrow.postAddedToGroup();
				}
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{	
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if(creditsTimer!=null && !creditsTimer.finished)
				creditsTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			for (tween in stopTweens) {
				tween.active = false;
			}
			for (timer in stopTimers) {
				timer.active = false;
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
			@:privateAccess
			{
				for (i in DoorsVideoSprite._videos)
				{
					if (i != null && i.bitmap != null && i.bitmap.isPlaying)
					{
						i.pause();
						i.wasPlaying = true;
					}
				}
			}
		}

		super.openSubState(SubState);
	}

	public var canResync:Bool = true;
	override function closeSubState()
	{
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{	
			if (FlxG.sound.music != null && !startingSong && canResync)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			for (tween in stopTweens) {
				tween.active = true;
			}
			for (timer in stopTimers) {
				timer.active = true;
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			@:privateAccess
			{
				for (i in DoorsVideoSprite._videos)
				{
					if (i != null && i.bitmap != null && !i.bitmap.isPlaying && i.wasPlaying)
					{
						i.resume();
						i.wasPlaying = false;
					}
				}
			}

			paused = false;

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, CoolUtil.getDisplaySong(SONG.song), largeIcon, smallIcon, true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, CoolUtil.getDisplaySong(SONG.song), largeIcon, smallIcon);
			}
			#end
		}

		//Options thing, cause options will be a substate lmao
		onOptionsChanged();

		super.closeSubState();
	}

	public function onOptionsChanged(){
		//splashes - no need
		//hide hud 
		healthBarBG.visible = !ClientPrefs.data.hideHud;
		healthBar.visible = !ClientPrefs.data.hideHud;
		aegisOverlay.visible = !ClientPrefs.data.hideHud;
		if(iconP1.alpha > 0.05) iconP1.visible = !ClientPrefs.data.hideHud;
		if(iconP2.alpha > 0.05) iconP2.visible = !ClientPrefs.data.hideHud;
		if(iconP3.alpha > 0.05) iconP3.visible = !ClientPrefs.data.hideHud;
		if(iconP4.alpha > 0.05) iconP4.visible = !ClientPrefs.data.hideHud;
		scoreTxt.visible = !ClientPrefs.data.hideHud;

		//timeBarType
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'disabled');
		timeTxt.visible = showTime;
		if(ClientPrefs.data.timeBarType == 'songname')
		{
			timeTxt.text = SONG.song;
			timeTxt.size = 24;
			timeTxt.y += 7;
		}
		if(ClientPrefs.data.timeBarType == 'songname-timeleft') {
			timeTxt.size = 24;
			timeTxt.y += 7;
		}
		updateTime = showTime;
		timeBarBG.visible = showTime;
		timeBar.visible = showTime;
		
		//flashing lights - no need
		//camZooms - no need
		//camFollow - no need
		//camAngle - no need
		//chachaSlide - no need
		//scoreZoom - no need
		//downScroll
		if(ClientPrefs.data.downScroll) strumLine.y = FlxG.height - 150;
		else strumLine.y = 50;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		else timeTxt.y = 0;
		if(ClientPrefs.data.downScroll) healthBarBG.y = FlxG.height * 0.15;
		else healthBarBG.y = FlxG.height * 0.93;
		if(ClientPrefs.data.downScroll && botplayTxt != null) botplayTxt.y = timeBarBG.y - 78;
		else timeBarBG.y + 55;
		if(isStoryMode){
			if(ClientPrefs.data.downScroll) moneyIndicator.y = FlxG.height * 0.12;
			else moneyIndicator.y = FlxG.height * 0.80;
			if(ClientPrefs.data.downScroll) knobIndicator.y = FlxG.height * 0.20;
			else knobIndicator.y = FlxG.height * 0.88;
		}
		for(i in 0...8) {
			var babyArrow = strumLineNotes.members[i];
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.y = strumLine.y;
		}

		//middleScroll - i'm too lazy to do it rn lmfao

		//opponentStrums
		for(note in notes){
			for(t in note.tail) t.flipY = ClientPrefs.data.downScroll;

			if(ClientPrefs.data.opponentStrums || note.mustPress)
			{
				note.copyAlpha = false;
				note.alpha = note.multAlpha;
				if(ClientPrefs.data.middleScroll && !note.mustPress) {
					note.alpha *= 0.35;
				}
			}
		}
		
		for(note in unspawnNotes) {
			for(t in note.tail)	t.flipY = ClientPrefs.data.downScroll;

			if(ClientPrefs.data.opponentStrums || note.mustPress)
			{
				note.copyAlpha = false;
				note.alpha = note.multAlpha;
				if(ClientPrefs.data.middleScroll && !note.mustPress) {
					note.alpha *= 0.35;
				}
			}
		};

		for(babyArrow in opponentStrums){
			if(!ClientPrefs.data.opponentStrums) babyArrow.alpha = 0;
			//gotta change some things
		}
		
		if(!ClientPrefs.data.ghostTapping)
		{
			precacheList.set('missnote1', 'sound');
			precacheList.set('missnote2', 'sound');
			precacheList.set('missnote3', 'sound');
		}
		if(ClientPrefs.data.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		/*
		var option:Option = new Option(lp.midScroll,
			lp.midScrollDesc,
			'middleScroll',
			'bool',
			false);
		addOption(option);*/

		//now do the fucking controls
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, CoolUtil.getDisplaySong(SONG.song), largeIcon, smallIcon, true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, CoolUtil.getDisplaySong(SONG.song), largeIcon, smallIcon);
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, CoolUtil.getDisplaySong(SONG.song), largeIcon, smallIcon);
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null || vocalsFinished) return;

	/*	trace("=== FLXG.SOUND.MUSIC ===");
		trace(FlxG.sound.music == null);
		trace(FlxG.sound.music.playing);
		trace(FlxG.sound.music.active);
		trace(FlxG.sound.music.length);
		trace(FlxG.sound.music);
		trace("=== FLXG.SOUND.MUSIC ===");

		trace("=== VOCALS ===");
		trace(vocals == null);
		trace(vocals.playing);
		trace(vocals.active);
		trace(vocals.length);
		trace(vocals);
		trace("=== VOCALS ===");
		
		trace('resynced vocals at ' + Math.floor(Conductor.songPosition));*/

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (FlxG.sound.music.time < vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
			vocals.play();
			if(!vocals.active && !paused){
				vocals.loadEmbedded(Paths.voices(PlayState.SONG.song));
			}
		//	trace("made vocals play");
		} else {
			vocals.pause();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = false;
	var limoSpeed:Float = 0;

	public static var maxLuaFPS = 30;
	var fpsElapsed:Array<Float> = [0,0,0];
	var numCalls:Array<Float> = [0,0,0];
	
	
	public var rawText:String="";// = Paths.getTextFromFile(u[fileIndex]);
	public var creditsPosition:Float = 550;
	public var positionMax:Float = 550;
	public var activated:Int=0;
	public var creditSpeed:Float = -0.1;
	public var creditSize:Int = 22;
	var thisIsSoDumbJustWorkPlease = false;
		
	override public function update(elapsed:Float)
	{
		for(mechanic in activeMechanics)
		{
			mechanic.update(elapsed);
		}

		switch (curStage)
		{
			case 'drip': // Drip stage events
				if(ClientPrefs.data.shaders){
					if (SONG.song == 'drip'){
						if (curStep >= 384 && curStep < 640){
							dripBackground.speed = 4;
						} else if (curStep >= 912) {
							dripBackground.speed = 8;
						} else {
							dripBackground.speed = 1;
						}
					}
					if (SONG.song == 'drip-hell'){
						if (curStep >= 256 && curStep < 368){
							dripBackground.speed = 2;
						} else if (curStep >= 384 && curStep < 640) {
							dripBackground.speed = 4;
						} else if (curStep >= 896){
							dripBackground.speed = 8;
						} else {
							dripBackground.speed = 1;
						}
					}
				}
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		#if final
		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
		#end

		if (controls.PAUSE #if android || FlxG.android.justReleased.BACK #end && startedCountdown && canPause)
		{
			openPauseMenu();
		}

		#if debug
		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		if (FlxG.keys.justPressed.Y && !endingSong && !inCutscene)
		{
			MusicBeatState.switchState(new modcharting.ModchartEditorState());
		}
		#end

		var iconOffset:Int = 26;
		var lerpVal = CoolUtil.boundTo(elapsed * 8 * playbackRate, 0, 1);
		lerpedHealth = FlxMath.lerp(lerpedHealth, health, lerpVal);

		if(ClientPrefs.data.iconsOnHB || isGreenhouseStage || dad.curCharacter == "halt" || dad.curCharacter == "eyes"){
			iconP1.x = FlxMath.lerp(iconP1.x, healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset, lerpVal/2);
			iconP2.x = FlxMath.lerp(iconP2.x, healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2, lerpVal/2);
			iconP3.x = FlxMath.lerp(iconP3.x, healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP3.scale.x) / 2 - iconOffset * 2 - 50, lerpVal/2);
			iconP4.x = FlxMath.lerp(iconP4.x, healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP4.scale.x) / 2 - iconOffset * 2 - 100, lerpVal/2);
		} else {
			iconP1.x = healthBar.x + healthBar.width - iconOffset*2;
			iconP2.x = healthBar.x - iconOffset*2 - 40;
			iconP3.x = healthBar.x - iconOffset*2 - 90;
			iconP4.x = healthBar.x - iconOffset*2 - 140;
		}

		var mult:Float = FlxMath.lerp(iconP1.scale.x, 1, lerpVal);
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(iconP2.scale.x, 1, lerpVal);
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var mult:Float = FlxMath.lerp(iconP3.scale.x, 1, lerpVal);
		iconP3.scale.set(mult, mult);
		iconP3.updateHitbox();

		var mult:Float = FlxMath.lerp(iconP4.scale.x, 1, lerpVal);
		iconP4.scale.set(mult, mult);
		iconP4.updateHitbox();

		if(ClientPrefs.data.downScroll){
			theHealthBarAimedPosY = FlxG.height * 0.15;
			theRatingsAimedPosY = FlxG.height * 0.13;
		} else {
			theHealthBarAimedPosY = FlxG.height * 0.93;
			theRatingsAimedPosY = FlxG.height * 0.93;
		}

		var effectiveMaxHealth = DoorsUtil.maxHealth;
		if(DoorsUtil.modifierActive(45)) effectiveMaxHealth *= 2;

		if (leftSideShit ? health <= 0 : health >= effectiveMaxHealth)
		{
			health = leftSideShit ? 0 : effectiveMaxHealth;

			var no:Bool = false;
			if (iPissedOnTheMoon.contains(SONG.song.toLowerCase())) no = true;
			if(isGreenhouseStage) no = true;

			if(!no && ClientPrefs.data.chachaSlide)
			{
				if(ClientPrefs.data.downScroll)
				{
					theHealthBarAimedPosY = -healthBarBG.height - 100;
					theRatingsAimedPosY = 0;
				}
				else
				{
					theHealthBarAimedPosY = FlxG.height + healthBarBG.height + 100;
				}
			}
		}

		if(DoorsUtil.modifierActive(45) && health >= DoorsUtil.maxHealth){
			health -= elapsed / 50 * healthLoss;
		}

		var varToUseIdkWhatThisIs = leftSideShit ? (-health+DoorsUtil.maxHealth) : health;
		if(glitchTimer) varToUseIdkWhatThisIs = fakeHealth;

		scoreTxt.y = FlxMath.lerp(theRatingsAimedPosY, scoreTxt.y, CoolUtil.boundTo(1 - (3 * elapsed * (1 + (DoorsUtil.maxHealth - varToUseIdkWhatThisIs) * 8)), 0, 1));
		healthBar.y = FlxMath.lerp(theHealthBarAimedPosY - 80, healthBar.y, CoolUtil.boundTo(1 - (elapsed * (1 + (DoorsUtil.maxHealth - varToUseIdkWhatThisIs) * 8)), 0, 1));
		aegisOverlay.y = healthBar.y;
		iconP1.y = healthBar.y - 40;
		iconP2.y = healthBar.y - 40;
		iconP3.y = healthBar.y - 40;
		iconP4.y = healthBar.y - 40;

		if(isStoryMode){
			if(DoorsUtil.curRun.curInventory.items.length <= 0){
				itemBoxTargetX = -itemInventory.width;
			}
			itemInventory.x = FlxMath.lerp(itemBoxTargetX, itemInventory.x, CoolUtil.boundTo(1 - (elapsed * (1 + (DoorsUtil.maxHealth - varToUseIdkWhatThisIs) * 8)), 0, 1));
		}

		if(!isGreenhouseStage){
			if (healthBar.percent < 20)
				iconP1.animation.curAnim.curFrame = 1;
			else
				iconP1.animation.curAnim.curFrame = 0;
		}

		if (healthBar.percent > 80) {
			iconP2.animation.curAnim.curFrame = 1;
			iconP3.animation.curAnim.curFrame = 1;
			iconP4.animation.curAnim.curFrame = 1;
		} else {
			iconP2.animation.curAnim.curFrame = 0;
			iconP3.animation.curAnim.curFrame = 0;
			iconP4.animation.curAnim.curFrame = 0;
		}

		#if debug
		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			canResync = false;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}
		#end
		
		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}

				if(updateTime)
				{
					var lengthOfSong:Float = hasFakeTimer ? songLengthFake : songLength;

					var curTime:Float = Conductor.songPosition - ClientPrefs.data.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / lengthOfSong);

					if(glitchTimer) 
					{
						glitchTimerTimer -= elapsed;
						if(glitchTimerTimer <= 0)
						{
							fakeHealth = FlxG.random.float(0.2, DoorsUtil.maxHealth);

							switch(ClientPrefs.data.timeBarType)
							{
								case 'timeelapsed' | 'timeleft':
									timeTxt.text = FlxStringUtil.formatTime(FlxG.random.int(99, 999));

								case 'songname': //I thought it would be funny if we added support for this
									var songSplit:Array<String> = SONG.song.split('');

									for (i in 0...songSplit.length)
									{
										var j = FlxG.random.int(0, songSplit.length - 1);
										var a = songSplit[i];
										var b = songSplit[j];
										songSplit[i] = b;
										songSplit[j] = a;
									}

									//output
									var outputGlitch:String = '';
									for(i in 0...songSplit.length)
									{
										outputGlitch += songSplit[i];
									}

									timeTxt.text = outputGlitch;
							}

							glitchTimerTimer = timeResetGlitch;
						}
					}
					else //default countDown
					{
						var songCalc:Float = (lengthOfSong - curTime);
						if(ClientPrefs.data.timeBarType == 'timeelapsed') songCalc = curTime;

						var secondsTotal:Int = Math.floor(songCalc / 1000);
						if(secondsTotal < 0) secondsTotal = 0;

						if(ClientPrefs.data.timeBarType != 'songname')
							timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
						if(ClientPrefs.data.timeBarType == 'songname-timeleft')
							timeTxt.text = CoolUtil.getDisplaySong(SONG.song) + ' - (' + FlxStringUtil.formatTime(secondsTotal, false) + ')';
					}
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}
		
		if(camZooming){
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			if(ClientPrefs.data.camAngle && curStage != "corridor" && curStage != "halt") {
				FlxG.camera.angle = FlxMath.lerp(defaultCamAngle, camGame.angle, CoolUtil.boundTo(1 - (elapsed), 0, 1));
			}
		}
		
		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];

				for(mechanic in activeMechanics)
					{
						mechanic.noteSpawn(dunceNote);
					}

				notes.insert(0, dunceNote);
				dunceNote.spawned=true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keysCheck();
				} else
					playerDance();

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						notes.forEachAlive(function(daNote:Note)
						{
							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if(daNote.mustPress)
							{
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									goodNoteHit(daNote);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteHit(daNote);

							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
									var willMiss:Bool = true;
									if (willMiss) noteMiss(daNote);
								}

								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		// camera follow start	
		if(!ClientPrefs.data.camFollow) camfollowEnabled = false;
		var camfollowMultiplier = 1;
		var bfcamfollowMultiplier = 1;
		var zoomOffset = 1.0;
		switch (curStage.toLowerCase()){
			case 'corridor':
				zoomOffset = 1.1;
			case 'a60':
				zoomOffset = 1.1;
			case 'timothy':
				zoomOffset = 0.8;
			case 'figureend':
				zoomOffset = 0.6;
			case 'f-library':
				zoomOffset = 1.2;
			case "mutant":
				zoomOffset = 1.3;
			case 'eyes':
				camfollowMultiplier = 3;
			case 'rush' | 'rush-greenhouse' | 'abush':
				zoomOffset = 0.9;
			case 'halt':
				offsetX = Std.int(boyfriend.getMidpoint().x);
				offsetY = Std.int(boyfriend.getMidpoint().y);
				bfoffsetX = Std.int(boyfriend.getMidpoint().x);
				bfoffsetY = Std.int(boyfriend.getMidpoint().y);
			case 'glitch':
				zoomOffset = 0.7;
			case 'drip':
				offsetX = Std.int(dad.getMidpoint().x - 300);
				offsetY = Std.int(dad.getMidpoint().y);
				bfoffsetX = Std.int(boyfriend.getMidpoint().x - 100);
				bfoffsetY = Std.int(boyfriend.getMidpoint().y - 100);
			case 'daddyIssues':
				offsetX = Std.int(dad.getMidpoint().x + 500);
				offsetY = Std.int(dad.getMidpoint().y + 300);
				bfoffsetX = Std.int(boyfriend.getMidpoint().x - 100);
				bfoffsetY = Std.int(boyfriend.getMidpoint().y + 200);
		}

		if(!currentlyMovingCamera){
			if(SONG.notes[curSection]!=null && SONG.notes[curSection].mustHitSection){
				camFollow.set(bfoffsetX,bfoffsetY);
			} else {
				camFollow.set(offsetX,offsetY);
			}
		}

		if(currentlyMovingCamera && eventCameraPoint != null){
			camFollow = eventCameraPoint;
		}

		if(currentlyMovingCamera && cameraFocusedOnChar){
			switch(cameraFocusedOn){
				case 0:
					offsetX = Std.int(boyfriend.cameraPosition[0] + boyfriend.getMidpoint().x - 100);
					offsetY = Std.int(boyfriend.cameraPosition[1] + boyfriend.getMidpoint().y - 100);
					bfoffsetX = Std.int(boyfriend.cameraPosition[0] + boyfriend.getMidpoint().x - 100);
					bfoffsetY = Std.int(boyfriend.cameraPosition[1] + boyfriend.getMidpoint().y - 100);
				case 1:
					offsetX = Std.int(dad.cameraPosition[0] + dad.getMidpoint().x + 150);
					offsetY = Std.int(dad.cameraPosition[1] + dad.getMidpoint().y - 100);
					bfoffsetX = Std.int(dad.cameraPosition[0] + dad.getMidpoint().x + 150);
					bfoffsetY = Std.int(dad.cameraPosition[1] + dad.getMidpoint().y - 100);
				case 2:
					if(gf != null){
						offsetX = Std.int(gf.cameraPosition[0]+ gf.getMidpoint().x);
						offsetY = Std.int(gf.cameraPosition[1]+ gf.getMidpoint().y);
						bfoffsetX = Std.int(gf.cameraPosition[0] + gf.getMidpoint().x);
						bfoffsetY = Std.int(gf.cameraPosition[1]+ gf.getMidpoint().y);
					}
				case 3:
					if(mom != null){
						offsetX = Std.int(mom.cameraPosition[0] + mom.getMidpoint().x);
						offsetY = Std.int(mom.cameraPosition[1]+ mom.getMidpoint().y);
						bfoffsetX = Std.int(mom.cameraPosition[0] + mom.getMidpoint().x);
						bfoffsetY = Std.int(mom.cameraPosition[1]+ mom.getMidpoint().y);
					}
				default:
					offsetX = Std.int(dad.getGraphicMidpoint().x);
					offsetY = Std.int(dad.getGraphicMidpoint().y);
					bfoffsetX = Std.int(dad.getGraphicMidpoint().x);
					bfoffsetY = Std.int(dad.getGraphicMidpoint().y);
			}
		}
		if(SONG.notes[curSection]!=null && SONG.notes[curSection].mustHitSection){
			if(boyfriend.isAnimateAtlas && boyfriend.alpha >= 0.1 && boyfriendGroup.visible && !currentlyMovingCamera) {
				bfoffsetX += 100;
				bfoffsetY += 200;
			}
			camFollow.set(bfoffsetX,bfoffsetY);
		} else {
			camFollow.set(offsetX,offsetY);
		}

		if(cameraEventOffset != null) camFollow += cameraEventOffset;

		if (camfollowEnabled){
			if(SONG.notes[curSection]!=null && SONG.notes[curSection].mustHitSection){
				if(!camEventZooming && !currentlyMovingCamera){
					defaultCamZoom = CAMZOOMCONST + zoomOffset - 1;
					CAMZOOMCONST2 = CAMZOOMCONST + zoomOffset - 1;
				}

				camFollow.x += bfcamX * bfcamfollowMultiplier;
				camFollow.y += bfcamY * bfcamfollowMultiplier;

				if(bfcamX > 0) defaultCamAngle = 1.5;
				else if (bfcamX < 0) defaultCamAngle = -1.5;
			} else {
				if(!camEventZooming) defaultCamZoom = CAMZOOMCONST;

				camFollow.x += camX * camfollowMultiplier;
				camFollow.y += camY * camfollowMultiplier;

				if(camX > 0) defaultCamAngle = 1.5;
				else if (camX < 0) defaultCamAngle = -1.5;
			}
		}

		if(hasChromaticAberration && ClientPrefs.data.shaders){
			chromaticEvent.iOffset = chromaticPoint.x /1000;
		}
		
		if(hasPixel && ClientPrefs.data.shaders){
			pixelEvent.strength = pixelPoint.x;
			scanlineEvent.strength = scanlinePoint.x;
			
			if(pixelPoint.x > 0.01){
				camGame.targetOffset.x = (camGame.scroll.x % 6);
				camGame.targetOffset.y = (camGame.scroll.y % 6);
			} else {
				camGame.targetOffset.x = 0;
				camGame.targetOffset.y = 0;
			}
		}
		
		if (isStoryMode){
			for(item in itemInventory.items){
				item.update(elapsed);
			}

			for(item in DoorsUtil.curRun.curInventory.items){
				if(item != null){
					if(Reflect.getProperty(controls, "ITEM"+ (item.itemSlot+1))){
						for(i in 0...itemInventory.items.members.length){
							if(itemInventory.items.members[i].itemData.itemSlot == item.itemSlot){
								itemInventory.items.members[i].onSongUse();
							}
						}
					}
				}
			}

			DoorsUtil.curRun.runSeconds += elapsed;
			if(DoorsUtil.curRun.runSeconds >= 3600) {
				DoorsUtil.curRun.runHours++;
				DoorsUtil.curRun.runSeconds -= 3600;
			}
		}

		super.update(elapsed);

		for (i in shaderUpdates){
			i(elapsed);
		}

		for(mechanic in activeMechanics)
		{
			mechanic.updatePost(elapsed);
		}
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
		openSubState(new PauseSubState());

		#if desktop
		DiscordClient.changePresence(detailsPausedText,  CoolUtil.getDisplaySong(SONG.song), largeIcon, smallIcon);
		#end
	}

	function openChartEditor()
	{
		canResync = false;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, null, true);
		#end
	}

	function stopReviveImmunity(timer){
		healthLoss = 1;
	}


	public var stopDeathEarly:Bool = false;
	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		var check:Bool = false;
		var effectiveMaxHealth = DoorsUtil.maxHealth;
		if(DoorsUtil.modifierActive(45)) effectiveMaxHealth *= 2;

		if(!leftSideShit)
			check = (((skipHealthCheck && (instakillOnMiss || DoorsUtil.modifierActive(15))) || health <= 0) && !practiceMode && !isDead && !stopDeathEarly);
		else
			check = (((skipHealthCheck && (instakillOnMiss || DoorsUtil.modifierActive(15))) || health >= effectiveMaxHealth) && !practiceMode && !isDead && !stopDeathEarly);

		if (check)
		{
			if(isStoryMode)
			{ 
				for (item in DoorsUtil.curRun.curInventory.items){
					if(item == null) continue;

					for(i in 0...itemInventory.items.members.length){
						if(itemInventory.items.members[i].itemData.itemSlot != item.itemSlot) continue;

						itemInventory.items.members[i].onSongDeath();
					}
				}
			}
		
			for(mechanic in activeMechanics)
			{
				mechanic.onDeath();
			}

			if(stopDeathEarly) return false;

			boyfriend.stunned = true;
			deathCounter++;

			canResync = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			persistentUpdate = false;
			persistentDraw = true;

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
			
			if(isStoryMode)
			{
				DoorsUtil.isDead = true;
				DoorsUtil.saveStoryData();
			}

			var songMetadata = new SongMetadata(SONG.song.toLowerCase().replace(' ', '-'));
			openSubState(new GameOverSubstate(songMetadata.deathMetadata, this));

			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, CoolUtil.getDisplaySong(SONG.song), "gameover", "gameover");
			#end
			isDead = true;
			return true;
		}

		if(practiceMode)
		{
			health = DoorsUtil.maxHealth/2;
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		return pressed;
	}

	function onZoomFinishedThingEvent(tween:FlxTween){
		defaultCamZoom = camGame.zoom;
		if(Math.ceil(defaultCamZoom * 100) == Math.ceil(CAMZOOMCONST * 100) || Math.ceil(defaultCamZoom * 100) == Math.ceil(CAMZOOMCONST2 * 100)){
			camEventZooming = false;
		}
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName)
		{
			case "spawn lyrics":
				var newText = new FlxText(0, 610, FlxG.width, lyrics[curLyricsIndex], 48);
				newText.setFormat(Paths.font("Oswald.ttf"), 48, 0xFFFEDEBF, CENTER, OUTLINE, 0xFF452D25);
				newText.antialiasing = ClientPrefs.globalAntialiasing;
				newText.alpha = 0.00001;
				newText.cameras = [camHUD];
				add(newText);

				FlxTween.tween(newText, {
					y: 490,
					alpha: 1
				}, Conductor.stepCrochet / 1000, {ease: FlxEase.backOut});

				lyricsFlxText.unshift(newText);
				if(lyricsFlxText.length > 1) {
					FlxTween.completeTweensOf(lyricsFlxText[1]);
					FlxTween.tween(lyricsFlxText[1], {
						y: 420,
						alpha: 0.5
					}, Conductor.stepCrochet / 1000, {ease: FlxEase.backOut});
				}
				if(lyricsFlxText.length > 2) {
					FlxTween.completeTweensOf(lyricsFlxText[2]);
					FlxTween.tween(lyricsFlxText[2], {
						y: 350,
						alpha: 0.25
					}, Conductor.stepCrochet / 1000, {ease: FlxEase.backOut});
				}
				if(lyricsFlxText.length > 3) {
					FlxTween.completeTweensOf(lyricsFlxText[3]);
					FlxTween.tween(lyricsFlxText[3], {
						y: 280,
						alpha: 0
					}, Conductor.stepCrochet / 1000, {ease: FlxEase.backOut, onComplete: function(twn){
						var l = lyricsFlxText.pop();
						l.kill();
						remove(l, true);
						l.destroy();
					}});
				}
				curLyricsIndex++;

			case "remove lyrics":
				for(lyric in lyricsFlxText){
					FlxTween.tween(lyric, {
						y: lyric.y - 70,
						alpha: 0
					}, Conductor.stepCrochet / 1000 * 16 * lyric.alpha, {ease: FlxEase.cubeOut, onComplete: function(twn){
						lyricsFlxText.remove(lyric);
						lyric.kill();
						remove(lyric, true);
						lyric.destroy();
					}});
				}
				lyricsFlxText = [];
				

			case "spawn credits":
				songCreditBox.start();

			case "load new credits":
				//do nothing for now, maybe soon

			case "bf pop off section ghost":
				bfGhostPopOff = !bfGhostPopOff;

			case 'move insant':
				cameraChangeInstant = value1.toLowerCase() == 'true' ? true : false;

			case 'show fake time left':
				tweenToFakeTime(Std.parseFloat(value1), Std.parseFloat(value2));

			case 'show real time left':
				tweenToRealTime(Std.parseFloat(value1));

			case 'set Glitch timer':
				timeResetGlitch = Conductor.crochet/1000*Std.parseFloat(value1);

			case 'darken the bg':
				var val1:FlxColor = value1.toLowerCase() == 'true' ? 0xFF3A3A3A : 0xFFFFFFFF;
				var val2:Int = Std.parseInt(value2);
				if(Math.isNaN(val2) || val2 == 0) val2 = 4;

				var bgElements:Array<FlxSprite> = [];

				var customColor:Bool = false;
				switch(curStage.toLowerCase())
				{
					case 'glitch':
						bgElements = [currentStageObject.back, currentStageObject.front, currentStageObject.chandelier];
						customColor = true;
						val1 = value1.toLowerCase() == 'true' ? 0xFF642CFF : 0xFFFFFFFF;

						if(ClientPrefs.data.shaders) currentStageObject.back.shader = value1.toLowerCase() == 'true' ? bgGlitchGlitch : null;
				}

				//if(bgElements.length == 0) return; //prevent a crash yeah
				//don't return, this prevents the "onEvent()" thing from happening in stages for this event

				if(bgElements.length >= 0){
					for (bgItem in bgElements)
					{
						var lastColor:FlxColor = !customColor ? (value1.toLowerCase() == 'true' ? 0xFFFFFFFF : 0xFF3A3A3A) : (value1.toLowerCase() == 'true' ? 0xFFFFFFFF: val1);
						FlxTween.color(bgItem, Conductor.crochet/1000*val2, lastColor, val1);
					}
				}

			case 'Black bars':
				//if(topBarsALT == null) return;
				//same thing here
				var val1:Bool = value1.toLowerCase() == 'true' ? true : false;
				var val2:Int = Std.parseInt(value2);
				if(Math.isNaN(val2) || val2 == 0) val2 = 4;

				var rect1 = val1 ? 0 : -topBarsALT.width;
				var rect2 = val1 ? 0 : FlxG.width;

				if(topBarsALT != null && bottomBarsALT != null){
					FlxTween.tween(topBarsALT, {x: rect1}, Conductor.crochet/1000*val2, {ease: FlxEase.sineInOut});
					FlxTween.tween(bottomBarsALT, {x: rect2}, Conductor.crochet/1000*val2, {ease: FlxEase.sineInOut});
				}

			case "cameraFreeMove":
				currentlyMovingCamera = true;
				
			case "stopCameraFreeMove":
				currentlyMovingCamera = false;

			case "focusCameraOnCharacter":
				cameraFocusedOnChar = true;
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'dad' | 'enemy' | 'opponent' | 'opponent1':
						charType = 0;

					case 'boyfriend' | 'bf':
						charType = 1;

					case 'gf' | 'girlfriend':
						charType = 2;

					case 'mom' | 'opponent2':
						charType = 3;

					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}
				cameraFocusedOn = charType;

			case "addCameraOffset":
				var one = Std.parseInt(value1);
				if(Math.isNaN(one)) one = 0;
				var two = Std.parseInt(value2);
				if(Math.isNaN(two)) two = 0;
				cameraEventOffset = new FlxPoint(one, two);

			case "focusCameraOnPoint":
				var one = Std.parseInt(value1);
				if(Math.isNaN(one)) one = 0;
				var two = Std.parseInt(value2);
				if(Math.isNaN(two)) two = 0;
				eventCameraPoint = new FlxPoint(one, two);

			case "Deactivate CamFollow":
				camfollowEnabled = !camfollowEnabled;

			case "remove Cam Actuation":
				camZooming = !camZooming;
			case 'zoomIn':
				var easing:String = null;
				var duration:Null<Float> = null;
				var zoomAdd:Null<Float> = null;
				var realZoom:Null<Float> = null;

				var temp = value2.split(',');
				if(temp.length >= 0) duration = Std.parseFloat(temp[0]);
				if(temp.length > 0)	easing = temp[1];

				temp = value1.split(',');

				if(duration == null){
					if(!Math.isNaN(Std.parseFloat(value2))){
						duration = Std.parseFloat(value2);
					} else {
						duration = 0.8;
					}
				}
				if(easing == null){
					easing = 'sineInOut';
				}

				//Handle the zoom itself now
				if(value1.contains("cur")){
					zoomAdd = Std.parseFloat(temp[1]);
					realZoom = defaultCamZoom + zoomAdd;
				} else {
					realZoom = Std.parseFloat(value1);
				}

				if(value2 != null){
					if(duration != 0){
						if(zoomTween != null) zoomTween.cancel();
						zoomTween = FlxTween.tween(camGame, {zoom: realZoom}, duration, {ease:getFlxEaseByString(easing), onComplete:onZoomFinishedThingEvent});
						modchartTweens.set("Zoom" + Conductor.songPosition, zoomTween);
					} else {
						camGame.zoom = realZoom;
						defaultCamZoom = realZoom;
					}
				} else {
					defaultCamZoom = realZoom;
				}
				camEventZooming = true;

			case "Camera Twist":
				//gaming
				
			case 'Chromatic Aberrate':
				if(ClientPrefs.data.shaders){
					FlxTween.tween(chromaticPoint, {x: Std.parseInt(value1)}, Std.parseFloat(value2));
				}
				
			case 'Pixelated Effect':
				if(ClientPrefs.data.shaders){
					var splitValue = value1.split(",");
					FlxTween.tween(pixelPoint, {x: Std.parseInt(splitValue[0].trim())}, Std.parseFloat(value2));
					FlxTween.tween(scanlinePoint, {x: Std.parseInt(splitValue[1].trim())}, Std.parseFloat(value2));
				}

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
							case 3: char = mom;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'mom' | 'opponent 2':
						charType = 3;
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var oldBfAlpha:Float = boyfriend.alpha;
							//var oldBfCTrans:ColorTransform = boyfriend.colorTransform;
							boyfriend.alpha = 0.00001;
							songCharacters[0] = boyfriendMap.get(value2);
							boyfriend = songCharacters[0];
							boyfriend.alpha = oldBfAlpha;
							//boyfriend.setColorTransform(
							//	oldBfCTrans.redMultiplier,
							//	oldBfCTrans.greenMultiplier,
							//	oldBfCTrans.blueMultiplier,
							//	oldBfCTrans.alphaMultiplier,
							//	Std.int(oldBfCTrans.redOffset),
							//	Std.int(oldBfCTrans.greenOffset),
							//	Std.int(oldBfCTrans.blueOffset),
							//	Std.int(oldBfCTrans.alphaOffset),
							//);
							iconP1.changeIcon(boyfriend.healthIcon);
						}

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}
							var oldDadAlpha:Float = dad.alpha;
							//var oldDadCTrans:ColorTransform = dad.colorTransform;
							dad.alpha = 0.00001;
							songCharacters[2] = dadMap.get(value2);
							dad = songCharacters[2];
							dad.alpha = oldDadAlpha;
							//dad.setColorTransform(
							//	oldDadCTrans.redMultiplier,
							//	oldDadCTrans.greenMultiplier,
							//	oldDadCTrans.blueMultiplier,
							//	oldDadCTrans.alphaMultiplier,
							//	Std.int(oldDadCTrans.redOffset),
							//	Std.int(oldDadCTrans.greenOffset),
							//	Std.int(oldDadCTrans.blueOffset),
							//	Std.int(oldDadCTrans.alphaOffset),
							//);
							iconP2.changeIcon(dad.healthIcon);
						}

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								songCharacters[1] = gfMap.get(value2);
								gf = songCharacters[1];
								gf.alpha = lastAlpha;
								iconP3.changeIcon(gf.healthIcon);
							}
						}
					case 3:
						if(mom != null)
						{
							if(mom.curCharacter != value2)
							{
								if(!momMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = mom.alpha;
								mom.alpha = 0.00001;
								songCharacters[3] = momMap.get(value2);
								mom = songCharacters[3];
								mom.alpha = lastAlpha;
								iconP4.changeIcon(mom.healthIcon);
							}
						}
				}
				switch(dad.curCharacter){
					case 'glitch' | 'glitch-alt':
						if(ClientPrefs.data.shaders){
							var glitchCharShader = new GlitchPosterize();
							dad.shader = glitchCharShader.shader;
							glitchCharShader.amount = dad.curCharacter == "glitch" ? 0.03 : 0.2;
						}
						dad.alpha = 1;
						dad.blend = BlendMode.NORMAL;
					case 'guidingLight':
						dad.alpha = 0.8;
						dad.blend = BlendMode.HARDLIGHT;
					default:
						if(dad.alpha > 0.1){
							dad.alpha = 1;
						} else {
							dad.alpha = 0.00001;
						}
						dad.blend = BlendMode.NORMAL;
				}
		
				if(gf != null){
					switch(gf.curCharacter){
						case 'glitch' | 'glitch-alt':
							if(ClientPrefs.data.shaders){
								var glitchCharShader = new GlitchPosterize();
								gf.shader = glitchCharShader.shader;
								glitchCharShader.amount = gf.curCharacter == "glitch" ? 0.03 : 0.2;
							}
							gf.alpha = 1;
							gf.blend = BlendMode.NORMAL;
						case 'guidingLight':
							gf.alpha = 0.8;
							gf.blend = BlendMode.HARDLIGHT;
						default:
							if(gf.alpha > 0.1){
								gf.alpha = 1;
							} else {
								gf.alpha = 0.00001;
							}
							gf.blend = BlendMode.NORMAL;
					}
				}
		
				if(mom != null){
					switch(mom.curCharacter){
						case 'glitch' | 'glitch-alt':
							if(ClientPrefs.data.shaders){
								var glitchCharShader = new GlitchPosterize();
								mom.shader = glitchCharShader.shader;
								glitchCharShader.amount = mom.curCharacter == "glitch" ? 0.03 : 0.2;
							}
							mom.alpha = 1;
							mom.blend = BlendMode.NORMAL;
						case 'guidingLight':
							mom.alpha = 0.8;
							mom.blend = BlendMode.HARDLIGHT;
						default:
							if(mom.alpha > 0.1){
								mom.alpha = 1;
							} else {
								mom.alpha = 0.00001;
							}
							mom.blend = BlendMode.NORMAL;
					}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				#if LUA_ALLOWED
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1) {
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					FunkinLua.setVarInArray(this, value1, value2);
				}
				#end

			case 'Tween Property':
				var propertyToModify:String = value1;
				var killMe:Array<String> = propertyToModify.split('.');

				if(value1 != ""){
					var easing:String = "sineInOut";
					var duration:Float = 0.6;
					var startValue:Float = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1]);
					var endValue:Float = startValue*2;

					var value2Arr:Array<String> = value2.split(";");
					if(value2Arr.length == 1) endValue = Std.parseFloat(value2Arr[0]);
					if(value2Arr.length >= 2) {
						startValue = Std.parseFloat(value2Arr[0]);
						endValue = Std.parseFloat(value2Arr[1]);
					}
					if(value2Arr.length == 3) duration = Std.parseFloat(value2Arr[2]);
					if(value2Arr.length == 4) easing = Std.string(value2Arr[3]);
	
					FlxTween.num(startValue, endValue, duration, {ease: getFlxEaseByString(easing)}, function(flt){
						if(killMe.length > 1) {
							FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], flt);
						} else {
							FunkinLua.setVarInArray(this, propertyToModify, flt);
						}
					});
				}

			case 'triggerTaiko':
				if(taikoActive){
					FlxTween.tween(taikoSpot, {alpha: 0.1}, 1);
				} else {
					FlxTween.tween(taikoSpot, {alpha: 0.8}, 1);
				}
				taikoActive = !taikoActive;

				if(hasVignette)
					{
						FlxTween.num(!taikoActive ? 10 : 25, !taikoActive ? 25 : 10, 1, function(num){
							vignetteShader.darkness = num;
						});
						FlxTween.num(!taikoActive ? 1.0 : 0.25, !taikoActive ? 0.25 : 1.0, 1, function(num){
							vignetteShader.extent = num;
						});
					}

			case 'cameraFlashGame':
				camGame.flash(FlxColor.fromString(value1), Std.parseFloat(value2), null, true);
			case 'cameraFlashHud':
				camHUD.flash(FlxColor.fromString(value1), Std.parseFloat(value2), null, true);
			case 'cameraFadeGame':
				camGame.fade(FlxColor.fromString(value1), Std.parseFloat(value2), false, null);
			case 'cameraFadeHud':
				camHUD.fade(FlxColor.fromString(value1), Std.parseFloat(value2), false, null);
			case 'endFadeGame':
				camGame.fade(FlxColor.fromString(value1), Std.parseFloat(value2), true, null);
			case 'endFadeHud':
				camHUD.fade(FlxColor.fromString(value1), Std.parseFloat(value2), true, null);
			case 'badApple':
				isBadApple = true;
				var theMapThing = currentStageObject.getBadAppleShit();

				var backgroundItems:Array<FlxSprite> = theMapThing.get("background");
				if(backgroundItems == null) backgroundItems = [];
				var foregroundItems:Array<FlxSprite> = theMapThing.get("foreground");
				if(foregroundItems == null) foregroundItems = [];
				var specialItems:Array<Dynamic> = theMapThing.get("special");
				if(specialItems == null) specialItems = [];
				var chars:Array<FlxSprite> = theMapThing.get("boyfriend");
				if(chars == null) chars = [];

				if(value1 == "") value1 = "0";
				var typeOfBadApple = Std.parseInt(value1);
				var duration = Std.parseFloat(value2);

				switch(typeOfBadApple){
					case 0:
						badAppleWhite = new FlxSprite(-500, -300).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.WHITE);
						badAppleWhite.alpha = 0.0001;
						insert(members.indexOf(backgroundItems != null ? backgroundItems[0]:dadGroup), badAppleWhite);

						FlxTween.tween(badAppleWhite, {alpha: 1}, duration, {ease: FlxEase.quintOut});
						for(thing in backgroundItems){
							FlxTween.num(0, 255, duration, {ease: FlxEase.quintOut}, function(num){
								thing.setColorTransform(0,0,0,1,Math.round(num),Math.round(num),Math.round(num),0);
							});
						}
						for(fore in foregroundItems){
							FlxTween.tween(fore, {alpha: 0}, duration, {ease: FlxEase.quintOut});
						}
						for(special in specialItems){
							if(special.length > 0){
								FlxTween.num(0, 255*special[1], duration, {ease: FlxEase.quintOut}, function(num){
									special[0].setColorTransform(0,0,0,1,Math.round(num),Math.round(num),Math.round(num),0);
								});
							}
						}

						for(char in songCharacters){
							if(char != null) FlxTween.color(char, duration, 0xFFFFFFFF, 0xFF000000, {ease: FlxEase.quintOut});
						}
						for(char in chars){
							if(char != null) FlxTween.color(char, duration, 0xFFFFFFFF, 0xFF000000, {ease: FlxEase.quintOut});
						}
					case 1:
						for(thing in backgroundItems){
							FlxTween.color(thing, duration, 0xFFFFFFFF, 0xFF000000, {ease: FlxEase.quintOut});
						}
						for(fore in foregroundItems){
							FlxTween.tween(fore, {alpha: 0}, duration, {ease: FlxEase.quintOut});
						}
						for(special in specialItems){
							if(special.length > 0){
								FlxTween.num(0, 255*(1 - special[1]), duration, {ease: FlxEase.quintOut}, function(num){
									special[0].setColorTransform(0,0,0,1,Math.round(num),Math.round(num),Math.round(num),0);
								});
							}
						}

						for(char in songCharacters){
							FlxTween.num(0, 255, duration, {ease: FlxEase.quintOut}, function(num){
								if(char != null) char.setColorTransform(0,0,0,1,Math.round(num),Math.round(num),Math.round(num),0);
							});
						}
						for(char in chars){
							FlxTween.num(0, 255, duration, {ease: FlxEase.quintOut}, function(num){
								if(char != null) char.setColorTransform(0,0,0,1,Math.round(num),Math.round(num),Math.round(num),0);
							});
						}
					default:
				}
			case 'endBadApple':
				isBadApple = false;
				var theMapThing = currentStageObject.getBadAppleShit();

				var backgroundItems:Array<FlxSprite> = theMapThing.get("background");
				if(backgroundItems == null) backgroundItems = [];
				var foregroundItems:Array<FlxSprite> = theMapThing.get("foreground");
				if(foregroundItems == null) foregroundItems = [];
				var specialItems:Array<Dynamic> = theMapThing.get("special");
				if(specialItems == null) specialItems = [];
				var chars:Array<FlxSprite> = theMapThing.get("boyfriend");
				if(chars == null) chars = [];

				if(value1 == "") value1 = "0";
				var typeOfBadApple = Std.parseInt(value1);
				var duration = Std.parseFloat(value2);

				switch(typeOfBadApple){
					case 0:
						//do black chars on white bg
						if(badAppleWhite != null){
							FlxTween.tween(badAppleWhite, {alpha: 0}, duration, {ease: FlxEase.quintOut, onComplete: function(twn){
								remove(badAppleWhite);
							}});
						}

						for(thing in backgroundItems){
							FlxTween.num(255, 0, duration, {ease: FlxEase.quintOut}, function(num){
								thing.setColorTransform(1,1,1,1,Math.round(num),Math.round(num),Math.round(num),0);
							});
						}
						for(fore in foregroundItems){
							FlxTween.tween(fore, {alpha: 1}, duration, {ease: FlxEase.quintOut});
						}
						for(special in specialItems){
							if(special.length > 0){
								FlxTween.num(255*special[1], 0, duration, {ease: FlxEase.quintOut}, function(num){
									special[0].setColorTransform(1,1,1,1,Math.round(num),Math.round(num),Math.round(num),0);
								});
							}
						}

						for(char in songCharacters){
							if(char != null) FlxTween.color(char, duration, 0xFF000000, 0xFFFFFFFF, {ease: FlxEase.quintOut});
						}
						for(char in chars){
							if(char != null) FlxTween.color(char, duration, 0xFF000000, 0xFFFFFFFF, {ease: FlxEase.quintOut});
						}
					case 1:
						for(thing in backgroundItems){
							FlxTween.color(thing, duration, 0xFF000000, 0xFFFFFFFF, {ease: FlxEase.quintOut});
						}
						for(fore in foregroundItems){
							FlxTween.tween(fore, {alpha: 1}, duration, {ease: FlxEase.quintOut});
						}
						for(special in specialItems){
							if(special.length > 0){
								FlxTween.num(255*(1 - special[1]), 0, duration, {ease: FlxEase.quintOut}, function(num){
									special[0].setColorTransform(1,1,1,1,Math.round(num),Math.round(num),Math.round(num),0);
								});
							}
						}

						for(char in songCharacters){
							FlxTween.num(255, 0, duration, {ease: FlxEase.quintOut}, function(num){
								if(char != null) char.setColorTransform(1,1,1,1,Math.round(num),Math.round(num),Math.round(num),0);
							});
						}
						for(char in chars){
							FlxTween.num(255, 0, duration, {ease: FlxEase.quintOut}, function(num){
								if(char != null) char.setColorTransform(1,1,1,1,Math.round(num),Math.round(num),Math.round(num),0);
							});
						}
					default:
						//do nothing
				}
			case 'Cinematics Bar':
				var time = Std.parseFloat(value2);
				var distance = Std.parseInt(value1);
				FlxTween.tween(bottomCinematicBar, {y: 720 - distance*2}, time, {ease: FlxEase.quintOut});
				FlxTween.tween(topCinematicBar, {y: -400 + distance*2}, time, {ease: FlxEase.quintOut});

			case 'moveCamera':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}
		}
		
		for(mechanic in activeMechanics)
		{
			mechanic.triggerEventNote(eventName, value1, value2, strumTime);
		}

		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			if(cameraChangeInstant) moveCamera(true);
		}
		else
		{
			if(cameraChangeInstant) moveCamera(false);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		switch (curStage)
		{
			case 'halt':
				offsetX = Std.int(dad.getMidpoint().x);
				offsetY = Std.int(dad.getMidpoint().y);
				bfoffsetX = Std.int(boyfriend.getMidpoint().x);
				bfoffsetY = Std.int(boyfriend.getMidpoint().y - 150);
			case 'drip':
				offsetX = Std.int(dad.getMidpoint().x - 300);
				offsetY = Std.int(dad.getMidpoint().y);
				bfoffsetX = Std.int(boyfriend.getMidpoint().x - 100);
				bfoffsetY = Std.int(boyfriend.getMidpoint().y - 100);
			case 'daddyIssues':
				offsetX = Std.int(dad.getMidpoint().x + 500);
				offsetY = Std.int(dad.getMidpoint().y + 300);
				bfoffsetX = Std.int(boyfriend.getMidpoint().x - 100);
				bfoffsetY = Std.int(boyfriend.getMidpoint().y + 200);
		}

		if(!currentlyMovingCamera){
			if(SONG.notes[curSection]!=null && SONG.notes[curSection].mustHitSection){
				if(boyfriend.isAnimateAtlas && boyfriend.alpha >= 0.1 && boyfriendGroup.visible && !currentlyMovingCamera) {
					bfoffsetX += 100;
					bfoffsetY += 200;
				}
				camFollow.set(bfoffsetX,bfoffsetY);
			} else {
				camFollow.set(offsetX,offsetY);
			}
		}

		if(currentlyMovingCamera && eventCameraPoint != null){
			camFollow = eventCameraPoint;
		}

		if(currentlyMovingCamera && cameraFocusedOnChar){
			switch(cameraFocusedOn){
				case 0:
					offsetX = Std.int(boyfriend.cameraPosition[0] + boyfriend.getMidpoint().x - 100);
					offsetY = Std.int(boyfriend.cameraPosition[1] + boyfriend.getMidpoint().y - 100);
					bfoffsetX = Std.int(boyfriend.cameraPosition[0] + boyfriend.getMidpoint().x - 100);
					bfoffsetY = Std.int(boyfriend.cameraPosition[1] + boyfriend.getMidpoint().y - 100);
				case 1:
					offsetX = Std.int(dad.cameraPosition[0] + dad.getMidpoint().x + 150);
					offsetY = Std.int(dad.cameraPosition[1] + dad.getMidpoint().y - 100);
					bfoffsetX = Std.int(dad.cameraPosition[0] + dad.getMidpoint().x + 150);
					bfoffsetY = Std.int(dad.cameraPosition[1] + dad.getMidpoint().y - 100);
				case 2:
					if(gf != null){
						offsetX = Std.int(gf.cameraPosition[0]+ gf.getMidpoint().x);
						offsetY = Std.int(gf.cameraPosition[1]+ gf.getMidpoint().y);
						bfoffsetX = Std.int(gf.cameraPosition[0] + gf.getMidpoint().x);
						bfoffsetY = Std.int(gf.cameraPosition[1]+ gf.getMidpoint().y);
					}
				case 3:
					if(mom != null){
						offsetX = Std.int(mom.cameraPosition[0] + mom.getMidpoint().x);
						offsetY = Std.int(mom.cameraPosition[1]+ mom.getMidpoint().y);
						bfoffsetX = Std.int(mom.cameraPosition[0] + mom.getMidpoint().x);
						bfoffsetY = Std.int(mom.cameraPosition[1]+ mom.getMidpoint().y);
					}
				default:
					offsetX = Std.int(dad.getGraphicMidpoint().x);
					offsetY = Std.int(dad.getGraphicMidpoint().y);
					bfoffsetX = Std.int(dad.getGraphicMidpoint().x);
					bfoffsetY = Std.int(dad.getGraphicMidpoint().y);
			}
		}
		if(SONG.notes[curSection]!=null && SONG.notes[curSection].mustHitSection)
		{
			camFollow.set(bfoffsetX,bfoffsetY);
		}
		else
		{
			camFollow.set(offsetX,offsetY);
		}

		if(cameraEventOffset != null) camFollow += cameraEventOffset;

		if(cameraChangeInstant) snapCamFollowToPos(camFollow.x, camFollow.y);
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		MenuSongManager.curMusic = "";
		updateTime = false;
		FlxG.sound.music.volume = 0;
		try{
			vocals.volume = 0;
			vocals.pause();
		} catch(e) { trace(e); }
		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public static var targetDoor:Int = 0;
	public var transitioning = false;
	public function endSong()
	{
		#if mobile
			mobileControls.visible = false;
		#end
			
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = true;
		inCutscene = false;
		updateTime = false;
		MenuSongManager.curMusic = "";

		deathCounter = 0;
		seenCutscene = false;

		if(!transitioning) //moved it up for the seek achievement
		{
			if (SONG.validScore)
			{
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song.replace("-hell", ""), songScore, storyDifficulty, songMisses, percent);
				Leaderboards.addHighScore(
					SONG.song.toLowerCase().replace("-hell", ""), 
					CoolUtil.defaultDifficulties[storyDifficulty].toLowerCase(), 
					CoolUtil.calculateCurrentChartHash(), 
					percent, 
					songScore, 
					songMisses, 
					activeModifiers
				);
			}
		}
		checkForAchievement();
		AwardsManager.onEndSong(this);

		if(!transitioning)
		{
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{				
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);
				@:privateAccess {
					var fxFadeAlpha = camGame._fxFadeAlpha;
					camGame.fade(0xFF000000, 1, false);
					camGame._fxFadeAlpha = fxFadeAlpha;
				}

				DoorsUtil.recalculateRunScores(percent, songScore, songMisses, SONG.song);
				DoorsUtil.recalculateSongEntitiesEncountered();
				if (storyPlaylist.length <= 0)
				{
					DoorsUtil.curRun.curDoor = targetDoor;
					DoorsUtil.saveStoryData();

					canResync = false;
					moneyIndicator.fadeIn();
					knobIndicator.fadeIn();
					new FlxTimer().start(1, function(tmr){
						add(new MoneyIndicator.MoneyPopup(moneyIndicator.x,moneyIndicator.y,Math.ceil(Math.max(25, Math.floor(((30 * (songLength / 60000)) * percent) - (songMisses * 8)))), moneyIndicator, false, false, camHUD));

						switch(SONG.song.toLowerCase()){
							case "encounter" | "delve":
								add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
									10, 
									knobIndicator, 
									true, true, camHUD));
							case "not-a-sound"  | "not-a-sound-hell" | "tranquil":
								add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
									30, 
									knobIndicator, 
									true, true, camHUD));
							case "ready-or-not" | "found-you":
								add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
									40, 
									knobIndicator, 
									true, true, camHUD));
							case "imperceptible" | "hyperacusis":
								add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
									75, 
									knobIndicator, 
									true, true, camHUD));
							default:
								add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
									Math.floor(Math.max(25, 
												Math.floor(((30 * (songLength / 60000)) * percent) 
												- (songMisses * 8))) / 10), 
									knobIndicator, 
									true, true, camHUD));
						}
					});
					new FlxTimer().start(4, function(tmr:FlxTimer){
						WeekData.loadTheFirstEnabledMod();

						cancelMusicFadeTween();
						if(FlxTransitionableState.skipNextTransIn) {
							CustomFadeTransition.nextCamera = null;
						}
						if(targetDoor == 100){
							MusicBeatState.switchState(new RunResultsState(F1_WIN));
						} else {
							MusicBeatState.switchState(new StoryMenuState());
						}
						if(!DoorsUtil.modifierActive(54) && !DoorsUtil.modifierActive(55)) {

							if (SONG.validScore)
							{
								Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
							}

							FlxG.save.flush();
						}
						changedDifficulty = false;
					});
				}
				else
				{
					add(new MoneyIndicator.MoneyPopup(moneyIndicator.x,moneyIndicator.y,Math.ceil(Math.max(25, Math.floor(((30 * (songLength / 60000)) * percent) - (songMisses * 8)))), moneyIndicator, false, false, camHUD));

					switch(SONG.song.toLowerCase()){
						case "encounter" | "delve":
							add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
								10, 
								knobIndicator, 
								true, true, camHUD));
						case "not-a-sound"  | "not-a-sound-hell" | "tranquil":
							add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
								30, 
								knobIndicator, 
								true, true, camHUD));
						case "ready-or-not" | "found-you":
							add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
								40, 
								knobIndicator, 
								true, true, camHUD));
						case "imperceptible" | "hyperacusis":
							add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
								75, 
								knobIndicator, 
								true, true, camHUD));
						default:
							add(new MoneyIndicator.MoneyPopup(knobIndicator.x,knobIndicator.y,
								Math.floor(Math.max(25, 
											Math.floor(((30 * (songLength / 60000)) * percent) 
											- (songMisses * 8))) / 10), 
								knobIndicator, 
								true, true, camHUD));
					}

					var difficulty:String = CoolUtil.getDifficultyFilePath();

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					canResync = false;
					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				canResync = false;
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new NewFreeplayState());
				changedDifficulty = false;
			}
			transitioning = true;
		}

		for(mechanic in activeMechanics)
		{
			mechanic.endSong();
		}

		return true;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	function doGhostAnim(char:Character, animToPlay:String, noteData:Int)
	{
		char.playGhostAnim(animToPlay, noteData);
	}

	private function cachePopUpScore()
	{
		Paths.image("sick");
		Paths.image("good");
		Paths.image("bad");
		Paths.image("shit");
		Paths.image("combo");
		
		for (i in 0...10) {
			Paths.image('num' + i);
		}
	}

	var comboBonus:Int = 100;
	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		if(comboPosition[0] == -420 && comboPosition[1] == 69){
			comboPosition[0] = (dad.getMidpoint().x + boyfriend.getMidpoint().x) / 2;
			comboPosition[1] = (dad.getMidpoint().y + boyfriend.getMidpoint().y) / 2;
		}
		coolText.setPosition(comboPosition[0], comboPosition[1]);

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			var baseScore = daRating.score;
			comboBonus += daRating.hitBonus - daRating.hitPunishment;
			comboBonus = Math.floor(FlxMath.bound(comboBonus, 0, 100));
			var bonusScore = daRating.hitBonusValue * Math.sqrt(comboBonus);
			var scoreToAdd = baseScore + bonusScore;

			songScore += Math.round(scoreToAdd * (isStoryMode ? 1 : ModifierManager.freeplayScoreMod));
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		rating.loadGraphic(Paths.image(daRating.image));
		rating.screenCenter();
		rating.x = coolText.x - (rating.width / 2) + 30;
		rating.y = coolText.y - 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		if(curStage == "corridor" && currentStageObject.isRunning){
			rating.acceleration.y = FlxG.random.int(50, 120) * playbackRate * playbackRate;
			rating.velocity.y = 0;
			if(!currentStageObject.isRunningFast) rating.velocity.x = FlxG.random.int(-2830, -2800) * playbackRate / 5;
			else rating.velocity.x = FlxG.random.int(-3240, -3200) * playbackRate / 5;
		}
		rating.visible = (!ClientPrefs.data.hideHud && showRating);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('combo'));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.y = coolText.y;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		if(curStage == "corridor" && currentStageObject.isRunning){
			comboSpr.acceleration.y = FlxG.random.int(50, 120) * playbackRate * playbackRate;
			comboSpr.velocity.y = 0;
			if(!currentStageObject.isRunningFast) comboSpr.velocity.x = FlxG.random.int(-2830, -2800) * playbackRate / 5;
			else comboSpr.velocity.x = FlxG.random.int(-3240, -3200) * playbackRate / 5;
		}

		addBehindDad(rating);

		rating.setGraphicSize(Std.int(rating.width * comboScale));
		rating.antialiasing = ClientPrefs.globalAntialiasing;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * comboScale));
		comboSpr.antialiasing = ClientPrefs.globalAntialiasing;

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			addBehindDad(comboSpr);
		}

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('num' + Std.int(i)));
			numScore.screenCenter();
			numScore.x = coolText.x + ((43 * (comboScale + 0.3)) * daLoop) - 90;
			numScore.y = coolText.y + 80;

			numScore.antialiasing = ClientPrefs.globalAntialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * (comboScale - 0.2)));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			if(curStage == "corridor" && currentStageObject.isRunning){
				numScore.acceleration.y = FlxG.random.int(50, 120) * playbackRate * playbackRate;
				numScore.velocity.y = 0;
				if(!currentStageObject.isRunningFast) numScore.velocity.x = FlxG.random.int(-2830, -2800) * playbackRate / 5;
				else numScore.velocity.x = FlxG.random.int(-3240, -3200) * playbackRate / 5;
			}
			numScore.visible = !ClientPrefs.data.hideHud;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				addBehindDad(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void {
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if (!controls.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
	}
	public var strumsBlocked:Array<Bool> = [];

	private function keyPressed(key:Int)
	{
		if(cpuControlled || paused || key < 0) return;
		if(!generatedMusic || endingSong || boyfriend.stunned) return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return n != null && canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(sortHitNotes);

		var shouldMiss:Bool = !(ClientPrefs.data.ghostTapping) || (key > 3 && taikoActive);

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}

			goodNoteHit(funnyNote);
		}
		else {
			if (shouldMiss && !boyfriend.stunned) {
				noteMissPress(key);
			}
		}

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrums.members[key];
		if(strumsBlocked[key] != true && spr != null && spr.strumSprite.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(!cpuControlled && startedCountdown && !paused)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
			}
		}
		return -1;
	}

	// Hold notes
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			if (notes.length > 0) {
				for (n in notes) { // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit
						&& n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote) {
						var released:Bool = !holdArray[n.noteData];
						
						if (!released)
							goodNoteHit(n);
					}
				}
			}

			if (!holdArray.contains(true) || endingSong)
				playerDance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}	

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});
		
		noteMissCommon(daNote.noteData, daNote);
		
		switch (SONG.song)
		{
			case "not-a-sound"  | "not-a-sound-hell" | "tranquil" | "imperceptible" | 'hyperacusis' | 'depths-below':
				if (daNote.noteData > 3) //heartBeat
				{
					if(!DoorsUtil.modifierActive(35)){
						if(storyDifficulty == 3){
							health -= 1.5 * healthLoss;
						} else if(storyDifficulty > 1){
							health -= 1 * healthLoss;
						} else {
							health -= 0.5 * healthLoss;
						}
					}
					MenuSongManager.playSoundWithRandomPitch('HeartbeatMessup', [0.8, 1.2], FlxG.random.float(0.6, 0.8));

					if(DoorsUtil.modifierActive(24)){
						health = -1 * healthLoss;
					}
				}
		}

		final end:Note = daNote.isSustainNote ? daNote.parent.tail[daNote.parent.tail.length - 1] : daNote.tail[daNote.tail.length - 1];
		if (end != null && end.extraData['holdSplash'] != null) {
			end.extraData['holdSplash'].visible = false;
		}
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		noteMissCommon(direction, null, true);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
	}

	function noteMissCommon(direction:Int, note:Note = null, ?isGhostTap:Bool = false) {
		// score and data
		for(mechanic in activeMechanics)
			{
				mechanic.noteMissEarly(direction, note);
			}

		var subtract:Float = 0.05;
		if(note != null) subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -Tahir
			}

			if (note.missed)
				return;
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed)
				return; 
			
			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}
		combo = 0;

		health -= subtract * healthLoss;
		if(!practiceMode) songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		// play character anims
		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;
		
		if(char != null && char.hasMissAnimations)
		{
			var suffix:String = '';
			if(note != null) suffix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + suffix;
			char.playAnim(animToPlay, true);
		}
		vocals.volume = 0;

		for(mechanic in activeMechanics)
		{
			mechanic.noteMissCommon(direction, note);
		}

		switch (SONG.song)
		{
			case "not-a-sound"  | "not-a-sound-hell" | "tranquil" | "imperceptible" | 'hyperacusis' | 'depths-below':
				if(note != null) return;
				if(isGhostTap) {
					health -= 0.05 * healthLoss;
					return;
				} 

				AwardsManager.hasMissedHeartbeat = false;

				if(!DoorsUtil.modifierActive(35)){
					if(storyDifficulty == 3){
						health -= 1.5 * healthLoss;
					} else if(storyDifficulty > 1){
						health -= 1 * healthLoss;
					} else {
						health -= 0.5 * healthLoss;
					}
				}
				MenuSongManager.playSoundWithRandomPitch('HeartbeatMessup', [0.8, 1.2], FlxG.random.float(0.6, 0.8));

				if(DoorsUtil.modifierActive(24)){
					health = -1 * healthLoss;
				}
		}
	}	

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		var assignedChar = note.assignedChars;

		if(assignedChar != null && assignedChar.length > 0 && !note.noAnimation){
			var charList:Array<Dynamic> = [];
			for (j in assignedChar){
				charList.push(songCharacters[j]);
			}
			var altAnim:String = note.animSuffix;
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;

			if(charList != []) {
				for(char in charList){
					if(note.noteType == 'Hey!' && char.animOffsets.exists('hey')) {
						char.playAnim('hey', true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}
					if (!note.isSustainNote && noteRows[note.mustPress?0:1][note.row].length > 1) {
						// potentially have jump anims?
						var chord = noteRows[note.mustPress?0:1][note.row];
						var realAnim = singAnimations[Std.int(Math.abs(chord[0].noteData))] + altAnim;
						
						var otherAnim = realAnim;
						if (chord.length > 0) {
							otherAnim = singAnimations[Std.int(Math.abs(chord[1].noteData))] + altAnim;
						}

						if (char.mostRecentRow != note.row)
						{
							char.playAnim(realAnim, true);
							char.holdTimer = 0;
						}

						if(char.mostRecentRow != note.row){
							doGhostAnim(char, otherAnim, chord[1].noteData);
						}
						char.mostRecentRow = note.row;
					} else {
						char.playAnim(animToPlay + altAnim, true);
						char.holdTimer = 0;
						// char.angle = 0;
					}
				}
				
				switch(note.noteData){
					case 0:
						camX = -20;
						camY = 0;
					case 1:
						camX = 0;
						camY = 15;
						defaultCamAngle = 0;
					case 2:
						camX = 0;
						camY = -15;
						defaultCamAngle = 0;
					case 3:
						camX = 20;
						camY = 0;
				}
			}
		} else {
			if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
				dad.playAnim('hey', true);
				dad.specialAnim = true;
				dad.heyTimer = 0.6;
			} else if(!note.noAnimation) {
				var altAnim:String = note.animSuffix;
	
				if (SONG.notes[curSection] != null)
				{
					if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
						altAnim = '-alt';
					}
				}
	
				var char:Character = dad;
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;

				if(note.noteType == 'GF Sing'){
					char = null;
					gf.playAnim(animToPlay, true);
					gf.holdTimer = 0;
				}
				else if (note.noteType == 'Mom Sing')
				{
					char = null;
					mom.playAnim(animToPlay, true);
					mom.holdTimer = 0;
				}
				else if (note.noteType == 'Mom GF Sing')
				{
					char = null;
					mom.playAnim(animToPlay, true);
					mom.holdTimer = 0;
					gf.playAnim(animToPlay, true);
					gf.holdTimer = 0;
				}
				else if (note.noteType == 'Dad GF Sing')
				{
					char = null;
					dad.playAnim(animToPlay, true);
					dad.holdTimer = 0;
					gf.playAnim(animToPlay, true);
					gf.holdTimer = 0;
				}
				else if (note.noteType == 'Dad Mom Sing')
				{
					char = null;
					dad.playAnim(animToPlay, true);
					dad.holdTimer = 0;
					mom.playAnim(animToPlay, true);
					mom.holdTimer = 0;
				}
				else if (note.noteType == 'All Sing'){
					char = null;
					mom.playAnim(animToPlay, true);
					mom.holdTimer = 0;
					dad.playAnim(animToPlay, true);
					dad.holdTimer = 0;
					gf.playAnim(animToPlay, true);
					gf.holdTimer = 0;
				}
	
				if(char != null)
				{
					dad.playAnim(animToPlay + altAnim, true);
					dad.holdTimer = 0;
					if (!note.isSustainNote && noteRows[note.mustPress?0:1][note.row].length > 1)
						{
							// potentially have jump anims?
							var chord = noteRows[note.mustPress?0:1][note.row];
							var animNote = chord[0];
							var realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))] + altAnim;
							
							var otherAnim = realAnim;
							if (chord.length > 0) {
								otherAnim = singAnimations[Std.int(Math.abs(chord[1].noteData))] + altAnim;
							}
	
							if (dad.mostRecentRow != note.row)
							{
								dad.playAnim(realAnim, true);
							}
	
							// if (note != animNote)
							// dad.playGhostAnim(chord.indexOf(note)-1, animToPlay, true);
	
							// dad.angle += 15; lmaooooo
							if(dad.mostRecentRow != note.row){
								doGhostAnim(dad, otherAnim, chord[1].noteData);
							}
							dad.mostRecentRow = note.row;
						}
						else{
							dad.playAnim(animToPlay, true);
							// dad.angle = 0;
						}
				}
				switch(note.noteData){
					case 0:
						camX = -20;
						camY = 0;
					case 1:
						camX = 0;
						camY = 15;
						defaultCamAngle = 0;
					case 2:
						camX = 0;
						camY = -15;
						defaultCamAngle = 0;
					case 3:
						camX = 20;
						camY = 0;
				}
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;

		spawnHoldSplashOnNote(note);

		for(mechanic in activeMechanics)
		{
			mechanic.opponentNoteHit(note);
		}

		stagesFunc(function(stage:BaseStage) stage.onOppNoteHit(note));
		
		if (!note.isSustainNote)
		{
			invalidateNote(note);
		}
	}

	public function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(note.wasGoodHit) return;
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);
			}

			if(note.hitCausesMiss)
			{
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					invalidateNote(note);
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}

			var gainHealth:Bool = true; // prevent health gain, as sustains are threated as a singular note
			if (guitarHeroSustains && note.isSustainNote)
				gainHealth = false;

			if (gainHealth) {
				if(DoorsUtil.modifierActive(46)) health += (note.hitHealth * healthGain * (note.ratingMod == 1 ? 2:0)) / 1.5;
				else if (DoorsUtil.modifierActive(57)) {
					if (note.ratingMod == 1){
						health += (note.hitHealth * healthGain * note.ratingMod) / 1.5;
					} else {
						health -= (note.hitHealth * healthLoss * note.ratingMod) * 3;
					}
				} else health += (note.hitHealth * healthGain * note.ratingMod) / 1.5;
			}

			switch(note.rating){
				case "perfect" | "sick": sicks++;
				case "good": goods++;
				case "bad": bads++;
				case "shit": shits++;
			}

			if(!note.noAnimation) {
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if(note.gfNote)
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					boyfriend.playAnim(animToPlay + note.animSuffix, true);

					for(mechanic in activeMechanics)
					{
						mechanic.bfAnim(animToPlay + note.animSuffix, true);
					}

					boyfriend.holdTimer = 0;

					switch(note.noteData){
						case 0:
							bfcamX = -20;
							bfcamY = 0;
						case 1:
							bfcamX = 0;
							bfcamY = 15;
							defaultCamAngle = 0;
						case 2:
							bfcamX = 0;
							bfcamY = -15;
							defaultCamAngle = 0;
						case 3:
							bfcamX = 20;
							bfcamY = 0;
					}

					if (!bfGhostPopOff && !note.isSustainNote && noteRows[note.mustPress?0:1][note.row].length > 1)
					{
						// potentially have jump anims?
						var chord = noteRows[note.mustPress?0:1][note.row];
						var animNote = chord[0];
						var realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))] + note.animSuffix;
						var otherAnim = realAnim;
						if (chord.length > 0) {
							otherAnim = singAnimations[Std.int(Math.abs(chord[1].noteData))] + note.animSuffix;
						}
						if (boyfriend.mostRecentRow != note.row)
						{
							boyfriend.playAnim(realAnim, true);

							for(mechanic in activeMechanics)
							{
								mechanic.bfAnim(animToPlay + note.animSuffix, true);
							}
						}

						// if (daNote != animNote)
						// dad.playGhostAnim(chord.indexOf(daNote)-1, animToPlay, true);

						// dad.angle += 15; lmaooooo
						if(boyfriend.mostRecentRow != note.row){
							doGhostAnim(boyfriend, otherAnim, chord[1].noteData);
						}
						boyfriend.mostRecentRow = note.row;
					}
					else if (!bfGhostPopOff)
					{
						boyfriend.playAnim(animToPlay + note.animSuffix, true);
						for(mechanic in activeMechanics)
						{
							mechanic.bfAnim(animToPlay + note.animSuffix, true);
						}
						// dad.angle = 0;
					} else if (bfGhostPopOff){
						doGhostAnim(boyfriend, animToPlay, note.noteData);
					}
				}


				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
				else if(note.noteType == 'GF Note'){
					gf.playAnim(animToPlay, true);
					gf.holdTimer = 0;
				}
				else if (note.noteType == 'Both Opponents Sing')
				{
					mom.playAnim(animToPlay, true);
					mom.holdTimer = 0;
					dad.playAnim(animToPlay, true);
					dad.holdTimer = 0;
				}
				else if (note.noteType == 'Opponent 2 Sing')
				{
					mom.playAnim(animToPlay, true);
					mom.holdTimer = 0;
				}
				else if (note.noteType == 'All Sing'){
					mom.playAnim(animToPlay, true);
					mom.holdTimer = 0;
					dad.playAnim(animToPlay, true);
					dad.holdTimer = 0;
					gf.playAnim(animToPlay, true);
					gf.holdTimer = 0;
				}
			}

			if(cpuControlled) {
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			} else {
				var spr = playerStrums.members[note.noteData];
				if(spr != null)
				{
					spr.playAnim('confirm', true);
				}
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			spawnHoldSplashOnNote(note);

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			for(mechanic in activeMechanics)
			{
				mechanic.goodNoteHit(note);
			}

			stagesFunc(function(stage:BaseStage) stage.onPlaNoteHit(note));

			switch (SONG.song.toLowerCase())
			{
				case 'halt' | 'onward':
					health += 0.005;
				case 'onward-hell':
					health += 0.008;
				case 'not-a-sound'  | "not-a-sound-hell" | 'tranquil' | 'imperceptible' | 'hyperacusis' | 'depths-below':
					if (taikoActive && note.noteData > 3){
						taikoSpot.animation.play("idle", true);
					}
			}

			if (!note.isSustainNote)
			{
				invalidateNote(note);
			}
		}
	}

	public function spawnHoldSplashOnNote(note:Note) {
		if(ClientPrefs.data.noteSplashes && note != null) {
			if (!note.isSustainNote && note.tail.length != 0 && note.tail[note.tail.length - 1].extraData['holdSplash'] == null) {
				spawnHoldSplash(note);
			} else if (note.isSustainNote) {
				final end:Note = StringTools.endsWith(note.animation.curAnim.name, 'holdEnd' + note) ? note : note.parent.tail[note.parent.tail.length - 1];
				if (end != null) {
					var leSplash:SustainSplash = end.extraData['holdSplash'];
					if (leSplash == null && !end.parent.wasGoodHit) {
						spawnHoldSplash(end);
					} else if (leSplash != null) {
						leSplash.visible = true;
					}
				}
			}
		}
	}

	public function spawnHoldSplash(note:Note) {
		var end:Note = note.isSustainNote ? note.parent.tail[note.parent.tail.length - 1] : note.tail[note.tail.length - 1];
		var splash:SustainSplash = grpHoldSplashes.recycle(SustainSplash);
		splash.setupSusSplash(strumLineNotes.members[note.noteData + (note.mustPress ? 4 : 0)], note, note.noteData, playbackRate);
		splash.alpha = strumLineNotes.members[note.noteData + (note.mustPress ? 4 : 0)].alpha;
		grpHoldSplashes.add(end.extraData['holdSplash'] = splash);
	}

	function revertTweenTaiko(t){
		FlxTween.tween(taikoVignette, {alpha: 0}, 0.1, {type: FlxTweenType.ONESHOT});
		FlxTween.tween(camGame, {zoom: 0.7}, 0.1, {type: FlxTweenType.ONESHOT});
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.data.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null && note.noteData < 4) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			} else if(strum != null && note.noteData > 3){
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		if(data > 3){
			skin = 'heartbeatSplash';
		}
		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		if(FlxG.stage.hasEventListener(KeyboardEvent.KEY_DOWN))
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);

		if(FlxG.stage.hasEventListener(KeyboardEvent.KEY_UP))
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		if(FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}

		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}
		lastStepHit = curStep;
		
		for(mechanic in activeMechanics)
			{
				mechanic.onStepHit(curStep);
			}
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);
		iconP3.scale.set(1.2, 1.2);
		iconP4.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();
		iconP3.updateHitbox();
		iconP4.updateHitbox();

		characterBop(curBeat);

		lastBeatHit = curBeat;
		for(mechanic in activeMechanics)
			{
				mechanic.onBeatHit(curBeat);
			}
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
			}
		}
	}


	public function callStageFunctions(event:String,args:Array<Dynamic>){
		try{
			var ret = gameStages.get(event);
			if(ret != null){
				Reflect.callMethod(null, ret.func, args);
			}
		}
		catch(err){
			trace("\n["+event+"] Stage Function Error: " + err);
		}
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		if(totalPlayed < 1) //Prevent divide by 0
			ratingName = '?';
		else
		{
			// Rating Percent
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

			// Rating Name
			if(ratingPercent >= 1)
			{
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
			}
			else
			{
				for (i in 0...ratingStuff.length-1)
				{
					if(ratingPercent < ratingStuff[i][1])
					{
						ratingName = ratingStuff[i][0];
						break;
					}
				}
			}
		}

		// Rating FC
		ratingFC = "";
		if (sicks > 0) ratingFC = Lang.getText("sfc", "generalshit/ratings/ratingsFC");
		if (goods > 0) ratingFC = Lang.getText("gfc", "generalshit/ratings/ratingsFC");
		if (bads > 0 || shits > 0) ratingFC = Lang.getText("fc", "generalshit/ratings/ratingsFC");
		if (songMisses > 0) ratingFC = Lang.getText("clear", "generalshit/ratings/ratingsFC");
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}

	private function checkForAchievement()
	{
		AwardsManager.loadAchievements();
		if(isStoryMode)
		{
			switch(SONG.player2.toLowerCase()){
				case 'rush_v1': AwardsManager.rushFind = true;
				case 'screech': AwardsManager.screechFind = true;
				case 'seek' | 'seek_run_body' | 'madseek': AwardsManager.seekFind = true;
				case 'timothy': AwardsManager.timothyFind = true;
				case 'ambush': AwardsManager.ambushFind = true;
				case 'eyes': AwardsManager.eyesFind = true;
				case 'figure' | 'figurebooks' | 'figure100' | 'db-figure': AwardsManager.figureFind = true;
				case 'glitch' | 'glitch-alt': AwardsManager.glitchFind = true;
				case 'halt': AwardsManager.haltFind = true;
				case 'jack': 
					AwardsManager.runJackCounter++;
					AwardsManager.jackFind = true;
					if(AwardsManager.runJackCounter == 2) AwardsManager.RNJesus = true;
			}
		}

		// Seek Mastery Achievement
		if(Highscore.getRating('Encounter', storyDifficulty??1) >= 0.95 &&
			Highscore.getRating('delve', storyDifficulty??1) >= 0.95 &&
			Highscore.getRating('ready-or-not', storyDifficulty??1) >= 0.95 &&
			Highscore.getRating('found-you', storyDifficulty??1) >= 0.95) AwardsManager.neverTripped = true;

		if(SONG.song.contains("404") && combo >= 404){
			AwardsManager.comboNotFound = true;
		}

		if(Highscore.haveAllFC()) AwardsManager.completionist = true;
	}

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
	public function updateCameraFilters(camera:String){

		switch(camera){
			case 'camGame':
				camGame.setFilters(camGameFilters);
			case 'camHUD':
				camHUD.setFilters(camHUDFilters);
			case 'camOther':
				camOther.setFilters(camOtherFilters);
			case 'camBackground':
				camBackground.setFilters(camBackgroundFilters);
		}
	}

	function createBars(inAlready:Bool):Void
	{
		topBarsALT = new FlxSprite().makeSolid(FlxG.width, 120, FlxColor.BLACK);
		topBarsALT.x = inAlready ? 0 : -topBarsALT.width;
		topBarsALT.cameras = [camBars];
		add(topBarsALT);

		bottomBarsALT = new FlxSprite(inAlready ? 0 : FlxG.width).makeSolid(FlxG.width, 120, FlxColor.BLACK);
		bottomBarsALT.cameras = [camBars];
		bottomBarsALT.y = FlxG.height - bottomBarsALT.height;
		add(bottomBarsALT);
	}

	function getFakeTime(songWithIt:String):Float
	{
		switch(songWithIt)
		{
			case 'invader':
				return 80400;

			case 'left-behind':
				return 141151.5;

			case 'left-behind-hell':
				return songLength + 329500;
		}

		return songLength;
	}

	function tweenToRealTime(beats:Float)
	{
		var tweenToRealTimeTween:FlxTween = FlxTween.tween(this, {songLengthFake: songLength}, Conductor.crochet/1000*beats);

		stopTweens.push(tweenToRealTimeTween);
	}

	function tweenToFakeTime(beats:Float, time:Float)
	{
		var tweenToFakeTimeTween:FlxTween = FlxTween.tween(this, {songLengthFake: (songLength + time)}, Conductor.crochet/1000*beats);

		stopTweens.push(tweenToFakeTimeTween);
	}

	function characterBop(beat:Int){
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
			{
				gf.dance();
			}
		if (boyfriend != null && beat % boyfriend.danceEveryNumBeats == 0 && !boyfriend.getAnimationName().startsWith('sing') && !boyfriend.getAnimationName().startsWith('closed-sing') && !boyfriend.getAnimationName().startsWith('closed-enter') && !boyfriend.stunned)
			{
				bfcamX = 0; // real.
				bfcamY = 0;
				defaultCamAngle = 0;
				boyfriend.dance();

				for(mechanic in activeMechanics)
				{
					mechanic.bfBop();
				}
			}
		if (beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			{
				camX = 0; // real.
				camY = 0;
				defaultCamAngle = 0;
				dad.dance();
			}
		if (mom != null && beat % mom.danceEveryNumBeats == 0 && !mom.getAnimationName().startsWith('sing') && !mom.stunned)
			{
				mom.dance();
			}
		if(SONG.characters != null && songCharacters.length > 3){
			for (i in 3...songCharacters.length){
				var char:Character = songCharacters[i];
				if (char != null && beat % char.danceEveryNumBeats == 0 && !char.getAnimationName().startsWith('sing') && !char.stunned)
				{
					char.dance();
				}
			}
		}
	}

	public function playerDance(force:Bool = false):Void {
		var anim:String = boyfriend.getAnimationName();
		if(boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && (!anim.startsWith('sing') || !anim.startsWith("closed-sing")) && !anim.endsWith('miss'))
			{
				boyfriend.dance();
				for(mechanic in activeMechanics)
				{
					mechanic.bfBop();
				}
			}
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == FunkinLua.Function_Continue;
			if(!bool) {
				returnVal = cast ret;
			}
		}
		#end

		callStageFunctions(event,args);
		
		return returnVal;
	}
}

typedef FunkyFunct =
{
    var func:Void->Void;
}