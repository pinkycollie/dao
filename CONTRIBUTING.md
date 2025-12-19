# Contributing to MBTQ DAO

Thank you for your interest in contributing to MBTQ DAO! We welcome contributions from the community and are grateful for your support.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Getting Help](#getting-help)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed and what you expected**
- **Include screenshots or animated GIFs if applicable**
- **Include your environment details** (OS, Node.js version, browser, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List any alternative solutions you've considered**

### Pull Requests

We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code lints
6. Issue that pull request!

## Development Setup

### Prerequisites

- **Node.js** (v18 or higher)
- **pnpm** (recommended) or npm
- **Git**
- **PostgreSQL** (for local database)
- **Vercel account** (for deployment)

### Local Development

1. **Clone the repository:**
   ```bash
   git clone https://github.com/pinkycollie/dao.git
   cd dao
   ```

2. **Install dependencies:**
   ```bash
   pnpm install
   ```

3. **Set up environment variables:**
   ```bash
   cp .env.example .env.local
   ```
   Then edit `.env.local` with your configuration.

4. **Run database migrations:**
   ```bash
   pnpm run db:push
   ```

5. **Start the development server:**
   ```bash
   pnpm dev
   ```

6. **Open your browser:**
   Navigate to `http://localhost:3000`

### Running Tests

```bash
# Run all tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run linting
pnpm lint

# Format code
pnpm format:write
```

## Pull Request Process

1. **Update documentation** - Ensure any install or build dependencies are documented in the README.md
2. **Follow the coding standards** - Make sure your code follows the project's style guidelines
3. **Add tests** - Add tests for any new functionality
4. **Update the CHANGELOG** - If applicable, update the CHANGELOG.md with details of changes
5. **Get approval** - Your PR needs to be reviewed and approved by at least one maintainer
6. **Squash commits** - We prefer clean commit history, so squash your commits before merging

### PR Title Format

Use clear and descriptive PR titles following this format:
- `feat: add new feature`
- `fix: resolve bug in component`
- `docs: update README`
- `style: format code`
- `refactor: restructure module`
- `test: add test coverage`
- `chore: update dependencies`

## Coding Standards

### TypeScript

- Use TypeScript for all new code
- Avoid using `any` type; use proper typing
- Document complex types and interfaces

### React/Next.js

- Use functional components with hooks
- Follow React best practices
- Use Next.js conventions (App Router, Server Components, etc.)
- Keep components small and focused

### Styling

- Use Tailwind CSS for styling
- Follow the existing design system
- Ensure responsive design for all screen sizes

### Code Formatting

- We use Prettier for code formatting
- Run `pnpm format:write` before committing
- ESLint is configured for code quality checks

### File Organization

```
/app              # Next.js app directory
/components       # Reusable React components
/lib              # Utility functions and helpers
/public           # Static assets
/styles           # Global styles
```

## Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to build process or auxiliary tools

### Examples

```
feat(proposals): add voting deadline feature

Add ability to set voting deadlines for proposals.
Users can now specify an end date when creating proposals.

Closes #123
```

```
fix(treasury): correct balance calculation

Fix issue where balance was showing incorrect decimals
for certain tokens.

Fixes #456
```

## Getting Help

- **Documentation**: Check the [README](README.md) and [docs](docs/) folder
- **Issues**: Browse [existing issues](https://github.com/pinkycollie/dao/issues)
- **Discussions**: Join our [GitHub Discussions](https://github.com/pinkycollie/dao/discussions)
- **Contact**: Reach out to the maintainers

## Recognition

Contributors who submit quality pull requests will be:
- Added to our contributors list
- Mentioned in release notes
- Eligible for contributor badges and recognition

Thank you for contributing to MBTQ DAO! 🎉
