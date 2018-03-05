

class Node {
  float lat, lon;
  String name;
  float x,y;
  Node(XML xml) {
    lon = xml.getFloat("lon"); 
    lat = xml.getFloat("lat"); 
    name = xml.getString("name");
  }
}