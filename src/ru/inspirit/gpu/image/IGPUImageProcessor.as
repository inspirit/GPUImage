package ru.inspirit.gpu.image
{
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.textures.TextureBase;

public interface IGPUImageProcessor
{
    function setup(context:Context3D, textureWidth:int, textureHeight:int):void;
    function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void;
    function clone():IGPUImageProcessor;

    function set antiAlias(value:int):void;
    function get antiAlias():int;
    function set enableDepthAndStencil(value:Boolean):void;
    function get enableDepthAndStencil():Boolean;
    function get inputTexture():TextureBase;
    function set inputTexture(value:TextureBase):void;
    function get outputTexture():TextureBase;
}
}
