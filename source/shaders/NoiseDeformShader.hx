package shaders;

import flixel.FlxBasic;
import flixel.system.FlxAssets.FlxShader;

class NoiseDeformShader extends FlxBasic
{
    public var shader:NoiseDeformShaderGLSL = new NoiseDeformShaderGLSL();

    public function new():Void
    {
        super();
        shader.iTime.value = [0];
        shader.strength.value = [0.02]; // Control distortion strength
        shader.scale.value = [5.0]; // Noise scale/frequency
        shader.speedX.value = [0.5]; // Animation speed X
        shader.speedY.value = [0.3]; // Animation speed Y
        shader.alphaThreshold.value = [0.001]; // Minimum alpha to process
        shader.octaves.value = [5]; // Number of noise octaves
        shader.persistence.value = [0.85]; // Octave amplitude decay
        shader.lacunarity.value = [-3.0]; // Octave frequency multiplier
    }

    override function update(elapsed:Float):Void
    {
        shader.iTime.value[0] += elapsed;
    }

    // Helper methods to control all effects
    public function setStrength(value:Float):Void
    {
        shader.strength.value[0] = value;
    }

    public function setScale(value:Float):Void
    {
        shader.scale.value[0] = value;
    }

    public function setSpeed(x:Float, y:Float):Void
    {
        shader.speedX.value[0] = x;
        shader.speedY.value[0] = y;
    }

    public function setSpeedX(value:Float):Void
    {
        shader.speedX.value[0] = value;
    }

    public function setSpeedY(value:Float):Void
    {
        shader.speedY.value[0] = value;
    }

    public function setAlphaThreshold(value:Float):Void
    {
        shader.alphaThreshold.value[0] = value;
    }

    public function setOctaves(value:Int):Void
    {
        shader.octaves.value[0] = value;
    }

    public function setPersistence(value:Float):Void
    {
        shader.persistence.value[0] = value;
    }

    public function setLacunarity(value:Float):Void
    {
        shader.lacunarity.value[0] = value;
    }
}

class NoiseDeformShaderGLSL extends FlxShader
{
    @:glFragmentSource('
#pragma header
uniform float iTime;
uniform float strength;
uniform float scale;
uniform float speedX;
uniform float speedY;
uniform float alphaThreshold;
uniform int octaves;
uniform float persistence;
uniform float lacunarity;

// Simplex 2D noise
vec3 permute(vec3 x){return mod(((x*34.)+1.)*x,289.);}
const vec2 pSize = vec2(1.0,1.0);
float snoise(vec2 v){
    const vec4 C=vec4(.211324865405187,.366025403784439,
    -.577350269189626,.024390243902439);
    vec2 i=floor(v+dot(v,C.yy));
    vec2 x0=v-i+dot(i,C.xx);
    vec2 i1;
    i1=(x0.x>x0.y)?vec2(1.,0.):vec2(0.,1.);
    vec4 x12=x0.xyxy+C.xxzz;
    x12.xy-=i1;
    i=mod(i,289.);
    vec3 p=permute(permute(i.y+vec3(0.,i1.y,1.))
    +i.x+vec3(0.,i1.x,1.));
    vec3 m=max(.5-vec3(dot(x0,x0),dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)),0.);
    m=m*m;
    m=m*m;
    vec3 x=2.*fract(p*C.www)-1.;
    vec3 h=abs(x)-.5;
    vec3 ox=floor(x+.5);
    vec3 a0=x-ox;
    m*=1.79284291400159-.85373472095314*(a0*a0+h*h);
    vec3 g;
    g.x=a0.x*x0.x+h.x*x0.y;
    g.yz=a0.yz*x12.xz+h.yz*x12.yw;
    return 130.*dot(m,g);
}

float snoise_octaves(vec2 uv, vec2 speed_vec, float offset){
    vec2 pos = uv * scale;
    float t = 1.;
    float s = 1.;
    vec2 q = iTime * speed_vec + offset;
    float r = 0.;
    
    // Use dynamic octaves but cap at reasonable limit for performance
    int max_octaves = (octaves < 8) ? octaves : 8;
    
    for(int i = 0; i < max_octaves; i++){
        r += s * snoise(pos + q);
        pos += t * uv * scale;
        t *= lacunarity;
        s *= persistence;
        q *= 1.203; // Fixed multiplier to avoid uniform patterns
    }
    return r;
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
    
    // First, sample the original texture to get the base alpha
    vec4 originalColor = flixel_texture2D(bitmap, uv);
    
    // If the original pixel is essentially transparent, skip distortion
    if (originalColor.a < alphaThreshold) {
        gl_FragColor = originalColor;
        return;
    }
    
    // Calculate distortion using configurable parameters
    vec2 speedVec = vec2(speedX, speedY);
    float dx = strength * 0.01 * snoise_octaves(uv, speedVec * 0.5, 0.0);
    float dy = strength * 0.01 * snoise_octaves(uv, speedVec * 0.7, 100.0);
    
    vec2 distortedUV = uv + vec2(dx, dy);
    
    // Check bounds to prevent sampling outside texture
    if (distortedUV.x < 0.0 || distortedUV.x > 1.0 || 
        distortedUV.y < 0.0 || distortedUV.y > 1.0) {
        // For out-of-bounds, either use original color or make transparent
        gl_FragColor = vec4(originalColor.rgb, originalColor.a * 0.5);
        return;
    }
    
    // Apply pixelation effect (optional - remove these lines for smooth distortion)
    vec2 size = openfl_TextureSize.xy / pSize;
    vec2 pixelatedUV = floor(distortedUV * size) / size;
    
    // Sample the distorted texture
    vec4 distortedColor = flixel_texture2D(bitmap, pixelatedUV);
    
    // Preserve alpha behavior
    float finalAlpha = distortedColor.a;
    
    gl_FragColor = vec4(distortedColor.rgb, finalAlpha);
}
    ')

    public function new()
    {
       super();
    }
}
