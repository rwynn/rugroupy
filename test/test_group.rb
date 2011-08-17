require 'helper'

class TestGroup < Test::Unit::TestCase
  context "a group" do
      setup do
        @database_name = "test"
        @connection =  Mongo::Connection.new
        @entity_name = "users"
        @entity_ids = %w{user1 user2 user3 user4}
        @entities = @entity_ids.collect do |n|
          Groupy::Entity.new(@connection[@database_name], @entity_name, n)
        end
      end

      teardown do
        @connection[@database_name][@entity_name].drop()
        @connection[@database_name]["#{@entity_name}_invert"].drop()
        @connection[@database_name]["#{@entity_name}_count"].drop()
        @connection.drop_database(@database_name)
        @connection.close
      end

      should "group and order entities sharing 1 tag" do
        @entities[0].tag("likes", ["a", "b", "c"])
        @entities[1].tag("likes", "b")
        @entities[2].tag("likes", ["a", "c"])
        @entities[3].tag("likes", ["d", "e"])

        grouper = Groupy::EntityGrouper.new(@connection[@database_name], @entity_name)
        grouper.group

        results = @entities[0].similiar
        assert_not_nil results
        assert_equal 2, results.size
        assert_equal @entity_ids[2], results[0]
        assert_equal @entity_ids[1], results[1]
      end

      should "group and order entities sharing 2 tags" do
        @entities[0].tag("likes", ["a", "b", "c"])
        @entities[0].tag("wants", ["d", "e", "f"])
        @entities[1].tag("likes", "b")
        @entities[1].tag("wants", ["d", "e"])
        @entities[2].tag("likes", ["a", "c"])

        grouper = Groupy::EntityGrouper.new(@connection[@database_name], @entity_name)
        grouper.group

        results = @entities[0].similiar
        assert_not_nil results
        assert_equal 2, results.size
        assert_equal @entity_ids[1], results[0]
        assert_equal @entity_ids[2], results[1]

      end

      should "find entities similiar to a specific entity by tag name" do
        @entities[0].tag("likes", ["a", "b", "c"])
        @entities[0].tag("wants", ["d", "e", "f"])
        @entities[1].tag("likes", "b")
        @entities[1].tag("wants", ["d", "e"])
        @entities[2].tag("likes", ["a", "c"])

        grouper = Groupy::EntityGrouper.new(@connection[@database_name], @entity_name)
        grouper.group

        results = @entities[0].similiar(tag="likes")
        assert_not_nil results
        assert_equal 2, results.size
        assert_equal @entity_ids[2], results[0]
        assert_equal @entity_ids[1], results[1]

        results = @entities[0].similiar(tag="wants")
        assert_not_nil results
        assert_equal 1, results.size
        assert_equal @entity_ids[1], results[0]
      end

      should "allow grouping over all tags" do
        @entities[0].tag("likes", ["a", "b", "c"])
        @entities[0].tag("wants", ["d", "e", "f"])
        @entities[1].tag("likes", ["b", "g", "h", "i", "j"])
        @entities[1].tag("wants", ["d", "e"])
        @entities[2].tag("likes", ["a", "c", "g", "h", "i", "j"])

        grouper = Groupy::EntityGrouper.new(@connection[@database_name], @entity_name)
        grouper.group

        results = grouper.similiar
        assert_not_nil results
        assert_equal 3, results.size
        assert results[0].member?(@entity_ids[1])
        assert results[0].member?(@entity_ids[2])
        assert results[1].member?(@entity_ids[0])
        assert results[1].member?(@entity_ids[1])
        assert results[2].member?(@entity_ids[0])
        assert results[2].member?(@entity_ids[2])

      end

      should "allow grouping by a specific tag" do
        @entities[0].tag("likes", ["a", "b", "c"])
        @entities[0].tag("wants", ["d", "e", "f"])
        @entities[1].tag("likes", ["b", "g", "h", "i", "j"])
        @entities[1].tag("wants", ["d", "e"])
        @entities[2].tag("likes", ["a", "c", "g", "h", "i", "j"])

        grouper = Groupy::EntityGrouper.new(@connection[@database_name], @entity_name)
        grouper.group

        results = grouper.similiar(tag="likes")
        assert_not_nil results
        assert_equal 3, results.size
        assert results[0].member?(@entity_ids[1])
        assert results[0].member?(@entity_ids[2])
        assert results[1].member?(@entity_ids[0])
        assert results[1].member?(@entity_ids[2])
        assert results[2].member?(@entity_ids[0])
        assert results[2].member?(@entity_ids[1])

      end

      should "group by a custom scoring function" do
        scoreFunction = "function(tag) { if (tag == 'wants') return 2; else return 1; }"
        @entities[0].tag("likes", ["a", "b", "c"])
        @entities[0].tag("wants", ["d", "e", "f"])
        @entities[1].tag("likes", ["b", "g", "h", "i", "j"])
        @entities[1].tag("wants", ["d", "e"])
        @entities[2].tag("likes", ["a", "c", "g", "h", "i", "j"])

        grouper = Groupy::EntityGrouper.new(@connection[@database_name], @entity_name)
        grouper.group(:scoreFunction => scoreFunction)

        results = grouper.similiar
        assert_not_nil results
        assert_equal 3, results.size
        assert results[0].member?(@entity_ids[0])
        assert results[0].member?(@entity_ids[1])
        assert results[1].member?(@entity_ids[1])
        assert results[1].member?(@entity_ids[2])
        assert results[2].member?(@entity_ids[0])
        assert results[2].member?(@entity_ids[2])

      end

      should "group by a custom include function" do
        includeFunction = "function(tag) { return (tag == 'likes'); }"
        @entities[0].tag("likes", ["a", "b", "c"])
        @entities[0].tag("wants", ["d", "e", "f"])
        @entities[1].tag("likes", ["b", "g", "h", "i", "j"])
        @entities[1].tag("wants", ["d", "e"])
        @entities[2].tag("likes", ["a", "c", "g", "h", "i", "j"])

        grouper = Groupy::EntityGrouper.new(@connection[@database_name], @entity_name)
        grouper.group(:includeFunction => includeFunction)

        results = grouper.similiar
        assert_not_nil results
        assert_equal 3, results.size
        assert results[0].member?(@entity_ids[1])
        assert results[0].member?(@entity_ids[2])
        assert results[1].member?(@entity_ids[0])
        assert results[1].member?(@entity_ids[2])
        assert results[2].member?(@entity_ids[0])
        assert results[2].member?(@entity_ids[1])

      end

      should "group according to a custom tag function which allows dynamic tagging" do
        dynamicTagFunction = <<-EOF
         function (doc) {
           doc_id = doc._id;
           for (tag in doc.tags) {
             if (tag == 'age') {
               doc.tags[tag].forEach(function(a) {
                   if (parseInt(a) > 40 && parseInt(a) < 60) {
                       emit({tag:"boomer", value:true}, {entities: [doc_id]}); 
                   }
               });
             }
           }
         }
EOF
        @entities[0].tag("age", "49")
        @entities[1].tag("age", "16")
        @entities[2].tag("age", "55")

        grouper = Groupy::EntityGrouper.new(@connection[@database_name], @entity_name)
        grouper.group(:dynamicTagFunction => dynamicTagFunction)

        results = grouper.similiar(tag="boomer")
        assert_not_nil results
        assert_equal 1, results.size
        assert results[0].member?(@entity_ids[0])
        assert results[0].member?(@entity_ids[2])
      end
  end
end