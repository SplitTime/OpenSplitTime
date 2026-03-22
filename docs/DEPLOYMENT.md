# GitHub Pages Deployment Guide

This document describes how the OpenSplitTime documentation is deployed to GitHub Pages.

## Overview

The documentation site is automatically deployed to GitHub Pages using GitHub Actions whenever changes are pushed to the `master` branch.

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
url: "https://splittime.github.io"
baseurl: "/OpenSplitTime"
```

These settings ensure proper URL generation for assets and links in the deployed site.

## Enabling GitHub Pages

To enable GitHub Pages for this repository (one-time setup):

1. Go to repository **Settings** → **Pages**
2. Under "Build and deployment":
   - Source: **GitHub Actions**
3. Save settings

The next push to `master` will trigger the first deployment.

## Monitoring Deployments

View deployment status:
- [Actions tab](https://github.com/SplitTime/OpenSplitTime/actions)
- Check "Deploy Jekyll Documentation to GitHub Pages" workflow runs

Deployment typically completes in 1-2 minutes.

## Custom Domain Setup (Optional)

To use a custom domain like `docs.opensplittime.org`:

### 1. DNS Configuration

Add a CNAME record in your DNS provider:

```
Type: CNAME
Name: docs
Value: splittime.github.io
```

### 2. GitHub Pages Configuration

1. Go to **Settings** → **Pages**
2. Enter custom domain: `docs.opensplittime.org`
3. Check "Enforce HTTPS"

### 3. Update Jekyll Configuration

Update `docs/_config.yml`:

```yaml
url: "https://docs.opensplittime.org"
baseurl: ""
```

Commit and push changes. GitHub will verify the domain and issue an SSL certificate.

## Testing Before Deployment

Test locally before pushing:

```bash
cd docs
bundle install
bundle exec jekyll serve
# Visit http://localhost:4000
```

Build for production locally:

```bash
cd docs
JEKYLL_ENV=production bundle exec jekyll build --baseurl "/OpenSplitTime"
# Check docs/_site/
```

## Troubleshooting

### Deployment Failed

1. Check [Actions tab](https://github.com/SplitTime/OpenSplitTime/actions) for error logs
2. Verify `docs/Gemfile.lock` is committed
3. Ensure Jekyll builds locally without errors

### 404 Errors on Deployed Site

1. Check `baseurl` in `_config.yml` matches repository name
2. Verify links use `{{ site.baseurl }}` or `relative_url` filter
3. Check GitHub Pages is enabled in repository settings

### Changes Not Appearing

1. Verify workflow completed successfully in Actions tab
2. GitHub Pages cache may take a few minutes to update
3. Hard refresh browser (Cmd+Shift+R / Ctrl+Shift+F5)

## Security

- Workflow uses `GITHUB_TOKEN` (automatic, no secrets needed)
- Permissions are scoped to minimum required
- Only `master` branch can trigger deployments
