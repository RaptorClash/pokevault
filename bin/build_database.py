import urllib.request
import urllib.error
import json
import sqlite3
import os
import re
import time
import openpyxl
from bs4 import BeautifulSoup
from database_constants import *

POKEMON_NAME_TO_ID = {}

def normalize_name(name):
    n = name.lower().replace('♀', 'f').replace('♂', 'm')
    return re.sub(r'[^a-z0-9]', '', n)

def get_id_by_name(name):
    n = normalize_name(name)
    if not n: return -1 
    return POKEMON_NAME_TO_ID.get(n, -1)

API_CACHE = {}

def fetch_json(url_or_path):
    if url_or_path.startswith("/api/v2/"):
        url_or_path = "https://pokeapi.co" + url_or_path

    if url_or_path in API_CACHE:
        return API_CACHE[url_or_path]

    if url_or_path.startswith("https://pokeapi.co/api/v2/"):
        local_path = url_or_path.replace("https://pokeapi.co/api/v2/", "bin/api-data/data/api/v2/")
        local_path = local_path.rstrip('/') + '/index.json'
        
        if os.path.exists(local_path):
            try:
                with open(local_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    API_CACHE[url_or_path] = data
                    return data
            except Exception:
                pass

    time.sleep(0.05)
    for _ in range(3):
        try:
            req = urllib.request.Request(url_or_path, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode())
                API_CACHE[url_or_path] = data
                return data
        except urllib.error.HTTPError as e:
            if e.code == 404: 
                API_CACHE[url_or_path] = None
                return None
            time.sleep(1)
        except Exception:
            time.sleep(1)
            
    return None

def clean_location(raw_loc):
    loc = raw_loc.lower()
    loc = re.sub(r'-?area$', '', loc)
    loc = re.sub(r'-?(south|north|east|west)-towards.*$', '', loc)
    loc = re.sub(r'-?(before|after)-galactic-intervention$', '', loc)
    loc = re.sub(r'^(kanto|johto|hoenn|sinnoh|unova|kalos|alola|galar|paldea|hisui)-', '', loc)
    loc = loc.replace('sea-route-', 'Sea Route ').replace('route-', 'Route ')
    if '-' in loc or ' ' in loc:
        loc = ' '.join([w.capitalize() for w in re.split(r'[- ]', loc) if w])
    else:
        if loc: loc = loc.capitalize()
    return loc.strip()

def parse_chain(node):
    species_url = node['species']['url']
    species_id = int(species_url.strip('/').split('/')[-1])
    evolves_to = [parse_chain(n) for n in node.get('evolves_to', [])]
    return {
        'species_id': species_id,
        'is_baby': node.get('is_baby', False),
        'evolves_to': evolves_to
    }

def get_gen_by_id(pid):
    if pid <= 151: return 1
    if pid <= 251: return 2
    if pid <= 386: return 3
    if pid <= 493: return 4
    if pid <= 649: return 5
    if pid <= 721: return 6
    if pid <= 809: return 7
    if pid <= 905: return 8
    return 9

def get_url(cell_value):
    if not isinstance(cell_value, str):
        return None
    match = re.search(r'(https?://[^\s"<>&\u0027\)]+)', cell_value)
    return match.group(1) if match else None

def get_form(name, is_direct=False):
    name = str(name).lower().replace('é', 'e').replace('è', 'e').strip()
    
    if is_direct:
        return re.sub(r'\s+', '-', name).replace("'", "")
        
    if 'alola' in name: return 'alola'
    if 'galar' in name: return 'galar'
    if 'hisui' in name: return 'hisui'
    if 'paldea' in name: return 'paldea'
    
    name_check = name.replace('*', '').strip()
    words = name_check.replace('(', ' ').replace(')', ' ').split()
    if 'mega' in words:
        if 'x' in words or 'x)' in name_check: return 'mega-x'
        if 'y' in words or 'y)' in name_check: return 'mega-y'
        return 'mega'
        
    if 'primal' in name: return 'primal'
    if 'gmax' in name or 'gigantamax' in name: return 'gmax'
    
    if '(' in name:
        form_part = name.split('(')[1].replace(')', '').strip()
        form_part = form_part.lower().replace('é', 'e').replace('è', 'e')
        
        base_forms = [
            'no plate', 'altered', 'land', 'incarnate', 'aria', 'ordinary',
            'shield', '50%', 'confined', 'baile', 'midday', 'solo', 'red core',
            'disguised', 'amped', 'ice face', 'full belly', 'single strike',
            'hero', 'chest', 'family of four', 'green plumage', 'curly', 'plant', 'west',
            'spring', 'normal', 'base', 'standard', 'red-striped', 'red meteor', 'red',
            'natural'
        ]
        if form_part in base_forms:
            return 'normal'
            
        return re.sub(r'\s+', '-', form_part).replace("'", "")
        
    return 'normal'

def to_key(name):
    return name.lower().replace('é', 'e').replace('è', 'e').replace(' ', '_').strip()

def scrape_pokewiki_marks(html_path):
    if not os.path.exists(html_path): return {}
    with open(html_path, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')

    pw_marks = {}
    tables = soup.find_all('table', class_=re.compile('jquery-tablesorter'))
    for table in tables:
        tbody = table.find('tbody')
        if not tbody: continue
        for tr in tbody.find_all('tr'):
            tds = tr.find_all('td')
            if len(tds) < 5: continue
            
            name_de = tds[1].get_text(separator=' ').strip()
            title_de = tds[2].get_text(separator=' ').strip()
            desc_de = tds[3].get_text(separator='\n').strip()
            location_de = tds[4].get_text(separator='\n').strip()
            location_de = re.sub(r'\n+', '\n', location_de)

            en_id = MARK_DE_TO_EN_ID.get(name_de)
            if en_id:
                pw_marks[en_id] = {
                    "name_de": name_de,
                    "desc_de": desc_de,
                    "title_de": title_de,
                    "location_de": location_de
                }
    return pw_marks

def extract_original_image_url(srcset):
    if not srcset: return ""
    try:
        first_url = srcset.split(' ')[0]
        original_url = first_url.replace('/thumb', '')
        original_url = '/'.join(original_url.split('/')[:-1])
        return original_url
    except:
        return ""

def scrape_pokewiki_ribbons(html_path):
    if not os.path.exists(html_path): return {}
    with open(html_path, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')

    pw_db = {}
    for band_div in soup.find_all('div', class_='band'):
        try:
            name_en_tag = band_div.find('span', lang='en')
            if not name_en_tag: continue
            name_en = name_en_tag.text.strip()
            r_id = name_en.lower().replace(' ', '-').replace('_', '-').replace("'", "")

            name_de_tag = band_div.find('div', class_='name')
            name_de = name_de_tag.text.strip() if name_de_tag else name_en
            img_url_pw = ""
            if name_de_tag:
                img_tag = name_de_tag.find('img')
                if img_tag:
                    img_url_pw = extract_original_image_url(img_tag.get('srcset', ''))
                    if not img_url_pw: img_url_pw = img_tag.get('src', '')
                    if img_url_pw.startswith('/'): img_url_pw = 'https://www.pokewiki.de' + img_url_pw

            desc_tags = band_div.find_all('div', class_=re.compile(r'desc text'))
            desc_de = desc_tags[-1].get_text(separator='\n').strip() if desc_tags else "Keine Beschreibung verfügbar."
            title_tag = band_div.find('div', class_=re.compile(r'title-text title'))
            title_de = title_tag.text.strip() if title_tag else ""

            places = []
            for place_div in band_div.find_all('div', class_=re.compile(r'place text')):
                place_text = place_div.get_text(separator=' | ').strip()
                if place_text and place_text not in places:
                    places.append(place_text)
            location_de = "\n".join(places)

            pw_db[r_id] = {
                "name_de": name_de,
                "desc_de": desc_de,
                "title_de": title_de,
                "location_de": location_de,
                "image_url": img_url_pw
            }
        except Exception: pass
    return pw_db

def get_ribbons_from_submodule():
    possible_paths = [
        'bin/ribbons_guide/data/ribbons.json',
        'ribbons_guide/data/ribbons.json',
        'data/ribbons.json',
        '../bin/ribbons_guide/data/ribbons.json'
    ]
    json_path = None
    for p in possible_paths:
        if os.path.exists(p):
            json_path = p
            break
            
    if not json_path: return {}
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            ribbons_data = json.load(f)
            
        formatted_ribbons = {}
        for r_id, r_info in ribbons_data.items():
            avail = r_info.get('available', [])
            if not isinstance(avail, list):
                avail = []
            formatted_ribbons[r_id] = {
                "is_mark": 1 if r_info.get('isMark') else 0,
                "min_gen": r_info.get('generation', 3),
                "name_en": r_info.get('name', r_id.replace('-', ' ').title()),
                "desc_en": r_info.get('description', "No description available."),
                "available_games": ",".join([str(x) for x in avail])
            }
        return formatted_ribbons
    except Exception as e:
        return {}


def scrape_bulbapedia_gifts(html_path):
    print(f"-> Scrape Bulbapedia Geschenke aus: {html_path}")
    if not os.path.exists(html_path): return []

    with open(html_path, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')

    gifts = []
    current_game = "Unknown"

    for tag in soup.find_all(['h2', 'h3', 'h4', 'table']):
        if tag.name in ['h2', 'h3', 'h4']:
            headline = tag.find('span', class_='mw-headline')
            if headline:
                text = headline.text.strip()
                if text in ["In animation", "In the manga", "Related articles", "In the anime", "In the TCG", "In Pokémon Stadium", "In Pokémon Stadium 2"]:
                    break
                
                if "Generation I" in text and "II" not in text and "III" not in text: 
                    current_game = "Rot/Blau/Gelb"
                elif "Generation II" in text and "III" not in text: 
                    current_game = "Gold/Silber/Kristall"
                elif "Generation" not in text:
                    current_game = text
                    
        elif tag.name == 'table' and 'roundy' in tag.get('class', []):
            if "Unknown" in current_game: continue
            
            last_loc = "Unbekannt"
            last_level = 5
            last_notes = ""
            
            for row in tag.find_all('tr'):
                tds = row.find_all(['td', 'th'])
                if not tds or len(tds) < 2: continue
                
                try:
                    poke_a = None
                    for cell in tds[:3]:
                        links = cell.find_all('a')
                        for a in links:
                            if get_id_by_name(a.text.strip()) != -1:
                                poke_a = a
                                break
                        if poke_a: break
                        
                    if not poke_a: continue
                    
                    poke_name = poke_a.text.strip()
                    pid = get_id_by_name(poke_name)
                    if pid == -1: continue

                    if len(tds) >= 5:
                        last_loc = tds[-3].text.strip()
                        level_str = tds[-2].text.strip()
                        last_notes = tds[-1].text.strip()
                        
                        level_match = re.search(r'\d+', level_str)
                        last_level = int(level_match.group()) if level_match else 5

                    form = 'normal'
                    n_lower = last_notes.lower()
                    if 'alolan' in n_lower: form = 'alola'
                    elif 'galarian' in n_lower: form = 'galar'
                    elif 'hisuian' in n_lower: form = 'hisui'
                    elif 'paldean' in n_lower: form = 'paldea'
                    elif 'totem-like' in n_lower: form = 'totem'

                    gifts.append({
                        "pokemon_id": pid,
                        "given_pokemon_id": -1,
                        "obtain_type": "gift",
                        "game_version": current_game,
                        "location": last_loc,
                        "npc_name": "",
                        "nickname": "",
                        "ot_name": "Spieler",
                        "level": last_level,
                        "nature": "Zufall",
                        "ability": "Standard",
                        "item": "",
                        "is_n_pokemon": 0,
                        "notes": last_notes,
                        "form": form
                    })
                except Exception:
                    pass
                    
    print(f"-> {len(gifts)} Geschenke von Bulbapedia geladen.")
    return gifts

def scrape_wikis_trades_and_gifts(html_path, obtain_type="trade"):
    print(f"-> Scrape Wiki Daten ({obtain_type}): {html_path}")
    if not os.path.exists(html_path): return []

    with open(html_path, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')

    results = []
    tables = soup.find_all('table', class_=re.compile(r'roundtable|lastisroundtable|roundy'))
    
    for table in tables:
        header = table.find_previous(['h2', 'h3', 'h4'])
        game_version = header.text.strip().replace('[edit]', '') if header else "Unknown"
        
        gv_lower = game_version.lower()
        if "unused" in gv_lower or "debug" in gv_lower or "test" in gv_lower or game_version in ["In animation", "In the manga", "Related articles", "In the anime"]:
            continue

        if "generation i" in gv_lower or "1. generation" in gv_lower:
            game_version = "Rot/Blau/Gelb"
        elif "generation ii" in gv_lower or "2. generation" in gv_lower:
            game_version = "Gold/Silber/Kristall"
            
        last_loc = "Unknown"
        for row in table.find_all('tr'):
            tds = row.find_all('td')
            if not tds: continue
            
            row_text = row.get_text(separator=' | ', strip=True)
            rt_lower = row_text.lower()
            
            if "unused" in rt_lower or "debug" in rt_lower or "beta" in rt_lower or "test trade" in rt_lower:
                continue

            try:
                poke_ids_in_row = []
                for td in tds:
                    for a in td.find_all('a'):
                        txt = a.text.strip()
                        pid = get_id_by_name(txt)
                        if pid == -1 and a.get('title'): pid = get_id_by_name(a['title'].strip())
                        if pid != -1 and pid not in poke_ids_in_row:
                            poke_ids_in_row.append(pid)
                
                if not poke_ids_in_row: continue
                
                loc = tds[0].text.strip()[:50] if len(tds) >= 3 else last_loc
                last_loc = loc
                
                given_id = -1
                received_id = poke_ids_in_row[0]
                
                if obtain_type == "trade" and len(poke_ids_in_row) >= 2:
                    given_id = poke_ids_in_row[0]
                    received_id = poke_ids_in_row[1]
                
                is_n = 1 if " N " in row_text or "N's" in row_text else 0
                form = 'normal'
                if 'alola' in rt_lower or 'alolan' in rt_lower: form = 'alola'
                elif 'galar' in rt_lower or 'galarian' in rt_lower: form = 'galar'
                elif 'hisui' in rt_lower or 'hisuian' in rt_lower: form = 'hisui'
                elif 'paldea' in rt_lower or 'paldean' in rt_lower: form = 'paldea'
                
                if obtain_type == "trade" and "let's go" in gv_lower: form = 'alola'

                results.append({
                    "pokemon_id": received_id,
                    "given_pokemon_id": given_id,
                    "obtain_type": obtain_type,
                    "game_version": game_version,
                    "location": loc,
                    "npc_name": "", 
                    "nickname": "",
                    "ot_name": "N" if is_n else "",
                    "level": 0,
                    "nature": "Festgelegt",
                    "ability": "Standard",
                    "item": "",
                    "is_n_pokemon": is_n,
                    "notes": row_text[:200],
                    "form": form
                })
            except Exception: pass
    return results

def scrape_pokewiki_ns_pokemon(html_path):
    print(f"-> Scrape N's Pokémon aus: {html_path}")
    if not os.path.exists(html_path): return []

    with open(html_path, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')

    results = []
    for event_div in soup.find_all('div', class_='event-pokemon'):
        try:
            name_tag = event_div.find('div', class_='name').find('a')
            if not name_tag: continue
            
            poke_id = get_id_by_name(name_tag.text.strip())
            if poke_id == -1: continue

            general_data = event_div.find('div', class_=re.compile(r'general data'))
            level = 0
            nature = "Unbekannt"
            ability = "Unbekannt"
            location = "Unbekannt"

            if general_data:
                divs = general_data.find_all('div')
                for i in range(len(divs)):
                    text = divs[i].text.strip()
                    if text == 'Level:':
                        level_str = divs[i+1].text.strip()
                        level_match = re.search(r'\d+', level_str)
                        level = int(level_match.group()) if level_match else 0
                    elif text == 'Wesen:':
                        nature = divs[i+1].text.strip()
                    elif text == 'Fähigkeit:':
                        ability = divs[i+1].text.strip()
                    elif text == 'Begegnung:':
                        location = divs[i+1].text.strip()

            results.append({
                "pokemon_id": poke_id,
                "given_pokemon_id": -1,
                "obtain_type": "gift", 
                "game_version": "Schwarz 2 / Weiß 2",
                "location": location,
                "npc_name": "N",
                "nickname": "",
                "ot_name": "N",
                "level": level,
                "nature": nature,
                "ability": ability,
                "item": "",
                "is_n_pokemon": 1,
                "notes": "Schimmert beim Kampfeinsatz grün auf.",
                "form": "normal"
            })
        except Exception:
            pass
            
    return results

def scrape_shiny_locks(html_path):
    print(f"-> Scrape Shiny-Sperren aus: {html_path}")
    if not os.path.exists(html_path): return []
    
    with open(html_path, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')
    
    locks = []
    headline = soup.find(id=re.compile(r'niemals_schillernd|Shiny-Sperre|Pokémon,_die_niemals_schillernd_sind'))
    if not headline: return locks
    
    table = headline.find_next('table')
    if not table: return locks
    
    for row in table.find_all('tr'):
        tds = row.find_all('td')
        if len(tds) >= 3:
            poke_cell = tds[-1]
            for a in poke_cell.find_all('a'):
                txt = a.text.strip()
                pid = get_id_by_name(txt)
                if pid == -1 and a.get('title'):
                    pid = get_id_by_name(a['title'].strip())
                if pid != -1 and pid not in locks:
                    locks.append(pid)
    
    print(f"-> {len(locks)} Shiny-Sperren erfolgreich eingelesen.")
    return locks
        
def main():
    os.makedirs('assets/db', exist_ok=True)

    if os.path.exists('assets/db/pokedex.sqlite'):
            os.remove('assets/db/pokedex.sqlite')

    conn = sqlite3.connect('assets/db/pokedex.sqlite')
    c = conn.cursor()

    print("Erstelle Tabellen...")
    c.executescript('''
        CREATE TABLE IF NOT EXISTS pokemon (
            id INTEGER PRIMARY KEY, name_de TEXT, name_en TEXT,
            has_gender_differences INTEGER, gender_rate INTEGER, capture_rate INTEGER,
            evolution_chain_id INTEGER, egg_groups TEXT, weight REAL, speed INTEGER,
            catch_rate_tags TEXT
        );
        CREATE TABLE IF NOT EXISTS forms (
            id INTEGER PRIMARY KEY AUTOINCREMENT, pokemon_id INTEGER, name TEXT,
            form_type TEXT, min_gen INTEGER, image_id INTEGER, types TEXT, exclusive_regions TEXT,
            forced_tera_type TEXT
        );
        CREATE TABLE IF NOT EXISTS ribbons (
            id TEXT PRIMARY KEY, name_en TEXT, name_de TEXT, desc_en TEXT, desc_de TEXT,
            title_de TEXT, location_de TEXT, image_url TEXT, is_mark INTEGER, min_gen INTEGER, available_games TEXT
        );
        CREATE TABLE IF NOT EXISTS encounters (
            pokemon_id INTEGER, gen TEXT, version TEXT, location_data TEXT
        );
        CREATE TABLE IF NOT EXISTS evolutions (
            chain_id INTEGER PRIMARY KEY, chain_json TEXT
        );
        CREATE TABLE IF NOT EXISTS dex_orders (
            dex_name TEXT, pokemon_id INTEGER, order_index INTEGER
        );
        CREATE TABLE IF NOT EXISTS special_dexes (
            dex_name TEXT, pokemon_id INTEGER
        );
        CREATE TABLE IF NOT EXISTS ball_urls (
            ball_name TEXT PRIMARY KEY, image_url TEXT
        );
        CREATE TABLE IF NOT EXISTS matching_balls (
            unique_id TEXT PRIMARY KEY, normal_balls TEXT, shiny_balls TEXT
        );
        CREATE TABLE IF NOT EXISTS gen1_base_stats (
            id INTEGER PRIMARY KEY, hp INTEGER, atk INTEGER, def INTEGER, spc INTEGER, spe INTEGER
        );
        CREATE TABLE IF NOT EXISTS gen12_pre_evolutions (
            id INTEGER PRIMARY KEY, pre_id INTEGER, req TEXT
        );
        CREATE TABLE IF NOT EXISTS default_levels (
            pokemon_id INTEGER PRIMARY KEY, default_level INTEGER
        );
        CREATE TABLE IF NOT EXISTS shiny_categories (
            pokemon_id INTEGER, category TEXT
        );
        CREATE TABLE IF NOT EXISTS abilities (
            id INTEGER PRIMARY KEY, name_de TEXT, name_en TEXT, desc_de TEXT, desc_en TEXT
        );
        CREATE TABLE IF NOT EXISTS pokemon_abilities (
            pokemon_id INTEGER, ability_id INTEGER, is_hidden INTEGER
        );
        CREATE TABLE IF NOT EXISTS moves (
            id INTEGER PRIMARY KEY, name_de TEXT, name_en TEXT, type TEXT, power INTEGER, 
            accuracy INTEGER, pp INTEGER, damage_class TEXT, desc_de TEXT, desc_en TEXT
        );
        CREATE TABLE IF NOT EXISTS pokemon_moves (
            pokemon_id INTEGER, move_id INTEGER, learn_method TEXT, level_learned INTEGER, version_group TEXT
        );
        CREATE TABLE IF NOT EXISTS special_obtainable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pokemon_id INTEGER,
            given_pokemon_id INTEGER,
            obtain_type TEXT,
            game_version TEXT,
            location TEXT,
            npc_name TEXT,
            nickname TEXT,
            ot_name TEXT,
            level INTEGER,
            nature TEXT,
            ability TEXT,
            item TEXT,
            is_n_pokemon INTEGER DEFAULT 0,
            notes TEXT,
            form TEXT DEFAULT 'normal'
        );
    ''')

    print("\nSchreibe Gen 1 Base Stats und Gen 1/2 Pre-Evolutions in die DB...")
    for poke_id, stats in GEN1_BASE_STATS.items():
        c.execute('INSERT INTO gen1_base_stats VALUES (?, ?, ?, ?, ?, ?)', (poke_id, stats[0], stats[1], stats[2], stats[3], stats[4]))

    for poke_id, data in GEN12_PRE_EVOLUTIONS.items():
        c.execute('INSERT INTO gen12_pre_evolutions VALUES (?, ?, ?)', (poke_id, data['pre'], data['req']))

    for pid, lvl in DEFAULT_LEVELS.items():
        c.execute('INSERT INTO default_levels VALUES (?, ?)', (pid, lvl))

    for cat, pids in SHINY_CATEGORIES.items():
        for pid in pids:
            c.execute('INSERT INTO shiny_categories VALUES (?, ?)', (pid, cat))

    print("\n--- Bänder Zusammenführung ---")
    rg_ribbons = get_ribbons_from_submodule()
    de_ribbons = scrape_pokewiki_ribbons('bin/Liste aller Bänder – PokéWiki.html')
    de_marks = scrape_pokewiki_marks('bin/Zeichen – PokéWiki.html')
    de_ribbons.update(de_marks)

    for r_id, r_info in rg_ribbons.items():
        de_info = de_ribbons.get(r_id, {})
        name_en = r_info['name_en']
        name_de = de_info.get("name_de", name_en)
        desc_en = r_info['desc_en']
        desc_de = de_info.get("desc_de", desc_en)
        title_de = de_info.get("title_de", "")
        location_de = de_info.get("location_de", "")
        image_url = f"https://raw.githubusercontent.com/SlyAceZeta/Ribbons.Guide/main/img/ribbons-and-marks/{r_id}.png"

        c.execute('''INSERT INTO ribbons 
                     (id, name_en, name_de, desc_en, desc_de, title_de, location_de, image_url, is_mark, min_gen, available_games)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                  (r_id, name_en, name_de, desc_en, desc_de, title_de, location_de,
                   image_url, r_info['is_mark'], r_info['min_gen'], r_info['available_games']))

    print("\n1. Verarbeite Matching Pokeballs...")
    actual_path = EXCEL_PATH
    if not os.path.exists(actual_path):
        for file in os.listdir('.'):
            if 'Legal_Matching' in file and file.endswith('.xlsx'):
                actual_path = file
                break
        for file in os.listdir('bin'):
            if 'Legal_Matching' in file and file.endswith('.xlsx'):
                actual_path = f"bin/{file}"
                break
    
    url_to_key = {}
    key_to_url = {}
    balls_database = {}

    if os.path.exists(actual_path):
        try:
            wb = openpyxl.load_workbook(actual_path, data_only=False)
            intro_sheet = wb['Intro']
            for row in intro_sheet.iter_rows(min_row=1, max_row=100, values_only=True):
                for col in range(len(row) - 1):
                    url = get_url(row[col])
                    if url:
                        name = str(row[col+1]).replace('"', '').strip()
                        if 'ball' in name.lower():
                            key = to_key(name)
                            url_to_key[url] = key
                            key_to_url[key] = url

            url_to_key['https://i.imgur.com/eru43o1.png'] = 'strange_ball'
            key_to_url['strange_ball'] = 'https://i.imgur.com/eru43o1.png'
            url_to_key['https://i.imgur.com/aeqHLEh.png'] = 'cherish_ball'
            key_to_url['cherish_ball'] = 'https://i.imgur.com/aeqHLEh.png'

            for sheet_name in wb.sheetnames:
                if sheet_name in ['Intro', 'Vivillon', 'Alcremie']: continue
                sheet = wb[sheet_name]
                rows = list(sheet.iter_rows(values_only=True))
                
                for r in range(0, len(rows), 7):
                    if r >= len(rows): break
                    row_0 = rows[r]
                    for col in range(len(row_0) - 1):
                        id_val = str(row_0[col] or '').strip()
                        id_match = re.sub(r'[^0-9]', '', id_val)
                        if not id_match: continue
                        
                        poke_id = int(id_match)
                        name_str = str(row_0[col+1] or '').replace('*', '').strip()
                        form = get_form(name_str)
                        unique_id = f"{poke_id}_{form}".replace("'", "")
                        
                        normal_balls, shiny_balls = [], []
                        for offset in [1, 2, 3]:
                            if r + offset < len(rows) and col < len(rows[r+offset]):
                                url = get_url(rows[r+offset][col])
                                if url and url in url_to_key and url_to_key[url] not in normal_balls:
                                    normal_balls.append(url_to_key[url])
                        
                        for offset in [4, 5, 6]:
                            if r + offset < len(rows) and col < len(rows[r+offset]):
                                url = get_url(rows[r+offset][col])
                                if url and url in url_to_key and url_to_key[url] not in shiny_balls:
                                    shiny_balls.append(url_to_key[url])
                        
                        norm_str = ",".join(normal_balls) if normal_balls else "any_ball"
                        shin_str = ",".join(shiny_balls) if shiny_balls else "any_ball"
                        balls_database[unique_id] = {'normal': norm_str, 'shiny': shin_str}
        except Exception as e:
            print(f"Fehler beim Laden/Parsen der Excel-Datei: {e}")

    if os.path.exists(CUSTOM_JSON_PATH):
        try:
            with open(CUSTOM_JSON_PATH, 'r', encoding='utf-8') as f:
                custom_data = json.load(f)
                for unique_id, data in custom_data.items():
                    norm_str = ",".join(data.get('normal', [])) if data.get('normal') else "any_ball"
                    shin_str = ",".join(data.get('shiny', [])) if data.get('shiny') else "any_ball"
                    balls_database[unique_id] = {'normal': norm_str, 'shiny': shin_str}
        except Exception as e: pass

    print("\n2. Hole Pokemon Daten (Basis, Formen, Encounters, Speed/Weight)...")
    custom_enc = {}
    if os.path.exists('bin/custom_encounters.json'):
        try:
            with open('bin/custom_encounters.json', 'r', encoding='utf-8') as f:
                custom_enc = json.load(f)
        except Exception as e: pass

    expected_app_uids = set()
    processed_abilities = set()
    processed_moves = set()
    
    for i in range(1, 1026):
        try:
            species = fetch_json(f"https://pokeapi.co/api/v2/pokemon-species/{i}")
            poke = fetch_json(f"https://pokeapi.co/api/v2/pokemon/{i}")
            if not species or not poke: continue

            has_gender_diff = species.get('has_gender_differences', False)

            name_de = name_en = "Unknown"
            for n in species.get('names', []):
                lang_name = n['language']['name']
                poke_name_val = n['name']

                if lang_name == 'de': name_de = poke_name_val
                if lang_name == 'en': name_en = poke_name_val
                if n['language']['name'] == 'de': name_de = n['name']
                if n['language']['name'] == 'en': name_en = n['name']
                
                norm = normalize_name(poke_name_val)
                if norm: POKEMON_NAME_TO_ID[norm] = i
            
            weight = poke.get('weight', 0) / 10.0
            speed = next((s['base_stat'] for s in poke.get('stats', []) if s['stat']['name'] == 'speed'), 0)
            egg_groups = ",".join([eg['name'] for eg in species.get('egg_groups', [])])
            evo_chain_id = int(species['evolution_chain']['url'].strip('/').split('/')[-1]) if species.get('evolution_chain') else -1
            
            tags = []
            if i in [793, 794, 795, 796, 797, 798, 799, 803, 804, 805, 806]: tags.append('ultra_beast')
            if i in [81, 82, 88, 89, 114]: tags.append('fast_ball_gen2')
            if i in [29, 30, 31, 32, 33, 34, 35, 36, 39, 40, 300, 301, 517, 518]: tags.append('moon_ball')
            catch_rate_tags = ",".join(tags)

            c.execute('''INSERT INTO pokemon
                (id, name_de, name_en, has_gender_differences, gender_rate, capture_rate, evolution_chain_id, egg_groups, weight, speed, catch_rate_tags)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                (i, name_de, name_en, 1 if has_gender_diff else 0,
                 species.get('gender_rate', -1), species.get('capture_rate', 255), evo_chain_id, egg_groups, weight, speed, catch_rate_tags))

            for ab in poke.get('abilities', []):
                ab_url = ab['ability']['url']
                ab_id = int(ab_url.strip('/').split('/')[-1])
                is_hidden = 1 if ab.get('is_hidden') else 0
                c.execute('INSERT INTO pokemon_abilities (pokemon_id, ability_id, is_hidden) VALUES (?, ?, ?)', (i, ab_id, is_hidden))
                
                if ab_id not in processed_abilities:
                    processed_abilities.add(ab_id)
                    ab_data = fetch_json(ab_url)
                    if ab_data:
                        name_de = name_en = "Unknown"
                        for n in ab_data.get('names', []):
                            if n['language']['name'] == 'de': name_de = n['name']
                            if n['language']['name'] == 'en': name_en = n['name']
                        
                        desc_de = desc_en = ""
                        for f in ab_data.get('flavor_text_entries', []):
                            if f['language']['name'] == 'de' and not desc_de: desc_de = f['flavor_text'].replace('\n', ' ')
                            if f['language']['name'] == 'en' and not desc_en: desc_en = f['flavor_text'].replace('\n', ' ')
                                
                        c.execute('''INSERT INTO abilities (id, name_de, name_en, desc_de, desc_en) 
                                    VALUES (?, ?, ?, ?, ?)''', (ab_id, name_de, name_en, desc_de, desc_en))

            for m in poke.get('moves', []):
                move_url = m['move']['url']
                move_id = int(move_url.strip('/').split('/')[-1])
                for vgd in m.get('version_group_details', []):
                    c.execute('''INSERT INTO pokemon_moves (pokemon_id, move_id, learn_method, level_learned, version_group) 
                                VALUES (?, ?, ?, ?, ?)''',
                            (i, move_id, vgd['move_learn_method']['name'], vgd['level_learned_at'], vgd['version_group']['name']))
                
                if move_id not in processed_moves:
                    processed_moves.add(move_id)
                    move_data = fetch_json(move_url)
                    if move_data:
                        name_de = name_en = "Unknown"
                        for n in move_data.get('names', []):
                            if n['language']['name'] == 'de': name_de = n['name']
                            if n['language']['name'] == 'en': name_en = n['name']
                        
                        desc_de = desc_en = ""
                        for f in move_data.get('flavor_text_entries', []):
                            if f['language']['name'] == 'de' and not desc_de: desc_de = f['flavor_text'].replace('\n', ' ')
                            if f['language']['name'] == 'en' and not desc_en: desc_en = f['flavor_text'].replace('\n', ' ')
                                
                        c.execute('''INSERT INTO moves (id, name_de, name_en, type, power, accuracy, pp, damage_class, desc_de, desc_en) 
                                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''', 
                                (move_id, name_de, name_en, move_data['type']['name'] if move_data.get('type') else 'unknown', 
                                move_data.get('power') or 0, move_data.get('accuracy') or 0, move_data.get('pp') or 0, 
                                move_data['damage_class']['name'] if move_data.get('damage_class') else 'unknown', desc_de, desc_en))

            varieties = species.get('varieties', [])
            if not varieties: expected_app_uids.add(f"{i}_normal")

            for variety in varieties:
                v_poke = fetch_json(variety['pokemon']['url'])
                if not v_poke: continue
                v_id = v_poke.get('id', i)
                
                forms_list = v_poke.get('forms', [])
                if not forms_list: expected_app_uids.add(f"{i}_normal")

                for form_obj in forms_list:
                    f_data = fetch_json(form_obj['url'])
                    if not f_data: continue
                    
                    types = ",".join([t['type']['name'] for t in f_data.get('types', [])] if f_data.get('types') else [t['type']['name'] for t in v_poke.get('types', [])])
                    raw_name = f_data.get('name', '')
                    clean_form = raw_name.replace(species['name'], '').lstrip('-').strip() or 'normal'
                    expected_app_uids.add(f"{i}_{clean_form}")
                    
                    form_type = 'other'
                    min_gen = get_gen_by_id(i)

                    if f_data.get('version_group'):
                        gen_str = VERSION_TO_GEN.get(f_data['version_group']['name'], '').split('_')[-1]
                        if gen_str.isdigit(): min_gen = int(gen_str)

                    if clean_form == 'normal': form_type = 'normal'
                    elif any(x in clean_form for x in ['alola', 'galar', 'hisui', 'paldea']): form_type = 'regional'
                    elif 'mega' in clean_form or 'primal' in clean_form: form_type = 'mega'
                    elif 'gmax' in clean_form: form_type = 'gmax'
                    
                    forced_tera = None
                    if i == 1017:
                        if 'teal-mask' in clean_form or clean_form == 'normal': forced_tera = 'grass'
                        elif 'wellspring' in clean_form: forced_tera = 'water'
                        elif 'hearthflame' in clean_form: forced_tera = 'fire'
                        elif 'cornerstone' in clean_form: forced_tera = 'rock'
                    elif i == 1024: forced_tera = 'stellar'
                    
                    exclusives = ",".join(FORM_WHITELIST.get(f"{i}_{clean_form}", []))
                    c.execute('''INSERT INTO forms (pokemon_id, name, form_type, min_gen, image_id, types, exclusive_regions, forced_tera_type)
                                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
                              (i, clean_form, form_type, min_gen, v_id, types, exclusives, forced_tera))

            if has_gender_diff:
                expected_app_uids.add(f"{i}_m")
                expected_app_uids.add(f"{i}_f")

            encounters = fetch_json(f"https://pokeapi.co/api/v2/pokemon/{i}/encounters") or []
            enc_data = {}
            if str(i) in custom_enc:
                for gen, vmap in custom_enc[str(i)].items(): enc_data[gen] = vmap
                
            for enc in encounters:
                raw_loc = enc['location_area']['name']
                clean_loc = clean_location(raw_loc)
                
                for v_detail in enc.get('version_details', []):
                    version = v_detail['version']['name']
                    if '-japan' in version: continue
                    gen = VERSION_TO_GEN.get(version, 'gen_unknown')
                    
                    chance_agg = {}
                    for detail in v_detail.get('encounter_details', []):
                        method = detail['method']['name']
                        min_l, max_l = detail['min_level'], detail['max_level']
                        lvl_str = str(min_l) if min_l == max_l else f"{min_l}-{max_l}"
                        key = f"{method}|||{lvl_str}"
                        chance_agg[key] = chance_agg.get(key, 0) + detail['chance']
                        
                    for key, total_chance in chance_agg.items():
                        method, lvl_str = key.split('|||')
                        final_loc = f"{clean_loc}|||{method}|||{lvl_str}|||{total_chance}"
                        
                        if gen not in enc_data: enc_data[gen] = {}
                        if version not in enc_data[gen]: enc_data[gen][version] = []
                        if final_loc not in enc_data[gen][version]: enc_data[gen][version].append(final_loc)

            for gen, vmap in enc_data.items():
                for version, locs in vmap.items():
                    locs_str = "|||||".join(locs)
                    c.execute('INSERT INTO encounters (pokemon_id, gen, version, location_data) VALUES (?, ?, ?, ?)', (i, gen, version, locs_str))

            if species.get('is_legendary'): c.execute('INSERT INTO special_dexes (dex_name, pokemon_id) VALUES (?, ?)', ('legendary-dex', i))
            if species.get('is_mythical'): c.execute('INSERT INTO special_dexes (dex_name, pokemon_id) VALUES (?, ?)', ('mythical-dex', i))
            for eg in species.get('egg_groups', []): c.execute('INSERT INTO special_dexes (dex_name, pokemon_id) VALUES (?, ?)', (f"egg-{eg['name']}", i))
            
            if i % 50 == 0:
                print(f"  ... {i}/1025 bearbeitet")
                conn.commit()
                
        except Exception as e:
            print(f"Fehler bei Pokemon ID {i}: {e}")
            
    conn.commit()

    print("\n3. Führe API Form/Geschlechter-Fallbacks durch...")
    for uid in expected_app_uids:
        if uid not in balls_database or balls_database[uid]['normal'] == "any_ball":
            parts = uid.split('_', 1)
            if not parts[0].isdigit(): continue
            poke_id = int(parts[0])
            
            fallback_data = None
            base_key = f"{poke_id}_normal"
            
            if base_key in balls_database and balls_database[base_key]['normal'] != "any_ball":
                fallback_data = balls_database[base_key]
            else:
                for db_uid, db_data in balls_database.items():
                    if db_uid.startswith(f"{poke_id}_") and db_data['normal'] != "any_ball":
                        fallback_data = db_data
                        break
            
            if fallback_data:
                balls_database[uid] = {'normal': fallback_data['normal'], 'shiny': fallback_data['shiny']}
            else:
                balls_database[uid] = {'normal': 'any_ball', 'shiny': 'any_ball'}

    for poke_id in [493, 773]:
        for type_name, ball_key in TYPE_BALL_MAPPING.items():
            balls_database[f"{poke_id}_{type_name}"] = {'normal': ball_key, 'shiny': ball_key}
            if type_name == 'normal': balls_database[f"{poke_id}_normal"] = {'normal': ball_key, 'shiny': ball_key}

    print("Schreibe Matching Balls in die Datenbank...")
    for key, url in key_to_url.items():
        c.execute("INSERT OR IGNORE INTO ball_urls (ball_name, image_url) VALUES (?, ?)", (key, url))

    for uid, data in balls_database.items():
        c.execute("INSERT OR REPLACE INTO matching_balls (unique_id, normal_balls, shiny_balls) VALUES (?, ?, ?)", (uid, data['normal'], data['shiny']))
    conn.commit()

    print("\n4. Hole Evolutionsketten (1-550)...")
    for i in range(1, 551):
        try:
            chain_data = fetch_json(f"https://pokeapi.co/api/v2/evolution-chain/{i}")
            if chain_data and chain_data.get('chain'):
                parsed_chain = parse_chain(chain_data['chain'])
                c.execute('INSERT INTO evolutions (chain_id, chain_json) VALUES (?, ?)', (i, json.dumps(parsed_chain)))
        except Exception as e: pass
    conn.commit()

    print("\n -> Dynamische Shiny-Sperren auslesen...")
    LOCAL_SHINY_HTML = 'bin/Schillernde Pokémon – PokéWiki.html'
    shiny_locks = scrape_shiny_locks(LOCAL_SHINY_HTML)
    for pid in shiny_locks:
        c.execute('INSERT INTO shiny_categories VALUES (?, ?)', (pid, 'never_shiny'))
    conn.commit()

    print("\n5. Lade Pokedex-Reihenfolgen...")
    try:
        for dex_name, map_key in REGIONAL_ENDPOINTS.items():
            if dex_name in HARDCODED_ORDERS:
                for idx, pid in enumerate(HARDCODED_ORDERS[dex_name]):
                    c.execute('INSERT INTO dex_orders (dex_name, pokemon_id, order_index) VALUES (?, ?, ?)', (map_key, pid, idx))
            else:
                dex_data = fetch_json(f"https://pokeapi.co/api/v2/pokedex/{dex_name}")
                if dex_data and dex_data.get('pokemon_entries'):
                    for idx, entry in enumerate(dex_data['pokemon_entries']):
                        url_parts = entry['pokemon_species']['url'].strip('/').split('/')
                        pid = int(url_parts[-1])
                        c.execute('INSERT INTO dex_orders (dex_name, pokemon_id, order_index) VALUES (?, ?, ?)', (map_key, pid, idx))
                        
        national_max = {'kanto': 151, 'johto': 251, 'hoenn': 386, 'sinnoh': 493, 'unova': 649, 'kalos': 721, 'alola': 809, 'galar': 905, 'paldea': 1025}
        for region, mx in national_max.items():
            for i in range(1, mx + 1):
                c.execute('INSERT INTO dex_orders (dex_name, pokemon_id, order_index) VALUES (?, ?, ?)', (f"{region}_national", i, i-1))
    except Exception as e: pass

    print("\n6. Verarbeite Geschenke und Tausche (Dynamisches Mapping)...")
    try:
        special_data = []
        
        bulba_gifts = scrape_bulbapedia_gifts('bin/Gift Pokémon - Bulbapedia.html')
        special_data.extend(bulba_gifts)

        bulba_trades = scrape_wikis_trades_and_gifts('bin/In-game trade - Bulbapedia.html', obtain_type='trade')
        special_data.extend(bulba_trades)
        pw_trades = scrape_wikis_trades_and_gifts('bin/Tausch – PokéWiki.html', obtain_type='trade')
        special_data.extend(pw_trades)
        
        ns_pokemon = scrape_pokewiki_ns_pokemon('bin/Ns Pokémon – PokéWiki.html')
        special_data.extend(ns_pokemon)
        
        unique_entries = {}
        for entry in special_data:
            loc_short = entry['location'][:8].lower()
            key = f"{entry['pokemon_id']}_{entry['obtain_type']}_{loc_short}_{entry['form']}"
            if key not in unique_entries:
                unique_entries[key] = entry
                
        for entry in unique_entries.values():
            c.execute('''INSERT INTO special_obtainable 
                        (pokemon_id, given_pokemon_id, obtain_type, game_version, location, npc_name, nickname, ot_name, level, nature, ability, item, is_n_pokemon, notes, form)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                    (entry['pokemon_id'], entry['given_pokemon_id'], entry['obtain_type'], entry['game_version'], 
                    entry['location'], entry['npc_name'], entry['nickname'], entry['ot_name'], 
                    entry['level'], entry['nature'], entry['ability'], entry['item'], entry['is_n_pokemon'], entry['notes'], entry['form']))
    except Exception as e:
        print(f"Fehler beim verarbeiten der Spezialerhaltung: {e}")

    conn.commit()
    conn.close()
    print("\nDatenbank erfolgreich aktualisiert!")

if __name__ == "__main__":
    main()