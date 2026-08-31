# An Arduino project

## How to install the AVR board core

Do this procedure one time:

1. Update the index of the boards:

   ```sh
   arduino-cli core update-index
   ```

2. Install the AVR core:

   ```sh
   arduino-cli core install arduino:avr
   ```

## How to compile the sketch

The `run` command compiles the sketch. The command uses the Fully Qualified Board
Name (FQBN) in the `ARDUINO_FQBN` variable. The `.envrc` file sets this variable.

## How to upload the sketch

To upload the sketch, run this command. Replace `<serial-port>` with the port of
the board.

```sh
arduino-cli compile --fqbn "$ARDUINO_FQBN" --upload --port <serial-port> sketch
```
