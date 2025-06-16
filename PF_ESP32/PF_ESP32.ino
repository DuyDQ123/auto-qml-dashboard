#include <Arduino.h>
#include <EEPROM.h>
#include <DHT.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>
#include <freertos/semphr.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define DHTPIN 4
#define DHTTYPE DHT11

// Hardware initialization
DHT dht(DHTPIN, DHTTYPE);
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// Input pins
const int POT_PIN = 34;          // BIENTRO1
const int ENGINE_MODE_PIN = 27;   // DONGCO_SW-PB
const int DRIVE_MODE_PIN = 26;    // CHEDO_SW-PB
const int FUEL_33_PIN = 25;       // 33%_SW-PB
const int FUEL_66_PIN = 33;       // 66%_SW-PB
const int FUEL_100_PIN = 32;      // 100%_SW-PB
const int START_STOP_PIN = 15;    // START/STOP_SW-PB

// Output LED pins
const int PMODE_LED = 13;         // LED1 for engine mode
const int AMODE_LED = 14;         // LED2 for drive mode
const int FUEL_33_LED = 12;       // LED3 for 33% fuel
const int FUEL_66_LED = 23;       // LED4 for 66% fuel
const int FUEL_100_LED = 19;      // LED5 for 100% fuel
const int START_STOP_LED = 18;    // LED6 for start/stop

// EEPROM addresses
const int PMODE_ADDR = 0;   // Engine mode state (1 byte)
const int AMODE_ADDR = 1;   // Drive mode state (1 byte)
const int FUEL_ADDR = 2;    // Fuel level (1 byte)

// Shared state (protected by mutex)
struct CarState {
    int pModeIndex = 0;  // 0=P, 1=E, 2=D
    int aModeIndex = 0;  // 0=A, 1=S, 2=W
    int fuelLevel = 100;
    bool isStarted = false;
    int currentSpeed = 0;
    float temperature = 0;
    float humidity = 0;
} carState;

// FreeRTOS resources
SemaphoreHandle_t stateMutex;
SemaphoreHandle_t displayMutex;
SemaphoreHandle_t eepromMutex;

// Function prototypes
void saveState();
void loadState();
void updateLEDs();
void updateOLED();

// Task to handle button inputs
void buttonTask(void *parameter) {
    // Button states
    int lastEngineState = HIGH;
    int lastDriveState = HIGH;
    int lastFuel33State = HIGH;
    int lastFuel66State = HIGH;
    int lastFuel100State = HIGH;
    int lastStartStopState = HIGH;

    while(1) {
        // Read current button states
        int engineState = digitalRead(ENGINE_MODE_PIN);
        int driveState = digitalRead(DRIVE_MODE_PIN);
        int fuel33State = digitalRead(FUEL_33_PIN);
        int fuel66State = digitalRead(FUEL_66_PIN);
        int fuel100State = digitalRead(FUEL_100_PIN);
        int startStopState = digitalRead(START_STOP_PIN);

        if (xSemaphoreTake(stateMutex, portMAX_DELAY)) {
            // Check engine mode button (pMode)
            if (engineState == LOW && lastEngineState == HIGH) {
                carState.pModeIndex = (carState.pModeIndex + 1) % 3;
                Serial.println("p");
                xSemaphoreTake(eepromMutex, portMAX_DELAY);
                saveState();
                xSemaphoreGive(eepromMutex);
            }

            // Check drive mode button (aMode)
            if (driveState == LOW && lastDriveState == HIGH) {
                carState.aModeIndex = (carState.aModeIndex + 1) % 3;
                Serial.println("a");
                xSemaphoreTake(eepromMutex, portMAX_DELAY);
                saveState();
                xSemaphoreGive(eepromMutex);
            }

            // Check fuel buttons
            if (fuel33State == LOW && lastFuel33State == HIGH) {
                carState.fuelLevel = 33;
                Serial.println("1");
                xSemaphoreTake(eepromMutex, portMAX_DELAY);
                saveState();
                xSemaphoreGive(eepromMutex);
            }
            if (fuel66State == LOW && lastFuel66State == HIGH) {
                carState.fuelLevel = 66;
                Serial.println("2");
                xSemaphoreTake(eepromMutex, portMAX_DELAY);
                saveState();
                xSemaphoreGive(eepromMutex);
            }
            if (fuel100State == LOW && lastFuel100State == HIGH) {
                carState.fuelLevel = 100;
                Serial.println("3");
                xSemaphoreTake(eepromMutex, portMAX_DELAY);
                saveState();
                xSemaphoreGive(eepromMutex);
            }

            // Check start/stop button
            if (startStopState == LOW && lastStartStopState == HIGH) {
                carState.isStarted = !carState.isStarted;
                Serial.println("s");
            }

            xSemaphoreGive(stateMutex);
        }

        // Update button states
        lastEngineState = engineState;
        lastDriveState = driveState;
        lastFuel33State = fuel33State;
        lastFuel66State = fuel66State;
        lastFuel100State = fuel100State;
        lastStartStopState = startStopState;

        vTaskDelay(pdMS_TO_TICKS(50)); // Debounce delay
    }
}

// Task to handle sensor readings
void sensorTask(void *parameter) {
    while(1) {
        if (xSemaphoreTake(stateMutex, portMAX_DELAY)) {
            // Read speed from potentiometer if car is started
            if (carState.isStarted) {
                int potValue = analogRead(POT_PIN);
                carState.currentSpeed = map(potValue, 0, 4095, 0, 250);
                Serial.print("v");
                Serial.println(carState.currentSpeed);
            }

            // Read DHT11 sensor
            float newHumidity = dht.readHumidity();
            float newTemperature = dht.readTemperature();

            if (!isnan(newHumidity) && !isnan(newTemperature)) {
                carState.humidity = newHumidity;
                carState.temperature = newTemperature;
                Serial.print("h");
                Serial.println(newHumidity);
                Serial.print("t");
                Serial.println(newTemperature);
            }

            xSemaphoreGive(stateMutex);
        }

        vTaskDelay(pdMS_TO_TICKS(100)); // Sensor reading interval
    }
}

// Task to update display
void displayTask(void *parameter) {
    while(1) {
        if (xSemaphoreTake(stateMutex, portMAX_DELAY)) {
            if (xSemaphoreTake(displayMutex, portMAX_DELAY)) {
                // Update OLED display
                updateOLED();
                // Update LEDs
                updateLEDs();
                xSemaphoreGive(displayMutex);
            }
            xSemaphoreGive(stateMutex);
        }
        vTaskDelay(pdMS_TO_TICKS(50)); // Display update interval
    }
}

void updateLEDs() {
    // Update mode LEDs
    digitalWrite(PMODE_LED, carState.pModeIndex > 0);
    digitalWrite(AMODE_LED, carState.aModeIndex > 0);
    
    // Update fuel LEDs
    digitalWrite(FUEL_33_LED, carState.fuelLevel >= 33);
    digitalWrite(FUEL_66_LED, carState.fuelLevel >= 66);
    digitalWrite(FUEL_100_LED, carState.fuelLevel == 100);
    
    // Update start/stop LED
    digitalWrite(START_STOP_LED, carState.isStarted);
}

void updateOLED() {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(WHITE);
    
    // Display fuel level
    display.setCursor(0,0);
    display.print("Fuel: ");
    display.print(carState.fuelLevel);
    display.print("%");
    
    // Display speed
    display.setCursor(0,16);
    display.print("Speed: ");
    display.print(carState.currentSpeed);
    display.print(" km/h");
    
    // Display modes
    display.setCursor(0,32);
    display.print("PMode: ");
    display.print(carState.pModeIndex == 0 ? "P" : (carState.pModeIndex == 1 ? "E" : "D"));
    
    display.setCursor(0,48);
    display.print("AMode: ");
    display.print(carState.aModeIndex == 0 ? "A" : (carState.aModeIndex == 1 ? "S" : "W"));
    
    display.display();
}

void saveState() {
    EEPROM.write(PMODE_ADDR, carState.pModeIndex);
    EEPROM.write(AMODE_ADDR, carState.aModeIndex);
    EEPROM.write(FUEL_ADDR, carState.fuelLevel);
    EEPROM.commit();
}

void loadState() {
    if (xSemaphoreTake(stateMutex, portMAX_DELAY)) {
        carState.pModeIndex = EEPROM.read(PMODE_ADDR);
        carState.aModeIndex = EEPROM.read(AMODE_ADDR);
        carState.fuelLevel = EEPROM.read(FUEL_ADDR);
        
        // Validate loaded values
        carState.pModeIndex = constrain(carState.pModeIndex, 0, 2);
        carState.aModeIndex = constrain(carState.aModeIndex, 0, 2);
        carState.fuelLevel = constrain(carState.fuelLevel, 0, 100);
        
        xSemaphoreGive(stateMutex);
    }
}

void setup() {
    Serial.begin(115200);
    EEPROM.begin(512);

    // Initialize DHT11
    dht.begin();

    // Initialize OLED
    Wire.begin(22, 21); // SDA, SCL
    if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("SSD1306 allocation failed");
        for(;;);
    }
    display.display();
    delay(2000);

    // Configure input pins
    pinMode(ENGINE_MODE_PIN, INPUT_PULLUP);
    pinMode(DRIVE_MODE_PIN, INPUT_PULLUP);
    pinMode(FUEL_33_PIN, INPUT_PULLUP);
    pinMode(FUEL_66_PIN, INPUT_PULLUP);
    pinMode(FUEL_100_PIN, INPUT_PULLUP);
    pinMode(START_STOP_PIN, INPUT_PULLUP);

    // Configure output pins
    pinMode(PMODE_LED, OUTPUT);
    pinMode(AMODE_LED, OUTPUT);
    pinMode(FUEL_33_LED, OUTPUT);
    pinMode(FUEL_66_LED, OUTPUT);
    pinMode(FUEL_100_LED, OUTPUT);
    pinMode(START_STOP_LED, OUTPUT);

    // Create FreeRTOS synchronization objects
    stateMutex = xSemaphoreCreateMutex();
    displayMutex = xSemaphoreCreateMutex();
    eepromMutex = xSemaphoreCreateMutex();

    // Load saved state
    xSemaphoreTake(eepromMutex, portMAX_DELAY);
    loadState();
    xSemaphoreGive(eepromMutex);

    // Create FreeRTOS tasks
    xTaskCreate(
        buttonTask,    // Task function
        "ButtonTask",  // Task name
        4096,         // Stack size
        NULL,         // Parameters
        3,            // Priority (3 = highest)
        NULL          // Task handle
    );

    xTaskCreate(
        sensorTask,
        "SensorTask",
        4096,
        NULL,
        2,            // Medium priority
        NULL
    );

    xTaskCreate(
        displayTask,
        "DisplayTask",
        4096,
        NULL,
        1,            // Lowest priority
        NULL
    );
}

void loop() {
    // Empty loop - everything is handled by FreeRTOS tasks
    vTaskDelete(NULL);
}