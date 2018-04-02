/*
This can parse the OSM files.
You can get OSM files from https://www.openstreetmap.org  just click "export"

TODO

allow straighten any road set 
allow save
set numlanes
set direction (1 way, 2 way)
draw arrow for direction, if one-way
show numlanes
*/

XML xml;
float s = .02;
boolean showhelp = false;
float px,py;
boolean hide = true;
HashMap<String,Node> nodeMap;
ArrayList<Way> wayList;
HashMap<String,RoadType> rtMap; 
RoadType currType;

void setup() {
  size(1000, 800);
  loadFile("elgin-map.osm"); s=.22; px=4600; py=-1300;
  //loadFile("belleview.osm"); s=0.03; px=0; py=32222;
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
    case 'n': hide = !hide; break;
    case 'h': if (currType!=null) currType.show = !currType.show; break;
    case '?': case '/': showhelp = !showhelp; break;
    case 'o': writeFile(); break;
    case 'c': setColor(); break;
    case 'r': reduce(); break;
    case 'R': for (int i=0;i<10;++i) reduce(); break;
  }
  //println("s "+s+" p "+px+", "+py);
}



void reduce() {
  // search all currType ways and see if any can be removed.
  if (currType==null) return;
  Way bestw = null;
  int besti = 0;
  float best = 0;
  for (Way w : wayList) {
    if (!same(w.highway, currType.k)) continue;
    for (int i=1; i < w.nodeList.size()-1; ++i) {
      Node n = w.nodeList.get(i);
      if (n.numway == 2) {
        float h = n.heron4area2(w.nodeList.get(i-1), w.nodeList.get(i+1));
        if (bestw == null || h < best) {
          best = h;
          besti = i;
          bestw = w;
        }
      }
    }
  }
  if (bestw != null) {
    println("removed node "+besti+" with area "+.25*Math.sqrt(best));
    bestw.nodeList.remove(besti);
  }  
}

boolean same(String q, String p) {
  if (q==null) return p==null;
  return q.equals(p);
}

void writeFile() {
}

void setColor() {
  if (currType==null) return;
  currType.cc = (currType.cc + 1) % 7;
  if (currType.cc==0) currType.c = color(150);
  else if (currType.cc==1) currType.c = color(250,0,0);
  else if (currType.cc==2) currType.c = color(250,250,0);
  else if (currType.cc==3) currType.c = color(0,250,0);
  else if (currType.cc==4) currType.c = color(0,250,250);
  else if (currType.cc==5) currType.c = color(0,0,250);
  else if (currType.cc==6) currType.c = color(250,0,250);
  else currType.c = color(250,40,120);
}

void mouseMoved() {
  currType = null;
  for (RoadType rt : rtMap.values()) {
    rt.hover = mouseY > rt.y && mouseY < rt.y + 18 && mouseX < 120;
    if (rt.hover) currType = rt;
  }
}

void draw() {
  background(255);
  
  pushMatrix();
  translate(width/2, height/2);
  scale(s, -s);
  translate(px, -py);

  // RESET counters
  for (RoadType rt : rtMap.values()) rt.reset();
  for (Node n: nodeMap.values()) n.reset();

  // DRAW ALL THE ROADS
  for (Way w: wayList) {
    Node p = null;
    RoadType rt = rtMap.get(w.highway);
    rt.numway++;
    rt.numnode += w.nodeList.size();
    if (!rt.show) continue;
    strokeWeight(rt.w);  
    stroke(rt.c);
    for (Node n: w.nodeList) {
      if (p != null) { line(p.x, p.y, n.x, n.y); p.numway++; }
      n.numway++;
      p = n;
    }
    if (!hide) {
      //p = null;
      //for (Node n: w.nodeList) {
      //  if (p != null) 
      //    line(p.x, p.y, n.x, n.y);
      //  p = n;
      //}
    }
  }
  
  // DRAW ALL THE NODES
  if (!hide) {
    fill(0);
    noStroke();
    for (Node n: nodeMap.values()) {
      if (n.numway == 0) fill(240);
      else if (n.numway == 2) fill(255,0,0);
      else fill(0);
      ellipse(n.x, n.y, 10, 10);
    } //<>//
  }
  
  popMatrix();  //<>//
  
  drawText();
}


void drawText() {
  int y = 30;
  int dy = 15;
  int x = 20;
  fill(0);
  text("? for help", x, 25); 
  if (showhelp) {
    text("wasd - pan", x, y += dy); 
    text("zx - zoom", x, y += dy); 
    text("c - set color of road type", x, y += dy); 
    text("h - show/hide road types", x, y += dy); 
    text("n - show/hide nodes and stuff like that", x, y += dy); 
    text("o - save visible roads to XML file", x, y += dy); 
    text("r - reduce one node", x, y += dy); 
    text("R - reduce 10 nodes", x, y += dy); 
    text("", x, y += dy); 
    return;
  }  
  strokeWeight(1);
  for (String r : rtMap.keySet()) {
    RoadType rt = rtMap.get(r);
    y = rt.y;
    noStroke(); if (rt==currType) stroke(0);
    fill(rt.c); rect(x, y, rt.show ? 120 : 100, 15);
    String s = r == null ? "(null)" : r;
    s = rt.numway + " : " + rt.numnode + " - " + s;
    fill(0); text(s, x + 5, y + 12);
  }
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

  String roadtypes = "RoadTypes: ";
  println("Begin parsing WAYS");  
  
  // Parse all the WAY elements
  wayList = new ArrayList<Way>();
  rtMap = new HashMap<String,RoadType>();
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
    if (!rtMap.containsKey(w.highway)) rtMap.put(w.highway,new RoadType(w.highway));
  }
  println("Parse Complete.");  
  println(roadtypes);

  int y = 30;
  int dy = 18;
  for (RoadType rt : rtMap.values()) {
    rt.y = (y += dy);
  }
}


void dump(XML xml, String pp) {
  if (xml.getName().equals("#text")) return;
  println(pp + xml.getName());
  String p2 = pp + ". ";
  for (XML c : xml.getChildren()) 
    dump(c, p2);
}