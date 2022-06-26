This work is based on the work of: https://github.com/oznu/docker-guacamole

A Docker Container for Apache Guacamole, a client-less remote desktop gateway. It supports standard protocols like VNC, RDP, and SSH over HTML5.
This image will run on most platforms that support Docker including Docker for arm64 boards (Raspberry ARM64v8 on an 64bit OS).
This container runs the guacamole web client, the guacd server and a postgres database.

- Apache Tomcat 9.0.64 (no CVE-2022-29885)
- Guacamole 1.4.0
- Postgressql 11
- ghostscript included (for virtual printing to PDF)
