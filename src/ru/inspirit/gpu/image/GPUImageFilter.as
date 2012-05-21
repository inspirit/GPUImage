package ru.inspirit.gpu.image
{
    import com.adobe.utils.AGALMiniAssembler;
    import flash.display3D.Context3DProgramType;
    import flash.utils.ByteArray;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.textures.TextureBase;

    public class GPUImageFilter implements IGPUImageProcessor
    {
        protected const VERTEX_TYPE:String = Context3DProgramType.VERTEX;
        protected const FRAGMENT_TYPE:String = Context3DProgramType.FRAGMENT;

        protected const DEFAULT_VERTEX_SHADER_CODE:String = "mov op, va0\n"+
                                                            "mov v0, va1";
        protected const DEFAULT_FRAGMENT_SHADER_CODE:String = "tex oc, v0, fs0 <2d,linear,mipnone,clamp>";

        protected var _vertexShader:ByteArray = null;
        protected var _fragmentShader:ByteArray = null;

        protected var _context:Context3D;
        protected var _antiAlias:int = 0;
        protected var _enableDepthAndStencil:Boolean = false; // not sure we ever may need true here
        protected var _program:Program3D;
        protected var _inputTexture:TextureBase;
        protected var _outputTexture:TextureBase;

        protected var _renderQuality:int = 4;
        protected var _textureWidth:int;
        protected var _textureHeight:int;

        protected const AGAL_DEBUG:Boolean = false;
        protected var agalCompiler:AGALMiniAssembler;

        public function GPUImageFilter()
        {
            agalCompiler = new AGALMiniAssembler(AGAL_DEBUG);
        }

        public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            var flag:int = int(_context != context) << 1;
            flag |= int(_textureWidth != textureWidth) << 2;
            flag |= int(_textureHeight != textureHeight) << 2;

            if (flag&2)
            {
                _context = context;
                buildShaderProgram(_vertexShader, _fragmentShader);
            }

            if(flag && _outputTexture)
            {
                _outputTexture.dispose();
                _outputTexture = null;
            }
            if(flag)
            {
                _textureWidth = textureWidth >> (4 - _renderQuality);
                _textureHeight = textureHeight >> (4 - _renderQuality);
                _outputTexture = _context.createTexture(_textureWidth, _textureHeight, Context3DTextureFormat.BGRA, true);
            }
        }

        public function buildShaderProgram(vertexShader:ByteArray, fragmentShader:ByteArray):void
        {
            // clean up first
            if (_program) _program.dispose();

            // Create the shader program
            _program = _context.createProgram();

            if (null == vertexShader)
            {
                _vertexShader = vertexShader = agalCompiler.assemble(VERTEX_TYPE, DEFAULT_VERTEX_SHADER_CODE, AGAL_DEBUG);
            }
            if (null == fragmentShader)
            {
                _fragmentShader = fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, DEFAULT_FRAGMENT_SHADER_CODE, AGAL_DEBUG);
            }

            _program.upload(vertexShader, fragmentShader);
        }

        public function activate():void
        {
            throw new Error("GPUImageFilter::activate Should be overwritten!");
        }

        public function deactivate():void
        {
            // clean up after yourself
        }

        public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
        {
            if(_outputTexture)
            {
                _context.setRenderToTexture(_outputTexture, _enableDepthAndStencil, _antiAlias, 0);
                _context.clear(0.0, 0.0, 0.0, 1.0);
            }

            _context.setTextureAt(0, sourceTexture || _inputTexture);

            activate();

            _context.drawTriangles(indices, 0, 2);

            deactivate();
        }

        public function dispose():void
        {
            if(_program) _program.dispose();
            if (_outputTexture) _outputTexture.dispose();

            if (_vertexShader) _vertexShader.clear();
            if (_fragmentShader) _fragmentShader.clear();

            _vertexShader = null;
            _fragmentShader = null;

            _outputTexture = null;
            _program = null;
        }

        public function disposeOutputTexture():void
        {
            if (_outputTexture) _outputTexture.dispose();
            _outputTexture = null;
        }

        public function set antiAlias(value:int):void
        {
            _antiAlias = value;
        }
        public function get antiAlias():int
        {
            return _antiAlias;
        }

        public function set enableDepthAndStencil(value:Boolean):void
        {
            _enableDepthAndStencil = value;
        }
        public function get enableDepthAndStencil():Boolean
        {
            return _enableDepthAndStencil;
        }

        public function get inputTexture():TextureBase
        {
            return _inputTexture;
        }

        public function set inputTexture(value:TextureBase):void
        {
            _inputTexture = value;
        }

        public function get outputTexture():TextureBase
        {
            return _outputTexture;
        }

        public function clone():IGPUImageProcessor
        {
            return null;
        }

        public function toString():String
        {
            return 'GPUImageFilter';
        }
    }
}
