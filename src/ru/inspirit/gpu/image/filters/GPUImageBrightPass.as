package ru.inspirit.gpu.image.filters
{
import com.adobe.utils.AGALMiniAssembler;
import ru.inspirit.gpu.image.IGPUImageProcessor;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

import ru.inspirit.gpu.image.GPUImageFilter;

public final class GPUImageBrightPass extends GPUImageFilter
{
    internal static const FRAGMENT_CODE:String = 
                                            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                            //"dp3 ft1.x, ft0.xyz, fc0.xyz    \n" +
                                            "sub ft0.xyz, ft0.xyz, fc0.xxx    \n" +
                                            "mul ft0.xyz, ft0.xyz, fc0.yyy    \n" +
                                            "sat ft0, ft0           \n" +
                                            //"mov ft0.xyz, ft1.xxx		\n" +
                                            "mov oc, ft0				\n";

    protected var _threshold:Number;
    protected var _params:Vector.<Number>;

    public function GPUImageBrightPass(threshold:Number = .75)
    {
        super();

        _threshold = threshold;

        //_params = Vector.<Number>([ 0.2125, 0.7154, 0.0721, threshold, 1./(1.-threshold), 0, 0, 0 ]);
        _params = Vector.<Number>([ threshold, 1./(1.-threshold), 0, 0 ]);

        _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
    }

    override public function activate():void
    {
        _context.setProgram(_program);
        _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 1);
    }

    public function get threshold():Number { return _threshold; }
    public function set threshold(value:Number):void
    {
        _params[0] = _threshold = value;
        _params[1] = 1./(1.-value);
    }
    
    override public function clone():IGPUImageProcessor
    {
        var copy:GPUImageBrightPass = new GPUImageBrightPass(_threshold);
        return copy;
    }
    
    override public function toString():String
    {
        return 'BrightPass Filter';
    }
}
}
