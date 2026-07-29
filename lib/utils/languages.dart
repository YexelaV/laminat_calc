/// The languages offered on the start screen and in the settings sheet. Kept
/// beside neither of them because the two must never disagree.
class AppLanguage {
  final String code;
  final String flagAsset;
  final String name;

  const AppLanguage(this.code, this.flagAsset, this.name);
}

const appLanguages = [
  AppLanguage('ru', 'assets/ru.svg', 'Русский'),
  AppLanguage('en', 'assets/gb.svg', 'English'),
  AppLanguage('de', 'assets/de.svg', 'Deutsch'),
  AppLanguage('es', 'assets/es.svg', 'Español'),
  AppLanguage('fr', 'assets/fr.svg', 'Français'),
  AppLanguage('pt', 'assets/pt.svg', 'Português'),
  AppLanguage('pl', 'assets/pl.svg', 'Polski'),
  AppLanguage('it', 'assets/it.svg', 'Italiano'),
  AppLanguage('tr', 'assets/tr.svg', 'Türkçe'),
  AppLanguage('zh', 'assets/cn.svg', '中文'),
];
