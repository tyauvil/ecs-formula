# ecs-formula

This formula adds the Amazon ECS service to an instance using the upstream Docker image and manages the service with a systemd unit file.

This formula has one pillar data node: `cluster_name`

```
ecs:
  cluster_name: inf-us-west-2
```