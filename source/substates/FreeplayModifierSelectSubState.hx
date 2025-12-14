package substates;

import flixel.math.FlxRect;
import objects.ui.*;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;

class FreeplayModifierSelectSubState extends MusicBeatSubstate
{
    var tempSelectedModifiers:Array<Modifier> = [];
    var tempKnobModifier:Float = 1.0;

    var song:String;
    var menu:DoorsMenu;
    var cancelButton:DoorsButton;
    var applyButton:DoorsButton;

    var filters:DoorsFilters;

    var descSmallText:FlxText;
    var descBigText:FlxText;

    var theModifiers:Array<DoorsModifier> = [];
    var visibleModifiers:Array<DoorsModifier> = [];
    var allModifierCategories:Array<Dynamic> = [];

    var curSelected:Int = 0;

    var targetY:Array<Float> = [];
    var lerpSpeed:Float = 0.15; // Adjust this value to control scrolling speed

    private var chooseSongCallback:Null<Void->Void>;

    public function new(songFile:String, ?isHell = false, ?chooseSongCallback:Void->Void)
    {
        song = songFile;
        this.chooseSongCallback = chooseSongCallback;
        super();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        menu = new DoorsMenu(150, 40, "modifiers", Lang.getText("chooseMods", "newUI"), false);
        add(menu);

        theModifiers = [];
        for(m in ModifierManager.defaultModifiers)
        {
            var blacklistShit:Bool = m.blacklistedSongs == null ? true : !m.blacklistedSongs.contains(song.toLowerCase());
            
            var hellSpecificShit = true;
            hellSpecificShit = m.hellSpecific == null ? true : !isHell;

            if(m.allowedSongs == null ? (hellSpecificShit && blacklistShit && m.showsUpEverywhere) : (isHell&&!hellSpecificShit ? m.allowedSongs.contains(song.toLowerCase() + "-hell"):m.allowedSongs.contains(song.toLowerCase())))
            {
                for(category in m.categories) {
                    if(!allModifierCategories.contains({cat: category}))
                        allModifierCategories.push({cat: category});
                }
                var modObj = new DoorsModifier(20, 265, m, DEFAULT);
                theModifiers.push(modObj);
                targetY.push(265);
                //check for unlocks once.
                var isLocked = false;
    
                switch(m.unlockCondition){
                    case FINISHGAME: if(!AwardsManager.isUnlocked(AwardsManager.getAwardFromID("youWin"))) isLocked = true;
                    case FINISHGAME_HARD: if(!AwardsManager.isUnlocked(AwardsManager.getAwardFromID("youWinHard"))) isLocked = true;
                    case WORST_HOTEL_EVER: if(!AwardsManager.isUnlocked(AwardsManager.getAwardFromID("hotelHell"))) isLocked = true;
                    case SEEK_MASTERY: if(!AwardsManager.isUnlocked(AwardsManager.getAwardFromID("neverTripped"))) isLocked = true;
                    case FIGURE_MASTERY: if(!AwardsManager.isUnlocked(AwardsManager.getAwardFromID("cardiacArrest"))) isLocked = true;
                    case HALT_MASTERY: if(!AwardsManager.isUnlocked(AwardsManager.getAwardFromID("onTheEdge"))) isLocked = true;
                    case NONE: continue;
                }

                #if debug 
                    //if(isLocked) theModifiers[theModifiers.length-1].modType = LOCKED;
                #else
                    if(isLocked) theModifiers[theModifiers.length-1].modType = LOCKED;
                #end
            }
        }

        for(i in 0...theModifiers.length){
            theModifiers[i].makeDisplay();
            menu.add(theModifiers[i]);
            theModifiers[i].y = 265 + (60*i);
            targetY[i] = theModifiers[i].y;
            theModifiers[i].clipRect = CoolUtil.calcRectByGlobal(theModifiers[i], FlxRect.get(170, 265, 640, 319));
        }

        cancelButton = new DoorsButton(24, 556, Lang.getText("cancel", "newUI"), MEDIUM, NORMAL);
        menu.add(cancelButton);

        applyButton = new DoorsButton(192, 553, Lang.getText("play", "newUI"), MEDIUM, CUSTOM);
        applyButton.makeButton = function(btnTxt:String){
            makeApplyButton(applyButton);
        }
        applyButton.makeButton("");
        menu.add(applyButton);

        descSmallText = new FlxText(19, 87, 641, "", 20);
        descSmallText.setFormat(FONT, 20, 0xFFFEDEBF, CENTER);
        descSmallText.antialiasing = ClientPrefs.globalAntialiasing;
        menu.add(descSmallText);

        descBigText = new FlxText(21, 115, 637, "", 32, 98);
        descBigText.setFormat(FONT, 32, 0xFFFEDEBF, CENTER);
        descBigText.antialiasing = ClientPrefs.globalAntialiasing;
        descBigText.autoSize = true;
        menu.add(descBigText);

        filters = new DoorsFilters(691, 20, allModifierCategories, "cat", "modifiers/categories", function(){
            changeSelection(0, false);
            while(curSelected > 0) {
                changeSelection(-1, false);
            }
        });
        menu.add(filters);

		#if mobile
		addVirtualPad(UP_DOWN, NONE);
		addVirtualPadCamera();
		#end

        startGaming();
        changeSelection(0, false);
        changeSelection(-1, false);
    }

    override function update(elapsed:Float){
        super.update(elapsed);
		var upScroll = FlxG.mouse.wheel > 0;
		var downScroll = FlxG.mouse.wheel < 0;

        if (controls.UI_UP_P)           changeSelection(-1);
        if (upScroll)                   changeSelection(-1);
        if (controls.UI_DOWN_P)         changeSelection(1);
        if (downScroll)                 changeSelection(1);
        if (controls.BACK)              closeState();

        // Apply lerping to modifier positions
        for (i in 0...theModifiers.length) {
            theModifiers[i].y = FlxMath.lerp(theModifiers[i].y, targetY[i], lerpSpeed);
            if (Math.abs(theModifiers[i].y - targetY[i]) < 0.5) {
                theModifiers[i].y = targetY[i];
            }
            theModifiers[i].clipRect = CoolUtil.calcRectByGlobal(theModifiers[i], FlxRect.get(0, 265, 99999, 319));
        }

        var mustClearDesc = true;
        for(i=>m in theModifiers){
            if(m.isHovered && 
                FlxRect.get(170, 265, 640, 319).intersection(theModifiers[i].getRotatedBounds()) != FlxRect.get() && 
                m.modType != RESERVED && 
                m.modType != LOCKED
            ){
                changeDescription(m.boundMod.name, m.boundMod.desc);
                mustClearDesc = false;
                break;
            } 
        }
        if(mustClearDesc) changeDescription("","");

        if(FlxG.mouse.justPressed){
            if(cancelButton.isHovered){
                ModifierManager.freeplayChosenModifiers = [];
                closeState();
            } else if(applyButton.isHovered){
                ModifierManager.freeplayChosenModifiers = tempSelectedModifiers;
                DoorsUtil.recalculateScoreModifier();
                closeState();
                if(chooseSongCallback != null) chooseSongCallback();
                else {
                    @:privateAccess{
                        var songLowercase:String = NewFreeplaySelectSubState.instance.metadatas[NewFreeplaySelectSubState.instance.curSelection].internalName;
                        var poop:String = Highscore.formatSong(songLowercase, NewFreeplaySelectSubState.instance.curDifficulty);

                        PlayState.SONG = Song.loadFromJson(poop, songLowercase);
                        PlayState.isStoryMode = false;
                        PlayState.storyDifficulty = NewFreeplaySelectSubState.instance.curDifficulty;
                        PlayState.storyPlaylist = [];
                        LoadingState.loadAndSwitchState(new PlayState());	
                    }
                }
            } else {
                //assume that a modifier is hit.
                tempSelectedModifiers = [];
                tempKnobModifier = 1.0;
                //handle selecting mods
                for(m in theModifiers){
                    if(m.modType == SELECTED){
                        tempSelectedModifiers.push(m.boundMod);
                        tempKnobModifier += (m.boundMod.knobAddition-1);
                    }
                }

                for(m in theModifiers){
                    if(m.modType == SELECTED){
                        tempKnobModifier *= m.boundMod.knobMultiplier;
                    }
                }

                for(m in theModifiers){
                    if(m.modType == RESERVED){
                        m.modType = DEFAULT;
                        m.makeDisplay();
                    } 

                    for(n in tempSelectedModifiers){
                        if(n.blocksModifiers.contains(m.boundMod.ID) && m.modType != LOCKED){
                            m.conflictedBy = n;
                            m.modType = RESERVED;
                            m.makeDisplay();
                            break;
                        }
                    }
                }

                makeApplyButton(applyButton);
            }
        }
    }

    private function startGaming(){
        FlxTween.tween(menu, {x: menu.x}, 0.6, {ease:FlxEase.quadInOut});
        menu.x += 1280;
    }

    private function stopGaming(){
        FlxTween.tween(menu, {x: menu.x + 1280}, 0.6, {ease:FlxEase.quadInOut, onComplete:function(twn){
            close();
        }});
    }
    
    public function closeState(){
        stopGaming();
    }
    
	var needsStopTween = false;
	function changeSelection(change:Int = 0, playSound:Bool = true)
	{	
		curSelected += change;

		if (curSelected < 0){
			curSelected = 0;
			change = 0;
		}
		if (curSelected >= theModifiers.length-4){
			curSelected = theModifiers.length-5;
			change = 0;
		}

        visibleModifiers = [];
        for(i in 0...theModifiers.length){
            var mustPush:Bool = true;
            if(filters.filteredArray.length != filters.arrayToFilter.length){
                for(filter in filters.filteredArray){
                    if(!(theModifiers[i].boundMod.categories:Array<String>).contains(filter)){
                        mustPush = false;
                    }
                }
                if(mustPush) visibleModifiers.push(theModifiers[i]);
            } else {
                visibleModifiers.push(theModifiers[i]);
            }
        }
        
        var iOffset:Int = 0;
        for(i in 0...theModifiers.length){
            if(visibleModifiers.contains(theModifiers[i])){
                targetY[i] = 265 + (60*((i - iOffset) - curSelected));
            } else {
                iOffset += 1;
                targetY[i] = -500;
            }
            theModifiers[i].clipRect = CoolUtil.calcRectByGlobal(theModifiers[i], FlxRect.get(170, 265, 640, 319));
        }

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

    function changeDescription(smal:String, beeg:String){
        descSmallText.text = smal.toUpperCase();
        descBigText.text = beeg;
    }

    function makeApplyButton(button:DoorsButton){
        button.forEach(function(spr){
            remove(spr);
        });

        button.bg = cast new StoryModeSpriteHoverable(0,0,"","").loadGraphic(Paths.image('menus/modifiers/Apply'));
        button.buttonText = new FlxText(14, -3, button.bg.width, Lang.getText("play", "newUI"));
        button.buttonText.setFormat(FONT, 48, 0xFF5B3B2E);
        button.buttonText.y = button.bg.getMidpoint().y - button.buttonText.height/2;

        //make knob text ooga booga
        var knobIndicator:FlxText = new FlxText(372, 9, 0, "", 32);
        knobIndicator.setFormat(FONT, 32, 0xFFFEDEBF);
        knobIndicator.text = '${(tempKnobModifier>1 ? "+" : "")}${Math.round((tempKnobModifier-1) * 100)}%';
        if(tempKnobModifier <= 0){
            knobIndicator.text = "x00%";
        }
        
        button.add(button.bg);
        button.add(button.buttonText);
        button.add(knobIndicator);

        button.forEach(function(spr){
            spr.antialiasing = ClientPrefs.globalAntialiasing;
        });
    }
}
