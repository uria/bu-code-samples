#! /usr/bin/ruby
require 'rubygems'
require 'mechanize'
require 'logger'
require 'uri'

def init()
  agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
  agent.post("http://dolphin/admin/index.php", "ID" => "beni", "Password" => "melk0r")
  agent
end

def translate_dolphin(agent, x)
  page = agent.get("http://dolphin/admin/lang_file.php?view=editLangString&editStringKeyID=#{x}&editStringLangID=4")
  unless page.body.match("Error: specified string not found.")
    string =  page.search("//textarea")[0].inner_html
    translated = translate_string(agent, string)
    agent.post("http://dolphin/admin/lang_file.php?view=editLangString",
               "UpdateString_KeyID" => x,
               "UpdateString_LangID" => "4",
               "UpdateString_String" => translated,
               "UpdateLangString" => "Save changes")

    puts "(#{x}) #{string} -> #{translated}"
  end
end

def translate_string(agent, string)
  page = agent.post("http://ets.freetranslation.com/",
                    "sequence" => "core",
                    "mode" => "html",
                    "charset" => "UTF-8",
                    "template" => "results_en-us.htm",
                    "language" => "English/Spanish",
                    "srctext" => string)

  page.search("//textarea")[0].inner_html
end

agent = init()
(1..3000).each do |x|
  translate_dolphin(agent, x)
  sleep(0.5)
end

