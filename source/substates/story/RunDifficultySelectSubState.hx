package substates.story;

import openfl.geom.Point;
import openfl.display.BitmapData;
import openfl.filters.ColorMatrixFilter;
import flixel.text.FlxTextNew as FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

using StringTools;

class RunDifficultySelectSubState extends StoryModeSubState
{
	var backgrounds:Array<FlxSprite> = [];
	var diffBg:FlxSprite;
	var curDifficulty:Int;

	var left:Bool = false;

	//the texts :woah:
	var fancyDifficulty:FlxText;
	var difficultyDescription:FlxText;

	// selectors
	var leftSelector:StoryModeSpriteHoverable;
	var rightSelector:StoryModeSpriteHoverable;

	public function new()
	{
		super();

		this.curDifficulty = 1;
		controls.isInSubstate = true;
		PlayState.storyDifficulty = curDifficulty;

		for(i in 0...CoolUtil.defaultDifficulties.length){
			backgrounds.push(new FlxSprite(0,0).loadGraphic(Paths.image('ui/difficulties/${CoolUtil.defaultDifficulties[i].toLowerCase()}Diff')));
			backgrounds[i].antialiasing = ClientPrefs.globalAntialiasing;
			backgrounds[i].alpha = 0.00001;
			add(backgrounds[i]);

			// HELL
			if(i == CoolUtil.defaultDifficulties.length - 1){
				var matrix:Array<Float> = [
					0.4, 0.4, 0.4, 0, 0,
					0.4, 0.4, 0.4, 0, 0,
					0.4, 0.4, 0.4, 0, 0,
					  0,   0,   0, 1, 0,
				];
				

				backgrounds[i].pixels.applyFilter(backgrounds[i].pixels, backgrounds[i].pixels.rect, new Point(), new ColorMatrixFilter(matrix));

				var wipImage:FlxSprite = new FlxSprite(0, 0);
				wipImage.loadGraphic(Paths.image("F1OverlayWIP_smaller"));
				wipImage.antialiasing = ClientPrefs.globalAntialiasing;
				backgrounds[i].stamp(wipImage, Math.round(wipImage.x), Math.round(wipImage.y));
			}
		}

		backgrounds[curDifficulty].alpha = 1;

		diffBg = new FlxSprite(228, 169).loadGraphic(Paths.image("ui/rectangle"));
		diffBg.antialiasing = ClientPrefs.globalAntialiasing;

		fancyDifficulty = new FlxText(-12, 168, FlxG.width, "", 60);
		fancyDifficulty.setFormat(FONT, 60, 0xFFFEDEBF, CENTER);
		fancyDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
		fancyDifficulty.text = CoolUtil.getDisplayDiffString(curDifficulty).toUpperCase();

		difficultyDescription = new FlxText(-12, 578, FlxG.width, "", 48);
		difficultyDescription.setFormat(FONT, 48, 0xFFFEDEBF, CENTER);
		difficultyDescription.setBorderStyle(OUTLINE, 0xFF452D25, 3, 1);
		difficultyDescription.antialiasing = ClientPrefs.globalAntialiasing;
		difficultyDescription.text = Lang.getText(CoolUtil.defaultDifficulties[curDifficulty], "generalshit/diffDescriptions");

        leftSelector = new StoryModeSpriteHoverable(228, 183, "freeplay/new/ArrowLeft");
        rightSelector = new StoryModeSpriteHoverable(994, 183, "freeplay/new/ArrowRight");

		add(diffBg);
		add(fancyDifficulty);
		add(difficultyDescription);
        add(leftSelector);
        add(rightSelector);

		#if mobile
		addVirtualPad(NONE, A);
		addVirtualPadCamera();
		#end

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		startGaming();
	}

	override function startGaming()
	{
		diffBg.x += FlxG.width;
		fancyDifficulty.x += FlxG.width;
		difficultyDescription.y += FlxG.height;

		FlxTween.cancelTweensOf(diffBg);
		FlxTween.cancelTweensOf(fancyDifficulty);
		FlxTween.cancelTweensOf(difficultyDescription);
		for(bg in backgrounds){
				FlxTween.cancelTweensOf(bg);
		}

		FlxTween.tween(diffBg, {x: diffBg.x - FlxG.width}, 1, {ease: FlxEase.backOut});
		FlxTween.tween(fancyDifficulty, {x: fancyDifficulty.x - FlxG.width}, 1, {ease: FlxEase.backOut});
		FlxTween.tween(
			difficultyDescription, {y: difficultyDescription.y - FlxG.height}, 1, {ease: FlxEase.backOut, startDelay: 0.5}
		);

		for(i=>bg in backgrounds){
			bg.alpha = 0;
			if(i == curDifficulty){
				FlxTween.tween(bg, {alpha: 1}, 1.2, {ease: FlxEase.circOut, startDelay: 0.5, onComplete: function(twn){
					changeDiff(0);
				}});
			}
		}
	}

	var hasLeft:Bool = false;
	override function stopGaming()
	{
		if(hasLeft) return;
		
		hasLeft = true;
		FlxTween.cancelTweensOf(diffBg);
		FlxTween.cancelTweensOf(fancyDifficulty);
		FlxTween.cancelTweensOf(difficultyDescription);
		for(bg in backgrounds){
			FlxTween.cancelTweensOf(bg);
		}


		FlxTween.tween(diffBg, {x: diffBg.x - FlxG.width}, 1, {ease: FlxEase.backInOut});
		FlxTween.tween(fancyDifficulty, {x: fancyDifficulty.x - FlxG.width}, 1, {ease: FlxEase.backInOut});
		FlxTween.tween(difficultyDescription, {y: difficultyDescription.y + FlxG.height}, 1, {ease: FlxEase.backInOut});

		for(i=>bg in backgrounds){
			if(i == curDifficulty){
				FlxTween.tween(bg, {alpha: 0}, 1.2, {ease: FlxEase.circIn, startDelay: 0.8, onComplete: function(twn){
					close();
				}});
			}
		}
	}

	override function update(elapsed:Float)
	{
		if(!left){
			if(controls.ACCEPT){
				if(curDifficulty == CoolUtil.defaultDifficulties.length - 1){
					cameras[0].shake(0.02, 0.05, true);
					fancyDifficulty.text = Lang.getText("wip", "generalshit");
					difficultyDescription.text = Lang.getText("Wip", "generalshit/diffDescriptions");

					super.update(elapsed);
					return;
				} else if(curDifficulty == CoolUtil.defaultDifficulties.length - 2) {
					if(!PopupSubState.hasSeenPopup("expertDiff")){
						openSubState(new PopupSubState("expertDiff"));
						
						super.update(elapsed);
						return;
					}
				}
				left = true;
				DoorsUtil.isNewRun = false;
				doShit();
			}

			if(controls.isInSubstate == true)
			  controls.isInSubstate = true;

			leftSelector.checkOverlap(this.cameras[0]);
			rightSelector.checkOverlap(this.cameras[0]);
			
			if (controls.UI_LEFT_P)	changeDiff(-1); 
			if (leftSelector.isHovered && FlxG.mouse.justPressed)	changeDiff(-1); 
			if (controls.UI_RIGHT_P) changeDiff(1);
			if (rightSelector.isHovered && FlxG.mouse.justPressed)	changeDiff(1); 
		}

		super.update(elapsed);
	}

	function doShit(){
		stopGaming();
	}
	
	function changeDiff(change:Int = 0, ?isHell:Bool = false)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 0;
		if (curDifficulty >= 3)
			curDifficulty = 3;

		DoorsUtil.setupRunData(CoolUtil.defaultDifficulties[curDifficulty]);

		PlayState.storyDifficulty = curDifficulty;
		fancyDifficulty.text = CoolUtil.getDisplayDiffString(curDifficulty).toUpperCase();
		difficultyDescription.text = Lang.getText(CoolUtil.defaultDifficulties[curDifficulty], "generalshit/diffDescriptions");

		for(i=>bg in backgrounds){
			FlxTween.cancelTweensOf(bg);
			if(change >= 1){
				if(i == curDifficulty) FlxTween.tween(bg, {alpha: 1}, 1.2, {ease: FlxEase.expoOut});
				else FlxTween.tween(bg, {alpha: 0}, 1.2, {ease: FlxEase.expoOut, startDelay: 1.2});
			} else {
				if(i == curDifficulty) bg.alpha = 1;
				else FlxTween.tween(bg, {alpha: 0}, 1.2, {ease: FlxEase.expoOut});
			}
		}
	}
}
