package ru.inspirit.gpu.image.filters
{
    import com.adobe.utils.AGALMiniAssembler;
    import ru.inspirit.gpu.image.IGPUImageProcessor;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;

    import ru.inspirit.gpu.image.GPUImageFilter;

    public final class GPUImageGrayscale extends GPUImageFilter
    {
        internal static const FRAGMENT_CODE:String =
                                                "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                                "dp3 ft0.xyz, ft0.xyz, fc0.xyz                \n" +
                                                "mov oc, ft0";

        protected var _params:Vector.<Number> = new <Number>[0.2125, 0.7154, 0.0721, 0.];

        public function GPUImageGrayscale()
        {
            super();
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }

        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 1);
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageGrayscale = new GPUImageGrayscale();
            return copy;
        }
        
        override public function toString():String
        {
            return 'Grayscale Filter';
        }
    }
}
