package ru.inspirit.gpu.image.filters
{
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

import ru.inspirit.gpu.image.IGPUImageProcessor;

import ru.inspirit.gpu.image.GPUImageTwoPassFilter;

public class GPUImageSobelEdges extends GPUImageTwoPassFilter
{
    internal static const FRAGMENT_CODE:String =
            "sub ft3.xy, v0.xy, fc1.xy        \n"+//topLeftTextureCoordinate
            "tex ft4, ft3.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
            "mov ft0.x, ft4.x\n" +
            "sub ft3.xy, v0.xy, fc0.zw        \n"+//topTextureCoordinate
            "tex ft4, ft3.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
            "mov ft0.y, ft4.x\n" +
            "add ft3.xy, v0.xy, fc1.zw        \n"+//topRightTextureCoordinate
            "tex ft4, ft3.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
            "mov ft0.z, ft4.x\n" +
            "sub ft3.xy, v0.xy, fc0.xy         \n" +//leftTextureCoordinate
            "tex ft4, ft3.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
            "mov ft1.x, ft4.x\n" +
            "add ft3.xy, v0.xy, fc0.xy         \n" + //rightTextureCoordinate
            "tex ft4, ft3.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
            "mov ft1.z, ft4.x\n" +
            "sub ft3.xy, v0.xy, fc1.zw        \n"+//bottomLeftTextureCoordinate
            "tex ft4, ft3.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
            "mov ft2.x, ft4.x\n" +
            "add ft3.xy, v0.xy, fc0.zw        \n"+//bottomTextureCoordinate
            "tex ft4, ft3.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
            "mov ft2.y, ft4.x\n" +
            "add ft3.xy, v0.xy, fc1.xy        \n"+//bottomRightTextureCoordinate
            "tex ft4, ft3.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
            "mov ft2.z, ft4.x\n" +
            //
            "neg ft0.x, ft0.x  \n" +
            "mul ft0.y, ft0.y, fc2.x \n" +
            "sub ft3.x, ft0.x, ft0.y \n" +
            "sub ft3.x, ft3.x, ft0.z \n" +
            "add ft3.x, ft3.x, ft2.x \n" +
            "add ft3.x, ft3.x, ft2.z \n" +
            "mul ft2.y, ft2.y, fc2.x \n" +
            "add ft3.x, ft3.x, ft2.y \n" + // H
            //
            "neg ft2.x, ft2.x  \n" +
            "mul ft1.x, ft1.x, fc2.x \n" +
            "sub ft3.y, ft2.x, ft1.x \n" +
            "add ft3.y, ft3.y, ft0.x \n" +
            "add ft3.y, ft3.y, ft2.z \n" +
            "mul ft1.z, ft1.z, fc2.x \n" +
            "add ft3.y, ft3.y, ft1.z \n" +
            "add ft3.y, ft3.y, ft0.z \n" + // V
            //
            "mul ft3.x, ft3.x, ft3.x \n" +
            "mul ft3.y, ft3.y, ft3.y \n" +
            "add ft3.x, ft3.x, ft3.y \n" +
            "sqt ft3.x, ft3.x \n" + // magnintude
            "sub ft3.x, ft3.x, fc2.y    \n" +
            "mul ft3.x, ft3.x, fc2.z    \n" +
            //"sub ft3.x, fc2.z, ft3.x \n" +
            //"sge ft3.x, ft3.x, fc2.y \n" +
            "mov ft4.xyz, ft3.xxx \n" +
           // output the color
           "mov oc, ft4			    \n";

    protected var _grayscaleParams:Vector.<Number> = new <Number>[0.2125, 0.7154, 0.0721, 0.];
    protected var _sobelParams:Vector.<Number>;

    protected var _invW:Number;
    protected var _invH:Number;

    protected var _threshold:Number;

    public function GPUImageSobelEdges(threshold:Number = 0.1)
    {
        super();

        _sobelParams = new Vector.<Number>();
        _sobelParams.length = 12;

        _sobelParams[8] = 2.0;
        _sobelParams[9] = threshold;
        _sobelParams[10] = 1./(1.-threshold);

        _threshold = threshold;
                
        _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, GPUImageGrayscale.FRAGMENT_CODE, AGAL_DEBUG);
        //
        _fragmentShader2 = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
    }

    override public function activate():void
    {
        _context.setProgram(_program);
        _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _grayscaleParams, 1);
    }

    override public function activateSecondPass():void
    {
        _context.setProgram(_secondPassProgram);
        _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _sobelParams, 3);
    }

    override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
    {
        super.setup(context, textureWidth, textureHeight);

        _invW = 1./textureWidth;
        _invH = 1./textureHeight;

        _sobelParams[0] = _invW;
        _sobelParams[1] = 0.;

        _sobelParams[2] = 0.;
        _sobelParams[3] = _invH;

        _sobelParams[4] = _invW;
        _sobelParams[5] = _invH;

        _sobelParams[6] = _invW;
        _sobelParams[7] = -_invH;
    }

    override public function clone():IGPUImageProcessor
    {
        var copy:GPUImageSobelEdges = new GPUImageSobelEdges(_threshold);
        return copy;
    }

    override public function toString():String
    {
        return 'Sobel Edges Filter';
    }
    
    public function get threshold():Number { return _threshold; }
    public function set threshold(value:Number):void 
    {
        _threshold = value;
        _sobelParams[9] = value;
        _sobelParams[10] = 1./(1.-value);
    }
}
}
