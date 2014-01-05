require 'set'
require 'ds'

module Hamiltonian
  class OperationalLimitReachedException < Exception; end

  class UndirectedGraph
    # vertices is a Set
    attr_accessor :vertices

    # edges is an EdgeSet
    attr_accessor :edges
    # Contained within is a Hash of vertex1 => Set: vertex2, vertex3, ..
    # If vertex1 => Set: vertex2, then vertex2 => Set: vertex1, ..
    class EdgeSet
      include Enumerable

      def initialize
        @edges = {}
      end

      def add_edge(v1, v2)
        @edges[v1] ||= Set.new
        @edges[v2] ||= Set.new
        @edges[v1] << v2
        @edges[v2] << v1
      end

      # Return an array of neighbours
      def neighbours(v)
        e = @edges[v]
        return [] if e.nil?
        return e.to_a
      end

      # Return a Set of vertices that are neighbours of the given
      # vertex, or an empty Set if there are none
      def [](vertex)
        e = @edges[vertex]
        if e
          return e
        else
          return Set.new
        end
      end

      def each
        already_seen_vertices = Set.new
        @edges.each do |v1, neighbours|
          neighbours.each do |v2|
            yield v1, v2 unless already_seen_vertices.include?(v2)
          end
          already_seen_vertices << v1
        end
      end

      def length
        count = 0
        each do
          count += 1
        end
        return count
      end

      # Is there an edge between v1 and v2?
      def edge?(v1,v2)
        e = @edges[v1]
        return false if e.nil?
        return e.include?(v2)
      end

      def empty?
        @edges.each do |v, neighbours|
          return false unless neighbours.empty?
        end
        return true
      end
    end


    def initialize
      @vertices = Set.new
      @edges = EdgeSet.new
    end

    # Add an edge between two vertices, adding the vertices in the
    # edge to the graph if they aren't already contained within it.
    def add_edge(vertex1, vertex2)
      @vertices << vertex1
      @vertices << vertex2
      @edges.add_edge vertex1, vertex2
      return
    end

    # Add a vertex to the graph
    def add_vertex(vertex)
      @vertices << vertex
    end

    # Return an Enumerable collection of vertices that
    # are directly connected to the given vertex
    def neighbours(vertex)
      @edges.neighbours(vertex)
    end

    def delete_edge(v1,v2)
      @edges[v1].delete v2
      @edges[v2].delete v1
    end

    # Yield a pair of vertices for each edge
    def each_edge
      @edges.each do |v1, v2|
        yield v1, v2
      end
    end

    def copy
      another = UndirectedGraph.new
      @vertices.each do |v|
        another.add_vertex v
      end
      each_edge do |v1, v2|
        another.add_edge v1, v2
      end
      return another
    end

    # Run depth first search, returning an array of Hamiltonian paths.
    # Or, if a block is given, yield each Hamiltonian path that comes
    # along (in no defined order), and don't return the array (to potentially
    # save RAM).
    #
    # The operational limit is used to make sure this algorithm doesn't
    # get out of hand - only this many 'operations' are used when traversing
    # the graph, as in #hamiltonian_paths_brute_force. When nil, there is no operational
    # limit
    def hamiltonian_cycles_brute_force(operational_limit=nil)
      stack = DS::Stack.new
      return [] if @vertices.empty?

      origin_vertex = @vertices.to_a[0]
      hamiltonians = []
      num_operations = 0

      path = Path.new
      path << origin_vertex
      stack.push path
      while path = stack.pop
        last_vertex = path[path.length-1]
        if last_vertex == origin_vertex and path.length > 1
          # Cycle of some sort detected. Is it Hamiltonian?
          if path.length == vertices.length + 1
            # Found a Hamiltonian path. Yield or save it for later
            hpath = path.copy[0...(path.length-1)]
            if block_given?
              yield hpath
            else
              hamiltonians << hpath
            end
          else
            # non-Hamiltonian path found. Ignore
          end

        elsif path.find_index(last_vertex) != path.length - 1
          # Found a loop, go no further

        else
          # No loop, just another regular thing.
          neighbours(last_vertex).each do |neighbour|
            unless operational_limit.nil?
              num_operations += 1
              if num_operations > operational_limit
                raise OperationalLimitReachedException
              end
            end
            new_path = Path.new(path.copy+[neighbour])
            stack.push new_path
          end
        end
      end

      return hamiltonians
    end
    alias_method :hamiltonian_cycles, :hamiltonian_cycles_brute_force

    # Return an array of edges (edges being an array of 2 vertices)
    # that correspond to edges that are found in all Hamiltonian paths.
    # This method might be quite slow because it requires finding all Hamiltonian
    # paths, which implies solving the (NP-complete) Hamiltonian path problem.
    #
    # There is probably no polynomial time way to implement this method anyway, see
    # http://cstheory.stackexchange.com/questions/20413/is-there-an-efficient-algorithm-for-finding-edges-that-are-part-of-all-hamiltoni
    #
    # The operational limit is used to make sure this algorithm doesn't
    # get out of hand - only this many 'operations' are used when traversing
    # the graph, as in #hamiltonian_cycles_brute_force
    def edges_in_all_hamiltonian_cycles(operational_limit=nil)
      hedges = nil
      hamiltonian_cycles do |path|
        # Convert the path to a hash v1->v2, v2->v3. Can't have collisions because the path is Hamiltonian
        edge_hash = {}
        path.each_with_index do |v, i|
          unless i == path.length-1
            edge_hash[v] = path[i+1]
          end
        end
        edge_hash[path[path.length-1]] = path[0] #Add the final wrap around edge

        if hedges.nil?
          # First Hpath found
          hedges = edge_hash
        else
          # Use a process of elimination, removing all edges that
          # aren't in hedges or this new Hpath
          hedges.select! do |v1, v2|
            edge_hash[v1] == v2 or edge_hash[v2] = v1
          end
          # If no edges fit the bill, then we are done
          return [] if hedges.empty?
        end
      end
      return [] if hedges.nil? #no Hpaths found in the graph
      return hedges.to_a
    end

    # If #edges_in_all_hamiltonian_cycles is too slow, the method
    # here is faster, but is not guaranteed to find every edge that is
    # part of Hamiltonian cycles. This method proceeds under the assumption
    # that the graph has at least 1 Hamiltonian cycle, but may stumble
    # across evidence to the contrary.
    #
    # Returns an instance of EdgeSearchResult where #edges_in_all are those
    # edges that are in all hamiltonian cycles, and #edges_in_none are those
    # edges that are not in any hamiltonian cycles. While
    def some_edges_in_all_hamiltonian_cycles
      stack = DS::Stack.new
      result = EdgeSearchResult.new

      # As we are deleting edges, make a deep copy to start with
      g = copy

      # Fill up the stack, in reverse to ease testing
      g.vertices.to_a.reverse.each do |v|
        stack.push v
      end

      while v = stack.pop
        all_neighbours = g.neighbours(v)
        ham_neighbours = result.hamiltonian_neighbours(v)
#        p v
#        p all_neighbours
#        p ham_neighbours

        # If a vertex contains 1 or 0 total neighbours, then the graph cannot contain
        # any hamcycles (in contrast, degree 1 doesn't preclude hampaths).
        if all_neighbours.length < 2
          result.contains_hamcycle = false

        elsif all_neighbours.length == 2
          # If a vertex has degree 2 then both edges must be a part of the hamcycle
          all_neighbours.each do |n|
            unless result.edges_in_all.edge?(v,n)
              result.edges_in_all.add_edge(v,n)
              stack.push n #now need to re-evalute the neighbour, as its neighbourhood is changed
            end

            # if an edge be and must not be in all hamcycles, then the graph is not Hamiltonian.
            # Are there any concrete examples of this? Possibly.
            if result.edges_in_all[v].include?(n) and result.edges_in_none[v].include?(n)
              result.contains_hamcycle = false
            end
          end

        elsif ham_neighbours.length >= 2
          # There cannot be any further hamcycle edges from this vertex, so the rest of the edges
          # cannot be a part of _any_ hamcycle
          all_neighbours.each do |n|
            next if ham_neighbours.include?(n)

            result.edges_in_none.add_edge(v,n)
            g.delete_edge(v,n)
            stack.push n #reconsider the neighbour
          end

        else
          # Anything else that can be done cheaply?
          # Maybe edges that create non-Hamiltonian cycles when only considering edges
          # that are in all Hamiltonian cycles -> these cannot be in any hamcycle

        end
        #p stack
      end
      #p result

      return result
    end

    class EdgeSearchResult
      # EdgeSets of edges that are contained in, or not contained in all Hamiltonian cycles.
      attr_accessor :edges_in_all, :edges_in_none

      # True, false, or dunno (nil), does the graph contain one or more Hamiltonian cycles?
      attr_accessor :contains_hamcycle

      def initialize
        @edges_in_all = EdgeSet.new
        @edges_in_none = EdgeSet.new
      end

      # Return an Set of neighbours that must be next or previous in a hamiltonian cycle (& path?)
      def hamiltonian_neighbours(vertex)
        @edges_in_all[vertex]
      end
    end

    class Path < Array
      def copy
        Path.new(self)
      end
    end
  end
end
