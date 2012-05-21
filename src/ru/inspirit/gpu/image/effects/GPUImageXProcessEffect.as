package ru.inspirit.gpu.image.effects
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
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUImageXProcessEffect extends GPUImageFilter
    {
        internal static const FRAGMENT_CODE:String =
                                            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                                            "mov ft2.xyz, ft0.xyz                       \n" + //save original
                                            "tex ft1, ft0.xx, fs1 <2d,linear,mipnone,clamp>	\n" +
                                            "mov ft0.x, ft1.x                       \n" +
                                            "tex ft1, ft0.yy, fs1 <2d,linear,mipnone,clamp>	\n" +
                                            "mov ft0.y, ft1.y                       \n" +
                                            "tex ft1, ft0.zz, fs1 <2d,linear,mipnone,clamp>	\n" +
                                            "mov ft0.z, ft1.z                       \n" + // lut processed
                                            // overlay original
                                            "sub ft3.xyz, fc0.www, ft2.xyz  \n" +
                                            "sub ft4.xyz, fc0.www, ft0.xyz  \n" +
                                            "mul ft3.xyz, ft3.xyz, ft4.xyz  \n" +
                                            "add ft3.xyz, ft3.xyz, ft3.xyz  \n" +
                                            "sub ft3.xyz, fc0.www, ft3.xyz  \n" +
                                            "mul ft4.xyz, ft2.xyz, ft0.xyz  \n" +
                                            "add ft4.xyz, ft4.xyz, ft4.xyz  \n" +
                                            "sge ft1.xyz, ft0.xyz, fc1.zzz  \n" +
                                            "slt ft5.xyz, ft0.xyz, fc1.zzz  \n" +
                                            "mul ft1.xyz, ft1.xyz, ft3.xyz  \n" +
                                            "mul ft5.xyz, ft5.xyz, ft4.xyz  \n" +
                                            "add ft1.xyz, ft1.xyz, ft5.xyz  \n" + // original overlay lut
                                            // mix overlay and lut
                                            "sub ft1.xyz, ft1.xyz, ft0.xyz  \n" +
                                            "mul ft1.xyz, ft1.xyz, fc1.xxx  \n" +
                                            "add ft0.xyz, ft0.xyz, ft1.xyz  \n" +
                                            //
                                            // overlay color
                                            //"sub ft3.xyz, fc0.www, fc2.xyz  \n" +
                                            "sub ft4.xyz, fc0.www, ft0.xyz  \n" +
                                            "mul ft3.xyz, fc2.xyz, ft4.xyz  \n" +
                                            "add ft3.xyz, ft3.xyz, ft3.xyz  \n" +
                                            "sub ft3.xyz, fc0.www, ft3.xyz  \n" +
                                            "mul ft4.xyz, fc0.xyz, ft0.xyz  \n" +
                                            "add ft4.xyz, ft4.xyz, ft4.xyz  \n" +
                                            "sge ft1.xyz, ft0.xyz, fc1.zzz  \n" +
                                            "slt ft5.xyz, ft0.xyz, fc1.zzz  \n" +
                                            "mul ft1.xyz, ft1.xyz, ft3.xyz  \n" +
                                            "mul ft5.xyz, ft5.xyz, ft4.xyz  \n" +
                                            "add ft1.xyz, ft1.xyz, ft5.xyz  \n" + // color overlay final
                                            // mix overlay
                                            "sub ft1.xyz, ft1.xyz, ft0.xyz  \n" +
                                            "mul ft1.xyz, ft1.xyz, fc1.yyy  \n" +
                                            "add ft0.xyz, ft0.xyz, ft1.xyz  \n" +
                                            //
                                            //out
                                            "mov oc, ft0";
                                            
        protected var _contrast:Number;
        protected var _tint:Number;
        protected var _color:uint;
        protected var _lutBmp:BitmapData;
        protected var _lutTexture:Texture;
        
        protected var _params:Vector.<Number>;
        
        public function GPUImageXProcessEffect(contrast:Number = 0.5, tint:Number = 0.1, color:uint = 0x00FFBA)
        {
            super();
            
            _contrast = contrast;
            _tint = tint;
            _color = color;
            
            var r:Number = ((color >> 16) & 0xFF) / 255.;
            var g:Number = ((color >> 8) & 0xFF) / 255.;
            var b:Number = (color & 0xFF) / 255.;
            
            _params = Vector.<Number>([
                                        r, g, b, 1.,
                                        _contrast, _tint, 0.5, 0,
                                        1.-r, 1.-g, 1.-b, 0
                                        ]);
            
            createLUTTexture();
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, FRAGMENT_CODE, AGAL_DEBUG);
        }
        
        override public function setup(context:Context3D, textureWidth:int, textureHeight:int):void
        {
            super.setup(context, textureWidth, textureHeight);
            
            if (_lutTexture)
            {
                _lutTexture.dispose();
                _lutTexture = null;
            }
            
            _lutTexture = _context.createTexture(256, 256, Context3DTextureFormat.BGRA, false);
            _lutTexture.uploadFromBitmapData(_lutBmp);
        }
        
        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 3);
            _context.setTextureAt(1, _lutTexture);
        }
        override public function deactivate():void 
        {
            _context.setTextureAt(1, null);
        }
        
        protected function createLUTTexture():void
        {
            // fix palettes
            var lut_r:Array = [];
            var lut_g:Array = [];
            for (var i:int = 0; i < 256; ++i)
            {
                lut_r[i] = _xproRedCurveLut[i] << 16;
            	lut_g[i] = _xproGreenCurveLut[i] << 8;
            }
            
            _lutBmp = new BitmapData(256, 256, false, 0x0);
            var sh:Shape = new Shape();
            var gfx:Graphics = sh.graphics;
            var mat:Matrix = new Matrix();
            mat.createGradientBox(256,256,0);
            gfx.beginGradientFill('linear', [0x000000, 0xFFFFFF], [1, 1], [0, 255], mat);
            gfx.drawRect(0, 0, 256, 256);
            gfx.endFill();

            _lutBmp.draw(sh);
            _lutBmp.paletteMap(_lutBmp, _lutBmp.rect, new Point, lut_r, lut_g, _xproBlueCurveLut);
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageXProcessEffect = new GPUImageXProcessEffect(_contrast, _tint, _color);
            return copy;
        }
        
        override public function dispose():void 
        {
            super.dispose();
            if (_lutBmp)
            {
                _lutBmp.dispose();
                _lutBmp = null;
            }
            if (_lutTexture)
            {
                _lutTexture.dispose();
                _lutTexture = null;
            }
        }
        
        override public function toString():String
        {
            return 'Cross Processing';
        }
        
        // taken from LightBox sources ;-)
        protected var _xproRedCurveLut:Array = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,
		1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7,
		8, 8, 8, 9, 9, 9, 10, 10, 11, 11, 11, 12, 12, 13, 13, 14, 14, 14, 15,
		15, 16, 16, 17, 18, 18, 19, 19, 20, 20, 21, 22, 22, 23, 24, 24, 25, 26,
		27, 27, 28, 29, 30, 30, 31, 32, 33, 34, 35, 36, 37, 37, 38, 39, 40, 41,
		42, 44, 44, 45, 46, 47, 49, 50, 52, 53, 54, 56, 57, 58, 60, 61, 63, 64,
		66, 68, 69, 71, 73, 75, 76, 78, 80, 81, 83, 85, 87, 89, 91, 93, 95, 97,
		98, 101, 103, 105, 107, 109, 111, 113, 115, 117, 119, 121, 123, 125,
		127, 129, 131, 133, 135, 137, 139, 141, 143, 145, 147, 149, 151, 154,
		156, 157, 159, 161, 163, 165, 167, 169, 171, 173, 175, 177, 178, 180,
		182, 184, 185, 187, 188, 191, 192, 193, 195, 197, 198, 200, 202, 203,
		205, 206, 208, 209, 211, 212, 214, 215, 217, 219, 220, 221, 223, 224,
		225, 227, 228, 230, 231, 232, 234, 235, 236, 237, 239, 240, 241, 242,
		243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 255,
		255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		255, 255, 255 ];
        protected var _xproGreenCurveLut:Array = [ 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
		10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
		28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45,
		47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 58, 59, 60, 61, 62, 63, 64, 65,
		67, 69, 70, 71, 72, 73, 75, 76, 77, 78, 80, 81, 82, 83, 85, 86, 87, 88,
		90, 91, 92, 94, 95, 96, 97, 99, 100, 101, 103, 104, 105, 107, 108, 109,
		111, 112, 113, 115, 116, 117, 119, 120, 121, 123, 124, 125, 127, 129,
		130, 132, 133, 134, 136, 137, 138, 140, 141, 142, 144, 145, 146, 147,
		149, 149, 150, 152, 153, 154, 155, 157, 158, 159, 160, 162, 163, 164,
		166, 167, 168, 170, 171, 172, 173, 174, 176, 177, 178, 179, 181, 182,
		183, 184, 185, 187, 188, 189, 190, 191, 192, 193, 195, 196, 197, 198,
		199, 200, 201, 202, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213,
		213, 215, 216, 217, 217, 218, 219, 220, 221, 222, 222, 223, 224, 225,
		226, 226, 227, 228, 229, 229, 230, 231, 231, 232, 233, 233, 234, 235,
		235, 236, 236, 237, 238, 238, 239, 239, 240, 240, 241, 241, 242, 242,
		243, 243, 244, 244, 245, 245, 245, 246, 246, 247, 247, 248, 248, 248,
		249, 249, 250, 250, 250, 251, 251, 251, 252, 252, 253, 253, 254, 254,
		255, 255, 255 ];
        protected var _xproBlueCurveLut:Array = [ 21, 21, 21, 22, 23, 24, 25, 26,
		27, 28, 29, 29, 30, 31, 32, 33, 34, 34, 35, 36, 37, 38, 39, 39, 40, 41,
		42, 43, 44, 44, 45, 46, 47, 48, 49, 49, 50, 51, 52, 53, 54, 54, 55, 56,
		57, 58, 59, 59, 60, 61, 62, 63, 64, 64, 65, 66, 67, 68, 69, 69, 70, 71,
		72, 73, 74, 74, 75, 76, 77, 78, 79, 80, 80, 81, 82, 83, 84, 84, 85, 86,
		87, 88, 89, 89, 91, 91, 92, 93, 94, 95, 95, 96, 97, 98, 99, 100, 101,
		101, 102, 103, 104, 105, 106, 106, 107, 108, 109, 110, 111, 111, 112,
		113, 114, 115, 115, 116, 117, 118, 119, 120, 121, 121, 122, 123, 124,
		125, 126, 126, 127, 128, 129, 130, 131, 132, 132, 133, 134, 135, 136,
		137, 137, 138, 139, 140, 141, 142, 142, 143, 144, 145, 146, 147, 147,
		148, 149, 150, 151, 152, 152, 153, 154, 155, 156, 157, 157, 158, 159,
		160, 160, 162, 162, 163, 164, 165, 166, 167, 167, 168, 169, 170, 171,
		172, 172, 173, 174, 175, 176, 176, 177, 178, 179, 180, 181, 181, 182,
		183, 184, 185, 186, 186, 187, 188, 189, 190, 191, 191, 192, 193, 194,
		195, 196, 197, 198, 198, 199, 200, 201, 202, 203, 203, 204, 205, 206,
		207, 208, 208, 209, 210, 211, 212, 213, 213, 214, 215, 216, 217, 218,
		218, 219, 220, 221, 222, 223, 223, 224, 225, 226, 227, 228, 228, 229,
		230, 231, 232, 232, 233 ];

        public function get contrast():Number { return _contrast; }
        public function set contrast(value:Number):void
        {
            _contrast = value;
            _params[4] = value;
        }

        public function get tint():Number { return _tint; }
        public function set tint(value:Number):void
        {
            _tint = value;
            _params[5] = value;
        }

        public function get color():uint { return _color; }
        public function set color(value:uint):void
        {
            _color = value;
            var r:Number = ((value >> 16) & 0xFF) / 255.;
            var g:Number = ((value >> 8) & 0xFF) / 255.;
            var b:Number = (value & 0xFF) / 255.;
            _params[0] = r;
            _params[1] = g;
            _params[2] = b;
            _params[8] = 1.-r;
            _params[9] = 1.-g;
            _params[10] = 1.-b;
        }
    }

}