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
class TranslationsVi extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsVi({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.vi,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <vi>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsVi _root = this; // ignore: unused_field

	@override 
	TranslationsVi $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsVi(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$vi common = _Translations$common$vi._(_root);
	@override late final _Translations$home$vi home = _Translations$home$vi._(_root);
	@override late final _Translations$sentry$vi sentry = _Translations$sentry$vi._(_root);
	@override late final _Translations$settings$vi settings = _Translations$settings$vi._(_root);
	@override late final _Translations$logs$vi logs = _Translations$logs$vi._(_root);
	@override late final _Translations$login$vi login = _Translations$login$vi._(_root);
	@override late final _Translations$profile$vi profile = _Translations$profile$vi._(_root);
	@override late final _Translations$appInfo$vi appInfo = _Translations$appInfo$vi._(_root);
	@override late final _Translations$update$vi update = _Translations$update$vi._(_root);
	@override late final _Translations$editor$vi editor = _Translations$editor$vi._(_root);
}

// Path: common
class _Translations$common$vi extends Translations$common$en {
	_Translations$common$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get done => 'Xong';
	@override String get continueBtn => 'Tiếp tục';
	@override String get cancel => 'Hủy';
}

// Path: home
class _Translations$home$vi extends Translations$home$en {
	_Translations$home$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$vi tabs = _Translations$home$tabs$vi._(_root);
	@override late final _Translations$home$titles$vi titles = _Translations$home$titles$vi._(_root);
	@override late final _Translations$home$tooltips$vi tooltips = _Translations$home$tooltips$vi._(_root);
	@override late final _Translations$home$create$vi create = _Translations$home$create$vi._(_root);
	@override String get welcome => 'Chào mừng đến với BadNotes';
	@override String get invalidFormat => 'Tệp bạn chọn không được hỗ trợ. Vui lòng chọn tệp sbn, sbn2, sba hoặc pdf.';
	@override String get noFiles => 'Không có tệp nào';
	@override String get noPreviewAvailable => 'Không có bản xem trước';
	@override String get createNewNote => 'Nhấn nút + để tạo ghi chú mới';
	@override String get backFolder => 'Quay lại thư mục trước';
	@override late final _Translations$home$newFolder$vi newFolder = _Translations$home$newFolder$vi._(_root);
	@override late final _Translations$home$renameNote$vi renameNote = _Translations$home$renameNote$vi._(_root);
	@override late final _Translations$home$moveNote$vi moveNote = _Translations$home$moveNote$vi._(_root);
	@override String get deleteNote => 'Xóa ghi chú';
	@override late final _Translations$home$deleteNoteDialog$vi deleteNoteDialog = _Translations$home$deleteNoteDialog$vi._(_root);
	@override late final _Translations$home$renameFolder$vi renameFolder = _Translations$home$renameFolder$vi._(_root);
	@override late final _Translations$home$deleteFolder$vi deleteFolder = _Translations$home$deleteFolder$vi._(_root);
	@override late final _Translations$home$sort$vi sort = _Translations$home$sort$vi._(_root);
	@override late final _Translations$home$layout$vi layout = _Translations$home$layout$vi._(_root);
}

// Path: sentry
class _Translations$sentry$vi extends Translations$sentry$en {
	_Translations$sentry$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$vi consent = _Translations$sentry$consent$vi._(_root);
}

// Path: settings
class _Translations$settings$vi extends Translations$settings$en {
	_Translations$settings$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$vi prefCategories = _Translations$settings$prefCategories$vi._(_root);
	@override late final _Translations$settings$prefLabels$vi prefLabels = _Translations$settings$prefLabels$vi._(_root);
	@override late final _Translations$settings$prefDescriptions$vi prefDescriptions = _Translations$settings$prefDescriptions$vi._(_root);
	@override late final _Translations$settings$themeModes$vi themeModes = _Translations$settings$themeModes$vi._(_root);
	@override late final _Translations$settings$layoutSizes$vi layoutSizes = _Translations$settings$layoutSizes$vi._(_root);
	@override late final _Translations$settings$accentColorPicker$vi accentColorPicker = _Translations$settings$accentColorPicker$vi._(_root);
	@override String get systemLanguage => 'Tự động';
	@override List<String> get axisDirections => [
		'Trên',
		'Phải',
		'Dưới',
		'Trái',
	];
	@override late final _Translations$settings$reset$vi reset = _Translations$settings$reset$vi._(_root);
	@override String get resyncEverything => 'Đồng bộ lại tất cả';
	@override String get openDataDir => 'Mở thư mục BadNotes';
	@override late final _Translations$settings$customDataDir$vi customDataDir = _Translations$settings$customDataDir$vi._(_root);
	@override String get autosaveDisabled => 'Không bao giờ';
	@override String get shapeRecognitionDisabled => 'Không bao giờ';
}

// Path: logs
class _Translations$logs$vi extends Translations$logs$en {
	_Translations$logs$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get logs => 'Nhật ký';
	@override String get viewLogs => 'Xem nhật ký';
	@override String get debuggingInfo => 'Nhật ký chứa thông tin hữu ích cho việc gỡ lỗi và phát triển';
	@override String get noLogs => 'Chưa có nhật ký nào!';
	@override String get useTheApp => 'Nhật ký sẽ xuất hiện ở đây khi bạn dùng ứng dụng';
}

// Path: login
class _Translations$login$vi extends Translations$login$en {
	_Translations$login$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Đăng nhập';
	@override late final _Translations$login$form$vi form = _Translations$login$form$vi._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: 'Chưa có tài khoản? '),
		linkToSignup('Đăng ký ngay'),
		const TextSpan(text: '!'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: 'Không phải bạn? '),
		undoLogin('Chọn tài khoản khác'),
		const TextSpan(text: '.'),
	]);
	@override late final _Translations$login$status$vi status = _Translations$login$status$vi._(_root);
	@override late final _Translations$login$ncLoginStep$vi ncLoginStep = _Translations$login$ncLoginStep$vi._(_root);
	@override late final _Translations$login$encLoginStep$vi encLoginStep = _Translations$login$encLoginStep$vi._(_root);
}

// Path: profile
class _Translations$profile$vi extends Translations$profile$en {
	_Translations$profile$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Hồ sơ của tôi';
	@override String get logout => 'Đăng xuất';
	@override String quotaUsage({required Object used, required Object total, required Object percent}) => 'Bạn đang dùng ${used} trên ${total} (${percent}%)';
	@override String quotaUsageUncapped({required Object used}) => 'Bạn đang dùng ${used}';
	@override String get connectedTo => 'Đã kết nối với';
	@override String lastSynced({required Object time}) => 'Đồng bộ lần cuối ${time}';
	@override String get notSyncedYet => 'Chưa đồng bộ';
	@override String get justNow => 'vừa xong';
	@override String minutesAgo({required Object n}) => '${n} phút trước';
	@override String hoursAgo({required Object n}) => '${n} giờ trước';
	@override String filesWaiting({required Object n}) => '${n} tệp đang chờ đồng bộ';
	@override String get signInAgainNeeded => 'Đăng nhập lại để tiếp tục đồng bộ';
	@override String get signInAgain => 'Đăng nhập lại';
	@override String wrongAccount({required Object email}) => 'Vui lòng chọn ${email}';
	@override late final _Translations$profile$quickLinks$vi quickLinks = _Translations$profile$quickLinks$vi._(_root);
	@override String get faqTitle => 'Câu hỏi thường gặp';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$vi._(_root),
		_Translations$profile$faq$1$vi._(_root),
		_Translations$profile$faq$2$vi._(_root),
		_Translations$profile$faq$3$vi._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$vi extends Translations$appInfo$en {
	_Translations$appInfo$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get debug => 'DEBUG';
}

// Path: update
class _Translations$update$vi extends Translations$update$en {
	_Translations$update$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => 'Có bản cập nhật';
	@override String get updateAvailableDescription => 'Đã có phiên bản mới của ứng dụng:';
	@override String get update => 'Cập nhật';
	@override String get downloadNotAvailableYet => 'Bản tải xuống cho nền tảng của bạn chưa sẵn sàng. Vui lòng quay lại sau ít phút.';
}

// Path: editor
class _Translations$editor$vi extends Translations$editor$en {
	_Translations$editor$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$vi toolbar = _Translations$editor$toolbar$vi._(_root);
	@override late final _Translations$editor$pens$vi pens = _Translations$editor$pens$vi._(_root);
	@override late final _Translations$editor$penOptions$vi penOptions = _Translations$editor$penOptions$vi._(_root);
	@override late final _Translations$editor$colors$vi colors = _Translations$editor$colors$vi._(_root);
	@override late final _Translations$editor$imageOptions$vi imageOptions = _Translations$editor$imageOptions$vi._(_root);
	@override late final _Translations$editor$selectionBar$vi selectionBar = _Translations$editor$selectionBar$vi._(_root);
	@override late final _Translations$editor$menu$vi menu = _Translations$editor$menu$vi._(_root);
	@override late final _Translations$editor$photoPdfError$vi photoPdfError = _Translations$editor$photoPdfError$vi._(_root);
	@override late final _Translations$editor$readOnlyBanner$vi readOnlyBanner = _Translations$editor$readOnlyBanner$vi._(_root);
	@override late final _Translations$editor$versionTooNew$vi versionTooNew = _Translations$editor$versionTooNew$vi._(_root);
	@override late final _Translations$editor$quill$vi quill = _Translations$editor$quill$vi._(_root);
	@override late final _Translations$editor$hud$vi hud = _Translations$editor$hud$vi._(_root);
	@override String get pages => 'Trang';
	@override String get untitled => 'Không có tiêu đề';
	@override String get needsToSaveBeforeExiting => 'Đang lưu thay đổi… Bạn có thể thoát trình soạn thảo khi lưu xong';
}

// Path: home.tabs
class _Translations$home$tabs$vi extends Translations$home$tabs$en {
	_Translations$home$tabs$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get home => 'Trang chủ';
	@override String get browse => 'Duyệt';
	@override String get whiteboard => 'Bảng trắng';
	@override String get settings => 'Cài đặt';
}

// Path: home.titles
class _Translations$home$titles$vi extends Translations$home$titles$en {
	_Translations$home$titles$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get home => 'Ghi chú gần đây';
	@override String get browse => 'Duyệt';
	@override String get whiteboard => 'Bảng trắng';
	@override String get settings => 'Cài đặt';
}

// Path: home.tooltips
class _Translations$home$tooltips$vi extends Translations$home$tooltips$en {
	_Translations$home$tooltips$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Ghi chú mới';
	@override String get showUpdateDialog => 'Hiện hộp thoại cập nhật';
	@override String get exportNote => 'Xuất ghi chú';
}

// Path: home.create
class _Translations$home$create$vi extends Translations$home$create$en {
	_Translations$home$create$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Ghi chú mới';
	@override String get importNote => 'Nhập ghi chú';
}

// Path: home.newFolder
class _Translations$home$newFolder$vi extends Translations$home$newFolder$en {
	_Translations$home$newFolder$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get newFolder => 'Thư mục mới';
	@override String get folderName => 'Tên thư mục';
	@override String get create => 'Tạo';
	@override String get folderNameEmpty => 'Tên thư mục không được để trống';
	@override String get folderNameContainsSlash => 'Tên thư mục không được chứa dấu gạch chéo';
	@override String get folderNameExists => 'Thư mục đã tồn tại';
}

// Path: home.renameNote
class _Translations$home$renameNote$vi extends Translations$home$renameNote$en {
	_Translations$home$renameNote$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get renameNote => 'Đổi tên ghi chú';
	@override String get noteName => 'Tên ghi chú';
	@override String get rename => 'Đổi tên';
	@override String get noteNameEmpty => 'Tên ghi chú không được để trống';
	@override String get noteNameExists => 'Đã có ghi chú trùng tên';
	@override String get noteNameForbiddenCharacters => 'Tên ghi chú chứa ký tự không hợp lệ';
	@override String get noteNameReserved => 'Tên ghi chú này đã được dành riêng';
}

// Path: home.moveNote
class _Translations$home$moveNote$vi extends Translations$home$moveNote$en {
	_Translations$home$moveNote$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get moveNote => 'Di chuyển ghi chú';
	@override String moveNotes({required Object n}) => 'Di chuyển ${n} ghi chú';
	@override String moveName({required Object f}) => 'Di chuyển ${f}';
	@override String get move => 'Di chuyển';
	@override String renamedTo({required Object newName}) => 'Ghi chú sẽ được đổi tên thành ${newName}';
	@override String get multipleRenamedTo => 'Các ghi chú sau sẽ được đổi tên:';
	@override String numberRenamedTo({required Object n}) => '${n} ghi chú sẽ được đổi tên để tránh trùng lặp';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$vi extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => 'Xóa ${n} ghi chú';
	@override String deleteName({required Object f}) => 'Xóa ${f}';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('vi'))(n,
		one: 'Xóa vĩnh viễn ghi chú đã chọn?',
		other: 'Xóa vĩnh viễn các ghi chú đã chọn?',
	);
	@override String get delete => 'Xóa';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$vi extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => 'Đổi tên thư mục';
	@override String get folderName => 'Tên thư mục';
	@override String get rename => 'Đổi tên';
	@override String get folderNameEmpty => 'Tên thư mục không được để trống';
	@override String get folderNameContainsSlash => 'Tên thư mục không được chứa dấu gạch chéo';
	@override String get folderNameExists => 'Đã có thư mục trùng tên';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$vi extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => 'Xóa thư mục';
	@override String deleteName({required Object f}) => 'Xóa ${f}';
	@override String get delete => 'Xóa';
	@override String get alsoDeleteContents => 'Xóa cả mọi ghi chú trong thư mục này';
}

// Path: home.sort
class _Translations$home$sort$vi extends Translations$home$sort$en {
	_Translations$home$sort$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get sortBy => 'Sắp xếp theo';
	@override String get nameAToZ => 'Tên (A-Z)';
	@override String get nameZToA => 'Tên (Z-A)';
	@override String get lastModifiedNewToOld => 'Ngày sửa (Mới nhất trước)';
	@override String get lastModifiedOldToNew => 'Ngày sửa (Cũ nhất trước)';
}

// Path: home.layout
class _Translations$home$layout$vi extends Translations$home$layout$en {
	_Translations$home$layout$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get layout => 'Bố cục';
	@override String get masonryGrid => 'Lưới so le';
	@override String get simpleGrid => 'Lưới đơn giản';
}

// Path: sentry.consent
class _Translations$sentry$consent$vi extends Translations$sentry$consent$en {
	_Translations$sentry$consent$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Giúp cải thiện BadNotes?';
	@override late final _Translations$sentry$consent$description$vi description = _Translations$sentry$consent$description$vi._(_root);
	@override late final _Translations$sentry$consent$answers$vi answers = _Translations$sentry$consent$answers$vi._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$vi extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get general => 'Chung';
	@override String get writing => 'Viết';
	@override String get editor => 'Trình soạn thảo';
	@override String get performance => 'Hiệu năng';
	@override String get advanced => 'Nâng cao';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$vi extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get locale => 'Ngôn ngữ';
	@override String get appTheme => 'Giao diện ứng dụng';
	@override String get platform => 'Kiểu giao diện';
	@override String get layoutSize => 'Kiểu bố cục';
	@override String get customAccentColor => 'Màu nhấn tùy chỉnh';
	@override String get hyperlegibleFont => 'Phông chữ Atkinson Hyperlegible';
	@override String get shouldCheckForUpdates => 'Kiểm tra cập nhật BadNotes';
	@override String get shouldAlwaysAlertForUpdates => 'Cập nhật nhanh hơn';
	@override String get allowInsecureConnections => 'Cho phép kết nối không an toàn';
	@override String get syncOnlyOnWifi => 'Chỉ đồng bộ qua Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'Tải bản xem trước lên bằng dữ liệu di động';
	@override String get editorToolbarAlignment => 'Vị trí thanh công cụ';
	@override String get editorToolbarShowInFullscreen => 'Hiện thanh công cụ khi toàn màn hình';
	@override String get editorAutoInvert => 'Đảo màu ghi chú ở chế độ tối';
	@override String get preferGreyscale => 'Ưu tiên màu xám';
	@override String get maxImageSize => 'Kích thước ảnh tối đa';
	@override String get autoClearWhiteboardOnExit => 'Tự động xóa bảng trắng';
	@override String get disableEraserAfterUse => 'Tự động tắt tẩy';
	@override String get hideFingerDrawingToggle => 'Ẩn nút vẽ bằng ngón tay';
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Tự động tắt vẽ bằng ngón tay';
	@override String get editorPromptRename => 'Nhắc đổi tên ghi chú mới';
	@override String get recentColorsDontSavePresets => 'Không lưu màu có sẵn vào màu gần đây';
	@override String get recentColorsLength => 'Số màu gần đây được lưu';
	@override String get printPageIndicators => 'In số trang';
	@override String get autosave => 'Tự động lưu';
	@override String get shapeRecognitionDelay => 'Độ trễ nhận dạng hình';
	@override String get autoStraightenLines => 'Tự động làm thẳng nét';
	@override String get customDataDir => 'Thư mục BadNotes tùy chỉnh';
	@override String get sentry => 'Báo cáo lỗi';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$vi extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => 'Tắt: ghi chú đồng bộ cả qua dữ liệu di động. Bật: chờ có Wi-Fi mới đồng bộ';
	@override String get syncPreviewsOnMobileData => 'Ảnh thu nhỏ của ghi chú thường chờ Wi-Fi để tiết kiệm dữ liệu';
	@override String get hyperlegibleFont => 'Dễ đọc hơn cho người có thị lực kém';
	@override String get allowInsecureConnections => '(Không khuyến nghị) Cho phép BadNotes kết nối tới máy chủ có chứng chỉ tự ký/không tin cậy';
	@override String get preferGreyscale => 'Dành cho màn hình e-ink';
	@override String get autoClearWhiteboardOnExit => 'Xóa bảng trắng sau khi bạn thoát ứng dụng';
	@override String get disableEraserAfterUse => 'Tự động chuyển về bút sau khi dùng tẩy';
	@override String get maxImageSize => 'Ảnh lớn hơn sẽ được nén';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$vi hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$vi._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Tắt vẽ bằng ngón tay khi phát hiện bút cảm ứng';
	@override String get editorPromptRename => 'Bạn luôn có thể đổi tên ghi chú sau';
	@override String get printPageIndicators => 'Hiện số trang trong tệp xuất';
	@override String get autosave => 'Tự động lưu sau một lúc, hoặc không bao giờ';
	@override String get shapeRecognitionDelay => 'Thời gian giữ yên bút trước khi nét vẽ chuyển thành hình';
	@override String get autoStraightenLines => 'Làm thẳng các nét dài mà không cần dùng bút hình';
	@override String get shouldAlwaysAlertForUpdates => 'Báo cho tôi ngay khi có bản cập nhật';
	@override late final _Translations$settings$prefDescriptions$sentry$vi sentry = _Translations$settings$prefDescriptions$sentry$vi._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$vi extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get system => 'Hệ thống';
	@override String get light => 'Sáng';
	@override String get dark => 'Tối';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$vi extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get auto => 'Tự động';
	@override String get phone => 'Điện thoại';
	@override String get tablet => 'Máy tính bảng';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$vi extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => 'Chọn màu';
}

// Path: settings.reset
class _Translations$settings$reset$vi extends Translations$settings$reset$en {
	_Translations$settings$reset$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Đặt lại cài đặt này?';
	@override String get button => 'Đặt lại';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$vi extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Hủy';
	@override String get select => 'Chọn';
	@override String get mustBeEmpty => 'Thư mục được chọn phải trống';
	@override String get mustBeDoneSyncing => 'Hãy đảm bảo đồng bộ đã xong trước khi đổi thư mục';
	@override String get unsupported => 'Tính năng này hiện chỉ dành cho nhà phát triển. Sử dụng nó có thể làm mất dữ liệu.';
}

// Path: login.form
class _Translations$login$form$vi extends Translations$login$form$en {
	_Translations$login$form$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'Khi đăng nhập, bạn đồng ý với '),
		linkToPrivacyPolicy('Chính sách quyền riêng tư'),
		const TextSpan(text: '.'),
	]);
}

// Path: login.status
class _Translations$login$status$vi extends Translations$login$status$en {
	_Translations$login$status$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => 'Đã đăng xuất';
	@override String get tapToLogin => 'Nhấn để đồng bộ với Google Drive';
	@override String hi({required Object u}) => 'Xin chào, ${u}!';
	@override String get almostDone => 'Sắp sẵn sàng đồng bộ, nhấn để hoàn tất đăng nhập';
	@override String get loggedIn => 'Đồng bộ đang bật';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$vi extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => 'Chọn nơi bạn muốn lưu dữ liệu:';
	@override String get cloudStorage => 'Google Drive hoặc OneDrive';
	@override String get loginWithGoogleDrive => 'Tiếp tục với Google Drive';
	@override String get loginWithOneDrive => 'Tiếp tục với OneDrive';
	@override String get cloudLoginFailed => 'Không thể đăng nhập';
	@override String get comingSoon => 'Sắp ra mắt';
	@override String get badnotesNcServer => 'Máy chủ Nextcloud của BadNotes';
	@override String get otherNcServer => 'Máy chủ Nextcloud khác';
	@override String get serverUrl => 'URL máy chủ';
	@override String get loginWithBadNotes => 'Đăng nhập bằng BadNotes';
	@override String get loginWithNextcloud => 'Đăng nhập bằng Nextcloud';
	@override late final _Translations$login$ncLoginStep$loginFlow$vi loginFlow = _Translations$login$ncLoginStep$loginFlow$vi._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$vi extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => 'Để bảo vệ dữ liệu, vui lòng nhập mật khẩu mã hóa của bạn:';
	@override String get newToBadNotes => 'Mới dùng BadNotes? Chỉ cần nhập một mật khẩu mã hóa mới.';
	@override String get encPassword => 'Mật khẩu mã hóa';
	@override String get encFaqTitle => 'Câu hỏi thường gặp';
	@override String get wrongEncPassword => 'Giải mã thất bại với mật khẩu đã nhập. Vui lòng thử nhập lại.';
	@override String get connectionFailed => 'Đã xảy ra lỗi khi kết nối tới máy chủ. Vui lòng thử lại sau.';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$vi._(_root),
		_Translations$login$encLoginStep$encFaq$1$vi._(_root),
		_Translations$login$encLoginStep$encFaq$2$vi._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$vi extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => 'Trang chủ máy chủ';
	@override String get deleteAccount => 'Xóa tài khoản';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$vi extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get q => 'Tôi có mất ghi chú nếu đăng xuất không?';
	@override String get a => 'Không. Ghi chú của bạn vẫn còn trên cả thiết bị và máy chủ. Chúng sẽ không được đồng bộ với máy chủ cho đến khi bạn đăng nhập lại. Hãy đảm bảo đồng bộ đã xong trước khi đăng xuất để không mất dữ liệu (xem tiến trình đồng bộ trên màn hình chính).';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$vi extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get q => 'Ghi chú của tôi được lưu ở đâu?';
	@override String get a => 'Trong thư mục "BadNotes" trên Google Drive, hoặc "Apps/BadNotes" trên OneDrive của bạn. Các tệp đã được mã hóa nên chỉ có thể mở bằng BadNotes.';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$vi extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get q => 'Làm sao để đổi mật khẩu mã hóa?';
	@override String get a => '0. Đảm bảo đồng bộ đã xong (xem tiến trình đồng bộ trên màn hình chính).\n1. Đăng xuất khỏi BadNotes.\n2. Xóa thư mục \'BadNotes\' trên Google Drive hoặc OneDrive. Thao tác này xóa mọi ghi chú trên đám mây, không xóa trên thiết bị của bạn.\n3. Đăng nhập lại BadNotes. Bạn có thể chọn mật khẩu mã hóa mới khi đăng nhập.\n4. Đừng quên đăng xuất rồi đăng nhập lại BadNotes trên các thiết bị khác.';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$vi extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get q => 'Làm sao để xóa tài khoản?';
	@override String get a => 'BadNotes không có tài khoản riêng. Hãy đăng xuất, rồi xóa thư mục \'BadNotes\' trên Google Drive hoặc OneDrive.\nĐể thu hồi cả quyền truy cập của BadNotes, hãy vào myaccount.google.com/permissions (Google) hoặc account.live.com/consent/Manage (Microsoft).';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$vi extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => 'Bật/tắt màu (Ctrl C)';
	@override String get select => 'Chọn';
	@override String get toggleEraser => 'Bật/tắt tẩy (Ctrl E)';
	@override String get photo => 'Hình ảnh';
	@override String get text => 'Văn bản';
	@override String get toggleFingerDrawing => 'Bật/tắt vẽ bằng ngón tay (Ctrl F)';
	@override String get undo => 'Hoàn tác';
	@override String get redo => 'Làm lại';
	@override String get export => 'Xuất (Ctrl Shift S)';
	@override String get exportAs => 'Xuất dưới dạng:';
	@override String get fullscreen => 'Bật/tắt toàn màn hình (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$vi extends Translations$editor$pens$en {
	_Translations$editor$pens$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => 'Bút máy';
	@override String get ballpointPen => 'Bút bi';
	@override String get highlighter => 'Bút dạ quang';
	@override String get pencil => 'Bút chì';
	@override String get shapePen => 'Bút hình';
	@override String get laserPointer => 'Bút laser';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$vi extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get size => 'Cỡ';
}

// Path: editor.colors
class _Translations$editor$colors$vi extends Translations$editor$colors$en {
	_Translations$editor$colors$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => 'Bảng chọn màu';
	@override String customBrightnessHue({required Object h, required Object b}) => '${h} ${b} tùy chỉnh';
	@override String customHue({required Object h}) => '${h} tùy chỉnh';
	@override String get dark => 'đậm';
	@override String get light => 'nhạt';
	@override String get black => 'Đen';
	@override String get darkGrey => 'Xám đậm';
	@override String get grey => 'Xám';
	@override String get lightGrey => 'Xám nhạt';
	@override String get white => 'Trắng';
	@override String get red => 'Đỏ';
	@override String get green => 'Xanh lá';
	@override String get cyan => 'Xanh lơ';
	@override String get blue => 'Xanh dương';
	@override String get yellow => 'Vàng';
	@override String get purple => 'Tím';
	@override String get pink => 'Hồng';
	@override String get orange => 'Cam';
	@override String get pastelRed => 'Đỏ pastel';
	@override String get pastelOrange => 'Cam pastel';
	@override String get pastelYellow => 'Vàng pastel';
	@override String get pastelGreen => 'Xanh lá pastel';
	@override String get pastelCyan => 'Xanh lơ pastel';
	@override String get pastelBlue => 'Xanh dương pastel';
	@override String get pastelPurple => 'Tím pastel';
	@override String get pastelPink => 'Hồng pastel';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$vi extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tùy chọn ảnh';
	@override String get invertible => 'Có thể đảo màu';
	@override String get download => 'Tải xuống';
	@override String get setAsBackground => 'Đặt làm nền';
	@override String get removeAsBackground => 'Bỏ làm nền';
	@override String get delete => 'Xóa';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$vi extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Xóa';
	@override String get duplicate => 'Nhân bản';
}

// Path: editor.menu
class _Translations$editor$menu$vi extends Translations$editor$menu$en {
	_Translations$editor$menu$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => 'Xóa trang ${page}/${totalPages}';
	@override String get clearAllPages => 'Xóa tất cả trang';
	@override String get insertPage => 'Chèn trang bên dưới';
	@override String get duplicatePage => 'Nhân bản trang';
	@override String get deletePage => 'Xóa trang';
	@override String get lineHeight => 'Chiều cao dòng';
	@override String get lineHeightDescription => 'Cũng điều chỉnh cỡ chữ cho ghi chú đánh máy';
	@override String get lineThickness => 'Độ dày đường kẻ';
	@override String get lineThicknessDescription => 'Độ dày đường kẻ nền';
	@override String get backgroundImageFit => 'Cách hiển thị ảnh nền';
	@override String get backgroundPattern => 'Mẫu nền';
	@override String get import => 'Nhập';
	@override String get watchServer => 'Theo dõi cập nhật trên máy chủ';
	@override String get watchServerReadOnly => 'Không thể chỉnh sửa khi đang theo dõi máy chủ';
	@override late final _Translations$editor$menu$boxFits$vi boxFits = _Translations$editor$menu$boxFits$vi._(_root);
	@override late final _Translations$editor$menu$bgPatterns$vi bgPatterns = _Translations$editor$menu$bgPatterns$vi._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$vi extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lỗi';
	@override String get message => 'Không thể thêm tệp PDF dưới dạng ảnh. Hãy dùng "${_root.editor.menu.import} > PDF" để làm việc đó.';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$vi extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Chế độ chỉ đọc';
	@override String get watchingServer => 'Bạn đang theo dõi cập nhật trên máy chủ. Không thể chỉnh sửa ở chế độ này.';
	@override String get corrupted => 'Không tải được ghi chú. Ghi chú có thể bị hỏng hoặc vẫn đang được tải xuống.';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$vi extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ghi chú này được sửa bằng phiên bản BadNotes mới hơn';
	@override String get subtitle => 'Chỉnh sửa ghi chú này có thể làm mất một số thông tin. Bạn vẫn muốn bỏ qua và chỉnh sửa?';
	@override String get allowEditing => 'Cho phép chỉnh sửa';
}

// Path: editor.quill
class _Translations$editor$quill$vi extends Translations$editor$quill$en {
	_Translations$editor$quill$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => 'Nhập nội dung tại đây…';
}

// Path: editor.hud
class _Translations$editor$hud$vi extends Translations$editor$hud$en {
	_Translations$editor$hud$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => 'Mở khóa thu phóng';
	@override String get lockZoom => 'Khóa thu phóng';
	@override String get unlockSingleFingerPan => 'Bật kéo bằng một ngón tay';
	@override String get lockSingleFingerPan => 'Tắt kéo bằng một ngón tay';
	@override String get unlockAxisAlignedPan => 'Bỏ khóa kéo theo chiều ngang hoặc dọc';
	@override String get lockAxisAlignedPan => 'Khóa kéo theo chiều ngang hoặc dọc';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$vi extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get question => 'Bạn có muốn tự động gửi báo cáo lỗi bất ngờ không? Điều này giúp tôi tìm và sửa lỗi nhanh hơn.';
	@override String get scope => 'Báo cáo có thể chứa thông tin về lỗi và thiết bị của bạn. Tôi đã cố gắng lọc bỏ dữ liệu cá nhân nhưng có thể vẫn còn sót.';
	@override String get currentlyOff => 'Nếu bạn đồng ý, tính năng báo cáo lỗi sẽ được bật sau khi khởi động lại ứng dụng.';
	@override String get currentlyOn => 'Nếu bạn rút lại đồng ý, hãy khởi động lại ứng dụng để tắt báo cáo lỗi.';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: 'Tìm hiểu thêm trong '),
		link('chính sách quyền riêng tư'),
		const TextSpan(text: '.'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$vi extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Có';
	@override String get no => 'Không';
	@override String get later => 'Hỏi lại sau';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$vi extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get shown => 'Tránh vô tình bật/tắt';
	@override String get fixedOn => 'Vẽ bằng ngón tay luôn bật';
	@override String get fixedOff => 'Vẽ bằng ngón tay luôn tắt';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$vi extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get active => 'Đang bật';
	@override String get inactive => 'Đang tắt';
	@override String get activeUntilRestart => 'Bật cho đến khi khởi động lại ứng dụng';
	@override String get inactiveUntilRestart => 'Tắt cho đến khi khởi động lại ứng dụng';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$vi extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => 'Vui lòng cho phép BadNotes truy cập tài khoản Nextcloud của bạn';
	@override String get followPrompts => 'Vui lòng làm theo hướng dẫn trên giao diện Nextcloud';
	@override String get browserDidntOpen => 'Trang đăng nhập không mở? Nhấn vào đây';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$vi extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get q => 'Mật khẩu mã hóa là gì? Tại sao cần hai mật khẩu?';
	@override String get a => 'Tài khoản Google hoặc Microsoft của bạn dùng để truy cập đám mây. Mật khẩu mã hóa sẽ "xáo trộn" dữ liệu của bạn trước khi nó được gửi lên đám mây.\nNgay cả khi ai đó truy cập được tài khoản Google hoặc Microsoft của bạn, ghi chú vẫn an toàn và được mã hóa bằng một mật khẩu riêng. Đây là lớp bảo mật thứ hai để bảo vệ dữ liệu của bạn.\nKhông ai có thể xem ghi chú của bạn trên máy chủ nếu không có mật khẩu mã hóa, nhưng điều này cũng có nghĩa là nếu bạn quên mật khẩu mã hóa, bạn sẽ mất quyền truy cập dữ liệu.';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$vi extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get q => 'Tôi chưa đặt mật khẩu mã hóa. Lấy nó ở đâu?';
	@override String get a => 'Hãy chọn một mật khẩu mã hóa mới và nhập vào ô phía trên.\nBadNotes sẽ tự động tạo khóa mã hóa từ mật khẩu này.';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$vi extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get q => 'Tôi có thể dùng mật khẩu giống tài khoản Google hoặc Microsoft không?';
	@override String get a => 'Xin đừng. Một mật khẩu mã hóa riêng giúp ghi chú của bạn an toàn ngay cả khi ai đó vào được tài khoản đó.';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$vi extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get fill => 'Kéo giãn';
	@override String get cover => 'Phủ kín';
	@override String get contain => 'Vừa khung';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$vi extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get none => 'Trống';
	@override String get college => 'Kẻ dòng hẹp';
	@override String get collegeRtl => 'Kẻ dòng hẹp (Đảo ngược)';
	@override String get lined => 'Kẻ dòng';
	@override String get grid => 'Ô vuông';
	@override String get dots => 'Chấm';
	@override String get staffs => 'Khuông nhạc';
	@override String get tablature => 'Tab đàn';
	@override String get cornell => 'Cornell';
}
