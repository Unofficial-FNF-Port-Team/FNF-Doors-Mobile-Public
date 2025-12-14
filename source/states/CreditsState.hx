package states;

import backend.system.CrashHandler;
import haxe.Json;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxTextNew as FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.math.FlxRandom;
import flixel.FlxObject;

import SoundCompare;

import lime.utils.Assets;

using StringTools;

typedef Credit = {
	var name:String;
	var role:Array<String>;
	var id:String;
	var ?message:String;
	var ?socials:Socials;

	// Special Thanks Specific Stuff
	var ?specialThanks:Array<SpecialThanks>;
}

typedef Socials = {
	var ?youtube:SocialInfo;
	var ?instagram:SocialInfo;
	var ?twitter:SocialInfo;
	var ?github:SocialInfo;
}

typedef SocialInfo = {
	var name:String;
	var url:String;
}

typedef SpecialThanks = {
	var group:String;
	var name:String;
	var message:String;
}

class CreditsState extends MusicBeatState
{
	public static function preloadEverything() {
		Paths.clearStoredMemory();
		var credits:Array<Credit> = cast Json.parse(Paths.getTextFromFile("data/credits.json"));

		var theMap:Map<String, Array<String>> = [
			"images" => [],
			"sounds" => [],
			"music" => [],
			"instogg" => []
		];

		theMap.get("images").push('menus/credits/bg');
		theMap.get("images").push('menus/credits/cord');
		theMap.get("images").push('menus/credits/front');
		theMap.get("images").push('menus/credits/ArrowLeft');
		theMap.get("images").push('menus/credits/ArrowRight');

		for (i=>credit in credits) {
			theMap.get("images").push('menus/credits/paintings/' + credit.id);
		}

		theMap.get("images").push('menus/specialThanks/master');
		theMap.get("images").push('menus/specialThanks/scrollBar');
		theMap.get("images").push('menus/specialThanks/scrollBG');

		
		theMap.get("music").push('amirrAmbience');
		theMap.get("music").push('fmAmbience');
		theMap.get("music").push('hrisAmbience');
		theMap.get("music").push('icyAmbience');
		theMap.get("music").push('niniAmbience');
		theMap.get("music").push('waleterAmbience');
		theMap.get("music").push('freakyOptions');

		return theMap;
	}


	var portrait:FlxSprite;

    var camPos:FlxObject = new FlxObject(0, 0, 1, 1);
    var listWidth:Float = -400;

	var credits:Array<Credit> = [];

	var leftSelector:StoryModeSpriteHoverable;
	var rightSelector:StoryModeSpriteHoverable;
	var bg:FlxSprite;

	// funny hris
	var hrisX:Float = 0.0;
	var fullBlack:FlxSprite;
	var hrisAmbience:FlxSound;

	// funny amirr
	var amirrX:Float = 0.0;
	var amirrAmbience:FlxSound;

	// funny fm
	var fmX:Float = 0.0;
	var fmAmbience:FlxSound;

	// funny waleter
	var waleterX:Float = 0.0;
	var waleterAmbience:FlxSound;

	// funny icy
	var icyX:Float = 0.0;
	var icyAmbience:FlxSound;

	// funny nini
	var niniX:Float = 0.0;
	var niniAmbience:FlxSound;

	// funny callu
	var calluX:Float = 0.0;
	var calluAmbience:FlxSound;

	// funny salad
	var saladX:Float = 0.0;
	var saladAmbience:FlxSound;

	// funny special thanks
	var specialThanksX:Float = 0.0;
	var specialThanks:Array<SpecialThanks> = [];

	var camHUD:FlxCamera;
	override function create()
	{
		MenuSongManager.crossfade("freakyOptions", 1, 140, true);
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		bg = new FlxSprite().loadGraphic(Paths.image('menus/credits/bg'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.scrollFactor.set();
		add(bg);

		var cord = new FlxBackdrop(Paths.image('menus/credits/cord'));
		cord.antialiasing = ClientPrefs.globalAntialiasing;
		add(cord);

        camPos.screenCenter();
        FlxG.camera.follow(camPos, LOCKON, 1);

		credits = cast Json.parse(Paths.getTextFromFile("data/credits.json"));

		for (i=>credit in credits) {
			var painting:FlxSprite;
			if(Paths.exists('images/menus/credits/paintings/' + credit.id + ".png")){
				painting = new FlxSprite(357 + (i*1280), 0).loadGraphic(Paths.image('menus/credits/paintings/' + credit.id));
			} else {
				painting = new FlxSprite(357 + (i*1280), 0).loadGraphic(Paths.image('menus/credits/paintings/placeholder'));
			}
			painting.antialiasing = ClientPrefs.globalAntialiasing;
			painting.setGraphicSize(-1, 601);
			painting.updateHitbox();
			painting.setPosition(360 + (i*1280) - ((painting.width-561)/2 > 0 ? (painting.width-561)/2 + 10 : 0), 0);

			var box = new FlxSprite((191 + (i*1280)) * 1.2, 580).loadGraphic(Paths.image('menus/credits/box'));
			box.scrollFactor.set(1.2, 1);
			box.antialiasing = ClientPrefs.globalAntialiasing;

			var theText = new FlxText((191 + (i*1280)) * 1.2, 616, 905, "text");
			theText.scrollFactor.set(1.2, 1);
			theText.setFormat(FONT, 48, 0xFFFEDEBF, CENTER);
			theText.antialiasing = ClientPrefs.globalAntialiasing;

			if(credit.id == "amirr") amirrX = painting.x + painting.width/2;
			if(credit.id == "callu") calluX = painting.x + painting.width/2;
			if(credit.id == "hris") hrisX = painting.x + painting.width/2;
			if(credit.id == "fm") fmX = painting.x + painting.width/2;
			if(credit.id == "waleter") waleterX = painting.x + painting.width/2;
			if(credit.id == "icy") icyX = painting.x + painting.width/2;
			if(credit.id == "nini") niniX = painting.x + painting.width/2;
			if(credit.id == "salad") saladX = painting.x + painting.width/2;
			if(credit.id == "playtesters"){
				specialThanksX = painting.x + painting.width / 2;
				specialThanks = credit.specialThanks;
			}

			var roleText:String = "";
			if(credit.role.length >= 1){
				for (i=>role in credit.role){
					switch(role){
						case "former" | "guest": roleText += '(${Lang.getText(role, "states/credits")}) ';
						default:
							var textToAdd:String = Lang.getText(role, "states/credits");
							if(i != 0) textToAdd.toLowerCase();
	
							if(role == "lead") {
								roleText += textToAdd + " ";
								continue;
							}
	
							if(credit.role.length - i > 2){
								roleText += textToAdd + ", ";
							} else if (credit.role.length - i > 1){
								roleText += textToAdd + " & ";
							} else {
								roleText += textToAdd;
							}
					}
				}
				theText.text = credit.name + ' - ${roleText}';
			} else {
				theText.text = credit.name;
			}

			listWidth += 1280;
			add(painting);
			add(box);
			add(theText);
			
			if(credit.message != null){
				theText.y = 574;

				var quoteText = new FlxText((191 + (i*1280)) * 1.2, 631, 905, '"${credit.message}"');
				quoteText.scrollFactor.set(1.2, 1);
				quoteText.setFormat(FONT, 28, 0xFFFEDEBF, CENTER);
				quoteText.antialiasing = ClientPrefs.globalAntialiasing;
				add(quoteText);
			}
		}
		
		listWidth -= 1280/2;

		var front = new FlxSprite().loadGraphic(Paths.image('menus/credits/front'));
		front.antialiasing = ClientPrefs.globalAntialiasing;
		front.scrollFactor.set();
		add(front);
		
        leftSelector = new StoryModeSpriteHoverable(219, 288, "freeplay/new/ArrowLeft");
		leftSelector.scrollFactor.set();
        add(leftSelector);

        rightSelector = new StoryModeSpriteHoverable(1043, 288, "freeplay/new/ArrowRight");
		rightSelector.scrollFactor.set();
        add(rightSelector);

        var scrollBar:HorizontalScrollBar = new HorizontalScrollBar(40, 730, this, "scroll", listWidth);
        add(scrollBar);

		// shenanigans

		fullBlack = new FlxSprite().makeSolid(1280, 720, 0xFF000000);
		fullBlack.alpha = 0.0001;
		fullBlack.scrollFactor.set();
		add(fullBlack);

		#if mobile
		addVirtualPad(LEFT_RIGHT, A_B);
		addVirtualPadCamera();
		#end

		hrisAmbience = new FlxSound();
		hrisAmbience.loadEmbedded(Paths.music("hrisAmbience"));
		hrisAmbience.looped = true;
		hrisAmbience.volume = 0.0001;
		hrisAmbience.play();
        FlxG.sound.list.add(hrisAmbience);

		amirrAmbience = new FlxSound();
		amirrAmbience.loadEmbedded(Paths.music("amirrAmbience"));
		amirrAmbience.looped = true;
		amirrAmbience.volume = 0.0001;
		amirrAmbience.play();
        FlxG.sound.list.add(amirrAmbience);

		fmAmbience = new FlxSound();
		fmAmbience.loadEmbedded(Paths.music("fmAmbience"));
		fmAmbience.looped = true;
		fmAmbience.volume = 0.0001;
		fmAmbience.play();
        FlxG.sound.list.add(fmAmbience);

		waleterAmbience = new FlxSound();
		waleterAmbience.loadEmbedded(Paths.music("waleterAmbience"));
		waleterAmbience.looped = true;
		waleterAmbience.volume = 0.0001;
		waleterAmbience.play();
        FlxG.sound.list.add(waleterAmbience);

		icyAmbience = new FlxSound();
		icyAmbience.loadEmbedded(Paths.music("icyAmbience"));
		icyAmbience.looped = true;
		icyAmbience.volume = 0.0001;
		icyAmbience.play();
        FlxG.sound.list.add(icyAmbience);

		niniAmbience = new FlxSound();
		niniAmbience.loadEmbedded(Paths.music("niniAmbience"));
		niniAmbience.looped = true;
		niniAmbience.volume = 0.0001;
		niniAmbience.play();
        FlxG.sound.list.add(niniAmbience);

		saladAmbience = new FlxSound();
		saladAmbience.loadEmbedded(Paths.music("saladAmbience"));
		saladAmbience.looped = true;
		saladAmbience.volume = 0.0001;
		saladAmbience.play();
        FlxG.sound.list.add(saladAmbience);

		calluAmbience = new FlxSound();
		calluAmbience.loadEmbedded(Paths.music("calluAmbience"));
		calluAmbience.looped = true;
		calluAmbience.volume = 0.0001;
		calluAmbience.play();
        FlxG.sound.list.add(calluAmbience);

		super.create();
	}

    var scroll:Float = 0.0;
	var hrisCanFlicker:Bool = true;
	var timeLookingAtHris:Float = 0.0;
	var mustUpdate:Bool = true;
	override function update(elapsed:Float)
	{
        if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

		if(mustUpdate){
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				
				hrisAmbience.destroy();
				icyAmbience.destroy();
				waleterAmbience.destroy();
				niniAmbience.destroy();
				saladAmbience.destroy();
				amirrAmbience.destroy();
				fmAmbience.destroy();
				calluAmbience.destroy();
	
				MusicBeatState.switchState(new MainMenuState());
				mustUpdate = false;
				return;
			}
	
			handleHris(elapsed);
			handleFM(elapsed);
			handleAmirr(elapsed);
			handleWaleter(elapsed);
			handleNini(elapsed);
			handleIcy(elapsed);
			handleSalad(elapsed);
			handleCallu(elapsed);
			handleSpecialThanks(elapsed);
			handleSocials(elapsed);
			
			var snap:Bool = false;
			if (FlxG.keys.pressed.SHIFT)
				snap = true;
	
			if(!snap){
				scroll -= FlxG.mouse.wheel*50*elapsed*960;
	
				if (controls.UI_LEFT)
					scroll -= 1600*elapsed;
				if (controls.UI_RIGHT)
					scroll += 1600*elapsed;
			} else {
				if (controls.UI_LEFT_P)
					scroll = Math.round((scroll - FlxG.width) / FlxG.width) * FlxG.width;
				if (controls.UI_RIGHT_P)
					scroll = Math.round((scroll + FlxG.width) / FlxG.width) * FlxG.width;
			}
	
			camPos.x = FlxMath.lerp(camPos.x, scroll+(FlxG.width*0.5), elapsed*12); //lerp cam pos to scroll
	
			scroll = FlxMath.bound(scroll, 0, listWidth); //bound
	
		}
		super.update(elapsed);
	}

	function handleSocials(elapsed:Float){
		for (i in 0...credits.length) {
			var credit = credits[i];
			var creditX = 357 + (i * 1280); // Calculate creditX based on index
			if (credit.socials != null && camPos.x >= creditX - 800 && camPos.x <= creditX + 800 && FlxG.keys.justPressed.ENTER) {
				persistentUpdate = false;
				openSubState(new SocialsSubstate(credit.name.toUpperCase(), credit.socials));
			}
		}
	}

	function handleSpecialThanks(elapsed:Float){
		if(camPos.x >= specialThanksX - 800 && camPos.x <= specialThanksX + 800 && FlxG.keys.justPressed.ENTER){
			persistentUpdate = false;
			openSubState(new SpecialThanksSubState(specialThanks));
		} 
	}

	function handleCallu(elapsed:Float){
		if(camPos.x >= calluX - 800 && camPos.x <= calluX + 800){
			var distanceToCallu:Float = Math.abs(calluX - camPos.x);
			var volumeFactor:Float = FlxMath.remapToRange(distanceToCallu, 200, 800, 0, 1);

			MenuSongManager.changeSongVolume(volumeFactor, elapsed);
			calluAmbience.volume = Math.abs(volumeFactor - 1);
		} else {
			calluAmbience.volume = 0.0;
		}
	}

	function handleIcy(elapsed:Float){
		if(camPos.x >= icyX - 800 && camPos.x <= icyX + 800){
			var distanceToIcy:Float = Math.abs(icyX - camPos.x);
			var volumeFactor:Float = FlxMath.remapToRange(distanceToIcy, 200, 800, 0, 1);

			MenuSongManager.changeSongVolume(volumeFactor, elapsed);
			icyAmbience.volume = Math.abs(volumeFactor - 1);
		} else {
			icyAmbience.volume = 0.0;
		}
	}

	function handleNini(elapsed:Float){
		if(camPos.x >= niniX - 800 && camPos.x <= niniX + 800){
			var distanceToNini:Float = Math.abs(niniX - camPos.x);
			var volumeFactor:Float = FlxMath.remapToRange(distanceToNini, 200, 800, 0, 1);

			MenuSongManager.changeSongVolume(volumeFactor, elapsed);
			niniAmbience.volume = Math.abs(volumeFactor - 1);
		} else {
			niniAmbience.volume = 0.0;
		}
	}

	function handleWaleter(elapsed:Float){
		if(camPos.x >= waleterX - 800 && camPos.x <= waleterX + 800){
			var distanceToWaleter:Float = Math.abs(waleterX - camPos.x);
			var volumeFactor:Float = FlxMath.remapToRange(distanceToWaleter, 200, 800, 0, 1);

			MenuSongManager.changeSongVolume(volumeFactor, elapsed);
			waleterAmbience.volume = Math.abs(volumeFactor - 1);
		} else {
			waleterAmbience.volume = 0.0;
		}
	}

	function handleSalad(elapsed:Float){
		if(camPos.x >= saladX - 800 && camPos.x <= saladX + 800){
			var distanceToSalad:Float = Math.abs(saladX - camPos.x);
			var volumeFactor:Float = FlxMath.remapToRange(distanceToSalad, 200, 800, 0, 1);

			MenuSongManager.changeSongVolume(volumeFactor, elapsed);
			saladAmbience.volume = Math.abs(volumeFactor - 1);
		} else {
			saladAmbience.volume = 0.0;
		}
	}

	function handleFM(elapsed:Float){
		if(camPos.x >= fmX - 800 && camPos.x <= fmX + 800){
			var distanceToFM:Float = Math.abs(fmX - camPos.x);
			var volumeFactor:Float = FlxMath.remapToRange(distanceToFM, 200, 800, 0, 1);

			MenuSongManager.changeSongVolume(volumeFactor, elapsed);
			fmAmbience.volume = Math.abs(volumeFactor - 1);
		} else {
			fmAmbience.volume = 0.0;
		}
	}

	function handleAmirr(elapsed:Float){
		if(camPos.x >= amirrX - 800 && camPos.x <= amirrX + 800){
			var distancetoAmirr:Float = Math.abs(amirrX - camPos.x);
			var volumeFactor:Float = FlxMath.remapToRange(distancetoAmirr, 200, 800, 0, 1);

			MenuSongManager.changeSongVolume(volumeFactor, elapsed);
			amirrAmbience.volume = Math.abs(volumeFactor - 1);
		} else {
			amirrAmbience.volume = 0.0;
		}
	}

	function handleHris(elapsed:Float){
		function makeHrisNewTween(){
			return FlxTween.tween(fullBlack, {alpha: 0}, 0.7, {ease: FlxEase.bounceOut, startDelay: FlxG.random.float(1.0, 5.0), onStart: function(twn){
				MenuSongManager.playSound("mainmenu/BulbZap", 1.0);
			}});
		}

		if(camPos.x >= hrisX - 800 && camPos.x <= hrisX + 800){
			var distanceToHris:Float = Math.abs(hrisX - camPos.x);
			var volumeFactor:Float = FlxMath.remapToRange(distanceToHris, 200, 800, 0, 1);
			var randomChance:Float = volumeFactor * 60;

			MenuSongManager.changeSongVolume(volumeFactor, elapsed);
			hrisAmbience.volume = Math.abs(volumeFactor - 1);
			if(FlxG.random.bool(randomChance / 20) && hrisCanFlicker){
				hrisCanFlicker = false;
				fullBlack.alpha = 0.6;
				makeHrisNewTween();

				new FlxTimer().start(8.0, function(tmr){
					hrisCanFlicker = true;
				});
			}

			timeLookingAtHris += (elapsed * Math.abs(volumeFactor - 1) * 0.1);
		} else {
			hrisAmbience.volume = 0.0;
		}

		timeLookingAtHris = FlxMath.lerp(timeLookingAtHris, 0, elapsed * 2);

		var shakeIntensity:Float = FlxMath.remapToRange(timeLookingAtHris, 0, 5, 0, 0.03);
		FlxG.camera.shake(shakeIntensity, 0.1);
	}
}


/**
 * Simple scroll bar that tracks and updates a value
 */
 class HorizontalScrollBar extends FlxTypedSpriteGroup<FlxSprite>
 {
	 /**
	  * Object to track value from
	 */
	 public var parent:Dynamic;
 
	 /**
	  * Property of parent object to track.
	 */
	 public var parentVariable:String;
 
	 public var scrollBar:FlxSprite;
	 public var scrollBG:FlxSprite;
 
	 private var grabbed:Bool = false;
	 private var grabX:Float = 0.0;
	 public var limit:Float = 0.0;
	 public function new(X:Float = 0, Y:Float = 0, ?parentRef:Dynamic, variable:String = "", limit:Float)
	 {
		 super(X,Y);
		 scrollBG = new FlxSprite(0, 0).loadGraphic(Paths.image("hemptyScroll"));
		 scrollBar = new FlxSprite(3, 3).loadGraphic(Paths.image("hscrollTick"));
		 add(scrollBG);
		 add(scrollBar);
		 scrollBG.scrollFactor.set();
		 scrollBar.scrollFactor.set();
		 scrollBG.antialiasing = ClientPrefs.globalAntialiasing;
		 scrollBar.antialiasing = ClientPrefs.globalAntialiasing;
		 this.limit = limit;
		 if (parentRef != null)
		 {
			 parent = parentRef;
			 parentVariable = variable;
		 }
	 }
	 override public function update(elapsed:Float)
	 {
		 super.update(elapsed);
		 if (parent == null)
			 return;
 
		 var value:Float = Reflect.getProperty(parent, parentVariable);
 
		 scrollBar.x = FlxMath.remapToRange(value, 0, limit, scrollBG.x + 3, (scrollBG.x+scrollBG.width)-scrollBar.width - 3); //set y from value
 
		 if (scrollBar.overlapsPoint(FlxG.mouse.getPosition(), true) && FlxG.mouse.justPressed) //grab bar
		 {
			 grabbed = true;
			 grabX = FlxG.mouse.screenX-scrollBar.x;
		 }
			 
		 if (FlxG.mouse.released && grabbed) //ungrab bar
		 {
			 scrollBar.color = 0xFFFFFFFF;
			 grabbed = false;
		 }
 
		 if (grabbed)
		 {
			 scrollBar.x = FlxG.mouse.screenX-grabX; //update bar position with mouse
			 scrollBar.color = 0xFF828282;
			 scrollBar.x = FlxMath.bound(scrollBar.x, scrollBG.x, (scrollBG.x+scrollBG.width)-scrollBar.width);
		 }
 
		 if (!grabbed && scrollBG.overlapsPoint(FlxG.mouse.getPosition(), true) && FlxG.mouse.justPressed) //when you click the black part
		 {
			 scrollBar.x = FlxG.mouse.screenX;
			 scrollBar.x = FlxMath.bound(scrollBar.x, scrollBG.x, (scrollBG.x+scrollBG.width)-scrollBar.width);
		 }
		 
		 value = FlxMath.remapToRange(scrollBar.x, scrollBG.x + 3, (scrollBG.x+scrollBG.width)-scrollBar.width - 3, 0, limit); //remap back after any changes to the bar
 
		 Reflect.setProperty(parent, parentVariable, value); //reset back to parent
	 }
	 override public function destroy():Void
	 {
		 scrollBar = null;
		 scrollBG = null;
		 parent = null;
		 super.destroy();
	 }
 }
