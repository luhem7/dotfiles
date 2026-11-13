pragma Singleton

import QtQuick
import Quickshell

// Nerd Font Material Design glyphs, by codepoint so the source stays readable.
Singleton {
	readonly property string volumeHigh: String.fromCodePoint(0xF057E)
	readonly property string volumeMedium: String.fromCodePoint(0xF0580)
	readonly property string volumeLow: String.fromCodePoint(0xF057F)
	readonly property string volumeOff: String.fromCodePoint(0xF0581)
	readonly property string mic: String.fromCodePoint(0xF036C)
	readonly property string micOff: String.fromCodePoint(0xF036D)
	readonly property string camera: String.fromCodePoint(0xF0100)
	readonly property string record: String.fromCodePoint(0xF044B)
	readonly property string docker: String.fromCodePoint(0xF0868)
	readonly property string sleep: String.fromCodePoint(0xF0594)
	readonly property string prev: String.fromCodePoint(0xF04AE)
	readonly property string next: String.fromCodePoint(0xF04AD)
	readonly property string play: String.fromCodePoint(0xF040A)
	readonly property string pause: String.fromCodePoint(0xF03E4)
	readonly property string chevronLeft: String.fromCodePoint(0xF0141)
	readonly property string chevronRight: String.fromCodePoint(0xF0142)
}
