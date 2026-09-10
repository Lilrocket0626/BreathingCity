// Breathing City - Stage 1: Static visual foundation
// Student: Jiangpeng Huang
// 52685 Creative Coding, Assessment 2
//
// This first version builds the visual world before sound interaction is added.
// The final version will connect microphone amplitude to the city's appearance.

Building[] buildings;

void settings() {
  size(1280, 720);
}

void setup() {
  smooth(8);
  frameRate(60);
  randomSeed(52685); // A fixed seed keeps the generated skyline consistent.

  buildings = new Building[24];
  float x = -20;

  for (int i = 0; i < buildings.length; i++) {
    float buildingWidth = random(45, 85);
    float buildingHeight = random(120, 330);
    buildings[i] = new Building(x, height - 125, buildingWidth, buildingHeight);
    x += buildingWidth - 4;
  }
}

void draw() {
  drawSkyGradient();
  drawMoon();

  for (int i = 0; i < buildings.length; i++) {
    buildings[i].display();
  }

  drawHarbour();
  drawTitle();
}

// Draws the evening sky as many horizontal lines whose colours are interpolated.
void drawSkyGradient() {
  int topColour = color(8, 14, 43);
  int bottomColour = color(32, 64, 94);

  for (int y = 0; y < height; y++) {
    float amount = map(y, 0, height, 0, 1);
    stroke(lerpColor(topColour, bottomColour, amount));
    line(0, y, width, y);
  }
}

void drawMoon() {
  noStroke();
  fill(232, 245, 255, 215);
  circle(width * 0.80, height * 0.18, 72);
}

void drawHarbour() {
  noStroke();
  fill(5, 17, 36, 220);
  rect(0, height - 125, width, 125);

  stroke(96, 182, 211, 80);
  for (int i = 0; i < 9; i++) {
    float y = height - 105 + i * 12;
    line(0, y, width, y);
  }
}

void drawTitle() {
  fill(235, 246, 255, 220);
  textAlign(LEFT, TOP);
  textSize(28);
  text("BREATHING CITY", 36, 30);

  fill(177, 205, 220, 180);
  textSize(13);
  text("Stage 1 - visual foundation", 38, 67);
}

class Building {
  float x;
  float groundY;
  float w;
  float h;
  int columns;
  int rows;

  Building(float startX, float bottomY, float buildingWidth, float buildingHeight) {
    x = startX;
    groundY = bottomY;
    w = buildingWidth;
    h = buildingHeight;
    columns = max(2, int(w / 17));
    rows = max(3, int(h / 24));
  }

  void display() {
    noStroke();
    fill(10, 20, 40);
    rect(x, groundY - h, w, h);

    // Each window is generated from the building's rows and columns.
    float gapX = w / (columns + 1);
    float gapY = h / (rows + 1);

    for (int row = 1; row <= rows; row++) {
      for (int column = 1; column <= columns; column++) {
        float windowX = x + column * gapX - 3;
        float windowY = groundY - h + row * gapY - 4;
        float glow = noise(column * 0.7, row * 0.6, x * 0.01);

        if (glow > 0.47) {
          fill(244, 196, 92, 155 + glow * 70);
        } else {
          fill(45, 77, 103, 105);
        }
        rect(windowX, windowY, 6, 8, 1);
      }
    }
  }
}
