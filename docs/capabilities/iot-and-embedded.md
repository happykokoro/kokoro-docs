---
description: Firmware, sensor systems, and edge compute for connected hardware. Microcontrollers, sensor fusion, telemetry pipelines, hardware-software co-design.
---

# IoT & embedded systems

Firmware, sensor systems, and edge compute for connected hardware — from microcontroller-class devices to gateway-class appliances. Hardware and software designed together as a single system, integrated from first principles.

## What we provide

- **Embedded firmware development.** Bare-metal and RTOS firmware in C, C++, and Rust. Targets include the ARM Cortex-M family (STM32, NXP LPC, Nordic nRF), Espressif ESP32 family (including ESP32-S3 / -C6), and SBC-class platforms (Raspberry Pi, NXP i.MX, Rockchip). Static analysis, MISRA-aligned style, and reproducible builds standard.
- **Sensor integration and fusion.** GNSS receivers (GPS, GLONASS, Galileo, BeiDou) including RTK and PPK workflows; IMUs (accelerometer, gyro, magnetometer) with Kalman / extended-Kalman fusion against GNSS for dead-reckoning continuity; environmental sensors (temperature, humidity, pressure, gas); ToF and LIDAR for ranging.
- **Radar and signal processing.** FMCW radar pipelines for target detection, tracking, and classification; range-Doppler processing; multi-sensor fusion across radar, GNSS, and inertial inputs.
- **Wireless connectivity.** BLE 5.x (peripheral, central, mesh), Wi-Fi (4/5/6, station and SoftAP), LoRa / LoRaWAN, cellular IoT (LTE-M, NB-IoT). Provisioning flows that survive contact with end users.
- **Telemetry and command pipelines.** Device-to-cloud telemetry with at-least-once delivery, store-and-forward against intermittent connectivity, signed firmware updates over the air. Backends consume into the same observability and alerting stack documented under [infrastructure & monitoring](infrastructure-and-monitoring.md).
- **Hardware-software co-design.** PCB-level review, BOM optimization, power-budget analysis, thermal-envelope sizing.

## Delivery models

- **Custom firmware against client hardware.** Firmware development against a customer's existing hardware platform or reference design.
- **Reference firmware and BSP.** Buildable firmware for a customer's chosen module or SoM, with documented board support package and porting guide for adjacent SKUs.
- **Hardware-software bring-up.** Full bring-up of new hardware — bootloader, peripheral drivers, sensor calibration, RF tuning, certification preparation.
- **Telemetry backend.** End-to-end telemetry pipeline from device firmware through ingestion, storage, and dashboards. Pairs with our payments and identity stacks if the device fleet is monetized.
- **Long-term firmware maintenance.** Quarterly OTA cadence, security-patch response, OS / SDK upgrade tracking, and end-of-life planning under retainer.

## Engagement

Hardware engagements assume a defined target SKU before firmware work begins. Pilots typically run on reference modules, with custom PCB or enclosure work scoped after the firmware is stable. Certification (FCC, CE, RED, RoHS) preparation is included in scoping when the customer is shipping at volume.
