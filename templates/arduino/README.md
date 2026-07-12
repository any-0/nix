# Arduino project

Install the AVR board core once:

```sh
arduino-cli core update-index
arduino-cli core install arduino:avr
```

`run` compiles the sketch for the `ARDUINO_FQBN` configured in `.envrc`. Upload it with:

```sh
arduino-cli compile --fqbn "$ARDUINO_FQBN" --upload --port <serial-port> sketch
```
