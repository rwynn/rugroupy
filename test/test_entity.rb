require 'helper'

class TestEntity < MiniTest::Test
  describe 'an entity' do
    before do
      @database_name = 'test'
      @connection = Mongo::Client.new('mongodb://localhost')
      @connection.use(@database_name)
      @database = Mongo::Database.new(@connection, @database_name)
      @entity_name = 'users'
      @entity_id = 'user1'
    end

    after do
      @connection[@entity_name].drop
      @database.drop
      @connection.close
    end

    describe 'create an entity' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert_equal @entity_id, doc['_id']
      end
    end

    describe 'not allow duplicate entities' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        e2 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        cursor = @database[@entity_name].find
        assert_equal 1, cursor.count
      end
    end

    describe 'tag an entity' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        e1.tag('likes', 'mongodb.org')
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert_equal @entity_id, doc['_id']
        assert doc.member?('tags')
        assert_equal 1, doc['tags'].size
        assert_equal 1, doc['tags']['likes'].size
        assert_equal 'mongodb.org', doc['tags']['likes'][0]
      end
    end

    describe 'validate entity has tag' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        e1.tag('likes', 'mongodb.org')
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert_equal @entity_id, doc['_id']
        assert e1.has_tag('likes', 'mongodb.org')
        assert_equal false, e1.has_tag('likes', 'apache.org')
      end
    end

    describe 'untag an entity' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        e1.tag('likes', 'mongodb.org')
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert_equal @entity_id, doc['_id']
        assert doc.member?('tags')
        assert_equal 1, doc['tags'].size
        assert_equal 1, doc['tags']['likes'].size
        assert_equal 'mongodb.org', doc['tags']['likes'][0]
        e1.untag('likes', 'mongodb.org')
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert doc.member?('tags')
        assert_equal 1, doc['tags'].size
        assert_equal 0, doc['tags']['likes'].size
      end
    end

    describe 'allow multiple tag values' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        e1.tag('likes', ['mongodb.org', 'apache.org'])
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert_equal @entity_id, doc['_id']
        assert doc.member?('tags')
        assert_equal 1, doc['tags'].size
        assert_equal 2, doc['tags']['likes'].size
        assert doc['tags']['likes'].member?('mongodb.org')
        assert doc['tags']['likes'].member?('apache.org')
      end
    end

    describe 'allow non-string tag values' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        e1.tag('zip', [22_204, 22_207])
        e1.tag('zip', 22_206)
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert_equal @entity_id, doc['_id']
        assert doc.member?('tags')
        assert_equal 1, doc['tags'].size
        assert_equal 3, doc['tags']['zip'].size
        assert doc['tags']['zip'].member?(22_206)
        assert doc['tags']['zip'].member?(22_207)
        assert doc['tags']['zip'].member?(22_204)
      end
    end

    describe 'allow complex tag values' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        e1.tag('height', 'feet' => 5, 'inches' => 10)
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert_equal @entity_id, doc['_id']
        assert doc.member?('tags')
        assert_equal 1, doc['tags'].size
        assert_equal 1, doc['tags']['height'].size
        assert_equal 5, doc['tags']['height'][0]['feet']
        assert_equal 10, doc['tags']['height'][0]['inches']
      end
    end

    describe 'ensure unique tag values' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        e1.tag('likes', 'mongodb.org')
        e1.tag('likes', 'mongodb.org')
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert_equal @entity_id, doc['_id']
        assert doc.member?('tags')
        assert_equal 1, doc['tags'].size
        assert_equal 1, doc['tags']['likes'].size
        assert doc['tags']['likes'].member?('mongodb.org')
      end
    end

    describe 'allow multiple tag names' do
      it do
        assert !@database.nil?
        e1 = Groupy::Entity.new(@database, @entity_name, @entity_id)
        e1.tag('likes', 'mongodb.org')
        e1.tag('languages', %w[python c])
        doc = @database[@entity_name].find('_id' => @entity_id).first
        assert !doc.nil?
        assert_equal @entity_id, doc['_id']
        assert doc.member?('tags')
        assert_equal 2, doc['tags'].size
        assert_equal 1, doc['tags']['likes'].size
        assert_equal 2, doc['tags']['languages'].size
        assert doc['tags']['likes'].member?('mongodb.org')
        assert doc['tags']['languages'].member?('python')
        assert doc['tags']['languages'].member?('c')
      end
    end
  end
end
