package states;

import backend.metadata.FreeplayMetadata;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxTextNew as FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.filters.BitmapFilterQuality;
import openfl.filters.BlurFilter;
import flixel.graphics.frames.FlxFilterFrames;
#if desktop
import Discord.DiscordClient;
#end

using StringTools;

class NewFreeplayState extends MusicBeatState
{
	public static var instance:NewFreeplayState;

	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	var initialCameraPosition:FlxPoint;
	public var camFollowPos:FlxObject;
	public var overrideCamFollow:Bool;

	public var categories:Array<String> = [];
	public static var currentCategory:String = "start";

	public var inBook:Bool = false;

	var bg:FlxBackdrop;
	var paintings:FlxTypedSpriteGroup<Painting>;
	var paintingFpsData:Array<Int> = [];

	public var knobIndicator:MoneyIndicator;

	var leftSelector:StoryModeSpriteHoverable;
	var rightSelector:StoryModeSpriteHoverable;
	var entityNameText:FlxText;
	var entityNameTextBg:FlxSprite;

	var wipOverlay:FlxSprite;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end
		MenuSongManager.crossfade("freakyFreeplay", 1, 140, true);
		Paths.clearStoredMemory();
		DoorsUtil.loadFreeplayData();
		instance = this;
		persistentUpdate = true;
		PlayState.isStoryMode = false;

		camGame = new FlxCamera();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		camGame.follow(camFollowPos, LOCKON, 0.95);

		camGame.zoom = 0.7;
		initialCameraPosition = new FlxPoint(960, 540);
		camFollowPos.setPosition(initialCameraPosition.x, initialCameraPosition.y);
		overrideCamFollow = false;
		
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camGame, true);
		FlxG.cameras.add(camHUD, false);

        bg = new FlxBackdrop(Paths.image('freeplay/new/bg'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);

		paintings = new FlxTypedSpriteGroup<Painting>(529, 99);
		var metadata:FreeplayMetadata = new FreeplayMetadata();
		for(testicle in metadata.categories){
			categories.push(testicle.catName);
			paintingFpsData.push(testicle.catFPS);
			paintings.add(new Painting(testicle));
		}

		//position paintings at 529 ; 99

		knobIndicator = new MoneyIndicator(FlxG.width * 0.01, FlxG.height * 0.88, true);
		knobIndicator.cameras = [camHUD];
		add(knobIndicator);

		// make the new stuff

        entityNameTextBg = new FlxSprite(152, 601).loadGraphic(Paths.image('freeplay/entityNameBG'));
		entityNameTextBg.antialiasing = ClientPrefs.globalAntialiasing;
		entityNameTextBg.updateHitbox();
		entityNameTextBg.cameras = [camHUD];
        add(entityNameTextBg);

		entityNameText = new FlxText(326, 593, 652, "TEST STRING");
		entityNameText.setFormat(MEDIUM_FONT, 64, 0xFEDEBF, CENTER, OUTLINE, 0xFF452D25);
		entityNameText.borderSize = 4;
		entityNameText.antialiasing = ClientPrefs.globalAntialiasing;
		entityNameText.cameras = [camHUD];
		add(entityNameText);

        leftSelector = new StoryModeSpriteHoverable(184, 619, "freeplay/new/ArrowLeft");
		leftSelector.cameras = [camHUD];
		add(leftSelector);

        rightSelector = new StoryModeSpriteHoverable(1062, 619, "freeplay/new/ArrowRight");
		rightSelector.cameras = [camHUD];
		add(rightSelector);
		
		add(paintings);

		wipOverlay = new FlxSprite(0, 0).loadGraphic(Paths.image("F1OverlayWIP"));
		wipOverlay.antialiasing = ClientPrefs.globalAntialiasing;
		wipOverlay.cameras = [camHUD];
		wipOverlay.setGraphicSize(1280, 720);
		wipOverlay.updateHitbox();
		add(wipOverlay);

		#if mobile
		addVirtualPad(LEFT_RIGHT, A_B);
		addVirtualPadCamera();
		#end
		
		changeCategory(0);
		inBook = false;
		super.create();
		Paths.clearUnusedMemory();
		

		FlxG.console.registerFunction("lockAllCategories", function() {
			for(painting in paintings.members){
				Reflect.setProperty(FlxG.save.data, painting.catInfo.catName + "category-unlocked", false);
			}
			MusicBeatState.switchState(new NewFreeplayState());
		});
	}

	override function closeSubState() {
		inBook = false;
		super.closeSubState();
	}

	public var isWatchingAnimation:Bool = false;
	override function update(elapsed:Float)
	{
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 4, 0, 1);
		if(!overrideCamFollow){
			camFollowPos.setPosition(
				FlxMath.lerp(camFollowPos.x, FlxG.mouse.getScreenPosition().x / 40 + initialCameraPosition.x - 32, lerpVal), 
				FlxMath.lerp(camFollowPos.y, FlxG.mouse.getScreenPosition().y / 32 + initialCameraPosition.y - 22.5, lerpVal)
			);
		}

		leftSelector.x = FlxMath.lerp(leftSelector.x, 184, lerpVal/2);
		rightSelector.x = FlxMath.lerp(rightSelector.x, 1062, lerpVal/2);

		if(!inBook && !isWatchingAnimation){
			leftSelector.checkOverlap(camHUD);
			rightSelector.checkOverlap(camHUD);
			if(controls.UI_LEFT_P #if desktop || (leftSelector.isHovered && FlxG.mouse.justPressed) #end){
				changeCategory(-1);
			} else if (controls.UI_RIGHT_P #if desktop || (rightSelector.isHovered && FlxG.mouse.justPressed) #end){
				changeCategory(1);
			}

			#if debug
			if(FlxG.keys.justPressed.J){
				paintings.members[categories.indexOf(currentCategory)].tryUnlockCategory(true);
			}
			#end
	
			if(controls.ACCEPT){
				if(paintings.members[categories.indexOf(currentCategory)].catInfo.unlockCondition == WIP) {
					MenuSongManager.playSoundWithRandomPitch("lock", [0.8, 1.2], 1.0);
					camHUD.flash(0xA0FF0000, 1, null, true);
					return;
				}


				if(paintings.members[categories.indexOf(currentCategory)].tryUnlockCategory(false).isUnlocked){
					inBook = true;
					openSubState(new NewFreeplaySelectSubState(this, currentCategory));
				} else {
					FlxG.camera.shake(0.01, 0.1);
					if (knobIndicator != null) 
						FlxTween.color(knobIndicator.moneyCounter, 1, 0xFFFF0000, 0xFFFEDEBF, {ease:FlxEase.expoOut});
				}
			}
	
			if (controls.BACK)
			{
				DoorsUtil.saveFreeplayData();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		super.update(elapsed);
	}

	function changeCategory(change:Int){
		var curCatInt = categories.indexOf(currentCategory);
		curCatInt += change;
		if(curCatInt >= categories.length) curCatInt = 0;
		else if (curCatInt < 0) curCatInt = categories.length-1;

		if(change < 0) leftSelector.x -= 20;
		else if (change > 0) rightSelector.x += 20;

		paintings.forEach(function(spr){
			spr.alpha = 0;
		});
		paintings.members[curCatInt].alpha = 1;
		currentCategory = categories[curCatInt];
		entityNameText.text = Lang.getText(currentCategory, "states/freeplay/categories", "value");

		entityNameText.y = 618;
		entityNameText.size = 40;

		if(paintings.members[curCatInt].catInfo.unlockCondition == WIP){
			wipOverlay.alpha = 1;
		} else {
			wipOverlay.alpha = 0;
		}
		
		return currentCategory;
	}
}

class Painting extends FlxSpriteGroup {

	var blurFilter:BlurFilter;

	public var isUnlocked(get, never):Bool;
	function get_isUnlocked(){
		switch(catInfo.unlockCondition){
			case ALWAYS_UNLOCKED: return true;
			case KNOBS_ACHIEVEMENT:
				if(AwardsManager.isUnlockedID(catInfo.tiedAchievement)){
					return true;
				}
				if(Reflect.hasField(FlxG.save.data, catInfo.catName + "category-unlocked")){
					return Reflect.field(FlxG.save.data, catInfo.catName + "category-unlocked");
				}
			case ACHIEVEMENT:
				if(AwardsManager.isUnlockedID(catInfo.tiedAchievement)){
					return true;
				}
			case KNOBS:
				if(Reflect.hasField(FlxG.save.data, catInfo.catName + "category-unlocked")){
					return Reflect.field(FlxG.save.data, catInfo.catName + "category-unlocked");
				}
			case WIP:
				return false;
			default: return false;
		}
		return false;
	}

	public var catInfo:FreeplayCategory;

	var painting:FlxSprite;
	var lockedImage:FlxSprite;
	var knobImage:FlxSprite;
	var knobText:FlxText;
	var separator:FlxSprite;
	var separatorText:FlxText;
	var unlockText:FlxText;

	public function new(catInfo:FreeplayCategory){
		super();
		this.catInfo = catInfo;
		painting = new FlxSprite();
		painting.frames = Paths.getSparrowAtlas("freeplay/new/paintings/" + catInfo.catName);
		painting.animation.addByPrefix("idle", catInfo.catName, catInfo.catFPS, true, false, false);
		painting.animation.play("idle");
		painting.antialiasing = ClientPrefs.globalAntialiasing;
		painting.alpha = 0;
		painting.setGraphicSize(866, 512);
		painting.updateHitbox();
		add(painting);

		blurFilter = new BlurFilter(16, 16, BitmapFilterQuality.MEDIUM);
		if(!isUnlocked){
			applyBlur();
			spawnPrerequisites();
		}
	}

	var filterFrames:FlxFilterFrames;
	public function applyBlur() {
		painting.frames = Paths.getSparrowAtlas("freeplay/new/paintings/blur/" + catInfo.catName);
	}

	public function removePrerequisite(?doAnim:Bool = false, ?callback:Void->Void) {
		if(doAnim){
			if(knobImage != null && this.members.contains(knobImage)) 
				FlxTween.tween(knobImage, {alpha: 0}, 1.6, {ease: FlxEase.circInOut, onComplete:function(twn){
					if(knobImage != null && this.members.contains(knobImage)) remove(knobImage);
					if(knobText != null && this.members.contains(knobText)) remove(knobText);
					if(separator != null && this.members.contains(separator)) remove(separator);
					if(separatorText != null && this.members.contains(separatorText)) remove(separatorText);
					if(unlockText != null && this.members.contains(unlockText)) remove(unlockText);
				}});
			if(knobText != null && this.members.contains(knobText)) FlxTween.tween(knobText, {alpha: 0}, 1, {ease: FlxEase.circInOut});
			if(separator != null && this.members.contains(separator)) FlxTween.tween(separator, {alpha: 0}, 1, {ease: FlxEase.circInOut});
			if(separatorText != null && this.members.contains(separatorText)) FlxTween.tween(separatorText, {alpha: 0}, 1, {ease: FlxEase.circInOut});
			if(unlockText != null && this.members.contains(unlockText)) FlxTween.tween(unlockText, {alpha: 0}, 1, {ease: FlxEase.circInOut});
			
			if(lockedImage != null && this.members.contains(lockedImage)) FlxTween.tween(lockedImage, {y: lockedImage.y + 180, "scale.x": 4, "scale.y": 4}, 2.6, {ease: FlxEase.circOut});
			if(lockedImage != null && this.members.contains(lockedImage)) FlxTween.shake(lockedImage, 0.2, 2.6, XY, {ease: FlxEase.circIn, onComplete: function(twn){
				NewFreeplayState.instance.camGame.flash(0x20FFFFFF, 1);
				if(lockedImage != null && this.members.contains(lockedImage)) remove(lockedImage);
				if(painting != null && this.members.contains(painting)) remove(painting);
				painting = new FlxSprite();
				painting.frames = Paths.getSparrowAtlas("freeplay/new/paintings/" + catInfo.catName);
				painting.animation.addByPrefix("idle", catInfo.catName, catInfo.catFPS, true, false, false);
				painting.animation.play("idle");
				painting.antialiasing = ClientPrefs.globalAntialiasing;
				painting.setGraphicSize(866, 512);
				painting.updateHitbox();
				add(painting);
				if(callback != null) callback();
			}});
		} else {
			if(painting != null && this.members.contains(painting)) remove(painting);
			painting = new FlxSprite();
			painting.frames = Paths.getSparrowAtlas("freeplay/new/paintings/" + catInfo.catName);
			painting.animation.addByPrefix("idle", catInfo.catName, catInfo.catFPS, true, false, false);
			painting.animation.play("idle");
			painting.antialiasing = ClientPrefs.globalAntialiasing;
			painting.setGraphicSize(866, 512);
			painting.updateHitbox();
			add(painting);
	
			if(lockedImage != null && this.members.contains(lockedImage)) remove(lockedImage);
			if(knobImage != null && this.members.contains(knobImage)) remove(knobImage);
			if(knobText != null && this.members.contains(knobText)) remove(knobText);
			if(separator != null && this.members.contains(separator)) remove(separator);
			if(separatorText != null && this.members.contains(separatorText)) remove(separatorText);
			if(unlockText != null && this.members.contains(unlockText)) remove(unlockText);

			if(callback != null) callback();
		}

	}
	
	public function spawnPrerequisites() {
		lockedImage = new FlxSprite(380, 25);
		lockedImage.loadGraphic(Paths.image("awards/locked"));
		lockedImage.antialiasing = ClientPrefs.globalAntialiasing;

		switch(catInfo.unlockCondition){
			case WIP:
				//nothing
			case KNOBS_ACHIEVEMENT:
				knobImage = new FlxSprite(345, 175);
				knobImage.loadGraphic(Paths.image("freeplay/knob"));
				knobImage.antialiasing = ClientPrefs.globalAntialiasing;
				add(knobImage);
		
				knobText = new FlxText(456, 172, Std.string(catInfo.knobCost));
				knobText.setFormat(FONT, 64, 0xFFFEDEBF, LEFT, OUTLINE, 0xFF452D25);
				knobText.antialiasing = ClientPrefs.globalAntialiasing;
				add(knobText);
		
				separator = new FlxSprite(196, 277);
				separator.loadGraphic(Paths.image("freeplay/separator"));
				separator.antialiasing = ClientPrefs.globalAntialiasing;
				add(separator);
		
				separatorText = new FlxText(425, 258, 58, Lang.getText("or", "states/freeplay"));
				separatorText.setFormat(FONT, 32, 0xFFFEDEBF, CENTER, OUTLINE, 0xFF452D25);
				separatorText.antialiasing = ClientPrefs.globalAntialiasing;
				add(separatorText);

				var text:String = Lang.getText("unlock", "states/freeplay");
				if(AwardsManager.getAwardFromID(catInfo.tiedAchievement) != null)
					text = text.replace("{0}", AwardsManager.getAwardFromID(catInfo.tiedAchievement).name);
				unlockText = new FlxText(0, 297, 912, text);
				unlockText.setFormat(FONT, 48, 0xFFFEDEBF, CENTER, OUTLINE, 0xFF452D25);
				unlockText.antialiasing = ClientPrefs.globalAntialiasing;
				add(unlockText);
				add(lockedImage);
			case KNOBS:
				knobImage = new FlxSprite(355, 241);
				knobImage.loadGraphic(Paths.image("freeplay/knob"));
				knobImage.antialiasing = ClientPrefs.globalAntialiasing;
				add(knobImage);
		
				knobText = new FlxText(466, 238, Std.string(catInfo.knobCost));
				knobText.setFormat(FONT, 64, 0xFFFEDEBF, LEFT, OUTLINE, 0xFF452D25);
				knobText.antialiasing = ClientPrefs.globalAntialiasing;
				add(knobText);
				add(lockedImage);
			default:
				add(lockedImage);
		}
	}

	public function tryUnlockCategory(?force:Bool = false){
		if(isUnlocked) {
			removePrerequisite();
			return {isUnlocked:true, success: true, catName: "none"};
		}
		if(DoorsUtil.knobs > catInfo.knobCost || force) {
			if(!force) DoorsUtil.addKnobs(-catInfo.knobCost, 1.0);
			NewFreeplayState.instance.knobIndicator.addMoney(-catInfo.knobCost);
			MenuSongManager.playSoundWithRandomPitch("GoldDecrease", [0.8, 1.2], 1.0);

			Reflect.setProperty(FlxG.save.data, catInfo.catName + "category-unlocked", true);
			FlxG.save.flush();
			NewFreeplayState.instance.isWatchingAnimation = true;
			MenuSongManager.playSound("lockbreaksound", 1.0);
			removePrerequisite(true, function(){
				NewFreeplayState.instance.isWatchingAnimation = false;
			});
		
			return {
				isUnlocked: false,
				success: true,
				catName: catInfo.catName
			}
		} else {
			MenuSongManager.playSoundWithRandomPitch("lock", [0.8, 1.2], 1.0);
			return {isUnlocked: false, success: false, catName: "none"};
		}
	}
}
