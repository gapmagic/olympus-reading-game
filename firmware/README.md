# Olympus firmware for Xteink X4 Pro

Olympus is also available as a modified build of [CrossPoint Reader](https://github.com/crosspoint-reader/crosspoint-reader) 2.0.0 for the Xteink X4 Pro. It follows the device language: Tiếng Việt shows Olympus in Vietnamese, any other language shows English.

- **Download:** `crosspoint-2.0.0-olympus-x4pro.bin` and `LICENSE-firmware.txt` from the [Releases page](../../../releases/latest).
- **Install:** see [FLASHING_EN.md](FLASHING_EN.md) (English) or [FLASHING.md](FLASHING.md) (Tiếng Việt). Back up your SD card first.
- **Status:** builds and passes 908 automated tests. Not yet tried on many real devices.

## License

This folder and the firmware are **not** under the AGPL that covers the KOReader plugin. CrossPoint's original code is MIT, and the combined firmware executable is distributed under **GPLv3**. Full notices are in [LICENSE-firmware.txt](LICENSE-firmware.txt).

## Source

The modifications are in [crosspoint-2.0.0-olympus-full.patch](crosspoint-2.0.0-olympus-full.patch). To rebuild the same firmware:

```sh
git clone --recursive https://github.com/crosspoint-reader/crosspoint-reader.git
cd crosspoint-reader
git checkout 42d58daaabcf469a2e5e1ba871714fb9dcf51d29   # tag 2.0.0
git submodule update --init --recursive               # FreeInk SDK at 5e94fe7480f019c89fbf691aef87523eb1b46704
git apply /path/to/crosspoint-2.0.0-olympus-full.patch
pio run -e x4pro-gh_release
```
