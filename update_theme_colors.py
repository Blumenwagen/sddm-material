import sys
import os
import shutil
import colorsys
from PIL import Image

def get_colors(image_path, numcolors=8):
    # Load image and resize for performance
    img = Image.open(image_path).convert('RGB')
    img.thumbnail((250, 250))
    
    # Quantize to find dominant colors - method 2 is fast octree
    q = img.quantize(colors=numcolors, method=2)
    palette = q.getpalette()
    
    counts = q.getcolors()
    if counts is None:
        return []
    
    # Extract colors from the flat palette array based on occurrences
    sorted_colors = []
    # counts is a list of tuples: (count, index)
    for count, idx in sorted(counts, reverse=True):
        if idx < numcolors:
            r, g, b = palette[idx*3:idx*3+3]
            sorted_colors.append((r, g, b))
            
    return sorted_colors

def rgb_to_hex(rgb):
    return "#{:02X}{:02X}{:02X}".format(*rgb)

def calculate_colors(dominant_colors):
    if not dominant_colors:
        return {}
    
    bg_color = dominant_colors[0]
    
    # Find most saturated color for accent
    max_sat = -1
    accent_rgb = dominant_colors[0]
    
    for r, g, b in dominant_colors:
        h, l, s = colorsys.rgb_to_hls(r/255.0, g/255.0, b/255.0)
        # Prefer saturated and neither too dark nor too light
        if s > max_sat and 0.15 < l < 0.85:
            max_sat = s
            accent_rgb = (r, g, b)
            
    # Fallback to a secondary color if the whole image is grayscale
    if max_sat < 0.05 and len(dominant_colors) > 1:
        accent_rgb = dominant_colors[1]
        
    # The user explicitly wants a very dark, tinted charcoal shape behind the clock.
    # We will mix 10% of the dominant accent color into a pure `#111` dark slate.
    base_surf = [15, 17, 19] # Very dark slate
    r_tint = int((base_surf[0] * 0.85) + (accent_rgb[0] * 0.15))
    g_tint = int((base_surf[1] * 0.85) + (accent_rgb[1] * 0.15))
    b_tint = int((base_surf[2] * 0.85) + (accent_rgb[2] * 0.15))
    surface_color = (r_tint, g_tint, b_tint)
    
    # Because the surface is now guaranteed to be VERY dark, text must be white for contrast
    text_color = (255, 255, 255)
    hint_color = (160, 160, 160)
    
    # Make the accent color universally pop against the dark surface
    h, l, s = colorsys.rgb_to_hls(accent_rgb[0]/255.0, accent_rgb[1]/255.0, accent_rgb[2]/255.0)
    
    # Boost lightness and saturation for the primary accent
    acc_l = min(1.0, max(0.6, l))
    acc_s = min(1.0, s + 0.2)
    acc_r, acc_g, acc_b = [int(x * 255) for x in colorsys.hls_to_rgb(h, acc_l, acc_s)]
    accent_color = (acc_r, acc_g, acc_b)
    
    # Hover is just slightly brighter yet
    hov_l = min(1.0, acc_l + 0.15)
    hov_r, hov_g, hov_b = [int(x * 255) for x in colorsys.hls_to_rgb(h, hov_l, acc_s)]
    hover_color = (hov_r, hov_g, hov_b)
    
    return {
        "BackgroundColor": rgb_to_hex(bg_color),
        "AccentColor": rgb_to_hex(accent_color),
        "AccentColorHover": rgb_to_hex(hover_color),
        "SurfaceColor": rgb_to_hex(surface_color),
        "TextColor": rgb_to_hex(text_color),
        "TextHintColor": rgb_to_hex(hint_color)
    }

def update_theme_conf(conf_path, new_colors):
    with open(conf_path, 'r') as f:
        lines = f.readlines()
        
    with open(conf_path, 'w') as f:
        for line in lines:
            replaced = False
            for key, val in new_colors.items():
                if line.startswith(f'{key}='):
                    f.write(f'{key}="{val}"\n')
                    replaced = True
                    break
            if not replaced:
                # Add it if missing maybe? For now we just replace if it exists
                f.write(line)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python update_theme_colors.py <path_to_wallpaper>")
        sys.exit(1)
        
    src_wallpaper = sys.argv[1]
    if not os.path.exists(src_wallpaper):
        print(f"Error: File not found - {src_wallpaper}")
        sys.exit(1)
        
    project_dir = os.path.dirname(os.path.abspath(__file__))
    bg_dir = os.path.join(project_dir, "backgrounds")
    os.makedirs(bg_dir, exist_ok=True)
    
    # Normalize extension (always save as wallpaper.jpg to match config)
    dest_wallpaper = os.path.join(bg_dir, "wallpaper.jpg")
    
    # We copy using shutil. If it's a PNG, SDDM can read PNGs, but let's convert using PIL if needed.
    # Actually, let's just use PIL to save it as JPEG to be safe and optimize size.
    try:
        img = Image.open(src_wallpaper)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        img.save(dest_wallpaper, "JPEG", quality=90)
        print(f"Saved wallpaper to {dest_wallpaper}")
    except Exception as e:
        print(f"Failed to process image: {e}")
        sys.exit(1)
    
    print("Extracting dynamic Material 3 palette...")
    dom_colors = get_colors(dest_wallpaper, 8)
    new_colors = calculate_colors(dom_colors)
    
    print("Generated Colors:")
    for k, v in new_colors.items():
        print(f"  {k}: {v}")
    
    conf_path = os.path.join(project_dir, "theme.conf")
    update_theme_conf(conf_path, new_colors)
    print("Successfully applied new colors to theme.conf!")
