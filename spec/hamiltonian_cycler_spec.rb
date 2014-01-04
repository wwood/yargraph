require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class GraphTesting
  def self.generate_undirected(edges)
    g = Hamiltonian::UndirectedGraph.new
    edges.each do |edge|
      g.add_edge edge[0], edge[1]
    end
    return g
  end

  def self.sorted_edges(edges)
    edges.collect{|edge| edge.sort}.sort
  end
end

describe "HamiltonianCycler" do
  it 'should do neighbours' do
    g = GraphTesting.generate_undirected([
      [0,1],
      [1,2],
      [2,0]
    ])
    g.neighbours(0).sort.should == [1,2]
    g.neighbours(1).sort.should == [0,2]

    g = GraphTesting.generate_undirected([
      [0,1],
      [1,2],
    ])
    g.neighbours(2).sort.should == [1]
  end

  it "should find hamiltonian cycles 1" do
    g = GraphTesting.generate_undirected([
      [0,1],
      [1,2],
      [2,0]
    ])
    g.hamiltonian_cycles.sort.should == [
      [0,1,2],
      [0,2,1],
    ].sort
  end

  it "should find hamiltonian cycles 2" do
    g = GraphTesting.generate_undirected([
      [1,2],
      [1,3],
      [2,4],
      [2,3],
      [3,6],
      [4,5],
      [4,6],
      [5,6],
    ])
    paths = [
      [1,2,4,5,6,3],
    ]
    revpaths = paths.collect do |path|
      (path[1..path.length]+[path[0]]).reverse
    end
    g.hamiltonian_cycles.sort.should ==
      (paths+revpaths).sort
  end

  it 'should find edges in all hamiltonian cycles' do
    g = GraphTesting.generate_undirected([
      [1,2],
      [1,3],
      [2,4],
      [2,3],
      [3,6],
      [4,5],
      [4,6],
      [5,6],
    ])
    GraphTesting.sorted_edges(g.edges_in_all_hamiltonian_cycles).should ==
      GraphTesting.sorted_edges([
      [1,2],
      [2,4],
      [4,5],
      [5,6],
      [6,3],
      [3,1],
    ])
  end

  it 'should operated within limits' do
    g = GraphTesting.generate_undirected([
      [1,2],
      [1,3],
      [2,4],
      [2,3],
      [3,6],
      [4,5],
      [4,6],
      [5,6],
    ])
    expect {
      g.hamiltonian_cycles_brute_force(4)
    }.to raise_error(Hamiltonian::OperationalLimitReachedException)
  end

  it 'should find some all-hamiltonian edges first' do
    g = GraphTesting.generate_undirected([
      [0,1],
      [1,2],
      [2,0]
    ])
    edgeset_results = g.some_edges_in_all_hamiltonian_cycles
    edgeset_results.contains_hamcycle.should == nil
    GraphTesting.sorted_edges(edgeset_results.edges_in_all.to_a).should ==
      GraphTesting.sorted_edges([
        [0,1],
        [1,2],
        [2,0],
      ])
    GraphTesting.sorted_edges(edgeset_results.edges_in_none.to_a).should == []
  end

  it 'some all-hamiltonian edges should say when it falsifies the assumption' do
    g = GraphTesting.generate_undirected([
      [0,1],
      [1,2],
    ])
    edgeset_results = g.some_edges_in_all_hamiltonian_cycles
    edgeset_results.contains_hamcycle.should == false
    GraphTesting.sorted_edges(edgeset_results.edges_in_all.to_a).should ==
      GraphTesting.sorted_edges([
        [0,1],
        [1,2],
      ])
    GraphTesting.sorted_edges(edgeset_results.edges_in_none.to_a).should == []
  end


  it 'some all-hamiltonian edges should not choose all edges when not all are right' do
    g = GraphTesting.generate_undirected([
      [0,1],
      [1,2],
      [2,3],
      [3,0],

      [0,2],
      [1,3],
    ]) #This graph has hamiltonian paths but no edges are in every hamiltonian cycle
    edgeset_results = g.some_edges_in_all_hamiltonian_cycles
    edgeset_results.contains_hamcycle.should == nil
    GraphTesting.sorted_edges(edgeset_results.edges_in_all.to_a).should == []
    GraphTesting.sorted_edges(edgeset_results.edges_in_none.to_a).should == []
  end

  it 'some all-hamiltonian edges should choose none when none are right' do
    g = GraphTesting.generate_undirected([
      [0,1],
      [1,2],
      [2,3],
      [3,0],

      [0,2],
      [1,3],
    ]) #This graph has hamiltonian paths but no edges are in every hamiltonian cycle
    edgeset_results = g.some_edges_in_all_hamiltonian_cycles
    edgeset_results.contains_hamcycle.should == nil
    GraphTesting.sorted_edges(edgeset_results.edges_in_all.to_a).should == []
    GraphTesting.sorted_edges(edgeset_results.edges_in_none.to_a).should == []
  end

  it 'some all-hamiltonian edges should iterate properly' do
    g = GraphTesting.generate_undirected([
      [0,1],
      [1,2],

      [3,4],
      [4,5],

      [0,3],
      [1,4],
      [2,5],
    ]) #This graph requires removal of edges to discover more h_edges
    edgeset_results = g.some_edges_in_all_hamiltonian_cycles
    edgeset_results.contains_hamcycle.should == nil

    GraphTesting.sorted_edges(edgeset_results.edges_in_all.to_a).should ==
      GraphTesting.sorted_edges([
        [0,1],
        [1,2],

        [3,4],
        [4,5],

        [0,3],
        #[1,4],
        [2,5],
      ])
    GraphTesting.sorted_edges(edgeset_results.edges_in_none.to_a).should ==
      GraphTesting.sorted_edges([
        [1,4],
      ])
  end
end