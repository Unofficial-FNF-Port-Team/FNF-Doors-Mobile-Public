package;

import flixel.FlxObject;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.Lib;
import openfl.display.FPS;
import flixel.FlxG;
import lime.app.Application;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.math.FlxMath;
import AwardsManager;

enum abstract PopUpSize(String) {
    var SMALL = "SMALL";
    var BIG = "BIG";
}

class PopUp extends Sprite
{
    var timeElapsed:Float = 0;
    var time:Float = 0;
    public var alive:Bool = true;
    public var shouldKill:Bool = false;

    public var popupY:Float = 0;
    public var popupHeight:Int = 82;
    public var popupWidth:Int = 402;

    var bg:Bitmap;

    function getScreenHeight()
    {
        return Lib.application.window.height;
    }

    function getScreenWidth()
    {
        return Lib.application.window.width;
    }

    public function new(time:Float, size:PopUpSize)
    {
        super();
        this.time = time;
        popupWidth = 402;
        switch(size){
            case SMALL:
                popupHeight = 62;
            case BIG:
                popupHeight = 82;
        }
        popupY = getScreenHeight() + popupHeight;
        

        var spriteImage:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.image('notifications/bg${size}'));
        spriteImage.scale.set(getScreenWidth()/1280, getScreenHeight()/720);
        spriteImage.updateHitbox();
        bg = new Bitmap(spriteImage.updateFramePixels()); //easy flixel to openfl shit
        addChild(bg);
        bg.smoothing = true;
        bg.scaleX = spriteImage.scale.x;
        bg.scaleY = spriteImage.scale.y;
        popupHeight = Math.round(popupHeight * bg.scaleY);
        popupWidth = Math.round(popupWidth * bg.scaleY);
        bg.y = getScreenHeight() - 8;
        bg.x = getScreenWidth()-popupWidth -550;
    }

	public function update(deltaTime:Float)
	{
        timeElapsed += deltaTime;
        bg.y = popupY;
        if (timeElapsed >= time)
            alive = false;

        shouldKill = (timeElapsed >= time+1);
    }
}

class MessagePopup extends PopUp
{
    var bigText:TextField;
    var descText:TextField;
    override public function new(time:Float, bigM:String = "", smallM:String = "")
    {
        super(time, SMALL);
        bigText = new TextField();
        bigText.text = bigM;
        bigText.defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont(MEDIUM_FONT).fontName,
        Math.round(18 * (getScreenWidth()/1280)), 0xFFFEDEBF, null, null, null, null, null, LEFT);
        addChild(bigText);
        bigText.width = popupWidth-10;
        bigText.height = popupHeight-(10 * (getScreenHeight()/1280));
        bigText.selectable = false;
        bigText.wordWrap = true;

        bigText.x = getScreenWidth()-popupWidth -530;
        bigText.y = popupY+8;
        
        descText = new TextField();
        descText.text = smallM;
        descText.defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont(FONT).fontName,
        Math.round(12 * (getScreenWidth()/1280)), 0xFFFEDEBF, null, null, null, null, null, LEFT);
        addChild(descText);
        descText.width = popupWidth-10;
        descText.height = popupHeight-(10 * (getScreenHeight()/1280));
        descText.selectable = false;
        descText.wordWrap = true;

        descText.x = getScreenWidth()-popupWidth -530;
        descText.y = popupY+36;
    }
    override public function update(deltaTime:Float)
    {
        super.update(deltaTime);
        bigText.y = popupY+(4* (getScreenWidth()/1280));
        descText.y = popupY+(30* (getScreenWidth()/1280));
    }
}
class ClickableMessagePopup extends PopUp
{
    var bigText:TextField;
    var descText:TextField;
    var clickFunc:Void->Void = null;
    var hitbox:FlxObject;
    override public function new(time:Float, bigM:String = "", smallM:String = "", clickFunc:Void->Void)
    {
        super(time, SMALL);
        this.clickFunc = clickFunc;
        bigText = new TextField();
        bigText.text = bigM;
        bigText.defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont(MEDIUM_FONT).fontName,
        Math.round(18 * (getScreenWidth()/1280)), 0xFFFEDEBF, null, null, null, null, null, LEFT);
        addChild(bigText);
        bigText.width = popupWidth-10;
        bigText.height = popupHeight-(10 * (getScreenHeight()/1280));
        bigText.selectable = false;
        bigText.wordWrap = true;

        bigText.x = getScreenWidth()-popupWidth+11;
        bigText.y = popupY+8;
        
        descText = new TextField();
        descText.text = smallM;
        descText.defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont(FONT).fontName,
        Math.round(12 * (getScreenWidth()/1280)), 0xFFFEDEBF, null, null, null, null, null, LEFT);
        addChild(descText);
        descText.width = popupWidth-10;
        descText.height = popupHeight-(10 * (getScreenHeight()/1280));
        descText.selectable = false;
        descText.wordWrap = true;

        descText.x = getScreenWidth()-popupWidth+11;
        descText.y = popupY+36;

        hitbox = new FlxObject(0,0,popupWidth,popupHeight);
    }
    override public function update(deltaTime:Float)
    {
        super.update(deltaTime);
        bigText.y = popupY+(4* (getScreenWidth()/1280));
        descText.y = popupY+(30* (getScreenWidth()/1280));
        hitbox.x = bg.x;
        hitbox.y = bg.y;
       
        if (alive && FlxG.mouse.justPressed && hitbox.overlapsPoint(FlxG.mouse.getScreenPosition()))
        {
            alive = false;
            if (clickFunc != null)
                clickFunc();
        }
    }
}
class AwardPopup extends PopUp
{
    var bigText:TextField;
    var smallText:TextField;
    var image:Bitmap;
    override public function new(time:Float, award:Award)
    {
        if (award == null)
        {
            award = {name: "Null Award lol", description: "", achievementID: "", imageName: "", hidden: true, knobAward: 0};
        }
        super(time, BIG);
        bigText = new TextField();
        bigText.text = award.name;
        bigText.defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont(MEDIUM_FONT).fontName,
        Math.round(18 * (getScreenWidth()/1280)), 0xFFFEDEBF, null, null, null, null, null, LEFT);
        addChild(bigText);
        bigText.width = popupWidth-80;
        bigText.height = (80 * (getScreenHeight()/1280));
        bigText.selectable = false;
        bigText.wordWrap = false;

        smallText = new TextField();
        smallText.text = award.description;
        smallText.defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont(FONT).fontName,
        Math.round(12 * (getScreenWidth()/1280)), 0xFFFEDEBF, null, null, null, null, null, LEFT);
        addChild(smallText);
        smallText.width = popupWidth-150;
        smallText.height = (36 * (getScreenHeight()/1280));
        smallText.selectable = false;
        smallText.wordWrap = true;

        var spriteImage:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.image('awards/${AwardsManager.getAwardImageName(award)}'));
        spriteImage.setGraphicSize(Math.round(60 * (getScreenWidth()/1280)), Math.round(61 * (getScreenWidth()/1280)));
        spriteImage.updateHitbox();
        image = new Bitmap(spriteImage.updateFramePixels()); //easy flixel to openfl shit
        addChild(image);
        image.smoothing = true;
        image.scaleX = spriteImage.scale.x;
        image.scaleY = spriteImage.scale.y;

        bigText.x = getScreenWidth()-popupWidth-530;
        smallText.x = getScreenWidth()-popupWidth-530;
        image.x = getScreenWidth()-(268 * bg.scaleX);
    }
    override public function update(deltaTime:Float)
    {
        super.update(deltaTime);
        bigText.y = popupY+(4* (getScreenWidth()/1280));
        smallText.y = popupY+(30* (getScreenWidth()/1280));
        image.y = popupY+(4* (getScreenWidth()/1280));
    }
}

class PopupManager extends Sprite
{
    function getScreenHeight()
    {
        return Lib.application.window.height;
    }

    function getScreenWidth()
    {
        return Lib.application.window.width;
    }
    var popups:Array<PopUp> = [];
    @:noCompletion private var currentTime:Float;
    public function new()
    {
        super();
        currentTime = 0;
        FlxG.signals.postUpdate.add(function()
        {
            update(FlxG.elapsed);
        });
        FlxG.signals.postStateSwitch.add(function()
        {
            for (p in popups)
            {
                FlxG.addChildBelowMouse(p); //fix for switching state
            }
        });
    }
	function update(elapsed:Float):Void
	{
        if (popups.length > 0)
        {
            var currentPopupHeight:Float = getScreenHeight();
            for (p in 0...popups.length)
            {
                var popup:PopUp = popups[p];
                var popupPos:Float = getScreenHeight(); //default to offscreen
                if (popup.alive)
                {
                    currentPopupHeight += -popup.popupHeight;
                    popupPos = currentPopupHeight; //target y position
                }
                popup.popupY = FlxMath.lerp(popup.popupY, popupPos, elapsed*6); //get y pos

                popup.update(elapsed);
            }

            for (popup in popups)
            {
                if (popup.shouldKill)
                {
                    removeChild(popup);
                    FlxG.removeChild(popup);
                    popups.remove(popup);
                }
            }
        }
    }

    public function addPopup(p:PopUp)
    {
        FlxG.addChildBelowMouse(p);
        popups.push(p);
    }

}