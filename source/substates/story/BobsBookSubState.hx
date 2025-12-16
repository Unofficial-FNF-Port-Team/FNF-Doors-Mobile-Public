package substates.story;

class BobsBookSubState extends StoryModeSubState {

    public var currentPage:Int = 0;
    final MAXPAGE = 12;

    var pageBackground:FlxSprite;
    var pageShading:FlxSprite;
    var leftDrawing:FlxSprite;
    var currentText:FlxText;

    var canUpdate:Bool = false;

    public function new(){
        super();
		controls.isInSubstate = true;

        Paths.image("bobsBook/cover");
        pageBackground = new FlxSprite(0, 0).loadGraphic(Paths.image("bobsBook/blank"));
        pageBackground.antialiasing = ClientPrefs.globalAntialiasing;

        for(i in 1...MAXPAGE+1){
            Paths.image("bobsBook/leftpage/page" + i);
        }

        leftDrawing = new FlxSprite(0, 0).loadGraphic(Paths.image("bobsBook/leftpage/page" + currentPage));
        leftDrawing.antialiasing = ClientPrefs.globalAntialiasing;

        currentText = new FlxText(710, 40, 505, getBookText(currentPage), 30);
        currentText.setFormat(Paths.font("BobsBackup.ttf"), 30, JUSTIFY);
        currentText.color = 0xFF081600;
        currentText.antialiasing = ClientPrefs.globalAntialiasing;

        add(pageBackground);
        add(currentText);
        //add(pageShading);
        add(leftDrawing);
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        #if mobile
		addVirtualPad(LEFT_RIGHT, B);
		addVirtualPadCamera();
		#end
        changePage(0);
        startGaming();
    }

    override function update(elapsed){
        if(canUpdate){
            if(controls.UI_RIGHT_P){
                changePage(1);
            } else if(controls.UI_LEFT_P){
                changePage(-1);
            } else if(controls.BACK || controls.ACCEPT
                stopGaming();
            }
        }

        super.update(elapsed);
    }

    override function startGaming(){
        pageBackground.y += FlxG.height;
        leftDrawing.y += FlxG.height;
        currentText.y += FlxG.height;
        canUpdate = false;

        FlxTween.tween(pageBackground, {y: pageBackground.y - FlxG.height}, 0.4, {ease: FlxEase.quadOut});
        FlxTween.tween(leftDrawing, {y: leftDrawing.y - FlxG.height}, 0.4, {ease: FlxEase.quadOut});
        FlxTween.tween(currentText, {y: currentText.y - FlxG.height}, 0.4, {ease: FlxEase.quadOut, onComplete: function(twn){
            canUpdate = true;
        }});
        MenuSongManager.changeSongVolume(0.7, 0.4);
    }

    override function stopGaming(){
        canUpdate = false;
        FlxTween.tween(pageBackground, {y: pageBackground.y + FlxG.height}, 0.8, {ease: FlxEase.quadIn});
        //FlxTween.tween(pageShading, {y: pageShading.y + FlxG.height}, 0.8, {ease: FlxEase.quadIn});
        FlxTween.tween(leftDrawing, {y: leftDrawing.y + FlxG.height}, 0.8, {ease: FlxEase.quadIn});
        FlxTween.tween(currentText, {y: currentText.y + FlxG.height}, 0.8, {ease: FlxEase.quadIn, onComplete: function(twn){
            close();
        }});
        MenuSongManager.changeSongVolume(1.0, 0.8);
    }

    public function changePage(change:Int){
        currentPage += change;
        if(currentPage < 0){
            currentPage = 0;
            return;
        } else if (currentPage > MAXPAGE){
            currentPage = MAXPAGE;
            return;
        }

        currentText.text = getBookText(currentPage).trim();
        currentText.size = 30;
        currentText.y = getRandomishPosition(currentPage);

        if(currentPage == 0 && change == 0){
            currentText.alpha = 0.00001;
            leftDrawing.visible = false;
            pageBackground.loadGraphic(Paths.image("bobsBook/cover"));
        } else if (currentPage == 0 && change == -1) {
            canUpdate = false;
            pageBackground.x = 266;
            pageBackground.loadGraphic(Paths.image("bobsBook/cover"));
            leftDrawing.visible = false;
            FlxTween.tween(pageBackground, {x: 0}, 0.4, {ease: FlxEase.quartInOut, onComplete: function(twn){
                canUpdate = true;
                currentText.alpha = 0.00001;
            }});
        } else if (currentPage == 1 && change == 1) {
            canUpdate = false;
            FlxTween.tween(pageBackground, {x: 266}, 0.4, {ease: FlxEase.quartInOut, onComplete: function(twn){
                leftDrawing.visible = true;
                pageBackground.x = 0;
                canUpdate = true;
                currentText.alpha = 1;
                pageBackground.loadGraphic(Paths.image("bobsBook/blank"));
                leftDrawing.loadGraphic(Paths.image("bobsBook/leftpage/page1"));
            }});
        } else {
            currentText.alpha = 1;
            leftDrawing.visible = true;
            pageBackground.loadGraphic(Paths.image("bobsBook/blank"));
            leftDrawing.loadGraphic(Paths.image("bobsBook/leftpage/page" + currentPage));
            MenuSongManager.playSound("page_turn", 1);
            if(currentPage == MAXPAGE){
                MenuSongManager.changeSongPitch(0.6, 0.4);
            }
        }

        while(currentText.height > currentText.y + 605){
            currentText.size -= 1;
        }
    }

    public function getRandomishPosition(v1:Int){
        return 45 + 15 * FlxMath.fastSin((519 * Math.PI * v1) / 100);
    }

    public function getBookText(page:Int){
        switch(page){
            default:
                return "";
            case 1: //Intro
return Lang.getText("intro", "bobsBook");
            case 2: //Hotel
return Lang.getText("hotel", "bobsBook");
            case 3: //Entities
return Lang.getText("entities", "bobsBook");
            case 4: //Guiding light
return Lang.getText("guidingLight", "bobsBook");
            case 5: //Hide
return Lang.getText("hide", "bobsBook");
            case 6: //Rush
return Lang.getText("rush", "bobsBook");
            case 7: //Screech
return Lang.getText("screech", "bobsBook");
            case 8: //Ambush
return Lang.getText("ambush", "bobsBook");
            case 9: //Timothy
return Lang.getText("timothy", "bobsBook");
            case 10: //Seek
return Lang.getText("seek", "bobsBook");
            case 11: //Eyes
return Lang.getText("eyes", "bobsBook");
            case 12: //Figure, final one
return Lang.getText("figure", "bobsBook");
        }
        return "";
    }
}
