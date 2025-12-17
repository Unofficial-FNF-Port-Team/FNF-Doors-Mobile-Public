package substates;

import backend.metadata.FreeplayMetadata;
import states.AchievementsState.ScrollBar;
import flixel.util.FlxStringUtil;
import flxanimate.FlxAnimate;
import flixel.math.FlxRect;
import backend.metadata.SongMetadata;
import sys.io.File;
import haxe.Json;
import sys.FileSystem;
import online.SongLeaderboardSubstate;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxTextNew as FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.input.keyboard.FlxKey;

using StringTools;

class NewFreeplaySelectSubState extends MusicBeatSubstate
{
	var scrollRect:FlxRect = null;
	public static var instance:NewFreeplaySelectSubState;
	var parentState:NewFreeplayState;

	var bgHorizontalGroup:FlxSpriteGroup;
	var bgVerticalGroup:FlxSpriteGroup;
	var bookGroup:FlxSpriteGroup;

	public var metadatas:Array<SongMetadata> = [];
	var bookSongs:Array<BookSong> = [];
	var difficultiesAvailable:Array<Int> = [];

	public var curSelection:Int = 0;
	public var curDifficulty:Int = 1;
	
	var leaderboardsButton:StoryModeSpriteHoverable;
	var modifiersButton:StoryModeSpriteHoverable;

	var ostArt:FlxSprite;

	/*
	* If the book has many songs, we may need a scroll bar
	*/
	var useScrollBar:Bool = false;
	var scrollBar:ScrollBar;
	var scroll:Float = 0;

	/*
	* Song Length
	*/
	var songLengthText:FlxText;
	var actualSongLengthText:FlxText;

	/*
	* Difficulty Selector Stuff
	*/
	var leftSelector:StoryModeSpriteHoverable;
	var rightSelector:StoryModeSpriteHoverable;
	var availableOptions:FlxSpriteGroup;
	var difficultyLerpPosition:Array<Float> = [];

	/*
	* Difficulty bar stuff
	*/
	var difficultyBars:FlxTypedSpriteGroup<DifficultyBar>;

	/*
	* Multiple pages ! 
	* Page 1 = Song Selection
	* Page 2 = Background Selection for said song
	*/
	var currentPage:Int = 0;

	public function new(parentState:NewFreeplayState, categoryName:String)
	{
		super();
		controls.isInSubstate = true;
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		instance = this;
		this.parentState = parentState;
		metadatas = getMetadatasForCategory();

		bgHorizontalGroup = new FlxSpriteGroup();
		bgHorizontalGroup.setPosition(0, 573);

		bgVerticalGroup = new FlxSpriteGroup();
		bgVerticalGroup.setPosition(0, 11);

		bookGroup = new FlxSpriteGroup();
		bookGroup.setPosition(237, 0);

		var bgHorizontal = new FlxSprite(0,0).loadGraphic(Paths.image("freeplay/new/selectedMenuBGHor"));
		bgHorizontal.antialiasing = ClientPrefs.globalAntialiasing;
		bgHorizontalGroup.add(bgHorizontal);

		var bgVertical = new FlxSprite(0,0).loadGraphic(Paths.image("freeplay/new/selectedMenuBGVer"));
		bgVertical.antialiasing = ClientPrefs.globalAntialiasing;
		bgVerticalGroup.add(bgVertical);

		var book = new FlxSprite(0,0).loadGraphic(Paths.image("freeplay/new/book"));
		book.setGraphicSize(1055, 594);
		book.updateHitbox();
		book.antialiasing = ClientPrefs.globalAntialiasing;
		bookGroup.add(book);

		var sticker = new FlxSprite(101,-8).loadGraphic(Paths.image("freeplay/new/sticker"));
		sticker.antialiasing = ClientPrefs.globalAntialiasing;
		bookGroup.add(sticker);

		makeBookText();

		add(bookGroup);
		useScrollBar = bookSongs.length > 6;
		if(useScrollBar){
			scrollBar = new ScrollBar(489, 34, this, "scroll", (bookSongs.length-4)*90);
			scrollBar.scrollBar.loadGraphic(Paths.image("freeplay/new/vertScrollBar"));
			scrollBar.scrollBG.loadGraphic(Paths.image("freeplay/new/vertScroll"));
			bookGroup.add(scrollBar);
		}
		add(bgVerticalGroup);
		add(bgHorizontalGroup);
		
		leaderboardsButton = new StoryModeSpriteHoverable(15, -20, "freeplay/leaderboard");
		leaderboardsButton.antialiasing = ClientPrefs.globalAntialiasing;
		bgHorizontalGroup.add(leaderboardsButton);
		
		Paths.image("freeplay/leaderboardHover"); //preload the hovered image

		modifiersButton = new StoryModeSpriteHoverable(1100, 0, "freeplay/modifier");
		modifiersButton.antialiasing = ClientPrefs.globalAntialiasing;
		bgHorizontalGroup.add(modifiersButton);

		ModifierManager.onReset();

		Paths.image("freeplay/modifierHover"); //preload the hovered image

        #if mobile
		addVirtualPad(LEFT_FULL, A_B);
		addVirtualPadCamera();
		virtualPad.y -= 140;
		#end
		
		startGaming();
		changeSelection(0);
	}

	function getMetadatasForCategory(){
		var metadataList:Array<SongMetadata> = [];
		var category = NewFreeplayState.currentCategory;
		for(folder in FileSystem.readDirectory(Paths.getPreloadPath("data/"))){
			if(!FileSystem.isDirectory(Paths.getPreloadPath("data/" + folder + "/"))) continue;
			var metadata:SongMetadata = new SongMetadata(folder);
			if(metadata.category != category) continue;
			metadataList.push(metadata);
		}

		var songOrder:Array<String> = [];
		var freeplayMetadata:FreeplayMetadata = new FreeplayMetadata();
		for(testicle in freeplayMetadata.categories){
			if(testicle.catName != category) continue;
			if(testicle.catSongs != null) {
				songOrder = testicle.catSongs;
				break;
			}
		}

		var fullSongOrder:Bool = false;
		for(song in [for (x in metadataList) x.internalName]){
			if(songOrder.contains(song)){
				fullSongOrder = true;
			}
		}

		if(fullSongOrder){
			var tmpList = [];
			for(i=>orderedSong in songOrder){
				for(j=>song in [for (x in metadataList) x.internalName]){
					if(song.trim() != orderedSong.trim()) {
						continue;
					}

					tmpList.push(metadataList[j]);
					break;
				}
			}
			metadataList = tmpList;
		} else {
			metadataList.sort(function(a, b){
				if(a.difficulties.normal == b.difficulties.normal)
					return a.mechanicDifficulties.normal - b.mechanicDifficulties.normal;
				return a.difficulties.normal - b.difficulties.normal;
			});
		}
		return metadataList;
	}

	function startGaming()
	{
		bookGroup.y -= bookGroup.height;
		bgVerticalGroup.x -= bgVerticalGroup.width;
		bgHorizontalGroup.y += bgHorizontalGroup.height;

		FlxTween.tween(bookGroup, {y: bookGroup.y + bookGroup.height}, 0.4, {ease: FlxEase.backOut, onComplete: function(twn){
			canInteract = true;
		}});
		FlxTween.tween(bgVerticalGroup, {x: bgVerticalGroup.x + bgVerticalGroup.width}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(bgHorizontalGroup, {y: bgHorizontalGroup.y - bgHorizontalGroup.height}, 0.4, {ease: FlxEase.backOut});
	}

	function stopGaming()
	{
		FlxTween.tween(bookGroup, {y: bookGroup.y - bookGroup.height}, 0.4, {ease: FlxEase.backOut, onComplete: function(twn){
			close();
		}});
		FlxTween.tween(bgVerticalGroup, {x: bgVerticalGroup.x - bgVerticalGroup.width}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(bgHorizontalGroup, {y: bgHorizontalGroup.y + bgHorizontalGroup.height}, 0.4, {ease: FlxEase.backOut});
	}

	function enterSong(){

	}

	public var canInteract:Bool = false;
	public static var isInOtherSub:Bool = false;
	override function update(elapsed:Float)
	{
		if(canInteract){
			var upScroll = FlxG.mouse.wheel > 0;
			var downScroll = FlxG.mouse.wheel < 0;
			if(controls.UI_UP_P || virtualPad.buttonUp.justPressed){ changeSelection(-1); }
			if(upScroll){ changeSelection(-1); }
			if(controls.UI_DOWN_P || virtualPad.buttonDown.justPressed){ changeSelection(1); }
			if(downScroll){ changeSelection(1); }
			if(controls.UI_LEFT_P || virtualPad.buttonLeft.justPressed){ changeDifficulty(-1); }
			if(controls.UI_RIGHT_P || virtualPad.buttonRight.justPressed){ changeDifficulty(1); }

			if(controls.ACCEPT || virtualPad.buttonA.justPressed){
				chooseSong();
			}

			if(controls.isInSubstate == false)
			  controls.isInSubstate = true;

			if(FlxG.keys.justPressed.SEVEN) { DoorsUtil.addKnobs(100, 1.0); }
			
			if (controls.BACK || virtualPad.buttonB.justPressed) {
				stopGaming();
			}
			leaderboardsButton.checkOverlap(this.cameras[0]);
			modifiersButton.checkOverlap(this.cameras[0]);

			if(leaderboardsButton.justHovered){
				leaderboardsButton.loadGraphic(Paths.image("freeplay/leaderboardHover"));
			} else if (leaderboardsButton.isHovered){
				if(FlxG.mouse.justPressed){
					isInOtherSub = true;
					openSubState(new SongLeaderboardSubstate(
						metadatas[curSelection].displayName, 
						CoolUtil.difficulties[curDifficulty], 
						metadatas[curSelection].internalName
					));
				}
			} else {
				leaderboardsButton.loadGraphic(Paths.image("freeplay/leaderboard"));
			}

			if(modifiersButton.justHovered){
				modifiersButton.loadGraphic(Paths.image("freeplay/modifierHover"));
			} else if (modifiersButton.isHovered){
				if(FlxG.mouse.justPressed){
					isInOtherSub = true;
					openSubState(new FreeplayModifierSelectSubState(
						metadatas[curSelection].internalName, 
						curDifficulty == 3,
						chooseSong
					));
				}
			} else {
				modifiersButton.loadGraphic(Paths.image("freeplay/modifier"));
			}
		}

		var rect = FlxRect.get(495, 32, 290, 90);
		for (i=>diffText in availableOptions.members){
			diffText.x = FlxMath.lerp(diffText.x, difficultyLerpPosition[i] + availableOptions.x, CoolUtil.boundTo(elapsed * 6, 0, 1));
			diffText.clipRect = FlxRect.get(rect.x - diffText.x, diffText.clipRect.y, rect.width, diffText.clipRect.height);
		}
		rect.put();
		if(useScrollBar){
			scroll -= FlxG.mouse.wheel*50*elapsed*240;
			if (this.scrollRect == null) this.scrollRect = FlxRect.get(277, 35, 900, 555);
			for(i=>bookSong in bookSongs){
				bookSong.y = FlxMath.lerp(bookSong.y, (bookGroup.y + 35 - scroll + (90*i)), elapsed*12);
				bookSong.clipRect = CoolUtil.calcRectByGlobal(bookSong, this.scrollRect);
			}
	
			scroll = FlxMath.bound(scroll, 0, (bookSongs.length-4)*90);
		}

		super.update(elapsed);
	}

	function makeBookText(){
		for(i=>metadata in metadatas){
			var songName:String = metadata.displayName;
			var songFile:String = metadata.internalName;
			var hasHell:Bool = metadata.hasHellDiff;
			var unlockMethod:String = metadata.unlockMethod;
			var unlockPrice:Int = metadata.cost;

			var song = new BookSong(songName, songFile, hasHell, unlockMethod, unlockPrice);
			song.setPosition(86, 35 + (i*90));
			bookGroup.add(song);
			bookSongs.push(song);

			song.makeSongText();
			
			var rect = FlxRect.get(277, 0, 900, 555);
            song.clipRect = CoolUtil.calcRectByGlobal(song, rect);
			rect.put();
		}
	}

	function makeDifficultyText(){
        difficultiesAvailable = [];
        difficultyLerpPosition = [];

        if (leftSelector != null) {
            if (bgHorizontalGroup.members.contains(leftSelector)) bgHorizontalGroup.remove(leftSelector, true);
            leftSelector.destroy();
            leftSelector = null;
        }
        if (rightSelector != null) {
            if (bgHorizontalGroup.members.contains(rightSelector)) bgHorizontalGroup.remove(rightSelector, true);
            rightSelector.destroy();
            rightSelector = null;
        }
        if (availableOptions != null) {
            availableOptions.forEachAlive(function(spr) {
                availableOptions.remove(spr, true);
                spr.destroy();
            });
            if (bgHorizontalGroup.members.contains(availableOptions)) bgHorizontalGroup.remove(availableOptions, true);
            availableOptions.destroy();
            availableOptions = null;
        }

        for(file in FileSystem.readDirectory(Paths.getPreloadPath("data/" + metadatas[curSelection].internalName + "/"))){
            if(FileSystem.isDirectory(file)) continue;
            if(!file.contains(metadatas[curSelection].internalName)) continue;

            var diffName = file.replace(metadatas[curSelection].internalName + "-", "").replace(".json", "");
            if(diffName == metadatas[curSelection].internalName) diffName = "Normal";

            difficultiesAvailable.push(CoolUtil.defaultDifficulties.indexOf(CoolUtil.capitalize(diffName)));
            difficultiesAvailable.sort(function(a,b){
                return a - b;
            });
        }

        leftSelector = new StoryModeSpriteHoverable(461, 47, "freeplay/new/ArrowLeft");
        bgHorizontalGroup.add(leftSelector);

        rightSelector = new StoryModeSpriteHoverable(782, 47, "freeplay/new/ArrowRight");
        bgHorizontalGroup.add(rightSelector);

        availableOptions = new FlxSpriteGroup(495, 32);

        var rect = FlxRect.get(0, 0, 290, 90);
        for(i=>diff in difficultiesAvailable){
            var diffText = new FlxText(((i - curDifficulty) * 300), 0, 290, CoolUtil.getDisplayDiffString(diff), 64, 0, 0xFFFEDEBF);
            diffText.antialiasing = ClientPrefs.globalAntialiasing;
            diffText.setFormat(FONT, 64, 0xFFFEDEBF, CENTER);
            difficultyLerpPosition.push(diffText.x);
            diffText.clipRect = CoolUtil.calcRectByGlobal(diffText, rect);
            availableOptions.add(diffText);
        }
        rect.put();

        bgHorizontalGroup.add(availableOptions);
    }

    function makeDifficultyBars(){
        if (difficultyBars != null) {
            difficultyBars.forEachAlive(function(spr) {
                difficultyBars.remove(spr, true);
                spr.destroy();
            });
            if (bgVerticalGroup.members.contains(difficultyBars)) bgVerticalGroup.remove(difficultyBars, true);
            difficultyBars.destroy();
            difficultyBars = null;
        }

        difficultyBars = new FlxTypedSpriteGroup<DifficultyBar>(0, 0);
        bgVerticalGroup.add(difficultyBars);

        difficultyBars.add(new DifficultyBar(13, 270, metadatas[curSelection], "DIFF"));
        difficultyBars.add(new DifficultyBar(13, 465, metadatas[curSelection], "MDIFF"));

        if (songLengthText != null && bgVerticalGroup.members.contains(songLengthText)) {
            bgVerticalGroup.remove(songLengthText, true);
            songLengthText.destroy();
            songLengthText = null;
        }
        songLengthText = new FlxText(13, 35, 218, Lang.getText("length", "states/newFreeplay"), 36, 0, 0xFFFEDEBF);
        songLengthText.antialiasing = ClientPrefs.globalAntialiasing;
        songLengthText.setFormat(FONT, 36, 0xFFFEDEBF, LEFT);
        bgVerticalGroup.add(songLengthText);

        if (actualSongLengthText != null && bgVerticalGroup.members.contains(actualSongLengthText)) {
            bgVerticalGroup.remove(actualSongLengthText, true);
            actualSongLengthText.destroy();
            actualSongLengthText = null;
        }
        actualSongLengthText = new FlxText(13, 78, 218, "Test", 48, 0, 0xFFFEDEBF);
        actualSongLengthText.antialiasing = ClientPrefs.globalAntialiasing;
        actualSongLengthText.setFormat(FONT, 48, 0xFFFEDEBF, CENTER);
        bgVerticalGroup.add(actualSongLengthText);
    }

	function changeSelection(change:Int){
		curSelection += change;

		if(curSelection >= bookSongs.length) { curSelection = bookSongs.length-1; }
		else if(curSelection < 0)  {curSelection = 0; }

		for(bookSong in bookSongs){
			bookSong.stopSelected();
		}
		bookSongs[curSelection].switchToSelected();
		
		scroll += 90 * change;
		makeDifficultyBars();
		makeDifficultyText();

		var tempDiff = [];
		for(diff in CoolUtil.defaultDifficulties){
			if(difficultiesAvailable.contains(CoolUtil.defaultDifficulties.indexOf(diff))) tempDiff.push(diff);
		}
		CoolUtil.difficulties = tempDiff.copy();
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		
		changeDifficulty(0);
	}

	var clearStar:Star;
	function changeDifficulty(change:Int){
		curDifficulty += change;

		if(curDifficulty >= difficultiesAvailable.length) { curDifficulty = 0; }
		else if(curDifficulty < 0)  {curDifficulty = difficultiesAvailable.length - 1; }

		for(i=>diff in difficultiesAvailable){
			difficultyLerpPosition[i] = (i - curDifficulty) * 300;
		}
		difficultyBars.forEach(function(dBar){
			dBar.isUnlocked = bookSongs[curSelection].isUnlocked;
			dBar.selectedDifficulty = curDifficulty;
		});
		actualSongLengthText.text = Std.string(switch(curDifficulty) {
			case 3: FlxStringUtil.formatTime(metadatas[curSelection].songLengths.hell);
			default: FlxStringUtil.formatTime(metadatas[curSelection].songLengths.normal);
		});
		if(!bookSongs[curSelection].isUnlocked){
			actualSongLengthText.text = "??:??";
		}

		if(ostArt == null || !bookGroup.members.contains(ostArt))
			ostArt = new FlxSprite(0,0);
		ostArt.loadGraphic(Paths.image("ostArt/" + metadatas[curSelection].ostArtPath));
		if(curDifficulty == 3 && Paths.fileExists("ostArt/"+metadatas[curSelection].ostArtPath+"-hell", IMAGE, false, "preload")){
			ostArt.loadGraphic(Paths.image("ostArt/" + metadatas[curSelection].ostArtPath+"-hell"));
		}
		ostArt.setGraphicSize(330, 330);
		ostArt.updateHitbox();
		ostArt.setPosition(627, 88);
		ostArt.antialiasing = ClientPrefs.globalAntialiasing;
		bookGroup.add(ostArt);

		if(clearStar != null) bgHorizontalGroup.remove(clearStar);
		clearStar = new Star(metadatas[curSelection], curDifficulty == 3);
		clearStar.setPosition(147, 9);
		bgHorizontalGroup.add(clearStar);
	}

	
	function chooseSong(){
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = CoolUtil.defaultDifficulties.indexOf(CoolUtil.difficulties[curDifficulty]);
		//PlayState.storyDifficulty = curDifficulty;
		
		var songLowercase:String = metadatas[curSelection].internalName.toLowerCase();
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
		if(NewFreeplayState.currentCategory == "freeplay") { // Force normal difficulty on this
			poop = Highscore.formatSong(songLowercase, 1);
		}

		#if debug
		trace(curSelection);
		trace(metadatas[curSelection]);
		trace(poop);
		#end
		
		PlayState.SONG = Song.loadFromJson(poop, songLowercase);
		
		if (FlxG.keys.pressed.SHIFT)
			LoadingState.loadAndSwitchState(new editors.ChartingState());
		else
			LoadingState.loadAndSwitchState(new PlayState());
				
		return true;
	}
}

class DifficultyBar extends FlxSpriteGroup {
	public var curDifficulty:Int = 0;
	var _lerpedDifficulty:Float = 0;

	var _metadata:SongMetadata;
	var _target:String = "DIFF";

	public var isUnlocked:Bool = true;
	public var isGlitch:Bool = false;

	public var selectedDifficulty(default, set):Int = 0;
	function set_selectedDifficulty(v:Int){
		if(_target == "MDIFF")
			curDifficulty = switch(v) {
				case 0: _metadata.mechanicDifficulties.easy;
				case 1: _metadata.mechanicDifficulties.normal;
				case 2: _metadata.mechanicDifficulties.hard;
				case 3: _metadata.mechanicDifficulties.hell;
				default: _metadata.mechanicDifficulties.normal;
			}
		else 
			curDifficulty = switch(v) {
				case 0: _metadata.difficulties.easy;
				case 1: _metadata.difficulties.normal;
				case 2: _metadata.difficulties.hard;
				case 3: _metadata.difficulties.hell;
				default: _metadata.difficulties.normal;
			}
		
		number.text = Std.string(curDifficulty);
		if (!isUnlocked) {
			curDifficulty = 0;
			number.text = "???";
		} else if (curDifficulty == -2){
			number.text = "TBD";
		} else if (curDifficulty == -1){
			number.text = "N/A";
		}
		
		selectedDifficulty = v;
		return v;
	}

	var actualBar:FlxAnimate;
	var label:FlxText;
	var number:FlxText;

	// Target can only be "DIFF" or "MDIFF" for Difficulty and Mechanic Difficulty
	public function new(x:Float, y:Float, songMetadata:SongMetadata, target:String){
		super(x, y);

		_metadata = songMetadata;
		_target = target;

		actualBar = new FlxAnimate(10, 20);
		Paths.loadAnimateAtlas(actualBar, "freeplay/new/difficulty-bar");
		actualBar.anim.addBySymbol("idle", "note bar", 24, false);
		actualBar.anim.play("idle", true, false, 0);
		actualBar.anim.pause();
		actualBar.setGraphicSize(200, 50);
		actualBar.updateHitbox();
		actualBar.antialiasing = ClientPrefs.globalAntialiasing;
		add(actualBar);

		label = new FlxText(0, -100, 0, switch(_target){
			case "DIFF": Lang.getText("diff", "states/newFreeplay");
			case "MDIFF": Lang.getText("mdiff", "states/newFreeplay");
			default: Lang.getText("diff", "states/newFreeplay");
		}, 36, 0, 0xFFFEDEBF);
		label.antialiasing = ClientPrefs.globalAntialiasing;
		label.setFormat(FONT, 36, 0xFFFEDEBF, CENTER);
		add(label);

		number = new FlxText(0, -50, 200, Std.string(curDifficulty), 48, 0, 0xFFFEDEBF);
		number.antialiasing = ClientPrefs.globalAntialiasing;
		number.setFormat(FONT, 48, 0xFFFEDEBF, CENTER);
		add(number);
	}

	override function update(elapsed:Float){
		_lerpedDifficulty = FlxMath.lerp(_lerpedDifficulty, curDifficulty, CoolUtil.boundTo(elapsed * 4, 0, 1));
		actualBar.anim.curFrame = Math.round(_lerpedDifficulty);

		super.update(elapsed);
	}
}

class BookSong extends FlxSpriteGroup {
	var songName:String;
	var songFile:String;
	var hasHell:Bool;
	var unlockMethod:String;
	var unlockPrice:Int;

	public var isSelected:Bool = false;
	public var isUnlocked:Bool = true;

	var songText:FlxText;
	var selector:FlxSprite;
	var hellIndicator:FlxSpriteGroup;

	public function new(songName:String, songFile:String, hasHell:Bool, unlockMethod:String, unlockPrice:Int){
		this.songName = songName;
		this.songFile = songFile;
		this.hasHell = hasHell;
		this.unlockMethod = unlockMethod;
		this.unlockPrice = unlockPrice;

		super(0,0);
		makeSongText();
		makeSelector();
		if(hasHell) makeHellIndicator();

		if(isSelected) switchToSelected();
		else stopSelected();


		forEach(function(spr){
			try{ spr.antialiasing = ClientPrefs.globalAntialiasing; }
			catch(e){
				try { (cast spr:FlxSpriteGroup).forEach(function(sprr){
					try{ sprr.antialiasing = ClientPrefs.globalAntialiasing;}
					catch(eee) {}
				});}
				catch(ee) {}
			};
		});
	}

	public function tryEnterSong(){
		if(!isSelected || !isUnlocked) return {success: false, songName: "none", songFile: "none"};
		return {
			success: true,
			songName: songName,
			songFile: songFile
		};
	}

	public function tryUnlockSong(?force:Bool = false){
		if(!isSelected || isUnlocked) return {success: false, songName: "none", songFile: "none"};
		if(DoorsUtil.knobs > unlockPrice || force) {
			if(!force) DoorsUtil.addKnobs(-unlockPrice, 1.0);

			Reflect.setProperty(FlxG.save.data, songFile + "-unlocked", true);
			FlxG.save.flush();
		
			return {
				success: true,
				songName: songName,
				songFile: songFile
			}
		} else {
			return {success: false, songName: "none", songFile: "none"};
		}
	}

	public function makeSongText(){
        if (songText != null && members.contains(songText)) {
            remove(songText, true);
            songText.destroy();
            songText = null;
        }
        songText = new FlxText(0,0,0,songName,8,0,0xFF452D25);
        songText.setFormat(MEDIUM_FONT, 36, 0xFF452D25, LEFT);
        if(!isUnlocked){
            songText.text = "???";
        }
        add(songText);
    }

    function makeSelector(){
        if (selector != null && members.contains(selector)) {
            remove(selector, true);
            selector.destroy();
            selector = null;
        }
        selector = new FlxSprite(-30,4).loadGraphic(Paths.image("freeplay/new/selector"));
        selector.alpha = 1;
        add(selector);
    }

    function makeHellIndicator(){
        if (hellIndicator != null && members.contains(hellIndicator)) {
            remove(hellIndicator, true);
            hellIndicator.forEachAlive(function(spr) {
                hellIndicator.remove(spr, true);
                spr.destroy();
            });
            hellIndicator.destroy();
            hellIndicator = null;
        }
        hellIndicator = new FlxSpriteGroup(300,-36);

        var hellFlame = new FlxSprite(-30,-30);
        hellFlame.frames = Paths.getSparrowAtlas("freeplay/new/fire");
        hellFlame.animation.addByPrefix("idle", "fire", 12, true);
        hellFlame.animation.play("idle");
        hellFlame.scale.set(0.398, 0.398);
        hellFlame.updateHitbox();
        hellFlame.antialiasing = ClientPrefs.globalAntialiasing;

        var hellText = new FlxText(17,46,0,Lang.getText("hell", "generalshit"),8,0,0xFFf6611c);
        hellText.setFormat(MEDIUM_FONT, 24, 0xFFf6611c, CENTER, OUTLINE, 0xFF452D25);

        hellIndicator.add(hellFlame);
        hellIndicator.add(hellText);

        add(hellIndicator);
    }

	public function switchToSelected(){
		isSelected = true;
		songText.setFormat(MEDIUM_FONT, 36, 0xFFFEDEBF, LEFT, OUTLINE, 0xFF452D25);
		songText.borderSize = 2;
		selector.alpha = 1;
	}

	public function stopSelected(){
		isSelected = false;
		songText.setFormat(MEDIUM_FONT, 36, 0xFF452D25, LEFT, NONE, 0xFF000000);
		songText.borderSize = 1;
		selector.alpha = 0;
	}
}

@:forward
enum abstract StarType(Int) from Int to Int {
	var NONE = 0;
	var CLEAR = 1;
	var FC = 2;
	var PFC = 3;
}
class Star extends FlxSprite {
	var starType:StarType;
	var attachedMetadata:SongMetadata;
	var isHell:Bool;

	public function new(metadata:SongMetadata, isHell:Bool){
		this.attachedMetadata = metadata;
		this.isHell = isHell;

		starType = getStarType();

		super(0, 0);
		this.loadGraphic(Paths.image("freeplay/stars/" + switch(starType) {
			case NONE: "none";
			case CLEAR: "clear";
			case FC:
				switch(attachedMetadata.deathMetadata.deathSpeaker){
					case "CURIOUS": "FC_curious";
					case "MISCHEVIOUS": "FC_mischevious";
					default: "FC_guiding";
				}
			case PFC:
				switch(attachedMetadata.deathMetadata.deathSpeaker){
					case "CURIOUS": "PFC_curious";
					case "MISCHEVIOUS": "PFC_mischevious";
					default: "PFC_guiding";
				}
		}));
		this.antialiasing = ClientPrefs.globalAntialiasing;
	}

	function getStarType():StarType {
		var highestStarType:StarType = NONE;
		for(i in 0...CoolUtil.defaultDifficulties.length) {
			if(isHell && i != CoolUtil.defaultDifficulties.indexOf("Hell")) continue;
			else if(!isHell && i == CoolUtil.defaultDifficulties.indexOf("Hell")) continue;

			if(Highscore.getRating(attachedMetadata.internalName, i) == 1) {
				highestStarType = Std.int(Math.max(highestStarType, StarType.PFC));
			}
			if(Highscore.getMisses(attachedMetadata.internalName + (isHell ? "-hell" : "")) == 0) {
				highestStarType = Std.int(Math.max(highestStarType, StarType.FC));
			}
			if(Highscore.getMisses(attachedMetadata.internalName + (isHell ? "-hell" : "")) >= 0 || Highscore.getRating(attachedMetadata.internalName, i) != 0) {
				highestStarType = Std.int(Math.max(highestStarType, StarType.CLEAR));
			}
		}
		return highestStarType;
	}
}
