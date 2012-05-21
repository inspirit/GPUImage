package ru.inspirit.gpu.image.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
	import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUImagePosterize extends GPUImageFilter 
    {
        internal static const FRAGMENT_CODE:String = 
                    "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                    "mul ft0.xyz, ft0.xyz, fc0.xyz \n" +
                    "frc ft1.xyz, ft0.xyz \n" +
                    "sub ft0.xyz, ft0.xyz, ft1.xyz \n" +
                    "div ft0.xyz, ft0.xyz, fc0.xyz \n" +
                    // output the color
                    "mov oc, ft0			    \n";
            
        protected var _params:Vector.<Number>;
        protected var _r:Number;
        protected var _g:Number;
        protected var _b:Number;
        
        public function GPUImagePosterize(R:Number = 16, G:Number = 16, B:Number = 16) 
        {
            super();
            
            _params = new Vector.<Number>();
            _params.length = 4;
            
            _params[0] = R;
            _params[1] = G;
            _params[2] = B;
            
            _r = R;
            _g = G;
            _b = B;
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }
        
        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 1);
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImagePosterize = new GPUImagePosterize(_r, _g, _b);
            return copy;
        }
        
        override public function toString():String
        {
            return 'Posterize Filter';
        }
        
        public function get r():Number { return _r; }
        public function set r(value:Number):void 
        {
            _r = value;
            _params[0] = value;
        }
        
        public function get g():Number { return _g; }
        public function set g(value:Number):void 
        {
            _g = value;
            _params[1] = value;
        }
        
        public function get b():Number { return _b; }
        public function set b(value:Number):void 
        {
            _b = value;
            _params[2] = value;
        }
        
    }

}