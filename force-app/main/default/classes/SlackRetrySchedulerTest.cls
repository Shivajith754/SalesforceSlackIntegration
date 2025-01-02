@isTest
public class SlackRetrySchedulerTest {

    @isTest static void testScheduleRetry() {
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Test Company');
        insert testLead;

        String testMessage = '{"channel":"C0871TVSDPW","text":"Test Message"}';
        Integer retryCount = 1;

        Test.startTest();
        SlackRetryScheduler.scheduleRetry(testMessage, testLead.Id, retryCount);
        Test.stopTest();

        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, State 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'SlackRetry-%'
        ];
        System.assertEquals(1, scheduledJobs.size(), 'One retry job should be scheduled.');
        System.assertEquals('WAITING', scheduledJobs[0].State, 'Scheduled job should be in WAITING state.');
    }

    @isTest static void testExecute() {
        Test.setMock(HttpCalloutMock.class, new SlackApiMockSuccess());

        Lead testLead = new Lead(FirstName = 'Retry', LastName = 'Lead', Company = 'Retry Inc.');
        insert testLead;

        String testMessage = '{"channel":"C0871TVSDPW","text":"Retry Message"}';
        Integer retryCount = 1;

        Test.startTest();
        new SlackRetryScheduler(testMessage, testLead.Id, retryCount).execute(null);
        Test.stopTest();

        List<Slack_Notification_Log__c> logs = [
            SELECT Status__c 
            FROM Slack_Notification_Log__c 
            WHERE Lead__c = :testLead.Id
        ];
        System.assertEquals(1, logs.size(), 'One Slack Notification Log should be created.');
        System.assertEquals('Success', logs[0].Status__c, 'Notification should succeed.');
    }

    public class SlackApiMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ok":true}');
            res.setStatusCode(200);
            return res;
        }
    }
}