@isTest
public class SlackServiceTest {

    @isTest static void testSendMessage_Success() {
        Test.setMock(HttpCalloutMock.class, new SlackApiMockSuccess());

        Lead testLead = new Lead(FirstName = 'Success', LastName = 'Lead', Company = 'Success Inc.');
        insert testLead;

        Test.startTest();
        ISlackService slackService = new SlackService();
        Map<String, Object> response = slackService.sendMessage('{"channel":"test","text":"Success"}', testLead.Id);
        Test.stopTest();

        System.assertEquals('Success', response.get('status'), 'Notification should succeed.');

        List<Slack_Notification_Log__c> logs = [
            SELECT Status__c FROM Slack_Notification_Log__c WHERE Lead__c = :testLead.Id
        ];
        System.assertEquals(1, logs.size(), 'One log should be created.');
    }

    @isTest static void testSendMessage_RateLimited() {
        Test.setMock(HttpCalloutMock.class, new SlackApiMockRateLimited());

        Lead testLead = new Lead(FirstName = 'Rate', LastName = 'Limited', Company = 'Rate Limited Inc.');
        insert testLead;

        Test.startTest();
        ISlackService slackService = new SlackService();
        Map<String, Object> response = slackService.sendMessage('{"channel":"test","text":"Rate Limited"}', testLead.Id);
        Test.stopTest();

        System.assertEquals('Rate Limited', response.get('status'), 'Status should indicate rate limit.');

        List<Slack_Notification_Log__c> logs = [
            SELECT Status__c FROM Slack_Notification_Log__c WHERE Lead__c = :testLead.Id
        ];
        System.assertEquals(1, logs.size(), 'log should be created for rate limit.');
    }

    private class SlackApiMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"ok":true}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class SlackApiMockRateLimited implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"ok":false,"error":"rate_limited"}');
            res.setStatusCode(429);
            return res;
        }
    }
}