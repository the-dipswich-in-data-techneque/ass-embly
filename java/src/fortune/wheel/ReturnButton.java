package fortune.wheel;

import fortune.wheel.Sketch.State;

public class ReturnButton extends Button{
  State returnPoint;
  public ReturnButton(int x, int y, int width, int height, State returnPoint) {
    super(x, y, width, height);
    this.returnPoint = returnPoint;
    buttonTxt = "Return";
  }
  @Override
  protected void action() {
    Sketch.setStates(returnPoint, null);
  }
}
