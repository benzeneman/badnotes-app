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
class TranslationsAr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <ar>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsAr _root = this; // ignore: unused_field

	@override 
	TranslationsAr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsAr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$ar common = _Translations$common$ar._(_root);
	@override late final _Translations$home$ar home = _Translations$home$ar._(_root);
	@override late final _Translations$sentry$ar sentry = _Translations$sentry$ar._(_root);
	@override late final _Translations$settings$ar settings = _Translations$settings$ar._(_root);
	@override late final _Translations$logs$ar logs = _Translations$logs$ar._(_root);
	@override late final _Translations$login$ar login = _Translations$login$ar._(_root);
	@override late final _Translations$profile$ar profile = _Translations$profile$ar._(_root);
	@override late final _Translations$appInfo$ar appInfo = _Translations$appInfo$ar._(_root);
	@override late final _Translations$update$ar update = _Translations$update$ar._(_root);
	@override late final _Translations$editor$ar editor = _Translations$editor$ar._(_root);
}

// Path: common
class _Translations$common$ar extends Translations$common$en {
	_Translations$common$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get done => 'تم';
	@override String get continueBtn => 'متابعة';
	@override String get cancel => 'إلغاء';
}

// Path: home
class _Translations$home$ar extends Translations$home$en {
	_Translations$home$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$ar tabs = _Translations$home$tabs$ar._(_root);
	@override late final _Translations$home$titles$ar titles = _Translations$home$titles$ar._(_root);
	@override late final _Translations$home$tooltips$ar tooltips = _Translations$home$tooltips$ar._(_root);
	@override late final _Translations$home$create$ar create = _Translations$home$create$ar._(_root);
	@override String get welcome => 'مرحبًا بك في BadNotes';
	@override String get invalidFormat => 'الملف الذي اخترته غير مدعوم. يُرجى اختيار ملف sbn أو sbn2 أو sba أو pdf.';
	@override String get noFiles => 'لا توجد ملفات';
	@override String get noPreviewAvailable => 'لا توجد معاينة';
	@override String get createNewNote => 'اضغط على زر + لإنشاء ملاحظة جديدة';
	@override String get backFolder => 'العودة إلى المجلد السابق';
	@override late final _Translations$home$newFolder$ar newFolder = _Translations$home$newFolder$ar._(_root);
	@override late final _Translations$home$renameNote$ar renameNote = _Translations$home$renameNote$ar._(_root);
	@override late final _Translations$home$moveNote$ar moveNote = _Translations$home$moveNote$ar._(_root);
	@override String get deleteNote => 'حذف الملاحظة';
	@override late final _Translations$home$deleteNoteDialog$ar deleteNoteDialog = _Translations$home$deleteNoteDialog$ar._(_root);
	@override late final _Translations$home$renameFolder$ar renameFolder = _Translations$home$renameFolder$ar._(_root);
	@override late final _Translations$home$deleteFolder$ar deleteFolder = _Translations$home$deleteFolder$ar._(_root);
	@override late final _Translations$home$sort$ar sort = _Translations$home$sort$ar._(_root);
	@override late final _Translations$home$layout$ar layout = _Translations$home$layout$ar._(_root);
}

// Path: sentry
class _Translations$sentry$ar extends Translations$sentry$en {
	_Translations$sentry$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$ar consent = _Translations$sentry$consent$ar._(_root);
}

// Path: settings
class _Translations$settings$ar extends Translations$settings$en {
	_Translations$settings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$ar prefCategories = _Translations$settings$prefCategories$ar._(_root);
	@override late final _Translations$settings$prefLabels$ar prefLabels = _Translations$settings$prefLabels$ar._(_root);
	@override late final _Translations$settings$prefDescriptions$ar prefDescriptions = _Translations$settings$prefDescriptions$ar._(_root);
	@override late final _Translations$settings$themeModes$ar themeModes = _Translations$settings$themeModes$ar._(_root);
	@override late final _Translations$settings$layoutSizes$ar layoutSizes = _Translations$settings$layoutSizes$ar._(_root);
	@override late final _Translations$settings$accentColorPicker$ar accentColorPicker = _Translations$settings$accentColorPicker$ar._(_root);
	@override String get systemLanguage => 'تلقائي';
	@override List<String> get axisDirections => [
		'أعلى',
		'يمين',
		'أسفل',
		'يسار',
	];
	@override late final _Translations$settings$reset$ar reset = _Translations$settings$reset$ar._(_root);
	@override String get resyncEverything => 'إعادة مزامنة الكل';
	@override String get openDataDir => 'فتح مجلد BadNotes';
	@override late final _Translations$settings$customDataDir$ar customDataDir = _Translations$settings$customDataDir$ar._(_root);
	@override String get autosaveDisabled => 'أبدًا';
	@override String get shapeRecognitionDisabled => 'أبدًا';
}

// Path: logs
class _Translations$logs$ar extends Translations$logs$en {
	_Translations$logs$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get logs => 'السجلات';
	@override String get viewLogs => 'عرض السجلات';
	@override String get debuggingInfo => 'تحتوي السجلات على معلومات مفيدة لتصحيح الأخطاء والتطوير';
	@override String get noLogs => 'لا توجد سجلات هنا!';
	@override String get useTheApp => 'ستظهر السجلات هنا أثناء استخدامك للتطبيق';
}

// Path: login
class _Translations$login$ar extends Translations$login$en {
	_Translations$login$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تسجيل الدخول';
	@override late final _Translations$login$form$ar form = _Translations$login$form$ar._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: 'ليس لديك حساب بعد؟ '),
		linkToSignup('أنشئ حسابًا الآن'),
		const TextSpan(text: '!'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: 'لست أنت؟ '),
		undoLogin('اختر حسابًا آخر'),
		const TextSpan(text: '.'),
	]);
	@override late final _Translations$login$status$ar status = _Translations$login$status$ar._(_root);
	@override late final _Translations$login$ncLoginStep$ar ncLoginStep = _Translations$login$ncLoginStep$ar._(_root);
	@override late final _Translations$login$encLoginStep$ar encLoginStep = _Translations$login$encLoginStep$ar._(_root);
}

// Path: profile
class _Translations$profile$ar extends Translations$profile$en {
	_Translations$profile$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'ملفي الشخصي';
	@override String get logout => 'تسجيل الخروج';
	@override String quotaUsage({required Object used, required Object total, required Object percent}) => 'أنت تستخدم ${used} من ${total} (${percent}%)';
	@override String quotaUsageUncapped({required Object used}) => 'أنت تستخدم ${used}';
	@override String get connectedTo => 'متصل بـ';
	@override String lastSynced({required Object time}) => 'آخر مزامنة ${time}';
	@override String get notSyncedYet => 'لم تتم المزامنة بعد';
	@override String get justNow => 'الآن';
	@override String minutesAgo({required Object n}) => 'منذ ${n} د';
	@override String hoursAgo({required Object n}) => 'منذ ${n} س';
	@override String filesWaiting({required Object n}) => '${n} ملفات بانتظار المزامنة';
	@override String get signInAgainNeeded => 'سجّل الدخول مجددًا لمتابعة المزامنة';
	@override String get signInAgain => 'تسجيل الدخول مجددًا';
	@override String wrongAccount({required Object email}) => 'يُرجى اختيار ${email}';
	@override late final _Translations$profile$quickLinks$ar quickLinks = _Translations$profile$quickLinks$ar._(_root);
	@override String get faqTitle => 'الأسئلة الشائعة';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$ar._(_root),
		_Translations$profile$faq$1$ar._(_root),
		_Translations$profile$faq$2$ar._(_root),
		_Translations$profile$faq$3$ar._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$ar extends Translations$appInfo$en {
	_Translations$appInfo$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get debug => 'DEBUG';
}

// Path: update
class _Translations$update$ar extends Translations$update$en {
	_Translations$update$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => 'يتوفر تحديث';
	@override String get updateAvailableDescription => 'يتوفر إصدار جديد من التطبيق:';
	@override String get update => 'تحديث';
	@override String get downloadNotAvailableYet => 'التنزيل غير متاح بعد لمنصتك. يُرجى التحقق مرة أخرى قريبًا.';
}

// Path: editor
class _Translations$editor$ar extends Translations$editor$en {
	_Translations$editor$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$ar toolbar = _Translations$editor$toolbar$ar._(_root);
	@override late final _Translations$editor$pens$ar pens = _Translations$editor$pens$ar._(_root);
	@override late final _Translations$editor$penOptions$ar penOptions = _Translations$editor$penOptions$ar._(_root);
	@override late final _Translations$editor$colors$ar colors = _Translations$editor$colors$ar._(_root);
	@override late final _Translations$editor$imageOptions$ar imageOptions = _Translations$editor$imageOptions$ar._(_root);
	@override late final _Translations$editor$selectionBar$ar selectionBar = _Translations$editor$selectionBar$ar._(_root);
	@override late final _Translations$editor$menu$ar menu = _Translations$editor$menu$ar._(_root);
	@override late final _Translations$editor$photoPdfError$ar photoPdfError = _Translations$editor$photoPdfError$ar._(_root);
	@override late final _Translations$editor$readOnlyBanner$ar readOnlyBanner = _Translations$editor$readOnlyBanner$ar._(_root);
	@override late final _Translations$editor$versionTooNew$ar versionTooNew = _Translations$editor$versionTooNew$ar._(_root);
	@override late final _Translations$editor$quill$ar quill = _Translations$editor$quill$ar._(_root);
	@override late final _Translations$editor$hud$ar hud = _Translations$editor$hud$ar._(_root);
	@override String get pages => 'الصفحات';
	@override String get untitled => 'بلا عنوان';
	@override String get needsToSaveBeforeExiting => 'جارٍ حفظ التغييرات… يمكنك الخروج من المحرر بأمان عند الانتهاء';
}

// Path: home.tabs
class _Translations$home$tabs$ar extends Translations$home$tabs$en {
	_Translations$home$tabs$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get home => 'الرئيسية';
	@override String get browse => 'تصفح';
	@override String get whiteboard => 'السبورة';
	@override String get settings => 'الإعدادات';
}

// Path: home.titles
class _Translations$home$titles$ar extends Translations$home$titles$en {
	_Translations$home$titles$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get home => 'الملاحظات الأخيرة';
	@override String get browse => 'تصفح';
	@override String get whiteboard => 'السبورة';
	@override String get settings => 'الإعدادات';
}

// Path: home.tooltips
class _Translations$home$tooltips$ar extends Translations$home$tooltips$en {
	_Translations$home$tooltips$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'ملاحظة جديدة';
	@override String get showUpdateDialog => 'عرض نافذة التحديث';
	@override String get exportNote => 'تصدير الملاحظة';
}

// Path: home.create
class _Translations$home$create$ar extends Translations$home$create$en {
	_Translations$home$create$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'ملاحظة جديدة';
	@override String get importNote => 'استيراد ملاحظة';
}

// Path: home.newFolder
class _Translations$home$newFolder$ar extends Translations$home$newFolder$en {
	_Translations$home$newFolder$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get newFolder => 'مجلد جديد';
	@override String get folderName => 'اسم المجلد';
	@override String get create => 'إنشاء';
	@override String get folderNameEmpty => 'لا يمكن ترك اسم المجلد فارغًا';
	@override String get folderNameContainsSlash => 'لا يمكن أن يحتوي اسم المجلد على شرطة مائلة';
	@override String get folderNameExists => 'المجلد موجود بالفعل';
}

// Path: home.renameNote
class _Translations$home$renameNote$ar extends Translations$home$renameNote$en {
	_Translations$home$renameNote$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get renameNote => 'إعادة تسمية الملاحظة';
	@override String get noteName => 'اسم الملاحظة';
	@override String get rename => 'إعادة تسمية';
	@override String get noteNameEmpty => 'لا يمكن ترك اسم الملاحظة فارغًا';
	@override String get noteNameExists => 'توجد ملاحظة بهذا الاسم بالفعل';
	@override String get noteNameForbiddenCharacters => 'يحتوي اسم الملاحظة على أحرف غير مسموح بها';
	@override String get noteNameReserved => 'اسم الملاحظة محجوز';
}

// Path: home.moveNote
class _Translations$home$moveNote$ar extends Translations$home$moveNote$en {
	_Translations$home$moveNote$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get moveNote => 'نقل الملاحظة';
	@override String moveNotes({required Object n}) => 'نقل ${n} ملاحظات';
	@override String moveName({required Object f}) => 'نقل ${f}';
	@override String get move => 'نقل';
	@override String renamedTo({required Object newName}) => 'ستُعاد تسمية الملاحظة إلى ${newName}';
	@override String get multipleRenamedTo => 'ستُعاد تسمية الملاحظات التالية:';
	@override String numberRenamedTo({required Object n}) => 'ستُعاد تسمية ${n} ملاحظات لتجنب التعارض';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$ar extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => 'حذف ${n} ملاحظات';
	@override String deleteName({required Object f}) => 'حذف ${f}';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'هل تريد حذف الملاحظة المحددة نهائيًا؟',
		other: 'هل تريد حذف الملاحظات المحددة نهائيًا؟',
	);
	@override String get delete => 'حذف';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$ar extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => 'إعادة تسمية المجلد';
	@override String get folderName => 'اسم المجلد';
	@override String get rename => 'إعادة تسمية';
	@override String get folderNameEmpty => 'لا يمكن ترك اسم المجلد فارغًا';
	@override String get folderNameContainsSlash => 'لا يمكن أن يحتوي اسم المجلد على شرطة مائلة';
	@override String get folderNameExists => 'يوجد مجلد بهذا الاسم بالفعل';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$ar extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => 'حذف المجلد';
	@override String deleteName({required Object f}) => 'حذف ${f}';
	@override String get delete => 'حذف';
	@override String get alsoDeleteContents => 'حذف جميع الملاحظات داخل هذا المجلد أيضًا';
}

// Path: home.sort
class _Translations$home$sort$ar extends Translations$home$sort$en {
	_Translations$home$sort$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get sortBy => 'ترتيب حسب';
	@override String get nameAToZ => 'الاسم (أ-ي)';
	@override String get nameZToA => 'الاسم (ي-أ)';
	@override String get lastModifiedNewToOld => 'التعديل (الأحدث أولًا)';
	@override String get lastModifiedOldToNew => 'التعديل (الأقدم أولًا)';
}

// Path: home.layout
class _Translations$home$layout$ar extends Translations$home$layout$en {
	_Translations$home$layout$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get layout => 'التخطيط';
	@override String get masonryGrid => 'شبكة متدرجة';
	@override String get simpleGrid => 'شبكة بسيطة';
}

// Path: sentry.consent
class _Translations$sentry$consent$ar extends Translations$sentry$consent$en {
	_Translations$sentry$consent$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'هل تساعد في تحسين BadNotes؟';
	@override late final _Translations$sentry$consent$description$ar description = _Translations$sentry$consent$description$ar._(_root);
	@override late final _Translations$sentry$consent$answers$ar answers = _Translations$sentry$consent$answers$ar._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$ar extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get general => 'عام';
	@override String get writing => 'الكتابة';
	@override String get editor => 'المحرر';
	@override String get performance => 'الأداء';
	@override String get advanced => 'متقدم';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$ar extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get locale => 'اللغة';
	@override String get appTheme => 'سمة التطبيق';
	@override String get platform => 'نوع السمة';
	@override String get layoutSize => 'نوع التخطيط';
	@override String get customAccentColor => 'لون مميز مخصص';
	@override String get hyperlegibleFont => 'خط Atkinson Hyperlegible';
	@override String get shouldCheckForUpdates => 'التحقق من تحديثات BadNotes';
	@override String get shouldAlwaysAlertForUpdates => 'تحديثات أسرع';
	@override String get allowInsecureConnections => 'السماح بالاتصالات غير الآمنة';
	@override String get syncOnlyOnWifi => 'المزامنة عبر Wi-Fi فقط';
	@override String get syncPreviewsOnMobileData => 'رفع المعاينات عبر بيانات الجوال';
	@override String get editorToolbarAlignment => 'موضع شريط الأدوات';
	@override String get editorToolbarShowInFullscreen => 'إظهار شريط الأدوات في وضع ملء الشاشة';
	@override String get editorAutoInvert => 'عكس ألوان الملاحظات في الوضع الداكن';
	@override String get preferGreyscale => 'تفضيل الألوان الرمادية';
	@override String get maxImageSize => 'الحد الأقصى لحجم الصورة';
	@override String get autoClearWhiteboardOnExit => 'مسح السبورة تلقائيًا';
	@override String get disableEraserAfterUse => 'إيقاف الممحاة تلقائيًا';
	@override String get hideFingerDrawingToggle => 'إخفاء مفتاح الرسم بالإصبع';
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'إيقاف الرسم بالإصبع تلقائيًا';
	@override String get editorPromptRename => 'مطالبتك بتسمية الملاحظات الجديدة';
	@override String get recentColorsDontSavePresets => 'عدم حفظ الألوان الجاهزة في الألوان الأخيرة';
	@override String get recentColorsLength => 'عدد الألوان الأخيرة المحفوظة';
	@override String get printPageIndicators => 'طباعة أرقام الصفحات';
	@override String get autosave => 'الحفظ التلقائي';
	@override String get shapeRecognitionDelay => 'مهلة التعرف على الأشكال';
	@override String get autoStraightenLines => 'تقويم الخطوط تلقائيًا';
	@override String get customDataDir => 'مجلد BadNotes مخصص';
	@override String get sentry => 'الإبلاغ عن الأخطاء';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$ar extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => 'معطّل: تُزامَن الملاحظات عبر بيانات الجوال أيضًا. مفعّل: تنتظر المزامنة شبكة Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'تنتظر الصور المصغرة للملاحظات عادةً شبكة Wi-Fi لتوفير البيانات';
	@override String get hyperlegibleFont => 'يُحسّن وضوح القراءة لضعاف البصر';
	@override String get allowInsecureConnections => '(غير مستحسن) السماح لـ BadNotes بالاتصال بخوادم ذات شهادات موقعة ذاتيًا أو غير موثوقة';
	@override String get preferGreyscale => 'لشاشات الحبر الإلكتروني';
	@override String get autoClearWhiteboardOnExit => 'يمسح السبورة بعد الخروج من التطبيق';
	@override String get disableEraserAfterUse => 'يعود تلقائيًا إلى القلم بعد استخدام الممحاة';
	@override String get maxImageSize => 'ستُضغط الصور الأكبر من ذلك';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$ar hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$ar._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'إيقاف الرسم بالإصبع عند اكتشاف قلم';
	@override String get editorPromptRename => 'يمكنك دائمًا إعادة تسمية الملاحظات لاحقًا';
	@override String get printPageIndicators => 'إظهار أرقام الصفحات في الملفات المصدّرة';
	@override String get autosave => 'الحفظ التلقائي بعد مهلة قصيرة، أو عدم الحفظ أبدًا';
	@override String get shapeRecognitionDelay => 'مدة تثبيت القلم قبل أن يتحول الحبر إلى شكل';
	@override String get autoStraightenLines => 'يقوّم الخطوط الطويلة دون الحاجة إلى قلم الأشكال';
	@override String get shouldAlwaysAlertForUpdates => 'أبلغني بالتحديثات فور توفرها';
	@override late final _Translations$settings$prefDescriptions$sentry$ar sentry = _Translations$settings$prefDescriptions$sentry$ar._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$ar extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get system => 'النظام';
	@override String get light => 'فاتح';
	@override String get dark => 'داكن';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$ar extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get auto => 'تلقائي';
	@override String get phone => 'هاتف';
	@override String get tablet => 'جهاز لوحي';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$ar extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => 'اختر لونًا';
}

// Path: settings.reset
class _Translations$settings$reset$ar extends Translations$settings$reset$en {
	_Translations$settings$reset$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إعادة تعيين هذا الإعداد؟';
	@override String get button => 'إعادة تعيين';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$ar extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'إلغاء';
	@override String get select => 'اختيار';
	@override String get mustBeEmpty => 'يجب أن يكون المجلد المحدد فارغًا';
	@override String get mustBeDoneSyncing => 'تأكد من اكتمال المزامنة قبل تغيير المجلد';
	@override String get unsupported => 'هذه الميزة مخصصة للمطورين حاليًا. استخدامها قد يؤدي على الأرجح إلى فقدان البيانات.';
}

// Path: login.form
class _Translations$login$form$ar extends Translations$login$form$en {
	_Translations$login$form$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'بتسجيل الدخول، فإنك توافق على '),
		linkToPrivacyPolicy('سياسة الخصوصية'),
		const TextSpan(text: '.'),
	]);
}

// Path: login.status
class _Translations$login$status$ar extends Translations$login$status$en {
	_Translations$login$status$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => 'تم تسجيل الخروج';
	@override String get tapToLogin => 'اضغط للمزامنة مع Google Drive';
	@override String hi({required Object u}) => 'مرحبًا، ${u}!';
	@override String get almostDone => 'المزامنة على وشك الجاهزية، اضغط لإكمال تسجيل الدخول';
	@override String get loggedIn => 'المزامنة مفعّلة';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$ar extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => 'اختر مكان تخزين بياناتك:';
	@override String get cloudStorage => 'Google Drive أو OneDrive';
	@override String get loginWithGoogleDrive => 'المتابعة باستخدام Google Drive';
	@override String get loginWithOneDrive => 'المتابعة باستخدام OneDrive';
	@override String get cloudLoginFailed => 'تعذّر تسجيل الدخول';
	@override String get comingSoon => 'قريبًا';
	@override String get badnotesNcServer => 'خادم Nextcloud الخاص بـ BadNotes';
	@override String get otherNcServer => 'خادم Nextcloud آخر';
	@override String get serverUrl => 'عنوان URL للخادم';
	@override String get loginWithBadNotes => 'تسجيل الدخول باستخدام BadNotes';
	@override String get loginWithNextcloud => 'تسجيل الدخول باستخدام Nextcloud';
	@override late final _Translations$login$ncLoginStep$loginFlow$ar loginFlow = _Translations$login$ncLoginStep$loginFlow$ar._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$ar extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => 'لحماية بياناتك، يُرجى إدخال كلمة مرور التشفير:';
	@override String get newToBadNotes => 'جديد على BadNotes؟ ما عليك سوى إدخال كلمة مرور تشفير جديدة.';
	@override String get encPassword => 'كلمة مرور التشفير';
	@override String get encFaqTitle => 'الأسئلة الشائعة';
	@override String get wrongEncPassword => 'فشل فك التشفير بكلمة المرور المُدخلة. يُرجى المحاولة مرة أخرى.';
	@override String get connectionFailed => 'حدث خطأ أثناء الاتصال بالخادم. يُرجى المحاولة لاحقًا.';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$ar._(_root),
		_Translations$login$encLoginStep$encFaq$1$ar._(_root),
		_Translations$login$encLoginStep$encFaq$2$ar._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$ar extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => 'الصفحة الرئيسية للخادم';
	@override String get deleteAccount => 'حذف الحساب';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$ar extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get q => 'هل سأفقد ملاحظاتي إذا سجّلت الخروج؟';
	@override String get a => 'لا. ستبقى ملاحظاتك على جهازك وعلى الخادم معًا، لكنها لن تُزامَن مع الخادم حتى تسجّل الدخول مجددًا. تأكد من اكتمال المزامنة قبل تسجيل الخروج حتى لا تفقد أي بيانات (راجع تقدم المزامنة في الشاشة الرئيسية).';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$ar extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get q => 'أين تُخزَّن ملاحظاتي؟';
	@override String get a => 'في مجلد "BadNotes" على Google Drive، أو "Apps/BadNotes" على OneDrive. الملفات مشفرة، لذا لا يمكن فتحها إلا في BadNotes.';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$ar extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get q => 'كيف أغيّر كلمة مرور التشفير؟';
	@override String get a => '0. تأكد من اكتمال المزامنة (راجع تقدم المزامنة في الشاشة الرئيسية).\n1. سجّل الخروج من BadNotes.\n2. احذف مجلد \'BadNotes\' من Google Drive أو OneDrive. هذا يحذف جميع ملاحظاتك من السحابة، وليس من جهازك.\n3. سجّل الدخول مجددًا إلى BadNotes. يمكنك اختيار كلمة مرور تشفير جديدة أثناء تسجيل الدخول.\n4. لا تنسَ تسجيل الخروج ثم الدخول مجددًا إلى BadNotes على أجهزتك الأخرى أيضًا.';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$ar extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get q => 'كيف يمكنني حذف حسابي؟';
	@override String get a => 'ليس لدى BadNotes حساب خاص به. سجّل الخروج، ثم احذف مجلد \'BadNotes\' من Google Drive أو OneDrive.\nولإلغاء وصول BadNotes أيضًا، انتقل إلى myaccount.google.com/permissions (Google) أو account.live.com/consent/Manage (Microsoft).';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$ar extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => 'تبديل الألوان (Ctrl C)';
	@override String get select => 'تحديد';
	@override String get toggleEraser => 'تبديل الممحاة (Ctrl E)';
	@override String get photo => 'الصور';
	@override String get text => 'نص';
	@override String get toggleFingerDrawing => 'تبديل الرسم بالإصبع (Ctrl F)';
	@override String get undo => 'تراجع';
	@override String get redo => 'إعادة';
	@override String get export => 'تصدير (Ctrl Shift S)';
	@override String get exportAs => 'تصدير بصيغة:';
	@override String get fullscreen => 'تبديل ملء الشاشة (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$ar extends Translations$editor$pens$en {
	_Translations$editor$pens$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => 'قلم حبر';
	@override String get ballpointPen => 'قلم جاف';
	@override String get highlighter => 'قلم تمييز';
	@override String get pencil => 'قلم رصاص';
	@override String get shapePen => 'قلم الأشكال';
	@override String get laserPointer => 'مؤشر ليزر';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$ar extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get size => 'الحجم';
}

// Path: editor.colors
class _Translations$editor$colors$ar extends Translations$editor$colors$en {
	_Translations$editor$colors$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => 'منتقي الألوان';
	@override String customBrightnessHue({required Object h, required Object b}) => '${h} ${b} مخصص';
	@override String customHue({required Object h}) => '${h} مخصص';
	@override String get dark => 'داكن';
	@override String get light => 'فاتح';
	@override String get black => 'أسود';
	@override String get darkGrey => 'رمادي داكن';
	@override String get grey => 'رمادي';
	@override String get lightGrey => 'رمادي فاتح';
	@override String get white => 'أبيض';
	@override String get red => 'أحمر';
	@override String get green => 'أخضر';
	@override String get cyan => 'سماوي';
	@override String get blue => 'أزرق';
	@override String get yellow => 'أصفر';
	@override String get purple => 'بنفسجي';
	@override String get pink => 'وردي';
	@override String get orange => 'برتقالي';
	@override String get pastelRed => 'أحمر باستيل';
	@override String get pastelOrange => 'برتقالي باستيل';
	@override String get pastelYellow => 'أصفر باستيل';
	@override String get pastelGreen => 'أخضر باستيل';
	@override String get pastelCyan => 'سماوي باستيل';
	@override String get pastelBlue => 'أزرق باستيل';
	@override String get pastelPurple => 'بنفسجي باستيل';
	@override String get pastelPink => 'وردي باستيل';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$ar extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'خيارات الصورة';
	@override String get invertible => 'قابلة لعكس الألوان';
	@override String get download => 'تنزيل';
	@override String get setAsBackground => 'تعيين كخلفية';
	@override String get removeAsBackground => 'إزالة من الخلفية';
	@override String get delete => 'حذف';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$ar extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get delete => 'حذف';
	@override String get duplicate => 'تكرار';
}

// Path: editor.menu
class _Translations$editor$menu$ar extends Translations$editor$menu$en {
	_Translations$editor$menu$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => 'مسح الصفحة ${page}/${totalPages}';
	@override String get clearAllPages => 'مسح كل الصفحات';
	@override String get insertPage => 'إدراج صفحة أسفلها';
	@override String get duplicatePage => 'تكرار الصفحة';
	@override String get deletePage => 'حذف الصفحة';
	@override String get lineHeight => 'ارتفاع السطر';
	@override String get lineHeightDescription => 'يتحكم أيضًا في حجم النص في الملاحظات المكتوبة';
	@override String get lineThickness => 'سُمك الخط';
	@override String get lineThicknessDescription => 'سُمك خطوط الخلفية';
	@override String get backgroundImageFit => 'ملاءمة صورة الخلفية';
	@override String get backgroundPattern => 'نمط الخلفية';
	@override String get import => 'استيراد';
	@override String get watchServer => 'مراقبة التحديثات على الخادم';
	@override String get watchServerReadOnly => 'التحرير معطّل أثناء مراقبة الخادم';
	@override late final _Translations$editor$menu$boxFits$ar boxFits = _Translations$editor$menu$boxFits$ar._(_root);
	@override late final _Translations$editor$menu$bgPatterns$ar bgPatterns = _Translations$editor$menu$bgPatterns$ar._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$ar extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'خطأ';
	@override String get message => 'لا يمكن إضافة ملفات PDF كصورة. استخدم "${_root.editor.menu.import} > PDF" لذلك.';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$ar extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'وضع القراءة فقط';
	@override String get watchingServer => 'أنت تراقب التحديثات على الخادم حاليًا. التحرير معطّل في هذا الوضع.';
	@override String get corrupted => 'تعذّر تحميل الملاحظة. قد تكون تالفة أو لا يزال تنزيلها جاريًا.';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$ar extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عُدّلت هذه الملاحظة بإصدار أحدث من BadNotes';
	@override String get subtitle => 'قد يؤدي تحرير هذه الملاحظة إلى فقدان بعض المعلومات. هل تريد تجاهل ذلك وتحريرها على أي حال؟';
	@override String get allowEditing => 'السماح بالتحرير';
}

// Path: editor.quill
class _Translations$editor$quill$ar extends Translations$editor$quill$en {
	_Translations$editor$quill$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => 'اكتب شيئًا هنا…';
}

// Path: editor.hud
class _Translations$editor$hud$ar extends Translations$editor$hud$en {
	_Translations$editor$hud$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => 'إلغاء قفل التكبير';
	@override String get lockZoom => 'قفل التكبير';
	@override String get unlockSingleFingerPan => 'تفعيل التحريك بإصبع واحد';
	@override String get lockSingleFingerPan => 'تعطيل التحريك بإصبع واحد';
	@override String get unlockAxisAlignedPan => 'إلغاء تقييد التحريك أفقيًا أو عموديًا';
	@override String get lockAxisAlignedPan => 'تقييد التحريك أفقيًا أو عموديًا';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$ar extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get question => 'هل تريد الإبلاغ تلقائيًا عن الأخطاء غير المتوقعة؟ هذا يساعدني على اكتشاف المشكلات وإصلاحها بشكل أسرع.';
	@override String get scope => 'قد تحتوي التقارير على معلومات عن الخطأ وعن جهازك. بذلتُ كل جهد لاستبعاد البيانات الشخصية، لكن قد يبقى بعضها.';
	@override String get currentlyOff => 'إذا منحت موافقتك، فسيُفعَّل الإبلاغ عن الأخطاء بعد إعادة تشغيل التطبيق.';
	@override String get currentlyOn => 'إذا سحبت موافقتك، فيُرجى إعادة تشغيل التطبيق لإيقاف الإبلاغ عن الأخطاء.';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: 'اعرف المزيد في '),
		link('سياسة الخصوصية'),
		const TextSpan(text: '.'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$ar extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get yes => 'نعم';
	@override String get no => 'لا';
	@override String get later => 'اسألني لاحقًا';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$ar extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get shown => 'يمنع التبديل غير المقصود';
	@override String get fixedOn => 'الرسم بالإصبع مفعّل دائمًا';
	@override String get fixedOff => 'الرسم بالإصبع معطّل دائمًا';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$ar extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get active => 'نشط';
	@override String get inactive => 'غير نشط';
	@override String get activeUntilRestart => 'نشط حتى إعادة تشغيل التطبيق';
	@override String get inactiveUntilRestart => 'غير نشط حتى إعادة تشغيل التطبيق';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$ar extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => 'يُرجى السماح لـ BadNotes بالوصول إلى حسابك على Nextcloud';
	@override String get followPrompts => 'يُرجى اتباع التعليمات في واجهة Nextcloud';
	@override String get browserDidntOpen => 'لم تُفتح صفحة تسجيل الدخول؟ اضغط هنا';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$ar extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get q => 'ما كلمة مرور التشفير؟ ولماذا كلمتا مرور؟';
	@override String get a => 'يُستخدم حسابك على Google أو Microsoft للوصول إلى السحابة. أما كلمة مرور التشفير فتُشفّر بياناتك قبل أن تصل إلى السحابة.\nحتى لو تمكّن أحد من الوصول إلى حسابك على Google أو Microsoft، ستبقى ملاحظاتك آمنة ومشفرة بكلمة مرور منفصلة. وهذا يمنحك طبقة حماية ثانية لبياناتك.\nلا يستطيع أحد الوصول إلى ملاحظاتك على الخادم دون كلمة مرور التشفير، لكن هذا يعني أيضًا أنك إذا نسيتها فستفقد الوصول إلى بياناتك.';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$ar extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get q => 'لم أُعيّن كلمة مرور تشفير بعد. من أين أحصل عليها؟';
	@override String get a => 'اختر كلمة مرور تشفير جديدة وأدخلها أعلاه.\nسيُنشئ BadNotes مفاتيح التشفير من كلمة المرور هذه تلقائيًا.';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$ar extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get q => 'هل يمكنني استخدام كلمة مرور حسابي على Google أو Microsoft نفسها؟';
	@override String get a => 'يُرجى عدم ذلك. كلمة مرور تشفير منفصلة تحافظ على أمان ملاحظاتك حتى لو تمكّن أحد من الدخول إلى ذلك الحساب.';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$ar extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get fill => 'تمديد';
	@override String get cover => 'تغطية';
	@override String get contain => 'احتواء';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$ar extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get none => 'فارغ';
	@override String get college => 'مسطّر جامعي';
	@override String get collegeRtl => 'مسطّر جامعي (معكوس)';
	@override String get lined => 'مسطّر';
	@override String get grid => 'شبكة';
	@override String get dots => 'نقاط';
	@override String get staffs => 'مدرّج موسيقي';
	@override String get tablature => 'تابلاتشر';
	@override String get cornell => 'كورنيل';
}
