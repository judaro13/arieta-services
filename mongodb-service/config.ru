require 'bundler'
require 'syro'
require 'pry'

require 'mongoid'

data = File.read "mongoid.yml"
data.gsub!("MONGODB_PATH", ENV["db_path"])
File.write("mongoid_conf.yml", data)

Mongoid.load! "mongoid_conf.yml"


puts ENV


App = Syro.new do
  get do
    res.write "Active service"
  end

  on :table do
    post do
      table = (inbox[:table]).capitalize
      klass = Class.new do
        include Mongoid::Document
        include Mongoid::Timestamps
        include Mongoid::Attributes::Dynamic
      end
      Object.const_set table, klass
      klass.store_in({collection: (inbox[:table]).downcase.pluralize})

      message = "data stored at table '#{inbox[:table]}'"

      begin
        data = JSON.parse(req.body.read)
        data.each do |h|
          puts klass.create(h)
        end
      rescue Exception => e
        message = e.message
      end

      res.write message
    end
  end
end

run App
