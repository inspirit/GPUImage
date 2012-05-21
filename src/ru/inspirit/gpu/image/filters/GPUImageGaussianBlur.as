package ru.inspirit.gpu.image.filters
{

import flash.display3D.Context3D;
import ru.inspirit.gpu.image.IGPUImageProcessor;
import ru.inspirit.gpu.image.GPUImageTwoPassFilter;



public class GPUImageGaussianBlur extends GPUImageTwoPassFilter
{
    internal static const GAUSSIAN_SAMPLES:int = 9;

    protected var _gaussians:Vector.<Number> = new <Number>[0.05, 0.09, 0.12, 0.15, 0.18, 0.15, 0.12, 0.09, 0.05];
    protected var _paramsH:Vector.<Number>;
    protected var _paramsV:Vector.<Number>;

    protected var _invW:Number;
    protected var _invH:Number;
    protected var _blurSize:Number = 1.0;

    public function GPUImageGaussianBlur(blurSize:Number = 1.0, quality:int = 4)
    {
        super();

        _blurSize = blurSize;
        _renderQuality = Math.min(quality, 4);
        _renderQuality = Math.max(_renderQuality, 1);

        _paramsH = new <Number>[];
        _paramsV = new <Number>[];
        _paramsH.length = 12;
        _paramsV.length = 12;

        // cut repeated values
        for(var i:int = 0; i < GAUSSIAN_SAMPLES-4; ++i)
        {
            _paramsH[i+4] = _gaussians[i];
            _paramsV[i+4] = _gaussians[i];
        }
        
        _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, getFragmentCode(), AGAL_DEBUG);
    }

    override public function activate():void
    {
        _context.setProgram(_program);
        _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _paramsH, 3);
    }

    override public function activateSecondPass():void
    {
        // we dont need it since we control passes via Constants
        //_context.setProgram(_secondPassProgram);
        _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _paramsV, 3);
    }
    
    override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
    {
        super.setup(context, textureWidth, textureHeight);

        _invW = 1./textureWidth;
        _invH = 1./textureHeight;

        _paramsH[0] = _invW * _blurSize * 4.;
        _paramsH[2] = _invW * _blurSize;

        _paramsV[1] = _invH * _blurSize * 4.;
        _paramsV[3] = _invH * _blurSize;
    }

    public function get blurSize():Number { return _blurSize; }
    public function set blurSize(value:Number):void
    {
        _blurSize = value;

        _paramsH[0] = _invW * _blurSize * 4.;
        _paramsH[2] = _invW * _blurSize;

        _paramsV[1] = _invH * _blurSize * 4.;
        _paramsV[3] = _invH * _blurSize;
    }

    internal static function getFragmentCode():String
    {
        var code:String;
        
        var _gauss_regs:Vector.<String> = new Vector.<String>(9);
        _gauss_regs[0] = "fc1.x";
        _gauss_regs[1] = "fc1.y";
        _gauss_regs[2] = "fc1.z";
        _gauss_regs[3] = "fc1.w";
        _gauss_regs[4] = "fc2.x"; // cut line
        _gauss_regs[5] = "fc1.w";
        _gauss_regs[6] = "fc1.z";
        _gauss_regs[7] = "fc1.y";
        _gauss_regs[8] = "fc1.x";

        code = 		"mov ft0, v0	                                \n" +
                    "sub ft0.xy, ft0.xy, fc0.xy                     \n" +
                    "tex ft1, ft0, fs0 <2d,linear,mipnone,clamp>    \n" +
                    "mul ft1.xyz, ft1.xyz, "+_gauss_regs[0]+"       \n" +
                    "add ft0.xy, ft0.xy, fc0.zw                     \n";

        // Calculate the positions for the blur
        //-4, -3, -2, -1, 0, 1, 2, 3, 4

        for (var i:int = 1; i < GAUSSIAN_SAMPLES-1; ++i)
        {

            code +=             "tex ft2, ft0, fs0 <2d,linear,mipnone,clamp>    \n" +
                                "mul ft2.xyz, ft2.xyz, "+_gauss_regs[i]+"       \n" +
                                "add ft1, ft1, ft2                              \n" +
                                "add ft0.xy, ft0.xy, fc0.zw                     \n";
        }

        code +=             "tex ft2, ft0, fs0 <2d,linear,mipnone,clamp>    \n" +
                            "mul ft2.xyz, ft2.xyz, " + _gauss_regs[8] + "   \n" +
                            "add oc, ft1, ft2                               \n";

        return code;
    }
    
    override public function clone():IGPUImageProcessor
    {
        var copy:GPUImageGaussianBlur = new GPUImageGaussianBlur(_blurSize, _renderQuality);
        return copy;
    }
    
    override public function toString():String
    {
        return 'Gaussian Blur Filter';
    }

    /*
    uniform float sigma;     // The sigma value for the gaussian function: higher value means more blur
                         // A good value for 9x9 is around 3 to 5
                         // A good value for 7x7 is around 2.5 to 4
                         // A good value for 5x5 is around 2 to 3.5
                         // ... play around with this based on what you need :)

uniform float blurSize;  // This should usually be equal to
                         // 1.0f / texture_pixel_width for a horizontal blur, and
                         // 1.0f / texture_pixel_height for a vertical blur.

uniform sampler2D blurSampler;  // Texture that will be blurred by this shader

const float pi = 3.14159265f;

// The following are all mutually exclusive macros for various
// seperable blurs of varying kernel size
#if defined(VERTICAL_BLUR_9)
const float numBlurPixelsPerSide = 4.0f;
const vec2  blurMultiplyVec      = vec2(0.0f, 1.0f);
#elif defined(HORIZONTAL_BLUR_9)
const float numBlurPixelsPerSide = 4.0f;
const vec2  blurMultiplyVec      = vec2(1.0f, 0.0f);
#elif defined(VERTICAL_BLUR_7)
const float numBlurPixelsPerSide = 3.0f;
const vec2  blurMultiplyVec      = vec2(0.0f, 1.0f);
#elif defined(HORIZONTAL_BLUR_7)
const float numBlurPixelsPerSide = 3.0f;
const vec2  blurMultiplyVec      = vec2(1.0f, 0.0f);
#elif defined(VERTICAL_BLUR_5)
const float numBlurPixelsPerSide = 2.0f;
const vec2  blurMultiplyVec      = vec2(0.0f, 1.0f);
#elif defined(HORIZONTAL_BLUR_5)
const float numBlurPixelsPerSide = 2.0f;
const vec2  blurMultiplyVec      = vec2(1.0f, 0.0f);
#else
// This only exists to get this shader to compile when no macros are defined
const float numBlurPixelsPerSide = 0.0f;
const vec2  blurMultiplyVec      = vec2(0.0f, 0.0f);
#endif

void main() {

  // Incremental Gaussian Coefficent Calculation (See GPU Gems 3 pp. 877 - 889)
  vec3 incrementalGaussian;
  incrementalGaussian.x = 1.0f / (sqrt(2.0f * pi) * sigma);
  incrementalGaussian.y = exp(-0.5f / (sigma * sigma));
  incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

  vec4 avgValue = vec4(0.0f, 0.0f, 0.0f, 0.0f);
  float coefficientSum = 0.0f;

  // Take the central sample first...
  avgValue += texture2D(blurSampler, gl_TexCoord[0].xy) * incrementalGaussian.x;
  coefficientSum += incrementalGaussian.x;
  incrementalGaussian.xy *= incrementalGaussian.yz;

  // Go through the remaining 8 vertical samples (4 on each side of the center)
  for (float i = 1.0f; i <= numBlurPixelsPerSide; i++) {
    avgValue += texture2D(blurSampler, gl_TexCoord[0].xy - i * blurSize *
                          blurMultiplyVec) * incrementalGaussian.x;
    avgValue += texture2D(blurSampler, gl_TexCoord[0].xy + i * blurSize *
                          blurMultiplyVec) * incrementalGaussian.x;
    coefficientSum += 2 * incrementalGaussian.x;
    incrementalGaussian.xy *= incrementalGaussian.yz;
  }

  gl_FragColor = avgValue / coefficientSum;
}
     */
}
}
