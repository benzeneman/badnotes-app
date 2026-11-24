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
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <es>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$es common = _Translations$common$es._(_root);
	@override late final _Translations$home$es home = _Translations$home$es._(_root);
	@override late final _Translations$sentry$es sentry = _Translations$sentry$es._(_root);
	@override late final _Translations$settings$es settings = _Translations$settings$es._(_root);
	@override late final _Translations$logs$es logs = _Translations$logs$es._(_root);
	@override late final _Translations$login$es login = _Translations$login$es._(_root);
	@override late final _Translations$profile$es profile = _Translations$profile$es._(_root);
	@override late final _Translations$appInfo$es appInfo = _Translations$appInfo$es._(_root);
	@override late final _Translations$update$es update = _Translations$update$es._(_root);
	@override late final _Translations$editor$es editor = _Translations$editor$es._(_root);
}

// Path: common
class _Translations$common$es extends Translations$common$en {
	_Translations$common$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get done => 'Listo';
	@override String get continueBtn => 'Continuar';
	@override String get cancel => 'Cancelar';
}

// Path: home
class _Translations$home$es extends Translations$home$en {
	_Translations$home$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$es tabs = _Translations$home$tabs$es._(_root);
	@override late final _Translations$home$titles$es titles = _Translations$home$titles$es._(_root);
	@override late final _Translations$home$tooltips$es tooltips = _Translations$home$tooltips$es._(_root);
	@override late final _Translations$home$create$es create = _Translations$home$create$es._(_root);
	@override String get welcome => 'Te damos la bienvenida a BadNotes';
	@override String get invalidFormat => 'El archivo seleccionado no es compatible. Selecciona un archivo sbn, sbn2, sba o pdf.';
	@override String get noFiles => 'No se encontraron archivos';
	@override String get noPreviewAvailable => 'Vista previa no disponible';
	@override String get createNewNote => 'Toca el botón + para crear una nota';
	@override String get backFolder => 'Volver a la carpeta anterior';
	@override late final _Translations$home$newFolder$es newFolder = _Translations$home$newFolder$es._(_root);
	@override late final _Translations$home$renameNote$es renameNote = _Translations$home$renameNote$es._(_root);
	@override late final _Translations$home$moveNote$es moveNote = _Translations$home$moveNote$es._(_root);
	@override String get deleteNote => 'Eliminar nota';
	@override late final _Translations$home$deleteNoteDialog$es deleteNoteDialog = _Translations$home$deleteNoteDialog$es._(_root);
	@override late final _Translations$home$renameFolder$es renameFolder = _Translations$home$renameFolder$es._(_root);
	@override late final _Translations$home$deleteFolder$es deleteFolder = _Translations$home$deleteFolder$es._(_root);
	@override late final _Translations$home$sort$es sort = _Translations$home$sort$es._(_root);
	@override late final _Translations$home$layout$es layout = _Translations$home$layout$es._(_root);
}

// Path: sentry
class _Translations$sentry$es extends Translations$sentry$en {
	_Translations$sentry$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$es consent = _Translations$sentry$consent$es._(_root);
}

// Path: settings
class _Translations$settings$es extends Translations$settings$en {
	_Translations$settings$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$es prefCategories = _Translations$settings$prefCategories$es._(_root);
	@override late final _Translations$settings$prefLabels$es prefLabels = _Translations$settings$prefLabels$es._(_root);
	@override late final _Translations$settings$prefDescriptions$es prefDescriptions = _Translations$settings$prefDescriptions$es._(_root);
	@override late final _Translations$settings$themeModes$es themeModes = _Translations$settings$themeModes$es._(_root);
	@override late final _Translations$settings$layoutSizes$es layoutSizes = _Translations$settings$layoutSizes$es._(_root);
	@override late final _Translations$settings$accentColorPicker$es accentColorPicker = _Translations$settings$accentColorPicker$es._(_root);
	@override String get systemLanguage => 'Automático';
	@override List<String> get axisDirections => [
		'Arriba',
		'Derecha',
		'Abajo',
		'Izquierda',
	];
	@override late final _Translations$settings$reset$es reset = _Translations$settings$reset$es._(_root);
	@override String get resyncEverything => 'Volver a sincronizar todo';
	@override String get openDataDir => 'Abrir carpeta de BadNotes';
	@override late final _Translations$settings$customDataDir$es customDataDir = _Translations$settings$customDataDir$es._(_root);
	@override String get autosaveDisabled => 'Nunca';
	@override String get shapeRecognitionDisabled => 'Nunca';
}

// Path: logs
class _Translations$logs$es extends Translations$logs$en {
	_Translations$logs$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get logs => 'Registros';
	@override String get viewLogs => 'Ver registros';
	@override String get debuggingInfo => 'Los registros contienen información útil para la depuración y el desarrollo';
	@override String get noLogs => '¡No hay registros!';
	@override String get useTheApp => 'Los registros aparecerán aquí mientras usas la app';
}

// Path: login
class _Translations$login$es extends Translations$login$en {
	_Translations$login$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Iniciar sesión';
	@override late final _Translations$login$form$es form = _Translations$login$form$es._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: '¿Aún no tienes cuenta? ¡'),
		linkToSignup('Regístrate ahora'),
		const TextSpan(text: '!'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: '¿No eres tú? '),
		undoLogin('Elige otra cuenta'),
		const TextSpan(text: '.'),
	]);
	@override late final _Translations$login$status$es status = _Translations$login$status$es._(_root);
	@override late final _Translations$login$ncLoginStep$es ncLoginStep = _Translations$login$ncLoginStep$es._(_root);
	@override late final _Translations$login$encLoginStep$es encLoginStep = _Translations$login$encLoginStep$es._(_root);
}

// Path: profile
class _Translations$profile$es extends Translations$profile$en {
	_Translations$profile$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mi perfil';
	@override String get logout => 'Cerrar sesión';
	@override String quotaUsage({required Object used, required Object total, required Object percent}) => 'Estás usando ${used} de ${total} (${percent}%)';
	@override String quotaUsageUncapped({required Object used}) => 'Estás usando ${used}';
	@override String get connectedTo => 'Conectado a';
	@override String lastSynced({required Object time}) => 'Última sincronización ${time}';
	@override String get notSyncedYet => 'Aún no sincronizado';
	@override String get justNow => 'ahora mismo';
	@override String minutesAgo({required Object n}) => 'hace ${n} min';
	@override String hoursAgo({required Object n}) => 'hace ${n} h';
	@override String filesWaiting({required Object n}) => '${n} archivos pendientes de sincronizar';
	@override String get signInAgainNeeded => 'Vuelve a iniciar sesión para seguir sincronizando';
	@override String get signInAgain => 'Volver a iniciar sesión';
	@override String wrongAccount({required Object email}) => 'Elige ${email}';
	@override late final _Translations$profile$quickLinks$es quickLinks = _Translations$profile$quickLinks$es._(_root);
	@override String get faqTitle => 'Preguntas frecuentes';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$es._(_root),
		_Translations$profile$faq$1$es._(_root),
		_Translations$profile$faq$2$es._(_root),
		_Translations$profile$faq$3$es._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$es extends Translations$appInfo$en {
	_Translations$appInfo$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get debug => 'DEBUG';
}

// Path: update
class _Translations$update$es extends Translations$update$en {
	_Translations$update$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => 'Actualización disponible';
	@override String get updateAvailableDescription => 'Hay una nueva versión de la app disponible:';
	@override String get update => 'Actualizar';
	@override String get downloadNotAvailableYet => 'La descarga aún no está disponible para tu plataforma. Vuelve a comprobarlo en breve.';
}

// Path: editor
class _Translations$editor$es extends Translations$editor$en {
	_Translations$editor$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$es toolbar = _Translations$editor$toolbar$es._(_root);
	@override late final _Translations$editor$pens$es pens = _Translations$editor$pens$es._(_root);
	@override late final _Translations$editor$penOptions$es penOptions = _Translations$editor$penOptions$es._(_root);
	@override late final _Translations$editor$colors$es colors = _Translations$editor$colors$es._(_root);
	@override late final _Translations$editor$imageOptions$es imageOptions = _Translations$editor$imageOptions$es._(_root);
	@override late final _Translations$editor$selectionBar$es selectionBar = _Translations$editor$selectionBar$es._(_root);
	@override late final _Translations$editor$menu$es menu = _Translations$editor$menu$es._(_root);
	@override late final _Translations$editor$photoPdfError$es photoPdfError = _Translations$editor$photoPdfError$es._(_root);
	@override late final _Translations$editor$readOnlyBanner$es readOnlyBanner = _Translations$editor$readOnlyBanner$es._(_root);
	@override late final _Translations$editor$versionTooNew$es versionTooNew = _Translations$editor$versionTooNew$es._(_root);
	@override late final _Translations$editor$quill$es quill = _Translations$editor$quill$es._(_root);
	@override late final _Translations$editor$hud$es hud = _Translations$editor$hud$es._(_root);
	@override String get pages => 'Páginas';
	@override String get untitled => 'Sin título';
	@override String get needsToSaveBeforeExiting => 'Guardando los cambios… Podrás salir del editor con seguridad cuando termine';
}

// Path: home.tabs
class _Translations$home$tabs$es extends Translations$home$tabs$en {
	_Translations$home$tabs$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get home => 'Inicio';
	@override String get browse => 'Explorar';
	@override String get whiteboard => 'Pizarra';
	@override String get settings => 'Ajustes';
}

// Path: home.titles
class _Translations$home$titles$es extends Translations$home$titles$en {
	_Translations$home$titles$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get home => 'Notas recientes';
	@override String get browse => 'Explorar';
	@override String get whiteboard => 'Pizarra';
	@override String get settings => 'Ajustes';
}

// Path: home.tooltips
class _Translations$home$tooltips$es extends Translations$home$tooltips$en {
	_Translations$home$tooltips$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Nueva nota';
	@override String get showUpdateDialog => 'Mostrar diálogo de actualización';
	@override String get exportNote => 'Exportar nota';
}

// Path: home.create
class _Translations$home$create$es extends Translations$home$create$en {
	_Translations$home$create$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Nueva nota';
	@override String get importNote => 'Importar nota';
}

// Path: home.newFolder
class _Translations$home$newFolder$es extends Translations$home$newFolder$en {
	_Translations$home$newFolder$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get newFolder => 'Nueva carpeta';
	@override String get folderName => 'Nombre de la carpeta';
	@override String get create => 'Crear';
	@override String get folderNameEmpty => 'El nombre de la carpeta no puede estar vacío';
	@override String get folderNameContainsSlash => 'El nombre de la carpeta no puede contener una barra';
	@override String get folderNameExists => 'La carpeta ya existe';
}

// Path: home.renameNote
class _Translations$home$renameNote$es extends Translations$home$renameNote$en {
	_Translations$home$renameNote$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get renameNote => 'Renombrar nota';
	@override String get noteName => 'Nombre de la nota';
	@override String get rename => 'Renombrar';
	@override String get noteNameEmpty => 'El nombre de la nota no puede estar vacío';
	@override String get noteNameExists => 'Ya existe una nota con este nombre';
	@override String get noteNameForbiddenCharacters => 'El nombre de la nota contiene caracteres no permitidos';
	@override String get noteNameReserved => 'Nombre de nota reservado';
}

// Path: home.moveNote
class _Translations$home$moveNote$es extends Translations$home$moveNote$en {
	_Translations$home$moveNote$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get moveNote => 'Mover nota';
	@override String moveNotes({required Object n}) => 'Mover ${n} notas';
	@override String moveName({required Object f}) => 'Mover ${f}';
	@override String get move => 'Mover';
	@override String renamedTo({required Object newName}) => 'La nota se renombrará como ${newName}';
	@override String get multipleRenamedTo => 'Las siguientes notas se renombrarán:';
	@override String numberRenamedTo({required Object n}) => 'Se renombrarán ${n} notas para evitar conflictos';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$es extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => 'Eliminar ${n} notas';
	@override String deleteName({required Object f}) => 'Eliminar ${f}';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '¿Eliminar definitivamente la nota seleccionada?',
		other: '¿Eliminar definitivamente las notas seleccionadas?',
	);
	@override String get delete => 'Eliminar';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$es extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => 'Renombrar carpeta';
	@override String get folderName => 'Nombre de la carpeta';
	@override String get rename => 'Renombrar';
	@override String get folderNameEmpty => 'El nombre de la carpeta no puede estar vacío';
	@override String get folderNameContainsSlash => 'El nombre de la carpeta no puede contener una barra';
	@override String get folderNameExists => 'Ya existe una carpeta con este nombre';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$es extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => 'Eliminar carpeta';
	@override String deleteName({required Object f}) => 'Eliminar ${f}';
	@override String get delete => 'Eliminar';
	@override String get alsoDeleteContents => 'Eliminar también todas las notas de esta carpeta';
}

// Path: home.sort
class _Translations$home$sort$es extends Translations$home$sort$en {
	_Translations$home$sort$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sortBy => 'Ordenar por';
	@override String get nameAToZ => 'Nombre (A-Z)';
	@override String get nameZToA => 'Nombre (Z-A)';
	@override String get lastModifiedNewToOld => 'Editado (más reciente primero)';
	@override String get lastModifiedOldToNew => 'Editado (más antiguo primero)';
}

// Path: home.layout
class _Translations$home$layout$es extends Translations$home$layout$en {
	_Translations$home$layout$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get layout => 'Diseño';
	@override String get masonryGrid => 'Cuadrícula tipo mosaico';
	@override String get simpleGrid => 'Cuadrícula simple';
}

// Path: sentry.consent
class _Translations$sentry$consent$es extends Translations$sentry$consent$en {
	_Translations$sentry$consent$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => '¿Quieres ayudar a mejorar BadNotes?';
	@override late final _Translations$sentry$consent$description$es description = _Translations$sentry$consent$description$es._(_root);
	@override late final _Translations$sentry$consent$answers$es answers = _Translations$sentry$consent$answers$es._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$es extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get general => 'General';
	@override String get writing => 'Escritura';
	@override String get editor => 'Editor';
	@override String get performance => 'Rendimiento';
	@override String get advanced => 'Avanzado';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$es extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get locale => 'Idioma';
	@override String get appTheme => 'Tema de la app';
	@override String get platform => 'Tipo de tema';
	@override String get layoutSize => 'Tipo de diseño';
	@override String get customAccentColor => 'Color de acento personalizado';
	@override String get hyperlegibleFont => 'Fuente Atkinson Hyperlegible';
	@override String get shouldCheckForUpdates => 'Buscar actualizaciones de BadNotes';
	@override String get shouldAlwaysAlertForUpdates => 'Actualizaciones más rápidas';
	@override String get allowInsecureConnections => 'Permitir conexiones no seguras';
	@override String get syncOnlyOnWifi => 'Sincronizar solo con Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'Subir vistas previas con datos móviles';
	@override String get editorToolbarAlignment => 'Posición de la barra de herramientas';
	@override String get editorToolbarShowInFullscreen => 'Mostrar la barra de herramientas en pantalla completa';
	@override String get editorAutoInvert => 'Invertir notas en modo oscuro';
	@override String get preferGreyscale => 'Preferir colores en escala de grises';
	@override String get maxImageSize => 'Tamaño máximo de imagen';
	@override String get autoClearWhiteboardOnExit => 'Borrar la pizarra automáticamente';
	@override String get disableEraserAfterUse => 'Desactivar el borrador automáticamente';
	@override String get hideFingerDrawingToggle => 'Ocultar el botón de dibujo con el dedo';
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Desactivar automáticamente el dibujo con el dedo';
	@override String get editorPromptRename => 'Pedir un nombre para las notas nuevas';
	@override String get recentColorsDontSavePresets => 'No guardar los colores predefinidos en colores recientes';
	@override String get recentColorsLength => 'Cantidad de colores recientes que guardar';
	@override String get printPageIndicators => 'Imprimir indicadores de página';
	@override String get autosave => 'Guardado automático';
	@override String get shapeRecognitionDelay => 'Retraso del reconocimiento de formas';
	@override String get autoStraightenLines => 'Enderezar líneas automáticamente';
	@override String get customDataDir => 'Carpeta personalizada de BadNotes';
	@override String get sentry => 'Informes de errores';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$es extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => 'Desactivado: las notas también se sincronizan con datos móviles. Activado: la sincronización espera al Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'Las miniaturas de las notas suelen esperar al Wi-Fi para ahorrar datos';
	@override String get hyperlegibleFont => 'Mejora la legibilidad para personas con baja visión';
	@override String get allowInsecureConnections => '(No recomendado) Permite que BadNotes se conecte a servidores con certificados autofirmados o no fiables';
	@override String get preferGreyscale => 'Para pantallas de tinta electrónica';
	@override String get autoClearWhiteboardOnExit => 'Borra la pizarra al salir de la app';
	@override String get disableEraserAfterUse => 'Vuelve automáticamente al bolígrafo después de usar el borrador';
	@override String get maxImageSize => 'Las imágenes más grandes se comprimirán';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$es hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$es._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Desactiva el dibujo con el dedo al detectar un lápiz óptico';
	@override String get editorPromptRename => 'Siempre puedes renombrar las notas más tarde';
	@override String get printPageIndicators => 'Muestra los indicadores de página en las exportaciones';
	@override String get autosave => 'Guarda automáticamente tras un breve retraso, o nunca';
	@override String get shapeRecognitionDelay => 'Cuánto tiempo mantener quieto el lápiz antes de que el trazo se convierta en una forma';
	@override String get autoStraightenLines => 'Endereza las líneas largas sin tener que usar el lápiz de formas';
	@override String get shouldAlwaysAlertForUpdates => 'Avisarme de las actualizaciones en cuanto estén disponibles';
	@override late final _Translations$settings$prefDescriptions$sentry$es sentry = _Translations$settings$prefDescriptions$sentry$es._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$es extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get system => 'Sistema';
	@override String get light => 'Claro';
	@override String get dark => 'Oscuro';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$es extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get auto => 'Automático';
	@override String get phone => 'Teléfono';
	@override String get tablet => 'Tableta';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$es extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => 'Elige un color';
}

// Path: settings.reset
class _Translations$settings$reset$es extends Translations$settings$reset$en {
	_Translations$settings$reset$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => '¿Restablecer este ajuste?';
	@override String get button => 'Restablecer';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$es extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get select => 'Seleccionar';
	@override String get mustBeEmpty => 'La carpeta seleccionada debe estar vacía';
	@override String get mustBeDoneSyncing => 'Asegúrate de que la sincronización haya terminado antes de cambiar la carpeta';
	@override String get unsupported => 'Por ahora, esta función es solo para desarrolladores. Usarla probablemente provocará pérdida de datos.';
}

// Path: login.form
class _Translations$login$form$es extends Translations$login$form$en {
	_Translations$login$form$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'Al iniciar sesión, aceptas la '),
		linkToPrivacyPolicy('Política de privacidad'),
		const TextSpan(text: '.'),
	]);
}

// Path: login.status
class _Translations$login$status$es extends Translations$login$status$en {
	_Translations$login$status$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => 'Sesión cerrada';
	@override String get tapToLogin => 'Toca para sincronizar con Google Drive';
	@override String hi({required Object u}) => '¡Hola, ${u}!';
	@override String get almostDone => 'Casi listo para sincronizar, toca para terminar de iniciar sesión';
	@override String get loggedIn => 'Sincronización activada';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$es extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => 'Elige dónde quieres guardar tus datos:';
	@override String get cloudStorage => 'Google Drive o OneDrive';
	@override String get loginWithGoogleDrive => 'Continuar con Google Drive';
	@override String get loginWithOneDrive => 'Continuar con OneDrive';
	@override String get cloudLoginFailed => 'No se pudo iniciar sesión';
	@override String get comingSoon => 'Próximamente';
	@override String get badnotesNcServer => 'Servidor Nextcloud de BadNotes';
	@override String get otherNcServer => 'Otro servidor Nextcloud';
	@override String get serverUrl => 'URL del servidor';
	@override String get loginWithBadNotes => 'Iniciar sesión con BadNotes';
	@override String get loginWithNextcloud => 'Iniciar sesión con Nextcloud';
	@override late final _Translations$login$ncLoginStep$loginFlow$es loginFlow = _Translations$login$ncLoginStep$loginFlow$es._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$es extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => 'Para proteger tus datos, introduce tu contraseña de cifrado:';
	@override String get newToBadNotes => '¿Eres nuevo en BadNotes? Solo tienes que introducir una nueva contraseña de cifrado.';
	@override String get encPassword => 'Contraseña de cifrado';
	@override String get encFaqTitle => 'Preguntas frecuentes';
	@override String get wrongEncPassword => 'No se pudo descifrar con la contraseña indicada. Vuelve a introducirla.';
	@override String get connectionFailed => 'Algo salió mal al conectar con el servidor. Inténtalo de nuevo más tarde.';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$es._(_root),
		_Translations$login$encLoginStep$encFaq$1$es._(_root),
		_Translations$login$encLoginStep$encFaq$2$es._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$es extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => 'Página principal del servidor';
	@override String get deleteAccount => 'Eliminar cuenta';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$es extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get q => '¿Perderé mis notas si cierro sesión?';
	@override String get a => 'No. Tus notas seguirán en tu dispositivo y en el servidor. No se sincronizarán con el servidor hasta que vuelvas a iniciar sesión. Asegúrate de que la sincronización haya terminado antes de cerrar sesión para no perder datos (consulta el progreso de sincronización en la pantalla de inicio).';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$es extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get q => '¿Dónde se guardan mis notas?';
	@override String get a => 'En una carpeta "BadNotes" de tu Google Drive, o en "Apps/BadNotes" de tu OneDrive. Los archivos están cifrados, así que solo se pueden abrir en BadNotes.';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$es extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get q => '¿Cómo cambio mi contraseña de cifrado?';
	@override String get a => '0. Asegúrate de que la sincronización haya terminado (consulta el progreso de sincronización en la pantalla de inicio).\n1. Cierra sesión en BadNotes.\n2. Elimina la carpeta \'BadNotes\' de tu Google Drive o OneDrive. Esto elimina todas tus notas de la nube, no de tu dispositivo.\n3. Vuelve a iniciar sesión en BadNotes. Podrás elegir una nueva contraseña de cifrado al iniciar sesión.\n4. No olvides cerrar sesión y volver a iniciarla en BadNotes también en tus otros dispositivos.';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$es extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get q => '¿Cómo puedo eliminar mi cuenta?';
	@override String get a => 'BadNotes no tiene cuentas propias. Cierra sesión y elimina la carpeta \'BadNotes\' de tu Google Drive o OneDrive.\nPara quitar también el acceso de BadNotes, ve a myaccount.google.com/permissions (Google) o account.live.com/consent/Manage (Microsoft).';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$es extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => 'Mostrar/ocultar colores (Ctrl C)';
	@override String get select => 'Seleccionar';
	@override String get toggleEraser => 'Activar/desactivar borrador (Ctrl E)';
	@override String get photo => 'Imágenes';
	@override String get text => 'Texto';
	@override String get toggleFingerDrawing => 'Activar/desactivar dibujo con el dedo (Ctrl F)';
	@override String get undo => 'Deshacer';
	@override String get redo => 'Rehacer';
	@override String get export => 'Exportar (Ctrl Shift S)';
	@override String get exportAs => 'Exportar como:';
	@override String get fullscreen => 'Pantalla completa (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$es extends Translations$editor$pens$en {
	_Translations$editor$pens$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => 'Pluma';
	@override String get ballpointPen => 'Bolígrafo';
	@override String get highlighter => 'Resaltador';
	@override String get pencil => 'Lápiz';
	@override String get shapePen => 'Lápiz de formas';
	@override String get laserPointer => 'Puntero láser';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$es extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get size => 'Tamaño';
}

// Path: editor.colors
class _Translations$editor$colors$es extends Translations$editor$colors$en {
	_Translations$editor$colors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => 'Selector de color';
	@override String customBrightnessHue({required Object h, required Object b}) => '${h} ${b} personalizado';
	@override String customHue({required Object h}) => '${h} personalizado';
	@override String get dark => 'oscuro';
	@override String get light => 'claro';
	@override String get black => 'Negro';
	@override String get darkGrey => 'Gris oscuro';
	@override String get grey => 'Gris';
	@override String get lightGrey => 'Gris claro';
	@override String get white => 'Blanco';
	@override String get red => 'Rojo';
	@override String get green => 'Verde';
	@override String get cyan => 'Cian';
	@override String get blue => 'Azul';
	@override String get yellow => 'Amarillo';
	@override String get purple => 'Morado';
	@override String get pink => 'Rosa';
	@override String get orange => 'Naranja';
	@override String get pastelRed => 'Rojo pastel';
	@override String get pastelOrange => 'Naranja pastel';
	@override String get pastelYellow => 'Amarillo pastel';
	@override String get pastelGreen => 'Verde pastel';
	@override String get pastelCyan => 'Cian pastel';
	@override String get pastelBlue => 'Azul pastel';
	@override String get pastelPurple => 'Morado pastel';
	@override String get pastelPink => 'Rosa pastel';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$es extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Opciones de imagen';
	@override String get invertible => 'Invertible';
	@override String get download => 'Descargar';
	@override String get setAsBackground => 'Usar como fondo';
	@override String get removeAsBackground => 'Quitar como fondo';
	@override String get delete => 'Eliminar';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$es extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Eliminar';
	@override String get duplicate => 'Duplicar';
}

// Path: editor.menu
class _Translations$editor$menu$es extends Translations$editor$menu$en {
	_Translations$editor$menu$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => 'Borrar página ${page}/${totalPages}';
	@override String get clearAllPages => 'Borrar todas las páginas';
	@override String get insertPage => 'Insertar página debajo';
	@override String get duplicatePage => 'Duplicar página';
	@override String get deletePage => 'Eliminar página';
	@override String get lineHeight => 'Interlineado';
	@override String get lineHeightDescription => 'También controla el tamaño del texto en las notas escritas a teclado';
	@override String get lineThickness => 'Grosor de línea';
	@override String get lineThicknessDescription => 'Grosor de las líneas del fondo';
	@override String get backgroundImageFit => 'Ajuste de la imagen de fondo';
	@override String get backgroundPattern => 'Patrón de fondo';
	@override String get import => 'Importar';
	@override String get watchServer => 'Seguir cambios en el servidor';
	@override String get watchServerReadOnly => 'La edición está desactivada mientras se siguen los cambios del servidor';
	@override late final _Translations$editor$menu$boxFits$es boxFits = _Translations$editor$menu$boxFits$es._(_root);
	@override late final _Translations$editor$menu$bgPatterns$es bgPatterns = _Translations$editor$menu$bgPatterns$es._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$es extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Error';
	@override String get message => 'Los archivos PDF no se pueden añadir como imagen. Usa "${_root.editor.menu.import} > PDF" para eso.';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$es extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Modo de solo lectura';
	@override String get watchingServer => 'Estás siguiendo los cambios del servidor. La edición está desactivada en este modo.';
	@override String get corrupted => 'No se pudo cargar la nota. Puede que esté dañada o que aún se esté descargando.';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$es extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Esta nota se editó con una versión más reciente de BadNotes';
	@override String get subtitle => 'Si editas esta nota, es posible que se pierda parte de la información. ¿Quieres ignorarlo y editarla de todos modos?';
	@override String get allowEditing => 'Permitir edición';
}

// Path: editor.quill
class _Translations$editor$quill$es extends Translations$editor$quill$en {
	_Translations$editor$quill$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => 'Escribe algo aquí…';
}

// Path: editor.hud
class _Translations$editor$hud$es extends Translations$editor$hud$en {
	_Translations$editor$hud$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => 'Desbloquear zoom';
	@override String get lockZoom => 'Bloquear zoom';
	@override String get unlockSingleFingerPan => 'Activar desplazamiento con un dedo';
	@override String get lockSingleFingerPan => 'Desactivar desplazamiento con un dedo';
	@override String get unlockAxisAlignedPan => 'Desbloquear desplazamiento horizontal o vertical';
	@override String get lockAxisAlignedPan => 'Bloquear desplazamiento horizontal o vertical';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$es extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get question => '¿Quieres enviar automáticamente informes de errores inesperados? Así puedo identificar y corregir los problemas más rápido.';
	@override String get scope => 'Los informes pueden contener información sobre el error y tu dispositivo. He hecho todo lo posible por filtrar los datos personales, pero es posible que quede alguno.';
	@override String get currentlyOff => 'Si das tu consentimiento, el envío de informes de errores se activará al reiniciar la app.';
	@override String get currentlyOn => 'Si retiras tu consentimiento, reinicia la app para desactivar el envío de informes de errores.';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: 'Más información en la '),
		link('política de privacidad'),
		const TextSpan(text: '.'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$es extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Sí';
	@override String get no => 'No';
	@override String get later => 'Preguntar más tarde';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$es extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get shown => 'Evita activarlo por accidente';
	@override String get fixedOn => 'El dibujo con el dedo está siempre activado';
	@override String get fixedOff => 'El dibujo con el dedo está siempre desactivado';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$es extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get active => 'Activo';
	@override String get inactive => 'Inactivo';
	@override String get activeUntilRestart => 'Activo hasta que reinicies la app';
	@override String get inactiveUntilRestart => 'Inactivo hasta que reinicies la app';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$es extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => 'Autoriza a BadNotes a acceder a tu cuenta de Nextcloud';
	@override String get followPrompts => 'Sigue las instrucciones en la interfaz de Nextcloud';
	@override String get browserDidntOpen => '¿No se abrió la página de inicio de sesión? Haz clic aquí';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$es extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get q => '¿Qué es una contraseña de cifrado? ¿Por qué usar dos contraseñas?';
	@override String get a => 'Tu cuenta de Google o Microsoft se usa para acceder a la nube. La contraseña de cifrado "codifica" tus datos antes de que lleguen a la nube.\nAunque alguien consiga acceder a tu cuenta de Google o Microsoft, tus notas seguirán seguras y cifradas con otra contraseña. Esto te da una segunda capa de seguridad para proteger tus datos.\nNadie puede acceder a tus notas en el servidor sin tu contraseña de cifrado, pero esto también significa que, si la olvidas, perderás el acceso a tus datos.';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$es extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get q => 'Todavía no he creado una contraseña de cifrado. ¿Dónde la consigo?';
	@override String get a => 'Elige una nueva contraseña de cifrado e introdúcela arriba.\nBadNotes generará automáticamente tus claves de cifrado a partir de esta contraseña.';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$es extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get q => '¿Puedo usar la misma contraseña que la de mi cuenta de Google o Microsoft?';
	@override String get a => 'Mejor no. Una contraseña de cifrado distinta mantiene tus notas seguras aunque alguien entre en esa cuenta.';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$es extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get fill => 'Estirar';
	@override String get cover => 'Cubrir';
	@override String get contain => 'Contener';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$es extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get none => 'En blanco';
	@override String get college => 'Rayado universitario';
	@override String get collegeRtl => 'Rayado universitario (invertido)';
	@override String get lined => 'Rayado';
	@override String get grid => 'Cuadrícula';
	@override String get dots => 'Puntos';
	@override String get staffs => 'Pentagramas';
	@override String get tablature => 'Tablatura';
	@override String get cornell => 'Cornell';
}
