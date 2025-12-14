package states;

import flixel.math.FlxRandom;
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

import SoundCompare;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;
import haxe.Json;

using StringTools;

typedef GalleryImage = {
	var path:String;
	
	var title:String;
	var subtext:String;
}

typedef GallerySong = {
	var path:String;
	
	var title:String;
	var subtext:String;

	var isPlayable:Bool;
}

typedef GalleryData = {
	var imageGallery:Array<GalleryImage>;
	var songGallery:Array<GallerySong>; 	// NOT YET IMPLEMENTED
}

class GalleryState extends MusicBeatState
{
	// Constants
	private static inline final OFFSET_Y:Float = -12;
	private static inline final SCREEN_WIDTH:Int = 1280;
	private static inline final MAX_IMAGE_WIDTH:Int = 865;
	private static inline final MAX_IMAGE_HEIGHT:Int = 487;
	
	// UI Components
	private var descText:FlxText;
	private var descBox:AttachedSprite;
	private var imageArray:Array<FlxSprite> = [];
	
	// State variables
	private var curSelected:Int = 0;
	private var intendedColor:Int;
	private var colorTween:FlxTween;
	private var moveTween:FlxTween = null;
	private var quitting:Bool = false;
	
	// Gallery content
	private var galleryData:GalleryData;

	override function create()
	{
		MenuSongManager.crossfade("freakyGallery", 1, 140, true);
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = true;
		
		loadGalleryData();
		setupBackground();
		loadGalleryImages();
		setupDescriptionBox();
		setupOverlays();
		
		changeSelection();
		super.create();
	}

	private function loadGalleryData():Void
	{
		var jsonPath:String = Paths.getPreloadPath("data/gallery.json");
		var json:GalleryData = Json.parse(sys.io.File.getContent(jsonPath));

		if(json != null){
			galleryData = json;
		}
	}

	private function setupBackground():Void
	{
		var bg = new FlxSprite().loadGraphic(Paths.image("menus/gallery/bg"));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		
		var grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0xff432004, 0xff400415));
		grid.velocity.set(40, 20);
		grid.alpha = 0.3;
		add(grid);
	}

	private function loadGalleryImages():Void
	{
		for (i in 0...galleryData.imageGallery.length)
		{
			var image:FlxSprite = new FlxSprite(0, 0, Paths.image('gallery/' + galleryData.imageGallery[i].path));
			var ratio:Float = calculateScaleRatio(image);

			image.scale.set(ratio, ratio);
			image.updateHitbox();
			image.screenCenter(XY);

			image.x += SCREEN_WIDTH * i;

			imageArray.push(image);
			add(image);
		}
	}

	private function calculateScaleRatio(image:FlxSprite):Float
	{
		var ratio:Float = 1;

		if (image.height > MAX_IMAGE_HEIGHT) {
			ratio = MAX_IMAGE_HEIGHT / image.height;
		}

		if (image.width > MAX_IMAGE_WIDTH && ratio > MAX_IMAGE_WIDTH / image.width) {
			ratio = MAX_IMAGE_WIDTH / image.width;
		}

		return ratio;
	}

	private function setupDescriptionBox():Void
	{
		// Description background
		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		// Description text
		descText = new FlxText(50, FlxG.height + OFFSET_Y - 25, 1180, "", 32);
		descText.setFormat(FONT, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.antialiasing = ClientPrefs.globalAntialiasing;
		descBox.sprTracker = descText;
		add(descText);

		#if mobile
		addVirtualPad(LEFT_RIGHT, B);
		addVirtualPadCamera();
		#end
	}

	private function setupOverlays():Void
	{
		var photos = new FlxSprite().loadGraphic(Paths.image("menus/gallery/photos"));
		photos.antialiasing = ClientPrefs.globalAntialiasing;
		add(photos);

		var plant = new FlxSprite().loadGraphic(Paths.image("menus/gallery/plant"));
		plant.antialiasing = ClientPrefs.globalAntialiasing;
		add(plant);
	}

	override function update(elapsed:Float)
	{
		if (!quitting) {
			handleInput();
		}
		
		super.update(elapsed);
	}

	private function handleInput():Void
	{
		if (galleryData.imageGallery.length > 1) {
			if (controls.UI_LEFT_P) {
				changeSelection(-1);
			}
			if (controls.UI_RIGHT_P) {
				changeSelection(1);
			}
		}

		if (controls.BACK) {
			if (colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
			quitting = true;
		}
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		curSelected += change;
		curSelected = wrapSelection(curSelected, galleryData.imageGallery.length);

		updateImagesPosition();
		updateDescriptionText();
	}
	
	private function wrapSelection(selection:Int, length:Int):Int
	{
		if (selection < 0) return length - 1;
		if (selection >= length) return 0;
		return selection;
	}
	
	private function updateImagesPosition():Void
	{
		for (i in 0...imageArray.length) {
			imageArray[i].x = (SCREEN_WIDTH * (i - curSelected)) + (SCREEN_WIDTH/2 - imageArray[i].width/2);
		}
	}
	
	private function updateDescriptionText():Void
	{
		// Update text content
		descText.text = galleryData.imageGallery[curSelected].title + "\n" + galleryData.imageGallery[curSelected].subtext;
		descText.y = FlxG.height - descText.height + OFFSET_Y - 60;

		// Animate text entry
		if (moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y: descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

		// Resize background box
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}
}
