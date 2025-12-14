package objects.ui;

import flixel.input.keyboard.FlxKey;
import flixel.math.FlxRect;

typedef Keybind = {
    keyboard:String,
    gamepad:String
}

enum abstract DoorsOptionType(Int) {
    final BOOL = 0;
    final INT = 1;
    final FLOAT = 4;
    final STRING = 2;
    final PERCENT = 3;
    final CONTROL = 5;
    final CONTROLTITLE = 6;
    final BUTTON = 7;
}

typedef CommonDoorsOption = {
    var name:String;
    var ?category:String;
    var ?description:String;
    var ?variable:String;
    var type:DoorsOptionType;

    var ?defaultValue:Dynamic;
    var ?onChange:Void->Void;

    var ?stringOptions:Array<String>;

    var ?scrollSpeed:Float;
    var ?changeValue:Dynamic;
    var ?minValue:Dynamic;
    var ?maxValue:Dynamic;
    var ?decimals:Int;
    var ?displayFormat:String;

    var ?controlKey:String;
}

class DoorsOption extends FlxSpriteGroup {
    // Constants
    static inline final DEFAULT_SCROLL_SPEED:Float = 50;
    static inline final DEFAULT_DECIMALS:Int = 1;
    static inline final DEFAULT_FORMAT:String = '%v';
    static inline final HOLD_THRESHOLD:Float = 0.5;
    
    // Core option properties
    var optionType:DoorsOptionType = DoorsOptionType.STRING;
    var name:String;
    var description:String;
    var category:String = "";
    var variable:String = null;
    public var defaultValue:Dynamic = null;
    public var onChange:Void->Void = null;

    // UI elements
    var bg:FlxSprite;
    var titleText:FlxText;
    var descText:FlxText;
    var availableOptions:FlxTypedSpriteGroup<FlxText>;
    public var leftSelector:StoryModeSpriteHoverable;
    public var rightSelector:StoryModeSpriteHoverable;

    // Option positioning and state
    var xLerpPositions:Array<Float> = [];
    var internalOptions:Array<String> = [];
    public var isSelected:Bool = false;
    public var pauseUpdate:Bool = false;
    public var curOption:Int = 0;
    
    // Value control parameters
    public var scrollSpeed:Float = DEFAULT_SCROLL_SPEED;
    public var changeValue:Dynamic = 1;
    public var minValue:Dynamic = null;
    public var maxValue:Dynamic = null;
    public var decimals:Int = DEFAULT_DECIMALS;
    public var displayFormat:String = DEFAULT_FORMAT;

    // Control-specific elements
    public var leftControlText:FlxText;
    public var rightControlText:FlxText;
    public var whichSelected:String = "l";
    public var assignedKey:String = "";
    public var binding:Bool = false;
    var holdingEsc:Float = 0;
    
    // Update tracking
    private var holdTime:Float = 0;
    private var holdValue:Float = 0;

    public function new(x:Float, y:Float, category:String, commonOption:CommonDoorsOption) {
        super(x, y);
        
        initializeProperties(category, commonOption);
        
        if (optionType != DoorsOptionType.CONTROL && optionType != DoorsOptionType.CONTROLTITLE && optionType != DoorsOptionType.BUTTON) {
            makeOption(commonOption, commonOption.stringOptions);
            setDefaultValues();
        } else if(optionType != DoorsOptionType.BUTTON) {
            makeControl();
        } else {
            makeButton();
        }
    }

    private function initializeProperties(category:String, commonOption:CommonDoorsOption) {
        this.category = commonOption.category != null ? commonOption.category : category;
        this.name = commonOption.name;
        this.description = commonOption.description != null ? commonOption.description : "";
        this.variable = commonOption.variable;
        this.optionType = commonOption.type;

        this.defaultValue = commonOption.defaultValue;
        this.onChange = commonOption.onChange;

        this.scrollSpeed = commonOption.scrollSpeed != null ? commonOption.scrollSpeed : DEFAULT_SCROLL_SPEED;
        this.changeValue = commonOption.changeValue != null ? commonOption.changeValue : 1;
        this.minValue = commonOption.minValue;
        this.maxValue = commonOption.maxValue;
        this.decimals = commonOption.decimals != null ? commonOption.decimals : DEFAULT_DECIMALS;
        this.displayFormat = commonOption.displayFormat != null ? commonOption.displayFormat : DEFAULT_FORMAT;

        this.assignedKey = commonOption.controlKey != null ? commonOption.controlKey : "";
    }

    public function changeBgSpr(selected:Bool) {
        if (optionType != DoorsOptionType.CONTROL && optionType != DoorsOptionType.BUTTON) {
            bg.loadGraphic(Paths.image(selected ? "ui/options/selected" : "ui/options/default"));
        } else if(optionType != DoorsOptionType.BUTTON) {
            if (!selected) {
                bg.loadGraphic(Paths.image("ui/options/c_default"));
            } else {
                var imagePath = whichSelected == "l" ? "ui/options/c_leftselect" : "ui/options/c_rightselect";
                bg.loadGraphic(Paths.image(imagePath));
            }
        } else if(optionType == DoorsOptionType.BUTTON){
            bg.loadGraphic(Paths.image(selected ? "ui/options/button_selected" : "ui/options/button"));
        }
    }

    private function makeControl() {
        if (optionType == DoorsOptionType.CONTROL) {
            createControlUI();
        } else {
            createControlTitleUI();
        }
    }

    private function createControlUI() {
        defaultValue = '';
        
        bg = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/options/c_default'));
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);

        var translatedName = 'options/controls/${category}/${name}';
        
        titleText = new FlxText(14, 4, 0, translatedName, 32);
        titleText.setFormat(FONT, 32, 0xFFFEDEBF, LEFT, OUTLINE, 0xFF452D25);
        titleText.antialiasing = ClientPrefs.globalAntialiasing;
        add(titleText);

        var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(assignedKey);

        leftControlText = new FlxText(727, 4, 239, InputFormatter.getKeyName((savKey[0] != null) ? savKey[0] : NONE));
        leftControlText.antialiasing = ClientPrefs.globalAntialiasing;
        leftControlText.setFormat(FONT, 32, 0xFFFEDEBF, CENTER, OUTLINE, 0xFF452D25);
        add(leftControlText);

        rightControlText = new FlxText(988, 4, 239, InputFormatter.getKeyName((savKey[1] != null) ? savKey[1] : NONE));
        rightControlText.antialiasing = ClientPrefs.globalAntialiasing;
        rightControlText.setFormat(FONT, 32, 0xFFFEDEBF, CENTER, OUTLINE, 0xFF452D25);
        add(rightControlText);
    }

    private function createControlTitleUI() {
        bg = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/options/c_title'));
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);

        var translatedName = 'options/controls/${category}/globalname';
        titleText = new FlxText(0, -5, 1232, translatedName, 48);
        titleText.setFormat(FONT, 48, 0xFFFEDEBF, CENTER, OUTLINE, 0xFF452D25);
        titleText.antialiasing = ClientPrefs.globalAntialiasing;
        add(titleText);
    }

    private function makeOption(commonOption:CommonDoorsOption, ?stringOpt:Array<String>) {
        createBasicUI();
        createSelectors();
        createOptionValues(stringOpt);
        
        applyAntialiasing();
    }
    
    private function createBasicUI() {
        bg = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/options/default'));
        add(bg);
        
        titleText = new FlxText(14, 4, 0, '|:|name|:|options/${category}/${name}', 32);
        titleText.setFormat(FONT, 32, 0xFFFEDEBF, LEFT, OUTLINE, 0xFF452D25);
        titleText.antialiasing = ClientPrefs.globalAntialiasing;
        add(titleText);
        
        descText = new FlxText(titleText.x + titleText.width + 20, 12, 962 - (titleText.x + titleText.width + 20), '|:|desc|:|options/${category}/${name}'.replace("\n", " "), 32);
        descText.setFormat(FONT, 20, 0xFFFEDEBF, LEFT, OUTLINE, 0xFF452D25);
        descText.alpha = 0.8;
        descText.antialiasing = ClientPrefs.globalAntialiasing;
        
        // Adjust text size if it's too big
        while (descText.height > 49) {
            descText.size--;
            descText.y--;
        }
        
        add(descText);
    }
    
    private function createSelectors() {
        leftSelector = new StoryModeSpriteHoverable(996, 9, "ui/leftArrow");
        add(leftSelector);

        rightSelector = new StoryModeSpriteHoverable(1198, 9, "ui/leftArrow");
        rightSelector.flipX = true;
        add(rightSelector);

        availableOptions = new FlxTypedSpriteGroup<FlxText>(988, 5);
        add(availableOptions);
    }
    
    private function createOptionValues(?stringOpt:Array<String>) {
        switch (optionType) {
            case DoorsOptionType.BOOL:
                setupBooleanOption();
                
            case DoorsOptionType.INT, DoorsOptionType.FLOAT, DoorsOptionType.PERCENT:
                setupNumericOption();
                
            case DoorsOptionType.STRING:
                setupStringOption(stringOpt);
                
            default:
                // No additional setup needed
        }

        // Common text setup
        setupOptionText();
    }
    
    private function setupBooleanOption() {
        internalOptions = ["disabled", "enabled"];
        
        var disabledOption = new FlxText(0, 0, 239, "options/disabled", 32);
        availableOptions.add(disabledOption);
        
        var enabledOption = new FlxText(0, 0, 239, "options/enabled", 32);
        availableOptions.add(enabledOption);
    }
    
    private function setupNumericOption() {
        var valueText = new FlxText(0, 0, 239, "", 32);
        availableOptions.add(valueText);
    }
    
    private function setupStringOption(stringOpt:Array<String>) {
        internalOptions = stringOpt;
        
        if (variable != "displayLanguage") {
            for (i in 0...internalOptions.length) {
                var text = new FlxText(0, 0, 239, '|:|_${i}|:|options/${category}/specificOptions/${name}', 32);
                availableOptions.add(text);
            }
        } else {
            for (i in 0...internalOptions.length) {
                var text = new FlxText(0, 0, 239, '${internalOptions[i]}', 32);
                availableOptions.add(text);
            }
        }
    }
    
    private function setupOptionText() {
        var rect = FlxRect.get(0, 0, 239, 47);
        
        for (i => o in availableOptions.members) {
            o.antialiasing = ClientPrefs.globalAntialiasing;
            o.setFormat(FONT, 32, 0xFFFEDEBF, CENTER);
            
            // Resize if needed
            while (o.height > 47) o.size--;
            
            o.x = 988 + (239 * i);
            xLerpPositions.push(o.x);
            o.clipRect = CoolUtil.calcRectByGlobal(o, rect);
        }
        
        rect.put();
    }

    private function applyAntialiasing() {
        this.forEach(function(spr) {
            try {
                spr.antialiasing = ClientPrefs.globalAntialiasing;
            } catch(e) {
                // Skip if antialiasing can't be applied
            }
        });
    }

    override function update(elapsed:Float) {
        if (pauseUpdate) {
            super.update(elapsed);
            return;
        }

        updateSelectorPositions(elapsed);
        
        if (optionType != DoorsOptionType.CONTROL && optionType != DoorsOptionType.CONTROLTITLE && optionType != DoorsOptionType.BUTTON) {
            handleStandardOptionUpdate(elapsed);
        } else if (isSelected && optionType == DoorsOptionType.CONTROL) {
            handleControlOptionUpdate(elapsed);
        }
        
        if (optionType == DoorsOptionType.BUTTON) {
            // Check for button activation
            if (Controls.instance.ACCEPT || 
                (FlxG.mouse.overlaps(bg) && FlxG.mouse.justPressed)) {
                triggerButton();
            }
        }

        updateOptionPositions(elapsed);
        
        super.update(elapsed);
    }
    
    private function updateSelectorPositions(elapsed:Float) {
        if (leftSelector != null) {
            leftSelector.x = FlxMath.lerp(leftSelector.x, 996 + this.x, CoolUtil.boundTo(elapsed * 6, 0, 1));
            rightSelector.x = FlxMath.lerp(rightSelector.x, 1198 + this.x, CoolUtil.boundTo(elapsed * 6, 0, 1));
        }
    }

    private function handleStandardOptionUpdate(elapsed:Float) {
        var left = checkLeftInput();
        var right = checkRightInput();
        var left_p = checkLeftPressedInput();
        var right_p = checkRightPressedInput();

        if (left || right) {
            var pressed = (left_p || right_p);

            if (holdTime > HOLD_THRESHOLD || pressed) {
                if (pressed) {
                    handlePressedInput(left, right);
                } else if (optionType != DoorsOptionType.STRING && optionType != DoorsOptionType.BOOL) {
                    handleHeldInput(elapsed, left);
                }
            }
            
            if (optionType != DoorsOptionType.STRING && optionType != DoorsOptionType.BOOL) {
                holdTime += elapsed;
            }
        } else if (Controls.instance.UI_LEFT_R || Controls.instance.UI_RIGHT_R || FlxG.mouse.justReleased) {
            clearHold();
        }
    }
    
    private function checkLeftInput():Bool {
        return leftSelector.isHovered && FlxG.mouse.pressed || 
               (isSelected && (Controls.instance.UI_LEFT || MusicBeatState.instance.virtualPad.buttonLeft.pressed));
    }
    
    private function checkRightInput():Bool {
        return rightSelector.isHovered && FlxG.mouse.pressed || 
               (isSelected && (Controls.instance.UI_RIGHT || MusicBeatState.instance.virtualPad.buttonRight.pressed));
    }
    
    private function checkLeftPressedInput():Bool {
        return leftSelector.isHovered && FlxG.mouse.justPressed || 
               (isSelected && (Controls.instance.UI_LEFT_P || MusicBeatState.instance.virtualPad.buttonLeft.justPressed));
    }
    
    private function checkRightPressedInput():Bool {
        return rightSelector.isHovered && FlxG.mouse.justPressed || 
               (isSelected && (Controls.instance.UI_RIGHT_P || MusicBeatState.instance.virtualPad.buttonRight.justPressed));
    }

    private function handlePressedInput(left:Bool, right:Bool) {
        if (left) {
            leftSelector.x = 988 + this.x;
        } else if (right) {
            rightSelector.x = 1206 + this.x;
        }

        switch (optionType) {
            case DoorsOptionType.INT, DoorsOptionType.FLOAT, DoorsOptionType.PERCENT:
                var add:Dynamic = left ? -changeValue : changeValue;
                updateNumericValue(add);
                
            case DoorsOptionType.STRING, DoorsOptionType.BOOL:
                updateOptionSelection(left);
                
            default:
                // No action needed
        }
        
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    private function updateNumericValue(add:Dynamic) {
        holdValue = getValue() + add;
        
        // Clamp the value
        if (holdValue <= minValue) {
            holdValue = minValue;
            leftSelector.visible = false;
        } else if (holdValue >= maxValue) {
            holdValue = maxValue;
            rightSelector.visible = false;
        } else {
            leftSelector.visible = true;
            rightSelector.visible = true;
        }

        // Round as necessary based on type
        switch (optionType) {
            case DoorsOptionType.INT:
                holdValue = Math.round(holdValue);
                setValue(holdValue);
                
            case DoorsOptionType.FLOAT, DoorsOptionType.PERCENT:
                holdValue = FlxMath.roundDecimal(holdValue, decimals);
                setValue(holdValue);
                
            default:
                // Shouldn't reach here
        }
    }
    
    private function updateOptionSelection(left:Bool) {
        var num:Int = curOption;
        
        if (left) {
            num--;
        } else {
            num++;
        }

        // Clamp the option index and update selector visibility
        if (num <= 0) {
            num = 0;
            leftSelector.visible = false;
            rightSelector.visible = true;
        } else if (num >= internalOptions.length - 1) {
            num = internalOptions.length - 1;
            leftSelector.visible = true;
            rightSelector.visible = false;
        } else {
            leftSelector.visible = true;
            rightSelector.visible = true;
        }
        
        // Update option positions
        for (i in 0...xLerpPositions.length) {
            xLerpPositions[i] = 988 + (239 * (i - num));
        }

        curOption = num;
        setValue(internalOptions[num]);
    }

    private function handleHeldInput(elapsed:Float, left:Bool) {
        holdValue += scrollSpeed * elapsed * (left ? -1 : 1);
        
        // Clamp the value
        if (holdValue <= minValue) {
            holdValue = minValue;
            leftSelector.visible = false;
        } else if (holdValue >= maxValue) {
            holdValue = maxValue;
            rightSelector.visible = false;
        } else {
            leftSelector.visible = true;
            rightSelector.visible = true;
        }

        // Update based on type
        switch (optionType) {
            case DoorsOptionType.INT:
                setValue(Math.round(holdValue));
                
            case DoorsOptionType.FLOAT, DoorsOptionType.PERCENT:
                setValue(FlxMath.roundDecimal(holdValue, decimals));
                
            default:
                // Shouldn't reach here
        }
    }
    
    private function handleControlOptionUpdate(elapsed:Float) {
        if (binding) {
            handleBinding(elapsed);
        } else {
            handleControlSelection();
        }
    }
    
    private function handleBinding(elapsed:Float) {
        var textToUpdate = whichSelected == "l" ? leftControlText : rightControlText;
        updateBind(textToUpdate, "...");
        
        if (FlxG.keys.pressed.ESCAPE) {
            holdingEsc += elapsed;
            if (holdingEsc > HOLD_THRESHOLD) {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                binding = false;
            }
        } else if (FlxG.keys.pressed.BACKSPACE) {
            holdingEsc += elapsed;
            if (holdingEsc > HOLD_THRESHOLD) {
                ClientPrefs.keyBinds.get(assignedKey)[whichSelected == "l" ? 0 : 1] = NONE;
                ClientPrefs.clearInvalidKeys(assignedKey);
                updateBind(textToUpdate, InputFormatter.getKeyName(NONE));
                FlxG.sound.play(Paths.sound('cancelMenu'));
                binding = false;
            }
        } else {
            holdingEsc = 0;
            checkForKeyBindChange();
        }
    }
    
    private function checkForKeyBindChange() {
        var changed:Bool = false;
        var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(assignedKey);
        var altNum = whichSelected == "l" ? 0 : 1;

        if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY) {
            var keyPressed:Int = FlxG.keys.firstJustPressed();
            var keyReleased:Int = FlxG.keys.firstJustReleased();
            
            if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE) {
                curKeys[altNum] = keyPressed;
                changed = true;
            } else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE)) {
                curKeys[altNum] = keyReleased;
                changed = true;
            }
        }

        if (changed) {
            if (curKeys[altNum] == curKeys[1 - altNum]) {
                curKeys[1 - altNum] = FlxKey.NONE;
            }
            
            ClientPrefs.clearInvalidKeys(assignedKey);
            updateControlTexts();
            binding = false;
        }
    }
    
    private function updateControlTexts() {
        for (n in 0...2) {
            var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(assignedKey);
            var key:String = InputFormatter.getKeyName(savKey[n] != null ? savKey[n] : NONE);
            
            if (n == 0) {
                updateBind(leftControlText, key);
            } else {
                updateBind(rightControlText, key);
            }
        }
    }
    
    private function handleControlSelection() {
        if (Controls.instance.UI_LEFT_P) {
            whichSelected = "l";
            changeBgSpr(true);
        } else if (Controls.instance.UI_RIGHT_P) {
            whichSelected = "r";
            changeBgSpr(true);
        }

        if (Controls.instance.ACCEPT) {
            binding = true;
            holdingEsc = 0;
        }
    }
    
    private function updateOptionPositions(elapsed:Float) {
        if (availableOptions != null) {
            var rect = FlxRect.get(this.x + 996, 0, 218, 47);
            
            for (i => o in availableOptions.members) {
                o.x = FlxMath.lerp(o.x, xLerpPositions[i] + this.x, CoolUtil.boundTo(elapsed * 6, 0, 1));
                o.clipRect = FlxRect.get(rect.x - o.x, o.clipRect.y, rect.width, o.clipRect.height);
            }
            
            rect.put();
        }
    }

    function clearHold() {
        if (holdTime > HOLD_THRESHOLD) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        holdTime = 0;
    }
    
    public function getValue():Dynamic {
        var value = Reflect.getProperty(ClientPrefs.data, variable);
        if (optionType == DoorsOptionType.CONTROL) {
            return !Controls.instance.controllerMode ? value.keyboard : value.gamepad;
        }
        return value;
    }

    public function setDefaultValues() {
        Reflect.setProperty(ClientPrefs.data, variable, getValue());

        switch (optionType) {
            case DoorsOptionType.INT, DoorsOptionType.PERCENT, DoorsOptionType.FLOAT:
                updateNumericDisplay();
                
            case DoorsOptionType.BOOL:
                updateBooleanDisplay();
                
            case DoorsOptionType.STRING:
                updateStringDisplay();
                
            case DoorsOptionType.CONTROL:
                // Control options are handled differently
                
            default:
                // Nothing to do
        }
    }
    
    private function updateNumericDisplay() {
        var text:String = displayFormat;
        var val:Dynamic = getValue();
        
        if (optionType == DoorsOptionType.PERCENT) {
            val *= 100;
        }
        
        var def:Dynamic = defaultValue;
        availableOptions.members[0].text = text.replace('%v', val).replace('%d', def);
        
        // Update selector visibility
        leftSelector.visible = !(val == minValue);
        rightSelector.visible = !(val == maxValue);
    }
    
    private function updateBooleanDisplay() {
        curOption = getValue() ? 1 : 0;
        
        for (i in 0...xLerpPositions.length) {
            xLerpPositions[i] = 988 + (239 * (i - curOption));
            availableOptions.members[i].x = xLerpPositions[i];
        }

        // Update selector visibility
        updateSelectorVisibility();
    }
    
    private function updateStringDisplay() {
        curOption = internalOptions.indexOf(getValue());
        
        for (i in 0...xLerpPositions.length) {
            xLerpPositions[i] = 988 + (239 * (i - curOption));
            availableOptions.members[i].x = xLerpPositions[i];
        }
        
        // Update selector visibility
        updateSelectorVisibility();
    }
    
    private function updateSelectorVisibility() {
        if (curOption <= 0) {
            leftSelector.visible = false;
            rightSelector.visible = true;
        } else if (curOption >= internalOptions.length - 1) {
            leftSelector.visible = true;
            rightSelector.visible = false;
        } else {
            leftSelector.visible = true;
            rightSelector.visible = true;
        }
    }
    
    public function setValue(value:Dynamic) {
        if (optionType == DoorsOptionType.BOOL) {
            value = (curOption != 0);
        }

        if (optionType == DoorsOptionType.CONTROL) {
            if (onChange != null) onChange();
            return;
        }

        Reflect.setProperty(ClientPrefs.data, variable, value);
        if (onChange != null) onChange();

        if (optionType != DoorsOptionType.STRING && optionType != DoorsOptionType.BOOL) {
            updateNumericDisplay();
        }
    }

    function updateBind(textToModify:FlxText, st:String) {
        textToModify.text = st;
    }

    private function makeButton() {
        createButtonUI();
    }

    private function createButtonUI() {
        bg = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/options/button'));
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);
        
        titleText = new FlxText(14, 4, 0, '|:|name|:|options/${category}/${name}', 32);
        titleText.setFormat(FONT, 32, 0xFFFEDEBF, LEFT, OUTLINE, 0xFF452D25);
        titleText.antialiasing = ClientPrefs.globalAntialiasing;
        add(titleText);
        
        descText = new FlxText(titleText.x + titleText.width + 20, 12, 1210 - (titleText.x + titleText.width + 20), '|:|desc|:|options/${category}/${name}'.replace("\n", " "), 32);
        descText.setFormat(FONT, 20, 0xFFFEDEBF, LEFT, OUTLINE, 0xFF452D25);
        descText.alpha = 0.8;
        descText.antialiasing = ClientPrefs.globalAntialiasing;
        
        while (descText.height > 49) {
            descText.size--;
            descText.y--;
        }
        
        add(descText);
        
        applyAntialiasing();
    }

    public function triggerButton():Void {
        if (onChange != null) {
            MenuSongManager.playSound('confirmMenu');
            onChange();
        }
    }
}
