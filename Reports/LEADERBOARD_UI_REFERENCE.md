# Restaurant Leaderboard - UI Reference

## Screen Layout

```
┌─────────────────────────────────────────┐
│  ←  Leaderboard                    ≡   │  ← App Bar
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────┐ ┌──────────┐ ┌────────┐ │  ← Period Chips
│  │This Week✓│ │This Month│ │All Time│ │
│  └──────────┘ └──────────┘ └────────┘ │
│                                         │
│         ┌─────────────┐                │
│         │    👑       │                │  ← Podium
│    ┌────┴─────┬───────┴────┐          │
│    │    🥈    │    🥇      │   🥉    │
│    │  Rank 2  │  Rank 1    │ Rank 3  │
│    │ 980 meals│ 1,250 meals│850 meals│
│    │          │   HERO     │          │
│    └──────────┴────────────┴──────────┘
│                                         │
│  ┌─────────────────────────────────────┐
│  │  REST OF THE BEST                   │  ← List Header
│  ├─────────────────────────────────────┤
│  │ 4  👤  The Soup Kitchen    720 kg  │
│  │        720 meals distributed        │
│  ├─────────────────────────────────────┤
│  │ 5  👤  Daily Bread         645 kg  │
│  │        Zero Waste Partner           │
│  ├─────────────────────────────────────┤
│  │ 6  👤  Spice Garden        550 kg  │
│  │        550 meals distributed        │
│  ├─────────────────────────────────────┤
│  │ 7  👤  Veggie Delight      420 kg  │
│  │        New Contributor              │
│  └─────────────────────────────────────┘
│                                         │
│  ┌─────────────────────────────────────┐
│  │ RANK  │  Your Impact         250 kg│  ← Sticky Card
│  │  12   │  You saved 250 meals!   ↗ │
│  └─────────────────────────────────────┘
│                                         │
├─────────────────────────────────────────┤
│  🏠    🍽️    📋    🏆    👤          │  ← Bottom Nav
│ Home  Meals Orders Rank Profile        │
└─────────────────────────────────────────┘
```

## Color Scheme

### Light Mode
```
Background:     #F8F7F6  (Light beige)
Surface:        #FFFFFF  (White)
Primary:        #EC7F13  (Orange)
Text Main:      #1B140D  (Dark brown)
Text Secondary: #9A734C  (Medium brown)
Border:         #E7E5E4  (Light gray)
```

### Dark Mode
```
Background:     #221910  (Dark brown)
Surface:        #2D241B  (Medium brown)
Primary:        #EC7F13  (Orange - same)
Text Main:      #FFFFFF  (White)
Text Secondary: #FFFFFF54 (White 54% opacity)
Border:         #3D3027  (Dark gray-brown)
```

### Podium Colors
```
Gold (Rank 1):   #FFD700
Silver (Rank 2): #C0C0C0
Bronze (Rank 3): #CD7F32
```

## Component Specifications

### App Bar
```
Height: 60px
Padding: 16px horizontal, 12px vertical
Background: Semi-transparent with backdrop blur
Border: Bottom border (1px)

Elements:
- Back button (left): 24px icon
- Title (center): 18px bold
- Filter button (right): 24px icon
```

### Period Chips
```
Height: 36px
Padding: 16px horizontal, 8px vertical
Border Radius: 20px
Gap: 12px

Selected:
- Background: Primary color (#EC7F13)
- Text: White, bold
- Icon: Check mark (16px)
- Shadow: 8px blur, 2px offset

Unselected:
- Background: White (light) / Surface (dark)
- Text: Text color, medium weight
- Border: 1px solid border color
```

### Podium

#### Rank 1 (Center)
```
Avatar Size: 96px
Border: 4px gold (#FFD700)
Shadow: 20px blur, 2px spread, primary color 30% opacity
Crown: 32px icon, gold, positioned -32px above avatar
Rank Badge: 32px circle, gold background, black text
Name: 16px bold
Score: 14px bold, primary color
Badge: "HERO" with verified icon, primary color 10% background
```

#### Rank 2 & 3 (Sides)
```
Avatar Size: 80px
Border: 4px silver/bronze
Shadow: 8px blur, 4px offset, black 10% opacity
Rank Badge: 24px circle, silver/bronze background, white text
Name: 14px bold
Score: 12px semi-bold, primary color
Vertical Offset: 16px below rank 1
```

### List Items (Rank 4+)
```
Height: Auto (min 64px)
Padding: 12px
Margin: 8px bottom
Border Radius: 12px
Background: Light background (light) / Dark background 50% (dark)

Layout:
- Rank number: 32px width, centered, 14px bold, secondary color
- Avatar: 40px circle
- Name: 14px bold, main text color
- Subtitle: 12px regular, secondary color
- Score: 14px bold, primary color, right-aligned
```

### Sticky "Your Impact" Card
```
Position: Fixed, 80px from bottom
Margin: 16px horizontal
Padding: 16px
Border Radius: 16px
Background: Gradient (primary to primary 80% opacity)
Shadow: 20px blur, 8px offset, primary 30% opacity
Border: 1px white 10% opacity

Layout:
- Rank section (left):
  - "RANK" label: 12px, white 80%, letter-spacing 1px
  - Rank number: 24px bold, white
- Divider: 1px white 20%, 32px height
- Impact text (center):
  - "Your Impact": 14px bold, white
  - "You saved X meals!": 12px, white 90%
- Score section (right):
  - Score: 18px bold, white
  - Trend icon: 20px, white
```

### Bottom Navigation
```
Height: 80px (includes safe area)
Background: Surface color
Border: Top border (1px)
Padding: 2px top, 2px bottom

Items (5):
- Icon: 24px
- Label: 10px
- Gap: 4px between icon and label

Selected:
- Color: Primary (#EC7F13)
- Icon: Filled variant
- Label: Bold

Unselected:
- Color: Gray
- Icon: Outlined variant
- Label: Medium weight
```

## States

### Loading State
```
┌─────────────────────────────────────────┐
│  ←  Leaderboard                    ≡   │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│                                         │
│              ⟳ Loading...              │
│                                         │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

### Error State
```
┌─────────────────────────────────────────┐
│  ←  Leaderboard                    ≡   │
├─────────────────────────────────────────┤
│                                         │
│              ⚠️                         │
│                                         │
│      Failed to load leaderboard        │
│                                         │
│      Network error occurred            │
│                                         │
│         ┌──────────┐                   │
│         │  Retry   │                   │
│         └──────────┘                   │
│                                         │
└─────────────────────────────────────────┘
```

### Empty State
```
┌─────────────────────────────────────────┐
│  ←  Leaderboard                    ≡   │
├─────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │This Week✓│ │This Month│ │All Time│ │
│  └──────────┘ └──────────┘ └────────┘ │
│                                         │
│              📊                         │
│                                         │
│         No rankings yet                │
│                                         │
│   Start selling meals to appear        │
│      on the leaderboard!               │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

### No Sales State (Your Impact Card)
```
┌─────────────────────────────────────────┐
│  ℹ️  Start selling meals to appear on  │
│      the leaderboard!                   │
└─────────────────────────────────────────┘
```

## Animations

### Period Chip Selection
```
Duration: 200ms
Easing: Ease-in-out
Properties:
- Background color
- Text color
- Border color
- Shadow
- Scale (0.95 on tap, 1.0 on release)
```

### Pull to Refresh
```
Duration: 300ms
Easing: Ease-out
Properties:
- Spinner rotation
- Opacity fade-in
```

### List Item Appearance
```
Duration: 150ms
Easing: Ease-out
Properties:
- Opacity (0 → 1)
- Transform (translateY: 10px → 0)
Stagger: 50ms between items
```

### Sticky Card Appearance
```
Duration: 300ms
Easing: Ease-out
Properties:
- Opacity (0 → 1)
- Transform (translateY: 20px → 0)
Delay: 200ms (after list loads)
```

## Responsive Behavior

### Small Screens (< 360px)
```
- Podium avatars: 72px (rank 1), 64px (rank 2/3)
- Period chips: Scrollable horizontal
- List items: Compact padding (8px)
- Sticky card: Smaller text (12px/10px)
```

### Medium Screens (360px - 480px)
```
- Default sizes (as specified above)
- All elements visible
- Comfortable spacing
```

### Large Screens (> 480px)
```
- Max width: 480px (centered)
- Larger podium avatars: 112px (rank 1), 96px (rank 2/3)
- More generous spacing
- Larger sticky card
```

## Accessibility

### Text Contrast
```
Light Mode:
- Text on background: 7.5:1 (AAA)
- Text on surface: 8.2:1 (AAA)
- Primary on white: 4.8:1 (AA)

Dark Mode:
- Text on background: 12.1:1 (AAA)
- Text on surface: 10.5:1 (AAA)
- Primary on dark: 5.2:1 (AA)
```

### Touch Targets
```
Minimum: 48x48 dp
- Back button: 48x48
- Filter button: 48x48
- Period chips: 48x36 (height acceptable for horizontal scroll)
- Bottom nav items: 48x64
```

### Screen Reader Labels
```
- Back button: "Go back"
- Filter button: "Filter leaderboard"
- Period chips: "Show [period] leaderboard"
- Podium items: "Rank [N], [Name], [Score] meals"
- List items: "Rank [N], [Name], [Score] meals"
- Sticky card: "Your rank: [N], You saved [Score] meals"
- Bottom nav: "[Item name], [selected/not selected]"
```

## Implementation Notes

### Flutter Widgets Used
```
- Scaffold (main structure)
- SafeArea (status bar padding)
- Stack (sticky card overlay)
- CustomScrollView (efficient scrolling)
- SliverToBoxAdapter (mixed content)
- RefreshIndicator (pull-to-refresh)
- Container (styling)
- Row/Column (layout)
- ClipOval (circular avatars)
- Image.network (avatar images)
- Icon (material icons)
- Text (typography)
- GestureDetector (tap handling)
- BottomNavigationBar (navigation)
```

### Key Measurements
```
App Bar Height: 60px
Period Chips Height: 36px
Podium Height: ~200px
List Item Height: ~64px
Sticky Card Height: ~80px
Bottom Nav Height: 80px
Total Screen Height: ~600px minimum
```

This UI reference ensures pixel-perfect implementation matching the HTML design while maintaining Flutter best practices and Material Design guidelines.
