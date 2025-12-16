# Contributing to ansible_deploy_haproxy

Thank you for your interest in contributing to this project!

## Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/bambule72/ansible_deploy_haproxy.git
   cd ansible_deploy_haproxy
   ```

2. **Install development dependencies:**
   ```bash
   pip install "molecule[podman]" molecule-plugins[podman] ansible-lint yamllint
   ansible-galaxy collection install containers.podman ansible.posix
   ```

## Making Changes

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards below

3. **Test your changes:**
   ```bash
   # Lint the code
   yamllint .
   ansible-lint
   
   # Run Molecule tests
   molecule test
   ```

## Coding Standards

### YAML Style

- Use 2 spaces for indentation
- Quote strings when they contain special characters
- Keep lines under 160 characters
- No trailing spaces
- Use descriptive variable names

### Ansible Best Practices

- Always use FQCN (Fully Qualified Collection Names) for modules
  - Good: `ansible.builtin.file`
  - Bad: `file`

- Use descriptive task names that explain what the task does

- Add comments for complex logic

- Keep tasks idempotent

- Use handlers for service restarts

- Validate configurations before applying (use `validate:` parameter)

### Template Guidelines

- Keep templates clean and well-commented
- Use Jinja2 best practices
- Test templates with various configurations

## Testing

### Running Tests Locally

```bash
# Lint only
yamllint .
ansible-lint

# Full test cycle
molecule test

# Create instances and test iteratively
molecule create
molecule converge
molecule verify
molecule destroy
```

### Writing Tests

When adding new features:

1. Add test scenarios to `molecule/default/converge.yml`
2. Add verification tests to `molecule/default/verify.yml`
3. Ensure all tests pass

## Submitting Changes

1. **Commit your changes:**
   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

2. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request** on GitHub with:
   - Clear description of changes
   - Reference to any related issues
   - Test results

## Pull Request Guidelines

- Keep PRs focused on a single feature or fix
- Include tests for new features
- Update documentation as needed
- Ensure all CI checks pass
- Follow the existing code style

## Questions or Issues?

Feel free to open an issue on GitHub if you have questions or encounter problems.

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.
