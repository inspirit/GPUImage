package ru.inspirit.gpu.image.filters
{
    import flash.display3D.textures.Texture;
    import ru.inspirit.gpu.image.GPUImageFilter;
    import ru.inspirit.gpu.image.IGPUImageProcessor;

    public final class GPUImageComposite extends GPUImageFilter
    {
        public static const BLEND_ADD:String = "add";
        public static const BLEND_MULTIPLY:String = "multiply";
        public static const BLEND_SUBTRACT:String = "subtract";
        public static const BLEND_NORMAL:String = "normal";
        public static const BLEND_DARKEN:String = "darken";
        public static const BLEND_LIGHTEN:String = "lighten";
        public static const BLEND_SCREEN:String = "screen";
        public static const BLEND_OVERLAY:String = "overlay";
        public static const BLEND_SOFTLIGHT:String = "softlight";
        public static const BLEND_HARDLIGHT:String = "hardlight";
        public static const BLEND_COLOR:String = "color";

        protected var _overlayTexture:Texture;
        protected var _exposure:Number;
        protected var _opacity:Number;
        protected var _blendMode:String;

        protected var _params:Vector.<Number>;

        public function GPUImageComposite(blendMode:String, exposure:Number = 1., opacity:Number = 1.)
        {
            super();

            _blendMode = blendMode;
            _exposure = exposure;
            _opacity = opacity;

            _params = Vector.<Number>([ exposure, opacity, 1.0, 0.5 ]);

            _fragmentShader = agalCompiler.assemble(FRAGMENT_TYPE, getFragmentCode(_blendMode), AGAL_DEBUG);
        }

        override public function activate():void
        {
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(FRAGMENT_TYPE, 0, _params, 1);
            _context.setTextureAt(1, _overlayTexture);
        }

        override public function deactivate():void
        {
            _context.setTextureAt(1, null);
        }

        public function get overlayTexture():Texture { return _overlayTexture; }
        public function set overlayTexture(value:Texture):void
        {
            _overlayTexture = value;
        }

        public function get exposure():Number { return _exposure; }
        public function set exposure(value:Number):void
        {
            _params[0] = _exposure = value;
        }

        public function get opacity():Number { return _opacity; }
        public function set opacity(value:Number):void
        {
            _params[1] = _opacity = value;
        }

        // extended from away3d sources
        internal static function getFragmentCode(blendMode:String, base:String = "ft0", over:String = "ft1"):String
        {
            var code : String;
            code = 	"tex "+base+", v0, fs0 <2d,linear,mipnone,clamp>	\n" +
                    "tex "+over+", v0, fs1 <2d,linear,mipnone,clamp>	\n" +
                    "mul ft1, ft1, fc0.x				\n";
            switch (blendMode)
            {
                case "multiply":
                    code += "mul ft1.xyz, ft0.xyz, ft1.xyz		\n";
                    break;
                case "add":
                    code += "add ft1.xyz, ft0.xyz, ft1.xyz	    \n";
                    break;
                case "subtract":
                    code += "sub ft1.xyz, ft0.xyz, ft1.xyz		\n";
                    break;
                case "normal":
                    code += "mov oc, ft0						\n";
                    return code;
                case "darken":
                    code += "min ft1.xyz, ft0.xyz, ft1.xyz      \n";
                    break;
                case "lighten":
                    code += "max ft1.xyz, ft0.xyz, ft1.xyz      \n";
                    break;
                case "screen":
                    code += "sub ft1.xyz, fc0.zzz, ft1.xyz       \n";
                    code += "sub ft2.xyz, fc0.zzz, ft0.xyz       \n";
                    code += "mul ft1.xyz, ft1.xyz, ft2.xyz       \n";
                    code += "sub ft1.xyz, fc0.zzz, ft1.xyz       \n";
                    break;
                case "overlay":
                    code += "sub ft3.xyz, fc0.zzz, ft1.xyz  \n" +
                            "sub ft4.xyz, fc0.zzz, ft0.xyz  \n" +
                            "mul ft3.xyz, ft3.xyz, ft4.xyz  \n" +
                            "add ft3.xyz, ft3.xyz, ft3.xyz  \n" +
                            "sub ft3.xyz, fc0.zzz, ft3.xyz  \n" +
                            "mul ft4.xyz, ft1.xyz, ft0.xyz  \n" +
                            "add ft4.xyz, ft4.xyz, ft4.xyz  \n" +
                            "sge ft6.xyz, ft0.xyz, fc0.www  \n" +
                            "slt ft5.xyz, ft0.xyz, fc0.www  \n" +
                            "mul ft6.xyz, ft6.xyz, ft3.xyz  \n" +
                            "mul ft5.xyz, ft5.xyz, ft4.xyz  \n" +
                            "add ft1.xyz, ft6.xyz, ft5.xyz  \n" ;
                    break;
                case "softlight":
                    code += "add ft2.xyz, ft0.xyz, ft0.xyz  \n" +
                            "mul ft2.xyz, ft2.xyz, ft1.xyz  \n" +
                            "sub ft2.xyz, ft0.xyz, ft2.xyz  \n" +
                            "add ft2.xyz, ft2.xyz, ft1.xyz  \n" +
                            "add ft2.xyz, ft2.xyz, ft1.xyz  \n" +
                            "mul ft1.xyz, ft2.xyz, ft0.xyz  \n";
                    break;
                case "hardlight":
                    return getFragmentCode("overlay", "ft1", "ft0");
                case "color":
                    code += "dp3 ft2.x, ft0.xyz, ft0.xyz    \n" +
                            "sqt ft2.x, ft2.x               \n" +
                            "nrm ft1.xyz, ft1.xyz           \n" +
                            "mul ft1.xyz, ft1.xyz, ft2.xxx  \n" ;
                    break;
                default:
                    throw new Error("Unknown blend mode");
            }
            // mix overlay and base
            code += "sub ft1.xyz, ft1.xyz, ft0.xyz  \n" +
                    "mul ft1.xyz, ft1.xyz, fc0.yyy  \n" +
                    "add ft0.xyz, ft0.xyz, ft1.xyz  \n" +
                    "mov oc, ft0                    \n" ;
            return code;
        }

        override public function clone():IGPUImageProcessor
        {
            var copy:GPUImageComposite = new GPUImageComposite(_blendMode, _exposure, _opacity);
            return copy;
        }

        override public function toString():String
        {
            return 'Composite Filter';
        }
    }
}
