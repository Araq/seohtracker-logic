// Mainly NSUserDefaults wrappers.

float bundle_version(void);
bool system_uses_metric(void);

float config_changelog_version(void);
void set_config_changelog_version(float value);

int user_metric_preference(void);
void set_user_metric_preference(int value);

void set_ad_index(int value);
int get_ad_index(void);

void set_nimrod_metric_use_based_on_user_preferences(void);
void configure_metric_locale(void);

bool analytics_tracking_preference(void);
void set_analytics_tracking_preference(bool doit);
