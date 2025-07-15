# ForgottenCrypts

# Crypts of the Forgotten

A top-down 2D multiplayer dungeon crawler built in Godot 4.4.1 using GDScript. This project is part of the Game Week challenge - building a polished, production-quality multiplayer game in 7 days using AI-accelerated development.

## Project Overview

**Genre**: Top-down 2D Multiplayer Dungeon Crawler / Roguelike  
**Platform**: PC (Primary), HTML5 export capability  
**Engine**: Godot 4.4.1  
**Language**: GDScript  
**Players**: 1-4 (Online multiplayer, one player hosting)  
**Target Performance**: 60fps (30fps fallback if needed for latency)  

## Core Gameplay Loop

Players explore through **7 progressively difficult levels**, each ending with a boss encounter, culminating in a **witch castle final boss level**:

1. **Levels 1-2**: Basic caves with elite enemy bosses
2. **Levels 3-4**: Catacombs with weaker witch mini-bosses  
3. **Levels 5-6**: Crypts with harder elite enemies
4. **Level 7**: Witch castle with final witch boss (spawns previous bosses in phases)

**Run Structure & Pacing:**
- **Target Duration**: 40 minutes for skilled players (challenging but achievable)
- **Level Selection**: Player choice between level types when possible
- **Rest Areas**: Healing/safe zones after each boss encounter
- **Variation**: Each run through same level type is procedurally different
- **Boss Variety**: Some variation in boss types and encounters
- **Environmental Variety**: Engaging visual differences without affecting difficulty

Each run features escalating difficulty with better upgrades/abilities as rewards.

## Character System

**4 Diverse Archetypes** (balanced but unique):
- Characters designed around available sprite themes
- Each has 2 unique combat abilities + dash/dodge
- Third ability unlocked through progression
- Character-specific upgrade trees
- Balanced through enemy design (some enemies harder for certain characters)

## Enemy Design

**Variety & Progression**:
- Multiple skeleton types (grunt, archer, guard, bomber)
- Additional enemies from available asset packs
- Elite variants of standard enemies
- Witch mini-bosses (levels 3-4)
- Final witch boss with minion spawning + phase system

## Progression Systems

**Temporary (Per Run)**:
- Weapons, armor, powerup abilities (invisibility, etc.)
- Relics and scrolls
- More significant power increases
- **Individual Loot Drops**: Each player finds their own temporary upgrades
- **Rare Second Life Powerup**: Prevents death once per run (uncommon)
- **Lost on Death**: All temporary upgrades lost when player dies

**Permanent (Soul XP)**:
- Subtle improvements (health, attack buffs)  
- Unlock third abilities
- Character enhancement trees
- **Shared Between Players**: All players gain Soul XP collectively
- **Persistent**: Saved between runs and recoverable after disconnection
- **No Checkpoints**: All-or-nothing run completion for progression

## Death & Revival System

**Single Player**:
- Death requires full run restart
- Rare second life powerup provides one extra chance

**Multiplayer**:
- Dead players remain dead until level boss is defeated
- **Rare NPC Resurrector**: Uncommon NPC that can revive fallen comrades
- **Revival Options**: Boss defeat automatically revives all dead players
- **Death Penalty**: Loss of all temporary upgrades/powerups
- **Shared Risk**: Team success depends on keeping players alive

## Technical Architecture

**Multiplayer**: 
- Online multiplayer using Godot's built-in networking API
- Peer-to-peer (one player hosts)
- Real-time synchronization of positions, health, inventory, actions
- **Connection Handling**: Players can only join at run start, can rejoin if disconnected
- **AI/Bot Replacements**: For testing and filling party slots
- **NPC Companions**: Recruitable allies that assist for the duration of their level
- **Difficulty Scaling**: More enemies + increased spawn frequency with more players
- **Boss Scaling**: Bosses gain more health, damage, and minion spawns with more players

**Game Systems**:
- Procedural cave/dungeon generation using available tilesets
- State machine enemy AI (Patrol, Chase, Attack, Die)
- Hitbox/collision-based combat
- Boss AI with spells, summoning, and phases

## Asset Information

**Included Assets**:
- 32rogues character pack (diverse rogue archetypes)
- Skeleton enemy sprites (complete animation sets)
- Blue witch boss sprites (attack, charge, death, idle, run, damage)
- Cave/dungeon tilesets (MainLev2.0, Kenney dungeons)
- Environmental props (torches, candles, spikes, decorative elements)

**Asset Creation Guidelines**:
- Match existing pixel art style
- Maintain visual and thematic consistency
- Powerups can be slightly simpler than character sprites
- All assets should fit the spooky cave/dungeon aesthetic

## Development Framework (7 Days)

**Day 1-2: Research & Learning Phase**
- Godot 4.4.1 multiplayer systems
- Architecture planning
- Proof-of-concept demos
- Character ability design

**Day 3-5: Core Development Phase**
- Single-player mechanics
- Multiplayer integration
- Enemy AI implementation
- Procedural generation

**Day 6-7: Polish & Testing Phase**
- Progression systems
- UI/UX improvements
- Stress testing
- Bug fixes and optimization

## Development Priorities

1. **Combat System**: Fun, engaging combat with character variety
2. **Enemy Variety**: Multiple enemy types to avoid repetition
3. **Character Balance**: Unique but balanced archetypes
4. **Boss Encounters**: Challenging, engaging boss fights
5. **Progression**: Meaningful temporary and permanent upgrades

## Key Features

- **Real-time Co-op**: 1-4 players online
- **Procedural Generation**: Connected cave/dungeon rooms
- **Character Progression**: Temporary and permanent upgrades
- **Boss Battles**: Elite enemies and witch bosses with phases
- **Multiplayer UI**: Main menu, character selection, lobby system
- **Performance**: Smooth 60fps gameplay with low latency

## Setup Instructions

1. Ensure Godot 4.4.1 is installed
2. Clone repository
3. Open project in Godot
4. Run main scene for testing

## License

Assets used under respective licenses (see individual asset folders for details).
Project code available under MIT license.

---

*This project demonstrates AI-accelerated game development, building a complete multiplayer dungeon crawler in 7 days using modern game development tools and techniques.*
