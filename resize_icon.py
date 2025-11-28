from PIL import Image, ImageDraw

# Open the image
img = Image.open(r'C:\Users\yassi\Downloads\WhatsApp Image 2025-11-25 at 00.57.02_805f679e.jpg')

# Convert to RGBA if needed
if img.mode != 'RGBA':
    img = img.convert('RGBA')

# Create a new 1024x1024 image with transparent background
size = 1024
new_img = Image.new('RGBA', (size, size), (255, 255, 255, 0))

# Calculate the size for the logo (70% of canvas to leave padding)
logo_size = int(size * 0.7)

# Resize the original image to fit within logo_size while maintaining aspect ratio
img.thumbnail((logo_size, logo_size), Image.Resampling.LANCZOS)

# Calculate position to center the logo
x = (size - img.width) // 2
y = (size - img.height) // 2

# Paste the logo in the center
new_img.paste(img, (x, y), img if img.mode == 'RGBA' else None)

# Save the result
new_img.save(r'd:\final_project\clothwise\assets\icons\app_icon.png', 'PNG')
print(f'Icon resized and centered: {img.width}x{img.height} logo on {size}x{size} canvas')
print(f'Position: ({x}, {y})')
