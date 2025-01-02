public interface ISlackService {
    /**
     * Sends a message to Slack.
     * @param message The message to send.
     * @param leadId The ID of the Lead associated with the message.
     * @return A map containing the status and response message from Slack.
     */
    Map<String, Object> sendMessage(String message, Id leadId);
}