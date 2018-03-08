require 'mongo'
require 'bson'

module Groupy
  class Entity
    def initialize(database, name, entity_id, create = true)
      @database = database
      @name = name
      @entity_id = entity_id
      @database[@name].create unless @database.collection_names.member?(@name)

      @database["#{@name}_count"].indexes.create_many([
                                                        { key: { '_id.e' => -1 }, background: false },
                                                        { key: { '_id.tag' => -1 }, background: false },
                                                        { key: { 'value.count' => -1 }, background: false }
                                                      ])

      if create
        begin
          doc = Hash['_id' => @entity_id, 'tags' => {}]
          @database[@name].insert_one(doc, safe: true)
        rescue Mongo::Error => e
        end
      end
    end

    def get
      @database[@name].find('_id' => @entity_id).first
    end

    def delete
      @database[@name].delete_one({ '_id' => @entity_id }, safe: true)
      nil
    end

    def clear_tags
      spec = { '_id' => @entity_id }
      doc = { '$set' => { 'tags' => {} } }
      @database[@name].update_one(spec, doc, safe: true)
      nil
    end

    def has_tag(tag, value)
      e = get
      e['tags'].member?(tag) && e['tags'][tag].member?(value)
    end

    def tag(tag, value)
      apply_tag(tag, value)
      nil
    end

    def untag(tag, value)
      apply_tag(tag, value, add = false)
      nil
    end

    def apply_tag(tag, value, add = true)
      op = add ? '$addToSet' : '$pull'
      doc = {}
      field = "tags.#{tag}"
      if value.is_a?(Array)
        op = '$pullAll' unless add
        doc[op] = add ? { field => { '$each' => value } } : { field => value }
      else
        doc[op] = { field => value }
      end
      spec = Hash['_id' => @entity_id]
      @database[@name].update_one(spec, doc, safe: true)
      nil
    end

    def similiar(tag = nil, skip = nil, limit = nil, reverse = false)
      q = BSON::Document.new
      q['_id.e'] = @entity_id
      q['_id.tag'] = tag ? tag : { '$exists' => false }
      opts = {
        projection: { '_id.e' => 1 },
        sort: { 'value.count' => reverse ? 1 : -1 }
      }
      opts[:skip] = skip if skip
      opts[:limit] = limit if limit
      cursor = @database["#{@name}_count"].find(q, opts)
      cursor.collect do |r|
        pair = r['_id']['e']
        pair[0] == @entity_id ? pair[1] : pair[0]
      end
    end
  end
end
