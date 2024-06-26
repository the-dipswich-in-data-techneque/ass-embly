package fortune.wheel;

public class Players {
  static private int[] money;
  static public void setup(int amount, int startMoney) {
    money = new int[amount];
    for (int i = 0; i < money.length; i++) {
      money[i] = startMoney;
    }
    UART.sendShort((short)amount, true);
    UART.sendShort((short)-startMoney, true);
    UART.sendShort((short)0, true);
  }
  static public void addMoney(int player, int amount) {
    money[player] += amount;
  }
  static public void payRoll(int player) {
    money[player] -= 100;
  }

  static public int getMoney(int player) {
    return money[player];
  }
  static public int getPlayerAmount() {
    return money.length;
  }
}
