package fortune.wheel;

import processing.core.PApplet;

public class Sketch extends PApplet {
  private Button b = new RollBTN();
  private static State currentState = State.start;
  private static Wheel pickedWheel;
  @Override
  public void settings() {
    size(400, 400);
  }
  @Override
  public void setup() {
    b.drawButton(getGraphics(), this);
  }
  
  public void draw(){
    background(180f);
    switch (currentState) {
      case start:
        // needs a way to make 4 buttons so that we can pick the amount of players
        break;
      case wheelPick:
        // needs a way to show what player it is and have the need to pick a wheel
        // also have a way to get to lastroll and bank from her.
        break;
      case wheelSpin:
        //shows the wheel spin
        break;
      case lastRolls:
        // show the last 10 rolls and be able to return to wheelPick
        break;
      case bank:
        //show the amount of money every player has.
        break;
      case end:
        // end screen.
        break;
    }
  }

  @Override
  public void mousePressed() {
    Button.click(this);
  }
  
  public int[] generateSlots(int[] value, int[] multiplier,int randomFactor){
    if(value.length != multiplier.length) return new int[]{0};
    int length = 0;
    for (int i = 0; i < multiplier.length; i++) {
      length += multiplier[i];
    }
    if(randomFactor > length) randomFactor = length;
    int[] slots = new int[length];
    int index = 0;
    for (int i = 0; i < value.length; i++) {
      for (int j = 0; j < multiplier[i]; j++) {
        slots[index] = value[i];
        index++;
      }
    }
    for (int i = 0; i < slots.length; i++) {
      int temp = slots[i];
      int randomIndex = i + (int)random(randomFactor);
      if(randomIndex >= slots.length) randomIndex -= slots.length;
      if(randomIndex < 0) randomIndex += slots.length;
      slots[i] = slots[randomIndex];
      slots[randomIndex] = temp;
    }
    return slots;
  }
  public static void setStates(State state, Object o){
    currentState = state;
    switch (state) {
      case wheelSpin:
        pickedWheel = (Wheel)o;
        currentState = state;
        break;
      default:
        currentState = state;
        break;
    }
  }
  public enum State{
    start,
    wheelPick,
    wheelSpin,
    lastRolls,
    bank,
    end,
  }
}