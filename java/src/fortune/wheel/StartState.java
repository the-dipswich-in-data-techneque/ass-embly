package fortune.wheel;

import processing.core.PGraphics;

public class StartState extends Button {
    //start page should have text and 4 button for amount of players
    private Button p1; 
    private Button p2;
    private Button p3;
    private Button p4;

    public StartState(int x, int y, int width, int height) {
        super(x, y, width, height);
    }

    public void helloText(int x, int y, String wellcome){
        wellcome = "Pick a number of players for the game";
    }

    @Override
    protected void action() {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'action'");
    }

}
