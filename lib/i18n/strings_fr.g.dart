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
class TranslationsFr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <fr>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$fr common = _Translations$common$fr._(_root);
	@override late final _Translations$home$fr home = _Translations$home$fr._(_root);
	@override late final _Translations$sentry$fr sentry = _Translations$sentry$fr._(_root);
	@override late final _Translations$settings$fr settings = _Translations$settings$fr._(_root);
	@override late final _Translations$logs$fr logs = _Translations$logs$fr._(_root);
	@override late final _Translations$login$fr login = _Translations$login$fr._(_root);
	@override late final _Translations$profile$fr profile = _Translations$profile$fr._(_root);
	@override late final _Translations$appInfo$fr appInfo = _Translations$appInfo$fr._(_root);
	@override late final _Translations$update$fr update = _Translations$update$fr._(_root);
	@override late final _Translations$editor$fr editor = _Translations$editor$fr._(_root);
}

// Path: common
class _Translations$common$fr extends Translations$common$en {
	_Translations$common$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get done => 'OK';
	@override String get continueBtn => 'Continuer';
	@override String get cancel => 'Annuler';
}

// Path: home
class _Translations$home$fr extends Translations$home$en {
	_Translations$home$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$fr tabs = _Translations$home$tabs$fr._(_root);
	@override late final _Translations$home$titles$fr titles = _Translations$home$titles$fr._(_root);
	@override late final _Translations$home$tooltips$fr tooltips = _Translations$home$tooltips$fr._(_root);
	@override late final _Translations$home$create$fr create = _Translations$home$create$fr._(_root);
	@override String get welcome => 'Bienvenue dans BadNotes';
	@override String get invalidFormat => 'Ce type de fichier n\'est pas pris en charge. Choisissez un fichier sbn, sbn2, sba ou pdf.';
	@override String get noFiles => 'Aucun fichier';
	@override String get noPreviewAvailable => 'Aucun aperçu disponible';
	@override String get createNewNote => 'Appuyez sur + pour créer une note';
	@override String get backFolder => 'Revenir au dossier précédent';
	@override late final _Translations$home$newFolder$fr newFolder = _Translations$home$newFolder$fr._(_root);
	@override late final _Translations$home$renameNote$fr renameNote = _Translations$home$renameNote$fr._(_root);
	@override late final _Translations$home$moveNote$fr moveNote = _Translations$home$moveNote$fr._(_root);
	@override String get deleteNote => 'Supprimer la note';
	@override late final _Translations$home$deleteNoteDialog$fr deleteNoteDialog = _Translations$home$deleteNoteDialog$fr._(_root);
	@override late final _Translations$home$renameFolder$fr renameFolder = _Translations$home$renameFolder$fr._(_root);
	@override late final _Translations$home$deleteFolder$fr deleteFolder = _Translations$home$deleteFolder$fr._(_root);
	@override late final _Translations$home$sort$fr sort = _Translations$home$sort$fr._(_root);
	@override late final _Translations$home$layout$fr layout = _Translations$home$layout$fr._(_root);
}

// Path: sentry
class _Translations$sentry$fr extends Translations$sentry$en {
	_Translations$sentry$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$fr consent = _Translations$sentry$consent$fr._(_root);
}

// Path: settings
class _Translations$settings$fr extends Translations$settings$en {
	_Translations$settings$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$fr prefCategories = _Translations$settings$prefCategories$fr._(_root);
	@override late final _Translations$settings$prefLabels$fr prefLabels = _Translations$settings$prefLabels$fr._(_root);
	@override late final _Translations$settings$prefDescriptions$fr prefDescriptions = _Translations$settings$prefDescriptions$fr._(_root);
	@override late final _Translations$settings$themeModes$fr themeModes = _Translations$settings$themeModes$fr._(_root);
	@override late final _Translations$settings$layoutSizes$fr layoutSizes = _Translations$settings$layoutSizes$fr._(_root);
	@override late final _Translations$settings$accentColorPicker$fr accentColorPicker = _Translations$settings$accentColorPicker$fr._(_root);
	@override String get systemLanguage => 'Auto';
	@override List<String> get axisDirections => [
		'Haut',
		'Droite',
		'Bas',
		'Gauche',
	];
	@override late final _Translations$settings$reset$fr reset = _Translations$settings$reset$fr._(_root);
	@override String get resyncEverything => 'Tout resynchroniser';
	@override String get openDataDir => 'Ouvrir le dossier BadNotes';
	@override late final _Translations$settings$customDataDir$fr customDataDir = _Translations$settings$customDataDir$fr._(_root);
	@override String get autosaveDisabled => 'Jamais';
	@override String get shapeRecognitionDisabled => 'Jamais';
}

// Path: logs
class _Translations$logs$fr extends Translations$logs$en {
	_Translations$logs$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get logs => 'Journaux';
	@override String get viewLogs => 'Voir les journaux';
	@override String get debuggingInfo => 'Les journaux contiennent des informations utiles au débogage et au développement';
	@override String get noLogs => 'Aucun journal ici !';
	@override String get useTheApp => 'Les journaux apparaîtront ici à mesure que vous utilisez l\'application';
}

// Path: login
class _Translations$login$fr extends Translations$login$en {
	_Translations$login$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Connexion';
	@override late final _Translations$login$form$fr form = _Translations$login$form$fr._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: 'Pas encore de compte ? '),
		linkToSignup('Inscrivez-vous'),
		const TextSpan(text: ' !'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: 'Ce n\'est pas vous ? '),
		undoLogin('Choisir un autre compte'),
		const TextSpan(text: '.'),
	]);
	@override late final _Translations$login$status$fr status = _Translations$login$status$fr._(_root);
	@override late final _Translations$login$ncLoginStep$fr ncLoginStep = _Translations$login$ncLoginStep$fr._(_root);
	@override late final _Translations$login$encLoginStep$fr encLoginStep = _Translations$login$encLoginStep$fr._(_root);
}

// Path: profile
class _Translations$profile$fr extends Translations$profile$en {
	_Translations$profile$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mon profil';
	@override String get logout => 'Se déconnecter';
	@override String quotaUsage({required Object used, required Object total, required Object percent}) => 'Vous utilisez ${used} sur ${total} (${percent}%)';
	@override String quotaUsageUncapped({required Object used}) => 'Vous utilisez ${used}';
	@override String get connectedTo => 'Connecté à';
	@override String lastSynced({required Object time}) => 'Dernière synchronisation ${time}';
	@override String get notSyncedYet => 'Pas encore synchronisé';
	@override String get justNow => 'à l\'instant';
	@override String minutesAgo({required Object n}) => 'il y a ${n} min';
	@override String hoursAgo({required Object n}) => 'il y a ${n} h';
	@override String filesWaiting({required Object n}) => '${n} fichiers en attente de synchronisation';
	@override String get signInAgainNeeded => 'Reconnectez-vous pour continuer la synchronisation';
	@override String get signInAgain => 'Se reconnecter';
	@override String wrongAccount({required Object email}) => 'Veuillez choisir ${email}';
	@override late final _Translations$profile$quickLinks$fr quickLinks = _Translations$profile$quickLinks$fr._(_root);
	@override String get faqTitle => 'Questions fréquentes';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$fr._(_root),
		_Translations$profile$faq$1$fr._(_root),
		_Translations$profile$faq$2$fr._(_root),
		_Translations$profile$faq$3$fr._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$fr extends Translations$appInfo$en {
	_Translations$appInfo$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get debug => 'DEBUG';
}

// Path: update
class _Translations$update$fr extends Translations$update$en {
	_Translations$update$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => 'Mise à jour disponible';
	@override String get updateAvailableDescription => 'Une nouvelle version de l\'application est disponible :';
	@override String get update => 'Mettre à jour';
	@override String get downloadNotAvailableYet => 'Le téléchargement n\'est pas encore disponible pour votre plateforme. Revenez un peu plus tard.';
}

// Path: editor
class _Translations$editor$fr extends Translations$editor$en {
	_Translations$editor$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$fr toolbar = _Translations$editor$toolbar$fr._(_root);
	@override late final _Translations$editor$pens$fr pens = _Translations$editor$pens$fr._(_root);
	@override late final _Translations$editor$penOptions$fr penOptions = _Translations$editor$penOptions$fr._(_root);
	@override late final _Translations$editor$colors$fr colors = _Translations$editor$colors$fr._(_root);
	@override late final _Translations$editor$imageOptions$fr imageOptions = _Translations$editor$imageOptions$fr._(_root);
	@override late final _Translations$editor$selectionBar$fr selectionBar = _Translations$editor$selectionBar$fr._(_root);
	@override late final _Translations$editor$menu$fr menu = _Translations$editor$menu$fr._(_root);
	@override late final _Translations$editor$photoPdfError$fr photoPdfError = _Translations$editor$photoPdfError$fr._(_root);
	@override late final _Translations$editor$readOnlyBanner$fr readOnlyBanner = _Translations$editor$readOnlyBanner$fr._(_root);
	@override late final _Translations$editor$versionTooNew$fr versionTooNew = _Translations$editor$versionTooNew$fr._(_root);
	@override late final _Translations$editor$quill$fr quill = _Translations$editor$quill$fr._(_root);
	@override late final _Translations$editor$hud$fr hud = _Translations$editor$hud$fr._(_root);
	@override String get pages => 'Pages';
	@override String get untitled => 'Sans titre';
	@override String get needsToSaveBeforeExiting => 'Enregistrement de vos modifications… Vous pourrez quitter l\'éditeur une fois terminé';
}

// Path: home.tabs
class _Translations$home$tabs$fr extends Translations$home$tabs$en {
	_Translations$home$tabs$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Accueil';
	@override String get browse => 'Parcourir';
	@override String get whiteboard => 'Tableau blanc';
	@override String get settings => 'Paramètres';
}

// Path: home.titles
class _Translations$home$titles$fr extends Translations$home$titles$en {
	_Translations$home$titles$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Notes récentes';
	@override String get browse => 'Parcourir';
	@override String get whiteboard => 'Tableau blanc';
	@override String get settings => 'Paramètres';
}

// Path: home.tooltips
class _Translations$home$tooltips$fr extends Translations$home$tooltips$en {
	_Translations$home$tooltips$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Nouvelle note';
	@override String get showUpdateDialog => 'Afficher la mise à jour';
	@override String get exportNote => 'Exporter la note';
}

// Path: home.create
class _Translations$home$create$fr extends Translations$home$create$en {
	_Translations$home$create$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Nouvelle note';
	@override String get importNote => 'Importer une note';
}

// Path: home.newFolder
class _Translations$home$newFolder$fr extends Translations$home$newFolder$en {
	_Translations$home$newFolder$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get newFolder => 'Nouveau dossier';
	@override String get folderName => 'Nom du dossier';
	@override String get create => 'Créer';
	@override String get folderNameEmpty => 'Le nom du dossier ne peut pas être vide';
	@override String get folderNameContainsSlash => 'Le nom du dossier ne peut pas contenir de barre oblique';
	@override String get folderNameExists => 'Ce dossier existe déjà';
}

// Path: home.renameNote
class _Translations$home$renameNote$fr extends Translations$home$renameNote$en {
	_Translations$home$renameNote$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get renameNote => 'Renommer la note';
	@override String get noteName => 'Nom de la note';
	@override String get rename => 'Renommer';
	@override String get noteNameEmpty => 'Le nom de la note ne peut pas être vide';
	@override String get noteNameExists => 'Une note porte déjà ce nom';
	@override String get noteNameForbiddenCharacters => 'Le nom de la note contient des caractères interdits';
	@override String get noteNameReserved => 'Ce nom est réservé';
}

// Path: home.moveNote
class _Translations$home$moveNote$fr extends Translations$home$moveNote$en {
	_Translations$home$moveNote$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get moveNote => 'Déplacer la note';
	@override String moveNotes({required Object n}) => 'Déplacer ${n} notes';
	@override String moveName({required Object f}) => 'Déplacer ${f}';
	@override String get move => 'Déplacer';
	@override String renamedTo({required Object newName}) => 'La note sera renommée en ${newName}';
	@override String get multipleRenamedTo => 'Les notes suivantes seront renommées :';
	@override String numberRenamedTo({required Object n}) => '${n} notes seront renommées pour éviter les doublons';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$fr extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => 'Supprimer ${n} notes';
	@override String deleteName({required Object f}) => 'Supprimer ${f}';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Supprimer définitivement la note sélectionnée ?',
		other: 'Supprimer définitivement les notes sélectionnées ?',
	);
	@override String get delete => 'Supprimer';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$fr extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => 'Renommer le dossier';
	@override String get folderName => 'Nom du dossier';
	@override String get rename => 'Renommer';
	@override String get folderNameEmpty => 'Le nom du dossier ne peut pas être vide';
	@override String get folderNameContainsSlash => 'Le nom du dossier ne peut pas contenir de barre oblique';
	@override String get folderNameExists => 'Un dossier porte déjà ce nom';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$fr extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => 'Supprimer le dossier';
	@override String deleteName({required Object f}) => 'Supprimer ${f}';
	@override String get delete => 'Supprimer';
	@override String get alsoDeleteContents => 'Supprimer aussi toutes les notes de ce dossier';
}

// Path: home.sort
class _Translations$home$sort$fr extends Translations$home$sort$en {
	_Translations$home$sort$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get sortBy => 'Trier par';
	@override String get nameAToZ => 'Nom (A-Z)';
	@override String get nameZToA => 'Nom (Z-A)';
	@override String get lastModifiedNewToOld => 'Modification (plus récentes)';
	@override String get lastModifiedOldToNew => 'Modification (plus anciennes)';
}

// Path: home.layout
class _Translations$home$layout$fr extends Translations$home$layout$en {
	_Translations$home$layout$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get layout => 'Disposition';
	@override String get masonryGrid => 'Grille en mosaïque';
	@override String get simpleGrid => 'Grille simple';
}

// Path: sentry.consent
class _Translations$sentry$consent$fr extends Translations$sentry$consent$en {
	_Translations$sentry$consent$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Aider à améliorer BadNotes ?';
	@override late final _Translations$sentry$consent$description$fr description = _Translations$sentry$consent$description$fr._(_root);
	@override late final _Translations$sentry$consent$answers$fr answers = _Translations$sentry$consent$answers$fr._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$fr extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get general => 'Général';
	@override String get writing => 'Écriture';
	@override String get editor => 'Éditeur';
	@override String get performance => 'Performances';
	@override String get advanced => 'Avancé';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$fr extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get locale => 'Langue';
	@override String get appTheme => 'Thème de l\'application';
	@override String get platform => 'Type de thème';
	@override String get layoutSize => 'Type de disposition';
	@override String get customAccentColor => 'Couleur d\'accent personnalisée';
	@override String get hyperlegibleFont => 'Police Atkinson Hyperlegible';
	@override String get shouldCheckForUpdates => 'Rechercher les mises à jour de BadNotes';
	@override String get shouldAlwaysAlertForUpdates => 'Mises à jour plus rapides';
	@override String get allowInsecureConnections => 'Autoriser les connexions non sécurisées';
	@override String get syncOnlyOnWifi => 'Synchroniser uniquement en Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'Envoyer les aperçus en données mobiles';
	@override String get editorToolbarAlignment => 'Position de la barre d\'outils';
	@override String get editorToolbarShowInFullscreen => 'Afficher la barre d\'outils en plein écran';
	@override String get editorAutoInvert => 'Inverser les notes en mode sombre';
	@override String get preferGreyscale => 'Privilégier les niveaux de gris';
	@override String get maxImageSize => 'Taille d\'image maximale';
	@override String get autoClearWhiteboardOnExit => 'Effacer automatiquement le tableau blanc';
	@override String get disableEraserAfterUse => 'Désactiver automatiquement la gomme';
	@override String get hideFingerDrawingToggle => 'Masquer le bouton de dessin au doigt';
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Désactiver automatiquement le dessin au doigt';
	@override String get editorPromptRename => 'Proposer de renommer les nouvelles notes';
	@override String get recentColorsDontSavePresets => 'Ne pas enregistrer les couleurs prédéfinies dans les couleurs récentes';
	@override String get recentColorsLength => 'Nombre de couleurs récentes à garder';
	@override String get printPageIndicators => 'Imprimer les numéros de page';
	@override String get autosave => 'Enregistrement automatique';
	@override String get shapeRecognitionDelay => 'Délai de reconnaissance des formes';
	@override String get autoStraightenLines => 'Redresser automatiquement les lignes';
	@override String get customDataDir => 'Dossier BadNotes personnalisé';
	@override String get sentry => 'Signalement des erreurs';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$fr extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => 'Désactivé : les notes se synchronisent aussi en données mobiles. Activé : la synchronisation attend le Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'Par défaut, les miniatures attendent le Wi-Fi pour économiser les données';
	@override String get hyperlegibleFont => 'Améliore la lisibilité pour les personnes malvoyantes';
	@override String get allowInsecureConnections => '(Déconseillé) Autoriser BadNotes à se connecter à des serveurs aux certificats autosignés ou non fiables';
	@override String get preferGreyscale => 'Pour les écrans à encre électronique';
	@override String get autoClearWhiteboardOnExit => 'Efface le tableau blanc quand vous quittez l\'application';
	@override String get disableEraserAfterUse => 'Revient automatiquement au stylo après l\'utilisation de la gomme';
	@override String get maxImageSize => 'Les images plus grandes seront compressées';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$fr hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$fr._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Désactive le dessin au doigt quand un stylet est détecté';
	@override String get editorPromptRename => 'Vous pourrez toujours renommer les notes plus tard';
	@override String get printPageIndicators => 'Afficher les numéros de page dans les exports';
	@override String get autosave => 'Enregistrer automatiquement après un court délai, ou jamais';
	@override String get shapeRecognitionDelay => 'Durée pendant laquelle garder le stylo immobile avant que le tracé devienne une forme';
	@override String get autoStraightenLines => 'Redresse les longues lignes sans passer par le stylo à formes';
	@override String get shouldAlwaysAlertForUpdates => 'Me prévenir des mises à jour dès qu\'elles sont disponibles';
	@override late final _Translations$settings$prefDescriptions$sentry$fr sentry = _Translations$settings$prefDescriptions$sentry$fr._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$fr extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get system => 'Système';
	@override String get light => 'Clair';
	@override String get dark => 'Sombre';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$fr extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get auto => 'Auto';
	@override String get phone => 'Téléphone';
	@override String get tablet => 'Tablette';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$fr extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => 'Choisir une couleur';
}

// Path: settings.reset
class _Translations$settings$reset$fr extends Translations$settings$reset$en {
	_Translations$settings$reset$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Réinitialiser ce paramètre ?';
	@override String get button => 'Réinitialiser';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$fr extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuler';
	@override String get select => 'Sélectionner';
	@override String get mustBeEmpty => 'Le dossier sélectionné doit être vide';
	@override String get mustBeDoneSyncing => 'Attendez la fin de la synchronisation avant de changer de dossier';
	@override String get unsupported => 'Cette fonction est pour l\'instant réservée aux développeurs. L\'utiliser risque fortement d\'entraîner une perte de données.';
}

// Path: login.form
class _Translations$login$form$fr extends Translations$login$form$en {
	_Translations$login$form$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'En vous connectant, vous acceptez la '),
		linkToPrivacyPolicy('politique de confidentialité'),
		const TextSpan(text: '.'),
	]);
}

// Path: login.status
class _Translations$login$status$fr extends Translations$login$status$en {
	_Translations$login$status$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => 'Déconnecté';
	@override String get tapToLogin => 'Appuyez pour synchroniser avec Google Drive';
	@override String hi({required Object u}) => 'Bonjour, ${u} !';
	@override String get almostDone => 'Presque prêt pour la synchronisation, appuyez pour terminer la connexion';
	@override String get loggedIn => 'Synchronisation activée';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$fr extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => 'Choisissez où stocker vos données :';
	@override String get cloudStorage => 'Google Drive ou OneDrive';
	@override String get loginWithGoogleDrive => 'Continuer avec Google Drive';
	@override String get loginWithOneDrive => 'Continuer avec OneDrive';
	@override String get cloudLoginFailed => 'Connexion impossible';
	@override String get comingSoon => 'Bientôt disponible';
	@override String get badnotesNcServer => 'Serveur Nextcloud de BadNotes';
	@override String get otherNcServer => 'Autre serveur Nextcloud';
	@override String get serverUrl => 'URL du serveur';
	@override String get loginWithBadNotes => 'Se connecter avec BadNotes';
	@override String get loginWithNextcloud => 'Se connecter avec Nextcloud';
	@override late final _Translations$login$ncLoginStep$loginFlow$fr loginFlow = _Translations$login$ncLoginStep$loginFlow$fr._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$fr extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => 'Pour protéger vos données, saisissez votre mot de passe de chiffrement :';
	@override String get newToBadNotes => 'Nouveau sur BadNotes ? Saisissez simplement un nouveau mot de passe de chiffrement.';
	@override String get encPassword => 'Mot de passe de chiffrement';
	@override String get encFaqTitle => 'Questions fréquentes';
	@override String get wrongEncPassword => 'Le déchiffrement a échoué avec ce mot de passe. Veuillez le saisir à nouveau.';
	@override String get connectionFailed => 'Un problème est survenu lors de la connexion au serveur. Veuillez réessayer plus tard.';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$fr._(_root),
		_Translations$login$encLoginStep$encFaq$1$fr._(_root),
		_Translations$login$encLoginStep$encFaq$2$fr._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$fr extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => 'Page d\'accueil du serveur';
	@override String get deleteAccount => 'Supprimer le compte';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$fr extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Vais-je perdre mes notes si je me déconnecte ?';
	@override String get a => 'Non. Vos notes restent sur votre appareil et sur le serveur. Elles ne seront plus synchronisées avec le serveur tant que vous ne vous reconnecterez pas. Attendez la fin de la synchronisation avant de vous déconnecter pour ne perdre aucune donnée (la progression s\'affiche sur l\'écran d\'accueil).';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$fr extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Où sont stockées mes notes ?';
	@override String get a => 'Dans un dossier « BadNotes » de votre Google Drive, ou « Apps/BadNotes » dans votre OneDrive. Les fichiers sont chiffrés et ne peuvent donc être ouverts que dans BadNotes.';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$fr extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Comment changer mon mot de passe de chiffrement ?';
	@override String get a => '0. Attendez la fin de la synchronisation (la progression s\'affiche sur l\'écran d\'accueil).\n1. Déconnectez-vous de BadNotes.\n2. Supprimez le dossier « BadNotes » de votre Google Drive ou OneDrive. Cela supprime toutes vos notes du cloud, pas de votre appareil.\n3. Reconnectez-vous à BadNotes. Vous pourrez choisir un nouveau mot de passe de chiffrement lors de la connexion.\n4. N\'oubliez pas de vous déconnecter puis de vous reconnecter à BadNotes sur vos autres appareils.';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$fr extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Comment supprimer mon compte ?';
	@override String get a => 'BadNotes n\'a pas de compte propre. Déconnectez-vous, puis supprimez le dossier « BadNotes » de votre Google Drive ou OneDrive.\nPour retirer aussi l\'accès de BadNotes, rendez-vous sur myaccount.google.com/permissions (Google) ou account.live.com/consent/Manage (Microsoft).';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$fr extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => 'Couleurs (Ctrl C)';
	@override String get select => 'Sélectionner';
	@override String get toggleEraser => 'Gomme (Ctrl E)';
	@override String get photo => 'Images';
	@override String get text => 'Texte';
	@override String get toggleFingerDrawing => 'Dessin au doigt (Ctrl F)';
	@override String get undo => 'Annuler';
	@override String get redo => 'Rétablir';
	@override String get export => 'Exporter (Ctrl Shift S)';
	@override String get exportAs => 'Exporter en :';
	@override String get fullscreen => 'Plein écran (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$fr extends Translations$editor$pens$en {
	_Translations$editor$pens$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => 'Stylo plume';
	@override String get ballpointPen => 'Stylo à bille';
	@override String get highlighter => 'Surligneur';
	@override String get pencil => 'Crayon';
	@override String get shapePen => 'Stylo à formes';
	@override String get laserPointer => 'Pointeur laser';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$fr extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get size => 'Taille';
}

// Path: editor.colors
class _Translations$editor$colors$fr extends Translations$editor$colors$en {
	_Translations$editor$colors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => 'Sélecteur de couleur';
	@override String customBrightnessHue({required Object h, required Object b}) => '${h} ${b} personnalisé';
	@override String customHue({required Object h}) => '${h} personnalisé';
	@override String get dark => 'foncé';
	@override String get light => 'clair';
	@override String get black => 'Noir';
	@override String get darkGrey => 'Gris foncé';
	@override String get grey => 'Gris';
	@override String get lightGrey => 'Gris clair';
	@override String get white => 'Blanc';
	@override String get red => 'Rouge';
	@override String get green => 'Vert';
	@override String get cyan => 'Cyan';
	@override String get blue => 'Bleu';
	@override String get yellow => 'Jaune';
	@override String get purple => 'Violet';
	@override String get pink => 'Rose';
	@override String get orange => 'Orange';
	@override String get pastelRed => 'Rouge pastel';
	@override String get pastelOrange => 'Orange pastel';
	@override String get pastelYellow => 'Jaune pastel';
	@override String get pastelGreen => 'Vert pastel';
	@override String get pastelCyan => 'Cyan pastel';
	@override String get pastelBlue => 'Bleu pastel';
	@override String get pastelPurple => 'Violet pastel';
	@override String get pastelPink => 'Rose pastel';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$fr extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Options de l\'image';
	@override String get invertible => 'Inversible';
	@override String get download => 'Télécharger';
	@override String get setAsBackground => 'Définir comme arrière-plan';
	@override String get removeAsBackground => 'Retirer de l\'arrière-plan';
	@override String get delete => 'Supprimer';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$fr extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Supprimer';
	@override String get duplicate => 'Dupliquer';
}

// Path: editor.menu
class _Translations$editor$menu$fr extends Translations$editor$menu$en {
	_Translations$editor$menu$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => 'Effacer la page ${page}/${totalPages}';
	@override String get clearAllPages => 'Effacer toutes les pages';
	@override String get insertPage => 'Insérer une page en dessous';
	@override String get duplicatePage => 'Dupliquer la page';
	@override String get deletePage => 'Supprimer la page';
	@override String get lineHeight => 'Interligne';
	@override String get lineHeightDescription => 'Règle aussi la taille du texte des notes saisies au clavier';
	@override String get lineThickness => 'Épaisseur des lignes';
	@override String get lineThicknessDescription => 'Épaisseur des lignes de fond';
	@override String get backgroundImageFit => 'Ajustement de l\'image de fond';
	@override String get backgroundPattern => 'Motif de fond';
	@override String get import => 'Importer';
	@override String get watchServer => 'Suivre les mises à jour du serveur';
	@override String get watchServerReadOnly => 'La modification est désactivée pendant le suivi du serveur';
	@override late final _Translations$editor$menu$boxFits$fr boxFits = _Translations$editor$menu$boxFits$fr._(_root);
	@override late final _Translations$editor$menu$bgPatterns$fr bgPatterns = _Translations$editor$menu$bgPatterns$fr._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$fr extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Erreur';
	@override String get message => 'Les fichiers PDF ne peuvent pas être ajoutés comme image. Utilisez plutôt « ${_root.editor.menu.import} > PDF ».';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$fr extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lecture seule';
	@override String get watchingServer => 'Vous suivez actuellement les mises à jour du serveur. La modification est désactivée dans ce mode.';
	@override String get corrupted => 'Impossible de charger la note. Elle est peut-être corrompue ou encore en cours de téléchargement.';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$fr extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cette note a été modifiée avec une version plus récente de BadNotes';
	@override String get subtitle => 'Modifier cette note peut entraîner la perte de certaines informations. Voulez-vous quand même la modifier ?';
	@override String get allowEditing => 'Autoriser la modification';
}

// Path: editor.quill
class _Translations$editor$quill$fr extends Translations$editor$quill$en {
	_Translations$editor$quill$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => 'Saisissez du texte ici…';
}

// Path: editor.hud
class _Translations$editor$hud$fr extends Translations$editor$hud$en {
	_Translations$editor$hud$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => 'Déverrouiller le zoom';
	@override String get lockZoom => 'Verrouiller le zoom';
	@override String get unlockSingleFingerPan => 'Activer le défilement à un doigt';
	@override String get lockSingleFingerPan => 'Désactiver le défilement à un doigt';
	@override String get unlockAxisAlignedPan => 'Ne plus limiter le défilement à l\'horizontale ou à la verticale';
	@override String get lockAxisAlignedPan => 'Limiter le défilement à l\'horizontale ou à la verticale';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$fr extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get question => 'Voulez-vous signaler automatiquement les erreurs inattendues ? Cela m\'aide à trouver et corriger les problèmes plus vite.';
	@override String get scope => 'Les rapports peuvent contenir des informations sur l\'erreur et sur votre appareil. J\'ai fait de mon mieux pour filtrer les données personnelles, mais il peut en rester.';
	@override String get currentlyOff => 'Si vous donnez votre accord, le signalement des erreurs sera activé au prochain redémarrage de l\'application.';
	@override String get currentlyOn => 'Si vous retirez votre accord, redémarrez l\'application pour désactiver le signalement des erreurs.';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: 'En savoir plus dans la '),
		link('politique de confidentialité'),
		const TextSpan(text: '.'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$fr extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Oui';
	@override String get no => 'Non';
	@override String get later => 'Plus tard';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$fr extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get shown => 'Évite les changements accidentels';
	@override String get fixedOn => 'Le dessin au doigt reste activé';
	@override String get fixedOff => 'Le dessin au doigt reste désactivé';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$fr extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get active => 'Activé';
	@override String get inactive => 'Désactivé';
	@override String get activeUntilRestart => 'Activé jusqu\'au redémarrage de l\'application';
	@override String get inactiveUntilRestart => 'Désactivé jusqu\'au redémarrage de l\'application';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$fr extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => 'Autorisez BadNotes à accéder à votre compte Nextcloud';
	@override String get followPrompts => 'Suivez les instructions dans l\'interface de Nextcloud';
	@override String get browserDidntOpen => 'La page de connexion ne s\'est pas ouverte ? Cliquez ici';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$fr extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Qu\'est-ce qu\'un mot de passe de chiffrement ? Pourquoi deux mots de passe ?';
	@override String get a => 'Votre compte Google ou Microsoft sert à accéder au cloud. Le mot de passe de chiffrement « brouille » vos données avant même qu\'elles n\'atteignent le cloud.\nMême si quelqu\'un accède à votre compte Google ou Microsoft, vos notes restent protégées et chiffrées par un mot de passe distinct. Vous bénéficiez ainsi d\'un second niveau de sécurité pour vos données.\nPersonne ne peut lire vos notes sur le serveur sans votre mot de passe de chiffrement. Mais cela signifie aussi que si vous l\'oubliez, vous perdrez l\'accès à vos données.';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$fr extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Je n\'ai pas encore de mot de passe de chiffrement. Où le trouver ?';
	@override String get a => 'Choisissez un nouveau mot de passe de chiffrement et saisissez-le ci-dessus.\nBadNotes générera automatiquement vos clés de chiffrement à partir de ce mot de passe.';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$fr extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Puis-je utiliser le même mot de passe que pour mon compte Google ou Microsoft ?';
	@override String get a => 'Mieux vaut éviter. Un mot de passe de chiffrement distinct protège vos notes même si quelqu\'un accède à ce compte.';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$fr extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get fill => 'Étirer';
	@override String get cover => 'Couvrir';
	@override String get contain => 'Contenir';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$fr extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get none => 'Vierge';
	@override String get college => 'Ligné (marge)';
	@override String get collegeRtl => 'Ligné (marge inversée)';
	@override String get lined => 'Ligné';
	@override String get grid => 'Quadrillé';
	@override String get dots => 'Pointillé';
	@override String get staffs => 'Portées';
	@override String get tablature => 'Tablature';
	@override String get cornell => 'Cornell';
}
