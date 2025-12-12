package shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxBasic;
import flixel.system.FlxAssets.FlxShader;

class HaltChromaticAberration extends FlxBasic{
    public var shader(default, null):HaltChromaticAberrationGLSL = new HaltChromaticAberrationGLSL();

    var iTime:Float = 0;
    
    public var k(default, set):Float = 0.0;
    public var kcube(default, set):Float = 0.0;
    public var offset(default, set):Float = 0.0;

    public function new():Void{
        super();
    }

    override public function update(elapsed:Float):Void{
        super.update(elapsed);
        iTime += elapsed;
        shader.iTime.value = [iTime];
    }

    public function set_k(v:Float):Float{
        k = v;
        shader.k.value = [v];
        return k;
    }

    public function set_offset(v:Float):Float{
        offset = v;
        shader.offset.value = [v];
        return offset;
    }

    public function set_kcube(v:Float):Float{
        kcube = v;
        shader.kcube.value = [v];
        return kcube;
    }

}

class HaltChromaticAberrationGLSL extends FlxShader{
    @:glFragmentSource('
        #pragma header
        uniform float iTime;
        #define iChannel0 bitmap
        #define texture flixel_texture2D
        #define fragColor gl_FragColor
        #define mainImage main
        
        uniform float k;
        uniform float kcube;
        
        uniform float offset;
        
        vec2 computeUV(vec2 uv, float k, float kcube){
            
            vec2 t = uv - .5;
            float r2 = t.x * t.x + t.y * t.y;
            float f = 0.;
            
            if(kcube == 0.0){
                f = 1. + r2 * k;
            }else{
                f = 1. + r2 * (k + kcube * sqrt(r2));
            }
            
            vec2 nUv = f * t + .5;
        
            return nUv;
            
        }
        
        void mainImage() {
             vec2 uv = openfl_TextureCoordv.xy;
            float theAlpha = flixel_texture2D(bitmap,uv).a;
            
            float red = texture(iChannel0, computeUV(uv, k + offset, kcube)).r; 
            float green = texture(iChannel0, computeUV(uv, k, kcube)).g; 
            float blue = texture(iChannel0, computeUV(uv, k - offset, kcube)).b; 
            
            fragColor = vec4(red, green,blue, theAlpha);
        }
    ')

    public function new(){
        super();
    }
}
