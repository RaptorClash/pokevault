///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsDe = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// de: 'PokéVault'
	String get app_title => 'PokéVault';

	/// de: 'Noch kein Dex vorhanden. Klicke auf das '+' um einen zu erstellen!'
	String get no_dex => 'Noch kein Dex vorhanden.\nKlicke auf das \'+\' um einen zu erstellen!';

	/// de: 'Importieren'
	String get import_tooltip => 'Importieren';

	/// de: 'Exportieren'
	String get export_tooltip => 'Exportieren';

	/// de: 'Neuen Dex anlegen'
	String get create_dex_title => 'Neuen Dex anlegen';

	/// de: 'Name (z.B. Mein Run)'
	String get create_dex_hint => 'Name (z.B. Mein Run)';

	/// de: 'Abbrechen'
	String get cancel => 'Abbrechen';

	/// de: 'Zurück'
	String get back => 'Zurück';

	/// de: 'Erstellen'
	String get create => 'Erstellen';

	/// de: 'Region'
	String get region => 'Region';

	/// de: 'Gefangen'
	String get caught => 'Gefangen';

	/// de: 'Suchen (Name oder ID)...'
	String get search_hint => 'Suchen (Name oder ID)...';

	/// de: 'Alle'
	String get filter_all => 'Alle';

	/// de: 'Gefangen'
	String get filter_caught => 'Gefangen';

	/// de: 'Fehlt'
	String get filter_missing => 'Fehlt';

	/// de: 'Dark Mode'
	String get dark_mode => 'Dark Mode';

	/// de: 'Einstellungen'
	String get settings => 'Einstellungen';

	/// de: 'ausgewählt'
	String get selected => 'ausgewählt';

	/// de: 'Bearbeiten'
	String get edit => 'Bearbeiten';

	/// de: 'Löschen'
	String get delete => 'Löschen';

	/// de: 'Speichern'
	String get save => 'Speichern';

	/// de: 'R'
	String get badge_red => 'R';

	/// de: 'B'
	String get badge_blue => 'B';

	/// de: 'G'
	String get badge_yellow => 'G';

	/// de: 'G'
	String get badge_gold => 'G';

	/// de: 'S'
	String get badge_silver => 'S';

	/// de: 'K'
	String get badge_crystal => 'K';

	/// de: 'RU'
	String get badge_ruby => 'RU';

	/// de: 'SA'
	String get badge_sapphire => 'SA';

	/// de: 'SM'
	String get badge_emerald => 'SM';

	/// de: 'FR'
	String get badge_firered => 'FR';

	/// de: 'BG'
	String get badge_leafgreen => 'BG';

	/// de: 'D'
	String get badge_diamond => 'D';

	/// de: 'P'
	String get badge_pearl => 'P';

	/// de: 'PT'
	String get badge_platinum => 'PT';

	/// de: 'HG'
	String get badge_heartgold => 'HG';

	/// de: 'SS'
	String get badge_soulsilver => 'SS';

	/// de: 'S'
	String get badge_black => 'S';

	/// de: 'W'
	String get badge_white => 'W';

	/// de: 'S2'
	String get badge_black_2 => 'S2';

	/// de: 'W2'
	String get badge_white_2 => 'W2';

	/// de: 'X'
	String get badge_x => 'X';

	/// de: 'Y'
	String get badge_y => 'Y';

	/// de: 'Î©R'
	String get badge_omega_ruby => 'Î©R';

	/// de: 'Î±S'
	String get badge_alpha_sapphire => 'Î±S';

	/// de: 'S'
	String get badge_sun => 'S';

	/// de: 'M'
	String get badge_moon => 'M';

	/// de: 'US'
	String get badge_ultra_sun => 'US';

	/// de: 'UM'
	String get badge_ultra_moon => 'UM';

	/// de: 'LGP'
	String get badge_lets_go_pikachu => 'LGP';

	/// de: 'LGE'
	String get badge_lets_go_eevee => 'LGE';

	/// de: 'SW'
	String get badge_sword => 'SW';

	/// de: 'SH'
	String get badge_shield => 'SH';

	/// de: 'SW EX'
	String get badge_the_isle_of_armor_sword => 'SW EX';

	/// de: 'SH EX'
	String get badge_the_isle_of_armor_shield => 'SH EX';

	/// de: 'SW EX2'
	String get badge_the_crown_tundra_sword => 'SW EX2';

	/// de: 'SH EX2'
	String get badge_the_crown_tundra_shield => 'SH EX2';

	/// de: 'SD'
	String get badge_brilliant_diamond => 'SD';

	/// de: 'LP'
	String get badge_shining_pearl => 'LP';

	/// de: 'PLA'
	String get badge_legends_arceus => 'PLA';

	/// de: 'KA'
	String get badge_scarlet => 'KA';

	/// de: 'PU'
	String get badge_violet => 'PU';

	/// de: 'KA EX'
	String get badge_the_teal_mask_scarlet => 'KA EX';

	/// de: 'PU EX'
	String get badge_the_teal_mask_violet => 'PU EX';

	/// de: 'KA EX2'
	String get badge_the_indigo_disk_scarlet => 'KA EX2';

	/// de: 'PU EX2'
	String get badge_the_indigo_disk_violet => 'PU EX2';

	/// de: 'PLZA'
	String get badge_legends_z_a => 'PLZA';

	/// de: 'COLO'
	String get badge_colosseum => 'COLO';

	/// de: 'XD'
	String get badge_xd => 'XD';

	/// de: 'Wähle eine Generation / Spiel'
	String get choose_generation => 'Wähle eine Generation / Spiel';

	/// de: 'Genauer Pokédex'
	String get exact_pokedex => 'Genauer Pokédex';

	/// de: 'Formen auswählen'
	String get include_forms => 'Formen auswählen';

	/// de: 'Geschlechter (M/W)'
	String get include_genders => 'Geschlechter (M/W)';

	/// de: 'In-Game Tausche'
	String get include_trades => 'In-Game Tausche';

	/// de: 'Geschenkte Pokémon'
	String get include_gifts => 'Geschenkte Pokémon';

	/// de: 'Glitch Pokémon (Game Boy)'
	String get include_glitch => 'Glitch Pokémon (Game Boy)';

	/// de: 'Shiny Status'
	String get shiny_status => 'Shiny Status';

	/// de: 'Shiny-Lock'
	String get shiny_lock_badge => 'Shiny-Lock';

	/// de: 'Shiny-Lock aktiv'
	String get shiny_lock_banner => 'Shiny-Lock aktiv';

	/// de: 'Dieses Pokémon kann an dieser Stelle nicht in seiner schillernden Form erhalten werden.'
	String get shiny_lock_banner_desc => 'Dieses Pokémon kann an dieser Stelle nicht in seiner schillernden Form erhalten werden.';

	/// de: 'Regionalformen'
	String get form_regional => 'Regionalformen';

	/// de: 'Regionalformen'
	String get form_regional_short => 'Regionalformen';

	/// de: 'Mega'
	String get form_mega => 'Mega';

	/// de: 'Gigadynamax'
	String get form_gmax => 'Gigadynamax';

	/// de: 'Sonstige (Kostüme, Pokusan...)'
	String get form_other => 'Sonstige (Kostüme, Pokusan...)';

	/// de: 'Sonstige (Kostüme...)'
	String get form_other_short => 'Sonstige (Kostüme...)';

	/// de: 'Dex löschen?'
	String get delete_confirm_title => 'Dex löschen?';

	/// de: 'Möchtest du diesen Dex wirklich löschen? Das kann nicht rückgängig gemacht werden.'
	String get delete_confirm_text => 'Möchtest du diesen Dex wirklich löschen? Das kann nicht rückgängig gemacht werden.';

	/// de: 'Dexe löschen?'
	String get delete_multiple_confirm_title => 'Dexe löschen?';

	/// de: 'Möchtest du die ausgewählten Dexe wirklich löschen?'
	String get delete_multiple_confirm_text => 'Möchtest du die ausgewählten Dexe wirklich löschen?';

	/// de: 'Pokédex erfolgreich importiert!'
	String get import_success => 'Pokédex erfolgreich importiert!';

	/// de: 'Backup erfolgreich gespeichert unter:'
	String get backup_success => 'Backup erfolgreich gespeichert unter:';

	/// de: 'Hier ist mein PokéVault Backup!'
	String get share_text => 'Hier ist mein PokéVault Backup!';

	/// de: 'JSON Dateien'
	String get json_files => 'JSON Dateien';

	/// de: 'Fehler:'
	String get error => 'Fehler:';

	/// de: 'Fehler beim Laden:'
	String get error_load => 'Fehler beim Laden:';

	/// de: 'Fehler beim Speichern:'
	String get error_save => 'Fehler beim Speichern:';

	/// de: 'Fehler beim Exportieren:'
	String get error_export => 'Fehler beim Exportieren:';

	/// de: 'Fehler beim Importieren:'
	String get error_import => 'Fehler beim Importieren:';

	/// de: 'Fehler beim Starten der App:'
	String get error_start_app => 'Fehler beim Starten der App:';

	/// de: 'Fehler beim bekomen von allen Optionen:'
	String get error_getting_available_features => 'Fehler beim bekomen von allen Optionen:';

	/// de: 'Fehler beim Anzeigen des Dex-Bearbeiten-Popups:'
	String get error_show_edit_dex_dialog => 'Fehler beim Anzeigen des Dex-Bearbeiten-Popups:';

	/// de: 'Fehler beim Bestätigen beim Löschen des Dexes:'
	String get error_confirm_delete => 'Fehler beim Bestätigen beim Löschen des Dexes:';

	/// de: 'Fehler beim Bestätigen zum Löschen von mehreren Dexen:'
	String get error_confirm_multiple_delete => 'Fehler beim Bestätigen zum Löschen von mehreren Dexen:';

	/// de: 'Fehler beim Anzeigen der Form:'
	String get error_get_form_display_name => 'Fehler beim Anzeigen der Form:';

	/// de: 'Fehler beim bauen des Dexes:'
	String get error_build_display_entries => 'Fehler beim bauen des Dexes:';

	/// de: 'Fehler beim Anzeigen der Sprachauswahl:'
	String get error_show_language_dialog => 'Fehler beim Anzeigen der Sprachauswahl:';

	/// de: 'Fehler beim Anzeigen der Farbauswahl:'
	String get error_show_colorpicker_dialog => 'Fehler beim Anzeigen der Farbauswahl:';

	/// de: 'Fehler beim Laden der Präferenzen:'
	String get error_load_prefs => 'Fehler beim Laden der Präferenzen:';

	/// de: 'Fehler beim aktualisieren der Theme-Farben:'
	String get error_update_theme_color => 'Fehler beim aktualisieren der Theme-Farben:';

	/// de: 'Fehler beim aktualisieren der Hintergrundfarbe:'
	String get error_update_background_color => 'Fehler beim aktualisieren der Hintergrundfarbe:';

	/// de: 'Fehler beim hinzufügen einer eigenen Farbe:'
	String get error_add_custom_color => 'Fehler beim hinzufügen einer eigenen Farbe:';

	/// de: 'Fehler beim zurücksetzen der Farben:'
	String get error_reset_to_default => 'Fehler beim zurücksetzen der Farben:';

	/// de: 'Konnte URL nicht öffnen:'
	String get error_launch_url => 'Konnte URL nicht öffnen:';

	/// de: 'Fehler beim Shiny eingeben:'
	String get error_toggle_shiny => 'Fehler beim Shiny eingeben:';

	/// de: 'Fehler beim Laden der Fundorte:'
	String get error_loading_encounters => 'Fehler beim Laden der Fundorte:';

	/// de: 'Eigener Dex'
	String get group_custom => 'Eigener Dex';

	/// de: 'Leerer Dex'
	String get region_custom_empty => 'Leerer Dex';

	/// de: 'National'
	String get group_national => 'National';

	/// de: 'Kanto'
	String get group_kanto => 'Kanto';

	/// de: 'Johto'
	String get group_johto => 'Johto';

	/// de: 'Hoenn'
	String get group_hoenn => 'Hoenn';

	/// de: 'Sinnoh'
	String get group_sinnoh => 'Sinnoh';

	/// de: 'Einall'
	String get group_unova => 'Einall';

	/// de: 'Kalos & Z-A'
	String get group_kalos => 'Kalos & Z-A';

	/// de: 'Alola'
	String get group_alola => 'Alola';

	/// de: 'Galar'
	String get group_galar => 'Galar';

	/// de: 'Hisui'
	String get group_hisui => 'Hisui';

	/// de: 'Paldea'
	String get group_paldea => 'Paldea';

	/// de: 'Alola'
	String get form_name_alola => 'Alola';

	/// de: 'Galar'
	String get form_name_galar => 'Galar';

	/// de: 'Hisui'
	String get form_name_hisui => 'Hisui';

	/// de: 'Paldea'
	String get form_name_paldea => 'Paldea';

	/// de: 'Mega'
	String get form_name_mega => 'Mega';

	/// de: 'Mega X'
	String get form_name_mega_x => 'Mega X';

	/// de: 'Mega Y'
	String get form_name_mega_y => 'Mega Y';

	/// de: 'Gigadynamax'
	String get form_name_gmax => 'Gigadynamax';

	/// de: 'Strubbelohr'
	String get form_name_spiky_eared => 'Strubbelohr';

	/// de: 'Cosplay'
	String get form_name_cosplay => 'Cosplay';

	/// de: 'Original-Kappe'
	String get form_name_original_cap => 'Original-Kappe';

	/// de: '!'
	String get form_name_exclamation => '!';

	/// de: '?'
	String get form_name_question => '?';

	/// de: 'Protomorphose'
	String get form_name_primal => 'Protomorphose';

	/// de: 'Ziergarten'
	String get form_name_meadow => 'Ziergarten';

	/// de: 'Schneefeld'
	String get form_name_icy_snow => 'Schneefeld';

	/// de: 'Schneeparadies'
	String get form_name_polar => 'Schneeparadies';

	/// de: 'Tundra'
	String get form_name_tundra => 'Tundra';

	/// de: 'Kontinental'
	String get form_name_continental => 'Kontinental';

	/// de: 'Blumenmeer'
	String get form_name_garden => 'Blumenmeer';

	/// de: 'Prunk'
	String get form_name_elegant => 'Prunk';

	/// de: 'Modern'
	String get form_name_modern => 'Modern';

	/// de: 'Aquamarin'
	String get form_name_marine => 'Aquamarin';

	/// de: 'Archipel'
	String get form_name_archipelago => 'Archipel';

	/// de: 'Dürre'
	String get form_name_high_plains => 'Dürre';

	/// de: 'Sand'
	String get form_name_sandstorm => 'Sand';

	/// de: 'Fluss'
	String get form_name_river => 'Fluss';

	/// de: 'Monsun'
	String get form_name_monsoon => 'Monsun';

	/// de: 'Savanne'
	String get form_name_savanna => 'Savanne';

	/// de: 'Sonne'
	String get form_name_sun => 'Sonne';

	/// de: 'Ozean'
	String get form_name_ocean => 'Ozean';

	/// de: 'Dschungel'
	String get form_name_jungle => 'Dschungel';

	/// de: 'Fantasie'
	String get form_name_fancy => 'Fantasie';

	/// de: 'Pokéball'
	String get form_name_poke_ball => 'Pokéball';

	/// de: 'Rot'
	String get form_name_red => 'Rot';

	/// de: 'Gelb'
	String get form_name_yellow => 'Gelb';

	/// de: 'Orange'
	String get form_name_orange => 'Orange';

	/// de: 'Blau'
	String get form_name_blue => 'Blau';

	/// de: 'Weiß'
	String get form_name_white => 'Weiß';

	/// de: 'Indigo'
	String get form_name_indigo => 'Indigo';

	/// de: 'Violett'
	String get form_name_violet => 'Violett';

	/// de: 'Grün'
	String get form_name_green => 'Grün';

	/// de: 'Frühling'
	String get form_name_spring => 'Frühling';

	/// de: 'Sommer'
	String get form_name_summer => 'Sommer';

	/// de: 'Herbst'
	String get form_name_autumn => 'Herbst';

	/// de: 'Winter'
	String get form_name_winter => 'Winter';

	/// de: 'Klein'
	String get form_name_small => 'Klein';

	/// de: 'Normal'
	String get form_name_average => 'Normal';

	/// de: 'Groß'
	String get form_name_large => 'Groß';

	/// de: 'Super'
	String get form_name_super => 'Super';

	/// de: 'Flamenco'
	String get form_name_baile => 'Flamenco';

	/// de: 'Cheerleading'
	String get form_name_pom_pom => 'Cheerleading';

	/// de: 'Hula'
	String get form_name_pau => 'Hula';

	/// de: 'Buyo'
	String get form_name_sensu => 'Buyo';

	/// de: 'Vanille'
	String get form_name_vanilla_cream => 'Vanille';

	/// de: 'Ruby'
	String get form_name_ruby_cream => 'Ruby';

	/// de: 'Matcha'
	String get form_name_matcha_cream => 'Matcha';

	/// de: 'Minz'
	String get form_name_mint_cream => 'Minz';

	/// de: 'Zitrone'
	String get form_name_lemon_cream => 'Zitrone';

	/// de: 'Salz'
	String get form_name_salted_cream => 'Salz';

	/// de: 'Ruby-Mix'
	String get form_name_ruby_swirl => 'Ruby-Mix';

	/// de: 'Karamell-Mix'
	String get form_name_caramel_swirl => 'Karamell-Mix';

	/// de: 'Regenbogen-Mix'
	String get form_name_rainbow_swirl => 'Regenbogen-Mix';

	/// de: 'Ewigblütler'
	String get form_name_eternal => 'Ewigblütler';

	/// de: 'Herrscher'
	String get form_name_totem => 'Herrscher';

	/// de: 'Herrscher'
	String get form_name_totem_alola => 'Herrscher';

	/// de: 'Herrscher (Entlarvt)'
	String get form_name_totem_busted => 'Herrscher (Entlarvt)';

	/// de: 'Herrscher (Verkleidet)'
	String get form_name_totem_disguised => 'Herrscher (Verkleidet)';

	/// de: 'Tempomacher'
	String get form_name_own_tempo => 'Tempomacher';

	/// de: 'Tagform'
	String get form_name_midday => 'Tagform';

	/// de: 'Nachtform'
	String get form_name_midnight => 'Nachtform';

	/// de: 'Zwielichtform'
	String get form_name_dusk => 'Zwielichtform';

	/// de: 'Morgenschwingen'
	String get form_name_dawn => 'Morgenschwingen';

	/// de: 'Abendmähne'
	String get form_name_dusk_mane => 'Abendmähne';

	/// de: 'Morgenschwingen'
	String get form_name_dawn_wings => 'Morgenschwingen';

	/// de: 'Ultra'
	String get form_name_ultra => 'Ultra';

	/// de: 'Einzelform'
	String get form_name_solo => 'Einzelform';

	/// de: 'Schwarmform'
	String get form_name_school => 'Schwarmform';

	/// de: 'Verkleidet'
	String get form_name_disguised => 'Verkleidet';

	/// de: 'Entlarvt'
	String get form_name_busted => 'Entlarvt';

	/// de: 'Hoch'
	String get form_name_amped => 'Hoch';

	/// de: 'Tief'
	String get form_name_low_key => 'Tief';

	/// de: 'Eisgesicht'
	String get form_name_ice_face => 'Eisgesicht';

	/// de: 'Wellenbrecher'
	String get form_name_noice_face => 'Wellenbrecher';

	/// de: '♂'
	String get form_name_male => '♂';

	/// de: '♀'
	String get form_name_female => '♀';

	/// de: 'Pappsatt'
	String get form_name_full_belly => 'Pappsatt';

	/// de: 'Kohldampf'
	String get form_name_hangry => 'Kohldampf';

	/// de: 'König'
	String get form_name_crowned => 'König';

	/// de: 'Unendynamax'
	String get form_name_eternamax => 'Unendynamax';

	/// de: 'Fokussierter Stil'
	String get form_name_single_strike => 'Fokussierter Stil';

	/// de: 'Fließender Stil'
	String get form_name_rapid_strike => 'Fließender Stil';

	/// de: 'Dada'
	String get form_name_dada => 'Dada';

	/// de: 'Schimmelreiter'
	String get form_name_ice_rider => 'Schimmelreiter';

	/// de: 'Rappenreiter'
	String get form_name_shadow_rider => 'Rappenreiter';

	/// de: 'Blutmond'
	String get form_name_bloodmoon => 'Blutmond';

	/// de: 'Inkarnationsform'
	String get form_name_incarnate => 'Inkarnationsform';

	/// de: 'Tiergeistform'
	String get form_name_therian => 'Tiergeistform';

	/// de: 'Dreierfamilie'
	String get form_name_family_of_three => 'Dreierfamilie';

	/// de: 'Viererfamilie'
	String get form_name_family_of_four => 'Viererfamilie';

	/// de: 'Grünes Gefieder'
	String get form_name_green_plumage => 'Grünes Gefieder';

	/// de: 'Blaues Gefieder'
	String get form_name_blue_plumage => 'Blaues Gefieder';

	/// de: 'Gelbes Gefieder'
	String get form_name_yellow_plumage => 'Gelbes Gefieder';

	/// de: 'Weißes Gefieder'
	String get form_name_white_plumage => 'Weißes Gefieder';

	/// de: 'Alltagsform'
	String get form_name_zero => 'Alltagsform';

	/// de: 'Heldenform'
	String get form_name_hero => 'Heldenform';

	/// de: 'Gebogene Form'
	String get form_name_curly => 'Gebogene Form';

	/// de: 'Hängende Form'
	String get form_name_droopy => 'Hängende Form';

	/// de: 'Gestreckte Form'
	String get form_name_stretchy => 'Gestreckte Form';

	/// de: 'Truhenform'
	String get form_name_chest => 'Truhenform';

	/// de: 'Wanderform'
	String get form_name_roaming => 'Wanderform';

	/// de: 'Fälschung'
	String get form_name_phony => 'Fälschung';

	/// de: 'Original'
	String get form_name_antique => 'Original';

	/// de: 'Fälschung'
	String get form_name_counterfeit => 'Fälschung';

	/// de: 'Original'
	String get form_name_artisan => 'Original';

	/// de: 'Minderwertige Form'
	String get form_name_unremarkable => 'Minderwertige Form';

	/// de: 'Kostbare Form'
	String get form_name_masterpiece => 'Kostbare Form';

	/// de: 'Türkisgrüne Maske'
	String get form_name_teal_mask => 'Türkisgrüne Maske';

	/// de: 'Brunnenmaske'
	String get form_name_wellspring_mask => 'Brunnenmaske';

	/// de: 'Ofenmaske'
	String get form_name_hearthflame_mask => 'Ofenmaske';

	/// de: 'Fundamentmaske'
	String get form_name_cornerstone_mask => 'Fundamentmaske';

	/// de: 'Terakristall'
	String get form_name_terastal => 'Terakristall';

	/// de: 'Stellar'
	String get form_name_stellar => 'Stellar';

	/// de: 'Westliches Meer'
	String get form_name_west => 'Westliches Meer';

	/// de: 'Östliches Meer'
	String get form_name_east => 'Östliches Meer';

	/// de: 'Geschlossene Form'
	String get form_name_overcast => 'Geschlossene Form';

	/// de: 'Sonnenform'
	String get form_name_sunshine => 'Sonnenform';

	/// de: 'Pflanzenlumpen'
	String get form_name_plant => 'Pflanzenlumpen';

	/// de: 'Sandlumpen'
	String get form_name_sandy => 'Sandlumpen';

	/// de: 'Lumpenlumpen'
	String get form_name_trash => 'Lumpenlumpen';

	/// de: 'Urform'
	String get form_name_origin => 'Urform';

	/// de: 'Wandelform'
	String get form_name_altered => 'Wandelform';

	/// de: 'Landform'
	String get form_name_land => 'Landform';

	/// de: 'Zenitform'
	String get form_name_sky => 'Zenitform';

	/// de: 'Angriffsform'
	String get form_name_attack => 'Angriffsform';

	/// de: 'Verteidigungsform'
	String get form_name_defense => 'Verteidigungsform';

	/// de: 'Initiativeform'
	String get form_name_speed => 'Initiativeform';

	/// de: 'Standardform'
	String get form_name_ordinary => 'Standardform';

	/// de: 'Resolutform'
	String get form_name_resolute => 'Resolutform';

	/// de: 'Gesangsform'
	String get form_name_aria => 'Gesangsform';

	/// de: 'Tanzform'
	String get form_name_pirouette => 'Tanzform';

	/// de: 'Schwarz'
	String get form_name_black => 'Schwarz';

	/// de: 'Aquamodul'
	String get form_name_douse => 'Aquamodul';

	/// de: 'Blitzmodul'
	String get form_name_shock => 'Blitzmodul';

	/// de: 'Flammenmodul'
	String get form_name_burn => 'Flammenmodul';

	/// de: 'Gefriermodul'
	String get form_name_chill => 'Gefriermodul';

	/// de: 'Aktivmodus'
	String get form_name_active => 'Aktivmodus';

	/// de: 'Neutralmodus'
	String get form_name_neutral => 'Neutralmodus';

	/// de: '10% (Scharwandel)'
	String get form_name_10_power_construct => '10% (Scharwandel)';

	/// de: '50% (Scharwandel)'
	String get form_name_50_power_construct => '50% (Scharwandel)';

	/// de: 'Optimum'
	String get form_name_complete => 'Optimum';

	/// de: '10%'
	String get form_name_10 => '10%';

	/// de: '50%'
	String get form_name_50 => '50%';

	/// de: 'Entfesselt'
	String get form_name_unbound => 'Entfesselt';

	/// de: 'Käfer'
	String get form_name_bug => 'Käfer';

	/// de: 'Unlicht'
	String get form_name_dark => 'Unlicht';

	/// de: 'Drache'
	String get form_name_dragon => 'Drache';

	/// de: 'Elektro'
	String get form_name_electric => 'Elektro';

	/// de: 'Fee'
	String get form_name_fairy => 'Fee';

	/// de: 'Kampf'
	String get form_name_fighting => 'Kampf';

	/// de: 'Feuer'
	String get form_name_fire => 'Feuer';

	/// de: 'Flug'
	String get form_name_flying => 'Flug';

	/// de: 'Geist'
	String get form_name_ghost => 'Geist';

	/// de: 'Pflanze'
	String get form_name_grass => 'Pflanze';

	/// de: 'Boden'
	String get form_name_ground => 'Boden';

	/// de: 'Eis'
	String get form_name_ice => 'Eis';

	/// de: 'Gift'
	String get form_name_poison => 'Gift';

	/// de: 'Psycho'
	String get form_name_psychic => 'Psycho';

	/// de: 'Gestein'
	String get form_name_rock => 'Gestein';

	/// de: 'Stahl'
	String get form_name_steel => 'Stahl';

	/// de: 'Wasser'
	String get form_name_water => 'Wasser';

	/// de: 'Unbekannt'
	String get form_name_unknown => 'Unbekannt';

	/// de: 'Nationaldex'
	String get region_national_overall => 'Nationaldex';

	/// de: 'Kanto (Regional)'
	String get region_kanto_regional => 'Kanto (Regional)';

	/// de: 'Johto (Regional)'
	String get region_johto_regional => 'Johto (Regional)';

	/// de: 'Johto (HG/SS Remake)'
	String get region_updated_johto_regional => 'Johto (HG/SS Remake)';

	/// de: 'Hoenn (Regional)'
	String get region_hoenn_regional => 'Hoenn (Regional)';

	/// de: 'Hoenn (OR/AS Remake)'
	String get region_updated_hoenn_regional => 'Hoenn (OR/AS Remake)';

	/// de: 'Sinnoh (Regional)'
	String get region_sinnoh_regional => 'Sinnoh (Regional)';

	/// de: 'Einall (Regional)'
	String get region_unova_regional => 'Einall (Regional)';

	/// de: 'Kalos (Zentral)'
	String get region_kalos_central_regional => 'Kalos (Zentral)';

	/// de: 'Kalos (Küste)'
	String get region_kalos_coastal_regional => 'Kalos (Küste)';

	/// de: 'Kalos (Gebirge)'
	String get region_kalos_mountain_regional => 'Kalos (Gebirge)';

	/// de: 'Illumina (Z-A)'
	String get region_lumiose_regional => 'Illumina (Z-A)';

	/// de: 'Dimensions Illumina (Z-A)'
	String get region_lumiose_dimensions_regional => 'Dimensions Illumina (Z-A)';

	/// de: 'Alola (Gesamt)'
	String get region_alola_regional => 'Alola (Gesamt)';

	/// de: 'Alola (Melemele-Insel)'
	String get region_melemele_regional => 'Alola (Melemele-Insel)';

	/// de: 'Alola (Akala-Insel)'
	String get region_akala_regional => 'Alola (Akala-Insel)';

	/// de: 'Alola (Ula-Ula-Insel)'
	String get region_ulaula_regional => 'Alola (Ula-Ula-Insel)';

	/// de: 'Alola (Poni-Insel)'
	String get region_poni_regional => 'Alola (Poni-Insel)';

	/// de: 'Galar (Regional)'
	String get region_galar_regional => 'Galar (Regional)';

	/// de: 'Galar (Rüstungsinsel)'
	String get region_isle_of_armor_regional => 'Galar (Rüstungsinsel)';

	/// de: 'Galar (Schneelande der Krone)'
	String get region_crown_tundra_regional => 'Galar (Schneelande der Krone)';

	/// de: 'Hisui (Regional)'
	String get region_hisui_regional => 'Hisui (Regional)';

	/// de: 'Paldea (Regional)'
	String get region_paldea_regional => 'Paldea (Regional)';

	/// de: 'Paldea (Kitakami-Provinz)'
	String get region_kitakami_regional => 'Paldea (Kitakami-Provinz)';

	/// de: 'Paldea (Blaubeer-Akademie)'
	String get region_blueberry_regional => 'Paldea (Blaubeer-Akademie)';

	/// de: 'Kanto (Let"s Go)'
	String get region_letsgo_kanto_regional => 'Kanto (Let"s Go)';

	/// de: 'Sinnoh (Platin)'
	String get region_extended_sinnoh_regional => 'Sinnoh (Platin)';

	/// de: 'Einall (S2/W2 Remix)'
	String get region_updated_unova_regional => 'Einall (S2/W2 Remix)';

	/// de: 'Alola (US/UM Gesamt)'
	String get region_updated_alola_regional => 'Alola (US/UM Gesamt)';

	/// de: 'Alola (US/UM Melemele)'
	String get region_updated_melemele_regional => 'Alola (US/UM Melemele)';

	/// de: 'Alola (US/UM Akala)'
	String get region_updated_akala_regional => 'Alola (US/UM Akala)';

	/// de: 'Alola (US/UM Ula-Ula)'
	String get region_updated_ulaula_regional => 'Alola (US/UM Ula-Ula)';

	/// de: 'Alola (US/UM Poni)'
	String get region_updated_poni_regional => 'Alola (US/UM Poni)';

	/// de: 'Spezial Dexe'
	String get region_special_dex => 'Spezial Dexe';

	/// de: 'Mega Dex'
	String get region_mega_dex => 'Mega Dex';

	/// de: 'Unkown Dex'
	String get region_icognito_dex => 'Unkown Dex';

	/// de: 'Glitch Dex'
	String get region_glitch_dex => 'Glitch Dex';

	/// de: 'Game Boy (VC Glitch)'
	String get form_name_vc_glitch => 'Game Boy (VC Glitch)';

	/// de: 'Game Boy (VC Glitch)'
	String get form_vc_glitch => 'Game Boy (VC Glitch)';

	/// de: 'Erscheinungsbild'
	String get appearance => 'Erscheinungsbild';

	/// de: 'Akzentfarbe'
	String get choose_accent_color => 'Akzentfarbe';

	/// de: 'Hintergrundfarbe'
	String get choose_bg_color => 'Hintergrundfarbe';

	/// de: 'Allgemein'
	String get general => 'Allgemein';

	/// de: 'Sprache'
	String get language => 'Sprache';

	/// de: 'Deutsch'
	String get current_language => 'Deutsch';

	/// de: 'Pokémon-Sprache'
	String get pokemon_language => 'Pokémon-Sprache';

	/// de: 'Automatisch'
	String get language_auto => 'Automatisch';

	/// de: 'Folgt App-Sprache'
	String get language_auto_desc => 'Folgt App-Sprache';

	/// de: 'Datenverwaltung'
	String get data_management => 'Datenverwaltung';

	/// de: 'Übernehmen'
	String get apply => 'Übernehmen';

	/// de: 'Standarddesign wiederherstellen'
	String get reset_theme => 'Standarddesign wiederherstellen';

	/// de: 'Danksagungen & Quellen'
	String get credits => 'Danksagungen & Quellen';

	/// de: 'PokéAPI & Sprites'
	String get credit_api_title => 'PokéAPI & Sprites';

	/// de: 'Basisdaten und offizielle Artworks'
	String get credit_api_sub => 'Basisdaten und offizielle Artworks';

	/// de: 'Living Dex Inspiration'
	String get credit_inspi_title => 'Living Dex Inspiration';

	/// de: 'Community Google Sheet für Tracker-Basis'
	String get credit_inspi_sub => 'Community Google Sheet für Tracker-Basis';

	/// de: 'Gen 1 Shiny Hunting'
	String get credit_shiny_gen1_title => 'Gen 1 Shiny Hunting';

	/// de: 'BlueMoonFalls Guide für DV-Werte'
	String get credit_shiny_gen1_sub => 'BlueMoonFalls Guide für DV-Werte';

	/// de: 'Silph Scope Shiny Hunting'
	String get credit_shiny_silph_scope_title => 'Silph Scope Shiny Hunting';

	/// de: 'Porygondolier (Gen 1 DV-Reroll Entdeckung)'
	String get credit_shiny_silph_scope_sub => 'Porygondolier (Gen 1 DV-Reroll Entdeckung)';

	/// de: 'Gen 2 Mail Writer Codes'
	String get credit_glitch_gen2_title => 'Gen 2 Mail Writer Codes';

	/// de: 'GlitchCity Wiki für Gen 3 Shiny Starter'
	String get credit_glitch_gen2_sub => 'GlitchCity Wiki für Gen 3 Shiny Starter';

	/// de: 'Matching Balls Guide'
	String get credit_balls_title => 'Matching Balls Guide';

	/// de: 'Community Sheet für passende Pokébälle'
	String get credit_balls_sub => 'Community Sheet für passende Pokébälle';

	/// de: 'Google Gemini'
	String get credit_ai_title => 'Google Gemini';

	/// de: 'KI-Assistenz beim Programmieren & Refactoring'
	String get credit_ai_sub => 'KI-Assistenz beim Programmieren & Refactoring';

	/// de: 'PokéWiki'
	String get credit_pokewiki_title => 'PokéWiki';

	/// de: 'Umfangreiche Wissensdatenbank'
	String get credit_pokewiki_sub => 'Umfangreiche Wissensdatenbank';

	/// de: 'Bisafans'
	String get credit_bisafans_title => 'Bisafans';

	/// de: 'Guides und Tutorials'
	String get credit_bisafans_sub => 'Guides und Tutorials';

	/// de: 'Zur Listen-Ansicht'
	String get view_list => 'Zur Listen-Ansicht';

	/// de: 'Zur PC-Box Ansicht'
	String get view_box => 'Zur PC-Box Ansicht';

	/// de: 'Nach PokéDex (Normal)'
	String get sort_dex => 'Nach PokéDex (Normal)';

	/// de: 'Nach Regionen & Formen'
	String get sort_forms => 'Nach Regionen & Formen';

	/// de: 'Ansicht & Sortierung'
	String get tooltip_view_sort => 'Ansicht & Sortierung';

	/// de: 'Keine Pokémon gefunden.'
	String get empty_box => 'Keine Pokémon gefunden.';

	/// de: 'Box'
	String get box => 'Box';

	/// de: 'Weibchen'
	String get cat_females => 'Weibchen';

	/// de: 'Alternativ'
	String get cat_alternate => 'Alternativ';

	/// de: 'Cap Pikachu'
	String get cat_cap => 'Cap Pikachu';

	/// de: 'Icognitodex'
	String get cat_unown => 'Icognitodex';

	/// de: 'Vivillon'
	String get cat_vivillon => 'Vivillon';

	/// de: 'Pokusan'
	String get cat_alcremie => 'Pokusan';

	/// de: 'Gigantamax'
	String get cat_gmax => 'Gigantamax';

	/// de: 'Regionalformen'
	String get cat_regional => 'Regionalformen';

	/// de: 'Mega'
	String get cat_mega => 'Mega';

	/// de: 'Kanto'
	String get region_name_kanto => 'Kanto';

	/// de: 'Johto'
	String get region_name_johto => 'Johto';

	/// de: 'Hoenn'
	String get region_name_hoenn => 'Hoenn';

	/// de: 'Sinnoh'
	String get region_name_sinnoh => 'Sinnoh';

	/// de: 'Einall'
	String get region_name_unova => 'Einall';

	/// de: 'Kalos'
	String get region_name_kalos => 'Kalos';

	/// de: 'Alola'
	String get region_name_alola => 'Alola';

	/// de: 'Galar'
	String get region_name_galar => 'Galar';

	/// de: 'Hisui'
	String get region_name_hisui => 'Hisui';

	/// de: 'Paldea'
	String get region_name_paldea => 'Paldea';

	/// de: 'Illumina'
	String get region_name_lumiose => 'Illumina';

	/// de: 'Unbekannt'
	String get region_name_unknown => 'Unbekannt';

	/// de: 'Galar G-Max'
	String get region_name_gmax => 'Galar G-Max';

	/// de: 'Zu Region springen...'
	String get jump_to_region => 'Zu Region springen...';

	/// de: 'Zusatzinformationen'
	String get extra_info => 'Zusatzinformationen';

	/// de: 'Form'
	String get form => 'Form';

	/// de: 'Kommt vor in'
	String get games_appearance => 'Kommt vor in';

	/// de: 'Fangbar in'
	String get games_catchable => 'Fangbar in';

	/// de: 'Event-Verteilungen'
	String get events => 'Event-Verteilungen';

	/// de: 'Aus Dex entfernen'
	String get ignore_pokemon => 'Aus Dex entfernen';

	/// de: 'Pokémon entfernen?'
	String get ignore_confirm_title => 'Pokémon entfernen?';

	/// de: 'Möchtest du dieses Pokémon ausblenden? Du kannst es im Menü jederzeit wiederherstellen.'
	String get ignore_confirm_text => 'Möchtest du dieses Pokémon ausblenden? Du kannst es im Menü jederzeit wiederherstellen.';

	/// de: 'Ausgeblendete Pokémon'
	String get ignored_list_title => 'Ausgeblendete Pokémon';

	/// de: 'Wiederherstellen'
	String get restore_pokemon => 'Wiederherstellen';

	/// de: 'Es wurden keine Pokémon ausgeblendet.'
	String get empty_ignored => 'Es wurden keine Pokémon ausgeblendet.';

	/// de: 'Wird in zukünftigen Updates hinzugefügt.'
	String get placeholder_text => 'Wird in zukünftigen Updates hinzugefügt.';

	/// de: 'Shiny Dex'
	String get shiny_dex => 'Shiny Dex';

	/// de: 'Fundorte & Begegnungen'
	String get encounters_title => 'Fundorte & Begegnungen';

	/// de: 'Keine Fundorte bekannt (oder noch nicht generiert).'
	String get no_encounters_found => 'Keine Fundorte bekannt (oder noch nicht generiert).';

	/// de: 'Hinweis: Wenn eine Edition nicht aufgeführt ist, ist das Pokémon dort in der Regel nur durch Entwicklung, Tausch oder Transfer erhältlich.'
	String get encounter_missing_note => 'Hinweis: Wenn eine Edition nicht aufgeführt ist, ist das Pokémon dort in der Regel nur durch Entwicklung, Tausch oder Transfer erhältlich.';

	/// de: 'Generation 1'
	String get gen_1 => 'Generation 1';

	/// de: 'Generation 2'
	String get gen_2 => 'Generation 2';

	/// de: 'Generation 3'
	String get gen_3 => 'Generation 3';

	/// de: 'Generation 4'
	String get gen_4 => 'Generation 4';

	/// de: 'Generation 5'
	String get gen_5 => 'Generation 5';

	/// de: 'Generation 6'
	String get gen_6 => 'Generation 6';

	/// de: 'Generation 7'
	String get gen_7 => 'Generation 7';

	/// de: 'Generation 8'
	String get gen_8 => 'Generation 8';

	/// de: 'Generation 9'
	String get gen_9 => 'Generation 9';

	/// de: 'Rote Edition'
	String get version_red => 'Rote Edition';

	/// de: 'Blaue Edition'
	String get version_blue => 'Blaue Edition';

	/// de: 'Gelbe Edition'
	String get version_yellow => 'Gelbe Edition';

	/// de: 'Goldene Edition'
	String get version_gold => 'Goldene Edition';

	/// de: 'Silberne Edition'
	String get version_silver => 'Silberne Edition';

	/// de: 'Kristall Edition'
	String get version_crystal => 'Kristall Edition';

	/// de: 'Rubin Edition'
	String get version_ruby => 'Rubin Edition';

	/// de: 'Saphir Edition'
	String get version_sapphire => 'Saphir Edition';

	/// de: 'Smaragd Edition'
	String get version_emerald => 'Smaragd Edition';

	/// de: 'Feuerrote Edition'
	String get version_firered => 'Feuerrote Edition';

	/// de: 'Blattgrüne Edition'
	String get version_leafgreen => 'Blattgrüne Edition';

	/// de: 'Diamant Edition'
	String get version_diamond => 'Diamant Edition';

	/// de: 'Perl Edition'
	String get version_pearl => 'Perl Edition';

	/// de: 'Platin Edition'
	String get version_platinum => 'Platin Edition';

	/// de: 'HeartGold'
	String get version_heartgold => 'HeartGold';

	/// de: 'SoulSilver'
	String get version_soulsilver => 'SoulSilver';

	/// de: 'Schwarze Edition'
	String get version_black => 'Schwarze Edition';

	/// de: 'Weiße Edition'
	String get version_white => 'Weiße Edition';

	/// de: 'Schwarz 2'
	String get version_black_2 => 'Schwarz 2';

	/// de: 'Weiß 2'
	String get version_white_2 => 'Weiß 2';

	/// de: 'Pokémon X'
	String get version_x => 'Pokémon X';

	/// de: 'Pokémon Y'
	String get version_y => 'Pokémon Y';

	/// de: 'Omega Rubin'
	String get version_omega_ruby => 'Omega Rubin';

	/// de: 'Alpha Saphir'
	String get version_alpha_sapphire => 'Alpha Saphir';

	/// de: 'Sonne'
	String get version_sun => 'Sonne';

	/// de: 'Mond'
	String get version_moon => 'Mond';

	/// de: 'Ultrasonne'
	String get version_ultra_sun => 'Ultrasonne';

	/// de: 'Ultramond'
	String get version_ultra_moon => 'Ultramond';

	/// de: 'Let"s Go Pikachu'
	String get version_lets_go_pikachu => 'Let"s Go Pikachu';

	/// de: 'Let"s Go Evoli'
	String get version_lets_go_eevee => 'Let"s Go Evoli';

	/// de: 'Schwert'
	String get version_sword => 'Schwert';

	/// de: 'Schild'
	String get version_shield => 'Schild';

	/// de: 'Rüstungsinsel (SW)'
	String get version_the_isle_of_armor_sword => 'Rüstungsinsel (SW)';

	/// de: 'Rüstungsinsel (SH)'
	String get version_the_isle_of_armor_shield => 'Rüstungsinsel (SH)';

	/// de: 'Schneelande der Krone (SW)'
	String get version_the_crown_tundra_sword => 'Schneelande der Krone (SW)';

	/// de: 'Schneelande der Krone (SH)'
	String get version_the_crown_tundra_shield => 'Schneelande der Krone (SH)';

	/// de: 'Strahlender Diamant'
	String get version_brilliant_diamond => 'Strahlender Diamant';

	/// de: 'Leuchtende Perle'
	String get version_shining_pearl => 'Leuchtende Perle';

	/// de: 'Legenden: Arceus'
	String get version_legends_arceus => 'Legenden: Arceus';

	/// de: 'Karmesin'
	String get version_scarlet => 'Karmesin';

	/// de: 'Purpur'
	String get version_violet => 'Purpur';

	/// de: 'Die Türkisgrüne Maske (KA)'
	String get version_the_teal_mask_scarlet => 'Die Türkisgrüne Maske (KA)';

	/// de: 'Die Türkisgrüne Maske (PU)'
	String get version_the_teal_mask_violet => 'Die Türkisgrüne Maske (PU)';

	/// de: 'Die Indigoblaue Scheibe (KA)'
	String get version_the_indigo_disk_scarlet => 'Die Indigoblaue Scheibe (KA)';

	/// de: 'Die Indigoblaue Scheibe (PU)'
	String get version_the_indigo_disk_violet => 'Die Indigoblaue Scheibe (PU)';

	/// de: 'Legenden: Z-A'
	String get version_legends_z_a => 'Legenden: Z-A';

	/// de: 'Pokémon Colosseum'
	String get version_colosseum => 'Pokémon Colosseum';

	/// de: 'Pokémon XD: Der Dunkle Sturm'
	String get version_xd => 'Pokémon XD: Der Dunkle Sturm';

	/// de: 'Legenden Dex'
	String get region_legendary_dex => 'Legenden Dex';

	/// de: 'Mysteriöse Dex'
	String get region_mythical_dex => 'Mysteriöse Dex';

	/// de: 'Eigruppen'
	String get group_egg_groups => 'Eigruppen';

	/// de: 'Eigruppe: Monster'
	String get region_egg_monster => 'Eigruppe: Monster';

	/// de: 'Eigruppe: Wasser 1'
	String get region_egg_water1 => 'Eigruppe: Wasser 1';

	/// de: 'Eigruppe: Wasser 2'
	String get region_egg_water2 => 'Eigruppe: Wasser 2';

	/// de: 'Eigruppe: Wasser 3'
	String get region_egg_water3 => 'Eigruppe: Wasser 3';

	/// de: 'Eigruppe: Käfer'
	String get region_egg_bug => 'Eigruppe: Käfer';

	/// de: 'Eigruppe: Flug'
	String get region_egg_flying => 'Eigruppe: Flug';

	/// de: 'Eigruppe: Feld'
	String get region_egg_ground => 'Eigruppe: Feld';

	/// de: 'Eigruppe: Fee'
	String get region_egg_fairy => 'Eigruppe: Fee';

	/// de: 'Eigruppe: Pflanze'
	String get region_egg_plant => 'Eigruppe: Pflanze';

	/// de: 'Eigruppe: Humanotyp'
	String get region_egg_humanshape => 'Eigruppe: Humanotyp';

	/// de: 'Eigruppe: Mineral'
	String get region_egg_mineral => 'Eigruppe: Mineral';

	/// de: 'Eigruppe: Amorph'
	String get region_egg_indeterminate => 'Eigruppe: Amorph';

	/// de: 'Eigruppe: Ditto'
	String get region_egg_ditto => 'Eigruppe: Ditto';

	/// de: 'Eigruppe: Drache'
	String get region_egg_dragon => 'Eigruppe: Drache';

	/// de: 'Eigruppe: Unbekannt'
	String get region_egg_no_eggs => 'Eigruppe: Unbekannt';

	/// de: 'Beliebig / Unbekannt'
	String get any_ball => 'Beliebig / Unbekannt';

	/// de: 'Matching Balls'
	String get matching_balls => 'Matching Balls';

	/// de: 'Pokéball'
	String get ball_poke_ball => 'Pokéball';

	/// de: 'Superball'
	String get ball_great_ball => 'Superball';

	/// de: 'Hyperball'
	String get ball_ultra_ball => 'Hyperball';

	/// de: 'Meisterball'
	String get ball_master_ball => 'Meisterball';

	/// de: 'Safariball'
	String get ball_safari_ball => 'Safariball';

	/// de: 'Levelball'
	String get ball_level_ball => 'Levelball';

	/// de: 'Köderball'
	String get ball_lure_ball => 'Köderball';

	/// de: 'Mondball'
	String get ball_moon_ball => 'Mondball';

	/// de: 'Freundesball'
	String get ball_friend_ball => 'Freundesball';

	/// de: 'Sympaball'
	String get ball_love_ball => 'Sympaball';

	/// de: 'Schwerball'
	String get ball_heavy_ball => 'Schwerball';

	/// de: 'Turboball'
	String get ball_fast_ball => 'Turboball';

	/// de: 'Turnierball'
	String get ball_sport_ball => 'Turnierball';

	/// de: 'Premierball'
	String get ball_premier_ball => 'Premierball';

	/// de: 'Wiederball'
	String get ball_repeat_ball => 'Wiederball';

	/// de: 'Timerball'
	String get ball_timer_ball => 'Timerball';

	/// de: 'Nestball'
	String get ball_nest_ball => 'Nestball';

	/// de: 'Netzball'
	String get ball_net_ball => 'Netzball';

	/// de: 'Tauchball'
	String get ball_dive_ball => 'Tauchball';

	/// de: 'Luxusball'
	String get ball_luxury_ball => 'Luxusball';

	/// de: 'Heilball'
	String get ball_heal_ball => 'Heilball';

	/// de: 'Flottball'
	String get ball_quick_ball => 'Flottball';

	/// de: 'Finsterball'
	String get ball_dusk_ball => 'Finsterball';

	/// de: 'Jubelball'
	String get ball_cherish_ball => 'Jubelball';

	/// de: 'Traumball'
	String get ball_dream_ball => 'Traumball';

	/// de: 'Ultraball'
	String get ball_beast_ball => 'Ultraball';

	/// de: 'Seltsamer Ball'
	String get ball_strange_ball => 'Seltsamer Ball';

	/// de: 'Shiny Guide'
	String get shiny_guide_title => 'Shiny Guide';

	/// de: 'Generation 1'
	String get shiny_guide_gen1 => 'Generation 1';

	/// de: 'Tipp: Fange/Züchte das Pokémon in Gen 2 und tausche es per Zeitkapsel nach Gen 1. Wenn du es dann auf Pokémon Bank/HOME überträgst, behält es seinen Shiny-Status, bekommt das Gameboy-Icon und als Herkunftsort 'Kanto'!'
	String get shiny_guide_gen1_desc => 'Tipp: Fange/Züchte das Pokémon in Gen 2 und tausche es per Zeitkapsel nach Gen 1. Wenn du es dann auf Pokémon Bank/HOME überträgst, behält es seinen Shiny-Status, bekommt das Gameboy-Icon und als Herkunftsort \'Kanto\'!';

	/// de: 'Shiny Stat Rechner'
	String get shiny_stat_calculator => 'Shiny Stat Rechner';

	/// de: 'Level'
	String get level => 'Level';

	/// de: 'Basiswerte'
	String get base_stats => 'Basiswerte';

	/// de: 'Tabelle 1 (KP DV: 0)'
	String get table_hp_0 => 'Tabelle 1 (KP DV: 0)';

	/// de: 'Tabelle 2 (KP DV: 8)'
	String get table_hp_8 => 'Tabelle 2 (KP DV: 8)';

	/// de: 'KP'
	String get stat_hp => 'KP';

	/// de: 'ANG'
	String get stat_atk => 'ANG';

	/// de: 'VER'
	String get stat_def => 'VER';

	/// de: 'INIT'
	String get stat_spe => 'INIT';

	/// de: 'SPEZ'
	String get stat_spc => 'SPEZ';

	/// de: 'Regulär Huntbar: Ja'
	String get shiny_huntable_yes => 'Regulär Huntbar: Ja';

	/// de: 'Regulär Huntbar: Nein'
	String get shiny_huntable_no => 'Regulär Huntbar: Nein';

	/// de: 'Besondere Begegnungen:'
	String get notable_encounters => 'Besondere Begegnungen:';

	/// de: 'Mew 8F-Glitch Tutorials:'
	String get tutorials_mew => 'Mew 8F-Glitch Tutorials:';

	/// de: 'Video Tutorial (DE) - LEOsMIND'
	String get tutorial_mew_video_de => 'Video Tutorial (DE) - LEOsMIND';

	/// de: 'Video Tutorial (EN) - Austin John'
	String get tutorial_mew_video_en => 'Video Tutorial (EN) - Austin John';

	/// de: 'Text Tutorial (EN) - extratricky'
	String get tutorial_mew_text_en => 'Text Tutorial (EN) - extratricky';

	/// de: 'Pokémon-Turm Silph Scope Tutorial:'
	String get tutorials_silph_scope => 'Pokémon-Turm Silph Scope Tutorial:';

	/// de: 'Video Tutorial (EN) - Porygondolier'
	String get tutorial_silph_scope_video_en => 'Video Tutorial (EN) - Porygondolier';

	/// de: 'Im Pokémon-Turm (Lavandia) sorgt das Silph Scope beim Identifizieren der Geister für einen DV-Reroll. Dadurch können Nebulak, Alpollo, Tragosso und Knogga regulär als Shiny mit der Chance 1:8192 gefangen werden!'
	String get shiny_gen1_silph_scope_desc => 'Im Pokémon-Turm (Lavandia) sorgt das Silph Scope beim Identifizieren der Geister für einen DV-Reroll. Dadurch können Nebulak, Alpollo, Tragosso und Knogga regulär als Shiny mit der Chance 1:8192 gefangen werden!';

	/// de: 'Starter'
	String get method_starter => 'Starter';

	/// de: 'Geschenk'
	String get method_gift => 'Geschenk';

	/// de: 'NPC-Tausch'
	String get method_trade => 'NPC-Tausch';

	/// de: 'Fossil'
	String get method_fossil => 'Fossil';

	/// de: 'Ei'
	String get method_egg => 'Ei';

	/// de: 'Surfen'
	String get method_surf => 'Surfen';

	/// de: 'Angel'
	String get method_old_rod => 'Angel';

	/// de: 'Profiangel'
	String get method_good_rod => 'Profiangel';

	/// de: 'Superangel'
	String get method_super_rod => 'Superangel';

	/// de: 'Fliegen'
	String get method_fly => 'Fliegen';

	/// de: 'Kampf-Dojo'
	String get method_fighting_dojo => 'Kampf-Dojo';

	/// de: 'Event / Tausch'
	String get method_event_trade => 'Event / Tausch';

	/// de: 'Shiny Zucht-Ketten Rechner (Gen 2)'
	String get shiny_breed_calc_title => 'Shiny Zucht-Ketten Rechner (Gen 2)';

	/// de: 'Start-Pokémon (Männliches Shiny)'
	String get shiny_breed_start => 'Start-Pokémon (Männliches Shiny)';

	/// de: 'Ziel-Pokémon'
	String get shiny_breed_target => 'Ziel-Pokémon';

	/// de: 'Kette berechnen'
	String get shiny_breed_calc_btn => 'Kette berechnen';

	/// de: 'Keine Zuchtkette gefunden.'
	String get shiny_breed_no_path => 'Keine Zuchtkette gefunden.';

	/// de: 'Hinweis: Die Zucht-Kette funktioniert nur, wenn das Ziel-Pokémon (und alle Zwischenstufen) weiblich sein können. Für rein männliche oder geschlechtslose Pokémon benötigst du ein Shiny Ditto.'
	String get shiny_breed_note => 'Hinweis: Die Zucht-Kette funktioniert nur, wenn das Ziel-Pokémon (und alle Zwischenstufen) weiblich sein können. Für rein männliche oder geschlechtslose Pokémon benötigst du ein Shiny Ditto.';

	/// de: 'Tipp: Wenn dein Start-Pokémon ein weibliches Shiny ist, paare es zuerst mit einem normalen Männchen derselben Art. Das erzeugt mit einer Chance von 1:64 ein Shiny, welches (je nach Geschlechterverhältnis) männlich sein könnte. Mit diesem kannst du dann diese Kette starten!'
	String get shiny_breed_female_note => 'Tipp: Wenn dein Start-Pokémon ein weibliches Shiny ist, paare es zuerst mit einem normalen Männchen derselben Art. Das erzeugt mit einer Chance von 1:64 ein Shiny, welches (je nach Geschlechterverhältnis) männlich sein könnte. Mit diesem kannst du dann diese Kette starten!';

	/// de: 'Paare ♂ Shiny {0} mit ♀ {1} ➔ ♀ {2} (1:64)'
	String get shiny_breed_step_female => 'Paare ♂ Shiny {0} mit ♀ {1} ➔ ♀ {2} (1:64)';

	/// de: 'Paare ♂ Shiny {0} mit ♀ {0} ➔ ♂ Shiny {0} (1:64)'
	String get shiny_breed_step_male => 'Paare ♂ Shiny {0} mit ♀ {0} ➔ ♂ Shiny {0} (1:64)';

	/// de: 'Paare ♂ Shiny {0} mit ♀ {1} ➔ ♂/♀ Shiny {2} (1:64)'
	String get shiny_breed_step_final => 'Paare ♂ Shiny {0} mit ♀ {1} ➔ ♂/♀ Shiny {2} (1:64)';

	/// de: 'Paare Shiny Ditto mit {0} ➔ Shiny {1} (1:64)'
	String get shiny_breed_step_ditto => 'Paare Shiny Ditto mit {0} ➔ Shiny {1} (1:64)';

	/// de: 'Chance: 1:64'
	String get shiny_breed_chance => 'Chance: 1:64';

	/// de: 'Chance: 1:64 (Ziel erreicht!)'
	String get shiny_breed_success => 'Chance: 1:64 (Ziel erreicht!)';

	/// de: 'Entwicklung: '
	String get shiny_breed_evo_step => 'Entwicklung: ';

	/// de: 'Soft Reset'
	String get soft_reset => 'Soft Reset';

	/// de: 'Shiny Ditto bekommen (Für Zucht)'
	String get shiny_ditto_guide => 'Shiny Ditto bekommen (Für Zucht)';

	/// de: 'Generation 2'
	String get shiny_guide_gen2 => 'Generation 2';

	/// de: 'Generation 3'
	String get shiny_guide_gen3 => 'Generation 3';

	/// de: 'Generation 4'
	String get shiny_guide_gen4 => 'Generation 4';

	/// de: 'Generation 5'
	String get shiny_guide_gen5 => 'Generation 5';

	/// de: 'Generation 6'
	String get shiny_guide_gen6 => 'Generation 6';

	/// de: 'Generation 7'
	String get shiny_guide_gen7 => 'Generation 7';

	/// de: 'Weitere Jagdmethoden werden in Zukunft hinzugefügt.'
	String get shiny_hunt_methods_soon => 'Weitere Jagdmethoden werden in Zukunft hinzugefügt.';

	/// de: 'Hinweis: Wenn eine Generation nicht aufgeführt ist, kann das Pokémon dort nicht regulär als Shiny gejagt/gezüchtet werden (oder die Jagdmethoden werden in zukünftigen Updates ergänzt).'
	String get shiny_guide_missing_note => 'Hinweis: Wenn eine Generation nicht aufgeführt ist, kann das Pokémon dort nicht regulär als Shiny gejagt/gezüchtet werden (oder die Jagdmethoden werden in zukünftigen Updates ergänzt).';

	/// de: 'Das Kurios-Ei (Pokémon Kristall)'
	String get shiny_odd_egg_title => 'Das Kurios-Ei (Pokémon Kristall)';

	/// de: 'In Pokémon Kristall erhältst du in der Pension das Kurios-Ei. Daraus schlüpft ein zufälliges Baby-Pokémon. Die Shiny-Chance ist massiv erhöht: 14% in der westlichen Version und sogar 50% in der japanischen Version!'
	String get shiny_odd_egg_desc => 'In Pokémon Kristall erhältst du in der Pension das Kurios-Ei. Daraus schlüpft ein zufälliges Baby-Pokémon. Die Shiny-Chance ist massiv erhöht: 14% in der westlichen Version und sogar 50% in der japanischen Version!';

	/// de: 'Gen 3 Starter in Gen 2 (Mail Writer Glitch)'
	String get shiny_mail_writer_title => 'Gen 3 Starter in Gen 2 (Mail Writer Glitch)';

	/// de: 'Hinweis: Mit dem Mail Writer Glitch können in Pokémon Gold/Silber/Kristall die ersten Pokémon der 3. Generation generiert werden. Beim Transfer über den PokéMover auf die Pokémon Bank werden diese dann völlig legal als Gen 3 Starter anerkannt!'
	String get shiny_mail_writer_note => 'Hinweis: Mit dem Mail Writer Glitch können in Pokémon Gold/Silber/Kristall die ersten Pokémon der 3. Generation generiert werden. Beim Transfer über den PokéMover auf die Pokémon Bank werden diese dann völlig legal als Gen 3 Starter anerkannt!';

	/// de: 'Text Tutorial (EN) - Mail Writer Codes'
	String get tutorial_mail_writer_main => 'Text Tutorial (EN) - Mail Writer Codes';

	/// de: 'Text Tutorial (EN) - Gen3Giver Scripts'
	String get tutorial_mail_writer_scripts => 'Text Tutorial (EN) - Gen3Giver Scripts';

	/// de: 'Mail Writer Glitch'
	String get mail_writer_glitch => 'Mail Writer Glitch';

	/// de: 'Community & Support'
	String get community_support => 'Community & Support';

	/// de: 'Fehler oder fehlende Daten melden'
	String get report_issue_title => 'Fehler oder fehlende Daten melden';

	/// de: 'Erstelle ein Ticket (Issue) auf GitHub'
	String get report_issue_sub => 'Erstelle ein Ticket (Issue) auf GitHub';

	/// de: 'Selber beitragen'
	String get contribute_title => 'Selber beitragen';

	/// de: 'Hilf mit via Pull Request (.json Dateien)'
	String get contribute_sub => 'Hilf mit via Pull Request (.json Dateien)';

	/// de: 'Text Tutorial (Mew-Glitch)'
	String get tutorial_mew_normal_text => 'Text Tutorial (Mew-Glitch)';

	/// de: 'Fehler beim Laden des Shiny-Guides:'
	String get error_shiny_guide => 'Fehler beim Laden des Shiny-Guides:';

	/// de: 'Hinweis: Mew kann in den Spielen der 1. Generation durch den bekannten 'Mew-Glitch' (Trainer-Flucht-Glitch) gefangen werden, welcher es dir ermöglicht, ein wildes Mew auf Level 7 anzutreffen.'
	String get mew_glitch_note => 'Hinweis: Mew kann in den Spielen der 1. Generation durch den bekannten \'Mew-Glitch\' (Trainer-Flucht-Glitch) gefangen werden, welcher es dir ermöglicht, ein wildes Mew auf Level 7 anzutreffen.';

	/// de: 'Text Tutorial (EN) - Reddit'
	String get tutorial_mew_normal_link => 'Text Tutorial (EN) - Reddit';

	/// de: 'Mew-Glitch'
	String get method_mew_glitch => 'Mew-Glitch';

	/// de: 'Wander-Pokémon (Legendäre Raubkatzen)'
	String get shiny_roamer_gen2_title => 'Wander-Pokémon (Legendäre Raubkatzen)';

	/// de: 'Hinweis: Die Statuswerte (und damit der Shiny-Status) von Raikou und Entei werden in Gold, Silber und Kristall bereits festgelegt, wenn sie in der Turmruine freigelassen werden! Du musst also vor dem Freilassen speichern, sie suchen und bei Nicht-Erfolg das Spiel neustarten (Soft Reset).'
	String get shiny_roamer_gen2_beasts_note => 'Hinweis: Die Statuswerte (und damit der Shiny-Status) von Raikou und Entei werden in Gold, Silber und Kristall bereits festgelegt, wenn sie in der Turmruine freigelassen werden! Du musst also vor dem Freilassen speichern, sie suchen und bei Nicht-Erfolg das Spiel neustarten (Soft Reset).';

	/// de: 'Hinweis: In Gold und Silber wird Suicunes Shiny-Status beim Freilassen in der Turmruine festgelegt (wie bei Raikou/Entei). In Pokémon Kristall hingegen ist Suicune ein statisches Event im Zinnturm und kann dort ganz normal per Soft Reset gejagt werden!'
	String get shiny_roamer_gen2_suicune_note => 'Hinweis: In Gold und Silber wird Suicunes Shiny-Status beim Freilassen in der Turmruine festgelegt (wie bei Raikou/Entei). In Pokémon Kristall hingegen ist Suicune ein statisches Event im Zinnturm und kann dort ganz normal per Soft Reset gejagt werden!';

	/// de: 'Wichtige Zucht-Mechaniken (Gen 2)'
	String get shiny_breed_mechanics_title => 'Wichtige Zucht-Mechaniken (Gen 2)';

	/// de: 'Warum dieser Geschlechter-Wechsel? In Gen 2 wird der Shiny-Status immer an das *andere* Geschlecht vererbt. Ein männliches Shiny erzeugt also immer ein weibliches Shiny und umgekehrt. Daher muss das Geschlecht bei jedem Zuchtschritt wechseln!'
	String get shiny_breed_mechanics_dv_passing => 'Warum dieser Geschlechter-Wechsel? In Gen 2 wird der Shiny-Status immer an das *andere* Geschlecht vererbt. Ein männliches Shiny erzeugt also immer ein weibliches Shiny und umgekehrt. Daher muss das Geschlecht bei jedem Zuchtschritt wechseln!';

	/// de: 'Inzest-Sperre: Pokémon verweigern die Zucht ('Sie zeigen kein Interesse'), wenn ihre Verteidigungs- und Spezial-DVs identisch sind. Da dein Shiny seine DVs vererbt, fange dir einfach ein neues normales Partner-Pokémon in der Wildnis, falls der Pensionsleiter diesen Spruch aufsagt!'
	String get shiny_breed_dv_conflict_text => 'Inzest-Sperre: Pokémon verweigern die Zucht (\'Sie zeigen kein Interesse\'), wenn ihre Verteidigungs- und Spezial-DVs identisch sind. Da dein Shiny seine DVs vererbt, fange dir einfach ein neues normales Partner-Pokémon in der Wildnis, falls der Pensionsleiter diesen Spruch aufsagt!';

	/// de: 'Nur gefangene Pokémon für Route verwenden'
	String get only_caught_pokemon => 'Nur gefangene Pokémon für Route verwenden';

	/// de: 'Es konnte keine Zucht-Route mit deinen gefangenen Pokémon generiert werden.'
	String get no_path_caught => 'Es konnte keine Zucht-Route mit deinen gefangenen Pokémon generiert werden.';

	/// de: 'Unmöglich! Dieses Pokémon hat eine zu geringe Weibchen-Rate (oder ist rein männlich/geschlechtslos) und kann daher in Gen 2 nicht als Shiny von einer anderen Spezies gezüchtet werden. Du MUSST ein Shiny Ditto verwenden!'
	String get no_path_impossible => 'Unmöglich! Dieses Pokémon hat eine zu geringe Weibchen-Rate (oder ist rein männlich/geschlechtslos) und kann daher in Gen 2 nicht als Shiny von einer anderen Spezies gezüchtet werden. Du MUSST ein Shiny Ditto verwenden!';

	/// de: 'Gesamt'
	String get odds_total => 'Gesamt';

	/// de: 'Geschlecht'
	String get odds_gender => 'Geschlecht';

	/// de: 'Unmöglich!'
	String get impossible => 'Unmöglich!';

	/// de: 'Hinweis: Da weibliche Shinys bei dieser Spezies mathematisch unmöglich sind (durch Gen 2 Programmierung), erhältst du hier ein normal aussehendes Weibchen, das die Shiny-Gene in sich trägt (Gen-Trägerin). Du erkennst sie daran, dass der Pensionsleiter 'Sie zeigen kein Interesse' sagt, wenn du sie mit dem Vater paarst!'
	String get shiny_breed_carrier_note => 'Hinweis: Da weibliche Shinys bei dieser Spezies mathematisch unmöglich sind (durch Gen 2 Programmierung), erhältst du hier ein normal aussehendes Weibchen, das die Shiny-Gene in sich trägt (Gen-Trägerin). Du erkennst sie daran, dass der Pensionsleiter \'Sie zeigen kein Interesse\' sagt, wenn du sie mit dem Vater paarst!';

	/// de: 'Trägerin'
	String get carrier => 'Trägerin';

	/// de: 'Chance: 1:2 (Gen-Trägerin)'
	String get chance_carrier => 'Chance: 1:2 (Gen-Trägerin)';

	/// de: 'Neues Update verfügbar!'
	String get update_available_title => 'Neues Update verfügbar!';

	/// de: 'Später'
	String get dismiss => 'Später';

	/// de: 'Update herunterladen'
	String get download_update => 'Update herunterladen';

	/// de: 'Updates'
	String get updates => 'Updates';

	/// de: 'Nach Updates suchen'
	String get check_for_updates => 'Nach Updates suchen';

	/// de: 'Die App ist auf dem neuesten Stand.'
	String get up_to_date => 'Die App ist auf dem neuesten Stand.';

	/// de: 'Neue Version'
	String get new_version => 'Neue Version';

	/// de: 'Tipp: Exportiere zur Sicherheit deine PokéDexe über die Einstellungen (Datenverwaltung), bevor du das Update durchführst!'
	String get update_backup_warning => 'Tipp: Exportiere zur Sicherheit deine PokéDexe über die Einstellungen (Datenverwaltung), bevor du das Update durchführst!';

	/// de: 'Backup jetzt erstellen'
	String get update_backup_button => 'Backup jetzt erstellen';

	/// de: 'Backup erstellt ✓'
	String get update_backup_done => 'Backup erstellt ✓';

	/// de: 'Vorherige Versionen (Downgrades)'
	String get downgrades_title => 'Vorherige Versionen (Downgrades)';

	/// de: 'Achtung: Downgrade'
	String get attention_downgrade => 'Achtung: Downgrade';

	/// de: 'Du bist dabei, auf eine ältere Version der App zurückzukehren. Dabei können neue Funktionen verloren gehen oder Inkompatibilitäten auftreten. WICHTIG FÜR ANDROID: Android blockiert direkte Downgrades. Du musst die App erst deinstallieren und die heruntergeladene APK manuell installieren. Bitte exportiere VORHER unbedingt deine Dexe in den Einstellungen als Backup!'
	String get downgrade_warning_text => 'Du bist dabei, auf eine ältere Version der App zurückzukehren. Dabei können neue Funktionen verloren gehen oder Inkompatibilitäten auftreten.\n\nWICHTIG FÜR ANDROID: Android blockiert direkte Downgrades. Du musst die App erst deinstallieren und die heruntergeladene APK manuell installieren.\n\nBitte exportiere VORHER unbedingt deine Dexe in den Einstellungen als Backup!';

	/// de: 'Downgrade ausführen'
	String get downgrade_execute => 'Downgrade ausführen';

	/// de: 'Vorher Backup erstellen?'
	String get downgrade_backup_title => 'Vorher Backup erstellen?';

	/// de: 'Möchtest du deine aktuellen PokéDexe vor dem Downgrade sichern? Das wird dringend empfohlen!'
	String get downgrade_backup_text => 'Möchtest du deine aktuellen PokéDexe vor dem Downgrade sichern? Das wird dringend empfohlen!';

	/// de: 'Backup erstellen'
	String get downgrade_backup_create => 'Backup erstellen';

	/// de: 'Ohne Backup fortfahren'
	String get downgrade_backup_skip => 'Ohne Backup fortfahren';

	/// de: 'Letzte Warnung'
	String get downgrade_final_warning_title => 'Letzte Warnung';

	/// de: 'Bist du dir absolut sicher, dass du auf diese alte Version downgraden möchtest? Hast du dein Backup gemacht?'
	String get downgrade_final_warning_text => 'Bist du dir absolut sicher, dass du auf diese alte Version downgraden möchtest? Hast du dein Backup gemacht?';

	/// de: 'Ja, Downgrade starten'
	String get downgrade_final_confirm => 'Ja, Downgrade starten';

	/// de: 'Level'
	String get encounter_level => 'Level';

	/// de: 'Häufigkeit'
	String get encounter_chance => 'Häufigkeit';

	/// de: 'Methode'
	String get encounter_method => 'Methode';

	/// de: 'Ort'
	String get encounter_location => 'Ort';

	/// de: 'Hohes Gras'
	String get method_walk => 'Hohes Gras';

	/// de: 'Einmalig / Statisch'
	String get method_only_one => 'Einmalig / Statisch';

	/// de: 'Routen-Tracker'
	String get route_tracker => 'Routen-Tracker';

	/// de: 'Keine Fundorte für diese Edition gefunden.'
	String get route_tracker_empty => 'Keine Fundorte für diese Edition gefunden.';

	/// de: 'Gefangene ausblenden'
	String get hide_caught => 'Gefangene ausblenden';

	/// de: 'Edition wählen'
	String get select_version => 'Edition wählen';

	/// de: 'Such-Befehle'
	String get search_help_title => 'Such-Befehle';

	/// de: 'Sucht exakt nach einer ID.'
	String get search_help_id => 'Sucht exakt nach einer ID.';

	/// de: 'Zeigt Pokémon im ID-Bereich.'
	String get search_help_range => 'Zeigt Pokémon im ID-Bereich.';

	/// de: 'Filtert nach Status.'
	String get search_help_status => 'Filtert nach Status.';

	/// de: 'Filtert nach Formen.'
	String get search_help_forms => 'Filtert nach Formen.';

	/// de: 'Zeigt die gesamte Entwicklungsreihe des Pokémon.'
	String get search_help_family => 'Zeigt die gesamte Entwicklungsreihe des Pokémon.';

	/// de: 'Wildcard-Suche (* ersetzt beliebige Zeichen).'
	String get search_help_wildcard => 'Wildcard-Suche (* ersetzt beliebige Zeichen).';

	/// de: 'Mit '&' müssen beide Begriffe zutreffen (UND).'
	String get search_help_and => 'Mit \'&\' müssen beide Begriffe zutreffen (UND).';

	/// de: 'Mit ',' reicht ein Treffer (ODER).'
	String get search_help_or => 'Mit \',\' reicht ein Treffer (ODER).';

	/// de: 'Normal'
	String get type_normal => 'Normal';

	/// de: 'Feuer'
	String get type_fire => 'Feuer';

	/// de: 'Wasser'
	String get type_water => 'Wasser';

	/// de: 'Elektro'
	String get type_electric => 'Elektro';

	/// de: 'Pflanze'
	String get type_grass => 'Pflanze';

	/// de: 'Eis'
	String get type_ice => 'Eis';

	/// de: 'Kampf'
	String get type_fighting => 'Kampf';

	/// de: 'Gift'
	String get type_poison => 'Gift';

	/// de: 'Boden'
	String get type_ground => 'Boden';

	/// de: 'Flug'
	String get type_flying => 'Flug';

	/// de: 'Psycho'
	String get type_psychic => 'Psycho';

	/// de: 'Käfer'
	String get type_bug => 'Käfer';

	/// de: 'Gestein'
	String get type_rock => 'Gestein';

	/// de: 'Geist'
	String get type_ghost => 'Geist';

	/// de: 'Drache'
	String get type_dragon => 'Drache';

	/// de: 'Unlicht'
	String get type_dark => 'Unlicht';

	/// de: 'Stahl'
	String get type_steel => 'Stahl';

	/// de: 'Fee'
	String get type_fairy => 'Fee';

	/// de: 'Gefangen Status'
	String get caught_status => 'Gefangen Status';

	/// de: 'Als gefangen markieren'
	String get mark_as_caught => 'Als gefangen markieren';

	/// de: 'Fangratenrechner'
	String get catch_calculator_title => 'Fangratenrechner';

	/// de: 'Basis-Fangrate'
	String get catch_rate_base => 'Basis-Fangrate';

	/// de: 'Generation'
	String get generation => 'Generation';

	/// de: 'Verbleibende KP (%)'
	String get hp_percent => 'Verbleibende KP (%)';

	/// de: 'Pokéball'
	String get pokeball_bonus => 'Pokéball';

	/// de: 'Statusveränderung'
	String get status_condition => 'Statusveränderung';

	/// de: 'Keine'
	String get status_none => 'Keine';

	/// de: 'Paralyse / Gift / Verbrennung'
	String get status_par_psn_brn => 'Paralyse / Gift / Verbrennung';

	/// de: 'Schlaf / Frost'
	String get status_slp_frz => 'Schlaf / Frost';

	/// de: 'Geschätzte Fangchance'
	String get catch_chance => 'Geschätzte Fangchance';

	/// de: 'Chance auf Kritischen Fang'
	String get critical_catch_chance => 'Chance auf Kritischen Fang';

	/// de: 'Sicherer Fang!'
	String get guaranteed_catch => 'Sicherer Fang!';

	/// de: 'Gefangene Pokémon (Für Kritischen Fang)'
	String get dex_caught => 'Gefangene Pokémon (Für Kritischen Fang)';

	/// de: 'Gen {0} Glitch simuliert!'
	String get glitch_warning => 'Gen {0} Glitch simuliert!';

	/// de: 'Pokéball / Premierball (1x)'
	String get calc_ball_poke => 'Pokéball / Premierball (1x)';

	/// de: 'Superball (1.5x)'
	String get calc_ball_great => 'Superball (1.5x)';

	/// de: 'Hyperball (2x)'
	String get calc_ball_ultra => 'Hyperball (2x)';

	/// de: 'Pokéball'
	String get calc_ball_gen1_poke => 'Pokéball';

	/// de: 'Superball (Glitchy bei hoher KP)'
	String get calc_ball_gen1_great => 'Superball (Glitchy bei hoher KP)';

	/// de: 'Hyperball / Safariball'
	String get calc_ball_gen1_ultra => 'Hyperball / Safariball';

	/// de: 'Turboball (nur Magnetilo/Sleima/Tangela)'
	String get calc_ball_fast => 'Turboball (nur Magnetilo/Sleima/Tangela)';

	/// de: 'Sympaball (GLITCH: Nur exakt gleiche Spezies & Geschlecht)'
	String get calc_ball_love => 'Sympaball (GLITCH: Nur exakt gleiche Spezies & Geschlecht)';

	/// de: 'Mondball (GLITCH: Wirkt wie Pokéball)'
	String get calc_ball_moon => 'Mondball (GLITCH: Wirkt wie Pokéball)';

	/// de: 'Köderball (Beim Angeln)'
	String get calc_ball_lure => 'Köderball (Beim Angeln)';

	/// de: 'Schwerball (Leichte Pokémon: -20 Rate)'
	String get calc_ball_heavy_minus => 'Schwerball (Leichte Pokémon: -20 Rate)';

	/// de: 'Schwerball (Schwere Pokémon: +20 bis +40 Rate)'
	String get calc_ball_heavy_plus => 'Schwerball (Schwere Pokémon: +20 bis +40 Rate)';

	/// de: 'Netzball (Käfer/Wasser) (3x/3.5x)'
	String get calc_ball_net => 'Netzball (Käfer/Wasser) (3x/3.5x)';

	/// de: 'Tauchball (Beim Surfen/Tauchen) (3.5x)'
	String get calc_ball_dive => 'Tauchball (Beim Surfen/Tauchen) (3.5x)';

	/// de: 'Nestball (Geringes Level) (Bis zu 4x)'
	String get calc_ball_nest => 'Nestball (Geringes Level) (Bis zu 4x)';

	/// de: 'Timerball (Runde 10+) (4x)'
	String get calc_ball_timer => 'Timerball (Runde 10+) (4x)';

	/// de: 'Flottball (Runde 1) (5x)'
	String get calc_ball_quick => 'Flottball (Runde 1) (5x)';

	/// de: 'Finsterball (Nachts/Höhle) (3x/3.5x)'
	String get calc_ball_dusk => 'Finsterball (Nachts/Höhle) (3x/3.5x)';

	/// de: 'Basis-Fangrate'
	String get calc_base_rate => 'Basis-Fangrate';

	/// de: '(Angepasst durch Schwerball von {0})'
	String get calc_modified_rate => '(Angepasst durch Schwerball von {0})';

	/// de: 'Kampf-Bedingungen'
	String get calc_battle_conditions => 'Kampf-Bedingungen';

	/// de: 'Zusatzkraft'
	String get calc_bonus_power => 'Zusatzkraft';

	/// de: 'Keine Kraft aktiv (1.0x)'
	String get calc_power_none => 'Keine Kraft aktiv (1.0x)';

	/// de: 'O-Kraft: Fangkraft Lv. 1 (1.5x)'
	String get calc_power_o1 => 'O-Kraft: Fangkraft Lv. 1 (1.5x)';

	/// de: 'O-Kraft: Fangkraft Lv. 2 (2.0x)'
	String get calc_power_o2 => 'O-Kraft: Fangkraft Lv. 2 (2.0x)';

	/// de: 'O-Kraft: Fangkraft Lv. 3 (2.5x)'
	String get calc_power_o3 => 'O-Kraft: Fangkraft Lv. 3 (2.5x)';

	/// de: 'Rotom-Fangkraft (2.5x)'
	String get calc_power_roto => 'Rotom-Fangkraft (2.5x)';

	/// de: 'Sandwich: Fangkraft Lv. 1 (1.1x)'
	String get calc_power_sand1 => 'Sandwich: Fangkraft Lv. 1 (1.1x)';

	/// de: 'Sandwich: Fangkraft Lv. 2 (1.25x)'
	String get calc_power_sand2 => 'Sandwich: Fangkraft Lv. 2 (1.25x)';

	/// de: 'Sandwich: Fangkraft Lv. 3 (2.0x)'
	String get calc_power_sand3 => 'Sandwich: Fangkraft Lv. 3 (2.0x)';

	/// de: 'Level des wilden Pokémon: {0}'
	String get calc_enemy_level => 'Level des wilden Pokémon: {0}';

	/// de: 'Level deines Pokémon: {0}'
	String get calc_own_level => 'Level deines Pokémon: {0}';

	/// de: '⚠️ In Gen 8 wird die Fangchance extrem bestraft, wenn dein Level niedriger ist!'
	String get calc_gen8_penalty => '⚠️ In Gen 8 wird die Fangchance extrem bestraft, wenn dein Level niedriger ist!';

	/// de: 'Aktuelle Runde im Kampf: {0}'
	String get calc_turn_count => 'Aktuelle Runde im Kampf: {0}';

	/// de: 'Angeln / Surfen Begegnung?'
	String get calc_water_encounter => 'Angeln / Surfen Begegnung?';

	/// de: 'Nachts oder in einer Höhle?'
	String get calc_night_cave => 'Nachts oder in einer Höhle?';

	/// de: 'Gleiche Spezies & anderes Geschlecht?'
	String get calc_love_condition => 'Gleiche Spezies & anderes Geschlecht?';

	/// de: 'Pokémon bereits im Dex registriert?'
	String get calc_already_caught => 'Pokémon bereits im Dex registriert?';

	/// de: 'Kritischer Fang'
	String get calc_crit_settings => 'Kritischer Fang';

	/// de: 'Transferkraft Lv. 1 (1.1x)'
	String get calc_power_pass1 => 'Transferkraft Lv. 1 (1.1x)';

	/// de: 'Transferkraft Lv. 2 (1.2x)'
	String get calc_power_pass2 => 'Transferkraft Lv. 2 (1.2x)';

	/// de: 'Transferkraft Lv. 3 (1.3x)'
	String get calc_power_pass3 => 'Transferkraft Lv. 3 (1.3x)';

	/// de: 'Bug-Hinweis: In Gen 1 ist der Superball bei fast vollen KP durch einen Rundungsfehler sogar effektiver als der Hyperball!'
	String get glitch_gen1_great => 'Bug-Hinweis: In Gen 1 ist der Superball bei fast vollen KP durch einen Rundungsfehler sogar effektiver als der Hyperball!';

	/// de: 'Bug-Hinweis: In Gen 2 wirkt der Sympaball nur, wenn das Pokémon exakt dieselbe Spezies UND das identische Geschlecht deines eigenen Pokémon hat (sonst immer 1x).'
	String get glitch_gen2_love => 'Bug-Hinweis: In Gen 2 wirkt der Sympaball nur, wenn das Pokémon exakt dieselbe Spezies UND das identische Geschlecht deines eigenen Pokémon hat (sonst immer 1x).';

	/// de: 'Bug-Hinweis: In Gen 2 wirkt der Mondball wegen eines Programmierfehlers nie (Bonus ist immer 1x).'
	String get glitch_gen2_moon => 'Bug-Hinweis: In Gen 2 wirkt der Mondball wegen eines Programmierfehlers nie (Bonus ist immer 1x).';

	/// de: 'Bug-Hinweis: In Gen 2 wirkt der Turboball wegen eines Programmierfehlers ausschließlich auf Sleima, Sleimok, Tangela, Magnetilo und Magneton.'
	String get glitch_gen2_fast => 'Bug-Hinweis: In Gen 2 wirkt der Turboball wegen eines Programmierfehlers ausschließlich auf Sleima, Sleimok, Tangela, Magnetilo und Magneton.';

	/// de: 'Fangpin (Basis-Item) im Beutel?'
	String get catching_charm => 'Fangpin (Basis-Item) im Beutel?';

	/// de: 'Dunkles hohes Gras (Gen 5)'
	String get calc_dark_grass => 'Dunkles hohes Gras (Gen 5)';

	/// de: 'Hisui-Pokéball'
	String get ball_poke_hisui => 'Hisui-Pokéball';

	/// de: 'Hisui-Superball'
	String get ball_great_hisui => 'Hisui-Superball';

	/// de: 'Hisui-Hyperball'
	String get ball_ultra_hisui => 'Hisui-Hyperball';

	/// de: 'Hisui-Schwerball'
	String get ball_heavy_hisui => 'Hisui-Schwerball';

	/// de: 'Zentnerball'
	String get ball_leaden => 'Zentnerball';

	/// de: 'Tonnenball'
	String get ball_gigaton => 'Tonnenball';

	/// de: 'Federball'
	String get ball_feather => 'Federball';

	/// de: 'Flügelball'
	String get ball_wing => 'Flügelball';

	/// de: 'Düsenball'
	String get ball_jet => 'Düsenball';

	/// de: 'Ursprungsball'
	String get ball_origin => 'Ursprungsball';

	/// de: 'Himmihbeere (1.5x)'
	String get berry_razz => 'Himmihbeere (1.5x)';

	/// de: 'Silberne Himmihbeere (2.25x)'
	String get berry_silver_razz => 'Silberne Himmihbeere (2.25x)';

	/// de: 'Goldene Himmihbeere (2.5x)'
	String get berry_golden_razz => 'Goldene Himmihbeere (2.5x)';

	/// de: 'Pokémon fliegt hoch in der Luft'
	String get calc_flying => 'Pokémon fliegt hoch in der Luft';

	/// de: 'Gefütterte Beere (Let"s Go)'
	String get calc_berry_let_go => 'Gefütterte Beere (Let"s Go)';

	/// de: 'Begegnungs-Status (Hisui)'
	String get calc_hisui_status => 'Begegnungs-Status (Hisui)';

	/// de: 'Im Kampf / Hat dich bemerkt (1.0x)'
	String get hisui_status_0 => 'Im Kampf / Hat dich bemerkt (1.0x)';

	/// de: 'Ahnungslos / Im Gras versteckt (1.5x)'
	String get hisui_status_1 => 'Ahnungslos / Im Gras versteckt (1.5x)';

	/// de: 'Rückangriff (2.0x)'
	String get hisui_status_2 => 'Rückangriff (2.0x)';

	/// de: 'Betäubt durch Items (1.25x / Alphas 3.0x)'
	String get hisui_status_3 => 'Betäubt durch Items (1.25x / Alphas 3.0x)';

	/// de: 'Fehler bei der Berechnung der Fangrate:'
	String get error_calc_catch_rate => 'Fehler bei der Berechnung der Fangrate:';

	/// de: 'Fehler bei der UI-Eingabe (Fangrate):'
	String get error_calc_catch_rate_ui => 'Fehler bei der UI-Eingabe (Fangrate):';

	/// de: 'Dyna-Raid'
	String get calc_max_raid => 'Dyna-Raid';

	/// de: 'Raid-Gast?'
	String get calc_max_raid_guest => 'Raid-Gast?';

	/// de: 'Gigadynamax?'
	String get calc_max_raid_gmax => 'Gigadynamax?';

	/// de: 'Rückenangriff'
	String get calc_backstrike => 'Rückenangriff';

	/// de: 'Ziel ist Shiny'
	String get calc_target_shiny => 'Ziel ist Shiny';

	/// de: 'Fangfenster (betäubt)'
	String get calc_catch_window => 'Fangfenster (betäubt)';

	/// de: 'Alpha Pokémon'
	String get calc_alpha => 'Alpha Pokémon';

	/// de: 'Z-A Royale Rang'
	String get calc_za_rank => 'Z-A Royale Rang';

	/// de: 'Kanari-Plüsch Level'
	String get calc_plush_level => 'Kanari-Plüsch Level';

	/// de: 'Kein Plüsch'
	String get calc_plush_none => 'Kein Plüsch';

	/// de: 'Donut Dimensions-Malus'
	String get calc_donut_penalty => 'Donut Dimensions-Malus';

	/// de: 'Kein Malus'
	String get calc_donut_none => 'Kein Malus';

	/// de: '1 Stern niedriger (-10%)'
	String get calc_donut_minus1 => '1 Stern niedriger (-10%)';

	/// de: '2+ Sterne niedriger (-70%)'
	String get calc_donut_minus2 => '2+ Sterne niedriger (-70%)';

	/// de: 'Fehlende Orden (Gehorsam)'
	String get calc_missing_badges => 'Fehlende Orden (Gehorsam)';

	/// de: 'Unbemerkt (Rücken/Tarnung)'
	String get calc_unnoticed => 'Unbemerkt (Rücken/Tarnung)';

	/// de: 'Shiny Form'
	String get shiny_form => 'Shiny Form';

	/// de: 'Normale Form'
	String get normal_form => 'Normale Form';

	/// de: 'Backup erfolgreich im Downloads-Ordner gespeichert!'
	String get backup_success_android => 'Backup erfolgreich im Downloads-Ordner gespeichert!';

	/// de: 'Direktes Speichern fehlgeschlagen. Bitte wähle einen Speicherort manuell aus.'
	String get backup_fallback_android => 'Direktes Speichern fehlgeschlagen. Bitte wähle einen Speicherort manuell aus.';

	/// de: 'Neuer Ordner'
	String get folder_create_title => 'Neuer Ordner';

	/// de: 'Ordnername'
	String get folder_name_hint => 'Ordnername';

	/// de: 'Ordner umbenennen'
	String get folder_rename_title => 'Ordner umbenennen';

	/// de: 'Verschieben nach...'
	String get folder_move_title => 'Verschieben nach...';

	/// de: 'Hier ist es noch leer.'
	String get folder_empty => 'Hier ist es noch leer.';

	/// de: 'Umbenennen'
	String get action_rename => 'Umbenennen';

	/// de: 'Verschieben...'
	String get action_move => 'Verschieben...';

	/// de: 'Löschen (Inhalt bleibt erhalten)'
	String get action_delete_keep => 'Löschen (Inhalt bleibt erhalten)';

	/// de: 'Ordner öffnen'
	String get action_open => 'Ordner öffnen';

	/// de: 'Manuell'
	String get sort_manual => 'Manuell';

	/// de: 'A-Z'
	String get sort_az => 'A-Z';

	/// de: 'Fortschritt'
	String get sort_progress => 'Fortschritt';

	/// de: 'Region'
	String get sort_region => 'Region';

	/// de: 'Fehler: Ein Ordner kann nicht in sich selbst oder seine eigenen Unterordner verschoben werden!'
	String get error_cyclic_move => 'Fehler: Ein Ordner kann nicht in sich selbst oder seine eigenen Unterordner verschoben werden!';

	/// de: 'Ordner löschen'
	String get delete_folder_title => 'Ordner löschen';

	/// de: 'Möchtest du diesen Ordner wirklich löschen? Der Inhalt wird sicher auf den Hauptbildschirm verschoben.'
	String get delete_folder_text => 'Möchtest du diesen Ordner wirklich löschen? Der Inhalt wird sicher auf den Hauptbildschirm verschoben.';

	/// de: 'Hauptverzeichnis'
	String get folder_root => 'Hauptverzeichnis';

	/// de: 'Ordner erfolgreich gelöscht.'
	String get success_delete_folder => 'Ordner erfolgreich gelöscht.';

	/// de: 'Fehler beim Löschen des Ordners:'
	String get error_delete_folder => 'Fehler beim Löschen des Ordners:';

	/// de: 'Pokédex erfolgreich gelöscht.'
	String get success_delete_dex => 'Pokédex erfolgreich gelöscht.';

	/// de: 'Fehler beim Löschen des Pokédex:'
	String get error_delete_dex => 'Fehler beim Löschen des Pokédex:';

	/// de: 'Fehler beim Verschieben:'
	String get error_move_item => 'Fehler beim Verschieben:';

	/// de: 'Erfolgreich verschoben.'
	String get success_move_item => 'Erfolgreich verschoben.';

	/// de: 'Zucht und Entwicklung'
	String get breeding_info_title => 'Zucht und Entwicklung';

	/// de: 'Geschlechter'
	String get gender_ratio => 'Geschlechter';

	/// de: 'Ei-Gruppen'
	String get egg_groups => 'Ei-Gruppen';

	/// de: 'Geschlechtslos'
	String get gender_genderless => 'Geschlechtslos';

	/// de: 'Basisform / Ei'
	String get evo_base_form => 'Basisform / Ei';

	/// de: 'Baby-Pokémon'
	String get evo_baby => 'Baby-Pokémon';

	/// de: 'Monster'
	String get egg_group_monster => 'Monster';

	/// de: 'Wasser 1'
	String get egg_group_water1 => 'Wasser 1';

	/// de: 'Käfer'
	String get egg_group_bug => 'Käfer';

	/// de: 'Flug'
	String get egg_group_flying => 'Flug';

	/// de: 'Feld'
	String get egg_group_ground => 'Feld';

	/// de: 'Fee'
	String get egg_group_fairy => 'Fee';

	/// de: 'Pflanze'
	String get egg_group_plant => 'Pflanze';

	/// de: 'Humanoid'
	String get egg_group_humanshape => 'Humanoid';

	/// de: 'Wasser 3'
	String get egg_group_water3 => 'Wasser 3';

	/// de: 'Mineral'
	String get egg_group_mineral => 'Mineral';

	/// de: 'Amorph'
	String get egg_group_amorphous => 'Amorph';

	/// de: 'Wasser 2'
	String get egg_group_water2 => 'Wasser 2';

	/// de: 'Ditto'
	String get egg_group_ditto => 'Ditto';

	/// de: 'Unbekannt'
	String get egg_group_noeggs => 'Unbekannt';

	/// de: 'Levelaufstieg'
	String get trigger_level_up => 'Levelaufstieg';

	/// de: 'Item anwenden'
	String get trigger_use_item => 'Item anwenden';

	/// de: 'Tausch'
	String get trigger_trade => 'Tausch';

	/// de: 'Drehung'
	String get trigger_spin => 'Drehung';

	/// de: '3 Volltreffer in einem Kampf'
	String get trigger_three_critical_hits => '3 Volltreffer in einem Kampf';

	/// de: '3 Gladiantri mit Anführersymbol besiegen'
	String get trigger_three_defeated_bisharp => '3 Gladiantri mit Anführersymbol besiegen';

	/// de: '999 Gierspenst-Münzen'
	String get trigger_gimmighoul_coins => '999 Gierspenst-Münzen';

	/// de: 'Turm des Unlichts'
	String get trigger_tower_of_darkness => 'Turm des Unlichts';

	/// de: 'Turm des Wassers'
	String get trigger_tower_of_waters => 'Turm des Wassers';

	/// de: 'Freier Platz im Team & Pokéball'
	String get trigger_shed => 'Freier Platz im Team & Pokéball';

	/// de: 'Rückstoß-Schaden'
	String get trigger_recoil_damage => 'Rückstoß-Schaden';

	/// de: 'Schaden erlitten'
	String get trigger_take_damage => 'Schaden erlitten';

	/// de: 'Kraft-Technik einsetzen'
	String get trigger_strong_style_move => 'Kraft-Technik einsetzen';

	/// de: 'Tempo-Technik einsetzen'
	String get trigger_agile_style_move => 'Tempo-Technik einsetzen';

	/// de: 'Attacke einsetzen'
	String get trigger_use_move => 'Attacke einsetzen';

	/// de: 'Besondere Bedingung'
	String get trigger_other => 'Besondere Bedingung';

	/// de: 'Level {0}'
	String get evo_level => 'Level {0}';

	/// de: 'ab Level {0}'
	String get evo_level_above => 'ab Level {0}';

	/// de: 'hohe Zuneigung'
	String get evo_happiness => 'hohe Zuneigung';

	/// de: 'hohe Zutraulichkeit'
	String get evo_affection => 'hohe Zutraulichkeit';

	/// de: 'Schönheit {0}+'
	String get evo_beauty => 'Schönheit {0}+';

	/// de: 'am Tag'
	String get evo_time_day => 'am Tag';

	/// de: 'in der Nacht'
	String get evo_time_night => 'in der Nacht';

	/// de: 'in der Dämmerung'
	String get evo_time_dusk => 'in der Dämmerung';

	/// de: 'bei Vollmond'
	String get evo_time_full_moon => 'bei Vollmond';

	/// de: 'trägt {0}'
	String get evo_held_item => 'trägt {0}';

	/// de: 'Attacke {0}'
	String get evo_move => 'Attacke {0}';

	/// de: '{0}-Attacke'
	String get evo_move_type => '{0}-Attacke';

	/// de: 'an Ort {0}'
	String get evo_location => 'an Ort {0}';

	/// de: 'in der Nähe eines Moos-/Eisfelsens'
	String get evo_special_rock => 'in der Nähe eines Moos-/Eisfelsens';

	/// de: 'besonderes Magnetfeld'
	String get evo_magnetic_field => 'besonderes Magnetfeld';

	/// de: 'bei Regen'
	String get evo_rain => 'bei Regen';

	/// de: 'Konsole umdrehen'
	String get evo_upside_down => 'Konsole umdrehen';

	/// de: 'mit {0} im Team'
	String get evo_party_species => 'mit {0} im Team';

	/// de: 'mit {0}-Pokémon im Team'
	String get evo_party_type => 'mit {0}-Pokémon im Team';

	/// de: 'gegen {0}'
	String get evo_trade_species => 'gegen {0}';

	/// de: 'Remoraid'
	String get species_remoraid => 'Remoraid';

	/// de: 'Schnuthelm'
	String get species_shelmet => 'Schnuthelm';

	/// de: 'Laukaps'
	String get species_karrablast => 'Laukaps';

	/// de: 'im Mehrspielermodus'
	String get evo_multiplayer => 'im Mehrspielermodus';

	/// de: 'nach {0} Schritten (Let's Go)'
	String get evo_steps => 'nach {0} Schritten (Let\'s Go)';

	/// de: '{0}+ Schaden'
	String get evo_damage => '{0}+ Schaden';

	/// de: '{0}× eingesetzt'
	String get evo_move_count => '{0}× eingesetzt';

	/// de: 'weiblich'
	String get evo_gender_female => 'weiblich';

	/// de: 'männlich'
	String get evo_gender_male => 'männlich';

	/// de: 'Angriff > Vert.'
	String get evo_stat_atk_gt_def => 'Angriff > Vert.';

	/// de: 'Angriff < Vert.'
	String get evo_stat_atk_lt_def => 'Angriff < Vert.';

	/// de: 'Angriff = Vert.'
	String get evo_stat_atk_eq_def => 'Angriff = Vert.';

	/// de: 'Wasserstein'
	String get item_water_stone => 'Wasserstein';

	/// de: 'Feuerstein'
	String get item_fire_stone => 'Feuerstein';

	/// de: 'Donnerstein'
	String get item_thunder_stone => 'Donnerstein';

	/// de: 'Blattstein'
	String get item_leaf_stone => 'Blattstein';

	/// de: 'Mondstein'
	String get item_moon_stone => 'Mondstein';

	/// de: 'Sonnenstein'
	String get item_sun_stone => 'Sonnenstein';

	/// de: 'Leuchtstein'
	String get item_shiny_stone => 'Leuchtstein';

	/// de: 'Finsterstein'
	String get item_dusk_stone => 'Finsterstein';

	/// de: 'Funkelstein'
	String get item_dawn_stone => 'Funkelstein';

	/// de: 'Eisstein'
	String get item_ice_stone => 'Eisstein';

	/// de: 'Glorienrüstung'
	String get item_auspicious_armor => 'Glorienrüstung';

	/// de: 'Schwarzaugit'
	String get item_black_augurite => 'Schwarzaugit';

	/// de: 'Löchrige Kanne'
	String get item_chipped_pot => 'Löchrige Kanne';

	/// de: 'Rissige Kanne'
	String get item_cracked_pot => 'Rissige Kanne';

	/// de: 'Galarnuss-Reif'
	String get item_galarica_cuff => 'Galarnuss-Reif';

	/// de: 'Galarnuss-Kranz'
	String get item_galarica_wreath => 'Galarnuss-Kranz';

	/// de: 'Fluchrüstung'
	String get item_malicious_armor => 'Fluchrüstung';

	/// de: 'Edle Teeschale'
	String get item_masterpiece_teacup => 'Edle Teeschale';

	/// de: 'Legierungsmetall'
	String get item_metal_alloy => 'Legierungsmetall';

	/// de: 'Torfblock'
	String get item_peat_block => 'Torfblock';

	/// de: 'Unlicht-Schriftrolle'
	String get item_scroll_of_darkness => 'Unlicht-Schriftrolle';

	/// de: 'Wasser-Schriftrolle'
	String get item_scroll_of_waters => 'Wasser-Schriftrolle';

	/// de: 'Süßer Apfel'
	String get item_sweet_apple => 'Süßer Apfel';

	/// de: 'Saftiger Apfel'
	String get item_syrupy_apple => 'Saftiger Apfel';

	/// de: 'Saurer Apfel'
	String get item_tart_apple => 'Saurer Apfel';

	/// de: 'Simple Teeschale'
	String get item_unremarkable_teacup => 'Simple Teeschale';

	/// de: 'Abyssplatte'
	String get item_deep_sea_scale => 'Abyssplatte';

	/// de: 'Abysszahn'
	String get item_deep_sea_tooth => 'Abysszahn';

	/// de: 'Drachenhaut'
	String get item_dragon_scale => 'Drachenhaut';

	/// de: 'Dubiosdisc'
	String get item_dubious_disc => 'Dubiosdisc';

	/// de: 'Stromisierer'
	String get item_electirizer => 'Stromisierer';

	/// de: 'King-Stein'
	String get item_kings_rock => 'King-Stein';

	/// de: 'Magmaisierer'
	String get item_magmarizer => 'Magmaisierer';

	/// de: 'Metallmantel'
	String get item_metal_coat => 'Metallmantel';

	/// de: 'Ovaler Stein'
	String get item_oval_stone => 'Ovaler Stein';

	/// de: 'Schönschuppe'
	String get item_prism_scale => 'Schönschuppe';

	/// de: 'Schützer'
	String get item_protector => 'Schützer';

	/// de: 'Scharfklaue'
	String get item_razor_claw => 'Scharfklaue';

	/// de: 'Scharfzahn'
	String get item_razor_fang => 'Scharfzahn';

	/// de: 'Düsterumhang'
	String get item_reaper_cloth => 'Düsterumhang';

	/// de: 'Duftbeutel'
	String get item_sachet => 'Duftbeutel';

	/// de: 'Up-Grade'
	String get item_up_grade => 'Up-Grade';

	/// de: 'Sahnehäubchen'
	String get item_whipped_dream => 'Sahnehäubchen';

	/// de: 'Antik-Kraft'
	String get move_ancient_power => 'Antik-Kraft';

	/// de: 'Giftstachelregen'
	String get move_barb_barrage => 'Giftstachelregen';

	/// de: 'Doppelschlag'
	String get move_double_hit => 'Doppelschlag';

	/// de: 'Drachenschrei'
	String get move_dragon_cheer => 'Drachenschrei';

	/// de: 'Drachenpuls'
	String get move_dragon_pulse => 'Drachenpuls';

	/// de: 'Hyperbohrer'
	String get move_hyper_drill => 'Hyperbohrer';

	/// de: 'Mimikry'
	String get move_mimic => 'Mimikry';

	/// de: 'Barrierenstoß'
	String get move_psyshield_bash => 'Barrierenstoß';

	/// de: 'Zornesfaust'
	String get move_rage_fist => 'Zornesfaust';

	/// de: 'Walzer'
	String get move_rollout => 'Walzer';

	/// de: 'Stampfer'
	String get move_stomp => 'Stampfer';

	/// de: 'Verhöhner'
	String get move_taunt => 'Verhöhner';

	/// de: 'Doppelstrahl'
	String get move_twin_beam => 'Doppelstrahl';

	/// de: 'Glühberg'
	String get loc_blush_mountain => 'Glühberg';

	/// de: 'Elektrolithhöhle'
	String get loc_chargestone_cave => 'Elektrolithhöhle';

	/// de: 'Ewigwald'
	String get loc_eterna_forest => 'Ewigwald';

	/// de: 'Frosthöhle'
	String get loc_frost_cavern => 'Frosthöhle';

	/// de: 'Route 13 (Kalos)'
	String get loc_kalos_route_13 => 'Route 13 (Kalos)';

	/// de: 'Route 20 (Kalos)'
	String get loc_kalos_route_20 => 'Route 20 (Kalos)';

	/// de: 'Schattendschungel'
	String get loc_lush_jungle => 'Schattendschungel';

	/// de: 'Mount Lanakila'
	String get loc_mount_lanakila => 'Mount Lanakila';

	/// de: 'Kraterberg'
	String get loc_mt_coronet => 'Kraterberg';

	/// de: 'Neu Malvenfroh'
	String get loc_new_mauville => 'Neu Malvenfroh';

	/// de: 'Blütenburgwald'
	String get loc_petalburg_woods => 'Blütenburgwald';

	/// de: 'Ewigenwald'
	String get loc_pinwheel_forest => 'Ewigenwald';

	/// de: 'Küstenhöhle'
	String get loc_shoal_cave => 'Küstenhöhle';

	/// de: 'Route 217 (Sinnoh)'
	String get loc_sinnoh_route_217 => 'Route 217 (Sinnoh)';

	/// de: 'Wendelberg'
	String get loc_twist_mountain => 'Wendelberg';

	/// de: 'Canyon von Poni'
	String get loc_vast_poni_canyon => 'Canyon von Poni';

	/// de: 'Überspringen'
	String get tutorial_skip => 'Überspringen';

	/// de: 'Weiter'
	String get tutorial_next => 'Weiter';

	/// de: 'Verstanden!'
	String get tutorial_finish => 'Verstanden!';

	/// de: 'Tutorials & Hilfe'
	String get tutorial_menu_title => 'Tutorials & Hilfe';

	/// de: 'Tutorials & Anleitungen'
	String get tutorial_center_title => 'Tutorials & Anleitungen';

	/// de: 'Lerne alle Funktionen von PokéVault kennen oder wiederhole gezielt einzelne Bereiche.'
	String get tutorial_center_subtitle => 'Lerne alle Funktionen von PokéVault kennen oder wiederhole gezielt einzelne Bereiche.';

	/// de: 'v1.6 Neuheiten-Tour starten'
	String get tutorial_v16_tour_btn => 'v1.6 Neuheiten-Tour starten';

	/// de: 'Themen & Kapitel'
	String get tutorial_chapters_header => 'Themen & Kapitel';

	/// de: 'Wiederholen'
	String get tutorial_replay => 'Wiederholen';

	/// de: 'Alle Tutorials zurücksetzen'
	String get tutorial_replay_all => 'Alle Tutorials zurücksetzen';

	/// de: 'Alle Tutorials wurden zurückgesetzt!'
	String get tutorial_replay_all_success => 'Alle Tutorials wurden zurückgesetzt!';

	/// de: 'Möchtest du wirklich alle Tutorials zurücksetzen? Beim nächsten Besuch werden wieder alle Hilfen und Erklärungen angezeigt.'
	String get tutorial_reset_confirm_msg => 'Möchtest du wirklich alle Tutorials zurücksetzen? Beim nächsten Besuch werden wieder alle Hilfen und Erklärungen angezeigt.';

	/// de: 'v1.6 Neuheiten-Tour aktiviert!'
	String get tutorial_tour_started => 'v1.6 Neuheiten-Tour aktiviert!';

	/// de: 'UPDATE v1.6'
	String get tutorial_v16_badge => 'UPDATE v1.6';

	/// de: 'Bzzzt! Neue Features entdeckt!'
	String get tutorial_v16_welcome_title => 'Bzzzt! Neue Features entdeckt!';

	/// de: 'Hallo Trainer! Während du fleißig gesammelt hast, habe ich dein PokéVault mit neuen Werkzeugen aufgerüstet:'
	String get tutorial_v16_welcome_desc => 'Hallo Trainer! Während du fleißig gesammelt hast, habe ich dein PokéVault mit neuen Werkzeugen aufgerüstet:';

	/// de: 'Neuheiten-Tour starten'
	String get tutorial_v16_start_tour => 'Neuheiten-Tour starten';

	/// de: 'Später ansehen'
	String get tutorial_v16_skip => 'Später ansehen';

	/// de: 'Shiny Hunt Tracker'
	String get tutorial_v16_f1_title => 'Shiny Hunt Tracker';

	/// de: 'Counter, Phasen, Quoten & Timer für deine Jagden!'
	String get tutorial_v16_f1_desc => 'Counter, Phasen, Quoten & Timer für deine Jagden!';

	/// de: 'Eigene Boxen & Stapel-Drag'
	String get tutorial_v16_f2_title => 'Eigene Boxen & Stapel-Drag';

	/// de: 'Boxen umbenennen, Inhalte per Stapel frei verschieben!'
	String get tutorial_v16_f2_desc => 'Boxen umbenennen, Inhalte per Stapel frei verschieben!';

	/// de: 'Statistiken & Share-Card'
	String get tutorial_v16_f3_title => 'Statistiken & Share-Card';

	/// de: 'Erfolge als schicke Grafik mit Trainernamen teilen!'
	String get tutorial_v16_f3_desc => 'Erfolge als schicke Grafik mit Trainernamen teilen!';

	/// de: 'Geschlechtsunterschiede & Details'
	String get tutorial_v16_f4_title => 'Geschlechtsunterschiede & Details';

	/// de: 'Vergleichende Ansichten, Zuchtrechner & Fundorte!'
	String get tutorial_v16_f4_desc => 'Vergleichende Ansichten, Zuchtrechner & Fundorte!';

	/// de: '1. Home & Sammlung'
	String get tutorial_chapter_home_title => '1. Home & Sammlung';

	/// de: 'Dexe anlegen, Spiele auswählen, Ordner erstellen und Sammlungen frei sortieren.'
	String get tutorial_chapter_home_desc => 'Dexe anlegen, Spiele auswählen, Ordner erstellen und Sammlungen frei sortieren.';

	/// de: 'Ordner & Sortierung'
	String get tutorial_home_organize_title => 'Ordner & Sortierung';

	/// de: 'Organisiere deine Dexe in Ordnern und passe ihre Anordnung beliebig per Drag & Drop an.'
	String get tutorial_home_organize_text => 'Organisiere deine Dexe in Ordnern und passe ihre Anordnung beliebig per Drag & Drop an.';

	/// de: '2. Dex-Erstellung & Filter'
	String get tutorial_chapter_create_dex_title => '2. Dex-Erstellung & Filter';

	/// de: 'Spezifische Unter-Dexe wählen, Shinys, Geschlechter, Formen, Megas & G-Max aktivieren.'
	String get tutorial_chapter_create_dex_desc => 'Spezifische Unter-Dexe wählen, Shinys, Geschlechter, Formen, Megas & G-Max aktivieren.';

	/// de: '3. Pokédex & Fangliste'
	String get tutorial_chapter_dex_screen_title => '3. Pokédex & Fangliste';

	/// de: 'Pokémon als gefangen markieren, Listen- vs. Boxansicht, Ignorier-Funktion & Filter.'
	String get tutorial_chapter_dex_screen_desc => 'Pokémon als gefangen markieren, Listen- vs. Boxansicht, Ignorier-Funktion & Filter.';

	/// de: 'Gefangen markieren'
	String get tutorial_dex_tap_catch_title => 'Gefangen markieren';

	/// de: 'Tippe auf eine Karte, um den Fangstatus blitzschnell zwischen gefangen und offen umzuschalten.'
	String get tutorial_dex_tap_catch_text => 'Tippe auf eine Karte, um den Fangstatus blitzschnell zwischen gefangen und offen umzuschalten.';

	/// de: 'Pokémon-Details'
	String get tutorial_dex_details_title => 'Pokémon-Details';

	/// de: 'Halte eine Pokémon-Karte lange gedrückt, um ihre Details, Attacken, Zucht und Fundorte zu öffnen.'
	String get tutorial_dex_details_text => 'Halte eine Pokémon-Karte lange gedrückt, um ihre Details, Attacken, Zucht und Fundorte zu öffnen.';

	/// de: 'Listen- & Boxansicht'
	String get tutorial_dex_modes_title => 'Listen- & Boxansicht';

	/// de: 'Wechsle oben rechts zwischen der klassischen Listenansicht und der authentischen PC-Boxenansicht.'
	String get tutorial_dex_modes_text => 'Wechsle oben rechts zwischen der klassischen Listenansicht und der authentischen PC-Boxenansicht.';

	/// de: 'Filter & Suchleiste'
	String get tutorial_dex_filter_title => 'Filter & Suchleiste';

	/// de: 'Filtere nach Status (Gefangen/Fehlend), Typen oder suche blitzschnell nach Namen und Nummern.'
	String get tutorial_dex_filter_text => 'Filtere nach Status (Gefangen/Fehlend), Typen oder suche blitzschnell nach Namen und Nummern.';

	/// de: '4. Box-Management (v1.6)'
	String get tutorial_chapter_box_mgmt_title => '4. Box-Management (v1.6)';

	/// de: 'Eigene Boxen anlegen, umbenennen, Reihenfolge anpassen & Stapel-Verschieben nutzen.'
	String get tutorial_chapter_box_mgmt_desc => 'Eigene Boxen anlegen, umbenennen, Reihenfolge anpassen & Stapel-Verschieben nutzen.';

	/// de: 'Eigene Boxen anlegen'
	String get tutorial_box_custom_title => 'Eigene Boxen anlegen';

	/// de: 'Erstelle und benenne Boxen wie in deinen Original-Spielen (z. B. 'Kanto Living Dex 1').'
	String get tutorial_box_custom_text => 'Erstelle und benenne Boxen wie in deinen Original-Spielen (z. B. \'Kanto Living Dex 1\').';

	/// de: 'Mehrfachauswahl'
	String get tutorial_box_batch_title => 'Mehrfachauswahl';

	/// de: 'Tippe auf mehrere Pokémon, um sie gemeinsam als Stapel auszuwählen und zu bewegen.'
	String get tutorial_box_batch_text => 'Tippe auf mehrere Pokémon, um sie gemeinsam als Stapel auszuwählen und zu bewegen.';

	/// de: 'Drag & Drop Verschiebung'
	String get tutorial_box_drag_title => 'Drag & Drop Verschiebung';

	/// de: 'Verschiebe Pokémon per Drag & Drop flexibel auf freie Slots oder tausche Plätze.'
	String get tutorial_box_drag_text => 'Verschiebe Pokémon per Drag & Drop flexibel auf freie Slots oder tausche Plätze.';

	/// de: 'Auto-Shift & Platzhalter'
	String get tutorial_box_shift_title => 'Auto-Shift & Platzhalter';

	/// de: 'Aktiviere Auto-Shift, um Lücken automatisch zu schließen, oder setze feste Platzhalter.'
	String get tutorial_box_shift_text => 'Aktiviere Auto-Shift, um Lücken automatisch zu schließen, oder setze feste Platzhalter.';

	/// de: 'Kapazitätsgrenzen & Folgeboxen'
	String get tutorial_box_limits_title => 'Kapazitätsgrenzen & Folgeboxen';

	/// de: 'Lege feste Boxgrößen fest und lasse Überläufe automatisch in die nächste Folgebox fließen.'
	String get tutorial_box_limits_text => 'Lege feste Boxgrößen fest und lasse Überläufe automatisch in die nächste Folgebox fließen.';

	/// de: '5. Shiny Hunt Tracker'
	String get tutorial_chapter_shiny_hunt_title => '5. Shiny Hunt Tracker';

	/// de: 'Neue Jagd anlegen, Counter bedienen, Phasen erfassen sowie Multi-Hunt Dashboard & Auto-Counter nutzen.'
	String get tutorial_chapter_shiny_hunt_desc => 'Neue Jagd anlegen, Counter bedienen, Phasen erfassen sowie Multi-Hunt Dashboard & Auto-Counter nutzen.';

	/// de: 'Shiny Hunt Hub'
	String get tutorial_shiny_hub_title => 'Shiny Hunt Hub';

	/// de: 'Hier findest du all deine aktiven und abgeschlossenen Jagden auf einen Blick.'
	String get tutorial_shiny_hub_text => 'Hier findest du all deine aktiven und abgeschlossenen Jagden auf einen Blick.';

	/// de: 'Neue Jagd starten'
	String get tutorial_shiny_new_title => 'Neue Jagd starten';

	/// de: 'Wähle Ziel-Pokémon, Spiel, Methode (Masuda, Reset, Kette) und aktiviere den Schillerpin.'
	String get tutorial_shiny_new_text => 'Wähle Ziel-Pokémon, Spiel, Methode (Masuda, Reset, Kette) und aktiviere den Schillerpin.';

	/// de: 'Großer Zähler & Steuerung'
	String get tutorial_shiny_counter_title => 'Großer Zähler & Steuerung';

	/// de: 'Zähle Begegnungen per Tap, Tastatur [Leertaste] oder Lautstärketasten für maximalen Komfort.'
	String get tutorial_shiny_counter_text => 'Zähle Begegnungen per Tap, Tastatur [Leertaste] oder Lautstärketasten für maximalen Komfort.';

	/// de: 'Phasen erfassen'
	String get tutorial_shiny_phases_title => 'Phasen erfassen';

	/// de: 'Taucht ein anderes Shiny auf? Erfasse es als Phase, ohne deinen Gesamtzähler zu verlieren.'
	String get tutorial_shiny_phases_text => 'Taucht ein anderes Shiny auf? Erfasse es als Phase, ohne deinen Gesamtzähler zu verlieren.';

	/// de: 'Wahrscheinlichkeiten & Timer'
	String get tutorial_shiny_stats_title => 'Wahrscheinlichkeiten & Timer';

	/// de: 'Behalte deine binomiale Chance und deine Jagdzeit mit integriertem Stoppuhr-Timer im Auge.'
	String get tutorial_shiny_stats_text => 'Behalte deine binomiale Chance und deine Jagdzeit mit integriertem Stoppuhr-Timer im Auge.';

	/// de: '6. Statistiken & Erfolgs-Karte (v1.6)'
	String get tutorial_chapter_stats_share_title => '6. Statistiken & Erfolgs-Karte (v1.6)';

	/// de: 'Detaillierten Fang-Fortschritt prüfen und als hochwertige Grafik exportieren/teilen.'
	String get tutorial_chapter_stats_share_desc => 'Detaillierten Fang-Fortschritt prüfen und als hochwertige Grafik exportieren/teilen.';

	/// de: 'Fortschritt & Statistiken'
	String get tutorial_stats_intro_title => 'Fortschritt & Statistiken';

	/// de: 'Öffne das Diagramm-Icon im Dex-Header, um deine Gesamtfangrate im Detail zu analysieren.'
	String get tutorial_stats_intro_text => 'Öffne das Diagramm-Icon im Dex-Header, um deine Gesamtfangrate im Detail zu analysieren.';

	/// de: 'Generationen, Typen & Varianten'
	String get tutorial_stats_breakdown_title => 'Generationen, Typen & Varianten';

	/// de: 'Erfahre genau, in welchen Generationen oder Typen dir noch Pokémon fehlen.'
	String get tutorial_stats_breakdown_text => 'Erfahre genau, in welchen Generationen oder Typen dir noch Pokémon fehlen.';

	/// de: 'Erfolgs-Karte (Share Card)'
	String get tutorial_share_card_title => 'Erfolgs-Karte (Share Card)';

	/// de: 'Generiere ein offizielles Diplom oder eine Infografik mit deinem Trainernamen.'
	String get tutorial_share_card_text => 'Generiere ein offizielles Diplom oder eine Infografik mit deinem Trainernamen.';

	/// de: 'Formate & Stile'
	String get tutorial_share_formats_title => 'Formate & Stile';

	/// de: 'Wähle zwischen Querformat (16:9), Quadrat (1:1) oder Instagram Story (9:16) und teile als PNG!'
	String get tutorial_share_formats_text => 'Wähle zwischen Querformat (16:9), Quadrat (1:1) oder Instagram Story (9:16) und teile als PNG!';

	/// de: '7. Pokémon-Details & Rechner (v1.6)'
	String get tutorial_chapter_pokemon_info_title => '7. Pokémon-Details & Rechner (v1.6)';

	/// de: 'Geschlechtsunterschiede, Zucht- & Fangraten-Rechner, Bälle, Tera-Typen & Event-Status.'
	String get tutorial_chapter_pokemon_info_desc => 'Geschlechtsunterschiede, Zucht- & Fangraten-Rechner, Bälle, Tera-Typen & Event-Status.';

	/// de: 'Geschlechtsunterschiede'
	String get tutorial_info_gender_title => 'Geschlechtsunterschiede';

	/// de: 'Vergleiche männliche und weibliche Formen mit detaillierten Hervorhebungen der optischen Merkmale.'
	String get tutorial_info_gender_text => 'Vergleiche männliche und weibliche Formen mit detaillierten Hervorhebungen der optischen Merkmale.';

	/// de: 'Spezielle Fundorte & Events'
	String get tutorial_info_obtainable_title => 'Spezielle Fundorte & Events';

	/// de: 'Prüfe, ob ein Pokémon durch Tausch, Geschenke, Fossilien oder Events erhältlich ist.'
	String get tutorial_info_obtainable_text => 'Prüfe, ob ein Pokémon durch Tausch, Geschenke, Fossilien oder Events erhältlich ist.';

	/// de: 'Zucht und Entwicklung'
	String get tutorial_info_breeding_title => 'Zucht und Entwicklung';

	/// de: 'Klappe diesen Bereich aus, um alles über Ei-Gruppen, Geschlechter und die genauen Entwicklungsbedingungen zu erfahren.'
	String get tutorial_info_breeding_text => 'Klappe diesen Bereich aus, um alles über Ei-Gruppen, Geschlechter und die genauen Entwicklungsbedingungen zu erfahren.';

	/// de: 'Fangraten-Rechner'
	String get tutorial_info_catch_calc_title => 'Fangraten-Rechner';

	/// de: 'Simuliere Fangchancen basierend auf KP, Statusproblemen und deinem bevorzugten Pokéball.'
	String get tutorial_info_catch_calc_text => 'Simuliere Fangchancen basierend auf KP, Statusproblemen und deinem bevorzugten Pokéball.';

	/// de: 'Direkte Jagd starten'
	String get tutorial_info_direct_hunt_title => 'Direkte Jagd starten';

	/// de: 'Starte einen neuen Shiny Hunt mit einem Klick direkt aus dem Detailbildschirm dieses Pokémon!'
	String get tutorial_info_direct_hunt_text => 'Starte einen neuen Shiny Hunt mit einem Klick direkt aus dem Detailbildschirm dieses Pokémon!';

	/// de: '8. Routen- & Fundort-Tracker (v1.6)'
	String get tutorial_chapter_route_tracker_title => '8. Routen- & Fundort-Tracker (v1.6)';

	/// de: 'Erfasse gefangene Pokémon ortsbezogen pro Spielroute und behalte offene Gebiete im Blick.'
	String get tutorial_chapter_route_tracker_desc => 'Erfasse gefangene Pokémon ortsbezogen pro Spielroute und behalte offene Gebiete im Blick.';

	/// de: 'Routen-Übersicht'
	String get tutorial_route_hub_title => 'Routen-Übersicht';

	/// de: 'Öffne den Routen-Tracker über das Standort-Symbol in der Dex-Leiste oben.'
	String get tutorial_route_hub_text => 'Öffne den Routen-Tracker über das Standort-Symbol in der Dex-Leiste oben.';

	/// de: 'Spawns & Fangmethoden'
	String get tutorial_route_spawns_title => 'Spawns & Fangmethoden';

	/// de: 'Sieh genau, welche Pokémon im hohen Gras, beim Surfen oder beim Angeln auftauchen.'
	String get tutorial_route_spawns_text => 'Sieh genau, welche Pokémon im hohen Gras, beim Surfen oder beim Angeln auftauchen.';

	/// de: 'Gebiets-Filter'
	String get tutorial_route_filters_title => 'Gebiets-Filter';

	/// de: 'Filtere nach unvollständigen Routen, um gezielt fehlende Pokémon nachzufangen.'
	String get tutorial_route_filters_text => 'Filtere nach unvollständigen Routen, um gezielt fehlende Pokémon nachzufangen.';

	/// de: '100% Routen-Meisterschaft'
	String get tutorial_route_mastery_title => '100% Routen-Meisterschaft';

	/// de: 'Schließe alle Routen ab, um die vollständige Erkundung des Spiels zu meistern!'
	String get tutorial_route_mastery_text => 'Schließe alle Routen ab, um die vollständige Erkundung des Spiels zu meistern!';

	/// de: '9. Steuerung & Shortcuts (v1.6)'
	String get tutorial_chapter_controls_title => '9. Steuerung & Shortcuts (v1.6)';

	/// de: 'Effiziente Shortcuts für Desktop, Wischgesten, Schnellwahl und Tastatur-Navigation.'
	String get tutorial_chapter_controls_desc => 'Effiziente Shortcuts für Desktop, Wischgesten, Schnellwahl und Tastatur-Navigation.';

	/// de: 'Desktop-Tastenkürzel'
	String get tutorial_ctrl_desktop_title => 'Desktop-Tastenkürzel';

	/// de: 'Nutze die Leertaste im Shiny-Counter, Strg+F zum Suchen und Pfeiltasten für Boxen.'
	String get tutorial_ctrl_desktop_text => 'Nutze die Leertaste im Shiny-Counter, Strg+F zum Suchen und Pfeiltasten für Boxen.';

	/// de: 'Schnellnavigation'
	String get tutorial_ctrl_shortcuts_title => 'Schnellnavigation';

	/// de: 'Navigiere blitzschnell mit Zifferntasten oder Tastaturkürzeln durch alle Menüs.'
	String get tutorial_ctrl_shortcuts_text => 'Navigiere blitzschnell mit Zifferntasten oder Tastaturkürzeln durch alle Menüs.';

	/// de: 'Mobile Wischgesten'
	String get tutorial_ctrl_gestures_title => 'Mobile Wischgesten';

	/// de: 'Wische horizontal, um zwischen Boxen zu blättern, und halte gedrückt für Details.'
	String get tutorial_ctrl_gestures_text => 'Wische horizontal, um zwischen Boxen zu blättern, und halte gedrückt für Details.';

	/// de: 'Gamepad & Zubehör'
	String get tutorial_ctrl_gamepad_title => 'Gamepad & Zubehör';

	/// de: 'Unterstützung für externe Bluetooth-Tastaturen und Gamepads für bequemes Tracken.'
	String get tutorial_ctrl_gamepad_text => 'Unterstützung für externe Bluetooth-Tastaturen und Gamepads für bequemes Tracken.';

	/// de: '10. Cloud-Sync & Backups'
	String get tutorial_chapter_backup_title => '10. Cloud-Sync & Backups';

	/// de: 'Google Drive Cloud-Sync, automatische lokale Backups & sicherer Daten-Export/Import.'
	String get tutorial_chapter_backup_desc => 'Google Drive Cloud-Sync, automatische lokale Backups & sicherer Daten-Export/Import.';

	/// de: 'Google Drive Synchronisation'
	String get tutorial_backup_cloud_title => 'Google Drive Synchronisation';

	/// de: 'Verbinde dein Google Drive Konto, um deinen Pokédex, gefangene Pokémon und Shiny Hunts automatisch geräteübergreifend zu sichern.'
	String get tutorial_backup_cloud_text => 'Verbinde dein Google Drive Konto, um deinen Pokédex, gefangene Pokémon und Shiny Hunts automatisch geräteübergreifend zu sichern.';

	/// de: 'Automatische lokale Sicherungen'
	String get tutorial_backup_auto_title => 'Automatische lokale Sicherungen';

	/// de: 'PokéVault erstellt vor kritischen Änderungen und in regelmäßigen Abständen automatische Backups in deinem App-Datenordner.'
	String get tutorial_backup_auto_text => 'PokéVault erstellt vor kritischen Änderungen und in regelmäßigen Abständen automatische Backups in deinem App-Datenordner.';

	/// de: 'Manueller Backup-Export'
	String get tutorial_backup_export_title => 'Manueller Backup-Export';

	/// de: 'Du kannst jederzeit ein vollständiges Backup als Datei exportieren, um deine Daten manuell zu archivieren oder auf ein neues Gerät mitzunehmen.'
	String get tutorial_backup_export_text => 'Du kannst jederzeit ein vollständiges Backup als Datei exportieren, um deine Daten manuell zu archivieren oder auf ein neues Gerät mitzunehmen.';

	/// de: 'Wiederherstellung & Downgrade-Schutz'
	String get tutorial_backup_restore_title => 'Wiederherstellung & Downgrade-Schutz';

	/// de: 'Solltest du zu einer älteren Version wechseln oder Daten wiederherstellen wollen, schützt das System deine Datenbank vor Datenverlust.'
	String get tutorial_backup_restore_text => 'Solltest du zu einer älteren Version wechseln oder Daten wiederherstellen wollen, schützt das System deine Datenbank vor Datenverlust.';

	/// de: 'Jetzt ausprobieren'
	String get tutorial_try_now => 'Jetzt ausprobieren';

	/// de: 'Korrektur & Schrittweite'
	String get tutorial_shiny_buttons_title => 'Korrektur & Schrittweite';

	/// de: 'Passe deinen Zähler mit den Plus-/Minus-Tasten an oder wähle eine feste Schrittweite (+1, +5, +10).'
	String get tutorial_shiny_buttons_text => 'Passe deinen Zähler mit den Plus-/Minus-Tasten an oder wähle eine feste Schrittweite (+1, +5, +10).';

	/// de: 'Phasen & Fang-Abschluss'
	String get tutorial_shiny_phases_actions_title => 'Phasen & Fang-Abschluss';

	/// de: 'Trage unerwartete Shinys als Phase ein oder schließe deine Jagd erfolgreich über 'Shiny Gefangen!' ab.'
	String get tutorial_shiny_phases_actions_text => 'Trage unerwartete Shinys als Phase ein oder schließe deine Jagd erfolgreich über \'Shiny Gefangen!\' ab.';

	/// de: 'Hauptmenü & Dexe'
	String get tutorial_feature_home => 'Hauptmenü & Dexe';

	/// de: 'Pokémon Details & Fangrate'
	String get tutorial_feature_details => 'Pokémon Details & Fangrate';

	/// de: 'Ups! Rotom kann dieses Element gerade nicht finden.'
	String get tutorial_error_widget_not_found => 'Ups! Rotom kann dieses Element gerade nicht finden.';

	/// de: 'Dein erster Pokédex!'
	String get tutorial_home_fab_title => 'Dein erster Pokédex!';

	/// de: 'Tippe hier auf das Plus-Symbol, um einen neuen Pokédex oder einen Ordner zu erstellen.'
	String get tutorial_home_fab_text => 'Tippe hier auf das Plus-Symbol, um einen neuen Pokédex oder einen Ordner zu erstellen.';

	/// de: 'Suchen & Sortieren'
	String get tutorial_home_search_title => 'Suchen & Sortieren';

	/// de: 'Sobald deine Sammlung wächst, kannst du sie hier durchsuchen oder nach Fortschritt und Region sortieren.'
	String get tutorial_home_search_text => 'Sobald deine Sammlung wächst, kannst du sie hier durchsuchen oder nach Fortschritt und Region sortieren.';

	/// de: 'Bzzzt! Hallo!'
	String get tutorial_home_intro_title => 'Bzzzt! Hallo!';

	/// de: 'Ich bin Rotom, dein smarter Pokédex-Assistent! Ich zeige dir kurz, wie hier alles funktioniert. Los geht's!'
	String get tutorial_home_intro_text => 'Ich bin Rotom, dein smarter Pokédex-Assistent! Ich zeige dir kurz, wie hier alles funktioniert. Los geht\'s!';

	/// de: 'Dein Dex, dein Name'
	String get tutorial_create_name_title => 'Dein Dex, dein Name';

	/// de: 'Gib deinem Pokédex hier einen passenden Namen. (z.B. 'Kanto Living Dex')'
	String get tutorial_create_name_text => 'Gib deinem Pokédex hier einen passenden Namen. (z.B. \'Kanto Living Dex\')';

	/// de: 'Neuer Pokédex'
	String get tutorial_home_sheet_title => 'Neuer Pokédex';

	/// de: 'Tippe hier, um das Menü zur Erstellung deines Dexes zu öffnen.'
	String get tutorial_home_sheet_text => 'Tippe hier, um das Menü zur Erstellung deines Dexes zu öffnen.';

	/// de: 'Spiele & Generationen'
	String get tutorial_create_group_title => 'Spiele & Generationen';

	/// de: 'Wische nach links und rechts, um die Region zu wählen. Bei manchen Regionen erscheint darunter ein Dropdown für einen noch genaueren Dex (z.B. Kalos Zentral).'
	String get tutorial_create_group_text => 'Wische nach links und rechts, um die Region zu wählen. Bei manchen Regionen erscheint darunter ein Dropdown für einen noch genaueren Dex (z.B. Kalos Zentral).';

	/// de: 'Dein Dex, deine Regeln'
	String get tutorial_create_options_title => 'Dein Dex, deine Regeln';

	/// de: 'Möchtest du Shinys oder Geschlechter sammeln? Klappe 'Formen auswählen' auf, um Megas oder G-Max zu aktivieren. Aktiviere für den Anfang am besten alles!'
	String get tutorial_create_options_text => 'Möchtest du Shinys oder Geschlechter sammeln? Klappe \'Formen auswählen\' auf, um Megas oder G-Max zu aktivieren. Aktiviere für den Anfang am besten alles!';

	/// de: 'Los geht's!'
	String get tutorial_create_save_title => 'Los geht\'s!';

	/// de: 'Tippe auf Erstellen, um deinen ultimativen Dex anzulegen.'
	String get tutorial_create_save_text => 'Tippe auf Erstellen, um deinen ultimativen Dex anzulegen.';

	/// de: 'Tutorial neustarten'
	String get tutorial_reset_title => 'Tutorial neustarten';

	/// de: 'Setzt alle Tutorial-Hinweise zurück'
	String get tutorial_reset_sub => 'Setzt alle Tutorial-Hinweise zurück';

	/// de: 'Das Tutorial wurde erfolgreich zurückgesetzt!'
	String get tutorial_reset_success => 'Das Tutorial wurde erfolgreich zurückgesetzt!';

	/// de: 'Spiele & Generationen'
	String get tutorial_create_step1_title => 'Spiele & Generationen';

	/// de: 'Dies ist die Regionsauswahl. Wische in der Liste nach rechts.'
	String get tutorial_create_step1_text => 'Dies ist die Regionsauswahl. Wische in der Liste nach rechts.';

	/// de: 'Region auswählen'
	String get tutorial_create_step2_title => 'Region auswählen';

	/// de: 'Tippe jetzt auf 'Kalos & Z-A', um zu sehen, wie sich die Optionen anpassen.'
	String get tutorial_create_step2_text => 'Tippe jetzt auf \'Kalos & Z-A\', um zu sehen, wie sich die Optionen anpassen.';

	/// de: 'Spezifische Dexe'
	String get tutorial_create_step3_title => 'Spezifische Dexe';

	/// de: 'Einige Regionen bieten hier ein Dropdown (z.B. für Zentral-Kalos). Tippe auf das Feld, um fortzufahren.'
	String get tutorial_create_step3_text => 'Einige Regionen bieten hier ein Dropdown (z.B. für Zentral-Kalos). Tippe auf das Feld, um fortzufahren.';

	/// de: 'Die volle Auswahl'
	String get tutorial_create_step3_5_title => 'Die volle Auswahl';

	/// de: 'Hier kannst du genau wählen, welchen Teil der Region du spielen möchtest! Tippe auf die Liste, um sie wieder zu schließen.'
	String get tutorial_create_step3_5_text => 'Hier kannst du genau wählen, welchen Teil der Region du spielen möchtest! Tippe auf die Liste, um sie wieder zu schließen.';

	/// de: 'Zurück zum Start'
	String get tutorial_create_step4_title => 'Zurück zum Start';

	/// de: 'Wir wollen für dieses Tutorial aber alles! Wische die Liste wieder ganz nach links.'
	String get tutorial_create_step4_text => 'Wir wollen für dieses Tutorial aber alles! Wische die Liste wieder ganz nach links.';

	/// de: 'Nationaldex'
	String get tutorial_create_step5_title => 'Nationaldex';

	/// de: 'Tippe auf 'National', um wieder alle Pokémon auszuwählen.'
	String get tutorial_create_step5_text => 'Tippe auf \'National\', um wieder alle Pokémon auszuwählen.';

	/// de: 'Shiny Dex'
	String get tutorial_create_step6_title => 'Shiny Dex';

	/// de: 'Sammelst du Shinys? Tippe auf den Schalter, um ihn zu aktivieren.'
	String get tutorial_create_step6_text => 'Sammelst du Shinys? Tippe auf den Schalter, um ihn zu aktivieren.';

	/// de: 'Geschlechter'
	String get tutorial_create_step7_title => 'Geschlechter';

	/// de: 'Aktiviere auch die Geschlechter-Unterschiede durch einen Tipp auf den Schalter.'
	String get tutorial_create_step7_text => 'Aktiviere auch die Geschlechter-Unterschiede durch einen Tipp auf den Schalter.';

	/// de: 'In-Game Tausche'
	String get tutorial_create_step_trades_title => 'In-Game Tausche';

	/// de: 'Aktiviere diese Option, um besondere getauschte Pokémon mit vorgegebenen Werten und Spitznamen (z. B. Quaputzi 'Barabara') aufzunehmen.'
	String get tutorial_create_step_trades_text => 'Aktiviere diese Option, um besondere getauschte Pokémon mit vorgegebenen Werten und Spitznamen (z. B. Quaputzi \'Barabara\') aufzunehmen.';

	/// de: 'Geschenkte Pokémon'
	String get tutorial_create_step_gifts_title => 'Geschenkte Pokémon';

	/// de: 'Aktiviere diese Option, um geschenkte Pokémon (z. B. Evoli im Prismania-Gebäude oder Fossilien) in deinen Pokédex aufzunehmen.'
	String get tutorial_create_step_gifts_text => 'Aktiviere diese Option, um geschenkte Pokémon (z. B. Evoli im Prismania-Gebäude oder Fossilien) in deinen Pokédex aufzunehmen.';

	/// de: 'Glitch-Pokémon'
	String get tutorial_create_step7_glitch_title => 'Glitch-Pokémon';

	/// de: 'Aktiviere diese Option, um Glitch-Pokémon (wie die Gen 2 VC Game Boy Icon Starter) in deinen Pokédex aufzunehmen.'
	String get tutorial_create_step7_glitch_text => 'Aktiviere diese Option, um Glitch-Pokémon (wie die Gen 2 VC Game Boy Icon Starter) in deinen Pokédex aufzunehmen.';

	/// de: 'Spezielle Formen'
	String get tutorial_create_step8_title => 'Spezielle Formen';

	/// de: 'Tippe hier, um das Menü für spezielle Formen aufzuklappen.'
	String get tutorial_create_step8_text => 'Tippe hier, um das Menü für spezielle Formen aufzuklappen.';

	/// de: 'Regionalformen'
	String get tutorial_create_step9_title => 'Regionalformen';

	/// de: 'Tippe, um Regionalformen (Alola, Galar...) zu aktivieren.'
	String get tutorial_create_step9_text => 'Tippe, um Regionalformen (Alola, Galar...) zu aktivieren.';

	/// de: 'Mega-Entwicklungen'
	String get tutorial_create_step10_title => 'Mega-Entwicklungen';

	/// de: 'Tippe, um Mega-Entwicklungen zu aktivieren.'
	String get tutorial_create_step10_text => 'Tippe, um Mega-Entwicklungen zu aktivieren.';

	/// de: 'Gigadynamax'
	String get tutorial_create_step11_title => 'Gigadynamax';

	/// de: 'Tippe, um G-Max Formen zu aktivieren.'
	String get tutorial_create_step11_text => 'Tippe, um G-Max Formen zu aktivieren.';

	/// de: 'Sonstige Formen'
	String get tutorial_create_step12_title => 'Sonstige Formen';

	/// de: 'Tippe, um die restlichen Formen (Kostüme, Pokusan...) zu aktivieren.'
	String get tutorial_create_step12_text => 'Tippe, um die restlichen Formen (Kostüme, Pokusan...) zu aktivieren.';

	/// de: 'Los geht's!'
	String get tutorial_create_step13_title => 'Los geht\'s!';

	/// de: 'Perfekt, du hast alles ausgewählt! Tippe jetzt auf 'Erstellen'.'
	String get tutorial_create_step13_text => 'Perfekt, du hast alles ausgewählt! Tippe jetzt auf \'Erstellen\'.';

	/// de: 'Fehler beim Scrollen im Tutorial:'
	String get tutorial_error_scroll => 'Fehler beim Scrollen im Tutorial:';

	/// de: 'Fehler beim Berechnen des Tutorial-Rahmens:'
	String get tutorial_error_rect => 'Fehler beim Berechnen des Tutorial-Rahmens:';

	/// de: 'Fehler beim Wechseln des Tutorial-Schritts:'
	String get tutorial_error_next => 'Fehler beim Wechseln des Tutorial-Schritts:';

	/// de: 'Halt, falsche Richtung! Wir wollen zurück zum Nationaldex (nach rechts wischen)!'
	String get tutorial_wrong_swipe => 'Halt, falsche Richtung! Wir wollen zurück zum Nationaldex (nach rechts wischen)!';

	/// de: 'Na gut, wenn du nicht willst... dann mach ich das eben selbst! ZZZZZZT!'
	String get tutorial_rotom_angry => 'Na gut, wenn du nicht willst... dann mach ich das eben selbst! ZZZZZZT!';

	/// de: 'Dein erster Pokédex!'
	String get tutorial_open_dex_title => 'Dein erster Pokédex!';

	/// de: 'Klicke hier auf deinen neu erstellten Pokédex, um ihn zu öffnen!'
	String get tutorial_open_dex_text => 'Klicke hier auf deinen neu erstellten Pokédex, um ihn zu öffnen!';

	/// de: 'Das Herzstück!'
	String get tutorial_dex_intro_title => 'Das Herzstück!';

	/// de: 'Willkommen in der Hauptansicht! Hier siehst du alle Pokémon, die zu diesem Dex gehören.'
	String get tutorial_dex_intro_text => 'Willkommen in der Hauptansicht! Hier siehst du alle Pokémon, die zu diesem Dex gehören.';

	/// de: 'Pokémon fangen!'
	String get tutorial_dex_tap_title => 'Pokémon fangen!';

	/// de: 'Tippe einmal kurz auf ein Pokémon, um es als gefangen zu markieren.'
	String get tutorial_dex_tap_text => 'Tippe einmal kurz auf ein Pokémon, um es als gefangen zu markieren.';

	/// de: 'Menü & Sortierung'
	String get tutorial_dex_menu_title => 'Menü & Sortierung';

	/// de: 'Tippe hier oben rechts auf das Sortierzeichen, um die Ansicht anzupassen.'
	String get tutorial_dex_menu_text => 'Tippe hier oben rechts auf das Sortierzeichen, um die Ansicht anzupassen.';

	/// de: 'Nach Pokédex (Normal)'
	String get tutorial_dex_menu_forms_title => 'Nach Pokédex (Normal)';

	/// de: 'Tippe auf 'Nach Pokédex (Normal)'. Nun stehen alle regulären Pokémon der Region zuerst und die Sonderformen am Ende!'
	String get tutorial_dex_menu_forms_text => 'Tippe auf \'Nach Pokédex (Normal)\'. Nun stehen alle regulären Pokémon der Region zuerst und die Sonderformen am Ende!';

	/// de: 'PC-Box Ansicht'
	String get tutorial_dex_menu_box_title => 'PC-Box Ansicht';

	/// de: 'Tippe auf 'Zur PC-Box Ansicht', um die Pokémon wie im echten Spiel in praktische Boxen zu sortieren. Das war"s für hier!'
	String get tutorial_dex_menu_box_text => 'Tippe auf \'Zur PC-Box Ansicht\', um die Pokémon wie im echten Spiel in praktische Boxen zu sortieren. Das war"s für hier!';

	/// de: 'Die Suchfunktion!'
	String get tutorial_dex_search_title => 'Die Suchfunktion!';

	/// de: 'Hier kannst du nach Namen, IDs oder Typen suchen. Tippe auf die Suchleiste, Rotom tippt mal testweise 'Gengar' für dich ein!'
	String get tutorial_dex_search_text => 'Hier kannst du nach Namen, IDs oder Typen suchen. Tippe auf die Suchleiste, Rotom tippt mal testweise \'Gengar\' für dich ein!';

	/// de: 'Detailansicht öffnen'
	String get tutorial_longpress_title => 'Detailansicht öffnen';

	/// de: 'Da ist es! Halte ein Pokémon lange gedrückt (oder tippe einfach hier), um in seine Detailansicht zu wechseln.'
	String get tutorial_longpress_text => 'Da ist es! Halte ein Pokémon lange gedrückt (oder tippe einfach hier), um in seine Detailansicht zu wechseln.';

	/// de: 'Zusatzinformationen'
	String get tutorial_info_appbar_title => 'Zusatzinformationen';

	/// de: 'Hier oben siehst du immer, in welcher Box und an welcher Position du dich gerade befindest.'
	String get tutorial_info_appbar_text => 'Hier oben siehst du immer, in welcher Box und an welcher Position du dich gerade befindest.';

	/// de: 'Shiny Ansicht'
	String get tutorial_info_shiny_toggle_title => 'Shiny Ansicht';

	/// de: 'Tippe auf dieses Icon unten rechts am Bild, um dir das Pokémon in seiner schillernden Form (Shiny) anzusehen!'
	String get tutorial_info_shiny_toggle_text => 'Tippe auf dieses Icon unten rechts am Bild, um dir das Pokémon in seiner schillernden Form (Shiny) anzusehen!';

	/// de: 'Basis-Infos'
	String get tutorial_info_basic_title => 'Basis-Infos';

	/// de: 'Darunter findest du die grundlegenden Daten: ID, Name und die Typen des Pokémon.'
	String get tutorial_info_basic_text => 'Darunter findest du die grundlegenden Daten: ID, Name und die Typen des Pokémon.';

	/// de: 'Gefangen Status'
	String get tutorial_info_caught_title => 'Gefangen Status';

	/// de: 'Mit diesem Schalter kannst du jederzeit abhaken, ob du das Pokémon bereits besitzt.'
	String get tutorial_info_caught_text => 'Mit diesem Schalter kannst du jederzeit abhaken, ob du das Pokémon bereits besitzt.';

	/// de: 'Shiny Status'
	String get tutorial_info_shiny_title => 'Shiny Status';

	/// de: 'Und hier markierst du, ob du es sogar als Shiny gefangen hast!'
	String get tutorial_info_shiny_text => 'Und hier markierst du, ob du es sogar als Shiny gefangen hast!';

	/// de: 'Fangratenrechner'
	String get tutorial_info_catchcalc_title => 'Fangratenrechner';

	/// de: 'Ein extrem nützliches Tool! Berechne hier deine genaue Fangchance. Die Optionen passen sich je nach Generation dynamisch an.'
	String get tutorial_info_catchcalc_text => 'Ein extrem nützliches Tool! Berechne hier deine genaue Fangchance. Die Optionen passen sich je nach Generation dynamisch an.';

	/// de: 'Matching Balls'
	String get tutorial_info_matchingballs_title => 'Matching Balls';

	/// de: 'Hier siehst du, welche Pokébälle farblich am besten zum normalen und zum Shiny-Pokémon passen.'
	String get tutorial_info_matchingballs_text => 'Hier siehst du, welche Pokébälle farblich am besten zum normalen und zum Shiny-Pokémon passen.';

	/// de: 'Internationale Namen'
	String get tutorial_info_language_title => 'Internationale Namen';

	/// de: 'Hier siehst du, wie das Pokémon in allen unterstützten Sprachen heißt – ideal für den internationalen Tausch!'
	String get tutorial_info_language_text => 'Hier siehst du, wie das Pokémon in allen unterstützten Sprachen heißt – ideal für den internationalen Tausch!';

	/// de: 'Fundorte & Begegnungen'
	String get tutorial_info_encounters_title => 'Fundorte & Begegnungen';

	/// de: 'Zeigt dir für jede Edition genau an, wo und wie du das Pokémon im Spiel finden kannst.'
	String get tutorial_info_encounters_text => 'Zeigt dir für jede Edition genau an, wo und wie du das Pokémon im Spiel finden kannst.';

	/// de: 'Shiny Guide'
	String get tutorial_info_shinyguide_title => 'Shiny Guide';

	/// de: 'Spezielle Tipps und Mechaniken, um dieses Pokémon gezielt als Shiny zu jagen!'
	String get tutorial_info_shinyguide_text => 'Spezielle Tipps und Mechaniken, um dieses Pokémon gezielt als Shiny zu jagen!';

	/// de: 'Pokémon entfernen'
	String get tutorial_info_ignore_title => 'Pokémon entfernen';

	/// de: 'Sollte ein Pokémon mal nicht in deinen Dex gehören, kannst du es hier ausblenden. Probier es zum Abschluss einmal aus und drücke den Button!'
	String get tutorial_info_ignore_text => 'Sollte ein Pokémon mal nicht in deinen Dex gehören, kannst du es hier ausblenden. Probier es zum Abschluss einmal aus und drücke den Button!';

	/// de: 'Wirklich entfernen?'
	String get tutorial_info_ignore_confirm_title => 'Wirklich entfernen?';

	/// de: 'Klicke jetzt auf 'Aus Dex entfernen', um Gengar vorerst zu verstecken.'
	String get tutorial_info_ignore_confirm_text => 'Klicke jetzt auf \'Aus Dex entfernen\', um Gengar vorerst zu verstecken.';

	/// de: 'Versteckte Pokémon finden'
	String get tutorial_dex_menu_ignored_title => 'Versteckte Pokémon finden';

	/// de: 'Oh nein, Gengar ist weg! Aber keine Sorge. Öffne wieder das Menü hier oben.'
	String get tutorial_dex_menu_ignored_text => 'Oh nein, Gengar ist weg! Aber keine Sorge. Öffne wieder das Menü hier oben.';

	/// de: 'Ausgeblendete Pokémon'
	String get tutorial_dex_menu_ignored_btn_title => 'Ausgeblendete Pokémon';

	/// de: 'Tippe hier auf 'Ausgeblendete Pokémon', um deine versteckten Freunde zu sehen.'
	String get tutorial_dex_menu_ignored_btn_text => 'Tippe hier auf \'Ausgeblendete Pokémon\', um deine versteckten Freunde zu sehen.';

	/// de: 'Wiederherstellen'
	String get tutorial_ignored_restore_title => 'Wiederherstellen';

	/// de: 'Hier sind alle Pokémon, die du ausgeblendet hast. Klicke auf 'Wiederherstellen', um Gengar zurück in deinen Dex zu holen.'
	String get tutorial_ignored_restore_text => 'Hier sind alle Pokémon, die du ausgeblendet hast. Klicke auf \'Wiederherstellen\', um Gengar zurück in deinen Dex zu holen.';

	/// de: 'Na gut, wenn du nicht weißt wie man tippt... ich übernehme das! ZZZZZZT!'
	String get tutorial_dex_search_easteregg => 'Na gut, wenn du nicht weißt wie man tippt... ich übernehme das! ZZZZZZT!';

	/// de: 'Neuer Ordner'
	String get tutorial_folder_option_title => 'Neuer Ordner';

	/// de: 'Tippe hier, um einen neuen Ordner anzulegen und deine Dex-Sammlung übersichtlich zu organisieren!'
	String get tutorial_folder_option_text => 'Tippe hier, um einen neuen Ordner anzulegen und deine Dex-Sammlung übersichtlich zu organisieren!';

	/// de: 'Ordner benennen'
	String get tutorial_folder_dialog_title => 'Ordner benennen';

	/// de: 'Gib deinem Ordner einen Namen (z. B. 'Kanto' oder 'Shinies') und bestätige mit OK!'
	String get tutorial_folder_dialog_text => 'Gib deinem Ordner einen Namen (z. B. \'Kanto\' oder \'Shinies\') und bestätige mit OK!';

	/// de: 'Pokémon & Notiz'
	String get tutorial_hunt_pokemon_title => 'Pokémon & Notiz';

	/// de: 'Wähle das Ziel-Pokémon für deine Jagd. Optional kannst du dem Hunt einen individuellen Titel oder eine Notiz geben.'
	String get tutorial_hunt_pokemon_text => 'Wähle das Ziel-Pokémon für deine Jagd. Optional kannst du dem Hunt einen individuellen Titel oder eine Notiz geben.';

	/// de: 'Edition & Methode'
	String get tutorial_hunt_game_method_title => 'Edition & Methode';

	/// de: 'Wähle Spiel und Jagdmethode (z. B. Masuda, Schillerpin oder Zufallsbegegnung). Die Fangquoten berechnen sich automatisch!'
	String get tutorial_hunt_game_method_text => 'Wähle Spiel und Jagdmethode (z. B. Masuda, Schillerpin oder Zufallsbegegnung). Die Fangquoten berechnen sich automatisch!';

	/// de: 'Chancen & Schrittweite'
	String get tutorial_hunt_params_title => 'Chancen & Schrittweite';

	/// de: 'Hier siehst du die exakte Wahrscheinlichkeit (z. B. 1:4096). Passe Spawns pro Runde oder die Schrittweite für schnelle Zählung an!'
	String get tutorial_hunt_params_text => 'Hier siehst du die exakte Wahrscheinlichkeit (z. B. 1:4096). Passe Spawns pro Runde oder die Schrittweite für schnelle Zählung an!';

	/// de: 'Hunt starten'
	String get tutorial_hunt_save_title => 'Hunt starten';

	/// de: 'Speichere deinen Hunt, um direkt zum Live-Zähler mit Phasen, Timer und Stoppuhr zu gelangen!'
	String get tutorial_hunt_save_text => 'Speichere deinen Hunt, um direkt zum Live-Zähler mit Phasen, Timer und Stoppuhr zu gelangen!';

	/// de: 'Dex-Statistiken'
	String get tutorial_appbar_stats_title => 'Dex-Statistiken';

	/// de: 'Hier findest du deinen Fangfortschritt im Detail – aufgeschlüsselt nach Generationen, Typen und Formen!'
	String get tutorial_appbar_stats_text => 'Hier findest du deinen Fangfortschritt im Detail – aufgeschlüsselt nach Generationen, Typen und Formen!';

	/// de: 'Erfolgs-Grafik teilen'
	String get tutorial_appbar_share_title => 'Erfolgs-Grafik teilen';

	/// de: 'Erstelle eine schicke Trainerkarte mit deinem Fortschritt und teile sie mit Freunden oder in Social Media!'
	String get tutorial_appbar_share_text => 'Erstelle eine schicke Trainerkarte mit deinem Fortschritt und teile sie mit Freunden oder in Social Media!';

	/// de: 'Boxen verwalten'
	String get tutorial_appbar_box_edit_title => 'Boxen verwalten';

	/// de: 'Passe Namen, Farben und Layout deiner Boxen an, erstelle neue Boxen oder nutze den Auto-Shift für lückenlose Ordnung!'
	String get tutorial_appbar_box_edit_text => 'Passe Namen, Farben und Layout deiner Boxen an, erstelle neue Boxen oder nutze den Auto-Shift für lückenlose Ordnung!';

	/// de: 'Box-Inhalte bearbeiten'
	String get tutorial_appbar_box_content_title => 'Box-Inhalte bearbeiten';

	/// de: 'Verschiebe Pokémon per Drag & Drop zwischen Boxen, wähle mehrere Pokémon gleichzeitig aus oder füge neue Pokémon hinzu!'
	String get tutorial_appbar_box_content_text => 'Verschiebe Pokémon per Drag & Drop zwischen Boxen, wähle mehrere Pokémon gleichzeitig aus oder füge neue Pokémon hinzu!';

	/// de: 'Routen- & Fundort-Tracker'
	String get tutorial_appbar_route_title => 'Routen- & Fundort-Tracker';

	/// de: 'Sieh nach, welche Pokémon dir auf welcher Spielroute noch fehlen und behalte die Gebiets-Erkundung im Blick!'
	String get tutorial_appbar_route_text => 'Sieh nach, welche Pokémon dir auf welcher Spielroute noch fehlen und behalte die Gebiets-Erkundung im Blick!';

	/// de: 'Shiny Hunt Tracker'
	String get tutorial_appbar_shiny_title => 'Shiny Hunt Tracker';

	/// de: 'Tippe hier, um zu deinen aktiven Shiny Hunts zu wechseln oder neue Jagden zu starten!'
	String get tutorial_appbar_shiny_text => 'Tippe hier, um zu deinen aktiven Shiny Hunts zu wechseln oder neue Jagden zu starten!';

	/// de: 'Boxen anpassen'
	String get tutorial_box_edit_intro_title => 'Boxen anpassen';

	/// de: 'Hier kannst du deine PC-Boxen frei anordnen, umbenennen, Farben zuweisen und das Raster für jede Box individuell anpassen!'
	String get tutorial_box_edit_intro_text => 'Hier kannst du deine PC-Boxen frei anordnen, umbenennen, Farben zuweisen und das Raster für jede Box individuell anpassen!';

	/// de: 'Box-Inhalt bearbeiten'
	String get tutorial_box_content_intro_title => 'Box-Inhalt bearbeiten';

	/// de: 'Tippe auf einen leeren Slot, um ein Pokémon oder einen Platzhalter einzufügen. Bestehende Pokémon kannst du frei verschieben!'
	String get tutorial_box_content_intro_text => 'Tippe auf einen leeren Slot, um ein Pokémon oder einen Platzhalter einzufügen. Bestehende Pokémon kannst du frei verschieben!';

	/// de: 'Pokémon auswählen'
	String get tutorial_search_select_intro_title => 'Pokémon auswählen';

	/// de: 'Nutze Filter für Region, Form, Geschlecht und Shiny-Status oder suche direkt nach Name oder Dex-Nummer!'
	String get tutorial_search_select_intro_text => 'Nutze Filter für Region, Form, Geschlecht und Shiny-Status oder suche direkt nach Name oder Dex-Nummer!';

	/// de: 'Das war ein normaler Klick! Halte das Pokémon LANGE gedrückt!'
	String get tutorial_longpress_error => 'Das war ein normaler Klick! Halte das Pokémon LANGE gedrückt!';

	/// de: 'Fehler beim Laden des Avatars:'
	String get error_avatar_load => 'Fehler beim Laden des Avatars:';

	/// de: 'Fehler beim Laden des Headers:'
	String get error_header_load => 'Fehler beim Laden des Headers:';

	/// de: 'Fehler beim Laden der Basis-Infos:'
	String get error_basic_info => 'Fehler beim Laden der Basis-Infos:';

	/// de: 'Fehler beim Laden der Status-Buttons:'
	String get error_status_toggles => 'Fehler beim Laden der Status-Buttons:';

	/// de: 'Fehler beim Laden der Matching Balls:'
	String get error_matching_balls => 'Fehler beim Laden der Matching Balls:';

	/// de: 'Fehler beim Laden der Fundorte:'
	String get error_encounters => 'Fehler beim Laden der Fundorte:';

	/// de: 'Fehler im Ergebnis-Widget:'
	String get error_calc_ui_result => 'Fehler im Ergebnis-Widget:';

	/// de: 'Fehler im HP/Status-Widget:'
	String get error_calc_ui_hp => 'Fehler im HP/Status-Widget:';

	/// de: 'Fehler im Crit-Widget:'
	String get error_calc_ui_crit => 'Fehler im Crit-Widget:';

	/// de: 'Pokédex erstellen'
	String get create_dex_btn => 'Pokédex erstellen';

	/// de: 'Datenbank konnte nicht initialisiert werden:'
	String get error_db_init => 'Datenbank konnte nicht initialisiert werden:';

	/// de: 'Benutzertabellen konnten nicht erstellt werden:'
	String get error_db_create => 'Benutzertabellen konnten nicht erstellt werden:';

	/// de: 'Fehler beim Speichern deiner Daten:'
	String get error_db_write => 'Fehler beim Speichern deiner Daten:';

	/// de: 'Daten werden für die neuste Version optimiert... Bitte App nicht schließen.'
	String get migration_loading_text => 'Daten werden für die neuste Version optimiert...\nBitte App nicht schließen.';

	/// de: 'Fehler beim Laden der Seite:'
	String get error_page_load => 'Fehler beim Laden der Seite:';

	/// de: 'Spezial Dexe'
	String get group_special => 'Spezial Dexe';

	/// de: 'Achtung: Im Web-Browser können deine Daten gelöscht werden, wenn der Browser-Cache geleert wird. Bitte erstelle regelmäßig Backups!'
	String get web_backup_warning_text => 'Achtung: Im Web-Browser können deine Daten gelöscht werden, wenn der Browser-Cache geleert wird. Bitte erstelle regelmäßig Backups!';

	/// de: 'Verstanden'
	String get web_backup_warning_action => 'Verstanden';

	/// de: 'Cloud-Synchronisation'
	String get cloud_sync => 'Cloud-Synchronisation';

	/// de: 'Google OAuth Client-ID'
	String get google_client_id => 'Google OAuth Client-ID';

	/// de: 'Erstelle eine Client-ID in der Google Cloud Console, um Drive zu nutzen.'
	String get google_client_id_help => 'Erstelle eine Client-ID in der Google Cloud Console, um Drive zu nutzen.';

	/// de: 'Automatische Synchronisation'
	String get auto_sync => 'Automatische Synchronisation';

	/// de: 'Synchronisiert im Hintergrund beim Schließen der App'
	String get auto_sync_desc => 'Synchronisiert im Hintergrund beim Schließen der App';

	/// de: 'Drive Login'
	String get login_drive => 'Drive Login';

	/// de: 'Drive Logout'
	String get logout_drive => 'Drive Logout';

	/// de: 'Jetzt synchronisieren'
	String get sync_now => 'Jetzt synchronisieren';

	/// de: 'Erfolgreich mit Google Drive synchronisiert!'
	String get sync_success => 'Erfolgreich mit Google Drive synchronisiert!';

	/// de: 'Cloud-Speicher einrichten'
	String get tutorial_sync_title => 'Cloud-Speicher einrichten';

	/// de: 'Trage hier deine eigene Google Client-ID ein, um deine Dexe sicher und kostenlos in deinem versteckten Google Drive App-Ordner zu speichern.'
	String get tutorial_sync_text => 'Trage hier deine eigene Google Client-ID ein, um deine Dexe sicher und kostenlos in deinem versteckten Google Drive App-Ordner zu speichern.';

	/// de: 'Google Client-Secret'
	String get google_client_secret => 'Google Client-Secret';

	/// de: 'Eigene Cloud einrichten'
	String get cloud_tut_title => 'Eigene Cloud einrichten';

	/// de: 'Da PokeVault völlig kostenlos ist, nutzt du einfach deinen eigenen (kostenlosen) Google-Schlüssel. Deine Daten landen sicher und unsichtbar in deinem eigenen Google Drive.'
	String get cloud_tut_intro => 'Da PokeVault völlig kostenlos ist, nutzt du einfach deinen eigenen (kostenlosen) Google-Schlüssel. Deine Daten landen sicher und unsichtbar in deinem eigenen Google Drive.';

	/// de: 'Gehe in die Google Cloud Console und erstelle ein 'Neues Projekt' (du kannst es z.B. 'PokeVault' nennen).'
	String get cloud_tut_step1 => 'Gehe in die Google Cloud Console und erstelle ein \'Neues Projekt\' (du kannst es z.B. \'PokeVault\' nennen).';

	/// de: 'Suche in der Leiste oben nach 'Google Drive API' und klicke auf 'Aktivieren'. Suche danach nach der 'Google People API' und aktiviere diese ebenfalls.'
	String get cloud_tut_step2 => 'Suche in der Leiste oben nach \'Google Drive API\' und klicke auf \'Aktivieren\'. Suche danach nach der \'Google People API\' und aktiviere diese ebenfalls.';

	/// de: 'Gehe links auf 'OAuth-Zustimmungsbildschirm' -> 'Zielgruppe'. Klicke unter 'Testnutzer' auf 'Add users' und trage die E-Mail-Adresse deines Google Drive-Kontos ein.'
	String get cloud_tut_step3 => 'Gehe links auf \'OAuth-Zustimmungsbildschirm\' -> \'Zielgruppe\'. Klicke unter \'Testnutzer\' auf \'Add users\' und trage die E-Mail-Adresse deines Google Drive-Kontos ein.';

	/// de: 'Gehe zurück zur Google Drive API-Übersicht, wähle links 'Anmeldedaten' und klicke oben auf '+ Anmeldedaten erstellen'.'
	String get cloud_tut_step4 => 'Gehe zurück zur Google Drive API-Übersicht, wähle links \'Anmeldedaten\' und klicke oben auf \'+ Anmeldedaten erstellen\'.';

	/// de: 'Wähle 'OAuth-Client-ID' und als Anwendungstyp zwingend 'Desktopanwendung' (bzw. Desktop-App). Als Name kannst du z.B. deinen Gerätenamen eintragen. Klicke auf 'Erstellen'.'
	String get cloud_tut_step5 => 'Wähle \'OAuth-Client-ID\' und als Anwendungstyp zwingend \'Desktopanwendung\' (bzw. Desktop-App). Als Name kannst du z.B. deinen Gerätenamen eintragen. Klicke auf \'Erstellen\'.';

	/// de: 'Wähle 'OAuth-Client-ID' und als Anwendungstyp zwingend 'Webanwendung'. Trage unter 'Autorisierte JavaScript-Quellen' die genaue URL dieser Seite ein. Klicke auf 'Erstellen'.'
	String get cloud_tut_step5_web => 'Wähle \'OAuth-Client-ID\' und als Anwendungstyp zwingend \'Webanwendung\'. Trage unter \'Autorisierte JavaScript-Quellen\' die genaue URL dieser Seite ein. Klicke auf \'Erstellen\'.';

	/// de: 'Kopiere die angezeigte 'Client-ID' und den 'Clientschlüssel' (Client-Secret) und füge sie hier in der App ein (oder lade die JSON-Datei herunter, um sie daraus zu kopieren).'
	String get cloud_tut_step6 => 'Kopiere die angezeigte \'Client-ID\' und den \'Clientschlüssel\' (Client-Secret) und füge sie hier in der App ein (oder lade die JSON-Datei herunter, um sie daraus zu kopieren).';

	/// de: 'Kopiere die angezeigte 'Client-ID' und füge sie hier in der App ein. Ein Client-Secret wird für die Web-Version nicht benötigt!'
	String get cloud_tut_step6_web => 'Kopiere die angezeigte \'Client-ID\' und füge sie hier in der App ein. Ein Client-Secret wird für die Web-Version nicht benötigt!';

	/// de: 'Tippe hier in der App auf 'Drive Login'.'
	String get cloud_tut_step7 => 'Tippe hier in der App auf \'Drive Login\'.';

	/// de: 'Wähle im Browserfenster exakt die E-Mail-Adresse aus, die du vorher als Testnutzer eingetragen hast.'
	String get cloud_tut_step8 => 'Wähle im Browserfenster exakt die E-Mail-Adresse aus, die du vorher als Testnutzer eingetragen hast.';

	/// de: 'Bestätige die Zugriffsanfrage, indem du zweimal auf 'Weiter' klickst.'
	String get cloud_tut_step9 => 'Bestätige die Zugriffsanfrage, indem du zweimal auf \'Weiter\' klickst.';

	/// de: 'Der Login sollte nun erfolgreich sein! Du kannst das Browserfenster schließen und zur App zurückkehren.'
	String get cloud_tut_step10 => 'Der Login sollte nun erfolgreich sein! Du kannst das Browserfenster schließen und zur App zurückkehren.';

	/// de: 'Schließen'
	String get close => 'Schließen';

	/// de: 'Ordnung muss sein!'
	String get tutorial_organize_intro_title => 'Ordnung muss sein!';

	/// de: 'Da du jetzt deinen ersten Dex hast, zeige ich dir kurz, wie du alles übersichtlich organisieren kannst.'
	String get tutorial_organize_intro_text => 'Da du jetzt deinen ersten Dex hast, zeige ich dir kurz, wie du alles übersichtlich organisieren kannst.';

	/// de: 'Ordner erstellen'
	String get tutorial_organize_folder_title => 'Ordner erstellen';

	/// de: 'Über dieses Plus-Symbol kannst du neben Dexen auch Ordner anlegen, um deine Sammlung zu gruppieren.'
	String get tutorial_organize_folder_text => 'Über dieses Plus-Symbol kannst du neben Dexen auch Ordner anlegen, um deine Sammlung zu gruppieren.';

	/// de: 'Drag & Drop'
	String get tutorial_organize_drag_title => 'Drag & Drop';

	/// de: 'Tipp: Wenn du oben rechts auf "Manuell" sortierst, kannst du Dexe und Ordner jederzeit an den rechten Griffen anfassen und verschieben.'
	String get tutorial_organize_drag_text => 'Tipp: Wenn du oben rechts auf "Manuell" sortierst, kannst du Dexe und Ordner jederzeit an den rechten Griffen anfassen und verschieben.';

	/// de: 'Auswahlmodus (Long-Press)'
	String get tutorial_organize_longpress_title => 'Auswahlmodus (Long-Press)';

	/// de: 'Halte deinen Dex jetzt LANGE gedrückt (ca. halbe Sekunde), um den Auswahlmodus zu starten!'
	String get tutorial_organize_longpress_text => 'Halte deinen Dex jetzt LANGE gedrückt (ca. halbe Sekunde), um den Auswahlmodus zu starten!';

	/// de: 'Elemente verschieben'
	String get tutorial_organize_move_title => 'Elemente verschieben';

	/// de: 'Perfekt! Jetzt kannst du ihn verschieben, exportieren oder löschen. Klicke auf das Ordner-Symbol, um ihn zu verschieben!'
	String get tutorial_organize_move_text => 'Perfekt! Jetzt kannst du ihn verschieben, exportieren oder löschen. Klicke auf das Ordner-Symbol, um ihn zu verschieben!';

	/// de: 'Lass uns aufräumen!'
	String get tutorial_org1_intro_title => 'Lass uns aufräumen!';

	/// de: 'Ordnung ist das halbe Leben. Ich zeige dir kurz die wichtigsten Funktionen auf dem Homescreen.'
	String get tutorial_org1_intro_text => 'Ordnung ist das halbe Leben. Ich zeige dir kurz die wichtigsten Funktionen auf dem Homescreen.';

	/// de: 'Sortieren & Manuell'
	String get tutorial_org1_sort_title => 'Sortieren & Manuell';

	/// de: 'Hier kannst du filtern und sortieren. Wählst du 'Manuell', kannst du Dexe und Ordner am rechten Rand anfassen und frei verschieben!'
	String get tutorial_org1_sort_text => 'Hier kannst du filtern und sortieren. Wählst du \'Manuell\', kannst du Dexe und Ordner am rechten Rand anfassen und frei verschieben!';

	/// de: 'Schnelle Aktionen (3 Punkte)'
	String get tutorial_org1_options_title => 'Schnelle Aktionen (3 Punkte)';

	/// de: 'Über die 3 Punkte auf einer Dex-Karte kommst du sofort an wichtige Aktionen wie Umbenennen oder Löschen heran.'
	String get tutorial_org1_options_text => 'Über die 3 Punkte auf einer Dex-Karte kommst du sofort an wichtige Aktionen wie Umbenennen oder Löschen heran.';

	/// de: 'Ordner erstellen'
	String get tutorial_org1_folder_title => 'Ordner erstellen';

	/// de: 'Klicke jetzt auf das Plus und erstelle im Menü einen neuen Ordner als praktisches Beispiel!'
	String get tutorial_org1_folder_text => 'Klicke jetzt auf das Plus und erstelle im Menü einen neuen Ordner als praktisches Beispiel!';

	/// de: 'Auswahlmodus'
	String get tutorial_org2_longpress_title => 'Auswahlmodus';

	/// de: 'Da ist der Ordner! Halte nun deinen ersten Dex LANGE gedrückt (ca. halbe Sekunde), um ihn auszuwählen.'
	String get tutorial_org2_longpress_text => 'Da ist der Ordner! Halte nun deinen ersten Dex LANGE gedrückt (ca. halbe Sekunde), um ihn auszuwählen.';

	/// de: 'Elemente verschieben'
	String get tutorial_org2_move_title => 'Elemente verschieben';

	/// de: 'Klicke nun auf das Verschieben-Icon, wähle deinen neuen Ordner aus und bestätige. Damit bist du ein Profi!'
	String get tutorial_org2_move_text => 'Klicke nun auf das Verschieben-Icon, wähle deinen neuen Ordner aus und bestätige. Damit bist du ein Profi!';

	/// de: 'Fast geschafft!'
	String get tutorial_home_settings_title => 'Fast geschafft!';

	/// de: 'Zum Abschluss zeige ich dir noch die Einstellungen. Klicke auf das Zahnrad oben rechts!'
	String get tutorial_home_settings_text => 'Zum Abschluss zeige ich dir noch die Einstellungen. Klicke auf das Zahnrad oben rechts!';

	/// de: 'Erscheinungsbild'
	String get tutorial_settings_appearance_title => 'Erscheinungsbild';

	/// de: 'Hier kannst du den Dark Mode aktivieren und die Farben der App ganz nach deinem Geschmack anpassen.'
	String get tutorial_settings_appearance_text => 'Hier kannst du den Dark Mode aktivieren und die Farben der App ganz nach deinem Geschmack anpassen.';

	/// de: 'Updates & Versionen'
	String get tutorial_settings_updates_title => 'Updates & Versionen';

	/// de: 'Prüfe hier auf neue Updates oder wechsle zu einer älteren Version zurück, falls mal etwas nicht klappt.'
	String get tutorial_settings_updates_text => 'Prüfe hier auf neue Updates oder wechsle zu einer älteren Version zurück, falls mal etwas nicht klappt.';

	/// de: 'Allgemein'
	String get tutorial_settings_general_title => 'Allgemein';

	/// de: 'Ändere die Sprache oder starte das gesamte Tutorial neu, falls du dir alles noch einmal ansehen möchtest.'
	String get tutorial_settings_general_text => 'Ändere die Sprache oder starte das gesamte Tutorial neu, falls du dir alles noch einmal ansehen möchtest.';

	/// de: 'Datenverwaltung'
	String get tutorial_settings_data_title => 'Datenverwaltung';

	/// de: 'Erstelle manuelle Backups deiner Dexe (Exportieren) oder lade alte Backups wieder in die App (Importieren).'
	String get tutorial_settings_data_text => 'Erstelle manuelle Backups deiner Dexe (Exportieren) oder lade alte Backups wieder in die App (Importieren).';

	/// de: 'Cloud-Synchronisation'
	String get tutorial_settings_cloud_title => 'Cloud-Synchronisation';

	/// de: 'Verbinde dein Google Drive, um deine Daten sicher in der Cloud zu speichern und zwischen deinen Geräten zu synchronisieren!'
	String get tutorial_settings_cloud_text => 'Verbinde dein Google Drive, um deine Daten sicher in der Cloud zu speichern und zwischen deinen Geräten zu synchronisieren!';

	/// de: 'Community & Support'
	String get tutorial_settings_community_title => 'Community & Support';

	/// de: 'Du hast einen Bug gefunden oder möchtest bei der Entwicklung helfen? Hier findest du alle Links!'
	String get tutorial_settings_community_text => 'Du hast einen Bug gefunden oder möchtest bei der Entwicklung helfen? Hier findest du alle Links!';

	/// de: 'Danksagungen & Quellen'
	String get tutorial_settings_credits_title => 'Danksagungen & Quellen';

	/// de: 'PokeVault wäre ohne diese tollen Projekte nicht möglich. Schau sie dir gerne an! Das war's – viel Spaß mit der App!'
	String get tutorial_settings_credits_text => 'PokeVault wäre ohne diese tollen Projekte nicht möglich. Schau sie dir gerne an! Das war\'s – viel Spaß mit der App!';

	/// de: 'Shiny Huntable: Ja (Basis-Chance 1:8192)'
	String get shiny_gen3_huntable_yes => 'Shiny Huntable: Ja (Basis-Chance 1:8192)';

	/// de: 'Rubin & Saphir: Der Seed ist zufällig, Standard Soft Resets (SR) funktionieren problemlos. AUSNAHME: Ist die interne Batterie leer oder der Spielstand hat 999:59h erreicht, friert der Seed bei 0 ein (wie in Smaragd).'
	String get shiny_gen3_rs_note => 'Rubin & Saphir: Der Seed ist zufällig, Standard Soft Resets (SR) funktionieren problemlos. AUSNAHME: Ist die interne Batterie leer oder der Spielstand hat 999:59h erreicht, friert der Seed bei 0 ein (wie in Smaragd).';

	/// de: 'Smaragd: RNG Fehler! Der Start-Seed ist bei jedem Reset immer 0. Klassische Soft Resets bringen nichts, da immer die exakt gleichen Pokémon-Werte generiert werden. Nutze hier die "Runaway"-Methode (Flucht & Neu-Encounter) oder RNG Manipulation.'
	String get shiny_gen3_emerald_note => 'Smaragd: RNG Fehler! Der Start-Seed ist bei jedem Reset immer 0. Klassische Soft Resets bringen nichts, da immer die exakt gleichen Pokémon-Werte generiert werden. Nutze hier die "Runaway"-Methode (Flucht & Neu-Encounter) oder RNG Manipulation.';

	/// de: 'Feuerrot & Blattgrün: Kein RNG Bug. Der Seed generiert sich bei jedem Spielstart neu. Soft Resets sind völlig bedenkenlos möglich.'
	String get shiny_gen3_frbg_note => 'Feuerrot & Blattgrün: Kein RNG Bug. Der Seed generiert sich bei jedem Spielstart neu. Soft Resets sind völlig bedenkenlos möglich.';

	/// de: 'RNG Manipulation Guides & Ressourcen'
	String get shiny_gen3_links_title => 'RNG Manipulation Guides & Ressourcen';

	/// de: 'im a blisy - YouTube Kanal (EN)'
	String get shiny_gen3_link_blisy_channel => 'im a blisy - YouTube Kanal (EN)';

	/// de: 'im a blisy - R/S/E RNG Playlist (EN)'
	String get shiny_gen3_link_blisy_playlist => 'im a blisy - R/S/E RNG Playlist (EN)';

	/// de: 'im a blisy - R/S Stationäre RNG (Video) (EN)'
	String get shiny_gen3_link_blisy_rs_video => 'im a blisy - R/S Stationäre RNG (Video) (EN)';

	/// de: 'Smogon - R/S Non-Bred RNG Guide (EN)'
	String get shiny_gen3_link_smogon => 'Smogon - R/S Non-Bred RNG Guide (EN)';

	/// de: 'Retail RNG - Smaragd Guide (EN)'
	String get shiny_gen3_link_retail_rng => 'Retail RNG - Smaragd Guide (EN)';

	/// de: 'Reddit - RNG Manipulation in Emerald (EN)'
	String get shiny_gen3_link_reddit_emerald => 'Reddit - RNG Manipulation in Emerald (EN)';

	/// de: 'Shiny Huntable: Ja (DV-basiert, Chance 1:8192)'
	String get shiny_gen1_huntable_yes => 'Shiny Huntable: Ja (DV-basiert, Chance 1:8192)';

	/// de: 'Shiny Huntable: Ja (Basis-Chance 1:8192)'
	String get shiny_gen2_huntable_yes => 'Shiny Huntable: Ja (Basis-Chance 1:8192)';

	/// de: 'Shiny Huntable: Ja (Basis-Chance 1:8192)'
	String get shiny_gen4_huntable_yes => 'Shiny Huntable: Ja (Basis-Chance 1:8192)';

	/// de: 'Masuda-Methode (Chance: 1:1638)'
	String get shiny_gen4_masuda_title => 'Masuda-Methode (Chance: 1:1638)';

	/// de: 'Züchte zwei Pokémon aus unterschiedlichen Sprachregionen miteinander (z.B. ein deutsches Feurigel und ein japanisches Ditto), um die Shiny-Chance auf 1:1638 (5/8192) zu vervielfachen.'
	String get shiny_gen4_masuda_desc => 'Züchte zwei Pokémon aus unterschiedlichen Sprachregionen miteinander (z.B. ein deutsches Feurigel und ein japanisches Ditto), um die Shiny-Chance auf 1:1638 (5/8192) zu vervielfachen.';

	/// de: 'Bulbapedia - Masuda Method (EN)'
	String get shiny_gen4_masuda_link => 'Bulbapedia - Masuda Method (EN)';

	/// de: 'Poké-Radar (Chance: bis 1:200)'
	String get shiny_gen4_radar_title => 'Poké-Radar (Chance: bis 1:200)';

	/// de: 'Exklusiv in D/P/Pt für Begegnungen im hohen Gras. Erreichst du eine Kette von 40 des gleichen Pokémon, steigt die Chance auf 1:200 pro wackelndem Feld. Manche Felder glitzern vorher sogar!'
	String get shiny_gen4_radar_desc => 'Exklusiv in D/P/Pt für Begegnungen im hohen Gras. Erreichst du eine Kette von 40 des gleichen Pokémon, steigt die Chance auf 1:200 pro wackelndem Feld. Manche Felder glitzern vorher sogar!';

	/// de: 'Reddit - Gen 4 Radar Guide (EN)'
	String get shiny_gen4_radar_link_en_reddit => 'Reddit - Gen 4 Radar Guide (EN)';

	/// de: 'YouTube - Radar Tutorial (EN)'
	String get shiny_gen4_radar_link_en_yt => 'YouTube - Radar Tutorial (EN)';

	/// de: 'Bisafans - Poké-Radar Guide (DE)'
	String get shiny_gen4_radar_link_de_bisa => 'Bisafans - Poké-Radar Guide (DE)';

	/// de: 'YouTube - Radar Tutorial (DE)'
	String get shiny_gen4_radar_link_de_yt => 'YouTube - Radar Tutorial (DE)';

	/// de: 'HGSS Starter Resets (Effektiv 3:8192)'
	String get shiny_gen4_hgss_starter_title => 'HGSS Starter Resets (Effektiv 3:8192)';

	/// de: 'Extrem schnell! Du siehst bereits bei der Auswahl im Koffer bei Prof. Lind, ob Endivie, Feurigel oder Karnimani Shiny sind. Bei jedem Soft-Reset checkst du also direkt 3 Pokémon gleichzeitig.'
	String get shiny_gen4_hgss_starter_desc => 'Extrem schnell! Du siehst bereits bei der Auswahl im Koffer bei Prof. Lind, ob Endivie, Feurigel oder Karnimani Shiny sind. Bei jedem Soft-Reset checkst du also direkt 3 Pokémon gleichzeitig.';

	/// de: 'Guide: HGSS Starters Hunten'
	String get shiny_gen4_hgss_starter_link => 'Guide: HGSS Starters Hunten';

	/// de: 'Cute Charm Glitch (~21% Shiny Chance!)'
	String get shiny_gen4_ccg_title => 'Cute Charm Glitch (~21% Shiny Chance!)';

	/// de: 'Fehler im Code: Besitzt dein Spiel eine bestimmte Kombination aus Trainer-ID und Secret-ID, zwingt ein Pokémon mit der Fähigkeit Charmebolzen an erster Stelle das Spiel dazu, unfassbar oft ein Shiny des anderen Geschlechts auftauchen zu lassen.'
	String get shiny_gen4_ccg_desc => 'Fehler im Code: Besitzt dein Spiel eine bestimmte Kombination aus Trainer-ID und Secret-ID, zwingt ein Pokémon mit der Fähigkeit Charmebolzen an erster Stelle das Spiel dazu, unfassbar oft ein Shiny des anderen Geschlechts auftauchen zu lassen.';

	/// de: 'YouTube - CCG für D/P/Pt (EN)'
	String get shiny_gen4_ccg_link_dppt => 'YouTube - CCG für D/P/Pt (EN)';

	/// de: 'YouTube - CCG für HGSS (EN)'
	String get shiny_gen4_ccg_link_hgss => 'YouTube - CCG für HGSS (EN)';

	/// de: 'Wander-Pokémon (Roamer) in Gen 4'
	String get shiny_gen4_roamer_title => 'Wander-Pokémon (Roamer) in Gen 4';

	/// de: 'Die Werte und der Shiny-Status werden festgelegt, sobald das Pokémon in die Wildnis entlassen wird! Du musst VOR diesem Gespräch / Event speichern und bei Misserfolg komplett resetten.'
	String get shiny_gen4_roamer_desc => 'Die Werte und der Shiny-Status werden festgelegt, sobald das Pokémon in die Wildnis entlassen wird! Du musst VOR diesem Gespräch / Event speichern und bei Misserfolg komplett resetten.';

	/// de: 'Soft Resets (Chance: 1:8192)'
	String get shiny_gen4_sr_title => 'Soft Resets (Chance: 1:8192)';

	/// de: 'Für stationäre Begegnungen, Legendäre Pokémon oder Geschenke. Speichere direkt vor dem Event und starte das Spiel neu, bis es Shiny ist.'
	String get shiny_gen4_sr_desc => 'Für stationäre Begegnungen, Legendäre Pokémon oder Geschenke. Speichere direkt vor dem Event und starte das Spiel neu, bis es Shiny ist.';

	/// de: 'Shiny Huntable: Ja (Basis-Chance 1:8192)'
	String get shiny_gen5_huntable_yes => 'Shiny Huntable: Ja (Basis-Chance 1:8192)';

	/// de: 'Shiny Locked!'
	String get shiny_gen5_locked_title => 'Shiny Locked!';

	/// de: 'Achtung: Dieses Pokémon kann in Generation 5 NICHT als Shiny erhalten werden (vom Spiel gesperrt).'
	String get shiny_gen5_locked_desc => 'Achtung: Dieses Pokémon kann in Generation 5 NICHT als Shiny erhalten werden (vom Spiel gesperrt).';

	/// de: 'Schillerpin (Nur S2/W2)'
	String get shiny_gen5_charm_title => 'Schillerpin (Nur S2/W2)';

	/// de: 'Der Schillerpin wurde in Schwarz 2 / Weiß 2 eingeführt. Er erhöht die wilde Shiny-Chance auf ca. 1:2731 (3/8192).'
	String get shiny_gen5_charm_desc => 'Der Schillerpin wurde in Schwarz 2 / Weiß 2 eingeführt. Er erhöht die wilde Shiny-Chance auf ca. 1:2731 (3/8192).';

	/// de: 'Masuda-Methode (Bis zu 1:1024)'
	String get shiny_gen5_masuda_title => 'Masuda-Methode (Bis zu 1:1024)';

	/// de: 'Züchte zwei Pokémon aus unterschiedlichen Sprachregionen. Chance in Gen 5: 1:1365 (Ohne Pin) / 1:1024 (Mit Schillerpin in S2/W2).'
	String get shiny_gen5_masuda_desc => 'Züchte zwei Pokémon aus unterschiedlichen Sprachregionen. Chance in Gen 5: 1:1365 (Ohne Pin) / 1:1024 (Mit Schillerpin in S2/W2).';

	/// de: 'Dunkles Gras (Doppelkämpfe)'
	String get shiny_gen5_darkgrass_title => 'Dunkles Gras (Doppelkämpfe)';

	/// de: 'Im dunklen Gras triffst du oft auf zwei Pokémon gleichzeitig. Das ändert zwar nicht die Basis-Chance, halbiert aber die Zeit pro Begegnung massiv!'
	String get shiny_gen5_darkgrass_desc => 'Im dunklen Gras triffst du oft auf zwei Pokémon gleichzeitig. Das ändert zwar nicht die Basis-Chance, halbiert aber die Zeit pro Begegnung massiv!';

	/// de: 'Soft Resets (Chance: 1:8192)'
	String get shiny_gen5_sr_title => 'Soft Resets (Chance: 1:8192)';

	/// de: 'Für Legendäre (außer den gesperrten) und statische Begegnungen. Die Shiny-Chance lässt sich in S2/W2 durch den Schillerpin auf 1:2731 verbessern.'
	String get shiny_gen5_sr_desc => 'Für Legendäre (außer den gesperrten) und statische Begegnungen. Die Shiny-Chance lässt sich in S2/W2 durch den Schillerpin auf 1:2731 verbessern.';

	/// de: 'RNG Manipulation (Gen 5)'
	String get shiny_gen5_rng_title => 'RNG Manipulation (Gen 5)';

	/// de: 'Gen 5 ist eine der anfängerfreundlichsten Generationen für RNG, da oft nur das exakte Datum und die Sekunde im DS-Menü getroffen werden muss.'
	String get shiny_gen5_rng_desc => 'Gen 5 ist eine der anfängerfreundlichsten Generationen für RNG, da oft nur das exakte Datum und die Sekunde im DS-Menü getroffen werden muss.';

	/// de: 'im a blisy - Gen 5 RNG (YouTube) (EN)'
	String get shiny_gen5_rng_link_blisy => 'im a blisy - Gen 5 RNG (YouTube) (EN)';

	/// de: 'Retail RNG - Gen 5 Guide (EN)'
	String get shiny_gen5_rng_link_retail => 'Retail RNG - Gen 5 Guide (EN)';

	/// de: 'Smogon - Gen 5 RNG Guide (EN)'
	String get shiny_gen5_rng_link_smogon => 'Smogon - Gen 5 RNG Guide (EN)';

	/// de: 'Shiny Huntable: Ja (Neue Basis-Chance: 1:4096)'
	String get shiny_gen6_huntable_yes => 'Shiny Huntable: Ja (Neue Basis-Chance: 1:4096)';

	/// de: 'Shiny Locks in Gen 6'
	String get shiny_gen6_locked_title => 'Shiny Locks in Gen 6';

	/// de: 'Masuda-Methode (Bis zu 1:512)'
	String get shiny_gen6_masuda_title => 'Masuda-Methode (Bis zu 1:512)';

	/// de: 'Züchte mit zwei Sprachregionen. Chance: 1:683 (ohne Pin) / 1:512 (mit Schillerpin). Tipp: Nutze die O-Kraft 'Brutkraft', um Eier rasend schnell auszubrüten!'
	String get shiny_gen6_masuda_desc => 'Züchte mit zwei Sprachregionen. Chance: 1:683 (ohne Pin) / 1:512 (mit Schillerpin). Tipp: Nutze die O-Kraft \'Brutkraft\', um Eier rasend schnell auszubrüten!';

	/// de: 'Kettenangeln / Chain Fishing (Bis zu ~1:100)'
	String get shiny_gen6_fishing_title => 'Kettenangeln / Chain Fishing (Bis zu ~1:100)';

	/// de: 'Wirf die Angel erfolgreich immer wieder an derselben Stelle aus. Ein Pokémon mit der Fähigkeit 'Saugnapf' oder 'Wertehalter' an der Spitze deines Teams ist Pflicht!'
	String get shiny_gen6_fishing_desc => 'Wirf die Angel erfolgreich immer wieder an derselben Stelle aus. Ein Pokémon mit der Fähigkeit \'Saugnapf\' oder \'Wertehalter\' an der Spitze deines Teams ist Pflicht!';

	/// de: 'YouTube - Chain Fishing Tutorial (EN)'
	String get shiny_gen6_fishing_link_yt => 'YouTube - Chain Fishing Tutorial (EN)';

	/// de: 'Reddit - Chain Fishing Guide (EN)'
	String get shiny_gen6_fishing_link_reddit => 'Reddit - Chain Fishing Guide (EN)';

	/// de: 'Massenbegegnungen / Hordes (Effektiv ~1:819)'
	String get shiny_gen6_horde_title => 'Massenbegegnungen / Hordes (Effektiv ~1:819)';

	/// de: 'Nutze die Attacke 'Lockduft' oder das Item 'Honig', um 5 Pokémon gleichzeitig zu treffen. Sehr entspannte Methode!'
	String get shiny_gen6_horde_desc => 'Nutze die Attacke \'Lockduft\' oder das Item \'Honig\', um 5 Pokémon gleichzeitig zu treffen. Sehr entspannte Methode!';

	/// de: 'Poké-Radar in X/Y (Bis zu 1:200)'
	String get shiny_gen6_radar_title => 'Poké-Radar in X/Y (Bis zu 1:200)';

	/// de: 'Wie in Gen 4: Bei einer Kette von 40 im hohen Gras hast du extrem hohe Chancen auf das glitzernde Grasfeld.'
	String get shiny_gen6_radar_desc => 'Wie in Gen 4: Bei einer Kette von 40 im hohen Gras hast du extrem hohe Chancen auf das glitzernde Grasfeld.';

	/// de: 'YouTube - X/Y Radar Tutorial (EN)'
	String get shiny_gen6_radar_link_yt => 'YouTube - X/Y Radar Tutorial (EN)';

	/// de: 'Google Slides - Radar Guide (EN)'
	String get shiny_gen6_radar_link_slides => 'Google Slides - Radar Guide (EN)';

	/// de: 'Kontaktsafari (Feste Chance: 1:512)'
	String get shiny_gen6_friendsafari_title => 'Kontaktsafari (Feste Chance: 1:512)';

	/// de: 'Exklusiv nach der Liga in X/Y. Jedes Pokémon hier hat eine feste Shiny-Chance von 1:512. Schillerpin oder Ketten haben hier KEINEN Einfluss.'
	String get shiny_gen6_friendsafari_desc => 'Exklusiv nach der Liga in X/Y. Jedes Pokémon hier hat eine feste Shiny-Chance von 1:512. Schillerpin oder Ketten haben hier KEINEN Einfluss.';

	/// de: 'DexNav in OR/AS'
	String get shiny_gen6_dexnav_title => 'DexNav in OR/AS';

	/// de: 'Je höher dein Suchlevel (Search Level) für dieses Pokémon, desto besser die Shiny-Chancen. Eine der interaktivsten Jagdmethoden überhaupt!'
	String get shiny_gen6_dexnav_desc => 'Je höher dein Suchlevel (Search Level) für dieses Pokémon, desto besser die Shiny-Chancen. Eine der interaktivsten Jagdmethoden überhaupt!';

	/// de: 'Reddit - DexNav Survival Guide (EN)'
	String get shiny_gen6_dexnav_link_reddit => 'Reddit - DexNav Survival Guide (EN)';

	/// de: 'YouTube - DexNav Tutorial (EN)'
	String get shiny_gen6_dexnav_link_yt => 'YouTube - DexNav Tutorial (EN)';

	/// de: 'PokeCommunity - DexNav Guide (EN)'
	String get shiny_gen6_dexnav_link_pokecomm => 'PokeCommunity - DexNav Guide (EN)';

	/// de: 'PokéWiki - Shiny Chaining (DE)'
	String get shiny_gen6_chaining_link_wiki => 'PokéWiki - Shiny Chaining (DE)';

	/// de: 'Soft Resets (Chance: 1:4096)'
	String get shiny_gen6_sr_title => 'Soft Resets (Chance: 1:4096)';

	/// de: 'Für Legendäre (die nicht gesperrt sind, z.B. aus Hoopa-Ringen) und statische Pokémon. Mit Schillerpin steigt die Chance auf 1:1365.'
	String get shiny_gen6_sr_desc => 'Für Legendäre (die nicht gesperrt sind, z.B. aus Hoopa-Ringen) und statische Pokémon. Mit Schillerpin steigt die Chance auf 1:1365.';

	/// de: 'Dieses Pokémon ist in dieser Generation nicht regulär fangbar oder züchtbar.'
	String get shiny_not_in_gen => 'Dieses Pokémon ist in dieser Generation nicht regulär fangbar oder züchtbar.';

	/// de: 'Relaxo Shiny Lock'
	String get shiny_gen6_snorlax_warning_title => 'Relaxo Shiny Lock';

	/// de: 'Hinweis: Das stationäre (schlafende) Relaxo auf Route 7 in X/Y ist Shiny Locked! Um ein Shiny Relaxo in Gen 6 zu erhalten, musst du es züchten.'
	String get shiny_gen6_snorlax_warning_desc => 'Hinweis: Das stationäre (schlafende) Relaxo auf Route 7 in X/Y ist Shiny Locked! Um ein Shiny Relaxo in Gen 6 zu erhalten, musst du es züchten.';

	/// de: 'In Gen 6 sind Mewtu, die legendären Vögel, Xerneas, Yveltal, Zygarde, Kyogre, Groudon, Rayquaza, Deoxys sowie Diancie, Hoopa und Volcanion Shiny Locked!'
	String get shiny_gen6_locked_desc => 'In Gen 6 sind Mewtu, die legendären Vögel, Xerneas, Yveltal, Zygarde, Kyogre, Groudon, Rayquaza, Deoxys sowie Diancie, Hoopa und Volcanion Shiny Locked!';

	/// de: 'Generation 7.5 (Let's Go P/E)'
	String get shiny_guide_gen7_5 => 'Generation 7.5 (Let\'s Go P/E)';

	/// de: 'Shiny Huntable: Ja (Basis-Chance 1:4096)'
	String get shiny_gen7_huntable_yes => 'Shiny Huntable: Ja (Basis-Chance 1:4096)';

	/// de: 'Shiny Locks in Gen 7'
	String get shiny_gen7_locked_title => 'Shiny Locks in Gen 7';

	/// de: 'Gesperrt in S/M & US/UM: Zygarde, Kapu-Riki, Kapu-Fala, Kapu-Toro, Kapu-Kime, Cosmog, Cosmovum, Solgaleo, Lunala, Necrozma.'
	String get shiny_gen7_locked_desc => 'Gesperrt in S/M & US/UM: Zygarde, Kapu-Riki, Kapu-Fala, Kapu-Toro, Kapu-Kime, Cosmog, Cosmovum, Solgaleo, Lunala, Necrozma.';

	/// de: 'Ultrabestien (Nur in S/M gesperrt!)'
	String get shiny_gen7_ub_locked_title => 'Ultrabestien (Nur in S/M gesperrt!)';

	/// de: 'Achtung: Alle Ultrabestien sind in Sonne & Mond Shiny Locked. In Ultrasonne & Ultramond kannst du sie jedoch regulär hunten!'
	String get shiny_gen7_ub_locked_desc => 'Achtung: Alle Ultrabestien sind in Sonne & Mond Shiny Locked. In Ultrasonne & Ultramond kannst du sie jedoch regulär hunten!';

	/// de: 'SOS-Chaining (Quereinsteiger)'
	String get shiny_gen7_sos_title => 'SOS-Chaining (Quereinsteiger)';

	/// de: 'Wilde Pokémon rufen um Hilfe. Mit einem Zitterorb steigt die Rufrate. Bei einer Kette von 70+ steigt die Shiny-Chance enorm an (bis 1:315).'
	String get shiny_gen7_sos_desc => 'Wilde Pokémon rufen um Hilfe. Mit einem Zitterorb steigt die Rufrate. Bei einer Kette von 70+ steigt die Shiny-Chance enorm an (bis 1:315).';

	/// de: 'Reddit - SOS Chaining Guide (EN)'
	String get shiny_gen7_sos_link_reddit => 'Reddit - SOS Chaining Guide (EN)';

	/// de: 'YouTube - SOS Tutorial (EN)'
	String get shiny_gen7_sos_link_yt_en => 'YouTube - SOS Tutorial (EN)';

	/// de: 'YouTube - SOS Tutorial (DE)'
	String get shiny_gen7_sos_link_yt_de => 'YouTube - SOS Tutorial (DE)';

	/// de: 'Ultradimension-Zero (US/UM)'
	String get shiny_gen7_warp_title => 'Ultradimension-Zero (US/UM)';

	/// de: 'Im Warp Ride haben normale Pokémon (je nach Distanz) eine irrsinnig hohe Shiny-Chance (bis 36%). Legenden haben die normale Chance (1:4096 / SR).'
	String get shiny_gen7_warp_desc => 'Im Warp Ride haben normale Pokémon (je nach Distanz) eine irrsinnig hohe Shiny-Chance (bis 36%). Legenden haben die normale Chance (1:4096 / SR).';

	/// de: 'Reddit - Warp Ride Odds (EN)'
	String get shiny_gen7_warp_link_reddit => 'Reddit - Warp Ride Odds (EN)';

	/// de: 'YouTube - Warp Ride Tutorial (EN)'
	String get shiny_gen7_warp_link_yt_en => 'YouTube - Warp Ride Tutorial (EN)';

	/// de: 'YouTube - Warp Ride Tutorial (DE)'
	String get shiny_gen7_warp_link_yt_de => 'YouTube - Warp Ride Tutorial (DE)';

	/// de: 'Bisafans - Warp Loch Shinys (DE)'
	String get shiny_gen7_warp_link_bisa => 'Bisafans - Warp Loch Shinys (DE)';

	/// de: 'Pokémon-Resort (Poké Pelago)'
	String get shiny_gen7_pelago_title => 'Pokémon-Resort (Poké Pelago)';

	/// de: 'Wilde Pokémon, die deine Insel besuchen, können Shiny sein! Du siehst es direkt, musst aber 24h warten, ob sie im Team bleiben.'
	String get shiny_gen7_pelago_desc => 'Wilde Pokémon, die deine Insel besuchen, können Shiny sein! Du siehst es direkt, musst aber 24h warten, ob sie im Team bleiben.';

	/// de: 'Fangserie (Catch Combo)'
	String get shiny_gen75_combo_title => 'Fangserie (Catch Combo)';

	/// de: 'Fange immer wieder das gleiche Pokémon. Ab einer Kette von 31 + Lockparfüm + Schillerpin steigt die Chance für den NÄCHSTEN Spawn auf gigantische 1:273!'
	String get shiny_gen75_combo_desc => 'Fange immer wieder das gleiche Pokémon. Ab einer Kette von 31 + Lockparfüm + Schillerpin steigt die Chance für den NÄCHSTEN Spawn auf gigantische 1:273!';

	/// de: 'Reddit - Let's Go Shiny Guide (EN)'
	String get shiny_gen75_combo_link_reddit => 'Reddit - Let\'s Go Shiny Guide (EN)';

	/// de: 'YouTube - Let's Go Hunt (DE)'
	String get shiny_gen75_combo_link_yt_de1 => 'YouTube - Let\'s Go Hunt (DE)';

	/// de: 'YouTube - Let's Go Hunt Teil 2 (DE)'
	String get shiny_gen75_combo_link_yt_de2 => 'YouTube - Let\'s Go Hunt Teil 2 (DE)';

	/// de: 'Alola-NPC-Tausche'
	String get shiny_gen75_alola_title => 'Alola-NPC-Tausche';

	/// de: 'NPCs tauschen unbegrenzt Alola-Formen. Diese können Shiny sein (Chance 1:4096). Der Schillerpin oder Ketten wirken hierauf NICHT.'
	String get shiny_gen75_alola_desc => 'NPCs tauschen unbegrenzt Alola-Formen. Diese können Shiny sein (Chance 1:4096). Der Schillerpin oder Ketten wirken hierauf NICHT.';

	/// de: 'Let's Go Shiny Locks'
	String get shiny_gen75_locked_title => 'Let\'s Go Shiny Locks';

	/// de: 'Dein Partner-Pikachu/Evoli und das Mew (Pokéball Plus) sind immer Shiny Locked. Wilde Pikachu/Evoli kannst du aber normal jagen!'
	String get shiny_gen75_locked_desc => 'Dein Partner-Pikachu/Evoli und das Mew (Pokéball Plus) sind immer Shiny Locked. Wilde Pikachu/Evoli kannst du aber normal jagen!';

	/// de: 'Generation 8 (SwSh & BDSP)'
	String get shiny_guide_gen8 => 'Generation 8 (SwSh & BDSP)';

	/// de: 'Generation 8.5 (Legenden: Arceus)'
	String get shiny_guide_gen8_5 => 'Generation 8.5 (Legenden: Arceus)';

	/// de: 'Schwert & Schild (Galar)'
	String get shiny_gen8_swsh_title => 'Schwert & Schild (Galar)';

	/// de: 'Basis-Chance 1:4096 (1:1365 mit Pin). Nutze Dynamax-Abenteuer im DLC (1:100 Chance!) oder die K.O.-Methode für wilde Spawns.'
	String get shiny_gen8_swsh_desc => 'Basis-Chance 1:4096 (1:1365 mit Pin). Nutze Dynamax-Abenteuer im DLC (1:100 Chance!) oder die K.O.-Methode für wilde Spawns.';

	/// de: 'Strahlender Diamant & Leuchtende Perle'
	String get shiny_gen8_bdsp_title => 'Strahlender Diamant & Leuchtende Perle';

	/// de: 'Basis-Chance 1:4096. Nutze den Untergrund-Diglett-Bonus (verdoppelt die Shiny-Rate temporär) oder Soft Resets für Legendäre.'
	String get shiny_gen8_bdsp_desc => 'Basis-Chance 1:4096. Nutze den Untergrund-Diglett-Bonus (verdoppelt die Shiny-Rate temporär) oder Soft Resets für Legendäre.';

	/// de: 'Shiny Locks in SwSh & BDSP'
	String get shiny_gen8_locked_title => 'Shiny Locks in SwSh & BDSP';

	/// de: 'Die Legendären aus Galar (Zacian, Zamazenta, Endynalos, Dakuma, Coronospa etc.) sowie Typ:Null, Cosmog und Venicro sind hier komplett gesperrt. Starter-Geschenke (wie Chimpep) sind gesperrt, können aber GEZÜCHTET werden!'
	String get shiny_gen8_locked_desc => 'Die Legendären aus Galar (Zacian, Zamazenta, Endynalos, Dakuma, Coronospa etc.) sowie Typ:Null, Cosmog und Venicro sind hier komplett gesperrt. Starter-Geschenke (wie Chimpep) sind gesperrt, können aber GEZÜCHTET werden!';

	/// de: 'Masuda-Methode (SwSh & BDSP)'
	String get shiny_gen8_masuda_title => 'Masuda-Methode (SwSh & BDSP)';

	/// de: 'Züchte zwei Pokémon aus unterschiedlichen Sprachregionen. Chance: 1:683 (ohne Pin) / 1:512 (mit Schillerpin).'
	String get shiny_gen8_masuda_desc => 'Züchte zwei Pokémon aus unterschiedlichen Sprachregionen. Chance: 1:683 (ohne Pin) / 1:512 (mit Schillerpin).';

	/// de: 'Bulbapedia - Masuda Method'
	String get shiny_gen8_masuda_link => 'Bulbapedia - Masuda Method';

	/// de: 'Poké-Radar (Nur BDSP)'
	String get shiny_gen8_radar_title => 'Poké-Radar (Nur BDSP)';

	/// de: 'Exklusiv in den Sinnoh-Remakes: Erreiche eine Kette von 40 im hohen Gras, um die Shiny-Chance auf gigantische 1:99 pro glitzerndem Grasfeld zu erhöhen!'
	String get shiny_gen8_radar_desc => 'Exklusiv in den Sinnoh-Remakes: Erreiche eine Kette von 40 im hohen Gras, um die Shiny-Chance auf gigantische 1:99 pro glitzerndem Grasfeld zu erhöhen!';

	/// de: 'YouTube - BDSP Radar Tutorial (DE)'
	String get shiny_gen8_radar_link_yt_de => 'YouTube - BDSP Radar Tutorial (DE)';

	/// de: 'Reddit - BDSP Radar Guide (EN)'
	String get shiny_gen8_radar_link_reddit => 'Reddit - BDSP Radar Guide (EN)';

	/// de: 'YouTube - BDSP Radar Tutorial (EN)'
	String get shiny_gen8_radar_link_yt_en => 'YouTube - BDSP Radar Tutorial (EN)';

	/// de: 'Legenden: Arceus (Hisui)'
	String get shiny_gen85_pla_title => 'Legenden: Arceus (Hisui)';

	/// de: 'Shinys laufen sichtbar in der Overworld herum! Sie kündigen sich durch einen **deutlichen Sound-Jingle und visuellen Effekt** an. Du kannst den Schillerpin und das Forschungslevel kombinieren.'
	String get shiny_gen85_pla_desc => 'Shinys laufen sichtbar in der Overworld herum! Sie kündigen sich durch einen **deutlichen Sound-Jingle und visuellen Effekt** an. Du kannst den Schillerpin und das Forschungslevel kombinieren.';

	/// de: 'Massive Massenauftritte (MMOs)'
	String get shiny_gen85_pla_outbreaks_title => 'Massive Massenauftritte (MMOs)';

	/// de: 'Das effektivste Tool in Hisui. Durch das gezielte Besiegen/Fangen in Massenauftritten sinkt die Chance auf bis zu 1:128.'
	String get shiny_gen85_pla_outbreaks_desc => 'Das effektivste Tool in Hisui. Durch das gezielte Besiegen/Fangen in Massenauftritten sinkt die Chance auf bis zu 1:128.';

	/// de: 'Shiny Locks in Hisui'
	String get shiny_gen85_locked_title => 'Shiny Locks in Hisui';

	/// de: 'Achtung: ALLE Legendären und Mysteriösen Pokémon (Arceus, Dialga, Palkia, Darkrai etc.) sowie einmalige Quest-Begegnungen sind in Hisui Shiny Locked!'
	String get shiny_gen85_locked_desc => 'Achtung: ALLE Legendären und Mysteriösen Pokémon (Arceus, Dialga, Palkia, Darkrai etc.) sowie einmalige Quest-Begegnungen sind in Hisui Shiny Locked!';

	/// de: 'Reddit - PLA Outbreaks Guide (EN)'
	String get shiny_gen8_pla_link_reddit => 'Reddit - PLA Outbreaks Guide (EN)';

	/// de: 'Bisafans - PLA Outbreaks Guide (DE)'
	String get shiny_gen8_pla_link_bisafans => 'Bisafans - PLA Outbreaks Guide (DE)';

	/// de: 'Generation 9 (Karmesin & Purpur)'
	String get shiny_guide_gen9 => 'Generation 9 (Karmesin & Purpur)';

	/// de: 'Generation 9.5 (Legenden: Z-A)'
	String get shiny_guide_gen9_5 => 'Generation 9.5 (Legenden: Z-A)';

	/// de: 'Karmesin & Purpur (Paldea)'
	String get shiny_gen9_sv_title => 'Karmesin & Purpur (Paldea)';

	/// de: 'Basis-Chance 1:4096. Shinys sind in der Overworld sichtbar, machen aber KEINEN Sound! Nutze die Let's Go-Funktion (Auto-Kampf), da dein Partner Shinys strikt verschont.'
	String get shiny_gen9_sv_desc => 'Basis-Chance 1:4096. Shinys sind in der Overworld sichtbar, machen aber KEINEN Sound! Nutze die Let\'s Go-Funktion (Auto-Kampf), da dein Partner Shinys strikt verschont.';

	/// de: 'Sandwiches (Schillerkraft)'
	String get shiny_gen9_sandwich_title => 'Sandwiches (Schillerkraft)';

	/// de: 'Mit Geheimgewürzen stellst du Schillerkraft Lv. 3 her. Erhöht die Shiny-Chance massiv (bis zu 1:512 mit Pin).'
	String get shiny_gen9_sandwich_desc => 'Mit Geheimgewürzen stellst du Schillerkraft Lv. 3 her. Erhöht die Shiny-Chance massiv (bis zu 1:512 mit Pin).';

	/// de: 'Massenaufläufe (Outbreaks)'
	String get shiny_gen9_outbreak_title => 'Massenaufläufe (Outbreaks)';

	/// de: 'Besiege 60+ Pokémon im Auto-Kampf in einem Auflauf für die maximale Bonus-Chance. Kombinierbar mit Sandwiches!'
	String get shiny_gen9_outbreak_desc => 'Besiege 60+ Pokémon im Auto-Kampf in einem Auflauf für die maximale Bonus-Chance. Kombinierbar mit Sandwiches!';

	/// de: 'Isolation Hunting (Begegnungskraft)'
	String get shiny_gen9_isolation_title => 'Isolation Hunting (Begegnungskraft)';

	/// de: 'Nutze Sandwiches mit 'Begegnungskraft' an Orten, wo nur das Ziel-Pokémon diesen Typ hat. Das zwingt das Spiel, fast ausschließlich dein Ziel spawnen zu lassen!'
	String get shiny_gen9_isolation_desc => 'Nutze Sandwiches mit \'Begegnungskraft\' an Orten, wo nur das Ziel-Pokémon diesen Typ hat. Das zwingt das Spiel, fast ausschließlich dein Ziel spawnen zu lassen!';

	/// de: 'Shiny Locks in Karmesin & Purpur'
	String get shiny_gen9_locked_title => 'Shiny Locks in Karmesin & Purpur';

	/// de: 'Zahlreiche Legendäre (Koraidon, Miraidon, Ruinen-Legis, Paradox-Legis, Terapagos etc.) sowie Gierspenst (außer Event-Raids) und Blutmond-Ursaluna sind Shiny Locked!'
	String get shiny_gen9_locked_desc => 'Zahlreiche Legendäre (Koraidon, Miraidon, Ruinen-Legis, Paradox-Legis, Terapagos etc.) sowie Gierspenst (außer Event-Raids) und Blutmond-Ursaluna sind Shiny Locked!';

	/// de: 'Polygon - Sandwich Rezepte & Guide (EN)'
	String get shiny_gen9_link_sandwich => 'Polygon - Sandwich Rezepte & Guide (EN)';

	/// de: 'YouTube - SV Shiny Hunting Guide (EN)'
	String get shiny_gen9_link_outbreak => 'YouTube - SV Shiny Hunting Guide (EN)';

	/// de: 'Bisafans - Shiny Hunting in SV (DE)'
	String get shiny_gen9_link_bisa => 'Bisafans - Shiny Hunting in SV (DE)';

	/// de: 'Legenden: Z-A (Lumiose City)'
	String get shiny_gen95_plza_title => 'Legenden: Z-A (Lumiose City)';

	/// de: 'Der Shiny-Sound ist zurück! Bis zu 10 Shinys können gleichzeitig auf der Map existieren und werden dauerhaft gespeichert, bevor das älteste despawnt.'
	String get shiny_gen95_plza_desc => 'Der Shiny-Sound ist zurück! Bis zu 10 Shinys können gleichzeitig auf der Map existieren und werden dauerhaft gespeichert, bevor das älteste despawnt.';

	/// de: 'Donuts & Spawns (50m/70m Trick)'
	String get shiny_gen95_donut_title => 'Donuts & Spawns (50m/70m Trick)';

	/// de: 'Donuts erhöhen die Shiny-Chance! Neue Pokémon spawnen im Umkreis von 50m. Legenden kannst du resetten, indem du 70m weggehst (Despawn) und wieder kommst (neuer Spawn bei 50m).'
	String get shiny_gen95_donut_desc => 'Donuts erhöhen die Shiny-Chance! Neue Pokémon spawnen im Umkreis von 50m. Legenden kannst du resetten, indem du 70m weggehst (Despawn) und wieder kommst (neuer Spawn bei 50m).';

	/// de: 'Shiny Locks in Legenden: Z-A'
	String get shiny_gen95_locked_title => 'Shiny Locks in Legenden: Z-A';

	/// de: 'Kyogre, Groudon, Rayquaza, Xerneas, Yveltal, Zygarde, Heatran, Darkrai und alle Nebenmissions-Begegnungen (außer Voltilamm) sind gesperrt!'
	String get shiny_gen95_locked_desc => 'Kyogre, Groudon, Rayquaza, Xerneas, Yveltal, Zygarde, Heatran, Darkrai und alle Nebenmissions-Begegnungen (außer Voltilamm) sind gesperrt!';

	/// de: 'Reddit - Best PLZA Hunting Methods (EN)'
	String get shiny_gen95_link_reddit => 'Reddit - Best PLZA Hunting Methods (EN)';

	/// de: 'IGN - PLZA Shiny Guide (EN)'
	String get shiny_gen95_link_ign => 'IGN - PLZA Shiny Guide (EN)';

	/// de: 'YouTube - Z-A Shiny Tutorial (DE)'
	String get shiny_gen95_link_yt_de => 'YouTube - Z-A Shiny Tutorial (DE)';

	/// de: 'Routen-Tracker'
	String get route_tracker_title => 'Routen-Tracker';

	/// de: 'Suche Route oder Pokémon...'
	String get search_route_pokemon => 'Suche Route oder Pokémon...';

	/// de: 'Fertige Routen ausblenden'
	String get hide_completed_routes => 'Fertige Routen ausblenden';

	/// de: 'Spiele & Editionen filtern'
	String get games_filter_title => 'Spiele & Editionen filtern';

	/// de: 'Sichtbare Editionen'
	String get visible_editions => 'Sichtbare Editionen';

	/// de: 'Generation {0}'
	String get generation_x => 'Generation {0}';

	/// de: 'Keine'
	String get none => 'Keine';

	/// de: 'Alle'
	String get all => 'Alle';

	/// de: 'Ganze Box abhaken'
	String get box_check_all => 'Ganze Box abhaken';

	/// de: 'Ganze Box Markierung aufheben'
	String get box_uncheck_all => 'Ganze Box Markierung aufheben';

	/// de: 'Fähigkeiten-Dex'
	String get dex_abilities => 'Fähigkeiten-Dex';

	/// de: 'Attacken-Dex'
	String get dex_moves => 'Attacken-Dex';

	/// de: 'Stärke'
	String get power => 'Stärke';

	/// de: 'Genauigkeit'
	String get accuracy => 'Genauigkeit';

	/// de: 'AP'
	String get pp => 'AP';

	/// de: 'Kategorie'
	String get category => 'Kategorie';

	/// de: 'Typ'
	String get type => 'Typ';

	/// de: 'Erlernbar von'
	String get learned_by => 'Erlernbar von';

	/// de: 'Versteckte Fähigkeit'
	String get hidden_ability => 'Versteckte Fähigkeit';

	/// de: 'Normale Fähigkeit'
	String get normal_ability => 'Normale Fähigkeit';

	/// de: 'Levelaufstieg (Lv. {0})'
	String get learned_by_level => 'Levelaufstieg (Lv. {0})';

	/// de: 'TM/VM'
	String get learned_by_machine => 'TM/VM';

	/// de: 'Zucht (Ei)'
	String get learned_by_egg => 'Zucht (Ei)';

	/// de: 'Attacken-Lehrer'
	String get learned_by_tutor => 'Attacken-Lehrer';

	/// de: 'Attacken-Dex'
	String get region_moves_dex => 'Attacken-Dex';

	/// de: 'Fähigkeiten-Dex'
	String get region_abilities_dex => 'Fähigkeiten-Dex';

	/// de: 'Attacken-Dex'
	String get special_dex_moves => 'Attacken-Dex';

	/// de: 'Fähigkeiten-Dex'
	String get special_dex_abilities => 'Fähigkeiten-Dex';

	/// de: 'Eine Übersicht aller verfügbaren Attacken'
	String get special_dex_moves_desc => 'Eine Übersicht aller verfügbaren Attacken';

	/// de: 'Eine Übersicht aller verfügbaren Fähigkeiten'
	String get special_dex_abilities_desc => 'Eine Übersicht aller verfügbaren Fähigkeiten';

	/// de: 'Registriert'
	String get registered => 'Registriert';

	/// de: 'Stärke'
	String get power_short => 'Stärke';

	/// de: 'Genauigk.'
	String get accuracy_short => 'Genauigk.';

	/// de: 'Physisch'
	String get category_physical => 'Physisch';

	/// de: 'Spezial'
	String get category_special => 'Spezial';

	/// de: 'Status'
	String get category_status => 'Status';

	/// de: 'Versteckt'
	String get hidden_ability_short => 'Versteckt';

	/// de: 'Normal'
	String get normal_ability_short => 'Normal';

	/// de: 'Sortieren nach'
	String get sort_by => 'Sortieren nach';

	/// de: 'Nach Typ gruppieren'
	String get sort_type => 'Nach Typ gruppieren';

	/// de: 'Bänder'
	String get ribbons => 'Bänder';

	/// de: 'Zeichen'
	String get marks => 'Zeichen';

	/// de: 'Terakristallisierung'
	String get tera_types_title => 'Terakristallisierung';

	/// de: 'Titel:'
	String get title => 'Titel:';

	/// de: 'Fundort / Bedingung:'
	String get location => 'Fundort / Bedingung:';

	/// de: 'Suchen...'
	String get search => 'Suchen...';

	/// de: 'Zeichen'
	String get tutorial_info_marks_title => 'Zeichen';

	/// de: 'Bulbapedia (Catch Rates)'
	String get credit_bulbapedia_title => 'Bulbapedia (Catch Rates)';

	/// de: 'Mechaniken für Legends Z-A und Max Raids'
	String get credit_bulbapedia_sub => 'Mechaniken für Legends Z-A und Max Raids';

	/// de: 'Ribbons.Guide'
	String get credit_ribbons_title => 'Ribbons.Guide';

	/// de: 'Datenbank für Bänder & Zeichen'
	String get credit_ribbons_sub => 'Datenbank für Bänder & Zeichen';

	/// de: 'Alpha-Pokémon'
	String get alpha_status => 'Alpha-Pokémon';

	/// de: 'Riesige Alphas!'
	String get tutorial_info_alpha_title => 'Riesige Alphas!';

	/// de: 'Manche Pokémon aus Hisui (und bald Z-A) können als riesige Alphas gefangen werden. Markiere sie hier!'
	String get tutorial_info_alpha_text => 'Manche Pokémon aus Hisui (und bald Z-A) können als riesige Alphas gefangen werden. Markiere sie hier!';

	/// de: 'Tera-Typen'
	String get tutorial_info_tera_title => 'Tera-Typen';

	/// de: 'In Paldea können Pokémon verschiedene Tera-Typen annehmen. Speichere hier, welche Tera-Typen du für dieses Pokémon bereits besitzt.'
	String get tutorial_info_tera_text => 'In Paldea können Pokémon verschiedene Tera-Typen annehmen. Speichere hier, welche Tera-Typen du für dieses Pokémon bereits besitzt.';

	/// de: 'Bänder sammeln'
	String get tutorial_info_ribbons_title => 'Bänder sammeln';

	/// de: 'Dein Pokémon hat eine Meisterschaft gewonnen oder etwas Besonderes geleistet? Hake hier die Bänder ab, die es gesammelt hat.'
	String get tutorial_info_ribbons_text => 'Dein Pokémon hat eine Meisterschaft gewonnen oder etwas Besonderes geleistet? Hake hier die Bänder ab, die es gesammelt hat.';

	/// de: 'Wilde Pokémon können beim Fang besondere Zeichen tragen. Wenn du ein solches gefangen hast, kannst du es hier vermerken.'
	String get tutorial_info_marks_text => 'Wilde Pokémon können beim Fang besondere Zeichen tragen. Wenn du ein solches gefangen hast, kannst du es hier vermerken.';

	/// de: 'Sprachen'
	String get languages_title => 'Sprachen';

	/// de: 'Geschenke'
	String get cat_gifts => 'Geschenke';

	/// de: 'Tausche'
	String get cat_trades => 'Tausche';

	/// de: 'Colosseum & XD'
	String get cat_orre => 'Colosseum & XD';

	/// de: 'Erweiterte Sortierung'
	String get advanced_sort_title => 'Erweiterte Sortierung';

	/// de: 'Mega-Entwicklungen'
	String get sort_mega_title => 'Mega-Entwicklungen';

	/// de: 'Giga-Dynamax'
	String get sort_gmax_title => 'Giga-Dynamax';

	/// de: 'Regionalformen'
	String get sort_regional_title => 'Regionalformen';

	/// de: 'Ursprungsregion (z.B. Kanto)'
	String get sort_origin_kanto => 'Ursprungsregion (z.B. Kanto)';

	/// de: 'Region der Mechanik (Kalos/Hoenn)'
	String get sort_mechanic_mega => 'Region der Mechanik (Kalos/Hoenn)';

	/// de: 'Region der Mechanik (Galar)'
	String get sort_mechanic_gmax => 'Region der Mechanik (Galar)';

	/// de: 'Region der Form (z.B. Alola)'
	String get sort_mechanic_regional => 'Region der Form (z.B. Alola)';

	/// de: 'Amigento'
	String get cat_silvally => 'Amigento';

	/// de: 'Arceus'
	String get cat_arceus => 'Arceus';

	/// de: 'Coiffwaff'
	String get cat_furfrou => 'Coiffwaff';

	/// de: 'Pokémon GO Exklusivität'
	String get shiny_meltan_go_title => 'Pokémon GO Exklusivität';

	/// de: 'Meltan und Melmetal können aktuell ausschließlich in Pokémon GO schillernd erhalten werden (über die Wunderbox während zeitlich begrenzter Event-Zeiträume). In Let's Go, Pikachu & Evoli können sie nur von Pokémon GO übertragen werden.'
	String get shiny_meltan_go_desc => 'Meltan und Melmetal können aktuell ausschließlich in Pokémon GO schillernd erhalten werden (über die Wunderbox während zeitlich begrenzter Event-Zeiträume). In Let\'s Go, Pikachu & Evoli können sie nur von Pokémon GO übertragen werden.';

	/// de: 'Boxen bearbeiten'
	String get box_edit_title => 'Boxen bearbeiten';

	/// de: 'Box hinzufügen'
	String get box_edit_add_box => 'Box hinzufügen';

	/// de: 'Box umbenennen'
	String get box_edit_rename_box => 'Box umbenennen';

	/// de: 'Box löschen'
	String get box_edit_delete_box => 'Box löschen';

	/// de: 'Inhalt verwalten'
	String get box_edit_manage_content => 'Inhalt verwalten';

	/// de: 'Mehrere auswählen'
	String get box_edit_select_multiple => 'Mehrere auswählen';

	/// de: 'Ausgewählte entfernen'
	String get box_edit_remove_selected => 'Ausgewählte entfernen';

	/// de: 'Pokémon hinzufügen'
	String get box_edit_add_pokemon => 'Pokémon hinzufügen';

	/// de: 'Pokémon hier einfügen'
	String get box_edit_insert_pokemon => 'Pokémon hier einfügen';

	/// de: 'Starter (Prof. Eich)'
	String get encounter_starter_oak => 'Starter (Prof. Eich)';

	/// de: 'Geschenk (Azuria City)'
	String get encounter_gift_cerulean => 'Geschenk (Azuria City)';

	/// de: 'Geschenk (Route 24)'
	String get encounter_gift_route24 => 'Geschenk (Route 24)';

	/// de: 'Geschenk (Orania City)'
	String get encounter_gift_vermilion => 'Geschenk (Orania City)';

	/// de: 'Geschenk (Prismania Villa)'
	String get encounter_gift_mansion => 'Geschenk (Prismania Villa)';

	/// de: 'Geschenk (Silph Co.)'
	String get encounter_gift_silph => 'Geschenk (Silph Co.)';

	/// de: 'Geschenk (Kampf-Dojo)'
	String get encounter_gift_dojo => 'Geschenk (Kampf-Dojo)';

	/// de: 'Fossil-Wiederbelebung'
	String get encounter_fossil_restoration => 'Fossil-Wiederbelebung';

	/// de: 'Stationäre Begegnung'
	String get encounter_stationary => 'Stationäre Begegnung';

	/// de: 'In-Game Tausch'
	String get encounter_trade => 'In-Game Tausch';

	/// de: 'Spielhalle'
	String get encounter_game_corner => 'Spielhalle';

	/// de: '8F Item Underflow Glitch'
	String get encounter_glitch_8f => '8F Item Underflow Glitch';

	/// de: 'Box-Verwaltung Einstellungen'
	String get box_edit_settings_header => 'Box-Verwaltung Einstellungen';

	/// de: 'Auto-Verschieben von Pokémon'
	String get box_edit_auto_shift_title => 'Auto-Verschieben von Pokémon';

	/// de: 'Verschiebt Pokémon beim Einfügen vorwärts und beim Entfernen rückwärts, um Lücken zu schließen.'
	String get box_edit_auto_shift_subtitle => 'Verschiebt Pokémon beim Einfügen vorwärts und beim Entfernen rückwärts, um Lücken zu schließen.';

	/// de: 'Strikte Kapazitätsgrenzen'
	String get box_edit_strict_limits_title => 'Strikte Kapazitätsgrenzen';

	/// de: 'Erzwingt feste Box-Kapazitätsgrenzen (Spalten × Zeilen) und leitet Überlauf in die nächste verknüpfte Box weiter.'
	String get box_edit_strict_limits_subtitle => 'Erzwingt feste Box-Kapazitätsgrenzen (Spalten × Zeilen) und leitet Überlauf in die nächste verknüpfte Box weiter.';

	/// de: 'Musterbasierte Auto-Erstellung'
	String get box_edit_pattern_auto_create_title => 'Musterbasierte Auto-Erstellung';

	/// de: 'Erstellt automatisch eine neue Folgebox (z. B. „Kanto 4“), wenn die letzte verknüpfte Box überläuft.'
	String get box_edit_pattern_auto_create_subtitle => 'Erstellt automatisch eine neue Folgebox (z. B. „Kanto 4“), wenn die letzte verknüpfte Box überläuft.';

	/// de: 'Leere Boxen automatisch löschen'
	String get box_edit_auto_delete_empty_title => 'Leere Boxen automatisch löschen';

	/// de: 'Löscht leere Folgeboxen automatisch nach dem Nachrücken von Pokémon (Stammbox bleibt erhalten).'
	String get box_edit_auto_delete_empty_subtitle => 'Löscht leere Folgeboxen automatisch nach dem Nachrücken von Pokémon (Stammbox bleibt erhalten).';

	/// de: 'Änderungen speichern?'
	String get edit_mode_save_title => 'Änderungen speichern?';

	/// de: 'Möchtest du alle Änderungen verwerfen?'
	String get edit_mode_discard_title => 'Möchtest du alle Änderungen verwerfen?';

	/// de: 'Ja'
	String get yes => 'Ja';

	/// de: 'Verwerfen'
	String get discard => 'Verwerfen';

	/// de: 'Tauschen'
	String get box_action_swap => 'Tauschen';

	/// de: 'Hierhin verschieben'
	String get move_selected_block => 'Hierhin verschieben';

	/// de: 'In Box verschieben...'
	String get move_selected_to_box => 'In Box verschieben...';

	/// de: 'Tippe auf Ziel-Slot...'
	String get tap_target_slot => 'Tippe auf Ziel-Slot...';

	/// de: 'Zielbox auswählen'
	String get select_target_box => 'Zielbox auswählen';

	/// de: 'Auswahl aufheben'
	String get cancel_selection => 'Auswahl aufheben';

	/// de: 'Platzhalter einfügen'
	String get insert_placeholder => 'Platzhalter einfügen';

	/// de: 'Platzhalter'
	String get placeholder => 'Platzhalter';

	/// de: 'Fixierte Lücke (geschützt vor Auto-Shift)'
	String get placeholder_desc => 'Fixierte Lücke (geschützt vor Auto-Shift)';

	/// de: 'Name oder Pokédex-Nr. suchen...'
	String get search_pokemon_hint => 'Name oder Pokédex-Nr. suchen...';

	/// de: 'Alle Regionen'
	String get all_regions => 'Alle Regionen';

	/// de: 'Alle Formen'
	String get all_forms => 'Alle Formen';

	/// de: 'Normal'
	String get form_normal => 'Normal';

	/// de: 'Regionen'
	String get filter_regions => 'Regionen';

	/// de: 'Formen'
	String get filter_forms => 'Formen';

	/// de: 'Geschlecht'
	String get filter_gender => 'Geschlecht';

	/// de: 'Männlich (♂)'
	String get gender_male => 'Männlich (♂)';

	/// de: 'Weiblich (♀)'
	String get gender_female => 'Weiblich (♀)';

	/// de: 'Unterschiede'
	String get gender_differences => 'Unterschiede';

	/// de: 'Variante'
	String get filter_variant => 'Variante';

	/// de: 'Standard'
	String get variant_normal => 'Standard';

	/// de: 'Schillernd'
	String get variant_shiny => 'Schillernd';

	/// de: 'Box-Menü'
	String get box_menu => 'Box-Menü';

	/// de: 'Filter zurücksetzen'
	String get reset_filters => 'Filter zurücksetzen';

	/// de: 'Rastergröße ändern'
	String get grid_size_title => 'Rastergröße ändern';

	/// de: 'Spalten'
	String get grid_columns => 'Spalten';

	/// de: 'Reihen'
	String get grid_rows => 'Reihen';

	/// de: 'Für alle Boxen übernehmen'
	String get grid_apply_all => 'Für alle Boxen übernehmen';

	/// de: 'Spaltenanzahl ändern'
	String get grid_columns_tooltip => 'Spaltenanzahl ändern';

	/// de: 'Leerer Platz'
	String get box_edit_empty_slot => 'Leerer Platz';

	/// de: 'Entfernen'
	String get box_edit_remove => 'Entfernen';

	/// de: 'Shiny Hunt Tracker'
	String get shiny_hunt_hub_title => 'Shiny Hunt Tracker';

	/// de: 'Aktiv'
	String get shiny_hunt_tab_active => 'Aktiv';

	/// de: 'Pausiert'
	String get shiny_hunt_tab_paused => 'Pausiert';

	/// de: 'Beendet'
	String get shiny_hunt_tab_completed => 'Beendet';

	/// de: 'Neuer Hunt'
	String get shiny_hunt_new_hunt => 'Neuer Hunt';

	/// de: 'Keine aktiven Hunts vorhanden.'
	String get shiny_hunt_empty_active => 'Keine aktiven Hunts vorhanden.';

	/// de: 'Keine pausierten Hunts.'
	String get shiny_hunt_empty_paused => 'Keine pausierten Hunts.';

	/// de: 'Noch keine Shinies gefangen. Starte jetzt deinen ersten Hunt!'
	String get shiny_hunt_empty_completed => 'Noch keine Shinies gefangen. Starte jetzt deinen ersten Hunt!';

	/// de: 'Fortsetzen'
	String get shiny_hunt_resume => 'Fortsetzen';

	/// de: 'Pausieren'
	String get shiny_hunt_pause => 'Pausieren';

	/// de: 'Hunt löschen?'
	String get shiny_hunt_delete_confirm_title => 'Hunt löschen?';

	/// de: 'Möchtest du diesen Hunt wirklich unwiderruflich löschen?'
	String get shiny_hunt_delete_confirm_desc => 'Möchtest du diesen Hunt wirklich unwiderruflich löschen?';

	/// de: 'Tippen zum Zählen'
	String get shiny_hunt_tap_to_count => 'Tippen zum Zählen';

	/// de: 'Schritt'
	String get shiny_hunt_step_label => 'Schritt';

	/// de: 'Zähler manuell anpassen'
	String get shiny_hunt_manual_count_title => 'Zähler manuell anpassen';

	/// de: 'Begegnungen eingeben...'
	String get shiny_hunt_manual_count_hint => 'Begegnungen eingeben...';

	/// de: 'Phase'
	String get shiny_hunt_phase_label => 'Phase';

	/// de: 'Gesamt'
	String get shiny_hunt_total_label => 'Gesamt';

	/// de: 'Würfe'
	String get shiny_hunt_rolls_label => 'Würfe';

	/// de: 'Chance auf mind. 1 Shiny'
	String get shiny_hunt_chance_at_least_one => 'Chance auf mind. 1 Shiny';

	/// de: 'Bisher noch kein Shiny'
	String get shiny_hunt_chance_none_yet => 'Bisher noch kein Shiny';

	/// de: 'Zeitaufwand'
	String get shiny_hunt_time_spent => 'Zeitaufwand';

	/// de: 'Pace'
	String get shiny_hunt_pace_per_hour => 'Pace';

	/// de: 'Encounters/Std.'
	String get shiny_hunt_encounters_per_hour => 'Encounters/Std.';

	/// de: 'Tap-Only Modus (Schloss)'
	String get shiny_hunt_lock_mode_title => 'Tap-Only Modus (Schloss)';

	/// de: 'Sperrt sekundäre Tasten gegen Fehlklicks.'
	String get shiny_hunt_lock_mode_desc => 'Sperrt sekundäre Tasten gegen Fehlklicks.';

	/// de: '✨ Shiny'
	String get shiny_hunt_sprite_toggle_shiny => '✨ Shiny';

	/// de: 'Normal'
	String get shiny_hunt_sprite_toggle_normal => 'Normal';

	/// de: 'Phasen-Shiny'
	String get shiny_hunt_record_phase_btn => 'Phasen-Shiny';

	/// de: '🎉 Shiny gefangen!'
	String get shiny_hunt_caught_btn => '🎉 Shiny gefangen!';

	/// de: 'Counter-Einstellungen'
	String get shiny_hunt_settings_title => 'Counter-Einstellungen';

	/// de: 'Haptisches Feedback'
	String get shiny_hunt_setting_haptics => 'Haptisches Feedback';

	/// de: 'Bildschirm eingeschaltet lassen'
	String get shiny_hunt_setting_wakelock => 'Bildschirm eingeschaltet lassen';

	/// de: 'Tastaturkürzel'
	String get shiny_hunt_shortcuts_title => 'Tastaturkürzel';

	/// de: 'Leertaste / Pfeil oben: + Schrittweite'
	String get shiny_hunt_shortcut_space => 'Leertaste / Pfeil oben: + Schrittweite';

	/// de: 'Pfeil unten / Minus: - Schrittweite'
	String get shiny_hunt_shortcut_down => 'Pfeil unten / Minus: - Schrittweite';

	/// de: 'P: Pause / Fortsetzen'
	String get shiny_hunt_shortcut_pause => 'P: Pause / Fortsetzen';

	/// de: 'Phasen-Chronik'
	String get shiny_hunt_phase_history_title => 'Phasen-Chronik';

	/// de: 'Neuen Shiny Hunt starten'
	String get shiny_hunt_dialog_create_title => 'Neuen Shiny Hunt starten';

	/// de: 'Shiny Hunt bearbeiten'
	String get shiny_hunt_dialog_edit_title => 'Shiny Hunt bearbeiten';

	/// de: 'Ziel-Pokémon'
	String get shiny_hunt_target_pokemon => 'Ziel-Pokémon';

	/// de: 'Titel / Notiz'
	String get shiny_hunt_title_field => 'Titel / Notiz';

	/// de: 'Spiel / Edition'
	String get shiny_hunt_game => 'Spiel / Edition';

	/// de: 'Methode'
	String get shiny_hunt_method => 'Methode';

	/// de: 'Schillerpin aktiv'
	String get shiny_hunt_has_charm => 'Schillerpin aktiv';

	/// de: 'Kette ist bereits vorbereitet (direkt mit Max-Odds zählen)'
	String get shiny_hunt_chain_prepared => 'Kette ist bereits vorbereitet (direkt mit Max-Odds zählen)';

	/// de: 'Basis-Quote (1/D)'
	String get shiny_hunt_base_odds => 'Basis-Quote (1/D)';

	/// de: 'Spawns pro Schritt (k)'
	String get shiny_hunt_spawns_per_step => 'Spawns pro Schritt (k)';

	/// de: 'Eigene Quote'
	String get shiny_hunt_custom_odds => 'Eigene Quote';

	/// de: '🎉 Glückwunsch zum Shiny!'
	String get shiny_hunt_catch_dialog_title => '🎉 Glückwunsch zum Shiny!';

	/// de: 'Verwendeter Pokéball'
	String get shiny_hunt_ball_select => 'Verwendeter Pokéball';

	/// de: 'Als gefangen & Shiny in Dex eintragen'
	String get shiny_hunt_save_to_dex => 'Als gefangen & Shiny in Dex eintragen';

	/// de: 'Ziel-Dex'
	String get shiny_hunt_target_dex => 'Ziel-Dex';

	/// de: 'Notizen (Wesen, DVs, Fangort...)'
	String get shiny_hunt_notes => 'Notizen (Wesen, DVs, Fangort...)';

	/// de: 'Phasen-Shiny protokollieren'
	String get shiny_hunt_phase_dialog_title => 'Phasen-Shiny protokollieren';

	/// de: 'Welches Pokémon ist aufgetaucht?'
	String get shiny_hunt_phase_pokemon_name => 'Welches Pokémon ist aufgetaucht?';

	/// de: 'Phasen-Shiny ebenfalls im Dex eintragen'
	String get shiny_hunt_save_phase_to_dex => 'Phasen-Shiny ebenfalls im Dex eintragen';

	/// de: 'Aktive Shiny Hunts'
	String get shiny_hunt_badge_tooltip => 'Aktive Shiny Hunts';

	/// de: '🎯 Hunt starten'
	String get shiny_hunt_start_from_guide => '🎯 Hunt starten';

	/// de: 'Starten'
	String get start => 'Starten';

	/// de: 'Bestätigen'
	String get confirm => 'Bestätigen';

	/// de: 'Fortsetzen'
	String get shiny_hunt_resume_hunt_btn => 'Fortsetzen';

	/// de: 'Pausieren'
	String get shiny_hunt_pause_hunt_btn => 'Pausieren';

	/// de: '🎯 Hunt starten: Kurioses Ei (14%)'
	String get shiny_hunt_start_odd_egg => '🎯 Hunt starten: Kurioses Ei (14%)';

	/// de: '🎯 Hunt starten: Shiny-Zucht / Ditto-Glitch (1/64)'
	String get shiny_hunt_start_ditto_glitch => '🎯 Hunt starten: Shiny-Zucht / Ditto-Glitch (1/64)';

	/// de: '🎯 Hunt starten: Cute Charm Glitch (21,34%)'
	String get shiny_hunt_start_ccg => '🎯 Hunt starten: Cute Charm Glitch (21,34%)';

	/// de: '🎯 Hunt starten: Starter Soft Reset (k=3)'
	String get shiny_hunt_start_hgss_starters => '🎯 Hunt starten: Starter Soft Reset (k=3)';

	/// de: '🎯 Hunt starten: Silph Scope Reroll'
	String get shiny_hunt_start_silph_scope => '🎯 Hunt starten: Silph Scope Reroll';

	/// de: 'Kein Dex (Nicht verknüpft)'
	String get shiny_hunt_target_dex_none => 'Kein Dex (Nicht verknüpft)';

	/// de: 'Hunts durchsuchen (Pokémon, Spiel, Notiz)...'
	String get shiny_hunt_search_hint => 'Hunts durchsuchen (Pokémon, Spiel, Notiz)...';

	/// de: 'Beenden'
	String get shiny_hunt_finish_btn => 'Beenden';

	/// de: 'Hunt beenden / archivieren'
	String get shiny_hunt_finish_dialog_title => 'Hunt beenden / archivieren';

	/// de: 'Möchtest du diesen Shiny Hunt als gefangen abschließen oder ohne Fang archivieren?'
	String get shiny_hunt_finish_dialog_desc => 'Möchtest du diesen Shiny Hunt als gefangen abschließen oder ohne Fang archivieren?';

	/// de: '🎉 Als Shiny gefangen abschließen'
	String get shiny_hunt_finish_as_caught => '🎉 Als Shiny gefangen abschließen';

	/// de: 'Ohne Fang archivieren'
	String get shiny_hunt_finish_archive_only => 'Ohne Fang archivieren';

	/// de: 'Dieser Shiny Hunt ist abgeschlossen und im Archiv.'
	String get shiny_hunt_completed_banner => 'Dieser Shiny Hunt ist abgeschlossen und im Archiv.';

	/// de: 'Hunt wieder aufnehmen'
	String get shiny_hunt_reopen_btn => 'Hunt wieder aufnehmen';

	/// de: 'Zurück zur Übersicht'
	String get shiny_hunt_back_to_hub => 'Zurück zur Übersicht';

	/// de: 'Matching Ball'
	String get shiny_hunt_matching_ball_badge => 'Matching Ball';

	/// de: 'In "{dexTitle}" als gefangen & Shiny markieren'
	String get shiny_hunt_sync_to_target_dex => 'In "{dexTitle}" als gefangen & Shiny markieren';

	/// de: 'Shiny Hunts'
	String get shiny_hunt_pokemon_card_title => 'Shiny Hunts';

	/// de: 'Keine aktiven Hunts für dieses Pokémon.'
	String get shiny_hunt_no_hunts_for_pokemon => 'Keine aktiven Hunts für dieses Pokémon.';

	/// de: '🎯 Neuen Shiny Hunt starten'
	String get shiny_hunt_start_new_for_pokemon => '🎯 Neuen Shiny Hunt starten';

	/// de: 'Phasen-Shinies'
	String get shiny_hunt_phase_history_card_title => 'Phasen-Shinies';

	/// de: 'Phase {phase}: {name} ({encounters})'
	String get shiny_hunt_phase_badge => 'Phase {phase}: {name} ({encounters})';

	/// de: 'Keine Shiny Hunts gefunden für "{query}".'
	String get shiny_hunt_search_no_results => 'Keine Shiny Hunts gefunden für "{query}".';

	/// de: 'Custom'
	String get shiny_hunt_step_custom => 'Custom';

	/// de: 'Eigene Schrittweite'
	String get shiny_hunt_step_custom_title => 'Eigene Schrittweite';

	/// de: 'Schrittweite eingeben (z. B. 3, 30)...'
	String get shiny_hunt_step_custom_hint => 'Schrittweite eingeben (z. B. 3, 30)...';

	/// de: 'Jagdart / Herkunft'
	String get shiny_hunt_hunting_type => 'Jagdart / Herkunft';

	/// de: 'Automatisch (nach Methode)'
	String get shiny_hunt_type_auto => 'Automatisch (nach Methode)';

	/// de: 'Wildfang'
	String get shiny_hunt_type_wild => 'Wildfang';

	/// de: 'Zucht / Ei'
	String get shiny_hunt_type_breeding => 'Zucht / Ei';

	/// de: 'Tausch'
	String get shiny_hunt_type_trade => 'Tausch';

	/// de: 'Soft Reset'
	String get shiny_hunt_type_soft_reset => 'Soft Reset';

	/// de: 'Raid'
	String get shiny_hunt_type_raid => 'Raid';

	/// de: 'Fossil'
	String get shiny_hunt_type_fossil => 'Fossil';

	/// de: 'Geschenk / Event'
	String get shiny_hunt_type_gift => 'Geschenk / Event';

	/// de: 'Sonstiges'
	String get shiny_hunt_type_other => 'Sonstiges';

	/// de: 'Hunt wurde wieder aktiviert!'
	String get shiny_hunt_reopened_toast => 'Hunt wurde wieder aktiviert!';

	/// de: 'Gefangen am {date}'
	String get shiny_hunt_caught_on => 'Gefangen am {date}';

	/// de: 'Archiviert am {date}'
	String get shiny_hunt_archived_on => 'Archiviert am {date}';

	/// de: 'Fang-Details'
	String get shiny_hunt_catch_details_title => 'Fang-Details';

	/// de: 'Schillerpin'
	String get shiny_hunt_charm_badge => 'Schillerpin';

	/// de: 'Form'
	String get shiny_hunt_form_label => 'Form';

	/// de: 'Bedienung & Tastaturkürzel'
	String get controls_guide_title => 'Bedienung & Tastaturkürzel';

	/// de: 'Shortcuts, Maus- & Touch-Gesten'
	String get controls_guide_sub => 'Shortcuts, Maus- & Touch-Gesten';

	/// de: 'Desktop & Web'
	String get controls_tab_desktop => 'Desktop & Web';

	/// de: 'Touch & Mobil'
	String get controls_tab_mobile => 'Touch & Mobil';

	/// de: 'Übersicht über alle Tastatur- und Mauskürzel für Desktop und Web.'
	String get controls_platform_hint_desktop => 'Übersicht über alle Tastatur- und Mauskürzel für Desktop und Web.';

	/// de: 'Übersicht über alle Touch-, Wisch- und Longpress-Gesten für Mobilgeräte.'
	String get controls_platform_hint_mobile => 'Übersicht über alle Touch-, Wisch- und Longpress-Gesten für Mobilgeräte.';

	/// de: 'Allgemein & Navigation'
	String get controls_cat_general => 'Allgemein & Navigation';

	/// de: 'Pokédex (PC-Box & Liste)'
	String get controls_cat_dex => 'Pokédex (PC-Box & Liste)';

	/// de: 'Hauptmenü (Home Screen)'
	String get controls_cat_home => 'Hauptmenü (Home Screen)';

	/// de: 'Shiny Hunt Counter'
	String get controls_cat_shiny_hunt => 'Shiny Hunt Counter';

	/// de: 'Bänder & Zeichen'
	String get controls_cat_ribbons_marks => 'Bänder & Zeichen';

	/// de: 'Fähigkeiten & Attacken'
	String get controls_cat_abilities_moves => 'Fähigkeiten & Attacken';

	/// de: 'Backspace / Browser Back'
	String get controls_nav_back_key => 'Backspace / Browser Back';

	/// de: 'Zur vorherigen Ansicht zurückkehren oder Ordner schließen'
	String get controls_nav_back_desc => 'Zur vorherigen Ansicht zurückkehren oder Ordner schließen';

	/// de: 'System-Zurück-Geste'
	String get controls_nav_back_gesture => 'System-Zurück-Geste';

	/// de: 'Vom Bildschirmrand wischen oder Android-Zurücktaste'
	String get controls_nav_back_gesture_desc => 'Vom Bildschirmrand wischen oder Android-Zurücktaste';

	/// de: 'Klick / Tippen auf Ordner'
	String get controls_folder_nav => 'Klick / Tippen auf Ordner';

	/// de: 'Ordner öffnen oder im Ordner navigieren'
	String get controls_folder_nav_desc => 'Ordner öffnen oder im Ordner navigieren';

	/// de: 'Linksklick'
	String get controls_dex_toggle_click => 'Linksklick';

	/// de: 'Einfaches Antippen'
	String get controls_dex_toggle_tap => 'Einfaches Antippen';

	/// de: 'Status Gefangen/Fehlt umschalten oder leeren Platzhalter belegen'
	String get controls_dex_toggle_desc => 'Status Gefangen/Fehlt umschalten oder leeren Platzhalter belegen';

	/// de: 'Rechtsklick'
	String get controls_dex_details_click => 'Rechtsklick';

	/// de: 'Langer Druck (Longpress)'
	String get controls_dex_details_longpress => 'Langer Druck (Longpress)';

	/// de: 'Detail- und Informationsseite des Pokémon öffnen'
	String get controls_dex_details_desc => 'Detail- und Informationsseite des Pokémon öffnen';

	/// de: 'Taste I / Strg + Enter'
	String get controls_dex_details_key => 'Taste I / Strg + Enter';

	/// de: 'Pokémon-Details bei Tastaturfokus öffnen'
	String get controls_dex_details_key_desc => 'Pokémon-Details bei Tastaturfokus öffnen';

	/// de: 'Maus Drag & Drop'
	String get controls_dex_drag_desktop => 'Maus Drag & Drop';

	/// de: 'Langer Druck + Ziehen'
	String get controls_dex_drag_mobile => 'Langer Druck + Ziehen';

	/// de: 'Pokémon innerhalb oder zwischen Boxen verschieben / tauschen'
	String get controls_dex_drag_desc => 'Pokémon innerhalb oder zwischen Boxen verschieben / tauschen';

	/// de: 'Mehrfachauswahl (Edit-Modus)'
	String get controls_dex_multiselect => 'Mehrfachauswahl (Edit-Modus)';

	/// de: 'Tippen im Bearbeiten-Modus, um mehrere Pokémon zu markieren'
	String get controls_dex_multiselect_desc => 'Tippen im Bearbeiten-Modus, um mehrere Pokémon zu markieren';

	/// de: 'Reorder-Handle (Ziehen)'
	String get controls_home_reorder => 'Reorder-Handle (Ziehen)';

	/// de: 'Dexe und Ordner bei manueller Sortierung frei anordnen'
	String get controls_home_reorder_desc => 'Dexe und Ordner bei manueller Sortierung frei anordnen';

	/// de: 'Langer Druck (Longpress)'
	String get controls_home_multiselect => 'Langer Druck (Longpress)';

	/// de: 'Auswahlmodus aktivieren (Mehrfachauswahl für Verschieben & Löschen)'
	String get controls_home_multiselect_desc => 'Auswahlmodus aktivieren (Mehrfachauswahl für Verschieben & Löschen)';

	/// de: 'Dreipunkt-Menü (⋮)'
	String get controls_home_menu => 'Dreipunkt-Menü (⋮)';

	/// de: 'Schnellmenü für Umbenennen, Verschieben, Exportieren & Löschen'
	String get controls_home_menu_desc => 'Schnellmenü für Umbenennen, Verschieben, Exportieren & Löschen';

	/// de: 'Leertaste / Pfeil Oben (↑)'
	String get controls_hunt_inc_key => 'Leertaste / Pfeil Oben (↑)';

	/// de: 'Große Zählerfläche tippen'
	String get controls_hunt_inc_touch => 'Große Zählerfläche tippen';

	/// de: '+1 Begegnung'
	String get controls_hunt_inc_title => '+1 Begegnung';

	/// de: 'Zähler um 1 (oder eingestellte Schrittweite) erhöhen'
	String get controls_hunt_inc_desc => 'Zähler um 1 (oder eingestellte Schrittweite) erhöhen';

	/// de: 'Pfeil Unten (↓) / Minus (-)'
	String get controls_hunt_dec_key => 'Pfeil Unten (↓) / Minus (-)';

	/// de: 'Minus-Button (-)'
	String get controls_hunt_dec_touch => 'Minus-Button (-)';

	/// de: '-1 Begegnung'
	String get controls_hunt_dec_title => '-1 Begegnung';

	/// de: 'Zähler um 1 verringern (Fehlzählung korrigieren)'
	String get controls_hunt_dec_desc => 'Zähler um 1 verringern (Fehlzählung korrigieren)';

	/// de: 'Taste P'
	String get controls_hunt_pause_key => 'Taste P';

	/// de: 'Pause-Button (⏸)'
	String get controls_hunt_pause_touch => 'Pause-Button (⏸)';

	/// de: 'Pause / Fortsetzen'
	String get controls_hunt_pause_title => 'Pause / Fortsetzen';

	/// de: 'Jagd-Timer pausieren oder fortsetzen'
	String get controls_hunt_pause_desc => 'Jagd-Timer pausieren oder fortsetzen';

	/// de: 'Schloss-Symbol (Tap-Only)'
	String get controls_hunt_lock => 'Schloss-Symbol (Tap-Only)';

	/// de: 'Fehlklickschutz: Sperrt Tasten und verhindert versehentliche Zählungen'
	String get controls_hunt_lock_desc => 'Fehlklickschutz: Sperrt Tasten und verhindert versehentliche Zählungen';

	/// de: 'Linksklick / Antippen'
	String get controls_ribbon_toggle_click => 'Linksklick / Antippen';

	/// de: 'Band oder Zeichen als erhalten oder nicht erhalten markieren'
	String get controls_ribbon_toggle_desc => 'Band oder Zeichen als erhalten oder nicht erhalten markieren';

	/// de: 'Rechtsklick / Langer Druck'
	String get controls_ribbon_details_click => 'Rechtsklick / Langer Druck';

	/// de: 'Detailinformationen, Beschreibung und Fundort anzeigen'
	String get controls_ribbon_details_desc => 'Detailinformationen, Beschreibung und Fundort anzeigen';

	/// de: 'Linksklick / Antippen'
	String get controls_ability_toggle_click => 'Linksklick / Antippen';

	/// de: 'Status (z. B. Beherrscht / Gesehen) umschalten'
	String get controls_ability_toggle_desc => 'Status (z. B. Beherrscht / Gesehen) umschalten';

	/// de: 'Rechtsklick / Langer Druck'
	String get controls_ability_details_click => 'Rechtsklick / Langer Druck';

	/// de: 'Detailansicht der Fähigkeit oder Attacke öffnen'
	String get controls_ability_details_desc => 'Detailansicht der Fähigkeit oder Attacke öffnen';

	/// de: 'Geschlechtsunterschiede'
	String get gender_differences_title => 'Geschlechtsunterschiede';

	/// de: 'Optische Unterschiede zwischen den Geschlechtern'
	String get gender_differences_subtitle => 'Optische Unterschiede zwischen den Geschlechtern';

	/// de: 'Hinweis'
	String get gender_differences_note => 'Hinweis';

	/// de: 'Lade Geschlechtsunterschiede...'
	String get gender_differences_loading => 'Lade Geschlechtsunterschiede...';

	/// de: 'Erfolgs-Grafik teilen...'
	String get share_dex_card => 'Erfolgs-Grafik teilen...';

	/// de: 'Erfolgs-Grafik'
	String get share_dex_card_btn => 'Erfolgs-Grafik';

	/// de: 'Erfolgs-Grafik (Living Dex)'
	String get dex_card_title => 'Erfolgs-Grafik (Living Dex)';

	/// de: 'The Analyst (Infografik)'
	String get dex_card_style_analyst => 'The Analyst (Infografik)';

	/// de: 'Trainer-Zertifikat'
	String get dex_card_style_certificate => 'Trainer-Zertifikat';

	/// de: 'Living Dex Mosaik'
	String get dex_card_style_mosaic => 'Living Dex Mosaik';

	/// de: 'Minimalist Glass'
	String get dex_card_style_minimalist => 'Minimalist Glass';

	/// de: '16:9 Querformat'
	String get dex_card_ratio_16_9 => '16:9 Querformat';

	/// de: '1:1 Quadrat'
	String get dex_card_ratio_1_1 => '1:1 Quadrat';

	/// de: '9:16 Story'
	String get dex_card_ratio_9_16 => '9:16 Story';

	/// de: 'Hintergrund-Wasserzeichen'
	String get dex_card_watermark => 'Hintergrund-Wasserzeichen';

	/// de: 'Deckkraft'
	String get dex_card_opacity => 'Deckkraft';

	/// de: 'Kein Pokémon (Nur Statistiken)'
	String get dex_card_no_pokemon => 'Kein Pokémon (Nur Statistiken)';

	/// de: 'Als PNG speichern'
	String get dex_card_save_png => 'Als PNG speichern';

	/// de: 'Teilen'
	String get dex_card_share => 'Teilen';

	/// de: 'Text kopieren'
	String get dex_card_copy_text => 'Text kopieren';

	/// de: 'Nur angefangene Generationen'
	String get dex_card_only_started_gens => 'Nur angefangene Generationen';

	/// de: 'Generationen ohne gefangene Pokémon ausblenden'
	String get dex_card_only_started_gens_sub => 'Generationen ohne gefangene Pokémon ausblenden';

	/// de: 'Typen-Anzeige'
	String get dex_card_type_limit => 'Typen-Anzeige';

	/// de: 'Top 6'
	String get dex_card_types_top6 => 'Top 6';

	/// de: 'Top 12'
	String get dex_card_types_top12 => 'Top 12';

	/// de: 'Alle 18'
	String get dex_card_types_all18 => 'Alle 18';

	/// de: 'Erfolgs-Text in die Zwischenablage kopiert!'
	String get dex_card_copy_success => 'Erfolgs-Text in die Zwischenablage kopiert!';

	/// de: 'Erfolgs-Grafik gespeichert:'
	String get dex_card_save_success => 'Erfolgs-Grafik gespeichert:';

	/// de: 'Gemeistert'
	String get dex_card_mastered => 'Gemeistert';

	/// de: 'In Arbeit'
	String get dex_card_in_progress => 'In Arbeit';

	/// de: 'Offizielles Pokédex-Diplom'
	String get dex_card_diploma_title => 'Offizielles Pokédex-Diplom';

	/// de: 'Verliehen für lückenlose Sammlung und Meisterschaft'
	String get dex_card_diploma_sub => 'Verliehen für lückenlose Sammlung und Meisterschaft';

	/// de: 'Champion-Siegel'
	String get dex_card_champion_seal => 'Champion-Siegel';

	/// de: 'Registriert in PokéVault'
	String get dex_card_registered_pkv => 'Registriert in PokéVault';

	/// de: 'Geprüft durch Spielstand-Inspektion'
	String get dex_card_verified => 'Geprüft durch Spielstand-Inspektion';

	/// de: 'Living-Dex-Übersichtsraster'
	String get dex_card_mosaic_grid => 'Living-Dex-Übersichtsraster';

	/// de: 'Fehlend'
	String get dex_card_missing => 'Fehlend';

	/// de: 'PC-Boxen'
	String get dex_card_boxes_count => 'PC-Boxen';

	/// de: 'Strukturiert archiviert'
	String get dex_card_boxes_archived => 'Strukturiert archiviert';

	/// de: 'Lücken verbleibend'
	String get dex_card_remaining => 'Lücken verbleibend';

	/// de: 'Stern-Rang'
	String get dex_card_star_rank => 'Stern-Rang';

	/// de: 'Meisterschaft'
	String get dex_card_mastery => 'Meisterschaft';

	/// de: 'Perfekte Ordnung'
	String get dex_card_perfect_order => 'Perfekte Ordnung';

	/// de: 'Alphas'
	String get alphas_count => 'Alphas';

	/// de: 'Schließen'
	String get dex_progress_close => 'Schließen';

	/// de: 'Generationen'
	String get dex_progress_generations => 'Generationen';

	/// de: 'Gesamtfortschritt'
	String get dex_progress_overall => 'Gesamtfortschritt';

	/// de: 'Alle anzeigen'
	String get dex_progress_show_all => 'Alle anzeigen';

	/// de: 'Nur Gefangene anzeigen'
	String get dex_progress_show_caught => 'Nur Gefangene anzeigen';

	/// de: 'Nur Fehlende anzeigen'
	String get dex_progress_show_missing => 'Nur Fehlende anzeigen';

	/// de: 'Gesamt-Übersicht'
	String get dex_progress_subtitle_overview => 'Gesamt-Übersicht';

	/// de: 'Dex-Fortschritt & Statistiken'
	String get dex_progress_title => 'Dex-Fortschritt & Statistiken';

	/// de: 'Fortschritt & Statistiken anzeigen'
	String get dex_progress_tooltip => 'Fortschritt & Statistiken anzeigen';

	/// de: 'Typen'
	String get dex_progress_types => 'Typen';

	/// de: 'Varianten & Formen'
	String get dex_progress_variants => 'Varianten & Formen';

	/// de: 'Kein Pokémon'
	String get no_pokemon_card => 'Kein Pokémon';

	/// de: 'Wasserzeichen deaktiviert'
	String get no_watermark_sub => 'Wasserzeichen deaktiviert';

	/// de: 'Pokémon auswählen'
	String get select_pokemon => 'Pokémon auswählen';

	/// de: 'Shinies'
	String get shinies_count => 'Shinies';

	/// de: 'Öffne deinen Dex, um das erweiterte Boxen-System, Geschlechter-Varianten und den Fangraten-Rechner zu nutzen!'
	String get tutorial_v16_tour_dex_text => 'Öffne deinen Dex, um das erweiterte Boxen-System, Geschlechter-Varianten und den Fangraten-Rechner zu nutzen!';

	/// de: 'v1.6: Neue Features in deinen Dexen'
	String get tutorial_v16_tour_dex_title => 'v1.6: Neue Features in deinen Dexen';

	/// de: 'Erstelle einen neuen Dex, um die neuen Optionen wie Geschlechtsformen und Mega-Evolutionen auszuprobieren!'
	String get tutorial_v16_tour_fab_text => 'Erstelle einen neuen Dex, um die neuen Optionen wie Geschlechtsformen und Mega-Evolutionen auszuprobieren!';

	/// de: 'v1.6: Neuen Dex erstellen'
	String get tutorial_v16_tour_fab_title => 'v1.6: Neuen Dex erstellen';

	/// de: 'Tippe hier, um deine Shiny Hunts mit Begegnungszähler, Phasen und Fangwahrscheinlichkeiten zu tracken!'
	String get tutorial_v16_tour_shiny_text => 'Tippe hier, um deine Shiny Hunts mit Begegnungszähler, Phasen und Fangwahrscheinlichkeiten zu tracken!';

	/// de: 'v1.6: Shiny Hunt Tracker'
	String get tutorial_v16_tour_shiny_title => 'v1.6: Shiny Hunt Tracker';

	/// de: 'Alpha-Pokémon'
	String get variant_alpha => 'Alpha-Pokémon';

	/// de: 'Gigadynamax'
	String get variant_gmax => 'Gigadynamax';

	/// de: 'Mega-Entwicklungen'
	String get variant_mega => 'Mega-Entwicklungen';

	/// de: 'Regionalformen'
	String get variant_regional => 'Regionalformen';

	/// de: 'Reguläre Formen'
	String get variant_regular => 'Reguläre Formen';

	/// de: 'Shinies'
	String get variant_shinies => 'Shinies';

	/// de: 'Schnellaktionen'
	String get actions => 'Schnellaktionen';

	/// de: 'Aktiv'
	String get active => 'Aktiv';

	/// de: 'Hinzufügen'
	String get add_pokemon => 'Hinzufügen';

	/// de: 'Als Alpha markieren'
	String get alpha_status_sub => 'Als Alpha markieren';

	/// de: 'Suche zurücksetzen'
	String get clear => 'Suche zurücksetzen';

	/// de: 'Fang-Details'
	String get details => 'Fang-Details';

	/// de: 'Möchtest du diesen Pokédex wirklich löschen?'
	String get dex_delete_text => 'Möchtest du diesen Pokédex wirklich löschen?';

	/// de: 'Pokédex löschen'
	String get dex_delete_title => 'Pokédex löschen';

	/// de: 'Formen & Varianten'
	String get dex_progress_forms => 'Formen & Varianten';

	/// de: 'Ordnernavigation'
	String get folder => 'Ordnernavigation';

	/// de: 'Fehlklickschutz'
	String get lock => 'Fehlklickschutz';

	/// de: 'Als schillernd markieren'
	String get mark_as_shiny => 'Als schillernd markieren';

	/// de: 'Matching Ball (Normal)'
	String get matching_ball_normal => 'Matching Ball (Normal)';

	/// de: 'Matching Ball (Shiny)'
	String get matching_ball_shiny => 'Matching Ball (Shiny)';

	/// de: 'Verschieben & Tauschen'
	String get move_pokemon => 'Verschieben & Tauschen';

	/// de: 'Keine Einträge'
	String get no_results => 'Keine Einträge';

	/// de: 'Notizen'
	String get notes => 'Notizen';

	/// de: 'Zurück'
	String get previous => 'Zurück';

	/// de: 'Möchtest du dieses Pokémon nur aus dieser Box entfernen oder komplett aus dem Pokédex ausblenden?'
	String get remove_from_box_desc => 'Möchtest du dieses Pokémon nur aus dieser Box entfernen oder komplett aus dem Pokédex ausblenden?';

	/// de: 'Nur aus Box'
	String get remove_from_box_only => 'Nur aus Box';

	/// de: 'Pokémon entfernen'
	String get remove_from_box_title => 'Pokémon entfernen';

	/// de: 'Zurücksetzen'
	String get reset => 'Zurücksetzen';

	/// de: 'Aktiver Hunt: Encounters'
	String get shiny_hunt_active => 'Aktiver Hunt: Encounters';

	/// de: 'Noch nicht abgeschlossen'
	String get shiny_hunt_active_desc => 'Noch nicht abgeschlossen';

	/// de: 'Hunt beendet / archiviert'
	String get shiny_hunt_completed_at => 'Hunt beendet / archiviert';

	/// de: 'Beendet'
	String get shiny_hunt_completed_status => 'Beendet';

	/// de: '< 1 Min.'
	String get shiny_hunt_duration_under_minute => '< 1 Min.';

	/// de: 'Gesamtdauer'
	String get shiny_hunt_gross_duration => 'Gesamtdauer';

	/// de: 'Jagdzeit (Netto)'
	String get shiny_hunt_net_time => 'Jagdzeit (Netto)';

	/// de: 'Keine Pausen aufgezeichnet'
	String get shiny_hunt_no_pauses => 'Keine Pausen aufgezeichnet';

	/// de: 'Pause'
	String get shiny_hunt_pause_label => 'Pause';

	/// de: 'aktiv pausiert'
	String get shiny_hunt_pause_ongoing => 'aktiv pausiert';

	/// de: 'Pausen (Summe)'
	String get shiny_hunt_pause_total => 'Pausen (Summe)';

	/// de: 'Pausiert'
	String get shiny_hunt_paused => 'Pausiert';

	/// de: 'Pausiert seit'
	String get shiny_hunt_paused_since => 'Pausiert seit';

	/// de: 'Pausen'
	String get shiny_hunt_pauses_label => 'Pausen';

	/// de: 'Start'
	String get shiny_hunt_started => 'Start';

	/// de: 'Hunt gestartet'
	String get shiny_hunt_started_at => 'Hunt gestartet';

	/// de: 'Gestartet'
	String get shiny_hunt_started_label => 'Gestartet';

	/// de: 'Hunt läuft aktiv'
	String get shiny_hunt_status_active => 'Hunt läuft aktiv';

	/// de: 'Aktuell pausiert'
	String get shiny_hunt_status_currently_paused => 'Aktuell pausiert';

	/// de: 'Zeiten'
	String get shiny_hunt_timeline_btn => 'Zeiten';

	/// de: 'Zeiten & Pausen'
	String get shiny_hunt_timeline_chip => 'Zeiten & Pausen';

	/// de: 'Ablauf & Intervalle'
	String get shiny_hunt_timeline_events => 'Ablauf & Intervalle';

	/// de: 'Timeline & Pausen'
	String get shiny_hunt_timeline_title => 'Timeline & Pausen';

	/// de: 'Manuelle Sortierung'
	String get sort => 'Manuelle Sortierung';

	/// de: 'Info'
	String get special_info => 'Info';

	/// de: 'Status ändern'
	String get status => 'Status ändern';

	/// de: 'Klick direkt auf den markierten Bereich!'
	String get tutorial_wrong_tap => 'Klick direkt auf den markierten Bereich!';

	/// de: 'Unbekannt'
	String get unknown => 'Unbekannt';

	/// de: 'Meiste Gefangen'
	String get sort_most_caught => 'Meiste Gefangen';

	/// de: 'Nach Region'
	String get sort_by_region => 'Nach Region';

	/// de: 'Verschieben'
	String get move_tooltip => 'Verschieben';

	/// de: 'Löschen'
	String get delete_tooltip => 'Löschen';

	/// de: 'Keine Dexe zum Exportieren in der Auswahl gefunden.'
	String get no_dexes_to_export => 'Keine Dexe zum Exportieren in der Auswahl gefunden.';

	/// de: 'Bearbeiten'
	String get menu_edit => 'Bearbeiten';

	/// de: 'Verschieben...'
	String get menu_move => 'Verschieben...';

	/// de: 'Löschen'
	String get menu_delete => 'Löschen';

	/// de: 'Boxen zurücksetzen?'
	String get reset_boxes_title => 'Boxen zurücksetzen?';

	/// de: 'Möchtest du alle deine benutzerdefinierten Boxen löschen und das Layout auf den Standard-Pokédex zurücksetzen? Deine gefangenen Pokémon bleiben dabei erhalten!'
	String get reset_boxes_content => 'Möchtest du alle deine benutzerdefinierten Boxen löschen und das Layout auf den Standard-Pokédex zurücksetzen? Deine gefangenen Pokémon bleiben dabei erhalten!';

	/// de: 'Zurücksetzen'
	String get reset_boxes_action => 'Zurücksetzen';

	/// de: 'Auf Standard zurücksetzen'
	String get reset_boxes_tooltip => 'Auf Standard zurücksetzen';

	/// de: 'Gen 1 (Rot/Blau/Gelb)'
	String get calc_gen_1 => 'Gen 1 (Rot/Blau/Gelb)';

	/// de: 'Gen 2 (Gold/Silber/Kristall)'
	String get calc_gen_2 => 'Gen 2 (Gold/Silber/Kristall)';

	/// de: 'Gen 3 & 4 (R/S/S/D/P/P)'
	String get calc_gen_3_4 => 'Gen 3 & 4 (R/S/S/D/P/P)';

	/// de: 'Gen 5 (Schwarz/Weiß 1&2)'
	String get calc_gen_5 => 'Gen 5 (Schwarz/Weiß 1&2)';

	/// de: 'Gen 6 & 7 (X/Y/S/M)'
	String get calc_gen_6_7 => 'Gen 6 & 7 (X/Y/S/M)';

	/// de: 'Gen 7.5 (Let's Go)'
	String get calc_gen_7_5 => 'Gen 7.5 (Let\'s Go)';

	/// de: 'Gen 8 (Schwert/Schild)'
	String get calc_gen_8 => 'Gen 8 (Schwert/Schild)';

	/// de: 'Gen 8.5 (Legenden: Arceus)'
	String get calc_gen_8_5 => 'Gen 8.5 (Legenden: Arceus)';

	/// de: 'Gen 9 (Karmesin/Purpur)'
	String get calc_gen_9 => 'Gen 9 (Karmesin/Purpur)';

	/// de: 'Gen 9.5 (Legenden: Z-A)'
	String get calc_gen_9_5 => 'Gen 9.5 (Legenden: Z-A)';

	/// de: '< 30 gefangen (0.0x)'
	String get calc_mult_under_30 => '< 30 gefangen (0.0x)';

	/// de: '30+ gefangen (0.5x)'
	String get calc_mult_30_plus => '30+ gefangen (0.5x)';

	/// de: '150+ gefangen (1.0x)'
	String get calc_mult_150_plus => '150+ gefangen (1.0x)';

	/// de: '300+ gefangen (1.5x)'
	String get calc_mult_300_plus => '300+ gefangen (1.5x)';

	/// de: '450+ gefangen (2.0x)'
	String get calc_mult_450_plus => '450+ gefangen (2.0x)';

	/// de: '600+ gefangen (2.5x)'
	String get calc_mult_600_plus => '600+ gefangen (2.5x)';

	/// de: 'Keine älteren Versionen gefunden.'
	String get no_older_versions => 'Keine älteren Versionen gefunden.';

	/// de: 'Bitte ein Pokémon auswählen'
	String get select_pokemon_warning => 'Bitte ein Pokémon auswählen';

	/// de: 'Bitte logge dich zuerst ein!'
	String get please_login_first => 'Bitte logge dich zuerst ein!';

	/// de: 'Spiel: {game} (Gen {gen})'
	String get hunt_game_label => 'Spiel: {game} (Gen {gen})';

	/// de: 'Ändern'
	String get change_btn => 'Ändern';

	/// de: 'Erfolgreich verschoben.'
	String get moved_successfully => 'Erfolgreich verschoben.';

	/// de: 'Erfolgreich gelöscht.'
	String get deleted_successfully => 'Erfolgreich gelöscht.';

	/// de: 'Elemente gelöscht.'
	String get items_deleted => 'Elemente gelöscht.';

	/// de: 'Neuen Pokédex erstellen'
	String get create_new_pokedex => 'Neuen Pokédex erstellen';

	/// de: '11. Kamera- & Foto-Scanner'
	String get tutorial_chapter_scanner_mobile_title => '11. Kamera- & Foto-Scanner';

	/// de: 'Live-Kamera-OCR, Tap-to-Focus, Scan-Zonen, Foto-Import & In-App Mini-PiP.'
	String get tutorial_chapter_scanner_mobile_desc => 'Live-Kamera-OCR, Tap-to-Focus, Scan-Zonen, Foto-Import & In-App Mini-PiP.';

	/// de: '11. Overlay-, Fenster- & Kamera-Scanner'
	String get tutorial_chapter_scanner_desktop_title => '11. Overlay-, Fenster- & Kamera-Scanner';

	/// de: 'Fenster-/Snipping-Capture, Always-on-Top Mini-HUD, Multi-Instanzen, Webcam & Foto-OCR.'
	String get tutorial_chapter_scanner_desktop_desc => 'Fenster-/Snipping-Capture, Always-on-Top Mini-HUD, Multi-Instanzen, Webcam & Foto-OCR.';

	/// de: 'Live-Kamera & Tap-to-Focus'
	String get tutorial_scanner_mob_camera_title => 'Live-Kamera & Tap-to-Focus';

	/// de: 'Richte dein Handy auf Switch, 3DS oder TV. Tippe direkt ins Kamerabild (auch im Auto-Modus), um den Fokus scharfzustellen.'
	String get tutorial_scanner_mob_camera_text => 'Richte dein Handy auf Switch, 3DS oder TV. Tippe direkt ins Kamerabild (auch im Auto-Modus), um den Fokus scharfzustellen.';

	/// de: 'Auto vs. Vierecke (Zonen)'
	String get tutorial_scanner_mob_modes_title => 'Auto vs. Vierecke (Zonen)';

	/// de: 'Nutze Auto für das ganze Bild oder zeichne exakte Rechtecke für Zone A (Textbox), Zone B (Fokus) und Multi-Instanzen.'
	String get tutorial_scanner_mob_modes_text => 'Nutze Auto für das ganze Bild oder zeichne exakte Rechtecke für Zone A (Textbox), Zone B (Fokus) und Multi-Instanzen.';

	/// de: 'Foto- & Screenshot-Import'
	String get tutorial_scanner_mob_photo_title => 'Foto- & Screenshot-Import';

	/// de: 'Alternativ kannst du jederzeit Fotos oder Screenshots aus deiner Galerie laden und einmalig scannen lassen.'
	String get tutorial_scanner_mob_photo_text => 'Alternativ kannst du jederzeit Fotos oder Screenshots aus deiner Galerie laden und einmalig scannen lassen.';

	/// de: 'Split-Screen & Mini-PiP'
	String get tutorial_scanner_mob_pip_title => 'Split-Screen & Mini-PiP';

	/// de: 'Wechsle zwischen Vollbild, Split-Tabs oder dem beweglichen Mini-Fenster (PiP), während du in deinen Dexen stöberst.'
	String get tutorial_scanner_mob_pip_text => 'Wechsle zwischen Vollbild, Split-Tabs oder dem beweglichen Mini-Fenster (PiP), während du in deinen Dexen stöberst.';

	/// de: 'Ziel-Dex, Entwicklung & Diagnose'
	String get tutorial_scanner_mob_dex_title => 'Ziel-Dex, Entwicklung & Diagnose';

	/// de: 'Wähle deinen Ziel-Dex, prüfe fehlende Entwicklungen im Fokus-Tab und kontrolliere Live-OCR-Logs im Diagnose-Tab.'
	String get tutorial_scanner_mob_dex_text => 'Wähle deinen Ziel-Dex, prüfe fehlende Entwicklungen im Fokus-Tab und kontrolliere Live-OCR-Logs im Diagnose-Tab.';

	/// de: 'Spiel-Fenster oder Webcam wählen'
	String get tutorial_scanner_desk_source_title => 'Spiel-Fenster oder Webcam wählen';

	/// de: 'Wähle ein laufendes Emulator-/Spiel-Fenster, einen Monitor oder deine USB-Webcam bzw. Capture-Card als Live-Quelle.'
	String get tutorial_scanner_desk_source_text => 'Wähle ein laufendes Emulator-/Spiel-Fenster, einen Monitor oder deine USB-Webcam bzw. Capture-Card als Live-Quelle.';

	/// de: 'Snipping & Zonen (A / B / Multi)'
	String get tutorial_scanner_desk_zones_title => 'Snipping & Zonen (A / B / Multi)';

	/// de: 'Markiere Zone A für Fang-Dialoge, Zone B für Live-Fokus oder lege mehrere Instanzen für paralleles Shiny-Hunting an.'
	String get tutorial_scanner_desk_zones_text => 'Markiere Zone A für Fang-Dialoge, Zone B für Live-Fokus oder lege mehrere Instanzen für paralleles Shiny-Hunting an.';

	/// de: 'Always-on-Top Floating HUD'
	String get tutorial_scanner_desk_hud_title => 'Always-on-Top Floating HUD';

	/// de: 'Öffne das schwebende Mini-HUD direkt über deinem Spiel, um Treffer und fehlende Entwicklungen mit einem Klick abzuhaken.'
	String get tutorial_scanner_desk_hud_text => 'Öffne das schwebende Mini-HUD direkt über deinem Spiel, um Treffer und fehlende Entwicklungen mit einem Klick abzuhaken.';

	/// de: 'Ziel-Dex & Live-Fokus'
	String get tutorial_scanner_desk_focus_title => 'Ziel-Dex & Live-Fokus';

	/// de: 'Prüfe sofort, ob das erkannte Pokémon in deinem Ziel-Dex fehlt oder noch Entwicklungen offen sind.'
	String get tutorial_scanner_desk_focus_text => 'Prüfe sofort, ob das erkannte Pokémon in deinem Ziel-Dex fehlt oder noch Entwicklungen offen sind.';

	/// de: '9 Spielsprachen & Eigene Muster'
	String get tutorial_scanner_desk_ocr_title => '9 Spielsprachen & Eigene Muster';

	/// de: 'Stelle die passende Spielsprache (DE/EN/FR/ES/IT/JA/KO/ZH) ein und ergänze bei Bedarf eigene Textmuster.'
	String get tutorial_scanner_desk_ocr_text => 'Stelle die passende Spielsprache (DE/EN/FR/ES/IT/JA/KO/ZH) ein und ergänze bei Bedarf eigene Textmuster.';

	/// de: 'UPDATE v1.7'
	String get tutorial_scanner_update_badge => 'UPDATE v1.7';

	/// de: 'Bzzzt! Kamera-Scanner & Guide sind da!'
	String get tutorial_scanner_update_mob_title => 'Bzzzt! Kamera-Scanner & Guide sind da!';

	/// de: 'Hallo Trainer! Entdecke die neuen v1.7-Features: Kamera- & Foto-Scanner, Mini-PiP sowie das neue Multi-Hunt Dashboard mit Visuellem Auto-Counter!'
	String get tutorial_scanner_update_mob_desc => 'Hallo Trainer! Entdecke die neuen v1.7-Features: Kamera- & Foto-Scanner, Mini-PiP sowie das neue Multi-Hunt Dashboard mit Visuellem Auto-Counter!';

	/// de: 'Flüssige Live-Kamera-OCR'
	String get tutorial_scanner_mob_f1_title => 'Flüssige Live-Kamera-OCR';

	/// de: 'Hoch- & Querformat, Tap-to-Focus und Offline-OCR in allen 9 Spielsprachen.'
	String get tutorial_scanner_mob_f1_desc => 'Hoch- & Querformat, Tap-to-Focus und Offline-OCR in allen 9 Spielsprachen.';

	/// de: 'Präzise Scan-Zonen & Foto-Import'
	String get tutorial_scanner_mob_f2_title => 'Präzise Scan-Zonen & Foto-Import';

	/// de: 'Zone A/B zeichnen, Multi-Instanzen oder Fotos direkt aus der Galerie scannen.'
	String get tutorial_scanner_mob_f2_desc => 'Zone A/B zeichnen, Multi-Instanzen oder Fotos direkt aus der Galerie scannen.';

	/// de: 'Bewegliches In-App Mini-PiP'
	String get tutorial_scanner_mob_f3_title => 'Bewegliches In-App Mini-PiP';

	/// de: 'Scanne im schwebenden Mini-Fenster weiter, während du in PokéVault navigierst.'
	String get tutorial_scanner_mob_f3_desc => 'Scanne im schwebenden Mini-Fenster weiter, während du in PokéVault navigierst.';

	/// de: 'Bzzzt! Dein Overlay- & Kamera-Guide!'
	String get tutorial_scanner_update_desk_title => 'Bzzzt! Dein Overlay- & Kamera-Guide!';

	/// de: 'Hallo Trainer! Entdecke die neuen v1.7-Features: Desktop-Overlay, Snipping-Zonen, Floating HUD sowie das neue Multi-Hunt Dashboard mit Visuellem Auto-Counter!'
	String get tutorial_scanner_update_desk_desc => 'Hallo Trainer! Entdecke die neuen v1.7-Features: Desktop-Overlay, Snipping-Zonen, Floating HUD sowie das neue Multi-Hunt Dashboard mit Visuellem Auto-Counter!';

	/// de: 'Fenster-, Monitor- & Webcam-Scan'
	String get tutorial_scanner_desk_f1_title => 'Fenster-, Monitor- & Webcam-Scan';

	/// de: 'Erfasst Emulatoren, Capture-Cards, USB-Webcams und Foto-Dateien in Echtzeit.'
	String get tutorial_scanner_desk_f1_desc => 'Erfasst Emulatoren, Capture-Cards, USB-Webcams und Foto-Dateien in Echtzeit.';

	/// de: 'Snipping-Zonen & Multi-Instanz'
	String get tutorial_scanner_desk_f2_title => 'Snipping-Zonen & Multi-Instanz';

	/// de: 'Freie Bereiche für Fangboxen, Live-Fokus und parallele Shiny-Hunt-Slots.'
	String get tutorial_scanner_desk_f2_desc => 'Freie Bereiche für Fangboxen, Live-Fokus und parallele Shiny-Hunt-Slots.';

	/// de: 'Always-on-Top Mini-HUD'
	String get tutorial_scanner_desk_f3_title => 'Always-on-Top Mini-HUD';

	/// de: 'Schwebendes Overlay direkt über dem Spiel mit 1-Klick-Dex-Eintrag.'
	String get tutorial_scanner_desk_f3_desc => 'Schwebendes Overlay direkt über dem Spiel mit 1-Klick-Dex-Eintrag.';

	/// de: 'Neuer Scanner-Guide!'
	String get tutorial_scanner_home_delta_title => 'Neuer Scanner-Guide!';

	/// de: 'Tippe hier auf das Scanner-Icon, um direkt deine interaktive Rotom-Tour im Scanner zu starten!'
	String get tutorial_scanner_home_delta_text => 'Tippe hier auf das Scanner-Icon, um direkt deine interaktive Rotom-Tour im Scanner zu starten!';

	/// de: 'Scanner-Tour starten'
	String get tutorial_scanner_tour_btn => 'Scanner-Tour starten';

	/// de: 'NEU'
	String get tutorial_new_badge => 'NEU';

	/// de: 'Ziel-Pokédex wählen'
	String get tutorial_scanner_desk_dex_title => 'Ziel-Pokédex wählen';

	/// de: 'Lege hier fest, in welchem Pokédex erkannte Pokémon und Fänge automatisch eingetragen werden.'
	String get tutorial_scanner_desk_dex_text => 'Lege hier fest, in welchem Pokédex erkannte Pokémon und Fänge automatisch eingetragen werden.';

	/// de: 'Farbige Scan-Rahmen'
	String get tutorial_scanner_desk_borders_title => 'Farbige Scan-Rahmen';

	/// de: 'Zeigt die markierten Scan-Zonen als farbige Overlay-Rahmen direkt über deinem Desktop oder Spiel an.'
	String get tutorial_scanner_desk_borders_text => 'Zeigt die markierten Scan-Zonen als farbige Overlay-Rahmen direkt über deinem Desktop oder Spiel an.';

	/// de: 'Scan-Bereich (Zone A)'
	String get tutorial_scanner_desk_zone_a_title => 'Scan-Bereich (Zone A)';

	/// de: 'Definiert die Textbox für Fang- und Encounter-Meldungen – per Preset (z. B. Unten) oder frei gezeichnet.'
	String get tutorial_scanner_desk_zone_a_text => 'Definiert die Textbox für Fang- und Encounter-Meldungen – per Preset (z. B. Unten) oder frei gezeichnet.';

	/// de: 'Live-Fokus-Zone (Zone B)'
	String get tutorial_scanner_desk_zone_b_title => 'Live-Fokus-Zone (Zone B)';

	/// de: 'Optionale zweite Zone für Gegner-Infoleisten (oben links/rechts): erkennt Pokémon sofort und prüft fehlende Entwicklungen.'
	String get tutorial_scanner_desk_zone_b_text => 'Optionale zweite Zone für Gegner-Infoleisten (oben links/rechts): erkennt Pokémon sofort und prüft fehlende Entwicklungen.';

	/// de: 'Multi-Instanzen (#2, #3 ...)'
	String get tutorial_scanner_desk_multi_title => 'Multi-Instanzen (#2, #3 ...)';

	/// de: 'Füge parallele Emulator-Fenster oder Zonen hinzu, um mehrere Spiele gleichzeitig auf Encounters und Shinys zu scannen.'
	String get tutorial_scanner_desk_multi_text => 'Füge parallele Emulator-Fenster oder Zonen hinzu, um mehrere Spiele gleichzeitig auf Encounters und Shinys zu scannen.';

	/// de: 'Live-Ereignisse & OCR-Optionen'
	String get tutorial_scanner_desk_feed_title => 'Live-Ereignisse & OCR-Optionen';

	/// de: 'Hier erscheinen alle Treffer samt 1-Klick-Eintrag. Über das Zahnrad oben stellst du 9 Spielsprachen, Scan-Intervall und eigene Muster ein.'
	String get tutorial_scanner_desk_feed_text => 'Hier erscheinen alle Treffer samt 1-Klick-Eintrag. Über das Zahnrad oben stellst du 9 Spielsprachen, Scan-Intervall und eigene Muster ein.';

	/// de: 'Tracker & Webcam wählen'
	String get scanner_home_desktop_webcam => 'Tracker & Webcam wählen';

	/// de: 'Desktop Tracker & Overlay'
	String get scanner_home_desktop_only => 'Desktop Tracker & Overlay';

	/// de: 'Kamera-Tracker'
	String get scanner_home_mobile_camera => 'Kamera-Tracker';

	/// de: 'Webcam- & Foto-Tracker'
	String get scanner_home_webcam_photo => 'Webcam- & Foto-Tracker';

	/// de: 'Standard'
	String get scanner_profile_standard => 'Standard';

	/// de: 'Pixel-Art (DS)'
	String get scanner_profile_pixel_art => 'Pixel-Art (DS)';

	/// de: 'Kamera / Display'
	String get scanner_profile_camera_display => 'Kamera / Display';

	/// de: 'Ganzes Fenster'
	String get scanner_preset_full_window => 'Ganzes Fenster';

	/// de: 'DS Oben'
	String get scanner_preset_ds_top => 'DS Oben';

	/// de: 'DS Unten'
	String get scanner_preset_ds_bottom => 'DS Unten';

	/// de: 'Textbox unten'
	String get scanner_preset_bottom_dialogue => 'Textbox unten';

	/// de: 'Aus'
	String get scanner_focus_disabled => 'Aus';

	/// de: 'Oben Links'
	String get scanner_focus_top_left => 'Oben Links';

	/// de: 'Oben Rechts'
	String get scanner_focus_top_right => 'Oben Rechts';

	/// de: 'Oberer Streifen'
	String get scanner_focus_top_banner => 'Oberer Streifen';

	/// de: 'Eigener Bereich'
	String get scanner_focus_custom => 'Eigener Bereich';

	/// de: 'Alle Entw. ✓ Im Dex'
	String get scanner_evo_all_caught => 'Alle Entw. ✓ Im Dex';

	/// de: 'Entw.: {names}{extra} fehlt!'
	String get scanner_evo_missing => 'Entw.: {names}{extra} fehlt!';

	/// de: 'Entw. offen: {names}'
	String get scanner_evo_hud_missing => 'Entw. offen: {names}';

	/// de: 'Entw. komplett ✓'
	String get scanner_evo_hud_complete => 'Entw. komplett ✓';

	/// de: 'Web-OCR Fehler'
	String get scanner_web_ocr_error => 'Web-OCR Fehler';

	/// de: 'Lade {lang}...'
	String get scanner_web_ocr_loading => 'Lade {lang}...';

	/// de: 'Tesseract.js (Lokal: {lang})'
	String get scanner_web_ocr_local => 'Tesseract.js (Lokal: {lang})';

	/// de: 'Tesseract.js ({lang} · IndexedDB)'
	String get scanner_web_ocr_indexeddb => 'Tesseract.js ({lang} · IndexedDB)';

	/// de: 'LIVE'
	String get scanner_dock_live => 'LIVE';

	/// de: 'PAUSIERT'
	String get scanner_dock_paused => 'PAUSIERT';

	/// de: 'Live-Tracker aktiv'
	String get scanner_dock_active => 'Live-Tracker aktiv';

	/// de: 'Tracker pausiert'
	String get scanner_dock_inactive => 'Tracker pausiert';

	/// de: '✔ Gefangen'
	String get scanner_dock_caught => '✔ Gefangen';

	/// de: 'Fehlt im Ziel-Dex'
	String get scanner_dock_missing => 'Fehlt im Ziel-Dex';

	/// de: 'Ziel-Dex: {title} ({count} gefangen)'
	String get scanner_dock_target_dex => 'Ziel-Dex: {title} ({count} gefangen)';

	/// de: '+ Eintragen'
	String get scanner_dock_add_caught => '+ Eintragen';

	/// de: 'Pausieren'
	String get scanner_dock_pause_tooltip => 'Pausieren';

	/// de: 'Fortsetzen'
	String get scanner_dock_resume_tooltip => 'Fortsetzen';

	/// de: 'HUD ausblenden'
	String get scanner_dock_hud_hide_tooltip => 'HUD ausblenden';

	/// de: 'HUD öffnen'
	String get scanner_dock_hud_open_tooltip => 'HUD öffnen';

	/// de: 'Scanner-Setup öffnen'
	String get scanner_dock_setup_tooltip => 'Scanner-Setup öffnen';

	/// de: 'HUD aktiv'
	String get scanner_dock_hud_active => 'HUD aktiv';

	/// de: 'HUD'
	String get scanner_dock_hud => 'HUD';

	/// de: 'Setup'
	String get scanner_dock_setup => 'Setup';

	/// de: 'Tracker beenden'
	String get scanner_dock_close_tooltip => 'Tracker beenden';

	/// de: 'Warte auf Spiel...'
	String get scanner_waiting_for_game => 'Warte auf Spiel...';

	/// de: '⚠️ Fehlt im Ziel-Dex'
	String get scanner_hud_missing => '⚠️ Fehlt im Ziel-Dex';

	/// de: 'Always-on-Top · Klick + zum Eintragen'
	String get scanner_hud_footer => 'Always-on-Top · Klick + zum Eintragen';

	/// de: 'LIVE SCAN'
	String get scanner_hud_live_label => 'LIVE SCAN';

	/// de: 'SHINY'
	String get scanner_hud_shiny_badge => 'SHINY';

	/// de: 'In Ziel-Dex eintragen'
	String get scanner_hud_add_tooltip => 'In Ziel-Dex eintragen';

	/// de: 'Transparenz'
	String get scanner_hud_transparent_tooltip => 'Transparenz';

	/// de: 'Nicht mehr fixieren'
	String get scanner_hud_pin_off_tooltip => 'Nicht mehr fixieren';

	/// de: 'Immer im Vordergrund'
	String get scanner_hud_pin_on_tooltip => 'Immer im Vordergrund';

	/// de: 'Maximieren'
	String get scanner_hud_expand_tooltip => 'Maximieren';

	/// de: 'Kompaktansicht'
	String get scanner_hud_compact_tooltip => 'Kompaktansicht';

	/// de: 'Schließen'
	String get scanner_hud_close_tooltip => 'Schließen';

	/// de: 'Pause'
	String get scanner_pause_suffix => 'Pause';

	/// de: 'Ziehe einen Bereich über das Spiel · Enter/Klick bestätigt · Esc bricht ab'
	String get scanner_native_snipping_hint => 'Ziehe einen Bereich über das Spiel · Enter/Klick bestätigt · Esc bricht ab';

	/// de: 'Scannen'
	String get scanner_native_snipping_confirm => 'Scannen';

	/// de: 'Abbrechen'
	String get scanner_native_snipping_cancel => 'Abbrechen';

	/// de: 'Desktop Tracker & Overlay'
	String get scanner_desk_title => 'Desktop Tracker & Overlay';

	/// de: 'Webcam Tracker'
	String get scanner_webcam_title => 'Webcam Tracker';

	/// de: 'OCR Aktiv'
	String get scanner_ocr_active => 'OCR Aktiv';

	/// de: 'Pausiert'
	String get scanner_ocr_paused => 'Pausiert';

	/// de: 'OCR: {tag} (Fallback: {fallback})'
	String get scanner_ocr_fallback_badge => 'OCR: {tag} (Fallback: {fallback})';

	/// de: 'HUD schließen'
	String get scanner_hud_close_btn => 'HUD schließen';

	/// de: 'Floating HUD öffnen'
	String get scanner_hud_open_btn => 'Floating HUD öffnen';

	/// de: 'Alarm- & Töne-Einstellungen'
	String get scanner_alert_settings_tooltip => 'Alarm- & Töne-Einstellungen';

	/// de: 'Fenster aktualisieren'
	String get scanner_refresh_windows_tooltip => 'Fenster aktualisieren';

	/// de: 'Einstellungen'
	String get scanner_settings_tooltip => 'Einstellungen';

	/// de: 'Scanner-Tutorial'
	String get scanner_tutorial_tooltip => 'Scanner-Tutorial';

	/// de: 'Scan-Quelle / Zielfenster'
	String get scanner_source_header => 'Scan-Quelle / Zielfenster';

	/// de: 'Lade...'
	String get scanner_loading => 'Lade...';

	/// de: 'Aktualisieren'
	String get scanner_refresh => 'Aktualisieren';

	/// de: 'Eigener Desktop-Bereich'
	String get scanner_custom_desktop_region => 'Eigener Desktop-Bereich';

	/// de: 'Zu Fenster'
	String get scanner_back_to_window => 'Zu Fenster';

	/// de: 'Foto'
	String get scanner_photo_meta => 'Foto';

	/// de: 'minimiert'
	String get scanner_minimized_meta => 'minimiert';

	/// de: 'Jetzt scannen'
	String get scanner_scan_now => 'Jetzt scannen';

	/// de: 'ZIEL-POKÉDEX'
	String get scanner_target_dex_header => 'ZIEL-POKÉDEX';

	/// de: 'Dex wechseln →'
	String get scanner_change_dex_btn => 'Dex wechseln →';

	/// de: 'Kein Dex ausgewählt'
	String get scanner_no_dex_selected => 'Kein Dex ausgewählt';

	/// de: '{caught} von {total} gefangen'
	String get scanner_caught_of_total => '{caught} von {total} gefangen';

	/// de: 'Farbige Bildschirm-Rahmen anzeigen'
	String get scanner_show_borders_label => 'Farbige Bildschirm-Rahmen anzeigen';

	/// de: 'SCAN-BEREICH (ZONE A)'
	String get scanner_zone_a_header => 'SCAN-BEREICH (ZONE A)';

	/// de: 'GRÜN · TEXTBOX'
	String get scanner_zone_a_badge => 'GRÜN · TEXTBOX';

	/// de: 'Info zu Scan-Bereich (Zone A)'
	String get scanner_zone_a_info_tooltip => 'Info zu Scan-Bereich (Zone A)';

	/// de: 'Wofür ist Scan-Bereich (Zone A)?'
	String get scanner_zone_a_info_title => 'Wofür ist Scan-Bereich (Zone A)?';

	/// de: 'Haupt-Scan-Zone für Spieltexte (z. B. Dialogbox unten). Erkennt Fänge, Entwicklungen und wilde Begegnungen und trägt gefangene Pokémon automatisch in deinen Ziel-Dex ein.'
	String get scanner_zone_a_info_body => 'Haupt-Scan-Zone für Spieltexte (z. B. Dialogbox unten). Erkennt Fänge, Entwicklungen und wilde Begegnungen und trägt gefangene Pokémon automatisch in deinen Ziel-Dex ein.';

	/// de: 'Ganzes Fenster (100%)'
	String get scanner_mode_full_window_pct => 'Ganzes Fenster (100%)';

	/// de: 'DS Oben (Top-Screen 50%)'
	String get scanner_mode_ds_top_pct => 'DS Oben (Top-Screen 50%)';

	/// de: 'DS Unten (Touchscreen 50%)'
	String get scanner_mode_ds_bottom_pct => 'DS Unten (Touchscreen 50%)';

	/// de: 'Textbox unten (30%)'
	String get scanner_mode_dialogue_pct => 'Textbox unten (30%)';

	/// de: 'DS Oben (Top)'
	String get scanner_btn_ds_top => 'DS Oben (Top)';

	/// de: 'DS Unten (Touch)'
	String get scanner_btn_ds_bottom => 'DS Unten (Touch)';

	/// de: 'Wähle ein Emulator-Fenster oder markiere einen Live-OCR-Bereich auf dem Desktop.'
	String get scanner_monitor_hint => 'Wähle ein Emulator-Fenster oder markiere einen Live-OCR-Bereich auf dem Desktop.';

	/// de: 'LIVE-OCR AKTIV'
	String get scanner_status_live_ocr_active => 'LIVE-OCR AKTIV';

	/// de: 'LIVE-OCR PAUSIERT'
	String get scanner_status_live_ocr_paused => 'LIVE-OCR PAUSIERT';

	/// de: 'LIVE-OCR ÜBERWACHT MONITOR'
	String get scanner_status_monitor_active => 'LIVE-OCR ÜBERWACHT MONITOR';

	/// de: 'MONITOR-VORSCHAU · PAUSIERT'
	String get scanner_status_monitor_paused => 'MONITOR-VORSCHAU · PAUSIERT';

	/// de: 'LIVE-OCR ÜBERWACHT FENSTER'
	String get scanner_status_window_active => 'LIVE-OCR ÜBERWACHT FENSTER';

	/// de: 'FENSTER-VORSCHAU PAUSIERT'
	String get scanner_status_window_paused => 'FENSTER-VORSCHAU PAUSIERT';

	/// de: 'Live-Bild vergrößern'
	String get scanner_enlarge_live_preview => 'Live-Bild vergrößern';

	/// de: 'Vorschau ohne Auto-OCR (↻ aktualisieren)'
	String get scanner_monitor_preview_hint => 'Vorschau ohne Auto-OCR (↻ aktualisieren)';

	/// de: 'Warte auf Text (alle {interval})...'
	String get scanner_waiting_text_interval => 'Warte auf Text (alle {interval})...';

	/// de: 'Monitor-Vorschau aktualisieren'
	String get scanner_refresh_monitor_tooltip => 'Monitor-Vorschau aktualisieren';

	/// de: 'Bereich zurücksetzen'
	String get scanner_reset_region_tooltip => 'Bereich zurücksetzen';

	/// de: 'Scan-Bereich neu zeichnen'
	String get scanner_redraw_scan_region => 'Scan-Bereich neu zeichnen';

	/// de: 'Scan-Bereich frei zeichnen'
	String get scanner_draw_scan_region => 'Scan-Bereich frei zeichnen';

	/// de: 'Scan'
	String get scanner_zone_scan_label => 'Scan';

	/// de: 'Fokus'
	String get scanner_zone_focus_label => 'Fokus';

	/// de: 'LIVE-FOKUS-ZONE (ZONE B)'
	String get scanner_zone_b_header => 'LIVE-FOKUS-ZONE (ZONE B)';

	/// de: 'TÜRKIS · NUR ENCOUNTER'
	String get scanner_zone_b_badge => 'TÜRKIS · NUR ENCOUNTER';

	/// de: 'Info zu Live-Fokus-Zone (Zone B)'
	String get scanner_zone_b_info_tooltip => 'Info zu Live-Fokus-Zone (Zone B)';

	/// de: 'Wofür ist Live-Fokus-Zone (Zone B)?'
	String get scanner_zone_b_info_title => 'Wofür ist Live-Fokus-Zone (Zone B)?';

	/// de: 'Liest nur den Gegnernamen oben im Kampf-HUD (z. B. oben links/rechts oder frei markiert) als Begegnung — perfekt für Live-Fokus und Mehrfachbegegnungen, ohne eigene Pokémon oder Teammitglieder als gefangen zu werten.'
	String get scanner_zone_b_info_body => 'Liest nur den Gegnernamen oben im Kampf-HUD (z. B. oben links/rechts oder frei markiert) als Begegnung — perfekt für Live-Fokus und Mehrfachbegegnungen, ohne eigene Pokémon oder Teammitglieder als gefangen zu werten.';

	/// de: 'Fokus-Bereich neu zeichnen'
	String get scanner_redraw_focus_region => 'Fokus-Bereich neu zeichnen';

	/// de: 'Live-Fokus-Bereich frei zeichnen'
	String get scanner_draw_focus_region => 'Live-Fokus-Bereich frei zeichnen';

	/// de: 'Zone B aktiv ({preset})'
	String get scanner_zone_b_active => 'Zone B aktiv ({preset})';

	/// de: 'Fokus-Bereich deaktivieren'
	String get scanner_disable_focus_tooltip => 'Fokus-Bereich deaktivieren';

	/// de: 'IGNORIERTE TEAM-POKÉMON (STARTER-SCHUTZ)'
	String get scanner_ignored_team_header => 'IGNORIERTE TEAM-POKÉMON (STARTER-SCHUTZ)';

	/// de: 'MULTI-INSTANZEN'
	String get scanner_multi_header => 'MULTI-INSTANZEN';

	/// de: '{count} aktiv'
	String get scanner_multi_active_count => '{count} aktiv';

	/// de: 'Zone A/B oben = Instanz #1 · Weitere Instanzen frei mit Scan/Fokus oder Fenster koppeln:'
	String get scanner_multi_subtitle => 'Zone A/B oben = Instanz #1 · Weitere Instanzen frei mit Scan/Fokus oder Fenster koppeln:';

	/// de: '+ Instanz #{id}'
	String get scanner_multi_add_btn => '+ Instanz #{id}';

	/// de: 'Alle löschen'
	String get scanner_clear_all => 'Alle löschen';

	/// de: 'Freie Bereiche (ohne festes Fenster)'
	String get scanner_multi_free_regions => 'Freie Bereiche (ohne festes Fenster)';

	/// de: 'Gebundenes Fenster'
	String get scanner_multi_bound_window => 'Gebundenes Fenster';

	/// de: 'Scan + Fokus'
	String get scanner_multi_role_both => 'Scan + Fokus';

	/// de: 'Nur Scan'
	String get scanner_multi_role_scan => 'Nur Scan';

	/// de: 'Nur Fokus'
	String get scanner_multi_role_focus => 'Nur Fokus';

	/// de: 'Bereich wählen'
	String get scanner_multi_role_none => 'Bereich wählen';

	/// de: 'Instanz {label}'
	String get scanner_multi_instance_title => 'Instanz {label}';

	/// de: 'Instanz entfernen'
	String get scanner_multi_remove_tooltip => 'Instanz entfernen';

	/// de: 'Scan zeichnen'
	String get scanner_multi_draw_scan => 'Scan zeichnen';

	/// de: 'Scan neu'
	String get scanner_multi_redraw_scan => 'Scan neu';

	/// de: 'Fokus zeichnen'
	String get scanner_multi_draw_focus => 'Fokus zeichnen';

	/// de: 'Fokus neu'
	String get scanner_multi_redraw_focus => 'Fokus neu';

	/// de: 'SCAN-PROFIL'
	String get scanner_profile_header => 'SCAN-PROFIL';

	/// de: 'Info zu den Scan-Profilen'
	String get scanner_profile_info_tooltip => 'Info zu den Scan-Profilen';

	/// de: 'Bild-Optimierung pro Quelle'
	String get scanner_profile_info_title => 'Bild-Optimierung pro Quelle';

	/// de: '• Standard: Für scharfe PC- oder HD-Fenster. • Pixel-Art (DS): Schärft & skaliert pixelige DS-/GBA-Texte (z. B. melonDS, Gen 4/5). • Kamera / Display: Erhöht Kontrast für blasse oder abgefilmte Bildschirme.'
	String get scanner_profile_info_body => '• Standard: Für scharfe PC- oder HD-Fenster.\n• Pixel-Art (DS): Schärft & skaliert pixelige DS-/GBA-Texte (z. B. melonDS, Gen 4/5).\n• Kamera / Display: Erhöht Kontrast für blasse oder abgefilmte Bildschirme.';

	/// de: 'OCR-SCAN-RATE'
	String get scanner_rate_header => 'OCR-SCAN-RATE';

	/// de: 'Eigene OCR-Muster ({count})'
	String get scanner_custom_patterns_btn => 'Eigene OCR-Muster ({count})';

	/// de: 'Aktueller Live-Fokus'
	String get scanner_focus_card_header => 'Aktueller Live-Fokus';

	/// de: 'MEHRFACHBEGEGNUNG ({count})'
	String get scanner_multi_encounter_badge => 'MEHRFACHBEGEGNUNG ({count})';

	/// de: '✓ Im Dex'
	String get scanner_caught_badge_short => '✓ Im Dex';

	/// de: '★ Fehlt!'
	String get scanner_missing_badge_short => '★ Fehlt!';

	/// de: 'Eintragen'
	String get scanner_mark_caught_short => 'Eintragen';

	/// de: '✓ Im Ziel-Dex gefangen'
	String get scanner_caught_badge_full => '✓ Im Ziel-Dex gefangen';

	/// de: '★ Fehlt im Ziel-Dex!'
	String get scanner_missing_badge_full => '★ Fehlt im Ziel-Dex!';

	/// de: 'SMART-ALTERNATIVEN (ANTIPPEN ZUM WECHSELN)'
	String get scanner_smart_alternatives => 'SMART-ALTERNATIVEN (ANTIPPEN ZUM WECHSELN)';

	/// de: 'In "{dex}" eintragen'
	String get scanner_mark_in_dex_btn => 'In "{dex}" eintragen';

	/// de: 'Live-Ereignisse'
	String get scanner_events_header => 'Live-Ereignisse';

	/// de: 'Leeren'
	String get scanner_clear_events => 'Leeren';

	/// de: 'Warte auf In-Game Ereignisse...'
	String get scanner_events_empty_title => 'Warte auf In-Game Ereignisse...';

	/// de: 'Wähle dein Emulator-Fenster aus. Fänge und Begegnungen werden automatisch erkannt.'
	String get scanner_events_empty_subtitle => 'Wähle dein Emulator-Fenster aus. Fänge und Begegnungen werden automatisch erkannt.';

	/// de: 'Ereignis korrigieren'
	String get scanner_correct_event_tooltip => 'Ereignis korrigieren';

	/// de: 'FANG'
	String get scanner_event_type_caught => 'FANG';

	/// de: 'BEGEGNUNG'
	String get scanner_event_type_encounter => 'BEGEGNUNG';

	/// de: 'ENTWICKLUNG'
	String get scanner_event_type_evolved => 'ENTWICKLUNG';

	/// de: 'SHINY'
	String get scanner_event_type_shiny => 'SHINY';

	/// de: 'ALPHA'
	String get scanner_event_type_alpha => 'ALPHA';

	/// de: 'INFO'
	String get scanner_event_type_info => 'INFO';

	/// de: '{name} wird als eigenes Team ignoriert.'
	String get scanner_snack_team_ignored => '{name} wird als eigenes Team ignoriert.';

	/// de: 'Kein Zielfenster oder Desktop ausgewählt.'
	String get scanner_snack_no_target => 'Kein Zielfenster oder Desktop ausgewählt.';

	/// de: 'Scanne "{title}"...'
	String get scanner_snack_scanning_target => 'Scanne "{title}"...';

	/// de: 'Windows-Snipping aktiv (Win+Shift+S): Ziehe den Bereich über deinen Desktop/Emulator!'
	String get scanner_snack_win_snipping_active => 'Windows-Snipping aktiv (Win+Shift+S): Ziehe den Bereich über deinen Desktop/Emulator!';

	/// de: 'Desktop-Ausschnitt ({width}x{height} px) übernommen!'
	String get scanner_snack_snippet_imported => 'Desktop-Ausschnitt ({width}x{height} px) übernommen!';

	/// de: 'Screenshot ({width}x{height} px) aus Zwischenablage übernommen!'
	String get scanner_snack_clipboard_imported => 'Screenshot ({width}x{height} px) aus Zwischenablage übernommen!';

	/// de: 'Kein Bild in der Windows-Zwischenablage. Nutze Win+Shift+S zum Ausschneiden.'
	String get scanner_snack_clipboard_empty => 'Kein Bild in der Windows-Zwischenablage. Nutze Win+Shift+S zum Ausschneiden.';

	/// de: 'In "{dex}" eingetragen!'
	String get scanner_snack_marked_in_dex => 'In "{dex}" eingetragen!';

	/// de: 'Alarm- & Signal-Einstellungen'
	String get scanner_alert_dialog_title => 'Alarm- & Signal-Einstellungen';

	/// de: 'Akustische Signale (Töne)'
	String get scanner_alert_sound_title => 'Akustische Signale (Töne)';

	/// de: 'Spielt Signal-Töne bei Spielereignissen ab'
	String get scanner_alert_sound_subtitle => 'Spielt Signal-Töne bei Spielereignissen ab';

	/// de: '✨ Schillernde Pokémon (Shiny-Gong)'
	String get scanner_alert_sound_shiny => '✨ Schillernde Pokémon (Shiny-Gong)';

	/// de: '🔴 Alpha- & Herrscher-Pokémon'
	String get scanner_alert_sound_alpha => '🔴 Alpha- & Herrscher-Pokémon';

	/// de: '⚪ Normale Fänge / Begegnungen'
	String get scanner_alert_sound_normal => '⚪ Normale Fänge / Begegnungen';

	/// de: 'Optischer Glow & Pulsieren bei Shiny'
	String get scanner_alert_visual_glow => 'Optischer Glow & Pulsieren bei Shiny';

	/// de: 'Schließen'
	String get scanner_close_btn => 'Schließen';

	/// de: 'Tracker-Einstellungen'
	String get scanner_settings_dialog_title => 'Tracker-Einstellungen';

	/// de: 'Scanbereich (Fensterbereich)'
	String get scanner_settings_region_title => 'Scanbereich (Fensterbereich)';

	/// de: 'Wähle welcher Teil des Emulatorfensters per OCR abgetastet werden soll:'
	String get scanner_settings_region_desc => 'Wähle welcher Teil des Emulatorfensters per OCR abgetastet werden soll:';

	/// de: 'Ganzes Fenster (Empfohlen für DS & Multi-Screen)'
	String get scanner_settings_full_title => 'Ganzes Fenster (Empfohlen für DS & Multi-Screen)';

	/// de: 'Scannt das gesamte Spielfenster (100%)'
	String get scanner_settings_full_sub => 'Scannt das gesamte Spielfenster (100%)';

	/// de: 'Oberer DS-Bildschirm (DS-Kämpfe & Dialoge)'
	String get scanner_settings_ds_top_title => 'Oberer DS-Bildschirm (DS-Kämpfe & Dialoge)';

	/// de: 'Scannt oberen Bildschirm (0-52%)'
	String get scanner_settings_ds_top_sub => 'Scannt oberen Bildschirm (0-52%)';

	/// de: 'Unterer DS-Bildschirm (Touchscreen)'
	String get scanner_settings_ds_bottom_title => 'Unterer DS-Bildschirm (Touchscreen)';

	/// de: 'Scannt unteren Bildschirm (48-100%)'
	String get scanner_settings_ds_bottom_sub => 'Scannt unteren Bildschirm (48-100%)';

	/// de: 'Klassische Textbox (GBA / 3DS unten)'
	String get scanner_settings_dialogue_title => 'Klassische Textbox (GBA / 3DS unten)';

	/// de: 'Scannt Textbox am unteren Fensterrand (70-100%)'
	String get scanner_settings_dialogue_sub => 'Scannt Textbox am unteren Fensterrand (70-100%)';

	/// de: 'Automatisch eintragen'
	String get scanner_settings_auto_mark_title => 'Automatisch eintragen';

	/// de: 'Erkannte Fänge direkt ohne Klick im Ziel-Dex speichern'
	String get scanner_settings_auto_mark_sub => 'Erkannte Fänge direkt ohne Klick im Ziel-Dex speichern';

	/// de: 'OCR-Sprache (Spieltext-Erkennung)'
	String get scanner_settings_ocr_lang_title => 'OCR-Sprache (Spieltext-Erkennung)';

	/// de: 'Ereignis korrigieren'
	String get scanner_correction_dialog_title => 'Ereignis korrigieren';

	/// de: 'Alle Pokémon durchsuchen (Name oder #ID)...'
	String get scanner_correction_search_hint => 'Alle Pokémon durchsuchen (Name oder #ID)...';

	/// de: 'TOP-10 OCR-TREFFER (NACH WAHRSCHEINLICHKEIT)'
	String get scanner_correction_top10_header => 'TOP-10 OCR-TREFFER (NACH WAHRSCHEINLICHKEIT)';

	/// de: 'Kein passendes Pokémon gefunden.'
	String get scanner_correction_none_found => 'Kein passendes Pokémon gefunden.';

	/// de: 'Eigenes Team / Starter dauerhaft ignorieren?'
	String get scanner_correction_ignore_title => 'Eigenes Team / Starter dauerhaft ignorieren?';

	/// de: 'Sperrt diese Art dauerhaft für künftige OCR-Fänge (z. B. deinen eigenen Starter im Kampfmenü).'
	String get scanner_correction_ignore_desc => 'Sperrt diese Art dauerhaft für künftige OCR-Fänge (z. B. deinen eigenen Starter im Kampfmenü).';

	/// de: '{name} dauerhaft ignorieren'
	String get scanner_correction_ignore_btn => '{name} dauerhaft ignorieren';

	/// de: 'Entfernen'
	String get scanner_remove_btn => 'Entfernen';

	/// de: 'Abbrechen'
	String get scanner_cancel_btn => 'Abbrechen';

	/// de: 'Ziel-Pokédex auswählen'
	String get scanner_dex_modal_title => 'Ziel-Pokédex auswählen';

	/// de: 'Pokédex durchsuchen...'
	String get scanner_dex_modal_search => 'Pokédex durchsuchen...';

	/// de: 'Kein passender Pokédex gefunden.'
	String get scanner_dex_modal_empty => 'Kein passender Pokédex gefunden.';

	/// de: 'Aktiv ✔'
	String get scanner_dex_modal_active => 'Aktiv ✔';

	/// de: '{caught} von {total} gefangen • {region}'
	String get scanner_dex_modal_progress => '{caught} von {total} gefangen • {region}';

	/// de: 'Benutzerdefinierter Bereich'
	String get scanner_snipping_custom_label => 'Benutzerdefinierter Bereich';

	/// de: 'Desktop-Snipping: Ziehe einen Bereich über den Bildschirm'
	String get scanner_snipping_desktop_hint => 'Desktop-Snipping: Ziehe einen Bereich über den Bildschirm';

	/// de: 'Snipping ({title}): Wähle oder ziehe einen Scan-Bereich'
	String get scanner_snipping_window_hint => 'Snipping ({title}): Wähle oder ziehe einen Scan-Bereich';

	/// de: 'Snipping-Modus: Ziehe ein Rechteck über den Lesebereich'
	String get scanner_snipping_default_hint => 'Snipping-Modus: Ziehe ein Rechteck über den Lesebereich';

	/// de: 'Zwischenablage'
	String get scanner_snipping_clipboard => 'Zwischenablage';

	/// de: '🎮 DS Oben (Top-Screen 50%)'
	String get scanner_snipping_ds_top_chip => '🎮 DS Oben (Top-Screen 50%)';

	/// de: '🎮 DS Unten (Touch 50%)'
	String get scanner_snipping_ds_bottom_chip => '🎮 DS Unten (Touch 50%)';

	/// de: '💬 Textbox unten (30%)'
	String get scanner_snipping_dialogue_chip => '💬 Textbox unten (30%)';

	/// de: '🖥️ Desktop-Fokus (Bildschirm 1)'
	String get scanner_snipping_desktop_focus => '🖥️ Desktop-Fokus (Bildschirm 1)';

	/// de: '🖥️ Bildschirm-Scanbereich'
	String get scanner_snipping_screen_region => '🖥️ Bildschirm-Scanbereich';

	/// de: 'Klicke und ziehe mit der Maus über das Spielfenster, oder nutze oben die DS Oben/Unten & Textbox Presets.'
	String get scanner_snipping_instructions => 'Klicke und ziehe mit der Maus über das Spielfenster,\noder nutze oben die DS Oben/Unten & Textbox Presets.';

	/// de: 'Diesen Bereich scannen'
	String get scanner_snipping_confirm_scan => 'Diesen Bereich scannen';

	/// de: 'Wechseln'
	String get scanner_webcam_switch => 'Wechseln';

	/// de: 'Fertig'
	String get scanner_webcam_done => 'Fertig';

	/// de: 'Zonen zeichnen'
	String get scanner_webcam_draw_zones => 'Zonen zeichnen';

	/// de: 'Foto scannen'
	String get scanner_webcam_scan_photo => 'Foto scannen';

	/// de: 'Webcam wird initialisiert...'
	String get scanner_webcam_initializing => 'Webcam wird initialisiert...';

	/// de: 'Keine aktive Webcam ausgewählt — nutze „Foto scannen“ oder schließe eine USB-Kamera an.'
	String get scanner_webcam_no_camera => 'Keine aktive Webcam ausgewählt — nutze „Foto scannen“ oder schließe eine USB-Kamera an.';

	/// de: 'Kamera neu verbinden'
	String get scanner_webcam_reconnect => 'Kamera neu verbinden';

	/// de: 'Vorlage muss {pokemon} als Platzhalter enthalten.'
	String get scanner_pattern_missing_placeholder => 'Vorlage muss {pokemon} als Platzhalter enthalten.';

	/// de: 'Muster "{template}" ist bereits aktiv.'
	String get scanner_pattern_duplicate => 'Muster "{template}" ist bereits aktiv.';

	/// de: 'Bilder'
	String get scanner_pattern_images_label => 'Bilder';

	/// de: 'Bild konnte nicht dekodiert werden.'
	String get scanner_pattern_decode_failed => 'Bild konnte nicht dekodiert werden.';

	/// de: 'Fehler beim Laden: {error}'
	String get scanner_pattern_load_error => 'Fehler beim Laden: {error}';

	/// de: 'OCR-Ausführung fehlgeschlagen: {error}'
	String get scanner_pattern_ocr_error => 'OCR-Ausführung fehlgeschlagen: {error}';

	/// de: 'Eigene OCR-Muster & Scan-Studio'
	String get scanner_pattern_title => 'Eigene OCR-Muster & Scan-Studio';

	/// de: 'Muster ohne Duplikate pflegen & gegen echten OCR-Text oder Fotos testen'
	String get scanner_pattern_subtitle => 'Muster ohne Duplikate pflegen & gegen echten OCR-Text oder Fotos testen';

	/// de: 'NEUES MUSTER DEFINIEREN'
	String get scanner_pattern_new_header => 'NEUES MUSTER DEFINIEREN';

	/// de: 'Gefangen'
	String get scanner_pattern_type_caught => 'Gefangen';

	/// de: 'Begegnung'
	String get scanner_pattern_type_encounter => 'Begegnung';

	/// de: 'Entwicklung'
	String get scanner_pattern_type_evolved => 'Entwicklung';

	/// de: 'z. B. Klasse! {pokemon} * gefangen'
	String get scanner_pattern_input_hint => 'z. B. Klasse! {pokemon} * gefangen';

	/// de: 'Hinzufügen'
	String get scanner_pattern_add_btn => 'Hinzufügen';

	/// de: 'Bausteine:'
	String get scanner_pattern_tokens_label => 'Bausteine:';

	/// de: '+ * (Platzhalter)'
	String get scanner_pattern_wildcard_chip => '+ * (Platzhalter)';

	/// de: 'Schnellvorlagen (werden automatisch dedupliziert):'
	String get scanner_pattern_quick_header => 'Schnellvorlagen (werden automatisch dedupliziert):';

	/// de: 'LIVE-SANDBOX TESTEN'
	String get scanner_pattern_sandbox_header => 'LIVE-SANDBOX TESTEN';

	/// de: 'Text testen'
	String get scanner_pattern_tab_text => 'Text testen';

	/// de: 'Foto / Frame testen'
	String get scanner_pattern_tab_photo => 'Foto / Frame testen';

	/// de: 'OCR-Zeile oder Log einfügen, z. B.: Klasse! Zr-rrokex wrde aefar«t!'
	String get scanner_pattern_text_hint => 'OCR-Zeile oder Log einfügen, z. B.:\nKlasse!\nZr-rrokex wrde aefar«t!';

	/// de: 'AKTIVE MUSTER ({count})'
	String get scanner_pattern_active_header => 'AKTIVE MUSTER ({count})';

	/// de: 'Noch keine eigenen Muster definiert.'
	String get scanner_pattern_empty => 'Noch keine eigenen Muster definiert.';

	/// de: 'Gib oben eine OCR-Zeile ein, um Muster + Smart-Search live zu prüfen.'
	String get scanner_pattern_sandbox_empty => 'Gib oben eine OCR-Zeile ein, um Muster + Smart-Search live zu prüfen.';

	/// de: 'Kein Ereignis erkannt (UI/Rauschen oder fehlendes Muster).'
	String get scanner_pattern_sandbox_no_event => 'Kein Ereignis erkannt (UI/Rauschen oder fehlendes Muster).';

	/// de: 'Typ: {type} | Rohtext "{raw}" -> kein Pokédex-Treffer >= 72%'
	String get scanner_pattern_sandbox_no_match => 'Typ: {type} | Rohtext "{raw}" -> kein Pokédex-Treffer >= 72%';

	/// de: 'Foto/Screenshot laden'
	String get scanner_pattern_load_photo => 'Foto/Screenshot laden';

	/// de: 'Aktuellen Live-Frame nutzen'
	String get scanner_pattern_use_live_frame => 'Aktuellen Live-Frame nutzen';

	/// de: 'Noch kein Frame geladen. Lade ein Emulator-/Kamera-Bild zum Testen.'
	String get scanner_pattern_no_frame => 'Noch kein Frame geladen. Lade ein Emulator-/Kamera-Bild zum Testen.';

	/// de: 'Geladener Frame: {width}×{height} ({format})'
	String get scanner_pattern_loaded_frame => 'Geladener Frame: {width}×{height} ({format})';

	/// de: 'Foto mit OCR testen'
	String get scanner_pattern_run_photo_ocr => 'Foto mit OCR testen';

	/// de: 'Alle 3 Profile vergleichen'
	String get scanner_pattern_compare_profiles => 'Alle 3 Profile vergleichen';

	/// de: '<kein Text erkannt>'
	String get scanner_pattern_no_text => '<kein Text erkannt>';

	/// de: 'GEFANGEN'
	String get scanner_pattern_badge_caught => 'GEFANGEN';

	/// de: 'Kein Ziel-Dex ausgewählt'
	String get scanner_mob_no_target_dex => 'Kein Ziel-Dex ausgewählt';

	/// de: 'Wechseln'
	String get scanner_mob_switch => 'Wechseln';

	/// de: '{caught} / {total} gefangen ({pct}%)'
	String get scanner_mob_dex_progress => '{caught} / {total} gefangen ({pct}%)';

	/// de: 'Noch kein Pokémon im Fokus. Richte die Kamera auf den Bildschirm oder importiere ein Foto.'
	String get scanner_mob_no_focus_pokemon => 'Noch kein Pokémon im Fokus. Richte die Kamera auf den Bildschirm oder importiere ein Foto.';

	/// de: 'Fehlt noch'
	String get scanner_mob_missing => 'Fehlt noch';

	/// de: 'Erneut markieren'
	String get scanner_mob_mark_again => 'Erneut markieren';

	/// de: 'Im Dex eintragen'
	String get scanner_mob_mark_in_dex => 'Im Dex eintragen';

	/// de: 'Starter ignorieren'
	String get scanner_mob_ignore_starter => 'Starter ignorieren';

	/// de: 'Ignorierte Team-/Starter-Pokémon'
	String get scanner_mob_ignored_starters => 'Ignorierte Team-/Starter-Pokémon';

	/// de: 'Scan-Modus & Haupt-Zonen (Instanz #1)'
	String get scanner_mob_scan_mode_header => 'Scan-Modus & Haupt-Zonen (Instanz #1)';

	/// de: 'Auto (Vollbild)'
	String get scanner_mob_auto_fullscreen => 'Auto (Vollbild)';

	/// de: 'Vierecke zeichnen'
	String get scanner_mob_draw_rects => 'Vierecke zeichnen';

	/// de: 'Zeichnen aktiv'
	String get scanner_mob_drawing_active => 'Zeichnen aktiv';

	/// de: 'Rechtecke gesperrt'
	String get scanner_mob_rects_locked => 'Rechtecke gesperrt';

	/// de: 'Zone A zeichnen'
	String get scanner_mob_draw_zone_a => 'Zone A zeichnen';

	/// de: 'Zone A neu'
	String get scanner_mob_redraw_zone_a => 'Zone A neu';

	/// de: 'Zone B zeichnen'
	String get scanner_mob_draw_zone_b => 'Zone B zeichnen';

	/// de: 'Zone B neu'
	String get scanner_mob_redraw_zone_b => 'Zone B neu';

	/// de: 'Kamera & Foto-Import'
	String get scanner_mob_camera_photo_header => 'Kamera & Foto-Import';

	/// de: 'Aktive Kamera'
	String get scanner_mob_active_camera => 'Aktive Kamera';

	/// de: 'Keine Hardware-Kamera gefunden'
	String get scanner_mob_no_hw_camera => 'Keine Hardware-Kamera gefunden';

	/// de: 'Licht an'
	String get scanner_mob_light_on => 'Licht an';

	/// de: 'Taschenlampe'
	String get scanner_mob_torch => 'Taschenlampe';

	/// de: 'Kamera drehen'
	String get scanner_mob_flip_camera => 'Kamera drehen';

	/// de: 'OCR, Sprache & Automation'
	String get scanner_mob_ocr_automation_header => 'OCR, Sprache & Automation';

	/// de: 'Spiel- & OCR-Sprache'
	String get scanner_mob_ocr_lang_label => 'Spiel- & OCR-Sprache';

	/// de: 'Scan-Intervall:'
	String get scanner_mob_scan_interval => 'Scan-Intervall:';

	/// de: 'Fänge automatisch im Dex speichern'
	String get scanner_mob_auto_save => 'Fänge automatisch im Dex speichern';

	/// de: 'Haptik & Shiny/Alpha-Alarme'
	String get scanner_mob_haptics_alerts => 'Haptik & Shiny/Alpha-Alarme';

	/// de: 'Eigene Textmuster ({count})'
	String get scanner_mob_custom_patterns => 'Eigene Textmuster ({count})';

	/// de: 'Rückkamera'
	String get scanner_mob_rear_camera => 'Rückkamera';

	/// de: 'Frontkamera'
	String get scanner_mob_front_camera => 'Frontkamera';

	/// de: 'Externe Kamera'
	String get scanner_mob_external_camera => 'Externe Kamera';

	/// de: 'MULTI-INSTANZEN ({count})'
	String get scanner_mob_multi_header => 'MULTI-INSTANZEN ({count})';

	/// de: 'Instanz'
	String get scanner_mob_instance_btn => 'Instanz';

	/// de: 'Lege zusätzliche Instanzen (#2, #3, …) an — jede mit eigener Zone A (Scan) und Zone B (Fokus), genau wie auf dem Desktop.'
	String get scanner_mob_multi_hint => 'Lege zusätzliche Instanzen (#2, #3, …) an — jede mit eigener Zone A (Scan) und Zone B (Fokus), genau wie auf dem Desktop.';

	/// de: 'Nicht gezeichnet'
	String get scanner_mob_not_drawn => 'Nicht gezeichnet';

	/// de: 'Zone B · Fokus'
	String get scanner_mob_zone_b_focus => 'Zone B · Fokus';

	/// de: 'Zone A · Scan'
	String get scanner_mob_zone_a_scan => 'Zone A · Scan';

	/// de: 'Rechteck löschen'
	String get scanner_mob_delete_rect => 'Rechteck löschen';

	/// de: 'Erkannte Ereignisse'
	String get scanner_mob_events_header => 'Erkannte Ereignisse';

	/// de: 'Noch keine Fänge oder Begegnungen erkannt.'
	String get scanner_mob_no_events => 'Noch keine Fänge oder Begegnungen erkannt.';

	/// de: 'Korrigieren'
	String get scanner_mob_correct_tooltip => 'Korrigieren';

	/// de: 'Live-OCR Diagnose ({count})'
	String get scanner_mob_live_ocr_diagnose => 'Live-OCR Diagnose ({count})';

	/// de: 'Pause'
	String get scanner_mob_pause => 'Pause';

	/// de: 'Kamera wechseln'
	String get scanner_mob_switch_camera => 'Kamera wechseln';

	/// de: 'Kamerazugriff verweigert'
	String get scanner_mob_permission_title => 'Kamerazugriff verweigert';

	/// de: 'Bitte erlaube den Kamerazugriff in den Systemeinstellungen oder importiere stattdessen ein Foto.'
	String get scanner_mob_permission_desc => 'Bitte erlaube den Kamerazugriff in den Systemeinstellungen oder importiere stattdessen ein Foto.';

	/// de: 'Erneut versuchen'
	String get scanner_mob_retry => 'Erneut versuchen';

	/// de: 'Bearbeiten'
	String get scanner_mob_editing => 'Bearbeiten';

	/// de: 'Gesperrt'
	String get scanner_mob_locked => 'Gesperrt';

	/// de: 'Fokus, Zonen & Feed ({count})'
	String get scanner_mob_drawer_header => 'Fokus, Zonen & Feed ({count})';

	/// de: 'Pokémon suchen'
	String get scanner_mob_search_pokemon => 'Pokémon suchen';

	/// de: 'Team- & Starter-Schutz'
	String get scanner_mob_starter_dialog_title => 'Team- & Starter-Schutz';

	/// de: 'Ignorierte Pokémon (z. B. dein eigenes Starter-Pokémon aus "Los, Pikachu!") werden bei Kampfeintritten übersprungen, bis du sie hier wieder entfernst.'
	String get scanner_mob_starter_dialog_desc => 'Ignorierte Pokémon (z. B. dein eigenes Starter-Pokémon aus "Los, Pikachu!") werden bei Kampfeintritten übersprungen, bis du sie hier wieder entfernst.';

	/// de: 'Vollbild'
	String get scanner_mob_fullscreen_tooltip => 'Vollbild';

	/// de: 'Geteilte Ansicht'
	String get scanner_mob_splitscreen_tooltip => 'Geteilte Ansicht';

	/// de: 'Als Mini-Fenster (PiP)'
	String get scanner_mob_pip_tooltip => 'Als Mini-Fenster (PiP)';

	/// de: 'Fokus & Dex'
	String get scanner_mob_tab_focus => 'Fokus & Dex';

	/// de: 'Zonen & Kamera'
	String get scanner_mob_tab_zones => 'Zonen & Kamera';

	/// de: 'Feed & Diagnose'
	String get scanner_mob_tab_feed => 'Feed & Diagnose';

	/// de: 'Kamera vergrößern'
	String get scanner_mob_pip_enlarge => 'Kamera vergrößern';

	/// de: 'Scanne...'
	String get scanner_mob_pip_scanning => 'Scanne...';

	/// de: 'AUTO-MODUS · {preset}'
	String get scanner_mob_auto_mode => 'AUTO-MODUS · {preset}';

	/// de: 'Auto-Scanner konfigurieren'
	String get shiny_auto_btn_tooltip => 'Auto-Scanner konfigurieren';

	/// de: 'Auto-Counter aktiv'
	String get shiny_auto_bar_active => 'Auto-Counter aktiv';

	/// de: 'Auto-Counter pausiert'
	String get shiny_auto_bar_paused => 'Auto-Counter pausiert';

	/// de: 'Undo'
	String get shiny_auto_undo => 'Undo';

	/// de: 'Auto-Counter Setup'
	String get shiny_auto_setup_title => 'Auto-Counter Setup';

	/// de: 'Scan-Quelle'
	String get shiny_auto_source_section => 'Scan-Quelle';

	/// de: 'Scanner-Quelle aktiv'
	String get shiny_auto_source_connected => 'Scanner-Quelle aktiv';

	/// de: 'Noch keine aktive Scan-Quelle verbunden.'
	String get shiny_auto_source_none => 'Noch keine aktive Scan-Quelle verbunden.';

	/// de: 'Fenster / Bildschirm / Webcam einrichten'
	String get shiny_auto_open_desktop_scanner => 'Fenster / Bildschirm / Webcam einrichten';

	/// de: 'Kamera / PiP / Multi-Zonen einrichten'
	String get shiny_auto_open_mobile_scanner => 'Kamera / PiP / Multi-Zonen einrichten';

	/// de: 'Mit aktiver Quelle starten'
	String get shiny_auto_connect_active_source => 'Mit aktiver Quelle starten';

	/// de: 'Erkennungsmethode & Reset-Logik'
	String get shiny_auto_mode_section => 'Erkennungsmethode & Reset-Logik';

	/// de: 'Wild Encounter'
	String get shiny_auto_mode_wild => 'Wild Encounter';

	/// de: 'Soft Reset'
	String get shiny_auto_mode_soft_reset => 'Soft Reset';

	/// de: 'Ei-Schlupf (Masuda)'
	String get shiny_auto_mode_egg => 'Ei-Schlupf (Masuda)';

	/// de: 'Overworld / Ladebildschirm'
	String get shiny_auto_mode_transition => 'Overworld / Ladebildschirm';

	/// de: 'Welche Pokémon zählen?'
	String get shiny_auto_filter_section => 'Welche Pokémon zählen?';

	/// de: 'Alle Pokémon'
	String get shiny_auto_filter_all => 'Alle Pokémon';

	/// de: 'Nur Ziel-Pokémon'
	String get shiny_auto_filter_target => 'Nur Ziel-Pokémon';

	/// de: 'Doppel-/Horden-Anzahl (+N) übernehmen'
	String get shiny_auto_horde_toggle => 'Doppel-/Horden-Anzahl (+N) übernehmen';

	/// de: 'Schwarzbild-Übergang als Reset werten'
	String get shiny_auto_black_reset_toggle => 'Schwarzbild-Übergang als Reset werten';

	/// de: 'Weißbild-Übergang als Reset werten'
	String get shiny_auto_white_reset_toggle => 'Weißbild-Übergang als Reset werten';

	/// de: 'Eigene Trigger-Muster'
	String get shiny_auto_custom_triggers => 'Eigene Trigger-Muster';

	/// de: 'Eigene Reset-Muster'
	String get shiny_auto_custom_resets => 'Eigene Reset-Muster';

	/// de: 'z. B. {pokemon} erscheint'
	String get shiny_auto_custom_trigger_hint => 'z. B. {pokemon} erscheint';

	/// de: 'z. B. Weiter oder Press Start'
	String get shiny_auto_custom_reset_hint => 'z. B. Weiter oder Press Start';

	/// de: 'Hinzufügen'
	String get shiny_auto_add_btn => 'Hinzufügen';

	/// de: 'Safety & Benachrichtigungen'
	String get shiny_auto_safety_section => 'Safety & Benachrichtigungen';

	/// de: 'Ton bei Auto-Zählung'
	String get shiny_auto_sound_count => 'Ton bei Auto-Zählung';

	/// de: 'Vibration bei Auto-Zählung'
	String get shiny_auto_haptic_count => 'Vibration bei Auto-Zählung';

	/// de: 'Alarm-Ton bei Shiny-Signal'
	String get shiny_auto_sound_shiny => 'Alarm-Ton bei Shiny-Signal';

	/// de: 'Vibration bei Shiny-Signal'
	String get shiny_auto_haptic_shiny => 'Vibration bei Shiny-Signal';

	/// de: 'Slot bei Shiny automatisch pausieren'
	String get shiny_auto_pause_on_shiny => 'Slot bei Shiny automatisch pausieren';

	/// de: 'Auto-Counter starten'
	String get shiny_auto_start_btn => 'Auto-Counter starten';

	/// de: 'Einstellungen übernehmen'
	String get shiny_auto_save_btn => 'Einstellungen übernehmen';

	/// de: 'SHINY-SIGNAL auf Slot #{slot}!'
	String get shiny_auto_shiny_alert_title => 'SHINY-SIGNAL auf Slot #{slot}!';

	/// de: 'Slot fortsetzen'
	String get shiny_auto_shiny_alert_resume => 'Slot fortsetzen';

	/// de: 'Bereit'
	String get shiny_auto_slot_armed => 'Bereit';

	/// de: 'Gezählt'
	String get shiny_auto_slot_counted => 'Gezählt';

	/// de: 'Reset...'
	String get shiny_auto_slot_rearm => 'Reset...';

	/// de: 'Shiny!'
	String get shiny_auto_slot_shiny => 'Shiny!';

	/// de: 'Pausiert'
	String get shiny_auto_slot_paused => 'Pausiert';

	/// de: 'Auto-Counter stoppen'
	String get shiny_auto_stop_tooltip => 'Auto-Counter stoppen';

	/// de: 'Multi-Hunt Dashboard'
	String get multi_hunt_dashboard_title => 'Multi-Hunt Dashboard';

	/// de: 'Multi-Hunt Dashboard öffnen'
	String get multi_hunt_dashboard_tooltip => 'Multi-Hunt Dashboard öffnen';

	/// de: 'Keine aktiven oder pausierten Hunts'
	String get multi_hunt_empty_title => 'Keine aktiven oder pausierten Hunts';

	/// de: 'Erstelle mindestens einen Shiny Hunt im Hub, um mehrere Spiele gleichzeitig zu tracken.'
	String get multi_hunt_empty_desc => 'Erstelle mindestens einen Shiny Hunt im Hub, um mehrere Spiele gleichzeitig zu tracken.';

	/// de: 'Scan-Slots'
	String get multi_hunt_slot_assign_label => 'Scan-Slots';

	/// de: 'Kein Slot zugewiesen'
	String get multi_hunt_assign_slot_none => 'Kein Slot zugewiesen';

	/// de: 'Einzelansicht'
	String get multi_hunt_open_counter => 'Einzelansicht';

	/// de: 'Live Auto-Log ({count})'
	String get multi_hunt_logs_title => 'Live Auto-Log ({count})';

	/// de: 'Neuer Hunt'
	String get multi_hunt_add_hunt => 'Neuer Hunt';

	/// de: 'Pausierte ({count})'
	String get multi_hunt_show_paused => 'Pausierte ({count})';

	/// de: 'Pausierte ausblenden'
	String get multi_hunt_hide_paused => 'Pausierte ausblenden';

	/// de: 'Pausierte Hunts ({count})'
	String get multi_hunt_paused_section => 'Pausierte Hunts ({count})';

	/// de: 'Auto-Regeln für diesen Hunt'
	String get multi_hunt_edit_rules_tooltip => 'Auto-Regeln für diesen Hunt';

	/// de: 'Hunt bearbeiten'
	String get multi_hunt_edit_hunt_tooltip => 'Hunt bearbeiten';

	/// de: 'Regeln für {name}'
	String get shiny_auto_setup_for_hunt => 'Regeln für {name}';

	/// de: 'Erweitert / Timing-Feintuning'
	String get shiny_auto_timing_section => 'Erweitert / Timing-Feintuning';

	/// de: 'Reset-Cooldown (ms)'
	String get shiny_auto_cooldown_label => 'Reset-Cooldown (ms)';

	/// de: 'Min. Schwarz-/Weißbild-Dauer (ms)'
	String get shiny_auto_transition_duration_label => 'Min. Schwarz-/Weißbild-Dauer (ms)';

	/// de: 'Tippen: Pause · Gedrückt halten: Manuell bereit (Re-Arm)'
	String get shiny_auto_slot_chip_tooltip => 'Tippen: Pause · Gedrückt halten: Manuell bereit (Re-Arm)';

	/// de: 'Live Auto-Log anzeigen'
	String get shiny_auto_logs_tooltip => 'Live Auto-Log anzeigen';

	/// de: 'Noch keine automatischen Zählungen in dieser Sitzung.'
	String get shiny_auto_logs_empty => 'Noch keine automatischen Zählungen in dieser Sitzung.';

	/// de: 'Rückgängig gemacht'
	String get shiny_auto_logs_undone => 'Rückgängig gemacht';

	/// de: 'Alle Slots bereit'
	String get shiny_auto_rearm_all_btn => 'Alle Slots bereit';

	/// de: 'Schwarzbild-Reset'
	String get shiny_auto_reason_black_reset => 'Schwarzbild-Reset';

	/// de: 'Weißbild-Reset'
	String get shiny_auto_reason_white_reset => 'Weißbild-Reset';

	/// de: 'Ei-Schlupf gestartet (Oh?)'
	String get shiny_auto_reason_egg_oh => 'Ei-Schlupf gestartet (Oh?)';

	/// de: 'Shiny erkannt: {name}'
	String get shiny_auto_reason_shiny => 'Shiny erkannt: {name}';

	/// de: 'Phase {phase} · {status}'
	String get multi_hunt_phase_status => 'Phase {phase} · {status}';

	/// de: 'Slot #{slot}'
	String get multi_hunt_slot_number => 'Slot #{slot}';

	/// de: 'EI-SCHLUPF'
	String get scanner_event_egg_hatched_badge => 'EI-SCHLUPF';

	/// de: 'Zählt bei erkannten wilden Begegnungen (+1 oder Horden-Anzahl). Macht sich nach Kampfende (Flucht/Sieg), Fang oder Schwarzbild-Übergang automatisch wieder scharf.'
	String get shiny_auto_mode_desc_wild => 'Zählt bei erkannten wilden Begegnungen (+1 oder Horden-Anzahl). Macht sich nach Kampfende (Flucht/Sieg), Fang oder Schwarzbild-Übergang automatisch wieder scharf.';

	/// de: 'Ideal für Starter, Legendäre & Geschenke. Zählt bei Erkennung des Pokémon und macht sich nach Titelbildschirm („Weiter“/„Continue“), Schwarzbild oder eigenem Reset-Text wieder scharf.'
	String get shiny_auto_mode_desc_soft_reset => 'Ideal für Starter, Legendäre & Geschenke. Zählt bei Erkennung des Pokémon und macht sich nach Titelbildschirm („Weiter“/„Continue“), Schwarzbild oder eigenem Reset-Text wieder scharf.';

	/// de: 'Zählt Masuda-/Zucht-Eier über den Schlupftext („… ist aus dem Ei geschlüpft!“) — bei „Alle Pokémon“ auch schon direkt bei „Oh?“. Macht sich pro Ei automatisch wieder scharf.'
	String get shiny_auto_mode_desc_egg => 'Zählt Masuda-/Zucht-Eier über den Schlupftext („… ist aus dem Ei geschlüpft!“) — bei „Alle Pokémon“ auch schon direkt bei „Oh?“. Macht sich pro Ei automatisch wieder scharf.';

	/// de: 'Zählt ohne Texterkennung anhand gleichmäßiger Schwarz-/Weißbild-Ladeübergänge (z. B. Overworld-Resets in Legenden: Arceus). Respektiert den Reset-Cooldown.'
	String get shiny_auto_mode_desc_transition => 'Zählt ohne Texterkennung anhand gleichmäßiger Schwarz-/Weißbild-Ladeübergänge (z. B. Overworld-Resets in Legenden: Arceus). Respektiert den Reset-Cooldown.';

	/// de: 'Jedes erkannte Pokémon löst +1 aus — ideal für Random Encounters und Shiny-Phasen.'
	String get shiny_auto_filter_desc_all => 'Jedes erkannte Pokémon löst +1 aus — ideal für Random Encounters und Shiny-Phasen.';

	/// de: 'Zählt nur, wenn das Ziel-Pokémon dieses Hunts erkannt wird — verhindert Fehlzählungen bei Starter-Intros oder fremden Pokémon.'
	String get shiny_auto_filter_desc_target => 'Zählt nur, wenn das Ziel-Pokémon dieses Hunts erkannt wird — verhindert Fehlzählungen bei Starter-Intros oder fremden Pokémon.';

	/// de: 'Erhöht bei Massen- oder Doppelbegegnungen um die gesamte erkannte Gegneranzahl statt +1.'
	String get shiny_auto_horde_desc => 'Erhöht bei Massen- oder Doppelbegegnungen um die gesamte erkannte Gegneranzahl statt +1.';

	/// de: 'Empfohlen für Soft-Resets & Ladebildschirme: Ein gleichmäßig schwarzer Übergang macht den Slot nach Ablauf des Cooldowns wieder scharf.'
	String get shiny_auto_black_reset_desc => 'Empfohlen für Soft-Resets & Ladebildschirme: Ein gleichmäßig schwarzer Übergang macht den Slot nach Ablauf des Cooldowns wieder scharf.';

	/// de: 'Nur aktivieren, wenn dein Spiel komplett weiß überblendet. Bei Spielen mit weißen Dialogboxen ausgeschaltet lassen.'
	String get shiny_auto_white_reset_desc => 'Nur aktivieren, wenn dein Spiel komplett weiß überblendet. Bei Spielen mit weißen Dialogboxen ausgeschaltet lassen.';

	/// de: 'Hält den betroffenen Scan-Slot sofort an, sobald ein Shiny-Signal erkannt wird, damit du den Treffer nicht versehentlich übergehst.'
	String get shiny_auto_pause_on_shiny_desc => 'Hält den betroffenen Scan-Slot sofort an, sobald ein Shiny-Signal erkannt wird, damit du den Treffer nicht versehentlich übergehst.';

	/// de: 'Optional für ROM-Hacks oder Fangames: Eigene Texte, die zählen sollen. Nutze {pokemon} als Platzhalter für den Pokémon-Namen.'
	String get shiny_auto_custom_triggers_desc => 'Optional für ROM-Hacks oder Fangames: Eigene Texte, die zählen sollen. Nutze {pokemon} als Platzhalter für den Pokémon-Namen.';

	/// de: 'Optional: Eigene Menü- oder Titelbildschirm-Wörter, die einen bereits gezählten Slot wieder scharf machen.'
	String get shiny_auto_custom_resets_desc => 'Optional: Eigene Menü- oder Titelbildschirm-Wörter, die einen bereits gezählten Slot wieder scharf machen.';

	/// de: 'Mindestwartezeit nach einem Reset/Übergang, bevor derselbe Slot wieder zählen darf (verhindert Doppelzählungen).'
	String get shiny_auto_cooldown_desc => 'Mindestwartezeit nach einem Reset/Übergang, bevor derselbe Slot wieder zählen darf (verhindert Doppelzählungen).';

	/// de: 'Wie lange der Bildschirm mindestens schwarz/weiß bleiben muss, um als echter Übergang statt Flackern zu gelten.'
	String get shiny_auto_transition_duration_desc => 'Wie lange der Bildschirm mindestens schwarz/weiß bleiben muss, um als echter Übergang statt Flackern zu gelten.';

	/// de: 'Schwarzbild-Schwelle (Luma {value})'
	String get shiny_auto_black_threshold_label => 'Schwarzbild-Schwelle (Luma {value})';

	/// de: 'Weißbild-Schwelle (Luma {value})'
	String get shiny_auto_white_threshold_label => 'Weißbild-Schwelle (Luma {value})';

	/// de: 'Tipp für Handykameras: Bei Restlicht im Raum die Schwarzbild-Schwelle höher (z. B. 35–50) und die Weißbild-Schwelle etwas niedriger stellen.'
	String get shiny_auto_thresholds_desc => 'Tipp für Handykameras: Bei Restlicht im Raum die Schwarzbild-Schwelle höher (z. B. 35–50) und die Weißbild-Schwelle etwas niedriger stellen.';

	/// de: 'Zählt für: {name}'
	String get shiny_auto_counting_for => 'Zählt für: {name}';

	/// de: 'Hierher wechseln'
	String get shiny_auto_switch_hunt_btn => 'Hierher wechseln';

	/// de: 'Auto-Counter vorgemerkt – startet automatisch, sobald der Scanner läuft.'
	String get shiny_auto_pending_banner => 'Auto-Counter vorgemerkt – startet automatisch, sobald der Scanner läuft.';

	/// de: 'Abbrechen'
	String get shiny_auto_pending_cancel => 'Abbrechen';

	/// de: 'Erklärung & Gesten anzeigen'
	String get shiny_auto_help_tooltip => 'Erklärung & Gesten anzeigen';

	/// de: 'Auto-Counter Legende & Gesten'
	String get shiny_auto_help_title => 'Auto-Counter Legende & Gesten';

	/// de: '• Bereit: Slot wartet auf die nächste Begegnung. • Gezählt: Treffer gezählt, wartet auf Kampfende/Reset. • Reset…: Cooldown läuft vor dem erneuten Scharfschalten. • Shiny!: Shiny erkannt – Slot pausiert bis zur Freigabe. • Pausiert: Slot manuell angehalten.'
	String get shiny_auto_help_phases_desc => '• Bereit: Slot wartet auf die nächste Begegnung.\n• Gezählt: Treffer gezählt, wartet auf Kampfende/Reset.\n• Reset…: Cooldown läuft vor dem erneuten Scharfschalten.\n• Shiny!: Shiny erkannt – Slot pausiert bis zur Freigabe.\n• Pausiert: Slot manuell angehalten.';

	/// de: 'Slot-Chips unten antippen = Slot pausieren/fortsetzen. Slot-Chip gedrückt halten = Slot sofort manuell wieder scharf machen (Re-Arm).'
	String get shiny_auto_help_gestures_desc => 'Slot-Chips unten antippen = Slot pausieren/fortsetzen.\nSlot-Chip gedrückt halten = Slot sofort manuell wieder scharf machen (Re-Arm).';

	/// de: 'Multi-Hunt-Anleitung'
	String get multi_hunt_help_tooltip => 'Multi-Hunt-Anleitung';

	/// de: 'Multi-Hunt Dashboard – So funktioniert's'
	String get multi_hunt_help_title => 'Multi-Hunt Dashboard – So funktioniert\'s';

	/// de: '• Parallele Hunts: Verwalte mehrere Spiele gleichzeitig nebeneinander (+1 / -1 / Pause / Phase). • Eigene Auto-Regeln (🎛️): Jede Karte kann eigene Erkennungsregeln (z. B. Wild, Soft Reset, Ei-Schlupf) erhalten. • Scan-Slots (+ Scan-Slots): Weise erkannte Multi-Instance-Slots (#1, #2, …) gezielt bestimmten Hunts zu. • Pausierte Hunts: Über den Button oben bei Bedarf ein- und wieder ausblenden.'
	String get multi_hunt_help_body => '• Parallele Hunts: Verwalte mehrere Spiele gleichzeitig nebeneinander (+1 / -1 / Pause / Phase).\n• Eigene Auto-Regeln (🎛️): Jede Karte kann eigene Erkennungsregeln (z. B. Wild, Soft Reset, Ei-Schlupf) erhalten.\n• Scan-Slots (+ Scan-Slots): Weise erkannte Multi-Instance-Slots (#1, #2, …) gezielt bestimmten Hunts zu.\n• Pausierte Hunts: Über den Button oben bei Bedarf ein- und wieder ausblenden.';

	/// de: 'v1.7 Neuheiten-Tour starten'
	String get tutorial_v17_tour_btn => 'v1.7 Neuheiten-Tour starten';

	/// de: 'Live-Tour'
	String get tutorial_start_live_tour => 'Live-Tour';

	/// de: 'Multi-Hunt Dashboard & Auto-Counter'
	String get tutorial_v17_shiny_f4_title => 'Multi-Hunt Dashboard & Auto-Counter';

	/// de: 'Parallele Hunts verwalten, eigene Erkennungsregeln setzen & automatisch per Scanner zählen!'
	String get tutorial_v17_shiny_f4_desc => 'Parallele Hunts verwalten, eigene Erkennungsregeln setzen & automatisch per Scanner zählen!';

	/// de: 'Neu in v1.7: Multi-Hunt & Auto-Counter'
	String get tutorial_v17_home_shiny_title => 'Neu in v1.7: Multi-Hunt & Auto-Counter';

	/// de: 'Im Shiny Hunt Tracker warten jetzt das Multi-Hunt Dashboard und der visuelle Auto-Counter auf dich! Sobald du ihn öffnest, erkläre ich dir dort alles Schritt für Schritt.'
	String get tutorial_v17_home_shiny_text => 'Im Shiny Hunt Tracker warten jetzt das Multi-Hunt Dashboard und der visuelle Auto-Counter auf dich! Sobald du ihn öffnest, erkläre ich dir dort alles Schritt für Schritt.';

	/// de: 'Multi-Hunt Dashboard & Auto-Counter'
	String get tutorial_shiny_dashboard_auto_title => 'Multi-Hunt Dashboard & Auto-Counter';

	/// de: 'Verwalte mehrere Hunts parallel im Multi-Hunt Dashboard und lass Begegnungen per visuellem Auto-Counter automatisch zählen!'
	String get tutorial_shiny_dashboard_auto_text => 'Verwalte mehrere Hunts parallel im Multi-Hunt Dashboard und lass Begegnungen per visuellem Auto-Counter automatisch zählen!';

	/// de: 'Neu: Multi-Hunt Dashboard'
	String get tutorial_shiny_hub_dashboard_title => 'Neu: Multi-Hunt Dashboard';

	/// de: 'Tippe hier auf das Raster-Icon, um das Multi-Hunt Dashboard zu öffnen – dort verwaltest du mehrere Hunts nebeneinander inklusive Auto-Counter!'
	String get tutorial_shiny_hub_dashboard_text => 'Tippe hier auf das Raster-Icon, um das Multi-Hunt Dashboard zu öffnen – dort verwaltest du mehrere Hunts nebeneinander inklusive Auto-Counter!';

	/// de: 'Neu: Visueller Auto-Counter'
	String get tutorial_shiny_counter_auto_title => 'Neu: Visueller Auto-Counter';

	/// de: 'Über dieses Fokus-Icon richtest du den visuellen Auto-Counter ein: Er erkennt Begegnungen, Resets und Ei-Schlüpfe automatisch über deinen Scanner und pausiert bei Shinys!'
	String get tutorial_shiny_counter_auto_text => 'Über dieses Fokus-Icon richtest du den visuellen Auto-Counter ein: Er erkennt Begegnungen, Resets und Ei-Schlüpfe automatisch über deinen Scanner und pausiert bei Shinys!';

	/// de: 'Wechsel ins Multi-Hunt Dashboard'
	String get tutorial_shiny_counter_dashboard_title => 'Wechsel ins Multi-Hunt Dashboard';

	/// de: 'Jagst du auf mehreren Spielen gleichzeitig? Tippe hier, um alle aktiven Hunts nebeneinander im Multi-Hunt Dashboard zu steuern.'
	String get tutorial_shiny_counter_dashboard_text => 'Jagst du auf mehreren Spielen gleichzeitig? Tippe hier, um alle aktiven Hunts nebeneinander im Multi-Hunt Dashboard zu steuern.';

	/// de: '12. Multi-Hunt & Auto-Counter'
	String get tutorial_chapter_shiny_auto_title => '12. Multi-Hunt & Auto-Counter';

	/// de: 'Parallele Hunts im Dashboard, Per-Hunt Auto-Regeln, Scan-Slots & Live-Steuerung.'
	String get tutorial_chapter_shiny_auto_desc => 'Parallele Hunts im Dashboard, Per-Hunt Auto-Regeln, Scan-Slots & Live-Steuerung.';

	/// de: 'Parallele Hunts im Dashboard'
	String get tutorial_auto_demo_dashboard_title => 'Parallele Hunts im Dashboard';

	/// de: 'Steuere beliebig viele Shiny Hunts gleichzeitig auf einer responsiven Übersichtskarte pro Jagd.'
	String get tutorial_auto_demo_dashboard_text => 'Steuere beliebig viele Shiny Hunts gleichzeitig auf einer responsiven Übersichtskarte pro Jagd.';

	/// de: 'Karten-Aktionen & Pausierte'
	String get tutorial_auto_demo_cards_title => 'Karten-Aktionen & Pausierte';

	/// de: 'Zähle direkt (+1 / -1), pausiere, trage Phasen ein, schließe Shinys ab oder blende pausierte Hunts ein.'
	String get tutorial_auto_demo_cards_text => 'Zähle direkt (+1 / -1), pausiere, trage Phasen ein, schließe Shinys ab oder blende pausierte Hunts ein.';

	/// de: 'Eigene Auto-Regeln pro Hunt'
	String get tutorial_auto_demo_rules_title => 'Eigene Auto-Regeln pro Hunt';

	/// de: 'Lege pro Karte fest, ob Wild-Begegnungen, Soft Resets, Ei-Schlüpfe oder Bildwechsel gezählt werden.'
	String get tutorial_auto_demo_rules_text => 'Lege pro Karte fest, ob Wild-Begegnungen, Soft Resets, Ei-Schlüpfe oder Bildwechsel gezählt werden.';

	/// de: 'Scan-Slots gezielt zuweisen'
	String get tutorial_auto_demo_slots_title => 'Scan-Slots gezielt zuweisen';

	/// de: 'Verbinde Multi-Instance-Slots (#1, #2, …) aus dem Scanner flexibel mit einzelnen Hunt-Karten.'
	String get tutorial_auto_demo_slots_text => 'Verbinde Multi-Instance-Slots (#1, #2, …) aus dem Scanner flexibel mit einzelnen Hunt-Karten.';

	/// de: 'Live-Leiste & Shiny-Schutz'
	String get tutorial_auto_demo_livebar_title => 'Live-Leiste & Shiny-Schutz';

	/// de: 'Mach Zähler per 1-Tipp rückgängig, sieh ins Live-Log und nutze die Shiny-Pause per OCR-Text/Symbol oder optionalen Beta-Heuristiken.'
	String get tutorial_auto_demo_livebar_text => 'Mach Zähler per 1-Tipp rückgängig, sieh ins Live-Log und nutze die Shiny-Pause per OCR-Text/Symbol oder optionalen Beta-Heuristiken.';

	/// de: 'Willkommen im Multi-Hunt Dashboard!'
	String get tutorial_multi_hunt_intro_title => 'Willkommen im Multi-Hunt Dashboard!';

	/// de: 'Bzzzt! Hier steuerst du beliebig viele Shiny Hunts gleichzeitig nebeneinander – manuell oder vollautomatisch über deinen Scanner.'
	String get tutorial_multi_hunt_intro_text => 'Bzzzt! Hier steuerst du beliebig viele Shiny Hunts gleichzeitig nebeneinander – manuell oder vollautomatisch über deinen Scanner.';

	/// de: 'Neue Hunts & Pausierte filtern'
	String get tutorial_multi_hunt_appbar_title => 'Neue Hunts & Pausierte filtern';

	/// de: 'Erstelle direkt neue Hunts über (+) oder blende pausierte Hunts oben bei Bedarf ein und wieder aus.'
	String get tutorial_multi_hunt_appbar_text => 'Erstelle direkt neue Hunts über (+) oder blende pausierte Hunts oben bei Bedarf ein und wieder aus.';

	/// de: 'Auto-Counter & Schnellhilfe'
	String get tutorial_multi_hunt_setup_title => 'Auto-Counter & Schnellhilfe';

	/// de: 'Über das Fokus-Icon öffnest du das Auto-Counter-Setup. Das (?)-Symbol liefert dir jederzeit eine kompakte Übersicht.'
	String get tutorial_multi_hunt_setup_text => 'Über das Fokus-Icon öffnest du das Auto-Counter-Setup. Das (?)-Symbol liefert dir jederzeit eine kompakte Übersicht.';

	/// de: 'Direkt-Steuerung pro Hunt-Karte'
	String get tutorial_multi_hunt_card_counter_title => 'Direkt-Steuerung pro Hunt-Karte';

	/// de: 'Jede Karte hat eigene + / - Tasten, Pause, Phase, Gefangen sowie einen Pfeil für die große Einzelansicht.'
	String get tutorial_multi_hunt_card_counter_text => 'Jede Karte hat eigene + / - Tasten, Pause, Phase, Gefangen sowie einen Pfeil für die große Einzelansicht.';

	/// de: 'Individuelle Auto-Regeln pro Hunt'
	String get tutorial_multi_hunt_card_rules_title => 'Individuelle Auto-Regeln pro Hunt';

	/// de: 'Über das Regler-Icon oder das Regel-Badge stellst du pro Hunt eigene Modi (Wild, Soft Reset, Ei-Schlupf) und Filter ein.'
	String get tutorial_multi_hunt_card_rules_text => 'Über das Regler-Icon oder das Regel-Badge stellst du pro Hunt eigene Modi (Wild, Soft Reset, Ei-Schlupf) und Filter ein.';

	/// de: 'Scan-Slots (#1, #2, …) zuweisen'
	String get tutorial_multi_hunt_card_slots_title => 'Scan-Slots (#1, #2, …) zuweisen';

	/// de: 'Ordne erkannte Multi-Instance-Slots aus deinem Desktop- oder Kamera-Scanner gezielt einzelnen Hunt-Karten zu!'
	String get tutorial_multi_hunt_card_slots_text => 'Ordne erkannte Multi-Instance-Slots aus deinem Desktop- oder Kamera-Scanner gezielt einzelnen Hunt-Karten zu!';

	/// de: '1. Scan-Quelle verbinden'
	String get tutorial_auto_setup_source_title => '1. Scan-Quelle verbinden';

	/// de: 'Sieh sofort, ob bereits ein Desktop- oder Kamera-Scanner läuft. Falls nicht, merkt sich PokéVault dein Setup und startet beim Scanner-Start automatisch.'
	String get tutorial_auto_setup_source_text => 'Sieh sofort, ob bereits ein Desktop- oder Kamera-Scanner läuft. Falls nicht, merkt sich PokéVault dein Setup und startet beim Scanner-Start automatisch.';

	/// de: '2. Erkennungsmodus wählen'
	String get tutorial_auto_setup_mode_title => '2. Erkennungsmodus wählen';

	/// de: 'Wähle ein Preset passend zur Methode: Wilde Begegnung, Soft Reset, Ei-Schlupf oder Nur Bildwechsel.'
	String get tutorial_auto_setup_mode_text => 'Wähle ein Preset passend zur Methode: Wilde Begegnung, Soft Reset, Ei-Schlupf oder Nur Bildwechsel.';

	/// de: '3. Trefferfilter & Bild-Resets'
	String get tutorial_auto_setup_filter_title => '3. Trefferfilter & Bild-Resets';

	/// de: 'Zähle alle Pokémon oder nur dein Ziel, aktiviere Horden-Zählung und nutze Schwarz-/Weißbild-Übergänge zum erneuten Scharfschalten.'
	String get tutorial_auto_setup_filter_text => 'Zähle alle Pokémon oder nur dein Ziel, aktiviere Horden-Zählung und nutze Schwarz-/Weißbild-Übergänge zum erneuten Scharfschalten.';

	/// de: '4. Eigene Trigger- & Reset-Wörter'
	String get tutorial_auto_setup_custom_title => '4. Eigene Trigger- & Reset-Wörter';

	/// de: 'Für ROM-Hacks oder Fangames kannst du eigene OCR-Texte für Treffer und Titelbildschirm-Resets ergänzen.'
	String get tutorial_auto_setup_custom_text => 'Für ROM-Hacks oder Fangames kannst du eigene OCR-Texte für Treffer und Titelbildschirm-Resets ergänzen.';

	/// de: '5. Timing & Helligkeitsschwellen'
	String get tutorial_auto_setup_timing_title => '5. Timing & Helligkeitsschwellen';

	/// de: 'Passe Cooldown, Übergangsdauer und Schwarz-/Weiß-Luma-Schwellen fein an deine Kamera oder dein Spiel an.'
	String get tutorial_auto_setup_timing_text => 'Passe Cooldown, Übergangsdauer und Schwarz-/Weiß-Luma-Schwellen fein an deine Kamera oder dein Spiel an.';

	/// de: '6. Shiny-Schutz & Starten'
	String get tutorial_auto_setup_safety_title => '6. Shiny-Schutz & Starten';

	/// de: 'Aktiviere Sound/Haptik, den automatischen Shiny-Pause-Schutz und bei Bedarf die Beta-Shiny-Heuristiken – tippe dann unten auf Starten bzw. Speichern!'
	String get tutorial_auto_setup_safety_text => 'Aktiviere Sound/Haptik, den automatischen Shiny-Pause-Schutz und bei Bedarf die Beta-Shiny-Heuristiken – tippe dann unten auf Starten bzw. Speichern!';

	/// de: 'Live-Leiste: Steuerung & Rückgängig'
	String get tutorial_auto_bar_controls_title => 'Live-Leiste: Steuerung & Rückgängig';

	/// de: 'Hier siehst du den Live-Status, machst Fehlzählungen mit einem Tipp rückgängig (↶), schaltest Slots per (↻) wieder scharf, prüfst das Log oder pausierst.'
	String get tutorial_auto_bar_controls_text => 'Hier siehst du den Live-Status, machst Fehlzählungen mit einem Tipp rückgängig (↶), schaltest Slots per (↻) wieder scharf, prüfst das Log oder pausierst.';

	/// de: 'Slot-Chips & Gesten'
	String get tutorial_auto_bar_slots_title => 'Slot-Chips & Gesten';

	/// de: 'Tippe einen farbigen Slot-Chip an zum Pausieren/Fortsetzen – oder halte ihn gedrückt (bzw. nutze das Re-Arm-Symbol), um den Slot sofort wieder scharf zu machen!'
	String get tutorial_auto_bar_slots_text => 'Tippe einen farbigen Slot-Chip an zum Pausieren/Fortsetzen – oder halte ihn gedrückt (bzw. nutze das Re-Arm-Symbol), um den Slot sofort wieder scharf zu machen!';

	/// de: 'Automatischer Shiny-Schutz'
	String get tutorial_auto_bar_shiny_title => 'Automatischer Shiny-Schutz';

	/// de: 'Bzzzt! Sobald ein Shiny-Text/Symbol (oder eine aktivierte Beta-Heuristik) auslöst, pausiert der Slot sofort mit einem goldenen Alarm-Banner!'
	String get tutorial_auto_bar_shiny_text => 'Bzzzt! Sobald ein Shiny-Text/Symbol (oder eine aktivierte Beta-Heuristik) auslöst, pausiert der Slot sofort mit einem goldenen Alarm-Banner!';

	/// de: 'Hinweis: Die Standard-OCR-Pause reagiert auf Texte/Symbole („Shiny“, „Schillernd“, ✨ – z. B. bei ROM-Hacks, Overlays oder Gen-9-HUD). Für offizielle Spiele kannst du zusätzlich die Beta-Heuristiken aktivieren.'
	String get shiny_auto_shiny_ocr_info => 'Hinweis: Die Standard-OCR-Pause reagiert auf Texte/Symbole („Shiny“, „Schillernd“, ✨ – z. B. bei ROM-Hacks, Overlays oder Gen-9-HUD). Für offizielle Spiele kannst du zusätzlich die Beta-Heuristiken aktivieren.';

	/// de: 'Sparkle-Delay-Erkennung (Beta)'
	String get shiny_auto_sparkle_delay_toggle => 'Sparkle-Delay-Erkennung (Beta)';

	/// de: 'Lernt die normale Zeit bis zum Kampfmenü (3 Begegnungen) und pausiert bei längerer Glitzer-Animation.'
	String get shiny_auto_sparkle_delay_desc => 'Lernt die normale Zeit bis zum Kampfmenü (3 Begegnungen) und pausiert bei längerer Glitzer-Animation.';

	/// de: 'Sparkle-Delay-Schwelle: +{ms} ms'
	String get shiny_auto_sparkle_delay_threshold_label => 'Sparkle-Delay-Schwelle: +{ms} ms';

	/// de: 'Farb-Abweichung / HSV-Baseline (Beta)'
	String get shiny_auto_color_dev_toggle => 'Farb-Abweichung / HSV-Baseline (Beta)';

	/// de: 'Vergleicht den Scan-Frame nach 3 normalen Encountern. Ideal bei ruhigem Emulator- oder Capture-Card-Bild.'
	String get shiny_auto_color_dev_desc => 'Vergleicht den Scan-Frame nach 3 normalen Encountern. Ideal bei ruhigem Emulator- oder Capture-Card-Bild.';

	/// de: 'Farb-Abweichungsschwelle: {pct}%'
	String get shiny_auto_color_dev_threshold_label => 'Farb-Abweichungsschwelle: {pct}%';

	/// de: 'Tipp für Starter/Geschenke: Wenn kein „Wildes Pokémon erscheint“-Text kommt, ergänze unten ein eigenes Trigger-Muster oder nutze den Bildwechsel-Modus.'
	String get shiny_auto_soft_reset_starter_hint => 'Tipp für Starter/Geschenke: Wenn kein „Wildes Pokémon erscheint“-Text kommt, ergänze unten ein eigenes Trigger-Muster oder nutze den Bildwechsel-Modus.';

	/// de: 'Gezählte Slots neu scharfschalten (Re-Arm)'
	String get shiny_auto_rearm_all_tooltip => 'Gezählte Slots neu scharfschalten (Re-Arm)';

	/// de: 'Slot #{slot} wieder scharf schalten'
	String get shiny_auto_rearm_single_tooltip => 'Slot #{slot} wieder scharf schalten';

	/// de: 'Gefangen'
	String get shiny_auto_shiny_mark_caught => 'Gefangen';

	/// de: 'OCR'
	String get shiny_auto_source_ocr => 'OCR';

	/// de: 'Sparkle-Delay'
	String get shiny_auto_source_sparkle_delay => 'Sparkle-Delay';

	/// de: 'Farb-Abweichung'
	String get shiny_auto_source_color_dev => 'Farb-Abweichung';

	/// de: 'Sparkle-Delay erkannt ({details})'
	String get shiny_auto_reason_sparkle_delay => 'Sparkle-Delay erkannt ({details})';

	/// de: 'Farb-Abweichung erkannt ({details})'
	String get shiny_auto_reason_color_dev => 'Farb-Abweichung erkannt ({details})';

	/// de: 'Multi-Hunt · Auto-Counter · Scan-Slots'
	String get tutorial_demo_shiny_auto_badge_title => 'Multi-Hunt · Auto-Counter · Scan-Slots';

	/// de: 'Parallele Hunts, Per-Hunt-Regeln & Shiny-Schutz'
	String get tutorial_demo_shiny_auto_badge_subtitle => 'Parallele Hunts, Per-Hunt-Regeln & Shiny-Schutz';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app_title' => 'PokéVault',
			'no_dex' => 'Noch kein Dex vorhanden.\nKlicke auf das \'+\' um einen zu erstellen!',
			'import_tooltip' => 'Importieren',
			'export_tooltip' => 'Exportieren',
			'create_dex_title' => 'Neuen Dex anlegen',
			'create_dex_hint' => 'Name (z.B. Mein Run)',
			'cancel' => 'Abbrechen',
			'back' => 'Zurück',
			'create' => 'Erstellen',
			'region' => 'Region',
			'caught' => 'Gefangen',
			'search_hint' => 'Suchen (Name oder ID)...',
			'filter_all' => 'Alle',
			'filter_caught' => 'Gefangen',
			'filter_missing' => 'Fehlt',
			'dark_mode' => 'Dark Mode',
			'settings' => 'Einstellungen',
			'selected' => 'ausgewählt',
			'edit' => 'Bearbeiten',
			'delete' => 'Löschen',
			'save' => 'Speichern',
			'badge_red' => 'R',
			'badge_blue' => 'B',
			'badge_yellow' => 'G',
			'badge_gold' => 'G',
			'badge_silver' => 'S',
			'badge_crystal' => 'K',
			'badge_ruby' => 'RU',
			'badge_sapphire' => 'SA',
			'badge_emerald' => 'SM',
			'badge_firered' => 'FR',
			'badge_leafgreen' => 'BG',
			'badge_diamond' => 'D',
			'badge_pearl' => 'P',
			'badge_platinum' => 'PT',
			'badge_heartgold' => 'HG',
			'badge_soulsilver' => 'SS',
			'badge_black' => 'S',
			'badge_white' => 'W',
			'badge_black_2' => 'S2',
			'badge_white_2' => 'W2',
			'badge_x' => 'X',
			'badge_y' => 'Y',
			'badge_omega_ruby' => 'Î©R',
			'badge_alpha_sapphire' => 'Î±S',
			'badge_sun' => 'S',
			'badge_moon' => 'M',
			'badge_ultra_sun' => 'US',
			'badge_ultra_moon' => 'UM',
			'badge_lets_go_pikachu' => 'LGP',
			'badge_lets_go_eevee' => 'LGE',
			'badge_sword' => 'SW',
			'badge_shield' => 'SH',
			'badge_the_isle_of_armor_sword' => 'SW EX',
			'badge_the_isle_of_armor_shield' => 'SH EX',
			'badge_the_crown_tundra_sword' => 'SW EX2',
			'badge_the_crown_tundra_shield' => 'SH EX2',
			'badge_brilliant_diamond' => 'SD',
			'badge_shining_pearl' => 'LP',
			'badge_legends_arceus' => 'PLA',
			'badge_scarlet' => 'KA',
			'badge_violet' => 'PU',
			'badge_the_teal_mask_scarlet' => 'KA EX',
			'badge_the_teal_mask_violet' => 'PU EX',
			'badge_the_indigo_disk_scarlet' => 'KA EX2',
			'badge_the_indigo_disk_violet' => 'PU EX2',
			'badge_legends_z_a' => 'PLZA',
			'badge_colosseum' => 'COLO',
			'badge_xd' => 'XD',
			'choose_generation' => 'Wähle eine Generation / Spiel',
			'exact_pokedex' => 'Genauer Pokédex',
			'include_forms' => 'Formen auswählen',
			'include_genders' => 'Geschlechter (M/W)',
			'include_trades' => 'In-Game Tausche',
			'include_gifts' => 'Geschenkte Pokémon',
			'include_glitch' => 'Glitch Pokémon (Game Boy)',
			'shiny_status' => 'Shiny Status',
			'shiny_lock_badge' => 'Shiny-Lock',
			'shiny_lock_banner' => 'Shiny-Lock aktiv',
			'shiny_lock_banner_desc' => 'Dieses Pokémon kann an dieser Stelle nicht in seiner schillernden Form erhalten werden.',
			'form_regional' => 'Regionalformen',
			'form_regional_short' => 'Regionalformen',
			'form_mega' => 'Mega',
			'form_gmax' => 'Gigadynamax',
			'form_other' => 'Sonstige (Kostüme, Pokusan...)',
			'form_other_short' => 'Sonstige (Kostüme...)',
			'delete_confirm_title' => 'Dex löschen?',
			'delete_confirm_text' => 'Möchtest du diesen Dex wirklich löschen? Das kann nicht rückgängig gemacht werden.',
			'delete_multiple_confirm_title' => 'Dexe löschen?',
			'delete_multiple_confirm_text' => 'Möchtest du die ausgewählten Dexe wirklich löschen?',
			'import_success' => 'Pokédex erfolgreich importiert!',
			'backup_success' => 'Backup erfolgreich gespeichert unter:',
			'share_text' => 'Hier ist mein PokéVault Backup!',
			'json_files' => 'JSON Dateien',
			'error' => 'Fehler:',
			'error_load' => 'Fehler beim Laden:',
			'error_save' => 'Fehler beim Speichern:',
			'error_export' => 'Fehler beim Exportieren:',
			'error_import' => 'Fehler beim Importieren:',
			'error_start_app' => 'Fehler beim Starten der App:',
			'error_getting_available_features' => 'Fehler beim bekomen von allen Optionen:',
			'error_show_edit_dex_dialog' => 'Fehler beim Anzeigen des Dex-Bearbeiten-Popups:',
			'error_confirm_delete' => 'Fehler beim Bestätigen beim Löschen des Dexes:',
			'error_confirm_multiple_delete' => 'Fehler beim Bestätigen zum Löschen von mehreren Dexen:',
			'error_get_form_display_name' => 'Fehler beim Anzeigen der Form:',
			'error_build_display_entries' => 'Fehler beim bauen des Dexes:',
			'error_show_language_dialog' => 'Fehler beim Anzeigen der Sprachauswahl:',
			'error_show_colorpicker_dialog' => 'Fehler beim Anzeigen der Farbauswahl:',
			'error_load_prefs' => 'Fehler beim Laden der Präferenzen:',
			'error_update_theme_color' => 'Fehler beim aktualisieren der Theme-Farben:',
			'error_update_background_color' => 'Fehler beim aktualisieren der Hintergrundfarbe:',
			'error_add_custom_color' => 'Fehler beim hinzufügen einer eigenen Farbe:',
			'error_reset_to_default' => 'Fehler beim zurücksetzen der Farben:',
			'error_launch_url' => 'Konnte URL nicht öffnen:',
			'error_toggle_shiny' => 'Fehler beim Shiny eingeben:',
			'error_loading_encounters' => 'Fehler beim Laden der Fundorte:',
			'group_custom' => 'Eigener Dex',
			'region_custom_empty' => 'Leerer Dex',
			'group_national' => 'National',
			'group_kanto' => 'Kanto',
			'group_johto' => 'Johto',
			'group_hoenn' => 'Hoenn',
			'group_sinnoh' => 'Sinnoh',
			'group_unova' => 'Einall',
			'group_kalos' => 'Kalos & Z-A',
			'group_alola' => 'Alola',
			'group_galar' => 'Galar',
			'group_hisui' => 'Hisui',
			'group_paldea' => 'Paldea',
			'form_name_alola' => 'Alola',
			'form_name_galar' => 'Galar',
			'form_name_hisui' => 'Hisui',
			'form_name_paldea' => 'Paldea',
			'form_name_mega' => 'Mega',
			'form_name_mega_x' => 'Mega X',
			'form_name_mega_y' => 'Mega Y',
			'form_name_gmax' => 'Gigadynamax',
			'form_name_spiky_eared' => 'Strubbelohr',
			'form_name_cosplay' => 'Cosplay',
			'form_name_original_cap' => 'Original-Kappe',
			'form_name_exclamation' => '!',
			'form_name_question' => '?',
			'form_name_primal' => 'Protomorphose',
			'form_name_meadow' => 'Ziergarten',
			'form_name_icy_snow' => 'Schneefeld',
			'form_name_polar' => 'Schneeparadies',
			'form_name_tundra' => 'Tundra',
			'form_name_continental' => 'Kontinental',
			'form_name_garden' => 'Blumenmeer',
			'form_name_elegant' => 'Prunk',
			'form_name_modern' => 'Modern',
			'form_name_marine' => 'Aquamarin',
			'form_name_archipelago' => 'Archipel',
			'form_name_high_plains' => 'Dürre',
			'form_name_sandstorm' => 'Sand',
			'form_name_river' => 'Fluss',
			'form_name_monsoon' => 'Monsun',
			'form_name_savanna' => 'Savanne',
			'form_name_sun' => 'Sonne',
			'form_name_ocean' => 'Ozean',
			'form_name_jungle' => 'Dschungel',
			'form_name_fancy' => 'Fantasie',
			'form_name_poke_ball' => 'Pokéball',
			'form_name_red' => 'Rot',
			'form_name_yellow' => 'Gelb',
			'form_name_orange' => 'Orange',
			'form_name_blue' => 'Blau',
			'form_name_white' => 'Weiß',
			'form_name_indigo' => 'Indigo',
			'form_name_violet' => 'Violett',
			'form_name_green' => 'Grün',
			'form_name_spring' => 'Frühling',
			'form_name_summer' => 'Sommer',
			'form_name_autumn' => 'Herbst',
			'form_name_winter' => 'Winter',
			'form_name_small' => 'Klein',
			'form_name_average' => 'Normal',
			'form_name_large' => 'Groß',
			'form_name_super' => 'Super',
			'form_name_baile' => 'Flamenco',
			'form_name_pom_pom' => 'Cheerleading',
			'form_name_pau' => 'Hula',
			'form_name_sensu' => 'Buyo',
			'form_name_vanilla_cream' => 'Vanille',
			'form_name_ruby_cream' => 'Ruby',
			'form_name_matcha_cream' => 'Matcha',
			'form_name_mint_cream' => 'Minz',
			'form_name_lemon_cream' => 'Zitrone',
			'form_name_salted_cream' => 'Salz',
			'form_name_ruby_swirl' => 'Ruby-Mix',
			'form_name_caramel_swirl' => 'Karamell-Mix',
			'form_name_rainbow_swirl' => 'Regenbogen-Mix',
			'form_name_eternal' => 'Ewigblütler',
			'form_name_totem' => 'Herrscher',
			'form_name_totem_alola' => 'Herrscher',
			'form_name_totem_busted' => 'Herrscher (Entlarvt)',
			'form_name_totem_disguised' => 'Herrscher (Verkleidet)',
			'form_name_own_tempo' => 'Tempomacher',
			'form_name_midday' => 'Tagform',
			'form_name_midnight' => 'Nachtform',
			'form_name_dusk' => 'Zwielichtform',
			'form_name_dawn' => 'Morgenschwingen',
			'form_name_dusk_mane' => 'Abendmähne',
			'form_name_dawn_wings' => 'Morgenschwingen',
			'form_name_ultra' => 'Ultra',
			'form_name_solo' => 'Einzelform',
			'form_name_school' => 'Schwarmform',
			'form_name_disguised' => 'Verkleidet',
			'form_name_busted' => 'Entlarvt',
			'form_name_amped' => 'Hoch',
			'form_name_low_key' => 'Tief',
			'form_name_ice_face' => 'Eisgesicht',
			'form_name_noice_face' => 'Wellenbrecher',
			'form_name_male' => '♂',
			'form_name_female' => '♀',
			'form_name_full_belly' => 'Pappsatt',
			'form_name_hangry' => 'Kohldampf',
			'form_name_crowned' => 'König',
			'form_name_eternamax' => 'Unendynamax',
			'form_name_single_strike' => 'Fokussierter Stil',
			'form_name_rapid_strike' => 'Fließender Stil',
			'form_name_dada' => 'Dada',
			'form_name_ice_rider' => 'Schimmelreiter',
			'form_name_shadow_rider' => 'Rappenreiter',
			'form_name_bloodmoon' => 'Blutmond',
			'form_name_incarnate' => 'Inkarnationsform',
			'form_name_therian' => 'Tiergeistform',
			'form_name_family_of_three' => 'Dreierfamilie',
			'form_name_family_of_four' => 'Viererfamilie',
			'form_name_green_plumage' => 'Grünes Gefieder',
			'form_name_blue_plumage' => 'Blaues Gefieder',
			'form_name_yellow_plumage' => 'Gelbes Gefieder',
			'form_name_white_plumage' => 'Weißes Gefieder',
			'form_name_zero' => 'Alltagsform',
			'form_name_hero' => 'Heldenform',
			'form_name_curly' => 'Gebogene Form',
			'form_name_droopy' => 'Hängende Form',
			'form_name_stretchy' => 'Gestreckte Form',
			'form_name_chest' => 'Truhenform',
			'form_name_roaming' => 'Wanderform',
			'form_name_phony' => 'Fälschung',
			'form_name_antique' => 'Original',
			'form_name_counterfeit' => 'Fälschung',
			'form_name_artisan' => 'Original',
			'form_name_unremarkable' => 'Minderwertige Form',
			'form_name_masterpiece' => 'Kostbare Form',
			'form_name_teal_mask' => 'Türkisgrüne Maske',
			'form_name_wellspring_mask' => 'Brunnenmaske',
			'form_name_hearthflame_mask' => 'Ofenmaske',
			'form_name_cornerstone_mask' => 'Fundamentmaske',
			'form_name_terastal' => 'Terakristall',
			'form_name_stellar' => 'Stellar',
			'form_name_west' => 'Westliches Meer',
			'form_name_east' => 'Östliches Meer',
			'form_name_overcast' => 'Geschlossene Form',
			'form_name_sunshine' => 'Sonnenform',
			'form_name_plant' => 'Pflanzenlumpen',
			'form_name_sandy' => 'Sandlumpen',
			'form_name_trash' => 'Lumpenlumpen',
			'form_name_origin' => 'Urform',
			'form_name_altered' => 'Wandelform',
			'form_name_land' => 'Landform',
			'form_name_sky' => 'Zenitform',
			'form_name_attack' => 'Angriffsform',
			'form_name_defense' => 'Verteidigungsform',
			'form_name_speed' => 'Initiativeform',
			'form_name_ordinary' => 'Standardform',
			'form_name_resolute' => 'Resolutform',
			'form_name_aria' => 'Gesangsform',
			'form_name_pirouette' => 'Tanzform',
			'form_name_black' => 'Schwarz',
			'form_name_douse' => 'Aquamodul',
			'form_name_shock' => 'Blitzmodul',
			'form_name_burn' => 'Flammenmodul',
			'form_name_chill' => 'Gefriermodul',
			'form_name_active' => 'Aktivmodus',
			'form_name_neutral' => 'Neutralmodus',
			'form_name_10_power_construct' => '10% (Scharwandel)',
			'form_name_50_power_construct' => '50% (Scharwandel)',
			'form_name_complete' => 'Optimum',
			'form_name_10' => '10%',
			'form_name_50' => '50%',
			'form_name_unbound' => 'Entfesselt',
			'form_name_bug' => 'Käfer',
			'form_name_dark' => 'Unlicht',
			'form_name_dragon' => 'Drache',
			'form_name_electric' => 'Elektro',
			'form_name_fairy' => 'Fee',
			'form_name_fighting' => 'Kampf',
			'form_name_fire' => 'Feuer',
			'form_name_flying' => 'Flug',
			'form_name_ghost' => 'Geist',
			'form_name_grass' => 'Pflanze',
			'form_name_ground' => 'Boden',
			'form_name_ice' => 'Eis',
			'form_name_poison' => 'Gift',
			'form_name_psychic' => 'Psycho',
			'form_name_rock' => 'Gestein',
			'form_name_steel' => 'Stahl',
			'form_name_water' => 'Wasser',
			'form_name_unknown' => 'Unbekannt',
			'region_national_overall' => 'Nationaldex',
			'region_kanto_regional' => 'Kanto (Regional)',
			'region_johto_regional' => 'Johto (Regional)',
			'region_updated_johto_regional' => 'Johto (HG/SS Remake)',
			'region_hoenn_regional' => 'Hoenn (Regional)',
			'region_updated_hoenn_regional' => 'Hoenn (OR/AS Remake)',
			'region_sinnoh_regional' => 'Sinnoh (Regional)',
			'region_unova_regional' => 'Einall (Regional)',
			'region_kalos_central_regional' => 'Kalos (Zentral)',
			'region_kalos_coastal_regional' => 'Kalos (Küste)',
			'region_kalos_mountain_regional' => 'Kalos (Gebirge)',
			'region_lumiose_regional' => 'Illumina (Z-A)',
			'region_lumiose_dimensions_regional' => 'Dimensions Illumina (Z-A)',
			'region_alola_regional' => 'Alola (Gesamt)',
			'region_melemele_regional' => 'Alola (Melemele-Insel)',
			'region_akala_regional' => 'Alola (Akala-Insel)',
			'region_ulaula_regional' => 'Alola (Ula-Ula-Insel)',
			'region_poni_regional' => 'Alola (Poni-Insel)',
			'region_galar_regional' => 'Galar (Regional)',
			'region_isle_of_armor_regional' => 'Galar (Rüstungsinsel)',
			'region_crown_tundra_regional' => 'Galar (Schneelande der Krone)',
			'region_hisui_regional' => 'Hisui (Regional)',
			'region_paldea_regional' => 'Paldea (Regional)',
			'region_kitakami_regional' => 'Paldea (Kitakami-Provinz)',
			'region_blueberry_regional' => 'Paldea (Blaubeer-Akademie)',
			'region_letsgo_kanto_regional' => 'Kanto (Let"s Go)',
			'region_extended_sinnoh_regional' => 'Sinnoh (Platin)',
			'region_updated_unova_regional' => 'Einall (S2/W2 Remix)',
			'region_updated_alola_regional' => 'Alola (US/UM Gesamt)',
			'region_updated_melemele_regional' => 'Alola (US/UM Melemele)',
			'region_updated_akala_regional' => 'Alola (US/UM Akala)',
			'region_updated_ulaula_regional' => 'Alola (US/UM Ula-Ula)',
			'region_updated_poni_regional' => 'Alola (US/UM Poni)',
			'region_special_dex' => 'Spezial Dexe',
			'region_mega_dex' => 'Mega Dex',
			'region_icognito_dex' => 'Unkown Dex',
			'region_glitch_dex' => 'Glitch Dex',
			'form_name_vc_glitch' => 'Game Boy (VC Glitch)',
			'form_vc_glitch' => 'Game Boy (VC Glitch)',
			'appearance' => 'Erscheinungsbild',
			'choose_accent_color' => 'Akzentfarbe',
			'choose_bg_color' => 'Hintergrundfarbe',
			'general' => 'Allgemein',
			'language' => 'Sprache',
			'current_language' => 'Deutsch',
			'pokemon_language' => 'Pokémon-Sprache',
			'language_auto' => 'Automatisch',
			'language_auto_desc' => 'Folgt App-Sprache',
			'data_management' => 'Datenverwaltung',
			'apply' => 'Übernehmen',
			'reset_theme' => 'Standarddesign wiederherstellen',
			'credits' => 'Danksagungen & Quellen',
			'credit_api_title' => 'PokéAPI & Sprites',
			'credit_api_sub' => 'Basisdaten und offizielle Artworks',
			'credit_inspi_title' => 'Living Dex Inspiration',
			'credit_inspi_sub' => 'Community Google Sheet für Tracker-Basis',
			'credit_shiny_gen1_title' => 'Gen 1 Shiny Hunting',
			'credit_shiny_gen1_sub' => 'BlueMoonFalls Guide für DV-Werte',
			'credit_shiny_silph_scope_title' => 'Silph Scope Shiny Hunting',
			'credit_shiny_silph_scope_sub' => 'Porygondolier (Gen 1 DV-Reroll Entdeckung)',
			'credit_glitch_gen2_title' => 'Gen 2 Mail Writer Codes',
			'credit_glitch_gen2_sub' => 'GlitchCity Wiki für Gen 3 Shiny Starter',
			'credit_balls_title' => 'Matching Balls Guide',
			'credit_balls_sub' => 'Community Sheet für passende Pokébälle',
			'credit_ai_title' => 'Google Gemini',
			'credit_ai_sub' => 'KI-Assistenz beim Programmieren & Refactoring',
			'credit_pokewiki_title' => 'PokéWiki',
			'credit_pokewiki_sub' => 'Umfangreiche Wissensdatenbank',
			'credit_bisafans_title' => 'Bisafans',
			'credit_bisafans_sub' => 'Guides und Tutorials',
			'view_list' => 'Zur Listen-Ansicht',
			'view_box' => 'Zur PC-Box Ansicht',
			'sort_dex' => 'Nach PokéDex (Normal)',
			'sort_forms' => 'Nach Regionen & Formen',
			'tooltip_view_sort' => 'Ansicht & Sortierung',
			'empty_box' => 'Keine Pokémon gefunden.',
			'box' => 'Box',
			'cat_females' => 'Weibchen',
			'cat_alternate' => 'Alternativ',
			'cat_cap' => 'Cap Pikachu',
			'cat_unown' => 'Icognitodex',
			'cat_vivillon' => 'Vivillon',
			'cat_alcremie' => 'Pokusan',
			'cat_gmax' => 'Gigantamax',
			'cat_regional' => 'Regionalformen',
			'cat_mega' => 'Mega',
			'region_name_kanto' => 'Kanto',
			'region_name_johto' => 'Johto',
			'region_name_hoenn' => 'Hoenn',
			'region_name_sinnoh' => 'Sinnoh',
			'region_name_unova' => 'Einall',
			'region_name_kalos' => 'Kalos',
			'region_name_alola' => 'Alola',
			'region_name_galar' => 'Galar',
			'region_name_hisui' => 'Hisui',
			'region_name_paldea' => 'Paldea',
			'region_name_lumiose' => 'Illumina',
			'region_name_unknown' => 'Unbekannt',
			'region_name_gmax' => 'Galar G-Max',
			'jump_to_region' => 'Zu Region springen...',
			'extra_info' => 'Zusatzinformationen',
			'form' => 'Form',
			'games_appearance' => 'Kommt vor in',
			'games_catchable' => 'Fangbar in',
			'events' => 'Event-Verteilungen',
			'ignore_pokemon' => 'Aus Dex entfernen',
			'ignore_confirm_title' => 'Pokémon entfernen?',
			'ignore_confirm_text' => 'Möchtest du dieses Pokémon ausblenden? Du kannst es im Menü jederzeit wiederherstellen.',
			'ignored_list_title' => 'Ausgeblendete Pokémon',
			'restore_pokemon' => 'Wiederherstellen',
			'empty_ignored' => 'Es wurden keine Pokémon ausgeblendet.',
			'placeholder_text' => 'Wird in zukünftigen Updates hinzugefügt.',
			'shiny_dex' => 'Shiny Dex',
			'encounters_title' => 'Fundorte & Begegnungen',
			'no_encounters_found' => 'Keine Fundorte bekannt (oder noch nicht generiert).',
			'encounter_missing_note' => 'Hinweis: Wenn eine Edition nicht aufgeführt ist, ist das Pokémon dort in der Regel nur durch Entwicklung, Tausch oder Transfer erhältlich.',
			'gen_1' => 'Generation 1',
			'gen_2' => 'Generation 2',
			'gen_3' => 'Generation 3',
			'gen_4' => 'Generation 4',
			'gen_5' => 'Generation 5',
			'gen_6' => 'Generation 6',
			'gen_7' => 'Generation 7',
			'gen_8' => 'Generation 8',
			'gen_9' => 'Generation 9',
			'version_red' => 'Rote Edition',
			'version_blue' => 'Blaue Edition',
			'version_yellow' => 'Gelbe Edition',
			'version_gold' => 'Goldene Edition',
			'version_silver' => 'Silberne Edition',
			'version_crystal' => 'Kristall Edition',
			'version_ruby' => 'Rubin Edition',
			'version_sapphire' => 'Saphir Edition',
			'version_emerald' => 'Smaragd Edition',
			'version_firered' => 'Feuerrote Edition',
			'version_leafgreen' => 'Blattgrüne Edition',
			'version_diamond' => 'Diamant Edition',
			'version_pearl' => 'Perl Edition',
			'version_platinum' => 'Platin Edition',
			'version_heartgold' => 'HeartGold',
			'version_soulsilver' => 'SoulSilver',
			'version_black' => 'Schwarze Edition',
			'version_white' => 'Weiße Edition',
			'version_black_2' => 'Schwarz 2',
			'version_white_2' => 'Weiß 2',
			'version_x' => 'Pokémon X',
			'version_y' => 'Pokémon Y',
			'version_omega_ruby' => 'Omega Rubin',
			'version_alpha_sapphire' => 'Alpha Saphir',
			'version_sun' => 'Sonne',
			'version_moon' => 'Mond',
			'version_ultra_sun' => 'Ultrasonne',
			'version_ultra_moon' => 'Ultramond',
			'version_lets_go_pikachu' => 'Let"s Go Pikachu',
			'version_lets_go_eevee' => 'Let"s Go Evoli',
			'version_sword' => 'Schwert',
			'version_shield' => 'Schild',
			'version_the_isle_of_armor_sword' => 'Rüstungsinsel (SW)',
			'version_the_isle_of_armor_shield' => 'Rüstungsinsel (SH)',
			'version_the_crown_tundra_sword' => 'Schneelande der Krone (SW)',
			'version_the_crown_tundra_shield' => 'Schneelande der Krone (SH)',
			'version_brilliant_diamond' => 'Strahlender Diamant',
			'version_shining_pearl' => 'Leuchtende Perle',
			'version_legends_arceus' => 'Legenden: Arceus',
			'version_scarlet' => 'Karmesin',
			'version_violet' => 'Purpur',
			'version_the_teal_mask_scarlet' => 'Die Türkisgrüne Maske (KA)',
			'version_the_teal_mask_violet' => 'Die Türkisgrüne Maske (PU)',
			'version_the_indigo_disk_scarlet' => 'Die Indigoblaue Scheibe (KA)',
			'version_the_indigo_disk_violet' => 'Die Indigoblaue Scheibe (PU)',
			'version_legends_z_a' => 'Legenden: Z-A',
			'version_colosseum' => 'Pokémon Colosseum',
			'version_xd' => 'Pokémon XD: Der Dunkle Sturm',
			'region_legendary_dex' => 'Legenden Dex',
			'region_mythical_dex' => 'Mysteriöse Dex',
			'group_egg_groups' => 'Eigruppen',
			'region_egg_monster' => 'Eigruppe: Monster',
			'region_egg_water1' => 'Eigruppe: Wasser 1',
			'region_egg_water2' => 'Eigruppe: Wasser 2',
			'region_egg_water3' => 'Eigruppe: Wasser 3',
			'region_egg_bug' => 'Eigruppe: Käfer',
			'region_egg_flying' => 'Eigruppe: Flug',
			'region_egg_ground' => 'Eigruppe: Feld',
			'region_egg_fairy' => 'Eigruppe: Fee',
			'region_egg_plant' => 'Eigruppe: Pflanze',
			'region_egg_humanshape' => 'Eigruppe: Humanotyp',
			'region_egg_mineral' => 'Eigruppe: Mineral',
			'region_egg_indeterminate' => 'Eigruppe: Amorph',
			'region_egg_ditto' => 'Eigruppe: Ditto',
			'region_egg_dragon' => 'Eigruppe: Drache',
			'region_egg_no_eggs' => 'Eigruppe: Unbekannt',
			'any_ball' => 'Beliebig / Unbekannt',
			'matching_balls' => 'Matching Balls',
			'ball_poke_ball' => 'Pokéball',
			'ball_great_ball' => 'Superball',
			'ball_ultra_ball' => 'Hyperball',
			'ball_master_ball' => 'Meisterball',
			'ball_safari_ball' => 'Safariball',
			'ball_level_ball' => 'Levelball',
			'ball_lure_ball' => 'Köderball',
			'ball_moon_ball' => 'Mondball',
			'ball_friend_ball' => 'Freundesball',
			'ball_love_ball' => 'Sympaball',
			'ball_heavy_ball' => 'Schwerball',
			'ball_fast_ball' => 'Turboball',
			'ball_sport_ball' => 'Turnierball',
			'ball_premier_ball' => 'Premierball',
			'ball_repeat_ball' => 'Wiederball',
			'ball_timer_ball' => 'Timerball',
			'ball_nest_ball' => 'Nestball',
			'ball_net_ball' => 'Netzball',
			_ => null,
		} ?? switch (path) {
			'ball_dive_ball' => 'Tauchball',
			'ball_luxury_ball' => 'Luxusball',
			'ball_heal_ball' => 'Heilball',
			'ball_quick_ball' => 'Flottball',
			'ball_dusk_ball' => 'Finsterball',
			'ball_cherish_ball' => 'Jubelball',
			'ball_dream_ball' => 'Traumball',
			'ball_beast_ball' => 'Ultraball',
			'ball_strange_ball' => 'Seltsamer Ball',
			'shiny_guide_title' => 'Shiny Guide',
			'shiny_guide_gen1' => 'Generation 1',
			'shiny_guide_gen1_desc' => 'Tipp: Fange/Züchte das Pokémon in Gen 2 und tausche es per Zeitkapsel nach Gen 1. Wenn du es dann auf Pokémon Bank/HOME überträgst, behält es seinen Shiny-Status, bekommt das Gameboy-Icon und als Herkunftsort \'Kanto\'!',
			'shiny_stat_calculator' => 'Shiny Stat Rechner',
			'level' => 'Level',
			'base_stats' => 'Basiswerte',
			'table_hp_0' => 'Tabelle 1 (KP DV: 0)',
			'table_hp_8' => 'Tabelle 2 (KP DV: 8)',
			'stat_hp' => 'KP',
			'stat_atk' => 'ANG',
			'stat_def' => 'VER',
			'stat_spe' => 'INIT',
			'stat_spc' => 'SPEZ',
			'shiny_huntable_yes' => 'Regulär Huntbar: Ja',
			'shiny_huntable_no' => 'Regulär Huntbar: Nein',
			'notable_encounters' => 'Besondere Begegnungen:',
			'tutorials_mew' => 'Mew 8F-Glitch Tutorials:',
			'tutorial_mew_video_de' => 'Video Tutorial (DE) - LEOsMIND',
			'tutorial_mew_video_en' => 'Video Tutorial (EN) - Austin John',
			'tutorial_mew_text_en' => 'Text Tutorial (EN) - extratricky',
			'tutorials_silph_scope' => 'Pokémon-Turm Silph Scope Tutorial:',
			'tutorial_silph_scope_video_en' => 'Video Tutorial (EN) - Porygondolier',
			'shiny_gen1_silph_scope_desc' => 'Im Pokémon-Turm (Lavandia) sorgt das Silph Scope beim Identifizieren der Geister für einen DV-Reroll. Dadurch können Nebulak, Alpollo, Tragosso und Knogga regulär als Shiny mit der Chance 1:8192 gefangen werden!',
			'method_starter' => 'Starter',
			'method_gift' => 'Geschenk',
			'method_trade' => 'NPC-Tausch',
			'method_fossil' => 'Fossil',
			'method_egg' => 'Ei',
			'method_surf' => 'Surfen',
			'method_old_rod' => 'Angel',
			'method_good_rod' => 'Profiangel',
			'method_super_rod' => 'Superangel',
			'method_fly' => 'Fliegen',
			'method_fighting_dojo' => 'Kampf-Dojo',
			'method_event_trade' => 'Event / Tausch',
			'shiny_breed_calc_title' => 'Shiny Zucht-Ketten Rechner (Gen 2)',
			'shiny_breed_start' => 'Start-Pokémon (Männliches Shiny)',
			'shiny_breed_target' => 'Ziel-Pokémon',
			'shiny_breed_calc_btn' => 'Kette berechnen',
			'shiny_breed_no_path' => 'Keine Zuchtkette gefunden.',
			'shiny_breed_note' => 'Hinweis: Die Zucht-Kette funktioniert nur, wenn das Ziel-Pokémon (und alle Zwischenstufen) weiblich sein können. Für rein männliche oder geschlechtslose Pokémon benötigst du ein Shiny Ditto.',
			'shiny_breed_female_note' => 'Tipp: Wenn dein Start-Pokémon ein weibliches Shiny ist, paare es zuerst mit einem normalen Männchen derselben Art. Das erzeugt mit einer Chance von 1:64 ein Shiny, welches (je nach Geschlechterverhältnis) männlich sein könnte. Mit diesem kannst du dann diese Kette starten!',
			'shiny_breed_step_female' => 'Paare ♂ Shiny {0} mit ♀ {1} ➔ ♀ {2} (1:64)',
			'shiny_breed_step_male' => 'Paare ♂ Shiny {0} mit ♀ {0} ➔ ♂ Shiny {0} (1:64)',
			'shiny_breed_step_final' => 'Paare ♂ Shiny {0} mit ♀ {1} ➔ ♂/♀ Shiny {2} (1:64)',
			'shiny_breed_step_ditto' => 'Paare Shiny Ditto mit {0} ➔ Shiny {1} (1:64)',
			'shiny_breed_chance' => 'Chance: 1:64',
			'shiny_breed_success' => 'Chance: 1:64 (Ziel erreicht!)',
			'shiny_breed_evo_step' => 'Entwicklung: ',
			'soft_reset' => 'Soft Reset',
			'shiny_ditto_guide' => 'Shiny Ditto bekommen (Für Zucht)',
			'shiny_guide_gen2' => 'Generation 2',
			'shiny_guide_gen3' => 'Generation 3',
			'shiny_guide_gen4' => 'Generation 4',
			'shiny_guide_gen5' => 'Generation 5',
			'shiny_guide_gen6' => 'Generation 6',
			'shiny_guide_gen7' => 'Generation 7',
			'shiny_hunt_methods_soon' => 'Weitere Jagdmethoden werden in Zukunft hinzugefügt.',
			'shiny_guide_missing_note' => 'Hinweis: Wenn eine Generation nicht aufgeführt ist, kann das Pokémon dort nicht regulär als Shiny gejagt/gezüchtet werden (oder die Jagdmethoden werden in zukünftigen Updates ergänzt).',
			'shiny_odd_egg_title' => 'Das Kurios-Ei (Pokémon Kristall)',
			'shiny_odd_egg_desc' => 'In Pokémon Kristall erhältst du in der Pension das Kurios-Ei. Daraus schlüpft ein zufälliges Baby-Pokémon. Die Shiny-Chance ist massiv erhöht: 14% in der westlichen Version und sogar 50% in der japanischen Version!',
			'shiny_mail_writer_title' => 'Gen 3 Starter in Gen 2 (Mail Writer Glitch)',
			'shiny_mail_writer_note' => 'Hinweis: Mit dem Mail Writer Glitch können in Pokémon Gold/Silber/Kristall die ersten Pokémon der 3. Generation generiert werden. Beim Transfer über den PokéMover auf die Pokémon Bank werden diese dann völlig legal als Gen 3 Starter anerkannt!',
			'tutorial_mail_writer_main' => 'Text Tutorial (EN) - Mail Writer Codes',
			'tutorial_mail_writer_scripts' => 'Text Tutorial (EN) - Gen3Giver Scripts',
			'mail_writer_glitch' => 'Mail Writer Glitch',
			'community_support' => 'Community & Support',
			'report_issue_title' => 'Fehler oder fehlende Daten melden',
			'report_issue_sub' => 'Erstelle ein Ticket (Issue) auf GitHub',
			'contribute_title' => 'Selber beitragen',
			'contribute_sub' => 'Hilf mit via Pull Request (.json Dateien)',
			'tutorial_mew_normal_text' => 'Text Tutorial (Mew-Glitch)',
			'error_shiny_guide' => 'Fehler beim Laden des Shiny-Guides:',
			'mew_glitch_note' => 'Hinweis: Mew kann in den Spielen der 1. Generation durch den bekannten \'Mew-Glitch\' (Trainer-Flucht-Glitch) gefangen werden, welcher es dir ermöglicht, ein wildes Mew auf Level 7 anzutreffen.',
			'tutorial_mew_normal_link' => 'Text Tutorial (EN) - Reddit',
			'method_mew_glitch' => 'Mew-Glitch',
			'shiny_roamer_gen2_title' => 'Wander-Pokémon (Legendäre Raubkatzen)',
			'shiny_roamer_gen2_beasts_note' => 'Hinweis: Die Statuswerte (und damit der Shiny-Status) von Raikou und Entei werden in Gold, Silber und Kristall bereits festgelegt, wenn sie in der Turmruine freigelassen werden! Du musst also vor dem Freilassen speichern, sie suchen und bei Nicht-Erfolg das Spiel neustarten (Soft Reset).',
			'shiny_roamer_gen2_suicune_note' => 'Hinweis: In Gold und Silber wird Suicunes Shiny-Status beim Freilassen in der Turmruine festgelegt (wie bei Raikou/Entei). In Pokémon Kristall hingegen ist Suicune ein statisches Event im Zinnturm und kann dort ganz normal per Soft Reset gejagt werden!',
			'shiny_breed_mechanics_title' => 'Wichtige Zucht-Mechaniken (Gen 2)',
			'shiny_breed_mechanics_dv_passing' => 'Warum dieser Geschlechter-Wechsel? In Gen 2 wird der Shiny-Status immer an das *andere* Geschlecht vererbt. Ein männliches Shiny erzeugt also immer ein weibliches Shiny und umgekehrt. Daher muss das Geschlecht bei jedem Zuchtschritt wechseln!',
			'shiny_breed_dv_conflict_text' => 'Inzest-Sperre: Pokémon verweigern die Zucht (\'Sie zeigen kein Interesse\'), wenn ihre Verteidigungs- und Spezial-DVs identisch sind. Da dein Shiny seine DVs vererbt, fange dir einfach ein neues normales Partner-Pokémon in der Wildnis, falls der Pensionsleiter diesen Spruch aufsagt!',
			'only_caught_pokemon' => 'Nur gefangene Pokémon für Route verwenden',
			'no_path_caught' => 'Es konnte keine Zucht-Route mit deinen gefangenen Pokémon generiert werden.',
			'no_path_impossible' => 'Unmöglich! Dieses Pokémon hat eine zu geringe Weibchen-Rate (oder ist rein männlich/geschlechtslos) und kann daher in Gen 2 nicht als Shiny von einer anderen Spezies gezüchtet werden. Du MUSST ein Shiny Ditto verwenden!',
			'odds_total' => 'Gesamt',
			'odds_gender' => 'Geschlecht',
			'impossible' => 'Unmöglich!',
			'shiny_breed_carrier_note' => 'Hinweis: Da weibliche Shinys bei dieser Spezies mathematisch unmöglich sind (durch Gen 2 Programmierung), erhältst du hier ein normal aussehendes Weibchen, das die Shiny-Gene in sich trägt (Gen-Trägerin). Du erkennst sie daran, dass der Pensionsleiter \'Sie zeigen kein Interesse\' sagt, wenn du sie mit dem Vater paarst!',
			'carrier' => 'Trägerin',
			'chance_carrier' => 'Chance: 1:2 (Gen-Trägerin)',
			'update_available_title' => 'Neues Update verfügbar!',
			'dismiss' => 'Später',
			'download_update' => 'Update herunterladen',
			'updates' => 'Updates',
			'check_for_updates' => 'Nach Updates suchen',
			'up_to_date' => 'Die App ist auf dem neuesten Stand.',
			'new_version' => 'Neue Version',
			'update_backup_warning' => 'Tipp: Exportiere zur Sicherheit deine PokéDexe über die Einstellungen (Datenverwaltung), bevor du das Update durchführst!',
			'update_backup_button' => 'Backup jetzt erstellen',
			'update_backup_done' => 'Backup erstellt ✓',
			'downgrades_title' => 'Vorherige Versionen (Downgrades)',
			'attention_downgrade' => 'Achtung: Downgrade',
			'downgrade_warning_text' => 'Du bist dabei, auf eine ältere Version der App zurückzukehren. Dabei können neue Funktionen verloren gehen oder Inkompatibilitäten auftreten.\n\nWICHTIG FÜR ANDROID: Android blockiert direkte Downgrades. Du musst die App erst deinstallieren und die heruntergeladene APK manuell installieren.\n\nBitte exportiere VORHER unbedingt deine Dexe in den Einstellungen als Backup!',
			'downgrade_execute' => 'Downgrade ausführen',
			'downgrade_backup_title' => 'Vorher Backup erstellen?',
			'downgrade_backup_text' => 'Möchtest du deine aktuellen PokéDexe vor dem Downgrade sichern? Das wird dringend empfohlen!',
			'downgrade_backup_create' => 'Backup erstellen',
			'downgrade_backup_skip' => 'Ohne Backup fortfahren',
			'downgrade_final_warning_title' => 'Letzte Warnung',
			'downgrade_final_warning_text' => 'Bist du dir absolut sicher, dass du auf diese alte Version downgraden möchtest? Hast du dein Backup gemacht?',
			'downgrade_final_confirm' => 'Ja, Downgrade starten',
			'encounter_level' => 'Level',
			'encounter_chance' => 'Häufigkeit',
			'encounter_method' => 'Methode',
			'encounter_location' => 'Ort',
			'method_walk' => 'Hohes Gras',
			'method_only_one' => 'Einmalig / Statisch',
			'route_tracker' => 'Routen-Tracker',
			'route_tracker_empty' => 'Keine Fundorte für diese Edition gefunden.',
			'hide_caught' => 'Gefangene ausblenden',
			'select_version' => 'Edition wählen',
			'search_help_title' => 'Such-Befehle',
			'search_help_id' => 'Sucht exakt nach einer ID.',
			'search_help_range' => 'Zeigt Pokémon im ID-Bereich.',
			'search_help_status' => 'Filtert nach Status.',
			'search_help_forms' => 'Filtert nach Formen.',
			'search_help_family' => 'Zeigt die gesamte Entwicklungsreihe des Pokémon.',
			'search_help_wildcard' => 'Wildcard-Suche (* ersetzt beliebige Zeichen).',
			'search_help_and' => 'Mit \'&\' müssen beide Begriffe zutreffen (UND).',
			'search_help_or' => 'Mit \',\' reicht ein Treffer (ODER).',
			'type_normal' => 'Normal',
			'type_fire' => 'Feuer',
			'type_water' => 'Wasser',
			'type_electric' => 'Elektro',
			'type_grass' => 'Pflanze',
			'type_ice' => 'Eis',
			'type_fighting' => 'Kampf',
			'type_poison' => 'Gift',
			'type_ground' => 'Boden',
			'type_flying' => 'Flug',
			'type_psychic' => 'Psycho',
			'type_bug' => 'Käfer',
			'type_rock' => 'Gestein',
			'type_ghost' => 'Geist',
			'type_dragon' => 'Drache',
			'type_dark' => 'Unlicht',
			'type_steel' => 'Stahl',
			'type_fairy' => 'Fee',
			'caught_status' => 'Gefangen Status',
			'mark_as_caught' => 'Als gefangen markieren',
			'catch_calculator_title' => 'Fangratenrechner',
			'catch_rate_base' => 'Basis-Fangrate',
			'generation' => 'Generation',
			'hp_percent' => 'Verbleibende KP (%)',
			'pokeball_bonus' => 'Pokéball',
			'status_condition' => 'Statusveränderung',
			'status_none' => 'Keine',
			'status_par_psn_brn' => 'Paralyse / Gift / Verbrennung',
			'status_slp_frz' => 'Schlaf / Frost',
			'catch_chance' => 'Geschätzte Fangchance',
			'critical_catch_chance' => 'Chance auf Kritischen Fang',
			'guaranteed_catch' => 'Sicherer Fang!',
			'dex_caught' => 'Gefangene Pokémon (Für Kritischen Fang)',
			'glitch_warning' => 'Gen {0} Glitch simuliert!',
			'calc_ball_poke' => 'Pokéball / Premierball (1x)',
			'calc_ball_great' => 'Superball (1.5x)',
			'calc_ball_ultra' => 'Hyperball (2x)',
			'calc_ball_gen1_poke' => 'Pokéball',
			'calc_ball_gen1_great' => 'Superball (Glitchy bei hoher KP)',
			'calc_ball_gen1_ultra' => 'Hyperball / Safariball',
			'calc_ball_fast' => 'Turboball (nur Magnetilo/Sleima/Tangela)',
			'calc_ball_love' => 'Sympaball (GLITCH: Nur exakt gleiche Spezies & Geschlecht)',
			'calc_ball_moon' => 'Mondball (GLITCH: Wirkt wie Pokéball)',
			'calc_ball_lure' => 'Köderball (Beim Angeln)',
			'calc_ball_heavy_minus' => 'Schwerball (Leichte Pokémon: -20 Rate)',
			'calc_ball_heavy_plus' => 'Schwerball (Schwere Pokémon: +20 bis +40 Rate)',
			'calc_ball_net' => 'Netzball (Käfer/Wasser) (3x/3.5x)',
			'calc_ball_dive' => 'Tauchball (Beim Surfen/Tauchen) (3.5x)',
			'calc_ball_nest' => 'Nestball (Geringes Level) (Bis zu 4x)',
			'calc_ball_timer' => 'Timerball (Runde 10+) (4x)',
			'calc_ball_quick' => 'Flottball (Runde 1) (5x)',
			'calc_ball_dusk' => 'Finsterball (Nachts/Höhle) (3x/3.5x)',
			'calc_base_rate' => 'Basis-Fangrate',
			'calc_modified_rate' => '(Angepasst durch Schwerball von {0})',
			'calc_battle_conditions' => 'Kampf-Bedingungen',
			'calc_bonus_power' => 'Zusatzkraft',
			'calc_power_none' => 'Keine Kraft aktiv (1.0x)',
			'calc_power_o1' => 'O-Kraft: Fangkraft Lv. 1 (1.5x)',
			'calc_power_o2' => 'O-Kraft: Fangkraft Lv. 2 (2.0x)',
			'calc_power_o3' => 'O-Kraft: Fangkraft Lv. 3 (2.5x)',
			'calc_power_roto' => 'Rotom-Fangkraft (2.5x)',
			'calc_power_sand1' => 'Sandwich: Fangkraft Lv. 1 (1.1x)',
			'calc_power_sand2' => 'Sandwich: Fangkraft Lv. 2 (1.25x)',
			'calc_power_sand3' => 'Sandwich: Fangkraft Lv. 3 (2.0x)',
			'calc_enemy_level' => 'Level des wilden Pokémon: {0}',
			'calc_own_level' => 'Level deines Pokémon: {0}',
			'calc_gen8_penalty' => '⚠️ In Gen 8 wird die Fangchance extrem bestraft, wenn dein Level niedriger ist!',
			'calc_turn_count' => 'Aktuelle Runde im Kampf: {0}',
			'calc_water_encounter' => 'Angeln / Surfen Begegnung?',
			'calc_night_cave' => 'Nachts oder in einer Höhle?',
			'calc_love_condition' => 'Gleiche Spezies & anderes Geschlecht?',
			'calc_already_caught' => 'Pokémon bereits im Dex registriert?',
			'calc_crit_settings' => 'Kritischer Fang',
			'calc_power_pass1' => 'Transferkraft Lv. 1 (1.1x)',
			'calc_power_pass2' => 'Transferkraft Lv. 2 (1.2x)',
			'calc_power_pass3' => 'Transferkraft Lv. 3 (1.3x)',
			'glitch_gen1_great' => 'Bug-Hinweis: In Gen 1 ist der Superball bei fast vollen KP durch einen Rundungsfehler sogar effektiver als der Hyperball!',
			'glitch_gen2_love' => 'Bug-Hinweis: In Gen 2 wirkt der Sympaball nur, wenn das Pokémon exakt dieselbe Spezies UND das identische Geschlecht deines eigenen Pokémon hat (sonst immer 1x).',
			'glitch_gen2_moon' => 'Bug-Hinweis: In Gen 2 wirkt der Mondball wegen eines Programmierfehlers nie (Bonus ist immer 1x).',
			'glitch_gen2_fast' => 'Bug-Hinweis: In Gen 2 wirkt der Turboball wegen eines Programmierfehlers ausschließlich auf Sleima, Sleimok, Tangela, Magnetilo und Magneton.',
			'catching_charm' => 'Fangpin (Basis-Item) im Beutel?',
			'calc_dark_grass' => 'Dunkles hohes Gras (Gen 5)',
			'ball_poke_hisui' => 'Hisui-Pokéball',
			'ball_great_hisui' => 'Hisui-Superball',
			'ball_ultra_hisui' => 'Hisui-Hyperball',
			'ball_heavy_hisui' => 'Hisui-Schwerball',
			'ball_leaden' => 'Zentnerball',
			'ball_gigaton' => 'Tonnenball',
			'ball_feather' => 'Federball',
			'ball_wing' => 'Flügelball',
			'ball_jet' => 'Düsenball',
			'ball_origin' => 'Ursprungsball',
			'berry_razz' => 'Himmihbeere (1.5x)',
			'berry_silver_razz' => 'Silberne Himmihbeere (2.25x)',
			'berry_golden_razz' => 'Goldene Himmihbeere (2.5x)',
			'calc_flying' => 'Pokémon fliegt hoch in der Luft',
			'calc_berry_let_go' => 'Gefütterte Beere (Let"s Go)',
			'calc_hisui_status' => 'Begegnungs-Status (Hisui)',
			'hisui_status_0' => 'Im Kampf / Hat dich bemerkt (1.0x)',
			'hisui_status_1' => 'Ahnungslos / Im Gras versteckt (1.5x)',
			'hisui_status_2' => 'Rückangriff (2.0x)',
			'hisui_status_3' => 'Betäubt durch Items (1.25x / Alphas 3.0x)',
			'error_calc_catch_rate' => 'Fehler bei der Berechnung der Fangrate:',
			'error_calc_catch_rate_ui' => 'Fehler bei der UI-Eingabe (Fangrate):',
			'calc_max_raid' => 'Dyna-Raid',
			'calc_max_raid_guest' => 'Raid-Gast?',
			'calc_max_raid_gmax' => 'Gigadynamax?',
			'calc_backstrike' => 'Rückenangriff',
			'calc_target_shiny' => 'Ziel ist Shiny',
			'calc_catch_window' => 'Fangfenster (betäubt)',
			'calc_alpha' => 'Alpha Pokémon',
			'calc_za_rank' => 'Z-A Royale Rang',
			'calc_plush_level' => 'Kanari-Plüsch Level',
			'calc_plush_none' => 'Kein Plüsch',
			'calc_donut_penalty' => 'Donut Dimensions-Malus',
			'calc_donut_none' => 'Kein Malus',
			'calc_donut_minus1' => '1 Stern niedriger (-10%)',
			'calc_donut_minus2' => '2+ Sterne niedriger (-70%)',
			'calc_missing_badges' => 'Fehlende Orden (Gehorsam)',
			'calc_unnoticed' => 'Unbemerkt (Rücken/Tarnung)',
			'shiny_form' => 'Shiny Form',
			'normal_form' => 'Normale Form',
			'backup_success_android' => 'Backup erfolgreich im Downloads-Ordner gespeichert!',
			'backup_fallback_android' => 'Direktes Speichern fehlgeschlagen. Bitte wähle einen Speicherort manuell aus.',
			'folder_create_title' => 'Neuer Ordner',
			'folder_name_hint' => 'Ordnername',
			'folder_rename_title' => 'Ordner umbenennen',
			'folder_move_title' => 'Verschieben nach...',
			'folder_empty' => 'Hier ist es noch leer.',
			'action_rename' => 'Umbenennen',
			'action_move' => 'Verschieben...',
			'action_delete_keep' => 'Löschen (Inhalt bleibt erhalten)',
			'action_open' => 'Ordner öffnen',
			'sort_manual' => 'Manuell',
			'sort_az' => 'A-Z',
			'sort_progress' => 'Fortschritt',
			'sort_region' => 'Region',
			'error_cyclic_move' => 'Fehler: Ein Ordner kann nicht in sich selbst oder seine eigenen Unterordner verschoben werden!',
			'delete_folder_title' => 'Ordner löschen',
			'delete_folder_text' => 'Möchtest du diesen Ordner wirklich löschen? Der Inhalt wird sicher auf den Hauptbildschirm verschoben.',
			'folder_root' => 'Hauptverzeichnis',
			'success_delete_folder' => 'Ordner erfolgreich gelöscht.',
			'error_delete_folder' => 'Fehler beim Löschen des Ordners:',
			'success_delete_dex' => 'Pokédex erfolgreich gelöscht.',
			'error_delete_dex' => 'Fehler beim Löschen des Pokédex:',
			'error_move_item' => 'Fehler beim Verschieben:',
			'success_move_item' => 'Erfolgreich verschoben.',
			'breeding_info_title' => 'Zucht und Entwicklung',
			'gender_ratio' => 'Geschlechter',
			'egg_groups' => 'Ei-Gruppen',
			'gender_genderless' => 'Geschlechtslos',
			'evo_base_form' => 'Basisform / Ei',
			'evo_baby' => 'Baby-Pokémon',
			'egg_group_monster' => 'Monster',
			'egg_group_water1' => 'Wasser 1',
			'egg_group_bug' => 'Käfer',
			'egg_group_flying' => 'Flug',
			'egg_group_ground' => 'Feld',
			'egg_group_fairy' => 'Fee',
			'egg_group_plant' => 'Pflanze',
			'egg_group_humanshape' => 'Humanoid',
			'egg_group_water3' => 'Wasser 3',
			'egg_group_mineral' => 'Mineral',
			'egg_group_amorphous' => 'Amorph',
			'egg_group_water2' => 'Wasser 2',
			'egg_group_ditto' => 'Ditto',
			'egg_group_noeggs' => 'Unbekannt',
			'trigger_level_up' => 'Levelaufstieg',
			'trigger_use_item' => 'Item anwenden',
			'trigger_trade' => 'Tausch',
			'trigger_spin' => 'Drehung',
			'trigger_three_critical_hits' => '3 Volltreffer in einem Kampf',
			'trigger_three_defeated_bisharp' => '3 Gladiantri mit Anführersymbol besiegen',
			'trigger_gimmighoul_coins' => '999 Gierspenst-Münzen',
			'trigger_tower_of_darkness' => 'Turm des Unlichts',
			'trigger_tower_of_waters' => 'Turm des Wassers',
			'trigger_shed' => 'Freier Platz im Team & Pokéball',
			'trigger_recoil_damage' => 'Rückstoß-Schaden',
			'trigger_take_damage' => 'Schaden erlitten',
			'trigger_strong_style_move' => 'Kraft-Technik einsetzen',
			'trigger_agile_style_move' => 'Tempo-Technik einsetzen',
			'trigger_use_move' => 'Attacke einsetzen',
			'trigger_other' => 'Besondere Bedingung',
			'evo_level' => 'Level {0}',
			'evo_level_above' => 'ab Level {0}',
			'evo_happiness' => 'hohe Zuneigung',
			'evo_affection' => 'hohe Zutraulichkeit',
			'evo_beauty' => 'Schönheit {0}+',
			'evo_time_day' => 'am Tag',
			'evo_time_night' => 'in der Nacht',
			'evo_time_dusk' => 'in der Dämmerung',
			'evo_time_full_moon' => 'bei Vollmond',
			'evo_held_item' => 'trägt {0}',
			'evo_move' => 'Attacke {0}',
			'evo_move_type' => '{0}-Attacke',
			'evo_location' => 'an Ort {0}',
			'evo_special_rock' => 'in der Nähe eines Moos-/Eisfelsens',
			'evo_magnetic_field' => 'besonderes Magnetfeld',
			'evo_rain' => 'bei Regen',
			'evo_upside_down' => 'Konsole umdrehen',
			'evo_party_species' => 'mit {0} im Team',
			'evo_party_type' => 'mit {0}-Pokémon im Team',
			'evo_trade_species' => 'gegen {0}',
			'species_remoraid' => 'Remoraid',
			'species_shelmet' => 'Schnuthelm',
			'species_karrablast' => 'Laukaps',
			'evo_multiplayer' => 'im Mehrspielermodus',
			'evo_steps' => 'nach {0} Schritten (Let\'s Go)',
			'evo_damage' => '{0}+ Schaden',
			'evo_move_count' => '{0}× eingesetzt',
			'evo_gender_female' => 'weiblich',
			'evo_gender_male' => 'männlich',
			'evo_stat_atk_gt_def' => 'Angriff > Vert.',
			'evo_stat_atk_lt_def' => 'Angriff < Vert.',
			'evo_stat_atk_eq_def' => 'Angriff = Vert.',
			'item_water_stone' => 'Wasserstein',
			'item_fire_stone' => 'Feuerstein',
			'item_thunder_stone' => 'Donnerstein',
			'item_leaf_stone' => 'Blattstein',
			'item_moon_stone' => 'Mondstein',
			'item_sun_stone' => 'Sonnenstein',
			'item_shiny_stone' => 'Leuchtstein',
			'item_dusk_stone' => 'Finsterstein',
			'item_dawn_stone' => 'Funkelstein',
			'item_ice_stone' => 'Eisstein',
			'item_auspicious_armor' => 'Glorienrüstung',
			'item_black_augurite' => 'Schwarzaugit',
			'item_chipped_pot' => 'Löchrige Kanne',
			'item_cracked_pot' => 'Rissige Kanne',
			'item_galarica_cuff' => 'Galarnuss-Reif',
			'item_galarica_wreath' => 'Galarnuss-Kranz',
			'item_malicious_armor' => 'Fluchrüstung',
			'item_masterpiece_teacup' => 'Edle Teeschale',
			'item_metal_alloy' => 'Legierungsmetall',
			'item_peat_block' => 'Torfblock',
			'item_scroll_of_darkness' => 'Unlicht-Schriftrolle',
			'item_scroll_of_waters' => 'Wasser-Schriftrolle',
			'item_sweet_apple' => 'Süßer Apfel',
			'item_syrupy_apple' => 'Saftiger Apfel',
			'item_tart_apple' => 'Saurer Apfel',
			'item_unremarkable_teacup' => 'Simple Teeschale',
			'item_deep_sea_scale' => 'Abyssplatte',
			'item_deep_sea_tooth' => 'Abysszahn',
			'item_dragon_scale' => 'Drachenhaut',
			'item_dubious_disc' => 'Dubiosdisc',
			'item_electirizer' => 'Stromisierer',
			'item_kings_rock' => 'King-Stein',
			'item_magmarizer' => 'Magmaisierer',
			'item_metal_coat' => 'Metallmantel',
			'item_oval_stone' => 'Ovaler Stein',
			'item_prism_scale' => 'Schönschuppe',
			'item_protector' => 'Schützer',
			'item_razor_claw' => 'Scharfklaue',
			'item_razor_fang' => 'Scharfzahn',
			'item_reaper_cloth' => 'Düsterumhang',
			'item_sachet' => 'Duftbeutel',
			'item_up_grade' => 'Up-Grade',
			'item_whipped_dream' => 'Sahnehäubchen',
			'move_ancient_power' => 'Antik-Kraft',
			'move_barb_barrage' => 'Giftstachelregen',
			'move_double_hit' => 'Doppelschlag',
			'move_dragon_cheer' => 'Drachenschrei',
			'move_dragon_pulse' => 'Drachenpuls',
			'move_hyper_drill' => 'Hyperbohrer',
			'move_mimic' => 'Mimikry',
			'move_psyshield_bash' => 'Barrierenstoß',
			'move_rage_fist' => 'Zornesfaust',
			'move_rollout' => 'Walzer',
			'move_stomp' => 'Stampfer',
			'move_taunt' => 'Verhöhner',
			'move_twin_beam' => 'Doppelstrahl',
			'loc_blush_mountain' => 'Glühberg',
			'loc_chargestone_cave' => 'Elektrolithhöhle',
			'loc_eterna_forest' => 'Ewigwald',
			'loc_frost_cavern' => 'Frosthöhle',
			'loc_kalos_route_13' => 'Route 13 (Kalos)',
			'loc_kalos_route_20' => 'Route 20 (Kalos)',
			'loc_lush_jungle' => 'Schattendschungel',
			'loc_mount_lanakila' => 'Mount Lanakila',
			'loc_mt_coronet' => 'Kraterberg',
			'loc_new_mauville' => 'Neu Malvenfroh',
			'loc_petalburg_woods' => 'Blütenburgwald',
			'loc_pinwheel_forest' => 'Ewigenwald',
			'loc_shoal_cave' => 'Küstenhöhle',
			'loc_sinnoh_route_217' => 'Route 217 (Sinnoh)',
			'loc_twist_mountain' => 'Wendelberg',
			'loc_vast_poni_canyon' => 'Canyon von Poni',
			'tutorial_skip' => 'Überspringen',
			'tutorial_next' => 'Weiter',
			'tutorial_finish' => 'Verstanden!',
			'tutorial_menu_title' => 'Tutorials & Hilfe',
			'tutorial_center_title' => 'Tutorials & Anleitungen',
			'tutorial_center_subtitle' => 'Lerne alle Funktionen von PokéVault kennen oder wiederhole gezielt einzelne Bereiche.',
			'tutorial_v16_tour_btn' => 'v1.6 Neuheiten-Tour starten',
			'tutorial_chapters_header' => 'Themen & Kapitel',
			'tutorial_replay' => 'Wiederholen',
			'tutorial_replay_all' => 'Alle Tutorials zurücksetzen',
			'tutorial_replay_all_success' => 'Alle Tutorials wurden zurückgesetzt!',
			'tutorial_reset_confirm_msg' => 'Möchtest du wirklich alle Tutorials zurücksetzen? Beim nächsten Besuch werden wieder alle Hilfen und Erklärungen angezeigt.',
			'tutorial_tour_started' => 'v1.6 Neuheiten-Tour aktiviert!',
			'tutorial_v16_badge' => 'UPDATE v1.6',
			'tutorial_v16_welcome_title' => 'Bzzzt! Neue Features entdeckt!',
			'tutorial_v16_welcome_desc' => 'Hallo Trainer! Während du fleißig gesammelt hast, habe ich dein PokéVault mit neuen Werkzeugen aufgerüstet:',
			'tutorial_v16_start_tour' => 'Neuheiten-Tour starten',
			'tutorial_v16_skip' => 'Später ansehen',
			'tutorial_v16_f1_title' => 'Shiny Hunt Tracker',
			'tutorial_v16_f1_desc' => 'Counter, Phasen, Quoten & Timer für deine Jagden!',
			'tutorial_v16_f2_title' => 'Eigene Boxen & Stapel-Drag',
			'tutorial_v16_f2_desc' => 'Boxen umbenennen, Inhalte per Stapel frei verschieben!',
			'tutorial_v16_f3_title' => 'Statistiken & Share-Card',
			'tutorial_v16_f3_desc' => 'Erfolge als schicke Grafik mit Trainernamen teilen!',
			'tutorial_v16_f4_title' => 'Geschlechtsunterschiede & Details',
			'tutorial_v16_f4_desc' => 'Vergleichende Ansichten, Zuchtrechner & Fundorte!',
			'tutorial_chapter_home_title' => '1. Home & Sammlung',
			'tutorial_chapter_home_desc' => 'Dexe anlegen, Spiele auswählen, Ordner erstellen und Sammlungen frei sortieren.',
			'tutorial_home_organize_title' => 'Ordner & Sortierung',
			'tutorial_home_organize_text' => 'Organisiere deine Dexe in Ordnern und passe ihre Anordnung beliebig per Drag & Drop an.',
			'tutorial_chapter_create_dex_title' => '2. Dex-Erstellung & Filter',
			'tutorial_chapter_create_dex_desc' => 'Spezifische Unter-Dexe wählen, Shinys, Geschlechter, Formen, Megas & G-Max aktivieren.',
			'tutorial_chapter_dex_screen_title' => '3. Pokédex & Fangliste',
			'tutorial_chapter_dex_screen_desc' => 'Pokémon als gefangen markieren, Listen- vs. Boxansicht, Ignorier-Funktion & Filter.',
			'tutorial_dex_tap_catch_title' => 'Gefangen markieren',
			'tutorial_dex_tap_catch_text' => 'Tippe auf eine Karte, um den Fangstatus blitzschnell zwischen gefangen und offen umzuschalten.',
			'tutorial_dex_details_title' => 'Pokémon-Details',
			'tutorial_dex_details_text' => 'Halte eine Pokémon-Karte lange gedrückt, um ihre Details, Attacken, Zucht und Fundorte zu öffnen.',
			'tutorial_dex_modes_title' => 'Listen- & Boxansicht',
			'tutorial_dex_modes_text' => 'Wechsle oben rechts zwischen der klassischen Listenansicht und der authentischen PC-Boxenansicht.',
			'tutorial_dex_filter_title' => 'Filter & Suchleiste',
			'tutorial_dex_filter_text' => 'Filtere nach Status (Gefangen/Fehlend), Typen oder suche blitzschnell nach Namen und Nummern.',
			'tutorial_chapter_box_mgmt_title' => '4. Box-Management (v1.6)',
			'tutorial_chapter_box_mgmt_desc' => 'Eigene Boxen anlegen, umbenennen, Reihenfolge anpassen & Stapel-Verschieben nutzen.',
			'tutorial_box_custom_title' => 'Eigene Boxen anlegen',
			'tutorial_box_custom_text' => 'Erstelle und benenne Boxen wie in deinen Original-Spielen (z. B. \'Kanto Living Dex 1\').',
			'tutorial_box_batch_title' => 'Mehrfachauswahl',
			'tutorial_box_batch_text' => 'Tippe auf mehrere Pokémon, um sie gemeinsam als Stapel auszuwählen und zu bewegen.',
			'tutorial_box_drag_title' => 'Drag & Drop Verschiebung',
			'tutorial_box_drag_text' => 'Verschiebe Pokémon per Drag & Drop flexibel auf freie Slots oder tausche Plätze.',
			'tutorial_box_shift_title' => 'Auto-Shift & Platzhalter',
			'tutorial_box_shift_text' => 'Aktiviere Auto-Shift, um Lücken automatisch zu schließen, oder setze feste Platzhalter.',
			'tutorial_box_limits_title' => 'Kapazitätsgrenzen & Folgeboxen',
			'tutorial_box_limits_text' => 'Lege feste Boxgrößen fest und lasse Überläufe automatisch in die nächste Folgebox fließen.',
			'tutorial_chapter_shiny_hunt_title' => '5. Shiny Hunt Tracker',
			'tutorial_chapter_shiny_hunt_desc' => 'Neue Jagd anlegen, Counter bedienen, Phasen erfassen sowie Multi-Hunt Dashboard & Auto-Counter nutzen.',
			'tutorial_shiny_hub_title' => 'Shiny Hunt Hub',
			'tutorial_shiny_hub_text' => 'Hier findest du all deine aktiven und abgeschlossenen Jagden auf einen Blick.',
			'tutorial_shiny_new_title' => 'Neue Jagd starten',
			'tutorial_shiny_new_text' => 'Wähle Ziel-Pokémon, Spiel, Methode (Masuda, Reset, Kette) und aktiviere den Schillerpin.',
			'tutorial_shiny_counter_title' => 'Großer Zähler & Steuerung',
			'tutorial_shiny_counter_text' => 'Zähle Begegnungen per Tap, Tastatur [Leertaste] oder Lautstärketasten für maximalen Komfort.',
			'tutorial_shiny_phases_title' => 'Phasen erfassen',
			'tutorial_shiny_phases_text' => 'Taucht ein anderes Shiny auf? Erfasse es als Phase, ohne deinen Gesamtzähler zu verlieren.',
			'tutorial_shiny_stats_title' => 'Wahrscheinlichkeiten & Timer',
			'tutorial_shiny_stats_text' => 'Behalte deine binomiale Chance und deine Jagdzeit mit integriertem Stoppuhr-Timer im Auge.',
			'tutorial_chapter_stats_share_title' => '6. Statistiken & Erfolgs-Karte (v1.6)',
			'tutorial_chapter_stats_share_desc' => 'Detaillierten Fang-Fortschritt prüfen und als hochwertige Grafik exportieren/teilen.',
			'tutorial_stats_intro_title' => 'Fortschritt & Statistiken',
			'tutorial_stats_intro_text' => 'Öffne das Diagramm-Icon im Dex-Header, um deine Gesamtfangrate im Detail zu analysieren.',
			'tutorial_stats_breakdown_title' => 'Generationen, Typen & Varianten',
			'tutorial_stats_breakdown_text' => 'Erfahre genau, in welchen Generationen oder Typen dir noch Pokémon fehlen.',
			'tutorial_share_card_title' => 'Erfolgs-Karte (Share Card)',
			'tutorial_share_card_text' => 'Generiere ein offizielles Diplom oder eine Infografik mit deinem Trainernamen.',
			'tutorial_share_formats_title' => 'Formate & Stile',
			'tutorial_share_formats_text' => 'Wähle zwischen Querformat (16:9), Quadrat (1:1) oder Instagram Story (9:16) und teile als PNG!',
			'tutorial_chapter_pokemon_info_title' => '7. Pokémon-Details & Rechner (v1.6)',
			'tutorial_chapter_pokemon_info_desc' => 'Geschlechtsunterschiede, Zucht- & Fangraten-Rechner, Bälle, Tera-Typen & Event-Status.',
			'tutorial_info_gender_title' => 'Geschlechtsunterschiede',
			'tutorial_info_gender_text' => 'Vergleiche männliche und weibliche Formen mit detaillierten Hervorhebungen der optischen Merkmale.',
			'tutorial_info_obtainable_title' => 'Spezielle Fundorte & Events',
			'tutorial_info_obtainable_text' => 'Prüfe, ob ein Pokémon durch Tausch, Geschenke, Fossilien oder Events erhältlich ist.',
			'tutorial_info_breeding_title' => 'Zucht und Entwicklung',
			'tutorial_info_breeding_text' => 'Klappe diesen Bereich aus, um alles über Ei-Gruppen, Geschlechter und die genauen Entwicklungsbedingungen zu erfahren.',
			'tutorial_info_catch_calc_title' => 'Fangraten-Rechner',
			_ => null,
		} ?? switch (path) {
			'tutorial_info_catch_calc_text' => 'Simuliere Fangchancen basierend auf KP, Statusproblemen und deinem bevorzugten Pokéball.',
			'tutorial_info_direct_hunt_title' => 'Direkte Jagd starten',
			'tutorial_info_direct_hunt_text' => 'Starte einen neuen Shiny Hunt mit einem Klick direkt aus dem Detailbildschirm dieses Pokémon!',
			'tutorial_chapter_route_tracker_title' => '8. Routen- & Fundort-Tracker (v1.6)',
			'tutorial_chapter_route_tracker_desc' => 'Erfasse gefangene Pokémon ortsbezogen pro Spielroute und behalte offene Gebiete im Blick.',
			'tutorial_route_hub_title' => 'Routen-Übersicht',
			'tutorial_route_hub_text' => 'Öffne den Routen-Tracker über das Standort-Symbol in der Dex-Leiste oben.',
			'tutorial_route_spawns_title' => 'Spawns & Fangmethoden',
			'tutorial_route_spawns_text' => 'Sieh genau, welche Pokémon im hohen Gras, beim Surfen oder beim Angeln auftauchen.',
			'tutorial_route_filters_title' => 'Gebiets-Filter',
			'tutorial_route_filters_text' => 'Filtere nach unvollständigen Routen, um gezielt fehlende Pokémon nachzufangen.',
			'tutorial_route_mastery_title' => '100% Routen-Meisterschaft',
			'tutorial_route_mastery_text' => 'Schließe alle Routen ab, um die vollständige Erkundung des Spiels zu meistern!',
			'tutorial_chapter_controls_title' => '9. Steuerung & Shortcuts (v1.6)',
			'tutorial_chapter_controls_desc' => 'Effiziente Shortcuts für Desktop, Wischgesten, Schnellwahl und Tastatur-Navigation.',
			'tutorial_ctrl_desktop_title' => 'Desktop-Tastenkürzel',
			'tutorial_ctrl_desktop_text' => 'Nutze die Leertaste im Shiny-Counter, Strg+F zum Suchen und Pfeiltasten für Boxen.',
			'tutorial_ctrl_shortcuts_title' => 'Schnellnavigation',
			'tutorial_ctrl_shortcuts_text' => 'Navigiere blitzschnell mit Zifferntasten oder Tastaturkürzeln durch alle Menüs.',
			'tutorial_ctrl_gestures_title' => 'Mobile Wischgesten',
			'tutorial_ctrl_gestures_text' => 'Wische horizontal, um zwischen Boxen zu blättern, und halte gedrückt für Details.',
			'tutorial_ctrl_gamepad_title' => 'Gamepad & Zubehör',
			'tutorial_ctrl_gamepad_text' => 'Unterstützung für externe Bluetooth-Tastaturen und Gamepads für bequemes Tracken.',
			'tutorial_chapter_backup_title' => '10. Cloud-Sync & Backups',
			'tutorial_chapter_backup_desc' => 'Google Drive Cloud-Sync, automatische lokale Backups & sicherer Daten-Export/Import.',
			'tutorial_backup_cloud_title' => 'Google Drive Synchronisation',
			'tutorial_backup_cloud_text' => 'Verbinde dein Google Drive Konto, um deinen Pokédex, gefangene Pokémon und Shiny Hunts automatisch geräteübergreifend zu sichern.',
			'tutorial_backup_auto_title' => 'Automatische lokale Sicherungen',
			'tutorial_backup_auto_text' => 'PokéVault erstellt vor kritischen Änderungen und in regelmäßigen Abständen automatische Backups in deinem App-Datenordner.',
			'tutorial_backup_export_title' => 'Manueller Backup-Export',
			'tutorial_backup_export_text' => 'Du kannst jederzeit ein vollständiges Backup als Datei exportieren, um deine Daten manuell zu archivieren oder auf ein neues Gerät mitzunehmen.',
			'tutorial_backup_restore_title' => 'Wiederherstellung & Downgrade-Schutz',
			'tutorial_backup_restore_text' => 'Solltest du zu einer älteren Version wechseln oder Daten wiederherstellen wollen, schützt das System deine Datenbank vor Datenverlust.',
			'tutorial_try_now' => 'Jetzt ausprobieren',
			'tutorial_shiny_buttons_title' => 'Korrektur & Schrittweite',
			'tutorial_shiny_buttons_text' => 'Passe deinen Zähler mit den Plus-/Minus-Tasten an oder wähle eine feste Schrittweite (+1, +5, +10).',
			'tutorial_shiny_phases_actions_title' => 'Phasen & Fang-Abschluss',
			'tutorial_shiny_phases_actions_text' => 'Trage unerwartete Shinys als Phase ein oder schließe deine Jagd erfolgreich über \'Shiny Gefangen!\' ab.',
			'tutorial_feature_home' => 'Hauptmenü & Dexe',
			'tutorial_feature_details' => 'Pokémon Details & Fangrate',
			'tutorial_error_widget_not_found' => 'Ups! Rotom kann dieses Element gerade nicht finden.',
			'tutorial_home_fab_title' => 'Dein erster Pokédex!',
			'tutorial_home_fab_text' => 'Tippe hier auf das Plus-Symbol, um einen neuen Pokédex oder einen Ordner zu erstellen.',
			'tutorial_home_search_title' => 'Suchen & Sortieren',
			'tutorial_home_search_text' => 'Sobald deine Sammlung wächst, kannst du sie hier durchsuchen oder nach Fortschritt und Region sortieren.',
			'tutorial_home_intro_title' => 'Bzzzt! Hallo!',
			'tutorial_home_intro_text' => 'Ich bin Rotom, dein smarter Pokédex-Assistent! Ich zeige dir kurz, wie hier alles funktioniert. Los geht\'s!',
			'tutorial_create_name_title' => 'Dein Dex, dein Name',
			'tutorial_create_name_text' => 'Gib deinem Pokédex hier einen passenden Namen. (z.B. \'Kanto Living Dex\')',
			'tutorial_home_sheet_title' => 'Neuer Pokédex',
			'tutorial_home_sheet_text' => 'Tippe hier, um das Menü zur Erstellung deines Dexes zu öffnen.',
			'tutorial_create_group_title' => 'Spiele & Generationen',
			'tutorial_create_group_text' => 'Wische nach links und rechts, um die Region zu wählen. Bei manchen Regionen erscheint darunter ein Dropdown für einen noch genaueren Dex (z.B. Kalos Zentral).',
			'tutorial_create_options_title' => 'Dein Dex, deine Regeln',
			'tutorial_create_options_text' => 'Möchtest du Shinys oder Geschlechter sammeln? Klappe \'Formen auswählen\' auf, um Megas oder G-Max zu aktivieren. Aktiviere für den Anfang am besten alles!',
			'tutorial_create_save_title' => 'Los geht\'s!',
			'tutorial_create_save_text' => 'Tippe auf Erstellen, um deinen ultimativen Dex anzulegen.',
			'tutorial_reset_title' => 'Tutorial neustarten',
			'tutorial_reset_sub' => 'Setzt alle Tutorial-Hinweise zurück',
			'tutorial_reset_success' => 'Das Tutorial wurde erfolgreich zurückgesetzt!',
			'tutorial_create_step1_title' => 'Spiele & Generationen',
			'tutorial_create_step1_text' => 'Dies ist die Regionsauswahl. Wische in der Liste nach rechts.',
			'tutorial_create_step2_title' => 'Region auswählen',
			'tutorial_create_step2_text' => 'Tippe jetzt auf \'Kalos & Z-A\', um zu sehen, wie sich die Optionen anpassen.',
			'tutorial_create_step3_title' => 'Spezifische Dexe',
			'tutorial_create_step3_text' => 'Einige Regionen bieten hier ein Dropdown (z.B. für Zentral-Kalos). Tippe auf das Feld, um fortzufahren.',
			'tutorial_create_step3_5_title' => 'Die volle Auswahl',
			'tutorial_create_step3_5_text' => 'Hier kannst du genau wählen, welchen Teil der Region du spielen möchtest! Tippe auf die Liste, um sie wieder zu schließen.',
			'tutorial_create_step4_title' => 'Zurück zum Start',
			'tutorial_create_step4_text' => 'Wir wollen für dieses Tutorial aber alles! Wische die Liste wieder ganz nach links.',
			'tutorial_create_step5_title' => 'Nationaldex',
			'tutorial_create_step5_text' => 'Tippe auf \'National\', um wieder alle Pokémon auszuwählen.',
			'tutorial_create_step6_title' => 'Shiny Dex',
			'tutorial_create_step6_text' => 'Sammelst du Shinys? Tippe auf den Schalter, um ihn zu aktivieren.',
			'tutorial_create_step7_title' => 'Geschlechter',
			'tutorial_create_step7_text' => 'Aktiviere auch die Geschlechter-Unterschiede durch einen Tipp auf den Schalter.',
			'tutorial_create_step_trades_title' => 'In-Game Tausche',
			'tutorial_create_step_trades_text' => 'Aktiviere diese Option, um besondere getauschte Pokémon mit vorgegebenen Werten und Spitznamen (z. B. Quaputzi \'Barabara\') aufzunehmen.',
			'tutorial_create_step_gifts_title' => 'Geschenkte Pokémon',
			'tutorial_create_step_gifts_text' => 'Aktiviere diese Option, um geschenkte Pokémon (z. B. Evoli im Prismania-Gebäude oder Fossilien) in deinen Pokédex aufzunehmen.',
			'tutorial_create_step7_glitch_title' => 'Glitch-Pokémon',
			'tutorial_create_step7_glitch_text' => 'Aktiviere diese Option, um Glitch-Pokémon (wie die Gen 2 VC Game Boy Icon Starter) in deinen Pokédex aufzunehmen.',
			'tutorial_create_step8_title' => 'Spezielle Formen',
			'tutorial_create_step8_text' => 'Tippe hier, um das Menü für spezielle Formen aufzuklappen.',
			'tutorial_create_step9_title' => 'Regionalformen',
			'tutorial_create_step9_text' => 'Tippe, um Regionalformen (Alola, Galar...) zu aktivieren.',
			'tutorial_create_step10_title' => 'Mega-Entwicklungen',
			'tutorial_create_step10_text' => 'Tippe, um Mega-Entwicklungen zu aktivieren.',
			'tutorial_create_step11_title' => 'Gigadynamax',
			'tutorial_create_step11_text' => 'Tippe, um G-Max Formen zu aktivieren.',
			'tutorial_create_step12_title' => 'Sonstige Formen',
			'tutorial_create_step12_text' => 'Tippe, um die restlichen Formen (Kostüme, Pokusan...) zu aktivieren.',
			'tutorial_create_step13_title' => 'Los geht\'s!',
			'tutorial_create_step13_text' => 'Perfekt, du hast alles ausgewählt! Tippe jetzt auf \'Erstellen\'.',
			'tutorial_error_scroll' => 'Fehler beim Scrollen im Tutorial:',
			'tutorial_error_rect' => 'Fehler beim Berechnen des Tutorial-Rahmens:',
			'tutorial_error_next' => 'Fehler beim Wechseln des Tutorial-Schritts:',
			'tutorial_wrong_swipe' => 'Halt, falsche Richtung! Wir wollen zurück zum Nationaldex (nach rechts wischen)!',
			'tutorial_rotom_angry' => 'Na gut, wenn du nicht willst... dann mach ich das eben selbst! ZZZZZZT!',
			'tutorial_open_dex_title' => 'Dein erster Pokédex!',
			'tutorial_open_dex_text' => 'Klicke hier auf deinen neu erstellten Pokédex, um ihn zu öffnen!',
			'tutorial_dex_intro_title' => 'Das Herzstück!',
			'tutorial_dex_intro_text' => 'Willkommen in der Hauptansicht! Hier siehst du alle Pokémon, die zu diesem Dex gehören.',
			'tutorial_dex_tap_title' => 'Pokémon fangen!',
			'tutorial_dex_tap_text' => 'Tippe einmal kurz auf ein Pokémon, um es als gefangen zu markieren.',
			'tutorial_dex_menu_title' => 'Menü & Sortierung',
			'tutorial_dex_menu_text' => 'Tippe hier oben rechts auf das Sortierzeichen, um die Ansicht anzupassen.',
			'tutorial_dex_menu_forms_title' => 'Nach Pokédex (Normal)',
			'tutorial_dex_menu_forms_text' => 'Tippe auf \'Nach Pokédex (Normal)\'. Nun stehen alle regulären Pokémon der Region zuerst und die Sonderformen am Ende!',
			'tutorial_dex_menu_box_title' => 'PC-Box Ansicht',
			'tutorial_dex_menu_box_text' => 'Tippe auf \'Zur PC-Box Ansicht\', um die Pokémon wie im echten Spiel in praktische Boxen zu sortieren. Das war"s für hier!',
			'tutorial_dex_search_title' => 'Die Suchfunktion!',
			'tutorial_dex_search_text' => 'Hier kannst du nach Namen, IDs oder Typen suchen. Tippe auf die Suchleiste, Rotom tippt mal testweise \'Gengar\' für dich ein!',
			'tutorial_longpress_title' => 'Detailansicht öffnen',
			'tutorial_longpress_text' => 'Da ist es! Halte ein Pokémon lange gedrückt (oder tippe einfach hier), um in seine Detailansicht zu wechseln.',
			'tutorial_info_appbar_title' => 'Zusatzinformationen',
			'tutorial_info_appbar_text' => 'Hier oben siehst du immer, in welcher Box und an welcher Position du dich gerade befindest.',
			'tutorial_info_shiny_toggle_title' => 'Shiny Ansicht',
			'tutorial_info_shiny_toggle_text' => 'Tippe auf dieses Icon unten rechts am Bild, um dir das Pokémon in seiner schillernden Form (Shiny) anzusehen!',
			'tutorial_info_basic_title' => 'Basis-Infos',
			'tutorial_info_basic_text' => 'Darunter findest du die grundlegenden Daten: ID, Name und die Typen des Pokémon.',
			'tutorial_info_caught_title' => 'Gefangen Status',
			'tutorial_info_caught_text' => 'Mit diesem Schalter kannst du jederzeit abhaken, ob du das Pokémon bereits besitzt.',
			'tutorial_info_shiny_title' => 'Shiny Status',
			'tutorial_info_shiny_text' => 'Und hier markierst du, ob du es sogar als Shiny gefangen hast!',
			'tutorial_info_catchcalc_title' => 'Fangratenrechner',
			'tutorial_info_catchcalc_text' => 'Ein extrem nützliches Tool! Berechne hier deine genaue Fangchance. Die Optionen passen sich je nach Generation dynamisch an.',
			'tutorial_info_matchingballs_title' => 'Matching Balls',
			'tutorial_info_matchingballs_text' => 'Hier siehst du, welche Pokébälle farblich am besten zum normalen und zum Shiny-Pokémon passen.',
			'tutorial_info_language_title' => 'Internationale Namen',
			'tutorial_info_language_text' => 'Hier siehst du, wie das Pokémon in allen unterstützten Sprachen heißt – ideal für den internationalen Tausch!',
			'tutorial_info_encounters_title' => 'Fundorte & Begegnungen',
			'tutorial_info_encounters_text' => 'Zeigt dir für jede Edition genau an, wo und wie du das Pokémon im Spiel finden kannst.',
			'tutorial_info_shinyguide_title' => 'Shiny Guide',
			'tutorial_info_shinyguide_text' => 'Spezielle Tipps und Mechaniken, um dieses Pokémon gezielt als Shiny zu jagen!',
			'tutorial_info_ignore_title' => 'Pokémon entfernen',
			'tutorial_info_ignore_text' => 'Sollte ein Pokémon mal nicht in deinen Dex gehören, kannst du es hier ausblenden. Probier es zum Abschluss einmal aus und drücke den Button!',
			'tutorial_info_ignore_confirm_title' => 'Wirklich entfernen?',
			'tutorial_info_ignore_confirm_text' => 'Klicke jetzt auf \'Aus Dex entfernen\', um Gengar vorerst zu verstecken.',
			'tutorial_dex_menu_ignored_title' => 'Versteckte Pokémon finden',
			'tutorial_dex_menu_ignored_text' => 'Oh nein, Gengar ist weg! Aber keine Sorge. Öffne wieder das Menü hier oben.',
			'tutorial_dex_menu_ignored_btn_title' => 'Ausgeblendete Pokémon',
			'tutorial_dex_menu_ignored_btn_text' => 'Tippe hier auf \'Ausgeblendete Pokémon\', um deine versteckten Freunde zu sehen.',
			'tutorial_ignored_restore_title' => 'Wiederherstellen',
			'tutorial_ignored_restore_text' => 'Hier sind alle Pokémon, die du ausgeblendet hast. Klicke auf \'Wiederherstellen\', um Gengar zurück in deinen Dex zu holen.',
			'tutorial_dex_search_easteregg' => 'Na gut, wenn du nicht weißt wie man tippt... ich übernehme das! ZZZZZZT!',
			'tutorial_folder_option_title' => 'Neuer Ordner',
			'tutorial_folder_option_text' => 'Tippe hier, um einen neuen Ordner anzulegen und deine Dex-Sammlung übersichtlich zu organisieren!',
			'tutorial_folder_dialog_title' => 'Ordner benennen',
			'tutorial_folder_dialog_text' => 'Gib deinem Ordner einen Namen (z. B. \'Kanto\' oder \'Shinies\') und bestätige mit OK!',
			'tutorial_hunt_pokemon_title' => 'Pokémon & Notiz',
			'tutorial_hunt_pokemon_text' => 'Wähle das Ziel-Pokémon für deine Jagd. Optional kannst du dem Hunt einen individuellen Titel oder eine Notiz geben.',
			'tutorial_hunt_game_method_title' => 'Edition & Methode',
			'tutorial_hunt_game_method_text' => 'Wähle Spiel und Jagdmethode (z. B. Masuda, Schillerpin oder Zufallsbegegnung). Die Fangquoten berechnen sich automatisch!',
			'tutorial_hunt_params_title' => 'Chancen & Schrittweite',
			'tutorial_hunt_params_text' => 'Hier siehst du die exakte Wahrscheinlichkeit (z. B. 1:4096). Passe Spawns pro Runde oder die Schrittweite für schnelle Zählung an!',
			'tutorial_hunt_save_title' => 'Hunt starten',
			'tutorial_hunt_save_text' => 'Speichere deinen Hunt, um direkt zum Live-Zähler mit Phasen, Timer und Stoppuhr zu gelangen!',
			'tutorial_appbar_stats_title' => 'Dex-Statistiken',
			'tutorial_appbar_stats_text' => 'Hier findest du deinen Fangfortschritt im Detail – aufgeschlüsselt nach Generationen, Typen und Formen!',
			'tutorial_appbar_share_title' => 'Erfolgs-Grafik teilen',
			'tutorial_appbar_share_text' => 'Erstelle eine schicke Trainerkarte mit deinem Fortschritt und teile sie mit Freunden oder in Social Media!',
			'tutorial_appbar_box_edit_title' => 'Boxen verwalten',
			'tutorial_appbar_box_edit_text' => 'Passe Namen, Farben und Layout deiner Boxen an, erstelle neue Boxen oder nutze den Auto-Shift für lückenlose Ordnung!',
			'tutorial_appbar_box_content_title' => 'Box-Inhalte bearbeiten',
			'tutorial_appbar_box_content_text' => 'Verschiebe Pokémon per Drag & Drop zwischen Boxen, wähle mehrere Pokémon gleichzeitig aus oder füge neue Pokémon hinzu!',
			'tutorial_appbar_route_title' => 'Routen- & Fundort-Tracker',
			'tutorial_appbar_route_text' => 'Sieh nach, welche Pokémon dir auf welcher Spielroute noch fehlen und behalte die Gebiets-Erkundung im Blick!',
			'tutorial_appbar_shiny_title' => 'Shiny Hunt Tracker',
			'tutorial_appbar_shiny_text' => 'Tippe hier, um zu deinen aktiven Shiny Hunts zu wechseln oder neue Jagden zu starten!',
			'tutorial_box_edit_intro_title' => 'Boxen anpassen',
			'tutorial_box_edit_intro_text' => 'Hier kannst du deine PC-Boxen frei anordnen, umbenennen, Farben zuweisen und das Raster für jede Box individuell anpassen!',
			'tutorial_box_content_intro_title' => 'Box-Inhalt bearbeiten',
			'tutorial_box_content_intro_text' => 'Tippe auf einen leeren Slot, um ein Pokémon oder einen Platzhalter einzufügen. Bestehende Pokémon kannst du frei verschieben!',
			'tutorial_search_select_intro_title' => 'Pokémon auswählen',
			'tutorial_search_select_intro_text' => 'Nutze Filter für Region, Form, Geschlecht und Shiny-Status oder suche direkt nach Name oder Dex-Nummer!',
			'tutorial_longpress_error' => 'Das war ein normaler Klick! Halte das Pokémon LANGE gedrückt!',
			'error_avatar_load' => 'Fehler beim Laden des Avatars:',
			'error_header_load' => 'Fehler beim Laden des Headers:',
			'error_basic_info' => 'Fehler beim Laden der Basis-Infos:',
			'error_status_toggles' => 'Fehler beim Laden der Status-Buttons:',
			'error_matching_balls' => 'Fehler beim Laden der Matching Balls:',
			'error_encounters' => 'Fehler beim Laden der Fundorte:',
			'error_calc_ui_result' => 'Fehler im Ergebnis-Widget:',
			'error_calc_ui_hp' => 'Fehler im HP/Status-Widget:',
			'error_calc_ui_crit' => 'Fehler im Crit-Widget:',
			'create_dex_btn' => 'Pokédex erstellen',
			'error_db_init' => 'Datenbank konnte nicht initialisiert werden:',
			'error_db_create' => 'Benutzertabellen konnten nicht erstellt werden:',
			'error_db_write' => 'Fehler beim Speichern deiner Daten:',
			'migration_loading_text' => 'Daten werden für die neuste Version optimiert...\nBitte App nicht schließen.',
			'error_page_load' => 'Fehler beim Laden der Seite:',
			'group_special' => 'Spezial Dexe',
			'web_backup_warning_text' => 'Achtung: Im Web-Browser können deine Daten gelöscht werden, wenn der Browser-Cache geleert wird. Bitte erstelle regelmäßig Backups!',
			'web_backup_warning_action' => 'Verstanden',
			'cloud_sync' => 'Cloud-Synchronisation',
			'google_client_id' => 'Google OAuth Client-ID',
			'google_client_id_help' => 'Erstelle eine Client-ID in der Google Cloud Console, um Drive zu nutzen.',
			'auto_sync' => 'Automatische Synchronisation',
			'auto_sync_desc' => 'Synchronisiert im Hintergrund beim Schließen der App',
			'login_drive' => 'Drive Login',
			'logout_drive' => 'Drive Logout',
			'sync_now' => 'Jetzt synchronisieren',
			'sync_success' => 'Erfolgreich mit Google Drive synchronisiert!',
			'tutorial_sync_title' => 'Cloud-Speicher einrichten',
			'tutorial_sync_text' => 'Trage hier deine eigene Google Client-ID ein, um deine Dexe sicher und kostenlos in deinem versteckten Google Drive App-Ordner zu speichern.',
			'google_client_secret' => 'Google Client-Secret',
			'cloud_tut_title' => 'Eigene Cloud einrichten',
			'cloud_tut_intro' => 'Da PokeVault völlig kostenlos ist, nutzt du einfach deinen eigenen (kostenlosen) Google-Schlüssel. Deine Daten landen sicher und unsichtbar in deinem eigenen Google Drive.',
			'cloud_tut_step1' => 'Gehe in die Google Cloud Console und erstelle ein \'Neues Projekt\' (du kannst es z.B. \'PokeVault\' nennen).',
			'cloud_tut_step2' => 'Suche in der Leiste oben nach \'Google Drive API\' und klicke auf \'Aktivieren\'. Suche danach nach der \'Google People API\' und aktiviere diese ebenfalls.',
			'cloud_tut_step3' => 'Gehe links auf \'OAuth-Zustimmungsbildschirm\' -> \'Zielgruppe\'. Klicke unter \'Testnutzer\' auf \'Add users\' und trage die E-Mail-Adresse deines Google Drive-Kontos ein.',
			'cloud_tut_step4' => 'Gehe zurück zur Google Drive API-Übersicht, wähle links \'Anmeldedaten\' und klicke oben auf \'+ Anmeldedaten erstellen\'.',
			'cloud_tut_step5' => 'Wähle \'OAuth-Client-ID\' und als Anwendungstyp zwingend \'Desktopanwendung\' (bzw. Desktop-App). Als Name kannst du z.B. deinen Gerätenamen eintragen. Klicke auf \'Erstellen\'.',
			'cloud_tut_step5_web' => 'Wähle \'OAuth-Client-ID\' und als Anwendungstyp zwingend \'Webanwendung\'. Trage unter \'Autorisierte JavaScript-Quellen\' die genaue URL dieser Seite ein. Klicke auf \'Erstellen\'.',
			'cloud_tut_step6' => 'Kopiere die angezeigte \'Client-ID\' und den \'Clientschlüssel\' (Client-Secret) und füge sie hier in der App ein (oder lade die JSON-Datei herunter, um sie daraus zu kopieren).',
			'cloud_tut_step6_web' => 'Kopiere die angezeigte \'Client-ID\' und füge sie hier in der App ein. Ein Client-Secret wird für die Web-Version nicht benötigt!',
			'cloud_tut_step7' => 'Tippe hier in der App auf \'Drive Login\'.',
			'cloud_tut_step8' => 'Wähle im Browserfenster exakt die E-Mail-Adresse aus, die du vorher als Testnutzer eingetragen hast.',
			'cloud_tut_step9' => 'Bestätige die Zugriffsanfrage, indem du zweimal auf \'Weiter\' klickst.',
			'cloud_tut_step10' => 'Der Login sollte nun erfolgreich sein! Du kannst das Browserfenster schließen und zur App zurückkehren.',
			'close' => 'Schließen',
			'tutorial_organize_intro_title' => 'Ordnung muss sein!',
			'tutorial_organize_intro_text' => 'Da du jetzt deinen ersten Dex hast, zeige ich dir kurz, wie du alles übersichtlich organisieren kannst.',
			'tutorial_organize_folder_title' => 'Ordner erstellen',
			'tutorial_organize_folder_text' => 'Über dieses Plus-Symbol kannst du neben Dexen auch Ordner anlegen, um deine Sammlung zu gruppieren.',
			'tutorial_organize_drag_title' => 'Drag & Drop',
			'tutorial_organize_drag_text' => 'Tipp: Wenn du oben rechts auf "Manuell" sortierst, kannst du Dexe und Ordner jederzeit an den rechten Griffen anfassen und verschieben.',
			'tutorial_organize_longpress_title' => 'Auswahlmodus (Long-Press)',
			'tutorial_organize_longpress_text' => 'Halte deinen Dex jetzt LANGE gedrückt (ca. halbe Sekunde), um den Auswahlmodus zu starten!',
			'tutorial_organize_move_title' => 'Elemente verschieben',
			'tutorial_organize_move_text' => 'Perfekt! Jetzt kannst du ihn verschieben, exportieren oder löschen. Klicke auf das Ordner-Symbol, um ihn zu verschieben!',
			'tutorial_org1_intro_title' => 'Lass uns aufräumen!',
			'tutorial_org1_intro_text' => 'Ordnung ist das halbe Leben. Ich zeige dir kurz die wichtigsten Funktionen auf dem Homescreen.',
			'tutorial_org1_sort_title' => 'Sortieren & Manuell',
			'tutorial_org1_sort_text' => 'Hier kannst du filtern und sortieren. Wählst du \'Manuell\', kannst du Dexe und Ordner am rechten Rand anfassen und frei verschieben!',
			'tutorial_org1_options_title' => 'Schnelle Aktionen (3 Punkte)',
			'tutorial_org1_options_text' => 'Über die 3 Punkte auf einer Dex-Karte kommst du sofort an wichtige Aktionen wie Umbenennen oder Löschen heran.',
			'tutorial_org1_folder_title' => 'Ordner erstellen',
			'tutorial_org1_folder_text' => 'Klicke jetzt auf das Plus und erstelle im Menü einen neuen Ordner als praktisches Beispiel!',
			'tutorial_org2_longpress_title' => 'Auswahlmodus',
			'tutorial_org2_longpress_text' => 'Da ist der Ordner! Halte nun deinen ersten Dex LANGE gedrückt (ca. halbe Sekunde), um ihn auszuwählen.',
			'tutorial_org2_move_title' => 'Elemente verschieben',
			'tutorial_org2_move_text' => 'Klicke nun auf das Verschieben-Icon, wähle deinen neuen Ordner aus und bestätige. Damit bist du ein Profi!',
			'tutorial_home_settings_title' => 'Fast geschafft!',
			'tutorial_home_settings_text' => 'Zum Abschluss zeige ich dir noch die Einstellungen. Klicke auf das Zahnrad oben rechts!',
			'tutorial_settings_appearance_title' => 'Erscheinungsbild',
			'tutorial_settings_appearance_text' => 'Hier kannst du den Dark Mode aktivieren und die Farben der App ganz nach deinem Geschmack anpassen.',
			'tutorial_settings_updates_title' => 'Updates & Versionen',
			'tutorial_settings_updates_text' => 'Prüfe hier auf neue Updates oder wechsle zu einer älteren Version zurück, falls mal etwas nicht klappt.',
			'tutorial_settings_general_title' => 'Allgemein',
			'tutorial_settings_general_text' => 'Ändere die Sprache oder starte das gesamte Tutorial neu, falls du dir alles noch einmal ansehen möchtest.',
			'tutorial_settings_data_title' => 'Datenverwaltung',
			'tutorial_settings_data_text' => 'Erstelle manuelle Backups deiner Dexe (Exportieren) oder lade alte Backups wieder in die App (Importieren).',
			'tutorial_settings_cloud_title' => 'Cloud-Synchronisation',
			'tutorial_settings_cloud_text' => 'Verbinde dein Google Drive, um deine Daten sicher in der Cloud zu speichern und zwischen deinen Geräten zu synchronisieren!',
			'tutorial_settings_community_title' => 'Community & Support',
			'tutorial_settings_community_text' => 'Du hast einen Bug gefunden oder möchtest bei der Entwicklung helfen? Hier findest du alle Links!',
			'tutorial_settings_credits_title' => 'Danksagungen & Quellen',
			'tutorial_settings_credits_text' => 'PokeVault wäre ohne diese tollen Projekte nicht möglich. Schau sie dir gerne an! Das war\'s – viel Spaß mit der App!',
			'shiny_gen3_huntable_yes' => 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
			'shiny_gen3_rs_note' => 'Rubin & Saphir: Der Seed ist zufällig, Standard Soft Resets (SR) funktionieren problemlos. AUSNAHME: Ist die interne Batterie leer oder der Spielstand hat 999:59h erreicht, friert der Seed bei 0 ein (wie in Smaragd).',
			'shiny_gen3_emerald_note' => 'Smaragd: RNG Fehler! Der Start-Seed ist bei jedem Reset immer 0. Klassische Soft Resets bringen nichts, da immer die exakt gleichen Pokémon-Werte generiert werden. Nutze hier die "Runaway"-Methode (Flucht & Neu-Encounter) oder RNG Manipulation.',
			'shiny_gen3_frbg_note' => 'Feuerrot & Blattgrün: Kein RNG Bug. Der Seed generiert sich bei jedem Spielstart neu. Soft Resets sind völlig bedenkenlos möglich.',
			'shiny_gen3_links_title' => 'RNG Manipulation Guides & Ressourcen',
			'shiny_gen3_link_blisy_channel' => 'im a blisy - YouTube Kanal (EN)',
			'shiny_gen3_link_blisy_playlist' => 'im a blisy - R/S/E RNG Playlist (EN)',
			'shiny_gen3_link_blisy_rs_video' => 'im a blisy - R/S Stationäre RNG (Video) (EN)',
			'shiny_gen3_link_smogon' => 'Smogon - R/S Non-Bred RNG Guide (EN)',
			'shiny_gen3_link_retail_rng' => 'Retail RNG - Smaragd Guide (EN)',
			'shiny_gen3_link_reddit_emerald' => 'Reddit - RNG Manipulation in Emerald (EN)',
			'shiny_gen1_huntable_yes' => 'Shiny Huntable: Ja (DV-basiert, Chance 1:8192)',
			'shiny_gen2_huntable_yes' => 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
			'shiny_gen4_huntable_yes' => 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
			'shiny_gen4_masuda_title' => 'Masuda-Methode (Chance: 1:1638)',
			'shiny_gen4_masuda_desc' => 'Züchte zwei Pokémon aus unterschiedlichen Sprachregionen miteinander (z.B. ein deutsches Feurigel und ein japanisches Ditto), um die Shiny-Chance auf 1:1638 (5/8192) zu vervielfachen.',
			'shiny_gen4_masuda_link' => 'Bulbapedia - Masuda Method (EN)',
			'shiny_gen4_radar_title' => 'Poké-Radar (Chance: bis 1:200)',
			'shiny_gen4_radar_desc' => 'Exklusiv in D/P/Pt für Begegnungen im hohen Gras. Erreichst du eine Kette von 40 des gleichen Pokémon, steigt die Chance auf 1:200 pro wackelndem Feld. Manche Felder glitzern vorher sogar!',
			'shiny_gen4_radar_link_en_reddit' => 'Reddit - Gen 4 Radar Guide (EN)',
			'shiny_gen4_radar_link_en_yt' => 'YouTube - Radar Tutorial (EN)',
			'shiny_gen4_radar_link_de_bisa' => 'Bisafans - Poké-Radar Guide (DE)',
			'shiny_gen4_radar_link_de_yt' => 'YouTube - Radar Tutorial (DE)',
			'shiny_gen4_hgss_starter_title' => 'HGSS Starter Resets (Effektiv 3:8192)',
			'shiny_gen4_hgss_starter_desc' => 'Extrem schnell! Du siehst bereits bei der Auswahl im Koffer bei Prof. Lind, ob Endivie, Feurigel oder Karnimani Shiny sind. Bei jedem Soft-Reset checkst du also direkt 3 Pokémon gleichzeitig.',
			'shiny_gen4_hgss_starter_link' => 'Guide: HGSS Starters Hunten',
			'shiny_gen4_ccg_title' => 'Cute Charm Glitch (~21% Shiny Chance!)',
			'shiny_gen4_ccg_desc' => 'Fehler im Code: Besitzt dein Spiel eine bestimmte Kombination aus Trainer-ID und Secret-ID, zwingt ein Pokémon mit der Fähigkeit Charmebolzen an erster Stelle das Spiel dazu, unfassbar oft ein Shiny des anderen Geschlechts auftauchen zu lassen.',
			'shiny_gen4_ccg_link_dppt' => 'YouTube - CCG für D/P/Pt (EN)',
			'shiny_gen4_ccg_link_hgss' => 'YouTube - CCG für HGSS (EN)',
			'shiny_gen4_roamer_title' => 'Wander-Pokémon (Roamer) in Gen 4',
			'shiny_gen4_roamer_desc' => 'Die Werte und der Shiny-Status werden festgelegt, sobald das Pokémon in die Wildnis entlassen wird! Du musst VOR diesem Gespräch / Event speichern und bei Misserfolg komplett resetten.',
			'shiny_gen4_sr_title' => 'Soft Resets (Chance: 1:8192)',
			'shiny_gen4_sr_desc' => 'Für stationäre Begegnungen, Legendäre Pokémon oder Geschenke. Speichere direkt vor dem Event und starte das Spiel neu, bis es Shiny ist.',
			'shiny_gen5_huntable_yes' => 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
			'shiny_gen5_locked_title' => 'Shiny Locked!',
			'shiny_gen5_locked_desc' => 'Achtung: Dieses Pokémon kann in Generation 5 NICHT als Shiny erhalten werden (vom Spiel gesperrt).',
			'shiny_gen5_charm_title' => 'Schillerpin (Nur S2/W2)',
			'shiny_gen5_charm_desc' => 'Der Schillerpin wurde in Schwarz 2 / Weiß 2 eingeführt. Er erhöht die wilde Shiny-Chance auf ca. 1:2731 (3/8192).',
			'shiny_gen5_masuda_title' => 'Masuda-Methode (Bis zu 1:1024)',
			'shiny_gen5_masuda_desc' => 'Züchte zwei Pokémon aus unterschiedlichen Sprachregionen. Chance in Gen 5: 1:1365 (Ohne Pin) / 1:1024 (Mit Schillerpin in S2/W2).',
			'shiny_gen5_darkgrass_title' => 'Dunkles Gras (Doppelkämpfe)',
			'shiny_gen5_darkgrass_desc' => 'Im dunklen Gras triffst du oft auf zwei Pokémon gleichzeitig. Das ändert zwar nicht die Basis-Chance, halbiert aber die Zeit pro Begegnung massiv!',
			'shiny_gen5_sr_title' => 'Soft Resets (Chance: 1:8192)',
			'shiny_gen5_sr_desc' => 'Für Legendäre (außer den gesperrten) und statische Begegnungen. Die Shiny-Chance lässt sich in S2/W2 durch den Schillerpin auf 1:2731 verbessern.',
			'shiny_gen5_rng_title' => 'RNG Manipulation (Gen 5)',
			'shiny_gen5_rng_desc' => 'Gen 5 ist eine der anfängerfreundlichsten Generationen für RNG, da oft nur das exakte Datum und die Sekunde im DS-Menü getroffen werden muss.',
			'shiny_gen5_rng_link_blisy' => 'im a blisy - Gen 5 RNG (YouTube) (EN)',
			'shiny_gen5_rng_link_retail' => 'Retail RNG - Gen 5 Guide (EN)',
			'shiny_gen5_rng_link_smogon' => 'Smogon - Gen 5 RNG Guide (EN)',
			'shiny_gen6_huntable_yes' => 'Shiny Huntable: Ja (Neue Basis-Chance: 1:4096)',
			'shiny_gen6_locked_title' => 'Shiny Locks in Gen 6',
			'shiny_gen6_masuda_title' => 'Masuda-Methode (Bis zu 1:512)',
			'shiny_gen6_masuda_desc' => 'Züchte mit zwei Sprachregionen. Chance: 1:683 (ohne Pin) / 1:512 (mit Schillerpin). Tipp: Nutze die O-Kraft \'Brutkraft\', um Eier rasend schnell auszubrüten!',
			'shiny_gen6_fishing_title' => 'Kettenangeln / Chain Fishing (Bis zu ~1:100)',
			'shiny_gen6_fishing_desc' => 'Wirf die Angel erfolgreich immer wieder an derselben Stelle aus. Ein Pokémon mit der Fähigkeit \'Saugnapf\' oder \'Wertehalter\' an der Spitze deines Teams ist Pflicht!',
			'shiny_gen6_fishing_link_yt' => 'YouTube - Chain Fishing Tutorial (EN)',
			'shiny_gen6_fishing_link_reddit' => 'Reddit - Chain Fishing Guide (EN)',
			'shiny_gen6_horde_title' => 'Massenbegegnungen / Hordes (Effektiv ~1:819)',
			'shiny_gen6_horde_desc' => 'Nutze die Attacke \'Lockduft\' oder das Item \'Honig\', um 5 Pokémon gleichzeitig zu treffen. Sehr entspannte Methode!',
			'shiny_gen6_radar_title' => 'Poké-Radar in X/Y (Bis zu 1:200)',
			'shiny_gen6_radar_desc' => 'Wie in Gen 4: Bei einer Kette von 40 im hohen Gras hast du extrem hohe Chancen auf das glitzernde Grasfeld.',
			'shiny_gen6_radar_link_yt' => 'YouTube - X/Y Radar Tutorial (EN)',
			'shiny_gen6_radar_link_slides' => 'Google Slides - Radar Guide (EN)',
			'shiny_gen6_friendsafari_title' => 'Kontaktsafari (Feste Chance: 1:512)',
			'shiny_gen6_friendsafari_desc' => 'Exklusiv nach der Liga in X/Y. Jedes Pokémon hier hat eine feste Shiny-Chance von 1:512. Schillerpin oder Ketten haben hier KEINEN Einfluss.',
			'shiny_gen6_dexnav_title' => 'DexNav in OR/AS',
			'shiny_gen6_dexnav_desc' => 'Je höher dein Suchlevel (Search Level) für dieses Pokémon, desto besser die Shiny-Chancen. Eine der interaktivsten Jagdmethoden überhaupt!',
			'shiny_gen6_dexnav_link_reddit' => 'Reddit - DexNav Survival Guide (EN)',
			'shiny_gen6_dexnav_link_yt' => 'YouTube - DexNav Tutorial (EN)',
			'shiny_gen6_dexnav_link_pokecomm' => 'PokeCommunity - DexNav Guide (EN)',
			'shiny_gen6_chaining_link_wiki' => 'PokéWiki - Shiny Chaining (DE)',
			'shiny_gen6_sr_title' => 'Soft Resets (Chance: 1:4096)',
			'shiny_gen6_sr_desc' => 'Für Legendäre (die nicht gesperrt sind, z.B. aus Hoopa-Ringen) und statische Pokémon. Mit Schillerpin steigt die Chance auf 1:1365.',
			'shiny_not_in_gen' => 'Dieses Pokémon ist in dieser Generation nicht regulär fangbar oder züchtbar.',
			'shiny_gen6_snorlax_warning_title' => 'Relaxo Shiny Lock',
			'shiny_gen6_snorlax_warning_desc' => 'Hinweis: Das stationäre (schlafende) Relaxo auf Route 7 in X/Y ist Shiny Locked! Um ein Shiny Relaxo in Gen 6 zu erhalten, musst du es züchten.',
			'shiny_gen6_locked_desc' => 'In Gen 6 sind Mewtu, die legendären Vögel, Xerneas, Yveltal, Zygarde, Kyogre, Groudon, Rayquaza, Deoxys sowie Diancie, Hoopa und Volcanion Shiny Locked!',
			'shiny_guide_gen7_5' => 'Generation 7.5 (Let\'s Go P/E)',
			'shiny_gen7_huntable_yes' => 'Shiny Huntable: Ja (Basis-Chance 1:4096)',
			'shiny_gen7_locked_title' => 'Shiny Locks in Gen 7',
			'shiny_gen7_locked_desc' => 'Gesperrt in S/M & US/UM: Zygarde, Kapu-Riki, Kapu-Fala, Kapu-Toro, Kapu-Kime, Cosmog, Cosmovum, Solgaleo, Lunala, Necrozma.',
			'shiny_gen7_ub_locked_title' => 'Ultrabestien (Nur in S/M gesperrt!)',
			'shiny_gen7_ub_locked_desc' => 'Achtung: Alle Ultrabestien sind in Sonne & Mond Shiny Locked. In Ultrasonne & Ultramond kannst du sie jedoch regulär hunten!',
			'shiny_gen7_sos_title' => 'SOS-Chaining (Quereinsteiger)',
			'shiny_gen7_sos_desc' => 'Wilde Pokémon rufen um Hilfe. Mit einem Zitterorb steigt die Rufrate. Bei einer Kette von 70+ steigt die Shiny-Chance enorm an (bis 1:315).',
			'shiny_gen7_sos_link_reddit' => 'Reddit - SOS Chaining Guide (EN)',
			'shiny_gen7_sos_link_yt_en' => 'YouTube - SOS Tutorial (EN)',
			'shiny_gen7_sos_link_yt_de' => 'YouTube - SOS Tutorial (DE)',
			'shiny_gen7_warp_title' => 'Ultradimension-Zero (US/UM)',
			'shiny_gen7_warp_desc' => 'Im Warp Ride haben normale Pokémon (je nach Distanz) eine irrsinnig hohe Shiny-Chance (bis 36%). Legenden haben die normale Chance (1:4096 / SR).',
			'shiny_gen7_warp_link_reddit' => 'Reddit - Warp Ride Odds (EN)',
			'shiny_gen7_warp_link_yt_en' => 'YouTube - Warp Ride Tutorial (EN)',
			'shiny_gen7_warp_link_yt_de' => 'YouTube - Warp Ride Tutorial (DE)',
			'shiny_gen7_warp_link_bisa' => 'Bisafans - Warp Loch Shinys (DE)',
			'shiny_gen7_pelago_title' => 'Pokémon-Resort (Poké Pelago)',
			'shiny_gen7_pelago_desc' => 'Wilde Pokémon, die deine Insel besuchen, können Shiny sein! Du siehst es direkt, musst aber 24h warten, ob sie im Team bleiben.',
			'shiny_gen75_combo_title' => 'Fangserie (Catch Combo)',
			'shiny_gen75_combo_desc' => 'Fange immer wieder das gleiche Pokémon. Ab einer Kette von 31 + Lockparfüm + Schillerpin steigt die Chance für den NÄCHSTEN Spawn auf gigantische 1:273!',
			'shiny_gen75_combo_link_reddit' => 'Reddit - Let\'s Go Shiny Guide (EN)',
			'shiny_gen75_combo_link_yt_de1' => 'YouTube - Let\'s Go Hunt (DE)',
			'shiny_gen75_combo_link_yt_de2' => 'YouTube - Let\'s Go Hunt Teil 2 (DE)',
			'shiny_gen75_alola_title' => 'Alola-NPC-Tausche',
			'shiny_gen75_alola_desc' => 'NPCs tauschen unbegrenzt Alola-Formen. Diese können Shiny sein (Chance 1:4096). Der Schillerpin oder Ketten wirken hierauf NICHT.',
			'shiny_gen75_locked_title' => 'Let\'s Go Shiny Locks',
			'shiny_gen75_locked_desc' => 'Dein Partner-Pikachu/Evoli und das Mew (Pokéball Plus) sind immer Shiny Locked. Wilde Pikachu/Evoli kannst du aber normal jagen!',
			'shiny_guide_gen8' => 'Generation 8 (SwSh & BDSP)',
			'shiny_guide_gen8_5' => 'Generation 8.5 (Legenden: Arceus)',
			'shiny_gen8_swsh_title' => 'Schwert & Schild (Galar)',
			'shiny_gen8_swsh_desc' => 'Basis-Chance 1:4096 (1:1365 mit Pin). Nutze Dynamax-Abenteuer im DLC (1:100 Chance!) oder die K.O.-Methode für wilde Spawns.',
			'shiny_gen8_bdsp_title' => 'Strahlender Diamant & Leuchtende Perle',
			'shiny_gen8_bdsp_desc' => 'Basis-Chance 1:4096. Nutze den Untergrund-Diglett-Bonus (verdoppelt die Shiny-Rate temporär) oder Soft Resets für Legendäre.',
			'shiny_gen8_locked_title' => 'Shiny Locks in SwSh & BDSP',
			'shiny_gen8_locked_desc' => 'Die Legendären aus Galar (Zacian, Zamazenta, Endynalos, Dakuma, Coronospa etc.) sowie Typ:Null, Cosmog und Venicro sind hier komplett gesperrt. Starter-Geschenke (wie Chimpep) sind gesperrt, können aber GEZÜCHTET werden!',
			'shiny_gen8_masuda_title' => 'Masuda-Methode (SwSh & BDSP)',
			'shiny_gen8_masuda_desc' => 'Züchte zwei Pokémon aus unterschiedlichen Sprachregionen. Chance: 1:683 (ohne Pin) / 1:512 (mit Schillerpin).',
			'shiny_gen8_masuda_link' => 'Bulbapedia - Masuda Method',
			'shiny_gen8_radar_title' => 'Poké-Radar (Nur BDSP)',
			'shiny_gen8_radar_desc' => 'Exklusiv in den Sinnoh-Remakes: Erreiche eine Kette von 40 im hohen Gras, um die Shiny-Chance auf gigantische 1:99 pro glitzerndem Grasfeld zu erhöhen!',
			'shiny_gen8_radar_link_yt_de' => 'YouTube - BDSP Radar Tutorial (DE)',
			'shiny_gen8_radar_link_reddit' => 'Reddit - BDSP Radar Guide (EN)',
			'shiny_gen8_radar_link_yt_en' => 'YouTube - BDSP Radar Tutorial (EN)',
			'shiny_gen85_pla_title' => 'Legenden: Arceus (Hisui)',
			'shiny_gen85_pla_desc' => 'Shinys laufen sichtbar in der Overworld herum! Sie kündigen sich durch einen **deutlichen Sound-Jingle und visuellen Effekt** an. Du kannst den Schillerpin und das Forschungslevel kombinieren.',
			'shiny_gen85_pla_outbreaks_title' => 'Massive Massenauftritte (MMOs)',
			'shiny_gen85_pla_outbreaks_desc' => 'Das effektivste Tool in Hisui. Durch das gezielte Besiegen/Fangen in Massenauftritten sinkt die Chance auf bis zu 1:128.',
			'shiny_gen85_locked_title' => 'Shiny Locks in Hisui',
			'shiny_gen85_locked_desc' => 'Achtung: ALLE Legendären und Mysteriösen Pokémon (Arceus, Dialga, Palkia, Darkrai etc.) sowie einmalige Quest-Begegnungen sind in Hisui Shiny Locked!',
			'shiny_gen8_pla_link_reddit' => 'Reddit - PLA Outbreaks Guide (EN)',
			'shiny_gen8_pla_link_bisafans' => 'Bisafans - PLA Outbreaks Guide (DE)',
			'shiny_guide_gen9' => 'Generation 9 (Karmesin & Purpur)',
			'shiny_guide_gen9_5' => 'Generation 9.5 (Legenden: Z-A)',
			'shiny_gen9_sv_title' => 'Karmesin & Purpur (Paldea)',
			'shiny_gen9_sv_desc' => 'Basis-Chance 1:4096. Shinys sind in der Overworld sichtbar, machen aber KEINEN Sound! Nutze die Let\'s Go-Funktion (Auto-Kampf), da dein Partner Shinys strikt verschont.',
			'shiny_gen9_sandwich_title' => 'Sandwiches (Schillerkraft)',
			'shiny_gen9_sandwich_desc' => 'Mit Geheimgewürzen stellst du Schillerkraft Lv. 3 her. Erhöht die Shiny-Chance massiv (bis zu 1:512 mit Pin).',
			'shiny_gen9_outbreak_title' => 'Massenaufläufe (Outbreaks)',
			'shiny_gen9_outbreak_desc' => 'Besiege 60+ Pokémon im Auto-Kampf in einem Auflauf für die maximale Bonus-Chance. Kombinierbar mit Sandwiches!',
			'shiny_gen9_isolation_title' => 'Isolation Hunting (Begegnungskraft)',
			'shiny_gen9_isolation_desc' => 'Nutze Sandwiches mit \'Begegnungskraft\' an Orten, wo nur das Ziel-Pokémon diesen Typ hat. Das zwingt das Spiel, fast ausschließlich dein Ziel spawnen zu lassen!',
			'shiny_gen9_locked_title' => 'Shiny Locks in Karmesin & Purpur',
			'shiny_gen9_locked_desc' => 'Zahlreiche Legendäre (Koraidon, Miraidon, Ruinen-Legis, Paradox-Legis, Terapagos etc.) sowie Gierspenst (außer Event-Raids) und Blutmond-Ursaluna sind Shiny Locked!',
			'shiny_gen9_link_sandwich' => 'Polygon - Sandwich Rezepte & Guide (EN)',
			'shiny_gen9_link_outbreak' => 'YouTube - SV Shiny Hunting Guide (EN)',
			'shiny_gen9_link_bisa' => 'Bisafans - Shiny Hunting in SV (DE)',
			'shiny_gen95_plza_title' => 'Legenden: Z-A (Lumiose City)',
			'shiny_gen95_plza_desc' => 'Der Shiny-Sound ist zurück! Bis zu 10 Shinys können gleichzeitig auf der Map existieren und werden dauerhaft gespeichert, bevor das älteste despawnt.',
			'shiny_gen95_donut_title' => 'Donuts & Spawns (50m/70m Trick)',
			'shiny_gen95_donut_desc' => 'Donuts erhöhen die Shiny-Chance! Neue Pokémon spawnen im Umkreis von 50m. Legenden kannst du resetten, indem du 70m weggehst (Despawn) und wieder kommst (neuer Spawn bei 50m).',
			'shiny_gen95_locked_title' => 'Shiny Locks in Legenden: Z-A',
			'shiny_gen95_locked_desc' => 'Kyogre, Groudon, Rayquaza, Xerneas, Yveltal, Zygarde, Heatran, Darkrai und alle Nebenmissions-Begegnungen (außer Voltilamm) sind gesperrt!',
			'shiny_gen95_link_reddit' => 'Reddit - Best PLZA Hunting Methods (EN)',
			'shiny_gen95_link_ign' => 'IGN - PLZA Shiny Guide (EN)',
			'shiny_gen95_link_yt_de' => 'YouTube - Z-A Shiny Tutorial (DE)',
			'route_tracker_title' => 'Routen-Tracker',
			'search_route_pokemon' => 'Suche Route oder Pokémon...',
			'hide_completed_routes' => 'Fertige Routen ausblenden',
			'games_filter_title' => 'Spiele & Editionen filtern',
			'visible_editions' => 'Sichtbare Editionen',
			'generation_x' => 'Generation {0}',
			'none' => 'Keine',
			'all' => 'Alle',
			'box_check_all' => 'Ganze Box abhaken',
			'box_uncheck_all' => 'Ganze Box Markierung aufheben',
			'dex_abilities' => 'Fähigkeiten-Dex',
			'dex_moves' => 'Attacken-Dex',
			'power' => 'Stärke',
			'accuracy' => 'Genauigkeit',
			'pp' => 'AP',
			'category' => 'Kategorie',
			'type' => 'Typ',
			'learned_by' => 'Erlernbar von',
			'hidden_ability' => 'Versteckte Fähigkeit',
			'normal_ability' => 'Normale Fähigkeit',
			'learned_by_level' => 'Levelaufstieg (Lv. {0})',
			'learned_by_machine' => 'TM/VM',
			'learned_by_egg' => 'Zucht (Ei)',
			'learned_by_tutor' => 'Attacken-Lehrer',
			'region_moves_dex' => 'Attacken-Dex',
			'region_abilities_dex' => 'Fähigkeiten-Dex',
			'special_dex_moves' => 'Attacken-Dex',
			'special_dex_abilities' => 'Fähigkeiten-Dex',
			'special_dex_moves_desc' => 'Eine Übersicht aller verfügbaren Attacken',
			'special_dex_abilities_desc' => 'Eine Übersicht aller verfügbaren Fähigkeiten',
			'registered' => 'Registriert',
			'power_short' => 'Stärke',
			'accuracy_short' => 'Genauigk.',
			'category_physical' => 'Physisch',
			'category_special' => 'Spezial',
			'category_status' => 'Status',
			'hidden_ability_short' => 'Versteckt',
			'normal_ability_short' => 'Normal',
			'sort_by' => 'Sortieren nach',
			'sort_type' => 'Nach Typ gruppieren',
			'ribbons' => 'Bänder',
			'marks' => 'Zeichen',
			'tera_types_title' => 'Terakristallisierung',
			'title' => 'Titel:',
			'location' => 'Fundort / Bedingung:',
			'search' => 'Suchen...',
			'tutorial_info_marks_title' => 'Zeichen',
			'credit_bulbapedia_title' => 'Bulbapedia (Catch Rates)',
			'credit_bulbapedia_sub' => 'Mechaniken für Legends Z-A und Max Raids',
			'credit_ribbons_title' => 'Ribbons.Guide',
			'credit_ribbons_sub' => 'Datenbank für Bänder & Zeichen',
			'alpha_status' => 'Alpha-Pokémon',
			'tutorial_info_alpha_title' => 'Riesige Alphas!',
			'tutorial_info_alpha_text' => 'Manche Pokémon aus Hisui (und bald Z-A) können als riesige Alphas gefangen werden. Markiere sie hier!',
			'tutorial_info_tera_title' => 'Tera-Typen',
			'tutorial_info_tera_text' => 'In Paldea können Pokémon verschiedene Tera-Typen annehmen. Speichere hier, welche Tera-Typen du für dieses Pokémon bereits besitzt.',
			'tutorial_info_ribbons_title' => 'Bänder sammeln',
			'tutorial_info_ribbons_text' => 'Dein Pokémon hat eine Meisterschaft gewonnen oder etwas Besonderes geleistet? Hake hier die Bänder ab, die es gesammelt hat.',
			'tutorial_info_marks_text' => 'Wilde Pokémon können beim Fang besondere Zeichen tragen. Wenn du ein solches gefangen hast, kannst du es hier vermerken.',
			'languages_title' => 'Sprachen',
			'cat_gifts' => 'Geschenke',
			'cat_trades' => 'Tausche',
			'cat_orre' => 'Colosseum & XD',
			'advanced_sort_title' => 'Erweiterte Sortierung',
			'sort_mega_title' => 'Mega-Entwicklungen',
			'sort_gmax_title' => 'Giga-Dynamax',
			'sort_regional_title' => 'Regionalformen',
			'sort_origin_kanto' => 'Ursprungsregion (z.B. Kanto)',
			'sort_mechanic_mega' => 'Region der Mechanik (Kalos/Hoenn)',
			'sort_mechanic_gmax' => 'Region der Mechanik (Galar)',
			'sort_mechanic_regional' => 'Region der Form (z.B. Alola)',
			'cat_silvally' => 'Amigento',
			'cat_arceus' => 'Arceus',
			'cat_furfrou' => 'Coiffwaff',
			'shiny_meltan_go_title' => 'Pokémon GO Exklusivität',
			'shiny_meltan_go_desc' => 'Meltan und Melmetal können aktuell ausschließlich in Pokémon GO schillernd erhalten werden (über die Wunderbox während zeitlich begrenzter Event-Zeiträume). In Let\'s Go, Pikachu & Evoli können sie nur von Pokémon GO übertragen werden.',
			'box_edit_title' => 'Boxen bearbeiten',
			'box_edit_add_box' => 'Box hinzufügen',
			'box_edit_rename_box' => 'Box umbenennen',
			'box_edit_delete_box' => 'Box löschen',
			'box_edit_manage_content' => 'Inhalt verwalten',
			'box_edit_select_multiple' => 'Mehrere auswählen',
			'box_edit_remove_selected' => 'Ausgewählte entfernen',
			'box_edit_add_pokemon' => 'Pokémon hinzufügen',
			'box_edit_insert_pokemon' => 'Pokémon hier einfügen',
			'encounter_starter_oak' => 'Starter (Prof. Eich)',
			'encounter_gift_cerulean' => 'Geschenk (Azuria City)',
			'encounter_gift_route24' => 'Geschenk (Route 24)',
			'encounter_gift_vermilion' => 'Geschenk (Orania City)',
			'encounter_gift_mansion' => 'Geschenk (Prismania Villa)',
			'encounter_gift_silph' => 'Geschenk (Silph Co.)',
			'encounter_gift_dojo' => 'Geschenk (Kampf-Dojo)',
			'encounter_fossil_restoration' => 'Fossil-Wiederbelebung',
			'encounter_stationary' => 'Stationäre Begegnung',
			'encounter_trade' => 'In-Game Tausch',
			'encounter_game_corner' => 'Spielhalle',
			'encounter_glitch_8f' => '8F Item Underflow Glitch',
			'box_edit_settings_header' => 'Box-Verwaltung Einstellungen',
			_ => null,
		} ?? switch (path) {
			'box_edit_auto_shift_title' => 'Auto-Verschieben von Pokémon',
			'box_edit_auto_shift_subtitle' => 'Verschiebt Pokémon beim Einfügen vorwärts und beim Entfernen rückwärts, um Lücken zu schließen.',
			'box_edit_strict_limits_title' => 'Strikte Kapazitätsgrenzen',
			'box_edit_strict_limits_subtitle' => 'Erzwingt feste Box-Kapazitätsgrenzen (Spalten × Zeilen) und leitet Überlauf in die nächste verknüpfte Box weiter.',
			'box_edit_pattern_auto_create_title' => 'Musterbasierte Auto-Erstellung',
			'box_edit_pattern_auto_create_subtitle' => 'Erstellt automatisch eine neue Folgebox (z. B. „Kanto 4“), wenn die letzte verknüpfte Box überläuft.',
			'box_edit_auto_delete_empty_title' => 'Leere Boxen automatisch löschen',
			'box_edit_auto_delete_empty_subtitle' => 'Löscht leere Folgeboxen automatisch nach dem Nachrücken von Pokémon (Stammbox bleibt erhalten).',
			'edit_mode_save_title' => 'Änderungen speichern?',
			'edit_mode_discard_title' => 'Möchtest du alle Änderungen verwerfen?',
			'yes' => 'Ja',
			'discard' => 'Verwerfen',
			'box_action_swap' => 'Tauschen',
			'move_selected_block' => 'Hierhin verschieben',
			'move_selected_to_box' => 'In Box verschieben...',
			'tap_target_slot' => 'Tippe auf Ziel-Slot...',
			'select_target_box' => 'Zielbox auswählen',
			'cancel_selection' => 'Auswahl aufheben',
			'insert_placeholder' => 'Platzhalter einfügen',
			'placeholder' => 'Platzhalter',
			'placeholder_desc' => 'Fixierte Lücke (geschützt vor Auto-Shift)',
			'search_pokemon_hint' => 'Name oder Pokédex-Nr. suchen...',
			'all_regions' => 'Alle Regionen',
			'all_forms' => 'Alle Formen',
			'form_normal' => 'Normal',
			'filter_regions' => 'Regionen',
			'filter_forms' => 'Formen',
			'filter_gender' => 'Geschlecht',
			'gender_male' => 'Männlich (♂)',
			'gender_female' => 'Weiblich (♀)',
			'gender_differences' => 'Unterschiede',
			'filter_variant' => 'Variante',
			'variant_normal' => 'Standard',
			'variant_shiny' => 'Schillernd',
			'box_menu' => 'Box-Menü',
			'reset_filters' => 'Filter zurücksetzen',
			'grid_size_title' => 'Rastergröße ändern',
			'grid_columns' => 'Spalten',
			'grid_rows' => 'Reihen',
			'grid_apply_all' => 'Für alle Boxen übernehmen',
			'grid_columns_tooltip' => 'Spaltenanzahl ändern',
			'box_edit_empty_slot' => 'Leerer Platz',
			'box_edit_remove' => 'Entfernen',
			'shiny_hunt_hub_title' => 'Shiny Hunt Tracker',
			'shiny_hunt_tab_active' => 'Aktiv',
			'shiny_hunt_tab_paused' => 'Pausiert',
			'shiny_hunt_tab_completed' => 'Beendet',
			'shiny_hunt_new_hunt' => 'Neuer Hunt',
			'shiny_hunt_empty_active' => 'Keine aktiven Hunts vorhanden.',
			'shiny_hunt_empty_paused' => 'Keine pausierten Hunts.',
			'shiny_hunt_empty_completed' => 'Noch keine Shinies gefangen. Starte jetzt deinen ersten Hunt!',
			'shiny_hunt_resume' => 'Fortsetzen',
			'shiny_hunt_pause' => 'Pausieren',
			'shiny_hunt_delete_confirm_title' => 'Hunt löschen?',
			'shiny_hunt_delete_confirm_desc' => 'Möchtest du diesen Hunt wirklich unwiderruflich löschen?',
			'shiny_hunt_tap_to_count' => 'Tippen zum Zählen',
			'shiny_hunt_step_label' => 'Schritt',
			'shiny_hunt_manual_count_title' => 'Zähler manuell anpassen',
			'shiny_hunt_manual_count_hint' => 'Begegnungen eingeben...',
			'shiny_hunt_phase_label' => 'Phase',
			'shiny_hunt_total_label' => 'Gesamt',
			'shiny_hunt_rolls_label' => 'Würfe',
			'shiny_hunt_chance_at_least_one' => 'Chance auf mind. 1 Shiny',
			'shiny_hunt_chance_none_yet' => 'Bisher noch kein Shiny',
			'shiny_hunt_time_spent' => 'Zeitaufwand',
			'shiny_hunt_pace_per_hour' => 'Pace',
			'shiny_hunt_encounters_per_hour' => 'Encounters/Std.',
			'shiny_hunt_lock_mode_title' => 'Tap-Only Modus (Schloss)',
			'shiny_hunt_lock_mode_desc' => 'Sperrt sekundäre Tasten gegen Fehlklicks.',
			'shiny_hunt_sprite_toggle_shiny' => '✨ Shiny',
			'shiny_hunt_sprite_toggle_normal' => 'Normal',
			'shiny_hunt_record_phase_btn' => 'Phasen-Shiny',
			'shiny_hunt_caught_btn' => '🎉 Shiny gefangen!',
			'shiny_hunt_settings_title' => 'Counter-Einstellungen',
			'shiny_hunt_setting_haptics' => 'Haptisches Feedback',
			'shiny_hunt_setting_wakelock' => 'Bildschirm eingeschaltet lassen',
			'shiny_hunt_shortcuts_title' => 'Tastaturkürzel',
			'shiny_hunt_shortcut_space' => 'Leertaste / Pfeil oben: + Schrittweite',
			'shiny_hunt_shortcut_down' => 'Pfeil unten / Minus: - Schrittweite',
			'shiny_hunt_shortcut_pause' => 'P: Pause / Fortsetzen',
			'shiny_hunt_phase_history_title' => 'Phasen-Chronik',
			'shiny_hunt_dialog_create_title' => 'Neuen Shiny Hunt starten',
			'shiny_hunt_dialog_edit_title' => 'Shiny Hunt bearbeiten',
			'shiny_hunt_target_pokemon' => 'Ziel-Pokémon',
			'shiny_hunt_title_field' => 'Titel / Notiz',
			'shiny_hunt_game' => 'Spiel / Edition',
			'shiny_hunt_method' => 'Methode',
			'shiny_hunt_has_charm' => 'Schillerpin aktiv',
			'shiny_hunt_chain_prepared' => 'Kette ist bereits vorbereitet (direkt mit Max-Odds zählen)',
			'shiny_hunt_base_odds' => 'Basis-Quote (1/D)',
			'shiny_hunt_spawns_per_step' => 'Spawns pro Schritt (k)',
			'shiny_hunt_custom_odds' => 'Eigene Quote',
			'shiny_hunt_catch_dialog_title' => '🎉 Glückwunsch zum Shiny!',
			'shiny_hunt_ball_select' => 'Verwendeter Pokéball',
			'shiny_hunt_save_to_dex' => 'Als gefangen & Shiny in Dex eintragen',
			'shiny_hunt_target_dex' => 'Ziel-Dex',
			'shiny_hunt_notes' => 'Notizen (Wesen, DVs, Fangort...)',
			'shiny_hunt_phase_dialog_title' => 'Phasen-Shiny protokollieren',
			'shiny_hunt_phase_pokemon_name' => 'Welches Pokémon ist aufgetaucht?',
			'shiny_hunt_save_phase_to_dex' => 'Phasen-Shiny ebenfalls im Dex eintragen',
			'shiny_hunt_badge_tooltip' => 'Aktive Shiny Hunts',
			'shiny_hunt_start_from_guide' => '🎯 Hunt starten',
			'start' => 'Starten',
			'confirm' => 'Bestätigen',
			'shiny_hunt_resume_hunt_btn' => 'Fortsetzen',
			'shiny_hunt_pause_hunt_btn' => 'Pausieren',
			'shiny_hunt_start_odd_egg' => '🎯 Hunt starten: Kurioses Ei (14%)',
			'shiny_hunt_start_ditto_glitch' => '🎯 Hunt starten: Shiny-Zucht / Ditto-Glitch (1/64)',
			'shiny_hunt_start_ccg' => '🎯 Hunt starten: Cute Charm Glitch (21,34%)',
			'shiny_hunt_start_hgss_starters' => '🎯 Hunt starten: Starter Soft Reset (k=3)',
			'shiny_hunt_start_silph_scope' => '🎯 Hunt starten: Silph Scope Reroll',
			'shiny_hunt_target_dex_none' => 'Kein Dex (Nicht verknüpft)',
			'shiny_hunt_search_hint' => 'Hunts durchsuchen (Pokémon, Spiel, Notiz)...',
			'shiny_hunt_finish_btn' => 'Beenden',
			'shiny_hunt_finish_dialog_title' => 'Hunt beenden / archivieren',
			'shiny_hunt_finish_dialog_desc' => 'Möchtest du diesen Shiny Hunt als gefangen abschließen oder ohne Fang archivieren?',
			'shiny_hunt_finish_as_caught' => '🎉 Als Shiny gefangen abschließen',
			'shiny_hunt_finish_archive_only' => 'Ohne Fang archivieren',
			'shiny_hunt_completed_banner' => 'Dieser Shiny Hunt ist abgeschlossen und im Archiv.',
			'shiny_hunt_reopen_btn' => 'Hunt wieder aufnehmen',
			'shiny_hunt_back_to_hub' => 'Zurück zur Übersicht',
			'shiny_hunt_matching_ball_badge' => 'Matching Ball',
			'shiny_hunt_sync_to_target_dex' => 'In "{dexTitle}" als gefangen & Shiny markieren',
			'shiny_hunt_pokemon_card_title' => 'Shiny Hunts',
			'shiny_hunt_no_hunts_for_pokemon' => 'Keine aktiven Hunts für dieses Pokémon.',
			'shiny_hunt_start_new_for_pokemon' => '🎯 Neuen Shiny Hunt starten',
			'shiny_hunt_phase_history_card_title' => 'Phasen-Shinies',
			'shiny_hunt_phase_badge' => 'Phase {phase}: {name} ({encounters})',
			'shiny_hunt_search_no_results' => 'Keine Shiny Hunts gefunden für "{query}".',
			'shiny_hunt_step_custom' => 'Custom',
			'shiny_hunt_step_custom_title' => 'Eigene Schrittweite',
			'shiny_hunt_step_custom_hint' => 'Schrittweite eingeben (z. B. 3, 30)...',
			'shiny_hunt_hunting_type' => 'Jagdart / Herkunft',
			'shiny_hunt_type_auto' => 'Automatisch (nach Methode)',
			'shiny_hunt_type_wild' => 'Wildfang',
			'shiny_hunt_type_breeding' => 'Zucht / Ei',
			'shiny_hunt_type_trade' => 'Tausch',
			'shiny_hunt_type_soft_reset' => 'Soft Reset',
			'shiny_hunt_type_raid' => 'Raid',
			'shiny_hunt_type_fossil' => 'Fossil',
			'shiny_hunt_type_gift' => 'Geschenk / Event',
			'shiny_hunt_type_other' => 'Sonstiges',
			'shiny_hunt_reopened_toast' => 'Hunt wurde wieder aktiviert!',
			'shiny_hunt_caught_on' => 'Gefangen am {date}',
			'shiny_hunt_archived_on' => 'Archiviert am {date}',
			'shiny_hunt_catch_details_title' => 'Fang-Details',
			'shiny_hunt_charm_badge' => 'Schillerpin',
			'shiny_hunt_form_label' => 'Form',
			'controls_guide_title' => 'Bedienung & Tastaturkürzel',
			'controls_guide_sub' => 'Shortcuts, Maus- & Touch-Gesten',
			'controls_tab_desktop' => 'Desktop & Web',
			'controls_tab_mobile' => 'Touch & Mobil',
			'controls_platform_hint_desktop' => 'Übersicht über alle Tastatur- und Mauskürzel für Desktop und Web.',
			'controls_platform_hint_mobile' => 'Übersicht über alle Touch-, Wisch- und Longpress-Gesten für Mobilgeräte.',
			'controls_cat_general' => 'Allgemein & Navigation',
			'controls_cat_dex' => 'Pokédex (PC-Box & Liste)',
			'controls_cat_home' => 'Hauptmenü (Home Screen)',
			'controls_cat_shiny_hunt' => 'Shiny Hunt Counter',
			'controls_cat_ribbons_marks' => 'Bänder & Zeichen',
			'controls_cat_abilities_moves' => 'Fähigkeiten & Attacken',
			'controls_nav_back_key' => 'Backspace / Browser Back',
			'controls_nav_back_desc' => 'Zur vorherigen Ansicht zurückkehren oder Ordner schließen',
			'controls_nav_back_gesture' => 'System-Zurück-Geste',
			'controls_nav_back_gesture_desc' => 'Vom Bildschirmrand wischen oder Android-Zurücktaste',
			'controls_folder_nav' => 'Klick / Tippen auf Ordner',
			'controls_folder_nav_desc' => 'Ordner öffnen oder im Ordner navigieren',
			'controls_dex_toggle_click' => 'Linksklick',
			'controls_dex_toggle_tap' => 'Einfaches Antippen',
			'controls_dex_toggle_desc' => 'Status Gefangen/Fehlt umschalten oder leeren Platzhalter belegen',
			'controls_dex_details_click' => 'Rechtsklick',
			'controls_dex_details_longpress' => 'Langer Druck (Longpress)',
			'controls_dex_details_desc' => 'Detail- und Informationsseite des Pokémon öffnen',
			'controls_dex_details_key' => 'Taste I / Strg + Enter',
			'controls_dex_details_key_desc' => 'Pokémon-Details bei Tastaturfokus öffnen',
			'controls_dex_drag_desktop' => 'Maus Drag & Drop',
			'controls_dex_drag_mobile' => 'Langer Druck + Ziehen',
			'controls_dex_drag_desc' => 'Pokémon innerhalb oder zwischen Boxen verschieben / tauschen',
			'controls_dex_multiselect' => 'Mehrfachauswahl (Edit-Modus)',
			'controls_dex_multiselect_desc' => 'Tippen im Bearbeiten-Modus, um mehrere Pokémon zu markieren',
			'controls_home_reorder' => 'Reorder-Handle (Ziehen)',
			'controls_home_reorder_desc' => 'Dexe und Ordner bei manueller Sortierung frei anordnen',
			'controls_home_multiselect' => 'Langer Druck (Longpress)',
			'controls_home_multiselect_desc' => 'Auswahlmodus aktivieren (Mehrfachauswahl für Verschieben & Löschen)',
			'controls_home_menu' => 'Dreipunkt-Menü (⋮)',
			'controls_home_menu_desc' => 'Schnellmenü für Umbenennen, Verschieben, Exportieren & Löschen',
			'controls_hunt_inc_key' => 'Leertaste / Pfeil Oben (↑)',
			'controls_hunt_inc_touch' => 'Große Zählerfläche tippen',
			'controls_hunt_inc_title' => '+1 Begegnung',
			'controls_hunt_inc_desc' => 'Zähler um 1 (oder eingestellte Schrittweite) erhöhen',
			'controls_hunt_dec_key' => 'Pfeil Unten (↓) / Minus (-)',
			'controls_hunt_dec_touch' => 'Minus-Button (-)',
			'controls_hunt_dec_title' => '-1 Begegnung',
			'controls_hunt_dec_desc' => 'Zähler um 1 verringern (Fehlzählung korrigieren)',
			'controls_hunt_pause_key' => 'Taste P',
			'controls_hunt_pause_touch' => 'Pause-Button (⏸)',
			'controls_hunt_pause_title' => 'Pause / Fortsetzen',
			'controls_hunt_pause_desc' => 'Jagd-Timer pausieren oder fortsetzen',
			'controls_hunt_lock' => 'Schloss-Symbol (Tap-Only)',
			'controls_hunt_lock_desc' => 'Fehlklickschutz: Sperrt Tasten und verhindert versehentliche Zählungen',
			'controls_ribbon_toggle_click' => 'Linksklick / Antippen',
			'controls_ribbon_toggle_desc' => 'Band oder Zeichen als erhalten oder nicht erhalten markieren',
			'controls_ribbon_details_click' => 'Rechtsklick / Langer Druck',
			'controls_ribbon_details_desc' => 'Detailinformationen, Beschreibung und Fundort anzeigen',
			'controls_ability_toggle_click' => 'Linksklick / Antippen',
			'controls_ability_toggle_desc' => 'Status (z. B. Beherrscht / Gesehen) umschalten',
			'controls_ability_details_click' => 'Rechtsklick / Langer Druck',
			'controls_ability_details_desc' => 'Detailansicht der Fähigkeit oder Attacke öffnen',
			'gender_differences_title' => 'Geschlechtsunterschiede',
			'gender_differences_subtitle' => 'Optische Unterschiede zwischen den Geschlechtern',
			'gender_differences_note' => 'Hinweis',
			'gender_differences_loading' => 'Lade Geschlechtsunterschiede...',
			'share_dex_card' => 'Erfolgs-Grafik teilen...',
			'share_dex_card_btn' => 'Erfolgs-Grafik',
			'dex_card_title' => 'Erfolgs-Grafik (Living Dex)',
			'dex_card_style_analyst' => 'The Analyst (Infografik)',
			'dex_card_style_certificate' => 'Trainer-Zertifikat',
			'dex_card_style_mosaic' => 'Living Dex Mosaik',
			'dex_card_style_minimalist' => 'Minimalist Glass',
			'dex_card_ratio_16_9' => '16:9 Querformat',
			'dex_card_ratio_1_1' => '1:1 Quadrat',
			'dex_card_ratio_9_16' => '9:16 Story',
			'dex_card_watermark' => 'Hintergrund-Wasserzeichen',
			'dex_card_opacity' => 'Deckkraft',
			'dex_card_no_pokemon' => 'Kein Pokémon (Nur Statistiken)',
			'dex_card_save_png' => 'Als PNG speichern',
			'dex_card_share' => 'Teilen',
			'dex_card_copy_text' => 'Text kopieren',
			'dex_card_only_started_gens' => 'Nur angefangene Generationen',
			'dex_card_only_started_gens_sub' => 'Generationen ohne gefangene Pokémon ausblenden',
			'dex_card_type_limit' => 'Typen-Anzeige',
			'dex_card_types_top6' => 'Top 6',
			'dex_card_types_top12' => 'Top 12',
			'dex_card_types_all18' => 'Alle 18',
			'dex_card_copy_success' => 'Erfolgs-Text in die Zwischenablage kopiert!',
			'dex_card_save_success' => 'Erfolgs-Grafik gespeichert:',
			'dex_card_mastered' => 'Gemeistert',
			'dex_card_in_progress' => 'In Arbeit',
			'dex_card_diploma_title' => 'Offizielles Pokédex-Diplom',
			'dex_card_diploma_sub' => 'Verliehen für lückenlose Sammlung und Meisterschaft',
			'dex_card_champion_seal' => 'Champion-Siegel',
			'dex_card_registered_pkv' => 'Registriert in PokéVault',
			'dex_card_verified' => 'Geprüft durch Spielstand-Inspektion',
			'dex_card_mosaic_grid' => 'Living-Dex-Übersichtsraster',
			'dex_card_missing' => 'Fehlend',
			'dex_card_boxes_count' => 'PC-Boxen',
			'dex_card_boxes_archived' => 'Strukturiert archiviert',
			'dex_card_remaining' => 'Lücken verbleibend',
			'dex_card_star_rank' => 'Stern-Rang',
			'dex_card_mastery' => 'Meisterschaft',
			'dex_card_perfect_order' => 'Perfekte Ordnung',
			'alphas_count' => 'Alphas',
			'dex_progress_close' => 'Schließen',
			'dex_progress_generations' => 'Generationen',
			'dex_progress_overall' => 'Gesamtfortschritt',
			'dex_progress_show_all' => 'Alle anzeigen',
			'dex_progress_show_caught' => 'Nur Gefangene anzeigen',
			'dex_progress_show_missing' => 'Nur Fehlende anzeigen',
			'dex_progress_subtitle_overview' => 'Gesamt-Übersicht',
			'dex_progress_title' => 'Dex-Fortschritt & Statistiken',
			'dex_progress_tooltip' => 'Fortschritt & Statistiken anzeigen',
			'dex_progress_types' => 'Typen',
			'dex_progress_variants' => 'Varianten & Formen',
			'no_pokemon_card' => 'Kein Pokémon',
			'no_watermark_sub' => 'Wasserzeichen deaktiviert',
			'select_pokemon' => 'Pokémon auswählen',
			'shinies_count' => 'Shinies',
			'tutorial_v16_tour_dex_text' => 'Öffne deinen Dex, um das erweiterte Boxen-System, Geschlechter-Varianten und den Fangraten-Rechner zu nutzen!',
			'tutorial_v16_tour_dex_title' => 'v1.6: Neue Features in deinen Dexen',
			'tutorial_v16_tour_fab_text' => 'Erstelle einen neuen Dex, um die neuen Optionen wie Geschlechtsformen und Mega-Evolutionen auszuprobieren!',
			'tutorial_v16_tour_fab_title' => 'v1.6: Neuen Dex erstellen',
			'tutorial_v16_tour_shiny_text' => 'Tippe hier, um deine Shiny Hunts mit Begegnungszähler, Phasen und Fangwahrscheinlichkeiten zu tracken!',
			'tutorial_v16_tour_shiny_title' => 'v1.6: Shiny Hunt Tracker',
			'variant_alpha' => 'Alpha-Pokémon',
			'variant_gmax' => 'Gigadynamax',
			'variant_mega' => 'Mega-Entwicklungen',
			'variant_regional' => 'Regionalformen',
			'variant_regular' => 'Reguläre Formen',
			'variant_shinies' => 'Shinies',
			'actions' => 'Schnellaktionen',
			'active' => 'Aktiv',
			'add_pokemon' => 'Hinzufügen',
			'alpha_status_sub' => 'Als Alpha markieren',
			'clear' => 'Suche zurücksetzen',
			'details' => 'Fang-Details',
			'dex_delete_text' => 'Möchtest du diesen Pokédex wirklich löschen?',
			'dex_delete_title' => 'Pokédex löschen',
			'dex_progress_forms' => 'Formen & Varianten',
			'folder' => 'Ordnernavigation',
			'lock' => 'Fehlklickschutz',
			'mark_as_shiny' => 'Als schillernd markieren',
			'matching_ball_normal' => 'Matching Ball (Normal)',
			'matching_ball_shiny' => 'Matching Ball (Shiny)',
			'move_pokemon' => 'Verschieben & Tauschen',
			'no_results' => 'Keine Einträge',
			'notes' => 'Notizen',
			'previous' => 'Zurück',
			'remove_from_box_desc' => 'Möchtest du dieses Pokémon nur aus dieser Box entfernen oder komplett aus dem Pokédex ausblenden?',
			'remove_from_box_only' => 'Nur aus Box',
			'remove_from_box_title' => 'Pokémon entfernen',
			'reset' => 'Zurücksetzen',
			'shiny_hunt_active' => 'Aktiver Hunt: Encounters',
			'shiny_hunt_active_desc' => 'Noch nicht abgeschlossen',
			'shiny_hunt_completed_at' => 'Hunt beendet / archiviert',
			'shiny_hunt_completed_status' => 'Beendet',
			'shiny_hunt_duration_under_minute' => '< 1 Min.',
			'shiny_hunt_gross_duration' => 'Gesamtdauer',
			'shiny_hunt_net_time' => 'Jagdzeit (Netto)',
			'shiny_hunt_no_pauses' => 'Keine Pausen aufgezeichnet',
			'shiny_hunt_pause_label' => 'Pause',
			'shiny_hunt_pause_ongoing' => 'aktiv pausiert',
			'shiny_hunt_pause_total' => 'Pausen (Summe)',
			'shiny_hunt_paused' => 'Pausiert',
			'shiny_hunt_paused_since' => 'Pausiert seit',
			'shiny_hunt_pauses_label' => 'Pausen',
			'shiny_hunt_started' => 'Start',
			'shiny_hunt_started_at' => 'Hunt gestartet',
			'shiny_hunt_started_label' => 'Gestartet',
			'shiny_hunt_status_active' => 'Hunt läuft aktiv',
			'shiny_hunt_status_currently_paused' => 'Aktuell pausiert',
			'shiny_hunt_timeline_btn' => 'Zeiten',
			'shiny_hunt_timeline_chip' => 'Zeiten & Pausen',
			'shiny_hunt_timeline_events' => 'Ablauf & Intervalle',
			'shiny_hunt_timeline_title' => 'Timeline & Pausen',
			'sort' => 'Manuelle Sortierung',
			'special_info' => 'Info',
			'status' => 'Status ändern',
			'tutorial_wrong_tap' => 'Klick direkt auf den markierten Bereich!',
			'unknown' => 'Unbekannt',
			'sort_most_caught' => 'Meiste Gefangen',
			'sort_by_region' => 'Nach Region',
			'move_tooltip' => 'Verschieben',
			'delete_tooltip' => 'Löschen',
			'no_dexes_to_export' => 'Keine Dexe zum Exportieren in der Auswahl gefunden.',
			'menu_edit' => 'Bearbeiten',
			'menu_move' => 'Verschieben...',
			'menu_delete' => 'Löschen',
			'reset_boxes_title' => 'Boxen zurücksetzen?',
			'reset_boxes_content' => 'Möchtest du alle deine benutzerdefinierten Boxen löschen und das Layout auf den Standard-Pokédex zurücksetzen? Deine gefangenen Pokémon bleiben dabei erhalten!',
			'reset_boxes_action' => 'Zurücksetzen',
			'reset_boxes_tooltip' => 'Auf Standard zurücksetzen',
			'calc_gen_1' => 'Gen 1 (Rot/Blau/Gelb)',
			'calc_gen_2' => 'Gen 2 (Gold/Silber/Kristall)',
			'calc_gen_3_4' => 'Gen 3 & 4 (R/S/S/D/P/P)',
			'calc_gen_5' => 'Gen 5 (Schwarz/Weiß 1&2)',
			'calc_gen_6_7' => 'Gen 6 & 7 (X/Y/S/M)',
			'calc_gen_7_5' => 'Gen 7.5 (Let\'s Go)',
			'calc_gen_8' => 'Gen 8 (Schwert/Schild)',
			'calc_gen_8_5' => 'Gen 8.5 (Legenden: Arceus)',
			'calc_gen_9' => 'Gen 9 (Karmesin/Purpur)',
			'calc_gen_9_5' => 'Gen 9.5 (Legenden: Z-A)',
			'calc_mult_under_30' => '< 30 gefangen (0.0x)',
			'calc_mult_30_plus' => '30+ gefangen (0.5x)',
			'calc_mult_150_plus' => '150+ gefangen (1.0x)',
			'calc_mult_300_plus' => '300+ gefangen (1.5x)',
			'calc_mult_450_plus' => '450+ gefangen (2.0x)',
			'calc_mult_600_plus' => '600+ gefangen (2.5x)',
			'no_older_versions' => 'Keine älteren Versionen gefunden.',
			'select_pokemon_warning' => 'Bitte ein Pokémon auswählen',
			'please_login_first' => 'Bitte logge dich zuerst ein!',
			'hunt_game_label' => 'Spiel: {game} (Gen {gen})',
			'change_btn' => 'Ändern',
			'moved_successfully' => 'Erfolgreich verschoben.',
			'deleted_successfully' => 'Erfolgreich gelöscht.',
			'items_deleted' => 'Elemente gelöscht.',
			'create_new_pokedex' => 'Neuen Pokédex erstellen',
			'tutorial_chapter_scanner_mobile_title' => '11. Kamera- & Foto-Scanner',
			'tutorial_chapter_scanner_mobile_desc' => 'Live-Kamera-OCR, Tap-to-Focus, Scan-Zonen, Foto-Import & In-App Mini-PiP.',
			'tutorial_chapter_scanner_desktop_title' => '11. Overlay-, Fenster- & Kamera-Scanner',
			'tutorial_chapter_scanner_desktop_desc' => 'Fenster-/Snipping-Capture, Always-on-Top Mini-HUD, Multi-Instanzen, Webcam & Foto-OCR.',
			'tutorial_scanner_mob_camera_title' => 'Live-Kamera & Tap-to-Focus',
			'tutorial_scanner_mob_camera_text' => 'Richte dein Handy auf Switch, 3DS oder TV. Tippe direkt ins Kamerabild (auch im Auto-Modus), um den Fokus scharfzustellen.',
			'tutorial_scanner_mob_modes_title' => 'Auto vs. Vierecke (Zonen)',
			'tutorial_scanner_mob_modes_text' => 'Nutze Auto für das ganze Bild oder zeichne exakte Rechtecke für Zone A (Textbox), Zone B (Fokus) und Multi-Instanzen.',
			'tutorial_scanner_mob_photo_title' => 'Foto- & Screenshot-Import',
			'tutorial_scanner_mob_photo_text' => 'Alternativ kannst du jederzeit Fotos oder Screenshots aus deiner Galerie laden und einmalig scannen lassen.',
			'tutorial_scanner_mob_pip_title' => 'Split-Screen & Mini-PiP',
			'tutorial_scanner_mob_pip_text' => 'Wechsle zwischen Vollbild, Split-Tabs oder dem beweglichen Mini-Fenster (PiP), während du in deinen Dexen stöberst.',
			'tutorial_scanner_mob_dex_title' => 'Ziel-Dex, Entwicklung & Diagnose',
			'tutorial_scanner_mob_dex_text' => 'Wähle deinen Ziel-Dex, prüfe fehlende Entwicklungen im Fokus-Tab und kontrolliere Live-OCR-Logs im Diagnose-Tab.',
			'tutorial_scanner_desk_source_title' => 'Spiel-Fenster oder Webcam wählen',
			'tutorial_scanner_desk_source_text' => 'Wähle ein laufendes Emulator-/Spiel-Fenster, einen Monitor oder deine USB-Webcam bzw. Capture-Card als Live-Quelle.',
			'tutorial_scanner_desk_zones_title' => 'Snipping & Zonen (A / B / Multi)',
			'tutorial_scanner_desk_zones_text' => 'Markiere Zone A für Fang-Dialoge, Zone B für Live-Fokus oder lege mehrere Instanzen für paralleles Shiny-Hunting an.',
			'tutorial_scanner_desk_hud_title' => 'Always-on-Top Floating HUD',
			'tutorial_scanner_desk_hud_text' => 'Öffne das schwebende Mini-HUD direkt über deinem Spiel, um Treffer und fehlende Entwicklungen mit einem Klick abzuhaken.',
			'tutorial_scanner_desk_focus_title' => 'Ziel-Dex & Live-Fokus',
			'tutorial_scanner_desk_focus_text' => 'Prüfe sofort, ob das erkannte Pokémon in deinem Ziel-Dex fehlt oder noch Entwicklungen offen sind.',
			'tutorial_scanner_desk_ocr_title' => '9 Spielsprachen & Eigene Muster',
			'tutorial_scanner_desk_ocr_text' => 'Stelle die passende Spielsprache (DE/EN/FR/ES/IT/JA/KO/ZH) ein und ergänze bei Bedarf eigene Textmuster.',
			'tutorial_scanner_update_badge' => 'UPDATE v1.7',
			'tutorial_scanner_update_mob_title' => 'Bzzzt! Kamera-Scanner & Guide sind da!',
			'tutorial_scanner_update_mob_desc' => 'Hallo Trainer! Entdecke die neuen v1.7-Features: Kamera- & Foto-Scanner, Mini-PiP sowie das neue Multi-Hunt Dashboard mit Visuellem Auto-Counter!',
			'tutorial_scanner_mob_f1_title' => 'Flüssige Live-Kamera-OCR',
			'tutorial_scanner_mob_f1_desc' => 'Hoch- & Querformat, Tap-to-Focus und Offline-OCR in allen 9 Spielsprachen.',
			'tutorial_scanner_mob_f2_title' => 'Präzise Scan-Zonen & Foto-Import',
			'tutorial_scanner_mob_f2_desc' => 'Zone A/B zeichnen, Multi-Instanzen oder Fotos direkt aus der Galerie scannen.',
			'tutorial_scanner_mob_f3_title' => 'Bewegliches In-App Mini-PiP',
			'tutorial_scanner_mob_f3_desc' => 'Scanne im schwebenden Mini-Fenster weiter, während du in PokéVault navigierst.',
			'tutorial_scanner_update_desk_title' => 'Bzzzt! Dein Overlay- & Kamera-Guide!',
			'tutorial_scanner_update_desk_desc' => 'Hallo Trainer! Entdecke die neuen v1.7-Features: Desktop-Overlay, Snipping-Zonen, Floating HUD sowie das neue Multi-Hunt Dashboard mit Visuellem Auto-Counter!',
			'tutorial_scanner_desk_f1_title' => 'Fenster-, Monitor- & Webcam-Scan',
			'tutorial_scanner_desk_f1_desc' => 'Erfasst Emulatoren, Capture-Cards, USB-Webcams und Foto-Dateien in Echtzeit.',
			'tutorial_scanner_desk_f2_title' => 'Snipping-Zonen & Multi-Instanz',
			'tutorial_scanner_desk_f2_desc' => 'Freie Bereiche für Fangboxen, Live-Fokus und parallele Shiny-Hunt-Slots.',
			'tutorial_scanner_desk_f3_title' => 'Always-on-Top Mini-HUD',
			'tutorial_scanner_desk_f3_desc' => 'Schwebendes Overlay direkt über dem Spiel mit 1-Klick-Dex-Eintrag.',
			'tutorial_scanner_home_delta_title' => 'Neuer Scanner-Guide!',
			'tutorial_scanner_home_delta_text' => 'Tippe hier auf das Scanner-Icon, um direkt deine interaktive Rotom-Tour im Scanner zu starten!',
			'tutorial_scanner_tour_btn' => 'Scanner-Tour starten',
			'tutorial_new_badge' => 'NEU',
			'tutorial_scanner_desk_dex_title' => 'Ziel-Pokédex wählen',
			'tutorial_scanner_desk_dex_text' => 'Lege hier fest, in welchem Pokédex erkannte Pokémon und Fänge automatisch eingetragen werden.',
			'tutorial_scanner_desk_borders_title' => 'Farbige Scan-Rahmen',
			'tutorial_scanner_desk_borders_text' => 'Zeigt die markierten Scan-Zonen als farbige Overlay-Rahmen direkt über deinem Desktop oder Spiel an.',
			'tutorial_scanner_desk_zone_a_title' => 'Scan-Bereich (Zone A)',
			'tutorial_scanner_desk_zone_a_text' => 'Definiert die Textbox für Fang- und Encounter-Meldungen – per Preset (z. B. Unten) oder frei gezeichnet.',
			'tutorial_scanner_desk_zone_b_title' => 'Live-Fokus-Zone (Zone B)',
			'tutorial_scanner_desk_zone_b_text' => 'Optionale zweite Zone für Gegner-Infoleisten (oben links/rechts): erkennt Pokémon sofort und prüft fehlende Entwicklungen.',
			'tutorial_scanner_desk_multi_title' => 'Multi-Instanzen (#2, #3 ...)',
			'tutorial_scanner_desk_multi_text' => 'Füge parallele Emulator-Fenster oder Zonen hinzu, um mehrere Spiele gleichzeitig auf Encounters und Shinys zu scannen.',
			'tutorial_scanner_desk_feed_title' => 'Live-Ereignisse & OCR-Optionen',
			'tutorial_scanner_desk_feed_text' => 'Hier erscheinen alle Treffer samt 1-Klick-Eintrag. Über das Zahnrad oben stellst du 9 Spielsprachen, Scan-Intervall und eigene Muster ein.',
			'scanner_home_desktop_webcam' => 'Tracker & Webcam wählen',
			'scanner_home_desktop_only' => 'Desktop Tracker & Overlay',
			'scanner_home_mobile_camera' => 'Kamera-Tracker',
			'scanner_home_webcam_photo' => 'Webcam- & Foto-Tracker',
			'scanner_profile_standard' => 'Standard',
			'scanner_profile_pixel_art' => 'Pixel-Art (DS)',
			'scanner_profile_camera_display' => 'Kamera / Display',
			'scanner_preset_full_window' => 'Ganzes Fenster',
			'scanner_preset_ds_top' => 'DS Oben',
			'scanner_preset_ds_bottom' => 'DS Unten',
			'scanner_preset_bottom_dialogue' => 'Textbox unten',
			'scanner_focus_disabled' => 'Aus',
			'scanner_focus_top_left' => 'Oben Links',
			'scanner_focus_top_right' => 'Oben Rechts',
			'scanner_focus_top_banner' => 'Oberer Streifen',
			'scanner_focus_custom' => 'Eigener Bereich',
			'scanner_evo_all_caught' => 'Alle Entw. ✓ Im Dex',
			'scanner_evo_missing' => 'Entw.: {names}{extra} fehlt!',
			'scanner_evo_hud_missing' => 'Entw. offen: {names}',
			'scanner_evo_hud_complete' => 'Entw. komplett ✓',
			'scanner_web_ocr_error' => 'Web-OCR Fehler',
			'scanner_web_ocr_loading' => 'Lade {lang}...',
			'scanner_web_ocr_local' => 'Tesseract.js (Lokal: {lang})',
			'scanner_web_ocr_indexeddb' => 'Tesseract.js ({lang} · IndexedDB)',
			'scanner_dock_live' => 'LIVE',
			'scanner_dock_paused' => 'PAUSIERT',
			'scanner_dock_active' => 'Live-Tracker aktiv',
			'scanner_dock_inactive' => 'Tracker pausiert',
			'scanner_dock_caught' => '✔ Gefangen',
			'scanner_dock_missing' => 'Fehlt im Ziel-Dex',
			'scanner_dock_target_dex' => 'Ziel-Dex: {title} ({count} gefangen)',
			'scanner_dock_add_caught' => '+ Eintragen',
			'scanner_dock_pause_tooltip' => 'Pausieren',
			'scanner_dock_resume_tooltip' => 'Fortsetzen',
			'scanner_dock_hud_hide_tooltip' => 'HUD ausblenden',
			'scanner_dock_hud_open_tooltip' => 'HUD öffnen',
			'scanner_dock_setup_tooltip' => 'Scanner-Setup öffnen',
			'scanner_dock_hud_active' => 'HUD aktiv',
			'scanner_dock_hud' => 'HUD',
			'scanner_dock_setup' => 'Setup',
			'scanner_dock_close_tooltip' => 'Tracker beenden',
			'scanner_waiting_for_game' => 'Warte auf Spiel...',
			'scanner_hud_missing' => '⚠️ Fehlt im Ziel-Dex',
			'scanner_hud_footer' => 'Always-on-Top · Klick + zum Eintragen',
			'scanner_hud_live_label' => 'LIVE SCAN',
			'scanner_hud_shiny_badge' => 'SHINY',
			'scanner_hud_add_tooltip' => 'In Ziel-Dex eintragen',
			'scanner_hud_transparent_tooltip' => 'Transparenz',
			'scanner_hud_pin_off_tooltip' => 'Nicht mehr fixieren',
			'scanner_hud_pin_on_tooltip' => 'Immer im Vordergrund',
			'scanner_hud_expand_tooltip' => 'Maximieren',
			'scanner_hud_compact_tooltip' => 'Kompaktansicht',
			'scanner_hud_close_tooltip' => 'Schließen',
			'scanner_pause_suffix' => 'Pause',
			'scanner_native_snipping_hint' => 'Ziehe einen Bereich über das Spiel · Enter/Klick bestätigt · Esc bricht ab',
			'scanner_native_snipping_confirm' => 'Scannen',
			'scanner_native_snipping_cancel' => 'Abbrechen',
			'scanner_desk_title' => 'Desktop Tracker & Overlay',
			'scanner_webcam_title' => 'Webcam Tracker',
			'scanner_ocr_active' => 'OCR Aktiv',
			'scanner_ocr_paused' => 'Pausiert',
			'scanner_ocr_fallback_badge' => 'OCR: {tag} (Fallback: {fallback})',
			'scanner_hud_close_btn' => 'HUD schließen',
			'scanner_hud_open_btn' => 'Floating HUD öffnen',
			'scanner_alert_settings_tooltip' => 'Alarm- & Töne-Einstellungen',
			'scanner_refresh_windows_tooltip' => 'Fenster aktualisieren',
			'scanner_settings_tooltip' => 'Einstellungen',
			'scanner_tutorial_tooltip' => 'Scanner-Tutorial',
			'scanner_source_header' => 'Scan-Quelle / Zielfenster',
			'scanner_loading' => 'Lade...',
			'scanner_refresh' => 'Aktualisieren',
			'scanner_custom_desktop_region' => 'Eigener Desktop-Bereich',
			'scanner_back_to_window' => 'Zu Fenster',
			'scanner_photo_meta' => 'Foto',
			'scanner_minimized_meta' => 'minimiert',
			'scanner_scan_now' => 'Jetzt scannen',
			'scanner_target_dex_header' => 'ZIEL-POKÉDEX',
			'scanner_change_dex_btn' => 'Dex wechseln →',
			'scanner_no_dex_selected' => 'Kein Dex ausgewählt',
			'scanner_caught_of_total' => '{caught} von {total} gefangen',
			'scanner_show_borders_label' => 'Farbige Bildschirm-Rahmen anzeigen',
			'scanner_zone_a_header' => 'SCAN-BEREICH (ZONE A)',
			'scanner_zone_a_badge' => 'GRÜN · TEXTBOX',
			'scanner_zone_a_info_tooltip' => 'Info zu Scan-Bereich (Zone A)',
			'scanner_zone_a_info_title' => 'Wofür ist Scan-Bereich (Zone A)?',
			'scanner_zone_a_info_body' => 'Haupt-Scan-Zone für Spieltexte (z. B. Dialogbox unten). Erkennt Fänge, Entwicklungen und wilde Begegnungen und trägt gefangene Pokémon automatisch in deinen Ziel-Dex ein.',
			'scanner_mode_full_window_pct' => 'Ganzes Fenster (100%)',
			'scanner_mode_ds_top_pct' => 'DS Oben (Top-Screen 50%)',
			'scanner_mode_ds_bottom_pct' => 'DS Unten (Touchscreen 50%)',
			'scanner_mode_dialogue_pct' => 'Textbox unten (30%)',
			_ => null,
		} ?? switch (path) {
			'scanner_btn_ds_top' => 'DS Oben (Top)',
			'scanner_btn_ds_bottom' => 'DS Unten (Touch)',
			'scanner_monitor_hint' => 'Wähle ein Emulator-Fenster oder markiere einen Live-OCR-Bereich auf dem Desktop.',
			'scanner_status_live_ocr_active' => 'LIVE-OCR AKTIV',
			'scanner_status_live_ocr_paused' => 'LIVE-OCR PAUSIERT',
			'scanner_status_monitor_active' => 'LIVE-OCR ÜBERWACHT MONITOR',
			'scanner_status_monitor_paused' => 'MONITOR-VORSCHAU · PAUSIERT',
			'scanner_status_window_active' => 'LIVE-OCR ÜBERWACHT FENSTER',
			'scanner_status_window_paused' => 'FENSTER-VORSCHAU PAUSIERT',
			'scanner_enlarge_live_preview' => 'Live-Bild vergrößern',
			'scanner_monitor_preview_hint' => 'Vorschau ohne Auto-OCR (↻ aktualisieren)',
			'scanner_waiting_text_interval' => 'Warte auf Text (alle {interval})...',
			'scanner_refresh_monitor_tooltip' => 'Monitor-Vorschau aktualisieren',
			'scanner_reset_region_tooltip' => 'Bereich zurücksetzen',
			'scanner_redraw_scan_region' => 'Scan-Bereich neu zeichnen',
			'scanner_draw_scan_region' => 'Scan-Bereich frei zeichnen',
			'scanner_zone_scan_label' => 'Scan',
			'scanner_zone_focus_label' => 'Fokus',
			'scanner_zone_b_header' => 'LIVE-FOKUS-ZONE (ZONE B)',
			'scanner_zone_b_badge' => 'TÜRKIS · NUR ENCOUNTER',
			'scanner_zone_b_info_tooltip' => 'Info zu Live-Fokus-Zone (Zone B)',
			'scanner_zone_b_info_title' => 'Wofür ist Live-Fokus-Zone (Zone B)?',
			'scanner_zone_b_info_body' => 'Liest nur den Gegnernamen oben im Kampf-HUD (z. B. oben links/rechts oder frei markiert) als Begegnung — perfekt für Live-Fokus und Mehrfachbegegnungen, ohne eigene Pokémon oder Teammitglieder als gefangen zu werten.',
			'scanner_redraw_focus_region' => 'Fokus-Bereich neu zeichnen',
			'scanner_draw_focus_region' => 'Live-Fokus-Bereich frei zeichnen',
			'scanner_zone_b_active' => 'Zone B aktiv ({preset})',
			'scanner_disable_focus_tooltip' => 'Fokus-Bereich deaktivieren',
			'scanner_ignored_team_header' => 'IGNORIERTE TEAM-POKÉMON (STARTER-SCHUTZ)',
			'scanner_multi_header' => 'MULTI-INSTANZEN',
			'scanner_multi_active_count' => '{count} aktiv',
			'scanner_multi_subtitle' => 'Zone A/B oben = Instanz #1 · Weitere Instanzen frei mit Scan/Fokus oder Fenster koppeln:',
			'scanner_multi_add_btn' => '+ Instanz #{id}',
			'scanner_clear_all' => 'Alle löschen',
			'scanner_multi_free_regions' => 'Freie Bereiche (ohne festes Fenster)',
			'scanner_multi_bound_window' => 'Gebundenes Fenster',
			'scanner_multi_role_both' => 'Scan + Fokus',
			'scanner_multi_role_scan' => 'Nur Scan',
			'scanner_multi_role_focus' => 'Nur Fokus',
			'scanner_multi_role_none' => 'Bereich wählen',
			'scanner_multi_instance_title' => 'Instanz {label}',
			'scanner_multi_remove_tooltip' => 'Instanz entfernen',
			'scanner_multi_draw_scan' => 'Scan zeichnen',
			'scanner_multi_redraw_scan' => 'Scan neu',
			'scanner_multi_draw_focus' => 'Fokus zeichnen',
			'scanner_multi_redraw_focus' => 'Fokus neu',
			'scanner_profile_header' => 'SCAN-PROFIL',
			'scanner_profile_info_tooltip' => 'Info zu den Scan-Profilen',
			'scanner_profile_info_title' => 'Bild-Optimierung pro Quelle',
			'scanner_profile_info_body' => '• Standard: Für scharfe PC- oder HD-Fenster.\n• Pixel-Art (DS): Schärft & skaliert pixelige DS-/GBA-Texte (z. B. melonDS, Gen 4/5).\n• Kamera / Display: Erhöht Kontrast für blasse oder abgefilmte Bildschirme.',
			'scanner_rate_header' => 'OCR-SCAN-RATE',
			'scanner_custom_patterns_btn' => 'Eigene OCR-Muster ({count})',
			'scanner_focus_card_header' => 'Aktueller Live-Fokus',
			'scanner_multi_encounter_badge' => 'MEHRFACHBEGEGNUNG ({count})',
			'scanner_caught_badge_short' => '✓ Im Dex',
			'scanner_missing_badge_short' => '★ Fehlt!',
			'scanner_mark_caught_short' => 'Eintragen',
			'scanner_caught_badge_full' => '✓ Im Ziel-Dex gefangen',
			'scanner_missing_badge_full' => '★ Fehlt im Ziel-Dex!',
			'scanner_smart_alternatives' => 'SMART-ALTERNATIVEN (ANTIPPEN ZUM WECHSELN)',
			'scanner_mark_in_dex_btn' => 'In "{dex}" eintragen',
			'scanner_events_header' => 'Live-Ereignisse',
			'scanner_clear_events' => 'Leeren',
			'scanner_events_empty_title' => 'Warte auf In-Game Ereignisse...',
			'scanner_events_empty_subtitle' => 'Wähle dein Emulator-Fenster aus. Fänge und Begegnungen werden automatisch erkannt.',
			'scanner_correct_event_tooltip' => 'Ereignis korrigieren',
			'scanner_event_type_caught' => 'FANG',
			'scanner_event_type_encounter' => 'BEGEGNUNG',
			'scanner_event_type_evolved' => 'ENTWICKLUNG',
			'scanner_event_type_shiny' => 'SHINY',
			'scanner_event_type_alpha' => 'ALPHA',
			'scanner_event_type_info' => 'INFO',
			'scanner_snack_team_ignored' => '{name} wird als eigenes Team ignoriert.',
			'scanner_snack_no_target' => 'Kein Zielfenster oder Desktop ausgewählt.',
			'scanner_snack_scanning_target' => 'Scanne "{title}"...',
			'scanner_snack_win_snipping_active' => 'Windows-Snipping aktiv (Win+Shift+S): Ziehe den Bereich über deinen Desktop/Emulator!',
			'scanner_snack_snippet_imported' => 'Desktop-Ausschnitt ({width}x{height} px) übernommen!',
			'scanner_snack_clipboard_imported' => 'Screenshot ({width}x{height} px) aus Zwischenablage übernommen!',
			'scanner_snack_clipboard_empty' => 'Kein Bild in der Windows-Zwischenablage. Nutze Win+Shift+S zum Ausschneiden.',
			'scanner_snack_marked_in_dex' => 'In "{dex}" eingetragen!',
			'scanner_alert_dialog_title' => 'Alarm- & Signal-Einstellungen',
			'scanner_alert_sound_title' => 'Akustische Signale (Töne)',
			'scanner_alert_sound_subtitle' => 'Spielt Signal-Töne bei Spielereignissen ab',
			'scanner_alert_sound_shiny' => '✨ Schillernde Pokémon (Shiny-Gong)',
			'scanner_alert_sound_alpha' => '🔴 Alpha- & Herrscher-Pokémon',
			'scanner_alert_sound_normal' => '⚪ Normale Fänge / Begegnungen',
			'scanner_alert_visual_glow' => 'Optischer Glow & Pulsieren bei Shiny',
			'scanner_close_btn' => 'Schließen',
			'scanner_settings_dialog_title' => 'Tracker-Einstellungen',
			'scanner_settings_region_title' => 'Scanbereich (Fensterbereich)',
			'scanner_settings_region_desc' => 'Wähle welcher Teil des Emulatorfensters per OCR abgetastet werden soll:',
			'scanner_settings_full_title' => 'Ganzes Fenster (Empfohlen für DS & Multi-Screen)',
			'scanner_settings_full_sub' => 'Scannt das gesamte Spielfenster (100%)',
			'scanner_settings_ds_top_title' => 'Oberer DS-Bildschirm (DS-Kämpfe & Dialoge)',
			'scanner_settings_ds_top_sub' => 'Scannt oberen Bildschirm (0-52%)',
			'scanner_settings_ds_bottom_title' => 'Unterer DS-Bildschirm (Touchscreen)',
			'scanner_settings_ds_bottom_sub' => 'Scannt unteren Bildschirm (48-100%)',
			'scanner_settings_dialogue_title' => 'Klassische Textbox (GBA / 3DS unten)',
			'scanner_settings_dialogue_sub' => 'Scannt Textbox am unteren Fensterrand (70-100%)',
			'scanner_settings_auto_mark_title' => 'Automatisch eintragen',
			'scanner_settings_auto_mark_sub' => 'Erkannte Fänge direkt ohne Klick im Ziel-Dex speichern',
			'scanner_settings_ocr_lang_title' => 'OCR-Sprache (Spieltext-Erkennung)',
			'scanner_correction_dialog_title' => 'Ereignis korrigieren',
			'scanner_correction_search_hint' => 'Alle Pokémon durchsuchen (Name oder #ID)...',
			'scanner_correction_top10_header' => 'TOP-10 OCR-TREFFER (NACH WAHRSCHEINLICHKEIT)',
			'scanner_correction_none_found' => 'Kein passendes Pokémon gefunden.',
			'scanner_correction_ignore_title' => 'Eigenes Team / Starter dauerhaft ignorieren?',
			'scanner_correction_ignore_desc' => 'Sperrt diese Art dauerhaft für künftige OCR-Fänge (z. B. deinen eigenen Starter im Kampfmenü).',
			'scanner_correction_ignore_btn' => '{name} dauerhaft ignorieren',
			'scanner_remove_btn' => 'Entfernen',
			'scanner_cancel_btn' => 'Abbrechen',
			'scanner_dex_modal_title' => 'Ziel-Pokédex auswählen',
			'scanner_dex_modal_search' => 'Pokédex durchsuchen...',
			'scanner_dex_modal_empty' => 'Kein passender Pokédex gefunden.',
			'scanner_dex_modal_active' => 'Aktiv ✔',
			'scanner_dex_modal_progress' => '{caught} von {total} gefangen • {region}',
			'scanner_snipping_custom_label' => 'Benutzerdefinierter Bereich',
			'scanner_snipping_desktop_hint' => 'Desktop-Snipping: Ziehe einen Bereich über den Bildschirm',
			'scanner_snipping_window_hint' => 'Snipping ({title}): Wähle oder ziehe einen Scan-Bereich',
			'scanner_snipping_default_hint' => 'Snipping-Modus: Ziehe ein Rechteck über den Lesebereich',
			'scanner_snipping_clipboard' => 'Zwischenablage',
			'scanner_snipping_ds_top_chip' => '🎮 DS Oben (Top-Screen 50%)',
			'scanner_snipping_ds_bottom_chip' => '🎮 DS Unten (Touch 50%)',
			'scanner_snipping_dialogue_chip' => '💬 Textbox unten (30%)',
			'scanner_snipping_desktop_focus' => '🖥️ Desktop-Fokus (Bildschirm 1)',
			'scanner_snipping_screen_region' => '🖥️ Bildschirm-Scanbereich',
			'scanner_snipping_instructions' => 'Klicke und ziehe mit der Maus über das Spielfenster,\noder nutze oben die DS Oben/Unten & Textbox Presets.',
			'scanner_snipping_confirm_scan' => 'Diesen Bereich scannen',
			'scanner_webcam_switch' => 'Wechseln',
			'scanner_webcam_done' => 'Fertig',
			'scanner_webcam_draw_zones' => 'Zonen zeichnen',
			'scanner_webcam_scan_photo' => 'Foto scannen',
			'scanner_webcam_initializing' => 'Webcam wird initialisiert...',
			'scanner_webcam_no_camera' => 'Keine aktive Webcam ausgewählt — nutze „Foto scannen“ oder schließe eine USB-Kamera an.',
			'scanner_webcam_reconnect' => 'Kamera neu verbinden',
			'scanner_pattern_missing_placeholder' => 'Vorlage muss {pokemon} als Platzhalter enthalten.',
			'scanner_pattern_duplicate' => 'Muster "{template}" ist bereits aktiv.',
			'scanner_pattern_images_label' => 'Bilder',
			'scanner_pattern_decode_failed' => 'Bild konnte nicht dekodiert werden.',
			'scanner_pattern_load_error' => 'Fehler beim Laden: {error}',
			'scanner_pattern_ocr_error' => 'OCR-Ausführung fehlgeschlagen: {error}',
			'scanner_pattern_title' => 'Eigene OCR-Muster & Scan-Studio',
			'scanner_pattern_subtitle' => 'Muster ohne Duplikate pflegen & gegen echten OCR-Text oder Fotos testen',
			'scanner_pattern_new_header' => 'NEUES MUSTER DEFINIEREN',
			'scanner_pattern_type_caught' => 'Gefangen',
			'scanner_pattern_type_encounter' => 'Begegnung',
			'scanner_pattern_type_evolved' => 'Entwicklung',
			'scanner_pattern_input_hint' => 'z. B. Klasse! {pokemon} * gefangen',
			'scanner_pattern_add_btn' => 'Hinzufügen',
			'scanner_pattern_tokens_label' => 'Bausteine:',
			'scanner_pattern_wildcard_chip' => '+ * (Platzhalter)',
			'scanner_pattern_quick_header' => 'Schnellvorlagen (werden automatisch dedupliziert):',
			'scanner_pattern_sandbox_header' => 'LIVE-SANDBOX TESTEN',
			'scanner_pattern_tab_text' => 'Text testen',
			'scanner_pattern_tab_photo' => 'Foto / Frame testen',
			'scanner_pattern_text_hint' => 'OCR-Zeile oder Log einfügen, z. B.:\nKlasse!\nZr-rrokex wrde aefar«t!',
			'scanner_pattern_active_header' => 'AKTIVE MUSTER ({count})',
			'scanner_pattern_empty' => 'Noch keine eigenen Muster definiert.',
			'scanner_pattern_sandbox_empty' => 'Gib oben eine OCR-Zeile ein, um Muster + Smart-Search live zu prüfen.',
			'scanner_pattern_sandbox_no_event' => 'Kein Ereignis erkannt (UI/Rauschen oder fehlendes Muster).',
			'scanner_pattern_sandbox_no_match' => 'Typ: {type} | Rohtext "{raw}" -> kein Pokédex-Treffer >= 72%',
			'scanner_pattern_load_photo' => 'Foto/Screenshot laden',
			'scanner_pattern_use_live_frame' => 'Aktuellen Live-Frame nutzen',
			'scanner_pattern_no_frame' => 'Noch kein Frame geladen. Lade ein Emulator-/Kamera-Bild zum Testen.',
			'scanner_pattern_loaded_frame' => 'Geladener Frame: {width}×{height} ({format})',
			'scanner_pattern_run_photo_ocr' => 'Foto mit OCR testen',
			'scanner_pattern_compare_profiles' => 'Alle 3 Profile vergleichen',
			'scanner_pattern_no_text' => '<kein Text erkannt>',
			'scanner_pattern_badge_caught' => 'GEFANGEN',
			'scanner_mob_no_target_dex' => 'Kein Ziel-Dex ausgewählt',
			'scanner_mob_switch' => 'Wechseln',
			'scanner_mob_dex_progress' => '{caught} / {total} gefangen ({pct}%)',
			'scanner_mob_no_focus_pokemon' => 'Noch kein Pokémon im Fokus. Richte die Kamera auf den Bildschirm oder importiere ein Foto.',
			'scanner_mob_missing' => 'Fehlt noch',
			'scanner_mob_mark_again' => 'Erneut markieren',
			'scanner_mob_mark_in_dex' => 'Im Dex eintragen',
			'scanner_mob_ignore_starter' => 'Starter ignorieren',
			'scanner_mob_ignored_starters' => 'Ignorierte Team-/Starter-Pokémon',
			'scanner_mob_scan_mode_header' => 'Scan-Modus & Haupt-Zonen (Instanz #1)',
			'scanner_mob_auto_fullscreen' => 'Auto (Vollbild)',
			'scanner_mob_draw_rects' => 'Vierecke zeichnen',
			'scanner_mob_drawing_active' => 'Zeichnen aktiv',
			'scanner_mob_rects_locked' => 'Rechtecke gesperrt',
			'scanner_mob_draw_zone_a' => 'Zone A zeichnen',
			'scanner_mob_redraw_zone_a' => 'Zone A neu',
			'scanner_mob_draw_zone_b' => 'Zone B zeichnen',
			'scanner_mob_redraw_zone_b' => 'Zone B neu',
			'scanner_mob_camera_photo_header' => 'Kamera & Foto-Import',
			'scanner_mob_active_camera' => 'Aktive Kamera',
			'scanner_mob_no_hw_camera' => 'Keine Hardware-Kamera gefunden',
			'scanner_mob_light_on' => 'Licht an',
			'scanner_mob_torch' => 'Taschenlampe',
			'scanner_mob_flip_camera' => 'Kamera drehen',
			'scanner_mob_ocr_automation_header' => 'OCR, Sprache & Automation',
			'scanner_mob_ocr_lang_label' => 'Spiel- & OCR-Sprache',
			'scanner_mob_scan_interval' => 'Scan-Intervall:',
			'scanner_mob_auto_save' => 'Fänge automatisch im Dex speichern',
			'scanner_mob_haptics_alerts' => 'Haptik & Shiny/Alpha-Alarme',
			'scanner_mob_custom_patterns' => 'Eigene Textmuster ({count})',
			'scanner_mob_rear_camera' => 'Rückkamera',
			'scanner_mob_front_camera' => 'Frontkamera',
			'scanner_mob_external_camera' => 'Externe Kamera',
			'scanner_mob_multi_header' => 'MULTI-INSTANZEN ({count})',
			'scanner_mob_instance_btn' => 'Instanz',
			'scanner_mob_multi_hint' => 'Lege zusätzliche Instanzen (#2, #3, …) an — jede mit eigener Zone A (Scan) und Zone B (Fokus), genau wie auf dem Desktop.',
			'scanner_mob_not_drawn' => 'Nicht gezeichnet',
			'scanner_mob_zone_b_focus' => 'Zone B · Fokus',
			'scanner_mob_zone_a_scan' => 'Zone A · Scan',
			'scanner_mob_delete_rect' => 'Rechteck löschen',
			'scanner_mob_events_header' => 'Erkannte Ereignisse',
			'scanner_mob_no_events' => 'Noch keine Fänge oder Begegnungen erkannt.',
			'scanner_mob_correct_tooltip' => 'Korrigieren',
			'scanner_mob_live_ocr_diagnose' => 'Live-OCR Diagnose ({count})',
			'scanner_mob_pause' => 'Pause',
			'scanner_mob_switch_camera' => 'Kamera wechseln',
			'scanner_mob_permission_title' => 'Kamerazugriff verweigert',
			'scanner_mob_permission_desc' => 'Bitte erlaube den Kamerazugriff in den Systemeinstellungen oder importiere stattdessen ein Foto.',
			'scanner_mob_retry' => 'Erneut versuchen',
			'scanner_mob_editing' => 'Bearbeiten',
			'scanner_mob_locked' => 'Gesperrt',
			'scanner_mob_drawer_header' => 'Fokus, Zonen & Feed ({count})',
			'scanner_mob_search_pokemon' => 'Pokémon suchen',
			'scanner_mob_starter_dialog_title' => 'Team- & Starter-Schutz',
			'scanner_mob_starter_dialog_desc' => 'Ignorierte Pokémon (z. B. dein eigenes Starter-Pokémon aus "Los, Pikachu!") werden bei Kampfeintritten übersprungen, bis du sie hier wieder entfernst.',
			'scanner_mob_fullscreen_tooltip' => 'Vollbild',
			'scanner_mob_splitscreen_tooltip' => 'Geteilte Ansicht',
			'scanner_mob_pip_tooltip' => 'Als Mini-Fenster (PiP)',
			'scanner_mob_tab_focus' => 'Fokus & Dex',
			'scanner_mob_tab_zones' => 'Zonen & Kamera',
			'scanner_mob_tab_feed' => 'Feed & Diagnose',
			'scanner_mob_pip_enlarge' => 'Kamera vergrößern',
			'scanner_mob_pip_scanning' => 'Scanne...',
			'scanner_mob_auto_mode' => 'AUTO-MODUS · {preset}',
			'shiny_auto_btn_tooltip' => 'Auto-Scanner konfigurieren',
			'shiny_auto_bar_active' => 'Auto-Counter aktiv',
			'shiny_auto_bar_paused' => 'Auto-Counter pausiert',
			'shiny_auto_undo' => 'Undo',
			'shiny_auto_setup_title' => 'Auto-Counter Setup',
			'shiny_auto_source_section' => 'Scan-Quelle',
			'shiny_auto_source_connected' => 'Scanner-Quelle aktiv',
			'shiny_auto_source_none' => 'Noch keine aktive Scan-Quelle verbunden.',
			'shiny_auto_open_desktop_scanner' => 'Fenster / Bildschirm / Webcam einrichten',
			'shiny_auto_open_mobile_scanner' => 'Kamera / PiP / Multi-Zonen einrichten',
			'shiny_auto_connect_active_source' => 'Mit aktiver Quelle starten',
			'shiny_auto_mode_section' => 'Erkennungsmethode & Reset-Logik',
			'shiny_auto_mode_wild' => 'Wild Encounter',
			'shiny_auto_mode_soft_reset' => 'Soft Reset',
			'shiny_auto_mode_egg' => 'Ei-Schlupf (Masuda)',
			'shiny_auto_mode_transition' => 'Overworld / Ladebildschirm',
			'shiny_auto_filter_section' => 'Welche Pokémon zählen?',
			'shiny_auto_filter_all' => 'Alle Pokémon',
			'shiny_auto_filter_target' => 'Nur Ziel-Pokémon',
			'shiny_auto_horde_toggle' => 'Doppel-/Horden-Anzahl (+N) übernehmen',
			'shiny_auto_black_reset_toggle' => 'Schwarzbild-Übergang als Reset werten',
			'shiny_auto_white_reset_toggle' => 'Weißbild-Übergang als Reset werten',
			'shiny_auto_custom_triggers' => 'Eigene Trigger-Muster',
			'shiny_auto_custom_resets' => 'Eigene Reset-Muster',
			'shiny_auto_custom_trigger_hint' => 'z. B. {pokemon} erscheint',
			'shiny_auto_custom_reset_hint' => 'z. B. Weiter oder Press Start',
			'shiny_auto_add_btn' => 'Hinzufügen',
			'shiny_auto_safety_section' => 'Safety & Benachrichtigungen',
			'shiny_auto_sound_count' => 'Ton bei Auto-Zählung',
			'shiny_auto_haptic_count' => 'Vibration bei Auto-Zählung',
			'shiny_auto_sound_shiny' => 'Alarm-Ton bei Shiny-Signal',
			'shiny_auto_haptic_shiny' => 'Vibration bei Shiny-Signal',
			'shiny_auto_pause_on_shiny' => 'Slot bei Shiny automatisch pausieren',
			'shiny_auto_start_btn' => 'Auto-Counter starten',
			'shiny_auto_save_btn' => 'Einstellungen übernehmen',
			'shiny_auto_shiny_alert_title' => 'SHINY-SIGNAL auf Slot #{slot}!',
			'shiny_auto_shiny_alert_resume' => 'Slot fortsetzen',
			'shiny_auto_slot_armed' => 'Bereit',
			'shiny_auto_slot_counted' => 'Gezählt',
			'shiny_auto_slot_rearm' => 'Reset...',
			'shiny_auto_slot_shiny' => 'Shiny!',
			'shiny_auto_slot_paused' => 'Pausiert',
			'shiny_auto_stop_tooltip' => 'Auto-Counter stoppen',
			'multi_hunt_dashboard_title' => 'Multi-Hunt Dashboard',
			'multi_hunt_dashboard_tooltip' => 'Multi-Hunt Dashboard öffnen',
			'multi_hunt_empty_title' => 'Keine aktiven oder pausierten Hunts',
			'multi_hunt_empty_desc' => 'Erstelle mindestens einen Shiny Hunt im Hub, um mehrere Spiele gleichzeitig zu tracken.',
			'multi_hunt_slot_assign_label' => 'Scan-Slots',
			'multi_hunt_assign_slot_none' => 'Kein Slot zugewiesen',
			'multi_hunt_open_counter' => 'Einzelansicht',
			'multi_hunt_logs_title' => 'Live Auto-Log ({count})',
			'multi_hunt_add_hunt' => 'Neuer Hunt',
			'multi_hunt_show_paused' => 'Pausierte ({count})',
			'multi_hunt_hide_paused' => 'Pausierte ausblenden',
			'multi_hunt_paused_section' => 'Pausierte Hunts ({count})',
			'multi_hunt_edit_rules_tooltip' => 'Auto-Regeln für diesen Hunt',
			'multi_hunt_edit_hunt_tooltip' => 'Hunt bearbeiten',
			'shiny_auto_setup_for_hunt' => 'Regeln für {name}',
			'shiny_auto_timing_section' => 'Erweitert / Timing-Feintuning',
			'shiny_auto_cooldown_label' => 'Reset-Cooldown (ms)',
			'shiny_auto_transition_duration_label' => 'Min. Schwarz-/Weißbild-Dauer (ms)',
			'shiny_auto_slot_chip_tooltip' => 'Tippen: Pause · Gedrückt halten: Manuell bereit (Re-Arm)',
			'shiny_auto_logs_tooltip' => 'Live Auto-Log anzeigen',
			'shiny_auto_logs_empty' => 'Noch keine automatischen Zählungen in dieser Sitzung.',
			'shiny_auto_logs_undone' => 'Rückgängig gemacht',
			'shiny_auto_rearm_all_btn' => 'Alle Slots bereit',
			'shiny_auto_reason_black_reset' => 'Schwarzbild-Reset',
			'shiny_auto_reason_white_reset' => 'Weißbild-Reset',
			'shiny_auto_reason_egg_oh' => 'Ei-Schlupf gestartet (Oh?)',
			'shiny_auto_reason_shiny' => 'Shiny erkannt: {name}',
			'multi_hunt_phase_status' => 'Phase {phase} · {status}',
			'multi_hunt_slot_number' => 'Slot #{slot}',
			'scanner_event_egg_hatched_badge' => 'EI-SCHLUPF',
			'shiny_auto_mode_desc_wild' => 'Zählt bei erkannten wilden Begegnungen (+1 oder Horden-Anzahl). Macht sich nach Kampfende (Flucht/Sieg), Fang oder Schwarzbild-Übergang automatisch wieder scharf.',
			'shiny_auto_mode_desc_soft_reset' => 'Ideal für Starter, Legendäre & Geschenke. Zählt bei Erkennung des Pokémon und macht sich nach Titelbildschirm („Weiter“/„Continue“), Schwarzbild oder eigenem Reset-Text wieder scharf.',
			'shiny_auto_mode_desc_egg' => 'Zählt Masuda-/Zucht-Eier über den Schlupftext („… ist aus dem Ei geschlüpft!“) — bei „Alle Pokémon“ auch schon direkt bei „Oh?“. Macht sich pro Ei automatisch wieder scharf.',
			'shiny_auto_mode_desc_transition' => 'Zählt ohne Texterkennung anhand gleichmäßiger Schwarz-/Weißbild-Ladeübergänge (z. B. Overworld-Resets in Legenden: Arceus). Respektiert den Reset-Cooldown.',
			'shiny_auto_filter_desc_all' => 'Jedes erkannte Pokémon löst +1 aus — ideal für Random Encounters und Shiny-Phasen.',
			'shiny_auto_filter_desc_target' => 'Zählt nur, wenn das Ziel-Pokémon dieses Hunts erkannt wird — verhindert Fehlzählungen bei Starter-Intros oder fremden Pokémon.',
			'shiny_auto_horde_desc' => 'Erhöht bei Massen- oder Doppelbegegnungen um die gesamte erkannte Gegneranzahl statt +1.',
			'shiny_auto_black_reset_desc' => 'Empfohlen für Soft-Resets & Ladebildschirme: Ein gleichmäßig schwarzer Übergang macht den Slot nach Ablauf des Cooldowns wieder scharf.',
			'shiny_auto_white_reset_desc' => 'Nur aktivieren, wenn dein Spiel komplett weiß überblendet. Bei Spielen mit weißen Dialogboxen ausgeschaltet lassen.',
			'shiny_auto_pause_on_shiny_desc' => 'Hält den betroffenen Scan-Slot sofort an, sobald ein Shiny-Signal erkannt wird, damit du den Treffer nicht versehentlich übergehst.',
			'shiny_auto_custom_triggers_desc' => 'Optional für ROM-Hacks oder Fangames: Eigene Texte, die zählen sollen. Nutze {pokemon} als Platzhalter für den Pokémon-Namen.',
			'shiny_auto_custom_resets_desc' => 'Optional: Eigene Menü- oder Titelbildschirm-Wörter, die einen bereits gezählten Slot wieder scharf machen.',
			'shiny_auto_cooldown_desc' => 'Mindestwartezeit nach einem Reset/Übergang, bevor derselbe Slot wieder zählen darf (verhindert Doppelzählungen).',
			'shiny_auto_transition_duration_desc' => 'Wie lange der Bildschirm mindestens schwarz/weiß bleiben muss, um als echter Übergang statt Flackern zu gelten.',
			'shiny_auto_black_threshold_label' => 'Schwarzbild-Schwelle (Luma {value})',
			'shiny_auto_white_threshold_label' => 'Weißbild-Schwelle (Luma {value})',
			'shiny_auto_thresholds_desc' => 'Tipp für Handykameras: Bei Restlicht im Raum die Schwarzbild-Schwelle höher (z. B. 35–50) und die Weißbild-Schwelle etwas niedriger stellen.',
			'shiny_auto_counting_for' => 'Zählt für: {name}',
			'shiny_auto_switch_hunt_btn' => 'Hierher wechseln',
			'shiny_auto_pending_banner' => 'Auto-Counter vorgemerkt – startet automatisch, sobald der Scanner läuft.',
			'shiny_auto_pending_cancel' => 'Abbrechen',
			'shiny_auto_help_tooltip' => 'Erklärung & Gesten anzeigen',
			'shiny_auto_help_title' => 'Auto-Counter Legende & Gesten',
			'shiny_auto_help_phases_desc' => '• Bereit: Slot wartet auf die nächste Begegnung.\n• Gezählt: Treffer gezählt, wartet auf Kampfende/Reset.\n• Reset…: Cooldown läuft vor dem erneuten Scharfschalten.\n• Shiny!: Shiny erkannt – Slot pausiert bis zur Freigabe.\n• Pausiert: Slot manuell angehalten.',
			'shiny_auto_help_gestures_desc' => 'Slot-Chips unten antippen = Slot pausieren/fortsetzen.\nSlot-Chip gedrückt halten = Slot sofort manuell wieder scharf machen (Re-Arm).',
			'multi_hunt_help_tooltip' => 'Multi-Hunt-Anleitung',
			'multi_hunt_help_title' => 'Multi-Hunt Dashboard – So funktioniert\'s',
			'multi_hunt_help_body' => '• Parallele Hunts: Verwalte mehrere Spiele gleichzeitig nebeneinander (+1 / -1 / Pause / Phase).\n• Eigene Auto-Regeln (🎛️): Jede Karte kann eigene Erkennungsregeln (z. B. Wild, Soft Reset, Ei-Schlupf) erhalten.\n• Scan-Slots (+ Scan-Slots): Weise erkannte Multi-Instance-Slots (#1, #2, …) gezielt bestimmten Hunts zu.\n• Pausierte Hunts: Über den Button oben bei Bedarf ein- und wieder ausblenden.',
			'tutorial_v17_tour_btn' => 'v1.7 Neuheiten-Tour starten',
			'tutorial_start_live_tour' => 'Live-Tour',
			'tutorial_v17_shiny_f4_title' => 'Multi-Hunt Dashboard & Auto-Counter',
			'tutorial_v17_shiny_f4_desc' => 'Parallele Hunts verwalten, eigene Erkennungsregeln setzen & automatisch per Scanner zählen!',
			'tutorial_v17_home_shiny_title' => 'Neu in v1.7: Multi-Hunt & Auto-Counter',
			'tutorial_v17_home_shiny_text' => 'Im Shiny Hunt Tracker warten jetzt das Multi-Hunt Dashboard und der visuelle Auto-Counter auf dich! Sobald du ihn öffnest, erkläre ich dir dort alles Schritt für Schritt.',
			'tutorial_shiny_dashboard_auto_title' => 'Multi-Hunt Dashboard & Auto-Counter',
			'tutorial_shiny_dashboard_auto_text' => 'Verwalte mehrere Hunts parallel im Multi-Hunt Dashboard und lass Begegnungen per visuellem Auto-Counter automatisch zählen!',
			'tutorial_shiny_hub_dashboard_title' => 'Neu: Multi-Hunt Dashboard',
			'tutorial_shiny_hub_dashboard_text' => 'Tippe hier auf das Raster-Icon, um das Multi-Hunt Dashboard zu öffnen – dort verwaltest du mehrere Hunts nebeneinander inklusive Auto-Counter!',
			'tutorial_shiny_counter_auto_title' => 'Neu: Visueller Auto-Counter',
			'tutorial_shiny_counter_auto_text' => 'Über dieses Fokus-Icon richtest du den visuellen Auto-Counter ein: Er erkennt Begegnungen, Resets und Ei-Schlüpfe automatisch über deinen Scanner und pausiert bei Shinys!',
			'tutorial_shiny_counter_dashboard_title' => 'Wechsel ins Multi-Hunt Dashboard',
			'tutorial_shiny_counter_dashboard_text' => 'Jagst du auf mehreren Spielen gleichzeitig? Tippe hier, um alle aktiven Hunts nebeneinander im Multi-Hunt Dashboard zu steuern.',
			'tutorial_chapter_shiny_auto_title' => '12. Multi-Hunt & Auto-Counter',
			'tutorial_chapter_shiny_auto_desc' => 'Parallele Hunts im Dashboard, Per-Hunt Auto-Regeln, Scan-Slots & Live-Steuerung.',
			'tutorial_auto_demo_dashboard_title' => 'Parallele Hunts im Dashboard',
			'tutorial_auto_demo_dashboard_text' => 'Steuere beliebig viele Shiny Hunts gleichzeitig auf einer responsiven Übersichtskarte pro Jagd.',
			'tutorial_auto_demo_cards_title' => 'Karten-Aktionen & Pausierte',
			'tutorial_auto_demo_cards_text' => 'Zähle direkt (+1 / -1), pausiere, trage Phasen ein, schließe Shinys ab oder blende pausierte Hunts ein.',
			'tutorial_auto_demo_rules_title' => 'Eigene Auto-Regeln pro Hunt',
			'tutorial_auto_demo_rules_text' => 'Lege pro Karte fest, ob Wild-Begegnungen, Soft Resets, Ei-Schlüpfe oder Bildwechsel gezählt werden.',
			'tutorial_auto_demo_slots_title' => 'Scan-Slots gezielt zuweisen',
			'tutorial_auto_demo_slots_text' => 'Verbinde Multi-Instance-Slots (#1, #2, …) aus dem Scanner flexibel mit einzelnen Hunt-Karten.',
			'tutorial_auto_demo_livebar_title' => 'Live-Leiste & Shiny-Schutz',
			'tutorial_auto_demo_livebar_text' => 'Mach Zähler per 1-Tipp rückgängig, sieh ins Live-Log und nutze die Shiny-Pause per OCR-Text/Symbol oder optionalen Beta-Heuristiken.',
			'tutorial_multi_hunt_intro_title' => 'Willkommen im Multi-Hunt Dashboard!',
			'tutorial_multi_hunt_intro_text' => 'Bzzzt! Hier steuerst du beliebig viele Shiny Hunts gleichzeitig nebeneinander – manuell oder vollautomatisch über deinen Scanner.',
			'tutorial_multi_hunt_appbar_title' => 'Neue Hunts & Pausierte filtern',
			'tutorial_multi_hunt_appbar_text' => 'Erstelle direkt neue Hunts über (+) oder blende pausierte Hunts oben bei Bedarf ein und wieder aus.',
			'tutorial_multi_hunt_setup_title' => 'Auto-Counter & Schnellhilfe',
			'tutorial_multi_hunt_setup_text' => 'Über das Fokus-Icon öffnest du das Auto-Counter-Setup. Das (?)-Symbol liefert dir jederzeit eine kompakte Übersicht.',
			'tutorial_multi_hunt_card_counter_title' => 'Direkt-Steuerung pro Hunt-Karte',
			'tutorial_multi_hunt_card_counter_text' => 'Jede Karte hat eigene + / - Tasten, Pause, Phase, Gefangen sowie einen Pfeil für die große Einzelansicht.',
			'tutorial_multi_hunt_card_rules_title' => 'Individuelle Auto-Regeln pro Hunt',
			'tutorial_multi_hunt_card_rules_text' => 'Über das Regler-Icon oder das Regel-Badge stellst du pro Hunt eigene Modi (Wild, Soft Reset, Ei-Schlupf) und Filter ein.',
			'tutorial_multi_hunt_card_slots_title' => 'Scan-Slots (#1, #2, …) zuweisen',
			'tutorial_multi_hunt_card_slots_text' => 'Ordne erkannte Multi-Instance-Slots aus deinem Desktop- oder Kamera-Scanner gezielt einzelnen Hunt-Karten zu!',
			'tutorial_auto_setup_source_title' => '1. Scan-Quelle verbinden',
			'tutorial_auto_setup_source_text' => 'Sieh sofort, ob bereits ein Desktop- oder Kamera-Scanner läuft. Falls nicht, merkt sich PokéVault dein Setup und startet beim Scanner-Start automatisch.',
			'tutorial_auto_setup_mode_title' => '2. Erkennungsmodus wählen',
			'tutorial_auto_setup_mode_text' => 'Wähle ein Preset passend zur Methode: Wilde Begegnung, Soft Reset, Ei-Schlupf oder Nur Bildwechsel.',
			'tutorial_auto_setup_filter_title' => '3. Trefferfilter & Bild-Resets',
			'tutorial_auto_setup_filter_text' => 'Zähle alle Pokémon oder nur dein Ziel, aktiviere Horden-Zählung und nutze Schwarz-/Weißbild-Übergänge zum erneuten Scharfschalten.',
			'tutorial_auto_setup_custom_title' => '4. Eigene Trigger- & Reset-Wörter',
			'tutorial_auto_setup_custom_text' => 'Für ROM-Hacks oder Fangames kannst du eigene OCR-Texte für Treffer und Titelbildschirm-Resets ergänzen.',
			'tutorial_auto_setup_timing_title' => '5. Timing & Helligkeitsschwellen',
			'tutorial_auto_setup_timing_text' => 'Passe Cooldown, Übergangsdauer und Schwarz-/Weiß-Luma-Schwellen fein an deine Kamera oder dein Spiel an.',
			'tutorial_auto_setup_safety_title' => '6. Shiny-Schutz & Starten',
			'tutorial_auto_setup_safety_text' => 'Aktiviere Sound/Haptik, den automatischen Shiny-Pause-Schutz und bei Bedarf die Beta-Shiny-Heuristiken – tippe dann unten auf Starten bzw. Speichern!',
			'tutorial_auto_bar_controls_title' => 'Live-Leiste: Steuerung & Rückgängig',
			'tutorial_auto_bar_controls_text' => 'Hier siehst du den Live-Status, machst Fehlzählungen mit einem Tipp rückgängig (↶), schaltest Slots per (↻) wieder scharf, prüfst das Log oder pausierst.',
			'tutorial_auto_bar_slots_title' => 'Slot-Chips & Gesten',
			'tutorial_auto_bar_slots_text' => 'Tippe einen farbigen Slot-Chip an zum Pausieren/Fortsetzen – oder halte ihn gedrückt (bzw. nutze das Re-Arm-Symbol), um den Slot sofort wieder scharf zu machen!',
			'tutorial_auto_bar_shiny_title' => 'Automatischer Shiny-Schutz',
			'tutorial_auto_bar_shiny_text' => 'Bzzzt! Sobald ein Shiny-Text/Symbol (oder eine aktivierte Beta-Heuristik) auslöst, pausiert der Slot sofort mit einem goldenen Alarm-Banner!',
			'shiny_auto_shiny_ocr_info' => 'Hinweis: Die Standard-OCR-Pause reagiert auf Texte/Symbole („Shiny“, „Schillernd“, ✨ – z. B. bei ROM-Hacks, Overlays oder Gen-9-HUD). Für offizielle Spiele kannst du zusätzlich die Beta-Heuristiken aktivieren.',
			'shiny_auto_sparkle_delay_toggle' => 'Sparkle-Delay-Erkennung (Beta)',
			'shiny_auto_sparkle_delay_desc' => 'Lernt die normale Zeit bis zum Kampfmenü (3 Begegnungen) und pausiert bei längerer Glitzer-Animation.',
			'shiny_auto_sparkle_delay_threshold_label' => 'Sparkle-Delay-Schwelle: +{ms} ms',
			'shiny_auto_color_dev_toggle' => 'Farb-Abweichung / HSV-Baseline (Beta)',
			'shiny_auto_color_dev_desc' => 'Vergleicht den Scan-Frame nach 3 normalen Encountern. Ideal bei ruhigem Emulator- oder Capture-Card-Bild.',
			'shiny_auto_color_dev_threshold_label' => 'Farb-Abweichungsschwelle: {pct}%',
			'shiny_auto_soft_reset_starter_hint' => 'Tipp für Starter/Geschenke: Wenn kein „Wildes Pokémon erscheint“-Text kommt, ergänze unten ein eigenes Trigger-Muster oder nutze den Bildwechsel-Modus.',
			'shiny_auto_rearm_all_tooltip' => 'Gezählte Slots neu scharfschalten (Re-Arm)',
			'shiny_auto_rearm_single_tooltip' => 'Slot #{slot} wieder scharf schalten',
			'shiny_auto_shiny_mark_caught' => 'Gefangen',
			'shiny_auto_source_ocr' => 'OCR',
			'shiny_auto_source_sparkle_delay' => 'Sparkle-Delay',
			'shiny_auto_source_color_dev' => 'Farb-Abweichung',
			'shiny_auto_reason_sparkle_delay' => 'Sparkle-Delay erkannt ({details})',
			'shiny_auto_reason_color_dev' => 'Farb-Abweichung erkannt ({details})',
			'tutorial_demo_shiny_auto_badge_title' => 'Multi-Hunt · Auto-Counter · Scan-Slots',
			'tutorial_demo_shiny_auto_badge_subtitle' => 'Parallele Hunts, Per-Hunt-Regeln & Shiny-Schutz',
			_ => null,
		};
	}
}
