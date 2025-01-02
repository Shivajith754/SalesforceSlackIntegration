@isTest
public class LeadTriggerHandlerTest {
    
    /**
     * Tests sending Slack notifications with partial Lead data.
     */
    @isTest static void testSendSlackNotifications_WithPartialData() {
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHandlerTest.SlackApiMockSuccess());

        // Create test Lead with partial data
        Lead testLead = new Lead(
            FirstName = 'Alice',
            LastName = 'Smith',
            Company = 'Wonderland Inc.',
            Phone = '987-654-3210'
        );
        insert testLead;

        // Clear any pre-existing logs
        delete [SELECT Id FROM Slack_Notification_Log__c WHERE Lead__c = :testLead.Id];

        Test.startTest();
        LeadTriggerHandler.sendSlackNotifications(new List<Lead>{ testLead });
        Test.stopTest();

        // Verify Slack Notification Log
        List<Slack_Notification_Log__c> logs = [
            SELECT Status__c 
            FROM Slack_Notification_Log__c 
            WHERE Lead__c = :testLead.Id
        ];
        System.assertEquals(1, logs.size(), 'One Slack Notification Log should be created.');
        System.assertEquals('Success', logs[0].Status__c, 'Slack notification should be successful.');
    }

    /**
     * Tests sending Slack notifications with invalid authentication.
     */
    @isTest static void testSendSlackNotifications_InvalidAuth() {
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHandlerTest.SlackApiMockInvalidAuth());

        // Create test Lead
        Lead testLead = new Lead(
            FirstName = 'Bob',
            LastName = 'Brown',
            Company = 'Example Corp.',
            Email = 'bob.brown@example.com',
            Phone = '555-1234'
        );
        insert testLead;

        // Clear any pre-existing logs
        delete [SELECT Id FROM Slack_Notification_Log__c WHERE Lead__c = :testLead.Id];

        Test.startTest();
        LeadTriggerHandler.sendSlackNotifications(new List<Lead>{ testLead });
        Test.stopTest();

        // Verify Slack Notification Log
        List<Slack_Notification_Log__c> logs = [
            SELECT Status__c, Response_Message__c 
            FROM Slack_Notification_Log__c 
            WHERE Lead__c = :testLead.Id
        ];
        System.assertEquals(1, logs.size(), 'One Slack Notification Log should be created.');
        System.assertEquals('Failure', logs[0].Status__c, 'Slack notification should fail due to invalid auth.');
        System.assertEquals('invalid_auth', logs[0].Response_Message__c, 'Error message should indicate invalid authentication.');
    }

    /**
     * Mock class for successful Slack API response.
     */
    public class SlackApiMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ok":true,"channel":"C0871TVSDPW","ts":"1234567890.123456","message":{"text":"New Lead Created!"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Mock class for invalid authentication Slack API response.
     */
    public class SlackApiMockInvalidAuth implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ok":false,"error":"invalid_auth"}');
            res.setStatusCode(200);
            return res;
        }
    }
}
