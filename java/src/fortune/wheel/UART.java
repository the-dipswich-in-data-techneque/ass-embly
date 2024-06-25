package fortune.wheel;
import com.fazecast.jSerialComm.SerialPort;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
//import javax.swing.event.*;
//import java.awt.event.*;

public class UART {

    private static SerialPort port;

    public static void setup() {
        SerialPort[] ports = SerialPort.getCommPorts();
        port.setComPortParameters(19200, 8, SerialPort.ONE_STOP_BIT, SerialPort.NO_PARITY);
        port.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 0, 0);

        port = ports[0];
        for (int i = 0; i < ports.length; i++) {
            if(ports[i].getSystemPortName() == "CP2104 USB to UART Bridge Controller"){
                port = ports[i];
            }
        }
        port.openPort();
    }

//    public void UART_sender() {
//
//        if (port.openPort()) {
//            // Configure the port settings
//            
//
//            // Send data
//            String dataToSend = scanner.nextLine();
//            byte[] writeBuffer = dataToSend.getBytes();
//            port.writeBytes(writeBuffer, writeBuffer.length);
//            System.out.println("Sent: " + dataToSend);
//
//            // Read data
//            byte[] readBuffer = new byte[1024];
//            while(port.bytesAvailable() < writeBuffer.length){
//                try {
//                    Thread.sleep(10);
//                } catch (InterruptedException ignore) {}
//            }
//
//            int numRead = port.readBytes(readBuffer, readBuffer.length);
//            String receivedData = new String(readBuffer, 0, numRead);
//            System.out.println("Received: " + receivedData);
//            }
//
//
//        // Close the port
//        port.closePort();
//    }

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
        
        if(shorty.length == 2) return true;
        
        return false;
    }
    
}



//            panel.addMouseListener(new MouseAdapter() {
//                @Override
//                public void mouseClicked(MouseEvent e) {
//                    if (port.isOpen()) {
//                        String dataToSend = "Click at (" + e.getX() + ", " + e.getY() + ")";
//                        sendData(dataToSend);
//                    } else {
//                        System.out.println("Port is not open.");
//                    }
//                }
//            });