**Product Requirements Document (PRD)**

**Project Title:** Crypts of the Forgotten

**Project Type:** Top-down 2D Multiplayer Dungeon Crawler / Roguelike

**Platform:** PC (Primary), HTML5 export capability

**Engine:** Godot 4.4.1

**Language:** GDScript

**Target Audience:** Fans of co-op action games, roguelikes, and dungeon crawlers; ages 13+

**Technical Specifications:**
- **Players:** 1-4 (Online multiplayer, peer-to-peer with one player hosting)
- **Target Performance:** 60fps (30fps fallback if needed for latency optimization)
- **Networking:** Godot's built-in multiplayer API
- **Architecture:** Real-time synchronization of positions, health, inventory, actions

---

### **1. Objective**
To build a multiplayer dungeon crawler featuring:
- Real-time co-op gameplay (1–4 players online)
- 7-level progression system with escalating difficulty
- Diverse enemy types with multiple skeleton variants
- Elite enemies, witch mini-bosses, and final witch boss
- Balanced character archetypes with unique abilities
- Meaningful progression systems (temporary and permanent)

---

### **2. Core Gameplay Loop**

**Level Progression System:**
Players progress through **7 levels** with increasing difficulty:

1. **Level 1-2: Basic Caves**
   - Environment: Cave tilesets
   - Enemies: Basic skeletons + variants
   - Boss: Elite enemy (stronger skeleton variant)

2. **Level 3-4: Catacombs**  
   - Environment: Catacomb tilesets
   - Enemies: More skeleton variants + additional enemy types
   - Boss: Weaker witch mini-bosses

3. **Level 5-6: Crypts**
   - Environment: Crypt tilesets  
   - Enemies: Harder elite enemies + mixed enemy types
   - Boss: Harder elite enemies

4. **Level 7: Witch Castle**
   - Environment: Castle tileset
   - Enemies: Elite minions + spawned enemies
   - Boss: Final witch boss with phase system (spawns previous bosses)

**Run Structure:**
- Each run = complete 7-level progression
- Escalating difficulty with better rewards
- Permanent progression between runs
- Temporary upgrades reset each run

---

### **3. Character System**

#### **4 Diverse Archetypes** (Balanced but Unique)
Characters selected from 32rogues asset pack themes:
- **Wizard/Mage:** Magic-based attacks, area effects
- **Barbarian/Fighter:** Heavy melee, high damage
- **Rogue/Assassin:** Speed, stealth abilities  
- **Knight/Paladin:** Defensive, support abilities

**Character Balance Approach:**
- Each character excels against certain enemy types
- Enemy design ensures no character is universally stronger
- Bosses challenging for all characters
- Unique playstyles encourage different strategies

**Character Abilities:**
- **2 Unique Combat Abilities** per character
- **Dash/Dodge Mechanic** (universal)
- **Third Ability** unlocked through permanent progression
- **Character-Specific Upgrade Trees**

---

### **4. Enemy Design & Variety**

#### **Skeleton Variants** (Primary Enemy Type)
- **Skeleton Grunt:** Basic melee
- **Skeleton Archer:** Ranged attacks
- **Skeleton Guard:** Shield/tank behavior
- **Skeleton Bomber:** Suicide/explosive attacks
- **Elite Skeletons:** Enhanced variants for boss encounters

#### **Additional Enemy Types**
- Sourced from available asset packs
- Custom-created enemies matching pixel art style
- Visually and thematically consistent
- Varied attack patterns and behaviors

#### **Boss Progression**
- **Elite Enemy Bosses (Levels 1-2):** Enhanced skeleton variants
- **Witch Mini-Bosses (Levels 3-4):** Weaker witch variants with minion spawning
- **Elite Enemy Bosses (Levels 5-6):** Harder elite variants
- **Final Witch Boss (Level 7):** Multi-phase, spawns previous bosses as minions

---

### **5. Progression Systems**

#### **Temporary Upgrades (Per Run)**
- **Weapons:** Enhanced damage, special effects
- **Armor:** Damage reduction, special properties
- **Powerup Abilities:** Invisibility, speed boost, etc.
- **Relics & Scrolls:** Unique effects and bonuses
- **Significance:** More substantial power increases

#### **Permanent Upgrades (Soul XP)**
- **Stat Improvements:** Health, attack, speed (subtle buffs)
- **Ability Unlocks:** Third ability per character
- **Character Enhancement Trees:** Branching upgrade paths
- **Significance:** Subtle, long-term progression

---

### **6. Multiplayer Architecture**

#### **Online Multiplayer Features**
- **Peer-to-Peer Networking:** One player hosts
- **Real-time Synchronization:** Position, health, inventory, actions
- **Connection Handling:** Player join/leave, disconnection recovery
- **Revive System:** Downed ally revival mechanics
- **Shared Progression:** Coordinated upgrade collection

#### **UI Components**
- **Main Menu:** Host game, join game options
- **Character Selection:** Visual preview, ability descriptions
- **Lobby System:** Player ready states, host controls
- **In-Game HUD:** Health, abilities, inventory, multiplayer status

---

### **7. Technical Architecture**

#### **Core Systems**
- `Main.gd` - Game loop controller and state management
- `NetworkManager.gd` - Multiplayer synchronization and connection handling
- `DungeonGenerator.gd` - Procedural level generation
- `Player.tscn` - Character controller with combat and networking logic
- `Enemy.tscn` - Base enemy class with state machine AI
- `BossWitch.tscn` - Specialized boss AI with phases and minion spawning

#### **Scene Structure**
- `MainMenu.tscn` - Main menu with multiplayer options
- `CharacterSelect.tscn` - Character selection with ability preview
- `GameWorld.tscn` - Main gameplay scene with level management
- `LevelManager.tscn` - Level progression and boss encounter handling

#### **AI Systems**
- **Enemy State Machines:** Patrol, Chase, Attack, Die, Special
- **Boss AI:** Multi-phase behavior, minion spawning, spell casting
- **Pathfinding:** Navigation for enemy movement and player targeting

---

### **8. Asset Creation Guidelines**

#### **Visual Style**
- **Pixel Art Consistency:** Match existing 32rogues and skeleton sprites
- **Color Palette:** Maintain spooky, dungeon aesthetic
- **Thematic Coherence:** All assets fit cave/dungeon/castle theme

#### **Asset Types to Create**
- **Powerup Icons:** Simple but consistent with game style
- **Additional Enemies:** If needed for variety
- **Environmental Elements:** Backgrounds, decorative objects
- **UI Elements:** Buttons, frames, HUD components

---

### **9. Development Timeline (7 Days)**

**Day 1-2: Research & Learning Phase**
- Godot 4.4.1 multiplayer system research
- Character ability design based on sprite analysis
- Network architecture planning
- Proof-of-concept multiplayer demo

**Day 3-4: Core Development Phase**
- Character implementation with abilities
- Enemy AI and variant creation
- Basic level generation and connectivity
- Combat system and hitbox implementation

**Day 5: Advanced Systems**
- Boss AI implementation (elite enemies, witch mini-bosses)
- Progression systems (temporary and permanent)
- Level progression and difficulty scaling
- Multiplayer synchronization refinement

**Day 6: Polish & Integration**
- Final witch boss with phase system
- UI/UX implementation and refinement
- Performance optimization
- Asset creation for missing elements

**Day 7: Testing & Finalization**
- Multiplayer stress testing
- Bug fixes and balancing
- Documentation and demonstration preparation
- Final polish and optimization

---

### **10. Success Criteria**

#### **Technical Achievement**
- Stable online multiplayer for 1-4 players
- 60fps performance with low latency
- Complete 7-level progression system
- Functional boss encounters with phases

#### **Gameplay Quality**
- Engaging combat with character variety
- Meaningful progression systems
- Challenging but fair boss encounters
- Smooth multiplayer experience

#### **Development Process**
- Effective AI-accelerated learning and development
- Rapid adaptation to Godot 4.4.1 systems
- Efficient asset creation and integration
- Comprehensive documentation of AI utilization

---

### **11. Quality Assurance**

#### **Testing Priorities**
1. **Multiplayer Stability:** Connection handling, synchronization
2. **Combat Balance:** Character abilities, enemy difficulty
3. **Progression Systems:** Upgrade mechanics, save/load
4. **Performance:** Frame rate, memory usage, network latency
5. **Boss Encounters:** AI behavior, phase transitions, minion spawning

#### **Performance Targets**
- **Frame Rate:** 60fps (30fps minimum)
- **Network Latency:** <100ms for responsive multiplayer
- **Memory Usage:** Efficient asset loading and management
- **Load Times:** <5 seconds between levels

---

### **12. Development Priorities**

1. **Combat System:** Fun, engaging combat with character differentiation
2. **Enemy Variety:** Multiple enemy types to maintain engagement
3. **Character Balance:** Unique abilities while maintaining fairness
4. **Boss Encounters:** Challenging, memorable boss fights
5. **Progression:** Meaningful temporary and permanent upgrades
6. **Multiplayer:** Stable, low-latency online experience

---

**Final Note:** This project demonstrates AI-accelerated game development, showcasing the ability to rapidly learn new technologies (Godot 4.4.1) and deliver a polished, production-quality multiplayer game within a 7-day timeframe. No features from this specification should be cut - all elements contribute to the core vision of an engaging, challenging dungeon crawler roguelike.

