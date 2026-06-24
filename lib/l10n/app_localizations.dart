import 'package:flutter/material.dart';

/// App-wide translations for en, es, fr, de, zh.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLanguageCodes = ['en', 'es', 'fr', 'de', 'zh'];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('zh'),
  ];

  static String normalizeLanguageCode(String raw) {
    switch (raw) {
      case 'English':
        return 'en';
      case 'Spanish':
        return 'es';
      case 'French':
        return 'fr';
      case 'German':
        return 'de';
      case 'Chinese':
        return 'zh';
      default:
        return supportedLanguageCodes.contains(raw) ? raw : 'en';
    }
  }

  String languageDisplayName(String code) {
    switch (code) {
      case 'es':
        return translate('langSpanish');
      case 'fr':
        return translate('langFrench');
      case 'de':
        return translate('langGerman');
      case 'zh':
        return translate('langChinese');
      case 'en':
      default:
        return translate('langEnglish');
    }
  }

  String translate(String key) =>
      _localized[key]?[locale.languageCode] ?? _localized[key]?['en'] ?? key;

  // ── Navigation ──────────────────────────────────────────────────────────
  String get appName => translate('appName');
  String get dashboard => translate('dashboard');
  String get animals => translate('animals');
  String get cattleInfo => translate('cattleInfo');
  String get milking => translate('milking');
  String get cameras => translate('cameras');
  String get settings => translate('settings');
  String get logout => translate('logout');
  String get farmer => translate('farmer');

  // ── Common ──────────────────────────────────────────────────────────────
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get close => translate('close');
  String get delete => translate('delete');
  String get done => translate('done');
  String get send => translate('send');
  String get reset => translate('reset');
  String get clear => translate('clear');
  String get copy => translate('copy');
  String get dismiss => translate('dismiss');
  String get refresh => translate('refresh');
  String get search => translate('search');
  String get add => translate('add');
  String get remove => translate('remove');
  String get yes => translate('yes');
  String get no => translate('no');

  // ── Auth ────────────────────────────────────────────────────────────────
  String get login => translate('login');
  String get signUp => translate('signUp');
  String get email => translate('email');
  String get password => translate('password');
  String get welcomeBack => translate('welcomeBack');
  String get loginFailed => translate('loginFailed');
  String get createAccount => translate('createAccount');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get dontHaveAccount => translate('dontHaveAccount');

  // ── Dashboard ─────────────────────────────────────────────────────────
  String get welcome => translate('welcome');
  String get searchCattleId => translate('searchCattleId');
  String get liveUpdatesActive => translate('liveUpdatesActive');
  String get aiServer => translate('aiServer');
  String get aiServerShort => translate('aiServerShort');
  String get aiServerOnline => translate('aiServerOnline');
  String get aiServerOffline => translate('aiServerOffline');
  String get aiServerChecking => translate('aiServerChecking');
  String get aiServerSubtitle => translate('aiServerSubtitle');
  String get aiServerEndpoint => translate('aiServerEndpoint');
  String get aiServerReconnect => translate('aiServerReconnect');
  String get aiServerNeverChecked => translate('aiServerNeverChecked');
  String get aiServerCheckedJustNow => translate('aiServerCheckedJustNow');
  String aiServerCheckedMinutes(int minutes) =>
      translate('aiServerCheckedMinutes').replaceAll('{n}', '$minutes');
  String aiServerCheckedAt(String time) =>
      translate('aiServerCheckedAt').replaceAll('{time}', time);
  String get copyCommand => translate('copyCommand');
  String get totalCows => translate('totalCows');
  String get milkingCows => translate('milkingCows');
  String get lamenessCases => translate('lamenessCases');
  String get todaysCattle => translate('todaysCattle');
  String get monthlyHealthReport => translate('monthlyHealthReport');
  String get recentDetections => translate('recentDetections');
  String get noDetectionsToday => translate('noDetectionsToday');
  String get pullToRefresh => translate('pullToRefresh');

  // ── Animals ─────────────────────────────────────────────────────────────
  String get addAnimal => translate('addAnimal');
  String get addNewAnimal => translate('addNewAnimal');
  String get deleteAnimal => translate('deleteAnimal');
  String get deleteAnimalConfirm => translate('deleteAnimalConfirm');
  String get srNo => translate('srNo');
  String get earTagId => translate('earTagId');
  String get isMilking => translate('isMilking');
  String get isLameness => translate('isLameness');
  String get noAnimalsYet => translate('noAnimalsYet');

  // ── Settings sections ───────────────────────────────────────────────────
  String get notifications => translate('notifications');
  String get enableNotifications => translate('enableNotifications');
  String get enableNotificationsSub => translate('enableNotificationsSub');
  String get lamenessAlerts => translate('lamenessAlerts');
  String get lamenessAlertsSub => translate('lamenessAlertsSub');
  String get milkingAlerts => translate('milkingAlerts');
  String get milkingAlertsSub => translate('milkingAlertsSub');
  String get healthAlerts => translate('healthAlerts');
  String get healthAlertsSub => translate('healthAlertsSub');
  String get aiDetectionSettings => translate('aiDetectionSettings');
  String get detectionConfidence => translate('detectionConfidence');
  String get detectionConfidenceSub => translate('detectionConfidenceSub');
  String get autoProcessVideos => translate('autoProcessVideos');
  String get autoProcessVideosSub => translate('autoProcessVideosSub');
  String get saveProcessedVideos => translate('saveProcessedVideos');
  String get saveProcessedVideosSub => translate('saveProcessedVideosSub');
  String get cameraSettings => translate('cameraSettings');
  String get cameraFps => translate('cameraFps');
  String get cameraFpsSub => translate('cameraFpsSub');
  String get videoQuality => translate('videoQuality');
  String get videoQualitySub => translate('videoQualitySub');
  String get dataAndSync => translate('dataAndSync');
  String get autoSync => translate('autoSync');
  String get autoSyncSub => translate('autoSyncSub');
  String get syncInterval => translate('syncInterval');
  String get syncIntervalSub => translate('syncIntervalSub');
  String get wifiOnly => translate('wifiOnly');
  String get wifiOnlySub => translate('wifiOnlySub');
  String get display => translate('display');
  String get darkMode => translate('darkMode');
  String get darkModeSub => translate('darkModeSub');
  String get language => translate('language');
  String get languageSub => translate('languageSub');
  String get account => translate('account');
  String get profile => translate('profile');
  String get profileSub => translate('profileSub');
  String get privacySecurity => translate('privacySecurity');
  String get privacySecuritySub => translate('privacySecuritySub');
  String get dataManagement => translate('dataManagement');
  String get dataManagementSub => translate('dataManagementSub');
  String get support => translate('support');
  String get helpFaq => translate('helpFaq');
  String get helpFaqSub => translate('helpFaqSub');
  String get contactSupport => translate('contactSupport');
  String get contactSupportSub => translate('contactSupportSub');
  String get sendFeedback => translate('sendFeedback');
  String get sendFeedbackSub => translate('sendFeedbackSub');
  String get dangerZone => translate('dangerZone');
  String get clearCache => translate('clearCache');
  String get clearCacheSub => translate('clearCacheSub');
  String get resetSettings => translate('resetSettings');
  String get resetSettingsSub => translate('resetSettingsSub');
  String get logoutSub => translate('logoutSub');

  // ── Settings dialogs ────────────────────────────────────────────────────
  String get aboutTitle => translate('aboutTitle');
  String get aboutBody => translate('aboutBody');
  String get profileUpdated => translate('profileUpdated');
  String get profileUpdateFailed => translate('profileUpdateFailed');
  String get nameLabel => translate('nameLabel');
  String get farmNameLabel => translate('farmNameLabel');
  String get shareAnalytics => translate('shareAnalytics');
  String get shareAnalyticsSub => translate('shareAnalyticsSub');
  String get crashReporting => translate('crashReporting');
  String get crashReportingSub => translate('crashReportingSub');
  String get privacyNote => translate('privacyNote');
  String get contactSupportBody => translate('contactSupportBody');
  String get supportEmailCopied => translate('supportEmailCopied');
  String get feedbackHint => translate('feedbackHint');
  String get feedbackThanks => translate('feedbackThanks');
  String get exportData => translate('exportData');
  String get exportDataSub => translate('exportDataSub');
  String get deleteAllData => translate('deleteAllData');
  String get deleteAllDataSub => translate('deleteAllDataSub');
  String get deleteAllDataConfirm => translate('deleteAllDataConfirm');
  String get allDataDeleted => translate('allDataDeleted');
  String get deleteDataFailed => translate('deleteDataFailed');
  String get dataExported => translate('dataExported');
  String get clearCacheConfirm => translate('clearCacheConfirm');
  String get cacheCleared => translate('cacheCleared');
  String get cacheEmpty => translate('cacheEmpty');
  String get resetSettingsConfirm => translate('resetSettingsConfirm');
  String get settingsReset => translate('settingsReset');
  String get logoutConfirm => translate('logoutConfirm');
  String get logoutQuestion => translate('logoutQuestion');
  String get langEnglish => translate('langEnglish');
  String get langSpanish => translate('langSpanish');
  String get langFrench => translate('langFrench');
  String get langGerman => translate('langGerman');
  String get langChinese => translate('langChinese');
  String syncMinutes(int n) => translate('syncMinutes').replaceAll('{n}', '$n');

  // ── Video quality options ─────────────────────────────────────────────────
  String videoQualityLabel(String key) => translate('vq_$key');

  // ── FAQ ─────────────────────────────────────────────────────────────────
  String get faqUploadTitle => translate('faqUploadTitle');
  String get faqUploadBody => translate('faqUploadBody');
  String get faqSyncTitle => translate('faqSyncTitle');
  String get faqSyncBody => translate('faqSyncBody');
  String get faqConfidenceTitle => translate('faqConfidenceTitle');
  String get faqConfidenceBody => translate('faqConfidenceBody');
  String get faqNotificationsTitle => translate('faqNotificationsTitle');
  String get faqNotificationsBody => translate('faqNotificationsBody');

  String welcomeUser(String name) =>
      translate('welcomeUser').replaceAll('{name}', name);

  String deleteAnimalMessage(String id) =>
      translate('deleteAnimalMessage').replaceAll('{id}', id);

  String cacheClearedCount(int n) =>
      translate('cacheClearedCount').replaceAll('{n}', '$n');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// All translation strings — key → { languageCode → text }.
const Map<String, Map<String, String>> _localized = {
  'appName': {
    'en': 'CattleEye',
    'es': 'Monitor de Ganado IA',
    'fr': 'Moniteur Bovin IA',
    'de': 'Rinder-KI-Monitor',
    'zh': '奶牛 AI 监测',
  },
  'dashboard': {
    'en': 'Dashboard',
    'es': 'Panel',
    'fr': 'Tableau de bord',
    'de': 'Dashboard',
    'zh': '仪表盘',
  },
  'animals': {
    'en': 'Animals',
    'es': 'Animales',
    'fr': 'Animaux',
    'de': 'Tiere',
    'zh': '动物',
  },
  'cattleInfo': {
    'en': 'Cattle Info',
    'es': 'Info del ganado',
    'fr': 'Info bétail',
    'de': 'Rinderinfo',
    'zh': '牛只信息',
  },
  'milking': {
    'en': 'Milking',
    'es': 'Ordeño',
    'fr': 'Traite',
    'de': 'Melken',
    'zh': '挤奶',
  },
  'cameras': {
    'en': 'Cameras',
    'es': 'Cámaras',
    'fr': 'Caméras',
    'de': 'Kameras',
    'zh': '摄像头',
  },
  'settings': {
    'en': 'Settings',
    'es': 'Ajustes',
    'fr': 'Paramètres',
    'de': 'Einstellungen',
    'zh': '设置',
  },
  'logout': {
    'en': 'Logout',
    'es': 'Cerrar sesión',
    'fr': 'Déconnexion',
    'de': 'Abmelden',
    'zh': '退出登录',
  },
  'farmer': {
    'en': 'Farmer',
    'es': 'Ganadero',
    'fr': 'Éleveur',
    'de': 'Landwirt',
    'zh': '农场主',
  },
  'cancel': {
    'en': 'Cancel',
    'es': 'Cancelar',
    'fr': 'Annuler',
    'de': 'Abbrechen',
    'zh': '取消',
  },
  'save': {
    'en': 'Save',
    'es': 'Guardar',
    'fr': 'Enregistrer',
    'de': 'Speichern',
    'zh': '保存',
  },
  'close': {
    'en': 'Close',
    'es': 'Cerrar',
    'fr': 'Fermer',
    'de': 'Schließen',
    'zh': '关闭',
  },
  'delete': {
    'en': 'Delete',
    'es': 'Eliminar',
    'fr': 'Supprimer',
    'de': 'Löschen',
    'zh': '删除',
  },
  'done': {
    'en': 'Done',
    'es': 'Listo',
    'fr': 'Terminé',
    'de': 'Fertig',
    'zh': '完成',
  },
  'send': {
    'en': 'Send',
    'es': 'Enviar',
    'fr': 'Envoyer',
    'de': 'Senden',
    'zh': '发送',
  },
  'reset': {
    'en': 'Reset',
    'es': 'Restablecer',
    'fr': 'Réinitialiser',
    'de': 'Zurücksetzen',
    'zh': '重置',
  },
  'clear': {
    'en': 'Clear',
    'es': 'Borrar',
    'fr': 'Effacer',
    'de': 'Leeren',
    'zh': '清除',
  },
  'copy': {
    'en': 'Copy email',
    'es': 'Copiar correo',
    'fr': 'Copier l\'e-mail',
    'de': 'E-Mail kopieren',
    'zh': '复制邮箱',
  },
  'dismiss': {
    'en': 'Dismiss',
    'es': 'Descartar',
    'fr': 'Ignorer',
    'de': 'Schließen',
    'zh': '忽略',
  },
  'refresh': {
    'en': 'Refresh',
    'es': 'Actualizar',
    'fr': 'Actualiser',
    'de': 'Aktualisieren',
    'zh': '刷新',
  },
  'search': {
    'en': 'Search',
    'es': 'Buscar',
    'fr': 'Rechercher',
    'de': 'Suchen',
    'zh': '搜索',
  },
  'add': {
    'en': 'Add',
    'es': 'Añadir',
    'fr': 'Ajouter',
    'de': 'Hinzufügen',
    'zh': '添加',
  },
  'remove': {
    'en': 'Remove',
    'es': 'Quitar',
    'fr': 'Retirer',
    'de': 'Entfernen',
    'zh': '移除',
  },
  'yes': {'en': 'Yes', 'es': 'Sí', 'fr': 'Oui', 'de': 'Ja', 'zh': '是'},
  'no': {'en': 'No', 'es': 'No', 'fr': 'Non', 'de': 'Nein', 'zh': '否'},
  'login': {
    'en': 'Login',
    'es': 'Iniciar sesión',
    'fr': 'Connexion',
    'de': 'Anmelden',
    'zh': '登录',
  },
  'signUp': {
    'en': 'Sign Up',
    'es': 'Registrarse',
    'fr': 'S\'inscrire',
    'de': 'Registrieren',
    'zh': '注册',
  },
  'email': {
    'en': 'Email',
    'es': 'Correo',
    'fr': 'E-mail',
    'de': 'E-Mail',
    'zh': '邮箱',
  },
  'password': {
    'en': 'Password',
    'es': 'Contraseña',
    'fr': 'Mot de passe',
    'de': 'Passwort',
    'zh': '密码',
  },
  'welcomeBack': {
    'en': 'Welcome back',
    'es': 'Bienvenido de nuevo',
    'fr': 'Bon retour',
    'de': 'Willkommen zurück',
    'zh': '欢迎回来',
  },
  'welcomeUser': {
    'en': 'Welcome back, {name}!',
    'es': '¡Bienvenido, {name}!',
    'fr': 'Bon retour, {name} !',
    'de': 'Willkommen zurück, {name}!',
    'zh': '欢迎回来，{name}！',
  },
  'loginFailed': {
    'en': 'Login failed. Try again.',
    'es': 'Error al iniciar sesión.',
    'fr': 'Échec de connexion.',
    'de': 'Anmeldung fehlgeschlagen.',
    'zh': '登录失败，请重试。',
  },
  'createAccount': {
    'en': 'Create Account',
    'es': 'Crear cuenta',
    'fr': 'Créer un compte',
    'de': 'Konto erstellen',
    'zh': '创建账户',
  },
  'alreadyHaveAccount': {
    'en': 'Already have an account?',
    'es': '¿Ya tienes cuenta?',
    'fr': 'Déjà un compte ?',
    'de': 'Bereits ein Konto?',
    'zh': '已有账户？',
  },
  'dontHaveAccount': {
    'en': 'Don\'t have an account?',
    'es': '¿No tienes cuenta?',
    'fr': 'Pas de compte ?',
    'de': 'Kein Konto?',
    'zh': '没有账户？',
  },
  'welcome': {
    'en': 'Welcome, ',
    'es': 'Bienvenido, ',
    'fr': 'Bienvenue, ',
    'de': 'Willkommen, ',
    'zh': '欢迎，',
  },
  'searchCattleId': {
    'en': 'Search by Cattle ID…',
    'es': 'Buscar por ID…',
    'fr': 'Rechercher par ID…',
    'de': 'Nach Ohrmarke suchen…',
    'zh': '按耳标搜索…',
  },
  'liveUpdatesActive': {
    'en': 'Live updates active',
    'es': 'Actualizaciones en vivo',
    'fr': 'Mises à jour en direct',
    'de': 'Live-Updates aktiv',
    'zh': '实时更新已开启',
  },
  'aiServer': {
    'en': 'AI Server',
    'es': 'Servidor IA',
    'fr': 'Serveur IA',
    'de': 'KI-Server',
    'zh': 'AI 服务器',
  },
  'aiServerShort': {'en': 'AI', 'es': 'IA', 'fr': 'IA', 'de': 'KI', 'zh': 'AI'},
  'aiServerOnline': {
    'en': 'Online',
    'es': 'En línea',
    'fr': 'En ligne',
    'de': 'Online',
    'zh': '在线',
  },
  'aiServerOffline': {
    'en': 'Offline',
    'es': 'Desconectado',
    'fr': 'Hors ligne',
    'de': 'Offline',
    'zh': '离线',
  },
  'aiServerChecking': {
    'en': 'Checking…',
    'es': 'Comprobando…',
    'fr': 'Vérification…',
    'de': 'Prüfe…',
    'zh': '检查中…',
  },
  'aiServerSubtitle': {
    'en': 'Local Python model backend',
    'es': 'Backend Python local',
    'fr': 'Backend Python local',
    'de': 'Lokales Python-Backend',
    'zh': '本地 Python 模型服务',
  },
  'aiServerEndpoint': {
    'en': 'Endpoint',
    'es': 'Endpoint',
    'fr': 'Point de terminaison',
    'de': 'Endpunkt',
    'zh': '地址',
  },
  'aiServerReconnect': {
    'en': 'Check connection',
    'es': 'Comprobar conexión',
    'fr': 'Vérifier la connexion',
    'de': 'Verbindung prüfen',
    'zh': '检查连接',
  },
  'aiServerNeverChecked': {
    'en': 'Not checked yet',
    'es': 'Sin comprobar',
    'fr': 'Pas encore vérifié',
    'de': 'Noch nicht geprüft',
    'zh': '尚未检查',
  },
  'aiServerCheckedJustNow': {
    'en': 'Just now',
    'es': 'Ahora mismo',
    'fr': 'À l\'instant',
    'de': 'Gerade eben',
    'zh': '刚刚',
  },
  'aiServerCheckedMinutes': {
    'en': '{n} min ago',
    'es': 'hace {n} min',
    'fr': 'il y a {n} min',
    'de': 'vor {n} Min.',
    'zh': '{n} 分钟前',
  },
  'aiServerCheckedAt': {
    'en': 'At {time}',
    'es': 'A las {time}',
    'fr': 'À {time}',
    'de': 'Um {time}',
    'zh': '{time}',
  },
  'copyCommand': {
    'en': 'Copy start command',
    'es': 'Copiar comando',
    'fr': 'Copier la commande',
    'de': 'Startbefehl kopieren',
    'zh': '复制启动命令',
  },
  'totalCows': {
    'en': 'Total Cows',
    'es': 'Total vacas',
    'fr': 'Total vaches',
    'de': 'Kühe gesamt',
    'zh': '牛只总数',
  },
  'milkingCows': {
    'en': 'Milking Cows',
    'es': 'Vacas en ordeño',
    'fr': 'Vaches en traite',
    'de': 'Melkende Kühe',
    'zh': '挤奶牛',
  },
  'lamenessCases': {
    'en': 'Lameness',
    'es': 'Cojera',
    'fr': 'Boiterie',
    'de': 'Lahmheit',
    'zh': '跛行',
  },
  'todaysCattle': {
    'en': 'Today\'s Cattle',
    'es': 'Ganado de hoy',
    'fr': 'Bétail du jour',
    'de': 'Heutiges Vieh',
    'zh': '今日牛只',
  },
  'monthlyHealthReport': {
    'en': 'Monthly Cattle Health Report',
    'es': 'Informe mensual de salud',
    'fr': 'Rapport mensuel de santé',
    'de': 'Monatlicher Gesundheitsbericht',
    'zh': '月度健康报告',
  },
  'recentDetections': {
    'en': 'Recent Detections',
    'es': 'Detecciones recientes',
    'fr': 'Détections récentes',
    'de': 'Letzte Erkennungen',
    'zh': '最近检测',
  },
  'noDetectionsToday': {
    'en': 'No detections today',
    'es': 'Sin detecciones hoy',
    'fr': 'Aucune détection aujourd\'hui',
    'de': 'Keine Erkennungen heute',
    'zh': '今日暂无检测',
  },
  'pullToRefresh': {
    'en': 'Pull to refresh',
    'es': 'Desliza para actualizar',
    'fr': 'Tirez pour actualiser',
    'de': 'Zum Aktualisieren ziehen',
    'zh': '下拉刷新',
  },
  'addAnimal': {
    'en': 'Add Animal',
    'es': 'Añadir animal',
    'fr': 'Ajouter un animal',
    'de': 'Tier hinzufügen',
    'zh': '添加动物',
  },
  'addNewAnimal': {
    'en': 'Add New Animal',
    'es': 'Añadir nuevo animal',
    'fr': 'Nouvel animal',
    'de': 'Neues Tier',
    'zh': '添加新动物',
  },
  'deleteAnimal': {
    'en': 'Delete animal',
    'es': 'Eliminar animal',
    'fr': 'Supprimer l\'animal',
    'de': 'Tier löschen',
    'zh': '删除动物',
  },
  'deleteAnimalMessage': {
    'en': 'Remove {id} from your herd?',
    'es': '¿Quitar {id} del rebaño?',
    'fr': 'Retirer {id} du troupeau ?',
    'de': '{id} aus der Herde entfernen?',
    'zh': '从牛群中移除 {id}？',
  },
  'srNo': {'en': 'Sr No', 'es': 'Nº', 'fr': 'N°', 'de': 'Nr.', 'zh': '序号'},
  'earTagId': {
    'en': 'Ear Tag ID',
    'es': 'ID oreja',
    'fr': 'ID boucle',
    'de': 'Ohrmarke',
    'zh': '耳标 ID',
  },
  'isMilking': {
    'en': 'Is Milking',
    'es': 'En ordeño',
    'fr': 'En traite',
    'de': 'Wird gemolken',
    'zh': '是否挤奶',
  },
  'isLameness': {
    'en': 'Is Lameness',
    'es': 'Cojera',
    'fr': 'Boiterie',
    'de': 'Lahm',
    'zh': '是否跛行',
  },
  'noAnimalsYet': {
    'en': 'No animals yet',
    'es': 'Sin animales aún',
    'fr': 'Aucun animal',
    'de': 'Noch keine Tiere',
    'zh': '暂无动物',
  },
  'notifications': {
    'en': 'Notifications',
    'es': 'Notificaciones',
    'fr': 'Notifications',
    'de': 'Benachrichtigungen',
    'zh': '通知',
  },
  'enableNotifications': {
    'en': 'Enable Notifications',
    'es': 'Activar notificaciones',
    'fr': 'Activer les notifications',
    'de': 'Benachrichtigungen aktivieren',
    'zh': '启用通知',
  },
  'enableNotificationsSub': {
    'en': 'Receive alerts and updates',
    'es': 'Recibir alertas y actualizaciones',
    'fr': 'Recevoir alertes et mises à jour',
    'de': 'Warnungen und Updates erhalten',
    'zh': '接收提醒和更新',
  },
  'lamenessAlerts': {
    'en': 'Lameness Alerts',
    'es': 'Alertas de cojera',
    'fr': 'Alertes boiterie',
    'de': 'Lahmheits-Warnungen',
    'zh': '跛行提醒',
  },
  'lamenessAlertsSub': {
    'en': 'Alert when lameness is detected',
    'es': 'Alerta al detectar cojera',
    'fr': 'Alerte en cas de boiterie',
    'de': 'Warnung bei Lahmheit',
    'zh': '检测到跛行时提醒',
  },
  'milkingAlerts': {
    'en': 'Milking Alerts',
    'es': 'Alertas de ordeño',
    'fr': 'Alertes traite',
    'de': 'Melk-Warnungen',
    'zh': '挤奶提醒',
  },
  'milkingAlertsSub': {
    'en': 'Alert for milking status changes',
    'es': 'Alerta por cambios de ordeño',
    'fr': 'Alerte changement de traite',
    'de': 'Warnung bei Melkstatus',
    'zh': '挤奶状态变化时提醒',
  },
  'healthAlerts': {
    'en': 'Health Alerts',
    'es': 'Alertas de salud',
    'fr': 'Alertes santé',
    'de': 'Gesundheits-Warnungen',
    'zh': '健康提醒',
  },
  'healthAlertsSub': {
    'en': 'Alert for unusual feeding or health issues',
    'es': 'Alerta por alimentación o salud',
    'fr': 'Alerte alimentation ou santé',
    'de': 'Warnung bei Fütterung/Gesundheit',
    'zh': '异常进食或健康问题时提醒',
  },
  'aiDetectionSettings': {
    'en': 'AI Detection Settings',
    'es': 'Detección IA',
    'fr': 'Détection IA',
    'de': 'KI-Erkennung',
    'zh': 'AI 检测设置',
  },
  'detectionConfidence': {
    'en': 'Detection Confidence',
    'es': 'Confianza de detección',
    'fr': 'Confiance de détection',
    'de': 'Erkennungssicherheit',
    'zh': '检测置信度',
  },
  'detectionConfidenceSub': {
    'en': 'Minimum confidence threshold for AI detection',
    'es': 'Umbral mínimo de confianza',
    'fr': 'Seuil minimum de confiance',
    'de': 'Mindest-Sicherheitsschwelle',
    'zh': 'AI 检测的最低置信度',
  },
  'autoProcessVideos': {
    'en': 'Auto Process Videos',
    'es': 'Procesar videos automáticamente',
    'fr': 'Traiter les vidéos auto',
    'de': 'Videos automatisch verarbeiten',
    'zh': '自动处理视频',
  },
  'autoProcessVideosSub': {
    'en': 'Automatically analyze uploaded videos',
    'es': 'Analizar videos subidos automáticamente',
    'fr': 'Analyser les vidéos importées',
    'de': 'Hochgeladene Videos analysieren',
    'zh': '自动分析上传的视频',
  },
  'saveProcessedVideos': {
    'en': 'Save Processed Videos',
    'es': 'Guardar videos procesados',
    'fr': 'Enregistrer les analyses',
    'de': 'Analysen speichern',
    'zh': '保存处理结果',
  },
  'saveProcessedVideosSub': {
    'en': 'Store AI analysis results for video uploads',
    'es': 'Guardar resultados de análisis IA',
    'fr': 'Stocker les résultats IA',
    'de': 'KI-Ergebnisse speichern',
    'zh': '保存视频分析的 AI 结果',
  },
  'cameraSettings': {
    'en': 'Camera Settings',
    'es': 'Ajustes de cámara',
    'fr': 'Paramètres caméra',
    'de': 'Kameraeinstellungen',
    'zh': '摄像头设置',
  },
  'cameraFps': {
    'en': 'Camera FPS',
    'es': 'FPS de cámara',
    'fr': 'FPS caméra',
    'de': 'Kamera-FPS',
    'zh': '摄像头帧率',
  },
  'cameraFpsSub': {
    'en': 'Controls live analysis frequency',
    'es': 'Controla la frecuencia de análisis',
    'fr': 'Fréquence d\'analyse en direct',
    'de': 'Live-Analyse-Frequenz',
    'zh': '控制实时分析频率',
  },
  'videoQuality': {
    'en': 'Video Quality',
    'es': 'Calidad de video',
    'fr': 'Qualité vidéo',
    'de': 'Videoqualität',
    'zh': '视频质量',
  },
  'videoQualitySub': {
    'en': 'Frame sampling density for video analysis',
    'es': 'Densidad de muestreo de fotogramas',
    'fr': 'Densité d\'échantillonnage',
    'de': 'Frame-Abtastrate',
    'zh': '视频分析的帧采样密度',
  },
  'dataAndSync': {
    'en': 'Data & Sync',
    'es': 'Datos y sincronización',
    'fr': 'Données et sync',
    'de': 'Daten & Sync',
    'zh': '数据与同步',
  },
  'autoSync': {
    'en': 'Auto Sync',
    'es': 'Sincronización automática',
    'fr': 'Sync automatique',
    'de': 'Auto-Sync',
    'zh': '自动同步',
  },
  'autoSyncSub': {
    'en': 'Realtime updates and periodic cloud refresh',
    'es': 'Tiempo real y actualización periódica',
    'fr': 'Temps réel et actualisation',
    'de': 'Echtzeit und periodische Aktualisierung',
    'zh': '实时更新和定期云端刷新',
  },
  'syncInterval': {
    'en': 'Sync Interval',
    'es': 'Intervalo de sync',
    'fr': 'Intervalle de sync',
    'de': 'Sync-Intervall',
    'zh': '同步间隔',
  },
  'syncIntervalSub': {
    'en': 'How often to refresh data from cloud',
    'es': 'Frecuencia de actualización',
    'fr': 'Fréquence d\'actualisation',
    'de': 'Aktualisierungsintervall',
    'zh': '从云端刷新数据的频率',
  },
  'syncMinutes': {
    'en': '{n} minutes',
    'es': '{n} minutos',
    'fr': '{n} minutes',
    'de': '{n} Minuten',
    'zh': '{n} 分钟',
  },
  'wifiOnly': {
    'en': 'WiFi Only',
    'es': 'Solo WiFi',
    'fr': 'WiFi uniquement',
    'de': 'Nur WLAN',
    'zh': '仅 WiFi',
  },
  'wifiOnlySub': {
    'en': 'Sync only when connected to WiFi',
    'es': 'Sincronizar solo con WiFi',
    'fr': 'Sync uniquement en WiFi',
    'de': 'Nur über WLAN synchronisieren',
    'zh': '仅在 WiFi 下同步',
  },
  'display': {
    'en': 'Display',
    'es': 'Pantalla',
    'fr': 'Affichage',
    'de': 'Anzeige',
    'zh': '显示',
  },
  'darkMode': {
    'en': 'Dark Mode',
    'es': 'Modo oscuro',
    'fr': 'Mode sombre',
    'de': 'Dunkelmodus',
    'zh': '深色模式',
  },
  'darkModeSub': {
    'en': 'Enable dark theme',
    'es': 'Activar tema oscuro',
    'fr': 'Activer le thème sombre',
    'de': 'Dunkles Design aktivieren',
    'zh': '启用深色主题',
  },
  'language': {
    'en': 'Language',
    'es': 'Idioma',
    'fr': 'Langue',
    'de': 'Sprache',
    'zh': '语言',
  },
  'languageSub': {
    'en': 'App display language',
    'es': 'Idioma de la aplicación',
    'fr': 'Langue de l\'application',
    'de': 'App-Sprache',
    'zh': '应用显示语言',
  },
  'account': {
    'en': 'Account',
    'es': 'Cuenta',
    'fr': 'Compte',
    'de': 'Konto',
    'zh': '账户',
  },
  'profile': {
    'en': 'Profile',
    'es': 'Perfil',
    'fr': 'Profil',
    'de': 'Profil',
    'zh': '个人资料',
  },
  'profileSub': {
    'en': 'Manage your profile information',
    'es': 'Gestionar tu perfil',
    'fr': 'Gérer votre profil',
    'de': 'Profil verwalten',
    'zh': '管理个人资料',
  },
  'privacySecurity': {
    'en': 'Privacy & Security',
    'es': 'Privacidad y seguridad',
    'fr': 'Confidentialité',
    'de': 'Datenschutz',
    'zh': '隐私与安全',
  },
  'privacySecuritySub': {
    'en': 'Manage privacy settings',
    'es': 'Gestionar privacidad',
    'fr': 'Gérer la confidentialité',
    'de': 'Datenschutz verwalten',
    'zh': '管理隐私设置',
  },
  'dataManagement': {
    'en': 'Data Management',
    'es': 'Gestión de datos',
    'fr': 'Gestion des données',
    'de': 'Datenverwaltung',
    'zh': '数据管理',
  },
  'dataManagementSub': {
    'en': 'Export or delete your data',
    'es': 'Exportar o eliminar datos',
    'fr': 'Exporter ou supprimer',
    'de': 'Daten exportieren/löschen',
    'zh': '导出或删除数据',
  },
  'support': {
    'en': 'Support',
    'es': 'Soporte',
    'fr': 'Assistance',
    'de': 'Support',
    'zh': '支持',
  },
  'helpFaq': {
    'en': 'Help & FAQ',
    'es': 'Ayuda y FAQ',
    'fr': 'Aide et FAQ',
    'de': 'Hilfe & FAQ',
    'zh': '帮助与常见问题',
  },
  'helpFaqSub': {
    'en': 'Get help and view frequently asked questions',
    'es': 'Ayuda y preguntas frecuentes',
    'fr': 'Aide et questions fréquentes',
    'de': 'Hilfe und häufige Fragen',
    'zh': '获取帮助和常见问题',
  },
  'contactSupport': {
    'en': 'Contact Support',
    'es': 'Contactar soporte',
    'fr': 'Contacter le support',
    'de': 'Support kontaktieren',
    'zh': '联系支持',
  },
  'contactSupportSub': {
    'en': 'Reach out to our support team',
    'es': 'Contacta a nuestro equipo',
    'fr': 'Contacter notre équipe',
    'de': 'Unser Team kontaktieren',
    'zh': '联系我们的支持团队',
  },
  'sendFeedback': {
    'en': 'Send Feedback',
    'es': 'Enviar comentarios',
    'fr': 'Envoyer un avis',
    'de': 'Feedback senden',
    'zh': '发送反馈',
  },
  'sendFeedbackSub': {
    'en': 'Share your thoughts with us',
    'es': 'Comparte tu opinión',
    'fr': 'Partagez votre avis',
    'de': 'Teilen Sie Ihre Meinung',
    'zh': '与我们分享您的想法',
  },
  'dangerZone': {
    'en': 'Danger Zone',
    'es': 'Zona de peligro',
    'fr': 'Zone dangereuse',
    'de': 'Gefahrenzone',
    'zh': '危险操作',
  },
  'clearCache': {
    'en': 'Clear Cache',
    'es': 'Borrar caché',
    'fr': 'Vider le cache',
    'de': 'Cache leeren',
    'zh': '清除缓存',
  },
  'clearCacheSub': {
    'en': 'Clear AI analysis cache',
    'es': 'Borrar caché de análisis IA',
    'fr': 'Vider le cache IA',
    'de': 'KI-Cache leeren',
    'zh': '清除 AI 分析缓存',
  },
  'resetSettings': {
    'en': 'Reset Settings',
    'es': 'Restablecer ajustes',
    'fr': 'Réinitialiser',
    'de': 'Einstellungen zurücksetzen',
    'zh': '重置设置',
  },
  'resetSettingsSub': {
    'en': 'Reset all settings to default',
    'es': 'Restablecer valores predeterminados',
    'fr': 'Réinitialiser par défaut',
    'de': 'Auf Standard zurücksetzen',
    'zh': '将所有设置恢复默认',
  },
  'logoutSub': {
    'en': 'Sign out of your account',
    'es': 'Cerrar sesión de tu cuenta',
    'fr': 'Se déconnecter',
    'de': 'Vom Konto abmelden',
    'zh': '退出当前账户',
  },
  'aboutTitle': {
    'en': 'About CattleEye',
    'es': 'Acerca de',
    'fr': 'À propos',
    'de': 'Über die App',
    'zh': '关于应用',
  },
  'aboutBody': {
    'en':
        'AI-powered cattle monitoring for lameness detection, milking status, and herd health.',
    'es': 'Monitoreo de ganado con IA para cojera, ordeño y salud del rebaño.',
    'fr': 'Surveillance bovine par IA : boiterie, traite et santé du troupeau.',
    'de':
        'KI-gestützte Rinderüberwachung für Lahmheit, Melkstatus und Gesundheit.',
    'zh': 'AI 驱动的奶牛监测：跛行检测、挤奶状态和牛群健康。',
  },
  'profileUpdated': {
    'en': 'Profile updated',
    'es': 'Perfil actualizado',
    'fr': 'Profil mis à jour',
    'de': 'Profil aktualisiert',
    'zh': '资料已更新',
  },
  'profileUpdateFailed': {
    'en': 'Update failed',
    'es': 'Error al actualizar',
    'fr': 'Échec de mise à jour',
    'de': 'Aktualisierung fehlgeschlagen',
    'zh': '更新失败',
  },
  'nameLabel': {
    'en': 'Name',
    'es': 'Nombre',
    'fr': 'Nom',
    'de': 'Name',
    'zh': '姓名',
  },
  'farmNameLabel': {
    'en': 'Farm name',
    'es': 'Nombre de la granja',
    'fr': 'Nom de la ferme',
    'de': 'Hofname',
    'zh': '农场名称',
  },
  'shareAnalytics': {
    'en': 'Share analytics',
    'es': 'Compartir analíticas',
    'fr': 'Partager les analyses',
    'de': 'Analysen teilen',
    'zh': '共享分析数据',
  },
  'shareAnalyticsSub': {
    'en': 'Help improve the app with anonymous usage data',
    'es': 'Ayuda con datos anónimos',
    'fr': 'Données d\'usage anonymes',
    'de': 'Anonyme Nutzungsdaten',
    'zh': '通过匿名使用数据改进应用',
  },
  'crashReporting': {
    'en': 'Crash reporting',
    'es': 'Informes de fallos',
    'fr': 'Rapports de plantage',
    'de': 'Absturzberichte',
    'zh': '崩溃报告',
  },
  'crashReportingSub': {
    'en': 'Send crash reports to improve stability',
    'es': 'Enviar informes de fallos',
    'fr': 'Envoyer des rapports',
    'de': 'Absturzberichte senden',
    'zh': '发送崩溃报告以提高稳定性',
  },
  'privacyNote': {
    'en':
        'Your cattle data is stored in your Supabase account and is only visible to you.',
    'es': 'Tus datos se almacenan en tu cuenta Supabase.',
    'fr': 'Vos données sont stockées dans votre compte Supabase.',
    'de': 'Ihre Daten werden in Ihrem Supabase-Konto gespeichert.',
    'zh': '您的数据存储在 Supabase 账户中，仅您可见。',
  },
  'contactSupportBody': {
    'en': 'Email our team:',
    'es': 'Correo de soporte:',
    'fr': 'E-mail du support :',
    'de': 'Support-E-Mail:',
    'zh': '联系邮箱：',
  },
  'supportEmailCopied': {
    'en': 'Support email copied to clipboard',
    'es': 'Correo copiado',
    'fr': 'E-mail copié',
    'de': 'E-Mail kopiert',
    'zh': '支持邮箱已复制',
  },
  'feedbackHint': {
    'en': 'Tell us what you think…',
    'es': 'Cuéntanos tu opinión…',
    'fr': 'Votre avis…',
    'de': 'Ihre Meinung…',
    'zh': '告诉我们您的想法…',
  },
  'feedbackThanks': {
    'en': 'Thank you for your feedback!',
    'es': '¡Gracias por tus comentarios!',
    'fr': 'Merci pour votre avis !',
    'de': 'Danke für Ihr Feedback!',
    'zh': '感谢您的反馈！',
  },
  'exportData': {
    'en': 'Export Data',
    'es': 'Exportar datos',
    'fr': 'Exporter les données',
    'de': 'Daten exportieren',
    'zh': '导出数据',
  },
  'exportDataSub': {
    'en': 'Copy a summary to clipboard',
    'es': 'Copiar resumen',
    'fr': 'Copier un résumé',
    'de': 'Zusammenfassung kopieren',
    'zh': '复制摘要到剪贴板',
  },
  'deleteAllData': {
    'en': 'Delete All Data',
    'es': 'Eliminar todos los datos',
    'fr': 'Supprimer toutes les données',
    'de': 'Alle Daten löschen',
    'zh': '删除所有数据',
  },
  'deleteAllDataSub': {
    'en': 'Remove all animals and detections from cloud',
    'es': 'Eliminar animales y detecciones',
    'fr': 'Supprimer animaux et détections',
    'de': 'Alle Tiere und Erkennungen löschen',
    'zh': '从云端删除所有动物和检测记录',
  },
  'deleteAllDataConfirm': {
    'en':
        'This permanently deletes all your animals and detection records from the cloud. This cannot be undone.',
    'es': 'Esto elimina permanentemente todos tus datos. No se puede deshacer.',
    'fr': 'Suppression définitive de toutes vos données. Irréversible.',
    'de': 'Löscht alle Daten dauerhaft. Nicht rückgängig zu machen.',
    'zh': '这将永久删除云端的所有动物和检测记录，无法撤销。',
  },
  'allDataDeleted': {
    'en': 'All data deleted',
    'es': 'Datos eliminados',
    'fr': 'Données supprimées',
    'de': 'Alle Daten gelöscht',
    'zh': '所有数据已删除',
  },
  'deleteDataFailed': {
    'en': 'Failed to delete data',
    'es': 'Error al eliminar',
    'fr': 'Échec de suppression',
    'de': 'Löschen fehlgeschlagen',
    'zh': '删除数据失败',
  },
  'dataExported': {
    'en': 'Data summary copied to clipboard',
    'es': 'Resumen copiado',
    'fr': 'Résumé copié',
    'de': 'Zusammenfassung kopiert',
    'zh': '数据摘要已复制',
  },
  'clearCacheConfirm': {
    'en': 'This clears cached AI analysis results from device storage.',
    'es': 'Borra resultados de análisis IA en caché.',
    'fr': 'Efface le cache d\'analyse IA.',
    'de': 'Löscht zwischengespeicherte KI-Analysen.',
    'zh': '这将清除设备上缓存的 AI 分析结果。',
  },
  'cacheCleared': {
    'en': 'Cache cleared',
    'es': 'Caché borrada',
    'fr': 'Cache vidé',
    'de': 'Cache geleert',
    'zh': '缓存已清除',
  },
  'cacheClearedCount': {
    'en': 'Cleared {n} cached analysis entries',
    'es': 'Se borraron {n} entradas',
    'fr': '{n} entrées supprimées',
    'de': '{n} Cache-Einträge gelöscht',
    'zh': '已清除 {n} 条缓存',
  },
  'cacheEmpty': {
    'en': 'Cache was already empty',
    'es': 'La caché ya estaba vacía',
    'fr': 'Le cache était déjà vide',
    'de': 'Cache war bereits leer',
    'zh': '缓存已为空',
  },
  'resetSettingsConfirm': {
    'en': 'This will reset all settings to their default values.',
    'es': 'Restablecerá todos los ajustes.',
    'fr': 'Réinitialisera tous les paramètres.',
    'de': 'Setzt alle Einstellungen zurück.',
    'zh': '这将把所有设置恢复为默认值。',
  },
  'settingsReset': {
    'en': 'Settings reset to default',
    'es': 'Ajustes restablecidos',
    'fr': 'Paramètres réinitialisés',
    'de': 'Einstellungen zurückgesetzt',
    'zh': '设置已重置',
  },
  'logoutConfirm': {
    'en': 'Logout?',
    'es': '¿Cerrar sesión?',
    'fr': 'Déconnexion ?',
    'de': 'Abmelden?',
    'zh': '退出登录？',
  },
  'logoutQuestion': {
    'en': 'Are you sure you want to logout?',
    'es': '¿Seguro que quieres cerrar sesión?',
    'fr': 'Voulez-vous vous déconnecter ?',
    'de': 'Möchten Sie sich abmelden?',
    'zh': '确定要退出登录吗？',
  },
  'langEnglish': {
    'en': 'English',
    'es': 'Inglés',
    'fr': 'Anglais',
    'de': 'Englisch',
    'zh': '英语',
  },
  'langSpanish': {
    'en': 'Spanish',
    'es': 'Español',
    'fr': 'Espagnol',
    'de': 'Spanisch',
    'zh': '西班牙语',
  },
  'langFrench': {
    'en': 'French',
    'es': 'Francés',
    'fr': 'Français',
    'de': 'Französisch',
    'zh': '法语',
  },
  'langGerman': {
    'en': 'German',
    'es': 'Alemán',
    'fr': 'Allemand',
    'de': 'Deutsch',
    'zh': '德语',
  },
  'langChinese': {
    'en': 'Chinese',
    'es': 'Chino',
    'fr': 'Chinois',
    'de': 'Chinesisch',
    'zh': '中文',
  },
  'faqUploadTitle': {
    'en': 'How do I upload a video?',
    'es': '¿Cómo subo un video?',
    'fr': 'Comment importer une vidéo ?',
    'de': 'Wie lade ich ein Video hoch?',
    'zh': '如何上传视频？',
  },
  'faqUploadBody': {
    'en':
        'Open Cameras, choose Upload Video, and select a file. Detections appear on Dashboard and Animals.',
    'es':
        'Abre Cámaras, sube un video y las detecciones aparecerán en el panel.',
    'fr':
        'Ouvrez Caméras, importez une vidéo. Les détections apparaissent au tableau de bord.',
    'de':
        'Öffnen Sie Kameras, laden Sie ein Video hoch. Erkennungen erscheinen im Dashboard.',
    'zh': '打开摄像头，选择上传视频。检测结果会显示在仪表盘和动物页面。',
  },
  'faqSyncTitle': {
    'en': 'Why is sync paused?',
    'es': '¿Por qué está pausada la sync?',
    'fr': 'Pourquoi la sync est en pause ?',
    'de': 'Warum ist Sync pausiert?',
    'zh': '为什么同步暂停了？',
  },
  'faqSyncBody': {
    'en':
        'If WiFi Only is enabled, sync waits until you are on WiFi. Change this under Data & Sync.',
    'es':
        'Si Solo WiFi está activo, espera conexión WiFi. Cambia en Datos y sync.',
    'fr':
        'Si WiFi uniquement est activé, attendez le WiFi. Modifiez dans Données et sync.',
    'de': 'Bei Nur WLAN wartet Sync auf WLAN. Ändern unter Daten & Sync.',
    'zh': '若启用“仅 WiFi”，需连接 WiFi 后才同步。可在“数据与同步”中修改。',
  },
  'faqConfidenceTitle': {
    'en': 'What does detection confidence do?',
    'es': '¿Qué hace la confianza?',
    'fr': 'À quoi sert la confiance ?',
    'de': 'Was bewirkt die Erkennungssicherheit?',
    'zh': '检测置信度有什么作用？',
  },
  'faqConfidenceBody': {
    'en':
        'Higher values require stronger AI certainty before saving detections or analyzing videos.',
    'es': 'Valores más altos exigen mayor certeza de la IA.',
    'fr': 'Des valeurs plus élevées exigent plus de certitude IA.',
    'de': 'Höhere Werte erfordern mehr KI-Sicherheit.',
    'zh': '数值越高，保存检测或分析视频所需的 AI 把握越大。',
  },
  'faqNotificationsTitle': {
    'en': 'How do notifications work?',
    'es': '¿Cómo funcionan las notificaciones?',
    'fr': 'Comment fonctionnent les notifications ?',
    'de': 'Wie funktionieren Benachrichtigungen?',
    'zh': '通知如何工作？',
  },
  'faqNotificationsBody': {
    'en':
        'Enable alerts under Notifications. Events show as in-app snackbars when new detections arrive.',
    'es':
        'Activa alertas en Notificaciones. Los eventos aparecen como avisos en la app.',
    'fr': 'Activez les alertes. Les événements s\'affichent dans l\'app.',
    'de': 'Aktivieren Sie Warnungen. Ereignisse erscheinen als Snackbars.',
    'zh': '在通知中启用提醒。有新检测时会显示应用内提示。',
  },
  'vq_low': {
    'en': 'low',
    'es': 'baja',
    'fr': 'basse',
    'de': 'niedrig',
    'zh': '低',
  },
  'vq_medium': {
    'en': 'medium',
    'es': 'media',
    'fr': 'moyenne',
    'de': 'mittel',
    'zh': '中',
  },
  'vq_high': {
    'en': 'high',
    'es': 'alta',
    'fr': 'haute',
    'de': 'hoch',
    'zh': '高',
  },
  'vq_ultra': {
    'en': 'ultra',
    'es': 'ultra',
    'fr': 'ultra',
    'de': 'ultra',
    'zh': '超高',
  },
};
