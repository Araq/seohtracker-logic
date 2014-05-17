#import "user_config.h"

#import "NSString+seohyun.h"
#import "SHNotifications.h"
#import "n_global.h"
#import "n_types.h"

#import "ELHASO.h"


static NSString *k_user_metric_preference = @"USER_METRIC_PREFERENCE";
static NSString *k_user_refuses_tracking = @"USER_REFUSES_TRACKING";
static NSString *k_config_changelog_version = @"USER_CHANGELOG_VERSION";
static NSString *k_ad_index_preference = @"AD_INDEX";


/** Returns the current user setting changelog value.
 *
 * Returns a value greater than zero if the user setting exists, zero otherwise.
 */
float config_changelog_version(void)
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    return [d floatForKey:k_config_changelog_version];
}

/** Sets the float value for the changelog version preference.
 *
 * Values lower than zero are clamped to zero, which is interpreted as no
 * value. Also generates the notification did_change_changelog_version.
 */
void set_config_changelog_version(float value)
{
    if (value < 0) value = 0;
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setFloat:value forKey:k_config_changelog_version];
    [d synchronize];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:did_change_changelog_version object:nil];
}

/** Returns the value of the embedded app version.
 *
 * Returns zero if something went wrong.
 */
float bundle_version(void)
{
    return [[[[NSBundle mainBundle] infoDictionary]
        objectForKey:@"CFBundleVersion"] floatValue];
}

/** Returns the user metric preference.
 *
 * This will be zero if the user hasn't set anything, therefore accepting the
 * automatic value. Otherwise it will be an integer mapping
 * (kilograms|pounds)+1.
 */
int user_metric_preference(void)
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    return (int)[d integerForKey:k_user_metric_preference];
}

/** Saves the specified value to the user preferences.
 *
 * See user_metric_preference() for valid values. Also generates the
 * notification user_metric_prefereces_changed.
 */
void set_user_metric_preference(int value)
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setInteger:value forKey:k_user_metric_preference];
    [d synchronize];

    set_nimrod_metric_use_based_on_user_preferences();
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:user_metric_prefereces_changed object:nil];
}

/** Returns the user analytics tracking preference.
 *
 * This will be true if the user hasn't set anything.
 */
bool analytics_tracking_preference(void)
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    return ![d boolForKey:k_user_refuses_tracking];
}

/** Saves the analytics tracking preference of the user.
 *
 * See analytics_tracking_preference() for valid values.
 */
void set_analytics_tracking_preference(bool doit)
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:!doit forKey:k_user_refuses_tracking];
    [d synchronize];
}

/** Returns true if the system is set up to use the metric system.
 *
 * This function doesn't read any configuration data, it always returns the
 * current system locale.
 */
bool system_uses_metric(void)
{
    // Obtain metric setting from environment.
    // http://stackoverflow.com/a/9997513/172690
    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    const BOOL uses_metric = [[locale objectForKey:NSLocaleUsesMetricSystem]
        boolValue];
    return uses_metric;
}

/// Sets the add index preference to the specified value.
void set_ad_index(int value)
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setInteger:value forKey:k_ad_index_preference];
    [d synchronize];
}

/// Recovers the ad index preference.
int get_ad_index(void)
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    return (int)[d integerForKey:k_ad_index_preference];
}

/// Helper method to update nimrod's global metric defaults.
void set_nimrod_metric_use_based_on_user_preferences(void)
{
    const int pref = user_metric_preference();
    if (pref > 0)
        specify_metric_use((kilograms == (pref - 1)));
    else
        specify_metric_use(system_uses_metric());
}

/// Configures locale settings, call once during initialisation.
void configure_metric_locale(void)
{
    // Obtain metric setting from environment.
    // http://stackoverflow.com/a/9997513/172690
    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    const BOOL uses_metric = [[locale objectForKey:NSLocaleUsesMetricSystem]
        boolValue];
    NSString *separator = [locale objectForKey:NSLocaleDecimalSeparator];

    DLOG(@"Uses metric? %d, decimal separator is '%@'", uses_metric, separator);
    set_decimal_separator([separator cstring]);
    set_nimrod_metric_use_based_on_user_preferences();
}
