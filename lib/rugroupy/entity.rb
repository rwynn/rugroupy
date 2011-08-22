require 'mongo'
require 'bson'

module Groupy
  
  class Entity
    def initialize(database, name, entity_id, create=true)
      @database, @name, @entity_id = database, name, entity_id
      @database.create_collection(@name) if not @database.collection_names.member?(@name)
    
      @database["#{@name}_count"].ensure_index([['_id.e', Mongo::DESCENDING],
        ['_id.tag', Mongo::DESCENDING], 
        ['value.count', Mongo::DESCENDING]], :background => false)
    
      if create
        begin
          doc = Hash["_id"=>@entity_id, "tags"=>Hash.new]
          @database[@name].insert(doc, :safe=>true)
        rescue Mongo::MongoDBError => e
        end
      end
    end

    def get
      @database[@name].find_one({ "_id" => @entity_id })
    end
    
    def delete
      @database[@name].remove({"_id" => @entity_id}, :safe => true)
      nil
    end

    def clear_tags
      spec = {"_id" => @entity_id }
      doc = {"$set" => { "tags" => Hash.new } }
      @database[@name].update(spec, doc, :safe=>true)
      nil
    end
  
    def has_tag(tag, value)
      e = self.get()
      e['tags'].member?(tag) and e['tags'][tag].member?(value)
    end
    
    def tag(tag, value)
      self.apply_tag(tag, value)
      nil
    end
    
    def untag(tag, value)
      self.apply_tag(tag, value, add=false)
      nil
    end
    
    def apply_tag(tag, value, add=true)
      op = add ? "$addToSet" : "$pull"
      doc = Hash.new
      field = "tags.#{tag}"
      unless value.is_a?(Array)
        doc[op] = { field => value }
      else
        op = "$pullAll" unless add
        doc[op] = add ? {field => {"$each" => value}} : {field => value}
      end
      spec = Hash["_id" => @entity_id]
      @database[@name].update(spec, doc, :safe=>true)
      nil
    end
  
    def similiar(tag=nil, skip=nil, limit=nil, reverse=false)
      q = BSON::OrderedHash.new
      q["_id.e"] = @entity_id
      q["_id.tag"] = tag ? tag : {"$exists" => false}
      cursor = @database["#{@name}_count"].find(q, :fields => {"_id.e" => 1})
      cursor.skip(skip) if skip
      cursor.limit(limit) if limit
      cursor.sort("value.count", reverse ? Mongo::ASCENDING : Mongo::DESCENDING)
      cursor.collect do |r|
        pair = r["_id"]["e"]
        pair[0] == @entity_id ? pair[1] : pair[0]
      end
    end
  
  end
end

