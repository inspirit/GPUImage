package ru.inspirit.gpu.image.effects
{
    import ru.inspirit.gpu.image.filters.*;
    import flash.display3D.Context3D;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.textures.TextureBase;

    import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUImageBloomEffect extends GPUImageFilter
    {
        public static const PRESET_DEFAULT:String = 'bloom_default';
        public static const PRESET_SOFT:String = 'bloom_soft';
        public static const PRESET_DESATURATED:String = 'bloom_desaturated';
        public static const PRESET_SATURATED:String = 'bloom_saturated';
        public static const PRESET_BLURRY:String = 'bloom_blurry';
        public static const PRESET_SUBTLE:String = 'bloom_subtle';
        
        // lerp(grey, color, saturation)
        // lerp(x, y, s)
        //  x + s * (y-x)
        protected const FRAGMENT_CODE:String = 
                //
                "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" + // bloom
                "tex ft1, v0, fs1 <2d,linear,mipnone,clamp>	\n" + // original
                // Adjust bloom saturation and intensity.
                "dp3 ft2.x, ft0.xyz, fc0.xyz                \n" +
                "sub ft3.xyz, ft0.xyz, ft2.xxx              \n" +
                "mul ft3.xyz, ft3.xyz, fc1.zzz              \n" +
                "add ft3.xyz, ft3.xyz, ft2.xxx              \n" +
                "mul ft0.xyz, ft3.xyz, fc1.xxx              \n" +
                // Adjust original saturation and intensity.
                "dp3 ft2.x, ft1.xyz, fc0.xyz                \n" +
                "sub ft3.xyz, ft1.xyz, ft2.xxx              \n" +
                "mul ft3.xyz, ft3.xyz, fc1.www              \n" +
                "add ft3.xyz, ft3.xyz, ft2.xxx              \n" +
                "mul ft1.xyz, ft3.xyz, fc1.yyy              \n" +
                // Darken down the base image in areas where there is a lot of bloom,
                // to prevent things looking excessively burned-out.
                "sat ft2.xyz, ft0.xyz                       \n" +
                "sub ft2.xyz, fc0.www, ft2.xyz              \n" +
                "mul ft1.xyz, ft1.xyz, ft2.xyz              \n" +
                "add oc, ft0, ft1              \n";
                //        
        
        protected var _params:Vector.<Number>;
        
        // Controls the amount of the bloom and base images that
        // will be mixed into the final scene. Range 0 to 1.
        protected var _bloomIntensity:Number = 1.0;
        protected var _baseIntensity:Number = 0.1;
        //
        // Independently control the color saturation of the bloom and
        // base images. Zero is totally desaturated, 1.0 leaves saturation
        // unchanged, while higher values increase the saturation level.
        protected var _bloomSaturation:Number = 1.0;
        protected var _baseSaturation:Number = 1.0;
        protected var _blurQuality:int = 4;
        protected var _secondTexture:TextureBase;

        protected var _brightPass:GPUImageBrightPass;
        protected var _blurPass:GPUImageGaussianBlur;
        
        // Table of preset bloom settings, used by the sample program.
        /*
            //                Name           Thresh  Blur Bloom  Base  BloomSat BaseSat
            new BloomSettings("Default",     0.25f,  4,   1.25f, 1,    1,       1),
            new BloomSettings("Soft",        0,      3,   1,     1,    1,       1),
            new BloomSettings("Desaturated", 0.5f,   8,   2,     1,    0,       1),
            new BloomSettings("Saturated",   0.25f,  4,   2,     1,    2,       0),
            new BloomSettings("Blurry",      0,      2,   1,     0.1f, 1,       1),
            new BloomSettings("Subtle",      0.5f,   2,   1,     1,    1,       1),
        */
        
        public function GPUImageBloomEffect(preset:String = PRESET_DEFAULT,
                                            blurQuality:int = 3) 
        {
            super();
            
            _brightPass = new GPUImageBrightPass(0.25);
            //_blurPass = new GPUImageFastBlur(4, 4, blurQuality);
            _blurPass = new GPUImageGaussianBlur(4, blurQuality);

            _blurQuality = blurQuality;
            
            _params = Vector.<Number>([ 0.3, 0.59, 0.11, 1, 0, 0, 0, 0 ]);
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
            
            initPreset(preset);
        }

        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            super.setup(context, textureWidth, textureHeight);
            _brightPass.setup(context, textureWidth, textureHeight);
            _blurPass.setup(context, textureWidth, textureHeight);
        }
        
        override public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
        {
            _brightPass.process(indices, sourceTexture);
            _blurPass.process(indices);

            _context.setRenderToTexture(_outputTexture, _enableDepthAndStencil, _antiAlias, 0);
            _context.clear(0.0, 0.0, 0.0, 1.0);

            _context.setTextureAt(0, _inputTexture);

            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 2);
            _context.setTextureAt(1, _secondTexture);

            _context.drawTriangles(indices, 0, 2);

            _context.setTextureAt(1, null);
        }
        
        override public function set inputTexture(value:TextureBase):void
        {
            _brightPass.inputTexture = value;
            _blurPass.inputTexture = _brightPass.outputTexture;
            _inputTexture = _blurPass.outputTexture;
            _secondTexture = value;
        }

        override public function set antiAlias(value:int):void
        {
            _antiAlias = value;
            _blurPass.antiAlias = value;
            _brightPass.antiAlias = value;
        }
        override public function set enableDepthAndStencil(value:Boolean):void
        {
            _enableDepthAndStencil = value;
            _blurPass.enableDepthAndStencil = value;
            _brightPass.enableDepthAndStencil = value;
        }
        
        public function initPreset(preset:String):void
        {
            switch(preset)
            {
                case PRESET_DEFAULT:
                    brightThresh = 0.25;
                    blurRadius = 4;
                    bloomIntensity = 1.25;
                    baseIntensity = 1.;
                    bloomSaturation = 1.;
                    baseSaturation = 1.;
                    break;
                case PRESET_SOFT:
                    brightThresh = 0.0;
                    blurRadius = 3;
                    bloomIntensity = 1.;
                    baseIntensity = 1.;
                    bloomSaturation = 1.;
                    baseSaturation = 1.;
                    break;
                case PRESET_DESATURATED:
                    brightThresh = 0.5;
                    blurRadius = 8;
                    bloomIntensity = 2.;
                    baseIntensity = 1.;
                    bloomSaturation = 0.;
                    baseSaturation = 1.;
                    break;
                case PRESET_SATURATED:
                    brightThresh = 0.25;
                    blurRadius = 4;
                    bloomIntensity = 2.;
                    baseIntensity = 1.;
                    bloomSaturation = 2.;
                    baseSaturation = 0.;
                    break;
                case PRESET_BLURRY:
                    brightThresh = 0.;
                    blurRadius = 2;
                    bloomIntensity = 1.;
                    baseIntensity = 0.1;
                    bloomSaturation = 1.;
                    baseSaturation = 1.;
                    break;
                case PRESET_SUBTLE:
                    brightThresh = 0.5;
                    blurRadius = 2;
                    bloomIntensity = 1.;
                    baseIntensity = 1.;
                    bloomSaturation = 1.;
                    baseSaturation = 1.;
                    break;
                default:
                    initPreset(PRESET_DEFAULT);
                    break;
            }
        }
        
        public function get bloomIntensity():Number  { return _bloomIntensity; }
        public function set bloomIntensity(value:Number):void 
        {
            _bloomIntensity = value;
            _params[4] = value;
        }
        
        public function get baseIntensity():Number { return _baseIntensity; }
        public function set baseIntensity(value:Number):void 
        {
            _baseIntensity = value;
            _params[5] = value;
        }
        
        public function get bloomSaturation():Number { return _bloomSaturation; }
        public function set bloomSaturation(value:Number):void 
        {
            _bloomSaturation = value;
            _params[6] = value;
        }
        
        public function get baseSaturation():Number { return _baseSaturation; }
        public function set baseSaturation(value:Number):void 
        {
            _baseSaturation = value;
            _params[7] = value;
        }
        
        public function get brightThresh():Number { return _brightPass.threshold; }
        public function set brightThresh(value:Number):void 
        {
            _brightPass.threshold = value;
        }
        
        public function get blurRadius():Number { return _blurPass.blurSize; }
        public function set blurRadius(value:Number):void 
        {
            _blurPass.blurSize = value;
        }
        
        override public function dispose():void 
        {
            super.dispose();
            _blurPass.dispose();
            _brightPass.dispose();
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageBloomEffect = new GPUImageBloomEffect(PRESET_DEFAULT, _blurQuality);
            copy.bloomIntensity = _bloomIntensity;
            copy.baseIntensity = _baseIntensity;
            copy.bloomSaturation = _bloomSaturation;
            copy.baseSaturation = _baseSaturation;
            copy.brightThresh = brightThresh;
            copy.blurRadius = blurRadius;
            return copy;
        }
        
        override public function toString():String
        {
            return 'Bloom Effect';
        }
        
    }

}