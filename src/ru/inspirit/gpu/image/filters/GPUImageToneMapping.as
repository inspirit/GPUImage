package ru.inspirit.gpu.image.filters
{
	import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUImageToneMapping extends GPUImageFilter 
    {
        internal static const FRAGMENT_CODE:String =
                                            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                            "sub ft1.xyz, ft0.xyz, fc0.xyz              \n" +
                                            "max ft1.xyz, ft1.xyz, fc3.yyy              \n" +
                                            "mul ft1.xyz, ft1.xyz, fc0.www              \n" +
                                            "pow ft1.xyz, ft1.xyz, fc1.xxx              \n" +
                                            // vignette
                                            "sub ft2.xy, v0.xy, fc1.zw              \n" +
                                            "mul ft2.xy, ft2.xy, ft2.xy              \n" +
                                            "add ft2.x, ft2.x, ft2.y              \n" +
                                            "sub ft2.x, fc3.x, ft2.x              \n" +
                                            "pow ft2.x, ft2.x, fc3.z              \n" +
                                            "mul ft2.x, ft2.x, fc2.x              \n" +
                                            "add ft1.xyz, ft1.xyz, ft2.xxx              \n" +
                                            // blueshift  x + s*(y-x)
                                            "mul ft2.xyz, ft1.xyz, fc2.yzw              \n" +
                                            "sub ft2.xyz, ft2.xyz, ft1.xyz              \n" +
                                            "mul ft2.xyz, ft2.xyz, fc1.yyy              \n" +
                                            "add ft0.xyz, ft2.xyz, ft1.xyz              \n" +
                                            //
                                            "mov oc, ft0";

        protected var _params:Vector.<Number>;
        protected var _exposure:Number;
        protected var _defog:Number;
        protected var _gamma:Number;
        protected var _fogColor:uint;
        protected var _fogR:Number;
        protected var _fogG:Number;
        protected var _fogB:Number;
        protected var _vignetteRadius:Number;
        protected var _vignetteCenterX:Number;
        protected var _vignetteCenterY:Number;
        protected var _blueShift:Number;

        public function GPUImageToneMapping(exposure:Number = 0,
                                            defog:Number = 0.1,
                                            gamma:Number = 0.454545,
                                            fogColor:uint = 0xFFFFFF,
                                            vignetteRadius:Number = 0.35,
                                            vignetteCenterX:Number = 0.5,
                                            vignetteCenterY:Number = 0.5,
                                            blueShift:Number = 0.7
                                            ) 
        {
            super();

            _exposure = exposure;
            _defog = defog;
            _gamma = gamma;
            _fogColor = fogColor;
            _fogR = ((fogColor >> 16) & 0xFF) / 255;
            _fogG = ((fogColor >> 8) & 0xFF) / 255;
            _fogB = (fogColor & 0xFF) / 255;
            _vignetteRadius = vignetteRadius;
            _vignetteCenterX = vignetteCenterX;
            _vignetteCenterY = vignetteCenterY;
            _blueShift = blueShift;
            
            _params = Vector.<Number>([
                                            _fogR* defog, _fogG* defog, _fogB* defog, Math.pow(2., exposure),
                                            gamma, blueShift, vignetteCenterX, vignetteCenterY,
                                            vignetteRadius, 1.05, 0.97, 1.27,
                                            1.0, 0.0, 4.0, 0.0
                                            ]);
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }
        
        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 4);
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageToneMapping = new GPUImageToneMapping();
            return copy;
        }
        
        override public function toString():String
        {
            return 'ToneMapping Filter';
        }

        public function get exposure():Number { return _exposure; }
        public function set exposure(value:Number):void
        {
            _exposure = value;
            _params[3] = Math.pow(2., value);
        }

        public function get gamma():Number { return _gamma; }
        public function set gamma(value:Number):void
        {
            _gamma = value;
            _params[4] = value;
        }

        public function get defog():Number { return _defog; }
        public function set defog(value:Number):void
        {
            _defog = value;
            _params[0] = _fogR* value;
            _params[1] = _fogG* value;
            _params[2] = _fogB* value;
        }

        public function get fogColor():uint { return _fogColor; }
        public function set fogColor(value:uint):void
        {
            _fogColor = value;
            _fogR = ((value >> 16) & 0xFF) / 255;
            _fogG = ((value >> 8) & 0xFF) / 255;
            _fogB = (value & 0xFF) / 255;
            _params[0] = _fogR* _defog;
            _params[1] = _fogG* _defog;
            _params[2] = _fogB* _defog;
        }

        public function get vignetteRadius():Number { return _vignetteRadius; }
        public function set vignetteRadius(value:Number):void
        {
            _vignetteRadius = value;
            _params[8] = value;
        }

        public function get vignetteCenterX():Number { return _vignetteCenterX; }
        public function set vignetteCenterX(value:Number):void
        {
            _vignetteCenterX = value;
            _params[6] = value;
        }

        public function get vignetteCenterY():Number { return _vignetteCenterY; }
        public function set vignetteCenterY(value:Number):void
        {
            _vignetteCenterY = value;
            _params[7] = value;
        }

        public function get blueShift():Number { return _blueShift; }
        public function set blueShift(value:Number):void
        {
            _blueShift = value;
            _params[5] = value;
        }
    }

}