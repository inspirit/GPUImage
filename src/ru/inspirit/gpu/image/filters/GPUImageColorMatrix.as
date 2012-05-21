package ru.inspirit.gpu.image.filters
{
import ru.inspirit.gpu.image.IGPUImageProcessor;
import flash.geom.Matrix3D;

import ru.inspirit.gpu.image.GPUImageFilter;

public class GPUImageColorMatrix extends GPUImageFilter
{
    internal static const FRAGMENT_CODE:String = "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                               "mov ft1, ft0       \n" +
                                               "m44 ft1, ft1, fc0       \n" +
                                               "mov ft0.xyz, ft1.xyz       \n" +
                                               //"add ft0, ft0, fc4       \n" +
                                               // output the color
                                               "mov oc, ft0			    \n";

    protected var _matrix:Matrix3D = new Matrix3D();
    protected var _temp:Matrix3D = new Matrix3D();
    protected var _hue_data:Vector.<Number>;
    protected var _saturation_data:Vector.<Number>;
    protected var _contrast_data:Vector.<Number>;
    protected var _brightness_data:Vector.<Number>;

    protected var _saturation:Number;
    protected var _contrast:Number;
    protected var _brightness:Number;
    protected var _hue:Number;

    public function GPUImageColorMatrix()
    {
        super();
        //
        _matrix.identity();

        _hue_data = new <Number>[1,0,0,0,  0,1,0,0,  0,0,1,0,  0,0,0,1];
        _saturation_data = _hue_data.concat();
        _contrast_data = _hue_data.concat();
        _brightness_data = _hue_data.concat();

        _hue = 0;
        _saturation = 1;
        _brightness = 1;
        _contrast = 1;

        _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
    }

    override public function activate():void
    {
        _context.setProgram(_program);
        _context.setProgramConstantsFromMatrix(FRAGMENT_TYPE, 0, _matrix, false);
    }

    public function setColorMatrix(matrixData:Vector.<Number>):void
    {
        _matrix.copyRawDataFrom(matrixData);
    }
    
    override public function clone():IGPUImageProcessor
    {
        var copy:GPUImageColorMatrix = new GPUImageColorMatrix();
        copy.setColorMatrix(_matrix.rawData);
        return copy;
    }
    
    override public function toString():String
    {
        return 'ColorMatrix Filter';
    }

    protected function updateMatrix():void
    {
        _matrix.copyRawDataFrom(_brightness_data);
        _temp.copyRawDataFrom(_contrast_data);
        _matrix.append(_temp);
        _temp.copyRawDataFrom(_saturation_data);
        _matrix.append(_temp);
        _temp.copyRawDataFrom(_hue_data);
        _matrix.append(_temp);
    }

    public function get saturation():Number { return _saturation; }
    public function set saturation(value:Number):void
    {
        if(value != _saturation)
        {
            _saturation = value;

            const inv:Number = 1.0 - value;
            const rwgt:Number = 0.3086 * inv;
            const gwgt:Number = 0.6094 * inv;
            const bwgt:Number = 0.0820 * inv;

            _saturation_data[0] = rwgt + value;
            _saturation_data[1] = gwgt; _saturation_data[2] = bwgt;

            _saturation_data[5] = gwgt + value;
            _saturation_data[4] = rwgt; _saturation_data[6] = bwgt;

            _saturation_data[10] = bwgt + value;
            _saturation_data[8] = rwgt; _saturation_data[9] = gwgt;

            updateMatrix();
        }
    }

    public function get contrast():Number { return _contrast; }
    public function set contrast(value:Number):void
    {
        if(value != _contrast)
        {
            _contrast = value;

            _contrast_data[0] = value;
            _contrast_data[5] = value;
            _contrast_data[10] = value;

            const off:Number = (1.0 - value) * 0.5;
            _contrast_data[12] = off;
            _contrast_data[13] = off;
            _contrast_data[14] = off;

            updateMatrix();
        }
    }

    public function get brightness():Number { return _brightness; }
    public function set brightness(value:Number):void
    {
        if(_brightness != value)
        {
            _brightness = value;

            _brightness_data[0] = value;
            _brightness_data[5] = value;
            _brightness_data[10] = value;

            updateMatrix();
        }
    }

    public function get hue():Number { return _hue; }
    public function set hue(value:Number):void
    {
        if(_hue != value)
        {
            _hue = value;

            const ang:Number = value * 0.017453292519943295;
            const s:Number = Math.sin(ang);
            const c:Number = Math.cos(ang);
            const c1:Number = 1.0 - c;
            const ds:Number = 0.5773502691896258 * s;
            const ddc1:Number = 0.3333333333333334 * c1;

            // probably should be transposed
            _hue_data[0] = ddc1 + c;
            _hue_data[1] = ddc1 + ds;
            _hue_data[2] = ddc1 - ds;

            _hue_data[4] = ddc1 - ds;
            _hue_data[5] = ddc1 + c;
            _hue_data[6] = ddc1 + ds;

            _hue_data[8] = ddc1 + ds;
            _hue_data[9] = ddc1 - ds;
            _hue_data[10] = ddc1 + c;

            updateMatrix();
        }
    }
}
}
