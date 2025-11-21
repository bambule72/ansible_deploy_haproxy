# ansible_deploy_haproxy

Ansible role to install and configure HAProxy on RHEL 8 and 9 servers with highly flexible configuration support for multiple frontends and backends.

## Requirements

- RHEL 8 or 9 (or compatible distributions like Rocky Linux, AlmaLinux)
- Ansible 2.15 or higher
- Python 3.6 or higher on target hosts

## Role Variables

### Global Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `haproxy_global_log` | `127.0.0.1 local2` | Syslog server and facility |
| `haproxy_global_chroot` | `/var/lib/haproxy` | Chroot directory |
| `haproxy_global_pidfile` | `/var/run/haproxy.pid` | PID file location |
| `haproxy_global_maxconn` | `4000` | Maximum connections |
| `haproxy_global_user` | `haproxy` | User to run HAProxy |
| `haproxy_global_group` | `haproxy` | Group to run HAProxy |
| `haproxy_global_daemon` | `true` | Run as daemon |
| `haproxy_global_stats_socket` | `/var/lib/haproxy/stats` | Stats socket path |
| `haproxy_global_ssl_default_bind_ciphers` | `PROFILE=SYSTEM` | SSL cipher profile |
| `haproxy_global_ssl_default_bind_options` | `ssl-min-ver TLSv1.2` | SSL options |

### Default Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `haproxy_defaults_mode` | `http` | Default mode (http/tcp) |
| `haproxy_defaults_log` | `global` | Log configuration |
| `haproxy_defaults_option` | `["httplog", "dontlognull"]` | Default options |
| `haproxy_defaults_timeout_connect` | `10s` | Connection timeout |
| `haproxy_defaults_timeout_client` | `1m` | Client timeout |
| `haproxy_defaults_timeout_server` | `1m` | Server timeout |
| `haproxy_defaults_maxconn` | `3000` | Maximum connections |

### Frontend Configuration

Configure multiple frontends using `haproxy_frontends` list:

```yaml
haproxy_frontends:
  - name: "http_frontend"
    bind: "*:80"
    mode: "http"
    default_backend: "web_backend"
    options:
      - "httplog"
      - "forwardfor"
    acls:
      - "is_api path_beg /api"
    use_backend:
      - "api_backend if is_api"
  
  - name: "https_frontend"
    bind: "*:443 ssl crt /etc/haproxy/certs/server.pem"
    mode: "http"
    default_backend: "web_backend"
    options:
      - "httplog"
      - "forwardfor"
```

### Backend Configuration

Configure multiple backends using `haproxy_backends` list:

```yaml
haproxy_backends:
  - name: "web_backend"
    mode: "http"
    balance: "roundrobin"
    options:
      - "httpchk GET /"
    servers:
      - name: "web1"
        address: "192.168.1.10:8080"
        check: true
      - name: "web2"
        address: "192.168.1.11:8080"
        check: true
        backup: true
  
  - name: "api_backend"
    mode: "http"
    balance: "leastconn"
    options:
      - "httpchk GET /health"
    servers:
      - name: "api1"
        address: "192.168.1.20:3000"
        check: true
```

### Stats Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `haproxy_stats_enable` | `false` | Enable stats page |
| `haproxy_stats_uri` | `/haproxy?stats` | Stats URI |
| `haproxy_stats_realm` | `HAProxy Statistics` | Auth realm |
| `haproxy_stats_auth` | `admin:password` | Stats authentication |
| `haproxy_stats_port` | `8080` | Stats page port |

### Certificate Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `haproxy_cert_path` | `/etc/haproxy/certs` | Certificate directory path |

**Note:** Certificates should be managed by the `dz_basis.certaccord.issue` role, which can export as PEM file or JKS store. HAProxy requires PEM format.

## Dependencies

None. However, for SSL/TLS certificates, you can use the `dz_basis.certaccord.issue` role to manage certificates.

## Example Playbook

### Basic Usage

```yaml
---
- hosts: loadbalancers
  become: true
  roles:
    - role: ansible_deploy_haproxy
      haproxy_frontends:
        - name: "http_frontend"
          bind: "*:80"
          mode: "http"
          default_backend: "web_backend"
      haproxy_backends:
        - name: "web_backend"
          mode: "http"
          balance: "roundrobin"
          servers:
            - name: "server1"
              address: "192.168.1.10:8080"
              check: true
```

### Advanced Usage with SSL

```yaml
---
- hosts: loadbalancers
  become: true
  
  tasks:
    # First, obtain SSL certificates using dz_basis.certaccord.issue role
    - name: Issue SSL certificate
      ansible.builtin.include_role:
        name: dz_basis.certaccord.issue
      vars:
        cert_common_name: example.com
        cert_export_format: pem
        cert_export_path: /etc/haproxy/certs/server.pem
    
    # Then deploy HAProxy with SSL configuration
    - name: Deploy HAProxy
      ansible.builtin.include_role:
        name: ansible_deploy_haproxy
      vars:
        haproxy_frontends:
          - name: "http_frontend"
            bind: "*:80"
            mode: "http"
            default_backend: "redirect_to_https"
          
          - name: "https_frontend"
            bind: "*:443 ssl crt /etc/haproxy/certs/server.pem"
            mode: "http"
            default_backend: "web_backend_ssl"
            options:
              - "httplog"
              - "forwardfor"
              - "http-server-close"
        
        haproxy_backends:
          - name: "redirect_to_https"
            mode: "http"
            http_request:
              - "redirect scheme https code 301"
          
          - name: "web_backend_ssl"
            mode: "http"
            balance: "roundrobin"
            options:
              - "httpchk GET /health"
            servers:
              - name: "web1"
                address: "192.168.1.10:8080"
                check: true
              - name: "web2"
                address: "192.168.1.11:8080"
                check: true
        
        haproxy_stats_enable: true
        haproxy_stats_port: 8080
        haproxy_stats_auth: "admin:SecurePassword123"
```

### Multiple Backends with ACLs

```yaml
---
- hosts: loadbalancers
  become: true
  roles:
    - role: ansible_deploy_haproxy
      haproxy_frontends:
        - name: "http_frontend"
          bind: "*:80"
          mode: "http"
          options:
            - "httplog"
            - "forwardfor"
          acls:
            - "is_api path_beg /api"
            - "is_static path_beg /static"
          use_backend:
            - "api_backend if is_api"
            - "static_backend if is_static"
          default_backend: "web_backend"
      
      haproxy_backends:
        - name: "web_backend"
          mode: "http"
          balance: "roundrobin"
          servers:
            - name: "web1"
              address: "192.168.1.10:8080"
              check: true
        
        - name: "api_backend"
          mode: "http"
          balance: "leastconn"
          servers:
            - name: "api1"
              address: "192.168.1.20:3000"
              check: true
        
        - name: "static_backend"
          mode: "http"
          balance: "roundrobin"
          servers:
            - name: "static1"
              address: "192.168.1.30:80"
              check: true
```

## Testing with Molecule

This role includes Molecule tests using Podman driver for RHEL 8 and 9.

### Prerequisites

```bash
pip install "molecule[podman]" molecule-plugins[podman] ansible-lint yamllint
ansible-galaxy collection install containers.podman ansible.posix
```

### Running Tests

```bash
# Run full test suite
molecule test

# Create test instances
molecule create

# Run converge (apply the role)
molecule converge

# Run verification tests
molecule verify

# Login to test instance
molecule login -h rhel8
molecule login -h rhel9

# Destroy test instances
molecule destroy
```

## License

MIT

## Author Information

bambule72
