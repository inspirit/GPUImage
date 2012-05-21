package ru.inspirit.gpu.image.effects
{
    import ru.inspirit.gpu.image.filters.*;
    import flash.display3D.Context3D;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.textures.TextureBase;

    import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;

    // ported from LightBox sources
    public final class GPUImageHDREffect extends GPUImageFilter
    {
        internal static const FRAGMENT_CODE:String =
                "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" + // blur
                "tex ft1, v0, fs1 <2d,linear,mipnone,clamp>	\n" + // original
                "sub ft0.xyz, fc0.www, ft0.xyz               \n" +
                "add ft0.xyz, ft1.xyz, ft0.xyz               \n" +
                "sub ft0.xyz, ft0.xyz, fc1.yyy               \n" +
                "sat ft0.xyz, ft0.xyz                        \n" +
                // boost original saturation
                "dp3 ft2.x, ft1.xyz, fc0.xyz                \n" +
                "sub ft1.xyz, ft1.xyz, ft2.xxx                \n" +
                "mul ft1.xyz, ft1.xyz, fc1.xxx                \n" +
                "add ft1.xyz, ft1.xyz, ft2.xxx                \n" +
                // merge result
                "add ft0.xyz, ft0.xyz, ft1.xyz               \n" +
                "sub ft0.xyz, ft0.xyz, fc1.yyy               \n" +
                "mov oc, ft0";

        protected var _saturation:Number;
        protected var _blurPass:GPUImageGaussianBlur;
        protected var _originalTexture:TextureBase;

        protected var _params:Vector.<Number>;

        public function GPUImageHDREffect(saturation:Number = 1.3, blurSize:Number = 7)
        {
            super();

            _blurPass = new GPUImageGaussianBlur(blurSize, 4);
            _saturation = saturation;

            _params = new <Number>[
                                    0.2125, 0.7154, 0.0721, 1.0,
                                    _saturation, 0.5, 0, 0];

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
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 2);
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
            var copy:GPUImageHDREffect = new GPUImageHDREffect(_saturation, _blurPass.blurSize);
            return copy;
        }

        override public function toString():String
        {
            return 'HDR Filter';
        }

        public function get saturation():Number { return _saturation; }
        public function set saturation(value:Number):void
        {
            _saturation = value;
            _params[4] = value;
        }

        public function get blurSize():Number { return _blurPass.blurSize; }
        public function set blurSize(value:Number):void
        {
            _blurPass.blurSize = value;
        }
    }
}
