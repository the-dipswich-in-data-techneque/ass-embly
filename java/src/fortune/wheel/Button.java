package fortune.wheel;

import java.util.ArrayList;

import processing.core.PApplet;
import processing.core.PGraphics;

public abstract class Button{
    public static ArrayList<Button> active = new ArrayList<>();
    protected int buttonX = 100, buttonY = 100, buttonWidth = 150, buttonHeight = 75;
    protected String buttonTxt = "You can click me";
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
    
    public Button (int x, int y, int width, int height){
        this.buttonX = x;
        this.buttonY = y;
        this.buttonWidth = width;
        this.buttonHeight = height;
        active.add(this);
    }
    public void drawButton(PGraphics g, PApplet p) {
        buttonHovered = isMouseOverButton(p);
        if(buttonHovered){
            g.fill(200);
        } else{
            g.fill(150);
        }
        g.rect(buttonX, buttonY, buttonWidth, buttonHeight);
        g.fill(0);
        g.textAlign(PApplet.CENTER, PApplet.CENTER);
        g.text(buttonTxt, buttonX + buttonWidth / 2, buttonY + buttonHeight / 2);
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