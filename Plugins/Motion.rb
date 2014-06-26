require "sketchup.rb"

class Array
	def each_cons( con )
		i = 0

		if block_given?
			while( i <= (self.length - con) ) do yield self[i..(i+con-1)]; i=i+1; end  
		else
			ent = []
			while( i <= (self.length - con) ) do ent << self[i..(i+con-1)]; i=i+1; end
			return ent				
		end
	end
end

class SuperProxy
  def initialize(obj)
    @obj = obj
  end

  def method_missing(meth, *args, &blk)
    @obj.class.superclass.instance_method(meth).bind(@obj).call(*args, &blk)
  end
end

class Object
  private
  def sup
    SuperProxy.new(self)
  end
end

module Math
	def self.min( x, y )
		if x < y then x else y end
	end
end

module Motion

	#
	# Usage :
	# 	Rotation.new( stage, Geom::Vector3d.new( 0.0, 0.0, 1.0 ), 80, 360 ).
	# 		when_arrived << lambda { |a| puts 'arrived' }
 	#
	class Action 
		attr_accessor :entity, :when_arrived
		
		def initialize
			@when_arrived = []
		end

		def fire_arrived_fn
			@when_arrived.each { |f| f.call(self) } if arrived?
		end
		
		def arrived?() end 
		def tick( elapsedSecond )  end
				
		protected :fire_arrived_fn 
	end

	class Translation < Action 
		attr_accessor :target, :velocity, :speed

		def initialize( entity, target, speed )
			super()

			@entity = entity
			@target = target
			@speed = speed
			
			@is_arrived = false
		end

		def tick( duration )
			return if arrived?
		
			ds = @speed * duration
			d = (@target - @entity.transformation.origin).normalize
			d.x, d.y, d.z = d.x*ds, d.y*ds, d.z*ds

			s = @entity.transformation.origin
			e = s + d
			dt = s.distance @target

			if ds >= dt
				d = @target - s;
				@is_arrived = true
			end

			@entity.transform! Geom::Transformation.new( d )

			fire_arrived_fn
		end
		
		def arrived?  
			@is_arrived  
		end

		def self.Move( entity, target, speed )
		   absolute_target = entity.transformation.origin + target
		   new( entity, absolute_target, speed )
		end

		def self.MoveDir( entity, axis, distance, speed )
			pos = case axis 
				when :AXIS_X then Geom::Vector3d.new( distance, 0.0, 0.0 )
				when :AXIS_Y then Geom::Vector3d.new( 0.0, distance, 0.0 )
				when :AXIS_Z then Geom::Vector3d.new( 0.0, 0.0, distance )
				else 
					raise ArgumentError, "Expected axis is #{:AXIS_X}, #{:AXIS_Y}, #{:AXIS_Z}"
				end
			
			self.Move( entity, pos, speed )
		end

		def to_s()
			if arrived? 
				puts "#{@entity.definition.name} arrived at #{@target}"
			else
				puts "move #{@entity.definition.name} at #{@entity.transformation.origin} toward #{@target} with velocity #{@velocity}"
			end
		end
	end
	
	class FollowPath < Action 
		attr_accessor :path, :speed, :position, :traveled
		attr_reader :index, :distances

		def initialize( entity, path, speed )
			super()

			@entity = entity
			@path = path
			@speed = speed
			
			@index = 0
			@traveled = 0.0
			@position = path[0]
			
			@distances = [ 0.0 ]
			path.each_cons(2) { |p| 
				@distances <<  ( @distances.last  + ( p[1] - p[0] ).length )
			}
			
			@is_arrived = false
		end
		
		def tick( duration )
			return if arrived?
			
			ds = @traveled + @speed * duration
			
			j = @index
			while ( @distances[j] < ds) do  
				j = j + 1; 
				break if j == @distances.length
			end 
			@index = j
			
			if( j == @distances.length )
				@is_arrived = true
				j = j - 1
				s = @distances[j] - @distances[j-1]
				ds = @distances[j]
			else
				s = ds - @distances[j-1];
			end
			
			@traveled = ds
			pn = ( path[j] - path[j-1] ).normalize
			pn.x, pn.y, pn.z = pn.x*s, pn.y*s, pn.z*s
			
			pm = ( path[j-1] + pn ) - @position
			@position = path[j-1] + pn
			
			@entity.transform! Geom::Transformation.translation( pm )

			fire_arrived_fn
		end
		
		def arrived?  
			@is_arrived  
		end

		def to_s()
			"FollowPath : speed #{@speed}, index #{@index}, traveled #{traveled}"
		end
	end	
	
	class FollowWithDir < FollowPath 
		attr_accessor :directions
		
		def initialize( entity, path, speed )
			super( entity, path, speed )

			@directions = []
			path.each_cons(2) { |p| 
				@directions << (p[1] - p[0]).normalize
			}
		end
		
		def tick( duration )
			return if arrived?
		
			i = Math::min( @index, @distances.length-1)
			sup.tick( duration )
			j = Math::min( @index, @distances.length-1)
			
			if i != j && i != 0
				di = @directions[ i-1 ]
				dj = @directions[ j-1 ]
				
				n = di.cross( dj )
				angle = di.angle_between( dj )
				
				@entity.transform! Geom::Transformation.rotation( entity.transformation.origin, n, angle )
			end
		end
	end		

	class Chain < Action
		attr_accessor :relative_target, :need_chaining, :translation
		
		def initialize( entity, target, speed )
			super()

			@relative_target = target
			@need_chaining = true
			@translation = Translation.new( entity, target, speed )
			@translation.when_arrived << lambda { |m| fire_arrived_fn }
		end	
		
		def arrived?() @translation.arrived?; end 
		
		def tick( duration )  
			if @need_chaining
				@translation.target = @translation.entity.transformation.origin + @relative_target
				@need_chaining = false

				o = @translation.entity.transformation.origin
				t = @translation.target
			end

			@translation.tick( duration ); 
		end
		
		def self.MoveDir( entity, axis, distance, speed )
			pos = case axis 
				when :AXIS_X then Geom::Vector3d.new( distance, 0.0, 0.0 )
				when :AXIS_Y then Geom::Vector3d.new( 0.0, distance, 0.0 )
				when :AXIS_Z then Geom::Vector3d.new( 0.0, 0.0, distance )
				else 
					raise ArgumentError, "Expected axis is #{:AXIS_X}, #{:AXIS_Y}, #{:AXIS_Z}"
				end
			
			new( entity, pos, speed )
		end	
	end

	class Rotation < Action 
		attr_accessor :axis, :speed, :target, :current

		def initialize( entity, axis, speed, target )
			super()
		
			@entity = entity
			
			@target = target
			@axis = axis
			@speed = speed
			@current = 0
			@speed = -@speed if @target < 0 
		end

		def tick( duration )
			return if arrived?
			
			delta = duration * @speed
			arrive_test = (@target - @current ) * ( @target - ( @current + delta ) ) 
			if arrive_test <= 0.0
				delta = @target - @current
				@current = @target
			else
				@current += delta
			end
			
			rot = Geom::Transformation.rotation entity.transformation.origin, @axis, delta.degrees
			@entity.transform! rot

			fire_arrived_fn
		end
		
		def arrived?
			@target == @current
		end

		def self.Rotate( entity, axis, speed, target )
		   new( entity, axis, speed, target  )
		end
		
		def to_s()
			if arrived? 
				puts "#{@entity.definition.name} arrived at #{@target}"
			else
				puts "rotate #{@entity.definition.name} at #{@entity.transformation.origin} with axis #{@axis} toward #{@target} with angular speed #{@speed}"
			end
		end
	end
	
	class DuctMove < Action
		attr_accessor :speed, :target, :current
		attr_reader :cable_duct_component, :parts, :part_positions, :cable_duct
		attr_reader :move_zero
	
		def initialize( cable_duct_component )
			super()
		
			@current = 0
			@target = 0
			@cable_duct_component = cable_duct_component
			
			begin
				
				part_name = cable_duct_component.definition.name.concat( "_part" )
				@parts = @cable_duct_component.walk( part_name ).to_a
				
				@part_positions = 
					@parts.map { |d| d.transformation.origin }.to_a
				@cable_duct = Geometric.extract_cable_duct( @part_positions )
				@cable_duct.spacer_count = @parts.length
				
				@transformation_base = @parts[0].transformation.clone
				@move_zero = @cable_duct.move( 0.0 )
				
			rescue  RuntimeError => ex
				raise "Failed to create DuctMove with #{cable_duct_component.definition.name} : #{ex.message}"
			end
		end
		
		def kick( target, speed )
			@target, @speed = target, speed.abs
			@speed = -@speed if @target < @current
		end

		def tick( duration )
			return if arrived?
			
			delta = duration * @speed
			arrive_test = (@target - @current ) * ( @target - ( @current + delta ) ) 
			if arrive_test <= 0.0
				delta = @target - @current
				@current = @target
			else
				@current += delta
			end
			

			m = @cable_duct.move( @current )
			mp = m[:position]
			md = m[:direction]
		
			@parts.each_with_index { |part,i|
			
				t = @transformation_base.clone
				tx = Geom::Transformation.translation( mp[i] - t.origin )
				rot_angle = md[i].angle_between( @move_zero[:direction][0] )
				rx = Geom::Transformation.rotation( [0,0,0], @cable_duct.normal, rot_angle )
				part.transformation = (  t * tx * rx  )
				
			}
			
			fire_arrived_fn
		end
		
		def arrived?
			@target == @current
		end

		def inspect
			"DuctMove : speed #{@speed}, target #{@target}, current #{@current}\n"
		end	
	end
	
	class ChainedDuctMove < Action
		attr_reader :speed, :target, :duct_move
		attr_reader :is_kicked
	
		def initialize( duct_move, target, speed )
			super()
		
			@duct_move = duct_move
			@target, @speed = target, speed
			@is_kicked = false
		end
		
		def tick( duration )
			if @is_kicked == false
				@duct_move.kick( @duct_move.current + @target, @speed )
				@duct_move.when_arrived = self.when_arrived
				@is_kicked = true
			end
		
			return if arrived?
			
			@duct_move.tick( duration )
		end
		
		def arrived?()  
			return false if @is_kicked == false 
			@duct_move.arrived?  
		end
		
		def inspect() @duct_move.inspect; end
	end	
	

	#
	# Usage :
	#	movement = Movement.new
	# 	movement.actions <<  Rotation.new( stage, Geom::Vector3d.new( 0.0, 0.0, 1.0 ), 80, 360 )
	#	movement.run( Sketchup.active_model, 0.1 ) 
	#
	class Movement
		attr_accessor :actions, :homes
		attr_reader :last_time
	
		def initialize
			@actions = []
			@homes = []
			@last_time = 0.0
		end
		
		def add( *moves )  moves.each { |m| @actions << m }; end
		
		def chain( *moves )
		
			moves.each_with_index do |m,i|
				unless i == 0 then
					moves[i-1].when_arrived << lambda { |arg|  @actions << m  }
				end
			end
			
			@actions << moves[0] 
		end
		
		def chain_to( move, *moves )
			
			move.when_arrived = lambda { |m|
				@actions << moves[0]
			}
			
			for i in 0...(moves.size-1)
				moves[i].when_arrived << lambda { |m| 
					@actions << moves[i+1]
				} 
			end
		end		
		
		def chain_concurrent( move, *moves )
			return if moves.size == 0 
			
			move.when_arrived << lambda { |m|
				moves.each { |v|  @actions << v; }
			}
		end		
				
		class Home
			attr_accessor :entity, :origin
			def initialize( entity, origin ) @entity, @origin = entity, origin; end
		end
		
		def return_home_when_finished( *entities )
			entities.each do |e|
				@homes << Home.new( e, e.transformation  )
			end
		end
		
		def do_return_home 
			@homes.each do |h| 
				h.entity.transformation = h.origin
			end
		end
		private :do_return_home 
		
		def when_finished=( lamda_fn ) @fn_finished = lamda_fn;  end
				
		def run( model, period )
		
			timer_id = UI.start_timer( period, true) {
					
				if @last_time == 0.0
					@last_time = Time.now.to_f
					elpased_time = period
				else
					current_time = Time.now.to_f
					elpased_time = current_time - @last_time 
					@last_time = current_time
				end

				@actions.delete_if do |a|
					a.tick( elpased_time )
					a.arrived?
				end
				model.active_view.invalidate
				
				if @actions.empty? then
					@fn_finished.call( self ) if @fn_finished
					
					if @actions.empty? then 
						UI.stop_timer timer_id
						do_return_home 
						model.active_view.invalidate
					end
				end
			}
		end
		
		def run_frames( count, period )
			(1..count).each { |i|
			
				@actions.delete_if { |a|
					a.tick( period )
					a.arrived?
				}
				
				if @actions.empty? then
					@fn_finished.call( self ) if @fn_finished

					if @actions.empty? then 
						do_return_home 
					end
				end
			}
		end	
		
	end
	

	#
	# Usage : 
	#	stage = Hierarchy.new( Sketchup.active_model ).walk_definition( "stage" ).first 
	#	
	class Hierarchy	
		def self.recursive_depth_first( entities, condition_fn )
			entities.
				select { |e| e.is_a? Sketchup::ComponentInstance }.
				each { |e| 
					if condition_fn.call( e ) then
						yield e
					end
					recursive_depth_first( e.definition.entities, condition_fn ) { |ee| yield ee }
				}
		end
		
		def self.depth_first( entities, condition_fn )
			if block_given?
				recursive_depth_first( entities, condition_fn ) { |e| yield e }
			else
				ent = Array.new
				recursive_depth_first( entities, condition_fn ) { |e| ent << e }
				ent
			end
		end	
		
		def self.walk_model( smodel, name )
			depth_first( smodel.entities, lambda { |e| e.definition.name == name } )
		end 

		def self.walk( base, name )
			depth_first( base.definition.entities, lambda { |e| e.definition.name == name } )
		end 
		
			
		#
		# usage : 
		#	glass = Hierarchy.rebase( glass, tractor_base, Geom::Point3d.new(10,20,30) )
		#
		def self.rebase( instance, new_parent, offset )
			#offset = Geom::Transformation.new( instance.transformation.origin - new_parent.transformation.origin )
			new_instance = new_parent.definition.entities.add_instance instance.definition, offset
			instance.parent.entities.erase_entities instance 
			new_instance
		end		
	end
end

class Sketchup::ComponentInstance
	def walk( name )  Hierarchy.walk( self, name ); end
end

module Motion
	class CableDuct
		attr_reader :float, :bend_start, :bend_end, :fixed
		attr_reader :d_m, :d_b, :d_f, :length, :bend_radius
		attr_reader :u_01, :u_12, :u_23
		attr_reader :spacer_count, :spacer
		attr_reader :normal
		
		def initialize( float, bend_start, bend_end, fixed )
			@float = float
			@bend_start = bend_start
			@bend_end = bend_end
			@fixed = fixed
			
			@u_01 = @bend_start - @float
			@u_12 = @bend_end - @bend_start
			@u_23 = @fixed - @bend_end
			
			@d_m = @u_01.length
			@d_f = @u_23.length
			@bend_radius = @u_12.length / 2 
			@d_b = @bend_radius * Math::PI
			@length = @d_m + @d_b + @d_f

			raise "CableDuct should have initial floating length bigger than 0" if @d_m <= 0.0 
			raise "CableDuct should have bend radius bigger than 0" if @bend_radius <= 0.0 
			raise "CableDuct should have initial fixed length bigger than 0" if @d_f <= 0.0 
			
			@u_01.normalize! 
			@u_12.normalize! 
			@u_23.normalize! 
			
			raise "CableDuct should have different direction between float #{@u_01} and bend #{@u_12}" if @u_01.parallel?( @u_12 ) 
			raise "CableDuct should have different direction between bend #{@u_12} and fixed #{@u_23}" if @u_12.parallel?( @u_23 ) 
			
			@normal = @u_01.cross( u_12 ).normalize
			raise "Failed to initialize CableDuct. No valid normal exist" if @normal.length != 1.0 
		end
		
		def spacer_count=( count )
			space = @length / (count-1)
			@spacer = (0..count-1).map { |i| space *i }.to_a 		
		end
		
		def spacer=( spacer )
			@spacer = spacer
		end
		
		def move( distance )
		
			d = distance
			pos, dirs = [], []
			ps, dir = 0
			i = 0
			
			while i < @spacer.length
			
				s = @spacer[ i ]
				if s < (@d_m - d/2)
					u = u_01.clone
					u.length = (s+d)
					ps = @float + u
					dir = u_01
				elsif ( @length - ( @d_f + d / 2 )) <= s 
					u = u_23.clone
					u.length = (@length - s)
					ps = @fixed - u 
					dir = u_23
				else
					sb = s - ( @d_m - d/2 )
					t = sb * Math::PI / @d_b
					
					r_sin_t_p_d = @bend_radius * Math.sin( t ) + d/2
					u1 = u_01.clone
					u1.length = r_sin_t_p_d
					
					r_r_cos_t = @bend_radius * ( 1 - Math.cos( t ) )
					u2 = u_12.clone
					u2.length = r_r_cos_t

					ps = @bend_start + u1 + u2
					
					o1 = u_01.clone
					o1.length = Math.cos(t)

					o2 = u_12.clone
					o2.length = Math.sin(t)
					
					dir = o1 + o2
				end
				
				pos << ps
				dirs << dir
				
				i = i + 1
			end
			
			return { :position => pos, :direction => dirs }
		end

		def inspect()
			"CableDuct : #{@float} -- #{@bend_start} >> #{@bend_end} -- #{@fixed} \n" \
			"  length : #{@length} ( = #{@d_m} + #{@d_b} + #{@d_f} ) \n" \
			"  directions : #{@u_01}, #{@u_12}, #{@u_23}\n" \
			"  spacer : #{ @spacer.inject( "[" ) { |msg,c| "#{msg}#{c}," } + "]" }"
		end	
		
	end

	class Geometric
	
		def self.extract_cable_duct( path )
			
			raise "can't create CableDuct as it's part count #{path.length} is less than 7" if path.length < 7
			
			dirs = []
			path.each_cons(2) { |p| dirs << p[1]-p[0] }
	
			dp = []
			dirs.each_cons(2) { |v| dp << v[0].angle_between( v[1] ) }
			
			bend_start, bend_end = 0, 0
			dp.each_with_index { |dir,i| 
				if dir.abs > 0.0001 && bend_start == 0
					bend_start = i + 1
				end
				
				if bend_start >0 && dir.abs < 0.0001 
					bend_end = i
					break
				end 
			}
			
			raise "Can't find bend_start" if bend_start == 0 || bend_start >= path.length
			raise "Can't find bend_end" if bend_end == 0 || bend_end >= path.length
			
			CableDuct.new( path[0], path[ bend_start], path[ bend_end], path[-1] )
		end
	
	
	end

end


module Motion

	class Edge
		attr_accessor :start, :end

		def initialize( s, e ) 
			@start = s
			@end = e
		end

		def []( index )
			if( index == 0 )
				@start
			elsif ( index == 1 || index == -1 )
				@end
			else
				raise "Not a valid index #{index} on Edge"
			end
		end
	end

	class PairInArray
		attr_accessor :linear

		def initialize() 
			@linear = []
		end

		def add( s, e ) 
			@linear << s;
			@linear << e;
		end

		def find( i )
			found = @linear.index( i )
			if found != nil
				return found/2, found%2
			end
		end

		def delete_at( i )  
			return @linear.delete_at( i*2 ), @linear.delete_at( i*2 ) 
		end

		def [] (i)
			return @linear[i*2], @linear[i*2+1]
		end

		def length() @linear.length / 2; end

		def pop_front() 
			return @linear.delete_at( 0 ), @linear.delete_at( 0 )
		end
		
		alias pop_at delete_at

	end

	class Vertice
		attr_accessor :next, :prev, :element

		def initialize( e ) @element = e; end
		def to_s()  @element.to_s; end
	end

	class DoubleLinkedList
		include Enumerable

		attr_accessor :head, :tail

		def add_tail( e )
			@tail.next, e.prev = e, @tail  if @tail != nil
			@tail = e
			@head = @tail if @head == nil
		end	

		def add_head( e )
			@head.prev, e.next = e, @head  if @head != nil
			@head = e
			@tail = @head if @tail == nil
		end	

		def each
			i = @head
			while i != nil do
				yield i
				i = i.next
			end
		end
		
		def to_s()
			inject( "{" ) { |msg,c| "#{msg}#{c}," } + "}"
		end	
	end

	
	class Graph

		def self.find_path_direction( dir, p, q )
		
			ei = []

			if dir == :FORWARD 
				k, ei[ 1 ] = 1, p.tail.element
				add_path = lambda { |e| p.add_tail( e ) }

			elsif dir == :BACKWARD
				k, ei[ 0 ] = 0, p.head.element
				add_path = lambda { |e| p.add_head( e ) }

			end

			while ( q.length > 0 )
				j,k = q.find( ei[k] )
				break if j == nil	

				ei = q.pop_at( j )
				k = k - 1     # -1 if 0 , 0 if 1
				
				add_path.call( Vertice.new( ei[ k ] ) )
			end
			
		end

		def self.find_path( edges )
		  
			q = PairInArray.new
			edges.each { |e| q.add( e.start, e.end ) }
	
			p = DoubleLinkedList.new 

			ei = q.pop_at(0)
			p.add_tail( Vertice.new( ei[0] ) )
			p.add_tail( Vertice.new( ei[1] ) )
			
			find_path_direction( :FORWARD, p, q )
			find_path_direction( :BACKWARD, p, q )
			
			p
		end


		def self.find_path_closest( points )
			
			ps = Array.new( points )
			path = [ ps.shift ]

			while ps.length > 0 
				
				closest_index = 0
				closest_distance = Float::MAX
				ps.length.times { |i|
					d = ( path.last - ps[i] ).length
					if( d < closest_distance )
						closest_index = i
						closest_distance = d
					end
				}
				
				path << ps.delete_at( closest_index )
			end
		
			path

		end
		
	end
end


