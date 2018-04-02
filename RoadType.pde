
class RoadType {
  String k;
  color c;
  int cc;
  int numway;
  int numnode;
  boolean show;
  int w;
  int y;
  boolean hover;
  public RoadType(String n) {
    k = n;
    show = false;
    if (n == null) { c = color(100,255,100);  }
    else if ("cycleway".equals(n)) {c = color(255,255,50); w = 5; }
    else if ("track".equals(n)) {c = color(180); w = 5; }
    else if ("construction".equals(n) || "service".equals(n) || "proposed".equals(n)) {c = color(50,255,255); w = 7; }
    else if ("footway".equals(n) || "steps".equals(n) || "path".equals(n)) {c = color(255,50,255); w = 5; }
    else { c = color(150);  w = 11; show = true; }
  }
  
  void reset() {
    numway = 0; numnode=0;
  }
}