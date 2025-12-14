package states.mechanics;

import shaders.ChromaticAberration;
#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

import flixel.math.FlxPoint;


class OvertimeHealthDrain extends MechanicsManager
{
    var eyesState:Bool = false;
	var canCloseEyes:Bool;
	var eyesBlack:FlxSprite;
	var eyesVignette:FlxSprite;
	var eyesFullBlack:FlxSprite;
	var eyesClosedStick:Bool;

	var graphicsOptimizedArray:Array<FlxSprite> = [];

	var eyesChroma:ChromaticAberration;

	var eyesAbePoint:FlxPoint;
	var eyesBlurPoint:FlxPoint;

    public function new(typeOfOvertime:String)
    {
        type = typeOfOvertime;

        super();
    }

    var multiplier:Float = 1.0;
    override function createPost()
    {
        if(!game.generatedMusic)
        {
            game.allowCountdown = false;

            if(PlayState.isStoryMode) game.health = 2;
        }

        eyesState = false;
        canCloseEyes = true;
        eyesClosedStick = false;

        eyesBlack = new FlxSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
        eyesBlack.scale.set(3, 3);
        eyesBlack.updateHitbox();
        eyesBlack.alpha = 0.0001;

        eyesFullBlack = new FlxSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
        eyesFullBlack.scale.set(3, 3);
        eyesFullBlack.updateHitbox();
        eyesFullBlack.alpha = 0.0001;

        eyesVignette = new FlxSprite().loadGraphic(Paths.image('vignette'), -600, -600);
        eyesVignette.scale.set(1.2, 1);
        eyesVignette.updateHitbox();
        eyesVignette.antialiasing = ClientPrefs.globalAntialiasing;
        eyesVignette.alpha = 0.0001;

        graphicsOptimizedArray.push(eyesBlack);
        graphicsOptimizedArray.push(eyesFullBlack);

        eyesBlack.cameras = [game.camHUD];
        eyesFullBlack.cameras = [game.camHUD];
        eyesVignette.cameras = [game.camHUD];
        
        add(eyesBlack);
        add(eyesFullBlack);
        add(eyesVignette);

        if(ClientPrefs.data.shaders)
        {
            eyesChroma = new ChromaticAberration();
            eyesChroma.iOffset = 0.0;
            add(eyesChroma);
            var filter2:ShaderFilter = new ShaderFilter(eyesChroma.shader);
            game.camGameFilters.push(filter2);
            game.updateCameraFilters('camGame');
        }
        
        eyesAbePoint = new FlxPoint(0, 0);
        eyesBlurPoint = new FlxPoint(0, 0);

		if(song == 'watch-out') {
            multiplier = 0.7;
        }
    
        if(DoorsUtil.modifierActive(22)){
            multiplier /= 1.5;
        } else if(DoorsUtil.modifierActive(23)){
            multiplier *= 1.5;
        }
    }

    override function update(elapsed:Float)
    {
        for(bgBlack in graphicsOptimizedArray)
        {
            bgBlack.scale.set(Std.int(FlxG.width/bgBlack.cameras[0].zoom) + 10, Std.int(FlxG.height/bgBlack.cameras[0].zoom) + 10);
            bgBlack.updateHitbox();
            bgBlack.screenCenter();
        }

		if (game.generatedMusic && game.allowCountdown && game.countdownCounter == 5 && PlayState.instance.dad.alpha >= 0.05)
		{
            var diff = PlayState.storyDifficulty == null ? 1 : PlayState.storyDifficulty;
			if (!eyesState) game.health -= ((diff+2)/1000) * 60 * elapsed * multiplier;
		}
		
		if (FlxG.keys.justPressed.SPACE #if mobile || PlayState.instance.mobileControls.hitbox.buttonAction.justPressed #end)
		{
			if(!eyesState)
			{
                //if the alpha is 0, it takes 20 seconds, if it's 0.5, it takes 10 seconds, you get the point.
                var timeToDark:Float = 20 - eyesFullBlack.alpha*20;
                if(DoorsUtil.modifierActive(39))
                {
                    timeToDark /= 1.5;
                }
                else if(DoorsUtil.modifierActive(40))
                {
                    timeToDark *= 2.25;
                }
                
				eyesState = true;
                FlxTween.cancelTweensOf(eyesBlack);
                FlxTween.cancelTweensOf(eyesFullBlack);
                FlxTween.cancelTweensOf(eyesVignette);
                FlxTween.tween(eyesBlack, {alpha: 0.5}, 0.2);
                FlxTween.tween(eyesFullBlack, {alpha: 1}, timeToDark);
                FlxTween.tween(eyesVignette, {alpha: 1}, 0.2);
                PlayState.instance.triggerEventNote("Change Character", "BF", "closed-eyesbf", 0.0);
				//game.boyfriend.playAnim("transIn", true, false, 0, true);

				FlxTween.tween(eyesBlurPoint, {x:20.0}, 0.01);
				FlxTween.tween(eyesAbePoint, {x:0.008}, 0.2);
			}
			else
			{
                //if the alpha is 1, it takes 2 seconds, if it's 0.5, it takes 1 second, you get the point.
                var timeToClear:Float = 2 - (-eyesFullBlack.alpha+1)*2;
                if(DoorsUtil.modifierActive(39))
                {
                    timeToClear *= 1.5;
                }
                else if(DoorsUtil.modifierActive(40))
                {
                    timeToClear /= 1.25;
                }

				eyesState = false;
                FlxTween.cancelTweensOf(eyesBlack);
                FlxTween.cancelTweensOf(eyesFullBlack);
                FlxTween.cancelTweensOf(eyesVignette);
                FlxTween.tween(eyesBlack, {alpha: 0}, 0.2);
                FlxTween.tween(eyesFullBlack, {alpha: 0}, timeToClear);
                FlxTween.tween(eyesVignette, {alpha: 0}, 0.2);
				//game.boyfriend.playAnim("transOut", true, false, 0, true);
                PlayState.instance.triggerEventNote("Change Character", "BF", "bf_eyes", 0.0);
				
				FlxTween.tween(eyesBlurPoint, {x:0.0}, 0.01);
				FlxTween.tween(eyesAbePoint, {x:0.0}, 0.2);
			}
		}

		if(ClientPrefs.data.shaders)
        {
			eyesChroma.iOffset = eyesAbePoint.x;
		}
    }

    override function goodNoteHit(note:Note)
    {
        if(!note.isSustainNote || PlayState.storyDifficulty == 0) {
            if (eyesState)
                game.health += (0.01 * (PlayState.storyDifficulty == 0 ? 2:1)) * (DoorsUtil.modifierActive(41) ? Math.max(1, (eyesFullBlack.alpha+0.25)*1.5) : 1);
            else
                game.health -= 0.005 * (PlayState.storyDifficulty == 0 ? -0.5:1) * PlayState.healthLoss;
        }
    }
}
