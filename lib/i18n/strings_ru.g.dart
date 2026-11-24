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
class TranslationsRu extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <ru>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsRu _root = this; // ignore: unused_field

	@override 
	TranslationsRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRu(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$ru common = _Translations$common$ru._(_root);
	@override late final _Translations$home$ru home = _Translations$home$ru._(_root);
	@override late final _Translations$sentry$ru sentry = _Translations$sentry$ru._(_root);
	@override late final _Translations$settings$ru settings = _Translations$settings$ru._(_root);
	@override late final _Translations$logs$ru logs = _Translations$logs$ru._(_root);
	@override late final _Translations$login$ru login = _Translations$login$ru._(_root);
	@override late final _Translations$profile$ru profile = _Translations$profile$ru._(_root);
	@override late final _Translations$appInfo$ru appInfo = _Translations$appInfo$ru._(_root);
	@override late final _Translations$update$ru update = _Translations$update$ru._(_root);
	@override late final _Translations$editor$ru editor = _Translations$editor$ru._(_root);
}

// Path: common
class _Translations$common$ru extends Translations$common$en {
	_Translations$common$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get done => 'Готово';
	@override String get continueBtn => 'Продолжить';
	@override String get cancel => 'Отмена';
}

// Path: home
class _Translations$home$ru extends Translations$home$en {
	_Translations$home$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$ru tabs = _Translations$home$tabs$ru._(_root);
	@override late final _Translations$home$titles$ru titles = _Translations$home$titles$ru._(_root);
	@override late final _Translations$home$tooltips$ru tooltips = _Translations$home$tooltips$ru._(_root);
	@override late final _Translations$home$create$ru create = _Translations$home$create$ru._(_root);
	@override String get welcome => 'Добро пожаловать в BadNotes';
	@override String get invalidFormat => 'Выбранный файл не поддерживается. Выберите файл sbn, sbn2, sba или pdf.';
	@override String get noFiles => 'Файлы не найдены';
	@override String get noPreviewAvailable => 'Предпросмотр недоступен';
	@override String get createNewNote => 'Нажмите +, чтобы создать заметку';
	@override String get backFolder => 'Вернуться в предыдущую папку';
	@override late final _Translations$home$newFolder$ru newFolder = _Translations$home$newFolder$ru._(_root);
	@override late final _Translations$home$renameNote$ru renameNote = _Translations$home$renameNote$ru._(_root);
	@override late final _Translations$home$moveNote$ru moveNote = _Translations$home$moveNote$ru._(_root);
	@override String get deleteNote => 'Удалить заметку';
	@override late final _Translations$home$deleteNoteDialog$ru deleteNoteDialog = _Translations$home$deleteNoteDialog$ru._(_root);
	@override late final _Translations$home$renameFolder$ru renameFolder = _Translations$home$renameFolder$ru._(_root);
	@override late final _Translations$home$deleteFolder$ru deleteFolder = _Translations$home$deleteFolder$ru._(_root);
	@override late final _Translations$home$sort$ru sort = _Translations$home$sort$ru._(_root);
	@override late final _Translations$home$layout$ru layout = _Translations$home$layout$ru._(_root);
}

// Path: sentry
class _Translations$sentry$ru extends Translations$sentry$en {
	_Translations$sentry$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$ru consent = _Translations$sentry$consent$ru._(_root);
}

// Path: settings
class _Translations$settings$ru extends Translations$settings$en {
	_Translations$settings$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$ru prefCategories = _Translations$settings$prefCategories$ru._(_root);
	@override late final _Translations$settings$prefLabels$ru prefLabels = _Translations$settings$prefLabels$ru._(_root);
	@override late final _Translations$settings$prefDescriptions$ru prefDescriptions = _Translations$settings$prefDescriptions$ru._(_root);
	@override late final _Translations$settings$themeModes$ru themeModes = _Translations$settings$themeModes$ru._(_root);
	@override late final _Translations$settings$layoutSizes$ru layoutSizes = _Translations$settings$layoutSizes$ru._(_root);
	@override late final _Translations$settings$accentColorPicker$ru accentColorPicker = _Translations$settings$accentColorPicker$ru._(_root);
	@override String get systemLanguage => 'Авто';
	@override List<String> get axisDirections => [
		'Сверху',
		'Справа',
		'Снизу',
		'Слева',
	];
	@override late final _Translations$settings$reset$ru reset = _Translations$settings$reset$ru._(_root);
	@override String get resyncEverything => 'Синхронизировать всё заново';
	@override String get openDataDir => 'Открыть папку BadNotes';
	@override late final _Translations$settings$customDataDir$ru customDataDir = _Translations$settings$customDataDir$ru._(_root);
	@override String get autosaveDisabled => 'Никогда';
	@override String get shapeRecognitionDisabled => 'Никогда';
}

// Path: logs
class _Translations$logs$ru extends Translations$logs$en {
	_Translations$logs$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get logs => 'Журнал';
	@override String get viewLogs => 'Открыть журнал';
	@override String get debuggingInfo => 'Журнал содержит сведения, полезные для отладки и разработки';
	@override String get noLogs => 'Записей нет!';
	@override String get useTheApp => 'Записи появятся здесь по мере использования приложения';
}

// Path: login
class _Translations$login$ru extends Translations$login$en {
	_Translations$login$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Вход';
	@override late final _Translations$login$form$ru form = _Translations$login$form$ru._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: 'Ещё нет аккаунта? '),
		linkToSignup('Зарегистрируйтесь'),
		const TextSpan(text: '!'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: 'Это не вы? '),
		undoLogin('Выберите другой аккаунт'),
		const TextSpan(text: '.'),
	]);
	@override late final _Translations$login$status$ru status = _Translations$login$status$ru._(_root);
	@override late final _Translations$login$ncLoginStep$ru ncLoginStep = _Translations$login$ncLoginStep$ru._(_root);
	@override late final _Translations$login$encLoginStep$ru encLoginStep = _Translations$login$encLoginStep$ru._(_root);
}

// Path: profile
class _Translations$profile$ru extends Translations$profile$en {
	_Translations$profile$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Мой профиль';
	@override String get logout => 'Выйти';
	@override String quotaUsage({required Object used, required Object total, required Object percent}) => 'Использовано ${used} из ${total} (${percent}%)';
	@override String quotaUsageUncapped({required Object used}) => 'Использовано ${used}';
	@override String get connectedTo => 'Подключено к';
	@override String lastSynced({required Object time}) => 'Синхронизировано ${time}';
	@override String get notSyncedYet => 'Ещё не синхронизировано';
	@override String get justNow => 'только что';
	@override String minutesAgo({required Object n}) => '${n} мин назад';
	@override String hoursAgo({required Object n}) => '${n} ч назад';
	@override String filesWaiting({required Object n}) => 'Файлов ожидает синхронизации: ${n}';
	@override String get signInAgainNeeded => 'Войдите снова, чтобы продолжить синхронизацию';
	@override String get signInAgain => 'Войти снова';
	@override String wrongAccount({required Object email}) => 'Выберите ${email}';
	@override late final _Translations$profile$quickLinks$ru quickLinks = _Translations$profile$quickLinks$ru._(_root);
	@override String get faqTitle => 'Частые вопросы';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$ru._(_root),
		_Translations$profile$faq$1$ru._(_root),
		_Translations$profile$faq$2$ru._(_root),
		_Translations$profile$faq$3$ru._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$ru extends Translations$appInfo$en {
	_Translations$appInfo$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get debug => 'DEBUG';
}

// Path: update
class _Translations$update$ru extends Translations$update$en {
	_Translations$update$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => 'Доступно обновление';
	@override String get updateAvailableDescription => 'Доступна новая версия приложения:';
	@override String get update => 'Обновить';
	@override String get downloadNotAvailableYet => 'Загрузка для вашей платформы пока недоступна. Загляните чуть позже.';
}

// Path: editor
class _Translations$editor$ru extends Translations$editor$en {
	_Translations$editor$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$ru toolbar = _Translations$editor$toolbar$ru._(_root);
	@override late final _Translations$editor$pens$ru pens = _Translations$editor$pens$ru._(_root);
	@override late final _Translations$editor$penOptions$ru penOptions = _Translations$editor$penOptions$ru._(_root);
	@override late final _Translations$editor$colors$ru colors = _Translations$editor$colors$ru._(_root);
	@override late final _Translations$editor$imageOptions$ru imageOptions = _Translations$editor$imageOptions$ru._(_root);
	@override late final _Translations$editor$selectionBar$ru selectionBar = _Translations$editor$selectionBar$ru._(_root);
	@override late final _Translations$editor$menu$ru menu = _Translations$editor$menu$ru._(_root);
	@override late final _Translations$editor$photoPdfError$ru photoPdfError = _Translations$editor$photoPdfError$ru._(_root);
	@override late final _Translations$editor$readOnlyBanner$ru readOnlyBanner = _Translations$editor$readOnlyBanner$ru._(_root);
	@override late final _Translations$editor$versionTooNew$ru versionTooNew = _Translations$editor$versionTooNew$ru._(_root);
	@override late final _Translations$editor$quill$ru quill = _Translations$editor$quill$ru._(_root);
	@override late final _Translations$editor$hud$ru hud = _Translations$editor$hud$ru._(_root);
	@override String get pages => 'Страницы';
	@override String get untitled => 'Без названия';
	@override String get needsToSaveBeforeExiting => 'Сохранение изменений… Когда оно завершится, можно выйти из редактора';
}

// Path: home.tabs
class _Translations$home$tabs$ru extends Translations$home$tabs$en {
	_Translations$home$tabs$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get home => 'Главная';
	@override String get browse => 'Обзор';
	@override String get whiteboard => 'Доска';
	@override String get settings => 'Настройки';
}

// Path: home.titles
class _Translations$home$titles$ru extends Translations$home$titles$en {
	_Translations$home$titles$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get home => 'Недавние заметки';
	@override String get browse => 'Обзор';
	@override String get whiteboard => 'Доска';
	@override String get settings => 'Настройки';
}

// Path: home.tooltips
class _Translations$home$tooltips$ru extends Translations$home$tooltips$en {
	_Translations$home$tooltips$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Новая заметка';
	@override String get showUpdateDialog => 'Показать окно обновления';
	@override String get exportNote => 'Экспортировать заметку';
}

// Path: home.create
class _Translations$home$create$ru extends Translations$home$create$en {
	_Translations$home$create$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Новая заметка';
	@override String get importNote => 'Импортировать заметку';
}

// Path: home.newFolder
class _Translations$home$newFolder$ru extends Translations$home$newFolder$en {
	_Translations$home$newFolder$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get newFolder => 'Новая папка';
	@override String get folderName => 'Имя папки';
	@override String get create => 'Создать';
	@override String get folderNameEmpty => 'Имя папки не может быть пустым';
	@override String get folderNameContainsSlash => 'Имя папки не может содержать косую черту';
	@override String get folderNameExists => 'Папка уже существует';
}

// Path: home.renameNote
class _Translations$home$renameNote$ru extends Translations$home$renameNote$en {
	_Translations$home$renameNote$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get renameNote => 'Переименовать заметку';
	@override String get noteName => 'Имя заметки';
	@override String get rename => 'Переименовать';
	@override String get noteNameEmpty => 'Имя заметки не может быть пустым';
	@override String get noteNameExists => 'Заметка с таким именем уже существует';
	@override String get noteNameForbiddenCharacters => 'Имя заметки содержит недопустимые символы';
	@override String get noteNameReserved => 'Это имя зарезервировано';
}

// Path: home.moveNote
class _Translations$home$moveNote$ru extends Translations$home$moveNote$en {
	_Translations$home$moveNote$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get moveNote => 'Переместить заметку';
	@override String moveNotes({required Object n}) => 'Переместить заметки: ${n}';
	@override String moveName({required Object f}) => 'Переместить ${f}';
	@override String get move => 'Переместить';
	@override String renamedTo({required Object newName}) => 'Заметка будет переименована в ${newName}';
	@override String get multipleRenamedTo => 'Следующие заметки будут переименованы:';
	@override String numberRenamedTo({required Object n}) => 'Заметок будет переименовано во избежание конфликтов: ${n}';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$ru extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => 'Удалить заметки: ${n}';
	@override String deleteName({required Object f}) => 'Удалить ${f}';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: 'Удалить выбранную заметку без возможности восстановления?',
		other: 'Удалить выбранные заметки без возможности восстановления?',
	);
	@override String get delete => 'Удалить';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$ru extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => 'Переименовать папку';
	@override String get folderName => 'Имя папки';
	@override String get rename => 'Переименовать';
	@override String get folderNameEmpty => 'Имя папки не может быть пустым';
	@override String get folderNameContainsSlash => 'Имя папки не может содержать косую черту';
	@override String get folderNameExists => 'Папка с таким именем уже существует';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$ru extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => 'Удалить папку';
	@override String deleteName({required Object f}) => 'Удалить ${f}';
	@override String get delete => 'Удалить';
	@override String get alsoDeleteContents => 'Также удалить все заметки в этой папке';
}

// Path: home.sort
class _Translations$home$sort$ru extends Translations$home$sort$en {
	_Translations$home$sort$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get sortBy => 'Сортировка';
	@override String get nameAToZ => 'Имя (А–Я)';
	@override String get nameZToA => 'Имя (Я–А)';
	@override String get lastModifiedNewToOld => 'Изменено (сначала новые)';
	@override String get lastModifiedOldToNew => 'Изменено (сначала старые)';
}

// Path: home.layout
class _Translations$home$layout$ru extends Translations$home$layout$en {
	_Translations$home$layout$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get layout => 'Вид';
	@override String get masonryGrid => 'Плиточная сетка';
	@override String get simpleGrid => 'Простая сетка';
}

// Path: sentry.consent
class _Translations$sentry$consent$ru extends Translations$sentry$consent$en {
	_Translations$sentry$consent$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Помочь улучшить BadNotes?';
	@override late final _Translations$sentry$consent$description$ru description = _Translations$sentry$consent$description$ru._(_root);
	@override late final _Translations$sentry$consent$answers$ru answers = _Translations$sentry$consent$answers$ru._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$ru extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get general => 'Общие';
	@override String get writing => 'Письмо';
	@override String get editor => 'Редактор';
	@override String get performance => 'Производительность';
	@override String get advanced => 'Дополнительно';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$ru extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get locale => 'Язык';
	@override String get appTheme => 'Тема приложения';
	@override String get platform => 'Стиль оформления';
	@override String get layoutSize => 'Тип макета';
	@override String get customAccentColor => 'Свой акцентный цвет';
	@override String get hyperlegibleFont => 'Шрифт Atkinson Hyperlegible';
	@override String get shouldCheckForUpdates => 'Проверять обновления BadNotes';
	@override String get shouldAlwaysAlertForUpdates => 'Быстрые обновления';
	@override String get allowInsecureConnections => 'Разрешить небезопасные подключения';
	@override String get syncOnlyOnWifi => 'Синхронизация только по Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'Загружать превью через мобильную сеть';
	@override String get editorToolbarAlignment => 'Положение панели инструментов';
	@override String get editorToolbarShowInFullscreen => 'Показывать панель инструментов в полноэкранном режиме';
	@override String get editorAutoInvert => 'Инвертировать заметки в тёмной теме';
	@override String get preferGreyscale => 'Предпочитать оттенки серого';
	@override String get maxImageSize => 'Максимальный размер изображения';
	@override String get autoClearWhiteboardOnExit => 'Автоочистка доски';
	@override String get disableEraserAfterUse => 'Автоотключение ластика';
	@override String get hideFingerDrawingToggle => 'Скрыть переключатель рисования пальцем';
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Автоотключение рисования пальцем';
	@override String get editorPromptRename => 'Предлагать переименовать новые заметки';
	@override String get recentColorsDontSavePresets => 'Не сохранять стандартные цвета в недавних';
	@override String get recentColorsLength => 'Сколько недавних цветов хранить';
	@override String get printPageIndicators => 'Печатать номера страниц';
	@override String get autosave => 'Автосохранение';
	@override String get shapeRecognitionDelay => 'Задержка распознавания фигур';
	@override String get autoStraightenLines => 'Автовыпрямление линий';
	@override String get customDataDir => 'Своя папка BadNotes';
	@override String get sentry => 'Отчёты об ошибках';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$ru extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => 'Выкл.: заметки синхронизируются и через мобильную сеть. Вкл.: синхронизация ждёт Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'Обычно миниатюры заметок ждут Wi-Fi, чтобы экономить трафик';
	@override String get hyperlegibleFont => 'Улучшает читаемость для слабовидящих';
	@override String get allowInsecureConnections => '(Не рекомендуется) Разрешить BadNotes подключаться к серверам с самоподписанными или ненадёжными сертификатами';
	@override String get preferGreyscale => 'Для экранов на электронных чернилах';
	@override String get autoClearWhiteboardOnExit => 'Очищает доску после выхода из приложения';
	@override String get disableEraserAfterUse => 'Автоматически возвращает перо после использования ластика';
	@override String get maxImageSize => 'Более крупные изображения будут сжаты';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$ru hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$ru._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Отключать рисование пальцем при обнаружении стилуса';
	@override String get editorPromptRename => 'Переименовать заметку можно и позже';
	@override String get printPageIndicators => 'Показывать номера страниц при экспорте';
	@override String get autosave => 'Автосохранение после короткой паузы или никогда';
	@override String get shapeRecognitionDelay => 'Сколько держать перо неподвижно, прежде чем линия превратится в фигуру';
	@override String get autoStraightenLines => 'Выпрямляет длинные линии без пера для фигур';
	@override String get shouldAlwaysAlertForUpdates => 'Сообщать об обновлениях сразу после их выхода';
	@override late final _Translations$settings$prefDescriptions$sentry$ru sentry = _Translations$settings$prefDescriptions$sentry$ru._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$ru extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get system => 'Системная';
	@override String get light => 'Светлая';
	@override String get dark => 'Тёмная';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$ru extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get auto => 'Авто';
	@override String get phone => 'Телефон';
	@override String get tablet => 'Планшет';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$ru extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => 'Выберите цвет';
}

// Path: settings.reset
class _Translations$settings$reset$ru extends Translations$settings$reset$en {
	_Translations$settings$reset$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Сбросить эту настройку?';
	@override String get button => 'Сбросить';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$ru extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Отмена';
	@override String get select => 'Выбрать';
	@override String get mustBeEmpty => 'Выбранная папка должна быть пустой';
	@override String get mustBeDoneSyncing => 'Перед сменой папки дождитесь окончания синхронизации';
	@override String get unsupported => 'Эта функция пока только для разработчиков. Её использование, скорее всего, приведёт к потере данных.';
}

// Path: login.form
class _Translations$login$form$ru extends Translations$login$form$en {
	_Translations$login$form$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'Входя в аккаунт, вы соглашаетесь с '),
		linkToPrivacyPolicy('политикой конфиденциальности'),
		const TextSpan(text: '.'),
	]);
}

// Path: login.status
class _Translations$login$status$ru extends Translations$login$status$en {
	_Translations$login$status$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => 'Вход не выполнен';
	@override String get tapToLogin => 'Нажмите, чтобы синхронизировать с Google Drive';
	@override String hi({required Object u}) => 'Привет, ${u}!';
	@override String get almostDone => 'Синхронизация почти готова, нажмите, чтобы завершить вход';
	@override String get loggedIn => 'Синхронизация включена';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$ru extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => 'Выберите, где хранить данные:';
	@override String get cloudStorage => 'Google Drive или OneDrive';
	@override String get loginWithGoogleDrive => 'Продолжить с Google Drive';
	@override String get loginWithOneDrive => 'Продолжить с OneDrive';
	@override String get cloudLoginFailed => 'Не удалось войти';
	@override String get comingSoon => 'Скоро';
	@override String get badnotesNcServer => 'Сервер Nextcloud от BadNotes';
	@override String get otherNcServer => 'Другой сервер Nextcloud';
	@override String get serverUrl => 'Адрес сервера';
	@override String get loginWithBadNotes => 'Войти через BadNotes';
	@override String get loginWithNextcloud => 'Войти через Nextcloud';
	@override late final _Translations$login$ncLoginStep$loginFlow$ru loginFlow = _Translations$login$ncLoginStep$loginFlow$ru._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$ru extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => 'Для защиты данных введите пароль шифрования:';
	@override String get newToBadNotes => 'Впервые в BadNotes? Просто придумайте новый пароль шифрования.';
	@override String get encPassword => 'Пароль шифрования';
	@override String get encFaqTitle => 'Частые вопросы';
	@override String get wrongEncPassword => 'Не удалось расшифровать данные с этим паролем. Попробуйте ввести его ещё раз.';
	@override String get connectionFailed => 'Не удалось подключиться к серверу. Попробуйте позже.';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$ru._(_root),
		_Translations$login$encLoginStep$encFaq$1$ru._(_root),
		_Translations$login$encLoginStep$encFaq$2$ru._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$ru extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => 'Сайт сервера';
	@override String get deleteAccount => 'Удалить аккаунт';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$ru extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get q => 'Потеряю ли я заметки, если выйду из аккаунта?';
	@override String get a => 'Нет. Заметки останутся и на устройстве, и на сервере, но не будут синхронизироваться, пока вы не войдёте снова. Перед выходом дождитесь окончания синхронизации, чтобы не потерять данные (ход синхронизации виден на главном экране).';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$ru extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get q => 'Где хранятся мои заметки?';
	@override String get a => 'В папке «BadNotes» на Google Drive или «Apps/BadNotes» в OneDrive. Файлы зашифрованы, поэтому открыть их можно только в BadNotes.';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$ru extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get q => 'Как сменить пароль шифрования?';
	@override String get a => '0. Дождитесь окончания синхронизации (ход синхронизации виден на главном экране).\n1. Выйдите из BadNotes.\n2. Удалите папку «BadNotes» на Google Drive или в OneDrive. Это удалит все заметки из облака, но не с устройства.\n3. Снова войдите в BadNotes. При входе можно задать новый пароль шифрования.\n4. Не забудьте выйти и снова войти в BadNotes и на других устройствах.';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$ru extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get q => 'Как удалить аккаунт?';
	@override String get a => 'У BadNotes нет собственного аккаунта. Выйдите, затем удалите папку «BadNotes» на Google Drive или в OneDrive.\nЧтобы также отозвать доступ BadNotes, откройте myaccount.google.com/permissions (Google) или account.live.com/consent/Manage (Microsoft).';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$ru extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => 'Цвета (Ctrl C)';
	@override String get select => 'Выделение';
	@override String get toggleEraser => 'Ластик (Ctrl E)';
	@override String get photo => 'Изображения';
	@override String get text => 'Текст';
	@override String get toggleFingerDrawing => 'Рисование пальцем (Ctrl F)';
	@override String get undo => 'Отменить';
	@override String get redo => 'Повторить';
	@override String get export => 'Экспорт (Ctrl Shift S)';
	@override String get exportAs => 'Экспортировать как:';
	@override String get fullscreen => 'Полноэкранный режим (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$ru extends Translations$editor$pens$en {
	_Translations$editor$pens$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => 'Перьевая ручка';
	@override String get ballpointPen => 'Шариковая ручка';
	@override String get highlighter => 'Маркер';
	@override String get pencil => 'Карандаш';
	@override String get shapePen => 'Перо для фигур';
	@override String get laserPointer => 'Лазерная указка';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$ru extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get size => 'Размер';
}

// Path: editor.colors
class _Translations$editor$colors$ru extends Translations$editor$colors$en {
	_Translations$editor$colors$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => 'Выбор цвета';
	@override String customBrightnessHue({required Object b, required Object h}) => 'Свой ${b} ${h}';
	@override String customHue({required Object h}) => 'Свой ${h}';
	@override String get dark => 'тёмный';
	@override String get light => 'светлый';
	@override String get black => 'Чёрный';
	@override String get darkGrey => 'Тёмно-серый';
	@override String get grey => 'Серый';
	@override String get lightGrey => 'Светло-серый';
	@override String get white => 'Белый';
	@override String get red => 'Красный';
	@override String get green => 'Зелёный';
	@override String get cyan => 'Голубой';
	@override String get blue => 'Синий';
	@override String get yellow => 'Жёлтый';
	@override String get purple => 'Фиолетовый';
	@override String get pink => 'Розовый';
	@override String get orange => 'Оранжевый';
	@override String get pastelRed => 'Пастельный красный';
	@override String get pastelOrange => 'Пастельный оранжевый';
	@override String get pastelYellow => 'Пастельный жёлтый';
	@override String get pastelGreen => 'Пастельный зелёный';
	@override String get pastelCyan => 'Пастельный голубой';
	@override String get pastelBlue => 'Пастельный синий';
	@override String get pastelPurple => 'Пастельный фиолетовый';
	@override String get pastelPink => 'Пастельный розовый';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$ru extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Параметры изображения';
	@override String get invertible => 'Инвертируемое';
	@override String get download => 'Скачать';
	@override String get setAsBackground => 'Сделать фоном';
	@override String get removeAsBackground => 'Убрать из фона';
	@override String get delete => 'Удалить';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$ru extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Удалить';
	@override String get duplicate => 'Дублировать';
}

// Path: editor.menu
class _Translations$editor$menu$ru extends Translations$editor$menu$en {
	_Translations$editor$menu$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => 'Очистить страницу ${page}/${totalPages}';
	@override String get clearAllPages => 'Очистить все страницы';
	@override String get insertPage => 'Вставить страницу ниже';
	@override String get duplicatePage => 'Дублировать страницу';
	@override String get deletePage => 'Удалить страницу';
	@override String get lineHeight => 'Межстрочный интервал';
	@override String get lineHeightDescription => 'Также задаёт размер текста в печатных заметках';
	@override String get lineThickness => 'Толщина линий';
	@override String get lineThicknessDescription => 'Толщина линий фона';
	@override String get backgroundImageFit => 'Размещение фонового изображения';
	@override String get backgroundPattern => 'Узор фона';
	@override String get import => 'Импорт';
	@override String get watchServer => 'Следить за обновлениями на сервере';
	@override String get watchServerReadOnly => 'Редактирование отключено во время слежения за сервером';
	@override late final _Translations$editor$menu$boxFits$ru boxFits = _Translations$editor$menu$boxFits$ru._(_root);
	@override late final _Translations$editor$menu$bgPatterns$ru bgPatterns = _Translations$editor$menu$bgPatterns$ru._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$ru extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ошибка';
	@override String get message => 'PDF-файлы нельзя добавить как изображение. Для этого используйте «${_root.editor.menu.import} > PDF».';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$ru extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Только чтение';
	@override String get watchingServer => 'Вы следите за обновлениями на сервере. В этом режиме редактирование отключено.';
	@override String get corrupted => 'Не удалось загрузить заметку. Возможно, она повреждена или ещё загружается.';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$ru extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Эта заметка изменена в более новой версии BadNotes';
	@override String get subtitle => 'При редактировании часть данных может быть потеряна. Всё равно редактировать?';
	@override String get allowEditing => 'Разрешить редактирование';
}

// Path: editor.quill
class _Translations$editor$quill$ru extends Translations$editor$quill$en {
	_Translations$editor$quill$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => 'Введите текст…';
}

// Path: editor.hud
class _Translations$editor$hud$ru extends Translations$editor$hud$en {
	_Translations$editor$hud$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => 'Разблокировать масштаб';
	@override String get lockZoom => 'Заблокировать масштаб';
	@override String get unlockSingleFingerPan => 'Включить прокрутку одним пальцем';
	@override String get lockSingleFingerPan => 'Отключить прокрутку одним пальцем';
	@override String get unlockAxisAlignedPan => 'Разрешить прокрутку в любом направлении';
	@override String get lockAxisAlignedPan => 'Прокрутка только по горизонтали или вертикали';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$ru extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get question => 'Автоматически отправлять отчёты о непредвиденных ошибках? Это поможет мне быстрее находить и исправлять проблемы.';
	@override String get scope => 'Отчёты могут содержать сведения об ошибке и вашем устройстве. Я сделал всё возможное, чтобы отфильтровать личные данные, но часть из них может остаться.';
	@override String get currentlyOff => 'Если вы дадите согласие, отправка отчётов об ошибках включится после перезапуска приложения.';
	@override String get currentlyOn => 'Если вы отзовёте согласие, перезапустите приложение, чтобы отключить отправку отчётов об ошибках.';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: 'Подробнее в '),
		link('политике конфиденциальности'),
		const TextSpan(text: '.'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$ru extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Да';
	@override String get no => 'Нет';
	@override String get later => 'Спросить позже';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$ru extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get shown => 'Защищает от случайного переключения';
	@override String get fixedOn => 'Рисование пальцем всегда включено';
	@override String get fixedOff => 'Рисование пальцем всегда выключено';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$ru extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get active => 'Включено';
	@override String get inactive => 'Выключено';
	@override String get activeUntilRestart => 'Включено до перезапуска приложения';
	@override String get inactiveUntilRestart => 'Выключено до перезапуска приложения';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$ru extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => 'Разрешите BadNotes доступ к вашему аккаунту Nextcloud';
	@override String get followPrompts => 'Следуйте подсказкам в интерфейсе Nextcloud';
	@override String get browserDidntOpen => 'Страница входа не открылась? Нажмите здесь';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$ru extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get q => 'Что такое пароль шифрования? Зачем два пароля?';
	@override String get a => 'Аккаунт Google или Microsoft нужен для доступа к облаку. Пароль шифрования «перемешивает» ваши данные ещё до того, как они попадут в облако.\nДаже если кто-то получит доступ к вашему аккаунту Google или Microsoft, заметки останутся в безопасности, ведь они зашифрованы отдельным паролем. Это второй уровень защиты ваших данных.\nБез пароля шифрования никто не сможет открыть ваши заметки на сервере, но это значит и то, что, забыв пароль шифрования, вы потеряете доступ к своим данным.';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$ru extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get q => 'Я ещё не задавал пароль шифрования. Где его взять?';
	@override String get a => 'Придумайте новый пароль шифрования и введите его выше.\nBadNotes автоматически создаст из него ключи шифрования.';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$ru extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get q => 'Можно ли использовать тот же пароль, что и для аккаунта Google или Microsoft?';
	@override String get a => 'Лучше не надо. Отдельный пароль шифрования защитит заметки, даже если кто-то войдёт в этот аккаунт.';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$ru extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get fill => 'Растянуть';
	@override String get cover => 'Заполнить';
	@override String get contain => 'Вписать';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$ru extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get none => 'Пустой';
	@override String get college => 'Узкая линейка';
	@override String get collegeRtl => 'Узкая линейка (справа налево)';
	@override String get lined => 'В линейку';
	@override String get grid => 'В клетку';
	@override String get dots => 'В точку';
	@override String get staffs => 'Нотный стан';
	@override String get tablature => 'Табулатура';
	@override String get cornell => 'Корнелл';
}
