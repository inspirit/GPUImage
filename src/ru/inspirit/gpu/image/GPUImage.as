package ru.inspirit.gpu.image
{
    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.textures.Texture;
    import flash.display3D.textures.TextureBase;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;

    import ru.inspirit.gpu.image.filters.GPUImageToScreen;

    public final class GPUImage
    {
        public static const FILL_MODE_STRETCH:int = 0;
        public static const FILL_MODE_PRESERVE_ASPECT_RATIO:int = 1;
        public static const FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL:int = 2;
        public static const FILL_MODE_NO_STRETCH:int = 3;

        public static var MAX_TEXTURE_SIZE:int = 2048;

        internal const FLOAT2_FORMAT:String = Context3DVertexBufferFormat.FLOAT_2;

        internal var _initialized:Boolean;
        internal var _context:Context3D;
        internal var _antiAlias:int;
        internal var _enableDepthAndStencil:Boolean;
        internal var _stageW:int;
        internal var _stageH:int;
        internal var _fillMode:int;

        internal var _texture:Texture;
        internal var _textureBmp:BitmapData;
        internal var _textureCopyPoint:Point;

        protected var _imageWidth:int;
        protected var _imageHeight:int;
        protected var _imageRect:Rectangle;

        internal var _textureWidth:int;
        internal var _textureHeight:int;

        internal var _indexBuffer:IndexBuffer3D;
        internal var _renderToTextureVertexBuffer:VertexBuffer3D;
        internal var _renderToScreenVertexBuffer:VertexBuffer3D;
        internal var _renderToBitmapVertexBuffer:VertexBuffer3D;
        internal var _renderToTextureRect:Rectangle = new Rectangle();

        internal var _textureRatioX:Number;
        internal var _textureRatioY:Number;

        internal var _screenFilter:GPUImageToScreen;
        internal var _defaultFilter:GPUImageFilter;

        // stage center
        private var _x:Number = 0.;
        private var _y:Number = 0.;

        private var _scaleX:Number = 1.;
        private var _scaleY:Number = 1.;

        internal var _dirty:int = 2;

        public function GPUImage()
        {
            _initialized = false;
            _fillMode = FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL;
        }
        
        public function init(ctx:Context3D, antiAlias:int, enableDepthAndStencil:Boolean,
                             viewWidth:int, viewHeight:int,
                             imageWidth:int, imageHeight:int,
                             powerOfTwoRect:Rectangle = null):void
        {
            if (_initialized)
            {
                dispose();
            }
            
            _initialized = true;
            _context = ctx;
            _antiAlias = antiAlias;
            _enableDepthAndStencil = enableDepthAndStencil;
            _stageW = viewWidth;
            _stageH = viewHeight;

            updateImage2Texture(imageWidth, imageHeight, powerOfTwoRect);
            updateRTTBuffers();

            // should i place it to Image2Texture update?
            if(_imageWidth != _textureWidth || _imageHeight != _textureHeight)
            {
                _textureBmp = new BitmapData(_textureWidth, _textureHeight, true, 0x0);
            }

            _textureCopyPoint = new Point((_textureWidth - _imageWidth) * 0.5, (_textureHeight - _imageHeight) * 0.5);
            if (_textureCopyPoint.x < 0) _textureCopyPoint.x = 0;
            if (_textureCopyPoint.y < 0) _textureCopyPoint.y = 0;
            //

            _texture = _context.createTexture(_textureWidth, _textureHeight, Context3DTextureFormat.BGRA, false);

            _defaultFilter = _screenFilter = new GPUImageToScreen();
            _screenFilter.setup(_context, _textureWidth, _textureHeight);
            _screenFilter.inputTexture = _texture;
            _screenFilter.disposeOutputTexture();
        }

        // to screen render mode
        public function setFillMode(fillMode:int):void
        {
            _fillMode = fillMode;
            updateRTTBuffers();
        }

        // in case u work with ByteArray input
        public function disposeTextureBitmap():void
        {
            if(_textureBmp)
            {
                _textureBmp.dispose();
                _textureBmp = null;
            }
        }
        
        public function setTexture(texture:Texture, imageWidth:int, imageHeight:int, powerOfTwoRect:Rectangle = null):void
        {
            if (_texture)
            {
                _texture.dispose();
            }

            updateImage2Texture(imageWidth, imageHeight, powerOfTwoRect);
            updateRTTBuffers();
            
            _texture = texture;
            _screenFilter.inputTexture = _texture;
        }

        protected function updateImage2Texture(imageWidth:int, imageHeight:int, powerOfTwoRect:Rectangle = null):void
        {
            // setup texture dimension

            _imageWidth = imageWidth;
            _imageHeight = imageHeight;
            _imageRect = new Rectangle(0, 0, imageWidth, imageHeight);

            _textureWidth = nextPowerOfTwo(_imageWidth);
            _textureHeight = nextPowerOfTwo(_imageHeight);

            _textureWidth = Math.min(MAX_TEXTURE_SIZE, _textureWidth);
            _textureHeight = Math.min(MAX_TEXTURE_SIZE, _textureHeight);

            if (null != powerOfTwoRect)
            {
                _textureWidth = Math.min(powerOfTwoRect.width, _textureWidth);
                _textureHeight = Math.min(powerOfTwoRect.height, _textureHeight);

                // update image dimensions
                if (_imageWidth > _textureWidth)
                {
                    _imageWidth = _textureWidth;
                    _imageRect.x = (_imageWidth - _textureWidth) / 2;
                }
                if (_imageHeight > _textureHeight)
                {
                    _imageHeight = _textureHeight;
                    _imageRect.y = (_imageHeight - _textureHeight) / 2;
                }
                _imageRect.width = _imageWidth;
                _imageRect.height = _imageHeight;
            }
        }

        protected function updateRTTBuffers():void
        {
            var textureVerts:Vector.<Number>;
            var screenVerts:Vector.<Number>;
            var x:Number, y:Number, u:Number, v:Number;

            _renderToTextureVertexBuffer ||= _context.createVertexBuffer(4, 4);
            _renderToScreenVertexBuffer ||= _context.createVertexBuffer(4, 4);
            _renderToBitmapVertexBuffer ||= _context.createVertexBuffer(4, 4);

            if (!_indexBuffer)
            {
                _indexBuffer = _context.createIndexBuffer(6);
                _indexBuffer.uploadFromVector(new <uint>[2, 1, 0, 3, 2, 0], 0, 6);
            }
            
            if (_textureWidth > _imageWidth) {
                _renderToTextureRect.x = uint((_textureWidth-_imageWidth)*.5);
                _renderToTextureRect.width = _imageWidth;
            }
            else {
                _renderToTextureRect.x = 0;
                _renderToTextureRect.width = _textureWidth;
            }

            if (_textureHeight > _imageHeight) {
                _renderToTextureRect.y = uint((_textureHeight-_imageHeight)*.5);
                _renderToTextureRect.height = _imageHeight;
            }
            else {
                _renderToTextureRect.y = 0;
                _renderToTextureRect.height = _textureHeight;
            }

            if (_imageWidth > _textureWidth) {
                x = 1;
                u = 0;
            }
            else {
                x = _imageWidth/_textureWidth;
                u = _renderToTextureRect.x/_textureWidth;
            }
            if (_imageHeight > _textureHeight) {
                y = 1;
                v = 0;
            }
            else {
                y = _imageHeight/_textureHeight;
                v = _renderToTextureRect.y/_textureHeight;
            }

            _textureRatioX = x;
            _textureRatioY = y;

            textureVerts = new <Number>[	-x, -y, u,   1-v,
                                             x, -y, 1-u, 1-v,
                                             x,  y, 1-u,   v,
                                            -x,  y, u,     v ];
            //
            var widthScaling:Number, heightScaling:Number;
            var insetSize:Point = scaleWithAspect(_imageWidth, _imageHeight, _stageW, _stageH, true);
            switch(_fillMode)
            {
                case 0://FillModeStretch:
                    widthScaling = 1.0;
                    heightScaling = 1.0;
                    break;
                case 1://FillModePreserveAspectRatio:
                    widthScaling = insetSize.x / _stageW;
                    heightScaling = insetSize.y / _stageH;
                    break;
                default:
                case 2://FillModePreserveAspectRatioAndFill:
                    widthScaling = _stageH / insetSize.y;
                    heightScaling = _stageW / insetSize.x;
                    break;
                case 3://FILL_MODE_NO_STRETCH
                    widthScaling = _imageWidth / _stageW;
                    heightScaling = _imageHeight / _stageH;
                    break;
            }
            //
            screenVerts = new <Number>[	    -widthScaling, -heightScaling,   u, 1-v,
                                             widthScaling, -heightScaling, 1-u, 1-v,
                                             widthScaling,  heightScaling, 1-u,   v,
                                            -widthScaling,  heightScaling,   u,   v ];
            //
            widthScaling = _imageWidth / _stageW;
            heightScaling = _imageHeight / _stageH;
            var outputBitmapVerts:Vector.<Number> = new <Number>[	    -widthScaling, -heightScaling,   u, 1-v,
                                             widthScaling, -heightScaling, 1-u, 1-v,
                                             widthScaling,  heightScaling, 1-u,   v,
                                            -widthScaling,  heightScaling,   u,   v ];

            _renderToBitmapVertexBuffer.uploadFromVector(outputBitmapVerts, 0, 4);
            _renderToTextureVertexBuffer.uploadFromVector(textureVerts, 0, 4);
            _renderToScreenVertexBuffer.uploadFromVector(screenVerts, 0, 4);
        }

        protected function scaleWithAspect(w:Number, h:Number, x:Number, y:Number, fill:Boolean = true):Point
        {
            var nw:int = y * w / h;
            var nh:int = x * h / w;
            if (int(fill) ^ int(nw >= x)) return new Point(nw || 1, y);
            return new Point(x, nh || 1);
        }
        public function uploadBitmap(bmp:BitmapData):void
        {
            if (!_textureBmp) {
                (_texture).uploadFromBitmapData(bmp);
                return;
            }

            _textureBmp.copyPixels(bmp, _imageRect, _textureCopyPoint);
            (_texture).uploadFromBitmapData(_textureBmp);
        }
        public function uploadBytes(ba:ByteArray, offset:uint):void
        {
            (_texture).uploadFromByteArray(ba, offset, 0);
        }

        public function render(useProcessors:Boolean = true, target:TextureBase = null, targetClear:Boolean = false, targetEnableDepthAndStencil:Boolean = false):void
        {
            var n:int = _processorsCount;
            
            if (useProcessors && n)
            {
                _context.setVertexBufferAt(0, _renderToTextureVertexBuffer, 0, FLOAT2_FORMAT);
                _context.setVertexBufferAt(1, _renderToTextureVertexBuffer, 2, FLOAT2_FORMAT);
                
                var proc:IGPUImageProcessor = _processors[0];

                proc.process(_indexBuffer);

                for(var i:int = 1; i < n; ++i)
                {
                    proc = _processors[i];
                    proc.process(_indexBuffer);
                }

                if(!target)
                {
                    _context.setRenderToBackBuffer();
                } else {
                    _context.setRenderToTexture(target, targetEnableDepthAndStencil, _antiAlias, 0);
                    if(targetClear) _context.clear(0.0, 0.0, 0.0, 1.0);
                }
            }
            else if(target)
            {
                _context.setRenderToTexture(target, targetEnableDepthAndStencil, _antiAlias, 0);
                if(targetClear) _context.clear(0.0, 0.0, 0.0, 1.0);
            }
            
            if(_dirty)
            {
                _dirty = 0; // clear flag
                _screenFilter.transformImage(_x,  _y, _scaleX, _scaleY, 0, 1);
            }
            
            /*if (target)
            {
                _context.setVertexBufferAt(0, _renderToTextureVertexBuffer, 0, FLOAT2_FORMAT);
                _context.setVertexBufferAt(1, _renderToTextureVertexBuffer, 2, FLOAT2_FORMAT);
            }
            else
            {*/
                _context.setVertexBufferAt(0, _renderToScreenVertexBuffer, 0, FLOAT2_FORMAT);
                _context.setVertexBufferAt(1, _renderToScreenVertexBuffer, 2, FLOAT2_FORMAT);
            //}

            _screenFilter.process(_indexBuffer, useProcessors ? null : _texture);

            _context.setTextureAt(0, null);
            _context.setVertexBufferAt(0, null, 0, null);
            _context.setVertexBufferAt(1, null, 0, null);
        }

        public function renderToBitmapData(bmp:BitmapData):void
        {
            var n:int = _processorsCount;
            var proc:IGPUImageProcessor = null;
            if (n)
            {
                _context.setVertexBufferAt(0, _renderToTextureVertexBuffer, 0, FLOAT2_FORMAT);
                _context.setVertexBufferAt(1, _renderToTextureVertexBuffer, 2, FLOAT2_FORMAT);

                proc = _processors[0];

                proc.process(_indexBuffer);

                for(var i:int = 1; i < n; ++i)
                {
                    proc = _processors[i];
                    proc.process(_indexBuffer);
                }

                _context.setRenderToBackBuffer();
            }

            // render to bitmap
            //_screenFilter.transformImage(0, 0, 1, 1, 0, 1);
            
            if (bmp.width == _stageW && bmp.height == _stageH)
            {
                _context.setVertexBufferAt(0, _renderToScreenVertexBuffer, 0, FLOAT2_FORMAT);
                _context.setVertexBufferAt(1, _renderToScreenVertexBuffer, 2, FLOAT2_FORMAT);
            } else {
                _context.setVertexBufferAt(0, _renderToBitmapVertexBuffer, 0, FLOAT2_FORMAT);
                _context.setVertexBufferAt(1, _renderToBitmapVertexBuffer, 2, FLOAT2_FORMAT);
            }

            _screenFilter.process(_indexBuffer);

            _context.setTextureAt(0, null);
            _context.setVertexBufferAt(0, null, 0, null);
            _context.setVertexBufferAt(1, null, 0, null);

            if (bmp.width == _stageW && bmp.height == _stageH)
            {
                _context.drawToBitmapData(bmp);
            }
            else
            {
                var stageBmp:BitmapData = new BitmapData(_stageW, _stageH, false, 0x00);
                
                _context.drawToBitmapData(stageBmp);
                
                bmp.copyPixels(stageBmp,
                    new Rectangle((_stageW-_imageWidth)*0.5, (_stageH-_imageHeight)*0.5, _imageWidth,_imageHeight),
                    new Point());

                stageBmp.dispose();
                stageBmp = null;
            }
            
            //
            // render to screen
            //_screenFilter.transformImage(_x,  _y, _scaleX, _scaleY, 0, 1);
            _context.setTextureAt(0, proc ? proc.outputTexture : _texture);
            _context.setVertexBufferAt(0, _renderToScreenVertexBuffer, 0, FLOAT2_FORMAT);
            _context.setVertexBufferAt(1, _renderToScreenVertexBuffer, 2, FLOAT2_FORMAT);

            _screenFilter.process(_indexBuffer);

            _context.setTextureAt(0, null);
            _context.setVertexBufferAt(0, null, 0, null);
            _context.setVertexBufferAt(1, null, 0, null);
        }

        protected var _processors:Vector.<IGPUImageProcessor> = new <IGPUImageProcessor>[];
        protected var _processorsCount:int = 0;

        public function addProcessor(proc:IGPUImageProcessor):void
        {
            _processors.push(proc);
            _processorsCount++;
            //
            proc.setup(_context, textureWidth, textureHeight);
            proc.antiAlias = _antiAlias;
            proc.enableDepthAndStencil = _enableDepthAndStencil;
            updateProcessorGroup();
        }
        public function removeProcessorAt(ind:int):void
        {
            if (_processorsCount > ind)
            {
                _processors.splice(ind, 1);
                _processorsCount--;
                updateProcessorGroup();
            }
        }
        public function removeProcessor(proc:IGPUImageProcessor):void
        {
            var ind:int = _processors.indexOf(proc);
            if (ind != -1)
            {
                _processors.splice(ind, 1);
                _processorsCount--;
                updateProcessorGroup();
            }
        }
        public function removeAllProcessors():void
        {
            _processors.length = 0;
            _processorsCount = 0;
            updateProcessorGroup();
        }

        protected function updateProcessorGroup():void
        {
            var n:int = _processorsCount;

            if(n)
            {
                var last:IGPUImageProcessor = _processors[n-1];
                var prev:IGPUImageProcessor = _processors[0];

                prev.inputTexture = _texture;
                for(var i:int = 1; i < n; ++i)
                {
                    var f:IGPUImageProcessor = _processors[i];
                    f.inputTexture = prev.outputTexture;
                    
                    prev = f;
                }

                _screenFilter.inputTexture = last.outputTexture;
            }
            else
            {
                _screenFilter.inputTexture = _texture;
            }
        }
        
        public function dispose():void
        {
            if (_indexBuffer)
            {
                _indexBuffer.dispose();
                _renderToScreenVertexBuffer.dispose();
                _renderToTextureVertexBuffer.dispose();
                _renderToBitmapVertexBuffer.dispose();
                _renderToScreenVertexBuffer = null;
                _renderToTextureVertexBuffer = null;
                _renderToBitmapVertexBuffer = null;
                _indexBuffer = null;

                if(_textureBmp)_textureBmp.dispose();
                if(_texture)_texture.dispose();
                _textureBmp = null;
                _texture = null;
            }
            _initialized = false;
        }

        public function get x():Number { return _x; }
        public function set x(value:Number):void
        {
            _dirty |= int(_x != value) << 1;
            _x = value;
        }

        public function get y():Number { return _y; }
        public function set y(value:Number):void
        {
            _dirty |= int(_y != value) << 1;
            _y = value;
        }

        public function get scaleX():Number { return _scaleX; }
        public function set scaleX(value:Number):void
        {
            _dirty |= int(_scaleX != value) << 1;
            _scaleX = value;
        }

        public function get scaleY():Number { return _scaleY; }
        public function set scaleY(value:Number):void
        {
            _dirty |= int(_scaleY != value) << 1;
            _scaleY = value;
        }

        public function set enableDepthAndStencil(value:Boolean):void
        {
            _enableDepthAndStencil = value;
            var n:int = _processorsCount;
            for (var i:int = 0; i < n; ++i)
            {
                _processors[i].enableDepthAndStencil = value;
            }
        }

        public function set antiAlias(value:int):void
        {
            _antiAlias = value;
            var n:int = _processorsCount;
            for (var i:int = 0; i < n; ++i)
            {
                _processors[i].antiAlias = value;
            }
        }

        public function get imageWidth():Number { return _imageWidth; }
        public function get imageHeight():Number { return _imageHeight; }
        public function get textureWidth():Number { return _textureWidth; }
        public function get textureHeight():Number { return _textureHeight; }
        
        public function get gpuTexture():Texture { return _texture; }

        public static function nextPowerOfTwo(v:uint):uint
        {
            v--;
            v |= v >> 1;
            v |= v >> 2;
            v |= v >> 4;
            v |= v >> 8;
            v |= v >> 16;
            v++;
            return v;
        }
    }
}
