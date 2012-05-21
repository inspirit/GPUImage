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
    public final class GPUImageTiltShiftEffect extends GPUImageFilter
    {
        //smoothstep(topFocusLevel - focusFallOffRate, topFocusLevel, textureCoordinate.y)
        //smoothstep(edge0, edge1, x);
        //t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
        //return t * t * (3.0 - 2.0 * t);
        internal static const FRAGMENT_CODE:String =
                //
                "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" + // blur
                "tex ft1, v0, fs1 <2d,linear,mipnone,clamp>	\n" + // original
                // calc blur intensity
                "sub ft2.x, v0.y, fc0.x                     \n" +
                "mul ft2.x, ft2.x, fc0.y                    \n" +
                "sat ft2.x, ft2.x                           \n" +
                "mul ft2.y, ft2.x, fc1.y                    \n" +
                "sub ft2.y, fc1.z, ft2.y                    \n" +
                "mul ft2.x, ft2.x, ft2.x                    \n" +
                "mul ft2.z, ft2.x, ft2.y                    \n" +
                "sub ft2.z, fc1.x, ft2.z                    \n" + // blur intensity .z
                // another smoothstep
                // smoothstep(bottomFocusLevel, bottomFocusLevel + focusFallOffRate, textureCoordinate.y);
                "sub ft2.x, v0.y, fc0.z                     \n" +
                "mul ft2.x, ft2.x, fc0.w                    \n" +
                "sat ft2.x, ft2.x                           \n" + 
                "mul ft2.y, ft2.x, fc1.y                    \n" +
                "sub ft2.y, fc1.z, ft2.y                    \n" +
                "mul ft2.x, ft2.x, ft2.x                    \n" +
                "mul ft2.w, ft2.x, ft2.y                    \n" +
                "add ft2.w, ft2.z, ft2.w                    \n" + // blur intensity .w
                // mix(original, blur, blurIntensity);
                // mix(x, y, s); // x  + s * (y - x);
                "sub ft3, ft0, ft1              \n" + 
                "mul ft3, ft3, ft2.w            \n" + 
                "add oc, ft1, ft3               \n";
                
        
        protected var _params:Vector.<Number>;
        protected var _topFocusLevel:Number;
        protected var _bottomFocusLevel:Number;
        protected var _focusFallOffRate:Number;
        protected var _secondTexture:TextureBase;
        
        protected var _blurPass:GPUImageGaussianBlur;
        protected var _blurRadius:Number;
        
        public function GPUImageTiltShiftEffect(blurRadius:Number = 2,
                                                topFocusLevel:Number = 0.4, 
                                                bottomFocusLevel:Number = 0.6, 
                                                focusFallOffRate:Number = 0.2) 
        {
            super();
			
            _blurPass = new GPUImageGaussianBlur(blurRadius, 4);
            //_blurPass = new GPUImageFastBlur(blurRadius, 2, 4);

            _blurRadius = blurRadius;
            _topFocusLevel = topFocusLevel;
            _bottomFocusLevel = bottomFocusLevel;
            _focusFallOffRate = focusFallOffRate;
            
            _params = new <Number>[ 
                                  topFocusLevel - focusFallOffRate, 
                                  1. / (topFocusLevel - (topFocusLevel - focusFallOffRate)),
                                  bottomFocusLevel, 
                                  1. / focusFallOffRate,
                                  1, 2, 3, 0
                                  ];
            //
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }

        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            super.setup(context, textureWidth, textureHeight);
            _blurPass.setup(context, textureWidth, textureHeight);
        }
        
        override public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
        {
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
            _blurPass.inputTexture = value;
            _inputTexture = _blurPass.outputTexture;
            _secondTexture = value;
        }
        override public function set antiAlias(value:int):void
        {
            _antiAlias = value;
            _blurPass.antiAlias = value;
        }
        override public function set enableDepthAndStencil(value:Boolean):void
        {
            _enableDepthAndStencil = value;
            _blurPass.enableDepthAndStencil = value;
        }
        
        public function get blurRadius():Number { return _blurRadius; }
        public function set blurRadius(value:Number):void 
        {
            _blurRadius = value;
            _blurPass.blurSize = value;
        }
        
        public function get topFocusLevel():Number { return _topFocusLevel; }
        public function set topFocusLevel(value:Number):void 
        {
            _topFocusLevel = value;
            _params[0] = value - _focusFallOffRate;
            _params[1] = 1. / (value - (value - _focusFallOffRate));
        }
        
        public function get bottomFocusLevel():Number { return _bottomFocusLevel; }
        public function set bottomFocusLevel(value:Number):void 
        {
            _params[2] = _bottomFocusLevel = value;
        }
        
        public function get focusFallOffRate():Number { return _focusFallOffRate; }
        public function set focusFallOffRate(value:Number):void 
        {
            _focusFallOffRate = value;
            _params[0] = _topFocusLevel - _focusFallOffRate;
            _params[1] = 1. / (_topFocusLevel - (_topFocusLevel - _focusFallOffRate));
            _params[3] = 1. / _focusFallOffRate;
        }
        
        override public function dispose():void 
        {
            super.dispose();
            _blurPass.dispose();
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageTiltShiftEffect = new GPUImageTiltShiftEffect(_blurRadius,
                                                                           _topFocusLevel, 
                                                                           _bottomFocusLevel,
                                                                           _focusFallOffRate);
            return copy;
        }
        
        override public function toString():String
        {
            return 'Tilt-Shift Effect';
        }
        
    }

}