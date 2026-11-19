#!/usr/bin/env python3
"""Build prestocking-2027.json from the client's two Excel files (stdlib only).

Usage: python3 doc/catalog/build_prestocking_json.py
Guest price = column G (USD). Net cost (column E, MXN) and the product link are admin-only.
Proteins PRE-104..PRE-124 are priced per oz from the Protein Portion Pricing sheet
(column F = guest USD/oz, column D = net MXN/oz; up to 4 decimals).
Display names are cleaned (internal notes and typos removed); the Excel stays the source of truth.
"""
import json
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
CATALOG_XLSX = HERE / "Kachava_Lux_2027_PreStocking_Catalog_MXN_USD.xlsx"
PROTEIN_XLSX = HERE / "Kachava_Lux_2027_Protein_Portion_Pricing.xlsx"
OUT = HERE / "prestocking-2027.json"
TERMS_FILE = HERE / "prestocking-terms.json"  # {"terms": {en, es}, "askSubstitutions": true}
NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
PORTION_OZ = [6, 8, 10, 12, 14]

CATEGORIES = {
    "Fresh baked good": "Fresh baked goods",
    "Hagen Daz ice cream": "Häagen-Dazs ice cream",
}

# SKU -> (English display name, Spanish name). Reviewed by the client from the admin.
NAMES = {
    "PRE-001": ("Mixed nuts", "Nueces mixtas"),
    "PRE-002": ("Cashews", "Nuez de la India"),
    "PRE-003": ("Almonds", "Almendras"),
    "PRE-004": ("Peanuts", "Cacahuates"),
    "PRE-005": ("Mazapán De la Rosa 50 g", "Mazapán De la Rosa 50 g"),
    "PRE-006": ("Oreo cookies", "Galletas Oreo"),
    "PRE-007": ("Chocolate chip cookies", "Galletas con chispas de chocolate"),
    "PRE-008": ("Chocolate bar", "Barra de chocolate"),
    "PRE-009": ("Potato chips", "Papas fritas"),
    "PRE-010": ("Doritos Nacho 198.4 g", "Doritos Nacho 198.4 g"),
    "PRE-011": ("Tortilla chips", "Totopos"),
    "PRE-012": ("Ritz crackers", "Galletas Ritz"),
    "PRE-013": ("Saltine crackers", "Galletas saladas"),
    "PRE-014": ("Corn tostadas", "Tostadas de maíz"),
    "PRE-015": ("Donuts, mixed", "Donas surtidas"),
    "PRE-016": ("Bagels, plain", "Bagels naturales"),
    "PRE-017": ("Bagels, onion", "Bagels de cebolla"),
    "PRE-018": ("Bagels, sesame", "Bagels de ajonjolí"),
    "PRE-019": ("Pastries, mixed", "Pan dulce surtido"),
    "PRE-020": ("Sourdough bread", "Pan de masa madre"),
    "PRE-021": ("Brown bread", "Pan integral oscuro"),
    "PRE-022": ("Fresh baked rolls", "Bolillos recién horneados"),
    "PRE-023": ("White bread", "Pan blanco"),
    "PRE-024": ("Whole grain bread", "Pan multigrano"),
    "PRE-025": ("Mixed Mexican cookies", "Galletas mexicanas surtidas"),
    "PRE-026": ("Chocolate cake, whole", "Pastel de chocolate, entero"),
    "PRE-027": ("Vanilla cake, whole", "Pastel de vainilla, entero"),
    "PRE-028": ("Carrot cake, whole", "Pastel de zanahoria, entero"),
    "PRE-029": ("Tres leches cake, whole", "Pastel de tres leches, entero"),
    "PRE-030": ("Cinnamon rolls", "Roles de canela"),
    "PRE-031": ("Granola, plain", "Granola natural"),
    "PRE-032": ("Granola, chocolate", "Granola de chocolate"),
    "PRE-033": ("Granola, coconut", "Granola de coco"),
    "PRE-034": ("Greek yogurt, plain", "Yogur griego natural"),
    "PRE-035": ("Greek yogurt, vanilla", "Yogur griego de vainilla"),
    "PRE-036": ("Greek yogurt, nonfat", "Yogur griego sin grasa"),
    "PRE-037": ("Greek yogurt, lactose free", "Yogur griego deslactosado"),
    "PRE-038": ("Häagen-Dazs vanilla 473 ml", "Häagen-Dazs vainilla 473 ml"),
    "PRE-039": ("Häagen-Dazs dulce de leche", "Häagen-Dazs dulce de leche"),
    "PRE-040": ("Häagen-Dazs chocolate", "Häagen-Dazs chocolate"),
    "PRE-041": ("Green apples", "Manzanas verdes"),
    "PRE-042": ("Red apples", "Manzanas rojas"),
    "PRE-043": ("Pears", "Peras"),
    "PRE-044": ("Bananas, 1 kg", "Plátano Tabasco, 1 kg"),
    "PRE-045": ("Avocado", "Aguacate"),
    "PRE-046": ("Watermelon", "Sandía"),
    "PRE-047": ("Cantaloupe", "Melón"),
    "PRE-048": ("Grapes", "Uvas"),
    "PRE-049": ("Pineapple", "Piña"),
    "PRE-050": ("Mango", "Mango"),
    "PRE-051": ("Papaya", "Papaya"),
    "PRE-052": ("Strawberries", "Fresas"),
    "PRE-053": ("Blueberries", "Moras azules"),
    "PRE-054": ("Dragon fruit", "Pitaya"),
    "PRE-055": ("Tangerines", "Mandarinas"),
    "PRE-056": ("Tomatoes", "Jitomates"),
    "PRE-057": ("Potatoes", "Papas"),
    "PRE-058": ("Mint", "Hierbabuena"),
    "PRE-059": ("Parsley", "Perejil"),
    "PRE-060": ("Fresh garlic", "Ajo fresco"),
    "PRE-061": ("Beets", "Betabel"),
    "PRE-062": ("Broccoli", "Brócoli"),
    "PRE-063": ("Shiitake mushrooms", "Hongos shiitake"),
    "PRE-064": ("Portobello mushrooms", "Hongos portobello"),
    "PRE-065": ("Cilantro, 1 bunch", "Cilantro, 1 manojo"),
    "PRE-066": ("Red onion", "Cebolla morada"),
    "PRE-067": ("White onion", "Cebolla blanca"),
    "PRE-068": ("Cucumbers", "Pepinos"),
    "PRE-069": ("Red bell peppers", "Pimientos rojos"),
    "PRE-070": ("Green bell peppers", "Pimientos verdes"),
    "PRE-071": ("Jalapeño peppers", "Chiles jalapeños"),
    "PRE-072": ("Habanero peppers", "Chiles habaneros"),
    "PRE-073": ("Lettuce", "Lechuga"),
    "PRE-074": ("Romaine lettuce", "Lechuga romana"),
    "PRE-075": ("Spinach", "Espinacas"),
    "PRE-076": ("Jícama", "Jícama"),
    "PRE-077": ("Olives", "Aceitunas"),
    "PRE-078": ("Carrots", "Zanahorias"),
    "PRE-079": ("Squash", "Calabacitas"),
    "PRE-080": ("Corn", "Elote"),
    "PRE-081": ("Celery", "Apio"),
    "PRE-082": ("Lemons", "Limones amarillos"),
    "PRE-083": ("Seedless limes, 1 kg", "Limones sin semilla, 1 kg"),
    "PRE-084": ("A.1. steak sauce", "Salsa para carne A.1."),
    "PRE-085": ("Barbecue sauce", "Salsa barbecue"),
    "PRE-086": ("Valentina hot sauce, yellow label 370 ml", "Salsa Valentina etiqueta amarilla 370 ml"),
    "PRE-087": ("Cholula hot sauce", "Salsa picante Cholula"),
    "PRE-088": ("Tabasco hot sauce", "Salsa picante Tabasco"),
    "PRE-089": ("Sweet pickles", "Pepinillos dulces"),
    "PRE-090": ("Dill pickles", "Pepinillos al eneldo"),
    "PRE-091": ("Ketchup", "Catsup"),
    "PRE-092": ("Mustard", "Mostaza"),
    "PRE-093": ("Mayonnaise", "Mayonesa"),
    "PRE-094": ("White vinegar", "Vinagre blanco"),
    "PRE-095": ("Balsamic vinegar", "Vinagre balsámico"),
    "PRE-096": ("Olive oil", "Aceite de oliva"),
    "PRE-097": ("Butter", "Mantequilla"),
    "PRE-098": ("Salt", "Sal"),
    "PRE-099": ("Pepper", "Pimienta"),
    "PRE-100": ("Garlic salt", "Sal de ajo"),
    "PRE-101": ("Onion salt", "Sal de cebolla"),
    "PRE-102": ("Maraschino cherries", "Cerezas en almíbar"),
    "PRE-103": ("Whipped cream", "Crema batida"),
    "PRE-104": ("New York steak", "Corte New York"),
    "PRE-105": ("Ribeye steak", "Corte Rib Eye"),
    "PRE-106": ("Filet mignon", "Filete mignon"),
    "PRE-107": ("Sirloin steak", "Corte Sirloin"),
    "PRE-108": ("Hamburger", "Carne para hamburguesa"),
    "PRE-109": ("Pork ribs, medium", "Costillas de cerdo, medianas"),
    "PRE-110": ("Whole chicken", "Pollo entero"),
    "PRE-111": ("Chicken breast fillet", "Pechuga de pollo en filete"),
    "PRE-112": ("Tofu", "Tofu"),
    "PRE-113": ("Salmon", "Salmón"),
    "PRE-114": ("Tuna", "Atún"),
    "PRE-115": ("Shrimp, small", "Camarón chico"),
    "PRE-116": ("Shrimp, medium", "Camarón mediano"),
    "PRE-117": ("Shrimp, large", "Camarón grande"),
    "PRE-118": ("Scallops", "Callo de hacha"),
    "PRE-119": ("Lobster tails, small", "Colas de langosta, chicas"),
    "PRE-120": ("Lobster tails, medium", "Colas de langosta, medianas"),
    "PRE-121": ("Squid", "Calamar"),
    "PRE-122": ("Octopus", "Pulpo"),
    "PRE-123": ("White fish (robalo)", "Pescado blanco (robalo)"),
    "PRE-124": ("Sea bass", "Lubina"),
    "PRE-125": ("Orange juice", "Jugo de naranja"),
    "PRE-126": ("Cranberry juice", "Jugo de arándano"),
    "PRE-127": ("Apple juice", "Jugo de manzana"),
    "PRE-128": ("Pineapple juice", "Jugo de piña"),
    "PRE-129": ("Sparkling water", "Agua mineral"),
    "PRE-130": ("Coconut water", "Agua de coco"),
    "PRE-131": ("Electrolyte drink, plain", "Suero electrolítico natural"),
    "PRE-132": ("Electrolyte drink, grape", "Suero electrolítico de uva"),
    "PRE-133": ("Electrolyte drink, strawberry", "Suero electrolítico de fresa"),
    "PRE-134": ("Electrolyte drink, coconut", "Suero electrolítico de coco"),
    "PRE-135": ("Nonfat milk", "Leche descremada"),
    "PRE-136": ("Low fat milk", "Leche semidescremada"),
    "PRE-137": ("Whole milk", "Leche entera"),
    "PRE-138": ("Chocolate milk", "Leche con chocolate"),
    "PRE-139": ("Sweet'N Low", "Sweet'N Low"),
    "PRE-140": ("Splenda", "Splenda"),
    "PRE-141": ("Vanilla coffee creamer", "Sustituto de crema para café, vainilla"),
    "PRE-142": ("Hazelnut coffee creamer", "Sustituto de crema para café, avellana"),
    "PRE-143": ("Cream", "Crema"),
    "PRE-144": ("Coca-Cola", "Coca-Cola"),
    "PRE-145": ("Coca-Cola Light 600 ml", "Coca-Cola Light 600 ml"),
    "PRE-146": ("Pepsi", "Pepsi"),
    "PRE-147": ("Sprite", "Sprite"),
    "PRE-148": ("7 Up", "7 Up"),
    "PRE-149": ("7 Up Diet", "7 Up Diet"),
    "PRE-150": ("Ginger ale", "Ginger ale"),
    "PRE-151": ("Orange soda", "Refresco de naranja"),
    "PRE-152": ("Squirt", "Squirt"),
    "PRE-153": ("Jarritos, mixed flavors", "Jarritos, sabores surtidos"),
    "PRE-154": ("Clamato", "Clamato"),
    "PRE-155": ("Tomato juice", "Jugo de tomate"),
    "PRE-156": ("San Pellegrino mineral water 750 ml", "Agua mineral San Pellegrino 750 ml"),
    "PRE-157": ("San Pellegrino Aranciata 330 ml", "San Pellegrino Aranciata 330 ml"),
    "PRE-158": ("Club soda", "Agua quina"),
    "PRE-159": ("OFF! bug repellent spray", "Repelente de insectos OFF! en aerosol"),
    "PRE-160": ("OFF! bug repellent cream", "Repelente de insectos OFF! en crema"),
    "PRE-161": ("Sunscreen SPF 30", "Protector solar FPS 30"),
    "PRE-162": ("Sunscreen SPF 50", "Protector solar FPS 50"),
    "PRE-163": ("Toothbrush and toothpaste", "Cepillo y pasta de dientes"),
    "PRE-164": ("Hair gel", "Gel para el cabello"),
    "PRE-165": ("Comb", "Peine"),
    "PRE-166": ("Aloe vera after-sun gel", "Gel de aloe vera para después del sol"),
    "PRE-167": ("Pepto-Bismol", "Pepto-Bismol"),
    "PRE-168": ("Aspirin", "Aspirina"),
    "PRE-169": ("Tylenol", "Tylenol"),
    "PRE-170": ("Baking soda", "Bicarbonato de sodio"),
    "PRE-171": ("Dramamine", "Dramamine"),
}


def read_rows(path):
    """Return {row_number: {column_letter: value}} for the first sheet."""
    with zipfile.ZipFile(path) as z:
        shared = []
        if "xl/sharedStrings.xml" in z.namelist():
            for si in ET.fromstring(z.read("xl/sharedStrings.xml")).findall("m:si", NS):
                shared.append("".join(t.text or "" for t in si.iter(f"{{{NS['m']}}}t")))
        sheet = ET.fromstring(z.read("xl/worksheets/sheet1.xml"))
    rows = {}
    for row in sheet.find("m:sheetData", NS):
        cells = {}
        for c in row:
            v = c.find("m:v", NS)
            if v is None:
                continue
            value = shared[int(v.text)] if c.get("t") == "s" else v.text
            cells[re.sub(r"\d", "", c.get("r"))] = value.strip()
        rows[int(row.get("r"))] = cells
    return rows


def money(value):
    return round(float(value), 2)


def protein_per_oz():
    """SKU -> (guest USD per oz, net MXN per oz): columns F and D of the protein calculator."""
    prices = {}
    for cells in read_rows(PROTEIN_XLSX).values():
        sku = cells.get("A", "")
        if sku.startswith("PRE-") and cells.get("F"):
            prices[sku] = (round(float(cells["F"]), 4), round(float(cells["D"]), 4))
    return prices


def build_items():
    per_oz = protein_per_oz()
    items = []
    for cells in read_rows(CATALOG_XLSX).values():
        sku = cells.get("A", "")
        if not sku.startswith("PRE-"):
            continue
        en, es = NAMES[sku]
        category = CATEGORIES.get(cells["B"], cells["B"])
        item = {
            "sku": sku,
            "category": category,
            "name": {"en": en, "es": es},
            "priceUSD": money(cells["G"]),
            "netCostMXN": money(cells["E"]),
            "sourceUrl": cells.get("D") or None,
            "pricingUnit": "ITEM",
            "portionOzOptions": [],
            "order": len(items) + 1,
        }
        if sku in per_oz:
            usd, net = per_oz[sku]
            item.update(priceUSD=usd, netCostMXN=net, pricingUnit="OZ", portionOzOptions=PORTION_OZ)
        items.append(item)
    return items


def validate(items):
    skus = [i["sku"] for i in items]
    assert len(skus) == len(set(skus)), "duplicate SKU"
    assert set(skus) == set(NAMES), f"name table mismatch: {set(skus) ^ set(NAMES)}"
    for i in items:
        assert i["priceUSD"] > 0, f"{i['sku']} has no guest price"
        assert i["name"]["en"] and i["name"]["es"], f"{i['sku']} missing a name"


def main():
    items = build_items()
    validate(items)
    service = json.loads(TERMS_FILE.read_text(encoding="utf-8"))
    OUT.write_text(json.dumps({"source": [CATALOG_XLSX.name, PROTEIN_XLSX.name], "service": service, "items": items},
                              ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    oz = sum(1 for i in items if i["pricingUnit"] == "OZ")
    print(f"{len(items)} items ({oz} priced per oz) -> {OUT.name}")


if __name__ == "__main__":
    sys.exit(main())
