# Wrapper for Monero

This project wraps Monero for EmbassyOS.  Monero is a private, secure, untraceable, decentralised digital currency. You are your bank, you control your funds, and nobody can trace your transfers unless you allow them to do so.

## Dependencies

- [docker](https://docs.docker.com/get-docker)
- [docker-buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [make](https://www.gnu.org/software/make/)

## Build enviroment
Prepare your EmbassyOS build enviroment. In this example we are using a Debian machine.


Now you are ready to build your first EmbassyOS service

## Cloning

Clone the project locally. Note the submodule link to the original project(s).

```
git clone https://github.com/kn0wmad/monerod-wrapper.git
cd monerod-wrapper
```

## Building

To build the project, run the following commands:

```
make
```

## Installing (on Embassy)
