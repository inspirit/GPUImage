package ru.inspirit.gpu.image.filters
{
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.Shape;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.Texture;
    import flash.geom.Matrix;
    import flash.geom.Point;

    import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;

    public class GPUImageLUT extends GPUImageFilter
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

        protected var _lutBitmap:BitmapData = null;
        protected var _lutMapTexture:Texture = null;

        public function GPUImageLUT()
        {
            super();

            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }

        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            super.setup(context, textureWidth, textureHeight);

            if(null != _lutBitmap)
            {
                if(null != _lutMapTexture)
                {
                    _lutMapTexture.dispose();
                }

                _lutMapTexture = _context.createTexture(256, 256, Context3DTextureFormat.BGRA, false);
                _lutMapTexture.uploadFromBitmapData(_lutBitmap, 0);
            }
        }

        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setTextureAt(1, _lutMapTexture);
        }

        override public function deactivate():void
        {
            _context.setTextureAt(1, null);
        }

        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageLUT = new GPUImageLUT();
            if(_lutMapTexture) copy.lutTexture = _lutMapTexture;
            if(_lutBitmap) copy.lutBitmap = _lutBitmap;
            return copy;
        }

        override public function dispose():void
        {
            super.dispose();
            if(_lutBitmap) _lutBitmap.dispose();
            if(_lutMapTexture) _lutMapTexture.dispose();
        }

        override public function toString():String
        {
            return 'LUT Filter';
        }

        public function get lutTexture():Texture { return _lutMapTexture; }
        public function set lutTexture(value:Texture):void
        {
            _lutMapTexture = value;
        }

        public function get lutBitmap():BitmapData {return _lutBitmap;}
        public function set lutBitmap(value:BitmapData):void
        {
            if(value.width != 256 || value.height != 256 )
            {
                throw new Error("LUT Filter BitmapData needs to be 256x256 size");
            }
            _lutBitmap = value;
        }

        public function setupLUTTexture(redPalette:Array, greenPalette:Array, bluePalette:Array, alphaPalette:Array = null):void
        {
            if(!_lutBitmap) _lutBitmap = new BitmapData(256, 256, false, 0x0);

            _lutBitmap.draw(_sh);
            _lutBitmap.paletteMap(_lutBitmap, _lutBitmap.rect, new Point, redPalette, greenPalette, bluePalette, alphaPalette);

            if(_lutMapTexture)
            {
                _lutMapTexture.uploadFromBitmapData(_lutBitmap, 0);
            }
        }

        protected static var _sh:Shape = new Shape();
        protected static var _gfx:Graphics = _sh.graphics;
        protected static var _mat:Matrix = new Matrix();
        {
            _mat.createGradientBox(256,256,0);
            _gfx.beginGradientFill('linear', [0x000000, 0xFFFFFF], [1, 1], [0, 255], _mat);
            _gfx.drawRect(0, 0, 256, 256);
            _gfx.endFill();
        }
    }
}
