import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NSecure'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @bahasaIndonesia.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get bahasaIndonesia;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// No description provided for @officer.
  ///
  /// In en, this message translates to:
  /// **'Officer'**
  String get officer;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @visitorStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get visitorStatusPending;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issue;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @securityTeam.
  ///
  /// In en, this message translates to:
  /// **'Security Team'**
  String get securityTeam;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get comingSoon;

  /// No description provided for @concept.
  ///
  /// In en, this message translates to:
  /// **'CONCEPT'**
  String get concept;

  /// No description provided for @signInDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Security account to access Security operations.'**
  String get signInDescription;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required.'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @authRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not restore the Security session.'**
  String get authRestoreFailed;

  /// No description provided for @authApiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the Security API.'**
  String get authApiUnavailable;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Security username or password is invalid.'**
  String get authInvalidCredentials;

  /// No description provided for @authUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Security session is invalid. Please sign in again.'**
  String get authUnauthenticated;

  /// No description provided for @authForbidden.
  ///
  /// In en, this message translates to:
  /// **'This account does not have Security access.'**
  String get authForbidden;

  /// No description provided for @authValidation.
  ///
  /// In en, this message translates to:
  /// **'Review the sign-in data and try again.'**
  String get authValidation;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the Security API. Check the network and try again.'**
  String get authNetwork;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorning;

  /// No description provided for @todaysOverview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Overview'**
  String get todaysOverview;

  /// No description provided for @securityModules.
  ///
  /// In en, this message translates to:
  /// **'Security Modules'**
  String get securityModules;

  /// No description provided for @activeTasks.
  ///
  /// In en, this message translates to:
  /// **'Active Tasks'**
  String get activeTasks;

  /// No description provided for @activeTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Priority work for the current security shift.'**
  String get activeTasksSubtitle;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get taskStatusInProgress;

  /// No description provided for @taskStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'WAITING'**
  String get taskStatusWaiting;

  /// No description provided for @taskStatusAttention.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY'**
  String get taskStatusAttention;

  /// No description provided for @taskPatrolTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue Patrol'**
  String get taskPatrolTitle;

  /// No description provided for @taskPatrolSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Main Lobby route • Continue to the next checkpoint'**
  String get taskPatrolSubtitle;

  /// No description provided for @taskVisitorTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Visitor'**
  String get taskVisitorTitle;

  /// No description provided for @taskVisitorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A visitor is waiting for verification at the main lobby'**
  String get taskVisitorSubtitle;

  /// No description provided for @taskIncidentTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Incident'**
  String get taskIncidentTitle;

  /// No description provided for @taskIncidentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Security incident requires attention in the basement area'**
  String get taskIncidentSubtitle;

  /// No description provided for @taskDispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect Parking Area'**
  String get taskDispatchTitle;

  /// No description provided for @taskDispatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Basement B1 • Follow up on suspicious activity'**
  String get taskDispatchSubtitle;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @todaysVisitors.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Visitors'**
  String get todaysVisitors;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked-In'**
  String get checkedIn;

  /// No description provided for @checkedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked-Out'**
  String get checkedOut;

  /// No description provided for @pendingArrivals.
  ///
  /// In en, this message translates to:
  /// **'Pending Arrivals'**
  String get pendingArrivals;

  /// No description provided for @securityPlatform.
  ///
  /// In en, this message translates to:
  /// **'Security Platform'**
  String get securityPlatform;

  /// No description provided for @platformModules.
  ///
  /// In en, this message translates to:
  /// **'Platform Modules'**
  String get platformModules;

  /// No description provided for @platformCatalogDescription.
  ///
  /// In en, this message translates to:
  /// **'Only contracted, operational Security modules are shown here.'**
  String get platformCatalogDescription;

  /// No description provided for @platformOperationalNotice.
  ///
  /// In en, this message translates to:
  /// **'Operational now: Visitor Verification + assigned Patrol execution + Incident Reporting + Emergency SOS. Access and Vehicle remain presentation-only until contracted.'**
  String get platformOperationalNotice;

  /// No description provided for @visitorVerification.
  ///
  /// In en, this message translates to:
  /// **'Visitor Verification'**
  String get visitorVerification;

  /// No description provided for @visitorVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'QR scan and manual visitor verification'**
  String get visitorVerificationSubtitle;

  /// No description provided for @patrolManagement.
  ///
  /// In en, this message translates to:
  /// **'Patrol Management'**
  String get patrolManagement;

  /// No description provided for @patrolManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned patrol routes and checkpoint execution'**
  String get patrolManagementSubtitle;

  /// No description provided for @incidentReporting.
  ///
  /// In en, this message translates to:
  /// **'Incident Reporting'**
  String get incidentReporting;

  /// No description provided for @incidentReportingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Operational incident reporting and handling'**
  String get incidentReportingSubtitle;

  /// No description provided for @emergencyResponse.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencyResponse;

  /// No description provided for @emergencyResponseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Durable Resident SOS alerts and Security response'**
  String get emergencyResponseSubtitle;

  /// No description provided for @accessControl.
  ///
  /// In en, this message translates to:
  /// **'Access Control'**
  String get accessControl;

  /// No description provided for @accessControlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resident, visitor, and vendor access concepts'**
  String get accessControlSubtitle;

  /// No description provided for @vehicleManagement.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Management'**
  String get vehicleManagement;

  /// No description provided for @vehicleManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle registration and access concepts'**
  String get vehicleManagementSubtitle;

  /// No description provided for @visitorDetail.
  ///
  /// In en, this message translates to:
  /// **'Visitor Detail'**
  String get visitorDetail;

  /// No description provided for @visitCode.
  ///
  /// In en, this message translates to:
  /// **'Visit Code'**
  String get visitCode;

  /// No description provided for @visitorId.
  ///
  /// In en, this message translates to:
  /// **'Visitor ID'**
  String get visitorId;

  /// No description provided for @visitor.
  ///
  /// In en, this message translates to:
  /// **'Visitor'**
  String get visitor;

  /// No description provided for @residentName.
  ///
  /// In en, this message translates to:
  /// **'Resident Name'**
  String get residentName;

  /// No description provided for @residentUnit.
  ///
  /// In en, this message translates to:
  /// **'Resident / Unit'**
  String get residentUnit;

  /// No description provided for @tower.
  ///
  /// In en, this message translates to:
  /// **'Tower'**
  String get tower;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @visitPurpose.
  ///
  /// In en, this message translates to:
  /// **'Visit Purpose'**
  String get visitPurpose;

  /// No description provided for @scheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Date'**
  String get scheduledDate;

  /// No description provided for @validTimeWindow.
  ///
  /// In en, this message translates to:
  /// **'Valid Time Window'**
  String get validTimeWindow;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @checkInTime.
  ///
  /// In en, this message translates to:
  /// **'Check-In Time'**
  String get checkInTime;

  /// No description provided for @checkedInBy.
  ///
  /// In en, this message translates to:
  /// **'Checked In By'**
  String get checkedInBy;

  /// No description provided for @checkOutTime.
  ///
  /// In en, this message translates to:
  /// **'Check-Out Time'**
  String get checkOutTime;

  /// No description provided for @checkedOutBy.
  ///
  /// In en, this message translates to:
  /// **'Checked Out By'**
  String get checkedOutBy;

  /// No description provided for @checkingIn.
  ///
  /// In en, this message translates to:
  /// **'Checking In...'**
  String get checkingIn;

  /// No description provided for @checkInVisitor.
  ///
  /// In en, this message translates to:
  /// **'Check-In Visitor'**
  String get checkInVisitor;

  /// No description provided for @checkingOut.
  ///
  /// In en, this message translates to:
  /// **'Checking Out...'**
  String get checkingOut;

  /// No description provided for @checkOutVisitor.
  ///
  /// In en, this message translates to:
  /// **'Check-Out Visitor'**
  String get checkOutVisitor;

  /// No description provided for @visitPendingActionHint.
  ///
  /// In en, this message translates to:
  /// **'This visit is still Pending. Check-In becomes available after approval.'**
  String get visitPendingActionHint;

  /// No description provided for @visitCheckedOutHint.
  ///
  /// In en, this message translates to:
  /// **'This visit has been checked out and is now read-only.'**
  String get visitCheckedOutHint;

  /// No description provided for @visitExpiredHint.
  ///
  /// In en, this message translates to:
  /// **'This visit has expired. Check-In is not available.'**
  String get visitExpiredHint;

  /// No description provided for @visitRejectedHint.
  ///
  /// In en, this message translates to:
  /// **'This visit was rejected. Check-In is not available.'**
  String get visitRejectedHint;

  /// No description provided for @visitCancelledHint.
  ///
  /// In en, this message translates to:
  /// **'This visit was cancelled. Check-In is not available.'**
  String get visitCancelledHint;

  /// No description provided for @visitApprovedHint.
  ///
  /// In en, this message translates to:
  /// **'This visit is eligible for Check-In.'**
  String get visitApprovedHint;

  /// No description provided for @visitApprovedCheckInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Check-In is not currently available for this approved visit.'**
  String get visitApprovedCheckInUnavailable;

  /// No description provided for @visitCheckedInHint.
  ///
  /// In en, this message translates to:
  /// **'This visitor is currently checked in.'**
  String get visitCheckedInHint;

  /// No description provided for @checkInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Check-In Successful!'**
  String get checkInSuccessful;

  /// No description provided for @checkOutSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Check-Out Successful!'**
  String get checkOutSuccessful;

  /// No description provided for @visitorCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Visitor has been checked in.'**
  String get visitorCheckedIn;

  /// No description provided for @visitorCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Visitor has been checked out.'**
  String get visitorCheckedOut;

  /// No description provided for @continueVerifying.
  ///
  /// In en, this message translates to:
  /// **'Continue Verifying'**
  String get continueVerifying;

  /// No description provided for @manualVerify.
  ///
  /// In en, this message translates to:
  /// **'Manual Verify'**
  String get manualVerify;

  /// No description provided for @searchByVisitCodeOrId.
  ///
  /// In en, this message translates to:
  /// **'Search by Visit Code or Visit ID'**
  String get searchByVisitCodeOrId;

  /// No description provided for @visitCodeExample.
  ///
  /// In en, this message translates to:
  /// **'Visit Code: use the code shown on the visitor record'**
  String get visitCodeExample;

  /// No description provided for @visitIdExample.
  ///
  /// In en, this message translates to:
  /// **'Visit ID: use the numeric ID shown on the visitor record'**
  String get visitIdExample;

  /// No description provided for @searchVisitor.
  ///
  /// In en, this message translates to:
  /// **'Search Visitor'**
  String get searchVisitor;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @enterVisitCodeOrId.
  ///
  /// In en, this message translates to:
  /// **'Enter a Visit Code or Visit ID.'**
  String get enterVisitCodeOrId;

  /// No description provided for @backToQrVerification.
  ///
  /// In en, this message translates to:
  /// **'Back to QR Verification'**
  String get backToQrVerification;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @flashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get flashlight;

  /// No description provided for @qrPositionApi.
  ///
  /// In en, this message translates to:
  /// **'Position visitor QR code\nwithin the frame to scan'**
  String get qrPositionApi;

  /// No description provided for @qrPositionDemo.
  ///
  /// In en, this message translates to:
  /// **'Position QR code\nwithin the frame to scan'**
  String get qrPositionDemo;

  /// No description provided for @qrApiExactPayload.
  ///
  /// In en, this message translates to:
  /// **'The scanned payload is sent to the Security API exactly as encoded.'**
  String get qrApiExactPayload;

  /// No description provided for @qrDemoExplanation.
  ///
  /// In en, this message translates to:
  /// **'Demo mode uses a deterministic sample QR and does not open the device camera.'**
  String get qrDemoExplanation;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @enterCodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Code Manually'**
  String get enterCodeManually;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable. Use Manual Verify to continue.'**
  String get cameraUnavailable;

  /// No description provided for @qrScanFailed.
  ///
  /// In en, this message translates to:
  /// **'QR scanner could not complete this scan. Use Manual Verify if needed.'**
  String get qrScanFailed;

  /// No description provided for @flashlightUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Flashlight is unavailable on this device.'**
  String get flashlightUnavailable;

  /// No description provided for @flashlightDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Flashlight is available only in device scanner mode.'**
  String get flashlightDeviceOnly;

  /// No description provided for @backToSecurityHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Security Home'**
  String get backToSecurityHome;

  /// No description provided for @scanDemoQr.
  ///
  /// In en, this message translates to:
  /// **'Scan demo QR'**
  String get scanDemoQr;

  /// No description provided for @tapToScanSampleQr.
  ///
  /// In en, this message translates to:
  /// **'Tap to scan sample QR'**
  String get tapToScanSampleQr;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @advancedFiltersDeferred.
  ///
  /// In en, this message translates to:
  /// **'Advanced result filters are outside the current checkpoint.'**
  String get advancedFiltersDeferred;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @visitorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Visitor Not Found'**
  String get visitorNotFound;

  /// No description provided for @noVisitorMatchPrefix.
  ///
  /// In en, this message translates to:
  /// **'No visitor visit matched'**
  String get noVisitorMatchPrefix;

  /// No description provided for @noVisitorMatchSuffix.
  ///
  /// In en, this message translates to:
  /// **'Check the Visit Code or Visit ID and try again.'**
  String get noVisitorMatchSuffix;

  /// No description provided for @backToVerification.
  ///
  /// In en, this message translates to:
  /// **'Back to Verification'**
  String get backToVerification;

  /// No description provided for @qrVerification.
  ///
  /// In en, this message translates to:
  /// **'QR Verification'**
  String get qrVerification;

  /// No description provided for @verificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Verification History'**
  String get verificationHistory;

  /// No description provided for @historyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'History Unavailable'**
  String get historyUnavailable;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No Records'**
  String get noRecords;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification activity matching this filter will appear here.'**
  String get historyEmptyMessage;

  /// No description provided for @checkedInStatus.
  ///
  /// In en, this message translates to:
  /// **'Checked In'**
  String get checkedInStatus;

  /// No description provided for @checkedOutStatus.
  ///
  /// In en, this message translates to:
  /// **'Checked Out'**
  String get checkedOutStatus;

  /// No description provided for @approvedStatus.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedStatus;

  /// No description provided for @expiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @unitInformationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unit information unavailable'**
  String get unitInformationUnavailable;

  /// No description provided for @verificationHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification history could not be loaded.'**
  String get verificationHistoryLoadFailed;

  /// No description provided for @visitorVisitNotFound.
  ///
  /// In en, this message translates to:
  /// **'Visitor visit was not found.'**
  String get visitorVisitNotFound;

  /// No description provided for @visitExpiredCannotAction.
  ///
  /// In en, this message translates to:
  /// **'This visit has expired and cannot be processed.'**
  String get visitExpiredCannotAction;

  /// No description provided for @visitNotValidTodayCannotAction.
  ///
  /// In en, this message translates to:
  /// **'This visit is not valid today and cannot be processed.'**
  String get visitNotValidTodayCannotAction;

  /// No description provided for @visitStillPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'This visit is still pending approval.'**
  String get visitStillPendingApproval;

  /// No description provided for @visitRejectedCannotAction.
  ///
  /// In en, this message translates to:
  /// **'This visit was rejected and cannot be processed.'**
  String get visitRejectedCannotAction;

  /// No description provided for @visitCancelledCannotAction.
  ///
  /// In en, this message translates to:
  /// **'This visit was cancelled and cannot be processed.'**
  String get visitCancelledCannotAction;

  /// No description provided for @visitorAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'This visitor has already been checked in.'**
  String get visitorAlreadyCheckedIn;

  /// No description provided for @visitorAlreadyCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'This visitor has already been checked out.'**
  String get visitorAlreadyCheckedOut;

  /// No description provided for @securitySessionUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your Security session is no longer authorized.'**
  String get securitySessionUnauthorized;

  /// No description provided for @actionForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get actionForbidden;

  /// No description provided for @networkRetry.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed. Check connectivity and try again.'**
  String get networkRetry;

  /// No description provided for @securityApiRejectedRequest.
  ///
  /// In en, this message translates to:
  /// **'The Security API rejected the request.'**
  String get securityApiRejectedRequest;

  /// No description provided for @qrCredentialInvalid.
  ///
  /// In en, this message translates to:
  /// **'The QR credential is invalid for this visitor.'**
  String get qrCredentialInvalid;

  /// No description provided for @visitorInvalidState.
  ///
  /// In en, this message translates to:
  /// **'This visitor cannot be processed from the current status.'**
  String get visitorInvalidState;

  /// No description provided for @visitorActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This visitor cannot be processed right now.'**
  String get visitorActionUnavailable;

  /// No description provided for @qrInvalid.
  ///
  /// In en, this message translates to:
  /// **'The QR code is invalid or no longer recognized.'**
  String get qrInvalid;

  /// No description provided for @qrExpiredVisit.
  ///
  /// In en, this message translates to:
  /// **'This visitor QR belongs to an expired visit.'**
  String get qrExpiredVisit;

  /// No description provided for @visitorNotScheduledToday.
  ///
  /// In en, this message translates to:
  /// **'This visitor is not scheduled for today.'**
  String get visitorNotScheduledToday;

  /// No description provided for @visitorRejectedVerification.
  ///
  /// In en, this message translates to:
  /// **'This visitor visit has been rejected.'**
  String get visitorRejectedVerification;

  /// No description provided for @visitorCancelledVerification.
  ///
  /// In en, this message translates to:
  /// **'This visitor visit has been cancelled.'**
  String get visitorCancelledVerification;

  /// No description provided for @verificationForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to verify this visitor.'**
  String get verificationForbidden;

  /// No description provided for @securityApiRejectedVerification.
  ///
  /// In en, this message translates to:
  /// **'The Security API rejected the verification request.'**
  String get securityApiRejectedVerification;

  /// No description provided for @visitorCannotVerifyState.
  ///
  /// In en, this message translates to:
  /// **'This visitor cannot be verified from the current status.'**
  String get visitorCannotVerifyState;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Visitor verification could not be completed.'**
  String get verificationFailed;

  /// No description provided for @historyForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view verification history.'**
  String get historyForbidden;

  /// No description provided for @historyNetworkRetry.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed. Check connectivity and retry.'**
  String get historyNetworkRetry;

  /// No description provided for @historyLoadRetry.
  ///
  /// In en, this message translates to:
  /// **'Verification history could not be loaded. Please retry.'**
  String get historyLoadRetry;

  /// No description provided for @patrolHistory.
  ///
  /// In en, this message translates to:
  /// **'Patrol History'**
  String get patrolHistory;

  /// No description provided for @loadingAssignedPatrols.
  ///
  /// In en, this message translates to:
  /// **'Loading assigned patrols...'**
  String get loadingAssignedPatrols;

  /// No description provided for @patrolDashboard.
  ///
  /// In en, this message translates to:
  /// **'Patrol Dashboard'**
  String get patrolDashboard;

  /// No description provided for @patrolDashboardDescription.
  ///
  /// In en, this message translates to:
  /// **'Assigned routes and checkpoint execution for your Security session.'**
  String get patrolDashboardDescription;

  /// No description provided for @activePatrol.
  ///
  /// In en, this message translates to:
  /// **'Active Patrol'**
  String get activePatrol;

  /// No description provided for @nextPatrol.
  ///
  /// In en, this message translates to:
  /// **'Next Patrol'**
  String get nextPatrol;

  /// No description provided for @assignedPatrols.
  ///
  /// In en, this message translates to:
  /// **'Assigned Patrols'**
  String get assignedPatrols;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'sessions'**
  String get sessions;

  /// No description provided for @noAssignedPatrols.
  ///
  /// In en, this message translates to:
  /// **'No Assigned Patrols'**
  String get noAssignedPatrols;

  /// No description provided for @noAssignedPatrolsMessage.
  ///
  /// In en, this message translates to:
  /// **'No patrol session is currently assigned to this officer.'**
  String get noAssignedPatrolsMessage;

  /// No description provided for @patrolRoute.
  ///
  /// In en, this message translates to:
  /// **'Patrol Route'**
  String get patrolRoute;

  /// No description provided for @loadingPatrolRoute.
  ///
  /// In en, this message translates to:
  /// **'Loading patrol route...'**
  String get loadingPatrolRoute;

  /// No description provided for @patrolUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Patrol Unavailable'**
  String get patrolUnavailable;

  /// No description provided for @patrolCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'The patrol could not be loaded.'**
  String get patrolCouldNotLoad;

  /// No description provided for @routeCheckpoints.
  ///
  /// In en, this message translates to:
  /// **'Route Checkpoints'**
  String get routeCheckpoints;

  /// No description provided for @noCheckpoints.
  ///
  /// In en, this message translates to:
  /// **'No Checkpoints'**
  String get noCheckpoints;

  /// No description provided for @noCheckpointsMessage.
  ///
  /// In en, this message translates to:
  /// **'This patrol has no checkpoint details available.'**
  String get noCheckpointsMessage;

  /// No description provided for @patrolHardwareNotice.
  ///
  /// In en, this message translates to:
  /// **'Photo evidence is the current checkpoint proof. QR, NFC, RFID, GPS, beacon, device-registry and scan-token proof are not part of the current Patrol contract.'**
  String get patrolHardwareNotice;

  /// No description provided for @loadingPatrolHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading patrol history...'**
  String get loadingPatrolHistory;

  /// No description provided for @completedPatrolActivity.
  ///
  /// In en, this message translates to:
  /// **'Completed Patrol Activity'**
  String get completedPatrolActivity;

  /// No description provided for @completedPatrolActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Terminal patrol sessions assigned to this Security officer.'**
  String get completedPatrolActivityDescription;

  /// No description provided for @noPatrolHistory.
  ///
  /// In en, this message translates to:
  /// **'No Patrol History'**
  String get noPatrolHistory;

  /// No description provided for @noPatrolHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'No patrol sessions match this history filter.'**
  String get noPatrolHistoryMessage;

  /// No description provided for @startingPatrol.
  ///
  /// In en, this message translates to:
  /// **'Starting Patrol...'**
  String get startingPatrol;

  /// No description provided for @startPatrol.
  ///
  /// In en, this message translates to:
  /// **'Start Patrol'**
  String get startPatrol;

  /// No description provided for @updatingPatrol.
  ///
  /// In en, this message translates to:
  /// **'Updating Patrol...'**
  String get updatingPatrol;

  /// No description provided for @completePatrol.
  ///
  /// In en, this message translates to:
  /// **'Complete Patrol'**
  String get completePatrol;

  /// No description provided for @completePendingCheckpointsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completePendingCheckpointsPrefix;

  /// No description provided for @completePendingCheckpointsSuffix.
  ///
  /// In en, this message translates to:
  /// **'Pending Checkpoints'**
  String get completePendingCheckpointsSuffix;

  /// No description provided for @patrolDataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Patrol data could not be loaded.'**
  String get patrolDataLoadFailed;

  /// No description provided for @patrolNotFound.
  ///
  /// In en, this message translates to:
  /// **'Patrol was not found.'**
  String get patrolNotFound;

  /// No description provided for @patrolStarted.
  ///
  /// In en, this message translates to:
  /// **'Patrol started.'**
  String get patrolStarted;

  /// No description provided for @checkpointCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed.'**
  String get checkpointCompleted;

  /// No description provided for @skipCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Skip Checkpoint'**
  String get skipCheckpoint;

  /// No description provided for @checkpointSkipped.
  ///
  /// In en, this message translates to:
  /// **'skipped.'**
  String get checkpointSkipped;

  /// No description provided for @checkpointPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo evidence is required to complete this checkpoint.'**
  String get checkpointPhotoRequired;

  /// No description provided for @checkpointPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo evidence is optional when skipping a checkpoint.'**
  String get checkpointPhotoOptional;

  /// No description provided for @addCheckpointPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addCheckpointPhoto;

  /// No description provided for @takeCheckpointPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo with Camera'**
  String get takeCheckpointPhoto;

  /// No description provided for @chooseCheckpointPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseCheckpointPhoto;

  /// No description provided for @removeCheckpointPhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeCheckpointPhoto;

  /// No description provided for @retakeCheckpointPhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retakeCheckpointPhoto;

  /// No description provided for @changeCheckpointPhoto.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeCheckpointPhoto;

  /// No description provided for @checkpointNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get checkpointNotesOptional;

  /// No description provided for @checkpointSkipReason.
  ///
  /// In en, this message translates to:
  /// **'Skip reason'**
  String get checkpointSkipReason;

  /// No description provided for @checkpointPhotoUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'Use a JPG, JPEG, PNG, or WEBP image.'**
  String get checkpointPhotoUnsupportedType;

  /// No description provided for @checkpointPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Photo must be 5 MB or smaller.'**
  String get checkpointPhotoTooLarge;

  /// No description provided for @checkpointPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The selected photo is unavailable. Choose or capture it again.'**
  String get checkpointPhotoUnavailable;

  /// No description provided for @checkpointPhotoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint Photo Evidence'**
  String get checkpointPhotoEvidence;

  /// No description provided for @checkpointPhotoUploadedAt.
  ///
  /// In en, this message translates to:
  /// **'Uploaded At'**
  String get checkpointPhotoUploadedAt;

  /// No description provided for @checkpointPhotoSignedUrlHint.
  ///
  /// In en, this message translates to:
  /// **'This photo uses a temporary secure link. Pull down to refresh Patrol Detail if it expires.'**
  String get checkpointPhotoSignedUrlHint;

  /// No description provided for @checkpointPhotoRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Photo link is unavailable or expired. Pull down to refresh Patrol Detail.'**
  String get checkpointPhotoRefreshHint;

  /// No description provided for @checkpointMutationNetworkHint.
  ///
  /// In en, this message translates to:
  /// **'Connection status is uncertain. Refresh Patrol Detail before retrying this checkpoint action.'**
  String get checkpointMutationNetworkHint;

  /// No description provided for @completionNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Completion notes (optional)'**
  String get completionNotesOptional;

  /// No description provided for @patrolCompleted.
  ///
  /// In en, this message translates to:
  /// **'Patrol completed.'**
  String get patrolCompleted;

  /// No description provided for @patrolActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Patrol action could not be completed.'**
  String get patrolActionFailed;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason is required.'**
  String get reasonRequired;

  /// No description provided for @doneToday.
  ///
  /// In en, this message translates to:
  /// **'Done Today'**
  String get doneToday;

  /// No description provided for @checkpoints.
  ///
  /// In en, this message translates to:
  /// **'checkpoints'**
  String get checkpoints;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @checkedAt.
  ///
  /// In en, this message translates to:
  /// **'Checked At'**
  String get checkedAt;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @scheduledStatus.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduledStatus;

  /// No description provided for @inProgressStatus.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgressStatus;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// No description provided for @cancelledUpperStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledUpperStatus;

  /// No description provided for @pendingUpperStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingUpperStatus;

  /// No description provided for @skippedUpperStatus.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skippedUpperStatus;

  /// No description provided for @issueUpperStatus.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueUpperStatus;

  /// No description provided for @patrolFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'Patrol was not found or is not assigned to this officer.'**
  String get patrolFailureNotFound;

  /// No description provided for @patrolFailureCheckpointNotFound.
  ///
  /// In en, this message translates to:
  /// **'The checkpoint was not found or is not available to this officer.'**
  String get patrolFailureCheckpointNotFound;

  /// No description provided for @patrolFailureAlreadyStarted.
  ///
  /// In en, this message translates to:
  /// **'This patrol has already started.'**
  String get patrolFailureAlreadyStarted;

  /// No description provided for @patrolFailureAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'This patrol has already been completed.'**
  String get patrolFailureAlreadyCompleted;

  /// No description provided for @patrolFailureCancelled.
  ///
  /// In en, this message translates to:
  /// **'This patrol has been cancelled by administration.'**
  String get patrolFailureCancelled;

  /// No description provided for @patrolFailureInvalidState.
  ///
  /// In en, this message translates to:
  /// **'This patrol action is not valid for the current state.'**
  String get patrolFailureInvalidState;

  /// No description provided for @patrolFailureNotInProgress.
  ///
  /// In en, this message translates to:
  /// **'Start the patrol before processing checkpoints.'**
  String get patrolFailureNotInProgress;

  /// No description provided for @patrolFailureCheckpointInvalidState.
  ///
  /// In en, this message translates to:
  /// **'This checkpoint cannot be processed in its current state.'**
  String get patrolFailureCheckpointInvalidState;

  /// No description provided for @patrolFailureCheckpointAlreadyProcessed.
  ///
  /// In en, this message translates to:
  /// **'This checkpoint has already been processed.'**
  String get patrolFailureCheckpointAlreadyProcessed;

  /// No description provided for @patrolFailureCheckpointsPending.
  ///
  /// In en, this message translates to:
  /// **'All Pending checkpoints must be completed or skipped first.'**
  String get patrolFailureCheckpointsPending;

  /// No description provided for @patrolFailureCheckpointsStillPendingSuffix.
  ///
  /// In en, this message translates to:
  /// **'checkpoints are still Pending.'**
  String get patrolFailureCheckpointsStillPendingSuffix;

  /// No description provided for @patrolFailureValidation.
  ///
  /// In en, this message translates to:
  /// **'Review the Patrol input and try again.'**
  String get patrolFailureValidation;

  /// No description provided for @patrolFailureUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Security session has expired. Please sign in again.'**
  String get patrolFailureUnauthorized;

  /// No description provided for @patrolFailureForbidden.
  ///
  /// In en, this message translates to:
  /// **'This Security account cannot perform the requested Patrol action.'**
  String get patrolFailureForbidden;

  /// No description provided for @patrolFailureNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the Security API. Check the connection and retry.'**
  String get patrolFailureNetwork;

  /// No description provided for @patrolFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Patrol action failed unexpectedly.'**
  String get patrolFailureUnknown;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @designConceptNotice.
  ///
  /// In en, this message translates to:
  /// **'Design concept only. No active backend API, hardware integration, or operational automation is enabled.'**
  String get designConceptNotice;

  /// No description provided for @searchNameUnitIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Search name, unit, or identifier'**
  String get searchNameUnitIdentifier;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @inactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveStatus;

  /// No description provided for @residents.
  ///
  /// In en, this message translates to:
  /// **'Residents'**
  String get residents;

  /// No description provided for @visitors.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get visitors;

  /// No description provided for @vendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendors;

  /// No description provided for @accessStatus.
  ///
  /// In en, this message translates to:
  /// **'Access Status'**
  String get accessStatus;

  /// No description provided for @accessConceptNotice.
  ///
  /// In en, this message translates to:
  /// **'Access Control is a future design concept. Access status is presentation data only and does not control doors or hardware.'**
  String get accessConceptNotice;

  /// No description provided for @emergencyConceptNotice.
  ///
  /// In en, this message translates to:
  /// **'Emergency Response is a future concept. SOS escalation and contact actions are intentionally non-operational.'**
  String get emergencyConceptNotice;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY'**
  String get emergency;

  /// No description provided for @pressHoldThreeSeconds.
  ///
  /// In en, this message translates to:
  /// **'Press and hold for 3 seconds'**
  String get pressHoldThreeSeconds;

  /// No description provided for @conceptOnlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Concept only — disabled'**
  String get conceptOnlyDisabled;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @securityCenter.
  ///
  /// In en, this message translates to:
  /// **'Security Center'**
  String get securityCenter;

  /// No description provided for @paramedic.
  ///
  /// In en, this message translates to:
  /// **'Paramedic'**
  String get paramedic;

  /// No description provided for @fireDepartment.
  ///
  /// In en, this message translates to:
  /// **'Fire Department'**
  String get fireDepartment;

  /// No description provided for @police.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get police;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @incidentConceptNotice.
  ///
  /// In en, this message translates to:
  /// **'Incident Reporting is a future presentation workflow. Fields are static and Submit Report is intentionally disabled.'**
  String get incidentConceptNotice;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @enterLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter location details'**
  String get enterLocationDetails;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @provideIncidentDescription.
  ///
  /// In en, this message translates to:
  /// **'Provide a brief description of the incident'**
  String get provideIncidentDescription;

  /// No description provided for @photoEvidenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo / Evidence (Optional)'**
  String get photoEvidenceOptional;

  /// No description provided for @photoEvidenceConceptArea.
  ///
  /// In en, this message translates to:
  /// **'Photo evidence concept area'**
  String get photoEvidenceConceptArea;

  /// No description provided for @submitReportFuture.
  ///
  /// In en, this message translates to:
  /// **'Submit Report — Future Capability'**
  String get submitReportFuture;

  /// No description provided for @viewExampleIncidentDetail.
  ///
  /// In en, this message translates to:
  /// **'View Example Incident Detail'**
  String get viewExampleIncidentDetail;

  /// No description provided for @securityBreach.
  ///
  /// In en, this message translates to:
  /// **'Security Breach'**
  String get securityBreach;

  /// No description provided for @suspiciousActivity.
  ///
  /// In en, this message translates to:
  /// **'Suspicious Activity'**
  String get suspiciousActivity;

  /// No description provided for @accident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get accident;

  /// No description provided for @vandalism.
  ///
  /// In en, this message translates to:
  /// **'Vandalism'**
  String get vandalism;

  /// No description provided for @fire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fire;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @incidentType.
  ///
  /// In en, this message translates to:
  /// **'Incident Type'**
  String get incidentType;

  /// No description provided for @incidentDetail.
  ///
  /// In en, this message translates to:
  /// **'Incident Detail'**
  String get incidentDetail;

  /// No description provided for @exampleIncidentDetailNotice.
  ///
  /// In en, this message translates to:
  /// **'Example incident detail for design validation only. This is not a live incident record.'**
  String get exampleIncidentDetailNotice;

  /// No description provided for @incidentId.
  ///
  /// In en, this message translates to:
  /// **'Incident ID'**
  String get incidentId;

  /// No description provided for @reportedAt.
  ///
  /// In en, this message translates to:
  /// **'Reported At'**
  String get reportedAt;

  /// No description provided for @reportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported By'**
  String get reportedBy;

  /// No description provided for @reportedStatus.
  ///
  /// In en, this message translates to:
  /// **'REPORTED'**
  String get reportedStatus;

  /// No description provided for @evidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get evidence;

  /// No description provided for @evidencePreview.
  ///
  /// In en, this message translates to:
  /// **'EVIDENCE PREVIEW'**
  String get evidencePreview;

  /// No description provided for @vehicleConceptNotice.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Management is a future design concept. Search and access records shown here are static presentation data.'**
  String get vehicleConceptNotice;

  /// No description provided for @searchPlateNumber.
  ///
  /// In en, this message translates to:
  /// **'Search plate number'**
  String get searchPlateNumber;

  /// No description provided for @registeredStatus.
  ///
  /// In en, this message translates to:
  /// **'REGISTERED'**
  String get registeredStatus;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @ownerVisitor.
  ///
  /// In en, this message translates to:
  /// **'Owner / Visitor'**
  String get ownerVisitor;

  /// No description provided for @residentUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Resident Unit'**
  String get residentUnitLabel;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @parkingAccess.
  ///
  /// In en, this message translates to:
  /// **'Parking / Access'**
  String get parkingAccess;

  /// No description provided for @inside.
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get inside;

  /// No description provided for @lastEntry.
  ///
  /// In en, this message translates to:
  /// **'Last Entry'**
  String get lastEntry;

  /// No description provided for @lastExit.
  ///
  /// In en, this message translates to:
  /// **'Last Exit'**
  String get lastExit;

  /// No description provided for @recentVehicleAccess.
  ///
  /// In en, this message translates to:
  /// **'Recent Vehicle Access'**
  String get recentVehicleAccess;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @visitorRole.
  ///
  /// In en, this message translates to:
  /// **'Visitor'**
  String get visitorRole;

  /// No description provided for @exitedStatus.
  ///
  /// In en, this message translates to:
  /// **'EXITED'**
  String get exitedStatus;

  /// No description provided for @securityModule.
  ///
  /// In en, this message translates to:
  /// **'Security Module'**
  String get securityModule;

  /// No description provided for @conceptScreenUndefined.
  ///
  /// In en, this message translates to:
  /// **'Concept screen is not defined.'**
  String get conceptScreenUndefined;

  /// No description provided for @incidentSampleLocation.
  ///
  /// In en, this message translates to:
  /// **'Tower B Parking Area'**
  String get incidentSampleLocation;

  /// No description provided for @incidentSampleDescription.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized individual observed near parked vehicles. Officer documented activity and escalated for review.'**
  String get incidentSampleDescription;

  /// No description provided for @incidentSampleReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Security Team'**
  String get incidentSampleReportedBy;

  /// No description provided for @vehicleSuv.
  ///
  /// In en, this message translates to:
  /// **'SUV'**
  String get vehicleSuv;

  /// No description provided for @unit12A.
  ///
  /// In en, this message translates to:
  /// **'Unit 12A'**
  String get unit12A;

  /// No description provided for @incidentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Incident Dashboard'**
  String get incidentDashboard;

  /// No description provided for @incidentDashboardDescription.
  ///
  /// In en, this message translates to:
  /// **'Operational incident reporting and handling for your authorized Security properties.'**
  String get incidentDashboardDescription;

  /// No description provided for @openIncidents.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openIncidents;

  /// No description provided for @criticalIncidents.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get criticalIncidents;

  /// No description provided for @escalatedIncidents.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get escalatedIncidents;

  /// No description provided for @resolvedToday.
  ///
  /// In en, this message translates to:
  /// **'Resolved Today'**
  String get resolvedToday;

  /// No description provided for @activeIncidents.
  ///
  /// In en, this message translates to:
  /// **'Active Incidents'**
  String get activeIncidents;

  /// No description provided for @noActiveIncidents.
  ///
  /// In en, this message translates to:
  /// **'No Active Incidents'**
  String get noActiveIncidents;

  /// No description provided for @noActiveIncidentsMessage.
  ///
  /// In en, this message translates to:
  /// **'No open, acknowledged, or in-progress incidents match the current view.'**
  String get noActiveIncidentsMessage;

  /// No description provided for @reportIncident.
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get reportIncident;

  /// No description provided for @incidentHistory.
  ///
  /// In en, this message translates to:
  /// **'Incident History'**
  String get incidentHistory;

  /// No description provided for @loadingIncidents.
  ///
  /// In en, this message translates to:
  /// **'Loading incidents...'**
  String get loadingIncidents;

  /// No description provided for @incidentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Incident Unavailable'**
  String get incidentUnavailable;

  /// No description provided for @incidentCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'The incident could not be loaded.'**
  String get incidentCouldNotLoad;

  /// No description provided for @createIncident.
  ///
  /// In en, this message translates to:
  /// **'Create Incident'**
  String get createIncident;

  /// No description provided for @incidentTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Title'**
  String get incidentTitle;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @locationOptional.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get locationOptional;

  /// No description provided for @incidentDescription.
  ///
  /// In en, this message translates to:
  /// **'Incident Description'**
  String get incidentDescription;

  /// No description provided for @selectProperty.
  ///
  /// In en, this message translates to:
  /// **'Select Property'**
  String get selectProperty;

  /// No description provided for @propertyContextHint.
  ///
  /// In en, this message translates to:
  /// **'Property selects context only from the Security properties already authorized by the backend.'**
  String get propertyContextHint;

  /// No description provided for @reportIncidentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Incident report submitted.'**
  String get reportIncidentSuccess;

  /// No description provided for @createIncidentFailed.
  ///
  /// In en, this message translates to:
  /// **'Incident report could not be submitted.'**
  String get createIncidentFailed;

  /// No description provided for @incidentOperationalNotice.
  ///
  /// In en, this message translates to:
  /// **'Incident lifecycle actions use backend capability flags. Statuses, actors, timestamps, escalation and authorization remain server-authoritative.'**
  String get incidentOperationalNotice;

  /// No description provided for @incidentNoMediaNotice.
  ///
  /// In en, this message translates to:
  /// **'Photo/video upload is not part of Incident V1. Do not attach or imply media evidence in this workflow.'**
  String get incidentNoMediaNotice;

  /// No description provided for @acknowledgeIncident.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledgeIncident;

  /// No description provided for @acknowledgingIncident.
  ///
  /// In en, this message translates to:
  /// **'Acknowledging...'**
  String get acknowledgingIncident;

  /// No description provided for @startHandling.
  ///
  /// In en, this message translates to:
  /// **'Start Handling'**
  String get startHandling;

  /// No description provided for @startingIncident.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get startingIncident;

  /// No description provided for @resolveIncident.
  ///
  /// In en, this message translates to:
  /// **'Resolve Incident'**
  String get resolveIncident;

  /// No description provided for @resolvingIncident.
  ///
  /// In en, this message translates to:
  /// **'Resolving...'**
  String get resolvingIncident;

  /// No description provided for @addIncidentNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addIncidentNote;

  /// No description provided for @addingIncidentNote.
  ///
  /// In en, this message translates to:
  /// **'Adding Note...'**
  String get addingIncidentNote;

  /// No description provided for @optionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get optionalNotes;

  /// No description provided for @resolutionNotes.
  ///
  /// In en, this message translates to:
  /// **'Resolution Notes'**
  String get resolutionNotes;

  /// No description provided for @resolutionNotesRequired.
  ///
  /// In en, this message translates to:
  /// **'Resolution notes are required.'**
  String get resolutionNotesRequired;

  /// No description provided for @incidentNote.
  ///
  /// In en, this message translates to:
  /// **'Incident Note'**
  String get incidentNote;

  /// No description provided for @incidentNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Incident note is required.'**
  String get incidentNoteRequired;

  /// No description provided for @incidentTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get incidentTimeline;

  /// No description provided for @noTimeline.
  ///
  /// In en, this message translates to:
  /// **'No Timeline'**
  String get noTimeline;

  /// No description provided for @noTimelineMessage.
  ///
  /// In en, this message translates to:
  /// **'No incident timeline events are available.'**
  String get noTimelineMessage;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned To'**
  String get assignedTo;

  /// No description provided for @escalationLevel.
  ///
  /// In en, this message translates to:
  /// **'Escalation Level'**
  String get escalationLevel;

  /// No description provided for @patrolContext.
  ///
  /// In en, this message translates to:
  /// **'Patrol Context'**
  String get patrolContext;

  /// No description provided for @checkpoint.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint'**
  String get checkpoint;

  /// No description provided for @incidentActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Incident action could not be completed.'**
  String get incidentActionFailed;

  /// No description provided for @incidentFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'Incident was not found or is outside this Security scope.'**
  String get incidentFailureNotFound;

  /// No description provided for @incidentFailureCheckpointNotFound.
  ///
  /// In en, this message translates to:
  /// **'The linked Patrol checkpoint was not found or is not accessible.'**
  String get incidentFailureCheckpointNotFound;

  /// No description provided for @incidentFailurePatrolNotInProgress.
  ///
  /// In en, this message translates to:
  /// **'The linked Patrol session is not in progress.'**
  String get incidentFailurePatrolNotInProgress;

  /// No description provided for @incidentFailureCheckpointProcessed.
  ///
  /// In en, this message translates to:
  /// **'The linked Patrol checkpoint has already been processed.'**
  String get incidentFailureCheckpointProcessed;

  /// No description provided for @incidentFailureAlreadyAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'This incident has already been acknowledged.'**
  String get incidentFailureAlreadyAcknowledged;

  /// No description provided for @incidentFailureAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'This incident is already in progress.'**
  String get incidentFailureAlreadyInProgress;

  /// No description provided for @incidentFailureAlreadyResolved.
  ///
  /// In en, this message translates to:
  /// **'This incident has already been resolved.'**
  String get incidentFailureAlreadyResolved;

  /// No description provided for @incidentFailureClosed.
  ///
  /// In en, this message translates to:
  /// **'This incident was closed by administration.'**
  String get incidentFailureClosed;

  /// No description provided for @incidentFailureCancelled.
  ///
  /// In en, this message translates to:
  /// **'This incident was cancelled by administration.'**
  String get incidentFailureCancelled;

  /// No description provided for @incidentFailureInvalidState.
  ///
  /// In en, this message translates to:
  /// **'This Incident action is not valid for the current status.'**
  String get incidentFailureInvalidState;

  /// No description provided for @incidentFailureValidation.
  ///
  /// In en, this message translates to:
  /// **'Review the Incident input and try again.'**
  String get incidentFailureValidation;

  /// No description provided for @incidentFailureUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your Security session has ended. Please sign in again.'**
  String get incidentFailureUnauthorized;

  /// No description provided for @incidentFailureForbidden.
  ///
  /// In en, this message translates to:
  /// **'This Security account cannot perform the requested Incident action.'**
  String get incidentFailureForbidden;

  /// No description provided for @incidentFailureNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the Security API. Check the network and try again.'**
  String get incidentFailureNetwork;

  /// No description provided for @incidentFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'The Incident request failed unexpectedly.'**
  String get incidentFailureUnknown;

  /// No description provided for @incidentStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get incidentStatusOpen;

  /// No description provided for @incidentStatusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get incidentStatusAcknowledged;

  /// No description provided for @incidentStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get incidentStatusInProgress;

  /// No description provided for @incidentStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get incidentStatusResolved;

  /// No description provided for @incidentStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get incidentStatusClosed;

  /// No description provided for @incidentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get incidentStatusCancelled;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severityLow;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get severityMedium;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severityHigh;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCritical;

  /// No description provided for @terminalIncidentActivity.
  ///
  /// In en, this message translates to:
  /// **'Resolved Incident Activity'**
  String get terminalIncidentActivity;

  /// No description provided for @terminalIncidentActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Resolved, closed, and cancelled incidents visible to this Security officer.'**
  String get terminalIncidentActivityDescription;

  /// No description provided for @noIncidentHistory.
  ///
  /// In en, this message translates to:
  /// **'No Incident History'**
  String get noIncidentHistory;

  /// No description provided for @noIncidentHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'No terminal incidents match this history filter.'**
  String get noIncidentHistoryMessage;

  /// No description provided for @searchIncidents.
  ///
  /// In en, this message translates to:
  /// **'Search incidents'**
  String get searchIncidents;

  /// No description provided for @searchIncidentHint.
  ///
  /// In en, this message translates to:
  /// **'Incident number, title, description, location, or category'**
  String get searchIncidentHint;

  /// No description provided for @reportedByMe.
  ///
  /// In en, this message translates to:
  /// **'Reported By Me'**
  String get reportedByMe;

  /// No description provided for @assignedToMe.
  ///
  /// In en, this message translates to:
  /// **'Assigned To Me'**
  String get assignedToMe;

  /// No description provided for @eventReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get eventReported;

  /// No description provided for @eventStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status Changed'**
  String get eventStatusChanged;

  /// No description provided for @eventNoteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note Added'**
  String get eventNoteAdded;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @submitIncident.
  ///
  /// In en, this message translates to:
  /// **'Submit Incident'**
  String get submitIncident;

  /// No description provided for @submittingIncident.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submittingIncident;

  /// No description provided for @incidentReportedAt.
  ///
  /// In en, this message translates to:
  /// **'Reported At'**
  String get incidentReportedAt;

  /// No description provided for @incidentResolvedAt.
  ///
  /// In en, this message translates to:
  /// **'Resolved At'**
  String get incidentResolvedAt;

  /// No description provided for @incidentAcknowledgedAt.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged At'**
  String get incidentAcknowledgedAt;

  /// No description provided for @incidentResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get incidentResolution;

  /// No description provided for @incidentEscalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get incidentEscalated;

  /// No description provided for @incidentNotEscalated.
  ///
  /// In en, this message translates to:
  /// **'Not escalated'**
  String get incidentNotEscalated;

  /// No description provided for @incidentCategoryExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Safety, Security, Accident'**
  String get incidentCategoryExample;

  /// No description provided for @incidentTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Incident title is required.'**
  String get incidentTitleRequired;

  /// No description provided for @incidentDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Incident description is required.'**
  String get incidentDescriptionRequired;

  /// No description provided for @incidentCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Incident category is required.'**
  String get incidentCategoryRequired;

  /// No description provided for @incidentPropertyRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an authorized property for this incident.'**
  String get incidentPropertyRequired;

  /// No description provided for @reportCheckpointIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportCheckpointIssue;

  /// No description provided for @linkedPatrolCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Linked Patrol Checkpoint'**
  String get linkedPatrolCheckpoint;

  /// No description provided for @emergencySos.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencySos;

  /// No description provided for @emergencySosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resident SOS alerts and Security response'**
  String get emergencySosSubtitle;

  /// No description provided for @emergencySosAlert.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS Alert'**
  String get emergencySosAlert;

  /// No description provided for @emergencyTakeAlert.
  ///
  /// In en, this message translates to:
  /// **'Take Alert'**
  String get emergencyTakeAlert;

  /// No description provided for @emergencyTakingAlert.
  ///
  /// In en, this message translates to:
  /// **'Taking Alert...'**
  String get emergencyTakingAlert;

  /// No description provided for @emergencyPersistentModalHint.
  ///
  /// In en, this message translates to:
  /// **'This alert stays visible until one Security officer takes it.'**
  String get emergencyPersistentModalHint;

  /// No description provided for @emergencyTriggeredAt.
  ///
  /// In en, this message translates to:
  /// **'Triggered'**
  String get emergencyTriggeredAt;

  /// No description provided for @emergencyUnresolvedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Unresolved Alerts'**
  String get emergencyUnresolvedAlerts;

  /// No description provided for @emergencyHistory.
  ///
  /// In en, this message translates to:
  /// **'Emergency History'**
  String get emergencyHistory;

  /// No description provided for @emergencyNoUnresolved.
  ///
  /// In en, this message translates to:
  /// **'No unresolved SOS alerts'**
  String get emergencyNoUnresolved;

  /// No description provided for @emergencyNoUnresolvedMessage.
  ///
  /// In en, this message translates to:
  /// **'Open and acknowledged SOS alerts will appear here.'**
  String get emergencyNoUnresolvedMessage;

  /// No description provided for @emergencyNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No resolved SOS history'**
  String get emergencyNoHistory;

  /// No description provided for @emergencyNoHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Resolved SOS alerts will appear here.'**
  String get emergencyNoHistoryMessage;

  /// No description provided for @emergencyAlertDetail.
  ///
  /// In en, this message translates to:
  /// **'SOS Alert Detail'**
  String get emergencyAlertDetail;

  /// No description provided for @emergencyResident.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get emergencyResident;

  /// No description provided for @emergencyUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get emergencyUnit;

  /// No description provided for @emergencyAcknowledgedAt.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get emergencyAcknowledgedAt;

  /// No description provided for @emergencyTakenBy.
  ///
  /// In en, this message translates to:
  /// **'Taken By'**
  String get emergencyTakenBy;

  /// No description provided for @emergencyResolvedAt.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get emergencyResolvedAt;

  /// No description provided for @emergencyMessage.
  ///
  /// In en, this message translates to:
  /// **'Resident Message'**
  String get emergencyMessage;

  /// No description provided for @emergencyResolutionNotes.
  ///
  /// In en, this message translates to:
  /// **'Resolution Notes'**
  String get emergencyResolutionNotes;

  /// No description provided for @emergencyResolutionNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes about the completed response.'**
  String get emergencyResolutionNotesHint;

  /// No description provided for @emergencyResolveAlert.
  ///
  /// In en, this message translates to:
  /// **'Resolve Alert'**
  String get emergencyResolveAlert;

  /// No description provided for @emergencyBackendSourceOfTruth.
  ///
  /// In en, this message translates to:
  /// **'Backend emergency state is the source of truth. Open alerts remain in the persistent modal queue until acknowledged.'**
  String get emergencyBackendSourceOfTruth;

  /// No description provided for @emergencyStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get emergencyStatusOpen;

  /// No description provided for @emergencyStatusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get emergencyStatusAcknowledged;

  /// No description provided for @emergencyStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get emergencyStatusResolved;

  /// No description provided for @emergencyFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'SOS alert not found.'**
  String get emergencyFailureNotFound;

  /// No description provided for @emergencyFailureAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'This SOS alert has already been taken by another Security officer.'**
  String get emergencyFailureAlreadyTaken;

  /// No description provided for @emergencyFailureAlreadyResolved.
  ///
  /// In en, this message translates to:
  /// **'This SOS alert has already been resolved.'**
  String get emergencyFailureAlreadyResolved;

  /// No description provided for @emergencyFailureNotAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Take the SOS alert before resolving it.'**
  String get emergencyFailureNotAcknowledged;

  /// No description provided for @emergencyFailureAssignedToOther.
  ///
  /// In en, this message translates to:
  /// **'This SOS alert is being handled by another Security officer.'**
  String get emergencyFailureAssignedToOther;

  /// No description provided for @emergencyFailureValidation.
  ///
  /// In en, this message translates to:
  /// **'The SOS request data is invalid.'**
  String get emergencyFailureValidation;

  /// No description provided for @emergencyFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unable to process the SOS alert right now.'**
  String get emergencyFailureUnknown;

  /// No description provided for @packageReceiving.
  ///
  /// In en, this message translates to:
  /// **'Package Receiving'**
  String get packageReceiving;

  /// No description provided for @packageReceivingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive and collect resident packages through the existing Package Center.'**
  String get packageReceivingSubtitle;

  /// No description provided for @packageCenterSourceOfTruth.
  ///
  /// In en, this message translates to:
  /// **'Package Center is the source of truth. Security Mobile writes to the same durable resident package records used by Web Admin and Resident Mobile.'**
  String get packageCenterSourceOfTruth;

  /// No description provided for @receivePackage.
  ///
  /// In en, this message translates to:
  /// **'Receive Package'**
  String get receivePackage;

  /// No description provided for @receivePackageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the resident or unit, then register the package with its courier details.'**
  String get receivePackageSubtitle;

  /// No description provided for @packageServerOwnedNotice.
  ///
  /// In en, this message translates to:
  /// **'Package number, property, unit, received time, actor, and initial Ready for Pickup status are assigned by the backend.'**
  String get packageServerOwnedNotice;

  /// No description provided for @searchResidentUnit.
  ///
  /// In en, this message translates to:
  /// **'Resident / Unit'**
  String get searchResidentUnit;

  /// No description provided for @searchResidentUnitHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, mobile, email, unit, or tower'**
  String get searchResidentUnitHint;

  /// No description provided for @searchResident.
  ///
  /// In en, this message translates to:
  /// **'Search Resident'**
  String get searchResident;

  /// No description provided for @noResidentsFound.
  ///
  /// In en, this message translates to:
  /// **'No Residents Found'**
  String get noResidentsFound;

  /// No description provided for @noResidentsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No active resident matches this search in an authorized Package Center property.'**
  String get noResidentsFoundMessage;

  /// No description provided for @selectedResident.
  ///
  /// In en, this message translates to:
  /// **'Selected Resident'**
  String get selectedResident;

  /// No description provided for @packageDetails.
  ///
  /// In en, this message translates to:
  /// **'Package Details'**
  String get packageDetails;

  /// No description provided for @courierName.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get courierName;

  /// No description provided for @trackingNumber.
  ///
  /// In en, this message translates to:
  /// **'Tracking Number'**
  String get trackingNumber;

  /// No description provided for @trackingNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Tracking Number (optional)'**
  String get trackingNumberOptional;

  /// No description provided for @senderName.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get senderName;

  /// No description provided for @senderNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Sender (optional)'**
  String get senderNameOptional;

  /// No description provided for @packageDescription.
  ///
  /// In en, this message translates to:
  /// **'Package Description'**
  String get packageDescription;

  /// No description provided for @packageDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Package Description (optional)'**
  String get packageDescriptionOptional;

  /// No description provided for @storageLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get storageLocation;

  /// No description provided for @storageLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Storage Location (optional)'**
  String get storageLocationOptional;

  /// No description provided for @registerPackage.
  ///
  /// In en, this message translates to:
  /// **'Register Package'**
  String get registerPackage;

  /// No description provided for @packageList.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packageList;

  /// No description provided for @searchPackages.
  ///
  /// In en, this message translates to:
  /// **'Search Packages'**
  String get searchPackages;

  /// No description provided for @searchPackagesHint.
  ///
  /// In en, this message translates to:
  /// **'Package no., courier, tracking, resident, or unit'**
  String get searchPackagesHint;

  /// No description provided for @noPackages.
  ///
  /// In en, this message translates to:
  /// **'No Packages'**
  String get noPackages;

  /// No description provided for @noPackagesMessage.
  ///
  /// In en, this message translates to:
  /// **'No package records match the current filters.'**
  String get noPackagesMessage;

  /// No description provided for @packageDetail.
  ///
  /// In en, this message translates to:
  /// **'Package Detail'**
  String get packageDetail;

  /// No description provided for @packageStatusReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get packageStatusReadyForPickup;

  /// No description provided for @packageStatusCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get packageStatusCollected;

  /// No description provided for @packageStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get packageStatusExpired;

  /// No description provided for @resident.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get resident;

  /// No description provided for @receivedAt.
  ///
  /// In en, this message translates to:
  /// **'Received At'**
  String get receivedAt;

  /// No description provided for @receivedBy.
  ///
  /// In en, this message translates to:
  /// **'Received By'**
  String get receivedBy;

  /// No description provided for @collectedAt.
  ///
  /// In en, this message translates to:
  /// **'Collected At'**
  String get collectedAt;

  /// No description provided for @collectedBy.
  ///
  /// In en, this message translates to:
  /// **'Picked Up By'**
  String get collectedBy;

  /// No description provided for @expiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires At'**
  String get expiresAt;

  /// No description provided for @collectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Collection Notes'**
  String get collectionNotes;

  /// No description provided for @collectionNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Collection Notes (optional)'**
  String get collectionNotesOptional;

  /// No description provided for @collectionNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional handover note'**
  String get collectionNotesHint;

  /// No description provided for @markPackageCollected.
  ///
  /// In en, this message translates to:
  /// **'Mark Collected'**
  String get markPackageCollected;

  /// No description provided for @packageResidentRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a resident before registering the package.'**
  String get packageResidentRequired;

  /// No description provided for @packageCourierRequired.
  ///
  /// In en, this message translates to:
  /// **'Courier is required.'**
  String get packageCourierRequired;

  /// No description provided for @packageFailureCenterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Package Center is not enabled for any Security property assigned to this user.'**
  String get packageFailureCenterUnavailable;

  /// No description provided for @packageFailureResidentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resident not found or is not available for package receiving.'**
  String get packageFailureResidentNotFound;

  /// No description provided for @packageFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'Package not found.'**
  String get packageFailureNotFound;

  /// No description provided for @packageFailureValidation.
  ///
  /// In en, this message translates to:
  /// **'Package data is not valid. Check the form and try again.'**
  String get packageFailureValidation;

  /// No description provided for @packageFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Package Center is temporarily unavailable. Please try again.'**
  String get packageFailureUnknown;

  /// No description provided for @dashboardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Dashboard data is unavailable for the current Security property.'**
  String get dashboardUnavailable;

  /// No description provided for @dashboardNetworkRetry.
  ///
  /// In en, this message translates to:
  /// **'Dashboard could not reach the Security API. Check the connection and retry.'**
  String get dashboardNetworkRetry;

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Dashboard data could not be loaded.'**
  String get dashboardLoadFailed;

  /// No description provided for @visitorBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'This visitor is blacklisted and cannot be admitted.'**
  String get visitorBlacklisted;

  /// No description provided for @processedBy.
  ///
  /// In en, this message translates to:
  /// **'Processed By'**
  String get processedBy;

  /// No description provided for @collectionRecipient.
  ///
  /// In en, this message translates to:
  /// **'Pickup Recipient'**
  String get collectionRecipient;

  /// No description provided for @collectionRecipientResident.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get collectionRecipientResident;

  /// No description provided for @collectionRecipientOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get collectionRecipientOthers;

  /// No description provided for @collectionRecipientName.
  ///
  /// In en, this message translates to:
  /// **'Recipient Name'**
  String get collectionRecipientName;

  /// No description provided for @collectionRecipientNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mbak Rina - ART'**
  String get collectionRecipientNameHint;

  /// No description provided for @collectionRecipientNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Recipient name is required when Others is selected.'**
  String get collectionRecipientNameRequired;

  /// No description provided for @packageFailureForbidden.
  ///
  /// In en, this message translates to:
  /// **'This Security account does not have permission to perform this Package Center action.'**
  String get packageFailureForbidden;

  /// No description provided for @pickedUpByType.
  ///
  /// In en, this message translates to:
  /// **'Picked Up By Type'**
  String get pickedUpByType;

  /// No description provided for @pickupRecipientNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Pickup recipient not recorded'**
  String get pickupRecipientNotRecorded;

  /// No description provided for @recordPickupRecipient.
  ///
  /// In en, this message translates to:
  /// **'Record Pickup Recipient'**
  String get recordPickupRecipient;

  /// No description provided for @pickupRecipientCorrectionHint.
  ///
  /// In en, this message translates to:
  /// **'This collected package has no pickup recipient recorded. Add the missing recipient without changing the original collection time or processor.'**
  String get pickupRecipientCorrectionHint;

  /// No description provided for @packageCollectionResidentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The package resident is no longer available for collection.'**
  String get packageCollectionResidentUnavailable;

  /// No description provided for @taskDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Detail'**
  String get taskDetailTitle;

  /// No description provided for @taskDetailInformation.
  ///
  /// In en, this message translates to:
  /// **'Task Information'**
  String get taskDetailInformation;

  /// No description provided for @taskDetailLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get taskDetailLocation;

  /// No description provided for @taskDetailPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskDetailPriority;

  /// No description provided for @taskDetailSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get taskDetailSource;

  /// No description provided for @taskDetailCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get taskDetailCreatedAt;

  /// No description provided for @taskDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get taskDetailStatus;

  /// No description provided for @taskDetailStatusAwaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'AWAITING RESPONSE'**
  String get taskDetailStatusAwaitingResponse;

  /// No description provided for @taskDetailInstruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get taskDetailInstruction;

  /// No description provided for @taskDispatchInstruction.
  ///
  /// In en, this message translates to:
  /// **'Inspect suspicious activity in the parking area and report the on-site condition.'**
  String get taskDispatchInstruction;

  /// No description provided for @taskDetailUnknownValue.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get taskDetailUnknownValue;

  /// No description provided for @taskDetailRespondAction.
  ///
  /// In en, this message translates to:
  /// **'Respond to Task'**
  String get taskDetailRespondAction;

  /// No description provided for @taskPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get taskPriorityNormal;

  /// No description provided for @taskPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get taskPriorityHigh;

  /// No description provided for @taskPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get taskPriorityCritical;

  /// No description provided for @taskResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Response'**
  String get taskResponseTitle;

  /// No description provided for @taskWorkflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Response Progress'**
  String get taskWorkflowTitle;

  /// No description provided for @taskStageAssigned.
  ///
  /// In en, this message translates to:
  /// **'Task assigned'**
  String get taskStageAssigned;

  /// No description provided for @taskStageAccepted.
  ///
  /// In en, this message translates to:
  /// **'Task accepted'**
  String get taskStageAccepted;

  /// No description provided for @taskStageEnRoute.
  ///
  /// In en, this message translates to:
  /// **'Heading to location'**
  String get taskStageEnRoute;

  /// No description provided for @taskStageArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived at location'**
  String get taskStageArrived;

  /// No description provided for @taskStageHandling.
  ///
  /// In en, this message translates to:
  /// **'Handling in progress'**
  String get taskStageHandling;

  /// No description provided for @taskActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept Task'**
  String get taskActionAccept;

  /// No description provided for @taskActionEnRoute.
  ///
  /// In en, this message translates to:
  /// **'Head to Location'**
  String get taskActionEnRoute;

  /// No description provided for @taskActionArrive.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Location'**
  String get taskActionArrive;

  /// No description provided for @taskActionHandle.
  ///
  /// In en, this message translates to:
  /// **'Start Handling'**
  String get taskActionHandle;

  /// No description provided for @taskEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get taskEvidenceTitle;

  /// No description provided for @taskActionAttachEvidence.
  ///
  /// In en, this message translates to:
  /// **'Attach Evidence'**
  String get taskActionAttachEvidence;

  /// No description provided for @taskEvidenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Attach evidence before completing the task.'**
  String get taskEvidenceRequired;

  /// No description provided for @taskActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete Task'**
  String get taskActionComplete;

  /// No description provided for @taskCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Completed'**
  String get taskCompletedTitle;

  /// No description provided for @taskCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Task {taskId} has been completed and removed from Active Tasks.'**
  String taskCompletedMessage(String taskId);

  /// No description provided for @taskBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get taskBackToHome;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed Tasks'**
  String get completedTasks;

  /// No description provided for @completedTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks completed during the current app session.'**
  String get completedTasksSubtitle;

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet'**
  String get noCompletedTasks;

  /// No description provided for @noCompletedTasksMessage.
  ///
  /// In en, this message translates to:
  /// **'Completed dispatch tasks will appear here.'**
  String get noCompletedTasksMessage;

  /// No description provided for @taskCompletedStatus.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get taskCompletedStatus;

  /// No description provided for @taskEvidenceAttached.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get taskEvidenceAttached;

  /// No description provided for @visitorVerificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Visitor Verification History'**
  String get visitorVerificationHistory;

  /// No description provided for @visitorVerificationHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the existing visitor check-in and check-out history.'**
  String get visitorVerificationHistorySubtitle;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
