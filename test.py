import pytesseract
from PIL import Image

# Optional safety line (recommended)
pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

img = Image.open("bill.png")  # use any clear image with text
text = pytesseract.image_to_string(img)

print(text)
