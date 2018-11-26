// #define __DEBUG__

const int N_PLEX_OUTPUTS = 1;
const int PLEX_PINS[N_PLEX_OUTPUTS] = { A0 };
const int PLEX_SYNC_PULSE_LENGTH_MS = 100;
int PLEX_TIMES[N_PLEX_OUTPUTS] = { PLEX_SYNC_PULSE_LENGTH_MS };
bool PLEX_STATE_CHANGED[N_PLEX_OUTPUTS] = { false };

const int BAUD_RATE = 9600;

const char TERMINATOR = '\n';
char BUFFER[32];

unsigned long millis_last_frame;
unsigned long millis_this_frame;

void setup_outputs();
void handle_serial_comm();
void handle_plex_sync();

void setup() {
  while ( !Serial ) {
    //  wait
  }
  
  Serial.begin(BAUD_RATE);
  
  Serial.println("*");
  
  setup_outputs();
}

void loop() {
  millis_this_frame = millis();

  handle_serial_comm();
  handle_plex_sync();

  millis_last_frame = millis_this_frame;  
}

void handle_serial_comm() {
  if (Serial.available() == 0) {
    return;
  }

  int n_read = Serial.readBytesUntil(TERMINATOR, BUFFER, sizeof(BUFFER)-1);

  if (n_read == 0) {
    Serial.println("!");
    return;
  }

  BUFFER[n_read] = '\0';

  int plex_pin_idx = atoi(BUFFER);

  if (plex_pin_idx < 0 || plex_pin_idx >= N_PLEX_OUTPUTS) {
    Serial.println("!");
    return;
  }

  #ifdef __DEBUG__
  Serial.println(plex_pin_idx);
  #endif

  PLEX_STATE_CHANGED[plex_pin_idx] = true;
  PLEX_TIMES[plex_pin_idx] = PLEX_SYNC_PULSE_LENGTH_MS;  
}

void handle_plex_sync() {
  unsigned long delta = millis_this_frame - millis_last_frame;
  for ( int i = 0; i < N_PLEX_OUTPUTS; i++ ) {
    if ( PLEX_TIMES[i] == 0 ) continue;
    PLEX_TIMES[i] -= delta;
    if ( PLEX_TIMES[i] <= 0 ) {
      PLEX_STATE_CHANGED[i] = true;
      PLEX_TIMES[i] = 0;
    }
    if (!PLEX_STATE_CHANGED[i]) continue;
    if ( PLEX_TIMES[i] == 0 ) {
      digitalWrite( PLEX_PINS[i], LOW );
    } else {
      digitalWrite( PLEX_PINS[i], HIGH );
    }
    PLEX_STATE_CHANGED[i] = false;
  }
}

void setup_outputs() {
  for (int i = 0; i < N_PLEX_OUTPUTS; i++) {
    pinMode(PLEX_PINS[i], OUTPUT);
  }
}

