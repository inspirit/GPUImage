package ru.inspirit.gpu.image.filters
{
    import flash.display3D.Context3D;
	import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public class GPUImage3x3Convolution extends GPUImageFilter 
    {

        internal static const FRAGMENT_CODE:String = 
                                               "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                               "mul ft0, ft0, fc1.y                                 \n" +
                                               "sub ft2.xy, v0.xy, fc3.xy         \n" +//leftTextureCoordinate
                                               "tex ft1, ft2.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
                                               "mul ft1, ft1, fc1.x                                 \n" +
                                               "add ft0, ft0, ft1                                   \n" +
                                               "add ft2.xy, v0.xy, fc3.xy         \n" + //rightTextureCoordinate
                                               "tex ft1, ft2.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
                                               "mul ft1, ft1, fc1.z                                 \n" +
                                               "add ft0, ft0, ft1                                   \n" +
                                               "sub ft2.xy, v0.xy, fc3.zw        \n"+//topTextureCoordinate
                                               "tex ft1, ft2.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
                                               "mul ft1, ft1, fc0.y                                 \n" +
                                               "add ft0, ft0, ft1                                   \n" +
                                               "sub ft2.xy, v0.xy, fc4.xy        \n"+//topLeftTextureCoordinate
                                               "tex ft1, ft2.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
                                               "mul ft1, ft1, fc0.x                                 \n" +
                                               "add ft0, ft0, ft1                                   \n" +
                                               "add ft2.xy, v0.xy, fc4.zw        \n"+//topRightTextureCoordinate
                                               "tex ft1, ft2.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
                                               "mul ft1, ft1, fc0.z                                 \n" +
                                               "add ft0, ft0, ft1                                   \n" +
                                               "add ft2.xy, v0.xy, fc3.zw        \n"+//bottomTextureCoordinate
                                               "tex ft1, ft2.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
                                               "mul ft1, ft1, fc2.y                                 \n" +
                                               "add ft0, ft0, ft1                                   \n" +
                                               "sub ft2.xy, v0.xy, fc4.zw        \n"+//bottomLeftTextureCoordinate
                                               "tex ft1, ft2.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
                                               "mul ft1, ft1, fc2.x                                 \n" +
                                               "add ft0, ft0, ft1                                   \n" +
                                               "add ft2.xy, v0.xy, fc4.xy        \n"+//bottomRightTextureCoordinate
                                               "tex ft1, ft2.xy, fs0 <2d,linear,mipnone,clamp>	    \n" +
                                               "mul ft1, ft1, fc2.z                                 \n" +
                                               "add ft0, ft0, ft1                                   \n" +
                                               // output the color
                                               "mov oc, ft0			    \n";

        protected var _fragmentParams:Vector.<Number>;
        protected var _inputMatrix:Vector.<Number>;
        protected var _invW:Number;
        protected var _invH:Number;
        
        public function GPUImage3x3Convolution(convolutionMatrix:Vector.<Number>) 
        {
            super();

            _fragmentParams = new Vector.<Number>();
            _fragmentParams.length = 20;
            
            setConvolutionMatrix(convolutionMatrix);
            // fc3 // offsets
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }
        
        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _fragmentParams, 5);
        }
        
        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            super.setup(context, textureWidth, textureHeight);

            _invW = 1./textureWidth;
            _invH = 1./textureHeight;

            _fragmentParams[12] = _invW;
            _fragmentParams[13] = 0.;
            
            _fragmentParams[14] = 0.;
            _fragmentParams[15] = _invH;
            
            _fragmentParams[16] = _invW;
            _fragmentParams[17] = _invH;
            
            _fragmentParams[18] = _invW;
            _fragmentParams[19] = -_invH;
        }

        public function setConvolutionMatrix(matrix:Vector.<Number>):void
        {
            // fc0
            _fragmentParams[0] = matrix[0];
            _fragmentParams[1] = matrix[1];
            _fragmentParams[2] = matrix[2];
            // fc1
            _fragmentParams[4] = matrix[3];
            _fragmentParams[5] = matrix[4];
            _fragmentParams[6] = matrix[5];
            // fc2
            _fragmentParams[8] = matrix[6];
            _fragmentParams[9] = matrix[7];
            _fragmentParams[10] = matrix[8];
            //
            _inputMatrix = matrix.concat();
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImage3x3Convolution = new GPUImage3x3Convolution(_inputMatrix);
            return copy;
        }
        
        override public function toString():String
        {
            return 'Emboss Filter';
        }
        
    }

}