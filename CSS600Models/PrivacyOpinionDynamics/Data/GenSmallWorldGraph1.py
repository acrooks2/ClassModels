# CSS 600 Final Project
# Generate a Simulated Small World Employee Network for Simulation
#

#from pandas import DataFrame, read_csv
import matplotlib.pyplot as plt
import pandas as pd
import networkx as nx
import scipy
import csv
import sys

# connected_watts_strogatz_graph(n, k, p, tries=100, seed=None)
# Returns a connected Watts–Strogatz small-world graph.
# Attempts to generate a connected graph by repeated generation of Watts–Strogatz small-world graphs. An
# exception is raised if the maximum number of tries is exceeded.
# Parameters
# • n (int) – The number of nodes
# • k (int) – Each node is joined with its k nearest neighbors in a ring topology.
# • p (float) – The probability of rewiring each edge
# • tries (int) – Number of attempts to generate a connected graph.
# • seed (integer, random_state, or None (default)) – Indicator of random number generation state.
# Notes
# First create a ring over 𝑛 nodes1. Then each node in the ring is joined to its 𝑘 nearest neighbors (or 𝑘 − 1
# neighbors if 𝑘 is odd). Then shortcuts are created by replacing some edges as follows: for each edge (𝑢, 𝑣)
# in the underlying “𝑛-ring with 𝑘 nearest neighbors” with probability 𝑝 replace it with a new edge (𝑢,𝑤) with
# uniformly random choice of existing node 𝑤. The entire process is repeated until a connected graph results.

# Define number of nodes in the employee graph
numberOfNodes = 2000
G = nx.connected_watts_strogatz_graph(numberOfNodes, 4, 0.250)

#Write an GRAPHML file -- THIS WORKS WITH NETLOGO!!
nx.write_graphml(G, "SmallWorld-2000Nodes-Ver1.graphml")

print ("\n")
print (nx.info(G))
print (nx.degree_histogram(G))
print ("Clustering Coefficient: "+ str(nx.average_clustering(G)))
print ("Average Shortest Path length: "+ str((nx.average_shortest_path_length(G))))