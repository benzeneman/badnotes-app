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
class TranslationsJa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <ja>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsJa _root = this; // ignore: unused_field

	@override 
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$ja common = _Translations$common$ja._(_root);
	@override late final _Translations$home$ja home = _Translations$home$ja._(_root);
	@override late final _Translations$sentry$ja sentry = _Translations$sentry$ja._(_root);
	@override late final _Translations$settings$ja settings = _Translations$settings$ja._(_root);
	@override late final _Translations$logs$ja logs = _Translations$logs$ja._(_root);
	@override late final _Translations$login$ja login = _Translations$login$ja._(_root);
	@override late final _Translations$profile$ja profile = _Translations$profile$ja._(_root);
	@override late final _Translations$appInfo$ja appInfo = _Translations$appInfo$ja._(_root);
	@override late final _Translations$update$ja update = _Translations$update$ja._(_root);
	@override late final _Translations$editor$ja editor = _Translations$editor$ja._(_root);
}

// Path: common
class _Translations$common$ja extends Translations$common$en {
	_Translations$common$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get done => '完了';
	@override String get continueBtn => '続ける';
	@override String get cancel => 'キャンセル';
}

// Path: home
class _Translations$home$ja extends Translations$home$en {
	_Translations$home$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$ja tabs = _Translations$home$tabs$ja._(_root);
	@override late final _Translations$home$titles$ja titles = _Translations$home$titles$ja._(_root);
	@override late final _Translations$home$tooltips$ja tooltips = _Translations$home$tooltips$ja._(_root);
	@override late final _Translations$home$create$ja create = _Translations$home$create$ja._(_root);
	@override String get welcome => 'BadNotes へようこそ';
	@override String get invalidFormat => '選択したファイルには対応していません。sbn、sbn2、sba、pdf のいずれかのファイルを選択してください。';
	@override String get noFiles => 'ファイルが見つかりません';
	@override String get noPreviewAvailable => 'プレビューはありません';
	@override String get createNewNote => '+ ボタンをタップして新しいノートを作成';
	@override String get backFolder => '前のフォルダに戻る';
	@override late final _Translations$home$newFolder$ja newFolder = _Translations$home$newFolder$ja._(_root);
	@override late final _Translations$home$renameNote$ja renameNote = _Translations$home$renameNote$ja._(_root);
	@override late final _Translations$home$moveNote$ja moveNote = _Translations$home$moveNote$ja._(_root);
	@override String get deleteNote => 'ノートを削除';
	@override late final _Translations$home$deleteNoteDialog$ja deleteNoteDialog = _Translations$home$deleteNoteDialog$ja._(_root);
	@override late final _Translations$home$renameFolder$ja renameFolder = _Translations$home$renameFolder$ja._(_root);
	@override late final _Translations$home$deleteFolder$ja deleteFolder = _Translations$home$deleteFolder$ja._(_root);
	@override late final _Translations$home$sort$ja sort = _Translations$home$sort$ja._(_root);
	@override late final _Translations$home$layout$ja layout = _Translations$home$layout$ja._(_root);
}

// Path: sentry
class _Translations$sentry$ja extends Translations$sentry$en {
	_Translations$sentry$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$ja consent = _Translations$sentry$consent$ja._(_root);
}

// Path: settings
class _Translations$settings$ja extends Translations$settings$en {
	_Translations$settings$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$ja prefCategories = _Translations$settings$prefCategories$ja._(_root);
	@override late final _Translations$settings$prefLabels$ja prefLabels = _Translations$settings$prefLabels$ja._(_root);
	@override late final _Translations$settings$prefDescriptions$ja prefDescriptions = _Translations$settings$prefDescriptions$ja._(_root);
	@override late final _Translations$settings$themeModes$ja themeModes = _Translations$settings$themeModes$ja._(_root);
	@override late final _Translations$settings$layoutSizes$ja layoutSizes = _Translations$settings$layoutSizes$ja._(_root);
	@override late final _Translations$settings$accentColorPicker$ja accentColorPicker = _Translations$settings$accentColorPicker$ja._(_root);
	@override String get systemLanguage => '自動';
	@override List<String> get axisDirections => [
		'上',
		'右',
		'下',
		'左',
	];
	@override late final _Translations$settings$reset$ja reset = _Translations$settings$reset$ja._(_root);
	@override String get resyncEverything => 'すべて再同期';
	@override String get openDataDir => 'BadNotes フォルダを開く';
	@override late final _Translations$settings$customDataDir$ja customDataDir = _Translations$settings$customDataDir$ja._(_root);
	@override String get autosaveDisabled => 'しない';
	@override String get shapeRecognitionDisabled => 'しない';
}

// Path: logs
class _Translations$logs$ja extends Translations$logs$en {
	_Translations$logs$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get logs => 'ログ';
	@override String get viewLogs => 'ログを表示';
	@override String get debuggingInfo => 'ログにはデバッグや開発に役立つ情報が含まれています';
	@override String get noLogs => 'ログはありません';
	@override String get useTheApp => 'アプリを使うとここにログが表示されます';
}

// Path: login
class _Translations$login$ja extends Translations$login$en {
	_Translations$login$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ログイン';
	@override late final _Translations$login$form$ja form = _Translations$login$form$ja._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: 'アカウントをお持ちでない場合は、'),
		linkToSignup('今すぐ登録'),
		const TextSpan(text: 'してください。'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: 'ご本人ではありませんか？'),
		undoLogin('別のアカウントを選択'),
		const TextSpan(text: 'してください。'),
	]);
	@override late final _Translations$login$status$ja status = _Translations$login$status$ja._(_root);
	@override late final _Translations$login$ncLoginStep$ja ncLoginStep = _Translations$login$ncLoginStep$ja._(_root);
	@override late final _Translations$login$encLoginStep$ja encLoginStep = _Translations$login$encLoginStep$ja._(_root);
}

// Path: profile
class _Translations$profile$ja extends Translations$profile$en {
	_Translations$profile$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'マイプロフィール';
	@override String get logout => 'ログアウト';
	@override String quotaUsage({required Object total, required Object used, required Object percent}) => '${total} 中 ${used} を使用中（${percent}%）';
	@override String quotaUsageUncapped({required Object used}) => '${used} を使用中';
	@override String get connectedTo => '接続先';
	@override String lastSynced({required Object time}) => '最終同期：${time}';
	@override String get notSyncedYet => 'まだ同期されていません';
	@override String get justNow => 'たった今';
	@override String minutesAgo({required Object n}) => '${n} 分前';
	@override String hoursAgo({required Object n}) => '${n} 時間前';
	@override String filesWaiting({required Object n}) => '${n} 件のファイルが同期待ちです';
	@override String get signInAgainNeeded => '同期を続けるには再度サインインしてください';
	@override String get signInAgain => '再度サインイン';
	@override String wrongAccount({required Object email}) => '${email} を選択してください';
	@override late final _Translations$profile$quickLinks$ja quickLinks = _Translations$profile$quickLinks$ja._(_root);
	@override String get faqTitle => 'よくある質問';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$ja._(_root),
		_Translations$profile$faq$1$ja._(_root),
		_Translations$profile$faq$2$ja._(_root),
		_Translations$profile$faq$3$ja._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$ja extends Translations$appInfo$en {
	_Translations$appInfo$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get debug => 'DEBUG';
}

// Path: update
class _Translations$update$ja extends Translations$update$en {
	_Translations$update$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => 'アップデートがあります';
	@override String get updateAvailableDescription => 'アプリの新しいバージョンが利用できます：';
	@override String get update => 'アップデート';
	@override String get downloadNotAvailableYet => 'お使いのプラットフォーム向けのダウンロードはまだ準備中です。しばらくしてからもう一度ご確認ください。';
}

// Path: editor
class _Translations$editor$ja extends Translations$editor$en {
	_Translations$editor$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$ja toolbar = _Translations$editor$toolbar$ja._(_root);
	@override late final _Translations$editor$pens$ja pens = _Translations$editor$pens$ja._(_root);
	@override late final _Translations$editor$penOptions$ja penOptions = _Translations$editor$penOptions$ja._(_root);
	@override late final _Translations$editor$colors$ja colors = _Translations$editor$colors$ja._(_root);
	@override late final _Translations$editor$imageOptions$ja imageOptions = _Translations$editor$imageOptions$ja._(_root);
	@override late final _Translations$editor$selectionBar$ja selectionBar = _Translations$editor$selectionBar$ja._(_root);
	@override late final _Translations$editor$menu$ja menu = _Translations$editor$menu$ja._(_root);
	@override late final _Translations$editor$photoPdfError$ja photoPdfError = _Translations$editor$photoPdfError$ja._(_root);
	@override late final _Translations$editor$readOnlyBanner$ja readOnlyBanner = _Translations$editor$readOnlyBanner$ja._(_root);
	@override late final _Translations$editor$versionTooNew$ja versionTooNew = _Translations$editor$versionTooNew$ja._(_root);
	@override late final _Translations$editor$quill$ja quill = _Translations$editor$quill$ja._(_root);
	@override late final _Translations$editor$hud$ja hud = _Translations$editor$hud$ja._(_root);
	@override String get pages => 'ページ';
	@override String get untitled => '無題';
	@override String get needsToSaveBeforeExiting => '変更を保存しています… 完了したらエディタを安全に終了できます';
}

// Path: home.tabs
class _Translations$home$tabs$ja extends Translations$home$tabs$en {
	_Translations$home$tabs$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get home => 'ホーム';
	@override String get browse => 'ブラウズ';
	@override String get whiteboard => 'ホワイトボード';
	@override String get settings => '設定';
}

// Path: home.titles
class _Translations$home$titles$ja extends Translations$home$titles$en {
	_Translations$home$titles$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get home => '最近のノート';
	@override String get browse => 'ブラウズ';
	@override String get whiteboard => 'ホワイトボード';
	@override String get settings => '設定';
}

// Path: home.tooltips
class _Translations$home$tooltips$ja extends Translations$home$tooltips$en {
	_Translations$home$tooltips$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get newNote => '新規ノート';
	@override String get showUpdateDialog => 'アップデート情報を表示';
	@override String get exportNote => 'ノートをエクスポート';
}

// Path: home.create
class _Translations$home$create$ja extends Translations$home$create$en {
	_Translations$home$create$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get newNote => '新規ノート';
	@override String get importNote => 'ノートをインポート';
}

// Path: home.newFolder
class _Translations$home$newFolder$ja extends Translations$home$newFolder$en {
	_Translations$home$newFolder$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get newFolder => '新規フォルダ';
	@override String get folderName => 'フォルダ名';
	@override String get create => '作成';
	@override String get folderNameEmpty => 'フォルダ名を入力してください';
	@override String get folderNameContainsSlash => 'フォルダ名にスラッシュは使用できません';
	@override String get folderNameExists => 'フォルダはすでに存在します';
}

// Path: home.renameNote
class _Translations$home$renameNote$ja extends Translations$home$renameNote$en {
	_Translations$home$renameNote$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get renameNote => 'ノート名を変更';
	@override String get noteName => 'ノート名';
	@override String get rename => '名前を変更';
	@override String get noteNameEmpty => 'ノート名を入力してください';
	@override String get noteNameExists => '同じ名前のノートがすでに存在します';
	@override String get noteNameForbiddenCharacters => 'ノート名に使用できない文字が含まれています';
	@override String get noteNameReserved => 'この名前は予約されています';
}

// Path: home.moveNote
class _Translations$home$moveNote$ja extends Translations$home$moveNote$en {
	_Translations$home$moveNote$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get moveNote => 'ノートを移動';
	@override String moveNotes({required Object n}) => '${n} 件のノートを移動';
	@override String moveName({required Object f}) => '${f} を移動';
	@override String get move => '移動';
	@override String renamedTo({required Object newName}) => 'ノート名は ${newName} に変更されます';
	@override String get multipleRenamedTo => '次のノートの名前が変更されます：';
	@override String numberRenamedTo({required Object n}) => '名前の重複を避けるため、${n} 件のノートの名前が変更されます';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$ja extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => '${n} 件のノートを削除';
	@override String deleteName({required Object f}) => '${f} を削除';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '選択したノートを完全に削除しますか？',
		other: '選択したノートを完全に削除しますか？',
	);
	@override String get delete => '削除';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$ja extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => 'フォルダ名を変更';
	@override String get folderName => 'フォルダ名';
	@override String get rename => '名前を変更';
	@override String get folderNameEmpty => 'フォルダ名を入力してください';
	@override String get folderNameContainsSlash => 'フォルダ名にスラッシュは使用できません';
	@override String get folderNameExists => '同じ名前のフォルダがすでに存在します';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$ja extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => 'フォルダを削除';
	@override String deleteName({required Object f}) => '${f} を削除';
	@override String get delete => '削除';
	@override String get alsoDeleteContents => 'フォルダ内のノートもすべて削除する';
}

// Path: home.sort
class _Translations$home$sort$ja extends Translations$home$sort$en {
	_Translations$home$sort$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get sortBy => '並べ替え';
	@override String get nameAToZ => '名前（A→Z）';
	@override String get nameZToA => '名前（Z→A）';
	@override String get lastModifiedNewToOld => '編集日時（新しい順）';
	@override String get lastModifiedOldToNew => '編集日時（古い順）';
}

// Path: home.layout
class _Translations$home$layout$ja extends Translations$home$layout$en {
	_Translations$home$layout$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get layout => 'レイアウト';
	@override String get masonryGrid => 'メイソンリーグリッド';
	@override String get simpleGrid => 'シンプルグリッド';
}

// Path: sentry.consent
class _Translations$sentry$consent$ja extends Translations$sentry$consent$en {
	_Translations$sentry$consent$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'BadNotes の改善に協力しますか？';
	@override late final _Translations$sentry$consent$description$ja description = _Translations$sentry$consent$description$ja._(_root);
	@override late final _Translations$sentry$consent$answers$ja answers = _Translations$sentry$consent$answers$ja._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$ja extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get general => '一般';
	@override String get writing => '書き込み';
	@override String get editor => 'エディタ';
	@override String get performance => 'パフォーマンス';
	@override String get advanced => '詳細設定';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$ja extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get locale => '言語';
	@override String get appTheme => 'アプリのテーマ';
	@override String get platform => 'テーマの種類';
	@override String get layoutSize => 'レイアウトの種類';
	@override String get customAccentColor => 'カスタムアクセントカラー';
	@override String get hyperlegibleFont => 'Atkinson Hyperlegible フォント';
	@override String get shouldCheckForUpdates => 'BadNotes のアップデートを確認';
	@override String get shouldAlwaysAlertForUpdates => 'アップデートをすぐに受け取る';
	@override String get allowInsecureConnections => '安全でない接続を許可';
	@override String get syncOnlyOnWifi => 'Wi-Fi 接続時のみ同期';
	@override String get syncPreviewsOnMobileData => 'モバイルデータでプレビューをアップロード';
	@override String get editorToolbarAlignment => 'ツールバーの位置';
	@override String get editorToolbarShowInFullscreen => '全画面表示でツールバーを表示';
	@override String get editorAutoInvert => 'ダークモードでノートを反転';
	@override String get preferGreyscale => 'グレースケールの色を優先';
	@override String get maxImageSize => '画像の最大サイズ';
	@override String get autoClearWhiteboardOnExit => 'ホワイトボードを自動でクリア';
	@override String get disableEraserAfterUse => '消しゴムを自動で解除';
	@override String get hideFingerDrawingToggle => '指描きの切り替えボタンを隠す';
	@override String get autoDisableFingerDrawingWhenStylusDetected => '指描きを自動で無効化';
	@override String get editorPromptRename => '新規ノートの名前変更を促す';
	@override String get recentColorsDontSavePresets => 'プリセットの色を最近使った色に保存しない';
	@override String get recentColorsLength => '最近使った色の保存数';
	@override String get printPageIndicators => 'ページ番号を印刷';
	@override String get autosave => '自動保存';
	@override String get shapeRecognitionDelay => '図形認識までの時間';
	@override String get autoStraightenLines => '線を自動でまっすぐにする';
	@override String get customDataDir => 'BadNotes フォルダの場所';
	@override String get sentry => 'エラー報告';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$ja extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => 'オフ：モバイルデータでも同期します。オン：Wi-Fi 接続まで同期を待ちます';
	@override String get syncPreviewsOnMobileData => '通信量を節約するため、通常ノートのサムネイルは Wi-Fi 接続まで待機します';
	@override String get hyperlegibleFont => 'ロービジョンのユーザー向けに読みやすさを高めます';
	@override String get allowInsecureConnections => '（非推奨）自己署名または信頼されていない証明書のサーバーへの接続を BadNotes に許可します';
	@override String get preferGreyscale => '電子ペーパー向け';
	@override String get autoClearWhiteboardOnExit => 'アプリを終了するとホワイトボードをクリアします';
	@override String get disableEraserAfterUse => '消しゴムを使った後、自動でペンに戻ります';
	@override String get maxImageSize => 'これより大きい画像は圧縮されます';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$ja hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$ja._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'スタイラスを検出したら指描きをオフにします';
	@override String get editorPromptRename => 'ノート名は後からいつでも変更できます';
	@override String get printPageIndicators => 'エクスポート時にページ番号を表示します';
	@override String get autosave => '少し時間をおいて自動保存するか、保存しないかを選びます';
	@override String get shapeRecognitionDelay => 'インクが図形に変わるまでペンを止めておく時間';
	@override String get autoStraightenLines => '図形ペンを使わなくても長い線をまっすぐにします';
	@override String get shouldAlwaysAlertForUpdates => 'アップデートが公開されたらすぐに通知します';
	@override late final _Translations$settings$prefDescriptions$sentry$ja sentry = _Translations$settings$prefDescriptions$sentry$ja._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$ja extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get system => 'システム';
	@override String get light => 'ライト';
	@override String get dark => 'ダーク';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$ja extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get auto => '自動';
	@override String get phone => 'スマートフォン';
	@override String get tablet => 'タブレット';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$ja extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => '色を選択';
}

// Path: settings.reset
class _Translations$settings$reset$ja extends Translations$settings$reset$en {
	_Translations$settings$reset$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'この設定をリセットしますか？';
	@override String get button => 'リセット';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$ja extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'キャンセル';
	@override String get select => '選択';
	@override String get mustBeEmpty => '空のフォルダを選択してください';
	@override String get mustBeDoneSyncing => 'フォルダを変更する前に同期が完了していることを確認してください';
	@override String get unsupported => 'この機能は現在開発者向けです。使用するとデータが失われる可能性が高いです。';
}

// Path: login.form
class _Translations$login$form$ja extends Translations$login$form$en {
	_Translations$login$form$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'ログインすると、'),
		linkToPrivacyPolicy('プライバシーポリシー'),
		const TextSpan(text: 'に同意したものとみなされます。'),
	]);
}

// Path: login.status
class _Translations$login$status$ja extends Translations$login$status$en {
	_Translations$login$status$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => 'ログアウト中';
	@override String get tapToLogin => 'タップして Google Drive と同期';
	@override String hi({required Object u}) => 'こんにちは、${u} さん';
	@override String get almostDone => '同期の準備はほぼ完了です。タップしてログインを完了してください';
	@override String get loggedIn => '同期はオンです';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$ja extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => 'データの保存先を選択してください：';
	@override String get cloudStorage => 'Google Drive または OneDrive';
	@override String get loginWithGoogleDrive => 'Google Drive で続ける';
	@override String get loginWithOneDrive => 'OneDrive で続ける';
	@override String get cloudLoginFailed => 'サインインできませんでした';
	@override String get comingSoon => '近日公開';
	@override String get badnotesNcServer => 'BadNotes の Nextcloud サーバー';
	@override String get otherNcServer => 'その他の Nextcloud サーバー';
	@override String get serverUrl => 'サーバー URL';
	@override String get loginWithBadNotes => 'BadNotes でログイン';
	@override String get loginWithNextcloud => 'Nextcloud でログイン';
	@override late final _Translations$login$ncLoginStep$loginFlow$ja loginFlow = _Translations$login$ncLoginStep$loginFlow$ja._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$ja extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => 'データを保護するため、暗号化パスワードを入力してください：';
	@override String get newToBadNotes => 'BadNotes を初めてお使いの場合は、新しい暗号化パスワードを入力するだけです。';
	@override String get encPassword => '暗号化パスワード';
	@override String get encFaqTitle => 'よくある質問';
	@override String get wrongEncPassword => '入力したパスワードで復号できませんでした。もう一度入力してください。';
	@override String get connectionFailed => 'サーバーへの接続中に問題が発生しました。しばらくしてからもう一度お試しください。';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$ja._(_root),
		_Translations$login$encLoginStep$encFaq$1$ja._(_root),
		_Translations$login$encLoginStep$encFaq$2$ja._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$ja extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => 'サーバーのホームページ';
	@override String get deleteAccount => 'アカウントを削除';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$ja extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get q => 'ログアウトするとノートは消えますか？';
	@override String get a => 'いいえ。ノートはデバイスとサーバーの両方に残ります。再度ログインするまでサーバーとは同期されません。データを失わないよう、ログアウトする前に同期が完了していることを確認してください（同期の進行状況はホーム画面で確認できます）。';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$ja extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get q => 'ノートはどこに保存されますか？';
	@override String get a => 'Google Drive の「BadNotes」フォルダ、または OneDrive の「Apps/BadNotes」に保存されます。ファイルは暗号化されているため、BadNotes でしか開けません。';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$ja extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get q => '暗号化パスワードを変更するにはどうすればよいですか？';
	@override String get a => '0. 同期が完了していることを確認します（同期の進行状況はホーム画面で確認できます）。\n1. BadNotes からログアウトします。\n2. Google Drive または OneDrive の「BadNotes」フォルダを削除します。これによりクラウド上のノートはすべて削除されますが、デバイス上のノートは削除されません。\n3. BadNotes に再度ログインします。ログイン時に新しい暗号化パスワードを設定できます。\n4. 他のデバイスでも BadNotes からログアウトし、再度ログインするのを忘れないでください。';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$ja extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get q => 'アカウントを削除するにはどうすればよいですか？';
	@override String get a => 'BadNotes には独自のアカウントはありません。ログアウトしてから、Google Drive または OneDrive の「BadNotes」フォルダを削除してください。\nBadNotes のアクセス権も取り消すには、myaccount.google.com/permissions（Google）または account.live.com/consent/Manage（Microsoft）にアクセスしてください。';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$ja extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => '色の切り替え (Ctrl C)';
	@override String get select => '選択';
	@override String get toggleEraser => '消しゴムの切り替え (Ctrl E)';
	@override String get photo => '画像';
	@override String get text => 'テキスト';
	@override String get toggleFingerDrawing => '指描きの切り替え (Ctrl F)';
	@override String get undo => '元に戻す';
	@override String get redo => 'やり直す';
	@override String get export => 'エクスポート (Ctrl Shift S)';
	@override String get exportAs => 'エクスポート形式：';
	@override String get fullscreen => '全画面表示の切り替え (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$ja extends Translations$editor$pens$en {
	_Translations$editor$pens$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => '万年筆';
	@override String get ballpointPen => 'ボールペン';
	@override String get highlighter => '蛍光ペン';
	@override String get pencil => '鉛筆';
	@override String get shapePen => '図形ペン';
	@override String get laserPointer => 'レーザーポインター';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$ja extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get size => 'サイズ';
}

// Path: editor.colors
class _Translations$editor$colors$ja extends Translations$editor$colors$en {
	_Translations$editor$colors$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => 'カラーピッカー';
	@override String customBrightnessHue({required Object b, required Object h}) => 'カスタム（${b} ${h}）';
	@override String customHue({required Object h}) => 'カスタム（${h}）';
	@override String get dark => '暗い';
	@override String get light => '明るい';
	@override String get black => '黒';
	@override String get darkGrey => 'ダークグレー';
	@override String get grey => 'グレー';
	@override String get lightGrey => 'ライトグレー';
	@override String get white => '白';
	@override String get red => '赤';
	@override String get green => '緑';
	@override String get cyan => 'シアン';
	@override String get blue => '青';
	@override String get yellow => '黄';
	@override String get purple => '紫';
	@override String get pink => 'ピンク';
	@override String get orange => 'オレンジ';
	@override String get pastelRed => 'パステルレッド';
	@override String get pastelOrange => 'パステルオレンジ';
	@override String get pastelYellow => 'パステルイエロー';
	@override String get pastelGreen => 'パステルグリーン';
	@override String get pastelCyan => 'パステルシアン';
	@override String get pastelBlue => 'パステルブルー';
	@override String get pastelPurple => 'パステルパープル';
	@override String get pastelPink => 'パステルピンク';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$ja extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '画像のオプション';
	@override String get invertible => '反転可能';
	@override String get download => 'ダウンロード';
	@override String get setAsBackground => '背景に設定';
	@override String get removeAsBackground => '背景から削除';
	@override String get delete => '削除';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$ja extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get delete => '削除';
	@override String get duplicate => '複製';
}

// Path: editor.menu
class _Translations$editor$menu$ja extends Translations$editor$menu$en {
	_Translations$editor$menu$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => 'ページ ${page}/${totalPages} をクリア';
	@override String get clearAllPages => 'すべてのページをクリア';
	@override String get insertPage => '下にページを挿入';
	@override String get duplicatePage => 'ページを複製';
	@override String get deletePage => 'ページを削除';
	@override String get lineHeight => '行の高さ';
	@override String get lineHeightDescription => '入力したノートの文字サイズも変わります';
	@override String get lineThickness => '線の太さ';
	@override String get lineThicknessDescription => '背景の線の太さ';
	@override String get backgroundImageFit => '背景画像の配置';
	@override String get backgroundPattern => '背景の模様';
	@override String get import => 'インポート';
	@override String get watchServer => 'サーバーの更新を監視';
	@override String get watchServerReadOnly => 'サーバーの監視中は編集できません';
	@override late final _Translations$editor$menu$boxFits$ja boxFits = _Translations$editor$menu$boxFits$ja._(_root);
	@override late final _Translations$editor$menu$bgPatterns$ja bgPatterns = _Translations$editor$menu$bgPatterns$ja._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$ja extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'エラー';
	@override String get message => 'PDF ファイルは画像として追加できません。「${_root.editor.menu.import} > PDF」を使用してください。';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$ja extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '読み取り専用モード';
	@override String get watchingServer => '現在サーバーの更新を監視しています。このモードでは編集できません。';
	@override String get corrupted => 'ノートを読み込めませんでした。破損しているか、まだダウンロード中の可能性があります。';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$ja extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'このノートは新しいバージョンの BadNotes で編集されています';
	@override String get subtitle => 'このノートを編集すると、一部の情報が失われる可能性があります。それでも編集しますか？';
	@override String get allowEditing => '編集を許可';
}

// Path: editor.quill
class _Translations$editor$quill$ja extends Translations$editor$quill$en {
	_Translations$editor$quill$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => 'ここに入力…';
}

// Path: editor.hud
class _Translations$editor$hud$ja extends Translations$editor$hud$en {
	_Translations$editor$hud$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => 'ズームのロックを解除';
	@override String get lockZoom => 'ズームをロック';
	@override String get unlockSingleFingerPan => '1 本指でのパンを有効化';
	@override String get lockSingleFingerPan => '1 本指でのパンを無効化';
	@override String get unlockAxisAlignedPan => '水平・垂直方向へのパン固定を解除';
	@override String get lockAxisAlignedPan => 'パンを水平・垂直方向に固定';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$ja extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get question => '予期しないエラーを自動で報告しますか？問題をより早く見つけて修正するのに役立ちます。';
	@override String get scope => 'レポートにはエラーやお使いのデバイスに関する情報が含まれる場合があります。個人情報はできる限り除外していますが、一部が残る可能性があります。';
	@override String get currentlyOff => '同意すると、アプリの再起動後にエラー報告が有効になります。';
	@override String get currentlyOn => '同意を取り消した場合は、アプリを再起動するとエラー報告が無効になります。';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: '詳しくは'),
		link('プライバシーポリシー'),
		const TextSpan(text: 'をご覧ください。'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$ja extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get yes => 'はい';
	@override String get no => 'いいえ';
	@override String get later => '後で確認する';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$ja extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get shown => '誤って切り替えるのを防ぎます';
	@override String get fixedOn => '指描きは常に有効です';
	@override String get fixedOff => '指描きは常に無効です';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$ja extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get active => '有効';
	@override String get inactive => '無効';
	@override String get activeUntilRestart => 'アプリを再起動するまで有効';
	@override String get inactiveUntilRestart => 'アプリを再起動するまで無効';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$ja extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => 'BadNotes による Nextcloud アカウントへのアクセスを許可してください';
	@override String get followPrompts => 'Nextcloud の画面の指示に従ってください';
	@override String get browserDidntOpen => 'ログインページが開きませんか？ここをクリック';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$ja extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get q => '暗号化パスワードとは何ですか？なぜパスワードが 2 つ必要なのですか？';
	@override String get a => 'Google または Microsoft アカウントはクラウドへのアクセスに使用されます。暗号化パスワードは、データがクラウドに届く前にデータを「スクランブル」します。\n誰かがあなたの Google または Microsoft アカウントにアクセスできたとしても、ノートは別のパスワードで暗号化されたまま安全に保たれます。これにより、データを守るための第 2 のセキュリティ層が加わります。\n暗号化パスワードがなければ、誰もサーバー上のノートにアクセスできません。ただしこれは、暗号化パスワードを忘れるとデータにアクセスできなくなることも意味します。';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$ja extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get q => 'まだ暗号化パスワードを設定していません。どこで入手できますか？';
	@override String get a => '新しい暗号化パスワードを決めて、上に入力してください。\nBadNotes がこのパスワードから暗号化キーを自動で生成します。';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$ja extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get q => 'Google または Microsoft アカウントと同じパスワードを使えますか？';
	@override String get a => 'おすすめしません。別の暗号化パスワードにしておけば、そのアカウントに誰かが侵入してもノートは安全です。';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$ja extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get fill => '引き伸ばす';
	@override String get cover => '全体を覆う';
	@override String get contain => '全体を表示';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$ja extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get none => '無地';
	@override String get college => '罫線（大学ノート）';
	@override String get collegeRtl => '罫線（大学ノート・左右反転）';
	@override String get lined => '罫線';
	@override String get grid => '方眼';
	@override String get dots => 'ドット';
	@override String get staffs => '五線譜';
	@override String get tablature => 'タブ譜';
	@override String get cornell => 'コーネル式';
}
