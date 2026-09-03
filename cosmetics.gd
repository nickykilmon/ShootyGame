class_name Cosmetics
# Catalog of weapon skins + character cosmetics, plus the primitive-mesh builder
# and case-roll helpers. Everything is procedural (no art assets).

# ---- rarity ---------------------------------------------------------------
const RARITY_COLOR := {
	"common": Color(0.54, 0.70, 1.0),
	"rare": Color(0.76, 0.61, 1.0),
	"epic": Color(1.0, 0.54, 0.84),
	"legendary": Color(1.0, 0.81, 0.36),
}

static func roll_rarity(r: float) -> String:
	if r < 0.75: return "common"
	if r < 0.94: return "rare"
	if r < 0.99: return "epic"
	return "legendary"

# ---- weapon skins ------------------------------------------------------------
# A skin recolours a weapon: "primary" replaces metal/steel/plastic parts,
# "secondary" replaces wood/dark/green parts. emission != black -> it glows.
const SKINS := {
	"bubblegum":   {"name": "Bubblegum",  "rarity": "common",    "primary": Color(1.0, 0.45, 0.78), "secondary": Color(0.95, 0.2, 0.55), "metallic": 0.2, "roughness": 0.5, "emission": Color(0,0,0)},
	"blackout":    {"name": "Blackout",   "rarity": "common",    "primary": Color(0.06, 0.06, 0.07), "secondary": Color(0.02, 0.02, 0.02), "metallic": 0.1, "roughness": 0.85, "emission": Color(0,0,0)},
	"snowcap":     {"name": "Snowcap",    "rarity": "common",    "primary": Color(0.93, 0.95, 0.98), "secondary": Color(0.6, 0.78, 0.95), "metallic": 0.1, "roughness": 0.55, "emission": Color(0,0,0)},
	"rustbucket":  {"name": "Rust Bucket","rarity": "common",    "primary": Color(0.55, 0.32, 0.18), "secondary": Color(0.25, 0.15, 0.1), "metallic": 0.25, "roughness": 0.9, "emission": Color(0,0,0)},
	"fieldnight":  {"name": "Field Night","rarity": "common",    "primary": Color(0.16, 0.2, 0.28), "secondary": Color(0.05, 0.06, 0.09), "metallic": 0.3, "roughness": 0.5, "emission": Color(0,0,0)},
	"jungle":      {"name": "Jungle",     "rarity": "common",    "primary": Color(0.33, 0.4, 0.22), "secondary": Color(0.5, 0.42, 0.28), "metallic": 0.1, "roughness": 0.8, "emission": Color(0,0,0)},
	"goldrush":    {"name": "Gold Rush",  "rarity": "rare",      "primary": Color(1.0, 0.79, 0.24), "secondary": Color(0.35, 0.22, 0.06), "metallic": 0.9, "roughness": 0.25, "emission": Color(0,0,0)},
	"chrome":      {"name": "Chrome",     "rarity": "rare",      "primary": Color(0.82, 0.85, 0.9), "secondary": Color(0.7, 0.72, 0.78), "metallic": 1.0, "roughness": 0.07, "emission": Color(0,0,0)},
	"emerald":     {"name": "Emerald",    "rarity": "rare",      "primary": Color(0.12, 0.75, 0.4), "secondary": Color(0.04, 0.3, 0.16), "metallic": 0.65, "roughness": 0.18, "emission": Color(0,0,0)},
	"ruby":        {"name": "Ruby",       "rarity": "rare",      "primary": Color(0.85, 0.1, 0.2), "secondary": Color(0.3, 0.02, 0.06), "metallic": 0.65, "roughness": 0.18, "emission": Color(0,0,0)},
	"toxic":       {"name": "Toxic",      "rarity": "rare",      "primary": Color(0.45, 0.95, 0.2), "secondary": Color(0.1, 0.3, 0.05), "metallic": 0.3, "roughness": 0.4, "emission": Color(0.25, 0.6, 0.08)},
	"highlighter": {"name": "Highlighter","rarity": "rare",      "primary": Color(0.95, 0.95, 0.15), "secondary": Color(0.15, 0.15, 0.15), "metallic": 0.2, "roughness": 0.45, "emission": Color(0.55, 0.55, 0.05)},
	"lava":        {"name": "Lava",       "rarity": "epic",      "primary": Color(0.12, 0.09, 0.09), "secondary": Color(0.05, 0.03, 0.03), "metallic": 0.2, "roughness": 0.85, "emission": Color(0.9, 0.3, 0.03)},
	"cyberline":   {"name": "Cyberline",  "rarity": "epic",      "primary": Color(0.07, 0.08, 0.1), "secondary": Color(0.03, 0.03, 0.04), "metallic": 0.5, "roughness": 0.3, "emission": Color(0.05, 0.7, 0.85)},
	"galaxy":      {"name": "Galaxy",     "rarity": "epic",      "primary": Color(0.18, 0.08, 0.32), "secondary": Color(0.09, 0.04, 0.18), "metallic": 0.55, "roughness": 0.28, "emission": Color(0.6, 0.15, 0.7)},
	"vaporwave":   {"name": "Vaporwave",  "rarity": "epic",      "primary": Color(1.0, 0.45, 0.8), "secondary": Color(0.35, 0.85, 0.95), "metallic": 0.35, "roughness": 0.35, "emission": Color(0.35, 0.1, 0.4)},
	"molten_gold": {"name": "Molten Gold","rarity": "legendary", "primary": Color(1.0, 0.82, 0.3), "secondary": Color(0.8, 0.55, 0.1), "metallic": 1.0, "roughness": 0.12, "emission": Color(0.7, 0.45, 0.05)},
	"prismatic":   {"name": "Prismatic",  "rarity": "legendary", "primary": Color(0.95, 0.95, 1.0), "secondary": Color(0.8, 0.85, 1.0), "metallic": 0.85, "roughness": 0.08, "emission": Color(0.3, 0.5, 0.9)},

	"candycorn":   {"name": "Candy Corn", "rarity": "common",    "primary": Color(0.98, 0.6, 0.1), "secondary": Color(0.98, 0.9, 0.3), "metallic": 0.2, "roughness": 0.5, "emission": Color(0,0,0)},
	"ocean":       {"name": "Ocean",      "rarity": "common",    "primary": Color(0.1, 0.5, 0.6), "secondary": Color(0.05, 0.12, 0.25), "metallic": 0.3, "roughness": 0.4, "emission": Color(0,0,0)},
	"copper":      {"name": "Copper",     "rarity": "common",    "primary": Color(0.72, 0.42, 0.24), "secondary": Color(0.3, 0.18, 0.1), "metallic": 0.9, "roughness": 0.35, "emission": Color(0,0,0)},
	"bumblebee":   {"name": "Bumblebee",  "rarity": "common",    "primary": Color(0.98, 0.82, 0.1), "secondary": Color(0.05, 0.05, 0.05), "metallic": 0.3, "roughness": 0.5, "emission": Color(0,0,0)},
	"sakura":      {"name": "Sakura",     "rarity": "common",    "primary": Color(1.0, 0.78, 0.85), "secondary": Color(0.6, 0.35, 0.4), "metallic": 0.2, "roughness": 0.55, "emission": Color(0,0,0)},
	"royal":       {"name": "Royal",      "rarity": "rare",      "primary": Color(0.12, 0.16, 0.5), "secondary": Color(0.9, 0.72, 0.25), "metallic": 0.7, "roughness": 0.25, "emission": Color(0,0,0)},
	"amethyst":    {"name": "Amethyst",   "rarity": "rare",      "primary": Color(0.55, 0.3, 0.8), "secondary": Color(0.2, 0.1, 0.32), "metallic": 0.6, "roughness": 0.16, "emission": Color(0,0,0)},
	"frostbite":   {"name": "Frostbite",  "rarity": "rare",      "primary": Color(0.6, 0.85, 1.0), "secondary": Color(0.2, 0.35, 0.5), "metallic": 0.4, "roughness": 0.2, "emission": Color(0.1, 0.4, 0.7)},
	"firestarter": {"name": "Firestarter","rarity": "rare",      "primary": Color(0.8, 0.2, 0.05), "secondary": Color(0.25, 0.06, 0.02), "metallic": 0.3, "roughness": 0.5, "emission": Color(0.8, 0.3, 0.05)},
	"digital":     {"name": "Digital",    "rarity": "rare",      "primary": Color(0.1, 0.12, 0.12), "secondary": Color(0.04, 0.05, 0.05), "metallic": 0.4, "roughness": 0.35, "emission": Color(0.1, 0.75, 0.25)},
	"neon_noir":   {"name": "Neon Noir",  "rarity": "epic",      "primary": Color(0.05, 0.05, 0.06), "secondary": Color(0.02, 0.02, 0.03), "metallic": 0.5, "roughness": 0.25, "emission": Color(0.95, 0.1, 0.55)},
	"void":        {"name": "Void",       "rarity": "epic",      "primary": Color(0.02, 0.02, 0.03), "secondary": Color(0.01, 0.01, 0.02), "metallic": 0.6, "roughness": 0.2, "emission": Color(0.25, 0.05, 0.4)},
	"radioactive": {"name": "Radioactive","rarity": "epic",      "primary": Color(0.7, 0.9, 0.1), "secondary": Color(0.2, 0.28, 0.05), "metallic": 0.3, "roughness": 0.4, "emission": Color(0.55, 0.8, 0.05)},
	"sunset":      {"name": "Sunset",     "rarity": "epic",      "primary": Color(1.0, 0.5, 0.25), "secondary": Color(0.5, 0.15, 0.4), "metallic": 0.35, "roughness": 0.3, "emission": Color(0.4, 0.12, 0.15)},
	"dragonfire":  {"name": "Dragonfire", "rarity": "legendary", "primary": Color(0.2, 0.03, 0.03), "secondary": Color(0.08, 0.02, 0.02), "metallic": 0.4, "roughness": 0.4, "emission": Color(1.0, 0.35, 0.05)},
	"starlight":   {"name": "Starlight",  "rarity": "legendary", "primary": Color(0.06, 0.07, 0.16), "secondary": Color(0.03, 0.03, 0.09), "metallic": 0.7, "roughness": 0.15, "emission": Color(0.6, 0.7, 1.0)},
}

# ---- character cosmetics ---------------------------------------------------
# slot: head / face / hair / back. Positions are player-local
# (capsule spans y 0..2; head ~ y 1.9; player faces -Z).
const _BLACK := Color(0.05, 0.05, 0.06)
const _GREY := Color(0.5, 0.5, 0.55)
const _PINK := Color(1.0, 0.55, 0.78)
const _GOLD := Color(1.0, 0.82, 0.35)
const _RED := Color(0.8, 0.12, 0.15)
const _WHITE := Color(0.95, 0.95, 0.95)
const _ORANGE := Color(0.95, 0.5, 0.15)
const _BROWN := Color(0.42, 0.28, 0.16)
const _PURPLE := Color(0.4, 0.2, 0.6)
const _OLIVE := Color(0.32, 0.36, 0.2)

const COSMETICS := {
	"cat_ears": {"name": "Cat Ears", "slot": "head", "rarity": "rare", "parts": [
		{"t": "prism", "s": Vector3(0.16, 0.22, 0.05), "p": Vector3(0.19, 2.0, 0), "r": Vector3(0, 0, -18), "c": _PINK},
		{"t": "prism", "s": Vector3(0.16, 0.22, 0.05), "p": Vector3(-0.19, 2.0, 0), "r": Vector3(0, 0, 18), "c": _PINK},
	]},
	"beanie": {"name": "Beanie", "slot": "head", "rarity": "common", "parts": [
		{"t": "sphere", "s": Vector3(0.62, 0.42, 0.62), "p": Vector3(0, 1.98, 0), "c": Color(0.7, 0.2, 0.25)},
		{"t": "cyl", "s": Vector3(0.32, 0.13, 0), "p": Vector3(0, 1.82, 0), "c": Color(0.5, 0.14, 0.18)},
	]},
	"cowboy_hat": {"name": "Cowboy Hat", "slot": "head", "rarity": "rare", "parts": [
		{"t": "cyl", "s": Vector3(0.9, 0.05, 0), "p": Vector3(0, 1.94, 0), "c": _BROWN},
		{"t": "sphere", "s": Vector3(0.55, 0.42, 0.55), "p": Vector3(0, 2.06, 0), "c": _BROWN},
	]},
	"halo": {"name": "Halo", "slot": "head", "rarity": "epic", "parts": [
		{"t": "torus", "s": Vector3(0.16, 0.26, 0), "p": Vector3(0, 2.4, 0), "r": Vector3(90, 0, 0), "c": _GOLD, "emission": Color(0.9, 0.7, 0.2)},
	]},
	"devil_horns": {"name": "Devil Horns", "slot": "head", "rarity": "rare", "parts": [
		{"t": "cone", "s": Vector3(0.09, 0.24, 0), "p": Vector3(0.18, 2.02, 0), "r": Vector3(0, 0, -25), "c": _RED},
		{"t": "cone", "s": Vector3(0.09, 0.24, 0), "p": Vector3(-0.18, 2.02, 0), "r": Vector3(0, 0, 25), "c": _RED},
	]},
	"wizard_hat": {"name": "Wizard Hat", "slot": "head", "rarity": "epic", "parts": [
		{"t": "cyl", "s": Vector3(0.7, 0.04, 0), "p": Vector3(0, 1.92, 0), "c": _PURPLE},
		{"t": "cone", "s": Vector3(0.42, 0.85, 0), "p": Vector3(0, 2.32, 0), "c": _PURPLE},
	]},
	"crown": {"name": "Crown", "slot": "head", "rarity": "legendary", "parts": [
		{"t": "cyl", "s": Vector3(0.44, 0.16, 0), "p": Vector3(0, 2.0, 0), "c": _GOLD, "emission": Color(0.5, 0.4, 0.1)},
		{"t": "cone", "s": Vector3(0.09, 0.18, 0), "p": Vector3(0, 2.14, 0.18), "c": _GOLD, "emission": Color(0.5, 0.4, 0.1)},
		{"t": "cone", "s": Vector3(0.09, 0.18, 0), "p": Vector3(0.18, 2.14, 0), "c": _GOLD, "emission": Color(0.5, 0.4, 0.1)},
		{"t": "cone", "s": Vector3(0.09, 0.18, 0), "p": Vector3(-0.18, 2.14, 0), "c": _GOLD, "emission": Color(0.5, 0.4, 0.1)},
		{"t": "cone", "s": Vector3(0.09, 0.18, 0), "p": Vector3(0, 2.14, -0.18), "c": _GOLD, "emission": Color(0.5, 0.4, 0.1)},
	]},
	"bunny_ears": {"name": "Bunny Ears", "slot": "head", "rarity": "rare", "parts": [
		{"t": "sphere", "s": Vector3(0.12, 0.5, 0.08), "p": Vector3(0.13, 2.2, 0), "r": Vector3(0, 0, -8), "c": _WHITE},
		{"t": "sphere", "s": Vector3(0.12, 0.5, 0.08), "p": Vector3(-0.13, 2.2, 0), "r": Vector3(0, 0, 8), "c": _WHITE},
	]},
	"antennae": {"name": "Antennae", "slot": "head", "rarity": "common", "parts": [
		{"t": "cyl", "s": Vector3(0.02, 0.3, 0), "p": Vector3(0.1, 2.1, 0), "r": Vector3(0, 0, -12), "c": _BLACK},
		{"t": "cyl", "s": Vector3(0.02, 0.3, 0), "p": Vector3(-0.1, 2.1, 0), "r": Vector3(0, 0, 12), "c": _BLACK},
		{"t": "sphere", "s": Vector3(0.08, 0.08, 0.08), "p": Vector3(0.14, 2.26, 0), "c": Color(1, 0.3, 0.3)},
		{"t": "sphere", "s": Vector3(0.08, 0.08, 0.08), "p": Vector3(-0.14, 2.26, 0), "c": Color(1, 0.3, 0.3)},
	]},
	"sunglasses": {"name": "Sunglasses", "slot": "face", "rarity": "common", "parts": [
		{"t": "box", "s": Vector3(0.56, 0.13, 0.05), "p": Vector3(0, 1.8, -0.46), "c": _BLACK},
		{"t": "box", "s": Vector3(0.05, 0.04, 0.3), "p": Vector3(0.27, 1.8, -0.32), "c": _BLACK},
		{"t": "box", "s": Vector3(0.05, 0.04, 0.3), "p": Vector3(-0.27, 1.8, -0.32), "c": _BLACK},
	]},
	"monocle": {"name": "Monocle", "slot": "face", "rarity": "rare", "parts": [
		{"t": "torus", "s": Vector3(0.09, 0.13, 0), "p": Vector3(0.16, 1.8, -0.47), "c": _GOLD},
		{"t": "box", "s": Vector3(0.02, 0.18, 0.02), "p": Vector3(0.16, 1.68, -0.44), "c": _GOLD},
	]},
	"mustache": {"name": "Mustache", "slot": "face", "rarity": "common", "parts": [
		{"t": "box", "s": Vector3(0.3, 0.07, 0.06), "p": Vector3(0, 1.66, -0.46), "c": _BROWN},
	]},
	"ryan": {"name": "Ryan Kiapour Accessory", "slot": "hair", "rarity": "epic", "parts": [
		{"t": "sphere", "s": Vector3(0.24, 0.24, 0.24), "p": Vector3(0, 2.0, 0), "c": _BLACK},
		{"t": "sphere", "s": Vector3(0.22, 0.22, 0.22), "p": Vector3(0.2, 1.96, 0.05), "c": _BLACK},
		{"t": "sphere", "s": Vector3(0.22, 0.22, 0.22), "p": Vector3(-0.2, 1.96, 0.05), "c": _BLACK},
		{"t": "sphere", "s": Vector3(0.22, 0.22, 0.22), "p": Vector3(0.1, 1.98, -0.2), "c": _BLACK},
		{"t": "sphere", "s": Vector3(0.22, 0.22, 0.22), "p": Vector3(-0.1, 1.98, -0.2), "c": _BLACK},
		{"t": "sphere", "s": Vector3(0.2, 0.2, 0.2), "p": Vector3(0.16, 1.92, -0.16), "c": _BLACK},
		{"t": "sphere", "s": Vector3(0.2, 0.2, 0.2), "p": Vector3(-0.16, 1.92, -0.16), "c": _BLACK},
		{"t": "sphere", "s": Vector3(0.2, 0.2, 0.2), "p": Vector3(0, 1.9, 0.2), "c": _BLACK},
	]},
	"mohawk": {"name": "Mohawk", "slot": "hair", "rarity": "rare", "parts": [
		{"t": "prism", "s": Vector3(0.06, 0.26, 0.16), "p": Vector3(0, 2.06, 0.14), "c": _RED},
		{"t": "prism", "s": Vector3(0.06, 0.3, 0.16), "p": Vector3(0, 2.08, 0), "c": _RED},
		{"t": "prism", "s": Vector3(0.06, 0.26, 0.16), "p": Vector3(0, 2.06, -0.14), "c": _RED},
	]},
	"cat_tail": {"name": "Cat Tail", "slot": "back", "rarity": "rare", "parts": [
		{"t": "sphere", "s": Vector3(0.14, 0.14, 0.14), "p": Vector3(0, 1.05, 0.42), "c": _GREY},
		{"t": "sphere", "s": Vector3(0.12, 0.12, 0.12), "p": Vector3(0, 1.2, 0.55), "c": _GREY},
		{"t": "sphere", "s": Vector3(0.1, 0.1, 0.1), "p": Vector3(0, 1.38, 0.6), "c": _GREY},
		{"t": "sphere", "s": Vector3(0.08, 0.08, 0.08), "p": Vector3(0, 1.55, 0.55), "c": _WHITE},
	]},
	"fox_tail": {"name": "Fox Tail", "slot": "back", "rarity": "epic", "parts": [
		{"t": "sphere", "s": Vector3(0.2, 0.2, 0.2), "p": Vector3(0, 1.0, 0.42), "c": _ORANGE},
		{"t": "sphere", "s": Vector3(0.17, 0.17, 0.17), "p": Vector3(0, 1.15, 0.55), "c": _ORANGE},
		{"t": "sphere", "s": Vector3(0.14, 0.14, 0.14), "p": Vector3(0, 1.32, 0.62), "c": _ORANGE},
		{"t": "sphere", "s": Vector3(0.11, 0.11, 0.11), "p": Vector3(0, 1.5, 0.58), "c": _WHITE},
	]},
	"angel_wings": {"name": "Angel Wings", "slot": "back", "rarity": "legendary", "parts": [
		{"t": "prism", "s": Vector3(0.06, 0.5, 0.5), "p": Vector3(0.3, 1.3, 0.35), "r": Vector3(0, -30, 20), "c": _WHITE, "emission": Color(0.3, 0.3, 0.35)},
		{"t": "prism", "s": Vector3(0.06, 0.5, 0.5), "p": Vector3(-0.3, 1.3, 0.35), "r": Vector3(0, 30, -20), "c": _WHITE, "emission": Color(0.3, 0.3, 0.35)},
	]},
	"backpack": {"name": "Backpack", "slot": "back", "rarity": "common", "parts": [
		{"t": "box", "s": Vector3(0.42, 0.5, 0.24), "p": Vector3(0, 1.2, 0.42), "c": _OLIVE},
		{"t": "box", "s": Vector3(0.06, 0.5, 0.06), "p": Vector3(0.18, 1.35, 0.15), "c": Color(0.2, 0.22, 0.14)},
		{"t": "box", "s": Vector3(0.06, 0.5, 0.06), "p": Vector3(-0.18, 1.35, 0.15), "c": Color(0.2, 0.22, 0.14)},
	]},
	"jetpack": {"name": "Jetpack", "slot": "back", "rarity": "epic", "parts": [
		{"t": "cyl", "s": Vector3(0.12, 0.5, 0), "p": Vector3(0.16, 1.25, 0.4), "c": _GREY},
		{"t": "cyl", "s": Vector3(0.12, 0.5, 0), "p": Vector3(-0.16, 1.25, 0.4), "c": _GREY},
		{"t": "sphere", "s": Vector3(0.12, 0.1, 0.12), "p": Vector3(0.16, 0.98, 0.4), "c": _ORANGE, "emission": Color(0.9, 0.4, 0.1)},
		{"t": "sphere", "s": Vector3(0.12, 0.1, 0.12), "p": Vector3(-0.16, 0.98, 0.4), "c": _ORANGE, "emission": Color(0.9, 0.4, 0.1)},
	]},

	"top_hat": {"name": "Top Hat", "slot": "head", "rarity": "rare", "parts": [
		{"t": "cyl", "s": Vector3(0.5, 0.04, 0), "p": Vector3(0, 1.94, 0), "c": _BLACK},
		{"t": "cyl", "s": Vector3(0.3, 0.4, 0), "p": Vector3(0, 2.15, 0), "c": _BLACK},
		{"t": "cyl", "s": Vector3(0.31, 0.07, 0), "p": Vector3(0, 2.0, 0), "c": _RED},
	]},
	"party_hat": {"name": "Party Hat", "slot": "head", "rarity": "common", "parts": [
		{"t": "cone", "s": Vector3(0.28, 0.55, 0), "p": Vector3(0, 2.2, 0), "c": Color(0.2, 0.7, 1.0)},
		{"t": "sphere", "s": Vector3(0.12, 0.12, 0.12), "p": Vector3(0, 2.48, 0), "c": _PINK},
	]},
	"pirate_hat": {"name": "Pirate Hat", "slot": "head", "rarity": "rare", "parts": [
		{"t": "box", "s": Vector3(0.75, 0.05, 0.45), "p": Vector3(0, 1.98, 0), "r": Vector3(0, 0, 4), "c": _BLACK},
		{"t": "sphere", "s": Vector3(0.5, 0.3, 0.4), "p": Vector3(0, 2.02, 0), "c": _BLACK},
		{"t": "box", "s": Vector3(0.12, 0.12, 0.02), "p": Vector3(0, 2.05, -0.22), "c": _WHITE},
	]},
	"viking_helmet": {"name": "Viking Helmet", "slot": "head", "rarity": "epic", "parts": [
		{"t": "sphere", "s": Vector3(0.6, 0.45, 0.6), "p": Vector3(0, 1.97, 0), "c": _GREY},
		{"t": "cone", "s": Vector3(0.1, 0.3, 0), "p": Vector3(0.34, 2.05, 0), "r": Vector3(0, 0, -55), "c": _WHITE},
		{"t": "cone", "s": Vector3(0.1, 0.3, 0), "p": Vector3(-0.34, 2.05, 0), "r": Vector3(0, 0, 55), "c": _WHITE},
	]},
	"flower_crown": {"name": "Flower Crown", "slot": "head", "rarity": "rare", "parts": [
		{"t": "torus", "s": Vector3(0.24, 0.34, 0), "p": Vector3(0, 1.98, 0), "r": Vector3(90, 0, 0), "c": Color(0.3, 0.6, 0.25)},
		{"t": "sphere", "s": Vector3(0.13, 0.13, 0.13), "p": Vector3(0, 1.99, 0.3), "c": _PINK},
		{"t": "sphere", "s": Vector3(0.13, 0.13, 0.13), "p": Vector3(0.28, 1.99, 0.08), "c": Color(1, 0.9, 0.3)},
		{"t": "sphere", "s": Vector3(0.13, 0.13, 0.13), "p": Vector3(-0.28, 1.99, 0.08), "c": Color(0.7, 0.5, 1.0)},
	]},
	"propeller_cap": {"name": "Propeller Cap", "slot": "head", "rarity": "epic", "parts": [
		{"t": "sphere", "s": Vector3(0.5, 0.3, 0.5), "p": Vector3(0, 1.95, 0), "c": Color(0.9, 0.2, 0.2)},
		{"t": "cyl", "s": Vector3(0.03, 0.12, 0), "p": Vector3(0, 2.14, 0), "c": _GREY},
		{"t": "box", "s": Vector3(0.5, 0.03, 0.08), "p": Vector3(0, 2.2, 0), "c": Color(1, 0.9, 0.2)},
	]},
	"space_helmet": {"name": "Space Helmet", "slot": "head", "rarity": "legendary", "parts": [
		{"t": "sphere", "s": Vector3(0.78, 0.8, 0.78), "p": Vector3(0, 1.82, 0), "c": Color(0.7, 0.85, 1.0), "alpha": 0.28},
		{"t": "torus", "s": Vector3(0.06, 0.4, 0), "p": Vector3(0, 1.55, 0), "r": Vector3(90, 0, 0), "c": _WHITE},
	]},
	"ushanka": {"name": "Ushanka", "slot": "head", "rarity": "common", "parts": [
		{"t": "sphere", "s": Vector3(0.66, 0.42, 0.6), "p": Vector3(0, 1.95, 0), "c": Color(0.35, 0.25, 0.15)},
		{"t": "box", "s": Vector3(0.22, 0.3, 0.12), "p": Vector3(0.32, 1.85, 0), "c": Color(0.3, 0.2, 0.12)},
		{"t": "box", "s": Vector3(0.22, 0.3, 0.12), "p": Vector3(-0.32, 1.85, 0), "c": Color(0.3, 0.2, 0.12)},
	]},
	"eyepatch": {"name": "Eyepatch", "slot": "face", "rarity": "common", "parts": [
		{"t": "box", "s": Vector3(0.18, 0.18, 0.04), "p": Vector3(0.13, 1.82, -0.47), "c": _BLACK},
	]},
	"clown_nose": {"name": "Clown Nose", "slot": "face", "rarity": "rare", "parts": [
		{"t": "sphere", "s": Vector3(0.14, 0.14, 0.14), "p": Vector3(0, 1.74, -0.48), "c": Color(1, 0.15, 0.15)},
	]},
	"three_d_glasses": {"name": "3D Glasses", "slot": "face", "rarity": "common", "parts": [
		{"t": "box", "s": Vector3(0.24, 0.13, 0.04), "p": Vector3(0.14, 1.8, -0.46), "c": Color(1, 0.1, 0.1), "alpha": 0.55},
		{"t": "box", "s": Vector3(0.24, 0.13, 0.04), "p": Vector3(-0.14, 1.8, -0.46), "c": Color(0.1, 0.4, 1.0), "alpha": 0.55},
	]},
	"afro": {"name": "Afro", "slot": "hair", "rarity": "rare", "parts": [
		{"t": "sphere", "s": Vector3(0.7, 0.6, 0.7), "p": Vector3(0, 2.0, 0), "c": Color(0.15, 0.1, 0.06)},
	]},
	"anime_spikes": {"name": "Anime Spikes", "slot": "hair", "rarity": "epic", "parts": [
		{"t": "prism", "s": Vector3(0.1, 0.35, 0.1), "p": Vector3(0, 2.1, 0.1), "r": Vector3(-20, 0, 0), "c": Color(0.15, 0.35, 0.9)},
		{"t": "prism", "s": Vector3(0.1, 0.35, 0.1), "p": Vector3(0.16, 2.08, 0), "r": Vector3(0, 0, -20), "c": Color(0.15, 0.35, 0.9)},
		{"t": "prism", "s": Vector3(0.1, 0.35, 0.1), "p": Vector3(-0.16, 2.08, 0), "r": Vector3(0, 0, 20), "c": Color(0.15, 0.35, 0.9)},
		{"t": "prism", "s": Vector3(0.1, 0.35, 0.1), "p": Vector3(0, 2.08, -0.16), "r": Vector3(20, 0, 0), "c": Color(0.15, 0.35, 0.9)},
	]},
	"blonde_locks": {"name": "Blonde Locks", "slot": "hair", "rarity": "rare", "parts": [
		{"t": "sphere", "s": Vector3(0.5, 0.25, 0.5), "p": Vector3(0, 2.0, 0), "c": Color(0.95, 0.82, 0.4)},
		{"t": "box", "s": Vector3(0.5, 0.55, 0.12), "p": Vector3(0, 1.7, 0.28), "c": Color(0.95, 0.82, 0.4)},
		{"t": "box", "s": Vector3(0.12, 0.55, 0.5), "p": Vector3(0.28, 1.7, 0), "c": Color(0.95, 0.82, 0.4)},
		{"t": "box", "s": Vector3(0.12, 0.55, 0.5), "p": Vector3(-0.28, 1.7, 0), "c": Color(0.95, 0.82, 0.4)},
	]},
	"cape": {"name": "Cape", "slot": "back", "rarity": "epic", "parts": [
		{"t": "box", "s": Vector3(0.7, 1.1, 0.06), "p": Vector3(0, 1.05, 0.36), "r": Vector3(6, 0, 0), "c": Color(0.6, 0.05, 0.1)},
	]},
	"demon_wings": {"name": "Demon Wings", "slot": "back", "rarity": "legendary", "parts": [
		{"t": "prism", "s": Vector3(0.06, 0.6, 0.6), "p": Vector3(0.34, 1.25, 0.3), "r": Vector3(0, -35, 25), "c": Color(0.15, 0.03, 0.05)},
		{"t": "prism", "s": Vector3(0.06, 0.6, 0.6), "p": Vector3(-0.34, 1.25, 0.3), "r": Vector3(0, 35, -25), "c": Color(0.15, 0.03, 0.05)},
	]},
	"turtle_shell": {"name": "Turtle Shell", "slot": "back", "rarity": "rare", "parts": [
		{"t": "sphere", "s": Vector3(0.6, 0.4, 0.5), "p": Vector3(0, 1.15, 0.4), "c": Color(0.2, 0.45, 0.2)},
		{"t": "sphere", "s": Vector3(0.55, 0.36, 0.45), "p": Vector3(0, 1.16, 0.44), "c": Color(0.5, 0.35, 0.15)},
	]},
	"balloon": {"name": "Balloon", "slot": "back", "rarity": "common", "parts": [
		{"t": "cyl", "s": Vector3(0.01, 0.8, 0), "p": Vector3(0, 1.6, 0.4), "c": _GREY},
		{"t": "sphere", "s": Vector3(0.35, 0.42, 0.35), "p": Vector3(0, 2.1, 0.4), "c": Color(1, 0.3, 0.3)},
	]},
	"sword_back": {"name": "Sword on Back", "slot": "back", "rarity": "rare", "parts": [
		{"t": "box", "s": Vector3(0.06, 0.9, 0.02), "p": Vector3(0.05, 1.3, 0.4), "r": Vector3(0, 0, 20), "c": _GREY},
		{"t": "box", "s": Vector3(0.24, 0.06, 0.06), "p": Vector3(-0.1, 0.9, 0.4), "r": Vector3(0, 0, 20), "c": _BROWN},
		{"t": "box", "s": Vector3(0.06, 0.16, 0.06), "p": Vector3(-0.16, 0.82, 0.4), "r": Vector3(0, 0, 20), "c": _BROWN},
	]},
}

# ---- helpers --------------------------------------------------------------

static func item(id: String) -> Dictionary:
	if SKINS.has(id):
		return {"name": SKINS[id]["name"], "rarity": SKINS[id]["rarity"], "kind": "skin"}
	if COSMETICS.has(id):
		return {"name": COSMETICS[id]["name"], "rarity": COSMETICS[id]["rarity"], "kind": "cosmetic", "slot": COSMETICS[id]["slot"]}
	return {}

static func all_ids() -> Array:
	var out := []
	for k in SKINS: out.append(k)
	for k in COSMETICS: out.append(k)
	return out

static func ids_of_rarity(rarity: String) -> Array:
	var out := []
	for id in all_ids():
		if item(id).get("rarity", "") == rarity:
			out.append(id)
	return out

static func cosmetics_for_slot(slot: String) -> Array:
	var out := []
	for id in COSMETICS:
		if COSMETICS[id]["slot"] == slot:
			out.append(id)
	return out

# Builds a mesh for one primitive part spec.
static func make_part(part: Dictionary) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh
	var kind: String = part.get("t", "box")
	match kind:
		"cyl", "cone":
			mesh = CylinderMesh.new()
			mesh.bottom_radius = part["s"].x
			mesh.top_radius = 0.0 if kind == "cone" else part["s"].x
			mesh.height = part["s"].y
		"sphere":
			mesh = SphereMesh.new()
			mesh.radius = 0.5
			mesh.height = 1.0
		"prism":
			mesh = PrismMesh.new()
			mesh.size = part["s"]
		"torus":
			mesh = TorusMesh.new()
			mesh.inner_radius = part["s"].x
			mesh.outer_radius = part["s"].y
		_:
			mesh = BoxMesh.new()
			mesh.size = part["s"]
	var mat := StandardMaterial3D.new()
	var col: Color = part.get("c", Color(0.8, 0.8, 0.8))
	var a := float(part.get("alpha", 1.0))
	if a < 1.0:
		col.a = a
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = col
	mat.metallic = part.get("metallic", 0.1)
	mat.roughness = part.get("roughness", 0.7)
	var em = part.get("emission", Color(0, 0, 0))
	if em != Color(0, 0, 0):
		mat.emission_enabled = true
		mat.emission = em
		mat.emission_energy_multiplier = 2.0
	mesh.material = mat
	mi.mesh = mesh
	mi.position = part.get("p", Vector3.ZERO)
	if part.has("r"):
		mi.rotation_degrees = part["r"]
	if kind == "sphere":
		mi.scale = part["s"]
	return mi
