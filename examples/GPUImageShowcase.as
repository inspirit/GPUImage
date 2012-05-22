package  
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
	import flash.display.Sprite;
    import flash.display.Stage3D;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DRenderMode;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.Texture;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.media.Camera;
    import flash.media.Video;
    import ru.inspirit.gpu.image.effects.GPUImageAnselEffect;
    import ru.inspirit.gpu.image.effects.GPUImageBloomEffect;
    import ru.inspirit.gpu.image.effects.GPUImageGeorgiaEffect;
    import ru.inspirit.gpu.image.effects.GPUImageHDREffect;
    import ru.inspirit.gpu.image.effects.GPUImageRetroEffect;
    import ru.inspirit.gpu.image.effects.GPUImageSaharaEffect;
    import ru.inspirit.gpu.image.effects.GPUImageTiltShiftEffect;
    import ru.inspirit.gpu.image.effects.GPUImageToonEffect;
    import ru.inspirit.gpu.image.effects.GPUImageXProcessEffect;
    import ru.inspirit.gpu.image.filters.GPUImageColorMatrix;
    import ru.inspirit.gpu.image.filters.GPUImageCurves;
    import ru.inspirit.gpu.image.filters.GPUImageEmboss;
    import ru.inspirit.gpu.image.filters.GPUImageGaussianBlur;
    import ru.inspirit.gpu.image.filters.GPUImageGrayscale;
    import ru.inspirit.gpu.image.filters.GPUImageLUT;
    import ru.inspirit.gpu.image.filters.GPUImagePosterize;
    import ru.inspirit.gpu.image.filters.GPUImageSepia;
    import ru.inspirit.gpu.image.filters.GPUImageSobelEdges;
    import ru.inspirit.gpu.image.filters.GPUImageUnsharpMask;
    import ru.inspirit.gpu.image.filters.GPUImageVignette;
    import ru.inspirit.gpu.image.GPUImage;
    import ru.inspirit.gpu.image.GPUImageFilterGroup;
    import ru.inspirit.gpu.image.IGPUImageProcessor;
	
	/**
     * Filter/effect Showcase for GPUImage lib
     * @author Eugene Zatepyakin
     */
    [SWF(frameRate='60', width='640', height='480', backgroundColor='0xFFFFFF')]
    public final class GPUImageShowcase extends Sprite 
    {
        [Embed(source = "../assets/lomo_texture.png")]private static const lomo_ass:Class;
        
        public var context3D:Context3D;
        public var antiAlias:int = 0;
        public var enableDepthAndStencil:Boolean = false;

        private var _gpuImg:GPUImage;
        private var _imageProcessors:Vector.<IGPUImageProcessor>;
        
        // camera
        public var streamW:int = 640;
        public var streamH:int = 480;
        public var streamFPS:int = 15;
        protected var _camVideo:Video;
        protected var _camBmp:BitmapData;
        
        // stage
        public var stageW:int = 640;
        public var stageH:int = 480;
        
        public function GPUImageShowcase() 
        {
            if (stage) init();
            else addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        protected function init(e:Event = null):void
        {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            
            stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.LOW;
            
            initFlashNativeCapture(streamW, streamH);
        }
        
        protected function updateFrame(e:Event):void 
		{
            _camBmp.draw(_camVideo);
            
            context3D.clear(0.5, 0.5, 0.5, 1.0);
            
            _gpuImg.uploadBitmap(_camBmp);
            _gpuImg.render(true);
            
            context3D.present();
		}
        
        private function getContext(mode:String): void
        {
            context3D = null;
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.requestContext3D(mode);
        }
 
        private function onContextCreated(ev:Event): void
        {
            stageW = stage.stageWidth;
            stageH = stage.stageHeight;
            
            // Setup context
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            context3D = stage3D.context3D;
            context3D.configureBackBuffer(
                stageW,
                stageH,
                antiAlias,
                enableDepthAndStencil
            );
            
            // Enable error checking in the debug player
            /*var debug:Boolean = Capabilities.isDebugger;
            if (debug)
            {
                context3D.enableErrorChecking = true;
            }*/
            
            _imageProcessors = new Vector.<IGPUImageProcessor>();
            
            _gpuImg = new GPUImage();
            _gpuImg.init(context3D, antiAlias, false, stageW, stageH, streamW, streamH);

            // setup filters
            var _gpuSepia:GPUImageSepia = new GPUImageSepia();
            var _gpuGauss:GPUImageGaussianBlur = new GPUImageGaussianBlur(1.0, 4);
            var _gpuGray:GPUImageGrayscale = new GPUImageGrayscale();
            
            // color mapping 
            var lomoTexture:Texture = context3D.createTexture(256, 256, Context3DTextureFormat.BGRA, true);
            var lomoMapBmp:BitmapData = Bitmap(new lomo_ass).bitmapData;
            lomoTexture.uploadFromBitmapData(lomoMapBmp, 0);
            
            var colorMap:GPUImageLUT = new GPUImageLUT();
            colorMap.lutTexture = lomoTexture
            
            // using Curves
            var lomoGroup:GPUImageFilterGroup = new GPUImageFilterGroup();
            var curves:GPUImageCurves = new GPUImageCurves();
            curves.addCurvePoint(GPUImageCurves.CURVE_CHANNEL_RED,
                                    new Point(0, 0),
                                    new Point(60, 30),
                                    new Point(190, 220),
                                    new Point(255, 255)
                                    );
            curves.addCurvePoint(GPUImageCurves.CURVE_CHANNEL_GREEN,
                                    new Point(0, 0),
                                    new Point(60, 30),
                                    new Point(190, 220),
                                    new Point(255, 255)
                                    );
            curves.addCurvePoint(GPUImageCurves.CURVE_CHANNEL_BLUE,
                                    new Point(0, 0),
                                    new Point(30, 60),
                                    new Point(220, 190),
                                    new Point(255, 255)
                                    );
            // update texture
            curves.update();
            
            var clrMat:GPUImageColorMatrix = new GPUImageColorMatrix();
            clrMat.saturation = 1.5;
            var lomoVig:GPUImageVignette = new GPUImageVignette();
            
            lomoGroup.addProcessor(curves);
            lomoGroup.addProcessor(clrMat);
            lomoGroup.addProcessor(lomoVig);
            //
            
            var xpro:GPUImageXProcessEffect = new GPUImageXProcessEffect(0.5);
            
            // Bloom Filter            
            var bloomEffect:GPUImageBloomEffect = new GPUImageBloomEffect(GPUImageBloomEffect.PRESET_DESATURATED, 4);
            bloomEffect.initPreset(GPUImageBloomEffect.PRESET_SATURATED);
            //
            
            // TiltShift
            var tiltShift:GPUImageTiltShiftEffect = new GPUImageTiltShiftEffect(2, 0.4, 0.6, 0.2);
            //
            
            var sepiaVignette:GPUImageFilterGroup = new GPUImageFilterGroup();
            sepiaVignette.addProcessor(new GPUImageSepia());
            sepiaVignette.addProcessor(new GPUImageVignette());
            
            var bloomTiltShiftVignette:GPUImageFilterGroup = new GPUImageFilterGroup();
            var bloomEff2:GPUImageBloomEffect = bloomEffect.clone() as GPUImageBloomEffect;
            bloomEff2.initPreset(GPUImageBloomEffect.PRESET_DESATURATED);
            bloomTiltShiftVignette.addProcessor(bloomEff2);
            bloomTiltShiftVignette.addProcessor(tiltShift.clone());
            bloomTiltShiftVignette.addProcessor(new GPUImageVignette());

            var anselGroup:GPUImageFilterGroup = new GPUImageFilterGroup();
            anselGroup.addProcessor(new GPUImageAnselEffect);
            anselGroup.addProcessor(new GPUImageUnsharpMask(3, .25));
            anselGroup.addProcessor(new GPUImageVignette());

            _imageProcessors.push(new GPUImageRetroEffect());
            _imageProcessors.push(anselGroup);
            _imageProcessors.push(new GPUImageSaharaEffect());
            _imageProcessors.push(new GPUImageHDREffect(1.2, 9));
            _imageProcessors.push(new GPUImageGeorgiaEffect);
            _imageProcessors.push(xpro);
            _imageProcessors.push(colorMap);
            _imageProcessors.push(lomoGroup);
            _imageProcessors.push(_gpuGray);
            _imageProcessors.push(_gpuSepia);
            _imageProcessors.push(_gpuGauss);
            _imageProcessors.push(new GPUImagePosterize(10, 12, 6));
            _imageProcessors.push(new GPUImageToonEffect(2, 6, 0.15, 0.15, 0.2, 0.15));
            _imageProcessors.push(new GPUImageEmboss(1));
            _imageProcessors.push(new GPUImageSobelEdges(0.1));
            
            _imageProcessors.push(bloomEffect);
            _imageProcessors.push(tiltShift);
            _imageProcessors.push(bloomTiltShiftVignette);
            _imageProcessors.push(sepiaVignette);
            
            _gpuImg.addProcessor(_imageProcessors[0]);
            
            addEventListener(Event.ENTER_FRAME, updateFrame);
            stage.doubleClickEnabled = true;
            stage.addEventListener(MouseEvent.DOUBLE_CLICK, nextProcessor);
        }
        
        private var _currProcInd:int = 0;
        private var _currProcessor:IGPUImageProcessor;
        private function nextProcessor(e:Event = null):void
        {
            _currProcInd = ++_currProcInd % _imageProcessors.length;
            _currProcessor = _imageProcessors[_currProcInd];
            _gpuImg.removeProcessorAt(0);
            _gpuImg.addProcessor(_currProcessor);            
        }
        
        protected function initFlashNativeCapture(w:int, h:int):void
		{
            var _cam:Camera = Camera.getCamera();
            _cam.setMode(w, h, streamFPS, false);
            _camVideo = new Video(w, h);
            
            _camVideo.attachCamera(_cam);
            _camBmp = new BitmapData(w, h, false, 0x0);
            
            getContext(Context3DRenderMode.AUTO);
        }
        
    }

}