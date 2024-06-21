package fortune.wheel;

import processing.core.PApplet;

public class Main {
  private static Sketch sketch; 
  public static void main(String[] args) {
    String[] processingArgs = {"Sketch"};
    sketch = new Sketch();
    PApplet.runSketch(processingArgs,sketch);
  }
}
