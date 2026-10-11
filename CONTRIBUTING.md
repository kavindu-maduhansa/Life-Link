# Contributing to LifeLink

Thank you for your interest in contributing to LifeLink! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

- Flutter SDK 3.12 or newer
- Dart SDK 3.12 or newer
- Android Studio or VS Code with Flutter extension
- Git
- Firebase account (for backend development)

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Life-Link.git
   cd Life-Link
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Create a branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Branch Naming

Use descriptive branch names:
- `feature/feature-name` for new features
- `bugfix/bug-description` for bug fixes
- `docs/documentation-update` for documentation changes
- `refactor/code-improvement` for refactoring

### Making Changes

1. Make your changes following the [Coding Standards](#coding-standards)
2. Test your changes thoroughly
3. Commit your changes with clear messages:
   ```bash
   git commit -m "Add: feature description"
   ```
4. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Format

Use conventional commit messages:
- `Add:` for new features
- `Fix:` for bug fixes
- `Update:` for updates to existing features
- `Refactor:` for code refactoring
- `Docs:` for documentation changes
- `Style:` for code style changes (formatting, etc.)
- `Test:` for adding or updating tests

Examples:
- `Add: donor availability toggle in profile screen`
- `Fix: resolve navigation issue in request status screen`
- `Update: improve error handling in authentication flow`

## Coding Standards

### Dart/Flutter Guidelines

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` to check for issues
- Format code with `dart format .`
- Keep functions small and focused
- Use meaningful variable and function names
- Add comments for complex logic

### File Organization

- Keep related files together
- Use descriptive file names in snake_case
- Follow the existing project structure
- Separate business logic from UI code

### UI/UX Guidelines

- Follow the [LifeLink Design System](docs/LIFELINK_DESIGN_SYSTEM.md)
- Ensure accessibility (color contrast, text size)
- Test on multiple screen sizes
- Handle loading, error, and empty states
- Use neumorphic components where appropriate

### Firebase Guidelines

- Follow the [Data Contract](docs/LIFELINK_DATA_CONTRACT.md)
- Use proper security rules
- Handle offline scenarios
- Validate data before writing to Firestore
- Use transactions for critical operations

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/utils/request_status_test.dart
```

### Writing Tests

- Write unit tests for utility functions
- Write widget tests for UI components
- Test edge cases and error conditions
- Aim for good test coverage on critical paths

### Manual Testing Checklist

- [ ] Feature works as expected
- [ ] No console errors or warnings
- [ ] UI looks correct on different screen sizes
- [ ] Offline behavior is handled
- [ ] Loading states are shown
- [ ] Error states are user-friendly
- [ ] Navigation works correctly
- [ ] Data persists correctly

## Submitting Changes

### Pull Request Process

1. Ensure your code follows the coding standards
2. Update documentation if needed
3. Add tests for new features
4. Run `flutter analyze` and fix any issues
5. Run `flutter test` and ensure all tests pass
6. Create a pull request with:
   - Clear title and description
   - Screenshots for UI changes
   - Link to related issues
   - List of changes made

### Review Process

- Maintainers will review your PR
- Address feedback promptly
- Keep the PR focused and small if possible
- Be responsive to review comments

### After Merge

- Delete your feature branch
- Update your local repository
- Celebrate your contribution! 🎉

## Questions?

If you have questions about contributing, feel free to:
- Open an issue for discussion
- Contact the maintainers
- Check existing issues for similar questions

---

Thank you for contributing to LifeLink! Your contributions help make blood donation coordination more efficient and save lives.
