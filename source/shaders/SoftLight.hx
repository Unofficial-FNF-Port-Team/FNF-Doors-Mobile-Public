package shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.display.BitmapData;
import flixel.FlxBasic;
import flixel.system.FlxAssets.FlxShader;

class SoftLight extends FlxBasic{
    public var shader(default, null):SoftLightGLSL = new SoftLightGLSL();

    var iTime:Float = 0;

    public var bitmapOverlay(default, set):BitmapData;
    public var bitmapAlpha(default, set):Float;

    public function new():Void{
        super();
    }

    override public function update(elapsed:Float):Void{
        super.update(elapsed);
    }

    public function set_bitmapOverlay(v:BitmapData):BitmapData{
        bitmapOverlay = v;
        shader.bitmapOverlay.input = v;
        return v;
    }
    
    public function set_bitmapAlpha(v:Float):Float{
        bitmapAlpha = v;
        shader.bitmapAlpha.value = [v];
        return v;
    }
}

class SoftLightGLSL extends FlxShader{
    @:glFragmentSource('
        #pragma header
        uniform float iTime;
        uniform sampler2D bitmapOverlay;
        uniform float bitmapAlpha;
        
        #define texture flixel_texture2D
        #define fragColor gl_FragColor
        #define mainImage main
        //****MAKE SURE TO remove the parameters from mainImage.
        //SHADERTOY PORT FIX

        //softLightBlendFilter :
        vec4 softLightBlendFilter(vec4 base,vec4 overlay){
            return base * (overlay.a * (base / base.a) + (2.0 * overlay * (1.0 - (base / base.a)))) + overlay * (1.0 - base.a) + base * (1.0 - overlay.a);
        }
        
        void mainImage()
        {
            vec2 uv = openfl_TextureCoordv.xy;
			vec4 base = texture2D(bitmap, uv);
            vec4 blend = texture2D(bitmapOverlay, uv);
            blend.a = bitmapAlpha;

			gl_FragColor = softLightBlendFilter(base, blend);
        }
    ')

    public function new(){
        super();
    }
}
