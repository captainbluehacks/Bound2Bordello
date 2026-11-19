// scr_ui_colours.gml — Bound to the Bordello · Parchment Theme
// Extracted from selection-mock.html CSS custom properties

// ─── PARCHMENT / PANEL SURFACE ───────────────────────────────
#macro COL_PAPER          #ECE1C8   // base parchment (main panel fill)
#macro COL_PAPER_DEEP     #E3D5B6   // deeper parchment tint (gradient bottom)
#macro COL_PANEL_BORDER   #5A462C   // 1px border around the whole panel
#macro COL_PANEL_EDGE     #7A5F3A   // burnt-edge / heavier border accent

// ─── INK / TEXT HIERARCHY ────────────────────────────────────
#macro COL_INK            #2C2418   // primary text (headings, body)
#macro COL_INK_SECONDARY  #6F6249   // secondary text (.sub, .muted)
#macro COL_INK_FAINT      #8D7E63   // tertiary / hints / locked labels
#macro COL_INK_BODY       #4A3F2C   // breakdown line descriptions
#macro COL_INK_ABOUT      #5A4D36   // "About" italic text, dir arrows
#macro COL_INK_NEIGHBOUR  #3F3524   // adjacency neighbour names

// ─── RULES / SEPARATORS ──────────────────────────────────────
#macro COL_LINE           #B6A079   // faded rule lines (section borders, tab underline)

// ─── GOLD ACCENTS ────────────────────────────────────────────
#macro COL_GOLD           #8A6A25   // section labels (.lbl), active tab underline, total border
#macro COL_GOLD_DIM       #A08A55   // dimmed gold (tab counts, upgrade tag border)

// ─── TABS ────────────────────────────────────────────────────
#macro COL_TAB_BG         #785F37   // tab bar background tint
#macro COL_TAB_BG_ALPHA   0.25      // tab bar alpha value
#macro COL_TAB_ACTIVE_BG  #FFFAEE   // active tab highlight
#macro COL_TAB_ACTIVE_BG_ALPHA 0.25 // active tab highlight alpha
#macro COL_TAB_INACTIVE   #5A4D36   // inactive tab text (COL_INK_SECONDARY)

// ─── TAGS / CHIPS ────────────────────────────────────────────
#macro COL_TAG_BG         #785F37   // plain tag background
#macro COL_TAG_BG_ALPHA   0.16      // plain tag background alpha
#macro COL_TAG_BORDER     #B6A079   // plain tag border (COL_LINE)
#macro COL_TAG_TEXT       #4A3D28   // plain tag text

// Quirk tags (purple-tinted)
#macro COL_QUIRK_BG       #7A3AA8
#macro COL_QUIRK_BG_ALPHA 0.14
#macro COL_QUIRK_BORDER   #B79AD0
#macro COL_QUIRK_TEXT     #5E2F86

// Upgrade tags (gold-tinted)
#macro COL_UPGRADE_BG     #8A6A25
#macro COL_UPGRADE_BG_ALPHA 0.16
#macro COL_UPGRADE_BORDER #A08A55   // (COL_GOLD_DIM)
#macro COL_UPGRADE_TEXT   #6F5418

// ─── RESOURCE COLOURS (spendable) ────────────────────────────
#macro COL_CASH           #9C6F14   // Cash — dark gold/amber
#macro COL_LUST           #B5305F   // Lust — deep rose/crimson
#macro COL_HUMILIATION    #BD5217   // Humiliation — burnt orange
#macro COL_INFLUENCE      #34549E   // Influence — muted blue

// ─── RESOURCE COLOURS (scores, never spent) ──────────────────
#macro COL_VALUE          #1D8A93   // Value — teal
#macro COL_POWER          #7A3AA8   // Power — purple
#macro COL_STOCK          #3C8A46   // Stock — green

// Resource chip backgrounds (colour at ~13% alpha over parchment)
#macro COL_CASH_BG              #9C6F14
#macro COL_LUST_BG              #B5305F
#macro COL_HUMILIATION_BG       #BD5217
#macro COL_INFLUENCE_BG         #34549E
#macro COL_VALUE_BG             #1D8A93
#macro COL_POWER_BG             #7A3AA8
#macro COL_STOCK_BG             #3C8A46
#macro COL_CASH_BG_ALPHA        0.13
#macro COL_LUST_BG_ALPHA        0.13
#macro COL_HUMILIATION_BG_ALPHA 0.13
#macro COL_INFLUENCE_BG_ALPHA   0.13
#macro COL_VALUE_BG_ALPHA       0.13
#macro COL_POWER_BG_ALPHA       0.13
#macro COL_STOCK_BG_ALPHA       0.13

// ─── STATUS / STATE ──────────────────────────────────────────
#macro COL_BLOCKED        #A8402F   // "blocked" text (reddish-brown)
#macro COL_CAN_CLEAR      #3C8A46   // "✓ can clear" (COL_STOCK green)
#macro COL_LOCKED_ALPHA   0.5       // opacity for locked/potential rows

// ─── BUTTONS / SLOTS ─────────────────────────────────────────
#macro COL_BTN_BG         #FFFAEE   // secondary button fill
#macro COL_BTN_BG_ALPHA   0.4       // secondary button fill
#macro COL_BTN_BORDER     #B6A079   // (COL_LINE)
#macro COL_BTN_TEXT       #3F3524   // (COL_INK_NEIGHBOUR)

// Primary button (gold gradient)
#macro COL_BTN_PRI_TOP    #A9862F   // top of gradient
#macro COL_BTN_PRI_BOT    #8A6A25   // bottom of gradient (COL_GOLD)
#macro COL_BTN_PRI_BORDER #6F5418   // border
#macro COL_BTN_PRI_TEXT   #FDF6E3   // cream text on gold

// ─── PROGRESS BAR (Reclamation) ──────────────────────────────
#macro COL_BAR_BG         #3C2D19   // track background
#macro COL_BAR_BG_ALPHA   0.18      // track background
#macro COL_BAR_BORDER     #B6A079   // (COL_LINE)
#macro COL_BAR_FILL_L     #A9862F   // fill gradient left
#macro COL_BAR_FILL_R     #C7A23E   // fill gradient right

// ─── THUMBNAILS / BUSTS (header icons) ───────────────────────
#macro COL_THUMB_BORDER   #8A6F42   // border on room thumbnail / minion bust
#macro COL_THUMB_BG_L     #CAA46E   // radial gradient light centre (room thumb)
#macro COL_THUMB_BG_R     #9C7A45   // radial gradient edge (room thumb)
#macro COL_BUST_BG_L      #BDA98A   // radial gradient light (minion bust / obstacle)
#macro COL_BUST_BG_R      #8A7455   // radial gradient edge

// ─── DESK / PAGE SURROUND (behind the panel, on dark bg) ─────
#macro COL_DESK           #2B241C   // dark surround framing the parchment
