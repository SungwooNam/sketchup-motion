require 'test/unit'
require 'motion.rb'

include Motion

class TEST_MOTION_UI < Test::Unit::TestCase

	EPSILON = 0.001
	
	def test_001_Hierarchy_find_object_at_the_base
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
		
		group = skp.entities.add_group
		comp = group.to_component
		comp.definition.name = "Hello"
		comp.definition.entities.add_line( Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,1,1) )
		
		hello_def = Hierarchy.walk_model( skp, "Hello" ).first	
		assert_not_nil( hello_def )
		assert_equal( "Hello", hello_def.definition.name )
	end
	
	def test_002_Hierarchy_find_object_at_children
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
		
		comp = skp.entities.add_group.to_component
		comp.definition.name = "Hello"
		comp.definition.entities.add_line( Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,1,1) )
		
		comp = comp.definition.entities.add_group.to_component
		comp.definition.name = "World"
		comp.definition.entities.add_line( Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0) )

		world_def = Hierarchy.walk_model( skp, "World" ).first	
		assert_not_nil( world_def )
		assert_equal( "World", world_def.definition.name )
	end
	
	def test_003_Graph_find_path
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
		
		comp = skp.entities.add_group.to_component
		comp.definition.name = "Hello"
		
		p = [ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), Geom::Point3d.new(1,1,0), Geom::Point3d.new(0,1,0) ]
		comp.definition.entities.add_line( p[0], p[1] )
		comp.definition.entities.add_line( p[1], p[2] )
		comp.definition.entities.add_line( p[2], p[3] )

		edges = comp.definition.entities.select { |e| e.is_a? Sketchup::Edge };
		single_path = Graph::find_path( edges )
		
		assert_equal( p, single_path.map { |e| e.element.position }.to_a )
	end	
	
	def test_004_Graph_find_path_in_reverse_order
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
		
		comp = skp.entities.add_group.to_component
		comp.definition.name = "Hello"
		
		p = [ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), Geom::Point3d.new(1,1,0), Geom::Point3d.new(0,1,0) ]
		comp.definition.entities.add_line( p[2], p[1] )
		comp.definition.entities.add_line( p[0], p[1] )
		comp.definition.entities.add_line( p[2], p[3] )

		edges = comp.definition.entities.select { |e| e.is_a? Sketchup::Edge };
		single_path = Graph::find_path( edges )
		
		assert_equal( p.reverse.to_a , single_path.map { |e| e.element.position }.to_a )
	end	
	
	def test_004_Graph_find_path_in_reverse_order
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
		
		comp = skp.entities.add_group.to_component
		comp.definition.name = "Hello"
		
		p = [ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), Geom::Point3d.new(1,1,0), Geom::Point3d.new(0,1,0) ]
		comp.definition.entities.add_line( p[2], p[1] )
		comp.definition.entities.add_line( p[0], p[1] )
		comp.definition.entities.add_line( p[2], p[3] )

		edges = comp.definition.entities.select { |e| e.is_a? Sketchup::Edge };
		single_path = Graph::find_path( edges )
		
		assert_equal( p.reverse.to_a , single_path.map { |e| e.element.position }.to_a )
	end		
	
	def test_005_FollowPath_should_move_object
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
		
		comp = skp.entities.add_group.to_component
		comp.definition.name = "Object"
		comp.transform! Geom::Transformation.new( [2.0,3.0,0] )
			
		p = [ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), Geom::Point3d.new(1,1,0), Geom::Point3d.new(0,1,0) ]

		act = FollowPath.new( 
			comp, 
			[ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), Geom::Point3d.new(1,2,0), Geom::Point3d.new(0,2,0) ],
			1.0 )
		
		assert_equal( [2.0, 3.0, 0.0], comp.transformation.origin.to_a )

		act.tick( 0.3 )
		assert_in_delta( 2.3, comp.transformation.origin.x, EPSILON )
		
		act.tick( 0.7 )
		assert_in_delta( 3.0, comp.transformation.origin.x, EPSILON )

		act.tick( 0.5 )
		assert_in_delta( 3.0, comp.transformation.origin.x, EPSILON )
		assert_in_delta( 3.5, comp.transformation.origin.y, EPSILON )
		assert_in_delta( 1.5, act.traveled, EPSILON )
		
		act.tick( 2.0 )
		assert_in_delta( 2.5, comp.transformation.origin.x, EPSILON )
		assert_in_delta( 5.0, comp.transformation.origin.y, EPSILON )
		assert_in_delta( 3.5, act.traveled, EPSILON )
		assert_equal( false, act.arrived? )
	
		act.tick( 1.0 )
		assert_in_delta( 2.0, comp.transformation.origin.x, EPSILON )
		assert_in_delta( 5.0, comp.transformation.origin.y, EPSILON )
		assert_in_delta( 4.0, act.traveled, EPSILON )
		assert_equal( true, act.arrived? )
	end		

	def test_006_Movement_should_do_translation
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
	
		c = skp.entities.add_group.to_component
		c.definition.name = "A"
		c.transform! Geom::Transformation.new( [0, 0, 0] )
		
		mov = Movement.new
		mov.chain( 
			Chain.MoveDir( c, :AXIS_X, 10, 2 ),
			Chain.MoveDir( c, :AXIS_Y, -10, 1 ),
			Chain.MoveDir( c, :AXIS_Z, 20, 5 ) )
		
		mov.run_frames( 5, 1.0 ) 
		assert_in_delta( 10.0, c.transformation.origin.x, EPSILON )

		mov.run_frames( 10, 1.0 ) 
		assert_in_delta( 10.0, c.transformation.origin.x, EPSILON )
		assert_in_delta( -10.0, c.transformation.origin.y, EPSILON )
		
		mov.run_frames(  2, 2.0 ) 
		assert_in_delta( 10.0, c.transformation.origin.x, EPSILON )
		assert_in_delta( -10.0, c.transformation.origin.y, EPSILON )
		assert_in_delta( 20.0, c.transformation.origin.z, EPSILON )
	end
	
	def test_007_Movement_should_FollowPath
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
	
		c = skp.entities.add_group.to_component
		c.definition.name = "A"
		c.transform! Geom::Transformation.new( [0, 0, 0] )
		
		mov = Movement.new
		mov.chain( 
			FollowPath.new( c, 
				[ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), Geom::Point3d.new(1,2,0), Geom::Point3d.new(0,2,0) ],
				1.0 ) 
		)
			
		mov.run_frames( 3, 0.5 ) 
		assert_in_delta( 1.0, c.transformation.origin.x, EPSILON )
		assert_in_delta( 0.5, c.transformation.origin.y, EPSILON )

		mov.run_frames( 3, 0.5 ) 
		assert_in_delta( 1.0, c.transformation.origin.x, EPSILON )
		assert_in_delta( 2.0, c.transformation.origin.y, EPSILON )
		
		mov.run_frames(  2, 1.0 ) 
		assert_in_delta( 0.0, c.transformation.origin.x, EPSILON )
		assert_in_delta( 2.0, c.transformation.origin.y, EPSILON )
	end	
	
	def test_008_SketchUp_Transformation
		p = [ 0, 1, 2, 3, 4 ]
		assert_equal( [ [0,1], [1,2], [2,3], [3,4] ], p.each_cons( 2 ).to_a )
	

		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
	
		c = skp.entities.add_group.to_component
		c.definition.name = "A"
		c.transform! Geom::Transformation.new( [0, 0, 0] )

		t = c.transformation
=begin		
		puts "transformation.xaxis #{t.xaxis}, yaxis #{t.yaxis}, zaxis #{t.zaxis}"		
		puts "transformation.rotx,y,z #{t.rotx},#{t.roty},#{t.rotz}"
		puts "transformation.scale #{t.xscale},#{t.yscale},#{t.zscale}"
		puts "transformation.to_a #{t.to_a}"
=end
		
		p = [ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), Geom::Point3d.new(1,1,0), Geom::Point3d.new(0,1,0) ]

		d1 = p[1] - p[0]
		d2 = p[2] - p[1]
		n = d1.cross( d2 )
		angle = d1.angle_between( d2 )
		
#		puts "d1 rotation to d2 -> #{n}, #{angle} ( #{angle / 1.0.degrees})" 
		
		c.transform! Geom::Transformation.rotation( Geom::Point3d.new(0,0,0), n, angle )
		t = c.transformation
#		puts "transformation.xaxis #{t.xaxis}, yaxis #{t.yaxis}, zaxis #{t.zaxis}"		
#		puts "transformation.rotx,y,z #{t.rotx},#{t.roty},#{t.rotz}"
	end
	
	def test_009_FollowPathWithDir_follows_path_and_change_direction
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
	
		c = skp.entities.add_group.to_component
		c.definition.name = "A"
		c.transform! Geom::Transformation.new( [0, 0, 0] )
		
		mov = Movement.new
		act = FollowWithDir.new( c, 
				[ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), Geom::Point3d.new(1,2,0), Geom::Point3d.new(0,2,0) ],
				1.0 ) 
		mov.chain( act )
		
		mov.run_frames( 1, 0.5 ) 
		assert_in_delta( 0.0, c.transformation.rotz, EPSILON )

		mov.run_frames( 2, 0.5 ) 
		assert_in_delta( 90.0, c.transformation.rotz, EPSILON )
		
		mov.run_frames( 4, 0.5 ) 
		assert_in_delta( 180.0, c.transformation.rotz, EPSILON )
		
		mov.run_frames( 2, 0.5 ) 
		assert_in_delta( 180.0, c.transformation.rotz, EPSILON )
	end
	
	def test_010_enumerate_all_children
		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
	
		a = skp.entities.add_group.to_component
		a.definition.name = "A"

		b = a.definition.entities.add_group.to_component
		b.definition.name = "B"

		a.definition.entities.add_instance(b.definition, Geom::Transformation.new( [1,0,0]))
		a.definition.entities.add_instance(b.definition, Geom::Transformation.new( [2,0,0]))
		a.definition.entities.add_instance(b.definition, Geom::Transformation.new( [3,0,0]))
		
		bs = Hierarchy.depth_first( a.definition.entities, lambda { |e| true } ).to_a
		assert_equal( 4, bs.length )
	end	
	
	def test_011_Graph_find_closest_path
		p = [ Geom::Point3d.new(0,0,0), Geom::Point3d.new(3,0,0), Geom::Point3d.new(2,0,0), Geom::Point3d.new(1,0,0) ]
		path = Graph.find_path_closest( p )
		assert_equal( [ p[0], p[3], p[2], p[1] ], path ) 
	end
	
	def test_012_Geometric_extract_cable_duct
		p = [ 
			Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), 
			Geom::Point3d.new(2,0,0), Geom::Point3d.new(3,-1,0), Geom::Point3d.new(2,-2,0),
			Geom::Point3d.new(1,-2,0), Geom::Point3d.new(0,-2,0)
		]
		duct = Geometric.extract_cable_duct( p )
		assert_equal( [ p[0], p[2], p[4], p[6] ], [ duct.float, duct.bend_start, duct.bend_end, duct.fixed ] )
		
		duct.spacer = [ 0, 1, 2, 3, 4, 6, 7.14 ]
	
		m0 = duct.move( 0.0 )
		m1 = duct.move( 0.5 )
		
		m0p = m0[:position]
		m1p = m1[:position]
		
		assert_in_delta( 0.5, (m1p[0] - m0p[0]).length, EPSILON )
		assert_in_delta( 0.5, (m1p[1] - m0p[1]).length, EPSILON )
		assert_in_delta( 0.0, (m1p[5] - m0p[5]).length, EPSILON )		
		assert_in_delta( 0.0, (m1p[6] - m0p[6]).length, EPSILON )
	end	
	
	def test_013_cable_duct_calculate_direction
		p = [ 
			Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0), 
			Geom::Point3d.new(2,0,0), Geom::Point3d.new(3,-1,0), Geom::Point3d.new(2,-2,0),
			Geom::Point3d.new(1,-2,0), Geom::Point3d.new(0,-2,0)
		]
		duct = Geometric.extract_cable_duct( p )
		duct.spacer = [ 2, 2+Math::PI/2, 2+Math::PI ]
		
		m0 = duct.move( 0 )
		m0d = m0[:direction]
		assert_in_delta( 0.0, (m0d[0] - Geom::Vector3d.new(1,0,0)).length, EPSILON )
		assert_in_delta( 0.0, (m0d[1] - Geom::Vector3d.new(0,-1,0)).length, EPSILON )
		assert_in_delta( 0.0, (m0d[2] - Geom::Vector3d.new(-1,0,0)).length, EPSILON )
		
		m1 = duct.move( Math::PI )
		m1d = m1[:direction]
		assert_in_delta( 0.0, (m1d[0] - Geom::Vector3d.new(0,-1,0)).length, EPSILON )
		assert_in_delta( 0.0, (m1d[1] - Geom::Vector3d.new(-1,0,0)).length, EPSILON )
		assert_in_delta( 0.0, (m1d[2] - Geom::Vector3d.new(-1,0,0)).length, EPSILON )

	end	
	
	def test_014_duct_move
		points = [ 
			Geom::Point3d.new(1,0,0), 
			Geom::Point3d.new(2,0,0), Geom::Point3d.new(3,-1,0), Geom::Point3d.new(2,-2,0),
			Geom::Point3d.new(1,-2,0), Geom::Point3d.new(0,-2,0)
		]

		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
	
		cable_duct = skp.entities.add_group.to_component
		cable_duct.definition.name = "cable_duct"
		cable_duct.transform! [ 1, 2, 0 ]
		cable_duct.transform! Geom::Transformation.rotation( [0,0,0], [0,0,1], 45.0.degrees )

		duct = cable_duct.definition.entities.add_group.to_component
		duct.definition.name = "cable_duct_part"
		duct.definition.entities.add_face [-0.2,-0.1,0],[0.2,0.0,0],[-0.2,0.1,0]

		points.each { |p| 		
			cable_duct.definition.entities.add_instance( duct.definition, p)
		}
		
		parts = cable_duct.walk( "cable_duct_part" ).to_a
		
		duct_move = DuctMove.new( cable_duct )
		duct_move.kick( 2.0, 1.0 )		
		
		duct_move.tick( 0.0 )
		m0 = parts.map { |p| p.transformation.rotz }.to_a
		duct_move.tick( Math::PI/2 )
		m1 = parts.map { |p| p.transformation.rotz }.to_a
		
		assert_in_delta( 45, (m0[2] - m1[2]), EPSILON )
		assert_in_delta( 45, (m0[3] - m1[3]), EPSILON )
		
		duct_move.tick( 1 )
		m1 = parts.map { |p| p.transformation.rotz }.to_a
	
		duct_move.kick( 0.0, 1.0 )		
		duct_move.tick( 2 )
		m2 = parts.map { |p| p.transformation.rotz }.to_a
		assert_equal( m0, m2 )
	end		
	
	def test_015_chained_duct_move
		points = [ 
			Geom::Point3d.new(1,0,0), 
			Geom::Point3d.new(2,0,0), Geom::Point3d.new(3,-1,0), Geom::Point3d.new(2,-2,0),
			Geom::Point3d.new(1,-2,0), Geom::Point3d.new(0,-2,0)
		]

		skp = Sketchup.active_model
		skp.entities.clear!
		skp.definitions.purge_unused
	
		cable_duct = skp.entities.add_group.to_component
		cable_duct.definition.name = "cable_duct"

		duct = cable_duct.definition.entities.add_group.to_component
		duct.definition.name = "cable_duct_part"
		duct.definition.entities.add_face [-0.2,-0.1,0],[0.2,0.0,0],[-0.2,0.1,0]

		points.each { |p| 		
			cable_duct.definition.entities.add_instance( duct.definition, p)
		}
		
		parts = cable_duct.walk( "cable_duct_part" ).to_a
		
		duct_move = DuctMove.new( cable_duct )
		mov = Movement.new
		mov.chain( 
			ChainedDuctMove.new( duct_move, 2.0, 1.0 ),
			ChainedDuctMove.new( duct_move, -2.0, 1.0 )
		)
		
		mov.run_frames( 1, 0.0 ) 
		m0 = parts.map { |p| p.transformation.rotz }.to_a
		puts "#{m0}, #{duct_move.inspect}"
		
		mov.run_frames( 2, 1.0 ) 
		m1 = parts.map { |p| p.transformation.rotz }.to_a
		puts "#{m1}, #{duct_move.inspect}"

		mov.run_frames( 2, 1.0 ) 
		m2 = parts.map { |p| p.transformation.rotz }.to_a
		puts "#{m2}, #{duct_move.inspect}"

		assert_not_equal( m0, m1 )
		assert_equal( m0, m2 )
	end			
end	
