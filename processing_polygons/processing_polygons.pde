import megamu.mesh.*;
import java.util.Map;

size(700, 800);
stroke(204, 102, 0);
fill(204, 102, 0);

int stepSize = 10;
float threshold = 0.95;

ArrayList<PVector> points = new ArrayList();

//points.add(new PVector(50, 100));
//points.add(new PVector(100, 100));
//points.add(new PVector(150, 150));
//points.add(new PVector(200, 150));
//points.add(new PVector(250, 200));

for (int x = 0; x < width; x += stepSize) {
   for (int y = 0; y < height; y += stepSize) {
     if (random(1) > threshold) {
       points.add(new PVector(x, y));
     }
   }
}

float[][] pointsArray = new float[points.size()][2];

for (int i = 0; i < points.size(); i++) {
  PVector point = points.get(i);
  point(point.x, point.y);
  pointsArray[i][0] = point.x;
  pointsArray[i][1] = point.y;
}

Delaunay myDelaunay = new Delaunay(pointsArray);

// Draw all the edges in the triangulation
float[][] myEdges = myDelaunay.getEdges();

for(int i=0; i< myEdges.length; i++) {
  float startX = myEdges[i][0];
  float startY = myEdges[i][1];
  float endX = myEdges[i][2];
  float endY = myEdges[i][3];
  line(startX, startY, endX, endY);
}

// Highlight one face in a different color
int[][] faces = myDelaunay.getFaces();

for (int i = 0; i < faces.length; i++) {
  int point1 = faces[i][0];
  int point2 = faces[i][1];
  int point3 = faces[i][2];
  
  if (point1 < pointsArray.length && point2 < pointsArray.length && point3 < pointsArray.length) {
    println("point1", point1);
    println("point2", point2);
    println("point3", point3);
    println(pointsArray.length);
    stroke(150, 150, 0);
    line(pointsArray[point1][0], pointsArray[point1][1], pointsArray[point2][0], pointsArray[point2][1]);
    line(pointsArray[point2][0], pointsArray[point2][1], pointsArray[point3][0], pointsArray[point3][1]);
    line(pointsArray[point3][0], pointsArray[point3][1], pointsArray[point1][0], pointsArray[point1][1]);
    
    break;
  }
}

// Boundary detection
class Edge {
  PVector start, end;
  Edge(PVector start, PVector end) {
    this.start = start;
    this.end = end;
  }

  @Override boolean equals(Object otherObj) {
    Edge other = (Edge)otherObj;
    return (other.start.equals(this.start) && other.end.equals(this.end)) || //<>//
           (other.end.equals(this.start) && other.start.equals(this.end));
  }
  
  @Override int hashCode() {
    return this.start.hashCode() + this.end.hashCode();
  } //<>//
}

// Draw all the edges by face just in case it doesn't match the edge drawing above
for (int i = 0; i < faces.length; i++) {
  int point1Index = faces[i][0];
  int point2Index = faces[i][1];
  int point3Index = faces[i][2];
  
  if (point1Index < pointsArray.length && 
      point2Index < pointsArray.length && 
      point3Index < pointsArray.length) {
    PVector point1 = new PVector(pointsArray[point1Index][0], pointsArray[point1Index][1]);
    PVector point2 = new PVector(pointsArray[point2Index][0], pointsArray[point2Index][1]);
    PVector point3 = new PVector(pointsArray[point3Index][0], pointsArray[point3Index][1]);

    Edge edge1 = new Edge(point1, point2);
    Edge edge2 = new Edge(point2, point3);
    Edge edge3 = new Edge(point3, point1);
    
    float r = random(255);
    float g = random(255);
    float b = random(255);
    stroke(r, g, b);
    fill(r, g, b);
    triangle(point1.x, point1.y, point2.x, point2.y, point3.x, point3.y);
    //line(edge1.start.x, edge1.start.y, edge1.end.x, edge1.end.y);
    //line(edge2.start.x, edge2.start.y, edge2.end.x, edge2.end.y);
    //line(edge3.start.x, edge3.start.y, edge3.end.x, edge3.end.y);
  }
}

// The outer boundary is the longest contiguous 
// set of edges that only appear in a single face
// 
// So first we find all edges that only appear in a single face.
// Then we find the longest contiguous edge. We do this because
// the Delaunay triangulation produces "inner" holes that are not
// covered by triangles.

// Count how many times each edge appears in the faces
HashMap<Edge, Integer> edgeCounts = new HashMap();

for (int i = 0; i < faces.length; i++) {
  int point1Index = faces[i][0];
  int point2Index = faces[i][1];
  int point3Index = faces[i][2];
  
  if (point1Index < pointsArray.length && 
      point2Index < pointsArray.length && 
      point3Index < pointsArray.length) {
    PVector point1 = new PVector(pointsArray[point1Index][0], pointsArray[point1Index][1]);
    PVector point2 = new PVector(pointsArray[point2Index][0], pointsArray[point2Index][1]); //<>//
    PVector point3 = new PVector(pointsArray[point3Index][0], pointsArray[point3Index][1]);

    Edge edge1 = new Edge(point1, point2);
    Edge edge2 = new Edge(point2, point3);
    Edge edge3 = new Edge(point3, point1);
    
    int count = edgeCounts.getOrDefault(edge1, 0);
    edgeCounts.put(edge1, count + 1);
    
    count = edgeCounts.getOrDefault(edge2, 0);
    edgeCounts.put(edge2, count + 1);
   
    count = edgeCounts.getOrDefault(edge3, 0);
    edgeCounts.put(edge3, count + 1);
  }
}

// Find edges that appear in only 1 face
ArrayList<Edge> boundaryCandidates = new ArrayList();

for (Map.Entry<Edge, Integer> entry: edgeCounts.entrySet()) {
  println(
    "startX", entry.getKey().start.x,
    "startY", entry.getKey().start.y,
    "endX", entry.getKey().end.x,
    "endY", entry.getKey().end.y,
    "count", entry.getValue()
  );  
  if (entry.getValue() == 1) {
    boundaryCandidates.add(entry.getKey());
  }
}

class EdgeUtils {
  ArrayList<Edge> getAdjacentEdges(Edge edge, ArrayList<Edge> allEdges) {
    ArrayList<Edge> adjacentEdges = new ArrayList();
    
    for (Edge candidateEdge: allEdges) {
       if (this.isAdjacent(edge, candidateEdge)) {
         adjacentEdges.add(candidateEdge);
       }
    }
    
    return adjacentEdges;
  }
  
  boolean isAdjacent(Edge edge1, Edge edge2) {
    return edge1.start.equals(edge2.start) || edge1.end.equals(edge1.start);
  }
  
  ArrayList<Edge> longestBoundary(ArrayList<Edge> allBoundaryEdges) {
    for (Edge start: allBoundaryEdges) {
      Edge current = null;
      Edge longestBoundary = current;
      int longestBoundarySize = 1;
      
      while (!start.equals(current)) {
        ArrayList<Edge> adjacents = getAdjacentEdges(current, allBoundaryEdges);
        longestBoundarySize += 1;
        current = 
      }
    }
  }
}

// Find the longest contiguous set of edges
ArrayList<Edge> boundary = new ArrayList();
for (Edge edge: boundaryCandidates) {
  Edge current = null;
  Edge longestBoundary = current;
  int longestBoundarySize = 1;
  
  while (!edge.equals(current)) {
    ArrayList<Edge> adjacents = getAdjacentEdges(edge)
    
  }
}

// Draw the boundary
for (Edge edge: boundary) {
  strokeWeight(2);
  stroke(0, 0, 0);
  line(
    edge.start.x - 3, 
    edge.start.y - 3, 
    edge.end.x - 3, 
    edge.end.y - 3
  );
}
