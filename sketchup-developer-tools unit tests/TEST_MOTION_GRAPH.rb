require 'test/unit'
require 'motion.rb'

include Motion

class TEST_MOTION_GRAPH < Test::Unit::TestCase

	def test_PairInArray_should_return_index_in_pairs
		a = PairInArray.new
		a.add( 0, 1 )
		a.add( 2, 3 )
		a.add( 1, 2 )

		assert_equal( 3, a.length )

		i,j = a.find( 1 )
		assert_equal( 0, i )
		assert_equal( 1, j )

		i,j = a.find(2)
		assert_equal( 1, i )
		assert_equal( 0, j )

		i,j = a.find(4)
		assert_equal( nil, i )
		assert_equal( nil, j )
	end

	def test_PairInArray_should_delete_given_index
		a = PairInArray.new
		a.add( 0, 1 )
		a.add( 2, 3 )
		a.add( 1, 2 )

		i,j = a.find( 1 )
		assert_equal( 0, i )

		a.delete_at( 0 )
		i,j = a.find(1)
		assert_equal( 1, i )

		assert_equal( 2, a.length )
	end  

	def test_PairInArrray_should_get_pair_in_index 
		a = PairInArray.new
		a.add( 0, 1 )
		a.add( 2, 3 )
		a.add( 1, 2 )

		i,j = a[1]
		assert_equal( 2, i )
		assert_equal( 3, j )
	end    

	def test_PairInArray_should_be_able_to_make_PairInArray_easily
		pairs = PairInArray.new

		edges = [ Edge.new(0,1), Edge.new(2,3), Edge.new(1,2) ]
		edges.each { |e| pairs.add( e.start, e.end ) }

		assert_equal( 3, pairs.length )
	end

	def test_PairInArray_should_be_able_to_pop_front
		pairs = PairInArray.new
		pairs.add( 0, 1 )
		pairs.add( 2, 3 )

		s,e = pairs.pop_front
		assert_equal( 0, s )
		assert_equal( 1, e )
		assert_equal( 1, pairs.length )
	end   

	def test_PairInArray_should_be_able_to_return_valeus_in_array 
		pairs = PairInArray.new
		pairs.add( 0, 1 )

		e = pairs[0]
		assert_equal( [0,1], e )
	end
	
	def test_Edge_should_return_value_at_start_with_index_0_and_end_with_1
		e = Edge.new( "START", "END" )
		assert_equal( e.start, e[0] )
		assert_equal( e.end, e[1] )
		assert_equal( e.end, e[-1] )
	end

	def test_Edge_should_raise_exception_when_out_of_bound_index_used
		e = Edge.new( "START", "END" )
		assert_raise RuntimeError do
			e[2]
		end
	end
	

	def test_DoublyLinkedList_should_add_values_to_head
		list = DoubleLinkedList.new()
		list.add_head Vertice.new( 3 )
		list.add_head Vertice.new( 2 )
		list.add_head Vertice.new( 1 )

		a = list.map{ |e| e.element }.to_a
		assert_equal( [1,2,3], a )
	end

	def test_DoublyLinkedList_should_add_values_to_tail
		list = DoubleLinkedList.new()
		list.add_tail Vertice.new( 3 )
		list.add_tail Vertice.new( 2 )
		list.add_tail Vertice.new( 1 )

		a = list.map{ |e| e.element }.to_a
		assert_equal( [3,2,1], a )
	end

	def test_DoublyLinkedList_should_add_values_to_head_and_tail
		list = DoubleLinkedList.new()
		list.add_tail Vertice.new( 3 )
		list.add_head Vertice.new( 2 )
		list.add_head Vertice.new( 1 )

		a = list.map{ |e| e.element }.to_a
		assert_equal( [1,2,3], a )
	end

	def test_DoublyLinkedList_can_have_no_element
		list = DoubleLinkedList.new()
		a = list.map{ |e| e.element }.to_a
		assert_equal( 0, a.length )
	end
	

	def test_Graph_should_find_path_in_order 	
		path = Graph::find_path( [ Edge.new(0,1), Edge.new(2,3), Edge.new(1,2) ] )
		assert_equal( [0,1,2,3], path.map { |v| v.element }.to_a )
	end
	
	def test_Graph_should_find_path_in_reverse_order 
		path = Graph::find_path( [ Edge.new(0,1), Edge.new(2,3), Edge.new(2,0) ] )
		assert_equal( [3,2,0,1], path.map { |v| v.element }.to_a )
	end 


	def test_Graph_should_find_path_in_order_and_reverse
		path = Graph::find_path( [  Edge.new(2,3), Edge.new(0,1), Edge.new(4,5),  Edge.new(3,4), Edge.new(1,2) ] )
		assert_equal( [0,1,2,3,4,5], path.map { |v| v.element }.to_a )
	end

end	
