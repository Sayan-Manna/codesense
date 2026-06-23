package com.codesense.webhookingestion;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
class KafkaTopicConfig {

    @Value("${app.kafka.topics.pr-received}")
    private String prReceivedTopic;

    @Value("${app.kafka.topics.analysis-completed}")
    private String analysisCompletedTopic;

    @Value("${app.kafka.topics.pr-merged}")
    private String prMergedTopic;

    /**
     * Published when a PR is opened or updated (synchronize event).
     * Partition key = repo full name → all events for the same repo go
     * to the same partition, preserving per-repo ordering.
     */
    @Bean
    public NewTopic prReceivedTopic() {
        return TopicBuilder.name(prReceivedTopic)
                .partitions(3)
                .replicas(1)
                .build();
    }

    /**
     * Published when the AI engine finishes analyzing a PR.
     * Partition key = PR id → all events for the same PR are ordered.
     */
    @Bean
    public NewTopic analysisCompletedTopic() {
        return TopicBuilder.name(analysisCompletedTopic)
                .partitions(3)
                .replicas(1)
                .build();
    }

    /**
     * Published when a PR is merged.
     * Partition key = repo full name → same ordering guarantee as pr.received.
     */
    @Bean
    public NewTopic prMergedTopic() {
        return TopicBuilder.name(prMergedTopic)
                .partitions(3)
                .replicas(1)
                .build();
    }
}
