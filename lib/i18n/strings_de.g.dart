///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsDe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <de>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$de common = _Translations$common$de._(_root);
	@override late final _Translations$home$de home = _Translations$home$de._(_root);
	@override late final _Translations$sentry$de sentry = _Translations$sentry$de._(_root);
	@override late final _Translations$settings$de settings = _Translations$settings$de._(_root);
	@override late final _Translations$logs$de logs = _Translations$logs$de._(_root);
	@override late final _Translations$login$de login = _Translations$login$de._(_root);
	@override late final _Translations$profile$de profile = _Translations$profile$de._(_root);
	@override late final _Translations$appInfo$de appInfo = _Translations$appInfo$de._(_root);
	@override late final _Translations$update$de update = _Translations$update$de._(_root);
	@override late final _Translations$editor$de editor = _Translations$editor$de._(_root);
}

// Path: common
class _Translations$common$de extends Translations$common$en {
	_Translations$common$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get done => 'Fertig';
	@override String get continueBtn => 'Weiter';
	@override String get cancel => 'Abbrechen';
}

// Path: home
class _Translations$home$de extends Translations$home$en {
	_Translations$home$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$de tabs = _Translations$home$tabs$de._(_root);
	@override late final _Translations$home$titles$de titles = _Translations$home$titles$de._(_root);
	@override late final _Translations$home$tooltips$de tooltips = _Translations$home$tooltips$de._(_root);
	@override late final _Translations$home$create$de create = _Translations$home$create$de._(_root);
	@override String get welcome => 'Willkommen bei BadNotes';
	@override String get invalidFormat => 'Die ausgewählte Datei wird nicht unterstützt. Bitte wähle eine sbn-, sbn2-, sba- oder PDF-Datei aus.';
	@override String get noFiles => 'Keine Dateien gefunden';
	@override String get noPreviewAvailable => 'Keine Vorschau verfügbar';
	@override String get createNewNote => 'Tippe auf +, um eine neue Notiz zu erstellen';
	@override String get backFolder => 'Zurück zum vorherigen Ordner';
	@override late final _Translations$home$newFolder$de newFolder = _Translations$home$newFolder$de._(_root);
	@override late final _Translations$home$renameNote$de renameNote = _Translations$home$renameNote$de._(_root);
	@override late final _Translations$home$moveNote$de moveNote = _Translations$home$moveNote$de._(_root);
	@override String get deleteNote => 'Notiz löschen';
	@override late final _Translations$home$deleteNoteDialog$de deleteNoteDialog = _Translations$home$deleteNoteDialog$de._(_root);
	@override late final _Translations$home$renameFolder$de renameFolder = _Translations$home$renameFolder$de._(_root);
	@override late final _Translations$home$deleteFolder$de deleteFolder = _Translations$home$deleteFolder$de._(_root);
	@override late final _Translations$home$sort$de sort = _Translations$home$sort$de._(_root);
	@override late final _Translations$home$layout$de layout = _Translations$home$layout$de._(_root);
}

// Path: sentry
class _Translations$sentry$de extends Translations$sentry$en {
	_Translations$sentry$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$de consent = _Translations$sentry$consent$de._(_root);
}

// Path: settings
class _Translations$settings$de extends Translations$settings$en {
	_Translations$settings$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$de prefCategories = _Translations$settings$prefCategories$de._(_root);
	@override late final _Translations$settings$prefLabels$de prefLabels = _Translations$settings$prefLabels$de._(_root);
	@override late final _Translations$settings$prefDescriptions$de prefDescriptions = _Translations$settings$prefDescriptions$de._(_root);
	@override late final _Translations$settings$themeModes$de themeModes = _Translations$settings$themeModes$de._(_root);
	@override late final _Translations$settings$layoutSizes$de layoutSizes = _Translations$settings$layoutSizes$de._(_root);
	@override late final _Translations$settings$accentColorPicker$de accentColorPicker = _Translations$settings$accentColorPicker$de._(_root);
	@override String get systemLanguage => 'Automatisch';
	@override List<String> get axisDirections => [
		'Oben',
		'Rechts',
		'Unten',
		'Links',
	];
	@override late final _Translations$settings$reset$de reset = _Translations$settings$reset$de._(_root);
	@override String get resyncEverything => 'Alles neu synchronisieren';
	@override String get openDataDir => 'BadNotes-Ordner öffnen';
	@override late final _Translations$settings$customDataDir$de customDataDir = _Translations$settings$customDataDir$de._(_root);
	@override String get autosaveDisabled => 'Nie';
	@override String get shapeRecognitionDisabled => 'Nie';
}

// Path: logs
class _Translations$logs$de extends Translations$logs$en {
	_Translations$logs$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get logs => 'Protokolle';
	@override String get viewLogs => 'Protokolle anzeigen';
	@override String get debuggingInfo => 'Protokolle enthalten nützliche Informationen für Fehlersuche und Entwicklung';
	@override String get noLogs => 'Keine Protokolle vorhanden!';
	@override String get useTheApp => 'Protokolle erscheinen hier, während du die App verwendest';
}

// Path: login
class _Translations$login$de extends Translations$login$en {
	_Translations$login$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Anmelden';
	@override late final _Translations$login$form$de form = _Translations$login$form$de._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: 'Noch kein Konto? '),
		linkToSignup('Jetzt registrieren'),
		const TextSpan(text: '!'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: 'Nicht du? '),
		undoLogin('Anderes Konto wählen'),
		const TextSpan(text: '.'),
	]);
	@override late final _Translations$login$status$de status = _Translations$login$status$de._(_root);
	@override late final _Translations$login$ncLoginStep$de ncLoginStep = _Translations$login$ncLoginStep$de._(_root);
	@override late final _Translations$login$encLoginStep$de encLoginStep = _Translations$login$encLoginStep$de._(_root);
}

// Path: profile
class _Translations$profile$de extends Translations$profile$en {
	_Translations$profile$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mein Profil';
	@override String get logout => 'Abmelden';
	@override String quotaUsage({required Object used, required Object total, required Object percent}) => 'Du nutzt ${used} von ${total} (${percent} %)';
	@override String quotaUsageUncapped({required Object used}) => 'Du nutzt ${used}';
	@override String get connectedTo => 'Verbunden mit';
	@override String lastSynced({required Object time}) => 'Zuletzt synchronisiert ${time}';
	@override String get notSyncedYet => 'Noch nicht synchronisiert';
	@override String get justNow => 'gerade eben';
	@override String minutesAgo({required Object n}) => 'vor ${n} Min.';
	@override String hoursAgo({required Object n}) => 'vor ${n} Std.';
	@override String filesWaiting({required Object n}) => '${n} Dateien warten auf Synchronisierung';
	@override String get signInAgainNeeded => 'Melde dich erneut an, um weiter zu synchronisieren';
	@override String get signInAgain => 'Erneut anmelden';
	@override String wrongAccount({required Object email}) => 'Bitte wähle ${email}';
	@override late final _Translations$profile$quickLinks$de quickLinks = _Translations$profile$quickLinks$de._(_root);
	@override String get faqTitle => 'Häufig gestellte Fragen';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$de._(_root),
		_Translations$profile$faq$1$de._(_root),
		_Translations$profile$faq$2$de._(_root),
		_Translations$profile$faq$3$de._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$de extends Translations$appInfo$en {
	_Translations$appInfo$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get debug => 'DEBUG';
}

// Path: update
class _Translations$update$de extends Translations$update$en {
	_Translations$update$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => 'Update verfügbar';
	@override String get updateAvailableDescription => 'Eine neue Version der App ist verfügbar:';
	@override String get update => 'Aktualisieren';
	@override String get downloadNotAvailableYet => 'Der Download ist für deine Plattform noch nicht verfügbar. Bitte schau in Kürze wieder vorbei.';
}

// Path: editor
class _Translations$editor$de extends Translations$editor$en {
	_Translations$editor$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$de toolbar = _Translations$editor$toolbar$de._(_root);
	@override late final _Translations$editor$pens$de pens = _Translations$editor$pens$de._(_root);
	@override late final _Translations$editor$penOptions$de penOptions = _Translations$editor$penOptions$de._(_root);
	@override late final _Translations$editor$colors$de colors = _Translations$editor$colors$de._(_root);
	@override late final _Translations$editor$imageOptions$de imageOptions = _Translations$editor$imageOptions$de._(_root);
	@override late final _Translations$editor$selectionBar$de selectionBar = _Translations$editor$selectionBar$de._(_root);
	@override late final _Translations$editor$menu$de menu = _Translations$editor$menu$de._(_root);
	@override late final _Translations$editor$photoPdfError$de photoPdfError = _Translations$editor$photoPdfError$de._(_root);
	@override late final _Translations$editor$readOnlyBanner$de readOnlyBanner = _Translations$editor$readOnlyBanner$de._(_root);
	@override late final _Translations$editor$versionTooNew$de versionTooNew = _Translations$editor$versionTooNew$de._(_root);
	@override late final _Translations$editor$quill$de quill = _Translations$editor$quill$de._(_root);
	@override late final _Translations$editor$hud$de hud = _Translations$editor$hud$de._(_root);
	@override String get pages => 'Seiten';
	@override String get untitled => 'Unbenannt';
	@override String get needsToSaveBeforeExiting => 'Änderungen werden gespeichert… Du kannst den Editor verlassen, sobald der Vorgang abgeschlossen ist';
}

// Path: home.tabs
class _Translations$home$tabs$de extends Translations$home$tabs$en {
	_Translations$home$tabs$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get home => 'Start';
	@override String get browse => 'Durchsuchen';
	@override String get whiteboard => 'Whiteboard';
	@override String get settings => 'Einstellungen';
}

// Path: home.titles
class _Translations$home$titles$de extends Translations$home$titles$en {
	_Translations$home$titles$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get home => 'Zuletzt verwendet';
	@override String get browse => 'Durchsuchen';
	@override String get whiteboard => 'Whiteboard';
	@override String get settings => 'Einstellungen';
}

// Path: home.tooltips
class _Translations$home$tooltips$de extends Translations$home$tooltips$en {
	_Translations$home$tooltips$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Neue Notiz';
	@override String get showUpdateDialog => 'Update-Dialog anzeigen';
	@override String get exportNote => 'Notiz exportieren';
}

// Path: home.create
class _Translations$home$create$de extends Translations$home$create$en {
	_Translations$home$create$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Neue Notiz';
	@override String get importNote => 'Notiz importieren';
}

// Path: home.newFolder
class _Translations$home$newFolder$de extends Translations$home$newFolder$en {
	_Translations$home$newFolder$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get newFolder => 'Neuer Ordner';
	@override String get folderName => 'Ordnername';
	@override String get create => 'Erstellen';
	@override String get folderNameEmpty => 'Der Ordnername darf nicht leer sein';
	@override String get folderNameContainsSlash => 'Der Ordnername darf keinen Schrägstrich enthalten';
	@override String get folderNameExists => 'Ordner existiert bereits';
}

// Path: home.renameNote
class _Translations$home$renameNote$de extends Translations$home$renameNote$en {
	_Translations$home$renameNote$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get renameNote => 'Notiz umbenennen';
	@override String get noteName => 'Notizname';
	@override String get rename => 'Umbenennen';
	@override String get noteNameEmpty => 'Der Notizname darf nicht leer sein';
	@override String get noteNameExists => 'Eine Notiz mit diesem Namen existiert bereits';
	@override String get noteNameForbiddenCharacters => 'Der Notizname enthält unzulässige Zeichen';
	@override String get noteNameReserved => 'Dieser Notizname ist reserviert';
}

// Path: home.moveNote
class _Translations$home$moveNote$de extends Translations$home$moveNote$en {
	_Translations$home$moveNote$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get moveNote => 'Notiz verschieben';
	@override String moveNotes({required Object n}) => '${n} Notizen verschieben';
	@override String moveName({required Object f}) => '${f} verschieben';
	@override String get move => 'Verschieben';
	@override String renamedTo({required Object newName}) => 'Die Notiz wird in ${newName} umbenannt';
	@override String get multipleRenamedTo => 'Folgende Notizen werden umbenannt:';
	@override String numberRenamedTo({required Object n}) => '${n} Notizen werden umbenannt, um Konflikte zu vermeiden';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$de extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => '${n} Notizen löschen';
	@override String deleteName({required Object f}) => '${f} löschen';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Ausgewählte Notiz endgültig löschen?',
		other: 'Ausgewählte Notizen endgültig löschen?',
	);
	@override String get delete => 'Löschen';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$de extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => 'Ordner umbenennen';
	@override String get folderName => 'Ordnername';
	@override String get rename => 'Umbenennen';
	@override String get folderNameEmpty => 'Der Ordnername darf nicht leer sein';
	@override String get folderNameContainsSlash => 'Der Ordnername darf keinen Schrägstrich enthalten';
	@override String get folderNameExists => 'Ein Ordner mit diesem Namen existiert bereits';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$de extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => 'Ordner löschen';
	@override String deleteName({required Object f}) => '${f} löschen';
	@override String get delete => 'Löschen';
	@override String get alsoDeleteContents => 'Auch alle Notizen in diesem Ordner löschen';
}

// Path: home.sort
class _Translations$home$sort$de extends Translations$home$sort$en {
	_Translations$home$sort$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get sortBy => 'Sortieren nach';
	@override String get nameAToZ => 'Name (A–Z)';
	@override String get nameZToA => 'Name (Z–A)';
	@override String get lastModifiedNewToOld => 'Bearbeitet (neueste zuerst)';
	@override String get lastModifiedOldToNew => 'Bearbeitet (älteste zuerst)';
}

// Path: home.layout
class _Translations$home$layout$de extends Translations$home$layout$en {
	_Translations$home$layout$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get layout => 'Layout';
	@override String get masonryGrid => 'Mauerwerk-Raster';
	@override String get simpleGrid => 'Einfaches Raster';
}

// Path: sentry.consent
class _Translations$sentry$consent$de extends Translations$sentry$consent$en {
	_Translations$sentry$consent$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'BadNotes verbessern?';
	@override late final _Translations$sentry$consent$description$de description = _Translations$sentry$consent$description$de._(_root);
	@override late final _Translations$sentry$consent$answers$de answers = _Translations$sentry$consent$answers$de._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$de extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get general => 'Allgemein';
	@override String get writing => 'Schreiben';
	@override String get editor => 'Editor';
	@override String get performance => 'Leistung';
	@override String get advanced => 'Erweitert';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$de extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get locale => 'Sprache';
	@override String get appTheme => 'App-Design';
	@override String get platform => 'Designstil';
	@override String get layoutSize => 'Layouttyp';
	@override String get customAccentColor => 'Eigene Akzentfarbe';
	@override String get hyperlegibleFont => 'Schriftart Atkinson Hyperlegible';
	@override String get shouldCheckForUpdates => 'Nach BadNotes-Updates suchen';
	@override String get shouldAlwaysAlertForUpdates => 'Schnellere Updates';
	@override String get allowInsecureConnections => 'Unsichere Verbindungen zulassen';
	@override String get syncOnlyOnWifi => 'Nur über WLAN synchronisieren';
	@override String get syncPreviewsOnMobileData => 'Vorschaubilder über mobile Daten hochladen';
	@override String get editorToolbarAlignment => 'Position der Werkzeugleiste';
	@override String get editorToolbarShowInFullscreen => 'Werkzeugleiste im Vollbildmodus anzeigen';
	@override String get editorAutoInvert => 'Notizen im dunklen Modus invertieren';
	@override String get preferGreyscale => 'Graustufen bevorzugen';
	@override String get maxImageSize => 'Maximale Bildgröße';
	@override String get autoClearWhiteboardOnExit => 'Whiteboard automatisch leeren';
	@override String get disableEraserAfterUse => 'Radierer automatisch deaktivieren';
	@override String get hideFingerDrawingToggle => 'Schalter für Fingerzeichnen ausblenden';
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Fingerzeichnen automatisch deaktivieren';
	@override String get editorPromptRename => 'Neue Notizen umbenennen lassen';
	@override String get recentColorsDontSavePresets => 'Vordefinierte Farben nicht in den letzten Farben speichern';
	@override String get recentColorsLength => 'Anzahl der gespeicherten letzten Farben';
	@override String get printPageIndicators => 'Seitenzahlen drucken';
	@override String get autosave => 'Automatisch speichern';
	@override String get shapeRecognitionDelay => 'Verzögerung der Formerkennung';
	@override String get autoStraightenLines => 'Linien automatisch begradigen';
	@override String get customDataDir => 'Eigener BadNotes-Ordner';
	@override String get sentry => 'Fehlerberichte';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$de extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => 'Aus: Notizen werden auch über mobile Daten synchronisiert. An: Die Synchronisierung wartet auf WLAN';
	@override String get syncPreviewsOnMobileData => 'Vorschaubilder warten normalerweise auf WLAN, um Daten zu sparen';
	@override String get hyperlegibleFont => 'Verbessert die Lesbarkeit bei eingeschränktem Sehvermögen';
	@override String get allowInsecureConnections => '(Nicht empfohlen) BadNotes erlauben, sich mit Servern mit selbstsignierten/nicht vertrauenswürdigen Zertifikaten zu verbinden';
	@override String get preferGreyscale => 'Für E-Ink-Displays';
	@override String get autoClearWhiteboardOnExit => 'Leert das Whiteboard, wenn du die App verlässt';
	@override String get disableEraserAfterUse => 'Wechselt nach dem Radieren automatisch zurück zum Stift';
	@override String get maxImageSize => 'Größere Bilder werden komprimiert';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$de hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$de._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Fingerzeichnen ausschalten, wenn ein Stift erkannt wird';
	@override String get editorPromptRename => 'Du kannst Notizen jederzeit später umbenennen';
	@override String get printPageIndicators => 'Seitenzahlen in Exporten anzeigen';
	@override String get autosave => 'Nach kurzer Verzögerung automatisch speichern oder nie';
	@override String get shapeRecognitionDelay => 'Wie lange der Stift still gehalten werden muss, bis die Tinte zu einer Form wird';
	@override String get autoStraightenLines => 'Begradigt lange Linien, ohne den Formenstift zu verwenden';
	@override String get shouldAlwaysAlertForUpdates => 'Über Updates informieren, sobald sie verfügbar sind';
	@override late final _Translations$settings$prefDescriptions$sentry$de sentry = _Translations$settings$prefDescriptions$sentry$de._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$de extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get system => 'System';
	@override String get light => 'Hell';
	@override String get dark => 'Dunkel';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$de extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get auto => 'Automatisch';
	@override String get phone => 'Smartphone';
	@override String get tablet => 'Tablet';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$de extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => 'Farbe auswählen';
}

// Path: settings.reset
class _Translations$settings$reset$de extends Translations$settings$reset$en {
	_Translations$settings$reset$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diese Einstellung zurücksetzen?';
	@override String get button => 'Zurücksetzen';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$de extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Abbrechen';
	@override String get select => 'Auswählen';
	@override String get mustBeEmpty => 'Der ausgewählte Ordner muss leer sein';
	@override String get mustBeDoneSyncing => 'Stelle sicher, dass die Synchronisierung abgeschlossen ist, bevor du den Ordner änderst';
	@override String get unsupported => 'Diese Funktion ist derzeit nur für Entwickler gedacht. Ihre Verwendung führt wahrscheinlich zu Datenverlust.';
}

// Path: login.form
class _Translations$login$form$de extends Translations$login$form$en {
	_Translations$login$form$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'Mit der Anmeldung stimmst du der '),
		linkToPrivacyPolicy('Datenschutzerklärung'),
		const TextSpan(text: ' zu.'),
	]);
}

// Path: login.status
class _Translations$login$status$de extends Translations$login$status$en {
	_Translations$login$status$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => 'Abgemeldet';
	@override String get tapToLogin => 'Tippen, um mit Google Drive zu synchronisieren';
	@override String hi({required Object u}) => 'Hallo, ${u}!';
	@override String get almostDone => 'Fast bereit zum Synchronisieren – tippe, um die Anmeldung abzuschließen';
	@override String get loggedIn => 'Synchronisierung ist aktiv';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$de extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => 'Wähle, wo deine Daten gespeichert werden sollen:';
	@override String get cloudStorage => 'Google Drive oder OneDrive';
	@override String get loginWithGoogleDrive => 'Weiter mit Google Drive';
	@override String get loginWithOneDrive => 'Weiter mit OneDrive';
	@override String get cloudLoginFailed => 'Anmeldung fehlgeschlagen';
	@override String get comingSoon => 'Demnächst verfügbar';
	@override String get badnotesNcServer => 'Nextcloud-Server von BadNotes';
	@override String get otherNcServer => 'Anderer Nextcloud-Server';
	@override String get serverUrl => 'Server-URL';
	@override String get loginWithBadNotes => 'Mit BadNotes anmelden';
	@override String get loginWithNextcloud => 'Mit Nextcloud anmelden';
	@override late final _Translations$login$ncLoginStep$loginFlow$de loginFlow = _Translations$login$ncLoginStep$loginFlow$de._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$de extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => 'Gib zum Schutz deiner Daten bitte dein Verschlüsselungspasswort ein:';
	@override String get newToBadNotes => 'Neu bei BadNotes? Gib einfach ein neues Verschlüsselungspasswort ein.';
	@override String get encPassword => 'Verschlüsselungspasswort';
	@override String get encFaqTitle => 'Häufig gestellte Fragen';
	@override String get wrongEncPassword => 'Entschlüsselung mit diesem Passwort fehlgeschlagen. Bitte versuche es erneut.';
	@override String get connectionFailed => 'Bei der Verbindung zum Server ist ein Fehler aufgetreten. Bitte versuche es später erneut.';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$de._(_root),
		_Translations$login$encLoginStep$encFaq$1$de._(_root),
		_Translations$login$encLoginStep$encFaq$2$de._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$de extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => 'Server-Startseite';
	@override String get deleteAccount => 'Konto löschen';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$de extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get q => 'Verliere ich meine Notizen, wenn ich mich abmelde?';
	@override String get a => 'Nein. Deine Notizen bleiben sowohl auf deinem Gerät als auch auf dem Server. Sie werden erst wieder mit dem Server synchronisiert, wenn du dich erneut anmeldest. Stelle vor dem Abmelden sicher, dass die Synchronisierung abgeschlossen ist, damit keine Daten verloren gehen (siehe Synchronisierungsfortschritt auf dem Startbildschirm).';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$de extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get q => 'Wo werden meine Notizen gespeichert?';
	@override String get a => 'In einem Ordner „BadNotes“ in deinem Google Drive oder „Apps/BadNotes“ in deinem OneDrive. Die Dateien sind verschlüsselt und lassen sich nur in BadNotes öffnen.';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$de extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get q => 'Wie ändere ich mein Verschlüsselungspasswort?';
	@override String get a => '0. Stelle sicher, dass die Synchronisierung abgeschlossen ist (siehe Synchronisierungsfortschritt auf dem Startbildschirm).\n1. Melde dich von BadNotes ab.\n2. Lösche den Ordner „BadNotes“ in deinem Google Drive oder OneDrive. Dadurch werden alle deine Notizen aus der Cloud gelöscht, nicht von deinem Gerät.\n3. Melde dich wieder bei BadNotes an. Bei der Anmeldung kannst du ein neues Verschlüsselungspasswort wählen.\n4. Vergiss nicht, dich auch auf deinen anderen Geräten bei BadNotes ab- und wieder anzumelden.';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$de extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get q => 'Wie kann ich mein Konto löschen?';
	@override String get a => 'BadNotes hat kein eigenes Konto. Melde dich ab und lösche dann den Ordner „BadNotes“ in deinem Google Drive oder OneDrive.\nUm BadNotes auch den Zugriff zu entziehen, besuche myaccount.google.com/permissions (Google) oder account.live.com/consent/Manage (Microsoft).';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$de extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => 'Farben ein/aus (Ctrl C)';
	@override String get select => 'Auswählen';
	@override String get toggleEraser => 'Radierer ein/aus (Ctrl E)';
	@override String get photo => 'Bilder';
	@override String get text => 'Text';
	@override String get toggleFingerDrawing => 'Fingerzeichnen ein/aus (Ctrl F)';
	@override String get undo => 'Rückgängig';
	@override String get redo => 'Wiederholen';
	@override String get export => 'Exportieren (Ctrl Shift S)';
	@override String get exportAs => 'Exportieren als:';
	@override String get fullscreen => 'Vollbild ein/aus (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$de extends Translations$editor$pens$en {
	_Translations$editor$pens$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => 'Füller';
	@override String get ballpointPen => 'Kugelschreiber';
	@override String get highlighter => 'Textmarker';
	@override String get pencil => 'Bleistift';
	@override String get shapePen => 'Formenstift';
	@override String get laserPointer => 'Laserpointer';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$de extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get size => 'Größe';
}

// Path: editor.colors
class _Translations$editor$colors$de extends Translations$editor$colors$en {
	_Translations$editor$colors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => 'Farbauswahl';
	@override String customBrightnessHue({required Object b, required Object h}) => 'Eigenes ${b} ${h}';
	@override String customHue({required Object h}) => 'Eigenes ${h}';
	@override String get dark => 'dunkel';
	@override String get light => 'hell';
	@override String get black => 'Schwarz';
	@override String get darkGrey => 'Dunkelgrau';
	@override String get grey => 'Grau';
	@override String get lightGrey => 'Hellgrau';
	@override String get white => 'Weiß';
	@override String get red => 'Rot';
	@override String get green => 'Grün';
	@override String get cyan => 'Cyan';
	@override String get blue => 'Blau';
	@override String get yellow => 'Gelb';
	@override String get purple => 'Lila';
	@override String get pink => 'Pink';
	@override String get orange => 'Orange';
	@override String get pastelRed => 'Pastellrot';
	@override String get pastelOrange => 'Pastellorange';
	@override String get pastelYellow => 'Pastellgelb';
	@override String get pastelGreen => 'Pastellgrün';
	@override String get pastelCyan => 'Pastellcyan';
	@override String get pastelBlue => 'Pastellblau';
	@override String get pastelPurple => 'Pastelllila';
	@override String get pastelPink => 'Pastellpink';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$de extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bildoptionen';
	@override String get invertible => 'Invertierbar';
	@override String get download => 'Herunterladen';
	@override String get setAsBackground => 'Als Hintergrund festlegen';
	@override String get removeAsBackground => 'Als Hintergrund entfernen';
	@override String get delete => 'Löschen';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$de extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Löschen';
	@override String get duplicate => 'Duplizieren';
}

// Path: editor.menu
class _Translations$editor$menu$de extends Translations$editor$menu$en {
	_Translations$editor$menu$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => 'Seite ${page}/${totalPages} leeren';
	@override String get clearAllPages => 'Alle Seiten leeren';
	@override String get insertPage => 'Seite darunter einfügen';
	@override String get duplicatePage => 'Seite duplizieren';
	@override String get deletePage => 'Seite löschen';
	@override String get lineHeight => 'Zeilenhöhe';
	@override String get lineHeightDescription => 'Steuert auch die Textgröße bei getippten Notizen';
	@override String get lineThickness => 'Linienstärke';
	@override String get lineThicknessDescription => 'Stärke der Hintergrundlinien';
	@override String get backgroundImageFit => 'Hintergrundbild anpassen';
	@override String get backgroundPattern => 'Hintergrundmuster';
	@override String get import => 'Importieren';
	@override String get watchServer => 'Auf Updates vom Server achten';
	@override String get watchServerReadOnly => 'Bearbeiten ist deaktiviert, während der Server beobachtet wird';
	@override late final _Translations$editor$menu$boxFits$de boxFits = _Translations$editor$menu$boxFits$de._(_root);
	@override late final _Translations$editor$menu$bgPatterns$de bgPatterns = _Translations$editor$menu$bgPatterns$de._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$de extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fehler';
	@override String get message => 'PDF-Dateien können nicht als Bild hinzugefügt werden. Verwende dafür "${_root.editor.menu.import} > PDF".';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$de extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Schreibgeschützter Modus';
	@override String get watchingServer => 'Du beobachtest gerade Updates vom Server. In diesem Modus ist Bearbeiten deaktiviert.';
	@override String get corrupted => 'Notiz konnte nicht geladen werden. Sie ist möglicherweise beschädigt oder wird noch heruntergeladen.';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$de extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diese Notiz wurde mit einer neueren Version von BadNotes bearbeitet';
	@override String get subtitle => 'Beim Bearbeiten dieser Notiz können Informationen verloren gehen. Möchtest du das ignorieren und sie trotzdem bearbeiten?';
	@override String get allowEditing => 'Bearbeiten erlauben';
}

// Path: editor.quill
class _Translations$editor$quill$de extends Translations$editor$quill$en {
	_Translations$editor$quill$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => 'Hier etwas eingeben…';
}

// Path: editor.hud
class _Translations$editor$hud$de extends Translations$editor$hud$en {
	_Translations$editor$hud$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => 'Zoom entsperren';
	@override String get lockZoom => 'Zoom sperren';
	@override String get unlockSingleFingerPan => 'Verschieben mit einem Finger aktivieren';
	@override String get lockSingleFingerPan => 'Verschieben mit einem Finger deaktivieren';
	@override String get unlockAxisAlignedPan => 'Verschieben nur horizontal oder vertikal aufheben';
	@override String get lockAxisAlignedPan => 'Verschieben nur horizontal oder vertikal';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$de extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get question => 'Möchtest du unerwartete Fehler automatisch melden? So kann ich Probleme schneller finden und beheben.';
	@override String get scope => 'Die Berichte können Informationen über den Fehler und dein Gerät enthalten. Ich habe mich bemüht, persönliche Daten herauszufiltern, aber einige könnten trotzdem enthalten sein.';
	@override String get currentlyOff => 'Wenn du zustimmst, wird die Fehlerberichterstattung nach einem Neustart der App aktiviert.';
	@override String get currentlyOn => 'Wenn du deine Zustimmung widerrufst, starte die App bitte neu, um die Fehlerberichterstattung zu deaktivieren.';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: 'Mehr dazu in der '),
		link('Datenschutzerklärung'),
		const TextSpan(text: '.'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$de extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Ja';
	@override String get no => 'Nein';
	@override String get later => 'Später fragen';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$de extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get shown => 'Verhindert versehentliches Umschalten';
	@override String get fixedOn => 'Fingerzeichnen ist dauerhaft aktiviert';
	@override String get fixedOff => 'Fingerzeichnen ist dauerhaft deaktiviert';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$de extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get active => 'Aktiv';
	@override String get inactive => 'Inaktiv';
	@override String get activeUntilRestart => 'Aktiv bis zum Neustart der App';
	@override String get inactiveUntilRestart => 'Inaktiv bis zum Neustart der App';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$de extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => 'Bitte erlaube BadNotes den Zugriff auf dein Nextcloud-Konto';
	@override String get followPrompts => 'Bitte folge den Anweisungen in der Nextcloud-Oberfläche';
	@override String get browserDidntOpen => 'Anmeldeseite nicht geöffnet? Hier klicken';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$de extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get q => 'Was ist ein Verschlüsselungspasswort? Warum zwei Passwörter?';
	@override String get a => 'Dein Google- oder Microsoft-Konto dient dem Zugriff auf die Cloud. Das Verschlüsselungspasswort „verschlüsselt“ deine Daten, bevor sie überhaupt in die Cloud gelangen.\nSelbst wenn jemand Zugriff auf dein Google- oder Microsoft-Konto erhält, bleiben deine Notizen sicher und mit einem separaten Passwort verschlüsselt. So hast du eine zweite Sicherheitsebene für deine Daten.\nOhne dein Verschlüsselungspasswort kann niemand auf deine Notizen auf dem Server zugreifen. Das bedeutet aber auch: Wenn du dein Verschlüsselungspasswort vergisst, verlierst du den Zugriff auf deine Daten.';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$de extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get q => 'Ich habe noch kein Verschlüsselungspasswort festgelegt. Woher bekomme ich es?';
	@override String get a => 'Wähle ein neues Verschlüsselungspasswort und gib es oben ein.\nBadNotes erzeugt deine Verschlüsselungsschlüssel automatisch aus diesem Passwort.';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$de extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get q => 'Kann ich dasselbe Passwort wie für mein Google- oder Microsoft-Konto verwenden?';
	@override String get a => 'Bitte nicht. Ein separates Verschlüsselungspasswort schützt deine Notizen auch dann, wenn jemand in dieses Konto eindringt.';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$de extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get fill => 'Strecken';
	@override String get cover => 'Füllen';
	@override String get contain => 'Einpassen';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$de extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get none => 'Leer';
	@override String get college => 'Liniert (College)';
	@override String get collegeRtl => 'Liniert (College, umgekehrt)';
	@override String get lined => 'Liniert';
	@override String get grid => 'Kariert';
	@override String get dots => 'Gepunktet';
	@override String get staffs => 'Notenlinien';
	@override String get tablature => 'Tabulatur';
	@override String get cornell => 'Cornell';
}
