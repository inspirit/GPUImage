package ru.inspirit.gpu.image.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.textures.TextureBase;

    import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;

    public class GPUImageUnsharpMask extends GPUImageFilter
    {
        internal static const FRAGMENT_CODE:String =
                        "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" + // blur
                        "tex ft1, v0, fs1 <2d,linear,mipnone,clamp>	\n" + // original
                        "sub ft0.xyz, ft1.xyz, ft0.xyz              \n" +
                        "mul ft0.xyz, ft0.xyz, fc0.xxx              \n" +
                        "add ft1.xyz, ft1.xyz, ft0.xyz              \n" +
                        "mov oc, ft1";


        protected var _blurPass:GPUImageGaussianBlur;
        protected var _params:Vector.<Number>;
        protected var _originalTexture:TextureBase;

        protected var _intensity:Number;

        public function GPUImageUnsharpMask(blurSize:Number = 1.0, intensity:Number = 0.2)
        {
            super();

            _blurPass = new GPUImageGaussianBlur(blurSize, 4);
            _intensity = intensity;

            _params = new <Number>[
                                    _intensity, 0, 0, 0
                                  ];

            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }

        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            super.setup(context, textureWidth, textureHeight);
            _blurPass.setup(context, textureWidth, textureHeight);
        }

        override public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
        {
            _blurPass.process(indices, sourceTexture);

            _context.setRenderToTexture(_outputTexture, _enableDepthAndStencil, _antiAlias, 0);
            _context.clear(0.0, 0.0, 0.0, 1.0);

            _context.setTextureAt(0, _inputTexture);

            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 1);
            _context.setTextureAt(1, _originalTexture);

            _context.drawTriangles(indices, 0, 2);

            _context.setTextureAt(1, null);
        }

        override public function set inputTexture(value:TextureBase):void
        {
            _blurPass.inputTexture = value;
            _inputTexture = _blurPass.outputTexture;
            _originalTexture = value;
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
        override public function dispose():void
        {
            super.dispose();
            _blurPass.dispose();
        }

        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageUnsharpMask = new GPUImageUnsharpMask(_blurPass.blurSize, _intensity);
            return copy;
        }

        override public function toString():String
        {
            return 'Unsharp Mask Filter';
        }

        public function get intensity():Number { return _intensity; }
        public function set intensity(value:Number):void
        {
            _intensity = value;
            _params[0] = value;
        }

        public function get blurSize():Number { return _blurPass.blurSize; }
        public function set blurSize(value:Number):void
        {
            _blurPass.blurSize = value;
        }
    }
}
