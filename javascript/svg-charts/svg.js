var svgNS = "http://www.w3.org/2000/svg";  //Namespace

// Creates an svg element
// svg is the svgDocument object
// type is the kind of elemnt to create
// options is a hash of attributes
// Example: svgObject(svgDoc, "rect", {"x":20, "y":40, "width":100, "height":100})
function svgObject(svg, type, options)
{
	var obj = svg.createElementNS(svgNS,type);
	
	for(key in options)
		obj.setAttributeNS(null,key,options[key]);
		
	return obj;
}

function appendElement(svg, where, type, options)
{
	svg.getElementById(where).appendChild(svgObject(svg, type, options));
}

//Clear element content
function clearElement(svg, elementId)
{
	var parent =  svg.getElementById(elementId);		
	var children = parent.childNodes;
			
	while(parent.hasChildNodes())
		parent.removeChild(parent.firstChild);	
}

//Creates an svg rect
function rect(svg, x, y, width, height, fill, stroke, strokewidth, options) {
  var obj = svg.createElementNS(svgNS,"rect");
  obj.setAttributeNS(null,"x",x);	
  obj.setAttributeNS(null,"y",y);		
  obj.setAttributeNS(null,"width",width);		
  obj.setAttributeNS(null,"height",height);			  
  obj.setAttributeNS(null,"fill",fill);			  
  obj.setAttributeNS(null,"stroke",stroke);
  obj.setAttributeNS(null,"stroke-width",strokewidth);
  for(key in options)
		obj.setAttributeNS(null,key,options[key]);
  return obj;			  
}

//Creates an svg line
function line(svg, x1,y1,x2,y2,stroke,strokewidth) {
  var obj = svg.createElementNS(svgNS,"line");
  obj.setAttributeNS(null,"x1",x1);	
  obj.setAttributeNS(null,"y1",y1);		
  obj.setAttributeNS(null,"x2",x2);		
  obj.setAttributeNS(null,"y2",y2);			  
  obj.setAttributeNS(null,"stroke",stroke);
  obj.setAttributeNS(null,"stroke-width",strokewidth);
  return obj;			  
}
//Creates an svg text. Options is a hash of optional attributes. For example {"text-anchor" : "end"}
function text(svg, text,x,y,fill,fontsize,options) {
  var obj = svg.createElementNS(svgNS,"text");
  obj.setAttributeNS(null,"x",x);	
  obj.setAttributeNS(null,"y",y);		
  obj.setAttributeNS(null,"fill",fill);		
  obj.setAttributeNS(null,"font-size",fontsize);
  
  for(key in options)
		obj.setAttributeNS(null,key,options[key]);
	
  var textNode = svg.createTextNode(text);
  obj.appendChild(textNode);
  return obj;			  
}

