import io
import os

import fitz  # PyMuPDF
from PIL import Image


def main() -> None:
    pdf_path = r"c:\Users\HP\OneDrive\Desktop\fall 2025\fyp part A\Final Year Project Proposal v2.pdf"
    out_path = r"c:\Users\HP\OneDrive\Desktop\fall 2025\fyp part A\App\ecoalert\assets\icons\app_icon.png"

    if not os.path.exists(pdf_path):
        raise SystemExit(f"PDF not found: {pdf_path}")

    doc = fitz.open(pdf_path)

    best = None  # (score, pil_image)

    for page_index in range(min(len(doc), 6)):
        page = doc[page_index]
        for img in page.get_images(full=True):
            xref = img[0]
            base = doc.extract_image(xref)
            img_bytes = base.get("image")
            if not img_bytes:
                continue
            try:
                pil = Image.open(io.BytesIO(img_bytes)).convert("RGBA")
            except Exception:
                continue

            w, h = pil.size
            if w < 128 or h < 128:
                continue

            aspect = w / h
            squareness = 1.0 - abs(1.0 - aspect)  # 1.0 is perfect square
            area = w * h
            score = area * (0.6 + 0.4 * squareness)

            if best is None or score > best[0]:
                best = (score, pil)

    if best is None:
        raise SystemExit(
            "No suitable embedded image found in the PDF. "
            "Please provide the logo as a PNG/JPG file so it can be used for the app icon."
        )

    pil = best[1]

    w, h = pil.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    pil = pil.crop((left, top, left + side, top + side))
    pil = pil.resize((1024, 1024), Image.Resampling.LANCZOS)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    pil.save(out_path, format="PNG", optimize=True)

    print(f"Wrote logo to: {out_path}")


if __name__ == "__main__":
    main()
