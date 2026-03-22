# GitHub Pages Deployment Guide

This document describes how the OpenSplitTime documentation is deployed to GitHub Pages.

## Overview

The documentation site is automatically deployed to GitHub Pages using GitHub Actions whenever changes are pushed to the `master` branch. The site is available at [https://docs.opensplittime.org](https://docs.opensplittime.org).

## Deployment Configuration

### GitHub Actions Workflow

The workflow is defined in `.github/workflows/deploy-docs.yml` and:

1. **Triggers** on:
   - Push to `master` branch affecting `docs/` directory
   - Manual workflow dispatch

2. **Builds** the Jekyll site:
   - Uses Ruby 3.3
   - Installs dependencies via Bundler
   - Builds with production settings
   - Uploads artifact for deployment

3. **Deploys** to GitHub Pages:
   - Uses official GitHub Pages deployment action
   - Deploys to `github-pages` environment
   - Updates within minutes

### Jekyll Configuration

Production settings in `docs/_config.yml`:

```yaml
url: "https://docs.opensplittime.org"
baseurl: ""
```

### Custom Domain

The site uses the custom domain `docs.opensplittime.org`. This is configured via:

1. **DNS**: A CNAME record pointing `docs.opensplittime.org` to `splittime.github.io`
2. **GitHub Pages**: Custom domain set in repository Settings → Pages with HTTPS enforced
3. **Jekyll**: `url` and `baseurl` set in `_config.yml` as shown above

## Monitoring Deployments

View deployment status:
- [Actions tab](https://github.com/SplitTime/OpenSplitTime/actions)
- Check "Deploy Jekyll Documentation to GitHub Pages" workflow runs

Deployment typically completes in 1-2 minutes.

## Testing Before Deployment

Test locally before pushing:

```bash
cd docs
bundle install
bundle exec jekyll serve
# Visit http://localhost:4000
```

## Troubleshooting

### Deployment Failed

1. Check [Actions tab](https://github.com/SplitTime/OpenSplitTime/actions) for error logs
2. Verify `docs/Gemfile.lock` is committed
3. Ensure Jekyll builds locally without errors

### 404 Errors on Deployed Site

1. Verify links use `relative_url` filter or relative paths
2. Check GitHub Pages is enabled in repository settings
3. Ensure the custom domain DNS is configured correctly

### Changes Not Appearing

1. Verify workflow completed successfully in Actions tab
2. GitHub Pages cache may take a few minutes to update
3. Hard refresh browser (Cmd+Shift+R / Ctrl+Shift+F5)

## Security

- Workflow uses `GITHUB_TOKEN` (automatic, no secrets needed)
- Permissions are scoped to minimum required
- Only `master` branch can trigger deployments
