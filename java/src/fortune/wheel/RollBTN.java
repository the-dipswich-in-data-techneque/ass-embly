package fortune.wheel;

public class RollBTN extends Button {
    public RollBTN(){
        super(100, 100, 150, 75);
        }
    @Override
    protected void action() {
        buttonTxt = "done";
        
    }
    
}
