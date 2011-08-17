require 'helper'

class TestEntity < Test::Unit::TestCase
  context "an entity" do 
    setup do
      @database_name = "test"
      @connection =  Mongo::Connection.new
      @entity_name = "users"
      @entity_id = "user1"
    end

    teardown do
      @connection[@database_name][@entity_name].drop()
      @connection.drop_database(@database_name)
      @connection.close
    end

    should "create an entity" do
      assert_not_nil @connection
      e1 = Groupy::Entity.new(@connection[@database_name], @entity_name, @entity_id)
      doc = @connection[@database_name][@entity_name].find_one({"_id" => @entity_id})  
      assert_not_nil doc
      assert_equal @entity_id, doc["_id"]
    end

    should "not allow duplicate entities" do
      assert_not_nil @connection
      e1 = Groupy::Entity.new(@connection[@database_name], @entity_name, @entity_id)
      e2 = Groupy::Entity.new(@connection[@database_name], @entity_name, @entity_id)
      cursor = @connection[@database_name][@entity_name].find()
      assert_equal 1, cursor.count
    end

    should "tag an entity" do
      assert_not_nil @connection
      e1 = Groupy::Entity.new(@connection[@database_name], @entity_name, @entity_id)
      e1.tag("likes", "mongodb.org")
      doc = @connection[@database_name][@entity_name].find_one({"_id" => @entity_id})
      assert_not_nil doc
      assert_equal @entity_id, doc["_id"]
      assert doc.member?("tags")
      assert_equal 1, doc["tags"].size
      assert_equal 1, doc["tags"]["likes"].size
      assert_equal "mongodb.org", doc["tags"]["likes"][0]
    end

    should "validate entity has tag" do
      assert_not_nil @connection
      e1 = Groupy::Entity.new(@connection[@database_name], @entity_name, @entity_id)
      e1.tag("likes", "mongodb.org")
      doc = @connection[@database_name][@entity_name].find_one({"_id" => @entity_id})
      assert_not_nil doc
      assert_equal @entity_id, doc["_id"]
      assert e1.has_tag("likes", "mongodb.org")
      assert_equal false, e1.has_tag("likes", "apache.org")
    end

    should "untag an entity" do
      assert_not_nil @connection
      e1 = Groupy::Entity.new(@connection[@database_name], @entity_name, @entity_id)
      e1.tag("likes", "mongodb.org")
      doc = @connection[@database_name][@entity_name].find_one({"_id" => @entity_id})
      assert_not_nil doc
      assert_equal @entity_id, doc["_id"]
      assert doc.member?("tags")
      assert_equal 1, doc["tags"].size
      assert_equal 1, doc["tags"]["likes"].size
      assert_equal "mongodb.org", doc["tags"]["likes"][0]
      e1.untag("likes", "mongodb.org")
      doc = @connection[@database_name][@entity_name].find_one({"_id" => @entity_id})
      assert_not_nil doc
      assert doc.member?("tags")
      assert_equal 1, doc["tags"].size
      assert_equal 0, doc["tags"]["likes"].size
    end

    should "allow multiple tag values" do
      assert_not_nil @connection
      e1 = Groupy::Entity.new(@connection[@database_name], @entity_name, @entity_id)
      e1.tag("likes", ["mongodb.org", "apache.org"])
      doc = @connection[@database_name][@entity_name].find_one({"_id" => @entity_id})
      assert_not_nil doc
      assert_equal @entity_id, doc["_id"]
      assert doc.member?("tags")
      assert_equal 1, doc["tags"].size
      assert_equal 2, doc["tags"]["likes"].size
      assert doc["tags"]["likes"].member?("mongodb.org" )
      assert doc["tags"]["likes"].member?("apache.org")
    end

    should "ensure unique tag values" do
      assert_not_nil @connection
      e1 = Groupy::Entity.new(@connection[@database_name], @entity_name, @entity_id)
      e1.tag("likes", "mongodb.org")
      e1.tag("likes", "mongodb.org")
      doc = @connection[@database_name][@entity_name].find_one({"_id" => @entity_id})
      assert_not_nil doc
      assert_equal @entity_id, doc["_id"]
      assert doc.member?("tags")
      assert_equal 1, doc["tags"].size
      assert_equal 1, doc["tags"]["likes"].size
      assert doc["tags"]["likes"].member?("mongodb.org")
    end

    should "allow multiple tag names" do
      assert_not_nil @connection
      e1 = Groupy::Entity.new(@connection[@database_name], @entity_name, @entity_id)
      e1.tag("likes", "mongodb.org")
      e1.tag("languages", ["python", "c"])
      doc = @connection[@database_name][@entity_name].find_one({"_id" => @entity_id})
      assert_not_nil doc
      assert_equal @entity_id, doc["_id"]
      assert doc.member?("tags")
      assert_equal 2, doc["tags"].size
      assert_equal 1, doc["tags"]["likes"].size
      assert_equal 2, doc["tags"]["languages"].size
      assert doc["tags"]["likes"].member?("mongodb.org")
      assert doc["tags"]["languages"].member?("python")
      assert doc["tags"]["languages"].member?("c")
    end
  end
end
