import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress maxAddress;
SendMessage sender;
int tile_width, tile_height, starting_x;
int numRectangles = 4;
Rectangle[] rectangles = new Rectangle[numRectangles];

void setup() {
  size(720, 1080);
  tile_width = 140;
  tile_height = 250;
  starting_x = 20;
  for (int i =0; i <numRectangles; i++) {
    rectangles[i] = new Rectangle(starting_x+(i*180), (height-200), tile_width, tile_height);
  }
sender = new SendMessage("127.0.0.1", 7400);

}
void draw() {
  background(34, 32, 32);

  for (int i=0; i<numRectangles; i++) {
    rectangles[i].display();
  }
}

void mousePressed() {
  for (int i=0; i<numRectangles; i++) {
    rectangles[i].checkClick(true);
    
  }

}

void mouseReleased() {
  for (int i=0; i<numRectangles; i++) {
    rectangles[i].checkClick(false);
  }
}
