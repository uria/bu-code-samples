var sibilant_phonemes = ['s','z','S','Z','T','D'];
var voiced_phonemes = ['i','I','4','E','e','A', 'o','u','U','@','3','0','6','N','S','Z','L','D','z','w','s','d','r','v','g','j','n','m','l'];
var fortis_phonemes = ['f','t','p','k','8','s','S','T'];
var vowel_phonemes = ['i', 'I', 'e', 'a', '4', 'A', 'o', 'O', 'u', 'U', '@', '3', '0'];

/*
var phonemic_symbols = {'i' : "i&#720;",
			'I' : "&#618;",
			'4' : "&#652;",
			'E' : "\346",
			'A' : "&#593;&#720;",
			'o' : "&#596;&#720;",
			'O' : "&#594;",
			'u' : "&#650;",
			'U' : "u&#720;",
			'@' : "&#601;",
			'3' : "&#604;&#720;",
			'0' : "&#596;",
			'6' : "\360",
			'8' : "&#952;",
			'N' : "&#331;",
			'T' : "t&#643;",
			'D' : "d&#658;",
			'S' : "&#643;",
			'Z' : "&#658;",
			',' : "&#716;",
			"'" : "&#712;",
			'L' : "l&#809;",
			//  't' : "t&#812;",
			'?' : "&#660;",
			'*' : "<sup>&#601;</sup>"};
*/

var phonemic_symbols = {'i' : "iː", 'I' : "ɪ", '4' : "ʌ", 'E' : "\346", 'A' : "ɑː", 'o' : "ɔː", 'O' : "ɒ", 'u' : "ʊ", 'U' : "uː", '@' : "ə", '3' : "ɜː", '0' : "ɔ", '6' : "\360", '8' : "θ", 'N' : "ŋ", 'T' : "tʃ", 'D' : "dʒ", 'S' : "ʃ", 'Z' : "ʒ", ',' : "ˌ", "'" : "ˈ", 'L' : "l̩", /* 't' : "t̬", */ '?' : "ʔ", '*' : "ə"};

function is_vowel(phoneme) {
    return vowel_phonemes.indexOf(phoneme) != -1;
}

function is_voiced(phoneme) {
    return voiced_phonemes.indexOf(phoneme) != -1;
}

function is_sibilant(phoneme) {
    return sibilant_phonemes.indexOf(phoneme) != -1;
}

function is_fortis(phoneme) {
    return fortis_phonemes.indexOf(phoneme) != -1;
}

function is_alveolar_plosive(phoneme) {
  return phoneme == 'd' || phoneme == 't';
}

function last_phoneme(txt) {
  return txt.charAt(txt.length-1);
}


// I miss LISP so badly...
var inflections = [{'conditions' : ["_s", "_'s", "_s'"],
		    'additions'  : [["is_sibilant", "_Iz"], ["is_fortis", "_s"], "_z"]},
		   {'conditions' : ["_ly"],
		    'additions'  : ["li"]},
		   {'conditions' : ["_ed", "(.+e)d"],
		    'additions'  : [["is_alveolar_plosive", "_Id"], ["is_fortis", "_t"], "_d"]},
		   {'conditions' : ["_d"],
		    'additions'  : [["is_alveolar_plosive", "_Id"], ["is_fortis", "_t"], "_d"]},
		   {'conditions' : ["_ing"],
		    'additions'  : ["_IN"]}
		   ];

function parse_conditions(conditions) {
  return jQuery.map(conditions, function (c,i) {
		      return "(txt.match(" +
			("/^"+c+"$/").replace('_','(.+)') +
			") && (t = lexicon[RegExp.$1]))";
		    }).join(" || ");
}

function parse_additions(additions) {
  return  jQuery.map(additions, function (a,i) {
		       if(jQuery.isArray(a))
			 return "if("+a[0]+"(lp)) return '" + a[1] + "'.replace('_',t); ";
		       else
			 return "return '" + a + "'.replace('_',t); ";
		     }).join(" ");
}

function parse_inflection(inflection) {
  return "if(" + parse_conditions(inflection['conditions']) + ") { " +
    " lp = last_phoneme(t); " + parse_additions(inflection['additions']) +
      ' } ';
}

var transcribe_inflections = new Function('txt', "var t, lp; " +
					    jQuery.map(inflections, function(inf, i) {
							 return parse_inflection(inf);
						       }).join(" ") +
					    "return undefined;");

function Word(txt)
{
  var word = txt;
  var trans = undefined;

  var status = null;

/*
  function inflectional_s(text) {
    var t = undefined, lp = undefined;

    if((text.match(/^(.+)s$/) && (t = lexicon[RegExp.$1])) ||
      (text.match(/^(.+)'s$/) && (t = lexicon[RegExp.$1])) ||
      (text.match(/^(.+)s'$/) && (t = lexicon[RegExp.$1])))
      {
//	status = 'testing';
	lp = last_phoneme(t);
	if(is_sibilant(lp))
	  return t + 'Iz';
	else if(is_fortis(lp))
	  return t + 's';
	else
	  return t + 'z';
      }

    //In the ruby prototype I have a especial (.+)es case

    return undefined;
  }

  function inflectional_ed(text) {
    var t = undefined, lp = undefined;

    if((text.match(/^(.+)ed$/) && (t = lexicon[RegExp.$1])) ||
      (text.match(/^(.+e)d$/) && (t = lexicon[RegExp.$1])))
      {
//	status = 'testing';
	lp = last_phoneme(t);
	if(is_alveolar_plosive(lp))
	  return t + 'Id';
	else if(is_fortis(lp))
	  return t + 't';
	else
	  return t + 'd';
      }

    return undefined;
  }

  function inflectional_ing(text) {
    var t = undefined;

    //TODO: doubled final consonants not working, permitting,
    if(text.match(/^(.+)ing$/) && ((t = lexicon[RegExp.$1]) || (t = lexicon[RegExp.$1+'e'])))
      {
	status = 'testing';
	return t + 'IN';
      }

    return undefined;
  }
*/
  //Try to transcribe
  function transcribe() {
    var lower = word.toLowerCase();

    trans = lexicon[lower];
    if(trans == undefined) {
      trans = transcribe_inflections(lower);
      if(trans != undefined) status = 'testing';
    }
      // inflectional_s(lower) ||
      // inflectional_ing(lower) ||
      // inflectional_ed(lower);
  }

  this.to_dom_element = function()
  {
      var tmp = '';
      var i = 0, p, c;

      var element = document.createElement("span");

      if(trans) {
	  for(i=0;i<trans.length;i++) {
	      c = trans[i];
	      p = phonemic_symbols[c];
	      if(p) {
		  tmp = tmp + p;
	      }else {
		  tmp = tmp + c;
	      }
	  }
	element.title = word;
      }else{
	element.style.color = 'red';
	tmp = word;
      }

    if(status == 'testing') element.style.color = 'orange';

    element.appendChild(document.createTextNode(tmp));

    return element;
  };

  transcribe();
  return true;
}

function Separator(txt)
{
  this.word = txt;

  this.to_dom_element = function()
  {
      return document.createTextNode(this.word);
  };

  return true;
}

function is_alpha(c) {
  return (c >= 97 && c<= 122) || (c >= 65 && c <= 90);// || c == 39;
}

function is_apostrophe(c) {
  return c == 39;
}

function tokenize(text) {
    var tokens = new Array();
    var text_length = text.length;
    var token_length = 0;

    start = 0;

    while (start < text_length) {
	token_length = 0;
	while (start + token_length < text_length &&
	       ( is_alpha(text.charCodeAt(start + token_length)) ||
		 ( is_apostrophe(text.charCodeAt(start + token_length)) &&
		   token_length > 0 )))
	    token_length++;
	if (token_length > 0)
	    tokens.push(new Word(text.substr(start, token_length)));
	start = start + token_length;

	token_length = 0;
	while (start + token_length < text_length && !is_alpha(text.charCodeAt(start + token_length)))
	    token_length++;
	if (token_length > 0)
	    tokens.push(new Separator(text.substr(start, token_length)));
	start = start + token_length;
    }

    return tokens;
}

function multiword_rules(t1, t2, t3) {
    // TODO
    return t1;
}

function transcribe(text) {
  var tokens = tokenize(text);
  var offset = 0;
  var i = 0;

  // Post-process (linking r, etc)
  for(i = 0; i < tokens.length; i++) {
    if(i == tokens.length-1)
      tokens[i] = multiword_rules(tokens[i], null, null);
    else if(i == tokens.length-2)
      tokens[i] = multiword_rules(tokens[i], tokens[i+1], null);
    else
      tokens[i] = multiword_rules(tokens[i], tokens[i+1], tokens[i+2]);
  }

  var element = document.createElement("span");

  //For each token, create a span with the original text as a hint. Mark the ones we don't know or are not sure about.
  for(i = 0; i < tokens.length; i++) {
    element.appendChild(tokens[i].to_dom_element());
  }

  //Concatenate
  return element;
}



