/*************************************************************************************/
//Class: Chart, chartName is the svg object or embed where the chart skeleton is.
function Chart(chartName){
	this.xAxis=null;
	this.yAxis=null;
	this.zAxis=null;
	this.autoYAxis = true; this.autoYAxisTitle = ""; this.autoYAxisDisplayMajor = null; this.autoYAxisDisplayMinor = null;
	this.autoZAxis = true; this.autoZAxisTitle = ""; this.autoZAxisDisplayMajor = null; this.autoZAxisDisplayMinor = null;

	this.yDataSeries={};
	this.zDataSeries={};

	this.getSVG = function(chartName)
    {
		var obj = document.getElementById(chartName);

		if(obj && obj.contentDocument)
		{
			return obj.contentDocument;
		}
		else
		{
			try{
				return obj.getSVGDocument();
			}catch(e){
				alert("Not supported.")
				return null;
			}
		}
  	}

    this.svg = this.getSVG(chartName);

    this.setXAxis = function(xAxis)
    {
            this.xAxis = xAxis;
    }

    this.setYAxis = function(yAxis)
    {
        if(yAxis == "auto")
        {
            this.autoYAxis = true;
        }
        else
        {
            this.autoYAxis = false;
            this.yAxis = yAxis;
        }
    }

    this.setZAxis = function(zAxis)
    {
        if(zAxis == "auto")
        {
            this.autoZAxis = true;
        }
        else
        {
            this.autoZAxis = false;
            this.zAxis = zAxis;
        }
    }

    this.display = function()
    {
		var i, max, dsm, x, y;

		//Clear all

		clearElement(this.svg, "charts");
		clearElement(this.svg, "guides");
		clearElement(this.svg, "axis");

		//Plot x axis
		if(this.xAxis != null)
		  this.xAxis.display(this.svg);

        //Plot y axis
		if(this.autoYAxis)  //Auto axis
		{
		  this.yAxis = createAutoAxis(YAxis, this.yDataSeries, this.autoYAxisTitle);
		 	if(this.yAxis != null) this.yAxis.setDisplayOptions(this.autoYAxisDisplayMajor,this.autoYAxisDisplayMinor);
		}
		if(this.yAxis != null)
		{
		  this.yAxis.display(this.svg);

		  //Plot y data series
		  for(i in this.yDataSeries)
		    this.yDataSeries[i].plot(this.svg, this.xAxis, this.yAxis);

			//Plot Leyend
			n = 0;
			for(i in this.yDataSeries)
			{
			  x = 125*(n%5);
			  y = 512+23*Math.floor(n/5);
			  //this.svg.getElementById("guides").appendChild(rect(this.svg, x, y, 30, 10, this.yDataSeries[i].color, "black", 1, {}));
			  this.svg.getElementById("guides").appendChild(rect(this.svg, x, y, 30, 10, this.yDataSeries[i].color, this.yDataSeries[i].color	, 1, {}));
			  this.svg.getElementById("guides").appendChild(text(this.svg, this.yDataSeries[i].leyendText, x+35, y+8, "black", 10, {}));
			  n++;
			}
		}

        //Plot z axis
    if(this.autoZAxis)  //Auto axis
    {
		  this.zAxis = createAutoAxis(ZAxis, this.zDataSeries, this.autoZAxisTitle);
		  if(this.zAxis != null) this.zAxis.setDisplayOptions(this.autoZAxisDisplayMajor,this.autoZAxisDisplayMinor);
		}
		if(this.zAxis != null)
		{
		  this.zAxis.display(this.svg);

		  //Plot z data series
		  for(i in this.zDataSeries)
		    this.zDataSeries[i].plot(this.svg, this.xAxis, this.zAxis);

		  for(i in this.zDataSeries)
			{
			  x = 125*(n%5);
			  y = 512+23*Math.floor(n/5);
			  this.svg.getElementById("guides").appendChild(rect(this.svg, x, y, 30, 10, this.zDataSeries[i].color, this.zDataSeries[i].color, 1, {}));
			  this.svg.getElementById("guides").appendChild(text(this.svg, this.zDataSeries[i].leyendText, x+35, y+8, "black", 10, {}));
			  n++;
			}
		}
  }
}

function autoAxis(maxValue, classname, title)
{
    var mul, n, max, major, minor;

    if(maxValue == 0)
        return new classname(0, 1, 0.2, 0.1, title);

    if(maxValue > 0)
    {
      mul = Math.pow(10,Math.ceil(Math.log(maxValue)*Math.LOG10E)-2);
	    n = maxValue/mul;    //n = two most significant digits (0-100)

	    max = (Math.floor(n/5)+1)*5*mul;
	  }
	  if(maxValue < 0)
    {
      mul = Math.pow(10,Math.ceil(Math.log(-maxValue)*Math.LOG10E)-2);
	    n = maxValue/mul;    //n = two most significant digits (0-100)

	    max = -(Math.floor(n/5)+1)*5*mul;
	  }

    major = (n>25)?mul * 10:mul*5;
    minor = mul * 2.5;

    return new classname(0, max, major, minor, title);
}

function createAutoAxis(classname, dataSeries, title)
{
  var max = -10e10;

  for(i in dataSeries)
  {
    dsm = dataSeries[i].maxValue();
    max = ((dsm>max)?dsm:max);
  }
  if(max > -10e10)
    return autoAxis(max, classname, title);
  else
    return null;
}

