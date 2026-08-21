# Tips and tricks

Stuff I worked out the hard way and don't want to rediscover from scratch in six months.

## Getting logs out of anything Hyprland starts

Short version: wrap the command in `systemd-cat` and its output shows up in the journal.

```lua
hl.exec_cmd("systemd-cat -t hypridle hypridle")
```
```bash
journalctl -t hypridle -f
```

Here's the problem it solves. Hyprland does not forward stdout or stderr from the processes it spawns; it points them straight at `/dev/null`. So everything in my autostart is running blind: hypridle, hyprpaper, dunst, ags, all of it. They could be screaming about a broken config line and I would never see a single character of it.

I found this out the annoying way, chasing a bug where the screen wasn't locking before suspend. hypridle actually logs really well (it tells you every dbus event it receives, every command it fires, and whether the lock landed), and none of that was reaching me. You can confirm the redirect yourself:

```bash
ls -l /proc/$(pidof hypridle)/fd/1    # -> /dev/null
```

`systemd-cat` is already on the system (it ships with systemd, so there's nothing to install (which is the best kind of dependency)). The `-t` flag sets a tag, which is what lets you pull that one program's output back out later without wading through the whole journal.

Also, this isn't some clever thing I came up with. It's an open Hyprland discussion (#10803) that nobody has answered yet, and the Hyprland wiki itself already uses `systemd-cat -t uwsm_start ...` for logging session startup. The idiom was sitting right there in the docs; it just hadn't been pointed at the thing that needed it.

The general shape works for anything Hyprland launches:

```lua
hl.exec_cmd("systemd-cat -t <tag> <command>")
```

One caveat, and I'm maybe 80% here: this is the right answer for a non-uwsm setup like mine, where Hyprland is started by hand. If you launch through uwsm instead, these programs get real systemd units and the journal logging comes along for free, so you wouldn't need the wrapper at all. Worth re-checking if I ever switch.
