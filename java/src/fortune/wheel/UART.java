package fortune.wheel;
import com.fazecast.jSerialComm.SerialPort;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

public class UART{
    public static boolean success = false;
    private static SerialPort port;

    public static void setup() {
        SerialPort[] ports = SerialPort.getCommPorts();
        
        port = ports[0];
        for (int i = 0; i < ports.length; i++) {
            if(ports[i].getDescriptivePortName().contains("UART") || ports[i].getDescriptivePortName().contains("Feather")){
                port = ports[i];
                break;
            }
        }
        port.setComPortParameters(19200, 8, SerialPort.ONE_STOP_BIT, SerialPort.NO_PARITY);
        port.setComPortTimeouts(SerialPort.TIMEOUT_READ_BLOCKING, 0, 0);
        port.openPort();
    }

    public static short getShort(boolean locking){
        byte[] shortBuffer = new byte[2];
        long timeout = System.currentTimeMillis() + 100;
        do {
            int bytesRead = port.readBytes(shortBuffer, shortBuffer.length);

            if(bytesRead == 2){
                success = true;
                return ByteBuffer.wrap(shortBuffer).order(ByteOrder.BIG_ENDIAN).getShort();
            }
        }while (locking && System.currentTimeMillis() < timeout);
        success = false;
        return 0;
    }

    public static boolean sendShort(short value, boolean locking){
        byte[] shorty = new byte[] {(byte)(value & 0xff), (byte)(value >> 8)};
        long timeout = System.currentTimeMillis() + 100;
        int bytesWritten = 0;

    while (bytesWritten < 2 && System.currentTimeMillis() < timeout) {
            bytesWritten += port.writeBytes(shorty, shorty.length - bytesWritten, bytesWritten);
        }
    
        if (bytesWritten == 2) {
            if (locking) {
                while (System.currentTimeMillis() < timeout) {
                    port.flushIOBuffers();
                    if (port.bytesAwaitingWrite() == 0) {
                        success = true;
                        return true;  // All bytes have been transmitted
                    }
                    try {
                        Thread.sleep(1);  // Small delay to prevent busy-waiting
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        success  = false;
                        return false;
                    }
                }
                success = false;
                return false;  // Timeout occurred before all bytes were transmitted
            }
            success = true;
            return true;
        } else {
            success = false;    
            return false;
        }
    }
}