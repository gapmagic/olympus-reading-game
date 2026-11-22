# Olympus firmware for Xteink X4 Pro

File: `crosspoint-2.0.0-olympus-x4pro.bin`
SHA-256: `264f0ff089ed31a1f7896e6569e104383ee7fe19ffdce7693857781e1a5c1400`

This is official CrossPoint 2.0.0, plus reading-progress % in the Library, plus the Olympus reading game.

**One file, two languages.** Olympus follows the language chosen in **Settings → Language**. With Vietnamese (Tiếng Việt) selected, Olympus is in Vietnamese. With any other language selected, Olympus is in English, including all 90 character profiles. Character names stay the same in both.

> **Important:** this build has only been compiled and run through the test suite on a computer (908/908 tests pass). It has **not been tried on a real X4 Pro yet**. Back up first and read "Going back to the old firmware" below.

## What's new

- **Home screen** gets an **Olympus** entry (just below the Library), for example `Olympus · 2 eggs · 12/90`. A `•` at the end means a new character is waiting to be seen.
- **Library → Recent tab → hold OK on a book → "Put in incubator"**. A book being incubated shows `Incubating N%` instead of its reading %.
- **Olympus sleep screen** turns on by itself when you place your first egg in the incubator. To turn it on right after installing: **Settings → Display → Sleep Screen → "Olympus"**. In Olympus, open the profile of a hatched character and tap **"Set as sleep screen"** (or press OK): that character becomes your companion on the sleep screen.
- **Touch:** tap the Incubator, the Temple, an egg or a character to open it. Tap an empty incubator slot to go to the Library and pick a book. Long-press an incubator slot to discard its egg. In the Temple, swipe up/down to turn pages and tap the Clay/Silver/Gold tabs to switch tier. In a profile, swipe left/right for the next character. Swipe from the left edge to go back; the round button goes Home. Incubator, Temple and profiles have a **Back** button at the bottom centre (next to the action button when there is one). Back from a profile always returns to the Temple.
- **Comics (XTC) without a table of contents:** press OK or tap to open the menu, and a % slider lets you jump to any page.
- Everything else is unchanged, including reading-progress %.

## How to play (short version)

**Stage 1: collect 90 characters**
- The incubator has 3 slots. Put a book in an empty slot (pages you already read count toward the egg). The egg is Clay (up to 200 pages), Silver (201–499) or Gold (500+).
- The egg's % follows your reading position: jump ahead and the egg follows, jump back and it goes back too. At 95% of the book the egg hatches right away while you read (no need to page through notes or credits at the end). Press Back to return to the book.
- An egg not read for 7 days goes cold. You can discard an egg at any time (hold OK or long-press its slot in the Incubator); its character is kept for the next egg.
- The Temple shows 3 tiers × 30 characters (tap a tab or hold Left/Right to switch tier).

**Companion** (available as soon as your first character hatches)
- The character set as the sleep screen is your companion: open its profile and tap "Set as sleep screen" (or press OK). Only books of the same length range as the character's tier count.
- Once you have all 90/90, the incubator closes and you only look after your companion.
- Daily goal: 5 / 10 / 20 pages by tier. A creature is fed for the day once you read 5 pages.
- A Clay creature leaves after 3 days without reading; Silver and Gold torches burn down to embers.

## Data on the SD card

- All Olympus data lives in `/.crosspoint/olympus/` (`state.bin` and the `pages/` folder).
- It does not touch existing reading-position files, progress files or settings. To start over, delete `/.crosspoint/olympus/`.
- Character art is built into the firmware; nothing needs to be copied to the card.

## Before flashing

1. Copy the `.crosspoint` folder on the SD card to your computer as a backup.
2. Charge the battery above 50%.
3. Keep the old firmware file ready to go back: `crosspoint-2.0.0-reading-progress-x4pro.bin`, or official CrossPoint 2.0.0.
4. (Optional) In the web flasher, choose **Full flash controls → Save full flash** to back up the whole device (about 25 minutes).

## Flash from the SD card (recommended)

1. Copy `crosspoint-2.0.0-olympus-x4pro.bin` to the root of the SD card and put the card back in.
2. On the device: **Settings → System → SD Card Firmware Update**.
3. Pick the `.bin` file. The device checks the file before writing and refuses it if it is not for the X4 Pro.
4. Wait for it to finish writing and restart. Do not power off while it writes.

## Flash over USB (alternative)

1. Connect the X4 Pro to your computer with the pogo-pin USB adapter and wake it to the home screen.
2. Open https://crosspointreader.com/#flash-tools in Chrome or Edge.
3. Choose **Xteink X4Pro → Custom .bin** and select `crosspoint-2.0.0-olympus-x4pro.bin`.
4. Click Flash and pick the device in the serial-port list.
5. When done, click **Reset**, then hold **Power** for 3–5 seconds to turn it on.

## Check after flashing

1. The home screen has an Olympus entry; opening it shows the Incubator and the Temple.
2. The Library still shows reading % as before.
3. Put a short book in the incubator, read a few pages and go back: the Library shows `Incubating N%`.
4. Open an old book: your reading position is still there.
5. Switch **Settings → Language** between Tiếng Việt and English and open Olympus: the text changes language.

## Going back to the old firmware

- **To the reading-progress build (no Olympus):** flash from the SD card as above, but pick `crosspoint-2.0.0-reading-progress-x4pro.bin`.
- **To official CrossPoint 2.0.0:** download the X4 Pro `.bin` from the Releases page of github.com/crosspoint-reader/crosspoint-reader, copy it to the SD card and pick it in **SD Card Firmware Update**; or over USB choose the official CrossPoint build for Xteink X4Pro instead of Custom .bin.
- **If the device does not boot normally:** hold **Down** and press **Power** to go straight to the firmware picker on the SD card.
- Olympus data stays on the card after going back (the old build simply ignores it). If the "Olympus" sleep screen was selected, the old build falls back to the default sleep screen.

Do not use Xteink Unlocker with this file.

## Known limits

- All 90 characters have art.
- EPUB page counts are estimates (about 2 KB of text per page), so they can differ from the page numbers the reader shows. XTC uses real page counts.
- An egg hatches when the reading position reaches 95% (or the end-of-book screen); pages actually viewed are not checked.
- "Put in incubator" is only on the Library's Recent tab (the book must have been opened at least once).
- Grey is drawn with dots (dither), not true grey.
- If the device clock has never been set (never connected to Wi-Fi), days are not counted.
- English layout was checked only on computer-rendered previews. Not tried on a real device.

## For builders

- `olympus-on-reading-progress-2.0.0.patch`: apply after `reading-progress-2.0.0.patch` on tag 2.0.0.
- `crosspoint-2.0.0-olympus-full.patch`: applies directly to tag 2.0.0 (includes reading-progress %).
- Build: `pio run -e x4pro-gh_release`. Firmware 5.75 MB / 6.25 MB app partition (87.7%), RAM 34.2%.
- Language switch: `src/olympus/OlympusLang.h` (`OLY_T(vi, en)`); English profiles are `ROSTER_EN` in `src/olympus/OlympusRoster.cpp`.
