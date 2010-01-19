/*******************************************************************************/
//Class: Defines an abstract data series
function DataSeries()
{
    this.init = function(leyendText, data, color)
    {
        this.leyendText = leyendText;
        this.data = data;
        this.color = color;
    }

    this.maxValue = function()
    {
        var max = this.data[1];
        for( var i = 1; i<this.data.length; i+=2)
        {
            if(this.data[i]>max)
                max = this.data[i];
        }

        return max;
    }

    this.minValue = function()
    {
        var min = this.data[1];
        for( var i = 1; i<this.data.length; i+=2)
        {
            if(this.data[i]>min)
                min = this.data[i];
        }

        return min;
    }

    this.getLeyendText = function()
    {
        return this.leyendText;
    }

    this.getColor = function()
    {
        return this.color;
    }

}
/*******************************************************************************/
//Class: Defines a data series to plot as a line
LineDataSeries.prototype = new DataSeries();
LineDataSeries.prototype.constructor = LineDataSeries;
LineDataSeries.prototype.parent = DataSeries.prototype;

function LineDataSeries(leyendText, data, color, markers)
{
    this.markers = markers;
    this.init(leyendText, data, color);
}


LineDataSeries.prototype.plot = function(svg, xAxis, yAxis)
{
	var i,str, x, y, options;

	x = xAxis.valueToX(this.data[0]);
	y = yAxis.valueToY(this.data[1]);

	str = "M "+x+" "+y;
	for(i=2;i<this.data.length;i+=2)
	{
		x = xAxis.valueToX(this.data[i]);
		y = yAxis.valueToY(this.data[i+1]);
		str += " L "+x+" "+y;
	}

	if(this.markers)
	 options = {"d":str, "fill":"none", "stroke":this.color, "stroke-width":2, "marker-start":"url(#marker)", "marker-mid":"url(#marker)", "marker-end":"url(#marker)"};
	else
	 options = {"d":str, "fill":"none", "stroke":this.color, "stroke-width":2};

	svg.getElementById("charts").appendChild(svgObject(svg, "path", options));
}

/*******************************************************************************/
//Class: Defines a data series to plot as an area
AreaDataSeries.prototype = new DataSeries();
AreaDataSeries.prototype.constructor = AreaDataSeries;
AreaDataSeries.prototype.parent = DataSeries.prototype;

function AreaDataSeries(leyendText, data, color, markers)
{
    this.markers = markers;
    this.init(leyendText, data, color);
}


AreaDataSeries.prototype.plot = function(svg, xAxis, yAxis)
{
	var i,str, x, y, options;

	x = xAxis.valueToX(this.data[0]);
	y = yAxis.valueToY(this.data[1]);

	str = "M "+x+" 430 L "+x+" "+y;
	for(i=2;i<this.data.length;i+=2)
	{
		x = xAxis.valueToX(this.data[i]);
		y = yAxis.valueToY(this.data[i+1]);
		str += " L "+x+" "+y;
	}
	str += " L "+x+" "+430;

	if(this.markers)
	 options = {"fill-opacity":0.2, "d":str, "fill":this.color, "stroke":this.color, "stroke-width":2, "marker-mid":"url(#marker)"};
	else
	 options = {"fill-opacity":0.2, "d":str, "fill":this.color, "stroke":this.color, "stroke-width":2};

	svg.getElementById("charts").appendChild(svgObject(svg, "path", options));
}

/*******************************************************************************/
//Class: Defines a data series to plot as bars
var SVGC_PERIOD_DAY = 86400000; // 24*3600*1000
var SVGC_PERIOD_WEEK = 604800000; // 7*24*3600*1000
var SVGC_PERIOD_MONTH = 2592000000; // 30*24*3600*1000

BarsDataSeries.prototype = new DataSeries();
BarsDataSeries.prototype.constructor = BarsDataSeries;
BarsDataSeries.prototype.parent = DataSeries.prototype;

function BarsDataSeries(leyendText, data, period, color)
{
    switch(period)
    {
       case "DAY":
            this.period = SVGC_PERIOD_DAY;
            break;
        case "WEEK":
            this.period = SVGC_PERIOD_WEEK;
            break;
        case "MONTH":
            this.period = SVGC_PERIOD_MONTH;
            break;
    }

    this.init(leyendText, data, color);
}

BarsDataSeries.prototype.plot = function(svg, xAxis, yAxis)
{
	var i, x, y, width, offset, options, d;

    options = {};

    d = new Date(xAxis.min.getTime()+this.period);
	width = xAxis.valueToX(d) - xAxis.valueToX(xAxis.min);
	offset = width * -0.375;
	width = width * 0.75;

	for(i=0;i<this.data.length;i+=2)
	{
		x = xAxis.valueToX(this.data[i])+offset;
		y = yAxis.valueToY(this.data[i+1]);
//		svg.getElementById("charts").appendChild(rect(svg, x, y, width, 430-y, this.color, "black", 0.5, options));
		svg.getElementById("charts").appendChild(rect(svg, x, y, width, 430-y, this.color, this.color, 0.5, options));
	}
}

