# Yargraph

Yet another Ruby graphing library. Implements some [graph](http://en.wikipedia.org/wiki/Graph_theory)/vertex/edge related algorithms. Currently operates only on undirected graphs.

* find all [Hamiltonian cycles](http://en.wikipedia.org/wiki/Hamiltonian_cycle) in a graph using an exponential time algorithm (`hamiltonian_cycles`, dynamic programming method of Bellman, Held, and Karp).
* find edges that are a part of all Hamiltonian cycles (```edges_in_all_hamiltonian_cycles```, requires exponential time so may be _very_ slow)
* find only some edges that are a part of all Hamiltonian cycles (```some_edges_in_all_hamiltonian_cycles```, faster but may not find all edges)

Soon to be implemented:
* finding [bridges](http://en.wikipedia.org/wiki/Bridge_%28graph_theory%29) (```bridges```, requires linear time using Schmidt's [chain decompositions method](http://dx.doi.org/10.1016%2Fj.ipl.2013.01.016))
* determining [3-edge-connectivity](http://en.wikipedia.org/wiki/K-edge-connected_graph) and if 3-edge-connected (but not 4- or more), determine pairs of edges whose removal disconnects the graph (```three_edge_connected?```, ```three_edge_connections```, algorithm runs in O(n^2))

Contributions are most welcome.

## Copyright
Copyright (c) 2014 Ben J. Woodcroft. See LICENSE.txt for
further details.

