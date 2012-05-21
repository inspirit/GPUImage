package ru.inspirit.gpu.image.filters
{

import ru.inspirit.gpu.image.GPUImageFilter;

public final class GPUImageToScreen extends GPUImageFilter
{
    internal static const VERTEX_CODE:String =
                            // Initial position
                            "mov vt0, va0                 \n" +

                            // Rotate (about Z, like this...)
                            //   x' = x*cos(rot) - y*sin(rot)
                            //   y' = x*sin(rot) + y*cos(rot)
                            "mul vt1.xy, va0.xy, vc1.yx   \n" +
                            "sub vt0.x, vt1.x, vt1.y      \n" +
                            "mul vt1.xy, va0.xy, vc1.xy   \n" +
                            "add vt0.y, vt1.x, vt1.y      \n" +

                            // Scale
                            "mul vt0.xy, vt0.xy, vc0.zw   \n" +

                            // Translate
                            "add vt0.xy, vt0.xy, vc0.xy   \n" +

                            // Output position
                            "mov op, vt0                  \n" +

                            // Copy texture coordinate to varying
                            "mov v0, va1                  \n";

    protected var _params:Vector.<Number>;

    public function GPUImageToScreen()
    {
        super();

        // x, y,  scaleX, scaleY, rotationSin, rotationCos
        _params = new <Number>[0., 0., 1., 1., 0., 1., 0, 0];
        
        
        _vertexShader = agalCompiler.assemble(VERTEX_TYPE, VERTEX_CODE, AGAL_DEBUG);
    }

    public function transformImage(x:Number,  y:Number, 
                                   scaleX:Number, scaleY:Number,
                                   rotationSin:Number,  rotationCos:Number):void
    {
        _params[0] = x;
        _params[1] = y;
        _params[2] = scaleX;
        _params[3] = scaleY;
        _params[4] = rotationSin;
        _params[5] = rotationCos;
    }

    override public function activate():void
    {
        _context.setProgram(_program);
        _context.setProgramConstantsFromVector(VERTEX_TYPE, 0, _params, 2);
    }
}
}
