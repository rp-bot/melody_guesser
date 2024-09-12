import oscP5.*;
import netP5.*;

class SendMessage {
  OscP5 oscP5;
  NetAddress maxAddress;
  
  SendMessage(String ip, int sendPort, int receivePort) {
    oscP5 = new OscP5(this, receivePort);
    maxAddress = new NetAddress(ip, sendPort);
  }
  
  void send(String messageAddress, int value) {
    OscMessage msg = new OscMessage(messageAddress);
    msg.add(value);
    oscP5.send(msg, maxAddress);
  }
  
  void oscEvent(OscMessage theOscMessage) {
    // Check if the message is for this class
    if (theOscMessage.checkAddrPattern("/test")) {
      // Assuming the message from Max is an integer
      int receivedValue = theOscMessage.get(1).intValue();
      println("Received value from Max: " + receivedValue);
      // You can add custom handling here
      handleReceivedMessage(receivedValue);
    }
  }
  
  // Custom method to handle received messages
  void handleReceivedMessage(int value) {
    // Implement your custom logic here
    println("Handling received message with value: " + value);
  }
}
