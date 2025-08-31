# SaladUI Phoenix 1.8 (Tailwind v4 Only) Migration Plan

## Executive Summary

We are migrating SaladUI to work ONLY with Phoenix 1.8+ and Tailwind CSS v4, dropping support for older Phoenix versions with Tailwind v3. This greatly simplifies the codebase by removing all JavaScript-based Tailwind configuration logic. DaisyUI, which ships with Phoenix 1.8, works alongside SaladUI without conflicts.

## Current State Analysis

### What Works ✅
- Phoenix LiveView 1.1.8 compatibility (after replacing `Phoenix.Naming.camelize` with `Macro.camelize`)
- Component code is compatible with Phoenix 1.8
- JavaScript hooks and LiveView integration work correctly
- Base SaladUI components use stable Phoenix APIs
- **No conflicts with colocated JS** - SaladUI doesn't use dot-prefixed hooks
- **No verified routes issues** - SaladUI doesn't use route helpers or ~p sigil
- **Component system compatible** - Properly uses `Phoenix.Component`

### The Main Issue 🚨

#### Tailwind Configuration System Changed Completely

**Tailwind v3 (Phoenix < 1.8)**
- Uses `tailwind.config.js` file
- Plugins added via `require()` statements in JavaScript
- Content paths configured in `module.exports`
- Colors imported from JSON files

**Tailwind v4 (Phoenix 1.8+)**
- No `tailwind.config.js` file exists
- Configuration done entirely in CSS
- Plugins added via `@plugin` directives
- Content auto-detected (no manual paths needed)
- Colors defined as CSS custom properties in `@theme` blocks

### Non-Issues ✅

#### DaisyUI Coexistence
Phoenix 1.8 ships with DaisyUI by default. **No conflicts exist** because:
- DaisyUI uses semantic classes (`btn`, `card`, `modal`)
- SaladUI uses utility classes (`bg-primary`, `text-foreground`)
- CSS variables don't overlap (`--primary` vs `--color-primary`)
- **Result**: Both libraries work together seamlessly

#### Phoenix 1.8 & LiveView 1.1 Features
New features in Phoenix 1.8 and LiveView 1.1 don't break SaladUI:
- **Colocated JavaScript**: SaladUI uses `phx-hook="SaladUI"` (no dot prefix conflicts)
- **Verified Routes**: SaladUI doesn't use route helpers internally
- **Live Layouts**: SaladUI components work with any layout system
- **Scopes**: No impact on component library functionality
- **TypeScript Support**: SaladUI's JS hooks already work with the typed client

#### 2. File Structure Differences

**Files that don't exist in Phoenix 1.8:**
- `assets/tailwind.config.js`
- `assets/tailwind.colors.json` (not needed)

**New CSS structure in Phoenix 1.8:**
```css
@import "tailwindcss";
@plugin "plugin-name";
@theme { /* custom properties */ }
```

#### 3. Current Installation Tasks Failures

**`mix salad.install` failures:**
- Line 234-236: Tries to patch non-existent `tailwind.config.js`
- Line 40: Calls `patch_tailwind_config()` which will fail
- Line 257: Downloads tailwindcss-animate.js but can't configure it

**`mix salad.setup` failures:**
- Line 177-179: Same tailwind.config.js patching issue
- Line 96: Calls failing `patch_tailwind_config()`

**`TailwindPatcher` module:**
- Entire module assumes JavaScript config file exists
- All functions will fail on Phoenix 1.8 projects

## Proposed Solution Architecture

### 1. Simplified CSS-Only Configuration

```elixir
defmodule SaladUI.Patcher.TailwindV4Patcher do
  @plugins [
    "@tailwindcss/typography",
    "tailwindcss-animate"
  ]
  
  def patch_css(css_path, color_scheme \\ "gray") do
    content = File.read!(css_path)
    
    content
    |> ensure_salad_ui_import()
    |> add_plugins(@plugins)
    |> add_color_variables(color_scheme)
    |> File.write!(css_path)
  end
  
  defp add_plugins(content, plugins) do
    # Add @plugin directives after @import "tailwindcss"
    plugin_imports = Enum.map_join(plugins, "\n", &"@plugin \"#{&1}\";")
    String.replace(content, "@import \"tailwindcss\";", "@import \"tailwindcss\";\n#{plugin_imports}")
  end
  
  defp add_color_variables(content, color_scheme) do
    # Add CSS variables for the color scheme
    color_vars = get_color_variables(color_scheme)
    content <> "\n\n" <> color_vars
  end
end
```

### 2. Simplified Mix Tasks (No Branching)

```elixir
defmodule Mix.Tasks.Salad.Install do
  def igniter(igniter) do
    Mix.shell().info("Installing SaladUI for Phoenix 1.8 with Tailwind v4")
    Mix.shell().info("Compatible with DaisyUI - no conflicts")
    
    igniter
    |> setup_css_configuration()
    |> copy_javascript_files()
    |> copy_component_files()
    |> patch_app_js()
  end
  
  defp setup_css_configuration(igniter) do
    SaladUI.Patcher.TailwindV4Patcher.patch_css("./assets/css/app.css")
    igniter
  end
end
```

### 3. New Tailwind v4 Patcher Module

```elixir
defmodule SaladUI.Patcher.TailwindV4Patcher do
  @plugins [
    "@tailwindcss/typography",
    "tailwindcss-animate"
  ]
  
  def patch_css(css_path, opts \\ []) do
    content = File.read!(css_path)
    
    content
    |> ensure_tailwind_import()
    |> add_plugins(@plugins)
    |> add_salad_ui_import()
    |> add_theme_configuration(opts[:color_scheme])
    |> write_file(css_path)
  end
  
  defp add_plugins(content, plugins) do
    # Add @plugin directives after @import "tailwindcss"
  end
  
  defp add_theme_configuration(content, color_scheme) do
    # Add CSS variables to @theme block
  end
end
```

### 4. Color Scheme Handling for v4

Instead of `tailwind.colors.json`, use CSS custom properties:

```css
@theme {
  --color-background: hsl(var(--background));
  --color-foreground: hsl(var(--foreground));
  --color-primary: hsl(var(--primary));
  /* ... other colors ... */
}

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    /* ... color values ... */
  }
}
```

## Implementation Steps

### 🎯 Simplified Implementation (Phoenix 1.8 Only)

1. **Fix Phoenix.Naming issue** ✅ Already done
   - Replace `Phoenix.Naming.camelize` with `Macro.camelize`

2. **Remove all Tailwind v3 support** 🔴 CRITICAL  
   - Delete `TailwindPatcher` module entirely
   - Remove all `tailwind.config.js` patching logic
   - Remove `tailwind.colors.json` handling

3. **Create CSS-only Tailwind v4 patcher** 🔴 CRITICAL
   - New module: `SaladUI.Patcher.TailwindV4Patcher`
   - Add `@plugin` directives to CSS only
   - Handle color schemes via CSS variables

4. **Simplify mix tasks** 🔴 CRITICAL
   - Remove branching logic entirely
   - Assume Phoenix 1.8 with Tailwind v4 always
   - Clean up old v3 code paths

### 📈 Enhancement Phase (Priority 2 - Nice to have)

5. **Transform color configurations** 🟡 MEDIUM
   - Convert JSON color configs to CSS variables
   - Create color scheme templates for v4
   - Maintain v3 JSON files for compatibility

6. **Update CSS patching logic** 🟡 MEDIUM
   - Handle single `@import "tailwindcss"` for v4
   - Properly insert `@import "./salad_ui.css"`
   - Add @plugin directives in correct order

7. **Handle tailwindcss-animate for v4** 🟡 MEDIUM
   - v3: Keep existing logic (download to vendor/ and add to config.js)
   - v4: Add `@plugin "tailwindcss-animate"` to CSS (Phoenix 1.8 includes it via npm)

### 🧪 Polish Phase (Priority 3 - Can be done later)

8. **Create integration tests**
   - Test installation on Phoenix 1.7 (Tailwind v3)
   - Test installation on Phoenix 1.8 (Tailwind v4)
   - Verify all components work in both environments

9. **Update documentation**
   - Add version compatibility matrix
   - Document v3 vs v4 differences
   - Update installation guides

10. **Add helpful error messages**
    - Detect common failure scenarios
    - Provide clear remediation steps
    - Add version mismatch warnings

### 🚀 Future Enhancements (Phoenix 1.8+ Specific)

11. **Optional: Colocated JavaScript Components** 🟢 FUTURE
    - Consider providing colocated JS versions of complex components
    - Would eliminate need for separate hook setup
    - Example: `<.dialog>` with embedded `<script :type={ColocatedHook}>`

12. **Optional: TypeScript Types** 🟢 FUTURE
    - Provide TypeScript definitions for SaladUI hooks
    - Leverage LiveView 1.1's official TypeScript support
    - Improve developer experience with IntelliSense

## File Changes Required

### Files to Delete

1. **`lib/mix/tasks/helpers/tailwind_patcher.ex`**
   - Remove entirely (Tailwind v3 only)

### Files to Modify

1. **`lib/mix/tasks/salad.install.ex`**
   - Remove all tailwind.config.js patching
   - Remove tailwind.colors.json handling
   - Simplify to CSS-only configuration

2. **`lib/mix/tasks/salad.setup.ex`**
   - Remove all Tailwind v3 logic
   - Use CSS-only patching

### Files to Create

1. **`lib/mix/tasks/helpers/tailwind_v4_patcher.ex`**
   - CSS-only configuration patching
   - Handle @plugin directives
   - Color scheme CSS variables

## Testing Strategy

### Unit Tests
- Test version detection logic
- Test CSS patching for v4
- Test backward compatibility for v3

### Integration Tests
- Create dummy Phoenix 1.7 app, run installation
- Create dummy Phoenix 1.8 app, run installation
- Verify components render correctly
- Test JavaScript hooks work

### Manual Testing Checklist
- [ ] Fresh Phoenix 1.8 app installation
- [ ] Fresh Phoenix 1.7 app installation  
- [ ] Upgrade scenario (v3 to v4)
- [ ] All color schemes work
- [ ] All components render
- [ ] JavaScript interactions work
- [ ] Build process succeeds

## Migration Guide for Users

### For New Phoenix 1.8 Projects
```bash
mix salad.install
# Automatically detects v4 and configures accordingly
```

### For Existing Phoenix Projects Upgrading to 1.8
```bash
# Before upgrade: uses Tailwind v3
mix salad.install  # Works with v3

# After Phoenix 1.8 upgrade
mix salad.migrate_to_v4  # New task to help migration
```

## Success Criteria

1. ✅ `mix salad.install` works on Phoenix 1.8 without errors
2. ✅ `mix salad.install` continues working on Phoenix 1.7
3. ✅ All SaladUI components render correctly in both versions
4. ✅ Color schemes work in Tailwind v4
5. ✅ JavaScript hooks and LiveView integration work
6. ✅ Clear documentation and error messages
7. ✅ No breaking changes for existing users

## Risk Mitigation

### Potential Risks
1. **Breaking existing installations** 
   - Mitigation: Maintain full v3 compatibility
   
2. **Complex version detection**
   - Mitigation: Allow manual version override flag
   
3. **Future Tailwind changes**
   - Mitigation: Abstract configuration logic for easier updates

## Timeline Estimate

- **Simplified Implementation**: 1-2 hours → **Phoenix 1.8 only support**
- Enhancement Phase: 2-3 hours → Polish and additional features
- **Total: 3-5 hours** (much faster without v3 compatibility)

## Next Steps

1. **Delete old Tailwind v3 code** (remove TailwindPatcher module)
2. **Create TailwindV4Patcher** (CSS-only patching)
3. **Update mix tasks** (remove all v3 branching logic)
4. **Test on Phoenix 1.8 project**
5. **Release as Phoenix 1.8+ only**

**Goal**: SaladUI works seamlessly with Phoenix 1.8 and Tailwind v4, no legacy support

---

*This plan migrates SaladUI to work exclusively with Phoenix 1.8+ and Tailwind v4, providing a cleaner, simpler codebase.*