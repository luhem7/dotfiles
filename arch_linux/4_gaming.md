# Gaming
This part of the setup goes through setting up everything needed for gaming

## Steam
I'm following the [official Steam page](https://wiki.archlinux.org/title/Steam).

I pretty much followed the guide as it is.

## Setting up hyprland to use a higher refresh rate
I installed `wlr-randr` to print out the listed display resolutions my monitor supports. Then I ran it to find I 60 Hz was listed as my current refresh rate:
```
Modes:
    3440x1440 px, 59.973000 Hz (preferred, current)
    3440x1440 px, 164.899994 Hz
```
After that, I ran `hyprctl keyword monitor DP-1, 3440x1440@164.9, auto, 1` to see if hyprctl would accept this higher refresh rate. The screen went blank for 3 seconds, but printed ok at the end! I verified that we were at a higher refresh rate by running `hyprctl monitors` and seeing `3440x1440@164.89999 at 0x0` in the output.
To make this change permanent, I editing the monitor line as follows: `monitor=DP-1, 3440x1440@164.9, auto, 1`
