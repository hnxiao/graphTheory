(* ::Package:: *)

BeginPackage["Matchings`",{"Graphs`"}]

BlossomSystem::usage="BlossomSystem[g] returns the linear system Ax<=b of odd set constraints in list {A,b}.";
BlossomMatrix::usage="BlossomMatrix[g] returns the LHS matrix of odd set constraints Ax<=b.";
BlossomVector::usage="BlossomVector[g] returns the RHS vector of odd set constraints Ax<=b.";

EdgeDominatingMatrix::usage="EdgeDominatingMatrix[g,pl] returns the Rothblum stability matrix.";
PreferenceList::usage="PreferenceList[g] returns a random prefrence list in edges.";
SubPreferenceList::usage="SubPreferenceList[subg,pl] returns the preference list restricted to subgraph subg.";

BirkhoffSystem::usage="BirkhoffSystem[g] returns the Birkhoff system for bipartite graph g"
EdmondsSystem::usage="EdmondsSystem[g] returns the fractional matching system.";
RothblumSystem::usage="RothblumSystem[g,p] returns the linear systme Ax<=b defining fractional stable matching polytope";
EdmondsRothblumSystem::usage="EdmondsRothblumSystem[g,p] returns the linear systme Ax<=b defining fractional stable matching polytope";


Begin["`Private`"]


StableMatchingQ[g_Graph,pref_List,sm_List]:=Module[{els,sms,prefs,DominatedEdge},
	els=Sort/@EdgeList@g;
	sms=Sort/@sm;
	If[!IndependentEdgeSetQ[Graph[els],sms],Return["Not matching"]];
	prefs=Map[Sort,pref,{2}];
	DominatedEdge[e_]:=Apply[Union,Take[#,Position[#,e][[1]][[1]]]&/@{Reverse/@Select[prefs,MemberQ[#,e]&]}];
	SameQ[Sort@Union@Flatten[DominatedEdge[#]&/@els],Sort@els]];


DominatedQ[pref_List,sm_List,e_UndirectedEdge]:=Module[{prefs,sms,es,l,Index,eindex,smindex},
	prefs=Map[Sort,pref,{2}];
	sms=Sort/@sm;
	es=Sort@e;
    Index=Position[#1,#2][[1]][[1]]&;
	smindex=Index[#,Alternatives@@sms]&/@Select[prefs,MemberQ[#,es]&];
	eindex=Index[#,es]&/@Select[prefs,MemberQ[#,es]&];
	AnyTrue[Apply[LessEqual]][Thread/@Thread[{smindex, eindex}]]
(*
	SetAttributes[LessEqual,Listable];
	Or@@LessEqual[smindex,eindex]
*)]


(*** Fractional matching linear systems ***)


BirkhoffSystem[g_Graph]:=Module[{A,b},
	A=Join[IncidenceMatrix@g,-IdentityMatrix[EdgeCount@g]];
	b=Join[ConstantArray[1,VertexCount@g],ConstantArray[0,EdgeCount@g]];
	{A,b}];

EdmondsSystem[g_Graph]:=Module[{A,b},
	{A,b}=BirkhoffSystem@g;
	A=Join[A,BlossomMatrix@g];
	b=Join[b,BlossomVector@g];
	{A,b}];

RothblumSystem[g_Graph,p_List]:=Module[{A,b},
	{A,b}=BirkhoffSystem[g];
	A=Join[A,-EdgeDominatingMatrix[g,p]];
	b=Join[b,-ConstantArray[1,EdgeCount@g]];
	{A,b}];

EdmondsRothblumSystem[g_Graph,p_List]:=Module[{A,b},
	{A,b}=RothblumSystem[g,p];
	A=Join[A,BlossomMatrix[g]];
	b=Join[b,BlossomVector[g]];
	{A,b}];


(*** Some related matrices ***)


(* Edmonds odd set system or blossom system *)
BlossomSystem[g_Graph]:=Module[{el,vl,subl,mat,vec},
	el=EdgeList[g];
	vl=VertexList[g];
	subl=Select[Subsets[vl,{3,Infinity,2}],!EmptyGraphQ[Subgraph[g,#]]&];
	mat=SparseArray[{i_,j_}/;(Length@Intersection[subl[[i]],List@@el[[j]]]==2):>1,{Length@subl,Length@el}];
	vec=(Length/@subl-1)/2;
	{mat,vec}];

BlossomMatrix[g_Graph]:=BlossomSystem[g][[1]];

BlossomVector[g_Graph]:=BlossomSystem[g][[2]];


(* Rothblum edge dominating matrix *)
EdgeDominatingMatrix[g_Graph,pl_List]:=Module[{cel,cpl,del},
(*EdgeDominatingMatrix is NOT order sensitive to PreferenceList*)
	cel=Sort/@EdgeList@g;(*Put edges in canonical form*)
	cpl=Map[Sort,pl,{2}];(*Put edges in canonical form*)
	del=dominatingEdges[cpl,#]&/@cel;
	Outer[Boole[MemberQ[#1,#2]]&,del,cel,1]];
(*Private function: Dominating edges*)
dominatingEdges[cpl_List,ce_UndirectedEdge]:=Module[{epl},
(*Edges are assumed to be in canonial form*)
	epl=Select[cpl,MemberQ[#,ce]&];
	Apply[Union,Take[#,Position[#,ce][[1]][[1]]]&/@epl]];

(* Random preference generating function *)
PreferenceList[g_Graph]:=Module[{},
	Map[RandomSample[IncidenceList[g,#]]&,Sort@VertexList@g]];

SubPreferenceList[subg_Graph,pl_List]:=Module[{cel,cpl,subpl},
	cel=Sort/@EdgeList@subg;
	cpl=Map[Sort,pl,{2}];
	subpl=Intersection[#,cel]&/@cpl;
	Select[subpl,UnsameQ[#,{}]&]];


End[]


EndPackage[]
