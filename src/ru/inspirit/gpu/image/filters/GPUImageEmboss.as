package ru.inspirit.gpu.image.filters
{
    import flash.display3D.Context3D;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUImageEmboss extends GPUImage3x3Convolution 
    {
        protected var _intensity:Number;
        
        public function GPUImageEmboss(intensity:Number) 
        {
            super(new <Number>[
                                        intensity * ( -2.0),       -intensity,              0.,
                                        -intensity,                         1.,             intensity,
                                        0.,                         intensity,              intensity * 2.0
                                        ]);
            
            _intensity = intensity;
        }

        public function get intensity():Number { return _intensity; }
        public function set intensity(value:Number):void
        {
            _intensity = value;
            _fragmentParams[0] = value * -2.0;
            _fragmentParams[1] = -value;
            _fragmentParams[3] = -value;
            _fragmentParams[5] = value;
            _fragmentParams[7] = value;
            _fragmentParams[8] = value * 2.0;
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageEmboss = new GPUImageEmboss(_intensity);
            return copy;
        }
        
        override public function toString():String
        {
            return 'Emboss Filter';
        }
    }

}