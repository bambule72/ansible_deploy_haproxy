# Quick Start Guide

This guide will help you get started with the `ansible_deploy_haproxy` role quickly.

## Prerequisites

1. **Target System Requirements:**
   - RHEL 8 or 9 (or compatible: Rocky Linux, AlmaLinux)
   - Python 3 installed
   - SSH access with sudo privileges

2. **Control Node Requirements:**
   - Ansible 2.15 or higher
   - Python 3.6 or higher

## Installation

### Option 1: Clone the repository

```bash
git clone https://github.com/bambule72/ansible_deploy_haproxy.git
cd ansible_deploy_haproxy
```

### Option 2: Install from Ansible Galaxy (when published)

```bash
ansible-galaxy install bambule72.ansible_deploy_haproxy
```

## Quick Test with Example Configuration

1. **Edit the inventory file** (`inventory.ini`) with your server details:

```ini
[loadbalancers]
your-server ansible_host=192.168.1.100

[loadbalancers:vars]
ansible_user=root
ansible_python_interpreter=/usr/bin/python3
```

2. **Review the example playbook** (`playbook.yml`) - it contains a working configuration with:
   - HTTP frontend on port 80
   - HTTPS frontend on port 443 (requires SSL certificate)
   - Two backends: web and API
   - Statistics page on port 8080

3. **Run the playbook:**

```bash
ansible-playbook -i inventory.ini playbook.yml
```

## Basic Usage Example

Create a simple playbook:

```yaml
---
- name: Deploy HAProxy
  hosts: loadbalancers
  become: true

  vars:
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
          - name: "web1"
            address: "192.168.1.10:8080"
            check: true

  tasks:
    - name: Include HAProxy role
      ansible.builtin.include_role:
        name: ansible_deploy_haproxy
```

## Common Use Cases

### 1. Simple HTTP Load Balancer

```yaml
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
      - name: "server2"
        address: "192.168.1.11:8080"
        check: true
```

### 2. HTTPS with SSL Termination

First, obtain SSL certificate (using `dz_basis.certaccord.issue` or manually):

```yaml
haproxy_frontends:
  - name: "https_frontend"
    bind: "*:443 ssl crt /etc/haproxy/certs/server.pem"
    mode: "http"
    default_backend: "web_backend"
```

### 3. Multiple Backends with ACLs

```yaml
haproxy_frontends:
  - name: "http_frontend"
    bind: "*:80"
    mode: "http"
    acls:
      - "is_api path_beg /api"
      - "is_admin path_beg /admin"
    use_backend:
      - "api_backend if is_api"
      - "admin_backend if is_admin"
    default_backend: "web_backend"

haproxy_backends:
  - name: "web_backend"
    balance: "roundrobin"
    servers:
      - name: "web1"
        address: "192.168.1.10:8080"
  
  - name: "api_backend"
    balance: "leastconn"
    servers:
      - name: "api1"
        address: "192.168.1.20:3000"
  
  - name: "admin_backend"
    servers:
      - name: "admin1"
        address: "192.168.1.30:9000"
```

## Verification

After deployment, verify HAProxy is running:

```bash
# Check service status
sudo systemctl status haproxy

# Validate configuration
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# View logs
sudo journalctl -u haproxy -f

# Check listening ports
sudo ss -tlnp | grep haproxy
```

## Accessing Statistics Page

If you enabled stats (set `haproxy_stats_enable: true`):

1. Open browser to: `http://your-server:8080/stats`
2. Login with credentials from `haproxy_stats_auth` (default: admin/password)

**Important:** Change the default password in production!

## Troubleshooting

### HAProxy won't start

1. Check configuration syntax:
   ```bash
   sudo haproxy -c -f /etc/haproxy/haproxy.cfg
   ```

2. Check SELinux status:
   ```bash
   sudo getenforce
   sudo ausearch -m avc -ts recent
   ```

3. Check logs:
   ```bash
   sudo journalctl -u haproxy -n 50
   ```

### Port binding errors

Ensure no other service is using the ports:
```bash
sudo ss -tlnp | grep :80
sudo ss -tlnp | grep :443
```

### Backend servers not reachable

1. Test connectivity from HAProxy server:
   ```bash
   curl -v http://backend-server:port
   ```

2. Check firewall rules:
   ```bash
   sudo firewall-cmd --list-all
   ```

## Development and Testing

### Running Molecule Tests

```bash
# Install dependencies
pip install "molecule[podman]" molecule-plugins[podman]
ansible-galaxy collection install containers.podman ansible.posix

# Run tests
cd ansible_deploy_haproxy
molecule test

# Test on specific platform
molecule test -s default
```

## Next Steps

- Review the full [README.md](README.md) for detailed configuration options
- Check the `molecule/default/converge.yml` for more examples
- Customize the configuration for your specific needs
- Integrate with `dz_basis.certaccord.issue` role for SSL certificate management

## Support

For issues and feature requests, please use the GitHub issue tracker.
