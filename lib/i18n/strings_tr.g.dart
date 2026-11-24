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
class TranslationsTr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsTr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.tr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <tr>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsTr _root = this; // ignore: unused_field

	@override 
	TranslationsTr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsTr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$tr common = _Translations$common$tr._(_root);
	@override late final _Translations$home$tr home = _Translations$home$tr._(_root);
	@override late final _Translations$sentry$tr sentry = _Translations$sentry$tr._(_root);
	@override late final _Translations$settings$tr settings = _Translations$settings$tr._(_root);
	@override late final _Translations$logs$tr logs = _Translations$logs$tr._(_root);
	@override late final _Translations$login$tr login = _Translations$login$tr._(_root);
	@override late final _Translations$profile$tr profile = _Translations$profile$tr._(_root);
	@override late final _Translations$appInfo$tr appInfo = _Translations$appInfo$tr._(_root);
	@override late final _Translations$update$tr update = _Translations$update$tr._(_root);
	@override late final _Translations$editor$tr editor = _Translations$editor$tr._(_root);
}

// Path: common
class _Translations$common$tr extends Translations$common$en {
	_Translations$common$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get done => 'Bitti';
	@override String get continueBtn => 'Devam';
	@override String get cancel => 'İptal';
}

// Path: home
class _Translations$home$tr extends Translations$home$en {
	_Translations$home$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$tr tabs = _Translations$home$tabs$tr._(_root);
	@override late final _Translations$home$titles$tr titles = _Translations$home$titles$tr._(_root);
	@override late final _Translations$home$tooltips$tr tooltips = _Translations$home$tooltips$tr._(_root);
	@override late final _Translations$home$create$tr create = _Translations$home$create$tr._(_root);
	@override String get welcome => 'BadNotes\'a hoş geldiniz';
	@override String get invalidFormat => 'Seçtiğiniz dosya desteklenmiyor. Lütfen bir sbn, sbn2, sba veya pdf dosyası seçin.';
	@override String get noFiles => 'Dosya bulunamadı';
	@override String get noPreviewAvailable => 'Önizleme yok';
	@override String get createNewNote => 'Yeni not oluşturmak için + düğmesine dokunun';
	@override String get backFolder => 'Önceki klasöre dön';
	@override late final _Translations$home$newFolder$tr newFolder = _Translations$home$newFolder$tr._(_root);
	@override late final _Translations$home$renameNote$tr renameNote = _Translations$home$renameNote$tr._(_root);
	@override late final _Translations$home$moveNote$tr moveNote = _Translations$home$moveNote$tr._(_root);
	@override String get deleteNote => 'Notu sil';
	@override late final _Translations$home$deleteNoteDialog$tr deleteNoteDialog = _Translations$home$deleteNoteDialog$tr._(_root);
	@override late final _Translations$home$renameFolder$tr renameFolder = _Translations$home$renameFolder$tr._(_root);
	@override late final _Translations$home$deleteFolder$tr deleteFolder = _Translations$home$deleteFolder$tr._(_root);
	@override late final _Translations$home$sort$tr sort = _Translations$home$sort$tr._(_root);
	@override late final _Translations$home$layout$tr layout = _Translations$home$layout$tr._(_root);
}

// Path: sentry
class _Translations$sentry$tr extends Translations$sentry$en {
	_Translations$sentry$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$tr consent = _Translations$sentry$consent$tr._(_root);
}

// Path: settings
class _Translations$settings$tr extends Translations$settings$en {
	_Translations$settings$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$tr prefCategories = _Translations$settings$prefCategories$tr._(_root);
	@override late final _Translations$settings$prefLabels$tr prefLabels = _Translations$settings$prefLabels$tr._(_root);
	@override late final _Translations$settings$prefDescriptions$tr prefDescriptions = _Translations$settings$prefDescriptions$tr._(_root);
	@override late final _Translations$settings$themeModes$tr themeModes = _Translations$settings$themeModes$tr._(_root);
	@override late final _Translations$settings$layoutSizes$tr layoutSizes = _Translations$settings$layoutSizes$tr._(_root);
	@override late final _Translations$settings$accentColorPicker$tr accentColorPicker = _Translations$settings$accentColorPicker$tr._(_root);
	@override String get systemLanguage => 'Otomatik';
	@override List<String> get axisDirections => [
		'Üst',
		'Sağ',
		'Alt',
		'Sol',
	];
	@override late final _Translations$settings$reset$tr reset = _Translations$settings$reset$tr._(_root);
	@override String get resyncEverything => 'Her şeyi yeniden eşitle';
	@override String get openDataDir => 'BadNotes klasörünü aç';
	@override late final _Translations$settings$customDataDir$tr customDataDir = _Translations$settings$customDataDir$tr._(_root);
	@override String get autosaveDisabled => 'Asla';
	@override String get shapeRecognitionDisabled => 'Asla';
}

// Path: logs
class _Translations$logs$tr extends Translations$logs$en {
	_Translations$logs$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get logs => 'Günlükler';
	@override String get viewLogs => 'Günlükleri görüntüle';
	@override String get debuggingInfo => 'Günlükler hata ayıklama ve geliştirme için yararlı bilgiler içerir';
	@override String get noLogs => 'Burada günlük yok!';
	@override String get useTheApp => 'Uygulamayı kullandıkça günlükler burada görünür';
}

// Path: login
class _Translations$login$tr extends Translations$login$en {
	_Translations$login$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Giriş';
	@override late final _Translations$login$form$tr form = _Translations$login$form$tr._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: 'Henüz hesabınız yok mu? '),
		linkToSignup('Hemen kaydolun'),
		const TextSpan(text: '!'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: 'Siz değil misiniz? '),
		undoLogin('Başka bir hesap seçin'),
		const TextSpan(text: '.'),
	]);
	@override late final _Translations$login$status$tr status = _Translations$login$status$tr._(_root);
	@override late final _Translations$login$ncLoginStep$tr ncLoginStep = _Translations$login$ncLoginStep$tr._(_root);
	@override late final _Translations$login$encLoginStep$tr encLoginStep = _Translations$login$encLoginStep$tr._(_root);
}

// Path: profile
class _Translations$profile$tr extends Translations$profile$en {
	_Translations$profile$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Profilim';
	@override String get logout => 'Çıkış yap';
	@override String quotaUsage({required Object total, required Object used, required Object percent}) => '${total} alanın ${used} kadarını kullanıyorsunuz (%${percent})';
	@override String quotaUsageUncapped({required Object used}) => '${used} kullanıyorsunuz';
	@override String get connectedTo => 'Bağlı olunan';
	@override String lastSynced({required Object time}) => 'Son eşitleme ${time}';
	@override String get notSyncedYet => 'Henüz eşitlenmedi';
	@override String get justNow => 'az önce';
	@override String minutesAgo({required Object n}) => '${n} dk önce';
	@override String hoursAgo({required Object n}) => '${n} sa önce';
	@override String filesWaiting({required Object n}) => '${n} dosya eşitlenmeyi bekliyor';
	@override String get signInAgainNeeded => 'Eşitlemeye devam etmek için yeniden giriş yapın';
	@override String get signInAgain => 'Yeniden giriş yap';
	@override String wrongAccount({required Object email}) => 'Lütfen ${email} hesabını seçin';
	@override late final _Translations$profile$quickLinks$tr quickLinks = _Translations$profile$quickLinks$tr._(_root);
	@override String get faqTitle => 'Sık sorulan sorular';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$tr._(_root),
		_Translations$profile$faq$1$tr._(_root),
		_Translations$profile$faq$2$tr._(_root),
		_Translations$profile$faq$3$tr._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$tr extends Translations$appInfo$en {
	_Translations$appInfo$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get debug => 'HATA AYIKLAMA';
}

// Path: update
class _Translations$update$tr extends Translations$update$en {
	_Translations$update$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => 'Güncelleme var';
	@override String get updateAvailableDescription => 'Uygulamanın yeni bir sürümü çıktı:';
	@override String get update => 'Güncelle';
	@override String get downloadNotAvailableYet => 'İndirme, platformunuz için henüz hazır değil. Lütfen kısa süre sonra yeniden bakın.';
}

// Path: editor
class _Translations$editor$tr extends Translations$editor$en {
	_Translations$editor$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$tr toolbar = _Translations$editor$toolbar$tr._(_root);
	@override late final _Translations$editor$pens$tr pens = _Translations$editor$pens$tr._(_root);
	@override late final _Translations$editor$penOptions$tr penOptions = _Translations$editor$penOptions$tr._(_root);
	@override late final _Translations$editor$colors$tr colors = _Translations$editor$colors$tr._(_root);
	@override late final _Translations$editor$imageOptions$tr imageOptions = _Translations$editor$imageOptions$tr._(_root);
	@override late final _Translations$editor$selectionBar$tr selectionBar = _Translations$editor$selectionBar$tr._(_root);
	@override late final _Translations$editor$menu$tr menu = _Translations$editor$menu$tr._(_root);
	@override late final _Translations$editor$photoPdfError$tr photoPdfError = _Translations$editor$photoPdfError$tr._(_root);
	@override late final _Translations$editor$readOnlyBanner$tr readOnlyBanner = _Translations$editor$readOnlyBanner$tr._(_root);
	@override late final _Translations$editor$versionTooNew$tr versionTooNew = _Translations$editor$versionTooNew$tr._(_root);
	@override late final _Translations$editor$quill$tr quill = _Translations$editor$quill$tr._(_root);
	@override late final _Translations$editor$hud$tr hud = _Translations$editor$hud$tr._(_root);
	@override String get pages => 'Sayfalar';
	@override String get untitled => 'Adsız';
	@override String get needsToSaveBeforeExiting => 'Değişiklikleriniz kaydediliyor… Bittiğinde düzenleyiciden güvenle çıkabilirsiniz';
}

// Path: home.tabs
class _Translations$home$tabs$tr extends Translations$home$tabs$en {
	_Translations$home$tabs$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Ana sayfa';
	@override String get browse => 'Göz at';
	@override String get whiteboard => 'Beyaz tahta';
	@override String get settings => 'Ayarlar';
}

// Path: home.titles
class _Translations$home$titles$tr extends Translations$home$titles$en {
	_Translations$home$titles$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Son notlar';
	@override String get browse => 'Göz at';
	@override String get whiteboard => 'Beyaz tahta';
	@override String get settings => 'Ayarlar';
}

// Path: home.tooltips
class _Translations$home$tooltips$tr extends Translations$home$tooltips$en {
	_Translations$home$tooltips$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Yeni not';
	@override String get showUpdateDialog => 'Güncelleme penceresini göster';
	@override String get exportNote => 'Notu dışa aktar';
}

// Path: home.create
class _Translations$home$create$tr extends Translations$home$create$en {
	_Translations$home$create$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Yeni not';
	@override String get importNote => 'Not içe aktar';
}

// Path: home.newFolder
class _Translations$home$newFolder$tr extends Translations$home$newFolder$en {
	_Translations$home$newFolder$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get newFolder => 'Yeni klasör';
	@override String get folderName => 'Klasör adı';
	@override String get create => 'Oluştur';
	@override String get folderNameEmpty => 'Klasör adı boş olamaz';
	@override String get folderNameContainsSlash => 'Klasör adı eğik çizgi içeremez';
	@override String get folderNameExists => 'Klasör zaten var';
}

// Path: home.renameNote
class _Translations$home$renameNote$tr extends Translations$home$renameNote$en {
	_Translations$home$renameNote$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get renameNote => 'Notu yeniden adlandır';
	@override String get noteName => 'Not adı';
	@override String get rename => 'Yeniden adlandır';
	@override String get noteNameEmpty => 'Not adı boş olamaz';
	@override String get noteNameExists => 'Bu adda bir not zaten var';
	@override String get noteNameForbiddenCharacters => 'Not adı izin verilmeyen karakterler içeriyor';
	@override String get noteNameReserved => 'Bu not adı ayrılmış';
}

// Path: home.moveNote
class _Translations$home$moveNote$tr extends Translations$home$moveNote$en {
	_Translations$home$moveNote$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get moveNote => 'Notu taşı';
	@override String moveNotes({required Object n}) => '${n} notu taşı';
	@override String moveName({required Object f}) => '${f} öğesini taşı';
	@override String get move => 'Taşı';
	@override String renamedTo({required Object newName}) => 'Notun adı ${newName} olarak değiştirilecek';
	@override String get multipleRenamedTo => 'Şu notların adı değiştirilecek:';
	@override String numberRenamedTo({required Object n}) => 'Çakışmaları önlemek için ${n} notun adı değiştirilecek';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$tr extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => '${n} notu sil';
	@override String deleteName({required Object f}) => '${f} öğesini sil';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('tr'))(n,
		one: 'Seçili not kalıcı olarak silinsin mi?',
		other: 'Seçili notlar kalıcı olarak silinsin mi?',
	);
	@override String get delete => 'Sil';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$tr extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => 'Klasörü yeniden adlandır';
	@override String get folderName => 'Klasör adı';
	@override String get rename => 'Yeniden adlandır';
	@override String get folderNameEmpty => 'Klasör adı boş olamaz';
	@override String get folderNameContainsSlash => 'Klasör adı eğik çizgi içeremez';
	@override String get folderNameExists => 'Bu adda bir klasör zaten var';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$tr extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => 'Klasörü sil';
	@override String deleteName({required Object f}) => '${f} öğesini sil';
	@override String get delete => 'Sil';
	@override String get alsoDeleteContents => 'Bu klasördeki tüm notları da sil';
}

// Path: home.sort
class _Translations$home$sort$tr extends Translations$home$sort$en {
	_Translations$home$sort$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get sortBy => 'Sırala';
	@override String get nameAToZ => 'Ad (A-Z)';
	@override String get nameZToA => 'Ad (Z-A)';
	@override String get lastModifiedNewToOld => 'Düzenlenme (Önce en yeni)';
	@override String get lastModifiedOldToNew => 'Düzenlenme (Önce en eski)';
}

// Path: home.layout
class _Translations$home$layout$tr extends Translations$home$layout$en {
	_Translations$home$layout$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get layout => 'Düzen';
	@override String get masonryGrid => 'Döşeme ızgara';
	@override String get simpleGrid => 'Basit ızgara';
}

// Path: sentry.consent
class _Translations$sentry$consent$tr extends Translations$sentry$consent$en {
	_Translations$sentry$consent$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'BadNotes\'u geliştirmeye yardım eder misiniz?';
	@override late final _Translations$sentry$consent$description$tr description = _Translations$sentry$consent$description$tr._(_root);
	@override late final _Translations$sentry$consent$answers$tr answers = _Translations$sentry$consent$answers$tr._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$tr extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get general => 'Genel';
	@override String get writing => 'Yazma';
	@override String get editor => 'Düzenleyici';
	@override String get performance => 'Performans';
	@override String get advanced => 'Gelişmiş';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$tr extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get locale => 'Dil';
	@override String get appTheme => 'Uygulama teması';
	@override String get platform => 'Tema türü';
	@override String get layoutSize => 'Düzen türü';
	@override String get customAccentColor => 'Özel vurgu rengi';
	@override String get hyperlegibleFont => 'Atkinson Hyperlegible yazı tipi';
	@override String get shouldCheckForUpdates => 'BadNotes güncellemelerini denetle';
	@override String get shouldAlwaysAlertForUpdates => 'Daha hızlı güncellemeler';
	@override String get allowInsecureConnections => 'Güvensiz bağlantılara izin ver';
	@override String get syncOnlyOnWifi => 'Yalnızca Wi-Fi\'da eşitle';
	@override String get syncPreviewsOnMobileData => 'Önizlemeleri mobil veriyle yükle';
	@override String get editorToolbarAlignment => 'Araç çubuğu konumu';
	@override String get editorToolbarShowInFullscreen => 'Tam ekranda araç çubuğunu göster';
	@override String get editorAutoInvert => 'Karanlık modda notları ters çevir';
	@override String get preferGreyscale => 'Gri tonlu renkleri tercih et';
	@override String get maxImageSize => 'En büyük görsel boyutu';
	@override String get autoClearWhiteboardOnExit => 'Beyaz tahtayı otomatik temizle';
	@override String get disableEraserAfterUse => 'Silgiyi otomatik kapat';
	@override String get hideFingerDrawingToggle => 'Parmakla çizim düğmesini gizle';
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Parmakla çizimi otomatik kapat';
	@override String get editorPromptRename => 'Yeni notlar için ad sor';
	@override String get recentColorsDontSavePresets => 'Hazır renkleri son renklere kaydetme';
	@override String get recentColorsLength => 'Kaç son renk saklansın';
	@override String get printPageIndicators => 'Sayfa numaralarını yazdır';
	@override String get autosave => 'Otomatik kaydet';
	@override String get shapeRecognitionDelay => 'Şekil tanıma gecikmesi';
	@override String get autoStraightenLines => 'Çizgileri otomatik düzelt';
	@override String get customDataDir => 'Özel BadNotes klasörü';
	@override String get sentry => 'Hata bildirimi';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$tr extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => 'Kapalı: notlar mobil veriyle de eşitlenir. Açık: eşitleme Wi-Fi\'ı bekler';
	@override String get syncPreviewsOnMobileData => 'Not küçük resimleri veri tasarrufu için normalde Wi-Fi\'ı bekler';
	@override String get hyperlegibleFont => 'Az gören kullanıcılar için okunabilirliği artırır';
	@override String get allowInsecureConnections => '(Önerilmez) BadNotes\'un kendinden imzalı/güvenilmeyen sertifikalı sunuculara bağlanmasına izin ver';
	@override String get preferGreyscale => 'E-mürekkep ekranlar için';
	@override String get autoClearWhiteboardOnExit => 'Uygulamadan çıkınca beyaz tahtayı temizler';
	@override String get disableEraserAfterUse => 'Silgiyi kullandıktan sonra otomatik olarak kaleme döner';
	@override String get maxImageSize => 'Daha büyük görseller sıkıştırılır';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$tr hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$tr._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Kalem algılanınca parmakla çizimi kapat';
	@override String get editorPromptRename => 'Notları daha sonra her zaman yeniden adlandırabilirsiniz';
	@override String get printPageIndicators => 'Dışa aktarımlarda sayfa numaralarını göster';
	@override String get autosave => 'Kısa bir gecikmeden sonra otomatik kaydet ya da hiç kaydetme';
	@override String get shapeRecognitionDelay => 'Mürekkebin şekle dönüşmesi için kalemin ne kadar sabit tutulacağı';
	@override String get autoStraightenLines => 'Şekil kalemi kullanmadan uzun çizgileri düzeltir';
	@override String get shouldAlwaysAlertForUpdates => 'Güncellemeler çıkar çıkmaz haber ver';
	@override late final _Translations$settings$prefDescriptions$sentry$tr sentry = _Translations$settings$prefDescriptions$sentry$tr._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$tr extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get system => 'Sistem';
	@override String get light => 'Açık';
	@override String get dark => 'Koyu';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$tr extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get auto => 'Otomatik';
	@override String get phone => 'Telefon';
	@override String get tablet => 'Tablet';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$tr extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => 'Renk seçin';
}

// Path: settings.reset
class _Translations$settings$reset$tr extends Translations$settings$reset$en {
	_Translations$settings$reset$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bu ayar sıfırlansın mı?';
	@override String get button => 'Sıfırla';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$tr extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'İptal';
	@override String get select => 'Seç';
	@override String get mustBeEmpty => 'Seçilen klasör boş olmalı';
	@override String get mustBeDoneSyncing => 'Klasörü değiştirmeden önce eşitlemenin bittiğinden emin olun';
	@override String get unsupported => 'Bu özellik şu anda yalnızca geliştiriciler içindir. Kullanmak büyük olasılıkla veri kaybına yol açar.';
}

// Path: login.form
class _Translations$login$form$tr extends Translations$login$form$en {
	_Translations$login$form$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'Giriş yaparak '),
		linkToPrivacyPolicy('Gizlilik Politikasını'),
		const TextSpan(text: ' kabul etmiş olursunuz.'),
	]);
}

// Path: login.status
class _Translations$login$status$tr extends Translations$login$status$en {
	_Translations$login$status$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => 'Çıkış yapıldı';
	@override String get tapToLogin => 'Google Drive ile eşitlemek için dokunun';
	@override String hi({required Object u}) => 'Merhaba, ${u}!';
	@override String get almostDone => 'Eşitlemeye neredeyse hazır, girişi tamamlamak için dokunun';
	@override String get loggedIn => 'Eşitleme açık';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$tr extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => 'Verilerinizi nerede saklamak istediğinizi seçin:';
	@override String get cloudStorage => 'Google Drive veya OneDrive';
	@override String get loginWithGoogleDrive => 'Google Drive ile devam et';
	@override String get loginWithOneDrive => 'OneDrive ile devam et';
	@override String get cloudLoginFailed => 'Giriş yapılamadı';
	@override String get comingSoon => 'Yakında';
	@override String get badnotesNcServer => 'BadNotes Nextcloud sunucusu';
	@override String get otherNcServer => 'Başka bir Nextcloud sunucusu';
	@override String get serverUrl => 'Sunucu URL\'si';
	@override String get loginWithBadNotes => 'BadNotes ile giriş yap';
	@override String get loginWithNextcloud => 'Nextcloud ile giriş yap';
	@override late final _Translations$login$ncLoginStep$loginFlow$tr loginFlow = _Translations$login$ncLoginStep$loginFlow$tr._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$tr extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => 'Verilerinizi korumak için lütfen şifreleme parolanızı girin:';
	@override String get newToBadNotes => 'BadNotes\'ta yeni misiniz? Yeni bir şifreleme parolası girmeniz yeterli.';
	@override String get encPassword => 'Şifreleme parolası';
	@override String get encFaqTitle => 'Sık sorulan sorular';
	@override String get wrongEncPassword => 'Girilen parolayla şifre çözülemedi. Lütfen yeniden girmeyi deneyin.';
	@override String get connectionFailed => 'Sunucuya bağlanırken bir sorun oluştu. Lütfen daha sonra yeniden deneyin.';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$tr._(_root),
		_Translations$login$encLoginStep$encFaq$1$tr._(_root),
		_Translations$login$encLoginStep$encFaq$2$tr._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$tr extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => 'Sunucu ana sayfası';
	@override String get deleteAccount => 'Hesabı sil';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$tr extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Çıkış yaparsam notlarımı kaybeder miyim?';
	@override String get a => 'Hayır. Notlarınız hem cihazınızda hem de sunucuda kalır. Yeniden giriş yapana kadar sunucuyla eşitlenmezler. Veri kaybetmemek için çıkış yapmadan önce eşitlemenin bittiğinden emin olun (eşitleme durumunu ana ekranda görebilirsiniz).';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$tr extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Notlarım nerede saklanıyor?';
	@override String get a => 'Google Drive\'ınızdaki "BadNotes" klasöründe veya OneDrive\'ınızdaki "Apps/BadNotes" klasöründe. Dosyalar şifrelidir, bu yüzden yalnızca BadNotes\'ta açılabilir.';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$tr extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Şifreleme parolamı nasıl değiştiririm?';
	@override String get a => '0. Eşitlemenin bittiğinden emin olun (eşitleme durumunu ana ekranda görebilirsiniz).\n1. BadNotes\'tan çıkış yapın.\n2. Google Drive veya OneDrive\'ınızdaki \'BadNotes\' klasörünü silin. Bu, tüm notlarınızı cihazınızdan değil, buluttan siler.\n3. BadNotes\'a yeniden giriş yapın. Giriş yaparken yeni bir şifreleme parolası seçebilirsiniz.\n4. Diğer cihazlarınızda da BadNotes\'tan çıkış yapıp yeniden giriş yapmayı unutmayın.';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$tr extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Hesabımı nasıl silebilirim?';
	@override String get a => 'BadNotes\'un kendine ait bir hesabı yoktur. Çıkış yapın, ardından Google Drive veya OneDrive\'ınızdaki \'BadNotes\' klasörünü silin.\nBadNotes\'un erişimini de kaldırmak için myaccount.google.com/permissions (Google) veya account.live.com/consent/Manage (Microsoft) adresine gidin.';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$tr extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => 'Renkleri aç/kapat (Ctrl C)';
	@override String get select => 'Seç';
	@override String get toggleEraser => 'Silgiyi aç/kapat (Ctrl E)';
	@override String get photo => 'Görseller';
	@override String get text => 'Metin';
	@override String get toggleFingerDrawing => 'Parmakla çizimi aç/kapat (Ctrl F)';
	@override String get undo => 'Geri al';
	@override String get redo => 'Yinele';
	@override String get export => 'Dışa aktar (Ctrl Shift S)';
	@override String get exportAs => 'Farklı dışa aktar:';
	@override String get fullscreen => 'Tam ekranı aç/kapat (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$tr extends Translations$editor$pens$en {
	_Translations$editor$pens$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => 'Dolma kalem';
	@override String get ballpointPen => 'Tükenmez kalem';
	@override String get highlighter => 'Fosforlu kalem';
	@override String get pencil => 'Kurşun kalem';
	@override String get shapePen => 'Şekil kalemi';
	@override String get laserPointer => 'Lazer işaretçi';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$tr extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get size => 'Boyut';
}

// Path: editor.colors
class _Translations$editor$colors$tr extends Translations$editor$colors$en {
	_Translations$editor$colors$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => 'Renk seçici';
	@override String customBrightnessHue({required Object b, required Object h}) => 'Özel ${b} ${h}';
	@override String customHue({required Object h}) => 'Özel ${h}';
	@override String get dark => 'koyu';
	@override String get light => 'açık';
	@override String get black => 'Siyah';
	@override String get darkGrey => 'Koyu gri';
	@override String get grey => 'Gri';
	@override String get lightGrey => 'Açık gri';
	@override String get white => 'Beyaz';
	@override String get red => 'Kırmızı';
	@override String get green => 'Yeşil';
	@override String get cyan => 'Camgöbeği';
	@override String get blue => 'Mavi';
	@override String get yellow => 'Sarı';
	@override String get purple => 'Mor';
	@override String get pink => 'Pembe';
	@override String get orange => 'Turuncu';
	@override String get pastelRed => 'Pastel kırmızı';
	@override String get pastelOrange => 'Pastel turuncu';
	@override String get pastelYellow => 'Pastel sarı';
	@override String get pastelGreen => 'Pastel yeşil';
	@override String get pastelCyan => 'Pastel camgöbeği';
	@override String get pastelBlue => 'Pastel mavi';
	@override String get pastelPurple => 'Pastel mor';
	@override String get pastelPink => 'Pastel pembe';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$tr extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Görsel seçenekleri';
	@override String get invertible => 'Ters çevrilebilir';
	@override String get download => 'İndir';
	@override String get setAsBackground => 'Arka plan yap';
	@override String get removeAsBackground => 'Arka plandan kaldır';
	@override String get delete => 'Sil';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$tr extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Sil';
	@override String get duplicate => 'Çoğalt';
}

// Path: editor.menu
class _Translations$editor$menu$tr extends Translations$editor$menu$en {
	_Translations$editor$menu$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => 'Sayfayı temizle ${page}/${totalPages}';
	@override String get clearAllPages => 'Tüm sayfaları temizle';
	@override String get insertPage => 'Alta sayfa ekle';
	@override String get duplicatePage => 'Sayfayı çoğalt';
	@override String get deletePage => 'Sayfayı sil';
	@override String get lineHeight => 'Satır yüksekliği';
	@override String get lineHeightDescription => 'Yazılan notlarda metin boyutunu da belirler';
	@override String get lineThickness => 'Çizgi kalınlığı';
	@override String get lineThicknessDescription => 'Arka plan çizgilerinin kalınlığı';
	@override String get backgroundImageFit => 'Arka plan görseli sığdırma';
	@override String get backgroundPattern => 'Arka plan deseni';
	@override String get import => 'İçe aktar';
	@override String get watchServer => 'Sunucudaki güncellemeleri izle';
	@override String get watchServerReadOnly => 'Sunucu izlenirken düzenleme kapalıdır';
	@override late final _Translations$editor$menu$boxFits$tr boxFits = _Translations$editor$menu$boxFits$tr._(_root);
	@override late final _Translations$editor$menu$bgPatterns$tr bgPatterns = _Translations$editor$menu$bgPatterns$tr._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$tr extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Hata';
	@override String get message => 'PDF dosyaları görsel olarak eklenemez. Bunun için "${_root.editor.menu.import} > PDF" seçeneğini kullanın.';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$tr extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Salt okunur mod';
	@override String get watchingServer => 'Şu anda sunucudaki güncellemeleri izliyorsunuz. Bu modda düzenleme kapalıdır.';
	@override String get corrupted => 'Not yüklenemedi. Bozuk olabilir ya da hâlâ indiriliyor olabilir.';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$tr extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bu not BadNotes\'un daha yeni bir sürümüyle düzenlendi';
	@override String get subtitle => 'Bu notu düzenlemek bazı bilgilerin kaybolmasına yol açabilir. Bunu yok sayıp yine de düzenlemek istiyor musunuz?';
	@override String get allowEditing => 'Düzenlemeye izin ver';
}

// Path: editor.quill
class _Translations$editor$quill$tr extends Translations$editor$quill$en {
	_Translations$editor$quill$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => 'Buraya bir şeyler yazın…';
}

// Path: editor.hud
class _Translations$editor$hud$tr extends Translations$editor$hud$en {
	_Translations$editor$hud$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => 'Yakınlaştırma kilidini aç';
	@override String get lockZoom => 'Yakınlaştırmayı kilitle';
	@override String get unlockSingleFingerPan => 'Tek parmakla kaydırmayı aç';
	@override String get lockSingleFingerPan => 'Tek parmakla kaydırmayı kapat';
	@override String get unlockAxisAlignedPan => 'Yatay veya dikey kaydırma kilidini aç';
	@override String get lockAxisAlignedPan => 'Kaydırmayı yatay veya dikeye kilitle';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$tr extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get question => 'Beklenmeyen hatalar otomatik olarak bildirilsin mi? Bu, sorunları daha hızlı bulup düzeltmeme yardımcı olur.';
	@override String get scope => 'Raporlar hata ve cihazınız hakkında bilgi içerebilir. Kişisel verileri ayıklamak için elimden geleni yaptım, ancak bir kısmı kalabilir.';
	@override String get currentlyOff => 'İzin verirseniz hata bildirimi, uygulamayı yeniden başlattıktan sonra etkinleşir.';
	@override String get currentlyOn => 'İzni geri alırsanız hata bildirimini kapatmak için lütfen uygulamayı yeniden başlatın.';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: 'Ayrıntılar için '),
		link('gizlilik politikasına'),
		const TextSpan(text: ' bakın.'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$tr extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Evet';
	@override String get no => 'Hayır';
	@override String get later => 'Daha sonra sor';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$tr extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get shown => 'Yanlışlıkla açılıp kapanmasını önler';
	@override String get fixedOn => 'Parmakla çizim açık olarak sabitlendi';
	@override String get fixedOff => 'Parmakla çizim kapalı olarak sabitlendi';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$tr extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get active => 'Etkin';
	@override String get inactive => 'Devre dışı';
	@override String get activeUntilRestart => 'Uygulamayı yeniden başlatana kadar etkin';
	@override String get inactiveUntilRestart => 'Uygulamayı yeniden başlatana kadar devre dışı';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$tr extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => 'Lütfen BadNotes\'un Nextcloud hesabınıza erişmesine izin verin';
	@override String get followPrompts => 'Lütfen Nextcloud arayüzündeki adımları izleyin';
	@override String get browserDidntOpen => 'Giriş sayfası açılmadı mı? Buraya tıklayın';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$tr extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Şifreleme parolası nedir? Neden iki parola kullanılıyor?';
	@override String get a => 'Buluta erişmek için Google veya Microsoft hesabınız kullanılır. Şifreleme parolası ise verileriniz buluta ulaşmadan önce onları "karıştırır".\nBiri Google veya Microsoft hesabınıza erişse bile notlarınız ayrı bir parolayla şifrelenmiş ve güvende kalır. Bu, verilerinizi korumak için size ikinci bir güvenlik katmanı sağlar.\nŞifreleme parolanız olmadan kimse sunucudaki notlarınıza erişemez; ancak bu, şifreleme parolanızı unutursanız verilerinize erişiminizi kaybedeceğiniz anlamına da gelir.';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$tr extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Henüz bir şifreleme parolası belirlemedim. Nereden alabilirim?';
	@override String get a => 'Yeni bir şifreleme parolası seçin ve yukarıya girin.\nBadNotes şifreleme anahtarlarınızı bu paroladan otomatik olarak oluşturur.';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$tr extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Google veya Microsoft hesabımla aynı parolayı kullanabilir miyim?';
	@override String get a => 'Lütfen kullanmayın. Ayrı bir şifreleme parolası, biri o hesaba girse bile notlarınızı güvende tutar.';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$tr extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get fill => 'Uzat';
	@override String get cover => 'Kapla';
	@override String get contain => 'Sığdır';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$tr extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$tr._(TranslationsTr root) : this._root = root, super.internal(root);

	final TranslationsTr _root; // ignore: unused_field

	// Translations
	@override String get none => 'Boş';
	@override String get college => 'Dar çizgili';
	@override String get collegeRtl => 'Dar çizgili (Ters)';
	@override String get lined => 'Çizgili';
	@override String get grid => 'Kareli';
	@override String get dots => 'Noktalı';
	@override String get staffs => 'Nota çizgili';
	@override String get tablature => 'Tablatür';
	@override String get cornell => 'Cornell';
}
