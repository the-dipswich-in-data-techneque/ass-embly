package fortune.wheel;

import processing.core.PApplet;

public class Sketch extends PApplet {
  Button b = new RollBTN();
  State currentState = State.start;
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
        
        break;
    
      default:
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

  
  public enum State{
    start,
    wheelPick,
    wheelSpin,
    lastRolls,
    bank,
    end,
  }
}