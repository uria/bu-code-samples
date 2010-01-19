#! /usr/bin/ruby
require 'rubygems'
require 'mechanize'
require 'logger'
require 'uri'
require 'sequel'
require 'threadpool.rb'

Listas_proxies = ["http://www.freshproxy.org/",
                  "http://www.freshproxy.org/page/2/",
                  "http://www.freshproxy.org/page/3/",
                  "http://www.freshproxy.org/page/4/",
                  "http://www.freshproxy.org/page/5/",
                  "http://www.aliveproxy.com/high-anonymity-proxy-list/",
                  "http://www.proxy-list.net/anonymous-proxy-lists.shtml",
                  "http://www.multiproxy.org/anon_proxy.htm",
                  "http://www.aliveproxy.com/proxy-list/proxies.aspx/Spain-es",
                  "http://www.proxyserverprivacy.com/free-proxy-list.shtml",
                  "http://www.digitalcybersoft.com/ProxyList/fresh-proxy-list.shtml",
                  "http://www.xroxy.com/proxy-type-Anonymous.htm",
                  "http://www.proxyleech.com/page/1.aspx",
                  "http://www.atomintersoft.com/anonymous_proxy_list"]

Samair = ["http://www.samair.ru/proxy/proxy-01.htm",
          "http://www.samair.ru/proxy/proxy-02.htm",
          "http://www.samair.ru/proxy/proxy-03.htm",
          "http://www.samair.ru/proxy/proxy-04.htm",
          "http://www.samair.ru/proxy/proxy-05.htm",
          "http://www.samair.ru/proxy/proxy-06.htm",
          "http://www.samair.ru/proxy/proxy-07.htm",
          "http://www.samair.ru/proxy/proxy-08.htm",
          "http://www.samair.ru/proxy/proxy-09.htm",
          "http://www.samair.ru/proxy/proxy-10.htm",
          "http://www.samair.ru/proxy/proxy-11.htm",
          "http://www.samair.ru/proxy/proxy-12.htm",
          "http://www.samair.ru/proxy/proxy-13.htm",
          "http://www.samair.ru/proxy/proxy-14.htm",
          "http://www.samair.ru/proxy/proxy-15.htm",
          "http://www.samair.ru/proxy/proxy-16.htm",
          "http://www.samair.ru/proxy/proxy-17.htm",
          "http://www.samair.ru/proxy/proxy-18.htm",
          "http://www.samair.ru/proxy/proxy-19.htm",
          "http://www.samair.ru/proxy/proxy-20.htm",
          "http://www.samair.ru/proxy/proxy-21.htm",
          "http://www.samair.ru/proxy/proxy-22.htm",
          "http://www.samair.ru/proxy/proxy-23.htm",
          "http://www.samair.ru/proxy/proxy-24.htm",
          "http://www.samair.ru/proxy/proxy-25.htm",
          "http://www.samair.ru/proxy/proxy-26.htm",
          "http://www.samair.ru/proxy/proxy-27.htm",
          "http://www.samair.ru/proxy/proxy-28.htm",
          "http://www.samair.ru/proxy/proxy-29.htm",
          "http://www.samair.ru/proxy/proxy-30.htm",
          "http://www.samair.ru/proxy/proxy-31.htm",
          "http://www.samair.ru/proxy/proxy-32.htm"]

LOGGER = Logger.new(STDOUT)

def tratar_samair(body)
  cambios = body.scan(/([a-z])=(\d)/)
  b = body.gsub("<script type=\"text/javascript\">document.write(\":\"", ":")
  b.gsub!("+", "")
  cambios.each { |c| b.gsub!(c[0], c[1]) }  
  b
end

def busca_proxies(url, &block) 
  begin
    agent = WWW::Mechanize.new 
    page = agent.get(url)
    body = page.body
    if block
      body = yield(body)
    end
    body.scan(/(\d?\d?\d\.\d?\d?\d\.\d?\d?\d\.\d?\d?\d):(\d+)/).collect { |x| {:ip => x[0], :port => x[1] } }
  rescue Exception
    []
  end
end

def add_proxy(p)
  LOGGER.info "Añadiendo #{p[:ip]}:#{p[:port]}"
  begin
    DB[:proxies].insert(p.merge({:created_at => Time.now, :aliveness => 0.5}))
  rescue
  end
end

def test_proxy(p)
  LOGGER.info "Testeando: #{p[:ip]}:#{p[:port]}"
  t = Time.now
  DB[:proxies].filter(:id => p[:id]).update(:last_checked_at => t)
  begin
    agent = WWW::Mechanize.new 
    agent.set_proxy(p[:ip], p[:port])
    
    #Check if google works (tests POSTS)
    #page = agent.get("")
    
    #Check if it is anonymous @ samair
    page = agent.get("http://checker.samair.ru/")
    resume = page.body.scan(/<b>Resume:<\/b>.*/)[0]
    if resume.nil?
      aliveness =  p[:aliveness]*0.95+0*0.05
      DB[:proxies].filter(:id => p[:id]).update(:aliveness => aliveness)
    else
      aliveness =  p[:aliveness]*0.95+1*0.05
      if resume =~ /\(elite\)/
        DB[:proxies].filter(:id => p[:id]).update(:last_alive_at => t, :anonymous => true, :aliveness => aliveness)
      else #if resume =~ /proxy is not anonymous/
        DB[:proxies].filter(:id => p[:id]).update(:last_alive_at => t, :anonymous => false, :aliveness => aliveness)
      end
    end
  rescue Exception
    aliveness =  p[:aliveness]*0.95+0*0.05
    DB[:proxies].filter(:id => p[:id]).update(:aliveness => aliveness)
  end
end

def update_proxies_status()
  pool = ThreadPool.new(30)
  DB[:proxies].all.each do |p|
    pool.process { test_proxy(p) } if p[:aliveness] > 0.46 || rand(5) == 0
#    test_proxy(p)
  end
  pool.join()
end

def find_new_proxies()
  Listas_proxies.each do |lp|
    LOGGER.info "Buscando proxies en #{lp}"
    busca_proxies(lp).each{ |p| add_proxy(p) }
  end
end

def rip_proxies_samair()
  Samair.each do |lp|
    LOGGER.info "Buscando proxies en #{lp}"
    busca_proxies(lp){|b| tratar_samair(b) }.each{ |p| add_proxy(p) }
  end
end


DB = Sequel.mysql 'proxies', :user => 'root', :password => 'melk0r', :host => 'localhost'
#DB = Sequel.sqlite('./db/proxies.db')
rip_proxies_samair()
find_new_proxies()
update_proxies_status()
