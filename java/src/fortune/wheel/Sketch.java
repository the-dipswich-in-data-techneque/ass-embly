package fortune.wheel;

import processing.core.PApplet;

public class Sketch extends PApplet {
  private static Button[] b = new Button[0];
  private static ReturnButton rb;
  private static State currentState = null;
  private static Wheel pickedWheel;
  private static short[] data = null;
  private static int currentPlayer = 0;
  @Override
  public void settings() {
    size(400, 400);
  }
  @Override
  public void setup() {
    setStates(State.start, null);
  }
  public void draw(){
    background(180f);
    Button.drawButton(getGraphics(),this);
    switch (currentState) {
      case start:
        text("Pick a number of players for the game",0 ,0);
        break;
      case wheelPick:
        text("player#" + currentPlayer, 10, 10);
        break;
      case wheelSpin:
        pickedWheel.display(getGraphics(), .02f);
        int slot = UART.getShort(false);
        if(UART.success){
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
  
  public static int[] generateSlots(int[] value, int[] multiplier,int randomFactor){
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
      int randomIndex = i + (int)(Math.random() *randomFactor);
      if(randomIndex >= slots.length) randomIndex -= slots.length;
      if(randomIndex < 0) randomIndex += slots.length;
      slots[i] = slots[randomIndex];
      slots[randomIndex] = temp;
    }
    return slots;
  }
  public static void setStates(State state, Object o){
    currentState = state;
    switch (currentState) {
      case start:
        for (int i = 0; i < b.length; i++) {
          b[i].remove();
        }
        break;
      default:
        break;
    }
    switch (state) {
      case start:
        b = new Button[4];
        b[0] = new StartButtons(10, 10, 10, 10, 0);
        b[1] = new StartButtons(20, 20, 20, 20, 1);
        b[2] = new StartButtons(30, 30, 30, 30, 2);
        b[3] = new StartButtons(40, 40, 40, 40, 3);
        currentState = state;
        break;
      case wheelSpin:
        pickedWheel = (Wheel)o;
        currentState = state;
        pickedWheel.setLocation(200, 200, 100);
        pickedWheel.sendSlots();
        break;
      case wheelPick:
        b = new Button[4];
        WheelButton wb;

        wb = new WheelButton(50, 200, 50);
        wb.setSlots(generateSlots(new int[]{0,1,2,3,4,5,6,7,8,9}, new int[]{1,1,1,1,1,1,1,1,1,1}, 5));
        b[0] = wb;

        wb = new WheelButton(50, 200, 50);
        wb.setSlots(generateSlots(new int[]{0,1,2,3,4,5,6,7,8,9}, new int[]{1,1,1,1,1,1,1,1,1,1}, 5));
        b[1] = wb;
        
        wb = new WheelButton(50, 200, 50);
        wb.setSlots(generateSlots(new int[]{0,1,2,3,4,5,6,7,8,9}, new int[]{1,1,1,1,1,1,1,1,1,1}, 5));
        b[2] = wb;
        
        wb = new WheelButton(50, 200, 50);
        wb.setSlots(generateSlots(new int[]{0,1,2,3,4,5,6,7,8,9}, new int[]{1,1,1,1,1,1,1,1,1,1}, 5));
        b[3] = wb;
        
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