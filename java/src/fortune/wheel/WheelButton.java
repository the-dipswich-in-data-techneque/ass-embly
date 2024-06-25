package fortune.wheel;

import processing.core.PApplet;
import processing.core.PGraphics;

public class WheelButton extends Button{
  private float destination = -1f;
  private Wheel w;
  public WheelButton(int x, int y, int r){
    super(x - r / 2, y - r / 2, r * 2, r * 2, " ");
    w = new Wheel(x, y, r);
  }
  public void setSlots(int[] slots) {
    w.setSlots(slots);
  }
  @Override
  public void draw(PGraphics g, PApplet p){
    w.display(g, 0.005f);
    if(destination != -1f) {
      w.display(g, 0.005f);
    }else{
      w.safeRotate(g, 0.005f);
    }
    w.hueGraph(
      g,
      w.getLocation()[0],
      w.getLocation()[1] + w.getLocation()[2] + 5,
      20,
      w.getLocation()[2]
    );
  }
  @Override
  protected void action() {
    Sketch.setStates(Sketch.State.wheelSpin, w);
  }
}