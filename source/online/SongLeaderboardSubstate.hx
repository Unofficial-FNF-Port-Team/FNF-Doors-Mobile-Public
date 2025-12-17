package online;

import flixel.math.FlxRect;
import objects.ui.DoorsScore;
import objects.ui.DoorsMenu;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import states.AchievementsState.ScrollBar;
import flixel.text.FlxText;
import substates.MusicBeatSubstate;


class SongLeaderboardSubstate extends MusicBeatSubstate
{
    var songname:String;
    var songFile:String;
    var diff:String;

    var theActualMenu:FlxSpriteGroup;
    var leaderboardsMenu:DoorsMenu;
    var glasshatTitle:FlxText;
    var scoreTitle:FlxText;
    var accTitle:FlxText;
    var missesTitle:FlxText;
    var modifiersTitle:FlxText;

    var leaderboardScores:FlxTypedSpriteGroup<DoorsScore>;
    var errorText:FlxText;
    
	private var yLerpTargets:Array<Float> = [];

	var curSelected:Int;

	public function new(songname:String, diff:String, ?songFile:String)
    {
        super();
		controls.isInSubstate = true;
        
        this.songname = songname;
        this.songFile = songFile;
        this.diff = diff;

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        theActualMenu = new FlxSpriteGroup(125, 40);
        add(theActualMenu);

        leaderboardsMenu = new DoorsMenu(0, 0, "leaderboards",
        'LEADERBOARDS - ${songname} (${CoolUtil.getDisplayDiffString(CoolUtil.defaultDifficulties.indexOf(diff))})',true);
        theActualMenu.add(leaderboardsMenu);

        glasshatTitle = new FlxText(9, 96, 413, Lang.getText("glasshat", "leaderboards"));
        glasshatTitle.setFormat(FONT, 32, 0xFFFEDEBF, CENTER);
        glasshatTitle.antialiasing = ClientPrefs.globalAntialiasing;
        theActualMenu.add(glasshatTitle);

        scoreTitle = new FlxText(428,96,180,Lang.getText("score", "leaderboards"));
        scoreTitle.setFormat(FONT, 32, 0xFFFEDEBF, CENTER);
        scoreTitle.antialiasing = ClientPrefs.globalAntialiasing;
        theActualMenu.add(scoreTitle);

        accTitle = new FlxText(613,96,127,Lang.getText("acc", "leaderboards"));
        accTitle.setFormat(FONT, 32, 0xFFFEDEBF, CENTER);
        accTitle.antialiasing = ClientPrefs.globalAntialiasing;
        theActualMenu.add(accTitle);

        missesTitle = new FlxText(746,96,127,Lang.getText("miss", "leaderboards"));
        missesTitle.setFormat(FONT, 32, 0xFFFEDEBF, CENTER);
        missesTitle.antialiasing = ClientPrefs.globalAntialiasing;
        theActualMenu.add(missesTitle);

        modifiersTitle = new FlxText(878,96,144,Lang.getText("modf", "leaderboards"));
        modifiersTitle.setFormat(FONT, 32, 0xFFFEDEBF, CENTER);
        modifiersTitle.antialiasing = ClientPrefs.globalAntialiasing;
        theActualMenu.add(modifiersTitle);

        errorText = new FlxText(8,148,1014,"");
        errorText.setFormat(FONT, 32, 0xFFFEDEBF, CENTER);
        errorText.antialiasing = ClientPrefs.globalAntialiasing;
        theActualMenu.add(errorText);

        leaderboardScores = new FlxTypedSpriteGroup<DoorsScore>(8, 148);
        theActualMenu.add(leaderboardScores);

		#if mobile
		addVirtualPad(UP_DOWN, B);
		addVirtualPadCamera();
		#end

        updateText();
        startGaming();
    }

    function startGaming(){
        doUpdate = true;
        this.forEach(function(basic:Dynamic){
            try{
                if(Std.isOfType(basic, FlxSprite)){
                    FlxTween.tween((basic:FlxSprite), {x: (basic:FlxSprite).x}, 0.6, {ease:FlxEase.quadInOut});
                    (basic:FlxSprite).x -= 1280;
                }
            } catch(e){}
        });
    }

    var doUpdate = true;
    function stopGaming(){
        this.forEach(function(basic:Dynamic){
            try{
                if(Std.isOfType(basic, FlxSprite)){
                    FlxTween.tween((basic:FlxSprite), {x: (basic:FlxSprite).x - 1280}, 0.6, {ease:FlxEase.quadInOut, onComplete:function(twn){
                        close();
                    }});
                }
            } catch(e){}
        });
    }

    var waiting:Bool = false;

    function updateText()
    {
        waiting = true;
        errorText.text = "Fetching scores...";
        if(songFile == null) songFile = songname;
        Leaderboards.getLeaderboard(songFile.toLowerCase(), diff.toLowerCase(), function(data:Dynamic)
        {
            if(Std.isOfType(data, String)){
                switch(data)
                {
                    case 'noScores':
                        errorText.text = Lang.getText("noScores", "glasshat");
                    case 'notLoggedIn':
                        errorText.text = Lang.getText("notLoggedIn", "glasshat");
                    case 'error': 
                        errorText.text = Lang.getText("error", "glasshat");
                } 
            } else {
                var scoreList:Leaderboards.SongLeaderboard;
                try
                {
                    scoreList = Leaderboards.parseLeaderboard(data); //unseralize from string to type
                }
                catch(e)
                {
                    errorText.text = Lang.getText("error", "glasshat");
                    return;
                }
                
                for (i in 0...scoreList.scores.length)
                {
                    var data = scoreList.scores[i];
                    var thisScore = new DoorsScore(16, 20 + 60*i, data, 
                        i == 0 ? FIRST : i == 1 ? SECOND : i == 2 ? THIRD : OTHER);
                    thisScore.forEach(function(spr){
                        spr.clipRect = CoolUtil.calcRectByGlobal(
                            spr, FlxRect.get(0, 188, 1280, 484));
                    });
                    yLerpTargets.push(thisScore.y);
                    leaderboardScores.add(thisScore);
                    
                    FlxTween.cancelTweensOf(leaderboardScores);
                    FlxTween.tween(thisScore, {y: thisScore.y, alpha: 1}, 0.6, {ease:FlxEase.quadInOut, startDelay:0.3+(0.01 * i)});
                    thisScore.y += 1280;
                    thisScore.alpha = 0;
                }
                errorText.text = "";
            }

            waiting = false;
        });
    }

	override function update(elapsed:Float)
    {
        if (controls.BACK)
        {
            stopGaming();
        }
        if (waiting)
        {
            super.update(elapsed);
            return;
        }

        if(doUpdate){
			var upScroll = FlxG.mouse.wheel > 0;
			var downScroll = FlxG.mouse.wheel < 0;
            if (controls.UI_UP_P || upScroll) changeSelection(-1);
            if (controls.UI_DOWN_P || downScroll) changeSelection(1);

			for (i=>o in leaderboardScores.members){
				o.y = FlxMath.lerp(o.y, yLerpTargets[i] + leaderboardScores.y, CoolUtil.boundTo(elapsed * 12, 0, 1));
                o.forEach(function(spr){
                    spr.clipRect = CoolUtil.calcRectByGlobal(
                        spr, FlxRect.get(0, 188, 1280, 484));
                });
			}
        }
        super.update(elapsed);
    }

	function changeSelection(change:Int = 0)
        {
            curSelected += change;
            if (curSelected < 0)
                curSelected = 0;
            if (curSelected >= leaderboardScores.members.length)
                curSelected = leaderboardScores.members.length - 1;

            for(i in 0...yLerpTargets.length){
                yLerpTargets[i] = (60*(i - curSelected));
                leaderboardScores.members[i].clipRect = CoolUtil.calcRectByGlobal(leaderboardScores.members[i], FlxRect.get(133, 188, 1014, 484));
            }
    
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
}
