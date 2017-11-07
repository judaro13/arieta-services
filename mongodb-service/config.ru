require 'bundler'
require 'syro'
require 'pry'

require 'mongoid'

data = File.read "mongoid.yml"
data.gsub!("MONGODB_PATH", ENV["db_path"])
File.write("mongoid_conf.yml", data)

Mongoid.load! "mongoid_conf.yml"


class BaseModel
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
end

App = Syro.new do
  on :table do
    post do
      table = (inbox[:table]).capitalize
      klass = Class.new(BaseModel) do
      end
      Object.const_set table, klass

      message = "data stored at table #{inbox[:table]}"

      begin
        data = JSON.parse(req.body.read)
        data.each do |h|
          puts klass.create(h)
        end
      rescue Exception => e
        message = e.message
      end

      res.write "stored in db"
    end
  end
end

run App



# curl -H "Content-Type: application/json" -X POST -d '[{"a":"xyz","b":"xyz"},{"a":"xyz","b":"xyz"}]' http://localhost:9292/miTabla
