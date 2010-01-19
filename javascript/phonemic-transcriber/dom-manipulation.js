function prepare()
{
    var iframe = $('iframe#iframe').get()[0];
    iframe.onload = function() {
//	var iframe = $('iframe#iframe').get()[0];
      var doc = iframe.contentWindow ? iframe.contentWindow.document : iframe.contentDocument ? iframe.contentDocument : iframe.document;
      var textnodes = doc.evaluate("//text()", doc, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);

      for (var j = 0; j < textnodes.snapshotLength; j++) {
	var node = textnodes.snapshotItem(j);
	node.parentNode.replaceChild(transcribe(node.data),
				     node);
      }
    };

    $('form').submit(function () {
      $('#info').html("Loading...");
    //	    iframe.attr('src', "/proxy/index.php?q=" + $('input#url_address').attr('value'));
      iframe.src = "/proxy/index.php?q=" + $('input#url_address').attr('value');
      return false;
    });
}