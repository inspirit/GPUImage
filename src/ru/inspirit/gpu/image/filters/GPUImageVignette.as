package ru.inspirit.gpu.image.filters
{

    import ru.inspirit.gpu.image.IGPUImageProcessor;
    import ru.inspirit.gpu.image.GPUImageFilter;

    public final class GPUImageVignette extends GPUImageFilter
    {
        internal static const FRAGMENT_CODE:String =
                                               "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                                // distance to center
                                               "sub ft1.xy, v0.xy, fc0.zw   \n" +
                                               "mul ft1.xy, ft1.xy, ft1.xy  \n" +
                                               "add ft1.x, ft1.x, ft1.y     \n" +
                                               "sqt ft1.x, ft1.x            \n" +
                                                //smoothstep(end, start, distance);
                                                //t = clamp((x - end) / (start - end), 0.0, 1.0);
                                                // t * t * (3.0 - 2.0 * t);
                                               "sub ft1.y, ft1.x, fc0.y     \n" +
                                               "mul ft1.y, ft1.y, fc1.x     \n" +
                                               "sat ft1.y, ft1.y            \n" +
                                               "mul ft1.x, ft1.y, ft1.y     \n" +
                                               "mul ft1.z, ft1.y, fc1.y     \n" +
                                               "sub ft1.z, fc1.z, ft1.z     \n" +
                                               "mul ft1.x, ft1.x, ft1.z     \n" +
                                               "mul ft0.xyz, ft0.xyz, ft1.x \n" +
                                               // output the color
                                               "mov oc, ft0			        \n";

        protected var _vignetteData:Vector.<Number> = new <Number>[];
        protected var _start:Number = 0.3;
        protected var _end:Number = 0.75;

        public function GPUImageVignette(start:Number = 0.3, end:Number = 0.75)
        {
            super();

            _vignetteData.length = 8;
            _vignetteData[0] = _start = start;
            _vignetteData[1] = _end = end;
            // texture Center
            _vignetteData[2] = 0.5;
            _vignetteData[3] = 0.5;
            // usefull
            _vignetteData[4] = 1.0 / (start - end);
            _vignetteData[5] = 2.0;
            _vignetteData[6] = 3.0;


            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }

        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _vignetteData, 2);
        }

        public function get start():Number { return _start; }
        public function set start(value:Number):void
        {
            _vignetteData[0] = _start = value;
            _vignetteData[4] = 1.0 / (value - _end);
        }

        public function get end():Number { return _end; }
        public function set end(value:Number):void
        {
            _vignetteData[1] = _end = value;
            _vignetteData[4] = 1.0 / (_start - value);
        }

        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageVignette = new GPUImageVignette(_start, _end);
            return copy;
        }

        override public function toString():String
        {
            return 'Vignette Filter';
        }
    }
}
