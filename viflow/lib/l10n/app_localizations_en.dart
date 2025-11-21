// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Viflow';

  @override
  String get onboardTitle1 => 'Water is Life';

  @override
  String get onboardDesc1 => 'It is now very easy to track the water your body needs.';

  @override
  String get onboardTitle2 => 'Set Your Goal';

  @override
  String get onboardDesc2 => 'Protect your health with goals calculated specifically for you.';

  @override
  String get onboardTitle3 => 'Take Action';

  @override
  String get onboardDesc3 => 'Make drinking water a habit with daily reminders.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get start => 'Start';

  @override
  String get nameQuestion => 'What is your name?';

  @override
  String get nameHint => 'Name';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get bodyMeasurements => 'Body Measurements';

  @override
  String get weight => 'Weight (kg)';

  @override
  String get height => 'Height (cm)';

  @override
  String get activityLevel => 'Activity Level';

  @override
  String get sedentary => 'Sedentary';

  @override
  String get moderate => 'Moderate';

  @override
  String get active => 'Active';

  @override
  String get calculateAndStart => 'Calculate & Start';

  @override
  String get enterNameError => 'Please enter your name.';

  @override
  String get enterAgeError => 'Please enter your age.';

  @override
  String get selectGenderError => 'Please select a gender.';

  @override
  String get enterWeightError => 'Please enter your weight.';

  @override
  String get enterHeightError => 'Please enter your height.';

  @override
  String get defaultUser => 'User';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get todaysRecords => 'Today\'s Records';

  @override
  String get noRecordsYet => 'No records yet';

  @override
  String get noWaterDrunk => 'You haven\'t drunk water yet';

  @override
  String get custom => 'Custom';

  @override
  String get enterAmount => 'Enter Amount';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get waterDrunk => 'Water Drunk';

  @override
  String get actionUndone => 'Undone';

  @override
  String addedMsg(int amount) {
    return '$amount ml added!';
  }

  @override
  String get undo => 'UNDO';

  @override
  String get errorInvalidAmount => 'Please enter a valid amount.';

  @override
  String get motivation1 => 'Water is life, don\'t forget to drink!';

  @override
  String get motivation2 => 'Great job! Keep hitting those goals.';

  @override
  String get motivation3 => 'Hydration is key to focus.';

  @override
  String get motivation4 => 'Small sips lead to big health benefits.';

  @override
  String get motivation5 => 'Your body thanks you for every drop.';

  @override
  String get statistics => 'Statistics';

  @override
  String get reminder => 'Reminder';

  @override
  String get settings => 'Settings';

  @override
  String get habitCalendar => 'Habit Calendar';

  @override
  String get overview => 'Overview';

  @override
  String get totalIntake => 'Total Intake';

  @override
  String get activeDays => 'Active Days';

  @override
  String get timeDistribution => 'Time Distribution (Last 7 Days)';

  @override
  String get weeklyDetail => 'Weekly Detail';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get night => 'Night';

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get day => 'Day';

  @override
  String get days => 'Days';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get reminderSubtitle => 'Remind me to drink water throughout the day';

  @override
  String get frequency => 'Frequency';

  @override
  String get minutes => 'minutes';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get reminderInfo => 'Notifications will be scheduled between selected hours.';

  @override
  String get permissionRequired => 'Notification Permission Required';

  @override
  String get permissionDesc => 'To remind you to drink water, we need permission to send notifications. Please enable it in settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get notificationsSet => 'Notifications scheduled!';

  @override
  String get notificationsDisabled => 'Notifications disabled.';

  @override
  String get end => 'End';

  @override
  String get interval => 'Interval';

  @override
  String get minuteAbbr => 'min';

  @override
  String get reminderActive => 'Reminder Active';

  @override
  String get reminderPassive => 'Reminder Inactive';

  @override
  String get googleSignIn => 'Save & Start with Google';

  @override
  String get continueAnonymously => 'Continue without saving data';

  @override
  String get fillAllFieldsError => 'Please fill in all steps first.';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get linkWithGoogle => 'Link with Google';

  @override
  String get secureYourData => 'Secure your data';

  @override
  String get accountLinked => 'Account linked successfully!';

  @override
  String get linkFailed => 'Could not link account';

  @override
  String get profile => 'Profile';

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get resetData => 'Reset All Data';

  @override
  String get resetDesc => 'To start over';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get resetWarning => 'All your drinking history and settings will be deleted. This action cannot be undone.';

  @override
  String get yesReset => 'Yes, Reset';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get targetUpdated => 'Daily goal updated based on new data.';

  @override
  String get selectGender => 'Select Gender';

  @override
  String get appSettings => 'App Settings';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get version => 'Version';
}
