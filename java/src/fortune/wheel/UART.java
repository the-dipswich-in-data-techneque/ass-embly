package fortune.wheel;
import com.fazecast.jSerialComm.SerialPort;
import java.util.Scanner;



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
        System.out.println("Write what COM PORT to use with the index number at the start of the line");
        // Select a port (in this example, we'll use the first port)
        Scanner scanner = new Scanner(System.in);
        int port_index = Integer.parseInt(scanner.nextLine());
        scanner.close();

        // Open the port
            SerialPort port = ports[port_index];
            if (port.openPort()) {
                System.out.println("Successfully opened port: " + port.getSystemPortName());

                // Configure the port settings
                port.setComPortParameters(19200, 8, SerialPort.ONE_STOP_BIT, SerialPort.NO_PARITY);
                port.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 0, 0);

                // Send data
                String dataToSend = "Hello, Serial Port!";
                byte[] writeBuffer = dataToSend.getBytes();
                int code = port.writeBytes(writeBuffer, writeBuffer.length);
                System.out.println("Sent: " + dataToSend);
                System.out.println("code: " + code);
                // Read data
                byte[] readBuffer = new byte[1024];
                while(port.bytesAvailable() < 19){
                    try {
                        Thread.sleep(10);
                    } catch (InterruptedException ignore) {}
                }
                int numRead = port.readBytes(readBuffer, readBuffer.length);
                String receivedData = new String(readBuffer, 0, numRead);
                System.out.println("Received: " + receivedData);

                // Close the port
                port.closePort();
                System.out.println("Port closed");
            } else {
                System.out.println("Failed to open port: " + port.getSystemPortName());
            }
        
    }
}