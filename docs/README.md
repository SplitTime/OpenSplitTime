# OpenSplitTime Documentation

This directory contains the Jekyll-based static documentation site for OpenSplitTime.

## Local Development

### Prerequisites

- Ruby 3.0 or higher
- Bundler

### Setup

```bash
cd docs
bundle install
```

### Running Locally

```bash
bundle exec jekyll serve
```

The site will be available at `http://localhost:4000`.

### Building for Production

```bash
bundle exec jekyll build
```

The static site will be generated in the `_site/` directory.

## Deployment

This site is deployed to GitHub Pages automatically via GitHub Actions when changes are pushed to the `master` branch.

### Deployment URL

The documentation is available at: [https://splittime.github.io/OpenSplitTime/](https://splittime.github.io/OpenSplitTime/)

### How It Works

1. Changes to the `docs/` directory are pushed to the `master` branch
2. GitHub Actions workflow (`.github/workflows/deploy-docs.yml`) is triggered
3. Jekyll builds the site with production settings
4. Built site is deployed to GitHub Pages
5. Site is available within a few minutes

### Manual Deployment

To manually trigger a deployment:
1. Go to the [Actions tab](https://github.com/SplitTime/OpenSplitTime/actions)
2. Select "Deploy Jekyll Documentation to GitHub Pages"
3. Click "Run workflow"

### Custom Domain (Optional)

To configure a custom domain (e.g., `docs.opensplittime.org`):
1. Go to repository Settings → Pages
2. Enter custom domain
3. Update DNS records:
   - Add CNAME record: `docs.opensplittime.org` → `splittime.github.io`
4. Update `docs/_config.yml`:
   ```yaml
   url: "https://docs.opensplittime.org"
   baseurl: ""
   ```

## Structure

- `_layouts/` - Page templates
- `_config.yml` - Jekyll configuration
- `index.md` - Homepage
- (Additional content will be added during migration)

## Contributing

When adding new documentation:

1. Create Markdown files (`.md`) in the appropriate directory
2. Add front matter with `layout` and `title`
3. Use standard Markdown syntax
4. Test locally before submitting PR

## Learn More

- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
