package states.storymechanics;

import backend.BaseSMMechanic.BaseSMMechanic;

enum ScreechState {
	Inactive;
	Waiting;
	ShowingSpaceBar;
	Active;
	Dodged;
}

class Screech extends BaseSMMechanic {
	private var spacebarPrompt:FlxSprite;
	private var screechJumpscare:FlxSprite;
	private var screechLeave:FlxSprite;
	private var spawnTimer:FlxTimer;
	private var currentState:ScreechState;
	
	private var activeTime:Float = 0.0;

	override function create() {
		setupSprites();
		currentState = Inactive;
		onDark();
	}

	private function setupSprites() {
		// Setup spacebar prompt
		spacebarPrompt = new FlxSprite();
		spacebarPrompt.frames = Paths.getSparrowAtlas('darkRoom/SpaceAnimation');
		spacebarPrompt.animation.addByPrefix('idle', 'Space', 12, true);
		spacebarPrompt.alpha = 0.00001;
		spacebarPrompt.cameras = [camHUD];
		spacebarPrompt.scale.set(0.7, 0.7);
		spacebarPrompt.updateHitbox();
		spacebarPrompt.screenCenter();
		spacebarPrompt.antialiasing = ClientPrefs.globalAntialiasing;
		spacebarPrompt.y += 260;
		spacebarPrompt.animation.play('idle');

		// Setup jumpscare sprite
		screechJumpscare = new FlxSprite();
		screechJumpscare.frames = Paths.getSparrowAtlas('darkRoom/ScreechJumpscare');
		screechJumpscare.animation.addByPrefix('idle', 'Stopped', 24, true);
		screechJumpscare.visible = false;
		screechJumpscare.cameras = [camHUD];
		screechJumpscare.screenCenter();
		screechJumpscare.antialiasing = ClientPrefs.globalAntialiasing;

		// Setup leave animation sprite
		screechLeave = new FlxSprite();
		screechLeave.frames = Paths.getSparrowAtlas('darkRoom/ScreechJumpscare2');
		screechLeave.animation.addByPrefix('stop', 'Jumpscare', 24, false);
		screechLeave.visible = false;
		screechLeave.cameras = [camHUD];
		screechLeave.screenCenter();
		screechLeave.antialiasing = ClientPrefs.globalAntialiasing;

		add(screechLeave);
		add(screechJumpscare);
		add(spacebarPrompt);
	}

	public function onLight() {
		resetState();
	}

	public function onDark() {
		resetState();
		startSpawnTimer();
	}

	private function resetState() {
		currentState = Inactive;
		hideAllSprites();
		if (spawnTimer != null) {
			spawnTimer.cancel();
			spawnTimer = null;
		}
	}

	private function hideAllSprites() {
		spacebarPrompt.alpha = 0;
		screechJumpscare.visible = false;
		screechLeave.visible = false;
	}

	private function startSpawnTimer() {
		currentState = Waiting;
		spawnTimer = new FlxTimer().start(FlxG.random.float(2, 10), function(_) {
			startScreechSequence();
		});
	}
	
	private function startScreechSequence() {
		currentState = ShowingSpaceBar;
		FlxTween.tween(spacebarPrompt, {alpha: 1}, 0.6);
		
		MenuSongManager.playSound("psst", 1.0);
		
		new FlxTimer().start(1, function(_) {
			if (currentState == ShowingSpaceBar) {
				currentState = Active;
				screechLeave.visible = true;
				screechLeave.animation.play('stop', true, true, 0);
				MenuSongManager.playSound("screech", 0.6);
				screechLeave.animation.callback = function(animName:String, frameNumber:Int, frameIndex:Int) {
					if(animName == "stop" && frameIndex == 5) {
						screechJumpscare.animation.play("idle");
						screechJumpscare.visible = true;
						screechLeave.visible = false;
						screechLeave.animation.finishCallback = null;
					}
				}
				StoryMenuState.instance.checkForSeeingDouble();
			}
		});
	}

	override function update(elapsed:Float) {
		switch (currentState) {
			case Active:
				handleActiveState(elapsed);
			case Dodged:
				handleDodgedState();
			default:
				//do nothing
		}
	}
	
	private function handleCanDodgeState() {
		if (FlxG.keys.justPressed.SPACE) {
			currentState = Dodged;
			screechLeave.visible = true;
			screechLeave.animation.play('stop', true, false, 6);
			screechJumpscare.visible = false;
			FlxTween.tween(spacebarPrompt, {alpha: 0}, 0.6);
			screechLeave.animation.finishCallback = null;
			screechLeave.animation.finished = false;
			MenuSongManager.playSound("screechCaught", 0.6);
		}

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				currentState = Dodged;
			    screechLeave.visible = true;
			    screechLeave.animation.play('stop', true, false, 6);
			    screechJumpscare.visible = false;
			    FlxTween.tween(spacebarPrompt, {alpha: 0}, 0.6);
			    screechLeave.animation.finishCallback = null;
			    screechLeave.animation.finished = false;
			    MenuSongManager.playSound("screechCaught", 0.6);
			}
		}
		#end
	}

	private function handleActiveState(elapsed:Float) {
		activeTime += elapsed;
		if(activeTime > 0.6) {
			applyDamage(elapsed);
		}
		handleCanDodgeState();
	}

	private function handleDodgedState() {
		if (screechLeave.animation.finished) {
			hideAllSprites();
			startSpawnTimer();
		}
	}

	private function applyDamage(elapsed:Float) {
		var multiplier:Int = DoorsUtil.modifierActive(20) ? 2 : 1;
		DoorsUtil.addStoryHealth(-1 * elapsed * multiplier, false);
		
		if (health <= 0) {
			StoryMenuState.instance.fuckingDie("SONG", "screech", function(){
				DoorsUtil.curRun.revivesLeft += 1;
			});
		}
		
		camGame.shake(0.01, 0.02);
		camHUD.shake(0.01, 0.02);
	}
}
