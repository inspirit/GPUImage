package ru.inspirit.gpu.image.filters
{

    import ru.inspirit.gpu.image.IGPUImageProcessor;

    import flash.display3D.Context3D;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.textures.TextureBase;

    import ru.inspirit.gpu.image.GPUImageTwoPassFilter;

    public final class GPUImageFastBlur extends GPUImageTwoPassFilter
    {
        //   Code based on http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
        
        internal static const FRAGMENT_CODE:String =
                            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>    \n" +
                            "mul ft0.xyz, ft0.xyz, fc1.y                    \n" +
                            "sub ft1.xy, v0.xy, fc0.xy                      \n" +
                            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp>    \n" +
                            "mul ft2.xyz, ft2.xyz, fc1.z                    \n" +
                            "add ft0, ft0, ft2                              \n" +
                            //
                            "add ft1.xy, v0.xy, fc0.xy                      \n" +
                            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp>    \n" +
                            "mul ft2.xyz, ft2.xyz, fc1.z                    \n" +
                            "add ft0, ft0, ft2                              \n" +
                            //
                            "sub ft1.xy, v0.xy, fc0.zw                      \n" +
                            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp>    \n" +
                            "mul ft2.xyz, ft2.xyz, fc1.w                    \n" +
                            "add ft0, ft0, ft2                              \n" +
                            //
                            "add ft1.xy, v0.xy, fc0.zw                      \n" +
                            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp>    \n" +
                            "mul ft2.xyz, ft2.xyz, fc1.w                    \n" +
                            "add oc, ft0, ft2                              \n";

        protected var _paramsH:Vector.<Number>;
        protected var _paramsV:Vector.<Number>;

        protected var _invW:Number;
        protected var _invH:Number;
        protected var _blurSize:Number = 1.0;
        protected var _numIterations:int = 1;
        protected var _setProgram:Boolean = true;

        public function GPUImageFastBlur(blurSize:Number, numIterations:int = 1, quality:int = 4)
        {
            super();

            _blurSize = blurSize;
            _renderQuality = Math.min(quality, 4);
            _renderQuality = Math.max(_renderQuality, 1);
            _numIterations = numIterations;

            _paramsH = new <Number>[0, 0, 0, 0, 0, 0.2270270270, 0.3162162162, 0.0702702703];
            _paramsV = new <Number>[0, 0, 0, 0, 0, 0.2270270270, 0.3162162162, 0.0702702703];
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }

        override public function activate():void
        {
            if (_setProgram)
            {
                _context.setProgram(_program);
            }
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _paramsV, 2);
        }

        override public function activateSecondPass():void
        {
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _paramsH, 2);
        }

        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            super.setup(context, textureWidth, textureHeight);

            _invW = 1./textureWidth;
            _invH = 1./textureHeight;

            _paramsH[0] = _invW * 1.3846153846 * _blurSize;
            _paramsH[2] = _invW * 3.2307692308 * _blurSize;

            _paramsV[1] = _invH * 1.3846153846 * _blurSize;
            _paramsV[3] = _invH * 3.2307692308 * _blurSize;
        }

        override public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
        {
            _setProgram = true;
            super.process(indices, sourceTexture);
            _setProgram = false;

            for(var i:int = 1; i < _numIterations; ++i)
            {
                super.process(indices, _outputTexture);
            }
        }

        public function get blurSize():Number { return _blurSize; }
        public function set blurSize(value:Number):void
        {
            _blurSize = value;

            _paramsH[0] = _invW * 1.3846153846 * _blurSize;
            _paramsH[2] = _invW * 3.2307692308 * _blurSize;

            _paramsV[1] = _invH * 1.3846153846 * _blurSize;
            _paramsV[3] = _invH * 3.2307692308 * _blurSize;
        }

        public function get numIterations():int { return _numIterations; }
        public function set numIterations(value:int):void
        {
            _numIterations = value;
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageFastBlur = new GPUImageFastBlur(_blurSize, _renderQuality);
            copy.numIterations = _numIterations;
            return copy;
        }
        
        override public function toString():String
        {
            return 'Fast Blur Filter';
        }
    }
}
