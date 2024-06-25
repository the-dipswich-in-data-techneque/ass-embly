package fortune.wheel;
import com.fazecast.jSerialComm.SerialPort;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedList;
import java.util.Queue;

public class UART{

    private Queue<String> messageQueue = new LinkedList<>();

    private static SerialPort port;

    public static void setup() {
        SerialPort[] ports = SerialPort.getCommPorts();
        port.setComPortParameters(19200, 8, SerialPort.ONE_STOP_BIT, SerialPort.NO_PARITY);
        port.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 0, 0);

        port = ports[0];
        for (int i = 0; i < ports.length; i++) {
            if(ports[i].getSystemPortName().contains("USB to UART Bridge")){
                port = ports[i];
                break;
            }
        }
        port.openPort();
    }

    public void addToQueue(String message){
        messageQueue.offer(message);
    }

    public void UART_sender() {
        if (port.openPort()) {
            byte[] writeBuffer;
            String dataToSend;

            // Send data
            if(!messageQueue.isEmpty()){
                dataToSend = messageQueue.poll() + "\n";
                writeBuffer = dataToSend.getBytes();
                port.writeBytes(writeBuffer, writeBuffer.length);

            // Read data
            byte[] readBuffer = new byte[1024];
            while(port.bytesAvailable() < writeBuffer.length){
                try {
                    Thread.sleep(10);
                } catch (InterruptedException ignore) {}
            }
            int bytesRead = 0;
            StringBuilder receivedData = new StringBuilder();

            long timeout = System.currentTimeMillis() + 5000; // 5 seconds timeout

            try {
                while(System.currentTimeMillis() < timeout){
                    if(port.bytesAvailable() > 0){
                        bytesRead = port.readBytes(readBuffer, Math.min(port.bytesAvailable(), readBuffer.length));
                        receivedData.append(new String(readBuffer, 0, bytesRead));

                        // Check if we've received a complete message
                        if (receivedData.toString().contains("\n")) {
                            break;
                        }
                    }
                    Thread.sleep(10); // Small delay to prevent busy-waiting
                }
            } catch (Exception ignore) {}
        }
    }
    }

    public static short getShort(boolean locking){
        byte[] shortBuffer = new byte[2];
        long timeout = System.currentTimeMillis() + 100;
        while (locking && System.currentTimeMillis() < timeout) {
            int bytesRead = port.readBytes(shortBuffer, shortBuffer.length);

            if(bytesRead == 2){
                return ByteBuffer.wrap(shortBuffer).order(ByteOrder.BIG_ENDIAN).getShort();
            }
        }
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
                        return true;  // All bytes have been transmitted
                    }
                    try {
                        Thread.sleep(1);  // Small delay to prevent busy-waiting
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        return false;
                    }
                }
                return false;  // Timeout occurred before all bytes were transmitted
            }
            return true;
        } else {
            return false;
        }
    }
}