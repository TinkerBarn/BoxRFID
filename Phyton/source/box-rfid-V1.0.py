import customtkinter as ctk
from tkinter import messagebox
from smartcard.System import readers
import threading
import time

# ================================
# DATABASE
# ================================
MATERIALS = {
    "PLA": 1, "PLA Matte": 2, "PLA Metal": 3, "PLA Silk": 4, "PLA-CF": 5, "PLA-Wood": 6,
    "PLA Basic": 7, "PLA Matte Basic": 8, "ABS": 11, "ABS-GF": 12, "ABS-Metal": 13, "ABS-Odorless": 14,
    "ASA": 18, "ASA-AERO": 19, "UltraPA": 24, "PA12-CF": 25, "UltraPA-CF25": 26, "PAHT-CF": 30,
    "PAHT-GF": 31, "Support For PAHT": 32, "Support For PET/PA": 33, "PC/ABS-FR": 34,
    "PET-CF": 37, "PET-GF": 38, "PETG Basic": 39, "PETG-Though": 40, "PETG": 41, "PPS-CF": 44,
    "PETG Translucent": 45, "PVA": 47, "TPU-AERO": 49, "TPU": 50
}
   
MATERIALS_REV = {v: k for k, v in MATERIALS.items()}

COLORS = {
    "#FAFAFA": {"de": "Weiß", "en": "White", "val": 1},
    "#060606": {"de": "Schwarz", "en": "Black", "val": 2},
    "#D9E3ED": {"de": "Grau", "en": "Gray", "val": 3},
    "#5CF30F": {"de": "Hellgrün", "en": "Light Green", "val": 4},
    "#63E492": {"de": "Mint", "en": "Mint", "val": 5},
    "#2850FF": {"de": "Blau", "en": "Blue", "val": 6},
    "#FE98FE": {"de": "Pink", "en": "Pink", "val": 7},
    "#DFD628": {"de": "Gelb", "en": "Yellow", "val": 8},
    "#228332": {"de": "Grün", "en": "Green", "val": 9},
    "#99DEFF": {"de": "Hellblau", "en": "Light Blue", "val": 10},
    "#1714B0": {"de": "Dunkelblau", "en": "Dark Blue", "val": 11},
    "#CEC0FE": {"de": "Lavendel", "en": "Lavender", "val": 12},
    "#CADE4B": {"de": "Lime", "en": "Lime", "val": 13},
    "#1353AB": {"de": "Royalblau", "en": "Royal Blue", "val": 14},
    "#5EA9FD": {"de": "Himmelblau", "en": "Sky Blue", "val": 15},
    "#A878FF": {"de": "Violett", "en": "Violet", "val": 16},
    "#FE717A": {"de": "Rosa", "en": "Rose", "val": 17},
    "#FF362D": {"de": "Rot", "en": "Red", "val": 18},
    "#E2DFCD": {"de": "Beige", "en": "Beige", "val": 19},
    "#898F9B": {"de": "Silber", "en": "Silver", "val": 20},
    "#6E3812": {"de": "Braun", "en": "Brown", "val": 21},
    "#CAC59F": {"de": "Khaki", "en": "Khaki", "val": 22},
    "#F28636": {"de": "Orange", "en": "Orange", "val": 23},
    "#B87F2B": {"de": "Bronze", "en": "Bronze", "val": 24},
}
COLORS_REV = {v["val"]: (k, v) for k, v in COLORS.items()}

# ================================
# LANGUAGE SETTINGS
# ================================
LANG = {
    "de": {
        "title": "BoxRFID Manager für QIDI Box",
        "material": "Materialtyp auswählen",
        "color": "Farbe auswählen",
        "write": "TAG SCHREIBEN",
        "read": "TAG LESEN",
        "done": "Schreiben abgeschlossen!",
        "error": "Fehler",
        "select_valid": "Bitte gültiges Material und Farbe auswählen",
        "no_color": "Keine Farbe ausgewählt",
        "tag_info": "Tag Informationen",
        "empty_tag": "Leerer RFID Tag",
        "no_reader": "Kein Lesegerät gefunden!",
        "no_key": "Kein gültiger Schlüssel gefunden",
        "auth_failed": "Authentifizierung fehlgeschlagen",
        "write_failed": "Schreiben fehlgeschlagen",
        "read_failed": "Lesen fehlgeschlagen",
        "unknown": "Unbekannt",
        "auto_detect": "Auto-Erkennung"
    },
    "en": {
        "title": "BoxRFID Manager for QIDI Box",
        "material": "Select Material",
        "color": "Select Color",
        "write": "WRITE TAG",
        "read": "READ TAG",
        "done": "Write completed!",
        "error": "Error",
        "select_valid": "Please select valid material and color",
        "no_color": "No color selected",
        "tag_info": "Tag Information",
        "empty_tag": "Empty RFID Tag",
        "no_reader": "No reader found!",
        "no_key": "No valid key found",
        "auth_failed": "Authentication failed",
        "write_failed": "Write failed",
        "read_failed": "Read failed",
        "unknown": "Unknown",
        "auto_detect": "Auto Detection"
    }
}
current_lang = "de"

# ================================
# RFID FUNCTIONS
# ================================
DATA_BLOCK = 4
KEYS_TO_TRY = [
    [0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7],
    [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
]

# Global variables for tag detection
auto_detect_active = False
current_tag_present = False
last_tag_data = None

def connect_reader():
    """Establish connection to RFID reader"""
    try:
        r = readers()
        if not r:
            raise Exception(LANG[current_lang]["no_reader"])
        conn = r[0].createConnection()
        conn.connect()
        return conn
    except Exception as e:
        raise Exception(LANG[current_lang]["no_reader"])

def load_key(conn, key):
    """Load authentication key to reader"""
    LOAD_KEY = [0xFF, 0x82, 0x00, 0x00, 0x06] + key
    _, sw1, sw2 = conn.transmit(LOAD_KEY)
    return (sw1 == 0x90 and sw2 == 0x00)

def authenticate_block(conn, block, key_type=0x60):
    """Authenticate access to block"""
    AUTH_BLOCK = [0xFF, 0x86, 0x00, 0x00, 0x05,
                  0x01, 0x00, block, key_type, 0x00]
    _, sw1, sw2 = conn.transmit(AUTH_BLOCK)
    return (sw1 == 0x90 and sw2 == 0x00)

def find_working_key(conn, block):
    """Find a working authentication key"""
    for key in KEYS_TO_TRY:
        if load_key(conn, key) and authenticate_block(conn, block):
            return key
    raise Exception(LANG[current_lang]["no_key"])

def write_tag(material_num, color_num, value_num=1):
    """Write data to RFID tag"""
    conn = connect_reader()
    working_key = find_working_key(conn, DATA_BLOCK)

    if not load_key(conn, working_key) or not authenticate_block(conn, DATA_BLOCK):
        raise Exception(LANG[current_lang]["auth_failed"])

    data_bytes = [material_num, color_num, value_num] + [0x00]*13
    WRITE_BLOCK = [0xFF, 0xD6, 0x00, DATA_BLOCK, 0x10] + data_bytes
    _, sw1, sw2 = conn.transmit(WRITE_BLOCK)

    if sw1 != 0x90 or sw2 != 0x00:
        raise Exception(LANG[current_lang]["write_failed"])

    conn.disconnect()
    messagebox.showinfo("OK", LANG[current_lang]["done"])

def read_tag():
    """Read data from RFID tag"""
    global last_tag_data
    
    try:
        conn = connect_reader()
        working_key = find_working_key(conn, DATA_BLOCK)

        if not load_key(conn, working_key) or not authenticate_block(conn, DATA_BLOCK):
            raise Exception(LANG[current_lang]["auth_failed"])

        READ_BLOCK = [0xFF, 0xB0, 0x00, DATA_BLOCK, 0x10]
        data, sw1, sw2 = conn.transmit(READ_BLOCK)

        if sw1 != 0x90 or sw2 != 0x00:
            raise Exception(LANG[current_lang]["read_failed"])

        material_val = data[0]
        color_val = data[1]
        
        # Store tag data for comparison
        last_tag_data = (material_val, color_val)
        
        # Check if tag is empty (all zeros or default values)
        if material_val == 0 and color_val == 0:
            show_tag_info(LANG[current_lang]["empty_tag"], "#FFFFFF", "")
            conn.disconnect()
            return True
        else:
            material_name = MATERIALS_REV.get(material_val, LANG[current_lang]["unknown"])
            color_hex, color_dict = COLORS_REV.get(color_val, ("#FFFFFF", {"de": LANG[current_lang]["unknown"], "en": LANG[current_lang]["unknown"]}))
            show_tag_info(material_name, color_hex, color_dict[current_lang])
            
        conn.disconnect()
        return True
        
    except Exception as e:
        # Connection error - tag might be removed
        print(f"Read error: {e}")
        return False

def check_tag_presence():
    """Quick check if a tag is present without full authentication"""
    try:
        # Try to get readers list - this is a quick operation
        r = readers()
        if not r:
            return False
            
        # Try to create a connection
        conn = r[0].createConnection()
        # Try to connect with a short timeout
        conn.connect()
        
        # If we get here, a tag is present
        return True
        
    except:
        # Any error means no tag is present
        return False

def auto_detect_tag():
    """Background thread to automatically detect and read tags"""
    global current_tag_present, last_tag_data
    
    tag_present = False
    tag_removed_timestamp = 0
    tag_removed_delay = 1.0  # 1 second delay before clearing display after tag removal
    
    while auto_detect_active:
        try:
            # Check if tag is present
            tag_now_present = check_tag_presence()
            
            if tag_now_present and not tag_present:
                # Tag was just placed - read it
                print("Tag detected, reading...")
                if read_tag():
                    tag_present = True
                    current_tag_present = True
                    tag_removed_timestamp = 0
                time.sleep(0.2)  # Short delay after successful read
            
            elif not tag_now_present and tag_present:
                # Tag was just removed
                print("Tag removed")
                if tag_removed_timestamp == 0:
                    tag_removed_timestamp = time.time()
                elif time.time() - tag_removed_timestamp > tag_removed_delay:
                    # Tag has been removed for longer than the delay period
                    tag_present = False
                    current_tag_present = False
                    last_tag_data = None
                    # Clear the display
                    root.after(0, lambda: show_tag_info("---", "#FFFFFF", "---"))
            
            elif tag_now_present and tag_present:
                # Tag is still present, check if it's the same tag
                try:
                    # Quick check if tag is still the same
                    if check_tag_presence():
                        # Tag is still there, no need to do anything
                        pass
                except:
                    # Tag might have been replaced
                    if read_tag():
                        tag_removed_timestamp = 0
            
            time.sleep(0.3)  # Check frequently for quick response
            
        except Exception as e:
            # If any error occurs in the detection loop, wait a bit and continue
            print(f"Auto-detect error: {e}")
            time.sleep(1)
            tag_present = False

# ================================
# GUI
# ================================
ctk.set_appearance_mode("light")
ctk.set_default_color_theme("blue")

# Create main window
root = ctk.CTk()
root.title(LANG[current_lang]["title"])
root.geometry("500x750")

# Main frame
main_frame = ctk.CTkFrame(root, corner_radius=15, fg_color="white")
main_frame.pack(padx=20, pady=20, fill="both", expand=True)

# Header with language selector
header_frame = ctk.CTkFrame(main_frame, fg_color="white", height=40)
header_frame.pack(fill="x", padx=10, pady=(10, 5))

title_label = ctk.CTkLabel(header_frame, text=LANG[current_lang]["title"],
                           font=("Segoe UI", 18, "bold"), text_color="black")
title_label.pack(side="left", padx=10)

# Compact language selector
def switch_lang():
    """Switch between German and English"""
    global current_lang
    current_lang = "en" if current_lang == "de" else "de"
    update_labels()

lang_btn = ctk.CTkButton(header_frame, text="DE/EN", command=switch_lang,
                         width=60, height=30, 
                         fg_color="#2b2b2b", hover_color="#3b3b3b", text_color="white",
                         font=("Segoe UI", 10, "bold"), corner_radius=6)
lang_btn.pack(side="right", padx=10)

# Material selection
mat_label = ctk.CTkLabel(main_frame, text=LANG[current_lang]["material"],
                         font=("Segoe UI", 14, "bold"), text_color="black")
mat_label.pack(pady=5)

material_var = ctk.StringVar()

# Custom OptionMenu for better styling
class CustomOptionMenu(ctk.CTkOptionMenu):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Configure the dropdown menu
        self._dropdown_menu.configure(font=("Segoe UI", 14, "bold"))

# Create custom option menu with larger font
material_combo = CustomOptionMenu(main_frame, values=list(MATERIALS.keys()), variable=material_var,
                                 fg_color="#f1f1f1", button_color="#f1f1f1", text_color="black",
                                 font=("Segoe UI", 14, "bold"),  # Larger font for selected value
                                 dropdown_font=("Segoe UI", 12, "bold"),  # Bold font for dropdown items
                                 width=220, height=35)
material_combo.pack(pady=5)

# Color selection
col_label = ctk.CTkLabel(main_frame, text=LANG[current_lang]["color"],
                         font=("Segoe UI", 14, "bold"), text_color="black")
col_label.pack(pady=5)

color_var = ctk.StringVar()
color_preview = ctk.CTkLabel(main_frame, text=LANG[current_lang]["no_color"], width=220, height=40,
                             corner_radius=8, fg_color="white", text_color="black", 
                             font=("Segoe UI", 14, "bold"))
color_preview.pack(pady=10)

# Color palette 8x3
color_frame = ctk.CTkFrame(main_frame, fg_color="white")
color_frame.pack(pady=5)

def select_color(hex_code, name):
    """Handle color selection"""
    color_var.set(hex_code)
    text_color = "black" if hex_code in ["#FAFAFA", "#D9E3ED", "#99DEFF", "#CEC0FE", 
                                         "#CADE4B", "#E2DFCD", "#CAC59F"] else "white"
    color_preview.configure(text=name, fg_color=hex_code, text_color=text_color)

# Create color buttons
row, col = 0, 0
for hex_code, vals in COLORS.items():
    btn = ctk.CTkButton(color_frame, text="", width=40, height=40, fg_color=hex_code,
                        hover_color=hex_code, corner_radius=6,
                        command=lambda h=hex_code, v=vals: select_color(h, v[current_lang]))
    btn.grid(row=row, column=col, padx=3, pady=3)
    col += 1
    if col >= 8: 
        col, row = 0, row + 1

# Action buttons
def on_write():
    """Handle write button click"""
    mat = material_var.get()
    col_hex = color_var.get()
    if mat not in MATERIALS or col_hex not in COLORS:
        messagebox.showerror(LANG[current_lang]["error"], LANG[current_lang]["select_valid"])
        return
    try:
        write_tag(MATERIALS[mat], COLORS[col_hex]["val"], 1)
    except Exception as e:
        messagebox.showerror(LANG[current_lang]["error"], str(e))

write_btn = ctk.CTkButton(main_frame, text=LANG[current_lang]["write"], command=on_write,
                          fg_color="#28a745", hover_color="#218838", text_color="white",
                          font=("Segoe UI", 14, "bold"), corner_radius=12, height=45)
write_btn.pack(pady=(20, 10), fill="x", padx=40)

read_btn = ctk.CTkButton(main_frame, text=LANG[current_lang]["read"], command=read_tag,
                         fg_color="#007bff", hover_color="#0069d9", text_color="white",
                         font=("Segoe UI", 14, "bold"), corner_radius=12, height=45)
read_btn.pack(pady=(0, 10), fill="x", padx=40)

# Auto-detection button
def toggle_auto_detect():
    """Toggle automatic tag detection"""
    global auto_detect_active
    
    auto_detect_active = not auto_detect_active
    
    if auto_detect_active:
        # Activated - green with filled circle
        auto_detect_btn.configure(text="⏺️ " + LANG[current_lang]["auto_detect"], 
                                 fg_color="#28a745", hover_color="#218838")
        # Start detection thread
        detection_thread = threading.Thread(target=auto_detect_tag, daemon=True)
        detection_thread.start()
    else:
        # Deactivated - gray with empty circle
        auto_detect_btn.configure(text="⭕ " + LANG[current_lang]["auto_detect"], 
                                 fg_color="#6c757d", hover_color="#5a6268")

auto_detect_btn = ctk.CTkButton(main_frame, text="⭕ " + LANG[current_lang]["auto_detect"], 
                                command=toggle_auto_detect,
                                fg_color="#6c757d", hover_color="#5a6268", text_color="white",
                                font=("Segoe UI", 12), corner_radius=8, height=35)
auto_detect_btn.pack(pady=(0, 15))

# Info section with darker background
info_frame = ctk.CTkFrame(main_frame, corner_radius=12, fg_color="#e9ecef")
info_frame.pack(pady=10, fill="x", padx=20)

info_title = ctk.CTkLabel(info_frame, text=LANG[current_lang]["tag_info"],
                          font=("Segoe UI", 15, "bold"), text_color="black")
info_title.pack(pady=5)

# Material info with larger, bold font
info_material = ctk.CTkLabel(info_frame, text="---", 
                             font=("Segoe UI", 18, "bold"), text_color="black")
info_material.pack(pady=5)

info_color = ctk.CTkLabel(info_frame, text="---", width=200, height=50, corner_radius=8,
                          fg_color="white", font=("Segoe UI", 14), text_color="black")
info_color.pack(pady=10)

def show_tag_info(material, hex_code, name):
    """Display tag information with improved formatting"""
    # Display material in larger, bold font
    info_material.configure(text=material, font=("Segoe UI", 18, "bold"))
    
    if name:  # If we have a color name
        text_color = "black" if hex_code in ["#FAFAFA", "#D9E3ED", "#99DEFF", "#CEC0FE", 
                                           "#CADE4B", "#E2DFCD", "#CAC59F"] else "white"
        info_color.configure(text=name, fg_color=hex_code, text_color=text_color, 
                            font=("Segoe UI", 14, "bold"))
    else:  # Empty tag or no tag
        info_color.configure(text="---", fg_color="#FFFFFF", text_color="black",
                            font=("Segoe UI", 14))

def update_labels():
    """Update all UI labels when language changes"""
    root.title(LANG[current_lang]["title"])
    title_label.configure(text=LANG[current_lang]["title"])
    mat_label.configure(text=LANG[current_lang]["material"])
    col_label.configure(text=LANG[current_lang]["color"])
    color_preview.configure(text=LANG[current_lang]["no_color"])
    write_btn.configure(text=LANG[current_lang]["write"])
    read_btn.configure(text=LANG[current_lang]["read"])
    info_title.configure(text=LANG[current_lang]["tag_info"])
    
    # Update auto detect button text
    if auto_detect_active:
        auto_detect_btn.configure(text="⏺️ " + LANG[current_lang]["auto_detect"])
    else:
        auto_detect_btn.configure(text="⭕ " + LANG[current_lang]["auto_detect"])
    
    # Update color buttons with new language
    for hex_code, vals in COLORS.items():
        if color_var.get() == hex_code:
            select_color(hex_code, vals[current_lang])

# Start the application
root.mainloop()