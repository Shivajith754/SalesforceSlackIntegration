public with sharing class SlackService implements ISlackService {

    public Map<String, Object> sendMessage(String message, Id leadId) {
        String endpoint = SlackConfig.SLACK_API_ENDPOINT;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json; charset=utf-8');
        req.setHeader('Authorization', 'Bearer ' + SlackConfigManager.getInstance().getBotToken());
        req.setBody(message);

        Http http = new Http();

        try {
            HttpResponse res = http.send(req);
            return processResponse(res, leadId);
        } catch (Exception e) {
            Logger.error('Exception sending Slack notification for Lead ID: ' + leadId + ' - ' + e.getMessage());
            return createErrorResponse(leadId, 'Exception: ' + e.getMessage());
        }
    }

    private Map<String, Object> processResponse(HttpResponse res, Id leadId) {
        Integer statusCode = res.getStatusCode();

        if (statusCode == 429) {
            return handleRateLimit(res, leadId);
        }

        if (statusCode == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (responseMap.containsKey('ok') && (Boolean) responseMap.get('ok')) {
                return createSuccessResponse(leadId, res.getBody(), true);
            } else {
                String error = responseMap.containsKey('error') ? (String) responseMap.get('error') : 'Unknown error';
                if ('rate_limited'.equalsIgnoreCase(error)) {
                    return handleRateLimit(res, leadId);
                }
                return createErrorResponse(leadId, error);
            }
        } else if (statusCode >= 500) {
            Logger.warn('Server error from Slack: HTTP ' + statusCode);
            return createErrorResponse(leadId, 'Server error: HTTP ' + statusCode);
        } else if (statusCode >= 400) {
            String errorDetail = parseErrorResponse(res.getBody());
            return createErrorResponse(leadId, 'Client error: HTTP ' + statusCode + ' - ' + errorDetail);
        } else {
            return createErrorResponse(leadId, 'Unexpected HTTP status: ' + statusCode);
        }
    }

    private Map<String, Object> handleRateLimit(HttpResponse res, Id leadId) {
        Logger.warn('Rate limited. Scheduling retry...');
        Integer retryAfter = res.getHeader('Retry-After') != null ? Integer.valueOf(res.getHeader('Retry-After')) : 1;
        SlackRetryScheduler.scheduleRetry(null, leadId, retryAfter);

        return new Map<String, Object>{
            'status' => 'Rate Limited',
            'message' => 'Rate limited. Retry scheduled after ' + retryAfter + ' seconds'
        };
    }

    private String parseErrorResponse(String responseBody) {
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            return responseMap.containsKey('error') ? (String) responseMap.get('error') : 'Unknown error';
        } catch (Exception e) {
            return 'Error parsing response body';
        }
    }

    private Map<String, Object> createSuccessResponse(Id leadId, String message, Boolean createLog) {
        if (createLog) {
            createLog(leadId, 'Success', message);
        }
        return new Map<String, Object>{
            'status' => 'Success',
            'message' => message
        };
    }

    private Map<String, Object> createErrorResponse(Id leadId, String message) {
        if (!'Rate Limited'.equalsIgnoreCase(message)) {
            createLog(leadId, 'Failure', message);
        }
        return new Map<String, Object>{
            'status' => 'Failure',
            'message' => message
        };
    }

    private void createLog(Id leadId, String status, String message) {
        if ('Rate Limited'.equalsIgnoreCase(status)) {
            Logger.info('Skipping log creation for status: Rate Limited');
            return;
        }

        DateTime oneMinuteAgo = DateTime.now().addMinutes(-1);
        List<Slack_Notification_Log__c> recentLogs = [
            SELECT Id
            FROM Slack_Notification_Log__c
            WHERE Lead__c = :leadId
            AND Status__c = :status
            AND Timestamp__c >= :oneMinuteAgo
        ];

        if (recentLogs.isEmpty()) {
            Slack_Notification_Log__c log = new Slack_Notification_Log__c(
                Lead__c = leadId,
                Status__c = status,
                Response_Message__c = message,
                Timestamp__c = System.now()
            );
            insert log;
        }
    }
}
