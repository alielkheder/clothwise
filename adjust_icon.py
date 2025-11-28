from PIL import Image

# Open the icon
icon = Image.open('assets/icons/app_icon.png')

# Get dimensions
width, height = icon.size

# Create a new image with same size
new_icon = Image.new('RGBA', (width, height), (237, 228, 216, 255))  # #EDE4D8 background

# Calculate shift to center the logo (shift down by 5% of height)
shift_down = int(height * 0.05)

# Paste the original icon shifted down
new_icon.paste(icon, (0, shift_down), icon)

# Crop back to original size to maintain dimensions
new_icon = new_icon.crop((0, 0, width, height))

# Or alternatively, shift by moving the content
# Create new canvas with padding at top
padding_top = int(height * 0.08)  # Add 8% padding at top
new_height = height + padding_top
canvas = Image.new('RGBA', (width, new_height), (237, 228, 216, 255))
canvas.paste(icon, (0, padding_top), icon)

# Crop from top to get centered result
final_icon = canvas.crop((0, padding_top//2, width, height + padding_top//2))

# Save the adjusted icon
final_icon.save('assets/icons/app_icon.png')

print("Icon adjusted successfully! Logo should now be better centered.")
