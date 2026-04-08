# Dozzle

Dozzle is an open-source project sponsored by Docker OSS. It is a lightweight, web-based log viewer designed to simplify monitoring and debugging containerized applications across Docker, Docker Swarm, and Kubernetes environments.  Instead of manually running terminal commands like docker logs, Dozzle provides a lightweight web-based interface where you can monitor all your container logs live in one place. 

- Website: https://dozzle.dev/
- Docs: https://dozzle.dev/guide/what-is-dozzle
- GitHub: https://github.com/amir20/dozzle
- Reference Docker Compoose: https://github.com/amir20/dozzle/blob/master/docker-compose.yml

## Why is Dozzle in this project?

Dozzle typically runs as a Docker container itself. It connects to the Docker daemon socket (/var/run/docker.sock) to read and stream log data to its web interface. It does not require a database or heavy configuration, making it a "plug-and-play" solution for developers and home lab enthusiasts.  This is the inward looking log tool that monitors the homelab-observability stack, whilst the other obvervability tools look outwards to external systems.

## Key Features

- **Real-time Monitoring:** Stream logs from running containers with instant updates through an intuitive web interface. Monitor CPU, memory, and network usage with live metrics and historical visualizations.

- **Flexible Deployment:** Deploy as a standalone server for single or multi-host Docker monitoring, enable automatic discovery in Docker Swarm clusters, or monitor pod logs in Kubernetes environments.

- **Advanced Log Handling:** Automatically detects and formats JSON logs with intelligent color coding. Supports simple text logs, structured JSON logs, and multi-line grouped entries with powerful filtering and search capabilities.

- **Multi-Host Support:** Monitor containers across multiple Docker hosts simultaneously through a distributed agent architecture using gRPC.

- **Interactive Terminal:** Attach to running containers or execute commands directly through the web interface.

- **Lightweight & Fast:** Built with Go backend and Vue 3 frontend, Dozzle uses efficient streaming protocols (SSE/WebSocket) and requires minimal resources.

Dozzle is easy to install and configure, making it an ideal solution for developers and system administrators seeking an efficient log viewer for their containerized environments. The tool is available under the MIT license and is actively maintained by its developer, Amir Raminfar.
