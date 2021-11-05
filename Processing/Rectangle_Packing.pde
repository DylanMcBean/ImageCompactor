import java.util.*; //<>// //<>// //<>//
boolean debugging = false;
int padding = 20;
ArrayList<PImage> images;
ArrayList<rect> rectangles;
ArrayList<layer> layers;
PGraphics DrawSurface;

int x_limit, image_width, image_height;


void setup() {
  size(400, 300);

  //fullScreen();
  String path = dataPath("/images/");

  String[] imageNames = listFileNames(path);

  println("Loading Images.");
  images = new ArrayList<PImage>();
  for (String s : imageNames) {
    if ((s.contains(".png") || s.contains(".jpg") || s.contains(".jpeg")) && images.size() < 3000) {
      images.add(loadImage(path+"/"+s));
    }
    println("Loaded: " + images.size());
  }

  images.sort(Collections.reverseOrder(Comparator.comparingInt(img -> img.height)));

  image_width = 0;
  image_height = 0;

  x_limit = 1_000_000;
  TestRun();
  rectangles = new ArrayList<rect>();
  layers = new ArrayList<layer>();
  DrawSurface = createGraphics(image_width, image_height);
}

void TestRun() {
  ArrayList<lmp> leftMostPoints = new ArrayList<lmp>();
  int x;
  int curr_layer;
  
  int best_minimum_width = 0, best_minimum_height = 0;
  int minimum_area = -1;
  ArrayList<Integer> previous_widths = new ArrayList<Integer>();
  int over_minimum = 0;
  
  while (true) {
    leftMostPoints = new ArrayList<lmp>();
    curr_layer = 0;
    rectangles = new ArrayList<rect>();
    layers = new ArrayList<layer>();
    x = 0;
    println("Pass: " + previous_widths.size());
    for (PImage img : images) {
      //sort leftMostPoints
      leftMostPoints.sort(Comparator.comparingInt(lmp_x -> lmp_x.x));

      boolean hasBeenPlaced = false;
      //check if point can be placed on any LeftMostPoints
      if (leftMostPoints.size() > 0) {
        for (lmp l : leftMostPoints) {
          if ((l.y - layers.get(l.layer).layer_y) + img.height <= layers.get(l.layer).layer_height && l.x + img.width <= x && !isOverlapping(l.x, l.y, img)) {
            rectangles.add(new rect(l.x-padding, l.y-padding, img.width+padding, img.height+padding));

            if (image_width <= l.x+img.width) image_width = l.x+img.width;
            if (image_height <= l.y+img.height) image_height = l.y+img.height;

            hasBeenPlaced = true;
            //try and place new leftMostPoint
            if (l.x + img.width < x) {
              leftMostPoints.add(new lmp(l.x+img.width+padding, l.y+img.height, l.layer));
            }

            l.y += img.height+padding;
            if (l.y == layers.get(curr_layer).layer_height) {
              leftMostPoints.remove(l);
            }
            x = max(x, l.x+img.width);
            break;
          }
        }
      }

      if (!hasBeenPlaced) {
        //add leftMostPoint if needed
        boolean found = false;
        for (lmp l : leftMostPoints) {
          if (l.x == x) {
            found = true;
            break;
          }
        }
        if (!found) {
          if (x == 0 && layers.size() == 0) {
            layers.add(new layer(0, img.height+padding));
          } else {
            if (x+img.width < x_limit || x_limit == -1) {
              leftMostPoints.add(new lmp(x, img.height+layers.get(curr_layer).layer_y+padding, curr_layer));
            }
          }
        }

        if (x+img.width > x_limit) {
          leftMostPoints.add(new lmp(x+padding, layers.get(curr_layer).layer_y, curr_layer));
          layers.add(new layer(layers.get(curr_layer).layer_y+layers.get(curr_layer).layer_height, img.height+padding));
          curr_layer += 1;
          x = 0;
          
          if (image_width <= x+img.width) image_width = x+img.width;
          if (image_height <= layers.get(curr_layer).layer_y+img.height) image_height = layers.get(curr_layer).layer_y+img.height;
          
          rectangles.add(new rect(x-padding, layers.get(curr_layer).layer_y-padding, img.width+padding, img.height+padding));
          x += img.width+padding;
        } else {
          
          if (image_width <= x+img.width) image_width = x+img.width;
          if (image_height <= layers.get(curr_layer).layer_y+img.height) image_height = layers.get(curr_layer).layer_y+img.height;
          
          rectangles.add(new rect(x-padding, layers.get(curr_layer).layer_y-padding, img.width+padding, img.height+padding));
          
          x += img.width+padding;
          if (x > x_limit) {
            layers.add(new layer(layers.get(curr_layer).layer_y+layers.get(curr_layer).layer_height, img.height+padding));
            println("here2");
            curr_layer += 1;
            x = 0;
          }
        }
      }
    }
    
    if (previous_widths.size() == 0){
      previous_widths.add(image_width);
      minimum_area = image_width*image_height;
      best_minimum_width = image_width;
      best_minimum_height = image_height;
      x_limit = image_width/2;
      over_minimum = 0;
    } else {
      int new_ratio = max(image_height,image_width) / min(image_height,image_width);
      if (new_ratio < minimum_area) {
        previous_widths.add(image_width);
        minimum_area = new_ratio;
        best_minimum_width = image_width;
        best_minimum_height = image_height;
        x_limit = image_width/2;
        over_minimum = 0;
      } else {
        if (over_minimum == 2){
          image_width = best_minimum_width;
          image_height = best_minimum_height;
          break;
        }
        over_minimum ++;
        previous_widths.add(image_width);
        x_limit = (image_width+previous_widths.get(previous_widths.size()-2))/2;
      }
    }
    image_width = 0;
    image_height = 0;
  }
}

void draw() {
  println("Started Generating");
  DrawSurface.beginDraw();
  ArrayList<lmp> leftMostPoints = new ArrayList<lmp>();
  int x = 0;
  int curr_layer = 0;
  x_limit = DrawSurface.width;
  for (PImage img : images) {
    //sort leftMostPoints
    leftMostPoints.sort(Comparator.comparingInt(lmp_x -> lmp_x.x));

    boolean hasBeenPlaced = false;
    //check if point can be placed on any LeftMostPoints
    if (leftMostPoints.size() > 0) {
      for (lmp l : leftMostPoints) {
        if ((l.y - layers.get(l.layer).layer_y) + img.height <= layers.get(l.layer).layer_height && l.x + img.width <= x && !isOverlapping(l.x, l.y, img)) {
          rectangles.add(new rect(l.x-padding, l.y-padding, img.width+padding, img.height+padding));
          DrawSurface.image(img, l.x, l.y);
          hasBeenPlaced = true;
          //try and place new leftMostPoint
          if (l.x + img.width < x) {
            leftMostPoints.add(new lmp(l.x+img.width+padding, l.y+img.height, l.layer));
          }

          l.y += img.height+padding;
          if (l.y == layers.get(curr_layer).layer_height) {
            leftMostPoints.remove(l);
          }
          x = max(x, l.x+img.width);
          break;
        }
      }
    }

    if (!hasBeenPlaced) {
      //add leftMostPoint if needed
      boolean found = false;
      for (lmp l : leftMostPoints) {
        if (l.x == x) {
          found = true;
          break;
        }
      }
      if (!found) {
        if (x == 0 && layers.size() == 0) {
          layers.add(new layer(0, img.height+padding));
        } else {
          if (x+img.width < x_limit) {
            leftMostPoints.add(new lmp(x, img.height+layers.get(curr_layer).layer_y+padding, curr_layer));
          }
        }
      }

      if (x+img.width > x_limit) {
        leftMostPoints.add(new lmp(x+padding, layers.get(curr_layer).layer_y, curr_layer));
        layers.add(new layer(layers.get(curr_layer).layer_y+layers.get(curr_layer).layer_height, img.height+padding));
        curr_layer += 1;
        x = 0;
        DrawSurface.image(img, x, layers.get(curr_layer).layer_y);
        rectangles.add(new rect(x-padding, layers.get(curr_layer).layer_y-padding, img.width+padding, img.height+padding));
        x += img.width+padding;
      } else {
        DrawSurface.image(img, x, layers.get(curr_layer).layer_y);
        rectangles.add(new rect(x-padding, layers.get(curr_layer).layer_y-padding, img.width+padding, img.height+padding));
        x += img.width+padding;
        if (x > x_limit) {
          layers.add(new layer(layers.get(curr_layer).layer_y+layers.get(curr_layer).layer_height, img.height+padding));
          curr_layer += 1;
          x = 0;
        }
      }
    }
  }

  //Debugging
  if (debugging) {
    DrawSurface.stroke(255, 70, 150);
    DrawSurface.strokeWeight(10);
    for (lmp l : leftMostPoints) {
      //DrawSurface.text(l.layer, l.x+2, l.y+8);
      DrawSurface.point(l.x, l.y);
    }

    DrawSurface.strokeWeight(1);
    DrawSurface.stroke(255, 70, 150);
    DrawSurface.noFill();
    for (rect r : rectangles) {
      DrawSurface.rect(r.x, r.y, r.w, r.h);
    }
  }
  DrawSurface.endDraw();
  println("Saving");
  DrawSurface.save("output.png");
  exit();
}

boolean isOverlapping(int x, int y, PImage img) {
  boolean isThereOverlap = false;
  for (rect r : rectangles) {
    boolean xOverlap = r.x < x + img.width &&
      r.x + r.w > x ;
    boolean yOverlap = r.y < y + img.height &&
      r.y + r.h > y ;
    boolean rectOverlaps = xOverlap && yOverlap;
    isThereOverlap = isThereOverlap || rectOverlaps;
  }

  return isThereOverlap;
}

String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } else {
    return null;
  }
}
