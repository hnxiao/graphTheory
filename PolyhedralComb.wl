(* ::Package:: *)

BeginPackage["PolyhedralComb`"]

EdmondsMatrix::usage="EdmondsMatrix[g] returns the LHS matrix of Edmonds odd set constraint Mx<=b";
EdmondsVector::usage="EdmondsVector[g] returns the RHS vector of Edmonds odd set constraint Mx<=b";

cycleVertexMatrix::usage="cycleVertexMatrix[g] returns the cycle vertex incidence matrix for both undirected and directed graphs";
cycleEdgeMatrix::usage="cycleEdgeMatrix[g] returns the cycle edge incidence matrix for undirected graphs only";
cycleArcMatrix::usage="cycleArcMatrix[g] returns the cycle arc incidence matrix for directed graphs only";

preferenceList::usage="preferenceList[g] returns a random prefrence table";
RothblumMatrix::usage="RothblumMatrix[g,pt] returns the Rothblum stable constraint matrix";

tournament::usage="tournament[n] generates a random tournament on n vertices";
semiCompleteD::usage="semiCompleteD[n,m] generates a random semicomplete digraph on n vertices";

obsTournament::usage="obsTournamen returns obstructions for a packing tournament";
obsSemiCompleteD::usage="obsSemiCompleteD returns all obstructions within five vertices for a packing semicomplete digraph";
packingQ::usage="packingQ[d,obs] tests whether digraph d packs by checking all obstructions";
goodTournament::usage="goodTournament[n] tries to return a random strongly connected tournament that packs within 1000 attempts";
goodSemiCompleteD::usage="goodSemiCompleteD[n,m] tries to return a random strongly connected semicomplete digraph that packs within 1000 attempts";
bfsVertexPartition::usage="bfsVertexPartition[d,r] returns a bfs vertex partition with root r. Moreover, it returns each parition in topological order if it is acyclic, otherwise it returns a cycle list in this partition";
maxOutDegreeVertexSet::usage="maxOutDegreeVertexSet[d] returns all vertices with maximum out degree";
bfsVertexPartitions::usage="bfsVertexPartitions[d] returns all bfs vertex partitions rooted at vertices with maximum outdegree. Moreover, it returns each partition in topological order if it is acyclic, otherwise it returns a cycle list in this partition";

feedbackVertexSetQ::usage="feedbackVertexSetQ[d,vs] checks whether vertex set vs is a feedback vertex set";

deleteIsomorphicGraphs::usage="";
distinctDeletionVertices::usage="";
distinctContractionVertices::usage="";
distinctEdges::usage="";
minorOperation::usage="";
minors::usage="";


Begin["`Private`"]

EdmondsMatrix[g_]:=Module[{el,vl,subl},
	el=EdgeList[g];
	vl=VertexList[g];
	subl=Select[Subsets[vl,{3,Infinity,2}],!EmptyGraphQ[Subgraph[g,#]]&];
	SparseArray[{i_,j_}/;(Length@Intersection[subl[[i]],List@@el[[j]]]==2):>1,{Length@subl,Length@el}]];

EdmondsVector[g_]:=Module[{subl},
	subl=Select[Subsets[VertexList[g],{3,Infinity,2}],!EmptyGraphQ[Subgraph[g,#]]&];
	(Length/@subl-1)/2
];

cycleVertexMatrix[g_]:=Module[{},
	Outer[Boole[MemberQ[Flatten[List@@@#1],#2]]&,FindCycle[g,Infinity,All],VertexList@g,1]];

cycleEdgeMatrix[g_]:=Module[{},
	Outer[Boole[MemberQ[Sort/@#1,#2]]&,FindCycle[g,Infinity,All],EdgeList@g,1]];

cycleArcMatrix[g_]:=Module[{},
	Outer[Boole[MemberQ[#1,#2]]&,FindCycle[g,Infinity,All],EdgeList@g,1]];

preferenceList[g_]:=Module[{},
	Map[RandomSample[AdjacencyList[g,#]]&,VertexList@g]];

RothblumMatrix[g_,pl_]:=Module[{el},
	el=List@@@EdgeList@g;
	Outer[Boole[#1==#2\[Or]IntersectingQ[#1,#2]&&
		OrderedQ@{Position[pl[[Intersection[#1,#2][[1]]]],Complement[#2,Intersection[#1,#2]][[1]]],
				Position[pl[[Intersection[#1,#2][[1]]]],Complement[#1,Intersection[#1,#2]][[1]]]}]&,el,el,1]];

tournament[n_]:=Module[{g,t},
	g=CompleteGraph[n];
	t=DirectedGraph[g,"Random",VertexLabels->"Name"]];

semiCompleteD[n_,m_:1]/;1<=m<=n (n-1)/2:=Module[{t,d,arcsReversed},
	t=tournament[n];
	arcsReversed=Reverse/@RandomChoice@Subsets[EdgeList[t],{1,m}];
	d= EdgeAdd[t,arcsReversed]];

packingQ[d_,obs_]:=Module[{subgraphs,vcobs},
	vcobs=VertexCount/@obs;
	subgraphs=Subgraph[d,#]&/@Subsets[VertexList@d,{Min@vcobs,Min[VertexCount@d,Max@vcobs]}];
	SameQ[Or@@Flatten@Outer[IsomorphicGraphQ,subgraphs,obs],False]];

goodTournament[n_]:=Module[{i,t,subgraphs},
	Do[t=tournament[n];
		If[ConnectedGraphQ[#]&&packingQ[#,obsTournament]&@t,Return[t]],
		{i,1000}]];

goodSemiCompleteD[n_,m_:1]/;1<=m<=n (n-1)/2:=Module[{i,d,subgraphs},
	Do[d=semiCompleteD[n,m];
		If[ConnectedGraphQ[#]&&packingQ[#,obsSemiCompleteD]&@d,Return[d]],
		{i,1000}]];

bfsVertexPartition[d_,r_]:=Module[{p,vl,vt,ct,vused},
	vt={r}; ct={}; vused=vt;
	vl=Complement[VertexList@d,vt];
	p=Reap[While[vl!={},
		vt=Complement[#,vused]&@VertexInComponent[d,vt,1];
		AppendTo[vused,#]&/@vt;
		If[AcyclicGraphQ@Subgraph[d,vt],vt=TopologicalSort@Subgraph[d,vt],ct=FindCycle[Subgraph[d,vt],{2,3},All]];
		Sow@{vt,ct};		
		vl=Complement[vl,vt]; ct={}]][[2,1]];
	Prepend[p,{{r},{}}]];

maxOutDegreeVertexSet[d_]:=Module[{},
	Flatten@Position[#,Max[#]]&@VertexOutDegree@d];

bfsVertexPartitions[d_]:=Module[{},
	bfsVertexPartition[d,#]&/@maxOutDegreeVertexSet@d];

feedbackVertexSetQ[d_,vs_]:=Module[{},
	d//AcyclicGraphQ[Subgraph[#,Complement[VertexList[#],vs]]]&];

(*Data storage area*)

obsTournament:=Module[{obs,f1,f2},
	f1=Graph[{1->4,4->3,3->2,2->1,2->5,4->5,5->1,5->3}];
	f2=Graph[{1->2,2->3,3->4,4->5,5->1,2->5,3->1,4->2,5->3,1->4}];
	obs={EdgeAdd[f1,{1->3,2->4}],EdgeAdd[f1,{1->3,4->2}],f2}
	];

obsSemiCompleteD:=Module[{obs,f3,f41,f42,f421,f422,f43,f51,f52,f521,f522,f523,f524,f53,f531,f532,f533,f534,f54,residf54,f54all},
	f3=Graph[{1->2,2->1,2->3,3->2,3->1,1->3}]; (*3-Ring*)
	f41=Graph[{1->2,2->3,3->2,1->3,2->4,3->4,4->1}]; (*K4 with one C2*)
	f42=Graph[{1->2,2->4,4->1,2->3,3->2,3->4,4->3}]; (*K4 with two C2, two cases*)
	f421=EdgeAdd[f42,{1->3}];
	f422=EdgeAdd[f42,{3->1}];
	f43=Graph[{1->2,2->3,3->1,1->4,4->1,2->4,4->2,3->4,4->3}]; (*K4 with three C2, 3-wheel W3*)
	f51=Graph[{1->2,2->3,3->4,4->5,5->1,4->3,1->4,3->1,4->2,5->2,5->3}]; (*K5 with one C2, case 1*)
	f52=Graph[{1->2,2->3,3->1,1->5,5->4,4->1,3->4,4->3}];
	f521=EdgeAdd[f52,{2->5,2->4,3->5}];
	f522=EdgeAdd[f52,{2->5,4->2,3->5}];
	f523=EdgeAdd[f52,{5->2,2->4,3->5}];
	f524=EdgeAdd[f52,{2->5,2->4,5->3}];
	f53=Graph[{1->3,3->2,2->1,1->4,4->5,5->1,3->4,4->3}];
	f531=EdgeAdd[f52,{2->5,2->4,3->5}];
	f532=EdgeAdd[f52,{2->5,4->2,3->5}];
	f533=EdgeAdd[f52,{5->2,2->4,3->5}];
	f534=EdgeAdd[f52,{2->5,2->4,5->3}];
	f54=Graph[{1->2,2->1,2->3,3->2,3->4,4->3,4->5,5->4,5->1,1->5}]; (*5-Ring*)
	residf54={{DirectedEdge[1,3],DirectedEdge[3,1]},{DirectedEdge[1,4],DirectedEdge[4,1]},{DirectedEdge[2,4],DirectedEdge[4,2]},{DirectedEdge[2,5],DirectedEdge[5,2]},{DirectedEdge[3,5],DirectedEdge[5,3]}};
	f54all=EdgeAdd[f54,#]&/@Tuples[residf54];
	obs=obsTournament\[Union]{f3,f41,f421,f422,f43,f51,f521,f522,f523,f524,f531,f532,f533,f534}\[Union]f54all];

(*Working area*)

(* Highlights a bfs tree rooted at a random vertex with maximum outdegree. *)
outbfsTree[d_]:=Module[{rd,bfshighlight},
	rd=ReverseGraph@d;
	bfshighlight=Reap[BreadthFirstScan[rd,RandomChoice@Flatten@Position[VertexOutDegree@d,Max[VertexOutDegree@d]],{"FrontierEdge"->Sow}]][[2,1]]//HighlightGraph[rd,#]&;
	ReverseGraph@bfshighlight];

deleteIsomorphicGraphs[gl_List]:= Module[{},
(* Given a list of graphs gl, remove duplicate graphs under isomorphism. *)
	Return[DeleteDuplicates[gl,IsomorphicGraphQ[#1,#2]&]];];

distinctEdges[g_Graph]:= Module[{el},
(* Returns a list of the distinct (non-equivalent) edges in graph G, where two edges are equivalent if the graphs that are the result of the removal of those edges are isomorphic.*)
	el=EdgeList@g;
	Return[DeleteDuplicates[el,IsomorphicGraphQ[EdgeDelete[g,#1],EdgeDelete[g,#2]]&]];];

distinctDeletionVertices[g_Graph]:= Module[{vl},
(* Returns a list of the distinct (non-equivalent) vertices in graph G, where two vertices are equivalent if the graphs that are the result of the removal
of those vertices are isomorphic. *)
	vl=VertexList@g;
	Return[DeleteDuplicates[vl,IsomorphicGraphQ[VertexDelete[g,#1],VertexDelete[g,#2]]&]];];

distinctContractionVertices[g_Graph]:= Module[{vl},
(* Returns a list of the distinct (non-equivalent) vertices in graph G, where two vertices are equivalent if the graphs that are the result of the contraction
of those vertices are isomorphic. *)
	vl=VertexList@g;
	Return[DeleteDuplicates[vl,IsomorphicGraphQ[VertexDelete[g,#1],VertexDelete[g,#2]]&]];];

minorOperation[g_Graph]:=Module[{vld,vlc,el,tminors},
(* Returns nonisomorphic minors of graph g after one minor operations, i.e., vertex deletion, vertex constraction and edge deletion. *)
	vld=distinctDeletionVertices@g;
	vlc=distinctContractionVertices@g;
	el=distinctEdges@g;
	tminors=Reap[Sow@VertexDelete[g,#]&/@vld;
				Sow@VertexContract[g,#]&/@vlc;
				Sow@EdgeDelete[g,#]&/@el;][[2,1]];
	tminors=Select[tminors,UnsameQ[#,g]&];
	tminors=Graph/@Select[EdgeList/@tminors,UnsameQ[#,{}]&];
	deleteIsomorphicGraphs[tminors]];

minors[g_Graph]:=Module[{tm,m},
(* Returns all minors of graph g. Caution: this function is rather slow. It takes 15s to find all minors of K7 on my computer. *)
	m=Reap[Sow[tm=minorOperation@g];
			NestWhile[Sow[tm=deleteIsomorphicGraphs@Flatten@Map[minorOperation,#]]&,
						tm,UnsameQ[#,{}]&]]//Flatten;
	deleteIsomorphicGraphs@m];

End[]

EndPackage[]
