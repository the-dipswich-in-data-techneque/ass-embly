package fortune.wheel;

import processing.core.PApplet;

public class Sketch extends PApplet {
  private Button b = new RollBTN();
  private static ReturnButton rb;
  private static State currentState = State.start;
  private static Wheel pickedWheel;
  private static short[] data = null;
  private static int currentPlayer = 0;
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
        pickedWheel.display(getGraphics(), .02f);
        int slot = UART.getShort(false);
        if(slot != -1){
          pickedWheel.setDestination(slot);
          Players.addMoney(currentPlayer, pickedWheel.getSlot(slot));
          setStates(State.wheelStopping, null);
        }
        break;
      case wheelStopping:
        if(pickedWheel.safeRotate(getGraphics(), .02f)){
          setStates(State.lastRolls, null);
        }
        
        break;
      case lastRolls:
      text("Last Rolls", 0, 0);
      for (int i = 0; i < Players.getPlayerAmount(); i++) {
        text("#" + i, 0, 10 + 10 * i);
      }
        for (int i = 0; i < data.length; i++) {
          text(
            data[i], 
            10 + 10 * (i % Players.getPlayerAmount()), 
            10 + 10 * (i / Players.getPlayerAmount())
          );
        }
        break;
      case bank:
        text("Bank", 10, 10);
        for (int i = 0; i < Players.getPlayerAmount(); i++) {
          text(
            "player#" + i + " : " + Players.getMoney(i) + "kr.", 
            100, 
            50 + (300 / Players.getPlayerAmount()) * i
          );
        }
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
        pickedWheel.setLocation(200, 200, 100);
        pickedWheel.sendSlots();
        break;
      case bank:
        rb = new ReturnButton(50, 250, 10, 50, Sketch.currentState);
        currentState = state;
        break;
      case lastRolls:
      data = new short[Players.getPlayerAmount() * 10];
      for (int i = 1; i < data.length + 1; i++) {
        UART.sendShort((short)-i, true);
        data[i - 1] = UART.getShort(true);
      }
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
    wheelStopping,
    lastRolls,
    bank,
    end,
  }
}