# GitHub Actions Workflows - Architecture Improvement Automation

This directory contains GitHub Actions workflows that automate tracking and enforcement of architecture improvements for the KRE8TIONS Flutter IDE project.

## 📋 Workflow Overview

### 🔄 Continuous Integration

#### `ci.yml` - Main CI/CD Pipeline
**Triggers**: Every push/PR to main, develop, sleepy-bartik
**Purpose**: Core quality gates

- ✅ Code formatting verification
- ✅ Flutter analysis (lint checks)
- ✅ Run test suite with coverage
- ✅ Build web production bundle
- ✅ Upload coverage to Codecov
- ✅ Store build artifacts

**Status Badge**:
```markdown
![CI Status](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/CI%20-%20Flutter%20Analysis%20%26%20Tests/badge.svg)
```

---

### 🏗️ Architecture Quality

#### `code-quality.yml` - Code Quality & Architecture Checks
**Triggers**: Push/PR + Weekly (Mondays)
**Purpose**: Enforce architecture standards

**Checks Performed**:
1. **Deprecated API Detection**
   - Scans for `withOpacity()` usage (should use `.withValues()`)
   - Creates GitHub issues when violations found
   - Priority: HIGH (blocks Flutter upgrades)

2. **Monolithic File Detection**
   - Finds files >1,000 lines
   - Recommends refactoring into modules
   - Priority: MEDIUM

3. **Dependency Injection Check**
   - Verifies use of `get_it` or `provider`
   - Counts hard-coded singleton usage
   - Creates recommendation issues

**Auto-Generated Issues**:
- 🚨 "Fix X Deprecated API Calls" (immediate)
- 🏗️ "Refactor Monolithic Services" (short-term)
- 🔧 "Implement Dependency Injection" (short-term)

---

### ⚡ Performance & Testing

#### `performance.yml` - Performance Benchmarks
**Triggers**: Push to main/develop + Weekly (Sundays 2 AM)
**Purpose**: Track performance metrics

**Benchmarks**:
- ⏱️ Build time measurement
- 📦 Build size analysis
- 🧪 Test suite execution time
- 📊 Test coverage percentage
- 🎯 Memory usage tracking (planned)

**Outputs**:
- Weekly performance report issues
- Coverage reports (30-day retention)
- Test coverage tracking issues

**Coverage Threshold**: 70% for production readiness

---

### 📚 Documentation

#### `documentation.yml` - Documentation & API Contracts
**Triggers**: Push/PR + Weekly (Mondays 3 AM)
**Purpose**: Ensure code documentation

**Checks**:
- 📖 Public class documentation coverage
- 📝 TODO/FIXME comment tracking
- 📋 README completeness
- 🏛️ Architecture docs existence (ARCHITECTURE.md, API.md)

**Auto-Generated Issues**:
- 📚 "Document Public API Contracts" (immediate)
- 🚀 "Long-term Architecture Roadmap" (quarterly)

**Long-term Tracking**:
- Browser API abstraction status
- WebSocket implementation progress
- Automated refactoring system
- AI integration completion

---

### 📦 Dependencies & Security

#### `dependencies.yml` - Dependency Management & Security
**Triggers**: Push to main + Weekly (Mondays 4 AM)
**Purpose**: Keep dependencies current and secure

**Checks**:
1. **Outdated Packages**
   - Identifies packages with newer versions
   - Highlights major version gaps
   - Generates update recommendations

2. **Security Audit**
   - Scans for hardcoded secrets
   - Checks for overly permissive files
   - Reviews package vulnerabilities

3. **Framework Compatibility**
   - Tests with Flutter stable channel
   - Verifies SDK constraints
   - Recommends beta/dev testing

**Current Version Gaps**:
- `analyzer`: 6.4.1 → 9.0.0 (2 major versions)
- `dart_style`: 2.3.6 → 3.1.3 (1 major version)
- `flutter_lints`: 5.0.0 → 6.0.0 (1 major version)

---

### 📊 Tracking & Reporting

#### `architecture-dashboard.yml` - Architecture Progress Dashboard
**Triggers**: Weekly (Mondays 9 AM) + Manual
**Purpose**: Comprehensive progress tracking

**Metrics Collected**:
- Deprecated API count
- Large file count (>1,000 lines)
- TODO comment count
- Test file count
- Dependency injection status
- Total lines of code
- Service file count

**Dashboard Sections**:
1. **Overall Progress** (Immediate/Short-term/Long-term)
2. **Immediate Tasks** (This Week)
   - Fix deprecated APIs
   - Add service failure tests
   - Document public APIs
3. **Short-term Tasks** (2-4 Weeks)
   - Refactor monolithic services
   - Implement dependency injection
   - Complete AI integration
   - Add performance benchmarks
4. **Long-term Tasks** (2-3 Months)
   - Browser API abstraction
   - Real-time collaboration
   - Automated refactoring
5. **Quality Metrics Table**
6. **Weekly Focus Items**

**Issue Management**:
- Creates new weekly dashboard issue
- Closes previous week's dashboard
- Labels: `dashboard`, `architecture`, `tracking`

---

## 🎯 Architecture Improvement Timeline

### ⚡ Immediate (This Week) - 4 hours total

| Task | Time | Priority | Workflow |
|------|------|----------|----------|
| Fix deprecated APIs | 30 min | 🔴 HIGH | `code-quality.yml` |
| Add service failure tests | 2-3 hrs | 🔴 HIGH | `performance.yml` |
| Document public APIs | 1 hr | 🟡 MEDIUM | `documentation.yml` |

### 🎯 Short-term (2-4 Weeks)

| Task | Time | Priority | Workflow |
|------|------|----------|----------|
| Refactor monolithic services | 2-4 weeks | 🟡 MEDIUM | `code-quality.yml` |
| Implement dependency injection | 1-2 weeks | 🟡 MEDIUM | `code-quality.yml` |
| Complete AI integration | 2-3 weeks | 🟡 MEDIUM | `documentation.yml` |
| Add performance benchmarks | 1 week | 🟡 MEDIUM | `performance.yml` |

### 🚀 Long-term (2-3 Months)

| Task | Time | Priority | Workflow |
|------|------|----------|----------|
| Browser API abstraction | 2-3 weeks | 🟢 LOW | `documentation.yml` |
| Real-time collaboration | 4-6 weeks | 🟢 LOW | `documentation.yml` |
| Automated refactoring | 3-4 weeks | 🟢 LOW | `documentation.yml` |

---

## 🚀 Getting Started

### 1. Enable Workflows

After pushing to GitHub, workflows will run automatically. To enable:

```bash
# Commit and push workflows
git add .github/workflows/
git commit -m "feat: Add architecture improvement workflows"
git push origin sleepy-bartik
```

### 2. Set Up Repository Secrets (Optional)

For Codecov integration:
```
Settings → Secrets → Actions → New repository secret
Name: CODECOV_TOKEN
Value: <your-codecov-token>
```

### 3. Configure Branch Protection (Recommended)

```
Settings → Branches → Branch protection rules
- Require status checks to pass (CI workflow)
- Require pull request reviews
```

### 4. Monitor Dashboard

Check weekly dashboard issues:
```
Issues → Labels: dashboard
```

---

## 📈 Workflow Schedule

| Workflow | Push/PR | Scheduled | Day/Time |
|----------|---------|-----------|----------|
| CI | ✅ | - | - |
| Code Quality | ✅ | ✅ | Mon 12:00 AM |
| Performance | ✅ | ✅ | Sun 2:00 AM |
| Documentation | ✅ | ✅ | Mon 3:00 AM |
| Dependencies | ✅ | ✅ | Mon 4:00 AM |
| Dashboard | - | ✅ | Mon 9:00 AM |

**Weekly Cycle**:
- Sunday 2 AM: Performance benchmarks run
- Monday 12 AM-4 AM: Quality checks run
- Monday 9 AM: Dashboard generated with results

---

## 🔧 Manual Workflow Triggers

Trigger any workflow manually:

```bash
# Via GitHub UI
Actions → Select Workflow → Run workflow

# Via GitHub CLI
gh workflow run architecture-dashboard.yml
gh workflow run ci.yml
```

---

## 📊 Issue Labels

Workflows create issues with these labels:

| Label | Purpose | Priority |
|-------|---------|----------|
| `tech-debt` | Technical debt items | HIGH |
| `deprecated-api` | Deprecated API usage | HIGH |
| `architecture` | Architecture improvements | MEDIUM |
| `performance` | Performance issues | MEDIUM |
| `testing` | Test coverage gaps | HIGH |
| `documentation` | Missing docs | MEDIUM |
| `dependencies` | Outdated packages | MEDIUM |
| `dashboard` | Weekly progress reports | INFO |
| `long-term` | Long-term goals | LOW |
| `roadmap` | Roadmap tracking | INFO |

---

## 🎯 Success Metrics

Track progress via dashboard metrics:

**Immediate Success** (1 week):
- ✅ 0 deprecated API calls
- ✅ Service failure tests added
- ✅ Key APIs documented

**Short-term Success** (1 month):
- ✅ 0 files >1,000 lines
- ✅ Dependency injection implemented
- ✅ 70%+ test coverage

**Long-term Success** (3 months):
- ✅ Browser API abstraction complete
- ✅ Real-time collaboration working
- ✅ Automated refactoring system

---

## 🛠️ Customization

### Adjust Schedule

Edit cron expressions in workflow files:
```yaml
schedule:
  - cron: '0 9 * * 1'  # Monday 9 AM
```

Cron format: `minute hour day month weekday`

### Modify Thresholds

**File size threshold** (`code-quality.yml`):
```bash
awk '$1 > 1000'  # Change 1000 to desired line count
```

**Coverage threshold** (`performance.yml`):
```bash
echo "Target: 70%+"  # Change to desired percentage
```

### Add Custom Checks

Add new jobs to existing workflows:
```yaml
custom-check:
  name: Custom Architecture Check
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: |
        # Your custom check here
```

---

## 🐛 Troubleshooting

### Workflow Not Running

1. Check workflow syntax: `gh workflow list`
2. Verify triggers match your branch
3. Check Actions tab for errors

### Issue Not Created

1. Verify repository permissions (Actions → General → Read/Write)
2. Check if issue already exists (workflows avoid duplicates)
3. Review workflow logs in Actions tab

### Build Failures

1. Check Flutter version compatibility
2. Verify dependency versions
3. Run locally: `flutter test && flutter build web`

---

## 📝 Contributing

When adding new workflows:

1. Follow existing naming conventions
2. Add documentation to this README
3. Use descriptive job/step names
4. Include error handling
5. Test locally with `act` (optional)

```bash
# Test workflows locally (requires Docker)
brew install act
act -l  # List available workflows
act -j job-name  # Run specific job
```

---

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/ci)
- [Cron Expression Generator](https://crontab.guru/)

---

## 🎉 Quick Wins

Start here for immediate impact:

1. **Run Dashboard Manually**:
   ```bash
   gh workflow run architecture-dashboard.yml
   ```

2. **Fix Deprecated APIs** (30 min):
   ```bash
   # Find all instances
   grep -r "\.withOpacity(" lib/ assets/ide_source/

   # Replace manually or with sed
   find lib/ -name "*.dart" -exec sed -i '' 's/\.withOpacity(\([^)]*\))/.withValues(alpha: \1)/g' {} +
   ```

3. **Check Your First Dashboard** (in Issues tab)

---

**Generated by**: Architecture Improvement Automation System
**Last Updated**: 2024-12-26
