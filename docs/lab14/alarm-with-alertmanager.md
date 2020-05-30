# Alarm with AlertManager

To prevent the downtime from occurring, we need to rely on monitoring and alerting. Monitoring helps predict potential problem or notify for current problem in our system and gives detail regarding the problem. Alerting helps notify as soon as the problem occurs. Alerts are essential to monitoring. They allow teams to identify problem through calls, notifications or another medium so the team can quickly take action and minimize critical system downtime. Monitoring and Alerting should be considered first-class citizens in any system. Alerting in Prometheus is separated into two parts. First, Alert rules are defined in Prometheus configuration. If any alert condition hits, Prometheus send alert to AlertManager. Second, AlertManager manages alerts through its pipeline of silencing, inhibition, grouping and sending out notifications. Silencing is to mute alerts for a given time. Alerts are checked to match against active silent alerts, if a match is found then no notifications are sent. Inhibition is to suppress notifications for certain alerts if other alerts are already fired. Grouping group alerts of similar nature into a single notification. This helps prevent firing multiple notifications simultaneously.

Alerting with Prometheus setup steps are mentioned below:

1. Setup and configure AlertManager.
2. Configure the config file on Prometheus so it can talk to the AlertManager.
3. Define alert rules in Prometheus server configuration.
4. Define alert mechanism in AlertManager to send alerts via Slack, Email, PagerDuty etc.

