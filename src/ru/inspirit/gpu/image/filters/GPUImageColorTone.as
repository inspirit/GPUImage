package ru.inspirit.gpu.image.filters
{
	import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUImageColorTone extends GPUImageFilter 
    {
        internal static const FRAGMENT_CODE:String =
                                            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                            "mul ft0.xyz, ft0.xyz, fc1.xyz                \n" +
                                            "dp3 ft1.x, ft0.xyz, fc0.xyz                \n" +
                                            "sub ft2.xyz, ft1.xxx, ft0.xyz                \n" +
                                            "mul ft2.xyz, ft2.xyz, fc1.www                \n" +
                                            "add ft0.xyz, ft0.xyz, ft2.xyz                \n" + // muted
                                            "mul ft2.xyz, fc3.xyz, ft1.xxx                \n" +
                                            "add ft2.xyz, ft2.xyz, fc2.xyz                \n" + // midle
                                            "sub ft2.xyz, ft2.xyz, ft0.xyz                \n" +
                                            "mul ft2.xyz, ft2.xyz, fc2.www                \n" +
                                            "add ft0.xyz, ft0.xyz, ft2.xyz                \n" +
                                            //
                                            "mov oc, ft0";

        protected var _params:Vector.<Number>;
        protected var _desaturation:Number;
        protected var _toned:Number;
        protected var _lightColor:uint;
        protected var _darkColor:uint;
        
        public function GPUImageColorTone(desaturation:Number = 0.2,
                                        toned:Number = 0.15,
                                        lightColor:uint = 0xFFE580,
                                        darkColor:uint = 0x338000
                                        ) 
        {
            super();
            
            _desaturation = desaturation;
            _toned = toned;
            _lightColor = lightColor;
            _darkColor = darkColor;
            
            var _lR:Number = ((lightColor >> 16) & 0xFF) / 255;
            var _lG:Number = ((lightColor >> 8) & 0xFF) / 255;
            var _lB:Number = (lightColor & 0xFF) / 255;
            
            var _dR:Number = ((darkColor >> 16) & 0xFF) / 255;
            var _dG:Number = ((darkColor >> 8) & 0xFF) / 255;
            var _dB:Number = (darkColor & 0xFF) / 255;
			
            _params =  new <Number>[
                                    0.3, 0.59, 0.11, 0,
                                    _lR, _lG, _lB, desaturation,
                                    _dR, _dG, _dB, toned,
                                    _lR-_dR, _lG-_dG, _lB-_dB, 0 
                                    ];
            //
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }
        
        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 4);
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageColorTone = new GPUImageColorTone(_desaturation, _toned, _lightColor, _darkColor);
            return copy;
        }
        
        override public function toString():String
        {
            return 'Color Tone Filter';
        }

        public function get desaturation():Number { return _desaturation; }
        public function set desaturation(value:Number):void
        {
            _desaturation = value;
            _params[7] = value;
        }

        public function get toned():Number { return _toned; }
        public function set toned(value:Number):void
        {
            _toned = value;
            _params[11] = value;
        }

        public function get lightColor():uint { return _lightColor; }
        public function set lightColor(value:uint):void
        {
            _lightColor = value;
            updateLightOptions();
        }

        public function get darkColor():uint { return _darkColor; }
        public function set darkColor(value:uint):void
        {
            _darkColor = value;
            updateLightOptions();
        }

        protected function updateLightOptions():void
        {
            var mult:Number = 1./255.;
            var _lR:Number = ((_lightColor >> 16) & 0xFF) * mult;
            var _lG:Number = ((_lightColor >> 8) & 0xFF) * mult;
            var _lB:Number = (_lightColor & 0xFF) * mult;

            var _dR:Number = ((_darkColor >> 16) & 0xFF) * mult;
            var _dG:Number = ((_darkColor >> 8) & 0xFF) * mult;
            var _dB:Number = (_darkColor & 0xFF) * mult;

            _params[4] = _lR; _params[5] = _lG; _params[6] = _lB;
            _params[8] = _dR; _params[9] = _dG; _params[10] = _dB;
            _params[12] = _lR-_dR; _params[13] = _lG-_dG; _params[14] = _lB-_dB;
        }
    }

}