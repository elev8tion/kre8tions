# Track C - Preview Panel Enhancements - Visual Demo Guide

## Quick Start Demo

### 1. Launch the IDE
```bash
cd /Users/kcdacre8tor/Desktop/codewhisper
flutter run -d chrome --web-renderer html
```

### 2. Navigate to Preview Panel
- Upload a Flutter project (or use the demo project)
- The preview panel is on the right side of the screen
- You'll see device frames (iPhone, iPad, Samsung Galaxy by default)

---

## Feature Demonstrations

### DEMO 1: Inspect Mode

**Steps:**
1. Look for the inspect mode button in the toolbar (touch icon: 👆)
2. Click to enable inspect mode
3. Button turns primary color (blue) to indicate active state
4. Help text updates: "Inspect Mode: Hover to highlight, click to select"

**Expected Behavior:**
```
┌─────────────────────────────────────────┐
│ Inspect Mode: OFF                       │
│ [👆] ← Click this button                │
└─────────────────────────────────────────┘

After clicking:

┌─────────────────────────────────────────┐
│ Inspect Mode: ON (button is blue)       │
│ [👆] ← Button highlighted               │
│ ℹ️  Inspect Mode: Hover to highlight... │
└─────────────────────────────────────────┘
```

**Hover Detection:**
1. Move mouse over the device preview
2. A semi-transparent overlay appears
3. Top-left corner shows widget type badge (e.g., "Text")
4. Bottom-right corner shows dimensions (e.g., "100 × 100")
5. 2px primary-colored border highlights the area

**Click to Select:**
1. While hovering, click on a widget
2. Toast notification appears: "Selected: [WidgetType]"
3. Widget Inspector Panel opens on the right (if in Mock UI mode)
4. Selected widget shows blue outline in all device previews

---

### DEMO 2: Zoom Controls

**Zoom UI Location:**
```
┌─────────────────────────────────────────────┐
│ Device Preview                [−] 100% [+] 🖥️│
│                               └─ Zoom UI ─┘ │
└─────────────────────────────────────────────┘
```

**Zoom In (Scenario 1):**
1. Click the [+] button
2. Percentage updates: 100% → 120%
3. All device previews scale up by 20%
4. Content gets larger but stays centered

**Zoom Out (Scenario 2):**
1. Click the [−] button
2. Percentage updates: 100% → 75%
3. All device previews scale down by 25%
4. More of the preview fits on screen

**Dropdown Menu (Scenario 3):**
1. Click on "100%" text or zoom icon
2. Dropdown menu appears with options:
   ```
   ┌──────┐
   │ 25%  │
   │ 50%  │
   │ 75%  │
   │ 100% │ ← Current (checkmark)
   │ 120% │
   │ 150% │
   │ 200% │
   └──────┘
   ```
3. Select "200%"
4. Preview zooms to double size
5. Pan capability automatically enables

**Fit to Screen (Scenario 4):**
1. Zoom to any level (e.g., 150%)
2. Click the 🖥️ (fit-to-screen) button
3. Zoom resets to 100%
4. Preview returns to original size

---

### DEMO 3: Pan Capability

**Prerequisites:** Zoom must be > 100%

**Steps:**
1. Zoom to 120% or higher (e.g., 150%)
2. Click and hold on the preview
3. Drag the mouse left/right/up/down
4. Preview pans in the direction of drag
5. Release mouse to stop panning

**Visual Feedback:**
```
At 100%:                    At 150%:
┌──────────────┐           ┌──────────────────────┐
│              │           │ ╔════════════════╗   │
│   iPhone     │           │ ║                ║   │
│   Preview    │  →        │ ║  iPhone        ║   │
│              │           │ ║  Preview       ║   │
│              │           │ ║  (Draggable)   ║   │
└──────────────┘           │ ╚════════════════╝   │
                           │  ← Can pan here →    │
                           └──────────────────────┘
```

**Boundary Margins:**
- 80px margin on all sides prevents content from disappearing
- You can pan, but widget won't go completely off-screen
- Smooth scrolling with momentum

---

### DEMO 4: Selection Indicators

**Prerequisites:** Select a widget (via inspect mode or other means)

**Visual Elements:**

1. **Blue Outline:**
   ```
   ╔═══════════════════════╗ ← 3px blue border
   ║                       ║
   ║   Selected Widget     ║
   ║                       ║
   ╚═══════════════════════╝
   ```

2. **Shadow Effect:**
   - 8px blur radius
   - 2px spread radius
   - Blue color at 30% opacity
   - Creates depth perception

3. **Breadcrumb Trail:**
   ```
   ┌──────────────────────────────────────┐
   │ Scaffold > Column > Text             │
   │           ↑         ↑                │
   │        Normal    Bold+Blue (selected)│
   └──────────────────────────────────────┘
   ```

**Interaction:**
1. Select different widget types
2. Breadcrumb updates to show hierarchy
3. Last item is always the selected widget
4. Chevrons (>) separate hierarchy levels

---

### DEMO 5: Multi-Device Sync

**Setup:**
1. Click "3 Devices" button in toolbar
2. Device selection dialog opens
3. Select 3 devices:
   - ☑️ iPhone 13
   - ☑️ iPad Pro 11"
   - ☑️ Samsung Galaxy S20
4. Click "Apply"

**Synchronized Behaviors:**

1. **Zoom Sync:**
   ```
   Action: Zoom to 150%

   Before:                 After:
   iPhone [100%]    →     iPhone [150%]
   iPad   [100%]    →     iPad   [150%]
   Galaxy [100%]    →     Galaxy [150%]
   ```

2. **Inspect Mode Sync:**
   ```
   Action: Enable inspect mode

   Result:
   - All 3 devices show hover overlays
   - All 3 devices respond to mouse hover
   - All 3 devices show same selection
   ```

3. **Selection Sync:**
   ```
   Action: Click "Text" widget in inspect mode

   Result:
   iPhone:  [Blue outline on Text widget]
   iPad:    [Blue outline on Text widget]
   Galaxy:  [Blue outline on Text widget]
   ```

**Visual Layout:**
```
┌────────────────────────────────────────────────────────────┐
│                    Preview Panel                           │
├────────────────────────────────────────────────────────────┤
│ [iPhone 13]        [iPad Pro]         [Galaxy S20]         │
│  All at 150%       All with blue      All hoverable       │
│  All pannable      selection outline  in inspect mode     │
└────────────────────────────────────────────────────────────┘
```

---

## Testing Checklist

### Inspect Mode
- [ ] Button toggles on/off
- [ ] Button color changes when active
- [ ] Hover shows widget overlay
- [ ] Widget type badge displays correctly
- [ ] Dimensions display correctly
- [ ] Click broadcasts selection
- [ ] Toast notification appears

### Zoom Controls
- [ ] [+] button increases zoom
- [ ] [−] button decreases zoom
- [ ] Buttons disable at min/max zoom
- [ ] Dropdown shows all preset values
- [ ] Dropdown selection updates zoom
- [ ] Fit-to-screen resets to 100%
- [ ] Percentage display updates correctly

### Pan Capability
- [ ] Pan disabled at 100% or less
- [ ] Pan enabled above 100%
- [ ] Click-and-drag pans smoothly
- [ ] Boundary margins work correctly
- [ ] Content doesn't disappear off-screen

### Selection Indicators
- [ ] Blue outline appears when widget selected
- [ ] Shadow effect renders correctly
- [ ] Breadcrumb shows widget hierarchy
- [ ] Last breadcrumb item is bold
- [ ] Chevrons separate hierarchy levels

### Multi-Device Sync
- [ ] Zoom syncs across all devices
- [ ] Inspect mode syncs across all devices
- [ ] Selection syncs across all devices
- [ ] All devices pan together when zoomed

---

## Troubleshooting

### Issue 1: Inspect mode hover not working
**Cause:** Mouse events might be captured by device frame
**Solution:** Ensure `_inspectModeWrapper` is wrapping the preview correctly

### Issue 2: Zoom looks pixelated
**Cause:** Browser zoom interpolation
**Solution:** This is expected behavior - actual Flutter rendering would be crisp

### Issue 3: Can't pan after zooming
**Cause:** Zoom level might be exactly 1.0
**Solution:** Zoom to 120% or higher to enable panning

### Issue 4: Selection indicator not showing
**Cause:** Widget might not be selected properly
**Solution:** Check that `widget.selectedWidget` is not null

### Issue 5: Multiple devices not showing
**Cause:** Device selection might be empty
**Solution:** Click "3 Devices" and select at least one device

---

## Performance Tips

### Smooth Hover Detection
- Move mouse slowly for better accuracy
- Rapid movements might miss intermediate widgets

### Zoom Performance
- Lower zoom levels (25%-75%) perform better on older machines
- Higher zoom levels (150%-200%) may lag on complex UIs

### Pan Performance
- Short drag gestures are smoother than long ones
- Release mouse frequently to reset momentum

---

## Visual States Summary

### Toolbar States
```
Inspect OFF, Zoom 100%:
[👆] 100% [Devices: 3]

Inspect ON, Zoom 150%:
[👆] 150% [Devices: 3]
 ↑ Blue  ↑ Larger
```

### Preview States
```
1. Normal (no zoom, no inspect):
   - Standard device frames
   - No overlays
   - No hover effects

2. Inspect Mode ON (no zoom):
   - Hover shows overlays
   - Click selects widgets
   - Widget metadata visible

3. Zoomed (no inspect):
   - Scaled device frames
   - Pan enabled if > 100%
   - No hover effects

4. Inspect + Zoom:
   - Scaled device frames
   - Hover shows overlays (scaled)
   - Pan enabled
   - Full functionality
```

---

## Edge Cases Handled

1. **Empty device selection:** Shows "No devices selected" message
2. **Zoom at min (25%):** [−] button disabled
3. **Zoom at max (200%):** [+] button disabled
4. **Hover exit:** Overlay disappears smoothly
5. **Rapid zoom changes:** State updates correctly
6. **Device switching:** Zoom level preserved
7. **Inspect mode toggle:** Overlays removed/added instantly

---

## Keyboard Shortcuts (Future Enhancement)

While not implemented in this version, these shortcuts are planned:

- `Cmd/Ctrl + +` : Zoom in
- `Cmd/Ctrl + -` : Zoom out
- `Cmd/Ctrl + 0` : Reset to 100%
- `Cmd/Ctrl + I` : Toggle inspect mode
- `Space + Drag` : Pan (when zoomed)

---

## Conclusion

This visual demo guide covers all aspects of the Track C implementation. Follow the steps in order to experience each feature, and use the testing checklist to verify functionality.

**Total Features:** 5 major features + multi-device sync
**Total UI Elements:** 7 interactive controls
**Total Visual Indicators:** 4 types (overlay, outline, breadcrumb, shadow)

Happy testing! 🚀

---

*Last Updated: 2025-12-24*
*Track: C - Preview Panel Enhancements*
