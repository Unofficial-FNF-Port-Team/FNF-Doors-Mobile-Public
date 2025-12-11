package options.substates;

import flixel.math.FlxPoint;
import objects.ui.DoorsMenu;
import objects.ui.DoorsOption.DoorsOptionType;
import objects.ui.DoorsButton;
import flixel.math.FlxRect;
import objects.ui.DoorsOption;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class BaseOptionsMenu extends MusicBeatSubstate
{
	public static var hideGlasshat:Bool = false;

	private var curSelected:Int = 0;
	private var optionsArray:Array<CommonDoorsOption>;
	
	final options:Array<String> = ['language', "glasshat", 'controls', 'graphics', 'visuals', 'gameplay'];
	var visualOptions:Array<String> = [];

	private var yLerpTargets:Array<Float> = [];

	private var switchStateButtons:FlxTypedSpriteGroup<DoorsButton>;
	private var grpOptions:FlxTypedSpriteGroup<DoorsOption>;

	public var internalTitle:String; //like title, but can be accessed in the en.xml
	public var title:String;
	public var rpcTitle:String;

	var titleText:FlxText;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'language':
				_parentState.openSubState(new options.substates.LanguageSubState());
			case 'controls':
				_parentState.openSubState(new options.substates.NewControlsSubState());
			case 'graphics':
				_parentState.openSubState(new options.substates.GraphicsSettingsSubState());
			case 'visuals':
				_parentState.openSubState(new options.substates.VisualsUISubState());
			case 'gameplay':
				_parentState.openSubState(new options.substates.GameplaySettingsSubState());
			case 'glasshat':
				_parentState.openSubState(new online.GlasshatLogin());
		}
		close();
	}

	public function new(?isFirstOpen:Bool = false)
	{
		super();
		ClientPrefs.saveSettings();
		
		for(i in 0...options.length){
			visualOptions.push('options/main/${options[i]}');
		}

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var blacc:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		blacc.alpha = 0.6;
		add(blacc);

		var bg:DoorsMenu = new DoorsMenu(8,8,"options", title, true, FlxPoint.get(1203, 25));
		bg.closeFunction = function(){
			ClientPrefs.saveSettings();
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
		add(bg);

		if(title == null) title = 'Options';
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if desktop
		DiscordClient.changePresence(rpcTitle, null);
		#end

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedSpriteGroup<DoorsOption>(24, 126);
		add(grpOptions);

		for (i in 0...optionsArray.length)
		{
			var theOption = new DoorsOption(0, i*70, internalTitle, optionsArray[i]);
			theOption.clipRect = CoolUtil.calcRectByGlobal(theOption, FlxRect.get(24, 92, 1232, 539));
			yLerpTargets.push(theOption.y);
			grpOptions.add(theOption);
		}

		makeButtons(hideGlasshat);
		changeSelection();

		if(isFirstOpen){
		}
	}

	public function addOption(option:CommonDoorsOption) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
	}

	var holdTime:Float = 0;
	var holdValue:Float = 0;
	var canUpdate:Bool = true;
	override function update(elapsed:Float)
	{
		canUpdate = true;
		if(internalTitle == "controls"){
			grpOptions.forEach(function(cnt){
				@:privateAccess if(cnt.optionType != CONTROLTITLE){
					if(cnt.binding) canUpdate = false;
				}
			});
		}

		if(canUpdate){
			var upScroll = FlxG.mouse.wheel > 0;
			var downScroll = FlxG.mouse.wheel < 0;
			if (controls.UI_UP_P || upScroll) changeSelection(-1);
			if (controls.UI_DOWN_P || downScroll) changeSelection(1);
	
			if (controls.BACK) {
				ClientPrefs.saveSettings();
				close();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
	
			var rect = FlxRect.get(0, 0, 1232, 539);
			for (i=>o in grpOptions.members){
				o.y = FlxMath.lerp(o.y, yLerpTargets[i] + grpOptions.y, CoolUtil.boundTo(elapsed * 12, 0, 1));
				o.clipRect = CoolUtil.calcRectByGlobal(o, FlxRect.get(24, 92, 1232, 539));
			}
			rect.put();
		}

		super.update(elapsed);
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = 0;
		if (curSelected >= optionsArray.length)
			curSelected = optionsArray.length - 1;

		for (i in 0...grpOptions.members.length) {
			grpOptions.members[i].isSelected = curSelected == i;
			@:privateAccess{
				if(grpOptions.members[i].optionType != DoorsOptionType.CONTROLTITLE) 
					grpOptions.members[i].changeBgSpr(grpOptions.members[i].isSelected);
			}

			if(grpOptions.members[i].isSelected){
				if(curSelected + 2 < optionsArray.length && curSelected - 2 > 0 && change != 0){
					for(i in 0...yLerpTargets.length){
						yLerpTargets[i] = (i - (curSelected - (change < 0 ? (curSelected + 2 == optionsArray.length ? 2 : 3) : (curSelected - 2 > 0 ? 3 : 4))))*70;
					}
				}
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function makeButtons(?hideGlasshat:Bool = false){
		if(switchStateButtons != null) switchStateButtons.clear();
		else {
			switchStateButtons = new FlxTypedSpriteGroup<DoorsButton>(25, 644);
			add(switchStateButtons);
		}
		for(i in 0...options.length){
			if(hideGlasshat && options[i] == 'glasshat') continue;
			//separate each by 54px

			var buton:DoorsButton = new DoorsButton((i * 214), 0, visualOptions[i], OPTIONS, NORMAL, function(){
				openSelectedSubstate(options[i]);
			});
			if(options[i] == internalTitle) {
				buton.state = PRESSED;
				buton.makeButton(visualOptions[i]);
			}
			switchStateButtons.add(buton);
		}
	}
}
