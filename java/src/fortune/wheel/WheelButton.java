package fortune.wheel;

import processing.core.PGraphics;

public class WheelButton extends Button{
  private float destination = -1f;
  private Wheel w;
  public WheelButton(int x, int y, int r){
    super(x - r / 2, y - r / 2, r * 2, r * 2);
    w = new Wheel(x, y, r);
  }
  public void setSlots(int[] slots) {
    w.setSlots(slots);
  }
  public void display(PGraphics g, float rotation) {
    w.display(g, rotation);
    if(destination != -1f) {
      w.display(g, rotation);
    }else{
      w.safeRotate(g, rotation);
    }
  }
  @Override
  protected void action() {
    Sketch.setStates(Sketch.State.wheelPick, w);
  }
}