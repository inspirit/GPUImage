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
    public final class GPUImageToonEffect extends GPUImageFilter
    {
        internal static const FRAGMENT_CODE:String =
                //
                "tex ft0, v0, fs1 <2d,linear,mipnone,clamp>	\n" + // original blured or not
                // quantize
                "mul ft0.xyz, ft0.xyz, fc2.xxx \n" +
                "frc ft2.xyz, ft0.xyz          \n" +
                "sub ft0.xyz, ft0.xyz, ft2.xyz \n" +
                "div ft0.xyz, ft0.xyz, fc2.xxx \n" +                
                // adjust brightness
                "add ft0.xyz, ft0.xyz, fc1.xxx \n" +
                // adjust contrast
                "sub ft0.xyz, ft0.xyz, fc0.www \n" +
                "mul ft0.xyz, ft0.xyz, fc1.yyy \n" +
                "add ft0.xyz, ft0.xyz, fc0.www \n" +
                // desaturate with percentage
                "dp3 ft1.xyz, ft0.xyz, fc0.xyz      \n" +
                "mul ft2.xyz, ft0.xyz, fc1.www      \n" +
                "mul ft1.xyz, ft1.xyz, fc1.zzz      \n" +
                "add ft1.xyz, ft1.xyz, ft2.xyz      \n" +
                // mult edges and color
                "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" + // edges
                "sub ft0.xyz, fc2.www, ft0.xyz              \n" + // invert edges
                //"sge ft0.xyz, ft0.xyz, fc2.yyy \n" +
                "mult ft0.xyz, ft0.xyz, ft1.xyz            \n" +
                "mov oc, ft0";
        
        protected var _params:Vector.<Number>;
        
        protected var _blurSize:Number;
        protected var _edgesThreshold:Number;
        protected var _quantizationLevels:Number;
        protected var _brightness:Number;
        protected var _contrast:Number;
        protected var _grayscale:Number;
        protected var _secondTexture:TextureBase;
        
        protected var _blurPass:GPUImageGaussianBlur;
        protected var _edgesPass:GPUImageSobelEdges;

        public function GPUImageToonEffect(     blurSize:Number = 1.0,
                                                quantizationLevels:Number = 10,
                                                edgesThreshold:Number = 0.2,
                                                brightness:Number = 0.13,
                                                contrast:Number = 0.2,
                                                grayscale:Number = 0.15)
        {
            super();

            _blurPass = new GPUImageGaussianBlur(blurSize, 4);
            _edgesPass = new GPUImageSobelEdges(edgesThreshold);

            _blurSize = blurSize;
            _quantizationLevels = quantizationLevels;
            _edgesThreshold = edgesThreshold;
            _brightness = brightness;
            _contrast = contrast;
            _grayscale = grayscale;

            _params = Vector.<Number>([
                                        0.2125, 0.7154, 0.0721, 0.5,
                                        brightness, contrast + 1, grayscale, 1.0 - grayscale,
                                        quantizationLevels, 0, 0, 1.0
                                        ]);

            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }

        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            super.setup(context, textureWidth, textureHeight);
            _blurPass.setup(context, textureWidth, textureHeight);
            _edgesPass.setup(context, textureWidth, textureHeight);
        }

        override public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
        {
            _blurPass.process(indices);
            _edgesPass.process(indices);

            _context.setRenderToTexture(_outputTexture, _enableDepthAndStencil, _antiAlias, 0);
            _context.clear(0.0, 0.0, 0.0, 1.0);

            _context.setTextureAt(0, _inputTexture);

            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 3);
            _context.setTextureAt(1, _secondTexture);

            _context.drawTriangles(indices, 0, 2);

            _context.setTextureAt(1, null);
        }
        
        override public function set inputTexture(value:TextureBase):void
        {
            _blurPass.inputTexture = value;
            _edgesPass.inputTexture = value;
            _inputTexture = _edgesPass.outputTexture;
            _secondTexture = _blurPass.outputTexture;
        }

        override public function set antiAlias(value:int):void
        {
            _antiAlias = value;
            _blurPass.antiAlias = value;
            _edgesPass.antiAlias = value;
        }
        override public function set enableDepthAndStencil(value:Boolean):void
        {
            _enableDepthAndStencil = value;
            _blurPass.enableDepthAndStencil = value;
            _edgesPass.enableDepthAndStencil = value;
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageToonEffect = new GPUImageToonEffect(_blurSize,
                                                                 _quantizationLevels,
                                                                 _edgesThreshold,
                                                                 _brightness,
                                                                 _contrast,
                                                                 _grayscale);
            return copy;
        }
        
        override public function dispose():void 
        {
            super.dispose();
            _blurPass.dispose();
            _edgesPass.dispose();
        }
        
        override public function toString():String
        {
            return 'Toon Effect';
        }

        public function get blurSize():Number { return _blurSize; }
        public function set blurSize(value:Number):void
        {
            _blurSize = value;
            _blurPass.blurSize = value;
        }

        public function get edgesThreshold():Number { return _edgesThreshold; }
        public function set edgesThreshold(value:Number):void
        {
            _edgesThreshold = value;
            _edgesPass.threshold = value;
        }

        public function get quantizationLevels():Number { return _quantizationLevels; }
        public function set quantizationLevels(value:Number):void
        {
            _quantizationLevels = value;
            _params[8] = value;
        }

        public function get brightness():Number { return _brightness; }
        public function set brightness(value:Number):void
        {
            _brightness = value;
            _params[4] = value;
        }

        public function get contrast():Number { return _contrast; }
        public function set contrast(value:Number):void
        {
            _contrast = value;
            _params[5] = value + 1.;
        }

        public function get grayscale():Number { return _grayscale; }
        public function set grayscale(value:Number):void
        {
            _grayscale = value;
            _params[6] = value;
            _params[7] = 1.0 - value;
        }
    }

}