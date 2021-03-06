//TODO: make note always on or completely off explicit
//TODO: fix arc not fitting into circle, off by 1 pix
//TODO: build note UI
//TODO: fix mismatched on/off midi note bug (this is a problem for garageband)
  // UNTESTED FIX

//TODO: channel knob
//TODO: channel drop down menu changes channel output

public class ATC{
  PApplet parent; // The PApplet that created the instance of ATC 
  GWindow win;    // The PApplet that ATC creates for itself
  int fps1; //36
 
  MidiBus bus;    // MidiBus instance (specified in constructor)
  private int channel;  // 1
  int nNotes;           // 8
  LoopingNote[] notes;  // Array of 8
  boolean isOn;         // Initially set to false
  String outputBuses[]; // Array of available output buses
  String currentOutput; // Initially outputBuses[0]
  
  
  
  GOption toggleOn, toggleSuspend, toggleOff;
  GToggleGroup onOffToggle; 
  
  GOption enabledOpts[];
  GToggleGroup enabledToggle;

  
  ATC(PApplet parent, MidiBus bus) {
    
    this.parent = parent; 
    this.channel = 1;
    this.bus = bus; 
    nNotes = 8; 
    notes = new LoopingNote[8]; 
    isOn = false; 
    refreshBusOutputs(); //set busNames array 
    currentOutput = outputBuses[0]; 
    bus.addOutput(currentOutput); 
    
    println(fps1);
   
    fps1 = 36;
    win = GWindow.getWindow(parent, "AirTrafficControl", 100, 100, 800, 600, JAVA2D); 
    //println("THE WINDOW FRAME RATE IS "+ win.frameRate);
    win.loop();
    win.frameRate(36);
    win.setActionOnClose(G4P.CLOSE_WINDOW);
    win.addData(new ATC_GWinData()); 
    ((ATC_GWinData)win.data).atc = this; //Attach instance of ATC to window data
    
    win.textFont(loadFont("Avenir-HeavyOblique-48.vlw"), 22);
    
    win.addDrawHandler(parent, "ATC_winDraw");
    textFont(loadFont("Avenir-HeavyOblique-48.vlw"), 22);
    
    
    int y0 = 265;
    int y1 = 475;
    notes[0] = new LoopingNote("F2 ", channel, 29, 100, y0, win);
    notes[1] = new LoopingNote("G#2", channel, 32, 300, y0, win);
    notes[2] = new LoopingNote("C3 ", channel, 36, 500, y0, win);
    notes[3] = new LoopingNote("C#3", channel, 37, 700, y0, win);
    notes[4] = new LoopingNote("D#3", channel, 39, 100, y1, win);
    notes[5] = new LoopingNote("F3 ", channel, 41, 300, y1, win);
    notes[6] = new LoopingNote("G#3", channel, 44, 500, y1, win);
    notes[7] = new LoopingNote("-- ", channel, 44, 700, y1, win);
    notes[7].disabled = true;
    
    onOffToggle = new GToggleGroup();
    toggleOn = new GOption(win, 60, 100, 80, 24, "ON");
    toggleOn.setLocalColor(2, color(150, 0, 0));
    toggleSuspend = new GOption(win, 60, 120, 80, 24, "SUSPEND");
    toggleSuspend.setLocalColor(2, color(150, 0, 0));
    toggleOff = new GOption(win, 60, 140, 80, 24, "OFF");
    toggleOff.setLocalColor(2, color(150, 0, 0));
    onOffToggle.addControls(toggleOn, toggleSuspend, toggleOff);
    
    //enabledToggle = new GToggleGroup();
    enabledOpts = new GOption[nNotes];
    
    
    //int xx = 550;
    //int yy = 100;
    //for(int i = 0; i<4; i++){
    //  enabledOpts[i] = new GOption(win, xx + i*20, yy, 10, 10);
    //  enabledOpts[i+4] = new GOption(win, xx + i*20, yy+20, 10, 10);
    //}
  }
  
  synchronized void draw(){
    win.background(0);

    win.stroke(150, 0, 0);
    win.fill(150, 0, 0);

    win.textSize(30);
    win.text("AirTrafficControl", 60, 80);
    win.text(fps1, 400, 80);
    win.text(win.frameRate, 400, 110);
    win.textSize(18);
  
    win.text("channel: "+notes[1].channel,180,120);
    
    ////UPDATE NOTES ONLY IF DEVICE IS ON
    if (isOn == true) {
      for (int i = 0; i < nNotes; i++) {
        notes[i].update();
        notes[i].draw();
      }
    } else { //ATC is off
      for (int i = 0; i < nNotes; i++) {
        notes[i].draw();
      }
    }    
  }
  
  private void refreshBusOutputs(){
    outputBuses = new String[16]; //set all values to NULL
    int n = MidiBus.availableInputs().length;
    if (n > 16) n = 16;
    System.arraycopy(MidiBus.availableInputs(), 0, outputBuses, 0, n);
  }
  
  public void setChannel(int c){
    if (c >= 16 || c < 0){
      return;
    }
    for(int i = 0; i < notes.length; i++){
       notes[i].channel = c;
    }
  }
}

/**
 * Handles drawing to the windows PApplet area
 * 
 * @param appc the PApplet object embeded into the frame
 * @param data the data for the GWindow being used
 */
 
synchronized public void ATC_winDraw(PApplet appc, GWinData data) {
  ATC_GWinData data1 = (ATC_GWinData)data;
  data1.atc.draw();
}
 
class ATC_GWinData extends GWinData {
  ATC atc;  
}






private class LoopingNote {
  GWindow win;
  String name;
  int channel, pitch, velocity;
  int x, y;

  boolean disabled;

  float toneOnRatio, period, diameter, angleDelta;

  float angle; //this is the relative angle
  //of the head from the start of the loop
  //in radians
  boolean isOn;
  
  GSlider2D slider;
  
  LoopingNote(String name, int channel, int pitch, int x, int y, PApplet win) {
    this.disabled = false;
    this.win = (GWindow)win;
    this.name  = name;
    this.channel = channel;
    this.pitch = pitch;
    this.velocity = 100;
    this.x = x;
    this.y = y;
    toneOnRatio = random(0.2, 0.35);
    period = ((int)random(150, 250))/10.0;
    //println("period "+period);
    angle = random(0.0, 2*PI);
    angleDelta = 2*PI/period/36.0;
    diameter = 144;

    isOn = false;
    
    slider = new GSlider2D(this.win, x-74, y-74, 148, 148);
    slider.setLimitsX(toneOnRatio, 0.0, 1.0);
    slider.setLimitsY(period, 0.01, 30.0);
    
    for (int i = 0; i < 16; i++) {
      slider.setLocalColor(i, color(255, 0));
    }
    
    slider.setLocalColor(6, color(255, 0));
    slider.setLocalColor(15, color(100, 150));
    slider.setEasing(30);
    
  }
  
  synchronized void update() {
    if (disabled) {return;}
    angleDelta = 2*PI/period/win.frameRate;
    //angle descends from 2*PI to 0
    angle -= angleDelta;//period/(2*PI);

    if (angle <= 0.0) { //Reset angle 2 * PI
      angle += 2*PI;
      if (isOn == false) { // Turn note on if it is off
        myBus.sendNoteOn(channel, pitch, velocity);
        isOn = true;
      }
      // If note should be off
    } else if (angle <= 2*PI - toneOnRatio * 2 * PI) {
      if(isOn){ // turn it off
        myBus.sendNoteOff(this.channel, this.pitch, this.velocity);
        isOn = false;
      }
      
    }
    else { // note should be on
      if(isOn == false){
        myBus.sendNoteOn(this.channel, this.pitch, this.velocity);
        isOn = true;
      }
    }
  }
   synchronized void draw() {
    if(disabled) return;
    win.noFill();

    win.fill(150, 0, 0);
    win.stroke(150, 0, 0);
    win.text(name+" "+"  "+nf(period, 2, 1)+"s  %"+nf(toneOnRatio*100, 2, 1), x - diameter/2, y + diameter/2 +24);
    win.noStroke();
    if (isOn) {
      win.fill(250, 0, 0);
      win.arc(x, y, diameter, diameter, angle + 3*PI/2, angle +2*PI*toneOnRatio + 3*PI/2);
      win.triangle(x, y-diameter/2, x-6, y-diameter/2-10, x+6, y-diameter/2-10);
      win.noFill();
      win.stroke(250, 0, 0);
      win.ellipse(x, y, diameter, diameter);
      //rect(x-diameter/2-1, y-diameter/2-1, diameter+2, diameter+2);
    } else {
      win.fill(120, 0, 0);
      win.triangle(x, y-diameter/2, x-6, y-diameter/2-10, x+6, y-diameter/2-10);
      win.arc(x, y, diameter, diameter, angle + 3*PI/2, angle +2*PI*toneOnRatio + 3*PI/2);      
      win.noFill();
      win.stroke(120, 0, 0);
      win.ellipse(x, y, diameter, diameter);
      //win.rect(x-diameter/2-1, y-diameter/2-1, diameter+2, diameter+2);
    }
  }
}