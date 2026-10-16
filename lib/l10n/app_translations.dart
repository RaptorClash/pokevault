import '../i18n/strings.g.dart';

class Translator {
  static const Map<String, Map<String, String>> boxSettingsTranslations = {
    'en': {
      'box_edit_settings_header': 'Box Management Settings',
      'box_edit_auto_shift_title': 'Auto-Shift Pokémon',
      'box_edit_auto_shift_subtitle': 'Shift Pokémon forward on insertion and backward on removal to close gaps.',
      'box_edit_strict_limits_title': 'Strict Capacity Limits',
      'box_edit_strict_limits_subtitle': 'Enforce fixed box grid limits (columns × rows) and spill overflow into the next linked box.',
      'box_edit_pattern_auto_create_title': 'Pattern-Based Auto-Creation',
      'box_edit_pattern_auto_create_subtitle': "Automatically create the next sequence box (e.g. 'Kanto 4') when the last linked box overflows.",
      'box_edit_auto_delete_empty_title': 'Auto-Delete Empty Boxes',
      'box_edit_auto_delete_empty_subtitle': 'Automatically delete empty sequence boxes when Pokémon are pulled back (preserves root box).',
      'edit_mode_save_title': 'Save changes?',
      'edit_mode_discard_title': 'Do you want to discard all changes?',
      'yes': 'Yes',
      'discard': 'Discard',
      'box_action_swap': 'Swap',
      'move_selected_block': 'Move here',
      'move_selected_to_box': 'Move to box...',
      'tap_target_slot': 'Tap target slot...',
      'select_target_box': 'Select target box',
      'cancel_selection': 'Cancel selection',
      'insert_placeholder': 'Insert Placeholder',
      'placeholder': 'Placeholder',
      'placeholder_desc': 'Fixed gap (protected from auto-shift)',
      'search_pokemon_hint': 'Search name or dex number...',
      'all_regions': 'All Regions',
      'all_forms': 'All Forms',
      'form_normal': 'Normal',
      'form_mega': 'Mega',
      'form_gmax': 'Gigantamax',
      'form_regional': 'Regional',
      'filter_regions': 'Regions',
      'filter_forms': 'Forms',
      'filter_gender': 'Gender',
      'gender_male': 'Male (♂)',
      'gender_female': 'Female (♀)',
      'gender_genderless': 'Genderless',
      'gender_differences': 'Differences',
      'filter_variant': 'Variant',
      'variant_normal': 'Standard',
      'variant_shiny': 'Shiny',
      'box_menu': 'Box Menu',
      'reset_filters': 'Reset filters',
    },
    'de': {
      'box_edit_settings_header': 'Box-Verwaltung Einstellungen',
      'box_edit_auto_shift_title': 'Auto-Verschieben von Pokémon',
      'box_edit_auto_shift_subtitle': 'Verschiebt Pokémon beim Einfügen vorwärts und beim Entfernen rückwärts, um Lücken zu schließen.',
      'box_edit_strict_limits_title': 'Strikte Kapazitätsgrenzen',
      'box_edit_strict_limits_subtitle': 'Erzwingt feste Box-Kapazitätsgrenzen (Spalten × Zeilen) und leitet Überlauf in die nächste verknüpfte Box weiter.',
      'box_edit_pattern_auto_create_title': 'Musterbasierte Auto-Erstellung',
      'box_edit_pattern_auto_create_subtitle': 'Erstellt automatisch eine neue Folgebox (z. B. „Kanto 4“), wenn die letzte verknüpfte Box überläuft.',
      'box_edit_auto_delete_empty_title': 'Leere Boxen automatisch löschen',
      'box_edit_auto_delete_empty_subtitle': 'Löscht leere Folgeboxen automatisch nach dem Nachrücken von Pokémon (Stammbox bleibt erhalten).',
      'edit_mode_save_title': 'Änderungen speichern?',
      'edit_mode_discard_title': 'Möchtest du alle Änderungen verwerfen?',
      'yes': 'Ja',
      'discard': 'Verwerfen',
      'box_action_swap': 'Tauschen',
      'move_selected_block': 'Hierhin verschieben',
      'move_selected_to_box': 'In Box verschieben...',
      'tap_target_slot': 'Tippe auf Ziel-Slot...',
      'select_target_box': 'Zielbox auswählen',
      'cancel_selection': 'Auswahl aufheben',
      'insert_placeholder': 'Platzhalter einfügen',
      'placeholder': 'Platzhalter',
      'placeholder_desc': 'Fixierte Lücke (geschützt vor Auto-Shift)',
      'search_pokemon_hint': 'Name oder Pokédex-Nr. suchen...',
      'all_regions': 'Alle Regionen',
      'all_forms': 'Alle Formen',
      'form_normal': 'Normal',
      'form_mega': 'Mega',
      'form_gmax': 'Gigadynamax',
      'form_regional': 'Regionalformen',
      'filter_regions': 'Regionen',
      'filter_forms': 'Formen',
      'filter_gender': 'Geschlecht',
      'gender_male': 'Männlich (♂)',
      'gender_female': 'Weiblich (♀)',
      'gender_genderless': 'Geschlechtslos',
      'gender_differences': 'Unterschiede',
      'filter_variant': 'Variante',
      'variant_normal': 'Standard',
      'variant_shiny': 'Schillernd',
      'box_menu': 'Box-Menü',
      'reset_filters': 'Filter zurücksetzen',
    },
  };

  static String get(String key, {String? fallback}) {
    final lang = currentLanguage;
    final settingVal = boxSettingsTranslations[lang]?[key] ?? boxSettingsTranslations['en']?[key];
    if (settingVal != null) return settingVal;

    String translated = key;

    try {
      final result = t[key];
      if (result != null) {
        translated = result.toString();
      } else {
        translated = DataTranslator.translateApi(key);
      }
    } catch (_) {
      translated = DataTranslator.translateApi(key);
    }

    if (translated == key || translated.isEmpty) {
      return fallback ?? key;
    }

    return translated;
  }

  static set currentLanguage(String lang) {
    if (lang == 'de') {
      LocaleSettings.setLocale(AppLocale.de);
    } else {
      LocaleSettings.setLocale(AppLocale.en);
    }
    DataTranslator.currentLanguage = lang;
  }

  static String get currentLanguage => DataTranslator.currentLanguage;
}

class DataTranslator {
  static String currentLanguage = 'de';

  static String translateApi(String key) {
    if (currentLanguage == 'de') {
      String translated = key;
      if (translated.startsWith('loc_')) {
        translated = translated.substring(4);
      }

      translated = translated.replaceAll('(Starter)', '(Starter)');
      translated = translated.replaceAll('(Gift)', '(Geschenk)');
      translated = translated.replaceAll('(Trade)', '(Tausch)');
      translated = translated.replaceAll('(Fly)', '(Fliegen)');
      translated = translated.replaceAll('(Surf)', '(Surfer)');
      translated = translated.replaceAll('(Old Rod)', '(Angel)');
      translated = translated.replaceAll('(Good Rod)', '(Profiangel)');
      translated = translated.replaceAll('(Super Rod)', '(Superangel)');
      translated = translated.replaceAll('(Fossil)', '(Fossil)');
      translated = translated.replaceAll('(Egg)', '(Ei)');

      translated = translated.replaceAll('Water Stone', 'Wasserstein');
      translated = translated.replaceAll('Fire Stone', 'Feuerstein');
      translated = translated.replaceAll('Thunder Stone', 'Donnerstein');
      translated = translated.replaceAll('Leaf Stone', 'Blattstein');
      translated = translated.replaceAll('Moon Stone', 'Mondstein');
      translated = translated.replaceAll('Sun Stone', 'Sonnenstein');

      translated = translated.replaceAll('Trade', 'Tausch');
      translated = translated.replaceAll('Friendship', 'Zuneigung');
      translated = translated.replaceAll('Day', 'Tag');
      translated = translated.replaceAll('Night', 'Nacht');
      translated = translated.replaceAll('Atk', 'Angriff');
      translated = translated.replaceAll('Def', 'Vert.');
      translated = translated.replaceAll('w/', 'mit');

      if (translated.contains('Max Den')) {
        translated = translated.replaceAll('Max Den', 'Dyna-Nest');
      }

      if (translated.startsWith('Friend Safari')) {
        translated = translated.replaceFirst('Friend Safari', 'Kontaktsafari');
        translated = translated.replaceAll('Grass', 'Pflanze');
        translated = translated.replaceAll('Fire', 'Feuer');
        translated = translated.replaceAll('Water', 'Wasser');
        translated = translated.replaceAll('Bug', 'Käfer');
        translated = translated.replaceAll('Poison', 'Gift');
        translated = translated.replaceAll('Flying', 'Flug');
        translated = translated.replaceAll('Ground', 'Boden');
        translated = translated.replaceAll('Fairy', 'Fee');
        translated = translated.replaceAll('Electric', 'Elektro');
        translated = translated.replaceAll('Fighting', 'Kampf');
        translated = translated.replaceAll('Rock', 'Gestein');
        translated = translated.replaceAll('Ice', 'Eis');
        translated = translated.replaceAll('Psychic', 'Psycho');
        translated = translated.replaceAll('Steel', 'Stahl');
        translated = translated.replaceAll('Dragon', 'Drache');
        translated = translated.replaceAll('Normal', 'Normal');
        translated = translated.replaceAll('Ghost', 'Geist');
        translated = translated.replaceAll('Dark', 'Unlicht');
      }

      translated = translated.replaceAll(RegExp(r'\b1f\b'), 'EG');
      translated = translated.replaceAll(RegExp(r'\b2f\b'), '1. OG');
      translated = translated.replaceAll(RegExp(r'\b3f\b'), '2. OG');
      translated = translated.replaceAll(RegExp(r'\b4f\b'), '3. OG');
      translated = translated.replaceAll(RegExp(r'\b5f\b'), '4. OG');
      translated = translated.replaceAll(RegExp(r'\b6f\b'), '5. OG');
      translated = translated.replaceAll(RegExp(r'\b7f\b'), '6. OG');
      translated = translated.replaceAll(RegExp(r'\bB1f\b'), 'U1');
      translated = translated.replaceAll(RegExp(r'\bB2f\b'), 'U2');
      translated = translated.replaceAll(RegExp(r'\bB3f\b'), 'U3');
      translated = translated.replaceAll(RegExp(r'\bB4f\b'), 'U4');

      baseLocationTranslationsDe.forEach((eng, ger) {
        if (translated.contains(eng)) {
          translated = translated.replaceAll(eng, ger);
        }
      });

      return translated;
    }

    if (key.startsWith('loc_')) {
      return key.substring(4);
    }

    return key;
  }
}

const Map<String, String> baseLocationTranslationsDe = {
  'Safari Zone Peak': 'Safari-Zone (Felslandschaft)',
  'Safari Zone Desert': 'Safari-Zone (Wüste)',
  'Safari Zone Wasteland': 'Safari-Zone (Ödland)',
  'Safari Zone Meadow': 'Safari-Zone (Blumenbeet)',
  'Safari Zone Swamp': 'Safari-Zone (Moorlandschaft)',
  'Safari Zone Marshland': 'Safari-Zone (Sumpflandschaft)',
  'Safari Zone Forest': 'Safari-Zone (Wald)',
  'Safari Zone Rocky Beach': 'Safari-Zone (Felsufer)',
  'Safari Zone Mountain': 'Safari-Zone (Berglandschaft)',
  'Safari Zone Plains': 'Safari-Zone (Graslandschaft)',
  'Safari Zone Wetland': 'Safari-Zone (Feuchtgebiet)',
  'Pallet Town': 'Alabastia',
  'Viridian City': 'Vertania City',
  'Pewter City': 'Marmoria City',
  'Cerulean City': 'Azuria City',
  'Vermilion City': 'Orania City',
  'Lavender Town': 'Lavandia',
  'Celadon City': 'Prismania City',
  'Fuchsia City': 'Fuchsania City',
  'Saffron City': 'Saffronia City',
  'Cinnabar Island': 'Zinnoberinsel',
  'Viridian Forest': 'Vertania-Wald',
  'Mt Moon': 'Mondberg',
  'Rock Tunnel': 'Felstunnel',
  'Pokemon Tower': 'Pokémon-Turm',
  'Safari Zone': 'Safari-Zone',
  'Seafoam Islands': 'See-Schauminseln',
  'Pokemon Mansion': 'Pokémon-Haus',
  'Power Plant': 'Kraftwerk',
  'Victory Road': 'Siegesstraße',
  'Cerulean Cave': 'Geheimdungeon',
  'Digletts Cave': 'Digdas Höhle',
  'Berry Forest': 'Beerenforst',
  'Bond Bridge': 'Bundebrücke',
  'Five Isle Meadow': 'Eiland 5-Weide',
  'Treasure Beach': 'Schatzstrand',
  'Cape Brink': 'Kap Kante',
  'Water Path': 'Wasserirrgarten',
  'Ruin Valley': 'Ruinental',
  'Canyon Entrance': 'Schluchteingang',
  'Sevault Canyon': 'Canyon-Sevault',
  'Pattern Bush': 'Musterbuschwald',
  'New Bark Town': 'Neuborkia',
  'Cherrygrove City': 'Rosalia City',
  'Violet City': 'Viola City',
  'Azalea Town': 'Azalea City',
  'Goldenrod City': 'Dukatia City',
  'Ecruteak City': 'Teak City',
  'Olivine City': 'Oliviana City',
  'Cianwood City': 'Anemonia City',
  'Mahogany Town': 'Mahagonia City',
  'Blackthorn City': 'Ebenholz City',
  'Sprout Tower': 'Knofensa-Turm',
  'Ruins Of Alph': 'Alph-Ruinen',
  'Union Cave': 'Einheitshöhle',
  'Slowpoke Well': 'Flegmon-Brunnen',
  'Ilex Forest': 'Steineichenwald',
  'National Park': 'Nationalpark',
  'Burned Tower': 'Turmruine',
  'Bell Tower': 'Zinnturm',
  'Whirl Islands': 'Strudelinseln',
  'Mt Mortar': 'Kesselberg',
  'Lake Of Rage': 'See des Zorns',
  'Ice Path': 'Eispfad',
  'Dragons Den': 'Drachenhöhle',
  'Dark Cave': 'Dunkelhöhle',
  'Mt Silver': 'Silberberg',
  'Tohjo Falls': 'Tohjo-Fälle',
  'Littleroot Town': 'Wurzelheim',
  'Oldale Town': 'Rosaltstadt',
  'Dewford Town': 'Faustauhaven',
  'Slateport City': 'Graphitport City',
  'Mauville City': 'Malvenfroh City',
  'Verdanturf Town': 'Wiesenflur',
  'Fallarbor Town': 'Laubwechselfeld',
  'Lavaridge Town': 'Bad Lavastadt',
  'Fortree City': 'Baumhausen City',
  'Lilycove City': 'Seegrasulb City',
  'Mossdeep City': 'Moosbach City',
  'Sootopolis City': 'Xeneroville',
  'Pacifidlog Town': 'Floßbrunn',
  'Ever Grande City': 'Prachtpolis City',
  'Petalburg City': 'Blütenburg City',
  'Meteor Falls': 'Meteorfälle',
  'Rusturf Tunnel': 'Metaflurtunnel',
  'Granite Cave': 'Granithöhle',
  'Fiery Path': 'Feuriger Pfad',
  'Jagged Pass': 'Steilpass',
  'New Mauville': 'Neu Malvenfroh',
  'Sea Mauville': 'Seewoge Malvenfroh',
  'Mt Pyre': 'Pyroberg',
  'Magma Hideout': 'Magma-Versteck',
  'Aqua Hideout': 'Aqua-Versteck',
  'Shoal Cave': 'Küstenhöhle',
  'Cave Of Origin': 'Urzeithöhle',
  'Sky Pillar': 'Himmelturm',
  'Seafloor Cavern': 'Tiefseehöhle',
  'Mirage Island': 'Wundereiland',
  'Desert Underpass': 'Wüstentunnel',
  'Artisan Cave': 'Künstlerhöhle',
  'Altering Cave': 'Wandelhöhle',
  'Twinleaf Town': 'Zweiblattdorf',
  'Sandgem Town': 'Sandgemme',
  'Jubilife City': 'Jubelstadt',
  'Oreburgh City': 'Erzelingen',
  'Floaroma Town': 'Flori',
  'Eterna City': 'Ewigenau',
  'Hearthome City': 'Herzhofen',
  'Solaceon Town': 'Trostu',
  'Veilstone City': 'Schleiede',
  'Pastoria City': 'Weideburg',
  'Celestic Town': 'Elyses',
  'Canalave City': 'Fleetburg',
  'Snowpoint City': 'Blizzach',
  'Sunyshore City': 'Sonnewik',
  'Oreburgh Gate': 'Erzelingen-Tor',
  'Ravaged Path': 'Verwüsteter Pfad',
  'Oreburgh Mine': 'Erzelingen-Mine',
  'Valley Windworks': 'Windkraftwerk',
  'Eterna Forest': 'Ewigwald',
  'Old Chateau': 'Alte Villa',
  'Wayward Cave': 'Bizarre Höhle',
  'Mt Coronet': 'Kraterberg',
  'Great Marsh': 'Großmoor',
  'Ruin Maniac Cave': 'Ruinenmaniac-Höhle',
  'Maniac Tunnel': 'Maniac-Tunnel',
  'Trophy Garden': 'Trophäengarten',
  'Iron Island': 'Eiseninsel',
  'Lake Verity': 'Wahrheitssee',
  'Lake Valor': 'Kühnheitssee',
  'Lake Acuity': 'Stärkesee',
  'Sendoff Spring': 'Frühlingspfad',
  'Turnback Cave': 'Höhle der Umkehr',
  'Snowpoint Temple': 'Blizzach-Tempel',
  'Stark Mountain': 'Kahlberg',
  'Fuego Ironworks': 'Feuriohütte',
  'Nuvema Town': 'Avenitia',
  'Accumula Town': 'Gavina',
  'Striaton City': 'Orion City',
  'Nacrene City': 'Septerna City',
  'Castelia City': 'Stratos City',
  'Nimbasa City': 'Rayono City',
  'Driftveil City': 'Marea City',
  'Mistralton City': 'Panaero City',
  'Icirrus City': 'Nevaio City',
  'Opelucid City': 'Twindrake City',
  'Undella Town': 'Ondula',
  'Lacunosa Town': 'Tessera',
  'Dreamyard': 'Traumbrache',
  'Pinwheel Forest': 'Ewigenwald',
  'Desert Resort': 'Wüstenresort',
  'Relic Castle': 'Alter Palast',
  'Cold Storage': 'Tiefkühlcontainer',
  'Chargestone Cave': 'Elektrolithhöhle',
  'Twist Mountain': 'Wendelberg',
  'Dragonspiral Tower': 'Drachenstiege',
  'Moor of Icirrus': 'Moor von Nevaio',
  'Challengers Cave': 'Höhle der Schulung',
  'Giant Chasm': 'Riesengrotte',
  'Abundant Shrine': 'Schrein der Ernte',
  'Lostlorn Forest': 'Hain der Täuschung',
  'Nature Sanctuary': 'Naturschutzgebiet',
  'Virbank Complex': 'Vapydro-Werke',
  'Castelia Sewers': 'Stratos-Kanalisation',
  'Relic Passage': 'Alte Flucht',
  'Strange House': 'Bizarre Villa',
  'Seaside Cave': 'Meerhöhle',
  'P2 Laboratory': 'P2-Labor',
  'Aquacorde Town': 'Petrophia',
  'Ambrette Town': 'Relievera City',
  'Cyllage City': 'Cromlexia',
  'Shalour City': 'Yantara City',
  'Couriway Town': 'Mosaia',
  'Laverre City': 'Romantia City',
  'Santalune Forest': 'Nouvaria-Wald',
  'Parfum Palace': 'Magnum-Opus-Palast',
  'Connecting Cave': 'Verbindungshöhle',
  'Glittering Cave': 'Leuchthöhle',
  'Reflection Cave': 'Spiegelhöhle',
  'Azure Bay': 'Azurbucht',
  'Frost Cavern': 'Frosthöhle',
  'Terminus Cave': 'Omega-Höhle',
  'Pokemon Village': 'Pokémon-Dorf',
  'Unknown Dungeon': 'Geheimdungeon',
  'Sea Spirits Den': 'Meerestitanenhöhle',
  'Lost Hotel': 'Hotel Ruine',
  'Lumiose City': 'Illumina City',
  'Hauoli City': 'Hauholi City',
  'Melemele Meadow': 'Melemele-Blumenmeer',
  'Seaward Cave': 'Meereshöhle',
  'Ten Carat Hill': 'Tenkarat-Hügel',
  'Kalae Bay': 'Kalae-Bucht',
  'Paniola Town': 'Ohana',
  'Paniola Ranch': 'Ohana-Farm',
  'Brooklet Hill': 'Plätscherhügel',
  'Wela Volcano Park': 'Wela-Vulkanpark',
  'Lush Jungle': 'Schattendschungel',
  'Digletts Tunnel': 'Digda-Tunnel',
  'Memorial Hill': 'Gedenkhügel',
  'Akala Outskirts': 'Akala-Küstenland',
  'Malie City': 'Malihe City',
  'Malie Garden': 'Malihe-Ziergarten',
  'Mount Hokulani': 'Hokulani-Berg',
  'Thrifty Megamart': 'Schnäppchenparadies',
  'Ulaula Meadow': 'Ula-Ula-Blumenmeer',
  'Po Town': 'Po Town',
  'Seafolk Village': 'Dorf des Seevolkes',
  'Poni Wilds': 'Poni-Wildnis',
  'Ancient Poni Path': 'Alter Poni-Pfad',
  'Poni Breaker Coast': 'Poni-Küstenklippe',
  'Poni Grove': 'Poni-Hain',
  'Poni Plains': 'Poni-Ebene',
  'Poni Meadow': 'Poni-Blumenmeer',
  'Resolution Cave': 'Finalhöhle',
  'Exeggutor Island': 'Kokowei-Eiland',
  'Vast Poni Canyon': 'Canyon von Poni',
  'Poni Gauntlet': 'Poni-Küste',
  'Mount Lanakila': 'Mount Lanakila',
  'Postwick': 'Furlongham',
  'Wedgehurst': 'Brassbury',
  'Motostoke': 'Engine City',
  'Turffield': 'Turffield',
  'Hulbury': 'Keel Town',
  'Hammerlocke': 'Claw City',
  'Stow-on-Side': 'Passio',
  'Spikemuth': 'Spikeford',
  'Circhester': 'Circhester',
  'Wyndon': 'Score City',
  'Slumbering Weald': 'Schlummerwald',
  'Galar Mine': 'Galar-Mine',
  'Rolling Fields': 'Wonnewiesen',
  'Dappled Grove': 'Hain der Entspannung',
  'West Lake Axewell': 'Milza-See (West)',
  'East Lake Axewell': 'Milza-See (Ost)',
  'Watchtower Ruins': 'Wachturmruine',
  'South Lake Miloch': 'Miloch-See (Süd)',
  'North Lake Miloch': 'Miloch-See (Nord)',
  'Giants Seat': 'Sitz des Giganten',
  'Motostoke Riverbank': 'Engine-Flussufer',
  'Bridge Field': 'Brückenfeld',
  'Stony Wilderness': 'Steinige Wildnis',
  'Dusty Bowl': 'Sandsturmkessel',
  'Giants Mirror': 'Spiegel des Giganten',
  'Hammerlocke Hills': 'Claw-Plateau',
  'Giants Cap': 'Kappe des Giganten',
  'Lake Of Outrage': 'Wutanfall-See',
  'Master Dojo': 'Meister-Dojo',
  'Fields Of Honor': 'Grußgefilde',
  'Soothing Wetlands': 'Balsamsumpf',
  'Forest Of Focus': 'Fokuswald',
  'Challenge Beach': 'Strand der Prüfung',
  'Brawlers Cave': 'Kämpfergrotte',
  'Challenge Road': 'Pfad der Prüfung',
  'Courageous Cavern': 'Tapferkeitshöhle',
  'Loop Lagoon': 'Ringbucht',
  'Training Lowlands': 'Trainingsniederung',
  'Warm Up Tunnel': 'Aufwärmtunnel',
  'Potbottom Desert': 'Pfannenkessel',
  'Workout Sea': 'Fitnessmeer',
  'Stepping Stone Sea': 'Inselmeer',
  'Insular Sea': 'Fernes Meer',
  'Honeycalm Sea': 'Wabenmeer',
  'Honeycalm Island': 'Wabeninsel',
  'Slippery Slope': 'Schollenhang',
  'Frostpoint Field': 'Frostfeld',
  'Giants Bed': 'Bett des Giganten',
  'Old Cemetery': 'Uralter Friedhof',
  'Snowslide Slope': 'Schneeschlucht',
  'Tunnel To The Top': 'Tunnel zum Gipfel',
  'Path To The Peak': 'Gipfelpfad',
  'Crown Shrine': 'Krönungstempel',
  'Giants Foot': 'Fuß des Giganten',
  'Roaring Sea Caves': 'Rauschende Höhlen',
  'Frigid Sea': 'Schollenmeer',
  'Three Point Pass': 'Dreiwegpass',
  'Ballimere Lake': 'Ballsee',
  'Dyna Tree Hill': 'Hügel des Dyna-Baums',
  'Roaming Kanto': 'Wanderpokémon (Kanto)',
  'Roaming Johto': 'Wanderpokémon (Johto)',
  'Roaming Hoenn': 'Wanderpokémon (Hoenn)',
  'Roaming Sinnoh': 'Wanderpokémon (Sinnoh)',
  'Roaming Kalos': 'Wanderpokémon (Kalos)',
  'Roaming Galar': 'Wanderpokémon (Galar)',
  'Outside': 'Außenbereich',
  'Inside': 'Innenbereich',
  'Entrance': 'Eingang',
  'Back': 'Hinterer Bereich',
  'Small Room': 'Kleiner Raum',
  'Sea Route': 'Seeroute',
  'Main': 'Hauptbereich',
  'Area 2': 'Bereich 2',
  'Area 3': 'Bereich 3',
};
