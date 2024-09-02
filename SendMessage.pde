import oscP5.*;
import netP5.*;

class SendMessage {
  OscP5 oscP5;
  NetAddress maxAddress;

  SendMessage(String ip, int port) {
    oscP5 = new OscP5(this, 12000);
    maxAddress = new NetAddress(ip, port);
  }
  
  void send(String messageAddress, int value){
    OscMessage msg = new OscMessage(messageAddress);
    msg.add(value);
    oscP5.send(msg, maxAddress);
  }
}
