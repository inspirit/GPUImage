package ru.inspirit.gpu.image.effects
{
    import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;

    // ported from LightBox sources
    public class GPUImageRetroEffect extends GPUImageFilter
    {
        internal static const FRAGMENT_CODE:String =
                        "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                        "dp3 ft2.x, ft0.xyz, fc0.xyz                \n" +
                        // overlay grey
                        "sub ft3.xyz, fc0.www, ft2.xxx  \n" +
                        "sub ft4.xyz, fc0.www, ft0.xyz  \n" +
                        "mul ft3.xyz, ft3.xyz, ft4.xyz  \n" +
                        "add ft3.xyz, ft3.xyz, ft3.xyz  \n" +
                        "sub ft3.xyz, fc0.www, ft3.xyz  \n" +
                        "mul ft4.xyz, ft2.xxx, ft0.xyz  \n" +
                        "add ft4.xyz, ft4.xyz, ft4.xyz  \n" +
                        "sge ft1.xyz, ft0.xyz, fc1.www  \n" +
                        "slt ft5.xyz, ft0.xyz, fc1.www  \n" +
                        "mul ft1.xyz, ft1.xyz, ft3.xyz  \n" +
                        "mul ft5.xyz, ft5.xyz, ft4.xyz  \n" +
                        "add ft1.xyz, ft1.xyz, ft5.xyz  \n" + // overlay result
                        // multiply
                        "mul ft1.xyz, ft1.xyz, fc1.xyz  \n" +
                        // screen
                        "sub ft1.xyz, fc0.www, ft1.xyz  \n" +
                        "mul ft1.xyz, fc2.xyz, ft1.xyz  \n" +
                        "sub ft1.xyz, fc0.www, ft1.xyz  \n" +
                        // screen
                        "sub ft1.xyz, fc0.www, ft1.xyz  \n" +
                        "mul ft1.xyz, fc3.xyz, ft1.xyz  \n" +
                        "sub ft1.xyz, fc0.www, ft1.xyz  \n" +
                        //out
                        "mov ft0.xyz, ft1.xyz           \n" +
                        "mov oc, ft0";

        protected var _params:Vector.<Number> = new <Number>[
                                0.3, 0.59, 0.11, 1.0,
                                251/255*0.588235, 242/255*0.588235, 163/255*0.588235, 0.5,
                                1.-(232/255*0.2), 1.-(101/255*0.2), 1.-(179/255*0.2), 0,
                                1.-(9/255*0.168627), 1.-(73/255*0.168627), 1.-(233/255*0.168627), 0
                                ];

        public function GPUImageRetroEffect()
        {
            super();

            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }

        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 4);
        }

        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageRetroEffect = new GPUImageRetroEffect();
            return copy;
        }

        override public function toString():String
        {
            return 'Retro Effect';
        }
    }
}
