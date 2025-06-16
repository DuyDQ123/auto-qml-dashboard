# Car Dashboard Control System

A comprehensive car dashboard system with a modern UI interface connected to an ESP32 microcontroller for real-time data processing and control.

![Qt](https://img.shields.io/badge/Qt-%23217346.svg?style=for-the-badge&logo=Qt&logoColor=white)
![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white)
![Arduino](https://img.shields.io/badge/Arduino-00979D?style=for-the-badge&logo=Arduino&logoColor=white)

## Table of Contents
- [System Overview](#system-overview)
- [Features](#features)
- [Requirements](#requirements)
  - [Hardware Requirements](#hardware-requirements)
  - [Software Requirements](#software-requirements)
- [Setup Instructions](#setup-instructions)
  - [Dashboard Application Setup](#dashboard-application-setup)
  - [ESP32 Setup](#esp32-setup)
- [Hardware Connections](#hardware-connections)
- [Usage Instructions](#usage-instructions)
- [Control Methods](#control-methods)
- [System Architecture](#system-architecture)
- [PCB Design](#pcb-design)
- [Contributors](#contributors)

## System Overview
The system consists of three main components:

1. **QML-based Dashboard Application**: A modern, interactive dashboard UI built with Qt/QML
2. **ESP32 Controller**: Firmware that handles sensor inputs, button controls, and communicates with the dashboard
3. **PCB Design**: Custom hardware design for connecting components

## Features

### Interactive Dashboard UI
- Digital speedometer with analog gauge visualization
- Fuel level indicator with refueling options
- Engine type selection (P/E/D modes)
- Driving mode selection (A/S/W modes)
- Vehicle status indicators (headlights, fog lights, etc.)
- Start/Stop control

### ESP32 Controller
- Real-time speed control via potentiometer
- Button controls for changing vehicle modes
- LED status indicators
- Temperature and humidity monitoring
- EEPROM-based state persistence
- FreeRTOS multitasking

### Serial Communication
- Bidirectional communication between dashboard and ESP32
- Real-time data updates

## Requirements

### Hardware Requirements
- ESP32 development board
- Potentiometer for speed control
- DHT11 temperature/humidity sensor
- Push buttons (x6)
- LEDs (x6)
- SSD1306 OLED display
- Connecting wires

### Software Requirements
- Qt 5.15+ with QtQuick and QtSerialPort
- Arduino IDE or PlatformIO for ESP32 programming

## Setup Instructions

### Dashboard Application Setup
1. Clone this repository
   ```bash
   git clone https://github.com/DuyDQ123/car-dashboard-system.git
   cd car-dashboard-system
   ```
2. Open the ProjectFinal.pro file with Qt Creator
3. Configure build settings for your platform
4. Build and run the application

### ESP32 Setup
1. Open Arduino IDE or PlatformIO
2. Open the PF_ESP32.ino file
3. Install required libraries:
   ```bash
   # For Arduino IDE, use Library Manager to install:
   # - DHT sensor library
   # - Adafruit GFX library
   # - Adafruit SSD1306 library
   # - Wire library
   
   # For PlatformIO, add these to platformio.ini:
   lib_deps =
     adafruit/DHT sensor library
     adafruit/Adafruit GFX Library
     adafruit/Adafruit SSD1306
     Wire
   ```
4. Select your ESP32 board from the boards menu
5. Upload the code to your ESP32

## Hardware Connections

Connect the ESP32 according to these pin assignments:

### Inputs

| Component | ESP32 Pin |
|-----------|-----------|
| Potentiometer | Pin 34 |
| Engine Mode Button | Pin 27 |
| Drive Mode Button | Pin 26 |
| Fuel 33% Button | Pin 25 |
| Fuel 66% Button | Pin 33 |
| Fuel 100% Button | Pin 32 |
| Start/Stop Button | Pin 15 |

### Outputs

| Component | ESP32 Pin |
|-----------|-----------|
| P Mode LED | Pin 13 |
| A Mode LED | Pin 14 |
| Fuel 33% LED | Pin 12 |
| Fuel 66% LED | Pin 23 |
| Fuel 100% LED | Pin 19 |
| Start/Stop LED | Pin 18 |

### I2C Display

| Connection | ESP32 Pin |
|-----------|-----------|
| SDA | Pin 22 |
| SCL | Pin 21 |

## Usage Instructions

1. Start the QML Dashboard application
2. Connect to the ESP32 using the serial port dropdown
3. Click "Connect" to establish communication
4. Use the dashboard controls or physical buttons to interact with the system

## Control Methods

### Keyboard Controls (Dashboard App)
- **Space**: Accelerate main speedometer
- **Left/Right Arrow**: Control side gauges
- Click buttons to toggle status indicators

### Physical Controls (ESP32)
- Press engine mode button to cycle between P, E, and D modes
- Press drive mode button to cycle between A, S, and W modes
- Press fuel buttons to set fuel level (when stopped)
- Press Start/Stop button to toggle vehicle running state
- Turn potentiometer to control vehicle speed (when started)

## System Architecture

The system follows a client-server architecture:

- **ESP32 (Server)**: Handles physical inputs/outputs and sends data to the dashboard
- **QML Dashboard (Client)**: Visualizes data and sends commands to ESP32

Communication protocol uses simple text commands through serial connection.

## PCB Design

PCB design files are available in the DesignPCB folder, including:
- Schematic diagram
- PCB layout
- 3D visualization

## Contributors

This project was developed by Team 3 as part of the VKU 2025 class.