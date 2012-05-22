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
    import ru.inspirit.gpu.image.filters.GPUImageCurves;
	import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUImageXProcessEffect extends GPUImageCurves
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
            
            // setup Curves
            addCurvePoint(GPUImageCurves.CURVE_CHANNEL_RED, 
                                    new Point(0, 0),
                                    new Point(88, 47),
                                    new Point(170, 188),
                                    new Point(221, 249),
                                    new Point(255, 255));
            addCurvePoint(GPUImageCurves.CURVE_CHANNEL_GREEN, 
                                        new Point(0, 0),
                                        new Point(65, 57),
                                        new Point(184, 208),
                                        new Point(255, 255));
            addCurvePoint(GPUImageCurves.CURVE_CHANNEL_BLUE, 
                                        new Point(0, 29), 
                                        new Point(255, 226));
            
            update();
            
            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, GPUImageXProcessEffect.FRAGMENT_CODE, AGAL_DEBUG);
        }
        
        override public function activate():void
        {
            super.activate();
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 3);
        }
        
        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageXProcessEffect = new GPUImageXProcessEffect(_contrast, _tint, _color);
            return copy;
        }
        
        override public function toString():String
        {
            return 'Cross Processing';
        }

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