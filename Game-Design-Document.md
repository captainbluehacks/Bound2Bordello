***

# PROJECT MASTER CONTEXT: "Bound to the Bordello" (v2.0)

## 1. High-Level Concept
**Genre:** Base Builder / Management Sim / Dark Comedy Horror.
**Premise:** A young man makes a greedy wish for wealth and women. A demon ironically grants this by transforming him into a succubus and binding them to an abandoned mansion. To win their freedom, the player must transform the ruin into the premier whorehouse in the region and reach specific narrative milestones.
**Setting:** A small town in America 1969.
**Tone:** Dark Humour, Gothic Horror, Ironic Twist.

## 2. Core Game Loop (Day/Night Cycle)
### Day Phase (Management & Planning)
*   **Building:** Vertical "Dollhouse" construction. Rooms are placed on floors; adjacent (vertical / horizontal) placement creates synergies (buffs/penalties).
*   **Personnel Management:** Assigning minions to rooms.
*   **Minion Upgrades:** Purchasing data-driven upgrades for minions (grants tags). Available any time during the Day Phase as long as resources remain. See [`MINION_STATE_SPEC.md`](MINION_STATE_SPEC.md) § Minion Upgrades.

### Night Phase (Operation & Hunting)
*   **The Funnel:** Clients arrive at the **House**. They will select **chambers** according to their preferences.
*   **Production:** Each **chamber** produces a particular resource assuming its requirements are met.
*   **The Hunt:** The player can escort a selected guest into a room tagged as private to convert them into a minion. Conversions require a room carrying the **Private** tag — public spaces such as The Bar cannot host them. Which Private room is used determines the Mana discount via preference-tag matching (§7 Conversion Cost); a mismatched Private room costs full price.
*   **Strategic Tension:** *Immediate profit (Money/Mana) vs. Exponential growth (New Minions).*

### End of Cycle (The Reckoning)
*   **Rewards:** Check if player has met any criteria for achievements / rewards.
*   **Next Day's Visitor List:** At the end of each cycle, build tomorrow night's visitor list — roll each guest's visit frequency (§7 Visit Frequency), excluding converted guests and applying the seasonal pool shift.

### Cycles per season
Each season will have 12 cycles (~1 per week). This is subject to tuning through playtest.

## 3. World Architecture & Perspective
*   **Visual Style:** Diegetic Paper-Doll. The game is presented as a physical, layered diorama. All UI elements (menus, buttons, resource bars) are rendered as "cutouts" of parchment, cardstock, and ink.
*   **Tactile Feedback:** Interaction should feel physical. Menus don't "pop up"; they slide in like cards or unfold like maps. Buttons "depress" into the background rather than glowing.
*   **Management View (The Dollhouse):** Vertical side-cutaway perspective (Basement -> Ground -> Upper Floors -> Attic).
*   **Interaction View:** Atmospheric scenes for The Hunt, Ally negotiations, and Signature Room events.
**Verticality Mechanics:**
*   **Zoning:** Certain rooms are restricted to specific floors (e.g., "Forbidden" in basement, "Luxury" on upper floors).
*   **Synergies:** Rooms exert effects on those directly above, below, left or right of them (e.g., a Basement Morgue may increase Fear production in the room above).

## 4. Resource Economy & The Mana Prism
### Primary Resources:
*   **Value:** Represents the cash value of the mansion.
*   **Power:** Represents the magical value of the mansion.
*   **Stock:** Represents the social value of the mansion.

Primary resources gate the end of season choices. Balancing these creates a spatial puzzle: players must optimize room placement to trigger high-value synergies while managing competing resource requirements for each floor.

### Secondary Resources:
*   **Cash:** Currency for building, bribes, and taxes.
*   **Mana (The Magic Resource):** A top-level energy divided into three "flavors." While often interchangeable, specific tasks are gated by flavor.
    *   **Lust Mana:** Generated via Seduction/Luxury. Used for high-end upgrades and "Devoted" minions.
    *   **Humiliation Mana:** Generated via Degradation. Used for power upgrades and "Broken" minions.
    *   **Fear Mana:** Generated via Terror. Used for security upgrades and "Terrified" minions.
*   **Influence:** The ability to influence the surrounding areas. Used for high end upgrades, building permits etc.

## 5. Friends
### The Draft (Prologue)
*   Three friends take part in the initial ritual that summons the demon. When it appears, all three flee; only the player remains to make their foolish deal.
*   At the start of each playthrough, **3 of 4 archetypes are randomly drafted** as this run's friend cast — one gateway ally stays "cold" every run (pool may be expanded beyond 4 for identity variety).
*   During the prologue, the player **nominates which friend is their best friend**. This is the first real strategic decision of the game.

### Archetype Table
Each archetype maps 1:1 to one Ally gateway. Their bonus makes the associated score threshold easier to reach; as a minion they carry a matching Quirk and upkeep flavor. (*Bold* = confirmed, *italics* = open decision.)

| Archetype | Persona | Bonus (as Friend) | Mapped Ally | Minion Quirk / Upkeep |
|---|---|---|---|---|
| **The Morbid** | Obsessed with death | **Fear Mana boost** | **Necromancer** | Terrified; *upkeep flavor TBD* |
| ***The Nerd*** | Science nerd | Immunity to degradation tags — the Nerd never accumulates negative tags from room assignment, and any other minion she shares a room with is likewise protected for that night. While present in a facility's rooms, those facilities' subjects do not degrade | **Mad Scientist** | Broken; *candidate quirk: requires converted humans available as experiments* |
| **The Cultist** | Low-level member of a cult | Influence bonus | Cult Leader | Devoted/Broken; *upkeep flavor TBD* |
| **The Farmer** | Interested in aliens | Money + livestock — enables buying the Cow Shed to lure out the Aliens | Aliens | *Candidate quirk: demands fresh cows be delivered monthly (flavored upkeep)* |

### Friend Roles Across the Seasons
1.  **Spring:** The **best friend** returns to investigate what happened, finds the ruin transformed and the player changed — converted into the first minion via a scripted Interaction View event (a relationship negotiation, *not* the generic Hunt pipeline).
2.  **Summer:** The player can **lure a second friend** to the mansion and convert them into an "upgraded" minion. Candidate mechanic: high enough town Influence lets the player make an offer (a job, a debt, a rumor) that draws a specific archetype in — which flavor of influence spent may determine *who* shows up.
3.  **Autumn:** The **last friend** is now working against the player alongside their associated ally (the mapping above makes this fall out naturally). Successfully capturing them grants additional bonuses; if their capture disables or weakens that ally, it becomes a real trade-off (to decide).
4.  **Winter:** Friends are valid sacrifices to the demon — more impactful than sacrificing an asset-ally, since friends cost identity rather than capability. Sacrifice must retract any ongoing game-system effects they contributed (Section 6 effect schema). Open: do allies remain as sacrificeable options alongside/instead of friends?

### Balance Guardrail
A bad draft (e.g., no Fear archetype) must never hard-softlock a strategy: the demon's deal itself should grant baseline progress toward all four gates, so friend bonuses are **accelerants, not prerequisites**. Alternately or additionally, each ally needs a secondary, slower gate path.

## 6. Room Specifications
### Utility & Production Rooms:
*   **Inner Sanctum:** A private room which grants access to additional succubus abilities.
*   **The Bar:** Allows one minion to deal with multiple clients
*   **Dormitory:** Minion recovery. Removes tags from the minion's tag list (oldest first). Can hold multiple minions (occupancy > 1). Adds positive tags based on upgrades.
*   **The Boudoir:** The primary engine. Modular upgrades (e.g., strap-ons, gags) determine which flavor of Mana is produced.

### Ally Gateway Rooms (Phase 1 Goals):
*   **Morgue/Graveyard -> Necromancer.**
*   **Basic Lab -> Mad Scientist.**
*   **Ritual Room/Secret Meeting Place -> Cult Leader.**
*   **Cow Shed -> Aliens.**

### Room tags
Rooms will have tags (*luxury*, *private*, *dungeon*, etc). These will be used to determine synergies and other effects. 

## 7. Minions
### Conversion:
Humans are converted using Mana + Sexual Energy. The flavor of mana used during conversion determines the minion's "Quirk" (Devoted, Broken, or Terrified).
* **Forfeited production.** The conversion consumes that guest's night: they generate no Secondary resources that cycle. Converting therefore costs Mana *plus* one night of that client's income, reinforcing the fixed-pool trade-off (§Guest Pool).

### Conversion Templates
The player selects **one** conversion template per conversion event. Templates are data-driven (JSON) and define:
- The narrative result (`conversion_text` prepended to history).
- Tags added to the new minion (including the quirk tag).
- Tags removed from the guest's existing tags if present (prevents contradictions, e.g., a "broken" minion shouldn't be "happy").
- Resource cost and availability gating (rooms built, allies secured).

See [`MINION_STATE_SPEC.md`](MINION_STATE_SPEC.md) § Conversion Templates for full schema.

### Guest Pool (Fixed)
*   **Minions are mostly converted guests.** The guest pool is generated at the start of the playthrough, not each night. Converting a guest permanently removes them from the resource-generating pool — every minion gained is income you will never earn again.
*   **Seasonal visitor pools:**
    *   **Spring:** Local village (vanilla desires).
    *   **Summer:** Player chooses one of two nearby towns; its visitors arrive that season.
    *   **Autumn:** The second town's visitors arrive.
    *   **Winter:** Visitors from the city.
*   **Town bias:** Each town has a pool of tags randomly allocated across its guests, so towns lean in particular directions (making the Summer choice a mechanical bet as well as an identity one).
*   **Pool sizes:** The village starts at ~6 guests against the usable first-floor rooms. Local population size is a candidate difficulty-scaling mechanic (parked for now; flat pools preferred until playtest).

### Visit Frequency
*   Guests do not arrive every night. Each has a **base number of visits per season**, plus an **affinity bonus** (+1–2 visits) when their preference tags match available rooms. Mismatched guests visit rarely — creating scarcity windows, so conversion timing matters per-guest (convert during the right window for a discounted cost, or bank their income nights first).

### Preferences & Backgrounds
*   **Preference tags:** Clients carry preference tags (e.g., a dominant client won't want to be tied up). Room tags therefore serve two roles: minion assignment compatibility *and* guest preference satisfaction.
*   **Backgrounds:** Each guest has a random background with no base mechanical effect, giving the player story material (the bishop who shouldn't be here, the virgin, the wife-beater…). Backgrounds are stored in JSON (`datafiles/backstories.json`) and randomly assigned when the guest pool is generated. At conversion, the backstory is copied to the minion and forms part of their first history entry.
*   **Influence buys knowledge:** Spending Influence reveals a guest's background and preferences — which also carries a mechanical effect: it reduces that specific client's conversion cost.

### Conversion Cost
*   Converting a client costs a large amount of temporary Mana (base ~40).
*   Each appropriate tag match between the room (and its upgrades) and the client's preferences reduces the cost — up to 2 tags. Example: a client tagged *dominant* + *violent* converted in the Sex Dungeon with the whip upgrade costs 20 instead of 40; converting them without an appropriate room costs full price.
*   Background knowledge (above) applies as a further personal discount on that specific client.

### Naming
*   **Guest names:** Drawn randomly from a JSON name pool (`datafiles/names/guest_names.json`) when the guest pool is generated. No duplicates within a pool.
*   **Minion names:** At conversion, the player picks 1 of 3 randomly selected names from `datafiles/names/minion_names.json`. The original guest name is retained for reference.

### Subjects & the Tag State Machine: 
Minions and rooms carry tags, applied at night resolution based on room assignment. All minion tags live in a **single flat array** — there is no positive/negative categorisation. Effects are triggered by tag presence; context (the room, the client, the effects table) determines whether a tag helps or hinders.

Assigned to a compatible facility (e.g., a Science Lab), a subject accumulates degradation tags over successive nights (experimented → degraded → scarred). At terminal severity the subject is lost (culls, flees, or requires major restoration). All four allies operate this way with distinct flavor:

- **Mad Scientist / Science Lab**: test subjects; "limbs replaced" progression.
- **Cult Leader:** zealots burn out and must be re-converted or new recruits made.
- **Necromancer:** thralls crumble to dust after enough nights of service.
- **Aliens:** cattle/abductees age, escape, or are consumed by the specimens.

The Nerd (Section 5) is the exception: her presence halts tag accumulation for herself and any minion sharing her room.

### Minion Upgrades
Data-driven purchases available during the Day Phase. Grant tags to the minion (specific effects are a later addition). Gated by existing tags on the minion, rooms available in the mansion, and/or quirk compatibility. First pass: a simple list; a draft/pick mechanic is planned for a later stage.

See [`MINION_STATE_SPEC.md`](MINION_STATE_SPEC.md) § Minion Upgrades for full schema.

### History & Appearance
*   **History:** Each minion carries a flavour log (`history` array). Updated by conversion (always first), terminal events, upgrades, story beats, and random room-based assignments. Entries are flavour only — mechanical effects are driven by tags, not history text.
*   **Appearance:** The minion's sprite is selected from available art based on their current tag list. Recomputed whenever tags change.

### Design Constraints
*   **No roaming minions.** Every minion must be assigned to a room at all times. If no productive task is available, assign to a Dormitory or reclamation obstacle.
*   **Minion cap.** Max minions = guest pool size + converted friends. No other source of minions exists.
*   **No orphan handling.** Rooms cannot be destroyed, so minion→room references never dangle due to room removal.

## 8. Narrative Progression (The Four Seasons)
1.  **Spring: The Hustle (Survival):** Establish base, survive taxes, and build the specific room required to secure the first Ally.
2.  **Summer: The Manager (Growth):** Scale operations, gain access to second floor, and attract a second Ally.
3.  **Autumn: The Empire (The Crisis):** gain access to third floor; choose objectives based on current Allies/Resources.
4.  **Winter: The Ascension (Finale):** Final choice—sacrifice allies to the demon for freedom or conquer the demon to take their place, or fail and be taken to hell.

## 9. Technical Implementation
*   **Engine:** Game Maker.
*   **Key Systems:** State Machine (Day/Night), Vertical Grid System, Resource Manager (Mana Prism logic).
*   **UI Architecture:**
    * **Layering System:** The UI will utilize a "Z-depth" approach to mimic paper layers. Use the Draw GUI event with slight Y-offsets and linear interpolation (lerp) for smooth, physical movement when elements are interacted with, avoiding 'snappy' digital transitions.
    * **Asset Pipeline:** All UI assets are generated as flat, high-contrast cutouts to be manipulated via GML code (scaling/rotating) rather than pre-baked animations, maintaining the "puppet" feel.

## 10. Environmental Progression & Reclamation
*   **The Ruin State:** The mansion begins as a series of fragmented, usable zones surrounded by blockages.
*   **Reclamation Tiers:** Expansion is gated by minion capabilities (Clutter -> Rubble -> Hazards -> Seals). Higher tiers require specific tags on the assigned minion (data-driven via `requires_tags` in the obstacle's `reclaim` block).
*   **Spatial Pacing:** New floors are unlocked via narrative phases, but the *usable area* within those floors is expanded through active reclamation.
*   **Reclaiming a Room:** The player assigns a minion to the blocked zone (a normal assignment). Each night they entice their guests into clearing the room for them (a succubus doesn't do her own manual labor). Clearing takes multiple nights, scaled by the Reclamation Tier; tags and upgrades can reduce this duration.
*   **The Reclamation Trade-off:** A room being reclaimed produces nothing for its guests or minion that night — the same applies to rooms under upgrade. This creates a direct tension between immediate operational profit and long-term infrastructure growth.

## 11. Future Features

Items identified as needed but not yet designed in detail:

*   **Save System:** The game will need a save/load system. Scope, format (JSON snapshot vs. serialised instance state), save frequency (per-cycle? manual?), and cloud/local storage approach are all open. To be designed once core systems are stabilised.
*   **Tag Effects Table:** A data-driven table mapping each tag ID to its mechanical effects (production modifiers, assignment restrictions, client value bonuses, etc.). Currently tags are applied/removed by the state system but their gameplay effects are ad-hoc. Will become a formal `tag_effects.json` or equivalent.
*   **Upgrade Draft Mechanic:** Replace the flat minion-upgrade list with a pick-N-of-M draft selection for more strategic depth. Data schema unchanged; UI/flow change only.
*   **Minion Upgrade Specific Effects:** Beyond tag-granting, upgrades may carry direct mechanical effects (e.g., reduce progression track duration by 1 night, add a flat resource bonus). Schema extension to `minion_upgrades.json`.
