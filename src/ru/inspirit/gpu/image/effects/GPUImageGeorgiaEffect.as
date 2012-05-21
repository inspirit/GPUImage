package ru.inspirit.gpu.image.effects
{
	import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * ported from LightBox sources
     * @author Eugene Zatepyakin
     */
    public final class GPUImageGeorgiaEffect extends GPUImageFilter 
    {
         internal static const FRAGMENT_CODE:String =
                                            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                            // brightness
                                            "sub ft1.xyz, fc0.www, ft0.xyz              \n" +
                                            "mul ft1.xyz, ft1.xyz, fc0.xxx              \n" +
                                            "add ft0.xyz, ft0.xyz, ft1.xyz              \n" +
                                            // contrast
                                            "sub ft0.xyz, ft0.xyz, fc0.zzz              \n" +
                                            "mul ft0.xyz, ft0.xyz, fc0.yyy              \n" +
                                            "add ft0.xyz, ft0.xyz, fc0.zzz              \n" +
                                            "min ft0.xyz, ft0.xyz, fc0.www              \n" +
                                            // compress g
                                            "mul ft0.y, ft0.y, fc1.x                    \n" +
                                            "add ft0.y, ft0.y, fc1.y                    \n" +
                                            // compress b
                                            "mul ft0.z, ft0.z, fc1.z                    \n" +
                                            "add ft0.z, ft0.z, fc1.w                    \n" +
                                            // multiply rgb
                                            "mul ft0.xyz, ft0.xyz, fc2.xyz              \n" +
                                            //out
                                            "mov oc, ft0";
                                            
        protected var _params:Vector.<Number> = new <Number>[
                                                            0.4724 / 2, // brightness
                                                            Math.tan((0.3149 + 1.) * Math.PI / 4.), // contrast
                                                            0.5, 1.0, // constants
                                                            0.87, 33 / 255, //compress green
                                                            0.439, 143 / 255,
                                                            250 / 255, 220 / 255, 175 / 255,
                                                            0
                                                            ];
        
        public function GPUImageGeorgiaEffect() 
        {
            super();
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }
        
        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 3);
        }
        
         override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageGeorgiaEffect = new GPUImageGeorgiaEffect();
            return copy;
        }
        
        override public function toString():String
        {
            return 'Georgia Filter';
        }
        
    }

}