/*
This can parse the OSM files.
You can get OSM files from https://www.openstreetmap.org  just click "export"
*/

XML xml;
float s = .02;
float px,py;
boolean hide = true;
HashMap<String,Node> nodeMap;
ArrayList<Way> wayList;


void setup() {
  size(1000, 800);
  loadFile("elgin-map.osm"); s=.22; px=4600; py=-1300;
  //loadFile("belleview.osm");
  surface.setResizable(true);
}


void keyTyped() {
  char k = key;
  float d = 200/s;
  switch(k) {
    case 'w': py += d; break;
    case 'a': px += d; break;
    case 's': py -= d; break;
    case 'd': px -= d; break;
    case 'x': s *= 1.5; break;
    case 'z': s /= 1.5; break;
    case 'c': hide = !hide; break;
  }
  println("s "+s+" p "+px+", "+py);
}


void draw() {
  background(255);
  
  pushMatrix();
  translate(width/2, height/2);
  scale(s, -s);
  translate(px, -py);

  // DRAW ALL THE ROADS
  for (Way w: wayList) {
    Node p = null;
    strokeWeight(2);  
    if (w.highway == null) { stroke(100,255,100); if (hide) continue; }
    else if ("cycleway".equals(w.highway)) {stroke(255,255,50);if (hide) continue; }
    else if ("construction".equals(w.highway) || "service".equals(w.highway) || "proposed".equals(w.highway)) {stroke(50,255,255);if (hide) continue; }
    else if ("footway".equals(w.highway) || "steps".equals(w.highway) || "path".equals(w.highway)) {stroke(255,50,255);if (hide) continue; }
    else { stroke(120);   strokeWeight(11);  }
    for (Node n: w.nodeList) {
      if (p != null) 
        line(p.x, p.y, n.x, n.y);
      p = n;
    }
  }
  
  // DRAW ALL THE NODES
  if (!hide) {
    fill(0);
    noStroke();
    for (String id: nodeMap.keySet()) {
      Node n = nodeMap.get(id);
      ellipse(n.x, n.y, 10, 10);
    } //<>//
  }
  
  popMatrix();  //<>//
}


void loadFile(String name) {
  println("Begin loading... ");
  
  xml = loadXML(name);  

  println("Load complete.  Begin parsing NODES");
  
  // Initialize lon/lat window min/max
  float x0,x1,y0,y1;  
  x0 = 1e10;  y0 = x0;
  x1 = -x0;  y1 = -y0;
  
  // Parse all the NODE elements
  nodeMap = new HashMap<String,Node>();
  for (XML node: xml.getChildren()) {
    if (!node.getName().equals("node")) continue;
    Node n = new Node(node);
    nodeMap.put(node.getString("id"), n);
    x0 = Math.min(x0, n.lon);
    x1 = Math.max(x1, n.lon);
    y0 = Math.min(y0, n.lat);
    y1 = Math.max(y1, n.lat);
  }
  
  // Compute x,y from lon,lat (convert degrees to feet and re-center to zero)
  float aveLon = (x0 + x1) / 2;
  float aveLat = (y0 + y1) / 2;   //<>//
  float feetPerDeg = 364320;  // Convert degrees to feet at the equator
  // Shrink because longitude lines get closer together near poles
  float shrinkFactor = (float) Math.cos(Math.toRadians(aveLat));

  for (String id: nodeMap.keySet()) {
    Node n = nodeMap.get(id);
    n.x = (n.lon - aveLon) * feetPerDeg * shrinkFactor;
    n.y = (n.lat - aveLat) * feetPerDeg;
  }

  String roadtypes = "";

  println("Begin parsing WAYS");  
  
  // Parse all the WAY elements
  wayList = new ArrayList<Way>();
  for (XML node: xml.getChildren()) {
    if (!node.getName().equals("way")) continue;
    Way w = new Way();
    wayList.add(w);
    // connect the way to the nodes
    int bad = 0;
    for (XML c: node.getChildren()) {
      if (c.getName().equals("nd")) {
        Node n = nodeMap.get(c.getString("ref"));
        if (n == null) bad++;
        else w.nodeList.add(n);
      }
      else if (c.getName().equals("tag")) {
        // Each tag has key/value pairs (k,v)
        String k = c.getString("k");
        if ("name".equals(k)) w.name = c.getString("v");
        if ("highway".equals(k)) w.highway = c.getString("v");
        if ("lanes".equals(k)) w.lanes = c.getInt("v");
        if ("oneway".equals(k)) w.oneway = "yes".equals(c.getString("v"));
      }
    }
    if (bad > 0) println("The following way contains "+bad+" bad nodes: "+node);
    if (w.highway != null && !roadtypes.contains(w.highway)) roadtypes += " " + w.highway;    
  }
  println("Parse Complete.");  
    println(roadtypes);
}


void dump(XML xml, String pp) {
  if (xml.getName().equals("#text")) return;
  println(pp + xml.getName());
  String p2 = pp + ". ";
  for (XML c : xml.getChildren()) 
    dump(c, p2);
}