/*************************************************************************************/
//Class: Axis. This is an abstraction. Don't instantiate
function Axis(min, max, majorUnit, minorUnit,title){
	this.displayMajor=null;
	this.displayMinor=null;

	//Called by descendents
	this.init = function(min, max, majorUnit, minorUnit,title)
	{
		this.min=min;
		this.max=max;
		this.minorUnit=minorUnit;
		this.majorUnit=majorUnit;
		this.title=title;
	}

	//Display options for each axis unit, possible values: guides, marks, none
	this.setDisplayOptions = function(major, minor)
	{
		this.displayMajor = major;
		this.displayMinor = minor;
	}
}
/*************************************************************************************/
//Class: Vertical Axis. Abstract.
VerticalAxis.prototype = new Axis();

function VerticalAxis(min, max, majorUnit, minorUnit){
	this.init(min, max, majorUnit, minorUnit);
}

//Conversion from data coordinates to view coordinates
VerticalAxis.prototype.valueToY = function(value)
{
	return 430-(380/(this.max-this.min))*value;
}

//Displays the vertical Axis
VerticalAxis.prototype.display = function(svg)
{
	var x,y;

	svg.getElementById("axis").appendChild(line(svg, this.axisX,this.valueToY(this.min),this.axisX,this.valueToY(this.max),"black", 1));
	svg.getElementById("axis").appendChild(text(svg, this.title, this.titleX,240,"black",18,{"text-anchor" : "middle","transform" : "rotate("+this.titleRotation+","+this.titleX+",240)"}));

	//minor unit display options
	if(this.displayMinor != "none")
	{
		x= (this.displayMinor == "guides")?this.maxX:this.axisX;

		for(y=Math.ceil(this.min/this.minorUnit)*this.minorUnit;y<=this.max;y+=this.minorUnit)
		{
			svg.getElementById("guides").appendChild(line(svg, this.minorMarkX,this.valueToY(y),x,this.valueToY(y),"lightblue", 0.5));
		}
	}
	//major unit display options
	if(this.displayMajor != "none")
	{
		x= (this.displayMajor == "guides")?this.maxX:this.axisX;

		for(y=Math.ceil(this.min/this.majorUnit)*this.majorUnit;y<=this.max;y+=this.majorUnit)
		{
			svg.getElementById("guides").appendChild(line(svg, this.majorMarkX,this.valueToY(y),x,this.valueToY(y),"gray", 1));
			svg.getElementById("guides").appendChild(text(svg, Math.round(y*10000)/10000, this.textX,this.valueToY(y),"black",10,{"text-anchor" : this.anchor}));
		}
	}
}

/*************************************************************************************/
//Class: YAxis (left side vertical axis)
YAxis.prototype = new VerticalAxis();
function YAxis(min, max, majorUnit, minorUnit,title){
	this.init(min, max, majorUnit, minorUnit,title);
	this.maxX = 590;
	this.axisX = 50;
	this.minorMarkX = 43;
	this.majorMarkX = 40;
	this.textX = 38;
	this.anchor = "end";
	this.titleX = -20;
	this.titleRotation = -90;
}

/*************************************************************************************/
//Class: ZAxis (right side vertical axis)
ZAxis.prototype = new VerticalAxis();
function ZAxis(min, max, majorUnit, minorUnit, title){
	this.init(min, max, majorUnit, minorUnit,title);
	this.maxX = 50;
	this.axisX = 590;
	this.minorMarkX = 597;
	this.majorMarkX = 600;
	this.textX = 602;
	this.anchor = "start";
	this.titleX = 660;
	this.titleRotation = 90;
}

/*************************************************************************************/
var SVGC_MONTH = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
//Class: XTimeAxis (defines an x axis of time units)
XTimeAxis.prototype = new Axis();
//min, max are Date objects.
//majorUnit, minorUnit take valuees: months, weeks (TODO: implement days and years?)
function XTimeAxis(min, max, majorUnit, minorUnit,title){
	this.init(min, max, majorUnit, minorUnit,title);
}

XTimeAxis.prototype.valueToX = function(value)
{
	return 50+540*(value.getTime()-this.min.getTime())/(this.max.getTime()-this.min.getTime()+(24*3600*1000));
}

XTimeAxis.prototype.display = function(svg)
{
	var maxY;

	svg.getElementById("axis").appendChild(line(svg, 50,430,590,430,"black", 1));

	if(this.displayMajor != "none")
	{
		maxY = (this.displayMajor=="guides")?50:430;
		switch(this.majorUnit)
		{
			case "months":
				this.displayMonths(svg, "gray", 1, true,440, maxY);
				break;
			case "weeks":
				this.displayWeeks(svg, "gray", 1, true,440, maxY);
				break;
		}
	}

	if(this.displayMinor != "none")
	{
		maxY = (this.displayMinor=="guides")?50:430;
		switch(this.minorUnit)
		{
			case "months":
				this.displayMonths(svg, "lightblue", 0.5,  false,437, maxY);
				break;
			case "weeks":
				this.displayWeeks(svg, "lightblue", 0.5, false,437, maxY);
				break;
			case "days":
			    this.displayPeriod(svg, "lightblue", 0.5, false,437, maxY, new Date(this.min.getTime()), SVGC_PERIOD_DAY);
				break;
		}
	}
}

XTimeAxis.prototype.displayWeeks = function(svg, color, strokeWidth, displayText, minY, maxY)
{
	var x;
	var sundays = new Date();
	sundays.setTime(this.min.getTime()+(7-this.min.getDay())*24*3600*1000);

	this.displayPeriod(svg, color, strokeWidth, displayText, minY, maxY, sundays, SVGC_PERIOD_WEEK);
}

XTimeAxis.prototype.displayPeriod = function(svg, color, strokeWidth, displayText, minY, maxY, moment, period)
{
    while(moment<this.max)
	{
		x = this.valueToX(moment);

		svg.getElementById("guides").appendChild(line(svg, x,minY,x,maxY,color, strokeWidth));

		moment.setTime(moment.getTime()+period);
	}
}

XTimeAxis.prototype.displayMonths = function(svg, color, strokeWidth, displayText, minY, maxY)
{
	var x;

	initYear=this.min.getFullYear();
	initMonth=this.min.getMonth();

	finalYear=this.max.getFullYear();
	finalMonth=this.max.getMonth();

	if(finalMonth == 11)
	{
		finalMonth=0;
		finalYear++;
	}
	else
	{
		finalMonth++;
	}

	for(year=initYear;year<=finalYear;year++)
	{
		for(month=(year==initYear?initMonth:0);month<=(year==finalYear?finalMonth:11);month++)
		{
			d = new Date(year, month, 1);
			x = this.valueToX(d);

			if(x>=49 && x<=591)
			{
				svg.getElementById("guides").appendChild(line(svg, x,minY,x,maxY,color, strokeWidth));
				if(displayText)
				{
					str = SVGC_MONTH[month]+" - "+year;
					svg.getElementById("guides").appendChild(text(svg, str, x+4, 450, "black", 10, {"text-anchor" :"end", "transform" : "rotate(-40,"+x+",442)"}));
				}
			}
		}
	}
}

