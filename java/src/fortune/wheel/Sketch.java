package fortune.wheel;

import processing.core.PApplet;

public class Sketch extends PApplet {
  private static Button[] b = new Button[0];
  private static ReturnButton rb;
  private static State currentState = State.init;
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
        push();
        noStroke();//plz
        fill(0,0,0);
        textAlign(CENTER);
        text("Pick a number of players for the game, you start with 1000",170 ,40);
        text("it costs 100 pr.spin",140,60 );
        pop();
        break;
      case wheelPick:
        push();
        fill(0,0,0);
        text("player#" + currentPlayer, 170, 80);
        pop();
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
      case init:
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
        b[0] = new StartButtons(80, 80, 120, 40, 0, "1 player");
        b[1] = new StartButtons(80, 130, 120, 40, 1, "2 players");
        b[2] = new StartButtons(80, 180, 120, 40, 2, "3 players");
        b[3] = new StartButtons(80, 230, 120, 40, 3, "4 players");
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
        wb.setSlots(generateSlots(new int[]{1,5,10,15,20,30,60,90,100,150,200,250}, new int[]{2,2,2,2,3,4,5,9,10,6,5,5}, 5));
        b[0] = wb;

        wb = new WheelButton(150, 200, 50);
        wb.setSlots(generateSlots(new int[]{1,5,10,15,20,30,60,90,100,150,200,250,300,400,500}, new int[]{5,5,5,5,5,6,8,9,10,6,5,4,3,2,1}, 5));
        b[1] = wb;
        
        wb = new WheelButton(250, 200, 50);
        wb.setSlots(generateSlots(new int[]{1,5,10,15,20,30,60,90,100,150,200,250,300,400,500,750}, new int[]{4,5,10,10,10,10,15,10,15,5,5,5,4,3,2,1}, 5));
        b[2] = wb;
        
        wb = new WheelButton(350, 200, 50);
        wb.setSlots(generateSlots(new int[]{15,20,30,60,90,100,150,200,250,500,1000}, new int[]{10,10,10,20,15,20,11,5,5,1,1}, 5));
        b[3] = wb;
        
        currentState = state;
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
    init
  }
}