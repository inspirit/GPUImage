package ru.inspirit.gpu.image.effects
{
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.textures.TextureBase;
	import ru.inspirit.gpu.image.filters.*;
	import ru.inspirit.gpu.image.GPUImageFilter;
	import ru.inspirit.gpu.image.IGPUImageProcessor;

	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUImageNoiseEffect extends GPUImageFilter
    {
        internal static const FRAGMENT_CODE:String =
                //
				"mov ft0, v0.xy         	                \n" + // get uv coords
                "sub ft0.zw, ft0.xy, fc0.xy                 \n" + // ft0.zw = outCoord() - fc0.xy
                "div ft0.xy, ft0.xy, fc0.zw                 \n" + // ft0.xy = ft0.xy / wh
                
				// frc(u*u + v*v) -> ft1.x
				"mul ft1.x, ft0.x, ft0.x                    \n" + //ft1.x = ft0.x * ft0.x;
				"mul ft1.y, ft0.y, ft0.y                    \n" + //ft1.y = ft0.y * ft0.y;
				"add ft1.x, ft1.x, ft1.y                    \n" + // 
				"frc ft1.x, ft1.x							\n" + //
				
				//x
				"cos ft0.x, ft0.x							\n" +
				"rcp ft0.y, ft1.y							\n" + // 1.0 / ft1.y
				"mul ft0.x, ft0.x, ft1.y					\n" +
				
				//y
				"sin ft0.y, ft0.z							\n" +
				"div ft0.z, ft1.y, ft1.x					\n" + 
				"mul ft0.y, ft0.y, ft0.z					\n" +
				
				"mul ft0.xy, ft0.xy, fc0.zw	                \n" + // scale
				"add ft0.xy, ft0.xy, fc0.xy	                \n" + // offset
				
				"tex ft0.xyz, ft0.yx, fs0.xyz <2d,nearest,repeat,mipnone>\n" 	+ // sample using noise uv into ft0
				"mul ft0.xyz, ft0.xyz, fc1.x                \n" 				+ // noise (amount) mult
				
				"tex ft1, v0.xy, fs0 <2d,nearest,repeat,mipnone>\n" + // sample input texture into ft1
				"mul ft1.xyz, ft1.xyz, fc1.y                \n" 	+ // texture (amount) mult
				
				"add ft0.xyz, ft0.zxy, ft1.xyz           	\n" + // add + mult noise over texture
				"mul ft0.xyz, ft0.xyz, ft1.xyz           	\n" + // 
				
				// ft0 now contains the sampled texture data + the psuedo noise
                "mov oc, ft0                                \n";  	// move to output
				
        
        protected var _params:Vector.<Number>;
		
        protected var _textureMult:Number;
        protected var _noiseMult:Number;
        
		private var _invWidth:Number;
		private var _invHeight:Number;

        public function GPUImageNoiseEffect(noiseAmount:Number=0.5, textureAmount:Number=1.0)
        {
            super();
			
			_textureMult	= textureAmount;
			_noiseMult		= noiseAmount;
			
			_params 		= Vector.<Number>([0, 0, 0, 0, 0, 0, 0, 0]);
			_params.fixed 	= true;
			
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }

        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void {
			_invWidth  = 1.0 / textureWidth;
			_invHeight = 1.0 / textureHeight;
			super.setup(context, textureWidth, textureHeight);
        }

        override public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
        {
			_context.setRenderToTexture(_outputTexture, _enableDepthAndStencil, _antiAlias, 0);
            _context.clear(0.0, 0.0, 0.0, 1.0);
			
            _context.setTextureAt(0, _inputTexture);
			
			_params[0] 	= 1e-3 + Math.random() * _textureWidth;
			_params[1] 	= 1e-3 + Math.random() * _textureHeight;
			_params[2] 	= 1e-3 + Math.random() * _invWidth;
			_params[3] 	= 1e-3 + Math.random() * _invHeight;
			
			_params[4] 	= _noiseMult; // noise amount
			_params[5] 	= _textureMult; // texture amount
			
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 2);			
			
            _context.drawTriangles(indices, 0, 2);
			
            _context.setTextureAt(1, null);
        }
        
       /**
        * 
        */
		public function set textureMult(value:Number):void {
			_textureMult = value;
		}
		
		/**
		 * 
		 */
		public function set noiseMult(value:Number):void {
			_noiseMult = value;
		}
		
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageNoiseEffect = new GPUImageNoiseEffect();
            return copy;
        }
        
        override public function dispose():void 
        {
            super.dispose();
        }
        
        override public function toString():String
        {
            return 'Noise Effect';
        }
	}
}