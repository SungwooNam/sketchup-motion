require 'test/unit'
require 'motion.rb'

include Motion

class TEST_MOTION_ACTION < Test::Unit::TestCase

	class AlwaysArrivedAction < Motion::Action
		def arrived?() true; end 
		def tick( sec = 1.0 ) fire_arrived_fn; end 
	end

	def test_should_call_all_the_added_fn_when_arrived
		action = AlwaysArrivedAction.new 

		trace = []
		action.when_arrived << lambda { |a| trace << 1 }
		action.when_arrived << lambda { |a| trace << 2 }
		action.tick

		assert_equal( [1,2], trace  )
	end
end


	

=begin



  def test_796127_point_to_latlong
    skp = Sketchup.active_model
    skp.entities.clear!
    point = Geom::Point3d.new([10, 10, 10])
    lat_long = skp.point_to_latlong(point)

    fail_msg = 'Model.point_to_latlong did not return a Geom::LatLong ' +
               'object. See bug report <a href="http://b/issue?id=796127">' +
               '796127</a>.'
    assert_equal('Geom::LatLong', lat_long.class.to_s, fail_msg)
  end

  def test_796127_latlong_to_point
    skp = Sketchup.active_model
    skp.entities.clear!
    lat_long = Geom::LatLong.new([50, 100])
    point = skp.latlong_to_point(lat_long)

    fail_msg = 'Model.latlong_to_point() did not return a Geom::Point3d ' +
               'object.'
    assert_equal('Geom::Point3d', point.class.to_s, fail_msg)
  end
end

require 'minitest/spec'
require 'minitest/mock'
require 'minitest/autorun'
load File.expand_path('Motion.rb', File.dirname(__FILE__))
#require './motion.rb'

include Motion


describe Motion::Action do

	class AlwaysArrivedAction < Motion::Action
		def arrived?() true; end 
		def tick( sec = 1.0 ) fire_arrived_fn; end 
	end

	it "should call all the added fn when arrived" do

		action = AlwaysArrivedAction.new 

		trace = []
		action.when_arrived << lambda { |a| trace << 1 }
		action.when_arrived << lambda { |a| trace << 2 }
		action.tick

		trace.must_equal [1,2]
	end

end




describe Motion::Translation do

	it "can be created but not arrived yet" do
		t = Motion::Translation.new nil, nil, 1.0
		t.arrived?.must_equal false
	end

	it "should hold target position" do
		mock_target = MiniTest::Mock.new 
		mock_target.expect :x, 1.0
		mock_target.expect :y, 0.0
		mock_target.expect :z, 0.0

		t = Motion::Translation.new nil, mock_target, 1.0

		t.target.x.must_equal 1.0
		t.target.y.must_equal 0.0
		t.target.z.must_equal 0.0
	end

end


describe Motion::PairInArray do 
	it "should return index in pairs" do	
		a = PairInArray.new
		a.add( 0, 1 )
		a.add( 2, 3 )
		a.add( 1, 2 )

		a.length.must_equal 3

		i,j = a.find( 1 )
		i.must_equal 0
		j.must_equal 1

		i,j = a.find(2)
		i.must_equal 1
		j.must_equal 0

		i,j = a.find(4)
		i.must_equal nil
		j.must_equal nil
	end

	it "should delete given index" do	
		a = PairInArray.new
		a.add( 0, 1 )
		a.add( 2, 3 )
		a.add( 1, 2 )

		i,j = a.find( 1 )
		i.must_equal 0

		a.delete_at( 0 )
		i,j = a.find(1)
		i.must_equal 1

		a.length.must_equal 2
	end  

	it "should get pair in index" do	
		a = PairInArray.new
		a.add( 0, 1 )
		a.add( 2, 3 )
		a.add( 1, 2 )

		i,j = a[1]
		i.must_equal 2
		j.must_equal 3
	end    

	it "should be able to make PariInArray easily" do	
		pairs = PairInArray.new

		edges = [ Edge.new(0,1), Edge.new(2,3), Edge.new(1,2) ]
		edges.each { |e| pairs.add( e.start, e.end ) }

		pairs.length.must_equal 3
	end   

	it "should be able to pop front" do	
		pairs = PairInArray.new
		pairs.add( 0, 1 )
		pairs.add( 2, 3 )

		s,e = pairs.pop_front
		s.must_equal 0
		e.must_equal 1
		pairs.length.must_equal 1
	end   

	it "should be able to return values in array" do	
		pairs = PairInArray.new
		pairs.add( 0, 1 )

		e = pairs[0]
		e[0].must_equal 0
		e[1].must_equal 1
	end     
end

describe Motion::Edge do 
	it "should return value at start with index 0 and end with 1" do	
		e = Edge.new( "START", "END" )
		e[0].must_equal e.start
		e[1].must_equal e.end
		e[-1].must_equal e.end
	end

	it "should raise exception when out of bound index used" do	
		e = Edge.new( "START", "END" )
		proc { e[2] }.must_raise RuntimeError
	end 
end

describe Motion::DoubleLinkedList do

	it "should add values to head" do	
		list = DoubleLinkedList.new()
		list.add_head Vertice.new( 3 )
		list.add_head Vertice.new( 2 )
		list.add_head Vertice.new( 1 )

		a = list.map{ |e| e.element }.to_a
		a.must_equal [1,2,3]
	end

	it "should add values to tail" do	
		list = DoubleLinkedList.new()
		list.add_tail Vertice.new( 3 )
		list.add_tail Vertice.new( 2 )
		list.add_tail Vertice.new( 1 )

		a = list.map{ |e| e.element }.to_a
		a.must_equal [3,2,1]
	end

	it "should add values to head and tail" do	
		list = DoubleLinkedList.new()
		list.add_tail Vertice.new( 3 )
		list.add_head Vertice.new( 2 )
		list.add_head Vertice.new( 1 )

		a = list.map{ |e| e.element }.to_a
		a.must_equal [1,2,3]
	end

	it "can have no element" do	
		list = DoubleLinkedList.new()
		a = list.map{ |e| e.element }.to_a
		a.must_equal []
	end 

end



describe Motion::Graph do

	it "should find path in order" do	
		path = Graph::find_path( [ Edge.new(0,1), Edge.new(2,3), Edge.new(1,2) ] )
		path.map { |v| v.element }.to_a.must_equal [0,1,2,3]
	end
	
	it "should find path in reverse order" do	
		path = Graph::find_path( [ Edge.new(0,1), Edge.new(2,3), Edge.new(2,0) ] )
		path.map { |v| v.element }.to_a.must_equal [3,2,0,1]
	end	
	
	it "should find path in order and reverse" do
		path = Graph::find_path( [  Edge.new(2,3), Edge.new(0,1), Edge.new(4,5),  Edge.new(3,4), Edge.new(1,2) ] )
		path.map { |v| v.element }.to_a.must_equal [0,1,2,3,4,5]
	end		

end

module Sketchup
	class Model
		def dumpr
			return true
		end
	end
end

class SketchupConsoleOutput
	def puts s
		print s.to_s + "\n"
	end
	
	def write s
		print s
	end
	
	def flush
		#nop
		# The testrunner expects to be able to call this method on the supplied io object.
	end
end




=end  
