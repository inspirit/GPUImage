package ru.inspirit.gpu.image.filters
{

import ru.inspirit.gpu.image.IGPUImageProcessor;

public final class GPUImageSepia extends GPUImageColorMatrix
{
    public function GPUImageSepia()
    {
        super();

        _matrix.copyRawDataFrom(Vector.<Number>([0.3588, 0.7044, 0.1368, 0.0,
                                                 0.2990, 0.5870, 0.1140, 0.0,
                                                 0.2392, 0.4696, 0.0912 ,0.0,
                                                 0,      0,      0,      1.0]), 0, false);
    }
    
    override public function clone():IGPUImageProcessor
    {
        var copy:GPUImageSepia = new GPUImageSepia();
        return copy;
    }
    
    override public function toString():String
    {
        return 'Sepia Filter';
    }
}
}
