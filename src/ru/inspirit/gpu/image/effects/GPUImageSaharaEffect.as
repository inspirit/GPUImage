package ru.inspirit.gpu.image.effects
{
    import ru.inspirit.gpu.image.filters.*;
    import flash.display3D.Context3D;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.textures.TextureBase;

    import ru.inspirit.gpu.image.GPUImageTwoPassFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;

    // ported from LightBox sources
    public class GPUImageSaharaEffect extends GPUImageTwoPassFilter
    {
        internal static const FRAGMENT_CODE_0:String =
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
                    // compress r
                        "mul ft0.x, ft0.x, fc1.x                    \n" +
                        "add ft0.x, ft0.x, fc1.y                    \n" +
                    // compress b
                        "mul ft0.z, ft0.z, fc1.z                    \n" +
                        "add ft0.z, ft0.z, fc1.w                    \n" +
                    // saturation
                        "dp3 ft2.x, ft0.xyz, fc2.yzw                \n" +
                        "sub ft0.xyz, ft0.xyz, ft2.xxx                \n" +
                        "mul ft0.xyz, ft0.xyz, fc2.xxx                \n" +
                        "add ft0.xyz, ft0.xyz, ft2.xxx                \n" +
                    //out
                        "mov oc, ft0";

        internal static const FRAGMENT_CODE_1:String =
                         "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" + // original
                         "tex ft2, v0, fs1 <2d,linear,mipnone,clamp>	\n" + // blur
                         // overlay
                         "sub ft3.xyz, fc0.www, ft2.xyz  \n" +
                         "sub ft4.xyz, fc0.www, ft0.xyz  \n" +
                         "mul ft3.xyz, ft3.xyz, ft4.xyz  \n" +
                         "add ft3.xyz, ft3.xyz, ft3.xyz  \n" +
                         "sub ft3.xyz, fc0.www, ft3.xyz  \n" +
                         "mul ft4.xyz, ft2.xyz, ft0.xyz  \n" +
                         "add ft4.xyz, ft4.xyz, ft4.xyz  \n" +
                         "sge ft1.xyz, ft0.xyz, fc1.www  \n" +
                         "slt ft5.xyz, ft0.xyz, fc1.www  \n" +
                         "mul ft1.xyz, ft1.xyz, ft3.xyz  \n" +
                         "mul ft5.xyz, ft5.xyz, ft4.xyz  \n" +
                         "add ft1.xyz, ft1.xyz, ft5.xyz  \n" + // done
                         "mul ft0.xyz, ft1.xyz, fc0.xyz  \n" +
                         //
                         //out
                         "mov oc, ft0";

        protected var _blurPass:GPUImageGaussianBlur;
        protected var _blurTexture:TextureBase;
        protected var _params0:Vector.<Number> = new <Number>[
                                                            0.45 / 2, // brightness
                                                            Math.tan((0.1 + 1.) * Math.PI / 4.), // contrast
                                                            0.5, 1.0, // constants
                                                            0.8431, 40 / 255, // compress red
                                                            0.8823, 30 / 255, // blue
                                                            0.65, // saturation
                                                            0.2125, 0.7154, 0.0721
                                                        ];
        protected var _params1:Vector.<Number> = new <Number>[
                                                            255/255, 227/255, 187/255, 1.0,
                                                            0, 0, 0, 0.5
                                                        ];

        public function GPUImageSaharaEffect()
        {
            super();

            _blurPass = new GPUImageGaussianBlur(1, 4);

            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE_0, AGAL_DEBUG);
            _fragmentShader2 = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE_1, AGAL_DEBUG);
        }

        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            super.setup(context, textureWidth, textureHeight);
            _blurPass.setup(context, textureWidth, textureHeight);
        }

        override public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
        {
            // FIRST PASS
            _context.setRenderToTexture(_secondPassTexture, _enableDepthAndStencil, _antiAlias, 0);
            _context.clear(0.0, 0.0, 0.0, 1.0);

            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params0, 3);

            _context.setTextureAt(0, sourceTexture || _inputTexture);

            _context.drawTriangles(indices, 0, 2);

            // blur pass
            _blurPass.process(indices, _secondPassTexture);

            // SECOND PASS
            _context.setRenderToTexture(_outputTexture, _enableDepthAndStencil, _antiAlias, 0);
            _context.clear(0.0, 0.0, 0.0, 1.0);

            _context.setProgram(_secondPassProgram);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params1, 2);

            _context.setTextureAt(0, _secondPassTexture);
            _context.setTextureAt(1, _blurTexture);

            _context.drawTriangles(indices, 0, 2);

            _context.setTextureAt(1, null);
        }

        override public function set inputTexture(value:TextureBase):void
        {
            _blurPass.inputTexture = _secondPassTexture;
            _inputTexture = value;
            _blurTexture = _blurPass.outputTexture;
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
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageSaharaEffect = new GPUImageSaharaEffect();
            return copy;
        }

        override public function toString():String
        {
            return 'Sahara Filter';
        }
        override public function dispose():void
        {
            super.dispose();
            _blurPass.dispose();
        }
    }
}
