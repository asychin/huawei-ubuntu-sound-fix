# Huawei Matebook 14s / 16s Soundcard Fix for Ubuntu / Fedora / Arch

This project provides a solution to the audio output issue on Huawei Matebook 14s/16s laptops running Ubuntu, Fedora, or Arch Linux, specifically those with TigerLake architecture.

## Problem

The headphone and speaker channels are mixed up in the sound card driver. When headphones are connected, the system outputs sound from the speakers, and vice versa. This issue is known to occur on systems with TigerLake architecture.

## Solution

This project implements a daemon that monitors the headphone jack and automatically switches the audio output between the headphones and speakers using `hda-verb` commands. It also supports PulseAudio and PipeWire for audio output switching.

## Installation

1.  Download the script `huawei-soundcard-headphones-monitor.sh`, `install.sh`, `uninstall.sh` and `huawei-soundcard-headphones-monitor.service`.
2.  Run the `install.sh` script:

    ```bash
    bash install.sh
    ```

## Usage

The daemon can be controlled using the following systemctl commands:

```bash
systemctl status huawei-soundcard-headphones-monitor
systemctl restart huawei-soundcard-headphones-monitor
systemctl start huawei-soundcard-headphones-monitor
systemctl stop huawei-soundcard-headphones-monitor
```

## Dependencies

*   `hda-verb`
*   `systemctl`
*   `pacmd` (optional, for PulseAudio)
*   `pw-cli` (optional, for PipeWire)
*   `evtest`

## Supported Systems

This fix has been tested on:

*   Ubuntu 22.04
*   Fedora 39
*   Huawei MateBook 14s
*   Manjaro Linux

Here's the hardware configuration of a tested system:

```
CPU:
  Info: quad core model: 11th Gen Intel Core i7-11370H bits: 64 type: MT MCP
Graphics:
  Device-1: Intel TigerLake-LP GT2 [Iris Xe Graphics] driver: i915 v: kernel
Audio:
  Device-1: Intel Tiger Lake-LP Smart Sound Audio
    driver: sof-audio-pci-intel-tgl
Network:
  Device-1: Intel Wi-Fi 6 AX201 driver: iwlwifi
```

## Credits

This solution was originally created by [Smoren](https://github.com/Smoren/huawei-ubuntu-sound-fix).
