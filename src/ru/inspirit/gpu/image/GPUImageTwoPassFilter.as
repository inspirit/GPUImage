package ru.inspirit.gpu.image
{
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.textures.TextureBase;
import flash.utils.ByteArray;

public class GPUImageTwoPassFilter extends GPUImageFilter
{
    protected var _secondPassTexture:TextureBase;
    protected var _secondPassProgram:Program3D;
    
    protected var _vertexShader2:ByteArray = null;
    protected var _fragmentShader2:ByteArray = null;
    

    public function GPUImageTwoPassFilter()
    {
        super();
    }
    
    public function buildShaderPrograms(firstPassVertexShader:ByteArray, firstPassFragmentShader:ByteArray,
                                        secondPassVertexShader:ByteArray = null, secondPassFragmentShader:ByteArray = null):void
    {
        // init first Program
        super.buildShaderProgram(firstPassVertexShader, firstPassFragmentShader);
        
        // clean up first
        if (_secondPassProgram) _secondPassProgram.dispose();
        
        // skip if both not defined
        if (null == secondPassVertexShader && null == secondPassFragmentShader)
        {
            return;
        }
        
        if (null == secondPassVertexShader)
        {
            _vertexShader2 = secondPassVertexShader = agalCompiler.assemble(VERTEX_TYPE, DEFAULT_VERTEX_SHADER_CODE, AGAL_DEBUG);
        }
        if (null == secondPassFragmentShader)
        {
            _fragmentShader2 = secondPassFragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, DEFAULT_FRAGMENT_SHADER_CODE, AGAL_DEBUG);
        }
        
        // Create the shader program
        _secondPassProgram = _context.createProgram();
        _secondPassProgram.upload(secondPassVertexShader, secondPassFragmentShader);
    }
    
    override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
    {
        var flag:int = int(_context != context) << 1;
        flag |= int(_textureWidth != textureWidth) << 2;
        flag |= int(_textureHeight != textureHeight) << 2;

        if (flag&2)
        {
            _context = context;
            buildShaderPrograms(_vertexShader, _fragmentShader, _vertexShader2, _fragmentShader2);
        }

        if(flag && _outputTexture)
        {
            _outputTexture.dispose();
            _outputTexture = null;
            _secondPassTexture.dispose();
            _secondPassTexture = null;
        }
        if(flag)
        {
            _textureWidth = textureWidth >> (4 - _renderQuality);
            _textureHeight = textureHeight >> (4 - _renderQuality);
            _outputTexture = _context.createTexture(_textureWidth, _textureHeight, Context3DTextureFormat.BGRA, true);
            _secondPassTexture = _context.createTexture(_textureWidth, _textureHeight, Context3DTextureFormat.BGRA, true);
        }
    }

    public function activateSecondPass():void
    {
        throw new Error("GPUImageTwoPassFilter::activateSecondPass Should be overwritten!");
    }

    public function deactivateSecondPass():void
    {
        //
    }

    override public function process(indices:IndexBuffer3D, sourceTexture:TextureBase = null):void
    {
        // FIRST PASS
        _context.setRenderToTexture(_secondPassTexture, _enableDepthAndStencil, _antiAlias, 0);
        _context.clear(0.0, 0.0, 0.0, 1.0);

        activate();

        _context.setTextureAt(0, sourceTexture || _inputTexture);

        _context.drawTriangles(indices, 0, 2);

        deactivate();
        
        // SECOND PASS
        _context.setRenderToTexture(_outputTexture, _enableDepthAndStencil, _antiAlias, 0);
        _context.clear(0.0, 0.0, 0.0, 1.0);

        activateSecondPass();

        _context.setTextureAt(0, _secondPassTexture);

        _context.drawTriangles(indices, 0, 2);

        deactivateSecondPass();
    }
    
    override public function dispose():void
    {
        super.dispose();
        if(_secondPassProgram) _secondPassProgram.dispose();
        if (_secondPassTexture) _secondPassTexture.dispose();
        if (_vertexShader2) _vertexShader2.clear();
        if (_fragmentShader2) _fragmentShader2.clear();
        
        _vertexShader2 = null;
        _fragmentShader2 = null;

        _secondPassTexture = null;
        _secondPassProgram = null;
    }
}
}
