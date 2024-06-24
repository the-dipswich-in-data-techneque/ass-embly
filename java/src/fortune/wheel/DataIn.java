package fortune.wheel;

import java.util.ArrayList;
import java.util.Scanner;

public class DataIn {
  private static ArrayList<Byte> newData;
  private static Thread t;
  public static boolean enable(){
    if(t != null && t.isAlive()){
      return false;
    }
    t = new reader();
    return true;
  }
  public static boolean disable(){
    if(t == null || !t.isAlive()){
      return false;
    }
    ((reader)t).end = true;
    try {
      Thread.sleep(1);
    } catch (InterruptedException ignore) {}
    if(t.isAlive()) t.interrupt();
    return true;
  }
  public static byte[] read(int byteCount){
    byte[] data = new byte[Math.min(byteCount,newData.size())];
    for(int i = 0; i < byteCount; i++){
      data[i] = newData.remove(0);
    }
    return data;
  }
  public static class reader extends Thread{
    private Scanner scan;
    public boolean end = false;
    public reader(){
      scan = new Scanner(System.in);
    }
    public void run(){
      try {
        while(true){
          if(scan.hasNextByte())
            newData.add(scan.nextByte());
          if (end) return;
            Thread.sleep(1);
          }
        }
        catch (InterruptedException e) {
        return;
      }
    }
  }
}
