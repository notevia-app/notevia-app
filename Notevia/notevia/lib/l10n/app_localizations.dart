import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Notevia'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @voiceNotes.
  ///
  /// In en, this message translates to:
  /// **'Voice Notes'**
  String get voiceNotes;

  /// No description provided for @timeTools.
  ///
  /// In en, this message translates to:
  /// **'Time Tools'**
  String get timeTools;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note title...'**
  String get noteTitle;

  /// No description provided for @noteContent.
  ///
  /// In en, this message translates to:
  /// **'Note Content'**
  String get noteContent;

  /// No description provided for @noteTags.
  ///
  /// In en, this message translates to:
  /// **'Note Tags'**
  String get noteTags;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag...'**
  String get addTag;

  /// No description provided for @removeTag.
  ///
  /// In en, this message translates to:
  /// **'Remove Tag'**
  String get removeTag;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @markAsImportant.
  ///
  /// In en, this message translates to:
  /// **'Mark as Important'**
  String get markAsImportant;

  /// No description provided for @unmarkAsImportant.
  ///
  /// In en, this message translates to:
  /// **'Unmark as Important'**
  String get unmarkAsImportant;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @hideNote.
  ///
  /// In en, this message translates to:
  /// **'Hide Note'**
  String get hideNote;

  /// No description provided for @showNote.
  ///
  /// In en, this message translates to:
  /// **'Show Note'**
  String get showNote;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteNoteConfirm;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @noteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Note updated'**
  String get noteUpdated;

  /// No description provided for @searchNotes.
  ///
  /// In en, this message translates to:
  /// **'Search Notes'**
  String get searchNotes;

  /// No description provided for @noNotesFound.
  ///
  /// In en, this message translates to:
  /// **'No notes found'**
  String get noNotesFound;

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get allNotes;

  /// No description provided for @importantNotes.
  ///
  /// In en, this message translates to:
  /// **'Important Notes'**
  String get importantNotes;

  /// No description provided for @hiddenNotes.
  ///
  /// In en, this message translates to:
  /// **'Hidden Notes'**
  String get hiddenNotes;

  /// No description provided for @recentNotes.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get recentNotes;

  /// No description provided for @oldestNotes.
  ///
  /// In en, this message translates to:
  /// **'Oldest Notes'**
  String get oldestNotes;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'By Date'**
  String get sortByDate;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'By Title'**
  String get sortByTitle;

  /// No description provided for @sortByImportance.
  ///
  /// In en, this message translates to:
  /// **'By Importance'**
  String get sortByImportance;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter By'**
  String get filterBy;

  /// No description provided for @filterByTags.
  ///
  /// In en, this message translates to:
  /// **'By Tags'**
  String get filterByTags;

  /// No description provided for @filterByImportance.
  ///
  /// In en, this message translates to:
  /// **'By Importance'**
  String get filterByImportance;

  /// No description provided for @enhanceWithAI.
  ///
  /// In en, this message translates to:
  /// **'Enhance with AI'**
  String get enhanceWithAI;

  /// No description provided for @summarizeWithAI.
  ///
  /// In en, this message translates to:
  /// **'Summarize with AI'**
  String get summarizeWithAI;

  /// No description provided for @continueWithAI.
  ///
  /// In en, this message translates to:
  /// **'Continue with AI'**
  String get continueWithAI;

  /// No description provided for @aiProcessing.
  ///
  /// In en, this message translates to:
  /// **'AI Processing'**
  String get aiProcessing;

  /// No description provided for @aiError.
  ///
  /// In en, this message translates to:
  /// **'AI error'**
  String get aiError;

  /// No description provided for @newDiary.
  ///
  /// In en, this message translates to:
  /// **'New Diary'**
  String get newDiary;

  /// No description provided for @diaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Diary title...'**
  String get diaryTitle;

  /// No description provided for @diaryContent.
  ///
  /// In en, this message translates to:
  /// **'Diary Content'**
  String get diaryContent;

  /// No description provided for @diaryDate.
  ///
  /// In en, this message translates to:
  /// **'Diary Date'**
  String get diaryDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @deleteDiary.
  ///
  /// In en, this message translates to:
  /// **'Delete Diary'**
  String get deleteDiary;

  /// No description provided for @deleteDiaryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this diary?'**
  String get deleteDiaryConfirm;

  /// No description provided for @diaryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Diary deleted'**
  String get diaryDeleted;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createYourAccount;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @pinFourDigit.
  ///
  /// In en, this message translates to:
  /// **'PIN (4 digits)'**
  String get pinFourDigit;

  /// No description provided for @pinUsageDescription.
  ///
  /// In en, this message translates to:
  /// **'PIN will be used for your hidden notes and diary.'**
  String get pinUsageDescription;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @writeNote.
  ///
  /// In en, this message translates to:
  /// **'Write Note'**
  String get writeNote;

  /// No description provided for @createNewNote.
  ///
  /// In en, this message translates to:
  /// **'Create a new note'**
  String get createNewNote;

  /// No description provided for @createDiaryEntry.
  ///
  /// In en, this message translates to:
  /// **'Create diary entry'**
  String get createDiaryEntry;

  /// No description provided for @diarySaved.
  ///
  /// In en, this message translates to:
  /// **'Diary saved'**
  String get diarySaved;

  /// No description provided for @diaryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Diary updated'**
  String get diaryUpdated;

  /// No description provided for @searchDiaries.
  ///
  /// In en, this message translates to:
  /// **'Search Diaries'**
  String get searchDiaries;

  /// No description provided for @noDiariesFound.
  ///
  /// In en, this message translates to:
  /// **'No diaries found'**
  String get noDiariesFound;

  /// No description provided for @allDiaries.
  ///
  /// In en, this message translates to:
  /// **'All Diaries'**
  String get allDiaries;

  /// No description provided for @recentDiaries.
  ///
  /// In en, this message translates to:
  /// **'Recent Diaries'**
  String get recentDiaries;

  /// No description provided for @oldestDiaries.
  ///
  /// In en, this message translates to:
  /// **'Oldest Diaries'**
  String get oldestDiaries;

  /// No description provided for @thisMonthDiaries.
  ///
  /// In en, this message translates to:
  /// **'This Month\'s Diaries'**
  String get thisMonthDiaries;

  /// No description provided for @lastMonthDiaries.
  ///
  /// In en, this message translates to:
  /// **'Last Month\'s Diaries'**
  String get lastMonthDiaries;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @groupByMonth.
  ///
  /// In en, this message translates to:
  /// **'Group by Month'**
  String get groupByMonth;

  /// No description provided for @groupByYear.
  ///
  /// In en, this message translates to:
  /// **'Group by Year'**
  String get groupByYear;

  /// No description provided for @enhanceDiaryWithAI.
  ///
  /// In en, this message translates to:
  /// **'Enhance Diary with AI'**
  String get enhanceDiaryWithAI;

  /// No description provided for @continueDiaryWithAI.
  ///
  /// In en, this message translates to:
  /// **'Continue Diary with AI'**
  String get continueDiaryWithAI;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @dailyReminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder enabled'**
  String get dailyReminderEnabled;

  /// No description provided for @dailyReminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder disabled'**
  String get dailyReminderDisabled;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @reminderTimeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder time updated'**
  String get reminderTimeUpdated;

  /// No description provided for @writeYourDiary.
  ///
  /// In en, this message translates to:
  /// **'Write Your Diary'**
  String get writeYourDiary;

  /// No description provided for @dontForgetToWriteToday.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to write today!'**
  String get dontForgetToWriteToday;

  /// No description provided for @newVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'New Voice Note'**
  String get newVoiceNote;

  /// No description provided for @recordVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Record Voice Note'**
  String get recordVoiceNote;

  /// No description provided for @clearAllDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all data? This action cannot be undone.'**
  String get clearAllDataConfirm;

  /// No description provided for @geminiApiKey.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Key'**
  String get geminiApiKey;

  /// No description provided for @apiKeySet.
  ///
  /// In en, this message translates to:
  /// **'API key set successfully'**
  String get apiKeySet;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @wrongPinCode.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN code'**
  String get wrongPinCode;

  /// No description provided for @pinCodeRemoved.
  ///
  /// In en, this message translates to:
  /// **'PIN code removed'**
  String get pinCodeRemoved;

  /// No description provided for @setApiKey.
  ///
  /// In en, this message translates to:
  /// **'Set API Key'**
  String get setApiKey;

  /// No description provided for @changePinCode.
  ///
  /// In en, this message translates to:
  /// **'Change PIN Code'**
  String get changePinCode;

  /// No description provided for @pinCodeChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN code changed'**
  String get pinCodeChanged;

  /// No description provided for @enterPinCode.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN Code'**
  String get enterPinCode;

  /// No description provided for @setPinCode.
  ///
  /// In en, this message translates to:
  /// **'Set PIN Code'**
  String get setPinCode;

  /// No description provided for @pinCodeSet.
  ///
  /// In en, this message translates to:
  /// **'PIN code set successfully'**
  String get pinCodeSet;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @playVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Play Voice Note'**
  String get playVoiceNote;

  /// No description provided for @pauseVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Pause Voice Note'**
  String get pauseVoiceNote;

  /// No description provided for @deleteVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Voice Note'**
  String get deleteVoiceNote;

  /// No description provided for @deleteVoiceNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this voice note?'**
  String get deleteVoiceNoteConfirm;

  /// No description provided for @voiceNoteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Voice note deleted'**
  String get voiceNoteDeleted;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// No description provided for @additionalSettings.
  ///
  /// In en, this message translates to:
  /// **'Additional Settings'**
  String get additionalSettings;

  /// No description provided for @diaries.
  ///
  /// In en, this message translates to:
  /// **'Diaries'**
  String get diaries;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @userNameChanged.
  ///
  /// In en, this message translates to:
  /// **'Username changed successfully'**
  String get userNameChanged;

  /// No description provided for @writeDiary.
  ///
  /// In en, this message translates to:
  /// **'Write Diary'**
  String get writeDiary;

  /// No description provided for @saveLocationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Save location not found'**
  String get saveLocationNotFound;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @noDiariesYet.
  ///
  /// In en, this message translates to:
  /// **'No diaries yet'**
  String get noDiariesYet;

  /// No description provided for @noSearchResultsDescription.
  ///
  /// In en, this message translates to:
  /// **'No search results found'**
  String get noSearchResultsDescription;

  /// No description provided for @noDiariesDescription.
  ///
  /// In en, this message translates to:
  /// **'Start writing your first diary entry'**
  String get noDiariesDescription;

  /// No description provided for @myDiaries.
  ///
  /// In en, this message translates to:
  /// **'My Diaries'**
  String get myDiaries;

  /// No description provided for @searchInDiaries.
  ///
  /// In en, this message translates to:
  /// **'Search in diaries'**
  String get searchInDiaries;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noSearchResults;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete Confirmation'**
  String get deleteConfirmation;

  /// No description provided for @diaryAccess.
  ///
  /// In en, this message translates to:
  /// **'Diary Access'**
  String get diaryAccess;

  /// No description provided for @enterPinToAccessDiaries.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to access diaries'**
  String get enterPinToAccessDiaries;

  /// No description provided for @enterPinToAccessHiddenNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN code to access your hidden notes'**
  String get enterPinToAccessHiddenNotes;

  /// No description provided for @deleteNotes.
  ///
  /// In en, this message translates to:
  /// **'Delete Notes'**
  String get deleteNotes;

  /// No description provided for @searchInNotes.
  ///
  /// In en, this message translates to:
  /// **'Search in notes...'**
  String get searchInNotes;

  /// No description provided for @welcomeToNotevia.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Notevia'**
  String get welcomeToNotevia;

  /// No description provided for @aiSupportedExperience.
  ///
  /// In en, this message translates to:
  /// **'Start your AI-supported voice and written note-taking experience.'**
  String get aiSupportedExperience;

  /// No description provided for @aiSupport.
  ///
  /// In en, this message translates to:
  /// **'AI Support'**
  String get aiSupport;

  /// No description provided for @enhanceWithGemini.
  ///
  /// In en, this message translates to:
  /// **'Enhance, summarize and continue your notes with Gemini AI.'**
  String get enhanceWithGemini;

  /// No description provided for @recordAndCombine.
  ///
  /// In en, this message translates to:
  /// **'Record voice notes, listen and combine with your texts.'**
  String get recordAndCombine;

  /// No description provided for @secureJournal.
  ///
  /// In en, this message translates to:
  /// **'Secure Journal'**
  String get secureJournal;

  /// No description provided for @pinProtectedJournal.
  ///
  /// In en, this message translates to:
  /// **'Keep a PIN-protected journal and keep your memories safe.'**
  String get pinProtectedJournal;

  /// No description provided for @createSecurityPin.
  ///
  /// In en, this message translates to:
  /// **'Create security PIN'**
  String get createSecurityPin;

  /// No description provided for @dataLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading data'**
  String get dataLoadingError;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get microphonePermissionRequired;

  /// No description provided for @recordingStartError.
  ///
  /// In en, this message translates to:
  /// **'Recording start error'**
  String get recordingStartError;

  /// No description provided for @recordingStopError.
  ///
  /// In en, this message translates to:
  /// **'Recording stop error'**
  String get recordingStopError;

  /// No description provided for @saveVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Save Voice Note'**
  String get saveVoiceNote;

  /// No description provided for @voiceNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Voice note saved'**
  String get voiceNoteSaved;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Save error'**
  String get saveError;

  /// No description provided for @playbackError.
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get playbackError;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Delete error'**
  String get deleteError;

  /// No description provided for @voiceNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Notes'**
  String get voiceNotesTitle;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @noteviaAI.
  ///
  /// In en, this message translates to:
  /// **'Notevia AI'**
  String get noteviaAI;

  /// No description provided for @voiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice Note'**
  String get voiceNote;

  /// No description provided for @noteTitleOrContentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Note title or content cannot be empty'**
  String get noteTitleOrContentEmpty;

  /// No description provided for @errorSavingNote.
  ///
  /// In en, this message translates to:
  /// **'Error saving note'**
  String get errorSavingNote;

  /// No description provided for @hiddenNote.
  ///
  /// In en, this message translates to:
  /// **'Hidden Note'**
  String get hiddenNote;

  /// No description provided for @enterPinToAccessHiddenNote.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN code to access hidden note'**
  String get enterPinToAccessHiddenNote;

  /// No description provided for @deleteFilter.
  ///
  /// In en, this message translates to:
  /// **'Delete Filter'**
  String get deleteFilter;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Repeat daily'**
  String get repeatDaily;

  /// No description provided for @enterCustomFilterName.
  ///
  /// In en, this message translates to:
  /// **'Enter custom filter name'**
  String get enterCustomFilterName;

  /// No description provided for @chatWithAI.
  ///
  /// In en, this message translates to:
  /// **'Chat with AI...'**
  String get chatWithAI;

  /// No description provided for @cancelRecording.
  ///
  /// In en, this message translates to:
  /// **'Cancel Recording'**
  String get cancelRecording;

  /// No description provided for @audioPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Audio playback error'**
  String get audioPlaybackError;

  /// No description provided for @diaryTitleOrContentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Diary title or content cannot be empty'**
  String get diaryTitleOrContentEmpty;

  /// No description provided for @contentRequiredForEnhancement.
  ///
  /// In en, this message translates to:
  /// **'Content required for enhancement'**
  String get contentRequiredForEnhancement;

  /// No description provided for @diaryEnhancedWithAI.
  ///
  /// In en, this message translates to:
  /// **'Diary enhanced with AI'**
  String get diaryEnhancedWithAI;

  /// No description provided for @aiEnhancementError.
  ///
  /// In en, this message translates to:
  /// **'AI enhancement error'**
  String get aiEnhancementError;

  /// No description provided for @contentRequiredForContinuation.
  ///
  /// In en, this message translates to:
  /// **'Content required for continuation'**
  String get contentRequiredForContinuation;

  /// No description provided for @diaryContinuedWithAI.
  ///
  /// In en, this message translates to:
  /// **'Diary continued with AI'**
  String get diaryContinuedWithAI;

  /// No description provided for @aiContinuationError.
  ///
  /// In en, this message translates to:
  /// **'AI continuation error'**
  String get aiContinuationError;

  /// No description provided for @selectBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Select Background Color'**
  String get selectBackgroundColor;

  /// No description provided for @continueDiary.
  ///
  /// In en, this message translates to:
  /// **'Continue Diary'**
  String get continueDiary;

  /// No description provided for @noteContentRequiredForEnhancement.
  ///
  /// In en, this message translates to:
  /// **'Note content required for enhancement'**
  String get noteContentRequiredForEnhancement;

  /// No description provided for @noteEnhancedWithAI.
  ///
  /// In en, this message translates to:
  /// **'Note enhanced with AI'**
  String get noteEnhancedWithAI;

  /// No description provided for @noteContentRequiredForSummarization.
  ///
  /// In en, this message translates to:
  /// **'Note content required for summarization'**
  String get noteContentRequiredForSummarization;

  /// No description provided for @noteSummarized.
  ///
  /// In en, this message translates to:
  /// **'Note summarized'**
  String get noteSummarized;

  /// No description provided for @aiSummarizationError.
  ///
  /// In en, this message translates to:
  /// **'AI summarization error'**
  String get aiSummarizationError;

  /// No description provided for @noteContentRequiredForContinuation.
  ///
  /// In en, this message translates to:
  /// **'Note content required for continuation'**
  String get noteContentRequiredForContinuation;

  /// No description provided for @noteContinuedWithAI.
  ///
  /// In en, this message translates to:
  /// **'Note continued with AI'**
  String get noteContinuedWithAI;

  /// No description provided for @summarize.
  ///
  /// In en, this message translates to:
  /// **'Summarize'**
  String get summarize;

  /// No description provided for @continueNote.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueNote;

  /// No description provided for @writeYourNoteHere.
  ///
  /// In en, this message translates to:
  /// **'Write your note here...'**
  String get writeYourNoteHere;

  /// No description provided for @audioFilePlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Audio file could not be played'**
  String get audioFilePlaybackError;

  /// No description provided for @deleteAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Delete Audio File'**
  String get deleteAudioFile;

  /// No description provided for @audioFileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Audio file deleted'**
  String get audioFileDeleted;

  /// No description provided for @audioFileCouldNotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Audio file could not be deleted'**
  String get audioFileCouldNotBeDeleted;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @colorPalette.
  ///
  /// In en, this message translates to:
  /// **'Color Palette'**
  String get colorPalette;

  /// No description provided for @oceanBlue.
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get oceanBlue;

  /// No description provided for @forestGreen.
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get forestGreen;

  /// No description provided for @sunsetOrange.
  ///
  /// In en, this message translates to:
  /// **'Sunset Orange'**
  String get sunsetOrange;

  /// No description provided for @royalPurple.
  ///
  /// In en, this message translates to:
  /// **'Royal Purple'**
  String get royalPurple;

  /// No description provided for @rosePink.
  ///
  /// In en, this message translates to:
  /// **'Rose Pink'**
  String get rosePink;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get timeFormat;

  /// No description provided for @twentyFourHour.
  ///
  /// In en, this message translates to:
  /// **'24 Hour'**
  String get twentyFourHour;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// No description provided for @writeFirstDiary.
  ///
  /// In en, this message translates to:
  /// **'Write Your First Diary'**
  String get writeFirstDiary;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @audioFileDeletionError.
  ///
  /// In en, this message translates to:
  /// **'Audio file deletion error'**
  String get audioFileDeletionError;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to'**
  String get languageChangedTo;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get fileSaved;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error'**
  String get exportError;

  /// No description provided for @importCompleted.
  ///
  /// In en, this message translates to:
  /// **'Import completed'**
  String get importCompleted;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import error'**
  String get importError;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data deleted. App restarting...'**
  String get allDataDeleted;

  /// No description provided for @changeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change Username'**
  String get changeUsername;

  /// No description provided for @usernameChanged.
  ///
  /// In en, this message translates to:
  /// **'Username changed successfully'**
  String get usernameChanged;

  /// No description provided for @themeSelection.
  ///
  /// In en, this message translates to:
  /// **'Theme Selection'**
  String get themeSelection;

  /// No description provided for @lightThemeOption.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightThemeOption;

  /// No description provided for @darkThemeOption.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkThemeOption;

  /// No description provided for @contentRequiredForSummarization.
  ///
  /// In en, this message translates to:
  /// **'Content required for summarization'**
  String get contentRequiredForSummarization;

  /// No description provided for @errorLoadingVoiceNotes.
  ///
  /// In en, this message translates to:
  /// **'Error loading voice notes'**
  String get errorLoadingVoiceNotes;

  /// No description provided for @errorLoadingDiaries.
  ///
  /// In en, this message translates to:
  /// **'Error loading diaries'**
  String get errorLoadingDiaries;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @personalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalization;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userName;

  /// No description provided for @changePinCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your PIN code'**
  String get changePinCodeSubtitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @noteTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Note title...'**
  String get noteTitlePlaceholder;

  /// No description provided for @noteContentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write your note here...'**
  String get noteContentPlaceholder;

  /// No description provided for @aiPoweredNoteTaking.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Note Taking'**
  String get aiPoweredNoteTaking;

  /// No description provided for @voiceNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Note'**
  String get voiceNoteTitle;

  /// No description provided for @deleteVoiceNoteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this voice note?'**
  String get deleteVoiceNoteConfirmation;

  /// No description provided for @noVoiceNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No voice notes yet'**
  String get noVoiceNotesYet;

  /// No description provided for @recordFirstVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Press the microphone button to record your first voice note'**
  String get recordFirstVoiceNote;

  /// No description provided for @recordingStartErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error starting recording'**
  String get recordingStartErrorMessage;

  /// No description provided for @recordingStopErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error stopping recording'**
  String get recordingStopErrorMessage;

  /// No description provided for @untitledVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Untitled Voice Note'**
  String get untitledVoiceNote;

  /// No description provided for @aiContinuationErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'AI continuation error'**
  String get aiContinuationErrorMessage;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @voiceNoteLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Voice note loading error'**
  String get voiceNoteLoadingError;

  /// No description provided for @noteEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get noteEditorTitle;

  /// No description provided for @aiDevelopmentError.
  ///
  /// In en, this message translates to:
  /// **'AI development error'**
  String get aiDevelopmentError;

  /// No description provided for @untitledNote.
  ///
  /// In en, this message translates to:
  /// **'Untitled Note'**
  String get untitledNote;

  /// No description provided for @enhanceNote.
  ///
  /// In en, this message translates to:
  /// **'Enhance Note'**
  String get enhanceNote;

  /// No description provided for @newNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNoteTitle;

  /// No description provided for @filterDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'filter will be deleted. Are you sure?'**
  String get filterDeleteConfirmation;

  /// No description provided for @deleteDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Diary'**
  String get deleteDiaryTitle;

  /// No description provided for @deleteDiaryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'diary will be deleted. Are you sure?'**
  String get deleteDiaryConfirmation;

  /// No description provided for @reminderSetError.
  ///
  /// In en, this message translates to:
  /// **'Reminder set error'**
  String get reminderSetError;

  /// No description provided for @dailyReminderSet.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder set'**
  String get dailyReminderSet;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get reminderSet;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get goodNight;

  /// No description provided for @markNoteAsImportant.
  ///
  /// In en, this message translates to:
  /// **'Mark Note as Important'**
  String get markNoteAsImportant;

  /// No description provided for @markNoteAsHidden.
  ///
  /// In en, this message translates to:
  /// **'Mark Note as Hidden'**
  String get markNoteAsHidden;

  /// No description provided for @noteRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Note Reminders'**
  String get noteRemindersDescription;

  /// No description provided for @dailyNoteReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Note Reminder'**
  String get dailyNoteReminder;

  /// No description provided for @noteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Note Reminder'**
  String get noteReminderTitle;

  /// No description provided for @myVoiceNotes.
  ///
  /// In en, this message translates to:
  /// **'My Voice Notes'**
  String get myVoiceNotes;

  /// No description provided for @noteReminders.
  ///
  /// In en, this message translates to:
  /// **'Note Reminders'**
  String get noteReminders;

  /// No description provided for @audioFileDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Audio file deletion failed'**
  String get audioFileDeletionFailed;

  /// No description provided for @repeatReminder.
  ///
  /// In en, this message translates to:
  /// **'Repeat Reminder'**
  String get repeatReminder;

  /// No description provided for @noVoiceRecordingYet.
  ///
  /// In en, this message translates to:
  /// **'No voice recording yet'**
  String get noVoiceRecordingYet;

  /// No description provided for @deleteAudioFileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this audio file?'**
  String get deleteAudioFileConfirmation;

  /// No description provided for @extraSettings.
  ///
  /// In en, this message translates to:
  /// **'Extra Settings'**
  String get extraSettings;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get goodEvening;

  /// No description provided for @audioRecordings.
  ///
  /// In en, this message translates to:
  /// **'Audio Recordings'**
  String get audioRecordings;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get edited;

  /// No description provided for @diaryContentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'How was your day? Write your thoughts here...'**
  String get diaryContentPlaceholder;

  /// No description provided for @homePage.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePage;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @myDiary.
  ///
  /// In en, this message translates to:
  /// **'My Diary'**
  String get myDiary;

  /// No description provided for @clock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get clock;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @editDiary.
  ///
  /// In en, this message translates to:
  /// **'Edit Diary'**
  String get editDiary;

  /// No description provided for @diaryTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Diary title...'**
  String get diaryTitlePlaceholder;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @recordingDuration.
  ///
  /// In en, this message translates to:
  /// **'Recording Duration'**
  String get recordingDuration;

  /// No description provided for @untitledDiary.
  ///
  /// In en, this message translates to:
  /// **'Untitled Diary'**
  String get untitledDiary;

  /// No description provided for @enterPinToViewHiddenNote.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN code to view this hidden note'**
  String get enterPinToViewHiddenNote;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to leave?'**
  String get unsavedChangesMessage;

  /// No description provided for @amPm.
  ///
  /// In en, this message translates to:
  /// **'AM/PM'**
  String get amPm;

  /// No description provided for @defaultPalette.
  ///
  /// In en, this message translates to:
  /// **'Default Palette'**
  String get defaultPalette;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @customFilter.
  ///
  /// In en, this message translates to:
  /// **'Custom Filter'**
  String get customFilter;

  /// No description provided for @cancelRecordingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel recording?'**
  String get cancelRecordingConfirmation;

  /// No description provided for @pinNotSet.
  ///
  /// In en, this message translates to:
  /// **'PIN not set'**
  String get pinNotSet;

  /// No description provided for @addedFilters.
  ///
  /// In en, this message translates to:
  /// **'Added Filters'**
  String get addedFilters;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @audioPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Audio playback failed'**
  String get audioPlaybackFailed;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @readingMode.
  ///
  /// In en, this message translates to:
  /// **'Reading Mode'**
  String get readingMode;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content...'**
  String get noContent;

  /// No description provided for @secure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// No description provided for @diaryDetail.
  ///
  /// In en, this message translates to:
  /// **'Diary Detail'**
  String get diaryDetail;

  /// No description provided for @writtenDate.
  ///
  /// In en, this message translates to:
  /// **'Written Date'**
  String get writtenDate;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @doubleTapToReturn.
  ///
  /// In en, this message translates to:
  /// **'Double tap to return to home'**
  String get doubleTapToReturn;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @selectYourColorPalette.
  ///
  /// In en, this message translates to:
  /// **'Select Your Color Palette'**
  String get selectYourColorPalette;

  /// No description provided for @renameAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Rename Audio File'**
  String get renameAudioFile;

  /// No description provided for @enterNewName.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get enterNewName;

  /// No description provided for @pdfDownloaded.
  ///
  /// In en, this message translates to:
  /// **'PDF downloaded'**
  String get pdfDownloaded;

  /// No description provided for @txtDownloaded.
  ///
  /// In en, this message translates to:
  /// **'TXT downloaded'**
  String get txtDownloaded;

  /// No description provided for @pdfDownloadError.
  ///
  /// In en, this message translates to:
  /// **'PDF download error'**
  String get pdfDownloadError;

  /// No description provided for @txtDownloadError.
  ///
  /// In en, this message translates to:
  /// **'TXT download error'**
  String get txtDownloadError;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required'**
  String get storagePermissionRequired;

  /// No description provided for @downloadAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Download as PDF'**
  String get downloadAsPdf;

  /// No description provided for @downloadAsTxt.
  ///
  /// In en, this message translates to:
  /// **'Download as TXT'**
  String get downloadAsTxt;

  /// No description provided for @shareFormat.
  ///
  /// In en, this message translates to:
  /// **'Select Share Format'**
  String get shareFormat;

  /// No description provided for @downloadToDevice.
  ///
  /// In en, this message translates to:
  /// **'Or Download to Device'**
  String get downloadToDevice;

  /// No description provided for @shareWith.
  ///
  /// In en, this message translates to:
  /// **'Share with'**
  String get shareWith;

  /// No description provided for @pdfSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PDF shared successfully'**
  String get pdfSharedSuccessfully;

  /// No description provided for @txtSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'TXT shared successfully'**
  String get txtSharedSuccessfully;

  /// No description provided for @pdfShareFailed.
  ///
  /// In en, this message translates to:
  /// **'PDF sharing failed'**
  String get pdfShareFailed;

  /// No description provided for @txtShareFailed.
  ///
  /// In en, this message translates to:
  /// **'TXT sharing failed'**
  String get txtShareFailed;

  /// No description provided for @pdfDownloadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PDF saved to Downloads folder'**
  String get pdfDownloadedSuccessfully;

  /// No description provided for @txtDownloadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'TXT saved to Downloads folder'**
  String get txtDownloadedSuccessfully;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @developerInfo.
  ///
  /// In en, this message translates to:
  /// **'Developer Info'**
  String get developerInfo;

  /// No description provided for @voiceRecordingContains.
  ///
  /// In en, this message translates to:
  /// **'voice recording contains'**
  String get voiceRecordingContains;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A simple and elegant diary app'**
  String get appDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
