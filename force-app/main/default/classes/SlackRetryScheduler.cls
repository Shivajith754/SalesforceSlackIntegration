public with sharing class SlackRetryScheduler implements Schedulable {

    private String message;
    private Id leadId;
    private Integer retryCount;

    public SlackRetryScheduler() {}

    public SlackRetryScheduler(String message, Id leadId, Integer retryCount) {
        this.message = message;
        this.leadId = leadId;
        this.retryCount = retryCount;
    }

    public static void scheduleRetry(String message, Id leadId, Integer retryCount) {
        try {
            Integer backoffTimeInSeconds = (Math.pow(2, retryCount)).intValue();
            Logger.info('Scheduling retry in ' + backoffTimeInSeconds + ' seconds.');

            String cronExpression = generateCronExpression(backoffTimeInSeconds);

            System.schedule('SlackRetry-' + retryCount, cronExpression, new SlackRetryScheduler(message, leadId, retryCount));
        } catch (Exception e) {
            Logger.error('Error in scheduleRetry: ' + e.getMessage());
        }
    }

    private static String generateCronExpression(Integer secondsFromNow) {
        DateTime futureTime = DateTime.now().addSeconds(secondsFromNow);

        return futureTime.second() + ' ' + futureTime.minute() + ' ' + futureTime.hour() + ' ' +
               futureTime.day() + ' ' + futureTime.month() + ' ? ' + futureTime.year();
    }

    public void execute(SchedulableContext context) {
        Logger.info('Executing Slack retry job for Lead ID: ' + leadId);

        try {
            if (message != null) {
                SlackService service = new SlackService();
                service.sendMessage(message, leadId);
                Logger.info('Retry attempt for Lead ID: ' + leadId);
            } else {
                Logger.warn('Message is null. Retry aborted for Lead ID: ' + leadId);
            }
        } catch (Exception e) {
            Logger.error('Retry failed for Lead ID: ' + leadId + '. Error: ' + e.getMessage());
        }
    }
}
