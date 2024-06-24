package fortune.wheel;

import processing.core.PApplet;

public class Sketch extends PApplet {
  Wheel w = new Wheel(200, 200, 100);
  float r = 0;
  int i = 1000;
  @Override
  public void settings() {
    size(400, 400);
  }
  @Override
  public void setup() {
    background(180f);
    w.setSlots(generateSlots(
      new int[] {0,1,20,30,60,90,100,150,200,250}, 
      new int[] {1,1,10,10,25,35,60 ,18 ,11 ,5},
      50
    ));
    w.setDestination(20);
    w.display(getGraphics(), 0f);
    w.hueGraph(getGraphics(), 300, 50, 20, 250);
  }
  @Override
  public void draw() {
    background(180f);
    w.hueGraph(g, 300, 50, 20, 250);
    if(i > 0){
      w.display(g, 0.02f);
      i--;
    }else{
      w.safeRotate(g, 0.02f);
    }
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
  public void mouseClicked() {
    Button.click(this);
  }
  public enum state{
    start,
    wheelPick,
    wheelSpin,
    lastRolls,
    bank,
    end,
  }
}