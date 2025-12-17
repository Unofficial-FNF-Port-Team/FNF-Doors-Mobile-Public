package substates;

import flixel.FlxState;
import backend.Lang.TRANS_ERRORS;
import shaders.HeatwaveShader;
import flixel.effects.particles.FlxEmitter;
import objects.ui.DoorsMenu;
import objects.ui.DoorsButton;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;
import flixel.math.FlxRandom;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.text.FlxTextNew as FlxText;
import backend.metadata.DeathMetadata;

enum abstract TipSpeaker(FlxColor) {
	var CURIOUS = 0xFFFFFFB6;
	var GUIDING = 0xFFAAFFFD;
}

class GameOverSubstate extends MusicBeatSubstate
{
	public static function getPreloadShit(?lastLife:Bool = false, ?state:String = "playstate") {
		var baseAssets = [
			"deathScreen/bubble", "deathScreen/star", 
			"deathScreen/smokeBack", "deathScreen/smokeMid",
			"menus/death"
		];
		
		var character = "DeathBF";
		var backgroundPath = "guiding";
		var musicTrack = "gameOver";
		var endMusicTrack = "gameOverEnd";
		
		if(lastLife) {
			return [
				"images" => ["characters/atlas/" + character + "/spritemap1", "deathScreen/guiding/background"].concat(baseAssets),
				"music" => ["gameOverFinal"],
				"sounds" => ["fnf_loss_sfx"]
			];
		}
		
		if(state == "playstate" && PlayState.SONG.song == "workloud") {
			character = "CuriousDeathBF";
			backgroundPath = "curious";
		} else if(state == "storymode") {
			musicTrack = "gameOverVoid";
			endMusicTrack = "gameOverVoidEnd";
			backgroundPath = "guiding";
		}
		
		var bgPath = backgroundPath != "" ? 
			"deathScreen/" + backgroundPath + "/background" : 
			"deathScreen/background";
			
		return [
			"images" => ["characters/atlas/" + character + "/spritemap1", bgPath].concat(baseAssets),
			"music" => [musicTrack, endMusicTrack],
			"sounds" => ["fnf_loss_sfx"]
		];
	}

	var background:FlxSprite;
	var deathSprite:Character;

	var ended:Bool = false; 
	var menu:DoorsMenu;
	var deathHUD:FlxCamera;
	public var focusPoint:FlxObject;
	var targetPoint:FlxObject;
	var fullBlack:FlxSprite;
	var black:FlxSprite;
	
	var starsEmitter:FlxEmitter;
	var bubbleEmitter:FlxEmitter;
	var mist0:FlxBackdrop;
	var mist1:FlxBackdrop;
	var mist2:FlxBackdrop;

	var songTipCategory:String;
	var songTips:Array<String> = [];
	var songTipsText:Array<FlxText> = [];

	var waterShader:HeatwaveShader;
	var waterFilter:ShaderFilter;
	var yTarget:Int = 70;
	var _timer:Float = 0;
	
	var state:FlxState;
	var timerBeforeTransition:FlxTimer;

	var deathMetadata:DeathMetadata;

	public function new(deathMetadata:DeathMetadata, ?state:FlxState)
	{
		super();
		this.state = state;
		this.deathMetadata = deathMetadata;

		if(deathMetadata.causeOfDeath != "PREVIOUS")
			DoorsUtil.causeOfDeath = deathMetadata.causeOfDeath;

		this.songTipCategory = deathMetadata.deathTipCategory;
		if(this.songTipCategory == null) {
			this.songTipCategory = "came back";
		}

		setupCameras();
		setupAudio();
		setupVisuals();
		setupParticles();
		setupCharacter();
		
		if(songTipCategory != ""){
			songTips = getRandomDeathTip();
			makeTexts();
		}
		
		setupMenu();
		startGaming();
		#if mobile if(PlayState.instance != null) PlayState.instance.mobileControls.visible = false; #end

		checkAchievements();
	}
	
	private function setupCameras():Void {
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		deathHUD = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
		deathHUD.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(deathHUD, false);
		
		focusPoint = new FlxObject(FlxG.width/2, FlxG.height/2, 1, 1);
		targetPoint = new FlxObject(FlxG.width/2, FlxG.height/2, 1, 1);
		cameras[0].follow(focusPoint, LOCKON, 0.95);
		cameras[0].focusOn(focusPoint.getPosition());
	}
	
	private function setupAudio():Void {
		MenuSongManager.playSound("fnf_loss_sfx", 1);
		MenuSongManager.crossfade(getMusic(), 1, 120, true);
	}
	
	private function setupVisuals():Void {
		var speakerPath:String = getTipSpeaker() == TipSpeaker.CURIOUS ? "curious" : "guiding";
		
		black = new FlxSprite(0, 0).makeSolid(FlxG.width * 3, FlxG.height * 3, 0xFF000000);
		black.scrollFactor.set(0, 0);
		black.screenCenter();
		black.alpha = 0.00001;
		add(black);
		
		background = new FlxSprite().loadGraphic(Paths.image('deathScreen/${speakerPath}/background'));
		background.screenCenter();
		background.y -= 300;
		background.antialiasing = ClientPrefs.globalAntialiasing;
		add(background);
		
		waterShader = new HeatwaveShader();
		waterFilter = new ShaderFilter(waterShader.shader);
		add(waterShader);
		cameras[0].setFilters([waterFilter]);
		
		fullBlack = new FlxSprite().loadGraphic(Paths.image('deathScreen/${speakerPath}/background'));
		fullBlack.setGraphicSize(1280, 720);
		fullBlack.screenCenter();
		fullBlack.antialiasing = ClientPrefs.globalAntialiasing;
		fullBlack.cameras = [deathHUD];
		fullBlack.alpha = 0.0001;
		add(fullBlack);
		
		makeSmoke();
	}
	
	private function setupCharacter():Void {
		deathSprite = new Character(0, 0, deathMetadata.deathSpriteType, true, false, true, false);
		deathSprite.playAnim(getAnimName(), false);
		deathSprite.screenCenter();
		deathSprite.x += deathSprite.positionArray[0];
		deathSprite.y += deathSprite.positionArray[1];
		add(deathSprite);
	}
	
	private function setupParticles():Void {
		var speakerPath:String = getTipSpeaker() == TipSpeaker.CURIOUS ? "curious" : "guiding";
		
		bubbleEmitter = new FlxEmitter(0, FlxG.height);
		bubbleEmitter.setSize(FlxG.width, 0);
		bubbleEmitter.launchMode = SQUARE;
		bubbleEmitter.velocity.set(-20, -100, 20, -200);
		bubbleEmitter.acceleration.set(-2, -5, 2, 5);
		bubbleEmitter.lifespan.set(8, 10);
		bubbleEmitter.alpha.set(0.7, 0.8, 0, 0);
		bubbleEmitter.keepScaleRatio = true;
		bubbleEmitter.scale.set(0.8, 0.8, 1.1, 1.1, 0.8, 0.8, 1.1, 1.1);
		bubbleEmitter.loadParticles(Paths.image('deathScreen/${speakerPath}/bubble'), 100);
		bubbleEmitter.cameras = [deathHUD];
		add(bubbleEmitter);

		starsEmitter = new FlxEmitter(824, 204);
		starsEmitter.setSize(1,1);
		starsEmitter.launchMode = CIRCLE;
		starsEmitter.speed.set(100, 200, 800, 1000);
		starsEmitter.acceleration.set(-10, -20, 10, 20);
		starsEmitter.lifespan.set(12, 15);
		starsEmitter.alpha.set(0.2, 0.2, 0.8, 1);
		starsEmitter.keepScaleRatio = true;
		starsEmitter.scale.set(0.2, 0.2, 0.4, 0.4, 0.8, 0.8, 1.1, 1.1);
		starsEmitter.loadParticles(Paths.image('deathScreen/${speakerPath}/star'), 100);
		starsEmitter.cameras = [deathHUD];
		add(starsEmitter);
	}
	
	private function makeSmoke():Void {
		var tipColor:FlxColor = cast getTipSpeaker();
		tipColor = tipColor.getDarkened(0.7);
		
		mist0 = new FlxBackdrop(Paths.image('deathScreen/smokeMid'), X);
		mist0.setPosition(0, 0);
		mist0.scrollFactor.set(1.2, 1.2);
		mist0.blend = BlendMode.ADD;
		mist0.color = tipColor;
		mist0.alpha = 0;
		mist0.velocity.x = 172;
		mist0.cameras = [deathHUD];
		add(mist0);

		mist1 = new FlxBackdrop(Paths.image('deathScreen/smokeMid'), X);
		mist1.setPosition(0, 0);
		mist1.scrollFactor.set(1.1, 1.1);
		mist1.blend = BlendMode.ADD;
		mist1.color = tipColor;
		mist1.alpha = 0;
		mist1.velocity.x = 150;
		mist1.cameras = [deathHUD];
		add(mist1);

		mist2 = new FlxBackdrop(Paths.image('deathScreen/smokeBack'), X);
		mist2.setPosition(0, 0);
		mist2.scrollFactor.set(1.2, 1.2);
		mist2.blend = BlendMode.ADD;
		mist2.color = tipColor;
		mist2.alpha = 0;
		mist2.velocity.x = -80;
		mist2.cameras = [deathHUD];
		add(mist2);
	}

	private function makeTexts():Void {
		trace(songTips);
		for(i in 0...songTips.length){
			var text:FlxText = new FlxText(0, 0, FlxG.width, songTips[i], 64);
			text.setFormat(FONT, 64, cast getTipSpeaker(), CENTER);
			text.screenCenter(Y);
			text.alpha = 0;
			text.cameras = [deathHUD];
			songTipsText.push(text);
			add(text);
		}
	}
	
	private function setupMenu():Void {
		menu = new DoorsMenu(127, 261, "death", Lang.getText("death", "newUI"), false, FlxPoint.get(999, 999));
		menu.cameras = [deathHUD];
		add(menu);

		if(PlayState.isStoryMode && DoorsUtil.curRun.revivesLeft > 0){
			var resetButton = new DoorsButton(15, 326, Lang.getText("reset", "newUI"), MEDIUM, DANGEROUS, function(){
				if(ended) return;
				handleReset();
			});
			menu.add(resetButton);
		}

		var quitButton = new DoorsButton(181, 326, Lang.getText("quit", "newUI"), MEDIUM, DANGEROUS, function(){
			if(ended) return;
			handleQuit();
		});
		menu.add(quitButton);

		if (!PlayState.isStoryMode || DoorsUtil.curRun.revivesLeft > 0){
			var reviveButton = new DoorsButton(347, 326, Lang.getText("revive", "newUI"), MEDIUM, NORMAL, function(){
				if(ended) return;
				handleRevive();
			});
			menu.add(reviveButton);
		}

		addRevivesText();
		
		addModsText();
	}
	
	private function addRevivesText():Void {
		var revivesLeftText:FlxText;
		if(PlayState.isStoryMode) {
			revivesLeftText = new FlxText(19, 101, 477, (Lang.getText("revivesLeft", "death"):String)
				.replace("{0}", Std.string(DoorsUtil.curRun.revivesLeft)));
		} else {
			revivesLeftText = new FlxText(19, 101, 477, (Lang.getText("freeplayRevives", "death"):String));
		}
		revivesLeftText.setFormat(FONT, 48, 0xFFFEDEBF);
		revivesLeftText.antialiasing = ClientPrefs.globalAntialiasing;
		menu.add(revivesLeftText);
	}
	
	private function addModsText():Void {
		var modValue = PlayState.isStoryMode ? 
			Std.string((DoorsUtil.curRun.runKnobModifier-1)*100) + "%" :
			Std.string((ModifierManager.freeplayScoreMod-1)*100) + "%";
		
		var modsText:FlxText = new FlxText(19, 172, 477, (Lang.getText("modsUsed", "death"):String)
			.replace("{0}", modValue));
		modsText.setFormat(FONT, 36, 0xFFFEDEBF);
		modsText.antialiasing = ClientPrefs.globalAntialiasing;
		menu.add(modsText);
	}
	
	private function checkAchievements():Void {
		if(PlayState.isStoryMode){
			var itemNb = 0;
			for(item in DoorsUtil.curRun.curInventory.items){
				if(item != null) itemNb += 1;
			}
	
			if(itemNb >= 6) AwardsManager.absoluteFailure = true;
			if(DoorsUtil.curRun.revivesLeft <= 0) AwardsManager.rip = true;
			if(songTipCategory == "void") AwardsManager.voidFind = true;
		}
	}
	
	private function handleReset():Void {
		var targetState = new RunResultsState(F1_LOSE); 
		ended = true;
		if(PlayState.isStoryMode){
			DoorsUtil.isDead = false;
			DoorsUtil.saveStoryData();
		}
		fadeAndSwitchState(targetState);
	}
	
	private function handleQuit():Void {
		ended = true;
		if(PlayState.isStoryMode){
			DoorsUtil.isDead = true;
			DoorsUtil.saveStoryData();
		}
		
		var targetState = PlayState.isStoryMode ? 
			(DoorsUtil.curRun.revivesLeft > 0 ? new MainMenuState() : new RunResultsState(F1_LOSE)) : 
			new NewFreeplayState();
		fadeAndSwitchState(targetState);
	}
	
	private function handleRevive():Void {
		ended = true;
		deathSprite.playAnim('deathConfirm', true);
		MenuSongManager.playSound(getReviveSound());
		
		if(PlayState.isStoryMode){
			DoorsUtil.isDead = false;
			DoorsUtil.curRun.revivesLeft -= 1;
			DoorsUtil.curRun.latestHealth = 2.0;
			DoorsUtil.saveStoryData();
			DoorsUtil.saveRunData();
		}
		
		fadeAndSwitchState(null, true);
	}
	
	private function fadeAndSwitchState(?targetState:FlxState, ?resetCurrentState:Bool = false):Void {
		stopGaming(resetCurrentState ? 1 : 0);
		fullBlack.makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		fullBlack.scale.set(1, 1);
		fullBlack.updateHitbox();
		fullBlack.screenCenter();
		fullBlack.cameras = [deathHUD];
		MenuSongManager.changeSongVolume(0.0001, 2);
		
		FlxTween.tween(fullBlack, {alpha: 1}, 2, {
			onComplete: function(twn) {
				MenuSongManager.curMusic = "";
				if (resetCurrentState)
					MusicBeatState.resetState();
				else if (targetState != null)
					MusicBeatState.switchState(targetState);
			}
		});
	}

	public function startGaming():Void {
		cameras[0].zoom = 1;
		yTarget = 200;
		menu.x = -menu.width - 200;

		fullBlack.y -= 1000;
		fullBlack.alpha = 1;
		focusPoint.setPosition(8000, 8000);
		targetPoint.setPosition(8000, 8000);

		var stateClassName = Type.getClassName(Type.getClass(this.state)).split(".").pop();
		
		if(stateClassName == "PlayState"){
			handlePlayStateTransition();
		} else if(stateClassName == "StoryMenuState"){
			handleStoryMenuTransition();
		}
	}
	
	private function handlePlayStateTransition():Void {
		FlxTween.tween(PlayState.instance.camGame, {angle: 720}, Conductor.crochet/1000 * 8, {ease: FlxEase.circIn});
		PlayState.instance.camHUD.fade(0xFF000000, Conductor.crochet/1000 * 2, false);
		FlxTween.tween(PlayState.instance.camGame, {zoom: PlayState.instance.camGame.zoom + 1}, Conductor.crochet/1000 * 2, {
			ease: FlxEase.backIn, 
			onComplete: function(twn) {
				startDeathTransition();
			}
		});
	}
	
	private function handleStoryMenuTransition():Void {
		black.alpha = 1;
		cameras[0].focusOn(focusPoint.getPosition());
		startDeathTransition();
	}
	
	private function startDeathTransition():Void {
		cameras[0].focusOn(focusPoint.getPosition());
		FlxTween.tween(fullBlack, {y: fullBlack.y + 1000}, Conductor.crochet / 1000 * 2, {
			ease: FlxEase.cubeOut, 
			onComplete: function(twn) {
				showDeathSequence();
			}
		});
	}
	
	private function showDeathSequence():Void {
		targetPoint.setPosition(FlxG.width/2, FlxG.height/2);
		focusPoint.setPosition(FlxG.width/2, FlxG.height/2);
		cameras[0].focusOn(focusPoint.getPosition());
		
		bubbleEmitter.start(false, Conductor.crochet/1000);
		starsEmitter.start(false, Conductor.crochet/1000 * 2);
		
		FlxTween.tween(mist0, {alpha: 0.6}, Conductor.crochet/1000 * 2, {ease: FlxEase.cubeOut});
		FlxTween.tween(mist1, {alpha: 0.6}, Conductor.crochet/1000 * 2, {ease: FlxEase.cubeOut});
		FlxTween.tween(mist2, {alpha: 0.8}, Conductor.crochet/1000 * 2, {ease: FlxEase.cubeOut});
		
		for(i in 0...songTipsText.length){
			FlxTween.tween(songTipsText[i], {alpha: 1}, Conductor.crochet / 1000 * 2, {
				startDelay: Conductor.crochet / 1000 * (8 * i), 
				onComplete: function(twn){
					FlxTween.tween(songTipsText[i], {alpha: 0}, Conductor.crochet / 1000 * 2, {
						startDelay: Conductor.crochet / 1000 * 4
					});
				}
			});
		}

		timerBeforeTransition = new FlxTimer().start(Conductor.crochet / 1000 * (8 * songTipsText.length), function(tmr){
			transitionFromLightText();
		});
	}

	private function transitionFromLightText():Void {
		FlxTween.tween(fullBlack, {alpha: 0}, Conductor.crochet / 1000 * 2, {
			onComplete: function(twn) {
				FlxTween.tween(this, {yTarget: 70}, Conductor.crochet / 1000 * 6, {ease: FlxEase.sineInOut});
				FlxTween.tween(cameras[0], {zoom:0.6}, Conductor.crochet / 1000 * 6, {startDelay: Conductor.crochet / 1000 * 2, ease: FlxEase.sineInOut});
				FlxTween.tween(targetPoint, {y:FlxG.height/2 - 173}, Conductor.crochet / 1000 * 2, {
					startDelay: Conductor.crochet / 1000 * 2, 
					ease: FlxEase.sineInOut, 
					onComplete: function(twn){
						FlxTween.tween(targetPoint, {x:FlxG.width/2 - 329}, Conductor.crochet / 1000 * 2, {
							startDelay: Conductor.crochet / 1000 * 2, 
							ease: FlxEase.sineInOut
						});
						FlxTween.tween(menu, {x: 127}, Conductor.crochet / 1000, {
							startDelay: Conductor.crochet / 1000 * 2, 
							ease: FlxEase.sineInOut
						});
						AwardsManager.onDeath();
					}
				});
			}
		});
	}

	public function stopGaming(chosen:Int):Void {
		remove(waterShader);
		FlxTween.tween(menu, {x: -menu.width - 200}, 2, {ease: FlxEase.smootherStepInOut});
		FlxTween.tween(this, {yTarget: 200}, 2, {ease: FlxEase.smootherStepInOut});
		
		if(chosen == 0){
			FlxTween.tween(targetPoint, {x: FlxG.width/2, y:FlxG.height/2 - 450}, 1, {ease: FlxEase.smootherStepInOut});
			FlxTween.tween(cameras[0], {zoom:1.6}, 2, {ease: FlxEase.smootherStepInOut});
		} else if(chosen == 1){
			FlxTween.tween(targetPoint, {x: FlxG.width/2, y:FlxG.height/2}, 1, {ease: FlxEase.smootherStepInOut});
			FlxTween.tween(cameras[0], {zoom:1.3}, 2, {ease: FlxEase.smootherStepInOut});
		}
	}

	override function update(elapsed:Float):Void {
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 8, 0, 1);
		focusPoint.setPosition(
			FlxMath.lerp(focusPoint.x, targetPoint.x, lerpVal), 
			FlxMath.lerp(focusPoint.y, targetPoint.y, lerpVal)
		);

		if (FlxG.sound.music.playing) {
			if(PlayState.instance != null && 
				PlayState.instance.vocals != null && 
				PlayState.instance.vocals.playing) {
					trace("stopped playstate vocals");
					PlayState.instance.vocals.stop();
				}
			Conductor.songPosition = FlxG.sound.music.time;
		}

		_timer += elapsed;
		mist0.y = yTarget + (Math.sin(_timer*0.35)*70);
		mist1.y = yTarget + 10 + (Math.sin(_timer*0.3)*80);
		mist2.y = yTarget - 10 + (Math.sin(_timer*0.4)*60);

		if(timerBeforeTransition != null && timerBeforeTransition.finished == false){
			if(controls.ACCEPT || controls.BACK) {
				for(tip in songTipsText) {
					FlxTween.cancelTweensOf(tip);
					tip.alpha = 0;
				}
				timerBeforeTransition.cancel();
				timerBeforeTransition.onComplete(new FlxTimer());
			}
		}

		super.update(elapsed);
	}

	override function beatHit():Void {
		super.beatHit();
		if(!ended) deathSprite.playAnim(getAnimName(), false);
	}

	private function getMusic():String {
		if(DoorsUtil.curRun.revivesLeft <= 0 && PlayState.isStoryMode) return "gameOverFinal";
		switch(DoorsUtil.causeOfDeath){
			case "SONG": return "gameOver";
			case "VOID": return "gameOverVoid";
			default: return "gameOver";
		}
	}

	private function getReviveSound():String {
		if(DoorsUtil.curRun.revivesLeft <= 0 && PlayState.isStoryMode) return "gameOverVoidEnd";
		switch(DoorsUtil.causeOfDeath){
			case "SONG": return "gameOverEnd";
			case "VOID": return "gameOverVoidEnd";
			default: return "gameOverEnd";
		}
	}

	private function getAnimName(?revive:Bool = false):String {
		if(DoorsUtil.curRun.revivesLeft <= 0 && PlayState.isStoryMode) return "deathLoopLast";
		if(revive) return "deathConfirm";
		switch(DoorsUtil.causeOfDeath){
			case "SONG": return "deathLoop";
			case "VOID": return "deathLoopVoid";
			default: return "deathLoop";
		}
	}

	private function getRandomDeathTip():Array<String> {
		if(DoorsUtil.curRun.revivesLeft <= 0 && PlayState.isStoryMode) {
			return [
				Lang.getText("lastLife", "death/tips", "_0"),
				Lang.getText("lastLife", "death/tips", "_1"),
				Lang.getText("lastLife", "death/tips", "_2"),
			];
		}

		if(Lang.getText(this.songTipCategory, "death/tips", "type") != TRANS_ERRORS.BAD_TRANS){
			if(Reflect.hasField(FlxG.save.data, this.songTipCategory)){
				Reflect.setProperty(FlxG.save.data, this.songTipCategory, Reflect.getProperty(FlxG.save.data, this.songTipCategory) + 1);
			} else {
				Reflect.setProperty(FlxG.save.data, this.songTipCategory, 1);
			}

			var tipIndex = ((Reflect.getProperty(FlxG.save.data, this.songTipCategory)-1) %3) + 1;
			return [
				Lang.getText('tip${tipIndex}', 'death/tips/${this.songTipCategory}', "_0"),
				Lang.getText('tip${tipIndex}', 'death/tips/${this.songTipCategory}', "_1"),
				Lang.getText('tip${tipIndex}', 'death/tips/${this.songTipCategory}', "_2"),
			];
		} else {
			return [
				Lang.getText('generalTip', 'death/tips', "_0"),
				Lang.getText('generalTip', 'death/tips', "_1"),
				Lang.getText('generalTip', 'death/tips', "_2"),
			];
		}
	}

	private function getTipSpeaker():TipSpeaker {
		return switch(deathMetadata.deathSpeaker) {
			case "CURIOUS": TipSpeaker.CURIOUS;
			case "GUIDING" | _: TipSpeaker.GUIDING;
		}
	}
}
