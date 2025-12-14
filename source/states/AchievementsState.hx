package states;

import openfl.filters.ColorMatrixFilter;
import openfl.geom.Point;
import flixel.math.FlxRandom;
import AwardsManager;
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
import lime.utils.Assets;
import flixel.FlxSubState;
import flixel.FlxObject;

using flixel.util.FlxSpriteUtil;
using StringTools;

class Achievement extends FlxSpriteGroup
{
    public function new(award:Award)
    {
        super();
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image("menus/awards/unlocked"));
        bg.antialiasing = ClientPrefs.globalAntialiasing;

        var name:FlxText = new FlxText(16, 6, 839, award.name);
        name.setFormat(MEDIUM_FONT, 48, 0xFFFEDEBF, LEFT);
        name.antialiasing = ClientPrefs.globalAntialiasing;

        var desc:FlxText = new FlxText(16, 72, 752, award.description);
        desc.setFormat(FONT, 24, 0xFFFEDEBF, LEFT);
        desc.antialiasing = ClientPrefs.globalAntialiasing;

        var knobs:FlxText = new FlxText(745, 83, 68, "+" + award.knobAward);
        knobs.setFormat(FONT, 24, 0xFFFEDEBF, RIGHT);
        knobs.antialiasing = ClientPrefs.globalAntialiasing;

        var spriteImage:FlxSprite = new FlxSprite(861, 3).loadGraphic(Paths.image("awards/"+AwardsManager.getAwardImageName(award)));
        spriteImage.antialiasing = ClientPrefs.globalAntialiasing;

        add(bg);
        add(name);
        add(desc);
        add(knobs);
        add(spriteImage);

        if (!AwardsManager.isUnlocked(award))
        {
            var matrix:Array<Float> = [
                0.4, 0.4, 0.4, 0, 0,
                0.4, 0.4, 0.4, 0, 0,
                0.4, 0.4, 0.4, 0, 0,
                  0,   0,   0, 1, 0,
            ];

            bg.loadGraphic(Paths.image("menus/awards/locked"));
            name.alpha = 0.6;
            desc.alpha = 0.6;
            spriteImage.pixels.applyFilter(spriteImage.pixels, spriteImage.pixels.rect, new Point(), new ColorMatrixFilter(matrix));
            knobs.text = "+???";

            var lockedImage:FlxSprite = new FlxSprite(868, 11);
            lockedImage.loadGraphic(Paths.image("awards/locked"));
            lockedImage.antialiasing = ClientPrefs.globalAntialiasing;
            add(lockedImage);
        }
    }
}

class AchievementsState extends MusicBeatState
{
    var awardDisplays:Array<Achievement> = [];
    var camPos:FlxObject = new FlxObject(0, 0, 1, 1);
    var listHeight:Float = -400;

    var unlockedCount:Int = 0;

    var camGame:FlxCamera;
    var camHUD:FlxCamera;

    override public function create()
    {
        #if discord_rpc
        // Updating Discord Rich Presence
        DiscordClient.changePresence("In the Awards Menu", null, "gameicon");
        #end

		MenuSongManager.crossfade("freakyOptions", 1, 140, true);

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

        camPos.screenCenter();
		camGame.follow(camPos, LOCKON, 1);
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		var bg = new FlxBackdrop(Paths.image("menus/awards/bg"));
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);

        var bgGradient = CoolUtil.makeGradient(1280, 800 + AwardsManager.fullAwards.length * 160, [0x01000000, 0x66000000], 1, 90, true);
        bgGradient.y -= 200;
        bgGradient.antialiasing = ClientPrefs.globalAntialiasing;

        for (i in 0...AwardsManager.fullAwards.length)
        {
            var display:Achievement = new Achievement(AwardsManager.fullAwards[i]);
            display.screenCenter(X);
            display.y = 150 + (i*160);
            add(display);
            awardDisplays.push(display);
            listHeight += 160;
            if (AwardsManager.isUnlocked(AwardsManager.fullAwards[i]))
                unlockedCount++;
        }

        var pageTabsText = new FlxText(0, 23, 1280, Lang.getText("menu", "achievements"));
        pageTabsText.setFormat(MEDIUM_FONT, 64, 0xFFFEDEBF, CENTER);

        var pageTabBG = new FlxSprite(240, 27).loadGraphic(Paths.image("menus/awards/achievementsBG"));
		add(pageTabBG);
        add(pageTabsText);
        pageTabsText.antialiasing = ClientPrefs.globalAntialiasing;
        pageTabBG.antialiasing = ClientPrefs.globalAntialiasing;
        pageTabsText.cameras = [camHUD];
        pageTabBG.cameras = [camHUD];

        
        /*var perc:Float = unlockedCount/AwardsManager.fullAwards.length*100;
        perc = FlxMath.roundDecimal(perc, 2);

        var percentage = new FlxText(0, 0,0, perc+"% ("+unlockedCount+"/"+AwardsManager.fullAwards.length+")");
        percentage.x = 10;
        percentage.setFormat(FONT, 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        percentage.y = FlxG.height-percentage.height;
        percentage.scrollFactor.set();
        percentage.antialiasing = ClientPrefs.globalAntialiasing;
        add(percentage);*/

        var scrollBar:ScrollBar = new ScrollBar(1200, 34, this, "scroll", listHeight);
        scrollBar.cameras = [camHUD];
        add(scrollBar);
        
        add(bgGradient);

		#if mobile
		addVirtualPad(UP_DOWN, B);
		addVirtualPadCamera();
		#end

        super.create();
    }
    var goingBack:Bool = false;
    var scroll:Float = 0.0;
    var grabbed:Bool = false;
    var grabY:Float = 0;
    override function update(elapsed:Float)
    {       
        if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

        if (controls.BACK && !goingBack)
        {
            goingBack = true;
            MusicBeatState.switchState(new MainMenuState());
        }
        var mult:Float = 1.0;
        if (FlxG.keys.pressed.SHIFT)
            mult = 3.0;
        scroll -= FlxG.mouse.wheel*50*elapsed*480*mult;
        if (controls.UI_DOWN)
            scroll += 800*elapsed*mult;
        if (controls.UI_UP)
            scroll -= 800*elapsed*mult;
        camPos.y = FlxMath.lerp(camPos.y, scroll+(FlxG.height*0.5), elapsed*12); //lerp cam pos to scroll

        scroll = FlxMath.bound(scroll, 0, listHeight); //bound

        

        super.update(elapsed);
    }
}


/**
 * Simple scroll bar that tracks and updates a value
 */
class ScrollBar extends FlxTypedSpriteGroup<FlxSprite>
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
    private var grabY:Float = 0.0;
    public var limit:Float = 0.0;
    public function new(X:Float = 0, Y:Float = 0, ?parentRef:Dynamic, variable:String = "", limit:Float)
    {
        super(X,Y);
        scrollBG = new FlxSprite(0, 0).loadGraphic(Paths.image("emptyScroll"));
        scrollBar = new FlxSprite(3, 3).loadGraphic(Paths.image("scrollTick"));
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

        scrollBar.y = FlxMath.remapToRange(value, 0, limit, scrollBG.y + 3, (scrollBG.y+scrollBG.height)-scrollBar.height - 3); //set y from value

        if (scrollBar.overlapsPoint(FlxG.mouse.getPositionInCameraView(this.cameras[0]), true, this.cameras[0]) && FlxG.mouse.justPressed) //grab bar
        {
            grabbed = true;
            grabY = FlxG.mouse.screenY-scrollBar.y;
        }
            
        if (FlxG.mouse.released && grabbed) //ungrab bar
        {
            scrollBar.color = 0xFFFFFFFF;
            grabbed = false;
        }

        if (grabbed)
        {
            scrollBar.y = FlxG.mouse.screenY-grabY; //update bar position with mouse
            scrollBar.color = 0xFF828282;
            scrollBar.y = FlxMath.bound(scrollBar.y, scrollBG.y, (scrollBG.y+scrollBG.height)-scrollBar.height);
        }

        if (!grabbed && scrollBG.overlapsPoint(FlxG.mouse.getPositionInCameraView(this.cameras[0]), true, this.cameras[0]) && FlxG.mouse.justPressed) //when you click the black part
        {
            scrollBar.y = FlxG.mouse.screenY;
            scrollBar.y = FlxMath.bound(scrollBar.y, scrollBG.y, (scrollBG.y+scrollBG.height)-scrollBar.height);
        }
        
        value = FlxMath.remapToRange(scrollBar.y, scrollBG.y + 3, (scrollBG.y+scrollBG.height)-scrollBar.height - 3, 0, limit); //remap back after any changes to the bar

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
