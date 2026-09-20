import os
import urllib.request
import subprocess
import ssl

BIN_DIR = "bin"

DOWNLOADS = [
    {
        "url": "https://bulbapedia.bulbagarden.net/wiki/List_of_Ribbons_in_the_games",
        "filename": "List of Ribbons in the games - Bulbapedia, the community-driven Pokémon encyclopedia.html",
    },
    {
        "url": "https://www.pokewiki.de/Liste_aller_B%C3%A4nder",
        "filename": "Liste aller Bänder – PokéWiki.html",
    },
    {"url": "https://www.pokewiki.de/Zeichen", "filename": "Zeichen – PokéWiki.html"},
    {
        "url": "https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/export?format=xlsx",
        "filename": "Legal_Matching_Pokeballs.xlsx",
    },
    {
        "url": "https://bulbapedia.bulbagarden.net/wiki/In-game_trade",
        "filename": "In-game trade - Bulbapedia.html",
    },
    {
        "url": "https://bulbapedia.bulbagarden.net/wiki/Gift_Pok%C3%A9mon",
        "filename": "Gift Pokémon - Bulbapedia.html",
    },
    {
        "url": "https://www.pokewiki.de/Tausch",
        "filename": "Tausch – PokéWiki.html",
    },
    {
        "url": "https://www.bisafans.de/spiele/editionen/sonne-mond/geschenkte-pokemon.php",
        "filename": "Geschenkte Pokémon Sonne Mond - Bisafans.html",
    },
    {
        "url": "https://www.bisafans.de/spiele/editionen/schwarz-2-weiss-2/geschenkte-pokemon.php",
        "filename": "Geschenkte Pokémon Schwarz 2 Weiß 2 - Bisafans.html",
    },
    {
        "url": "https://www.bisafans.de/spiele/editionen/omega-rubin-alpha-saphir/geschenkte-pokemon.php",
        "filename": "Geschenkte Pokémon Omega Rubin Alpha Saphir - Bisafans.html",
    },
    {
        "url": "https://www.bisafans.de/spiele/editionen/pikachu-evoli/tausche-geschenke.php",
        "filename": "Tausche Geschenke Pikachu Evoli - Bisafans.html",
    },
    {
        "url": "https://www.bisafans.de/spiele/editionen/schild-schwert/geschenkte-pokemon.php",
        "filename": "Geschenkte Pokémon Schild Schwert - Bisafans.html",
    },
    {
        "url": "https://www.bisafans.de/spiele/editionen/strahlender-diamant-leuchtende-perle/geschenkte-pokemon.php",
        "filename": "Geschenkte Pokémon Strahlender Diamant Leuchtende Perle - Bisafans.html",
    },
    {
        "url": "https://www.bisafans.de/spiele/editionen/karmesin-purpur/geschenkte-pokemon.php",
        "filename": "Geschenkte Pokémon Karmesin Purpur - Bisafans.html",
    },
    {
        "url": "https://www.bisafans.de/spiele/editionen/z-a/geschenkte-pokemon.php",
        "filename": "Geschenkte Pokémon ZA - Bisafans.html",
    },
    {
        "url": "https://www.pokewiki.de/Ns_Pok%C3%A9mon",
        "filename": "Ns Pokémon – PokéWiki.html",
    },
]


def download_file(url, filepath):
    print(f"Lade herunter: {filepath}...")
    req = urllib.request.Request(
        url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    )

    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            with open(filepath, "wb") as f:
                f.write(response.read())
        print(" -> Erfolgreich!")
    except Exception as e:
        print(f" -> Fehler beim Download: {e}")


def main():
    os.makedirs(BIN_DIR, exist_ok=True)

    print("=== DATEIEN WERDEN HERUNTERGELADEN ===")
    for item in DOWNLOADS:
        filepath = os.path.join(BIN_DIR, item["filename"])
        download_file(item["url"], filepath)

    print("\n=== GIT SUBMODULES WERDEN AKTUALISIERT ===")
    try:
        subprocess.run(["git", "submodule", "update", "--init", "--remote"], check=True)
        print(" -> Submodules erfolgreich auf den neuesten Stand gebracht!")
    except Exception as e:
        print(f"FEHLER beim Aktualisieren der Submodules: {e}")

    print(
        "\nUpdater erfolgreich beendet! Du kannst nun 'python bin/build_database.py' ausführen."
    )


if __name__ == "__main__":
    main()
