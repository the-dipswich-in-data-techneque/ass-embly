package fortune.wheel;
import com.fazecast.jSerialComm.SerialPort;
import java.util.Scanner;
//import javax.swing.event.*;
//import java.awt.event.*;

public class UART {
    
    public static void main(String[] args) {
        // Get the list of available serial ports
        SerialPort[] ports = SerialPort.getCommPorts();

        // Print the available ports
        System.out.println("Available ports:");
        for (int i = 0; i < ports.length; i++) {
            System.out.println(i + ": " + ports[i] + " " + ports[i].getSystemPortName());
        }

        System.out.println("Use CP2104 USB to UART Bridge Controller");
        System.out.println("Write what COM PORT to use with the index number at the start of the previous line");
        // Select a port (in this example, we'll use the first port)
        Scanner scanner = new Scanner(System.in);
        int port_index = Integer.parseInt(scanner.nextLine());
        

        // Open the port
        SerialPort port = ports[port_index];
        System.out.println("Successfully opened port: " + port.getSystemPortName());

        while (port.openPort()) {
            // Configure the port settings
            port.setComPortParameters(19200, 8, SerialPort.ONE_STOP_BIT, SerialPort.NO_PARITY);
            port.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 0, 0);

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

            // Send data
            String dataToSend = scanner.nextLine();
            byte[] writeBuffer = dataToSend.getBytes();
            port.writeBytes(writeBuffer, writeBuffer.length);
            System.out.println("Sent: " + dataToSend);

            // Read data
            byte[] readBuffer = new byte[1024];
            while(port.bytesAvailable() < writeBuffer.length){
                try {
                    Thread.sleep(10);
                } catch (InterruptedException ignore) {}
            }

            int numRead = port.readBytes(readBuffer, readBuffer.length);
            String receivedData = new String(readBuffer, 0, numRead);
            System.out.println("Received: " + receivedData);

            }

        scanner.close();

        // Close the port
        port.closePort();
        System.out.println("Port closed");
    }
    public static short getShort(boolean locking){
        return 0;
    }
    public static boolean sendShort(short value, boolean locking){
        return false;
    }
}