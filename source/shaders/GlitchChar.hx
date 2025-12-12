package shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxBasic;
import flixel.system.FlxAssets.FlxShader;

class GlitchChar extends FlxBasic{
    public var shader(default, null):GlitchCharGLSL = new GlitchCharGLSL();

    var iTime:Float = 0;

    public function new():Void{
        super();
    }

    override public function update(elapsed:Float):Void{
        super.update(elapsed);
        iTime += elapsed;
        shader.iTime.value = [iTime];
    }
}

class GlitchCharGLSL extends FlxShader{
    @:glFragmentSource('
        //SHADERTOY PORT FIX
        #pragma header
        uniform float iTime;
        #define iChannel0 bitmap
        #define texture flixel_texture2D
        #define fragColor gl_FragColor
        #define mainImage main
        //****MAKE SURE TO remove the parameters from mainImage.
        //SHADERTOY PORT FIX
        
        //2D (returns 0 - 1)
        float random2d(vec2 n) { 
            return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
        }
        
        float randomRange (in vec2 seed, in float min, in float max) {
                return min + random2d(seed) * (max - min);
        }
        
        // return 1 if v inside 1d range
        float insideRange(float v, float bottom, float top) {
        return step(bottom, v) - step(top, v);
        }
        
        //inputs
        float AMT = 0.01; //0 - 1 glitch amount
        float SPEED = 0.99; //0 - 1 speed
        
        void mainImage()
        {
            vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
            vec2 iResolution = openfl_TextureSize;
            float time = floor(iTime * SPEED * 60.0);    
            vec2 uv = fragCoord.xy / iResolution.xy;
            
            //copy orig
            vec3 outCol = texture(iChannel0, uv).rgb;
            
            //randomly offset slices horizontally
            float maxOffset = AMT/2.0;
            for (float i = 0.0; i < 10.0 * AMT; i += 1.0) {
                float sliceY = random2d(vec2(time , 2345.0 + float(i)));
                float sliceH = random2d(vec2(time , 9035.0 + float(i))) * 0.25;
                float hOffset = randomRange(vec2(time , 9625.0 + float(i)), -maxOffset, maxOffset);
                vec2 uvOff = uv;
                uvOff.x += hOffset;
                if (insideRange(uv.y, sliceY, fract(sliceY+sliceH)) == 1.0 ){
                    outCol = texture(iChannel0, uvOff).rgb;
                }
            }
            
            //do slight offset on one entire channel
            float maxColOffset = AMT/6.0;
            float rnd = random2d(vec2(time , 9545.0));
            vec2 colOffset = vec2(randomRange(vec2(time , 9545.0),-maxColOffset,maxColOffset), 
                            randomRange(vec2(time , 7205.0),-maxColOffset,maxColOffset));
            if (rnd < 0.33){
                outCol.r = texture(iChannel0, uv + colOffset).r;
                
            }else if (rnd < 0.66){
                outCol.g = texture(iChannel0, uv + colOffset).g;
                
            } else{
                outCol.b = texture(iChannel0, uv + colOffset).b;  
            }
            
            float theAlpha = flixel_texture2D(bitmap, uv).a;
            
            fragColor = vec4(outCol,theAlpha);
        }
    ')

    public function new(){
        super();
    }
}
