package fortune.wheel;

import java.util.ArrayList;

import processing.core.PApplet;
import processing.core.PGraphics;

public abstract class Button{
    public static ArrayList<Button> active = new ArrayList<>();
    protected int buttonX = 100, buttonY = 100, buttonWidth = 150, buttonHeight = 75;
    //protected String buttonTxt = "You can click me";
    public String txt;
    private boolean buttonHovered = false;
    public static void click(PApplet p){
        for (int i = 0; i < active.size(); i++) {
            if(active.get(i) != null){
                active.get(i).mousePressed(p);
            }else{
                active.remove(i);
            }
        }
    }
    
    public Button (int x, int y, int width, int height, String txt){
        this.buttonX = x;
        this.buttonY = y;
        this.buttonWidth = width;
        this.buttonHeight = height;
        this.txt = txt;
        active.add(this);
    }
    public static void drawButton(PGraphics g, PApplet p) {
        for (int i = 0; i < active.size(); i++) {
            active.get(i).buttonHovered = active.get(i).isMouseOverButton(p);
            if(active.get(i).buttonHovered){
                g.fill(200);
            } else{
                g.fill(150);
            }
            g.rect(active.get(i).buttonX, active.get(i).buttonY, active.get(i).buttonWidth, active.get(i).buttonHeight);
            g.fill(0);
            g.textAlign(PApplet.CENTER, PApplet.CENTER);
            //g.text(active.get(i).buttonTxt, active.get(i).buttonX + active.get(i).buttonWidth / 2, active.get(i).buttonY + active.get(i).buttonHeight / 2);
            g.text(active.get(i).txt, active.get(i).buttonX + active.get(i).buttonWidth / 2, active.get(i).buttonY + active.get(i).buttonHeight / 2);
        }

}
    public void mousePressed(PApplet p) {
        if (isMouseOverButton(p)) {
            action();
        }
    }
    abstract protected void action();
    public void remove(){
        active.remove(this);
    }
    boolean isMouseOverButton(PApplet p){
        return  p.mouseX > buttonX && p.mouseX < buttonX + buttonWidth &&
                p.mouseY > buttonY && p.mouseY < buttonY + buttonHeight;
    }


}