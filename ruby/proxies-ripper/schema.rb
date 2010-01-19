require 'rubygems'
require 'sequel'

class CreateProxies < Sequel::Migration
  def up
    create_table :proxies do
      primary_key :id
      varchar   :ip, :size => 16, :unique => true
      integer   :port
      boolean   :anonymous
      float     :aliveness
      datetime  :last_alive_at
      datetime  :last_checked_at
      datetime  :created_at
    end

    create_table :uses do
      primary_key :id
      integer     :id_proxy
      datetime    :used_at
      varchar     :program, :size => 64
    end
  end
  
  def down
    execute 'DROP TABLE proxies'
    end
end

#DB = Sequel.sqlite('./db/proxies.db')
DB = Sequel.mysql 'proxies', :user => 'root', :password => 'melk0r', :host => 'localhost'
CreateProxies.apply(DB, :up)

