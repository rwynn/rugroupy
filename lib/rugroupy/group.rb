require 'mongo'
require 'bson'

module Groupy
  
  class EntityGrouper
  
    @@defaultScoreFunction = "function(tag) { return 1; }"
    @@defaultIncludeFunction = "function(tag) { return true; }"
    @@dynamicTagFunction = "function(doc) {}"
  
    def initialize(database, entity)
      @database, @entity = database, entity
      @database["#{@entity}_count"].ensure_index([['_id.tag', Mongo::DESCENDING],
        ['value.count', Mongo::DESCENDING]], :background => false)
    end
  
    def similiar(tag=nil, skip=nil, limit=nil, reverse=false)
      q = BSON::OrderedHash.new
      q["_id.tag"] = tag ? tag : {"$exists" => false}
      cursor = @database["#{@entity}_count"].find(q, :fields => {"_id.e" => 1})
      cursor.skip(skip) if skip
      cursor.limit(limit) if limit
      cursor.sort("value.count", reverse ? Mongo::ASCENDING : Mongo::DESCENDING)
      cursor.collect { |r| r["_id"]["e"] }
    end
  
    def group(options={})
      self.invert_entities(options[:includeFunction] || @@defaultIncludeFunction,
        options[:dynamicTagFunction] || @@dynamicTagFunction)
      self.count_entities(options[:scoreFunction] || @@defaultScoreFunction)
    end
  
    def count_entities(scoreFunction)
      map = BSON::Code.new(<<eos)
        function() { 
          score = #{scoreFunction}; 
          tag = this._id.tag; 
          tagScore = score(tag); 
          entities = this.value.entities.slice(0).sort(); 
          for (x in entities) { 
            for (y in entities) { 
              if (x < y) { 
                emit({tag:tag, e:[entities[x], entities[y]]}, {count:tagScore}); 
                emit({e:[entities[x], entities[y]]}, {count:tagScore}); 
              } 
            } 
          } 
        } 
eos

      reduce = BSON::Code.new(<<eos)
        function(key, values) { 
          result = {count:0}; 
          values.forEach(function(value) { 
            result.count += value.count; 
          }); 
          return result; 
        } 
eos
    
      @database["#{@entity}_invert"].map_reduce(map, reduce, :out => "#{@entity}_count")
      nil
    end
  
    def invert_entities(includeFunction, dynamicTagFunction)
      map = BSON::Code.new(<<eos)
        function() { 
          include = #{includeFunction};
          dynamicTagFunction = #{dynamicTagFunction};
          entity_id = this._id; 
          if (this.tags) { 
            for (tag in this.tags) { 
              if (!include(tag)) continue; 
              this.tags[tag].forEach(function(z) { 
                emit({tag:tag, value:z}, {entities: [entity_id]}); 
              });
            }
            dynamicTagFunction(this);
          } 
        }
eos
    
      reduce = BSON::Code.new(<<eos)
        function(key, values) { 
          result = {entities:[]}; 
          values.forEach(function(value) { 
            value['entities'].forEach(function(entity_id) { 
              result['entities'].push( entity_id ); 
            }); 
          }); 
          return result; 
        }
eos
     
      @database[@entity].map_reduce(map, reduce, :out => "#{@entity}_invert")
      nil
    end
  
  end
end