package fortune.wheel;

import processing.core.PApplet;
import processing.core.PGraphics;

public class RollBTN extends Button {
    public RollBTN(){
        super(100, 100, 150, 75);
        }
    @Override
    protected void action() {
        buttonTxt = "done";
        
    }
    
}
