require 'helper'

class TestGroup < MiniTest::Test
  describe 'a group' do
    before do
      @database_name = 'test'
      @connection =  Mongo::Client.new('mongodb://localhost')
      @connection.use(@database_name)
      @database = Mongo::Database.new(@connection, @database_name)
      @entity_name = 'users'
      @entity_ids = %w[user1 user2 user3 user4]
      @entities = @entity_ids.collect do |n|
        Groupy::Entity.new(@database, @entity_name, n)
      end
    end

    after do
      @connection[@entity_name].drop
      @connection["#{@entity_name}_invert"].drop
      @connection["#{@entity_name}_count"].drop
      @database.drop
      @connection.close
    end

    describe 'group and order entities sharing 1 tag' do
      it do
        @entities[0].tag('likes', %w[a b c])
        @entities[1].tag('likes', 'b')
        @entities[2].tag('likes', %w[a c])
        @entities[3].tag('likes', %w[d e])

        grouper = Groupy::EntityGrouper.new(@database, @entity_name)
        grouper.group

        results = @entities[0].similiar
        assert !results.nil?
        assert_equal 2, results.size
        assert_equal @entity_ids[2], results[0]
        assert_equal @entity_ids[1], results[1]
      end
    end

    describe 'group and order entities sharing 2 tags' do
      it do
        @entities[0].tag('likes', %w[a b c])
        @entities[0].tag('wants', %w[d e f])
        @entities[1].tag('likes', 'b')
        @entities[1].tag('wants', %w[d e])
        @entities[2].tag('likes', %w[a c])

        grouper = Groupy::EntityGrouper.new(@database, @entity_name)
        grouper.group

        results = @entities[0].similiar
        assert !results.nil?
        assert_equal 2, results.size
        assert_equal @entity_ids[1], results[0]
        assert_equal @entity_ids[2], results[1]
      end
    end

    describe 'find entities similiar to a specific entity by tag name' do
      it do
        @entities[0].tag('likes', %w[a b c])
        @entities[0].tag('wants', %w[d e f])
        @entities[1].tag('likes', 'b')
        @entities[1].tag('wants', %w[d e])
        @entities[2].tag('likes', %w[a c])

        grouper = Groupy::EntityGrouper.new(@database, @entity_name)
        grouper.group

        results = @entities[0].similiar(tag = 'likes')
        assert !results.nil?
        assert_equal 2, results.size
        assert_equal @entity_ids[2], results[0]
        assert_equal @entity_ids[1], results[1]

        results = @entities[0].similiar(tag = 'wants')
        assert !results.nil?
        assert_equal 1, results.size
        assert_equal @entity_ids[1], results[0]
      end
    end

    describe 'allow grouping over all tags' do
      it do
        @entities[0].tag('likes', %w[a b c])
        @entities[0].tag('wants', %w[d e f])
        @entities[1].tag('likes', %w[b g h i j])
        @entities[1].tag('wants', %w[d e])
        @entities[2].tag('likes', %w[a c g h i j])

        grouper = Groupy::EntityGrouper.new(@database, @entity_name)
        grouper.group

        results = grouper.similiar
        assert !results.nil?
        assert_equal 3, results.size
        assert results[0].member?(@entity_ids[1])
        assert results[0].member?(@entity_ids[2])
        assert results[1].member?(@entity_ids[0])
        assert results[1].member?(@entity_ids[1])
        assert results[2].member?(@entity_ids[0])
        assert results[2].member?(@entity_ids[2])
      end
    end

    describe 'allow grouping by a specific tag' do
      it do
        @entities[0].tag('likes', %w[a b c])
        @entities[0].tag('wants', %w[d e f])
        @entities[1].tag('likes', %w[b g h i j])
        @entities[1].tag('wants', %w[d e])
        @entities[2].tag('likes', %w[a c g h i j])

        grouper = Groupy::EntityGrouper.new(@database, @entity_name)
        grouper.group

        results = grouper.similiar(tag = 'likes')
        assert !results.nil?
        assert_equal 3, results.size
        assert results[0].member?(@entity_ids[1])
        assert results[0].member?(@entity_ids[2])
        assert results[1].member?(@entity_ids[0])
        assert results[1].member?(@entity_ids[2])
        assert results[2].member?(@entity_ids[0])
        assert results[2].member?(@entity_ids[1])
      end
    end

    describe 'group by a custom scoring function' do
      it do
        scoreFunction = "function(tag) { if (tag == 'wants') return 2; else return 1; }"
        @entities[0].tag('likes', %w[a b c])
        @entities[0].tag('wants', %w[d e f])
        @entities[1].tag('likes', %w[b g h i j])
        @entities[1].tag('wants', %w[d e])
        @entities[2].tag('likes', %w[a c g h i j])

        grouper = Groupy::EntityGrouper.new(@database, @entity_name)
        grouper.group(scoreFunction: scoreFunction)

        results = grouper.similiar
        assert !results.nil?
        assert_equal 3, results.size
        assert results[0].member?(@entity_ids[0])
        assert results[0].member?(@entity_ids[1])
        assert results[1].member?(@entity_ids[1])
        assert results[1].member?(@entity_ids[2])
        assert results[2].member?(@entity_ids[0])
        assert results[2].member?(@entity_ids[2])
      end
    end

    describe 'group by a custom include function' do
      it do
        includeFunction = "function(tag) { return (tag == 'likes'); }"
        @entities[0].tag('likes', %w[a b c])
        @entities[0].tag('wants', %w[d e f])
        @entities[1].tag('likes', %w[b g h i j])
        @entities[1].tag('wants', %w[d e])
        @entities[2].tag('likes', %w[a c g h i j])

        grouper = Groupy::EntityGrouper.new(@database, @entity_name)
        grouper.group(includeFunction: includeFunction)

        results = grouper.similiar
        assert !results.nil?
        assert_equal 3, results.size
        assert results[0].member?(@entity_ids[1])
        assert results[0].member?(@entity_ids[2])
        assert results[1].member?(@entity_ids[0])
        assert results[1].member?(@entity_ids[2])
        assert results[2].member?(@entity_ids[0])
        assert results[2].member?(@entity_ids[1])
      end
    end

    describe 'group according to a custom tag function which allows dynamic tagging' do
      it do
        dynamicTagFunction = <<-EOF
         function (doc) {
           var doc_id = doc._id;
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
        @entities[0].tag('age', '49')
        @entities[1].tag('age', '16')
        @entities[2].tag('age', '55')

        grouper = Groupy::EntityGrouper.new(@database, @entity_name)
        grouper.group(dynamicTagFunction: dynamicTagFunction)

        results = grouper.similiar(tag = 'boomer')
        assert !results.nil?
        assert_equal 1, results.size
        assert results[0].member?(@entity_ids[0])
        assert results[0].member?(@entity_ids[2])
      end
    end

    describe 'group by dynamic tags from complex tags' do
      it do
        dynamicTagFunction = <<-EOF
         function (doc) {
           var doc_id = doc._id;
           for (tag in doc.tags) {
             if (tag == 'height') {
               doc.tags[tag].forEach(function(h) {
                   if (h['feet'] >= 6) {
                       emit({tag:"tall", value:true}, {entities: [doc_id]});
                   }
               });
             }
           }
         }
      EOF
        @entities[0].tag('height', 'feet' => 5, 'inches' => 0)
        @entities[1].tag('height', 'feet' => 6, 'inches' => 1)
        @entities[2].tag('height', 'feet' => 5, 'inches' => 10)
        @entities[3].tag('height', 'feet' => 6, 'inches' => 6)

        grouper = Groupy::EntityGrouper.new(@database, @entity_name)
        grouper.group(dynamicTagFunction: dynamicTagFunction)

        results = grouper.similiar(tag = 'tall')
        assert !results.nil?
        assert_equal 1, results.size
        assert results[0].member?(@entity_ids[1])
        assert results[0].member?(@entity_ids[3])
      end
    end
  end
end
