package ru.inspirit.gpu.image.filters
{
    import flash.display3D.textures.Texture;
	import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUImageColorMapping extends GPUImageFilter 
    {
        internal static const FRAGMENT_CODE:String =
                                            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                            "tex ft1, ft0.xx, fs1 <2d,linear,mipnone,clamp>	\n" +
                                            "mov ft0.x, ft1.x                       \n" +
                                            "tex ft1, ft0.yy, fs1 <2d,linear,mipnone,clamp>	\n" +
                                            "mov ft0.y, ft1.y                       \n" +
                                            "tex ft1, ft0.zz, fs1 <2d,linear,mipnone,clamp>	\n" +
                                            "mov ft0.z, ft1.z                       \n" +
                                            //out
                                            "mov oc, ft0";
                                            
        protected var _colorMapTexture:Texture;
        
        public function GPUImageColorMapping() 
        {
            super();
			
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }
        
        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setTextureAt(1, _colorMapTexture);
        }

        override public function deactivate():void
        {
            _context.setTextureAt(1, null);
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageColorMapping = new GPUImageColorMapping();
            return copy;
        }
        
        override public function toString():String
        {
            return 'ColorMap Filter';
        }
        
        public function get colorMapTexture():Texture { return _colorMapTexture; }
        public function set colorMapTexture(value:Texture):void 
        {
            _colorMapTexture = value;
        }
        
    }

}