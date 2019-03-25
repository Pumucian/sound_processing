import ddf.minim.*;
import ddf.minim.effects.*;
import ddf.minim.ugens.*;
import ddf.minim.analysis.*;

PImage img;

Minim minim;

//Hacer combinación de pedales como si fuera un número binario
boolean [] activeButton;
final int buttonY = 145, buttonDiameter = 20, maxSamples = 3;
final int [] buttonX = {150, 250, 350};
final String[] samples = {"sample1.wav", "sample2.wav", "sample3.wav"};
int effect, sample;
String playingSample;

//Entrada
AudioInput IN;
//Grabación
AudioRecorder recorder;
boolean recorded;
//Reproducción
AudioOutput OUT;
FilePlayer player;

//Filtros
Flanger flanger, chorus;
Delay delay;

void setup() {
  size(500, 200);
  background(255);
  textAlign(CENTER);
  textSize(14);
  
  effect = 0;
  
  playingSample = "";
    
  activeButton = new boolean[3];
  for (boolean b : activeButton) b = false;
  
  minim = new Minim(this); 
  
  img = loadImage("table.jpg");
  img.resize(width, height);
  
  flanger = new Flanger(.5, .4, .5, .5, .3, .7);
  delay = new Delay(.3, .3, true, true);
  chorus = new Flanger(2, .4, 4, 0, .5, .5);
  
  // Línea estéreo de entrada, 44100 Hz 16 bits
  IN = minim.getLineIn(Minim.MONO, 2048);
  
  // Define el nombre del archivo a salvar
  recorder = minim.createRecorder(IN, "sonido.wav");
  
  // Canal de salida para la reproducción
  OUT = minim.getLineOut( Minim.MONO );
}

void showWaves(){  
  background(0);
  stroke(255);
  if (recorder.isRecording()) text("Press R to stop recording", 250, 15);
  else {
    text("Press R to start recording", 250, 15);
    text("Press S to play a sample", 250, 30);
  }
  // Dibuja ondas
  // Valores entre -1 y 1, se escalan y desplazan
  for(int i = 0; i < IN.left.size()-1; i++)
    {
      line(i, height/2 + IN.left.get(i)*height/2, i+1, height/2 + IN.left.get(i+1)*height/2);
      line(i, 3*height/2 + IN.right.get(i)*height/2, i+1, 3*height/2 + IN.right.get(i+1)*height/2);
    }
}

void chorusPedal(){
  fill(100, 210, 100);
  rect(105, 30, 90, 140);
  fill(192, 192, 192);
  circle(buttonX[0], buttonY, buttonDiameter);
  fill(0);
  text("CHORUS", 150, 70);
  if (activeButton[0]) fill(255, 0, 0);
  circle(150, 45, 8);  
}

void delayPedal(){
  fill(60, 60, 190);
  rect(205, 30, 90, 140);
  fill(192, 192, 192);
  circle(buttonX[1], buttonY, buttonDiameter);
  fill(0);
  text("DELAY", 250, 70);
  if (activeButton[1]) fill(255, 0, 0);
  circle(250, 45, 8);
}

void flangerPedal(){
  fill(150, 40, 150);
  rect(305, 30, 90, 140);
  fill(192, 192, 192);
  circle(buttonX[2], buttonY, buttonDiameter);
  fill(0);
  text("FLANGER", 350, 70);
  if (activeButton[2]) fill(255, 0, 0);
  circle(350, 45, 8);
}

void showEffects(){
  background(img);
  stroke(0);
  fill(0);
  textSize(11);
  text(playingSample, width/2, 10);
  textSize(18);
  chorusPedal();
  delayPedal();
  flangerPedal();
}

void recorder(){
  if ( recorder.isRecording() ){
    recorder.endRecord();
    recorded=true;
    //Salva y reproduce
    recorder.save();
    if ( player != null )
    {
        player.unpatch( OUT );
        player.close();
    }
    player = new FilePlayer( recorder.save() );   
    
    //Asocia filtro por defecto
    player.patch(OUT);      
         
    //En bucle
    player.loop();
  }
  else {
    recorder.beginRecord();
  }
}

void playFirstSample(){
  sample = 0;
  recorded = true;
  player = new FilePlayer(minim.loadFileStream(samples[0]));
  playingSample = "Playing " + samples[0] + ".\nPress S to change sample.";
  player.patch(OUT);
  player.loop();
}

void changeSample(){
  turnOffButtons(-1);
  removeEffect();
  applyEffect();
  sample++;
  if (sample == maxSamples) sample = 0;
  player.pause();
  player.close();
  player = new FilePlayer(minim.loadFileStream(samples[sample]));
  playingSample = "Playing " + samples[sample] + ".\nPress S to change sample.";
  player.patch(OUT);
  player.loop();
}

void keyReleased()
{
  if ( key == 'r' && !recorded ) recorder();
  else if (key == 's'){
    if (!recorded) playFirstSample();
    else changeSample();
  } 
}

void applyEffect(){
  effect = 0;
  for (int i = 0; i < activeButton.length; i++){
    if (activeButton[i]) {
      effect = i+1; 
      break;
    }
  }
  switch (effect){
    case 0:
      player.patch(OUT);
      break;
    case 1:
      player.patch(chorus).patch(OUT);
      break;
    case 2:
      player.patch(delay).patch(OUT);
      break;
    case 3:
      player.patch(flanger).patch(OUT);
  }
}

void removeEffect(){
  switch (effect){
    case 0:
      player.unpatch(OUT);
      break;
    case 1:
      player.unpatch(chorus);
      break;
    case 2:
      player.unpatch(delay);
      break;
    case 3:
      player.unpatch(flanger);
  }
}

void turnOffButtons(int index){
  for (int i = 0; i < buttonX.length; i++){
    if (i != index) activeButton[i] = false;
  }
}

void mouseClicked(){
  float offsetY = pow((mouseY - buttonY), 2);
  for (int i = 0; i < buttonX.length; i++){
    float offsetX = pow((mouseX - buttonX[i]), 2);
    if (sqrt(offsetX + offsetY) < buttonDiameter/2) {
      activeButton[i] = !activeButton[i];
      turnOffButtons(i);
      removeEffect();
      applyEffect();
      break;
    }
  }
}

void draw() {
  if (!recorded) showWaves();
  else showEffects();
}



void stop()
{
  //Cerrar Minim antes de finalizar
   IN.close();
  if ( player != null )
  {
    player.close();
  }
  minim.stop();
  
  super.stop();
}
