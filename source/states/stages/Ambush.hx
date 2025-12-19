package states.stages;

import flixel.addons.effects.FlxTrail;
import backend.BaseStage;
import backend.BaseStage.Countdown;

class Ambush extends BaseStage
{
	public static var altID:Int = 0;

	public static function getPreloadShit():Null<Map<String, Array<String>>>
	{
		var theMap:Map<String, Array<String>> = [
			"images" => switch (altID)
			{
				case 1: ["ambush_alt/bg", "GreenLight"];
				case 2: ["ambush_alt2/bg", "GreenLight"];
				default: ["ambush/lightBG", "GreenLight"];
			}
		];

		return theMap;
	}

	override function getBadAppleShit():Null<Map<String, Array<Dynamic>>>
	{
		var map:Map<String, Array<Dynamic>> = [
			"background" => [background, abushStage],
			"foreground" => [],
			"special" => [[abushFog, 0.8]]
		];

		return map;
	}

	var background:Rain;
	var abushStage:BGSprite;
	var abushFog:FlxSprite;

	override function create()
	{
		background = new Rain(-750, -150, 1920, 1080, [0xFF225742, 0xFF001000]);
		background.rainSpeed = 1;
		background.rainAngle = -10;
		add(background);

		abushStage = switch (altID)
		{
			case 1: new BGSprite('ambush_alt/bg', -755, -148, 1, 1);
			case 2: new BGSprite('ambush_alt2/bg', -679, -133, 1, 1);
			default: new BGSprite('ambush/lightBG', -755, -140, 1, 1);
		}
		add(abushStage);

		boyfriendGroup.visible = false;

		abushFog = new FlxSprite(-300, -110);
		abushFog.frames = Paths.getSparrowAtlas('GreenLight');
		abushFog.animation.addByPrefix('I', 'TheIdle0', 24);
		abushFog.animation.play('I');
		abushFog.scale.set(1.6, 1.6);
		abushFog.updateHitbox();
		add(abushFog);
		abushFog.antialiasing = ClientPrefs.globalAntialiasing;
	}

	override function createPost()
	{
		var evilTrail = new FlxTrail(dad, null, 4, 2, 0.3, 0.069); // nice
		evilTrail.framesEnabled = true;
		addBehindDad(evilTrail);

		comboPosition = [248, 474]; // average of the two characters
		comboPosition[0] -= 600;
		comboPosition[1] -= 100;

		dad.x = 25;
	    dad.y = 130; // marcelo salvou dms
	}

	override function update(elapsed:Float)
	{
	    offsetX = Std.int(dad.getMidpoint().x);
	    offsetY = Std.int(dad.getMidpoint().y + 70); 
		bfoffsetX = Std.int(dad.getMidpoint().x);
		bfoffsetY = Std.int(dad.getMidpoint().y + 70);
	}
}
