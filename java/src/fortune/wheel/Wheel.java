package fortune.wheel;

import processing.core.PApplet;
import processing.core.PGraphics;

public class Wheel {
  private int x,y,r;
  private int[] slots;
  private int min,max;
  private float destination;
  private float rotation;
  // private final float colorScale = 3.75f;
  private final float colorScale = 1.4f;
  public Wheel(int x, int y, int r) {
    this.x = x;
    this.y = y;
    this.r = r;
    slots = new int[]{0};
  }
  public void setLocation(int x, int y, int r){
    this.x = x;
    this.y = y;
    this.r = r;
  }
  public void setSlots(int[] slots) {
    this.slots = slots;
    min = slots[0];
    max = slots[0];
    for (int i = 0; i < slots.length; i++) {
      if(slots[i] < min) min = slots[i];
      else if(slots[i] > max) max = slots[i];
    }
  }
  public void setDestination(int destination){
    double perSlot = Math.PI * 2d / (double)slots.length;
    this.destination = (float)(perSlot * destination - Math.PI / 2 - perSlot / 2);
    while(this.destination < 0) this.destination += Math.PI * 2;
  }
  public void display(PGraphics g, float rotation){
    g.push();
    g.translate(x, y);
    g.rotate(this.rotation + rotation);
    g.colorMode(PApplet.HSB,(max-min)*colorScale,1f,1f);
    g.fill(255);
    g.color(0,0,0);
    g.circle(0, 0, (float)r);
    float start = 0f; 
    float end = PApplet.PI*2f/slots.length;
    for (int i = 0; i < slots.length; i++) {
      g.fill(slots[i]-min,1,1);
      g.arc(0, 0, r*2, r*2, start, end);
      start = end;
      end += PApplet.PI*2f/slots.length;
    }
    g.pop();
    this.rotation += rotation;
    while(this.rotation < 0) this.rotation += Math.PI * 2;
    while(this.rotation > Math.PI * 2) this.rotation -= Math.PI * 2;
  }
  public boolean safeRotate(PGraphics g, float rotation){
    if(
        rotation >= 0 && this.rotation + rotation >= destination && this.rotation <= destination || 
        rotation <= 0 && this.rotation + rotation <= destination && this.rotation >= destination
      ) {
      this.rotation = destination;
      display(g, 0);
      return false;
    }
    display(g,rotation);
    return true;
  }
  public void hueGraph(PGraphics g, int x, int y, int width, int height){
    g.push();
    g.colorMode(PApplet.HSB,(max-min)*colorScale,1f,1f);
    g.strokeWeight(0.9f);
    for(int i = 0; i < height; i++){
      g.stroke((i*(max-min))/(float)height,1,1);
      g.line(x, y + i, x + width, y + i);
    }
    g.stroke(0);
    g.fill(0);
    g.text("" + min, x + width * 1.1f, y);
    g.text("" + max, x + width * 1.1f, y + height);
    g.pop();
  }
  public void setRotation(int slot){
    double perSlot = Math.PI * 2d / (double)slots.length;
    this.rotation = (float)(perSlot * slot - Math.PI / 2 - perSlot / 2);
    while(this.rotation < 0) this.rotation += Math.PI * 2;
  }
  public void setRotation(float rotation){
    this.rotation = rotation;
    while(this.rotation < 0) this.rotation += Math.PI * 2;
  }
  public int[] getLocation(){
    return new int[]{x,y,r};
  }
  public void sendSlots() {
    for (int i = 0; i < slots.length; i++) {
      UART.sendShort((short)slots[i], true);
    }
  }
  public int getSlot(int i){
    return slots[i];
  }
}
