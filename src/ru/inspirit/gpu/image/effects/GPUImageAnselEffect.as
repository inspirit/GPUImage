package ru.inspirit.gpu.image.effects
{
	import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * ported from LightBox sources
     * @author Eugene Zatepyakin
     */
    public final class GPUImageAnselEffect extends GPUImageFilter 
    {
        internal static const FRAGMENT_CODE:String =
                                            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                            "dp3 ft2.x, ft0.xyz, fc0.xyz                \n" +
                                            "dp3 ft0.x, ft2.xxx, fc0.xyz                \n" +
                                            "mov ft2.x, ft0.x                       \n" +
                                            
                                            // hardlight
                                            "sub ft3.x, fc0.w, ft2.x  \n" +
                                            "sub ft4.x, fc0.w, ft0.x  \n" +
                                            "mul ft3.x, ft3.x, ft4.x  \n" +
                                            "add ft3.x, ft3.x, ft3.x  \n" +
                                            "sub ft3.x, fc0.w, ft3.x  \n" +
                                            "mul ft4.x, ft2.x, ft0.x  \n" +
                                            "add ft4.x, ft4.x, ft4.x  \n" +
                                            "sge ft1.x, ft0.x, fc1.z  \n" +
                                            "slt ft5.x, ft0.x, fc1.z  \n" +
                                            "mul ft1.x, ft1.x, ft3.x  \n" +
                                            "mul ft5.x, ft5.x, ft4.x  \n" +
                                            "add ft1.x, ft1.x, ft5.x  \n" + 
     
                                            "mov ft0.xyz, ft1.xxx                       \n" +
                                            //
                                            //out
                                            "mov oc, ft0";
                                            
        protected var _params:Vector.<Number> = new <Number>[0.3, 0.59, 0.11, 1.0, 0.0, 0, 0.5, 0];
        
        public function GPUImageAnselEffect() 
        {
            super();
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }
        
        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 2);
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageAnselEffect = new GPUImageAnselEffect();
            return copy;
        }
        
        override public function toString():String
        {
            return 'Ansel Effect';
        }
        
    }

}