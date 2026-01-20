import { Gtk } from "ags/gtk4"
import Tray from "gi://AstalTray"

const tray = Tray.get_default()

function initTray(container: Gtk.Box) {
  const items = new Map<string, Gtk.MenuButton>()

  const createItem = (item: Tray.TrayItem) => {
    const menuButton = new Gtk.MenuButton()
    menuButton.add_css_class("tray-item")
    menuButton.set_tooltip_text(item.get_tooltip_text() || item.get_title())

    const icon = new Gtk.Image()
    icon.set_from_gicon(item.get_gicon())
    icon.set_pixel_size(16)
    icon.set_size_request(16, 16)
    menuButton.set_child(icon)

    // Set up the menu if available
    const menuModel = item.get_menu_model()
    if (menuModel) {
      menuButton.set_menu_model(menuModel)
      const actionGroup = item.get_action_group()
      if (actionGroup) {
        menuButton.insert_action_group("dbusmenu", actionGroup)
      }
    }

    // Handle left click - activate if not menu-only
    if (!item.get_is_menu()) {
      const clickGesture = new Gtk.GestureClick()
      clickGesture.set_button(1) // Left mouse button
      clickGesture.connect("pressed", (_gesture, _n, x, y) => {
        // Get screen coordinates for activation
        const native = menuButton.get_native()
        if (native) {
          const surface = native.get_surface()
          if (surface) {
            item.activate(Math.round(x), Math.round(y))
          }
        }
      })
      menuButton.add_controller(clickGesture)
    }

    // Update icon when it changes
    item.connect("notify::gicon", () => {
      icon.set_from_gicon(item.get_gicon())
    })

    // Update tooltip when it changes
    item.connect("notify::tooltip", () => {
      menuButton.set_tooltip_text(item.get_tooltip_text() || item.get_title())
    })

    // Notify about to show when menu opens
    menuButton.connect("notify::active", () => {
      if (menuButton.get_active()) {
        item.about_to_show()
      }
    })

    items.set(item.get_item_id(), menuButton)
    container.append(menuButton)
  }

  const removeItem = (itemId: string) => {
    const btn = items.get(itemId)
    if (btn) {
      container.remove(btn)
      items.delete(itemId)
    }
  }

  // Initialize with existing items
  tray.get_items().forEach(createItem)

  // Listen for new items
  tray.connect("item-added", (_self, itemId: string) => {
    const item = tray.get_item(itemId)
    if (item) {
      createItem(item)
    }
  })

  // Listen for removed items
  tray.connect("item-removed", (_self, itemId: string) => {
    removeItem(itemId)
  })
}

export function SysTray() {
  return <box class="systray" onRealize={initTray} />
}
