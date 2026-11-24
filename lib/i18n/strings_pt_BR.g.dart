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
class TranslationsPtBr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPtBr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ptBr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <pt-BR>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final TranslationsPtBr _root = this; // ignore: unused_field

	@override 
	TranslationsPtBr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPtBr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$pt_BR common = _Translations$common$pt_BR._(_root);
	@override late final _Translations$home$pt_BR home = _Translations$home$pt_BR._(_root);
	@override late final _Translations$sentry$pt_BR sentry = _Translations$sentry$pt_BR._(_root);
	@override late final _Translations$settings$pt_BR settings = _Translations$settings$pt_BR._(_root);
	@override late final _Translations$logs$pt_BR logs = _Translations$logs$pt_BR._(_root);
	@override late final _Translations$login$pt_BR login = _Translations$login$pt_BR._(_root);
	@override late final _Translations$profile$pt_BR profile = _Translations$profile$pt_BR._(_root);
	@override late final _Translations$appInfo$pt_BR appInfo = _Translations$appInfo$pt_BR._(_root);
	@override late final _Translations$update$pt_BR update = _Translations$update$pt_BR._(_root);
	@override late final _Translations$editor$pt_BR editor = _Translations$editor$pt_BR._(_root);
}

// Path: common
class _Translations$common$pt_BR extends Translations$common$en {
	_Translations$common$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get done => 'Concluído';
	@override String get continueBtn => 'Continuar';
	@override String get cancel => 'Cancelar';
}

// Path: home
class _Translations$home$pt_BR extends Translations$home$en {
	_Translations$home$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$tabs$pt_BR tabs = _Translations$home$tabs$pt_BR._(_root);
	@override late final _Translations$home$titles$pt_BR titles = _Translations$home$titles$pt_BR._(_root);
	@override late final _Translations$home$tooltips$pt_BR tooltips = _Translations$home$tooltips$pt_BR._(_root);
	@override late final _Translations$home$create$pt_BR create = _Translations$home$create$pt_BR._(_root);
	@override String get welcome => 'Boas-vindas ao BadNotes';
	@override String get invalidFormat => 'O arquivo selecionado não é compatível. Selecione um arquivo sbn, sbn2, sba ou pdf.';
	@override String get noFiles => 'Nenhum arquivo encontrado';
	@override String get noPreviewAvailable => 'Prévia indisponível';
	@override String get createNewNote => 'Toque no botão + para criar uma nova nota';
	@override String get backFolder => 'Voltar para a pasta anterior';
	@override late final _Translations$home$newFolder$pt_BR newFolder = _Translations$home$newFolder$pt_BR._(_root);
	@override late final _Translations$home$renameNote$pt_BR renameNote = _Translations$home$renameNote$pt_BR._(_root);
	@override late final _Translations$home$moveNote$pt_BR moveNote = _Translations$home$moveNote$pt_BR._(_root);
	@override String get deleteNote => 'Excluir nota';
	@override late final _Translations$home$deleteNoteDialog$pt_BR deleteNoteDialog = _Translations$home$deleteNoteDialog$pt_BR._(_root);
	@override late final _Translations$home$renameFolder$pt_BR renameFolder = _Translations$home$renameFolder$pt_BR._(_root);
	@override late final _Translations$home$deleteFolder$pt_BR deleteFolder = _Translations$home$deleteFolder$pt_BR._(_root);
	@override late final _Translations$home$sort$pt_BR sort = _Translations$home$sort$pt_BR._(_root);
	@override late final _Translations$home$layout$pt_BR layout = _Translations$home$layout$pt_BR._(_root);
}

// Path: sentry
class _Translations$sentry$pt_BR extends Translations$sentry$en {
	_Translations$sentry$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$sentry$consent$pt_BR consent = _Translations$sentry$consent$pt_BR._(_root);
}

// Path: settings
class _Translations$settings$pt_BR extends Translations$settings$en {
	_Translations$settings$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$prefCategories$pt_BR prefCategories = _Translations$settings$prefCategories$pt_BR._(_root);
	@override late final _Translations$settings$prefLabels$pt_BR prefLabels = _Translations$settings$prefLabels$pt_BR._(_root);
	@override late final _Translations$settings$prefDescriptions$pt_BR prefDescriptions = _Translations$settings$prefDescriptions$pt_BR._(_root);
	@override late final _Translations$settings$themeModes$pt_BR themeModes = _Translations$settings$themeModes$pt_BR._(_root);
	@override late final _Translations$settings$layoutSizes$pt_BR layoutSizes = _Translations$settings$layoutSizes$pt_BR._(_root);
	@override late final _Translations$settings$accentColorPicker$pt_BR accentColorPicker = _Translations$settings$accentColorPicker$pt_BR._(_root);
	@override String get systemLanguage => 'Automático';
	@override List<String> get axisDirections => [
		'Topo',
		'Direita',
		'Base',
		'Esquerda',
	];
	@override late final _Translations$settings$reset$pt_BR reset = _Translations$settings$reset$pt_BR._(_root);
	@override String get resyncEverything => 'Sincronizar tudo de novo';
	@override String get openDataDir => 'Abrir pasta do BadNotes';
	@override late final _Translations$settings$customDataDir$pt_BR customDataDir = _Translations$settings$customDataDir$pt_BR._(_root);
	@override String get autosaveDisabled => 'Nunca';
	@override String get shapeRecognitionDisabled => 'Nunca';
}

// Path: logs
class _Translations$logs$pt_BR extends Translations$logs$en {
	_Translations$logs$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get logs => 'Registros';
	@override String get viewLogs => 'Ver registros';
	@override String get debuggingInfo => 'Os registros contêm informações úteis para depuração e desenvolvimento';
	@override String get noLogs => 'Nenhum registro aqui!';
	@override String get useTheApp => 'Os registros aparecerão aqui conforme você usar o app';
}

// Path: login
class _Translations$login$pt_BR extends Translations$login$en {
	_Translations$login$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Entrar';
	@override late final _Translations$login$form$pt_BR form = _Translations$login$form$pt_BR._(_root);
	@override TextSpan signup({required InlineSpanBuilder linkToSignup}) => TextSpan(children: [
		const TextSpan(text: 'Ainda não tem uma conta? '),
		linkToSignup('Cadastre-se agora'),
		const TextSpan(text: '!'),
	]);
	@override TextSpan notYou({required InlineSpanBuilder undoLogin}) => TextSpan(children: [
		const TextSpan(text: 'Não é você? '),
		undoLogin('Escolha outra conta'),
		const TextSpan(text: '.'),
	]);
	@override late final _Translations$login$status$pt_BR status = _Translations$login$status$pt_BR._(_root);
	@override late final _Translations$login$ncLoginStep$pt_BR ncLoginStep = _Translations$login$ncLoginStep$pt_BR._(_root);
	@override late final _Translations$login$encLoginStep$pt_BR encLoginStep = _Translations$login$encLoginStep$pt_BR._(_root);
}

// Path: profile
class _Translations$profile$pt_BR extends Translations$profile$en {
	_Translations$profile$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Meu perfil';
	@override String get logout => 'Sair';
	@override String quotaUsage({required Object used, required Object total, required Object percent}) => 'Você está usando ${used} de ${total} (${percent}%)';
	@override String quotaUsageUncapped({required Object used}) => 'Você está usando ${used}';
	@override String get connectedTo => 'Conectado a';
	@override String lastSynced({required Object time}) => 'Última sincronização ${time}';
	@override String get notSyncedYet => 'Ainda não sincronizado';
	@override String get justNow => 'agora mesmo';
	@override String minutesAgo({required Object n}) => 'há ${n} min';
	@override String hoursAgo({required Object n}) => 'há ${n} h';
	@override String filesWaiting({required Object n}) => '${n} arquivos aguardando sincronização';
	@override String get signInAgainNeeded => 'Entre novamente para continuar sincronizando';
	@override String get signInAgain => 'Entrar novamente';
	@override String wrongAccount({required Object email}) => 'Escolha ${email}';
	@override late final _Translations$profile$quickLinks$pt_BR quickLinks = _Translations$profile$quickLinks$pt_BR._(_root);
	@override String get faqTitle => 'Perguntas frequentes';
	@override List<dynamic> get faq => [
		_Translations$profile$faq$0$pt_BR._(_root),
		_Translations$profile$faq$1$pt_BR._(_root),
		_Translations$profile$faq$2$pt_BR._(_root),
		_Translations$profile$faq$3$pt_BR._(_root),
	];
}

// Path: appInfo
class _Translations$appInfo$pt_BR extends Translations$appInfo$en {
	_Translations$appInfo$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get debug => 'DEBUG';
}

// Path: update
class _Translations$update$pt_BR extends Translations$update$en {
	_Translations$update$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get updateAvailable => 'Atualização disponível';
	@override String get updateAvailableDescription => 'Uma nova versão do app está disponível:';
	@override String get update => 'Atualizar';
	@override String get downloadNotAvailableYet => 'O download ainda não está disponível para a sua plataforma. Volte a verificar em breve.';
}

// Path: editor
class _Translations$editor$pt_BR extends Translations$editor$en {
	_Translations$editor$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$editor$toolbar$pt_BR toolbar = _Translations$editor$toolbar$pt_BR._(_root);
	@override late final _Translations$editor$pens$pt_BR pens = _Translations$editor$pens$pt_BR._(_root);
	@override late final _Translations$editor$penOptions$pt_BR penOptions = _Translations$editor$penOptions$pt_BR._(_root);
	@override late final _Translations$editor$colors$pt_BR colors = _Translations$editor$colors$pt_BR._(_root);
	@override late final _Translations$editor$imageOptions$pt_BR imageOptions = _Translations$editor$imageOptions$pt_BR._(_root);
	@override late final _Translations$editor$selectionBar$pt_BR selectionBar = _Translations$editor$selectionBar$pt_BR._(_root);
	@override late final _Translations$editor$menu$pt_BR menu = _Translations$editor$menu$pt_BR._(_root);
	@override late final _Translations$editor$photoPdfError$pt_BR photoPdfError = _Translations$editor$photoPdfError$pt_BR._(_root);
	@override late final _Translations$editor$readOnlyBanner$pt_BR readOnlyBanner = _Translations$editor$readOnlyBanner$pt_BR._(_root);
	@override late final _Translations$editor$versionTooNew$pt_BR versionTooNew = _Translations$editor$versionTooNew$pt_BR._(_root);
	@override late final _Translations$editor$quill$pt_BR quill = _Translations$editor$quill$pt_BR._(_root);
	@override late final _Translations$editor$hud$pt_BR hud = _Translations$editor$hud$pt_BR._(_root);
	@override String get pages => 'Páginas';
	@override String get untitled => 'Sem título';
	@override String get needsToSaveBeforeExiting => 'Salvando suas alterações… Você pode sair do editor com segurança quando terminar';
}

// Path: home.tabs
class _Translations$home$tabs$pt_BR extends Translations$home$tabs$en {
	_Translations$home$tabs$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Início';
	@override String get browse => 'Explorar';
	@override String get whiteboard => 'Quadro branco';
	@override String get settings => 'Configurações';
}

// Path: home.titles
class _Translations$home$titles$pt_BR extends Translations$home$titles$en {
	_Translations$home$titles$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Notas recentes';
	@override String get browse => 'Explorar';
	@override String get whiteboard => 'Quadro branco';
	@override String get settings => 'Configurações';
}

// Path: home.tooltips
class _Translations$home$tooltips$pt_BR extends Translations$home$tooltips$en {
	_Translations$home$tooltips$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Nova nota';
	@override String get showUpdateDialog => 'Mostrar aviso de atualização';
	@override String get exportNote => 'Exportar nota';
}

// Path: home.create
class _Translations$home$create$pt_BR extends Translations$home$create$en {
	_Translations$home$create$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get newNote => 'Nova nota';
	@override String get importNote => 'Importar nota';
}

// Path: home.newFolder
class _Translations$home$newFolder$pt_BR extends Translations$home$newFolder$en {
	_Translations$home$newFolder$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get newFolder => 'Nova pasta';
	@override String get folderName => 'Nome da pasta';
	@override String get create => 'Criar';
	@override String get folderNameEmpty => 'O nome da pasta não pode ficar vazio';
	@override String get folderNameContainsSlash => 'O nome da pasta não pode conter barra';
	@override String get folderNameExists => 'A pasta já existe';
}

// Path: home.renameNote
class _Translations$home$renameNote$pt_BR extends Translations$home$renameNote$en {
	_Translations$home$renameNote$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get renameNote => 'Renomear nota';
	@override String get noteName => 'Nome da nota';
	@override String get rename => 'Renomear';
	@override String get noteNameEmpty => 'O nome da nota não pode ficar vazio';
	@override String get noteNameExists => 'Já existe uma nota com esse nome';
	@override String get noteNameForbiddenCharacters => 'O nome da nota contém caracteres não permitidos';
	@override String get noteNameReserved => 'Nome de nota reservado';
}

// Path: home.moveNote
class _Translations$home$moveNote$pt_BR extends Translations$home$moveNote$en {
	_Translations$home$moveNote$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get moveNote => 'Mover nota';
	@override String moveNotes({required Object n}) => 'Mover ${n} notas';
	@override String moveName({required Object f}) => 'Mover ${f}';
	@override String get move => 'Mover';
	@override String renamedTo({required Object newName}) => 'A nota será renomeada para ${newName}';
	@override String get multipleRenamedTo => 'As seguintes notas serão renomeadas:';
	@override String numberRenamedTo({required Object n}) => '${n} notas serão renomeadas para evitar conflitos';
}

// Path: home.deleteNoteDialog
class _Translations$home$deleteNoteDialog$pt_BR extends Translations$home$deleteNoteDialog$en {
	_Translations$home$deleteNoteDialog$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String deleteNotes({required Object n}) => 'Excluir ${n} notas';
	@override String deleteName({required Object f}) => 'Excluir ${f}';
	@override String confirmDelete({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Excluir permanentemente a nota selecionada?',
		other: 'Excluir permanentemente as notas selecionadas?',
	);
	@override String get delete => 'Excluir';
}

// Path: home.renameFolder
class _Translations$home$renameFolder$pt_BR extends Translations$home$renameFolder$en {
	_Translations$home$renameFolder$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get renameFolder => 'Renomear pasta';
	@override String get folderName => 'Nome da pasta';
	@override String get rename => 'Renomear';
	@override String get folderNameEmpty => 'O nome da pasta não pode ficar vazio';
	@override String get folderNameContainsSlash => 'O nome da pasta não pode conter barra';
	@override String get folderNameExists => 'Já existe uma pasta com esse nome';
}

// Path: home.deleteFolder
class _Translations$home$deleteFolder$pt_BR extends Translations$home$deleteFolder$en {
	_Translations$home$deleteFolder$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get deleteFolder => 'Excluir pasta';
	@override String deleteName({required Object f}) => 'Excluir ${f}';
	@override String get delete => 'Excluir';
	@override String get alsoDeleteContents => 'Excluir também todas as notas desta pasta';
}

// Path: home.sort
class _Translations$home$sort$pt_BR extends Translations$home$sort$en {
	_Translations$home$sort$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sortBy => 'Ordenar por';
	@override String get nameAToZ => 'Nome (A-Z)';
	@override String get nameZToA => 'Nome (Z-A)';
	@override String get lastModifiedNewToOld => 'Edição (mais recentes primeiro)';
	@override String get lastModifiedOldToNew => 'Edição (mais antigas primeiro)';
}

// Path: home.layout
class _Translations$home$layout$pt_BR extends Translations$home$layout$en {
	_Translations$home$layout$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get layout => 'Layout';
	@override String get masonryGrid => 'Grade em mosaico';
	@override String get simpleGrid => 'Grade simples';
}

// Path: sentry.consent
class _Translations$sentry$consent$pt_BR extends Translations$sentry$consent$en {
	_Translations$sentry$consent$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Quer ajudar a melhorar o BadNotes?';
	@override late final _Translations$sentry$consent$description$pt_BR description = _Translations$sentry$consent$description$pt_BR._(_root);
	@override late final _Translations$sentry$consent$answers$pt_BR answers = _Translations$sentry$consent$answers$pt_BR._(_root);
}

// Path: settings.prefCategories
class _Translations$settings$prefCategories$pt_BR extends Translations$settings$prefCategories$en {
	_Translations$settings$prefCategories$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get general => 'Geral';
	@override String get writing => 'Escrita';
	@override String get editor => 'Editor';
	@override String get performance => 'Desempenho';
	@override String get advanced => 'Avançado';
}

// Path: settings.prefLabels
class _Translations$settings$prefLabels$pt_BR extends Translations$settings$prefLabels$en {
	_Translations$settings$prefLabels$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get locale => 'Idioma';
	@override String get appTheme => 'Tema do app';
	@override String get platform => 'Tipo de tema';
	@override String get layoutSize => 'Tipo de layout';
	@override String get customAccentColor => 'Cor de destaque personalizada';
	@override String get hyperlegibleFont => 'Fonte Atkinson Hyperlegible';
	@override String get shouldCheckForUpdates => 'Verificar atualizações do BadNotes';
	@override String get shouldAlwaysAlertForUpdates => 'Atualizações mais rápidas';
	@override String get allowInsecureConnections => 'Permitir conexões inseguras';
	@override String get syncOnlyOnWifi => 'Sincronizar só no Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'Enviar prévias usando dados móveis';
	@override String get editorToolbarAlignment => 'Posição da barra de ferramentas';
	@override String get editorToolbarShowInFullscreen => 'Mostrar a barra de ferramentas em tela cheia';
	@override String get editorAutoInvert => 'Inverter notas no modo escuro';
	@override String get preferGreyscale => 'Preferir cores em tons de cinza';
	@override String get maxImageSize => 'Tamanho máximo da imagem';
	@override String get autoClearWhiteboardOnExit => 'Limpar o quadro branco automaticamente';
	@override String get disableEraserAfterUse => 'Desativar a borracha automaticamente';
	@override String get hideFingerDrawingToggle => 'Ocultar o botão de desenho com o dedo';
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Desativar o desenho com o dedo automaticamente';
	@override String get editorPromptRename => 'Pedir para renomear novas notas';
	@override String get recentColorsDontSavePresets => 'Não salvar cores predefinidas nas cores recentes';
	@override String get recentColorsLength => 'Quantas cores recentes guardar';
	@override String get printPageIndicators => 'Imprimir indicadores de página';
	@override String get autosave => 'Salvamento automático';
	@override String get shapeRecognitionDelay => 'Atraso no reconhecimento de formas';
	@override String get autoStraightenLines => 'Endireitar linhas automaticamente';
	@override String get customDataDir => 'Pasta personalizada do BadNotes';
	@override String get sentry => 'Relatórios de erros';
}

// Path: settings.prefDescriptions
class _Translations$settings$prefDescriptions$pt_BR extends Translations$settings$prefDescriptions$en {
	_Translations$settings$prefDescriptions$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get syncOnlyOnWifi => 'Desativado: as notas também sincronizam com dados móveis. Ativado: a sincronização espera o Wi-Fi';
	@override String get syncPreviewsOnMobileData => 'As miniaturas das notas normalmente esperam o Wi-Fi para economizar dados';
	@override String get hyperlegibleFont => 'Melhora a legibilidade para pessoas com baixa visão';
	@override String get allowInsecureConnections => '(Não recomendado) Permite que o BadNotes se conecte a servidores com certificados autoassinados/não confiáveis';
	@override String get preferGreyscale => 'Para telas de tinta eletrônica (e-ink)';
	@override String get autoClearWhiteboardOnExit => 'Limpa o quadro branco quando você sai do app';
	@override String get disableEraserAfterUse => 'Volta automaticamente para a caneta depois de usar a borracha';
	@override String get maxImageSize => 'Imagens maiores serão comprimidas';
	@override late final _Translations$settings$prefDescriptions$hideFingerDrawing$pt_BR hideFingerDrawing = _Translations$settings$prefDescriptions$hideFingerDrawing$pt_BR._(_root);
	@override String get autoDisableFingerDrawingWhenStylusDetected => 'Desativa o desenho com o dedo quando uma caneta stylus é detectada';
	@override String get editorPromptRename => 'Você pode renomear as notas depois a qualquer momento';
	@override String get printPageIndicators => 'Mostra indicadores de página nas exportações';
	@override String get autosave => 'Salva automaticamente após um breve intervalo, ou nunca';
	@override String get shapeRecognitionDelay => 'Quanto tempo segurar a caneta parada até o traço virar uma forma';
	@override String get autoStraightenLines => 'Endireita linhas longas sem precisar usar a caneta de formas';
	@override String get shouldAlwaysAlertForUpdates => 'Avisar sobre atualizações assim que estiverem disponíveis';
	@override late final _Translations$settings$prefDescriptions$sentry$pt_BR sentry = _Translations$settings$prefDescriptions$sentry$pt_BR._(_root);
}

// Path: settings.themeModes
class _Translations$settings$themeModes$pt_BR extends Translations$settings$themeModes$en {
	_Translations$settings$themeModes$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get system => 'Sistema';
	@override String get light => 'Claro';
	@override String get dark => 'Escuro';
}

// Path: settings.layoutSizes
class _Translations$settings$layoutSizes$pt_BR extends Translations$settings$layoutSizes$en {
	_Translations$settings$layoutSizes$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get auto => 'Automático';
	@override String get phone => 'Celular';
	@override String get tablet => 'Tablet';
}

// Path: settings.accentColorPicker
class _Translations$settings$accentColorPicker$pt_BR extends Translations$settings$accentColorPicker$en {
	_Translations$settings$accentColorPicker$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get pickAColor => 'Escolha uma cor';
}

// Path: settings.reset
class _Translations$settings$reset$pt_BR extends Translations$settings$reset$en {
	_Translations$settings$reset$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Redefinir esta configuração?';
	@override String get button => 'Redefinir';
}

// Path: settings.customDataDir
class _Translations$settings$customDataDir$pt_BR extends Translations$settings$customDataDir$en {
	_Translations$settings$customDataDir$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get select => 'Selecionar';
	@override String get mustBeEmpty => 'A pasta selecionada precisa estar vazia';
	@override String get mustBeDoneSyncing => 'Aguarde a sincronização terminar antes de trocar a pasta';
	@override String get unsupported => 'No momento, este recurso é só para desenvolvedores. Usá-lo provavelmente causará perda de dados.';
}

// Path: login.form
class _Translations$login$form$pt_BR extends Translations$login$form$en {
	_Translations$login$form$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override TextSpan agreeToPrivacyPolicy({required InlineSpanBuilder linkToPrivacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'Ao entrar, você concorda com a '),
		linkToPrivacyPolicy('Política de Privacidade'),
		const TextSpan(text: '.'),
	]);
}

// Path: login.status
class _Translations$login$status$pt_BR extends Translations$login$status$en {
	_Translations$login$status$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get loggedOut => 'Desconectado';
	@override String get tapToLogin => 'Toque para sincronizar com o Google Drive';
	@override String hi({required Object u}) => 'Olá, ${u}!';
	@override String get almostDone => 'Quase pronto para sincronizar, toque para concluir o login';
	@override String get loggedIn => 'Sincronização ativada';
}

// Path: login.ncLoginStep
class _Translations$login$ncLoginStep$pt_BR extends Translations$login$ncLoginStep$en {
	_Translations$login$ncLoginStep$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get whereToStoreData => 'Escolha onde guardar seus dados:';
	@override String get cloudStorage => 'Google Drive ou OneDrive';
	@override String get loginWithGoogleDrive => 'Continuar com o Google Drive';
	@override String get loginWithOneDrive => 'Continuar com o OneDrive';
	@override String get cloudLoginFailed => 'Não foi possível entrar';
	@override String get comingSoon => 'Em breve';
	@override String get badnotesNcServer => 'Servidor Nextcloud do BadNotes';
	@override String get otherNcServer => 'Outro servidor Nextcloud';
	@override String get serverUrl => 'URL do servidor';
	@override String get loginWithBadNotes => 'Entrar com o BadNotes';
	@override String get loginWithNextcloud => 'Entrar com o Nextcloud';
	@override late final _Translations$login$ncLoginStep$loginFlow$pt_BR loginFlow = _Translations$login$ncLoginStep$loginFlow$pt_BR._(_root);
}

// Path: login.encLoginStep
class _Translations$login$encLoginStep$pt_BR extends Translations$login$encLoginStep$en {
	_Translations$login$encLoginStep$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get enterEncPassword => 'Para proteger seus dados, digite sua senha de criptografia:';
	@override String get newToBadNotes => 'Novo no BadNotes? É só digitar uma nova senha de criptografia.';
	@override String get encPassword => 'Senha de criptografia';
	@override String get encFaqTitle => 'Perguntas frequentes';
	@override String get wrongEncPassword => 'Não foi possível descriptografar com a senha informada. Tente digitá-la novamente.';
	@override String get connectionFailed => 'Algo deu errado ao conectar ao servidor. Tente novamente mais tarde.';
	@override List<dynamic> get encFaq => [
		_Translations$login$encLoginStep$encFaq$0$pt_BR._(_root),
		_Translations$login$encLoginStep$encFaq$1$pt_BR._(_root),
		_Translations$login$encLoginStep$encFaq$2$pt_BR._(_root),
	];
}

// Path: profile.quickLinks
class _Translations$profile$quickLinks$pt_BR extends Translations$profile$quickLinks$en {
	_Translations$profile$quickLinks$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get serverHomepage => 'Página inicial do servidor';
	@override String get deleteAccount => 'Excluir conta';
}

// Path: profile.faq.0
class _Translations$profile$faq$0$pt_BR extends Translations$profile$faq$0$en {
	_Translations$profile$faq$0$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Vou perder minhas notas se eu sair?';
	@override String get a => 'Não. Suas notas continuarão no seu dispositivo e no servidor. Elas não serão sincronizadas com o servidor até você entrar novamente. Aguarde a sincronização terminar antes de sair para não perder dados (veja o progresso da sincronização na tela inicial).';
}

// Path: profile.faq.1
class _Translations$profile$faq$1$pt_BR extends Translations$profile$faq$1$en {
	_Translations$profile$faq$1$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Onde minhas notas ficam guardadas?';
	@override String get a => 'Em uma pasta "BadNotes" no seu Google Drive, ou em "Apps/BadNotes" no seu OneDrive. Os arquivos são criptografados, então só podem ser abertos no BadNotes.';
}

// Path: profile.faq.2
class _Translations$profile$faq$2$pt_BR extends Translations$profile$faq$2$en {
	_Translations$profile$faq$2$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Como altero minha senha de criptografia?';
	@override String get a => '0. Aguarde a sincronização terminar (veja o progresso da sincronização na tela inicial).\n1. Saia do BadNotes.\n2. Exclua a pasta \'BadNotes\' do seu Google Drive ou OneDrive. Isso exclui todas as suas notas da nuvem, não do seu dispositivo.\n3. Entre novamente no BadNotes. Você poderá escolher uma nova senha de criptografia ao entrar.\n4. Não se esqueça de sair e entrar novamente no BadNotes nos seus outros dispositivos também.';
}

// Path: profile.faq.3
class _Translations$profile$faq$3$pt_BR extends Translations$profile$faq$3$en {
	_Translations$profile$faq$3$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Como posso excluir minha conta?';
	@override String get a => 'O BadNotes não tem conta própria. Saia e depois exclua a pasta \'BadNotes\' do seu Google Drive ou OneDrive.\nPara também remover o acesso do BadNotes, acesse myaccount.google.com/permissions (Google) ou account.live.com/consent/Manage (Microsoft).';
}

// Path: editor.toolbar
class _Translations$editor$toolbar$pt_BR extends Translations$editor$toolbar$en {
	_Translations$editor$toolbar$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get toggleColors => 'Alternar cores (Ctrl C)';
	@override String get select => 'Selecionar';
	@override String get toggleEraser => 'Alternar borracha (Ctrl E)';
	@override String get photo => 'Imagens';
	@override String get text => 'Texto';
	@override String get toggleFingerDrawing => 'Alternar desenho com o dedo (Ctrl F)';
	@override String get undo => 'Desfazer';
	@override String get redo => 'Refazer';
	@override String get export => 'Exportar (Ctrl Shift S)';
	@override String get exportAs => 'Exportar como:';
	@override String get fullscreen => 'Alternar tela cheia (F11)';
}

// Path: editor.pens
class _Translations$editor$pens$pt_BR extends Translations$editor$pens$en {
	_Translations$editor$pens$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get fountainPen => 'Caneta-tinteiro';
	@override String get ballpointPen => 'Caneta esferográfica';
	@override String get highlighter => 'Marca-texto';
	@override String get pencil => 'Lápis';
	@override String get shapePen => 'Caneta de formas';
	@override String get laserPointer => 'Apontador laser';
}

// Path: editor.penOptions
class _Translations$editor$penOptions$pt_BR extends Translations$editor$penOptions$en {
	_Translations$editor$penOptions$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get size => 'Tamanho';
}

// Path: editor.colors
class _Translations$editor$colors$pt_BR extends Translations$editor$colors$en {
	_Translations$editor$colors$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get colorPicker => 'Seletor de cores';
	@override String customBrightnessHue({required Object h, required Object b}) => '${h} ${b} personalizado';
	@override String customHue({required Object h}) => '${h} personalizado';
	@override String get dark => 'escuro';
	@override String get light => 'claro';
	@override String get black => 'Preto';
	@override String get darkGrey => 'Cinza-escuro';
	@override String get grey => 'Cinza';
	@override String get lightGrey => 'Cinza-claro';
	@override String get white => 'Branco';
	@override String get red => 'Vermelho';
	@override String get green => 'Verde';
	@override String get cyan => 'Ciano';
	@override String get blue => 'Azul';
	@override String get yellow => 'Amarelo';
	@override String get purple => 'Roxo';
	@override String get pink => 'Rosa';
	@override String get orange => 'Laranja';
	@override String get pastelRed => 'Vermelho pastel';
	@override String get pastelOrange => 'Laranja pastel';
	@override String get pastelYellow => 'Amarelo pastel';
	@override String get pastelGreen => 'Verde pastel';
	@override String get pastelCyan => 'Ciano pastel';
	@override String get pastelBlue => 'Azul pastel';
	@override String get pastelPurple => 'Roxo pastel';
	@override String get pastelPink => 'Rosa pastel';
}

// Path: editor.imageOptions
class _Translations$editor$imageOptions$pt_BR extends Translations$editor$imageOptions$en {
	_Translations$editor$imageOptions$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Opções da imagem';
	@override String get invertible => 'Invertível';
	@override String get download => 'Baixar';
	@override String get setAsBackground => 'Definir como fundo';
	@override String get removeAsBackground => 'Remover do fundo';
	@override String get delete => 'Excluir';
}

// Path: editor.selectionBar
class _Translations$editor$selectionBar$pt_BR extends Translations$editor$selectionBar$en {
	_Translations$editor$selectionBar$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Excluir';
	@override String get duplicate => 'Duplicar';
}

// Path: editor.menu
class _Translations$editor$menu$pt_BR extends Translations$editor$menu$en {
	_Translations$editor$menu$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String clearPage({required Object page, required Object totalPages}) => 'Limpar página ${page}/${totalPages}';
	@override String get clearAllPages => 'Limpar todas as páginas';
	@override String get insertPage => 'Inserir página abaixo';
	@override String get duplicatePage => 'Duplicar página';
	@override String get deletePage => 'Excluir página';
	@override String get lineHeight => 'Altura da linha';
	@override String get lineHeightDescription => 'Também controla o tamanho do texto nas notas digitadas';
	@override String get lineThickness => 'Espessura da linha';
	@override String get lineThicknessDescription => 'Espessura das linhas do fundo';
	@override String get backgroundImageFit => 'Ajuste da imagem de fundo';
	@override String get backgroundPattern => 'Padrão de fundo';
	@override String get import => 'Importar';
	@override String get watchServer => 'Acompanhar atualizações no servidor';
	@override String get watchServerReadOnly => 'A edição fica desativada enquanto você acompanha o servidor';
	@override late final _Translations$editor$menu$boxFits$pt_BR boxFits = _Translations$editor$menu$boxFits$pt_BR._(_root);
	@override late final _Translations$editor$menu$bgPatterns$pt_BR bgPatterns = _Translations$editor$menu$bgPatterns$pt_BR._(_root);
}

// Path: editor.photoPdfError
class _Translations$editor$photoPdfError$pt_BR extends Translations$editor$photoPdfError$en {
	_Translations$editor$photoPdfError$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Erro';
	@override String get message => 'Arquivos PDF não podem ser adicionados como imagem. Use "${_root.editor.menu.import} > PDF" para isso.';
}

// Path: editor.readOnlyBanner
class _Translations$editor$readOnlyBanner$pt_BR extends Translations$editor$readOnlyBanner$en {
	_Translations$editor$readOnlyBanner$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Modo somente leitura';
	@override String get watchingServer => 'Você está acompanhando atualizações no servidor. A edição fica desativada neste modo.';
	@override String get corrupted => 'Não foi possível carregar a nota. Ela pode estar corrompida ou ainda sendo baixada.';
}

// Path: editor.versionTooNew
class _Translations$editor$versionTooNew$pt_BR extends Translations$editor$versionTooNew$en {
	_Translations$editor$versionTooNew$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Esta nota foi editada em uma versão mais recente do BadNotes';
	@override String get subtitle => 'Editar esta nota pode causar a perda de algumas informações. Quer ignorar isso e editar mesmo assim?';
	@override String get allowEditing => 'Permitir edição';
}

// Path: editor.quill
class _Translations$editor$quill$pt_BR extends Translations$editor$quill$en {
	_Translations$editor$quill$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get typeSomething => 'Digite algo aqui…';
}

// Path: editor.hud
class _Translations$editor$hud$pt_BR extends Translations$editor$hud$en {
	_Translations$editor$hud$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get unlockZoom => 'Desbloquear zoom';
	@override String get lockZoom => 'Bloquear zoom';
	@override String get unlockSingleFingerPan => 'Ativar movimento com um dedo';
	@override String get lockSingleFingerPan => 'Desativar movimento com um dedo';
	@override String get unlockAxisAlignedPan => 'Liberar movimento fora da horizontal ou vertical';
	@override String get lockAxisAlignedPan => 'Travar movimento na horizontal ou vertical';
}

// Path: sentry.consent.description
class _Translations$sentry$consent$description$pt_BR extends Translations$sentry$consent$description$en {
	_Translations$sentry$consent$description$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get question => 'Quer enviar automaticamente relatórios de erros inesperados? Isso me ajuda a encontrar e corrigir problemas mais rápido.';
	@override String get scope => 'Os relatórios podem conter informações sobre o erro e o seu dispositivo. Fiz o possível para filtrar dados pessoais, mas alguns podem permanecer.';
	@override String get currentlyOff => 'Se você der o consentimento, o envio de erros será ativado depois que você reiniciar o app.';
	@override String get currentlyOn => 'Se você retirar o consentimento, reinicie o app para desativar o envio de erros.';
	@override TextSpan learnMoreInPrivacyPolicy({required InlineSpanBuilder link}) => TextSpan(children: [
		const TextSpan(text: 'Saiba mais na '),
		link('política de privacidade'),
		const TextSpan(text: '.'),
	]);
}

// Path: sentry.consent.answers
class _Translations$sentry$consent$answers$pt_BR extends Translations$sentry$consent$answers$en {
	_Translations$sentry$consent$answers$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Sim';
	@override String get no => 'Não';
	@override String get later => 'Perguntar depois';
}

// Path: settings.prefDescriptions.hideFingerDrawing
class _Translations$settings$prefDescriptions$hideFingerDrawing$pt_BR extends Translations$settings$prefDescriptions$hideFingerDrawing$en {
	_Translations$settings$prefDescriptions$hideFingerDrawing$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get shown => 'Evita ativar ou desativar sem querer';
	@override String get fixedOn => 'O desenho com o dedo fica sempre ativado';
	@override String get fixedOff => 'O desenho com o dedo fica sempre desativado';
}

// Path: settings.prefDescriptions.sentry
class _Translations$settings$prefDescriptions$sentry$pt_BR extends Translations$settings$prefDescriptions$sentry$en {
	_Translations$settings$prefDescriptions$sentry$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get active => 'Ativo';
	@override String get inactive => 'Inativo';
	@override String get activeUntilRestart => 'Ativo até você reiniciar o app';
	@override String get inactiveUntilRestart => 'Inativo até você reiniciar o app';
}

// Path: login.ncLoginStep.loginFlow
class _Translations$login$ncLoginStep$loginFlow$pt_BR extends Translations$login$ncLoginStep$loginFlow$en {
	_Translations$login$ncLoginStep$loginFlow$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get pleaseAuthorize => 'Autorize o BadNotes a acessar sua conta do Nextcloud';
	@override String get followPrompts => 'Siga as instruções na interface do Nextcloud';
	@override String get browserDidntOpen => 'A página de login não abriu? Clique aqui';
}

// Path: login.encLoginStep.encFaq.0
class _Translations$login$encLoginStep$encFaq$0$pt_BR extends Translations$login$encLoginStep$encFaq$0$en {
	_Translations$login$encLoginStep$encFaq$0$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get q => 'O que é uma senha de criptografia? Por que usar duas senhas?';
	@override String get a => 'Sua conta do Google ou da Microsoft é usada para acessar a nuvem. A senha de criptografia "embaralha" seus dados antes mesmo de eles chegarem à nuvem.\nMesmo que alguém consiga acessar sua conta do Google ou da Microsoft, suas notas continuarão seguras e criptografadas com uma senha separada. Isso oferece uma segunda camada de segurança para proteger seus dados.\nNinguém consegue acessar suas notas no servidor sem a sua senha de criptografia, mas isso também significa que, se você esquecer essa senha, perderá o acesso aos seus dados.';
}

// Path: login.encLoginStep.encFaq.1
class _Translations$login$encLoginStep$encFaq$1$pt_BR extends Translations$login$encLoginStep$encFaq$1$en {
	_Translations$login$encLoginStep$encFaq$1$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Ainda não defini uma senha de criptografia. Onde consigo uma?';
	@override String get a => 'Escolha uma nova senha de criptografia e digite-a acima.\nO BadNotes vai gerar suas chaves de criptografia a partir dessa senha automaticamente.';
}

// Path: login.encLoginStep.encFaq.2
class _Translations$login$encLoginStep$encFaq$2$pt_BR extends Translations$login$encLoginStep$encFaq$2$en {
	_Translations$login$encLoginStep$encFaq$2$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get q => 'Posso usar a mesma senha da minha conta do Google ou da Microsoft?';
	@override String get a => 'Melhor não. Uma senha de criptografia separada mantém suas notas seguras mesmo que alguém invada essa conta.';
}

// Path: editor.menu.boxFits
class _Translations$editor$menu$boxFits$pt_BR extends Translations$editor$menu$boxFits$en {
	_Translations$editor$menu$boxFits$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get fill => 'Esticar';
	@override String get cover => 'Cobrir';
	@override String get contain => 'Conter';
}

// Path: editor.menu.bgPatterns
class _Translations$editor$menu$bgPatterns$pt_BR extends Translations$editor$menu$bgPatterns$en {
	_Translations$editor$menu$bgPatterns$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get none => 'Em branco';
	@override String get college => 'Pautado universitário';
	@override String get collegeRtl => 'Pautado universitário (invertido)';
	@override String get lined => 'Pautado';
	@override String get grid => 'Quadriculado';
	@override String get dots => 'Pontilhado';
	@override String get staffs => 'Pautas musicais';
	@override String get tablature => 'Tablatura';
	@override String get cornell => 'Cornell';
}
