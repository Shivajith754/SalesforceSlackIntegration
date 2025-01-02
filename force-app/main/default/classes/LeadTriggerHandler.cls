public with sharing class LeadTriggerHandler {

    public static void sendSlackNotifications(List<Lead> newLeads) {
        if (newLeads.isEmpty()) return;

        Set<Id> leadIdsProcessed = new Set<Id>();
        List<SlackNotificationJob> jobs = new List<SlackNotificationJob>();

        for (Lead lead : newLeads) {
            if (!leadIdsProcessed.contains(lead.Id)) {
                String slackMessage = prepareSlackMessage(lead);
                if (slackMessage != null) {
                    jobs.add(new SlackNotificationJob(slackMessage, lead.Id));
                    leadIdsProcessed.add(lead.Id);
                } else {
                    Logger.warn('Skipped notification for Lead ID: ' + lead.Id + ' due to null message.');
                }
            }
        }

        if (!jobs.isEmpty()) {
            Logger.info('Enqueuing Slack notification jobs.');
            System.enqueueJob(new SlackNotificationQueueable(jobs, new SlackService()));
        }
    }

    private static String prepareSlackMessage(Lead lead) {
        try {
            String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
            String link = '<' + baseUrl + '/' + lead.Id + '|View in Salesforce>';

            Map<String, Object> messageMap = new Map<String, Object> {
                'channel' => SlackConfig.CHANNEL_ID,
                'text' => 'New Lead Created!'
            };

            List<Map<String, Object>> blocks = new List<Map<String, Object>>();

            String text = '*New Lead:* ' + 
                          (lead.FirstName != null ? lead.FirstName + ' ' : '') + 
                          (lead.LastName != null ? lead.LastName : '') + '\n';

            if (lead.Company != null) text += '*Company:* ' + lead.Company + '\n';
            if (lead.Email != null) text += '*Email:* ' + lead.Email + '\n';
            if (lead.Phone != null) text += '*Phone:* ' + lead.Phone + '\n';
            if (lead.LeadSource != null) text += '*Lead Source:* ' + lead.LeadSource + '\n';

            text += link;

            blocks.add(new Map<String, Object> {
                'type' => 'section',
                'text' => new Map<String, Object> { 'type' => 'mrkdwn', 'text' => text }
            });

            messageMap.put('blocks', blocks);
            return JSON.serialize(messageMap);

        } catch (Exception e) {
            Logger.error('Failed to prepare Slack message: ' + e.getMessage());
            return null;
        }
    }

    public class SlackNotificationJob {
        public String message { get; private set; }
        public Id leadId { get; private set; }

        public SlackNotificationJob(String message, Id leadId) {
            this.message = message;
            this.leadId = leadId;
        }
    }

    public class SlackNotificationQueueable implements Queueable, Database.AllowsCallouts {
        private List<SlackNotificationJob> jobs;
        private ISlackService slackService;

        public SlackNotificationQueueable(List<SlackNotificationJob> jobs, ISlackService service) {
            this.jobs = jobs;
            this.slackService = service;
        }

        public void execute(QueueableContext context) {
            for (SlackNotificationJob job : jobs) {
                Logger.info('Processing Slack notification job for Lead ID: ' + job.leadId);
                Map<String, Object> response = slackService.sendMessage(job.message, job.leadId);
                createLog(job.leadId, (String)response.get('status'), (String)response.get('message'));
            }
        }

        private void createLog(Id leadId, String status, String responseMessage) {
            List<Slack_Notification_Log__c> existingLogs = [
                SELECT Id FROM Slack_Notification_Log__c WHERE Lead__c = :leadId
            ];
            if (existingLogs.isEmpty()) {
                Slack_Notification_Log__c log = new Slack_Notification_Log__c();
                log.Lead__c = leadId;
                log.Status__c = status;
                log.Response_Message__c = responseMessage;
                log.Timestamp__c = System.now();
                insert log;
            } else {
                Logger.warn('Slack Notification Log already exists for Lead ID: ' + leadId);
            }
        }
    }
}
