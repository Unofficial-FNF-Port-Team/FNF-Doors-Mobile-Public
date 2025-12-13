package states;

import backend.BaseSMMechanic;
import flixel.FlxSubState;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import modcharting.*;
import backend.BaseStage;
import mobile.MobileControls;
import mobile.flixel.FlxVirtualPad;
import flixel.util.FlxDestroyUtil;

class MusicBeatState extends modcharting.ModchartMusicBeatState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public var controls(get, never):Controls;
	public var mouseCanClick:Bool = false;
	public var changedMouseState:Bool = false;

	public static var camBeat:FlxCamera;

	public var theMouse:DoorsMouse;

	inline function get_controls():Controls
		return Controls.instance;

	public static var instance:MusicBeatState;
	public var mobileControls:MobileControls;
	public var virtualPad:FlxVirtualPad;

	public var vpadCam:FlxCamera;
	public var camControls:FlxCamera;

	
    public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
	{
		if (virtualPad != null)
			removeVirtualPad();

		virtualPad = new FlxVirtualPad(DPad, Action);
		add(virtualPad);
	}

	public function removeVirtualPad()
	{
		if (virtualPad != null)
			remove(virtualPad);
	}

	public function addMobileControls(DefaultDrawTarget:Bool = false, SpaceButton:Int = 0)
	{
		mobileControls = new MobileControls(SpaceButton);

		camControls = new FlxCamera();
		camControls.bgColor.alpha = 0;
		FlxG.cameras.add(camControls, DefaultDrawTarget);

		mobileControls.cameras = [camControls];
		mobileControls.visible = false;
		add(mobileControls);
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
			remove(mobileControls);
	}

	public function addVirtualPadCamera(DefaultDrawTarget:Bool = false)
	{
		if (virtualPad != null)
		{
			vpadCam = new FlxCamera();
			FlxG.cameras.add(vpadCam, DefaultDrawTarget);
			vpadCam.bgColor.alpha = 0;
			virtualPad.cameras = [vpadCam];
		}
	}

	override function destroy()
	{
		super.destroy();

		if (virtualPad != null)
		{
			virtualPad = FlxDestroyUtil.destroy(virtualPad);
			virtualPad = null;
		}

		if (mobileControls != null)
		{
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
			mobileControls = null;
		}
	}

	override function create()
	{
		instance = this;
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if (!skip)
		{
			openSubState(new CustomFadeTransition(0.4, true));
		}

		FlxTransitionableState.skipNextTransOut = false;

		theMouse = new DoorsMouse();
		theMouse.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		add(theMouse);
		theMouse.isTransparent = false;
	}

	override public function onFocus():Void
	{
		super.onFocus();
	}

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		stagesFunc(function(stage:BaseStage)
		{
			stage.update(elapsed);
		});

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState, ?shaky:Bool = false)
	{
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.4, false, shaky));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finished = false;
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.resetState();
					CustomFadeTransition.finished = true;
				};
			}
			else
			{
				CustomFadeTransition.finished = false;
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.switchState(nextState);
					CustomFadeTransition.finished = true;
				};
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();

		stagesFunc(function(stage:BaseStage)
		{
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		entitiesFunc(function(entity:BaseSMMechanic)
		{
			entity.curStep = curStep;
			entity.curDecStep = curDecStep;
			entity.stepHit(curStep);
		});

		roomsFunc(function(room:BaseSMRoom)
		{
			room.curStep = curStep;
			room.curDecStep = curDecStep;
			room.stepHit(curStep);
		});
	}

	public function beatHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});

		entitiesFunc(function(entity:BaseSMMechanic)
		{
			entity.curBeat = curBeat;
			entity.curDecBeat = curDecBeat;
			entity.beatHit(curBeat);
		});

		roomsFunc(function(room:BaseSMRoom)
		{
			room.curBeat = curBeat;
			room.curDecBeat = curDecBeat;
			room.beatHit(curBeat);
		});
	}

	public function sectionHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	public var stages:Array<BaseStage> = [];

	public function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				func(stage);
	}

	public var entities:Array<BaseSMMechanic> = [];

	public function entitiesFunc(func:BaseSMMechanic->Void)
	{
		for (entity in entities)
			if (entity != null && entity.exists && entity.active)
				func(entity);
	}

	public var rooms:Array<BaseSMRoom> = [];

	public function roomsFunc(func:BaseSMRoom->Void)
	{
		for (room in rooms)
			if (room != null && room.exists && room.active)
				func(room);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
