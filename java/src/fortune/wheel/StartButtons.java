package fortune.wheel;

/**
 *  StartButtons
 */
public class StartButtons extends Button{
    private int id;
    public StartButtons(int x, int y, int width, int height, int id, String txt) {
        super(x, y, width, height, txt);
        this.id = id;
    }

    @Override
    protected void action() {
        switch (id) {
            case 0:
                Players.setup(1, 1000);
                break;
            case 1:
                Players.setup(2, 1000);
                break;
            case 2:
                Players.setup(3, 1000);
                break;
            case 3:
                Players.setup(4, 1000);
                break;
        }
    }

}