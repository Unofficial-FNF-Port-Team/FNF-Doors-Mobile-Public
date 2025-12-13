package substates;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;
import mobile.MobileControls;
import mobile.flixel.FlxVirtualPad;
import flixel.util.FlxDestroyUtil;

class MusicBeatSubstate extends FlxSubState
{
	public static var instance:MusicBeatSubstate;
	
	public function new()
	{
		instance = this;
		controls.isInSubstate = true;
		super();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;
	
	public var theMouse:DoorsMouse;

	inline function get_controls():Controls
		return Controls.instance;

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

	public function addMobileControls(DefaultDrawTarget:Bool = false)
	{
		mobileControls = new MobileControls();

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

		controls.isInSubstate = false;
		
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
		
		super.destroy();
	}
	override function create(){
		super.create();

		theMouse = new DoorsMouse();
		theMouse.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		add(theMouse);
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();


		super.update(elapsed);
	}
	
	override function close(){
		super.close();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
