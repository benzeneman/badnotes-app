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
class TranslationsZhHansCn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhHansCn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhHansCn,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <zh-Hans-CN>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsZhHansCn _root = this; // ignore: unused_field

	@override 
	TranslationsZhHansCn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhHansCn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$zh_Hans_CN common = _Translations$common$zh_Hans_CN._(_root);
	@override late final _Translations$home$zh_Hans_CN home = _Translations$home$zh_Hans_CN._(_root);
	@override late final _Translations$sentry$zh_Hans_CN sentry = _Translations$sentry$zh_Hans_CN._(_root);
	@override late final _Translations$settings$zh_Hans_CN settings = _Translations$settings$zh_Hans_CN._(_root);
	@override late final _Translations$logs$zh_Hans_CN logs = _Translations$logs$zh_Hans_CN._(_root);
	@override late final _Translations$login$zh_Hans_CN login = _Translations$login$zh_Hans_CN._(_root);
	@override late final _Translations$profile$zh_Hans_CN profile = _Translations$profile$zh_Hans_CN._(_root);
	@override late final _Translations$appInfo$zh_Hans_CN appInfo = _Translations$appInfo$zh_Hans_CN._(_root);
	@override late final _Translations$update$zh_Hans_CN update = _Translations$update$zh_Hans_CN._(_root);
	@override late final _Translations$editor$zh_Hans_CN editor = _Translations$editor$zh_Hans_CN._(_root);
}

// Path: common
class _Translations$common$zh_Hans_CN extends Translations$common$en {
	_Translations$common$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get done => '完成';
	@override String get continueBtn => '继续';
	@override String get cancel => '取消';
}

// Path: home
class _Translations$home$zh_Hans_CN extends Translations$home$en {
	_Translations$home$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$zh_Hans_CN tabs = _Translations$home$tabs$zh_Hans_CN._(_root);
	@override late final _Translations$home$titles$zh_Hans_CN titles = _Translations$home$titles$zh_Hans_CN._(_root);
	@override late final _Translations$home$tooltips$zh_Hans_CN tooltips = _Translations$home$tooltips$zh_Hans_CN._(_root);
	@override late final _Translations$home$create$zh_Hans_CN create = _Translations$home$create$zh_Hans_CN._(_root);
	@override String get welcome => '欢迎使用 BadNotes';
	@override String get invalidFormat => '不支持所选文件。请选择 sbn、sbn2、sba 或 pdf 文件。';
	@override String get noFiles => '未找到文件';
	@override String get noPreviewAvailable => '暂无预览';
	@override String get createNewNote => '点按 + 按钮新建笔记';
	@override String get backFolder => '返回上一个文件夹';
	@override late final _Translations$home$newFolder$zh_Hans_CN newFolder = _Translations$home$newFolder$zh_Hans_CN._(_root);
	@override late final _Translations$home$renameNote$zh_Hans_CN renameNote = _Translations$home$renameNote$zh_Hans_CN._(_root);
	@override late final _Translations$home$moveNote$zh_Hans_CN moveNote = _Translations$home$moveNote$zh_Hans_CN._(_root);
	@override String get deleteNote => '删除笔记';
	@override late final _Translations$home$deleteNoteDialog$zh_Hans_CN deleteNoteDialog = _Translations$home$deleteNoteDialog$zh_Hans_CN._(_root);
	@override late final _Translations$home$renameFolder$zh_Hans_CN renameFolder = _Translations$home$renameFolder$zh_Hans_CN._(_root);
	@override late final _Translations$home$deleteFolder$zh_Hans_CN deleteFolder = _Translations$home$deleteFolder$zh_Hans_CN._(_root);
	@override late final _Translations$home$sort$zh_Hans_CN sort = _Translations$home$sort$zh_Hans_CN._(_root);
	@override late final _Translations$home$layout$zh_Hans_CN layout = _Translations$home$layout$zh_Hans_CN._(_root);
}

// Path: sentry
class _Translations$sentry$zh_Hans_CN extends Translations$sentry$en {
	_Translations$sentry$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$zh_Hans_CN consent = _Translations$sentry$consent$zh_Hans_CN._(_root);
}

// Path: settings
class _Translations$settings$zh_Hans_CN extends Translations$settings$en {
	_Translations$settings$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$zh_Hans_CN prefCategories = _Translations$settings$prefCategories$zh_Hans_CN._(_root);
	@override late final _Translations$settings$prefLabels$zh_Hans_CN prefLabels = _Translations$settings$prefLabels$zh_Hans_CN._(_root);
	@override late final _Translations$settings$prefDescriptions$zh_Hans_CN prefDescriptions = _Translations$settings$prefDescriptions$zh_Hans_CN._(_root);
	@override late final _Translations$settings$themeModes$zh_Hans_CN themeModes = _Translations$settings$themeModes$zh_Hans_CN._(_root);
	@override late final _Translations$settings$layoutSizes$zh_Hans_CN layoutSizes = _Translations$settings$layoutSizes$zh_Hans_CN._(_root);
	@override late final _Translations$settings$accentColorPicker$zh_Hans_CN accentColorPicker = _Translations$settings$accentColorPicker$zh_Hans_CN._(_root);
	@override String get systemLanguage => '自动';
	@override List<String> get axisDirections => [
		'顶部',
		'右侧',
		'底部',
		'左侧',
	];
	@override late final _Translations$settings$reset$zh_Hans_CN reset = _Translations$settings$reset$zh_Hans_CN._(_root);
	@override String get resyncEverything => '全部重新同步';
	@override String get openDataDir => '打开 BadNotes 文件夹';
	@override late final _Translations$settings$customDataDir$zh_Hans_CN customDataDir = _Translations$settings$customDataDir$zh_Hans_CN._(_root);
	@override String get autosaveDisabled => '从不';
	@override String get shapeRecognitionDisabled => '从不';
}

// Path: logs
class _Translations$logs$zh_Hans_CN extends Translations$logs$en {
	_Translations$logs$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get logs => '日志';
	@override String get viewLogs => '查看日志';
	@override String get debuggingInfo => '日志包含有助于调试和开发的信息';
	@override String get noLogs => '暂无日志！';
	@override String get useTheApp => '使用应用时，日志会显示在这里';
}

// Path: login
class _Translations$login$zh_Hans_CN extends Translations$login$en {
	_Translations$login$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '登录';
	@override late final _Translations$login$form$zh_Hans_CN form = _Translations$login$form$zh_Hans_CN._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: '还没有账号？'),
		linkToSignup('立即注册'),
		const TextSpan(text: '！'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: '不是你？'),
		undoLogin('选择其他账号'),
		const TextSpan(text: '。'),
	]);
	@override late final _Translations$login$status$zh_Hans_CN status = _Translations$login$status$zh_Hans_CN._(_root);
	@override late final _Translations$login$ncLoginStep$zh_Hans_CN ncLoginStep = _Translations$login$ncLoginStep$zh_Hans_CN._(_root);
	@override late final _Translations$login$encLoginStep$zh_Hans_CN encLoginStep = _Translations$login$encLoginStep$zh_Hans_CN._(_root);
}

// Path: profile
class _Translations$profile$zh_Hans_CN extends Translations$profile$en {
	_Translations$profile$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '我的资料';
	@override String get logout => '退出登录';
	@override String quotaUsage({required Object used, required Object total, required Object percent}) => '已使用 ${used} / ${total}（${percent}%）';
	@override String quotaUsageUncapped({required Object used}) => '已使用 ${used}';
	@override String get connectedTo => '已连接到';
	@override String lastSynced({required Object time}) => '上次同步：${time}';
	@override String get notSyncedYet => '尚未同步';
	@override String get justNow => '刚刚';
	@override String minutesAgo({required Object n}) => '${n} 分钟前';
	@override String hoursAgo({required Object n}) => '${n} 小时前';
	@override String filesWaiting({required Object n}) => '${n} 个文件等待同步';
	@override String get signInAgainNeeded => '请重新登录以继续同步';
	@override String get signInAgain => '重新登录';
	@override String wrongAccount({required Object email}) => '请选择 ${email}';
	@override late final _Translations$profile$quickLinks$zh_Hans_CN quickLinks = _Translations$profile$quickLinks$zh_Hans_CN._(_root);
	@override String get faqTitle => '常见问题';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$zh_Hans_CN._(_root),
		_Translations$profile$faq$1$zh_Hans_CN._(_root),
		_Translations$profile$faq$2$zh_Hans_CN._(_root),
		_Translations$profile$faq$3$zh_Hans_CN._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$zh_Hans_CN extends Translations$appInfo$en {
	_Translations$appInfo$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get debug => '调试';
}

// Path: update
class _Translations$update$zh_Hans_CN extends Translations$update$en {
	_Translations$update$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => '有可用更新';
	@override String get updateAvailableDescription => '应用有新版本可用：';
	@override String get update => '更新';
	@override String get downloadNotAvailableYet => '你的平台暂时无法下载，请稍后再试。';
}

// Path: editor
class _Translations$editor$zh_Hans_CN extends Translations$editor$en {
	_Translations$editor$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$zh_Hans_CN toolbar = _Translations$editor$toolbar$zh_Hans_CN._(_root);
	@override late final _Translations$editor$pens$zh_Hans_CN pens = _Translations$editor$pens$zh_Hans_CN._(_root);
	@override late final _Translations$editor$penOptions$zh_Hans_CN penOptions = _Translations$editor$penOptions$zh_Hans_CN._(_root);
	@override late final _Translations$editor$colors$zh_Hans_CN colors = _Translations$editor$colors$zh_Hans_CN._(_root);
	@override late final _Translations$editor$imageOptions$zh_Hans_CN imageOptions = _Translations$editor$imageOptions$zh_Hans_CN._(_root);
	@override late final _Translations$editor$selectionBar$zh_Hans_CN selectionBar = _Translations$editor$selectionBar$zh_Hans_CN._(_root);
	@override late final _Translations$editor$menu$zh_Hans_CN menu = _Translations$editor$menu$zh_Hans_CN._(_root);
	@override late final _Translations$editor$photoPdfError$zh_Hans_CN photoPdfError = _Translations$editor$photoPdfError$zh_Hans_CN._(_root);
	@override late final _Translations$editor$readOnlyBanner$zh_Hans_CN readOnlyBanner = _Translations$editor$readOnlyBanner$zh_Hans_CN._(_root);
	@override late final _Translations$editor$versionTooNew$zh_Hans_CN versionTooNew = _Translations$editor$versionTooNew$zh_Hans_CN._(_root);
	@override late final _Translations$editor$quill$zh_Hans_CN quill = _Translations$editor$quill$zh_Hans_CN._(_root);
	@override late final _Translations$editor$hud$zh_Hans_CN hud = _Translations$editor$hud$zh_Hans_CN._(_root);
	@override String get pages => '页面';
	@override String get untitled => '未命名';
	@override String get needsToSaveBeforeExiting => '正在保存更改… 完成后即可安全退出编辑器';
}

// Path: home.tabs
class _Translations$home$tabs$zh_Hans_CN extends Translations$home$tabs$en {
	_Translations$home$tabs$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get home => '首页';
	@override String get browse => '浏览';
	@override String get whiteboard => '白板';
	@override String get settings => '设置';
}

// Path: home.titles
class _Translations$home$titles$zh_Hans_CN extends Translations$home$titles$en {
	_Translations$home$titles$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get home => '最近笔记';
	@override String get browse => '浏览';
	@override String get whiteboard => '白板';
	@override String get settings => '设置';
}

// Path: home.tooltips
class _Translations$home$tooltips$zh_Hans_CN extends Translations$home$tooltips$en {
	_Translations$home$tooltips$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get newNote => '新建笔记';
	@override String get showUpdateDialog => '显示更新对话框';
	@override String get exportNote => '导出笔记';
}

// Path: home.create
class _Translations$home$create$zh_Hans_CN extends Translations$home$create$en {
	_Translations$home$create$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get newNote => '新建笔记';
	@override String get importNote => '导入笔记';
}

// Path: home.newFolder
class _Translations$home$newFolder$zh_Hans_CN extends Translations$home$newFolder$en {
	_Translations$home$newFolder$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get newFolder => '新建文件夹';
	@override String get folderName => '文件夹名称';
	@override String get create => '创建';
	@override String get folderNameEmpty => '文件夹名称不能为空';
	@override String get folderNameContainsSlash => '文件夹名称不能包含斜杠';
	@override String get folderNameExists => '文件夹已存在';
}

// Path: home.renameNote
class _Translations$home$renameNote$zh_Hans_CN extends Translations$home$renameNote$en {
	_Translations$home$renameNote$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get renameNote => '重命名笔记';
	@override String get noteName => '笔记名称';
	@override String get rename => '重命名';
	@override String get noteNameEmpty => '笔记名称不能为空';
	@override String get noteNameExists => '已存在同名笔记';
	@override String get noteNameForbiddenCharacters => '笔记名称包含不允许的字符';
	@override String get noteNameReserved => '该笔记名称为保留名称';
}

// Path: home.moveNote
class _Translations$home$moveNote$zh_Hans_CN extends Translations$home$moveNote$en {
	_Translations$home$moveNote$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get moveNote => '移动笔记';
	@override String moveNotes({required Object n}) => '移动 ${n} 条笔记';
	@override String moveName({required Object f}) => '移动 ${f}';
	@override String get move => '移动';
	@override String renamedTo({required Object newName}) => '笔记将重命名为 ${newName}';
	@override String get multipleRenamedTo => '以下笔记将被重命名：';
	@override String numberRenamedTo({required Object n}) => '为避免冲突，${n} 条笔记将被重命名';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$zh_Hans_CN extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => '删除 ${n} 条笔记';
	@override String deleteName({required Object f}) => '删除 ${f}';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '要永久删除所选笔记吗？',
		other: '要永久删除所选笔记吗？',
	);
	@override String get delete => '删除';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$zh_Hans_CN extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => '重命名文件夹';
	@override String get folderName => '文件夹名称';
	@override String get rename => '重命名';
	@override String get folderNameEmpty => '文件夹名称不能为空';
	@override String get folderNameContainsSlash => '文件夹名称不能包含斜杠';
	@override String get folderNameExists => '已存在同名文件夹';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$zh_Hans_CN extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => '删除文件夹';
	@override String deleteName({required Object f}) => '删除 ${f}';
	@override String get delete => '删除';
	@override String get alsoDeleteContents => '同时删除此文件夹中的所有笔记';
}

// Path: home.sort
class _Translations$home$sort$zh_Hans_CN extends Translations$home$sort$en {
	_Translations$home$sort$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get sortBy => '排序方式';
	@override String get nameAToZ => '名称（A-Z）';
	@override String get nameZToA => '名称（Z-A）';
	@override String get lastModifiedNewToOld => '编辑时间（从新到旧）';
	@override String get lastModifiedOldToNew => '编辑时间（从旧到新）';
}

// Path: home.layout
class _Translations$home$layout$zh_Hans_CN extends Translations$home$layout$en {
	_Translations$home$layout$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get layout => '布局';
	@override String get masonryGrid => '瀑布流';
	@override String get simpleGrid => '简单网格';
}

// Path: sentry.consent
class _Translations$sentry$consent$zh_Hans_CN extends Translations$sentry$consent$en {
	_Translations$sentry$consent$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '帮助改进 BadNotes？';
	@override late final _Translations$sentry$consent$description$zh_Hans_CN description = _Translations$sentry$consent$description$zh_Hans_CN._(_root);
	@override late final _Translations$sentry$consent$answers$zh_Hans_CN answers = _Translations$sentry$consent$answers$zh_Hans_CN._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$zh_Hans_CN extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get general => '常规';
	@override String get writing => '书写';
	@override String get editor => '编辑器';
	@override String get performance => '性能';
	@override String get advanced => '高级';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$zh_Hans_CN extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get locale => '语言';
	@override String get appTheme => '应用主题';
	@override String get platform => '主题类型';
	@override String get layoutSize => '布局类型';
	@override String get customAccentColor => '自定义强调色';
	@override String get hyperlegibleFont => 'Atkinson Hyperlegible 字体';
	@override String get shouldCheckForUpdates => '检查 BadNotes 更新';
	@override String get shouldAlwaysAlertForUpdates => '更快获取更新';
	@override String get allowInsecureConnections => '允许不安全的连接';
	@override String get syncOnlyOnWifi => '仅在 Wi-Fi 下同步';
	@override String get syncPreviewsOnMobileData => '使用移动数据上传预览图';
	@override String get editorToolbarAlignment => '工具栏位置';
	@override String get editorToolbarShowInFullscreen => '全屏模式下显示工具栏';
	@override String get editorAutoInvert => '深色模式下反色显示笔记';
	@override String get preferGreyscale => '优先使用灰度颜色';
	@override String get maxImageSize => '最大图片尺寸';
	@override String get autoClearWhiteboardOnExit => '自动清空白板';
	@override String get disableEraserAfterUse => '自动关闭橡皮擦';
	@override String get hideFingerDrawingToggle => '隐藏手指绘图开关';
	@override String get autoDisableFingerDrawingWhenStylusDetected => '自动关闭手指绘图';
	@override String get editorPromptRename => '提示重命名新笔记';
	@override String get recentColorsDontSavePresets => '最近使用的颜色中不保存预设颜色';
	@override String get recentColorsLength => '保存的最近颜色数量';
	@override String get printPageIndicators => '打印页码';
	@override String get autosave => '自动保存';
	@override String get shapeRecognitionDelay => '形状识别延迟';
	@override String get autoStraightenLines => '自动拉直线条';
	@override String get customDataDir => '自定义 BadNotes 文件夹';
	@override String get sentry => '错误报告';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$zh_Hans_CN extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => '关闭：使用移动数据时也会同步笔记。开启：等到连接 Wi-Fi 时再同步';
	@override String get syncPreviewsOnMobileData => '笔记缩略图默认等到连接 Wi-Fi 时再上传，以节省流量';
	@override String get hyperlegibleFont => '为视力不佳的用户提升文字辨识度';
	@override String get allowInsecureConnections => '（不推荐）允许 BadNotes 连接使用自签名或不受信任证书的服务器';
	@override String get preferGreyscale => '适用于墨水屏';
	@override String get autoClearWhiteboardOnExit => '退出应用后清空白板';
	@override String get disableEraserAfterUse => '使用橡皮擦后自动切换回笔';
	@override String get maxImageSize => '超过此尺寸的图片将被压缩';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$zh_Hans_CN hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$zh_Hans_CN._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => '检测到手写笔时关闭手指绘图';
	@override String get editorPromptRename => '你随时可以稍后重命名笔记';
	@override String get printPageIndicators => '在导出文件中显示页码';
	@override String get autosave => '短暂延迟后自动保存，或从不保存';
	@override String get shapeRecognitionDelay => '笔停住多久后，笔迹会自动吸附为形状';
	@override String get autoStraightenLines => '无需使用形状笔即可拉直长线条';
	@override String get shouldAlwaysAlertForUpdates => '有更新时第一时间通知我';
	@override late final _Translations$settings$prefDescriptions$sentry$zh_Hans_CN sentry = _Translations$settings$prefDescriptions$sentry$zh_Hans_CN._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$zh_Hans_CN extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get system => '跟随系统';
	@override String get light => '浅色';
	@override String get dark => '深色';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$zh_Hans_CN extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get auto => '自动';
	@override String get phone => '手机';
	@override String get tablet => '平板';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$zh_Hans_CN extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => '选择颜色';
}

// Path: settings.reset
class _Translations$settings$reset$zh_Hans_CN extends Translations$settings$reset$en {
	_Translations$settings$reset$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '重置此设置？';
	@override String get button => '重置';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$zh_Hans_CN extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get select => '选择';
	@override String get mustBeEmpty => '所选文件夹必须为空';
	@override String get mustBeDoneSyncing => '更改文件夹前，请确保同步已完成';
	@override String get unsupported => '此功能目前仅供开发者使用，使用它很可能导致数据丢失。';
}

// Path: login.form
class _Translations$login$form$zh_Hans_CN extends Translations$login$form$en {
	_Translations$login$form$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: '登录即表示你同意'),
		linkToPrivacyPolicy('隐私政策'),
		const TextSpan(text: '。'),
	]);
}

// Path: login.status
class _Translations$login$status$zh_Hans_CN extends Translations$login$status$en {
	_Translations$login$status$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => '已退出登录';
	@override String get tapToLogin => '点按以与 Google Drive 同步';
	@override String hi({required Object u}) => '你好，${u}！';
	@override String get almostDone => '即将可以同步，点按以完成登录';
	@override String get loggedIn => '同步已开启';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$zh_Hans_CN extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => '选择数据的存储位置：';
	@override String get cloudStorage => 'Google Drive 或 OneDrive';
	@override String get loginWithGoogleDrive => '通过 Google Drive 继续';
	@override String get loginWithOneDrive => '通过 OneDrive 继续';
	@override String get cloudLoginFailed => '无法登录';
	@override String get comingSoon => '即将推出';
	@override String get badnotesNcServer => 'BadNotes 的 Nextcloud 服务器';
	@override String get otherNcServer => '其他 Nextcloud 服务器';
	@override String get serverUrl => '服务器地址';
	@override String get loginWithBadNotes => '使用 BadNotes 登录';
	@override String get loginWithNextcloud => '使用 Nextcloud 登录';
	@override late final _Translations$login$ncLoginStep$loginFlow$zh_Hans_CN loginFlow = _Translations$login$ncLoginStep$loginFlow$zh_Hans_CN._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$zh_Hans_CN extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => '为保护你的数据，请输入加密密码：';
	@override String get newToBadNotes => '首次使用 BadNotes？直接输入一个新的加密密码即可。';
	@override String get encPassword => '加密密码';
	@override String get encFaqTitle => '常见问题';
	@override String get wrongEncPassword => '使用该密码解密失败，请重新输入。';
	@override String get connectionFailed => '连接服务器时出错，请稍后重试。';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$zh_Hans_CN._(_root),
		_Translations$login$encLoginStep$encFaq$1$zh_Hans_CN._(_root),
		_Translations$login$encLoginStep$encFaq$2$zh_Hans_CN._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$zh_Hans_CN extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => '服务器主页';
	@override String get deleteAccount => '删除账号';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$zh_Hans_CN extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get q => '退出登录会丢失笔记吗？';
	@override String get a => '不会。你的笔记会同时保留在设备和服务器上，但在你重新登录之前不会与服务器同步。退出登录前请确保同步已完成，以免丢失数据（可在首页查看同步进度）。';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$zh_Hans_CN extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get q => '我的笔记存储在哪里？';
	@override String get a => '存储在 Google Drive 的"BadNotes"文件夹中，或 OneDrive 的"Apps/BadNotes"中。这些文件已加密，因此只能在 BadNotes 中打开。';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$zh_Hans_CN extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get q => '如何更改加密密码？';
	@override String get a => '0. 确保同步已完成（可在首页查看同步进度）。\n1. 退出 BadNotes 登录。\n2. 删除 Google Drive 或 OneDrive 中的"BadNotes"文件夹。这会删除云端的所有笔记，但不会删除设备上的笔记。\n3. 重新登录 BadNotes。登录时可以设置新的加密密码。\n4. 别忘了在其他设备上也退出并重新登录 BadNotes。';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$zh_Hans_CN extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get q => '如何删除我的账号？';
	@override String get a => 'BadNotes 没有自己的账号体系。退出登录，然后删除 Google Drive 或 OneDrive 中的"BadNotes"文件夹即可。\n如需同时撤销 BadNotes 的访问权限，请前往 myaccount.google.com/permissions（Google）或 account.live.com/consent/Manage（Microsoft）。';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$zh_Hans_CN extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => '切换颜色 (Ctrl C)';
	@override String get select => '选择';
	@override String get toggleEraser => '切换橡皮擦 (Ctrl E)';
	@override String get photo => '图片';
	@override String get text => '文本';
	@override String get toggleFingerDrawing => '切换手指绘图 (Ctrl F)';
	@override String get undo => '撤销';
	@override String get redo => '重做';
	@override String get export => '导出 (Ctrl Shift S)';
	@override String get exportAs => '导出为：';
	@override String get fullscreen => '切换全屏 (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$zh_Hans_CN extends Translations$editor$pens$en {
	_Translations$editor$pens$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => '钢笔';
	@override String get ballpointPen => '圆珠笔';
	@override String get highlighter => '荧光笔';
	@override String get pencil => '铅笔';
	@override String get shapePen => '形状笔';
	@override String get laserPointer => '激光笔';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$zh_Hans_CN extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get size => '粗细';
}

// Path: editor.colors
class _Translations$editor$colors$zh_Hans_CN extends Translations$editor$colors$en {
	_Translations$editor$colors$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => '取色器';
	@override String customBrightnessHue({required Object b, required Object h}) => '自定义${b}${h}';
	@override String customHue({required Object h}) => '自定义${h}';
	@override String get dark => '深';
	@override String get light => '浅';
	@override String get black => '黑色';
	@override String get darkGrey => '深灰色';
	@override String get grey => '灰色';
	@override String get lightGrey => '浅灰色';
	@override String get white => '白色';
	@override String get red => '红色';
	@override String get green => '绿色';
	@override String get cyan => '青色';
	@override String get blue => '蓝色';
	@override String get yellow => '黄色';
	@override String get purple => '紫色';
	@override String get pink => '粉色';
	@override String get orange => '橙色';
	@override String get pastelRed => '浅红色';
	@override String get pastelOrange => '浅橙色';
	@override String get pastelYellow => '浅黄色';
	@override String get pastelGreen => '浅绿色';
	@override String get pastelCyan => '浅青色';
	@override String get pastelBlue => '浅蓝色';
	@override String get pastelPurple => '浅紫色';
	@override String get pastelPink => '浅粉色';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$zh_Hans_CN extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '图片选项';
	@override String get invertible => '可反色';
	@override String get download => '下载';
	@override String get setAsBackground => '设为背景';
	@override String get removeAsBackground => '取消背景';
	@override String get delete => '删除';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$zh_Hans_CN extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get delete => '删除';
	@override String get duplicate => '复制';
}

// Path: editor.menu
class _Translations$editor$menu$zh_Hans_CN extends Translations$editor$menu$en {
	_Translations$editor$menu$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => '清空第 ${page}/${totalPages} 页';
	@override String get clearAllPages => '清空所有页面';
	@override String get insertPage => '在下方插入页面';
	@override String get duplicatePage => '复制页面';
	@override String get deletePage => '删除页面';
	@override String get lineHeight => '行高';
	@override String get lineHeightDescription => '同时控制键入笔记的文字大小';
	@override String get lineThickness => '线条粗细';
	@override String get lineThicknessDescription => '背景线条的粗细';
	@override String get backgroundImageFit => '背景图片适应方式';
	@override String get backgroundPattern => '背景样式';
	@override String get import => '导入';
	@override String get watchServer => '监听服务器更新';
	@override String get watchServerReadOnly => '监听服务器时无法编辑';
	@override late final _Translations$editor$menu$boxFits$zh_Hans_CN boxFits = _Translations$editor$menu$boxFits$zh_Hans_CN._(_root);
	@override late final _Translations$editor$menu$bgPatterns$zh_Hans_CN bgPatterns = _Translations$editor$menu$bgPatterns$zh_Hans_CN._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$zh_Hans_CN extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '错误';
	@override String get message => 'PDF 文件不能作为图片添加。请使用“${_root.editor.menu.import} > PDF”。';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$zh_Hans_CN extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '只读模式';
	@override String get watchingServer => '你正在监听服务器上的更新，此模式下无法编辑。';
	@override String get corrupted => '无法加载笔记。笔记可能已损坏或仍在下载中。';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$zh_Hans_CN extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get title => '此笔记是用更新版本的 BadNotes 编辑的';
	@override String get subtitle => '编辑此笔记可能导致部分信息丢失。仍要忽略并继续编辑吗？';
	@override String get allowEditing => '允许编辑';
}

// Path: editor.quill
class _Translations$editor$quill$zh_Hans_CN extends Translations$editor$quill$en {
	_Translations$editor$quill$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => '在此输入内容…';
}

// Path: editor.hud
class _Translations$editor$hud$zh_Hans_CN extends Translations$editor$hud$en {
	_Translations$editor$hud$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => '解锁缩放';
	@override String get lockZoom => '锁定缩放';
	@override String get unlockSingleFingerPan => '启用单指平移';
	@override String get lockSingleFingerPan => '停用单指平移';
	@override String get unlockAxisAlignedPan => '解除水平或垂直平移锁定';
	@override String get lockAxisAlignedPan => '锁定为水平或垂直平移';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$zh_Hans_CN extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get question => '是否自动报告意外错误？这有助于我更快地发现并修复问题。';
	@override String get scope => '报告可能包含错误信息和设备信息。我已尽力过滤个人数据，但仍可能有少量残留。';
	@override String get currentlyOff => '如果你同意，错误报告将在重启应用后启用。';
	@override String get currentlyOn => '如果你撤回同意，请重启应用以停用错误报告。';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: '详情请参阅'),
		link('隐私政策'),
		const TextSpan(text: '。'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$zh_Hans_CN extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get yes => '是';
	@override String get no => '否';
	@override String get later => '以后再问';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$zh_Hans_CN extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get shown => '防止误触切换';
	@override String get fixedOn => '手指绘图已固定为开启';
	@override String get fixedOff => '手指绘图已固定为关闭';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$zh_Hans_CN extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get active => '已启用';
	@override String get inactive => '未启用';
	@override String get activeUntilRestart => '重启应用前保持启用';
	@override String get inactiveUntilRestart => '重启应用前保持停用';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$zh_Hans_CN extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => '请授权 BadNotes 访问你的 Nextcloud 账号';
	@override String get followPrompts => '请按照 Nextcloud 界面中的提示操作';
	@override String get browserDidntOpen => '登录页面没有打开？点击这里';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$zh_Hans_CN extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get q => '什么是加密密码？为什么要用两个密码？';
	@override String get a => '你的 Google 或 Microsoft 账号用于访问云端。加密密码会在数据上传到云端之前将其"打乱"。\n即使有人获取了你的 Google 或 Microsoft 账号，你的笔记仍会通过单独的密码加密，保持安全。这为你的数据提供了第二层保护。\n没有你的加密密码，任何人都无法访问服务器上的笔记；但这也意味着，如果你忘记了加密密码，将无法再访问你的数据。';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$zh_Hans_CN extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get q => '我还没有设置加密密码，去哪里获取？';
	@override String get a => '选择一个新的加密密码并在上方输入即可。\nBadNotes 会根据此密码自动生成你的加密密钥。';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$zh_Hans_CN extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get q => '我可以使用与 Google 或 Microsoft 账号相同的密码吗？';
	@override String get a => '请不要这样做。单独的加密密码可以在该账号被他人登录时仍保护你的笔记安全。';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$zh_Hans_CN extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get fill => '拉伸';
	@override String get cover => '覆盖';
	@override String get contain => '适应';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$zh_Hans_CN extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$zh_Hans_CN._(TranslationsZhHansCn root) : this._root = root, super.internal(root);

	final TranslationsZhHansCn _root; // ignore: unused_field

	// Translations
	@override String get none => '空白';
	@override String get college => '窄横线';
	@override String get collegeRtl => '窄横线（反向）';
	@override String get lined => '横线';
	@override String get grid => '方格';
	@override String get dots => '点阵';
	@override String get staffs => '五线谱';
	@override String get tablature => '六线谱';
	@override String get cornell => '康奈尔笔记';
}
