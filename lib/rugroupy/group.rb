require 'mongo'
require 'bson'

module Groupy
  class EntityGrouper
    @@defaultScoreFunction = 'function(tag) { return 1; }'
    @@defaultIncludeFunction = 'function(tag) { return true; }'
    @@dynamicTagFunction = 'function(doc) {}'

    def initialize(database, entity)
      @database = database
      @entity = entity
      @database["#{@entity}_count"].indexes.create_many([
                                                          { key: { '_id.tag' => -1 }, background: false },
                                                          { key: { 'value.count' => -1 }, background: false }
                                                        ])
    end

    def similiar(tag = nil, skip = nil, limit = nil, reverse = false)
      q = BSON::Document.new
      q['_id.tag'] = tag ? tag : { '$exists' => false }
      opts = {
        projection: { '_id.e' => 1 },
        sort: { 'value.count' => reverse ? 1 : -1 }
      }
      opts[:skip] = skip if skip
      opts[:limit] = limit if limit
      cursor = @database["#{@entity}_count"].find(q, opts)
      cursor.collect { |r| r['_id']['e'] }
    end

    def group(options = {})
      invert_entities(options[:includeFunction] || @@defaultIncludeFunction,
                      options[:dynamicTagFunction] || @@dynamicTagFunction)
      count_entities(options[:scoreFunction] || @@defaultScoreFunction)
    end

    def count_entities(scoreFunction)
      map = BSON::Code.new(<<eos)
        function() {
          var score = #{scoreFunction},
              tag = this._id.tag,
              tagScore = score(tag),
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
          var result = {count:0};
          values.forEach(function(value) {
            result.count += value.count;
          });
          return result;
        }
eos

      @database["#{@entity}_invert"].find.map_reduce(map, reduce, out: "#{@entity}_count").execute
      nil
    end

    def invert_entities(includeFunction, dynamicTagFunction)
      map = BSON::Code.new(<<eos)
        function() {
          var include = #{includeFunction},
              dynamicTagFunction = #{dynamicTagFunction},
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
          var result = {entities:[]};
          values.forEach(function(value) {
            value['entities'].forEach(function(entity_id) {
              result['entities'].push( entity_id );
            });
          });
          return result;
        }
eos
      @database[@entity].find.map_reduce(map, reduce, out: "#{@entity}_invert").execute
      nil
    end
  end
end
