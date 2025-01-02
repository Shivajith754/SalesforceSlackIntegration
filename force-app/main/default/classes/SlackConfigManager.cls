public class SlackConfigManager {
    private static SlackConfigManager instance;
    private String botToken;
    private String channelId;
    
    // Private constructor to enforce Singleton pattern
    private SlackConfigManager() {
        Slack_Settings__c settings = Slack_Settings__c.getOrgDefaults();
        if (settings != null) {
            botToken = settings.Slack_Bot_Token__c;
            // If channel ID is also stored in Custom Settings, retrieve it here
            // channelId = settings.Slack_Channel_ID__c;
        }
    }
    
    /**
     * Retrieves the singleton instance of SlackConfigManager.
     * @return The singleton instance.
     */
    public static SlackConfigManager getInstance() {
        if (instance == null) {
            instance = new SlackConfigManager();
        }
        return instance;
    }
    
    /**
     * Retrieves the Slack Bot Token.
     * @return The Slack Bot Token.
     */
    public String getBotToken() {
        return botToken;
    }
    
    // If channel ID is stored in Custom Settings, include a getter
    // public String getChannelId() {
    //     return channelId;
    // }
}
