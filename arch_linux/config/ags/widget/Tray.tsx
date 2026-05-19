import { Gtk } from "ags/gtk4"
import { createBinding, For } from "ags"
import Tray from "gi://AstalTray"

const tray = Tray.get_default()

const trayItems = createBinding(tray, "items")

function TrayItemButton({ item }: { item: Tray.TrayItem }) {
  const gicon = createBinding(item, "gicon")
  const tooltip = createBinding(item, "tooltipText").as(
    t => t || item.get_title() || "",
  )

  // One-time imperative setup. <For> re-parents existing children on every
  // update (unmap+map), so onRealize can re-fire. Guard with a flag.
  let setupDone = false
  const setupOnce = (self: Gtk.MenuButton) => {
    if (setupDone) return
    setupDone = true

    const menuModel = item.get_menu_model()
    if (menuModel) {
      self.set_menu_model(menuModel)
      const actionGroup = item.get_action_group()
      if (actionGroup) self.insert_action_group("dbusmenu", actionGroup)
    }

    if (!item.get_is_menu()) {
      const click = new Gtk.GestureClick()
      click.set_button(1)
      click.connect("pressed", (_gesture, _n, x, y) => {
        item.activate(Math.round(x), Math.round(y))
      })
      self.add_controller(click)
    }
  }

  return (
    <menubutton
      class="tray-item"
      tooltipText={tooltip}
      onRealize={setupOnce}
      onNotifyActive={(self) => {
        if (self.get_active()) item.about_to_show()
      }}
    >
      <image gicon={gicon} pixelSize={16} />
    </menubutton>
  )
}

export function SysTray() {
  return (
    <box class="systray">
      <For each={trayItems} id={item => item.get_item_id()}>
        {item => <TrayItemButton item={item} />}
      </For>
    </box>
  )
}
