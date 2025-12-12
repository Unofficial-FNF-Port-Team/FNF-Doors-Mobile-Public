package shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxBasic;
import flixel.system.FlxAssets.FlxShader;

class FigureBlur extends FlxBasic{
    public var shader(default, null):FigureBlurGLSL = new FigureBlurGLSL();

    var iTime:Float = 0;

    public var cx(default, set):Float = 0.5;
    public var cy(default, set):Float = 0.5;
    public var blurWidth(default, set):Float = 0.5;

    public function new():Void{
        super();
    }

    override public function update(elapsed:Float):Void{
        super.update(elapsed);
    }

    public function set_cx(v:Float):Float{
        cx = v;
        shader.cx.value = [v];
        return cx;
    }

    public function set_cy(v:Float):Float{
        cy = v;
        shader.cy.value = [v];
        return cy;
    }

    public function set_blurWidth(v:Float):Float{
        blurWidth = v;
        shader.blurWidth.value = [v];
        return blurWidth;
    }
}

class FigureBlurGLSL extends FlxShader{
    @:glFragmentSource('
    #pragma header
    //https://github.com/bbpanzu/FNF-Sunday/blob/main/source_sunday/RadialBlur.hx
    //https://www.shadertoy.com/view/XsfSDs
    uniform float cx; //center x (0.0 - 1.0)
    uniform float cy; //center y (0.0 - 1.0)
    uniform float blurWidth; // blurAmount 
    
    const int nsamples = 30; //samples
    
    void main(){
        vec4 color = texture2D(bitmap, openfl_TextureCoordv);
            vec2 res;
            res = openfl_TextureCoordv;
        vec2 pp;
        pp = vec2(cx, cy);
        vec2 center = pp;
        float blurStart = 1.0;

        
        vec2 uv = openfl_TextureCoordv.xy;
        
        uv -= center;
        float precompute = blurWidth * (1.0 / float(nsamples - 1));
        
        for(int i = 0; i < nsamples; i++)
        {
            float scale = blurStart + (float(i)* precompute);
        color += texture2D(bitmap, uv * scale + center);
        }
        
        
        color /= float(nsamples);
        
        gl_FragColor = color; 
    
    }
    ')

    public function new(){
        super();
    }
}
