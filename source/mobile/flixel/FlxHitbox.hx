package mobile.flixel;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.display.Shape;
import mobile.flixel.FlxButton;
import mobile.flixel.input.FlxMobileInputManager;
import mobile.flixel.input.FlxMobileInputID;
import haxe.ds.Map;

/**
 * A zone with 4 hint's (A hitbox).
 * It's really easy to customize the layout.
 *
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class FlxHitbox extends FlxMobileInputManager
{
	public var buttonLeft:FlxButton = new FlxButton(0, 0, [FlxMobileInputID.hitboxLEFT, FlxMobileInputID.noteLEFT]);
	public var buttonDown:FlxButton = new FlxButton(0, 0, [FlxMobileInputID.hitboxDOWN, FlxMobileInputID.noteDOWN]);
	public var buttonUp:FlxButton = new FlxButton(0, 0, [FlxMobileInputID.hitboxUP, FlxMobileInputID.noteUP]);
	public var buttonRight:FlxButton = new FlxButton(0, 0, [FlxMobileInputID.hitboxRIGHT, FlxMobileInputID.noteRIGHT]);
	public var buttonAction:FlxButton = new FlxButton(0, 0, [FlxMobileInputID.NONE]);
	public var buttonActionTwo:FlxButton = new FlxButton(0, 0, [FlxMobileInputID.NONE]);

	var AlphaThing:Float = 0.2;
	var storedButtonsIDs:Map<String, Array<FlxMobileInputID>> = new Map<String, Array<FlxMobileInputID>>();

	/**
	 * Create the zone.
	 */
	public function new(ButtonNumber:Int = 0):Void
	{
		super();

		var activateSpaceButton:Bool = ButtonNumber >= 1;
		var activateSpaceButtonTwo:Bool = ButtonNumber == 2;

		var buttonHeight:Int = activateSpaceButton ? Std.int(FlxG.height * 0.75) : FlxG.height;
		var hitboxY:Int = activateSpaceButton ? Std.int(FlxG.height / 4) : 0;

		AlphaThing = ClientPrefs.data.hitboxalpha;
		for (button in Reflect.fields(this))
		{
			if (Std.isOfType(Reflect.field(this, button), FlxButton))
				storedButtonsIDs.set(button, Reflect.getProperty(Reflect.field(this, button), 'IDs'));
		}

			add(buttonLeft = createHint(0, hitboxY, Std.int(FlxG.width / 4), buttonHeight, 0xFF00FF));
			add(buttonDown = createHint(FlxG.width / 4, hitboxY, Std.int(FlxG.width / 4), buttonHeight, 0x00FFFF));
			add(buttonUp = createHint(FlxG.width / 2, hitboxY, Std.int(FlxG.width / 4), buttonHeight, 0x00FF00));
			add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), hitboxY, Std.int(FlxG.width / 4), buttonHeight, 0xFF0000));
    if (activateSpaceButton) {
		    if (activateSpaceButtonTwo) {
				add(buttonAction = createHint(0, 0, Std.int(FlxG.width / 2), Std.int(FlxG.height * 0.25), 0xFFFF00));
				add(buttonActionTwo = createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 2), Std.int(FlxG.height * 0.25), 0x800080));
			} else {
				add(buttonAction = createHint(0, 0, FlxG.width, Std.int(FlxG.height * 0.25), 0xFFFF00));
			}
		}
		
		for (button in Reflect.fields(this))
		{
			if (Std.isOfType(Reflect.field(this, button), FlxButton))
				Reflect.setProperty(Reflect.getProperty(this, button), 'IDs', storedButtonsIDs.get(button));
		}
		scrollFactor.set();
		updateTrackedButtons();
	}

	/**
	 * Clean up memory.
	 */
	override function destroy():Void
	{
		super.destroy();

		buttonLeft = FlxDestroyUtil.destroy(buttonLeft);
		buttonUp = FlxDestroyUtil.destroy(buttonUp);
		buttonDown = FlxDestroyUtil.destroy(buttonDown);
		buttonRight = FlxDestroyUtil.destroy(buttonRight);
		buttonAction = FlxDestroyUtil.destroy(buttonAction);
	}

	private function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF):BitmapData
	{
		var shape:Shape = new Shape();
		shape.graphics.beginFill(Color);
		shape.graphics.lineStyle(10, Color, 1);
		shape.graphics.drawRect(0, 0, Width, Height);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}

	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):FlxButton
	{
		var hint:FlxButton = new FlxButton(X, Y);
		hint.loadGraphic(createHintGraphic(Width, Height, Color));
		hint.solid = false;
		hint.immovable = true;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.onDown.callback = hint.onOver.callback = function()
		{
			if (hint.alpha != AlphaThing)
				hint.alpha = AlphaThing;
		}
		hint.onUp.callback = hint.onOut.callback = function()
		{
			if (hint.alpha != 0.00001)
				hint.alpha = 0.00001;
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}
}
