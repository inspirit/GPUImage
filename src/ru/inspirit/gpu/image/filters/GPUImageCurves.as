package ru.inspirit.gpu.image.filters
{
    import flash.display.BitmapData;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    public class GPUImageCurves extends GPUImageLUT
    {
        public static const CURVE_INTERPOLATION_LINEAR:uint = 0;
        public static const CURVE_INTERPOLATION_SMOOTH:uint = 1;
        
        public static const CURVE_CHANNEL_RED:int = 2; // 1 << 1
        public static const CURVE_CHANNEL_GREEN:int = 4; // 1 << 2
        public static const CURVE_CHANNEL_BLUE:int = 8; // 1 << 3
        public static const CURVE_CHANNEL_RGB:int = 14; // 2 | 4 | 8

        // using array cause of sort routine :)
        // dont wnat to use custom sort function
        protected var _redPoints:Array;
        protected var _greenPoints:Array;
        protected var _bluePoints:Array;

        protected var _interpolation:uint;

        public function GPUImageCurves(interpolation:uint = CURVE_INTERPOLATION_SMOOTH)
        {
            super();

            _redPoints = new Array;
            _greenPoints = new Array;
            _bluePoints = new Array;

            _interpolation = interpolation;

            clearCurve(CURVE_CHANNEL_RGB);
        }

        public function update():void
        {
            var redPalette:Array = calculateCurveLUT(_redPoints, 16);
            var greenPalette:Array = calculateCurveLUT(_greenPoints, 8);
            var bluePalette:Array = calculateCurveLUT(_bluePoints, 0);

            setupLUTTexture(redPalette, greenPalette, bluePalette);
        }

        public function renderCurves():BitmapData
        {
            var gridColor:uint = 0xCCCCCC;
            var render:BitmapData = new BitmapData(256, 256, false, 0xDDDDDD);
            var i:int = 0;
            while (i < 0x0100) {
                render.setPixel(i, 0, gridColor);
                render.setPixel(i, 64, gridColor);
                render.setPixel(i, 128, gridColor);
                render.setPixel(i, 192, gridColor);
                render.setPixel(i, 0xFF, gridColor);
                i++;
            }
            i = 0;
            while (i < 0x0100) {
                render.setPixel(0, i, gridColor);
                render.setPixel(64, i, gridColor);
                render.setPixel(128, i, gridColor);
                render.setPixel(192, i, gridColor);
                render.setPixel(0xFF, i, gridColor);
                i++;
            }

            renderCurve(calculateCurveLUT(_redPoints), _redPoints, render, 0xFF0000, 0xFF0000);
            renderCurve(calculateCurveLUT(_greenPoints), _greenPoints, render, 0x00FF00, 0x00FF00);
            renderCurve(calculateCurveLUT(_bluePoints), _bluePoints, render, 0x0000FF, 0x0000FF);

            return render;
        }
        
        public function addCurvePoint(channel:int, ...points):void
        {
            var n:int = points.length;
            var i:int;
            if (channel == CURVE_CHANNEL_RGB)
            {
                for(i = 0; i < n; ++i)
                {
                    _redPoints.push(points[i]);
                    _greenPoints.push(points[i]);
                    _bluePoints.push(points[i]);
                }
            }
            else if (channel & CURVE_CHANNEL_RED)
            {
                for(i = 0; i < n; ++i)
                {
                    _redPoints.push(points[i]);
                }
            }
            else if (channel & CURVE_CHANNEL_GREEN)
            {
                for(i = 0; i < n; ++i)
                {
                    _greenPoints.push(points[i]);
                }
            }
            else if (channel & CURVE_CHANNEL_BLUE)
            {
                for(i = 0; i < n; ++i)
                {
                    _bluePoints.push(points[i]);
                }
            }
        }

        public function removeCurvePoint(channel:int, point:Point):void
        {
            var n:int;
            var i:int;
           
            if (channel == CURVE_CHANNEL_RGB)
            {
                n = _redPoints.length;
                for(i = 0; i < n; ++i)
                {
                    if(point.equals(_redPoints[i]))
                    {
                        _redPoints.splice(i,  1);
                        break;
                    }
                }
                //
                n = _greenPoints.length;
                for(i = 0; i < n; ++i)
                {
                    if(point.equals(_greenPoints[i]))
                    {
                        _greenPoints.splice(i,  1);
                        break;
                    }
                }
                //
                n = _bluePoints.length;
                for(i = 0; i < n; ++i)
                {
                    if(point.equals(_bluePoints[i]))
                    {
                        _bluePoints.splice(i,  1);
                        break;
                    }
                }
            }
            else if (channel & CURVE_CHANNEL_RED)
            {
                n = _redPoints.length;
                for(i = 0; i < n; ++i)
                {
                    if(point.equals(_redPoints[i]))
                    {
                        _redPoints.splice(i,  1);
                        break;
                    }
                }
            }
            else if (channel & CURVE_CHANNEL_GREEN)
            {
                n = _greenPoints.length;
                for(i = 0; i < n; ++i)
                {
                    if(point.equals(_greenPoints[i]))
                    {
                        _greenPoints.splice(i,  1);
                        break;
                    }
                }
            }
            else if (channel & CURVE_CHANNEL_BLUE)
            {
                n = _bluePoints.length;
                for(i = 0; i < n; ++i)
                {
                    if(point.equals(_bluePoints[i]))
                    {
                        _bluePoints.splice(i,  1);
                        break;
                    }
                }
            }
        }

        public function clearCurve(channel:int):void
        {
            if (channel == CURVE_CHANNEL_RGB)
            {
                _redPoints.length = 0;
                _greenPoints.length = 0;
                _bluePoints.length = 0;
            }
            else if (channel & CURVE_CHANNEL_RED)
            {
                _redPoints.length = 0;
            }
            else if (channel & CURVE_CHANNEL_GREEN)
            {
                _greenPoints.length = 0;
            }
            else if (channel & CURVE_CHANNEL_BLUE)
            {
                _bluePoints.length = 0;
            }
        }
        
        public function get interpolation():uint { return _interpolation; }
        public function set interpolation(value:uint):void
        {
            _interpolation = value;
        }

        // original implementation by Joa Ebert
        // from popforge image processing lib
        // but looks like i overwrote it mostly
        protected function calculateCurveLUT(points:Array, shift:int = 0):Array
        {
            var table:Array;
            var pnts:Array;
            var p0:Point;
            var p1:Point;
            var i:int;
            var t0:Number;
            var t1:Number;
            var x:int;
            var y:int;
            var n:int;

            table = new Array(0x0100);
            
            if (points.length == 0){
                i = 0;
                while (i < 0x0100) 
                {
                    table[i] = 0;
                    ++i;
                }
                return table;
            }

            pnts = points.slice();
            pnts.sortOn("x", Array.NUMERIC);
            n = pnts.length;
            if(pnts[n-1].x < 0xFF)
            {
                pnts.push(new Point(0xFF, pnts[n-1].y));
            }
            if(pnts[0].x > 0)
            {
                pnts.unshift(new Point(0, pnts[0].y));
            }
            n = pnts.length;

            switch(_interpolation)
            {
                default:
                case CURVE_INTERPOLATION_SMOOTH:
                    if (n > 2)
                    {
                        var spl:Spline = new Spline(pnts);
                        i = 0;
                        while (i < 256)
                        {
                            y = spl.interpolate(i) + 0.5;
                            table[i] = y < 0 ? 0 : (y > 0xFF ? 0xFF : y);
                            ++i;
                        }
                        break;
                    }
                    // otherwise just fall to linear
                case CURVE_INTERPOLATION_LINEAR:
                    --n;
                    i = 0;
                    while (i < n) {
                        p0 = pnts[i];
                        p1 = pnts[(i + 1)|0];
                        t0 = 0;
                        t1 = Math.abs((p1.x - p0.x));
                        if (t1 != 0){
                            x = p0.x;
                            while (x <= p1.x) 
                            {
                                y = p0.y + ((p1.y - p0.y) * (t0 / t1)) + 0.5;
                                table[x] = y < 0 ? 0 : (y > 0xFF ? 0xFF : y);
                                ++t0;
                                ++x;
                            }
                        }
                        ++i;
                    }
                    break;
            }

            i = 0x0100;
            while(--i > -1)
            {
                table[i] <<= shift;
            }

            return table;
        }

        protected function renderCurve(table:Array, points:Array, render:BitmapData, pointColor:int=0xFF00FF, lineColor:int=0x666666):void
        {
            var y0:int;
            var x:int;
            var i:int, n:int;
            var y:int;
            var ty:int;
            var p:Point;
            
            y0 = (0xFF - table[0]);
            x = 0;
            while (x < 0x0100) {
                y = (0xFF - table[x]);
                ty = y;
                render.setPixel(x, y, lineColor);
                if (ty > y0){
                    while (--ty > y0) {
                        render.setPixel(x, ty, lineColor);
                    }
                } else {
                    if (ty < y0){
                        while (++ty < y0) {
                            render.setPixel(x, ty, lineColor);
                        }
                    }
                }
                y0 = y;
                x++;
            }

            i = 0;
            n = points.length;
            var r:Rectangle = new Rectangle(0, 0, 5, 5);
            while (i < n) {
                p = points[i];
                r.x = p.x - 2;
                r.y = 0xFF - p.y - 2;
                render.fillRect(r, pointColor);
                i++;
            }
        }
    }
}

// Martin Heidegger found on wonderfl and gave it to me ;)
internal final class Spline 
{
    protected var num:int;
    
    protected var x:Vector.<Number>;
    protected var y:Vector.<Number>;
    protected var z:Vector.<Number>;
    
    public function Spline(points:Array):void
    {
        num = points.length;
        x = new Vector.<Number>(num, true);
        y = new Vector.<Number>(num, true);
        for (var i:int = 0; i < num; ++i)
        {
            x[i] = points[i].x;
            y[i] = points[i].y;
        }
        init();
    }
    
    protected function init():void
    {
        z = new Vector.<Number>(num);
        var h:Vector.<Number> = new Vector.<Number>(num);
        var d:Vector.<Number> = new Vector.<Number>(num);
        z[0]=z[num-1]=0;
        for (var i:int = 0; i < num - 1;++i)
        {
            h[i] = x[i+1]-x[i];
            d[i+1] = (y[i+1]-y[i])/ h[i];
        }
        z[1]=d[2]-d[1]-h[0]*z[0];
        d[1]=2*(x[2]-x[0]);
        for (i = 1; i < num - 2; ++i)
        {
            var t:Number = h[i]/d[i];
            z[i+1]=d[i+2]-d[i+1]-z[i]*t;
            d[i+1]=2*(x[i+2]-x[i])-h[i]*t;
        }
        z[num-2] -= h[num-2]*z[num-1];
        for (i = num - 2; i > 0; i--)
        {
            z[i]=(z[i]-h[i]*z[i+1])/d[i];
        }
    }
    
    public function interpolate(t:Number):Number
    {
        var i:int=0;
        var j:int=num-1;
        while(i<j){
            var k:int = (i+j) * 0.5;
            if(x[k]<t){
                i=k+1;
            }else{
                j = k;
            }
        }
        if(i>0)i--;
        var h:Number=x[i+1]-x[i];
        var d:Number= t - x[i];
        return (((z[i+1]-z[i])*d/h+z[i]*3)*d
                    +((y[i+1]-y[i])/ h
                    -(z[i]*2+z[i+1])*h))*d+y[i];
    }
}
