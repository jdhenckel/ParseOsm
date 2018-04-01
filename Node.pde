

class Node {
  float lat, lon;
  String name;
  float x,y;
  int numway;
  Node(XML xml) {
    lon = xml.getFloat("lon"); 
    lat = xml.getFloat("lat"); 
    name = xml.getString("name");
  }
  void reset() { numway = 0; }
  
  float dist2(Node n) {
    return (x-n.x)*(x-n.x)+(y-n.y)*(y-n.y);
  }
  
  float heron(Node a, Node b) {
    // compute the area of triangle formed by this node and a and b.
    // SEE http://geomalgorithms.com/a01-_area.html
    float A2 = dist2(a);
    float B2 = dist2(b);
    float D = A2 + B2 - a.dist2(b);
    return .25 * (float) Math.sqrt(4*A2*B2 - D*D);
  }
}