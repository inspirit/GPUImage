package ru.inspirit.gpu.image
{

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.textures.TextureBase;

public class GPUImageFilterGroup implements IGPUImageProcessor
{
    protected var _filters:Vector.<IGPUImageProcessor>;
    protected var _size:int;

    public function GPUImageFilterGroup()
    {
        _filters = new <IGPUImageProcessor>[];
        _size = 0;
    }

    public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
    {
        var filter:IGPUImageProcessor = _filters[0];
        filter.process(indices, sourceTexture);
        
        var n:int = _size;
        for(var i:int = 1; i < n; ++i)
        {
            _filters[i].process(indices);
        }
    }

    public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
    {
        var n:int = _size;
        for(var i:int = 0; i < n; ++i)
        {
            _filters[i].setup(context, textureWidth, textureHeight);
        }
        connectProcessors();
    }

    public function addProcessor(proc:IGPUImageProcessor, index:int = -1):void
    {
        if(index != -1 && index < _size)
        {
            _filters.splice(index, 0, proc);
        }
        else
        {
            _filters.push(proc);
        }

        ++_size;
        //connectProcessors();
    }
    public function removeProcessorAt(ind:int):void
    {
        if (_size > ind)
        {
            _filters.splice(ind, 1);
            --_size;
        }
    }
    public function removeProcessor(proc:IGPUImageProcessor):void
    {
        var n:int = _size;
        for(var i:int = 0; i < n; ++i)
        {
            if(_filters[i] == proc)
            {
                _filters.splice(i, 1);
                --i;
                --n;
            }
        }
        _size = n;
        //connectProcessors();
    }
    public function getProcessorAt(ind:int):IGPUImageProcessor
    {
        if (ind < _size)
        {
            return _filters[ind];
        }
        return null;
    }

    protected function connectProcessors():void
    {
        var n:int = _size;

        if(n)
        {
            var prev:IGPUImageProcessor = _filters[0];
            for(var i:int = 1; i < n; ++i)
            {
                var f:IGPUImageProcessor = _filters[i];
                f.inputTexture = prev.outputTexture;
                prev = f;
            }
        }
    }

    public function set antiAlias(value:int):void
    {
        var n:int = _size;
        for(var i:int = 0; i < n; ++i)
        {
            _filters[i].antiAlias = value;
        }
    }
    public function get antiAlias():int
    {
        return _filters[0].antiAlias;
    }

    public function set enableDepthAndStencil(value:Boolean):void
    {
        var n:int = _size;
        for(var i:int = 0; i < n; ++i)
        {
            _filters[i].enableDepthAndStencil = value;
        }
    }
    public function get enableDepthAndStencil():Boolean
    {
        return _filters[0].enableDepthAndStencil;
    }

    public function get inputTexture():TextureBase
    {
        return _filters[0].inputTexture;
    }
    public function set inputTexture(value:TextureBase):void
    {
       _filters[0].inputTexture = value;
    }

    public function get outputTexture():TextureBase
    {
        return _filters[_size-1].outputTexture;
    }
    
    public function toString():String
    {
        var str:String = '';
        var n:int = _size;
        for (var i:int = 0; i < n; ++i)
        {
            str += _filters[i] + '\n';
        }
        
        return str;
    }
    
    public function clone():IGPUImageProcessor
    {
        var copy:GPUImageFilterGroup = new GPUImageFilterGroup();
        var n:int = _size;
        for(var i:int = 0; i < n; ++i)
        {
            copy.addProcessor( _filters[i].clone() );
        }
        return copy;
    }
}
}
